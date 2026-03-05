import { ApiClientError } from '@/app/core/error.interceptor';
import { TokenService } from '@/app/core/token.service';
import { LoginResponse, UserCreate, UserLogin, UserResponse } from '@/app/types/api';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, throwError } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';
import { ApiClient } from './api.client';

/**
 * Authentication Service
 * Handles user registration, login, and profile management
 */
@Injectable({
    providedIn: 'root'
})
export class AuthService {
    private userSubject = new BehaviorSubject<UserResponse | null>(null);
    public user$ = this.userSubject.asObservable();

    private loadingSubject = new BehaviorSubject<boolean>(false);
    public loading$ = this.loadingSubject.asObservable();

    private errorSubject = new BehaviorSubject<string | null>(null);
    public error$ = this.errorSubject.asObservable();

    constructor(
        private apiClient: ApiClient,
        private tokenService: TokenService
    ) {
        this.checkAuthentication();
    }

    /**
     * Check if user is already logged in on initialization
     */
    private checkAuthentication(): void {
        if (!this.tokenService.isAuthenticated()) {
            return;
        }

        this.loadingSubject.next(true);
        this.apiClient.get<UserResponse>('/users/me')
            .pipe(
                tap(user => {
                    this.userSubject.next(user);
                    this.errorSubject.next(null);
                }),
                catchError(error => {
                    if (error instanceof ApiClientError && error.statusCode === 401) {
                        this.tokenService.clearToken();
                        this.userSubject.next(null);
                        this.errorSubject.next('Session expired. Please login again.');
                    }
                    return throwError(() => error);
                })
            )
            .subscribe({
                complete: () => this.loadingSubject.next(false),
                error: () => this.loadingSubject.next(false)
            });
    }

    /**
     * Register a new user
     */
    register(userData: UserCreate): Observable<UserResponse> {
        this.loadingSubject.next(true);
        this.errorSubject.next(null);

        return this.apiClient.post<UserResponse>('/users/register', userData)
            .pipe(
                tap(user => {
                    this.userSubject.next(user);
                    this.errorSubject.next(null);
                }),
                catchError(error => {
                    const message = error instanceof ApiClientError
                        ? `Registration failed: ${error.message}`
                        : 'Registration failed';
                    this.errorSubject.next(message);
                    this.loadingSubject.next(false);
                    return throwError(() => new Error(message));
                })
            );
    }

    /**
     * Login user with username and password
     */
    login(credentials: UserLogin): Observable<LoginResponse> {
        this.loadingSubject.next(true);
        this.errorSubject.next(null);

        // Create FormData for OAuth2PasswordRequestForm
        const formData = new FormData();
        formData.append('username', credentials.username);
        formData.append('password', credentials.password);

        return this.apiClient.postForm<LoginResponse>('/users/login', formData)
            .pipe(
                tap(response => {
                    // Save token
                    if (response.access_token) {
                        this.tokenService.setToken(response.access_token);
                    }
                }),
                catchError(error => {
                    const message = error instanceof ApiClientError
                        ? `Login failed: ${error.message}`
                        : 'Login failed';
                    this.errorSubject.next(message);
                    this.loadingSubject.next(false);
                    return throwError(() => new Error(message));
                })
            );
    }

    /**
     * Get current user profile
     */
    getCurrentUser(): Observable<UserResponse> {
        return this.apiClient.get<UserResponse>('/users/me')
            .pipe(
                tap(user => {
                    this.userSubject.next(user);
                    this.errorSubject.next(null);
                    this.loadingSubject.next(false);
                }),
                catchError(error => {
                    if (error instanceof ApiClientError && error.statusCode === 401) {
                        this.tokenService.clearToken();
                        this.userSubject.next(null);
                        this.errorSubject.next('Session expired. Please login again.');
                    } else {
                        const message = error instanceof ApiClientError
                            ? error.message
                            : 'Failed to fetch user';
                        this.errorSubject.next(message);
                    }
                    this.loadingSubject.next(false);
                    return throwError(() => error);
                })
            );
    }

    /**
     * Logout user
     */
    logout(): void {
        this.tokenService.clearToken();
        this.userSubject.next(null);
        this.errorSubject.next(null);
        this.loadingSubject.next(false);
    }

    /**
     * Get current user value
     */
    get currentUser(): UserResponse | null {
        return this.userSubject.value;
    }

    /**
     * Get loading state
     */
    get loading(): boolean {
        return this.loadingSubject.value;
    }

    /**
     * Get error message
     */
    get error(): string | null {
        return this.errorSubject.value;
    }

    /**
     * Check if user is authenticated
     */
    get isAuthenticated(): boolean {
        return this.tokenService.isAuthenticated();
    }

    /**
     * Clear error message
     */
    clearError(): void {
        this.errorSubject.next(null);
    }
}
