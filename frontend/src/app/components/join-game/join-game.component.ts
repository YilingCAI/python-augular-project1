import { ValidationService } from '@/app/core/validation.service';
import { GameService } from '@/app/services/game.service';
import { GameResponse } from '@/app/types/api';
import { CommonModule, Location } from '@angular/common';
import { Component, OnDestroy } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { GameBoardComponent } from '../game-board/game-board.component';

/**
 * Join Game Component
 * Allows users to join existing games
 * - Game ID validation
 * - Real-time game board updates
 * - Security checks for game moves
 */
@Component({
    selector: 'app-join-game',
    standalone: true,
    imports: [CommonModule, FormsModule, GameBoardComponent],
    templateUrl: './join-game.component.html',
    styleUrls: ['./join-game.component.scss']
})
export class JoinGameComponent implements OnDestroy {
    gameIdInput: string = '';
    gameId: string | null = null;
    loading: boolean = false;
    error: string | null = null;
    board: string[] = Array(9).fill(' ');
    boardStatus: string = '';

    private destroy$ = new Subject<void>();

    constructor(
        private gameService: GameService,
        private validationService: ValidationService,
        private location: Location
    ) { }

    ngOnDestroy(): void {
        this.destroy$.next();
        this.destroy$.complete();
    }

    /**
     * Handle join game
     */
    handleJoinGame(): void {
        // Trim input
        const gameId = this.gameIdInput.trim();

        if (!gameId) {
            this.error = 'Please enter a game ID';
            return;
        }

        // Validate game ID format
        const validation = this.validationService.validateGameId(gameId);
        if (!validation.valid) {
            this.error = validation.error || 'Invalid game ID format';
            return;
        }

        this.loading = true;
        this.error = null;

        this.gameService.joinGame(gameId)
            .pipe(takeUntil(this.destroy$))
            .subscribe({
                next: (game: GameResponse) => {
                    this.gameId = game.game_id;
                    this.board = game.board;
                    this.updateBoardStatus();
                    this.loading = false;

                    console.info('[JOIN_GAME] Successfully joined:', {
                        gameId: this.gameId,
                        timestamp: new Date().toISOString()
                    });
                },
                error: (err) => {
                    this.error = err.message || 'Failed to join game. Check the game ID and try again.';
                    this.loading = false;

                    console.error('[JOIN_GAME] Error:', {
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
        if (!this.gameId || this.loading) return;

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
                    this.updateBoardStatus();
                    this.loading = false;
                },
                error: (err) => {
                    this.error = err.message || 'Move failed. Please try again.';
                    this.loading = false;

                    console.error('[JOIN_GAME] Move error:', {
                        status: err.status,
                        gameId: this.gameId
                    });
                }
            });
    }

    /**
     * Update board status message
     */
    private updateBoardStatus(): void {
        this.boardStatus = 'Game in progress!';
    }

    /**
     * Go back to previous page
     */
    goBack(): void {
        this.location.back();
    }
}
