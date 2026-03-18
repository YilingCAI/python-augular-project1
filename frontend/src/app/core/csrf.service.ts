import { Injectable } from '@angular/core';

/**
 * CSRF Protection Service
 * Manages CSRF tokens for secure API calls
 */
@Injectable({
    providedIn: 'root'
})
export class CsrfService {
    private readonly CSRF_HEADER_NAME = 'X-CSRF-Token';
    private readonly CSRF_COOKIE_NAME = 'XSRF-TOKEN';
    private readonly CSRF_STORAGE_KEY = 'csrf-token';

    constructor() { }

    /**
     * Generate CSRF token
     */
    generateToken(): string {
        const array = new Uint8Array(32);
        crypto.getRandomValues(array);
        return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
    }

    /**
     * Store CSRF token
     */
    setToken(token: string): void {
        localStorage.setItem(this.CSRF_STORAGE_KEY, token);
    }

    /**
     * Get CSRF token
     */
    getToken(): string | null {
        return localStorage.getItem(this.CSRF_STORAGE_KEY);
    }

    /**
     * Ensure token exists, generate if not
     */
    ensureToken(): string {
        let token = this.getToken();

        if (!token) {
            token = this.generateToken();
            this.setToken(token);
        }

        return token;
    }

    /**
     * Get CSRF header name
     */
    getHeaderName(): string {
        return this.CSRF_HEADER_NAME;
    }

    /**
     * Clear token
     */
    clearToken(): void {
        localStorage.removeItem(this.CSRF_STORAGE_KEY);
    }

    /**
     * Validate token format
     */
    isValidToken(token: string): boolean {
        // Token should be 64 hex characters
        return /^[0-9a-f]{64}$/.test(token);
    }
}
