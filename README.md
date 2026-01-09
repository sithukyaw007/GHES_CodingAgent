# 🤖 GitHub Copilot Coder for GHES

> **Automated code generation powered by GitHub Copilot CLI on GitHub Enterprise Server**

[![GitHub Actions](https://img.shields.io/badge/GitHub-Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![GitHub Copilot](https://img.shields.io/badge/GitHub-Copilot-000000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/features/copilot)
[![GHES](https://img.shields.io/badge/GHES-Compatible-success?style=for-the-badge&logo=github&logoColor=white)](https://docs.github.com/en/enterprise-server)

---

## 📋 Overview

This repository implements an automated coding workflow using **GitHub Copilot CLI** integrated with **GitHub Enterprise Server (GHES)**. Simply create an issue, add a label, and watch as Copilot generates the code, creates a PR, and links everything together automatically.

### ✨ Key Features

#### 🤖 Copilot Coder
- 🏷️ **Label-driven workflow** - Trigger code generation by adding the `copilot` label
- 🤖 **AI-powered coding** - GitHub Copilot CLI generates code based on issue descriptions
- 🌿 **Automatic branching** - Creates feature branches (`copilot/{issue-number}`)
- 📬 **Auto PR creation** - Opens pull requests with generated code
- 🔗 **Native linking** - Automatically links PRs to issues
- 📊 **Progress tracking** - Updates issue labels to track workflow state
- 📦 **Artifact logging** - Captures and stores execution logs
- 🔄 **MCP integration** - Uses Context7 for documentation and best practices

#### 🔍 Copilot PR Reviewer
- 🏷️ **Label-triggered PR reviews** - Add `copilot` label to trigger review
- 🔒 **Security analysis** - Detects security vulnerabilities
- ⚡ **Performance checks** - Identifies performance issues
- 🧹 **Code quality** - Flags code quality concerns
- 📝 **Detailed feedback** - Posts actionable comments with examples
- 📊 **Artifact logs** - Complete analysis available for reference

---

## 🛠️ Getting Started Guide

This section walks you through the complete setup process, from infrastructure to running your first Copilot workflow.

### 📊 Setup Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        COMPLETE SETUP JOURNEY                               │
│                                                                             │
│  PHASE 0: Prerequisites          PHASE 1: Configuration    PHASE 2: Usage  │
│  (One-time infrastructure)       (One-time setup)          (Daily use)     │
│                                                                             │
│  ┌─────────────────────┐        ┌──────────────────┐      ┌─────────────┐  │
│  │ 0.1 GHES Instance   │        │ 1.1 Clone Repo   │      │ Create      │  │
│  │ 0.2 Self-Hosted     │───────▶│ 1.2 Add Secrets  │─────▶│ Issue +     │  │
│  │     Runner VM       │        │ 1.3 Deploy to    │      │ Add Label   │  │
│  │ 0.3 Network Access  │        │     Target Repos │      │ = Done! ✨  │  │
│  └─────────────────────┘        └──────────────────┘      └─────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Phase 0: Prerequisites (Infrastructure Setup)

> **⏱️ Time Required:** 1-2 hours (one-time setup)

Before using the Copilot workflows, you need to set up the required infrastructure.

### 0.1 GitHub Enterprise Server Requirements

Ensure your GHES instance is properly configured:

| Requirement | Details | How to Verify |
|-------------|---------|---------------|
| **GHES Version** | 3.x or later recommended | Check admin dashboard |
| **GitHub Actions** | Must be enabled at org level | **Settings → Actions → General** |
| **GitHub Copilot** | Enterprise/Organization license | **Settings → Copilot** |
| **Reusable Workflows** | Must allow cross-repo workflows | **Settings → Actions → General → Access** |

### 0.2 Self-Hosted Runner Setup

The workflows require a self-hosted runner. Follow these steps to set one up:

#### Step 1: Provision a Server

| Specification | Minimum | Recommended |
|---------------|---------|-------------|
| **OS** | Ubuntu 20.04 LTS | Ubuntu 22.04 LTS |
| **vCPUs** | 2 | 4+ |
| **RAM** | 4 GB | 8+ GB |
| **Disk** | 50 GB | 100+ GB SSD |
| **Network** | Outbound HTTPS | Low-latency connection |

#### Step 2: Register the Runner with GHES

```bash
# 1. Go to your GHES organization settings:
#    https://<your-ghes-host>/<org>/settings/actions/runners/new

# 2. Download and extract the runner package (commands shown in GHES UI)
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L <download-url-from-ghes>
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# 3. Configure the runner
./config.sh --url https://<your-ghes-host>/<org> --token <token-from-ghes>

# 4. Install and start as a service (recommended for production)
sudo ./svc.sh install
sudo ./svc.sh start

# 5. Verify runner is online
sudo ./svc.sh status
```

#### Step 3: Install Required Software on Runner

```bash
# ============================================
# REQUIRED: GitHub CLI (gh) - MUST pre-install
# ============================================
# Enterprise networks often block npm during workflow execution,
# so GitHub CLI must be installed beforehand.

GH_VERSION="2.62.0"
cd /tmp
curl -L -o gh.tar.gz "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz"
tar -xzf gh.tar.gz
sudo mv gh_${GH_VERSION}_linux_amd64/bin/gh /usr/local/bin/
sudo chmod +x /usr/local/bin/gh

# Verify installation
gh --version

# ============================================
# VERIFY: Standard tools (usually pre-installed)
# ============================================
git --version      # Required for repository operations
curl --version     # Required for API calls
jq --version       # Optional but helpful for debugging
```

> **Note:** Node.js, Python, Copilot CLI, and MCP servers are installed **automatically** by the workflow - you don't need to pre-install them.

### 0.3 Network & Firewall Configuration

Your self-hosted runner needs outbound HTTPS access to these endpoints:

| Service | Hostname | Port | Purpose |
|---------|----------|------|---------|
| **Your GHES** | `<your-ghes-host>` | 443 | Git operations, API calls |
| **npm Registry** | `registry.npmjs.org` | 443 | Download Copilot CLI |
| **PyPI** | `pypi.org`, `files.pythonhosted.org` | 443 | Download MCP servers |
| **Copilot API** | `copilot-api.github.com` | 443 | AI code generation |
| **Context7** | `api.context7.com` | 443 | Documentation (optional) |

#### If Behind a Corporate Proxy

Add these to your runner's environment (`~/.bashrc` or `/etc/environment`):

```bash
export HTTP_PROXY="http://proxy.company.com:8080"
export HTTPS_PROXY="http://proxy.company.com:8080"
export NO_PROXY="<your-ghes-host>,localhost,127.0.0.1"
```

#### Firewall Rules (if applicable)

```bash
# Example iptables rules (adjust for your firewall)
sudo iptables -A OUTPUT -p tcp --dport 443 -d registry.npmjs.org -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 443 -d pypi.org -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 443 -d copilot-api.github.com -j ACCEPT
```

### ✅ Phase 0 Checklist

Before proceeding, verify all prerequisites are met:

- [ ] GHES instance is running with Actions enabled
- [ ] Self-hosted runner is registered and online (green status in GHES)
- [ ] GitHub CLI (`gh`) is installed on the runner
- [ ] Network connectivity verified (can reach npmjs.org, pypi.org, etc.)
- [ ] GitHub Copilot is enabled for your organization

---

## ⚙️ Phase 1: Configuration (One-Time Setup)

> **⏱️ Time Required:** 15-30 minutes

### 1.1 Clone This Repository to Your Organization

First, get the `GHES_CodingAgent` repository into your GHES organization:

**Option A: Clone via Git (Recommended)**

```bash
# Clone from source
git clone https://github.com/original/GHES_CodingAgent.git
cd GHES_CodingAgent

# Push to your GHES organization
git remote set-url origin https://<your-ghes-host>/<your-org>/GHES_CodingAgent.git
git push -u origin main
```

**Option B: For Air-Gapped Environments**

1. Download this repository as a ZIP file
2. Create a new repository named `GHES_CodingAgent` in your GHES org
3. Upload/push all files to the new repository

### 1.2 Configure the Central Repository

After cloning, configure the `GHES_CodingAgent` repository in your org:

#### Enable Cross-Repository Workflow Access

1. Go to **Settings → Actions → General**
2. Under "Access", select **"Accessible from repositories in the organization"**
3. Click **Save**

#### Add Organization or Repository Secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret | Required | Description | How to Get |
|--------|----------|-------------|------------|
| `GH_TOKEN` | ✅ Yes | Classic PAT with `repo` and `workflow` scopes | See below |
| `COPILOT_TOKEN` | ✅ Yes | Token for GitHub Copilot API access | From Copilot settings |
| `CONTEXT7_API_KEY` | ❌ Optional | Context7 API key for enhanced docs | [context7.com](https://context7.com) |

#### Creating the GH_TOKEN (Classic PAT)

> ⚠️ **CRITICAL:** Must be a **Classic PAT** from your GHES instance. Fine-grained PATs have GraphQL issues on GHES.

1. Go to `https://<your-ghes-host>/settings/tokens`
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Set a descriptive name (e.g., "Copilot Workflows Token")
4. Set expiration (recommend 90 days or longer)
5. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
6. Click **Generate token**
7. Copy and save the token securely
8. Add it as a secret named `GH_TOKEN`

### 1.3 Deploy to Target Repositories

Use the deployment scripts to install Copilot workflows into other repositories:

#### Using Bash (Linux/Mac/Git Bash)

```bash
./scripts/deploy-to-repo.sh \
    <ghes-host> \
    <your-org> \
    <target-repo> \
    <gh-token>

# Example:
./scripts/deploy-to-repo.sh ghes.company.com myorg my-project ghp_xxxxxxxxxxxx
```

#### Using PowerShell (Windows)

```powershell
.\scripts\deploy-to-repo.ps1 `
    -GhesHost "ghes.company.com" `
    -Owner "myorg" `
    -Repo "my-project" `
    -GhToken "ghp_xxxxxxxxxxxx"
```

The script will:
1. ✅ Clone the target repository
2. ✅ Copy lightweight caller workflow files
3. ✅ Create required labels (`copilot`, `in-progress`, `ready-for-review`)
4. ✅ Create a Pull Request with setup instructions

**After running the script:**
1. Review and merge the created PR
2. Add the same secrets (`GH_TOKEN`, `COPILOT_TOKEN`) to the target repository

### ✅ Phase 1 Checklist

- [ ] `GHES_CodingAgent` repository cloned to your GHES org
- [ ] Workflow access enabled ("Accessible from repositories in the organization")
- [ ] Secrets configured (`GH_TOKEN`, `COPILOT_TOKEN`)
- [ ] Target repository(ies) have caller workflows deployed
- [ ] Target repository(ies) have secrets configured

---

## 🚀 Phase 2: Quick Start (Daily Usage)

> **⏱️ Time Required:** 2-3 minutes per issue

Now you're ready to use Copilot! Here's how:

### 2️⃣ Create an Issue

Create a standard issue with:

```markdown
## 📋 Task Description
Create a Python FastAPI application with a simple health check endpoint.

## 🎯 Acceptance Criteria
- [ ] FastAPI app with /health endpoint
- [ ] Returns JSON with status and timestamp
- [ ] Includes proper documentation
- [ ] Add requirements.txt

## 📚 Technical Details
- Use FastAPI latest version
- Python 3.11+
- Follow REST API best practices
```

### 3️⃣ Trigger the Workflow

Add the **`copilot`** label to the issue.

### 4️⃣ Watch the Magic ✨

The workflow will automatically:

1. 🏷️ Update issue label → `in-progress`
2. 🌿 Create branch → `copilot/{issue-number}`
3. 🤖 Generate code using Copilot CLI
4. 💾 Commit changes with co-author attribution
5. 🚀 Push branch to repository
6. 📬 Create Pull Request
7. 💬 Comment on issue with PR link
8. 🏷️ Update label → `ready-for-review`

### 5️⃣ Review and Merge

1. Review the Pull Request
2. **Add `copilot` label to PR for AI review** (optional) ✨
3. Test the implementation
4. Approve and merge when ready

---

## 🚀 Deployment Guide (Reference)

> **Note:** If you followed the Phase 0 and Phase 1 steps above, you've already completed the deployment! This section provides additional details for reference.

### Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Your GHES Organization                           │
│                                                                         │
│  ┌─────────────────────────┐      ┌─────────────────────────────────┐  │
│  │   GHES_CodingAgent      │      │     Target Repository           │  │
│  │   (Central/Master)      │      │     (e.g., my-project)          │  │
│  │                         │      │                                 │  │
│  │  • Master workflows     │      │  • Caller workflows only (2)    │  │
│  │  • MCP configuration    │◄─────│                                 │  │
│  │  • Documentation        │      │  (fetches config at runtime)    │  │
│  │  • Deploy scripts       │ uses │                                 │  │
│  └─────────────────────────┘      └─────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### What Gets Deployed to Target Repositories

| File | Size | Description |
|------|------|-------------|
| `.github/workflows/copilot-coder.yml` | ~30 lines | Calls master coder workflow |
| `.github/workflows/copilot-reviewer.yml` | ~35 lines | Calls master reviewer workflow |

### Benefits of This Architecture

| Benefit | Description |
|---------|-------------|
| **Centralized Updates** | Update master workflows once, all repos get improvements |
| **Minimal Footprint** | Target repos only have 2 small YAML files |
| **No Script Duplication** | Scripts live only in central repo |
| **Easy Rollout** | Deploy to new repos in seconds |
| **Version Control** | Pin to specific tags/commits if needed |

For detailed deployment instructions, see [Deployment Guide](docs/DEPLOYMENT.md).

---

## 🤖 Copilot PR Reviewer (On-Demand)

The **Copilot PR Reviewer** analyzes pull requests when triggered:

- 🏷️ **Triggers when `copilot` label is added** - Add label to request review
- 🔍 **Analyzes all changed files** - Security, performance, code quality
- 💬 **Posts review comments** - With actionable recommendations
- 📊 **Generates analysis report** - Available as artifact

### Review Process

```
Developer adds 'copilot' label to PR
         ↓
Reviewer Workflow Triggers
         ↓
1️⃣ Download Changed Files
2️⃣ Run Copilot Analysis
3️⃣ Post Review Comments
         ↓
📝 Feedback Ready for Developer
```

### Example Review Output

Copilot identifies and comments on issues like:

- 🔒 **Security**: SQL injection, exposed secrets, unsafe deserialization
- ⚡ **Performance**: Inefficient loops, unnecessary allocations, N+1 queries
- 🧹 **Code Quality**: Naming, documentation, complexity, error handling
- 📝 **Best Practices**: Type safety, error handling, edge cases

**To request a review:** Add the `copilot` label to the PR. The reviewer workflow will analyze your code and post feedback.

For detailed information, see [Copilot PR Reviewer Documentation](docs/COPILOT-REVIEWER.md).

## 🎯 How It Works

### Coder Workflow Trigger

```yaml
on:
  issues:
    types: [labeled]
```

The coder workflow triggers when:
- The `copilot` label is added to an issue

### Reviewer Workflow Trigger

```yaml
on:
  pull_request:
    types: [labeled]
```

The reviewer workflow triggers when:
- The `copilot` label is added to a pull request

### Architecture

```
GitHub Issue Created
       ↓
Add 'copilot' Label
       ↓
Workflow Triggers
       ↓
Update Labels (in-progress)
       ↓
Setup Environment
(Python, Node.js, Copilot CLI)
       ↓
Configure MCP Servers
       ↓
Create Feature Branch
       ↓
Run Copilot CLI
(Generate Code)
       ↓
Commit Changes
       ↓
Push Branch
       ↓
Create Pull Request
       ↓
Comment on Issue
       ↓
Update Labels (completed, ready-for-review)
       ↓
✅ Done!
```

## 📦 Repository Structure

### Central Repository (GHES_CodingAgent)

```
.github/
├── workflows/
│   ├── copilot-coder-master.yml    # Master workflow (reusable) - full logic
│   ├── copilot-coder.yml           # Caller workflow (example/reference)
│   ├── copilot-reviewer-master.yml # Master workflow (reusable) - full logic
│   └── copilot-reviewer.yml        # Caller workflow (example/reference)

scripts/                            # Scripts for deployment only (NOT deployed to targets)
├── deploy-to-repo.ps1              # Deploy to target repo (PowerShell)
├── deploy-to-repo.sh               # Deploy to target repo (Bash)
└── README.md                       # Script documentation

docs/
├── GHES-SETUP.md                   # Detailed setup guide
├── DEPLOYMENT.md                   # Deployment guide
├── COPILOT-REVIEWER.md             # PR Reviewer documentation
├── TROUBLESHOOTING.md              # Common issues and solutions
└── ...                             # Other documentation

mcp-config.json                     # MCP servers configuration (fetched at runtime)
```

### Target Repositories (After Deployment)

```
.github/
└── workflows/
    ├── copilot-coder.yml           # Caller workflow (~30 lines)
    └── copilot-reviewer.yml        # Caller workflow (~35 lines)
```

> **Note:** Target repositories receive ONLY the caller workflows. All logic is in the master workflows, and MCP configuration is fetched at runtime from the central repository.

### Master vs Caller Workflows

| Type | File | Purpose |
|------|------|---------|
| **Master** | `*-master.yml` | Contains full implementation logic, called by other repos |
| **Caller** | `*.yml` | Lightweight wrapper that invokes the master workflow |

Target repositories only receive the **caller workflows**, which are ~30 lines each.

## 🛠️ Technologies Used

- **GitHub Actions** - Workflow orchestration
- **GitHub Copilot CLI** - AI-powered code generation
- **GitHub Issues** - Task management
- **Bash Scripts** - Automation
- **Node.js 22.x** - Runtime for Copilot CLI
- **Python 3.x** - Tooling and MCP server runtime
- **uv** - Python package manager for installing MCP servers
- **MCP Servers** - Context providers:
  - **Context7** (npx) - Documentation and examples
  - **Fetch** (uvx) - Web content retrieval
  - **Time** (uvx) - Time-based operations

## ⚙️ Configuration

### Workflow Variables

Edit `.github/workflows/copilot-coder.yml` to customize:

```yaml
env:
  MODEL: claude-haiku-4.5          # LLM model to use
  COPILOT_VERSION: 0.0.352         # Copilot CLI version
```

## 🌐 Network Requirements

For the workflow to run successfully, GHES runners must have outbound internet access to:

| Service | Host | Port | Protocol | Purpose |
|---------|------|------|----------|---------|
| **GHES API** | `<your-ghes-host>` | 443 | HTTPS | GitHub CLI and API calls |
| **Copilot CLI** | `registry.npmjs.org` | 443 | HTTPS | Download @github/copilot package |
| **MCP Servers** | `pypi.org` | 443 | HTTPS | Install MCP servers via uv |
| **Documentation** | `api.context7.com` | 443 | HTTPS | Context7 MCP service |

### Firewall Configuration

If your GHES runners are behind a firewall, ensure these outbound rules are configured:

```bash
# Allow outbound HTTPS to required services
Allow: registry.npmjs.org:443
Allow: pypi.org:443  
Allow: api.context7.com:443
Allow: <your-ghes-host>:443
```

### Behind Corporate Proxy

If GHES runners access the internet through a corporate proxy, configure:

```yaml
# In workflow or runner configuration
HTTP_PROXY: http://proxy.company.com:8080
HTTPS_PROXY: http://proxy.company.com:8080
NO_PROXY: <your-ghes-host>
```

For detailed network configuration and troubleshooting, see **[GHES Compatibility Guide](docs/GHES-COMPATIBILITY.md#-required-networkfirewall-paths)**.

---

### MCP Servers

Edit `mcp-config.json` to add or remove MCP servers:

```json
{
  "mcpServers": {
    "context7": {
      "type": "local",
      "command": "npx",
      "tools": ["*"],
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "fetch": {
      "type": "local",
      "command": "uvx",
      "tools": ["*"],
      "args": ["mcp-server-fetch"]
    },
    "time": {
      "type": "local",
      "command": "uvx",
      "tools": ["*"],
      "args": ["mcp-server-time"]
    }
  }
}
```

**Note**: MCP servers using `uvx` are installed on-demand via the `uv` Python package manager from PyPI.

### Copilot Instructions

Edit `.github/copilot-instructions.md` to customize Copilot's behavior:

- Add project-specific guidelines
- Define code style preferences
- Specify frameworks or libraries to use
- Add security or compliance requirements

### Logs and Artifacts

Each workflow run publishes:

- 📝 **Workflow logs** - Available in Actions tab
- 📦 **Copilot logs** - Downloaded as artifacts (retention: 30 days)

Access artifacts:
1. Go to Actions tab
2. Select workflow run
3. Scroll to Artifacts section
4. Download `copilot-logs`

### Workflow Permissions

```yaml
permissions:
  contents: write        # Create branches and commits
  issues: write          # Update issue labels and comments
  pull-requests: write   # Create pull requests
```

## 📚 Documentation

Detailed guides are available in the `docs/` directory:

| Document | Description |
|----------|-------------|
| **[Technical Overview](docs/TECHNICAL-OVERVIEW.md)** | Deep-dive into architecture, MCP servers, and data flow |
| **[GHES Setup Guide](docs/GHES-SETUP.md)** | Complete setup instructions for GHES |
| **[Deployment Guide](docs/DEPLOYMENT.md)** | Deploying workflows to repositories |
| **[Copilot PR Reviewer Guide](docs/COPILOT-REVIEWER.md)** | Automated PR review documentation |
| **[Troubleshooting](docs/TROUBLESHOOTING.md)** | Common issues and solutions |

## 🆘 Troubleshooting

### Workflow Not Triggering

- ✅ Verify label is exactly `copilot` (case-sensitive)
- ✅ Check workflow file syntax
- ✅ Ensure workflow is enabled in Actions tab

### Authentication Errors

- ✅ Verify `GH_TOKEN` is set in organization or repository secrets
- ✅ Check token scopes (`repo`, `copilot_requests`)
- ✅ Ensure token is from GHES, not GitHub.com

### Copilot Errors

- ✅ Check issue description is clear and detailed
- ✅ Verify `MODEL` setting in workflow
- ✅ Review Copilot logs in artifacts

For more troubleshooting help, see **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**.

## 🙏 Acknowledgments

- **GitHub Copilot team** - For the Copilot CLI
- **Original ADO implementation** - By the amazing  [Gisela Torres - 0GiS0](https://github.com/0GiS0)

---

<div align="center">

**Made with ❤️ and 🤖 by GitHub Copilot**

</div>
