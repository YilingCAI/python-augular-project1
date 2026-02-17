import { ValidationService } from '@/app/core/validation.service';
import { AuthService } from '@/app/services/auth.service';
import { CommonModule } from '@angular/common';
import { Component, OnDestroy, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

/**
 * Signup Component
 * Handles user registration with enterprise security
 * - Strong password validation with visual feedback
 * - Input sanitization and XSS prevention
 * - Password strength indicator
 * - Secure password handling
 */
@Component({
    selector: 'app-signup',
    standalone: true,
    imports: [CommonModule, FormsModule],
    templateUrl: './signup.component.html',
    styleUrls: ['./signup.component.scss']
})
export class SignupComponent implements OnInit, OnDestroy {
    // Form Data
    username: string = '';
    password: string = '';
    confirmPassword: string = '';
    showPassword: boolean = false;
    showConfirmPassword: boolean = false;

    // State
    errors: Record<string, string> = {};
    loading: boolean = false;

    // Password Strength
    passwordStrength: 'weak' | 'fair' | 'strong' = 'weak';
    hasMinLength: boolean = false;
    hasUppercase: boolean = false;
    hasLowercase: boolean = false;
    hasNumber: boolean = false;
    hasSpecialChar: boolean = false;

    private destroy$ = new Subject<void>();

    constructor(
        private authService: AuthService,
        private router: Router,
        private validationService: ValidationService
    ) { }

    ngOnInit(): void {
        this.authService.loading$
            .pipe(takeUntil(this.destroy$))
            .subscribe(loading => {
                this.loading = loading;
            });
    }

    ngOnDestroy(): void {
        this.destroy$.next();
        this.destroy$.complete();
    }

    /**
     * Toggle password visibility
     */
    togglePasswordVisibility(): void {
        this.showPassword = !this.showPassword;
    }

    /**
     * Toggle confirm password visibility
     */
    toggleConfirmPasswordVisibility(): void {
        this.showConfirmPassword = !this.showConfirmPassword;
    }

    /**
     * Update password strength indicator
     */
    updatePasswordStrength(): void {
        if (!this.password) {
            this.passwordStrength = 'weak';
            return;
        }

        this.hasMinLength = this.password.length >= 8;
        this.hasUppercase = /[A-Z]/.test(this.password);
        this.hasLowercase = /[a-z]/.test(this.password);
        this.hasNumber = /[0-9]/.test(this.password);
        this.hasSpecialChar = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(this.password);

        const metRequirements = [
            this.hasMinLength,
            this.hasUppercase,
            this.hasLowercase,
            this.hasNumber,
            this.hasSpecialChar
        ].filter(Boolean).length;

        if (metRequirements <= 2) {
            this.passwordStrength = 'weak';
        } else if (metRequirements <= 3) {
            this.passwordStrength = 'fair';
        } else {
            this.passwordStrength = 'strong';
        }
    }

    /**
     * Get password strength percentage
     */
    getPasswordStrengthPercent(): number {
        if (!this.password) return 0;
        if (this.passwordStrength === 'weak') return 33;
        if (this.passwordStrength === 'fair') return 66;
        return 100;
    }

    /**
     * Validate username field
     */
    validateUsernameField(): void {
        if (!this.username) {
            delete this.errors['username'];
            return;
        }

        const validation = this.validationService.validateUsername(this.username);
        if (!validation.valid) {
            this.errors['username'] = validation.error || 'Invalid username';
        } else {
            delete this.errors['username'];
        }
    }

    /**
     * Validate password field
     */
    validatePasswordField(): void {
        if (!this.password) {
            delete this.errors['password'];
            return;
        }

        const validation = this.validationService.validatePassword(this.password);
        if (!validation.valid) {
            this.errors['password'] = validation.errors[0] || 'Invalid password';
        } else {
            delete this.errors['password'];
        }
    }

    /**
     * Validate confirm password field
     */
    validateConfirmPasswordField(): void {
        if (!this.confirmPassword) {
            delete this.errors['confirmPassword'];
            return;
        }

        if (this.password !== this.confirmPassword) {
            this.errors['confirmPassword'] = 'Passwords do not match';
        } else {
            delete this.errors['confirmPassword'];
        }
    }

    /**
     * Validate entire form
     */
    validateForm(): boolean {
        const newErrors: Record<string, string> = {};

        // Username validation
        const usernameValidation = this.validationService.validateUsername(this.username);
        if (!usernameValidation.valid) {
            newErrors['username'] = usernameValidation.error || 'Invalid username';
        }

        // Password validation
        const passwordValidation = this.validationService.validatePassword(this.password);
        if (!passwordValidation.valid) {
            newErrors['password'] = passwordValidation.errors[0] || 'Invalid password';
        }

        // Check for XSS
        if (this.validationService.containsXSSPayload(this.username)) {
            newErrors['username'] = 'Invalid characters in username';
        }

        // Password match
        const matchValidation = this.validationService.validatePasswordMatch(
            this.password,
            this.confirmPassword
        );
        if (!matchValidation.valid) {
            newErrors['confirmPassword'] = matchValidation.error || 'Passwords do not match';
        }

        this.errors = newErrors;
        return Object.keys(newErrors).length === 0;
    }

    /**
     * Handle form submission
     */
    onSubmit(): void {
        if (!this.validateForm()) {
            return;
        }

        // Sanitize username
        const sanitizedUsername = this.validationService.sanitizeInput(this.username);

        this.authService.register({
            username: sanitizedUsername,
            password: this.password
        }).pipe(takeUntil(this.destroy$))
            .subscribe({
                next: () => {
                    // Clear sensitive data
                    this.password = '';
                    this.confirmPassword = '';
                    this.router.navigate(['/homepage']);
                },
                error: (err) => {
                    this.errors['submit'] = err.message || 'Registration failed. Please try again.';
                    console.warn('[SIGNUP] Registration failed:', {
                        status: err.status,
                        timestamp: new Date().toISOString()
                    });
                }
            });
    }

    /**
     * Navigate to login
     */
    goToLogin(): void {
        this.router.navigate(['/login']);
    }
}
