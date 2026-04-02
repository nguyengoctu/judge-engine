import { Component } from '@angular/core';
import { RouterOutlet, RouterLink } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink],
  template: `
    <nav class="navbar">
      <a routerLink="/" class="logo">⚡ Judge-Engine</a>
      <div class="nav-links">
        <a routerLink="/">Problems</a>
        <a routerLink="/submit">Submit</a>
      </div>
    </nav>
    <main class="container">
      <router-outlet></router-outlet>
    </main>
  `,
  styles: [`
    .navbar {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 1rem 2rem;
      background: #1a1a2e;
      border-bottom: 2px solid #16213e;
    }
    .logo {
      font-size: 1.4rem;
      font-weight: 700;
      color: #e94560;
      text-decoration: none;
    }
    .nav-links a {
      color: #a0a0b0;
      text-decoration: none;
      margin-left: 1.5rem;
      font-weight: 500;
      transition: color 0.2s;
    }
    .nav-links a:hover { color: #fff; }
    .container {
      max-width: 900px;
      margin: 2rem auto;
      padding: 0 1rem;
    }
  `]
})
export class AppComponent { }
