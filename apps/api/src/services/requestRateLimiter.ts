export type RateLimitDecision =
  | { allowed: true }
  | { allowed: false; retryAfterSeconds: number };

export interface RequestRateLimiter {
  check(callerId: string, now: Date): RateLimitDecision;
}

type InMemoryRateLimiterOptions = {
  limit: number;
  windowMs: number;
};

/**
 * Bounds bursts within one running API instance. It is deliberately not
 * described as a durable quota: serverless instances do not share memory.
 */
export class InMemoryRequestRateLimiter implements RequestRateLimiter {
  private readonly attemptsByCaller = new Map<string, number[]>();

  constructor(private readonly options: InMemoryRateLimiterOptions) {}

  check(callerId: string, now: Date): RateLimitDecision {
    const current = now.getTime();
    const windowStart = current - this.options.windowMs;
    const attempts = (this.attemptsByCaller.get(callerId) ?? []).filter(
      (attempt) => attempt > windowStart,
    );

    if (attempts.length >= this.options.limit) {
      this.attemptsByCaller.set(callerId, attempts);
      const retryAfterMs = attempts[0]! + this.options.windowMs - current;
      return {
        allowed: false,
        retryAfterSeconds: Math.max(1, Math.ceil(retryAfterMs / 1000)),
      };
    }

    attempts.push(current);
    this.attemptsByCaller.set(callerId, attempts);
    return { allowed: true };
  }
}
