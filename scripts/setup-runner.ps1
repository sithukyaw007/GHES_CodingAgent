# ============================================================================
# GitHub Actions Self-Hosted Runner - One-Time Software Setup (Windows)
# ============================================================================
# This script installs all required software on a Windows self-hosted runner.
# Run this script once on each runner machine to pre-install all dependencies.
#
# Usage:
#   .\setup-runner.ps1
#   (Run PowerShell as Administrator)
#
# What gets installed:
#   - GitHub CLI (gh)
#   - Node.js 22.x
#   - Python 3.x
#   - uv/uvx (Python package installer)
#   - GitHub Copilot CLI (@github/copilot)
# ============================================================================

# Require Administrator privileges
#Requires -RunAsAdministrator

# Versions
$GH_VERSION = "2.62.0"
$NODE_VERSION = "22"
$PYTHON_VERSION = "3.12.0"
$COPILOT_VERSION = "0.0.352"

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║  GitHub Actions Runner - Software Installation Script         ║" -ForegroundColor Blue
Write-Host "║  (Windows Version)                                             ║" -ForegroundColor Blue
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Check for Administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "   Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Helper Functions
# ============================================================================

function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

function Download-File {
    param(
        [string]$Url,
        [string]$Output
    )
    
    Write-Host "📥 Downloading from: $Url" -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Url -OutFile $Output -UseBasicParsing
}

# ============================================================================
# 1. Install GitHub CLI
# ============================================================================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "1️⃣  Installing GitHub CLI (gh) v$GH_VERSION" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

if (Test-CommandExists gh) {
    $installedVersion = (gh --version | Select-Object -First 1) -replace '.*\s(\d+\.\d+\.\d+).*', '$1'
    Write-Host "✅ GitHub CLI already installed: v$installedVersion" -ForegroundColor Green
} else {
    Write-Host "📥 Downloading GitHub CLI..." -ForegroundColor Cyan
    $ghUrl = "https://github.com/cli/cli/releases/download/v$GH_VERSION/gh_${GH_VERSION}_windows_amd64.msi"
    $ghInstaller = "$env:TEMP\gh_installer.msi"
    
    Download-File -Url $ghUrl -Output $ghInstaller
    
    Write-Host "📦 Installing GitHub CLI..." -ForegroundColor Cyan
    Start-Process msiexec.exe -ArgumentList "/i `"$ghInstaller`" /qn /norestart" -Wait -NoNewWindow
    
    Write-Host "🧹 Cleaning up..." -ForegroundColor Cyan
    Remove-Item $ghInstaller -Force
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    Write-Host "✅ GitHub CLI installed successfully" -ForegroundColor Green
    gh --version
}
Write-Host ""

# ============================================================================
# 2. Install Node.js 22.x
# ============================================================================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "2️⃣  Installing Node.js $NODE_VERSION.x" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

if (Test-CommandExists node) {
    $installedNodeVersion = node --version
    $nodeMajorVersion = $installedNodeVersion -replace 'v(\d+)\..*', '$1'
    
    if ($nodeMajorVersion -eq $NODE_VERSION) {
        Write-Host "✅ Node.js $NODE_VERSION.x already installed: $installedNodeVersion" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Node.js $installedNodeVersion found, but version $NODE_VERSION.x is required" -ForegroundColor Yellow
        Write-Host "📥 Installing Node.js $NODE_VERSION.x..." -ForegroundColor Cyan
        
        # Download and install Node.js
        $nodeUrl = "https://nodejs.org/dist/latest-v$NODE_VERSION.x/node-v$NODE_VERSION-x64.msi"
        $nodeInstaller = "$env:TEMP\node_installer.msi"
        
        Download-File -Url $nodeUrl -Output $nodeInstaller
        
        Write-Host "📦 Installing Node.js..." -ForegroundColor Cyan
        Start-Process msiexec.exe -ArgumentList "/i `"$nodeInstaller`" /qn /norestart" -Wait -NoNewWindow
        
        Write-Host "🧹 Cleaning up..." -ForegroundColor Cyan
        Remove-Item $nodeInstaller -Force
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Write-Host "✅ Node.js installed successfully" -ForegroundColor Green
        node --version
        npm --version
    }
} else {
    Write-Host "📥 Installing Node.js $NODE_VERSION.x..." -ForegroundColor Cyan
    
    # Find the latest version in the v22.x line
    $nodeUrl = "https://nodejs.org/dist/latest-v$NODE_VERSION.x/"
    $nodeVersionPage = Invoke-WebRequest -Uri $nodeUrl -UseBasicParsing
    $latestMsi = ($nodeVersionPage.Links | Where-Object { $_.href -match "node-v$NODE_VERSION.*-x64.msi" } | Select-Object -First 1).href
    
    if (-not $latestMsi) {
        Write-Host "❌ Could not find Node.js $NODE_VERSION.x installer" -ForegroundColor Red
        Write-Host "   Please install manually from https://nodejs.org/" -ForegroundColor Yellow
        exit 1
    }
    
    $nodeInstaller = "$env:TEMP\node_installer.msi"
    Download-File -Url "$nodeUrl$latestMsi" -Output $nodeInstaller
    
    Write-Host "📦 Installing Node.js..." -ForegroundColor Cyan
    Start-Process msiexec.exe -ArgumentList "/i `"$nodeInstaller`" /qn /norestart" -Wait -NoNewWindow
    
    Write-Host "🧹 Cleaning up..." -ForegroundColor Cyan
    Remove-Item $nodeInstaller -Force
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    Write-Host "✅ Node.js installed successfully" -ForegroundColor Green
    node --version
    npm --version
}
Write-Host ""

# ============================================================================
# 3. Install Python 3.x
# ============================================================================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "3️⃣  Installing Python 3.x" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

if (Test-CommandExists python) {
    $installedPythonVersion = (python --version 2>&1) -replace 'Python\s+(\d+\.\d+\.\d+).*', '$1'
    Write-Host "✅ Python 3 already installed: v$installedPythonVersion" -ForegroundColor Green
} else {
    Write-Host "📥 Downloading Python $PYTHON_VERSION..." -ForegroundColor Cyan
    
    $pythonUrl = "https://www.python.org/ftp/python/$PYTHON_VERSION/python-$PYTHON_VERSION-amd64.exe"
    $pythonInstaller = "$env:TEMP\python_installer.exe"
    
    Download-File -Url $pythonUrl -Output $pythonInstaller
    
    Write-Host "📦 Installing Python..." -ForegroundColor Cyan
    Start-Process $pythonInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait -NoNewWindow
    
    Write-Host "🧹 Cleaning up..." -ForegroundColor Cyan
    Remove-Item $pythonInstaller -Force
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    Write-Host "✅ Python 3 installed successfully" -ForegroundColor Green
    python --version
    pip --version
}
Write-Host ""

# ============================================================================
# 4. Install uv/uvx
# ============================================================================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "4️⃣  Installing uv/uvx (Python package installer)" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

if (Test-CommandExists uv) {
    $installedUvVersion = (uv --version 2>&1) -replace '.*\s+(\d+\.\d+\.\d+).*', '$1'
    Write-Host "✅ uv already installed: v$installedUvVersion" -ForegroundColor Green
} else {
    Write-Host "📥 Installing uv..." -ForegroundColor Cyan
    python -m pip install --upgrade pip
    pip install uv
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    Write-Host "✅ uv installed successfully" -ForegroundColor Green
    uv --version
}
Write-Host ""

# ============================================================================
# 5. Install GitHub Copilot CLI
# ============================================================================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "5️⃣  Installing GitHub Copilot CLI v$COPILOT_VERSION" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

if (Test-CommandExists copilot) {
    $installedCopilotVersion = (copilot --version 2>&1 | Select-Object -First 1) -replace '.*\s+(\d+\.\d+\.\d+).*', '$1'
    Write-Host "✅ GitHub Copilot CLI already installed: v$installedCopilotVersion" -ForegroundColor Green
    
    if ($installedCopilotVersion -ne $COPILOT_VERSION) {
        Write-Host "⚠️  Upgrading to v$COPILOT_VERSION..." -ForegroundColor Yellow
        npm install -g "@github/copilot@$COPILOT_VERSION"
        Write-Host "✅ Upgraded successfully" -ForegroundColor Green
    }
} else {
    Write-Host "📥 Installing GitHub Copilot CLI..." -ForegroundColor Cyan
    npm install -g "@github/copilot@$COPILOT_VERSION"
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    Write-Host "✅ GitHub Copilot CLI installed successfully" -ForegroundColor Green
    copilot --version
}
Write-Host ""

# ============================================================================
# Summary
# ============================================================================
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                  ✅ Installation Complete!                     ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Installed Software Summary:" -ForegroundColor Blue
Write-Host ""

# Refresh PATH one final time
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# GitHub CLI
if (Test-CommandExists gh) {
    $ghVersion = (gh --version | Select-Object -First 1)
    Write-Host "✅ GitHub CLI:      $ghVersion" -ForegroundColor Green
} else {
    Write-Host "❌ GitHub CLI:      Not installed" -ForegroundColor Red
}

# Node.js
if (Test-CommandExists node) {
    $nodeVersion = node --version
    $npmVersion = npm --version
    Write-Host "✅ Node.js:         $nodeVersion" -ForegroundColor Green
    Write-Host "✅ npm:             $npmVersion" -ForegroundColor Green
} else {
    Write-Host "❌ Node.js:         Not installed" -ForegroundColor Red
}

# Python
if (Test-CommandExists python) {
    $pythonVersion = python --version 2>&1
    $pipVersion = (pip --version 2>&1) -replace '.*\s+(\d+\.\d+\.\d+).*', '$1'
    Write-Host "✅ Python:          $pythonVersion" -ForegroundColor Green
    Write-Host "✅ pip:             $pipVersion" -ForegroundColor Green
} else {
    Write-Host "❌ Python:          Not installed" -ForegroundColor Red
}

# uv
if (Test-CommandExists uv) {
    $uvVersion = uv --version 2>&1
    Write-Host "✅ uv:              $uvVersion" -ForegroundColor Green
} else {
    Write-Host "❌ uv:              Not installed" -ForegroundColor Red
}

# Copilot CLI
if (Test-CommandExists copilot) {
    $copilotVersion = copilot --version 2>&1 | Select-Object -First 1
    Write-Host "✅ Copilot CLI:     $copilotVersion" -ForegroundColor Green
} else {
    Write-Host "❌ Copilot CLI:     Not installed" -ForegroundColor Red
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🎯 Next Steps:" -ForegroundColor Blue
Write-Host ""
Write-Host "1. Verify all software versions match your requirements"
Write-Host "2. Ensure the runner service is configured correctly"
Write-Host "3. Test the runner with a sample workflow"
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Blue
Write-Host "   - Deployment Guide: docs\DEPLOYMENT.md"
Write-Host "   - GHES Setup: docs\GHES-SETUP.md"
Write-Host "   - Troubleshooting: docs\TROUBLESHOOTING.md"
Write-Host ""
Write-Host "All done! Your runner is ready to execute workflows." -ForegroundColor Green
