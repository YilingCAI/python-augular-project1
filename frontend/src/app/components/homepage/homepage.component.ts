import { AuthService } from '@/app/services/auth.service';
import { UserResponse } from '@/app/types/api';
import { CommonModule } from '@angular/common';
import { Component, OnDestroy, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

/**
 * Homepage Component
 * Main dashboard after user login
 * - Displays user information
 * - Game action buttons
 * - How to play guide
 */
@Component({
    selector: 'app-homepage',
    standalone: true,
    imports: [CommonModule],
    templateUrl: './homepage.component.html',
    styleUrls: ['./homepage.component.scss']
})
export class HomepageComponent implements OnInit, OnDestroy {
    user: UserResponse | null = null;

    private destroy$ = new Subject<void>();

    constructor(
        private authService: AuthService,
        private router: Router
    ) { }

    ngOnInit(): void {
        this.authService.user$
            .pipe(takeUntil(this.destroy$))
            .subscribe(user => {
                this.user = user;
            });
    }

    ngOnDestroy(): void {
        this.destroy$.next();
        this.destroy$.complete();
    }

    /**
     * Navigate to create game
     */
    goToCreateGame(): void {
        this.router.navigate(['/game/create']);
    }

    /**
     * Navigate to join game
     */
    goToJoinGame(): void {
        this.router.navigate(['/game/join']);
    }

    /**
     * Logout user
     */
    onLogout(): void {
        this.authService.logout();
        this.router.navigate(['/login']);
    }
}
