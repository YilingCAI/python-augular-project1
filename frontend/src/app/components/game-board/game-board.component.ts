import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';

/**
 * Game Board Component
 * Reusable tic-tac-toe board display with enterprise styling
 * - Handles cell clicks and state display
 * - Accessibility features (ARIA labels)
 * - Responsive design
 */
@Component({
    selector: 'app-game-board',
    standalone: true,
    imports: [CommonModule],
    templateUrl: './game-board.component.html',
    styleUrls: ['./game-board.component.scss']
})
export class GameBoardComponent {
    @Input() board: string[] = Array(9).fill(' ');
    @Input() disabled: boolean = false;
    @Output() cellClick = new EventEmitter<number>();

    /**
     * Handle cell click
     */
    onCellClick(index: number): void {
        this.cellClick.emit(index);
    }
}
