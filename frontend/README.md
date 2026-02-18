# Frontend README

Angular SPA with TypeScript and Tailwind CSS.

## Quick Start

```bash
# Install dependencies
cd frontend
npm install

# Run locally
make frontend
# or
npm start

# Visit http://localhost:4200
```

## Project Structure

```
frontend/
├── README.md                 # This file
├── package.json              # npm dependencies
├── package-lock.json         # Locked versions
├── angular.json              # Angular CLI config
├── tsconfig.json             # TypeScript base config
├── tsconfig.app.json         # TypeScript app config
├── tsconfig.spec.json        # TypeScript spec config
├── postcss.config.mjs        # PostCSS config (Tailwind)
├── tailwind.config.js        # Tailwind CSS config
│
├── src/
│   ├── index.html            # Entry HTML
│   ├── main.ts               # Bootstrap Angular
│   ├── polyfills.ts          # Browser polyfills
│   ├── styles.css            # Global styles
│   │
│   └── app/
│       ├── app.component.ts           # Root component
│       ├── app.component.html         # Root template
│       ├── app.routes.ts              # Route definitions
│       │
│       ├── components/               # Feature components
│       │   ├── login/
│       │   ├── register/
│       │   ├── dashboard/
│       │   ├── game/
│       │   └── shared/               # Shared UI components
│       │
│       ├── services/                 # API & state services
│       │   ├── api.service.ts       # Base API client
│       │   ├── auth.service.ts      # Authentication
│       │   ├── game.service.ts      # Game operations
│       │   └── user.service.ts      # User operations
│       │
│       ├── core/                    # Guards & interceptors
│       │   ├── auth.guard.ts        # Route protection
│       │   └── http.interceptor.ts  # HTTP token injection
│       │
│       └── types/                   # TypeScript interfaces
│           ├── auth.types.ts
│           └── game.types.ts
│
├── public/                   # Static assets
│   ├── favicon.ico
│   └── assets/
│
└── Dockerfile                # Container image
```

## Technologies

- **Framework**: Angular 19
- **Language**: TypeScript 5.6
- **Styling**: Tailwind CSS 4
- **HTTP**: HttpClient + RxJS
- **Routing**: Angular Router
- **Forms**: Reactive Forms
- **Testing**: Jasmine + Karma
- **Build**: Webpack (via Angular CLI)

## Running

### Development Server
```bash
npm start
# or
ng serve --open

# Available at http://localhost:4200
```

### Production Build
```bash
npm run build
# or
ng build --configuration production

# Output: dist/myproject/
```

### Run Tests
```bash
npm test
# or
ng test
```

### Lint & Format
```bash
# Lint
ng lint

# Format
npm run format
# or
ng format
```

## Project Features

### Authentication
- User registration and login
- JWT token storage and refresh
- HTTP interceptor for automatic token injection
- Route guards for protected pages

### Game Management
- Create and join games
- Real-time game board interaction
- Win/loss tracking
- Game history

### UI Components
- Responsive design (mobile, tablet, desktop)
- Tailwind CSS styling
- Error messages and loading states
- Navigation menu

### State Management
- Services with RxJS BehaviorSubjects
- Observable patterns throughout
- Centralized auth state
- Game state management

## Configuration

### Environment Variables
```bash
# src/environments/environment.ts (development)
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8000',
};

# src/environments/environment.prod.ts (production)
export const environment = {
  production: true,
  apiUrl: 'https://api.example.com',
};
```

### Tailwind Configuration
```js
// tailwind.config.js
module.exports = {
  content: ['./src/**/*.{html,ts}'],
  theme: {
    extend: {},
  },
  plugins: [],
};
```

## API Integration

### Example Service
```typescript
// app/services/game.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class GameService {
  constructor(private http: HttpClient) {}

  getGames(): Observable<Game[]> {
    return this.http.get<Game[]>('/api/games');
  }

  createGame(): Observable<Game> {
    return this.http.post<Game>('/api/games', {});
  }
}
```

### Using in Component
```typescript
// app/components/dashboard/dashboard.component.ts
import { Component, OnInit } from '@angular/core';
import { GameService } from '../../services/game.service';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
})
export class DashboardComponent implements OnInit {
  games$ = this.gameService.getGames();

  constructor(private gameService: GameService) {}

  ngOnInit() {
    // Observable is handled in template with async pipe
  }
}
```

### Template Usage
```html
<!-- dashboard.component.html -->
<div *ngFor="let game of (games$ | async) as games">
  <p>{{ game.id }}</p>
</div>
```

## Component Structure

### Smart Component (Container)
```typescript
@Component({
  selector: 'app-dashboard',
  template: `<app-game-list [games]="games$ | async"></app-game-list>`,
})
export class DashboardComponent implements OnInit {
  games$: Observable<Game[]>;

  constructor(private gameService: GameService) {}

  ngOnInit() {
    this.games$ = this.gameService.getGames();
  }
}
```

### Dumb Component (Presentational)
```typescript
@Component({
  selector: 'app-game-list',
  template: `<div *ngFor="let game of games">...</div>`,
})
export class GameListComponent {
  @Input() games: Game[] = [];
  @Output() gameSelected = new EventEmitter<Game>();
}
```

## Routing

### Define Routes
```typescript
// app/app.routes.ts
import { Routes } from '@angular/router';
import { LoginComponent } from './components/login/login.component';
import { DashboardComponent } from './components/dashboard/dashboard.component';
import { AuthGuard } from './core/auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  {
    path: 'dashboard',
    component: DashboardComponent,
    canActivate: [AuthGuard],
  },
];
```

### Navigate
```typescript
constructor(private router: Router) {}

goToDashboard() {
  this.router.navigate(['/dashboard']);
}
```

## Authentication Flow

### Login
```typescript
login(email: string, password: string) {
  this.authService.login(email, password).subscribe({
    next: (response) => {
      localStorage.setItem('token', response.access_token);
      this.router.navigate(['/dashboard']);
    },
    error: (error) => {
      console.error('Login failed', error);
    },
  });
}
```

### HTTP Interceptor
```typescript
// app/core/http.interceptor.ts
@Injectable()
export class HttpInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler) {
    const token = localStorage.getItem('token');
    if (token) {
      req = req.clone({
        setHeaders: {
          Authorization: `Bearer ${token}`,
        },
      });
    }
    return next.handle(req);
  }
}
```

## Testing

### Unit Test Example
```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { GameComponent } from './game.component';
import { GameService } from '../../services/game.service';

describe('GameComponent', () => {
  let component: GameComponent;
  let fixture: ComponentFixture<GameComponent>;
  let gameService: jasmine.SpyObj<GameService>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [GameComponent],
      providers: [
        { provide: GameService, useValue: jasmine.createSpyObj('GameService', ['getGame']) },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(GameComponent);
    component = fixture.componentInstance;
    gameService = TestBed.inject(GameService) as jasmine.SpyObj<GameService>;
  });

  it('should display game', () => {
    gameService.getGame.and.returnValue(of({ id: '1', status: 'active' }));
    fixture.detectChanges();
    expect(component.game).toBeDefined();
  });
});
```

### Run Tests
```bash
npm test
npm test -- --watch=false   # Run once and exit
npm test -- --code-coverage # With coverage report
```

## Building for Production

### Build
```bash
npm run build
# or
ng build --configuration production
```

### Build Output
```
dist/myproject/
├── index.html
├── main.*.js        # Main bundle
├── polyfills.*.js   # Polyfills
├── styles.*.css     # Compiled Tailwind
└── assets/
```

### Docker Build
```bash
# Multistage build
docker build -t myproject-frontend:local .

# Run in container
docker run -p 80:80 myproject-frontend:local
```

## Performance Optimization

1. **Lazy Load Modules**
```typescript
const routes: Routes = [
  {
    path: 'games',
    loadChildren: () => import('./games/games.module').then(m => m.GamesModule)
  }
];
```

2. **Change Detection Strategy**
```typescript
@Component({
  selector: 'app-game-list',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
```

3. **Unsubscribe from Observables**
```typescript
private destroy$ = new Subject<void>();

ngOnInit() {
  this.data$.pipe(takeUntil(this.destroy$)).subscribe(...);
}

ngOnDestroy() {
  this.destroy$.next();
  this.destroy$.complete();
}
```

## Troubleshooting

### Dependencies Not Installing
```bash
rm -rf node_modules package-lock.json
npm install
```

### Port 4200 Already in Use
```bash
lsof -i :4200
kill -9 <PID>
```

### Template Errors
```bash
# Check for typos in component names
# Verify imports are correct
# Use ng lint to check
```

### Build Fails
```bash
npm run clean  # If available
npm install
npm run build
```

## Deployment

### Build Docker Image
```bash
make docker-build ENV=staging IMAGE_TAG=v1.0.0
```

### Deploy to ECS
```bash
make deploy ENV=staging IMAGE_TAG=v1.0.0
```

### Visit Application
```
https://myapp.example.com
```

## Further Reading

- [Angular Docs](https://angular.io/docs/)
- [TypeScript Docs](https://www.typescriptlang.org/docs/)
- [Tailwind CSS Docs](https://tailwindcss.com/docs/)
- [RxJS Docs](https://rxjs.dev/)
- [Angular Testing](https://angular.io/guide/testing/)

## Related Documentation

- [README.md](../README.md) - Project overview
- [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) - System design
- [../backend/README.md](../backend/README.md) - Backend docs
- [../infra/README.md](../infra/README.md) - Infrastructure docs
