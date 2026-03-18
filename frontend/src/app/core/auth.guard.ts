import { AuthService } from '@/app/services/auth.service';
import { Injectable } from '@angular/core';
import { CanActivate, Router } from '@angular/router';
import { Observable } from 'rxjs';

/**
 * Auth Guard
 * Protects routes that require authentication
 */
@Injectable({
    providedIn: 'root'
})
export class AuthGuard implements CanActivate {
    constructor(
        private authService: AuthService,
        private router: Router
    ) { }

    canActivate(): Observable<boolean> | Promise<boolean> | boolean {
        if (this.authService.isAuthenticated) {
            return true;
        }

        // Store the attempted URL for redirecting after login
        this.router.navigate(['/login']);
        return false;
    }
}
