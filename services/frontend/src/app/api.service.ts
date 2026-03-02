import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface ProblemSummary {
    id: string;
    title: string;
    level: string;
    tags: string[];
}

export interface ProblemDetail {
    id: string;
    title: string;
    question: string;
    level: string;
    tags: string[];
    codeStubs: { [key: string]: string };
}

export interface SubmissionCreate {
    code: string;
    language: string;
    problem_id?: string;
}

export interface SubmissionResult {
    id: string;
    status: string;
    code?: string;
    language?: string;
    results?: {
        status: string;
        execution_time_ms: number;
        memory_mb: number;
        output?: string;
        error?: string;
    };
    execution_time?: number;
    memory_used?: number;
    submitted_at?: string;
}

export interface QueueStatus {
    queue: string;
    messages: number;
    consumers: number;
    error?: string;
}

@Injectable({ providedIn: 'root' })
export class ApiService {
    private baseUrl = '/api';

    constructor(private http: HttpClient) { }

    getProblems(): Observable<ProblemSummary[]> {
        return this.http.get<ProblemSummary[]>(`${this.baseUrl}/problems`);
    }

    getProblem(id: string): Observable<ProblemDetail> {
        return this.http.get<ProblemDetail>(`${this.baseUrl}/problems/${id}`);
    }

    submitCode(body: SubmissionCreate): Observable<SubmissionResult> {
        return this.http.post<SubmissionResult>(`${this.baseUrl}/submissions`, body);
    }

    getSubmission(id: string): Observable<SubmissionResult> {
        return this.http.get<SubmissionResult>(`${this.baseUrl}/submissions/${id}`);
    }

    getQueueStatus(): Observable<QueueStatus> {
        return this.http.get<QueueStatus>(`${this.baseUrl}/queue/status`);
    }
}
