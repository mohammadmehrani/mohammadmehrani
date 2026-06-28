/**
 * Extraordinary Workflow - Webhook Handler
 * Helper module for n8n Function nodes
 * Processes GitHub webhook events and formats data
 */

class WebhookHandler {
  constructor(event) {
    this.event = event;
    this.eventType = event.headers?.['x-github-event'] || 'manual';
    this.payload = event.body || event;
    this.timestamp = new Date().toISOString();
  }

  classify() {
    const classifications = {
      push: { category: 'code', weight: 2 },
      issues: { category: 'management', weight: 3 },
      issue_comment: { category: 'communication', weight: 2 },
      pull_request: { category: 'code', weight: 5 },
      pull_request_review: { category: 'review', weight: 4 },
      star: { category: 'social', weight: 1 },
      fork: { category: 'social', weight: 3 },
      watch: { category: 'social', weight: 1 },
      create: { category: 'code', weight: 1 },
      delete: { category: 'code', weight: 1 },
      release: { category: 'release', weight: 4 },
      member: { category: 'social', weight: 2 },
    };
    return classifications[this.eventType] || { category: 'other', weight: 1 };
  }

  extractRepo() {
    return this.payload?.repository?.full_name || 'unknown';
  }

  extractSender() {
    return this.payload?.sender?.login || 'unknown';
  }

  isSignificant() {
    const cls = this.classify();
    return cls.weight >= 3;
  }

  summarize() {
    const cls = this.classify();
    return {
      event: this.eventType,
      category: cls.category,
      weight: cls.weight,
      repo: this.extractRepo(),
      sender: this.extractSender(),
      significant: this.isSignificant(),
      timestamp: this.timestamp,
    };
  }
}

module.exports = { WebhookHandler };
