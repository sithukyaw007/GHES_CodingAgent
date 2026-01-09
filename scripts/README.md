# GitHub Copilot Coder - Scripts

This directory contains helper scripts used by the GitHub Copilot Coder workflow to manage commit and branch operations for GHES (GitHub Enterprise Server).

## 📋 Scripts Overview

### Runner Setup Scripts (One-Time Installation)
- `setup-runner.sh` - **NEW**: Automated setup for Linux/Mac runners
- `setup-runner.ps1` - **NEW**: Automated setup for Windows runners

### Deployment Scripts
- `deploy-to-repo.ps1` - PowerShell script to deploy workflows to a target repository
- `deploy-to-repo.sh` - Bash script to deploy workflows to a target repository

### Core Workflow Scripts
- `prepare-commit.sh` - Prepares and commits changes with co-author attribution
- `push-branch.sh` - Pushes feature branch to remote repository
- `post-workflow-comment.sh` - Posts completion comment to GitHub issue

---

## 🖥️ Runner Setup Scripts

### `setup-runner.sh` (Linux/Mac)

**⚠️ NEW - REQUIRED FOR ALL RUNNERS**

One-time installation script that pre-installs all required software on Linux/Mac self-hosted runners. This must be run before executing any workflows.

**Prerequisites:** 
- Sudo access to the runner VM
- Internet access (or pre-downloaded installers)

**Usage:**
```bash
sudo ./scripts/setup-runner.sh
```

**What it installs:**
- GitHub CLI (gh) v2.62.0
- Node.js 22.x
- Python 3.x
- uv/uvx (Python package installer)
- GitHub Copilot CLI v0.0.352

**Supported OS:**
- Ubuntu/Debian (apt-based)
- RHEL/CentOS/Fedora (yum-based)

**Features:**
- Automatic OS detection
- Version checking (skips if already installed)
- Colored output for readability
- Comprehensive error handling
- Installation summary

**Example:**
```bash
# SSH into your runner VM
ssh runner@runner-vm

# Clone or download GHES_CodingAgent
git clone https://ghes.company.com/myorg/GHES_CodingAgent.git
cd GHES_CodingAgent

# Run the setup script
sudo ./scripts/setup-runner.sh
```

**Verification:**
After running the script, verify all software:
```bash
gh --version
node --version
npm --version
python3 --version
uv --version
copilot --version
```

### `setup-runner.ps1` (Windows)

**⚠️ NEW - REQUIRED FOR ALL WINDOWS RUNNERS**

One-time installation script that pre-installs all required software on Windows self-hosted runners. This must be run before executing any workflows.

**Prerequisites:** 
- Administrator privileges
- Internet access (or pre-downloaded installers)

**Usage:**
```powershell
# Run PowerShell as Administrator
.\scripts\setup-runner.ps1
```

**What it installs:**
- GitHub CLI (gh) v2.62.0
- Node.js 22.x
- Python 3.x
- uv/uvx (Python package installer)
- GitHub Copilot CLI v0.0.352

**Features:**
- Administrator check
- Version checking (skips if already installed)
- Colored output for readability
- Comprehensive error handling
- Installation summary

**Example:**
```powershell
# RDP into your runner machine
# Open PowerShell as Administrator

# Clone or download GHES_CodingAgent
git clone https://ghes.company.com/myorg/GHES_CodingAgent.git
cd GHES_CodingAgent

# Run the setup script
.\scripts\setup-runner.ps1
```

**Verification:**
After running the script, verify all software:
```powershell
gh --version
node --version
npm --version
python --version
uv --version
copilot --version
```

---

## 🚀 Deployment Scripts

### `deploy-to-repo.ps1` (PowerShell)

Deploys the Copilot caller workflows to a target repository on GHES.

**Prerequisites:** You must first clone GHES_CodingAgent into your GHES organization.

**Usage:**
```powershell
.\scripts\deploy-to-repo.ps1 -GhesHost <host> -Owner <org> -Repo <repo> -GhToken <token>
```

**Parameters:**
- `GhesHost` - Your GHES hostname (e.g., `ghes.company.com`)
- `Owner` - Organization name (where GHES_CodingAgent is cloned)
- `Repo` - Target repository name
- `GhToken` - Classic PAT with `repo` and `workflow` scopes

**Example:**
```powershell
.\scripts\deploy-to-repo.ps1 -GhesHost ghes.company.com -Owner myorg -Repo myproject -GhToken ghp_xxxxx
```

### `deploy-to-repo.sh` (Bash)

Deploys the Copilot caller workflows to a target repository on GHES.

**Prerequisites:** You must first clone GHES_CodingAgent into your GHES organization.

**Usage:**
```bash
./scripts/deploy-to-repo.sh <ghes-host> <org> <repo> <gh-token>
```

**Parameters:**
- `ghes-host` - Your GHES hostname (e.g., `ghes.company.com`)
- `org` - Organization name (where GHES_CodingAgent is cloned)
- `repo` - Target repository name
- `gh-token` - Classic PAT with `repo` and `workflow` scopes

**Example:**
```bash
./scripts/deploy-to-repo.sh ghes.company.com myorg myproject ghp_xxxxx
```

**What the deployment scripts do:**
1. Clone the target repository
2. Create a setup branch (`setup/copilot-workflows`)
3. Copy caller workflow files (updating org references)
4. Copy `copilot-instructions.md` and `mcp-config.json`
5. Create required labels (`copilot`, `in-progress`, `ready-for-review`)
6. Push the branch and create a Pull Request

**Files deployed to target repos:**
- `.github/workflows/copilot-coder.yml` - Caller workflow
- `.github/workflows/copilot-reviewer.yml` - Caller workflow
- `.github/copilot-instructions.md` - Copilot instructions
- `mcp-config.json` - MCP configuration

> **Note:** No `scripts/` folder is deployed! The caller workflows reference the master workflows in the central GHES_CodingAgent repository.

---

## � Script Descriptions

### `prepare-commit.sh`

Prepares and commits staged changes with proper co-author attribution.

**Usage:**
```bash
./scripts/prepare-commit.sh <issue_number> <issue_title> <creator_username>
```

**Parameters:**
- `issue_number` - GitHub issue number
- `issue_title` - GitHub issue title
- `creator_username` - GitHub username of issue creator

**Example:**
```bash
./scripts/prepare-commit.sh 42 "Add new feature" "octocat"
```

**What it does:**
- Validates that required parameters are provided
- Checks git configuration is set up
- Stages all changes (excluding metadata files)
- Creates a commit with co-author attribution
- Generates commit message from `commit-message.md` if available

**Environment variables:**
- Requires `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL` set by workflow

### `push-branch.sh`

Pushes the feature branch to the remote repository.

**Usage:**
```bash
./scripts/push-branch.sh <branch_name>
```

**Parameters:**
- `branch_name` - Name of branch to push (typically `copilot/<issue-number>`)

**Example:**
```bash
./scripts/push-branch.sh copilot/42
```

**What it does:**
- Validates branch name is provided
- Pushes branch to origin
- Sets upstream tracking

**Environment variables:**
- Requires `GH_TOKEN` for authentication

### `post-workflow-comment.sh`

Posts a completion comment to the GitHub issue linking to the created pull request.

**Usage:**
```bash
./scripts/post-workflow-comment.sh <issue_number> <pr_url>
```

**Parameters:**
- `issue_number` - GitHub issue number
- `pr_url` - URL of the created pull request

**Example:**
```bash
./scripts/post-workflow-comment.sh 42 "https://github.com/owner/repo/pull/99"
```

**What it does:**
- Validates parameters are provided
- Posts a comment on the GitHub issue
- Links to the generated pull request
- Notifies issue creator of completion

**Environment variables:**
- Requires `GH_TOKEN` for authentication
