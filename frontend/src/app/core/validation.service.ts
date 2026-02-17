import { Injectable } from '@angular/core';

/**
 * Enterprise Validation Service
 * Provides sanitized input validation and security checks
 */
@Injectable({
    providedIn: 'root'
})
export class ValidationService {
    // Security patterns
    private readonly USERNAME_PATTERN = /^[a-zA-Z0-9_-]{3,20}$/;
    private readonly EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    private readonly PASSWORD_MIN_LENGTH = 8;
    private readonly XSS_PATTERN = /<script|<iframe|javascript:|onerror=|onload=/gi;

    constructor() { }

    /**
     * Validate username against security rules
     */
    validateUsername(username: string): { valid: boolean; error?: string } {
        if (!username || username.trim().length === 0) {
            return { valid: false, error: 'Username is required' };
        }

        if (username.length < 3 || username.length > 20) {
            return { valid: false, error: 'Username must be between 3 and 20 characters' };
        }

        if (!this.USERNAME_PATTERN.test(username)) {
            return {
                valid: false,
                error: 'Username can only contain letters, numbers, hyphens, and underscores'
            };
        }

        return { valid: true };
    }

    /**
     * Validate email address
     */
    validateEmail(email: string): { valid: boolean; error?: string } {
        if (!email || email.trim().length === 0) {
            return { valid: false, error: 'Email is required' };
        }

        if (!this.EMAIL_PATTERN.test(email)) {
            return { valid: false, error: 'Invalid email address' };
        }

        return { valid: true };
    }

    /**
     * Validate password strength
     */
    validatePassword(password: string): { valid: boolean; errors: string[] } {
        const errors: string[] = [];

        if (!password) {
            return { valid: false, errors: ['Password is required'] };
        }

        if (password.length < this.PASSWORD_MIN_LENGTH) {
            errors.push(`Password must be at least ${this.PASSWORD_MIN_LENGTH} characters`);
        }

        if (!/[A-Z]/.test(password)) {
            errors.push('Password must contain at least one uppercase letter');
        }

        if (!/[a-z]/.test(password)) {
            errors.push('Password must contain at least one lowercase letter');
        }

        if (!/[0-9]/.test(password)) {
            errors.push('Password must contain at least one number');
        }

        if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) {
            errors.push('Password must contain at least one special character');
        }

        return { valid: errors.length === 0, errors };
    }

    /**
     * Validate password match
     */
    validatePasswordMatch(password: string, confirmPassword: string): {
        valid: boolean;
        error?: string;
    } {
        if (password !== confirmPassword) {
            return { valid: false, error: 'Passwords do not match' };
        }
        return { valid: true };
    }

    /**
     * Sanitize user input to prevent XSS attacks
     */
    sanitizeInput(input: string): string {
        if (!input) return '';

        // Remove potentially harmful scripts
        let sanitized = input.replace(this.XSS_PATTERN, '');

        // Trim and limit length
        sanitized = sanitized.trim().substring(0, 255);

        return sanitized;
    }

    /**
     * Check if input contains potential XSS payload
     */
    containsXSSPayload(input: string): boolean {
        return this.XSS_PATTERN.test(input);
    }

    /**
     * Validate game ID format (UUID-like)
     */
    validateGameId(gameId: string): { valid: boolean; error?: string } {
        if (!gameId || gameId.trim().length === 0) {
            return { valid: false, error: 'Game ID is required' };
        }

        // Basic UUID v4 validation pattern
        const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

        if (!uuidPattern.test(gameId)) {
            return { valid: false, error: 'Invalid game ID format' };
        }

        return { valid: true };
    }

    /**
     * Validate board position (0-8 for tic tac toe)
     */
    validateBoardPosition(position: number): { valid: boolean; error?: string } {
        if (!Number.isInteger(position) || position < 0 || position > 8) {
            return { valid: false, error: 'Invalid board position' };
        }
        return { valid: true };
    }
}
