# Test script for the n8n webhook endpoint
# Sends simulated GitHub events to test the workflow

param(
    [string]$WebhookUrl = "http://localhost:5678/webhook/github-profile-events",
    [string]$EventType = "push"
)

$events = @{
    push = @{
        headers = @{ "x-github-event" = "push"; "x-github-delivery" = [guid]::NewGuid().ToString() }
        body = @{
            ref = "refs/heads/main"
            repository = @{
                full_name = "mohammadmehrani/mohammadmehrani"
                name = "mohammadmehrani"
                owner = @{ login = "mohammadmehrani" }
            }
            sender = @{ login = "mohammadmehrani" }
            commits = @(
                @{ message = "test: workflow simulation"; sha = "abc123" }
            )
            created_at = (Get-Date -Format "o")
        }
    }
    star = @{
        headers = @{ "x-github-event" = "star"; "x-github-delivery" = [guid]::NewGuid().ToString() }
        body = @{
            action = "created"
            repository = @{
                full_name = "mohammadmehrani/mohammadmehrani"
                name = "mohammadmehrani"
                owner = @{ login = "mohammadmehrani" }
                stargazers_count = 5
            }
            sender = @{ login = "test-user"; html_url = "https://github.com/test-user" }
            starred_at = (Get-Date -Format "o")
        }
    }
    issues = @{
        headers = @{ "x-github-event" = "issues"; "x-github-delivery" = [guid]::NewGuid().ToString() }
        body = @{
            action = "opened"
            issue = @{
                title = "Test Issue"
                body = "This is a test issue from the webhook simulator"
                html_url = "https://github.com/mohammadmehrani/mohammadmehrani/issues/1"
                state = "open"
                created_at = (Get-Date -Format "o")
            }
            repository = @{
                full_name = "mohammadmehrani/mohammadmehrani"
            }
            sender = @{ login = "mohammadmehrani" }
        }
    }
}

$event = $events[$EventType]
if (-not $event) {
    Write-Host "❌ Unknown event type: $EventType" -ForegroundColor Red
    Write-Host "Available: push, star, issues" -ForegroundColor Yellow
    exit 1
}

Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  🚀 Webhook Test Simulator" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📤 Sending '$EventType' event to: $WebhookUrl" -ForegroundColor Yellow
Write-Host ""

try {
    $jsonBody = $event.body | ConvertTo-Json -Depth 10
    Write-Host "📦 Payload:" -ForegroundColor Gray
    Write-Host $jsonBody -ForegroundColor DarkGray

    $response = Invoke-RestMethod -Uri $WebhookUrl -Method Post `
        -Headers $event.headers `
        -Body $jsonBody `
        -ContentType "application/json" `
        -TimeoutSec 10

    Write-Host ""
    Write-Host "✅ Response received!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json) -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "⚠️  Request completed (webhook may not return data)" -ForegroundColor Yellow
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "💡 Tip: Check n8n execution history for workflow results" -ForegroundColor Cyan
