#!/bin/bash
# ============================================================================
# GitHub Actions Self-Hosted Runner - One-Time Software Setup
# ============================================================================
# This script installs all required software on a self-hosted runner.
# Run this script once on each runner VM to pre-install all dependencies.
#
# Usage:
#   sudo ./setup-runner.sh
#
# What gets installed:
#   - GitHub CLI (gh)
#   - Node.js 22.x
#   - Python 3.x
#   - uv/uvx (Python package installer)
#   - GitHub Copilot CLI (@github/copilot)
# ============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Versions
GH_VERSION="2.62.0"
NODE_VERSION="22"
COPILOT_VERSION="0.0.352"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  GitHub Actions Runner - Software Installation Script         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Running as root. This is recommended for system-wide installation.${NC}"
    SUDO=""
else
    echo -e "${YELLOW}⚠️  Not running as root. Will use sudo for system commands.${NC}"
    SUDO="sudo"
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    echo -e "${RED}❌ Cannot detect OS. /etc/os-release not found.${NC}"
    exit 1
fi

echo -e "${BLUE}📋 System Information:${NC}"
echo "   - OS: $OS $OS_VERSION"
echo "   - Architecture: $(uname -m)"
echo ""

# ============================================================================
# 1. Install GitHub CLI
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}1️⃣  Installing GitHub CLI (gh) v${GH_VERSION}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v gh &> /dev/null; then
    INSTALLED_VERSION=$(gh --version | head -n1 | awk '{print $3}')
    echo -e "${GREEN}✅ GitHub CLI already installed: v${INSTALLED_VERSION}${NC}"
else
    echo "📥 Downloading GitHub CLI..."
    cd /tmp
    curl -L -o gh.tar.gz "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz"
    
    echo "📦 Extracting..."
    tar -xzf gh.tar.gz
    
    echo "🔧 Installing to /usr/local/bin..."
    $SUDO mv gh_${GH_VERSION}_linux_amd64/bin/gh /usr/local/bin/
    $SUDO chmod +x /usr/local/bin/gh
    
    echo "🧹 Cleaning up..."
    rm -rf gh.tar.gz gh_${GH_VERSION}_linux_amd64
    
    echo -e "${GREEN}✅ GitHub CLI installed successfully${NC}"
    gh --version
fi
echo ""

# ============================================================================
# 2. Install Node.js 22.x
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}2️⃣  Installing Node.js ${NODE_VERSION}.x${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v node &> /dev/null; then
    INSTALLED_NODE_VERSION=$(node --version)
    NODE_MAJOR_VERSION=$(echo $INSTALLED_NODE_VERSION | cut -d. -f1 | sed 's/v//')
    
    if [ "$NODE_MAJOR_VERSION" == "$NODE_VERSION" ]; then
        echo -e "${GREEN}✅ Node.js ${NODE_VERSION}.x already installed: ${INSTALLED_NODE_VERSION}${NC}"
    else
        echo -e "${YELLOW}⚠️  Node.js ${INSTALLED_NODE_VERSION} found, but version ${NODE_VERSION}.x is required${NC}"
        echo "📥 Installing Node.js ${NODE_VERSION}.x..."
        
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
            curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | $SUDO -E bash -
            $SUDO apt-get install -y nodejs
        elif [ "$OS" == "rhel" ] || [ "$OS" == "centos" ] || [ "$OS" == "fedora" ]; then
            curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | $SUDO bash -
            $SUDO yum install -y nodejs
        else
            echo -e "${RED}❌ Unsupported OS for automatic Node.js installation: $OS${NC}"
            echo "Please install Node.js ${NODE_VERSION}.x manually from https://nodejs.org/"
            exit 1
        fi
        
        echo -e "${GREEN}✅ Node.js installed successfully${NC}"
        node --version
        npm --version
    fi
else
    echo "📥 Installing Node.js ${NODE_VERSION}.x..."
    
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | $SUDO -E bash -
        $SUDO apt-get install -y nodejs
    elif [ "$OS" == "rhel" ] || [ "$OS" == "centos" ] || [ "$OS" == "fedora" ]; then
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | $SUDO bash -
        $SUDO yum install -y nodejs
    else
        echo -e "${RED}❌ Unsupported OS for automatic Node.js installation: $OS${NC}"
        echo "Please install Node.js ${NODE_VERSION}.x manually from https://nodejs.org/"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Node.js installed successfully${NC}"
    node --version
    npm --version
fi
echo ""

# ============================================================================
# 3. Install Python 3.x
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}3️⃣  Installing Python 3.x${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v python3 &> /dev/null; then
    INSTALLED_PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    echo -e "${GREEN}✅ Python 3 already installed: v${INSTALLED_PYTHON_VERSION}${NC}"
else
    echo "📥 Installing Python 3..."
    
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        $SUDO apt-get update
        $SUDO apt-get install -y python3 python3-pip python3-venv
    elif [ "$OS" == "rhel" ] || [ "$OS" == "centos" ] || [ "$OS" == "fedora" ]; then
        $SUDO yum install -y python3 python3-pip
    else
        echo -e "${RED}❌ Unsupported OS for automatic Python installation: $OS${NC}"
        echo "Please install Python 3.x manually from https://www.python.org/"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Python 3 installed successfully${NC}"
    python3 --version
    pip3 --version
fi
echo ""

# ============================================================================
# 4. Install uv/uvx
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}4️⃣  Installing uv/uvx (Python package installer)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v uv &> /dev/null; then
    INSTALLED_UV_VERSION=$(uv --version | awk '{print $2}')
    echo -e "${GREEN}✅ uv already installed: v${INSTALLED_UV_VERSION}${NC}"
else
    echo "📥 Installing uv..."
    pip3 install --upgrade pip
    pip3 install uv
    
    echo -e "${GREEN}✅ uv installed successfully${NC}"
    uv --version
fi
echo ""

# ============================================================================
# 5. Install GitHub Copilot CLI
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}5️⃣  Installing GitHub Copilot CLI v${COPILOT_VERSION}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v copilot &> /dev/null; then
    INSTALLED_COPILOT_VERSION=$(copilot --version 2>&1 | head -n1 | awk '{print $NF}')
    echo -e "${GREEN}✅ GitHub Copilot CLI already installed: v${INSTALLED_COPILOT_VERSION}${NC}"
    
    if [ "$INSTALLED_COPILOT_VERSION" != "$COPILOT_VERSION" ]; then
        echo -e "${YELLOW}⚠️  Upgrading to v${COPILOT_VERSION}...${NC}"
        npm install -g @github/copilot@${COPILOT_VERSION}
        echo -e "${GREEN}✅ Upgraded successfully${NC}"
    fi
else
    echo "📥 Installing GitHub Copilot CLI..."
    npm install -g @github/copilot@${COPILOT_VERSION}
    
    echo -e "${GREEN}✅ GitHub Copilot CLI installed successfully${NC}"
    copilot --version
fi
echo ""

# ============================================================================
# Summary
# ============================================================================
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  ✅ Installation Complete!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📋 Installed Software Summary:${NC}"
echo ""

# GitHub CLI
if command -v gh &> /dev/null; then
    echo -e "${GREEN}✅ GitHub CLI:      $(gh --version | head -n1)${NC}"
else
    echo -e "${RED}❌ GitHub CLI:      Not installed${NC}"
fi

# Node.js
if command -v node &> /dev/null; then
    echo -e "${GREEN}✅ Node.js:         $(node --version)${NC}"
    echo -e "${GREEN}✅ npm:             $(npm --version)${NC}"
else
    echo -e "${RED}❌ Node.js:         Not installed${NC}"
fi

# Python
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}✅ Python:          $(python3 --version)${NC}"
    echo -e "${GREEN}✅ pip:             $(pip3 --version | awk '{print $2}')${NC}"
else
    echo -e "${RED}❌ Python:          Not installed${NC}"
fi

# uv
if command -v uv &> /dev/null; then
    echo -e "${GREEN}✅ uv:              $(uv --version)${NC}"
else
    echo -e "${RED}❌ uv:              Not installed${NC}"
fi

# Copilot CLI
if command -v copilot &> /dev/null; then
    echo -e "${GREEN}✅ Copilot CLI:     $(copilot --version 2>&1 | head -n1)${NC}"
else
    echo -e "${RED}❌ Copilot CLI:     Not installed${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🎯 Next Steps:${NC}"
echo ""
echo "1. Verify all software versions match your requirements"
echo "2. Ensure the runner service is configured correctly"
echo "3. Test the runner with a sample workflow"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo "   - Deployment Guide: docs/DEPLOYMENT.md"
echo "   - GHES Setup: docs/GHES-SETUP.md"
echo "   - Troubleshooting: docs/TROUBLESHOOTING.md"
echo ""
echo -e "${GREEN}All done! Your runner is ready to execute workflows.${NC}"
