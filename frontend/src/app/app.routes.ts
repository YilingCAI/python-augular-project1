import { Routes } from '@angular/router';
import { CreateGameComponent } from './components/create-game/create-game.component';
import { HomepageComponent } from './components/homepage/homepage.component';
import { JoinGameComponent } from './components/join-game/join-game.component';
import { LoginComponent } from './components/login/login.component';
import { SignupComponent } from './components/signup/signup.component';
import { AuthGuard } from './core/auth.guard';

export const routes: Routes = [
    {
        path: '',
        redirectTo: '/login',
        pathMatch: 'full'
    },
    {
        path: 'login',
        component: LoginComponent
    },
    {
        path: 'signup',
        component: SignupComponent
    },
    {
        path: 'homepage',
        component: HomepageComponent,
        canActivate: [AuthGuard]
    },
    {
        path: 'game',
        children: [
            {
                path: 'create',
                component: CreateGameComponent,
                canActivate: [AuthGuard]
            },
            {
                path: 'join',
                component: JoinGameComponent,
                canActivate: [AuthGuard]
            }
        ]
    },
    {
        path: '**',
        redirectTo: '/login'
    }
];
