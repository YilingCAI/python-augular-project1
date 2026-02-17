/**
 * API Types - Generated from backend Pydantic schemas
 * Source: backend/app/schemas/
 */

/**
 * User-related types
 */
export interface UserCreate {
    username: string;
    password: string;
}

export interface UserLogin {
    username: string;
    password: string;
}

export interface UserResponse {
    id: number;
    username: string;
    wins: number;
}

export interface LoginResponse {
    access_token: string;
    token_type: 'bearer';
}

/**
 * Game-related types
 */
export interface GameCreate {
    // Empty for now - uses current_user from JWT
}

export interface MoveRequest {
    game_id: string; // UUID
    move: number; // 0-8 for board index
}

export interface GameResponse {
    game_id: string; // UUID
    player1: number;
    player2: number | null;
    board: string[]; // Array of 9 strings (empty " " or "X"/"O")
    current_turn: number | null;
    winner: number | null;
    status: 'in_progress' | 'finished';
}

/**
 * API Error Response
 */
export interface ApiError {
    detail: string;
}

/**
 * Pagination metadata (for future use)
 */
export interface PaginatedResponse<T> {
    items: T[];
    total: number;
    page: number;
    size: number;
}
