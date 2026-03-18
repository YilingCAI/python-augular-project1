import { RateLimitConfig, RateLimitService } from '@/app/core/rate-limit.service';
import { ValidationService } from '@/app/core/validation.service';
import { AuthService } from '@/app/services/auth.service';
import { CommonModule } from '@angular/common';
import { Component, OnDestroy, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

/**
 * Login Component
 * Handles user authentication with enterprise security measures
 * - Input validation and sanitization
 * - Rate limiting for brute force protection
 * - XSS prevention
 * - Secure password handling
 */
@Component({
    selector: 'app-login',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './login.component.html',
    styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit, OnDestroy {
    // Form Data
    username: string = '';
    password: string = '';
    showPassword: boolean = false;

    // State
    loading: boolean = false;
    localError: string | null = null;
    usernameError: string | null = null;
    passwordError: string | null = null;

    // Rate Limiting
    rateLimited: boolean = false;
    showRateLimitWarning: boolean = false;
    rateLimitMessage: string = '';

    private destroy$ = new Subject<void>();

    private readonly RATE_LIMIT_KEY = 'login-attempts';
    private readonly RATE_LIMIT_CONFIG: RateLimitConfig = {
        maxAttempts: 5,
        windowMs: 15 * 60 * 1000, // 15 minutes
        blockDurationMs: 30 * 60 * 1000 // 30 minutes
    };

    constructor(
        private authService: AuthService,
        private router: Router,
        private validationService: ValidationService,
        private rateLimitService: RateLimitService
    ) { }

    ngOnInit(): void {
        // Subscribe to loading state
        this.authService.loading$
            .pipe(takeUntil(this.destroy$))
            .subscribe(loading => {
                this.loading = loading;
            });

        // Subscribe to error state
        this.authService.error$
            .pipe(takeUntil(this.destroy$))
            .subscribe(error => {
                this.localError = error;
            });

        // Check rate limit on init
        this.checkRateLimit();
    }

    ngOnDestroy(): void {
        this.destroy$.next();
        this.destroy$.complete();
    }

    /**
     * Check if user is rate limited
     */
    private checkRateLimit(): void {
        if (this.rateLimitService.isRateLimited(this.RATE_LIMIT_KEY, this.RATE_LIMIT_CONFIG)) {
            this.rateLimited = true;
            this.showRateLimitWarning = true;
            const resetTime = this.rateLimitService.getResetTime(this.RATE_LIMIT_KEY);
            const minutes = Math.ceil(resetTime / 60);
            this.rateLimitMessage = `Too many login attempts. Please try again in ${minutes} minute${minutes > 1 ? 's' : ''}.`;
        } else {
            this.rateLimited = false;
            this.showRateLimitWarning = false;
        }
    }

    /**
     * Get display error (service or local)
     */
    get displayError(): string | null {
        return this.localError || this.authService.error;
    }

    /**
     * Toggle password visibility
     */
    togglePasswordVisibility(): void {
        this.showPassword = !this.showPassword;
    }

    /**
     * Validate username on blur
     */
    onUsernameBlur(): void {
        if (!this.username) {
            this.usernameError = null;
            return;
        }

        const validation = this.validationService.validateUsername(this.username);
        this.usernameError = validation.error || null;
    }

    /**
     * Validate password on blur
     */
    onPasswordBlur(): void {
        if (!this.password) {
            this.passwordError = null;
            return;
        }

        // For login, just check if password is present and not obviously malicious
        if (this.validationService.containsXSSPayload(this.password)) {
            this.passwordError = 'Invalid password format';
        } else {
            this.passwordError = null;
        }
    }

    /**
     * Handle form submission with security checks
     */
    onSubmit(): void {
        // Check rate limiting
        this.checkRateLimit();
        if (this.rateLimited) {
            return;
        }

        // Clear previous field errors
        this.usernameError = null;
        this.passwordError = null;
        this.localError = null;

        // Validate username
        const usernameValidation = this.validationService.validateUsername(this.username);
        if (!usernameValidation.valid) {
            this.usernameError = usernameValidation.error || 'Invalid username';
            return;
        }

        // Validate password is present
        if (!this.password || this.password.trim().length === 0) {
            this.passwordError = 'Password is required';
            return;
        }

        // Check for XSS in password
        if (this.validationService.containsXSSPayload(this.password)) {
            this.passwordError = 'Invalid password format';
            return;
        }

        // Sanitize inputs
        const sanitizedUsername = this.validationService.sanitizeInput(this.username);

        // Call auth service
        this.authService.login({
            username: sanitizedUsername,
            password: this.password // Password is not sanitized, sent as-is
        }).pipe(takeUntil(this.destroy$))
            .subscribe({
                next: () => {
                    // Reset rate limit on successful login
                    this.rateLimitService.reset(this.RATE_LIMIT_KEY);
                    // Clear sensitive data
                    this.password = '';
                    this.router.navigate(['/homepage']);
                },
                error: (err) => {
                    // Record failed attempt
                    this.rateLimitService.isRateLimited(this.RATE_LIMIT_KEY, this.RATE_LIMIT_CONFIG);
                    this.checkRateLimit();

                    // Set error message
                    this.localError = err.message || 'Login failed. Please try again.';

                    console.warn('[LOGIN] Authentication failed:', {
                        status: err.status,
                        timestamp: new Date().toISOString()
                    });
                }
            });
    }

    /**
     * Navigate to signup
     */
    goToSignup(): void {
        this.router.navigate(['/signup']);
    }
}
