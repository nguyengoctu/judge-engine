import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ApiService, ProblemSummary } from '../../api.service';

@Component({
    selector: 'app-home',
    standalone: true,
    imports: [CommonModule, RouterLink],
    template: `
    <h1>Coding Problems</h1>
    <div class="problem-list">
      <div *ngFor="let p of problems" class="problem-card">
        <div class="problem-header">
          <span class="level" [class]="p.level">{{ p.level }}</span>
          <h3>{{ p.title }}</h3>
        </div>
        <div class="tags">
          <span *ngFor="let t of p.tags" class="tag">{{ t }}</span>
        </div>
        <a [routerLink]="['/submit', p.id]" class="btn">Solve →</a>
      </div>
    </div>
    <p *ngIf="problems.length === 0 && !loading" class="empty">No problems found.</p>
    <p *ngIf="loading" class="empty">Loading...</p>
  `,
    styles: [`
    h1 { color: #e0e0e0; margin-bottom: 1.5rem; }
    .problem-list { display: flex; flex-direction: column; gap: 1rem; }
    .problem-card {
      background: #16213e;
      border-radius: 8px;
      padding: 1.2rem 1.5rem;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
      transition: transform 0.15s;
    }
    .problem-card:hover { transform: translateX(4px); }
    .problem-header { display: flex; align-items: center; gap: 0.8rem; flex: 1; }
    .problem-header h3 { color: #e0e0e0; margin: 0; font-size: 1.1rem; }
    .level {
      padding: 0.2rem 0.6rem;
      border-radius: 4px;
      font-size: 0.75rem;
      font-weight: 600;
      text-transform: uppercase;
    }
    .easy { background: #0a3d2a; color: #4ade80; }
    .medium { background: #3d2a0a; color: #fbbf24; }
    .hard { background: #3d0a0a; color: #f87171; }
    .tags { display: flex; gap: 0.4rem; }
    .tag {
      background: #0f3460;
      color: #7ca0d4;
      padding: 0.15rem 0.5rem;
      border-radius: 4px;
      font-size: 0.75rem;
    }
    .btn {
      background: #e94560;
      color: #fff;
      padding: 0.5rem 1rem;
      border-radius: 6px;
      text-decoration: none;
      font-weight: 600;
      font-size: 0.85rem;
      white-space: nowrap;
      transition: background 0.2s;
    }
    .btn:hover { background: #c73a52; }
    .empty { color: #888; text-align: center; margin-top: 3rem; }
  `]
})
export class HomeComponent implements OnInit {
    problems: ProblemSummary[] = [];
    loading = true;

    constructor(private api: ApiService) { }

    ngOnInit() {
        this.api.getProblems().subscribe({
            next: (data) => { this.problems = data; this.loading = false; },
            error: () => { this.loading = false; }
        });
    }
}
