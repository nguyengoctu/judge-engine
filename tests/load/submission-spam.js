import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter } from 'k6/metrics';

const submissionsCreated = new Counter('submissions_created');
const submissionsFailed = new Counter('submissions_failed');

export const options = {
    scenarios: {
        // Scenario 1: Ramp up submissions
        submission_spam: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '30s', target: 5 },    // Warm up
                { duration: '1m', target: 20 },   // Ramp to 20 VUs
                { duration: '2m', target: 50 },   // Push to 50 VUs ← HPA should trigger
                { duration: '2m', target: 50 },   // Sustain
                { duration: '1m', target: 0 },    // Ramp down
            ],
        },
    },
    thresholds: {
        http_req_duration: ['p(95)<2000'],      // P95 < 2 seconds
        http_req_failed: ['rate<0.1'],          // Error rate < 10%
    },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost';
const PROBLEM_ID = __ENV.PROBLEM_ID || 'ee6ed272-dc6f-4db9-8fff-c6f6456f4760'; // Two Sum

export default function () {
    // POST submission
    const payload = JSON.stringify({
        problem_id: PROBLEM_ID,
        language: 'python',
        code: `
import time
n = int(input())

# CPU-heavy: brute-force prime counting
def is_prime(x):
    if x < 2:
        return False
    for i in range(2, int(x**0.5) + 1):
        if x % i == 0:
            return False
    return True

start = time.time()
count = sum(1 for i in range(2, max(n, 50000)) if is_prime(i))
elapsed = time.time() - start
print(f"{count} primes found in {elapsed:.2f}s")
`,
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
        },
    };

    const res = http.post(`${BASE_URL}/api/submissions`, payload, params);

    const success = check(res, {
        'submission created': (r) => r.status === 200 || r.status === 201,
        'has submission id': (r) => {
            try {
                return JSON.parse(r.body).id !== undefined;
            } catch {
                return false;
            }
        },
    });

    if (success) {
        submissionsCreated.add(1);
    } else {
        submissionsFailed.add(1);
    }

    sleep(0.5); // 0.5s between submissions per VU
}