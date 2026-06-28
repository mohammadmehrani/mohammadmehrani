# Extraordinary Workflow - Infrastructure Setup Script
# Run this from the repository root

$ErrorActionPreference = "Stop"
$ROOT = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  🚀 Extraordinary Workflow Setup   " -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Yellow
$prereqs = @(
    @{ Name = "Docker"; Cmd = "docker --version" },
    @{ Name = "Docker Compose"; Cmd = "docker compose version" }
)

$allOk = $true
foreach ($prereq in $prereqs) {
    try {
        Invoke-Expression $prereq.Cmd | Out-Null
        Write-Host "  ✅ $($prereq.Name) found" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ $($prereq.Name) not found" -ForegroundColor Red
        $allOk = $false
    }
}

if (-not $allOk) {
    Write-Host "❌ Prerequisites missing. Install Docker first." -ForegroundColor Red
    exit 1
}

# Step 2: Check .env
Write-Host "`n📋 Checking configuration..." -ForegroundColor Yellow
$envFile = Join-Path $ROOT "infra\.env"
if (Test-Path $envFile) {
    Write-Host "  ✅ .env file exists" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  .env file missing - creating from template" -ForegroundColor Yellow
    @"
N8N_HOST=localhost
N8N_PROTOCOL=http
WEBHOOK_URL=http://localhost:5678
GITHUB_TOKEN=your_github_token_here
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here
"@ | Set-Content -Path $envFile
    Write-Host "  ⚠️  Please edit infra\.env with your tokens" -ForegroundColor Yellow
}

# Step 3: Create Docker networks
Write-Host "`n📋 Setting up Docker network..." -ForegroundColor Yellow
$networkName = "n8n-extraordinary"
$networkExists = docker network ls --filter name=$networkName --format "{{.Name}}"
if (-not $networkExists) {
    docker network create $networkName
    Write-Host "  ✅ Network '$networkName' created" -ForegroundColor Green
} else {
    Write-Host "  ✅ Network '$networkName' already exists" -ForegroundColor Green
}

# Step 4: Create required directories
Write-Host "`n📋 Creating data directories..." -ForegroundColor Yellow
$dirs = @(
    "infra/postgres-data",
    "infra/redis-data",
    "infra/n8n-data"
)
foreach ($dir in $dirs) {
    $fullPath = Join-Path $ROOT $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  ✅ Created $dir" -ForegroundColor Green
    }
}

# Step 5: Start services
Write-Host "`n📋 Starting Docker services..." -ForegroundColor Yellow
$composeFile = Join-Path $ROOT "infra\docker-compose.yml"
docker compose -f $composeFile up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Services started successfully" -ForegroundColor Green
} else {
    Write-Host "  ❌ Failed to start services" -ForegroundColor Red
    exit 1
}

# Step 6: Wait for health
Write-Host "`n⏳ Waiting for services to be healthy..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "`n===================================" -ForegroundColor Cyan
Write-Host "  ✅ Infrastructure Ready!" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  📍 n8n:       http://localhost:5678" -ForegroundColor White
Write-Host "  📍 PostgreSQL: localhost:5432" -ForegroundColor White
Write-Host "  📍 Redis:      localhost:6379" -ForegroundColor White
Write-Host ""
Write-Host "  📋 Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open http://localhost:5678 in browser" -ForegroundColor White
Write-Host "  2. Import workflows/n8n-extraordinary-workflow.json" -ForegroundColor White
Write-Host "  3. Configure credentials (GitHub, Telegram, PostgreSQL, Redis)" -ForegroundColor White
Write-Host "  4. Activate the workflow" -ForegroundColor White
Write-Host "  5. Set GITHUB_TOKEN in GitHub repo secrets" -ForegroundColor White
Write-Host ""
