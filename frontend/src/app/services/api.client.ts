import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

/**
 * Centralized API Client
 * Handles all HTTP requests with error handling
 */
@Injectable({
    providedIn: 'root'
})
export class ApiClient {
    private baseUrl: string;

    constructor(private http: HttpClient) {
        this.baseUrl = this.getApiBaseUrl();
    }

    /**
     * Get API base URL from environment
     */
    private getApiBaseUrl(): string {
        return (window as any)['API_BASE_URL'] || 'http://localhost:8000';
    }

    /**
     * Perform GET request
     */
    get<T>(endpoint: string): Observable<T> {
        const url = `${this.baseUrl}${endpoint}`;
        return this.http.get<T>(url);
    }

    /**
     * Perform POST request
     */
    post<T>(endpoint: string, data?: any): Observable<T> {
        const url = `${this.baseUrl}${endpoint}`;
        return this.http.post<T>(url, data || {});
    }

    /**
     * Perform POST request with FormData
     */
    postForm<T>(endpoint: string, formData: FormData): Observable<T> {
        const url = `${this.baseUrl}${endpoint}`;
        return this.http.post<T>(url, formData);
    }

    /**
     * Perform PUT request
     */
    put<T>(endpoint: string, data?: any): Observable<T> {
        const url = `${this.baseUrl}${endpoint}`;
        return this.http.put<T>(url, data || {});
    }

    /**
     * Perform DELETE request
     */
    delete<T>(endpoint: string): Observable<T> {
        const url = `${this.baseUrl}${endpoint}`;
        return this.http.delete<T>(url);
    }
}
