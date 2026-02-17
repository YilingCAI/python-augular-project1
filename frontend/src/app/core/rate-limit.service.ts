import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';

/**
 * Rate Limiting Service
 * Prevents brute force attacks and DoS attempts
 */
export interface RateLimitConfig {
    maxAttempts: number;
    windowMs: number; // milliseconds
    blockDurationMs: number; // milliseconds
}

@Injectable({
    providedIn: 'root'
})
export class RateLimitService {
    private rateLimits = new Map<string, { attempts: number; resetTime: number; blockedUntil?: number }>();
    private isBlocked$ = new BehaviorSubject<boolean>(false);

    private readonly DEFAULT_CONFIG: RateLimitConfig = {
        maxAttempts: 5,
        windowMs: 15 * 60 * 1000, // 15 minutes
        blockDurationMs: 30 * 60 * 1000 // 30 minutes
    };

    constructor() { }

    /**
     * Check if action should be rate limited
     */
    isRateLimited(key: string, config: Partial<RateLimitConfig> = {}): boolean {
        const finalConfig = { ...this.DEFAULT_CONFIG, ...config };
        const now = Date.now();
        const limitData = this.rateLimits.get(key);

        // Check if currently blocked
        if (limitData?.blockedUntil && now < limitData.blockedUntil) {
            this.isBlocked$.next(true);
            return true;
        }

        // Reset window if expired
        if (!limitData || now > limitData.resetTime) {
            this.rateLimits.set(key, {
                attempts: 0,
                resetTime: now + finalConfig.windowMs
            });
            this.isBlocked$.next(false);
            return false;
        }

        // Increment and check attempts
        limitData.attempts++;

        if (limitData.attempts > finalConfig.maxAttempts) {
            limitData.blockedUntil = now + finalConfig.blockDurationMs;
            this.isBlocked$.next(true);
            return true;
        }

        this.isBlocked$.next(false);
        return false;
    }

    /**
     * Get remaining attempts before rate limit
     */
    getRemainingAttempts(key: string, config: Partial<RateLimitConfig> = {}): number {
        const finalConfig = { ...this.DEFAULT_CONFIG, ...config };
        const limitData = this.rateLimits.get(key);

        if (!limitData) return finalConfig.maxAttempts;

        return Math.max(0, finalConfig.maxAttempts - limitData.attempts);
    }

    /**
     * Get time until rate limit is reset (in seconds)
     */
    getResetTime(key: string): number {
        const limitData = this.rateLimits.get(key);

        if (!limitData) return 0;

        const now = Date.now();
        const timeUntilReset = Math.max(0, limitData.resetTime - now);

        return Math.ceil(timeUntilReset / 1000);
    }

    /**
     * Reset rate limit for a key
     */
    reset(key: string): void {
        this.rateLimits.delete(key);
        this.isBlocked$.next(false);
    }

    /**
     * Reset all rate limits (admin only)
     */
    resetAll(): void {
        this.rateLimits.clear();
        this.isBlocked$.next(false);
    }

    /**
     * Observable for blocked state
     */
    isBlocked(): Observable<boolean> {
        return this.isBlocked$.asObservable();
    }
}
