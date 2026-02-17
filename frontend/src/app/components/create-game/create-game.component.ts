import { ValidationService } from '@/app/core/validation.service';
import { GameService } from '@/app/services/game.service';
import { GameResponse } from '@/app/types/api';
import { CommonModule } from '@angular/common';
import { Component, OnDestroy, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { GameBoardComponent } from '../game-board/game-board.component';

/**
 * Create Game Component
 * Allows users to create a new game
 * - Generates shareable game ID
 * - Displays game board when opponent joins
 * - Input validation for game moves
 */
@Component({
    selector: 'app-create-game',
    standalone: true,
    imports: [CommonModule, GameBoardComponent],
    templateUrl: './create-game.component.html',
    styleUrls: ['./create-game.component.scss']
})
export class CreateGameComponent implements OnInit, OnDestroy {
    gameId: string | null = null;
    loading: boolean = false;
    error: string | null = null;
    board: string[] = Array(9).fill(' ');
    opponent: boolean = false;
    boardStatus: string = '';
    showCopyMessage: boolean = false;

    private destroy$ = new Subject<void>();
    private copyMessageTimeout: any;

    constructor(
        private gameService: GameService,
        private router: Router,
        private validationService: ValidationService
    ) { }

    ngOnInit(): void {
        // Component initialization
    }

    ngOnDestroy(): void {
        if (this.copyMessageTimeout) {
            clearTimeout(this.copyMessageTimeout);
        }
        this.destroy$.next();
        this.destroy$.complete();
    }

    /**
     * Create a new game
     */
    handleCreateGame(): void {
        this.loading = true;
        this.error = null;

        this.gameService.createGame()
            .pipe(takeUntil(this.destroy$))
            .subscribe({
                next: (game: GameResponse) => {
                    // Validate game ID
                    const gameIdValidation = this.validationService.validateGameId(game.game_id);
                    if (!gameIdValidation.valid) {
                        this.error = 'Invalid game ID received from server';
                        this.loading = false;
                        return;
                    }

                    this.gameId = game.game_id;
                    this.board = game.board;
                    this.opponent = !!game.player2;
                    this.updateBoardStatus();
                    this.loading = false;

                    console.info('[CREATE_GAME] Game created:', {
                        gameId: this.gameId,
                        timestamp: new Date().toISOString()
                    });
                },
                error: (err) => {
                    this.error = err.message || 'Failed to create game. Please try again.';
                    this.loading = false;
                    console.error('[CREATE_GAME] Error:', {
                        status: err.status,
                        message: err.message
                    });
                }
            });
    }

    /**
     * Handle cell click on game board
     */
    handleCellClick(index: number): void {
        if (!this.gameId || this.loading || !this.opponent) return;

        // Validate board position
        const positionValidation = this.validationService.validateBoardPosition(index);
        if (!positionValidation.valid) {
            this.error = positionValidation.error || 'Invalid move';
            return;
        }

        // Check if cell is already filled
        if (this.board[index] !== ' ') {
            this.error = 'Cell already occupied';
            return;
        }

        this.loading = true;
        this.error = null;

        this.gameService.makeMove(this.gameId, index)
            .pipe(takeUntil(this.destroy$))
            .subscribe({
                next: (game: GameResponse) => {
                    this.board = game.board;
                    this.opponent = !!game.player2;
                    this.updateBoardStatus();
                    this.loading = false;
                },
                error: (err) => {
                    this.error = err.message || 'Move failed. Please try again.';
                    this.loading = false;
                    console.error('[CREATE_GAME] Move error:', {
                        status: err.status,
                        gameId: this.gameId
                    });
                }
            });
    }

    /**
     * Copy game ID to clipboard
     */
    copyGameId(): void {
        if (!this.gameId) return;

        navigator.clipboard.writeText(this.gameId).then(() => {
            this.showCopyMessage = true;

            if (this.copyMessageTimeout) {
                clearTimeout(this.copyMessageTimeout);
            }

            this.copyMessageTimeout = setTimeout(() => {
                this.showCopyMessage = false;
            }, 2000);
        }).catch((err) => {
            this.error = 'Failed to copy game ID';
            console.error('[COPY] Error:', err);
        });
    }

    /**
     * Update board status message
     */
    private updateBoardStatus(): void {
        if (!this.opponent) {
            this.boardStatus = 'Waiting for opponent to join...';
        } else {
            this.boardStatus = 'Game in progress!';
        }
    }

    /**
     * Go back to previous page
     */
    goBack(): void {
        window.history.back();
    }
}
