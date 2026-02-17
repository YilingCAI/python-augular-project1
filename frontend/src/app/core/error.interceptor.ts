import { HttpErrorResponse, HttpEvent, HttpHandler, HttpInterceptor, HttpRequest } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

/**
 * Custom error class for API errors
 */
export class ApiClientError extends Error {
  public readonly statusCode: number;
  public readonly details?: unknown;

  constructor(statusCode: number, message: string, details?: unknown) {
    super(message);

    // Fix prototype chain (important for instanceof checks)
    Object.setPrototypeOf(this, new.target.prototype);

    this.name = 'ApiClientError';
    this.statusCode = statusCode;
    this.details = details;
  }
}
/**
 * HTTP Error Interceptor
 * Handles API errors globally
 */
/**
 * HTTP Error Interceptor
 * Handles API errors globally
 */
@Injectable()
export class ErrorInterceptor implements HttpInterceptor {

  intercept(
    request: HttpRequest<unknown>,
    next: HttpHandler
  ): Observable<HttpEvent<unknown>> {

    return next.handle(request).pipe(
      catchError((error: HttpErrorResponse) => {

        let errorMessage = `HTTP ${error.status}`;

        // 1️⃣ Client-side or network error
        if (error.error instanceof ErrorEvent) {
          errorMessage = error.error.message;

        // 2️⃣ FastAPI style: { detail: "message" }
        } else if (error.error && typeof error.error === 'object' && 'detail' in error.error) {
          errorMessage = String((error.error as any).detail);

        // 3️⃣ Fallback to status text
        } else if (error.statusText) {
          errorMessage = error.statusText;
        }

        const apiError = new ApiClientError(
          error.status,
          errorMessage,
          error.error
        );

        return throwError(() => apiError);
      })
    );
  }
}
