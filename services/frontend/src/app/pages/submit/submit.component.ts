import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { ApiService, SubmissionResult, QueueStatus } from '../../api.service';

@Component({
  selector: 'app-submit',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <h1>Submit Code</h1>

    <!-- Queue Status Bar -->
    <div class="queue-bar">
      <div class="queue-stat">
        <span class="queue-label">📬 Queue</span>
        <span class="queue-value" [class.queue-busy]="queueStatus && queueStatus.messages > 5">
          {{ queueStatus ? queueStatus.messages : '—' }} pending
        </span>
      </div>
      <div class="queue-stat">
        <span class="queue-label">⚙️ Workers</span>
        <span class="queue-value">{{ queueStatus ? queueStatus.consumers : '—' }} active</span>
      </div>
      <div class="queue-stat" *ngIf="queueStatus && queueStatus.messages > 0">
        <span class="queue-label">⏱️ Est. wait</span>
        <span class="queue-value">~{{ estimatedWait() }}s</span>
      </div>
    </div>

    <div class="form-group">
      <label>Language</label>
      <select [(ngModel)]="language" class="select">
        <option value="python">Python</option>
        <option value="javascript">JavaScript</option>
        <option value="java">Java</option>
      </select>
    </div>

    <div class="form-group">
      <label>Code</label>
      <textarea
        [(ngModel)]="code"
        rows="12"
        class="code-editor"
        placeholder="Write your code here..."
        [disabled]="submitting"
      ></textarea>
    </div>

    <button (click)="submit()" class="btn-submit" [disabled]="submitting || !code.trim()">
      {{ submitting ? 'Submitting...' : '🚀 Submit' }}
    </button>

    <!-- Result Display -->
    <div *ngIf="result && !polling" class="result-card" [class]="'result-' + getResultStatus()">
      <div class="result-header">
        <span class="badge" [class]="'badge-' + getResultStatus()">
          {{ getStatusEmoji() }} {{ getResultStatus() | uppercase }}
        </span>
        <span class="result-time" *ngIf="result.results?.execution_time_ms">
          {{ result.results?.execution_time_ms }}ms
        </span>
        <span class="result-memory" *ngIf="result.results?.memory_mb">
          {{ result.results?.memory_mb }}MB
        </span>
      </div>
      <p class="result-message" *ngIf="result.results?.output">{{ result.results?.output }}</p>
      <p class="result-error" *ngIf="result.results?.error">{{ result.results?.error }}</p>
    </div>

    <div *ngIf="polling" class="polling">
      <div class="spinner"></div>
      <span>{{ result?.status === 'running' ? 'Running...' : 'Waiting in queue...' }}</span>
    </div>
  `,
  styles: [`
    h1 { color: #e0e0e0; margin-bottom: 1.5rem; }

    .queue-bar {
      display: flex; gap: 1.5rem; padding: 0.8rem 1.2rem;
      background: #16213e; border-radius: 8px; margin-bottom: 1.5rem;
      border: 1px solid #2a3a5e;
    }
    .queue-stat { display: flex; align-items: center; gap: 0.5rem; }
    .queue-label { color: #a0a0b0; font-size: 0.8rem; }
    .queue-value { color: #4ade80; font-weight: 600; font-size: 0.9rem; }
    .queue-busy { color: #fbbf24 !important; }

    .form-group { margin-bottom: 1rem; }
    label { display: block; color: #a0a0b0; margin-bottom: 0.4rem; font-weight: 500; }
    .select {
      background: #16213e; color: #e0e0e0; border: 1px solid #2a3a5e;
      padding: 0.5rem; border-radius: 6px; font-size: 0.95rem; width: 200px;
    }
    .code-editor {
      width: 100%; background: #0d1117; color: #c9d1d9; border: 1px solid #30363d;
      border-radius: 8px; padding: 1rem; font-family: 'Courier New', monospace;
      font-size: 0.9rem; resize: vertical; line-height: 1.5;
    }
    .code-editor:focus { outline: none; border-color: #e94560; }
    .btn-submit {
      background: #e94560; color: #fff; border: none; padding: 0.7rem 2rem;
      border-radius: 8px; font-size: 1rem; font-weight: 600; cursor: pointer;
      transition: background 0.2s;
    }
    .btn-submit:hover:not(:disabled) { background: #c73a52; }
    .btn-submit:disabled { opacity: 0.5; cursor: not-allowed; }

    .result-card {
      margin-top: 1.5rem; padding: 1.2rem; border-radius: 8px;
      border-left: 4px solid;
    }
    .result-passed { background: #0a2e1a; border-color: #4ade80; }
    .result-timeout { background: #2e2a0a; border-color: #fbbf24; }
    .result-oom_killed { background: #2e0a0a; border-color: #f87171; }
    .result-failed { background: #2e0a0a; border-color: #f87171; }
    .result-pending, .result-running { background: #16213e; border-color: #60a5fa; }

    .result-header { display: flex; align-items: center; gap: 1rem; }
    .badge {
      padding: 0.3rem 0.8rem; border-radius: 4px; font-weight: 700; font-size: 0.8rem;
    }
    .badge-passed { background: #166534; color: #4ade80; }
    .badge-timeout { background: #713f12; color: #fbbf24; }
    .badge-oom_killed { background: #7f1d1d; color: #f87171; }
    .badge-failed { background: #7f1d1d; color: #f87171; }
    .result-time, .result-memory { color: #a0a0b0; font-size: 0.85rem; }
    .result-message { color: #4ade80; margin: 0.8rem 0 0; }
    .result-error { color: #f87171; margin: 0.8rem 0 0; }

    .polling {
      display: flex; align-items: center; gap: 0.8rem;
      margin-top: 1.5rem; color: #60a5fa;
    }
    .spinner {
      width: 20px; height: 20px; border: 3px solid #2a3a5e;
      border-top-color: #60a5fa; border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
  `]
})
export class SubmitComponent implements OnInit, OnDestroy {
  code = '';
  language = 'python';
  problemId?: string;
  submitting = false;
  polling = false;
  result: SubmissionResult | null = null;
  queueStatus: QueueStatus | null = null;
  private pollTimer: any;
  private queueTimer: any;

  constructor(private api: ApiService, private route: ActivatedRoute) { }

  ngOnInit() {
    this.problemId = this.route.snapshot.paramMap.get('problemId') || undefined;
    this.refreshQueue();
    this.queueTimer = setInterval(() => this.refreshQueue(), 10000);
  }

  ngOnDestroy() {
    if (this.pollTimer) clearInterval(this.pollTimer);
    if (this.queueTimer) clearInterval(this.queueTimer);
  }

  refreshQueue() {
    this.api.getQueueStatus().subscribe({
      next: (s) => this.queueStatus = s,
      error: () => { }
    });
  }

  estimatedWait(): number {
    if (!this.queueStatus || this.queueStatus.consumers === 0) return 0;
    // Rough estimate: each message takes ~3s avg, divided by consumer count
    return Math.ceil((this.queueStatus.messages * 3) / this.queueStatus.consumers);
  }

  submit() {
    if (this.pollTimer) { clearInterval(this.pollTimer); this.pollTimer = null; }
    this.polling = false;
    this.submitting = true;
    this.result = null;

    this.api.submitCode({
      code: this.code,
      language: this.language,
      problem_id: this.problemId,
    }).subscribe({
      next: (res) => {
        this.result = res;
        this.submitting = false;
        this.startPolling(res.id);
      },
      error: () => {
        this.submitting = false;
      }
    });
  }

  startPolling(id: string) {
    this.polling = true;
    if (this.pollTimer) clearInterval(this.pollTimer);
    this.pollTimer = setInterval(() => {
      this.api.getSubmission(id).subscribe({
        next: (res) => {
          this.result = res;
          if (res.status !== 'pending' && res.status !== 'running') {
            this.polling = false;
            clearInterval(this.pollTimer);
            this.pollTimer = null;
          }
        }
      });
    }, 2000);
  }

  getResultStatus(): string {
    if (!this.result) return '';
    if (this.result.results?.status) return this.result.results.status;
    return this.result.status;
  }

  getStatusEmoji(): string {
    const s = this.getResultStatus();
    if (s === 'passed') return '✅';
    if (s === 'timeout') return '⏱️';
    if (s === 'oom_killed') return '💀';
    if (s === 'failed') return '❌';
    if (s === 'running') return '⏳';
    return '⏳';
  }
}
