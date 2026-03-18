import { Injectable } from '@angular/core';

const TOKEN_KEY = 'access_token';

/**
 * Token Service
 * Manages JWT token storage and retrieval
 */
@Injectable({
    providedIn: 'root'
})
export class TokenService {
    /**
     * Get the stored JWT token
     */
    getToken(): string | null {
        return localStorage.getItem(TOKEN_KEY);
    }

    /**
     * Store JWT token
     */
    setToken(token: string): void {
        localStorage.setItem(TOKEN_KEY, token);
    }

    /**
     * Clear JWT token
     */
    clearToken(): void {
        localStorage.removeItem(TOKEN_KEY);
    }

    /**
     * Check if user is authenticated
     */
    isAuthenticated(): boolean {
        return this.getToken() !== null;
    }
}
