#!/usr/bin/env python3
"""
Extraordinary GitHub Profile Report Generator
Called by n8n workflow for advanced processing
"""
import json
import sys
import os
from datetime import datetime, timezone
from collections import defaultdict


def load_input_data():
    """Load data passed from n8n"""
    input_raw = os.environ.get('N8N_INPUT', '{}')
    try:
        return json.loads(input_raw)
    except json.JSONDecodeError:
        return {}


def calculate_growth_metrics(data):
    """Calculate advanced growth metrics"""
    history = data.get('history', {})
    snapshots = history.get('snapshots', [])

    if len(snapshots) < 2:
        return {
            'follower_growth_7d': 0,
            'follower_growth_30d': 0,
            'avg_daily_events': 0,
            'growth_trend': 'stable'
        }

    now = datetime.now(timezone.utc)

    # Filter last 7 and 30 days
    last_7d = [s for s in snapshots
               if (now - datetime.fromisoformat(s['timestamp'])).days <= 7]
    last_30d = [s for s in snapshots
                if (now - datetime.fromisoformat(s['timestamp'])).days <= 30]

    metrics = {
        'follower_growth_7d': (
            last_7d[-1]['followers'] - last_7d[0]['followers']
        ) if len(last_7d) >= 2 else 0,
        'follower_growth_30d': (
            last_30d[-1]['followers'] - last_30d[0]['followers']
        ) if len(last_30d) >= 2 else 0,
        'avg_daily_events': (
            sum(s.get('daily_events', 0) for s in last_7d) / max(len(last_7d), 1)
        ),
    }

    # Determine trend
    if metrics['avg_daily_events'] > 10:
        metrics['growth_trend'] = 'high'
    elif metrics['avg_daily_events'] > 5:
        metrics['growth_trend'] = 'moderate'
    elif metrics['avg_daily_events'] > 0:
        metrics['growth_trend'] = 'low'
    else:
        metrics['growth_trend'] = 'inactive'

    return metrics


def generate_activity_heatmap(analysis):
    """Generate activity pattern analysis"""
    event_types = analysis.get('event_types', {})

    # Calculate coding vs collaboration ratio
    coding_events = event_types.get('PushEvent', 0)
    collaboration_events = (
        event_types.get('PullRequestEvent', 0) +
        event_types.get('IssuesEvent', 0) +
        event_types.get('PullRequestReviewEvent', 0)
    )

    total = coding_events + collaboration_events
    coding_ratio = (coding_events / total * 100) if total > 0 else 0

    return {
        'coding_ratio': round(coding_ratio, 1),
        'collaboration_ratio': round(100 - coding_ratio, 1),
        'activity_diversity': len(event_types),
        'primary_pattern': 'coding' if coding_ratio > 60 else 'collaboration'
    }


def generate_markdown_report(stats, analysis, metrics, heatmap, insights):
    """Generate a beautiful markdown report"""
    report = []
    report.append('## 📊 Automated Activity Report')
    report.append(f'*Generated: {datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")}*\n')

    # Summary section
    report.append('### 📈 Summary')
    report.append('| Metric | Value | Status |')
    report.append('|--------|-------|--------|')
    report.append(f'| Activity Score | {analysis.get("score", 0)}/100 | {"✅ Excellent" if analysis.get("score", 0) >= 80 else "⚠️ Needs Improvement"} |')
    report.append(f'| Coding/Events Ratio | {heatmap["coding_ratio"]}% | {"💻 Code Heavy" if heatmap["coding_ratio"] > 60 else "🤝 Collaborative"} |')
    report.append(f'| Daily Average | {metrics["avg_daily_events"]:.1f} events | {"🔥 Hot" if metrics["avg_daily_events"] > 10 else "💤 Quiet"} |')
    report.append(f'| 7-Day Growth | +{metrics["follower_growth_7d"]} followers | {"📈 Growing" if metrics["follower_growth_7d"] > 0 else "➡️ Stable"} |\n')

    # Activity breakdown
    report.append('### 🎯 Activity Breakdown')
    report.append(f'- **Push Events:** {analysis.get("push_count", 0)}')
    report.append(f'- **Pull Requests:** {analysis.get("pr_count", 0)}')
    report.append(f'- **Issues:** {analysis.get("issue_count", 0)}')
    report.append(f'- **Code Reviews:** {analysis.get("review_count", 0)}\n')

    # Active repos
    top_repos = analysis.get('top_repos', {})
    if top_repos:
        report.append('### 📁 Most Active Repositories')
        for repo, count in top_repos.items():
            report.append(f'- **{repo}**: {count} events')
        report.append('')

    # Insights
    if insights:
        report.append('### 💡 Insights & Recommendations')
        for insight in insights:
            report.append(f'- {insight}')
        report.append('')

    # Footer
    report.append('---')
    report.append('*Powered by n8n Extraordinary Workflow Engine*')

    return '\n'.join(report)


def main():
    data = load_input_data()
    stats = data.get('stats', {})
    analysis = data.get('analysis', {})
    insights = data.get('insights', [])

    metrics = calculate_growth_metrics(data)
    heatmap = generate_activity_heatmap(analysis)
    report = generate_markdown_report(stats, analysis, metrics, heatmap, insights)

    # Output as JSON for n8n
    output = {
        'report': report,
        'metrics': metrics,
        'heatmap': heatmap,
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'report_lines': report.count('\n') + 1
    }

    print(json.dumps(output, indent=2))
    return 0


if __name__ == '__main__':
    sys.exit(main())
