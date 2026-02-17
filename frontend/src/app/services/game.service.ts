import { ApiClientError } from '@/app/core/error.interceptor';
import { GameResponse, MoveRequest } from '@/app/types/api';
import { Injectable } from '@angular/core';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { ApiClient } from './api.client';

/**
 * Game Service
 * Handles game creation, moves, and game state management
 */
@Injectable({
    providedIn: 'root'
})
export class GameService {
    constructor(private apiClient: ApiClient) { }

    /**
     * Create a new game
     * POST /games/create_game
     */
    createGame(): Observable<GameResponse> {
        return this.apiClient.post<GameResponse>('/games/create_game', {})
            .pipe(
                catchError(error => {
                    const message = error instanceof ApiClientError
                        ? `Failed to create game: ${error.message}`
                        : 'Failed to create game';
                    return throwError(() => new Error(message));
                })
            );
    }

    /**
     * Make a move in a game
     * POST /games/move
     */
    makeMove(gameId: string, move: number): Observable<GameResponse> {
        const payload: MoveRequest = {
            game_id: gameId,
            move
        };

        return this.apiClient.post<GameResponse>('/games/move', payload)
            .pipe(
                catchError(error => {
                    const message = error instanceof ApiClientError
                        ? `Move failed: ${error.message}`
                        : 'Move failed';
                    return throwError(() => new Error(message));
                })
            );
    }

    /**
     * Get all games for the current user
     * GET /games
     */
    getUserGames(): Observable<GameResponse[]> {
        return this.apiClient.get<GameResponse[]>('/games')
            .pipe(
                catchError(error => {
                    const message = error instanceof ApiClientError
                        ? `Failed to fetch games: ${error.message}`
                        : 'Failed to fetch games';
                    return throwError(() => new Error(message));
                })
            );
    }

    /**
     * Get a specific game by ID
     * GET /games/{game_id}
     */
    getGame(gameId: string): Observable<GameResponse> {
        return this.apiClient.get<GameResponse>(`/games/${gameId}`)
            .pipe(
                catchError(error => {
                    const message = error instanceof ApiClientError
                        ? `Failed to fetch game: ${error.message}`
                        : 'Failed to fetch game';
                    return throwError(() => new Error(message));
                })
            );
    }

    /**
     * Join an existing game
     * POST /games/{game_id}/join
     */
    joinGame(gameId: string): Observable<GameResponse> {
        return this.apiClient.post<GameResponse>(`/games/${gameId}/join`, {})
            .pipe(
                catchError(error => {
                    const message = error instanceof ApiClientError
                        ? `Failed to join game: ${error.message}`
                        : 'Failed to join game';
                    return throwError(() => new Error(message));
                })
            );
    }
}
