# 🚀 GitHub Enterprise Server (GHES) Setup Guide

This guide explains how to set up the GitHub Copilot Coder workflow on GitHub Enterprise Server.

## 📋 Prerequisites

### Required Software on Self-Hosted Runner

All software must be pre-installed on the runner using the provided setup script. The workflows verify software availability but do not install it at runtime.

**Setup Script:** `scripts/setup-runner.sh` (Linux/Mac) or `scripts/setup-runner.ps1` (Windows)

The following software will be installed by the setup script:
- GitHub CLI (gh) v2.62.0
- Node.js 22.x
- Python 3.x
- uv/uvx (Python package installer)
- GitHub Copilot CLI

### Required Permissions
- Repository admin access
- Ability to create GitHub Actions workflows
- Ability to configure repository secrets
- SSH/RDP access to self-hosted runner (for one-time setup)

## 🔐 Step 1: Configure Organization or Repository Secrets

Navigate to your repository **Settings** → **Secrets and variables** → **Actions** and add the following secrets:

### Required Secrets

1. **`GH_TOKEN`** (Required)
   - **Description**: GitHub Personal Access Token for repository operations and GitHub CLI
   - **Type**: ⚠️ **Classic PAT ONLY** - Fine-grained PATs have issues with GraphQL on GHES
   - **Required Scopes**:
     - `repo` - Full control of private repositories
     - `workflow` - Update GitHub Action workflows
   - **How to create**:
     1. Go to `https://<your-ghes-instance>/settings/tokens`
     2. Click **"Generate new token"** → **"Generate new token (classic)"**
     3. Set a descriptive name (e.g., "Copilot Workflows")
     4. Set expiration (recommend 90+ days)
     5. Select scopes: ✅ `repo`, ✅ `workflow`
     6. Click **Generate token**
     7. Copy and add as repository secret

   > ⚠️ **Important**: Do NOT use Fine-grained PATs - they fail with `Resource not accessible by personal access token` errors on GHES GraphQL operations.

2. **`COPILOT_TOKEN`** (Required)
   - **Description**: Token for GitHub Copilot API access
   - **Required for**: Running Copilot CLI commands

3. **`CONTEXT7_API_KEY`** (Optional)
   - **Description**: API key for Context7 MCP server (for documentation access)
   - **Required for**: Enhanced documentation lookup
   - **How to get**: Sign up at [Context7](https://context7.com)

## 🎯 Step 3: Set Up Self-Hosted Runner

Before running any workflows, you **must** pre-install all required software on your self-hosted runner.

### Automated Setup (Recommended)

We provide automated setup scripts that install all required software in one command.

#### For Linux/Mac Runners

SSH into your runner VM and execute:

```bash
# Clone the GHES_CodingAgent repository
git clone https://<your-ghes-host>/<your-org>/GHES_CodingAgent.git
cd GHES_CodingAgent

# Run the setup script with sudo
sudo ./scripts/setup-runner.sh
```

#### For Windows Runners

RDP into your runner machine, open PowerShell as Administrator, and execute:

```powershell
# Clone the GHES_CodingAgent repository
git clone https://<your-ghes-host>/<your-org>/GHES_CodingAgent.git
cd GHES_CodingAgent

# Run the setup script
.\scripts\setup-runner.ps1
```

### What Gets Installed

The setup script installs:

1. **GitHub CLI (gh)** - v2.62.0 - For GitHub API operations
2. **Node.js** - v22.x - Required for Copilot CLI
3. **Python** - v3.x - Required for uv/uvx
4. **uv/uvx** - Latest - Python package installer
5. **GitHub Copilot CLI** - v0.0.352 - The AI coding assistant

### Verification

After running the setup script, verify all software is installed:

```bash
# On Linux/Mac
gh --version
node --version
npm --version
python3 --version
uv --version
copilot --version
```

```powershell
# On Windows (PowerShell)
gh --version
node --version
npm --version
python --version
uv --version
copilot --version
```

All commands should return version information without errors.

### Manual Installation (If Automatic Fails)

If the automated setup fails due to network restrictions, you can manually install each component. Refer to the setup script source code for the exact versions and installation steps.

---

The workflow file is located at `.github/workflows/copilot-coder.yml`.

### Default Configuration

```yaml
env:
  MODEL: claude-haiku-4.5          # LLM model to use
  COPILOT_VERSION: 0.0.352         # Copilot CLI version (for reference only)
```

### Customization Options

You can customize the workflow by editing these environment variables:

- **`MODEL`**: Change the LLM model (e.g., `claude-sonnet-4`, `gpt-4`)
- **`COPILOT_VERSION`**: Reference version (software is pre-installed on runner)

**Note:** The `COPILOT_VERSION` variable is now informational only. The actual version used is whatever is pre-installed on the runner via the setup script.

## 🎯 Step 5: Understand MCP Server Configuration

The workflow uses MCP (Model Context Protocol) servers for enhanced functionality like documentation lookup and web content retrieval.

### How MCP Configuration Works

**Important:** MCP configuration is fetched automatically at runtime from the central `GHES_CodingAgent` repository. You do not need to:
- ❌ Edit any local `mcp-config.json` file
- ❌ Deploy MCP configuration to target repositories
- ❌ Manually configure MCP servers

The master workflow automatically downloads the latest `mcp-config.json` from the central repository during execution, ensuring all repositories use consistent, up-to-date MCP settings.

### Default MCP Servers

The centrally managed configuration includes:

1. **Context7**: Documentation and code examples
2. **Fetch**: Web content retrieval
3. **Time**: Time-based operations

### Customizing MCP Servers

To modify MCP configuration for all repositories:

1. Edit `mcp-config.json` in the `GHES_CodingAgent` repository
2. Changes apply automatically to all subsequent workflow runs
```

## 🎯 Step 5: Understand MCP Server Configuration

### Creating an Issue

1. Go to **Issues** → **New Issue**
2. Create a standard issue with your task description
3. Include clear acceptance criteria and technical details (if applicable)
4. Create the issue

### Triggering the Workflow

To trigger code generation:

1. Open the issue you want to implement
2. Add the label **`copilot`**
3. The workflow will automatically start

### Workflow States

The workflow manages issue states using labels:

- **`copilot`**: User adds to trigger workflow (automatically removed when workflow starts)
- **`in-progress`**: Workflow adds when code generation starts
- **`ready-for-review`**: Workflow adds when PR is created

## 📝 Step 6: Create Issues for Copilot

### Viewing Workflow Runs

1. Go to **Actions** tab in your repository
2. Select **🤖 GitHub Copilot Coder** workflow
3. Click on the latest run to see details

### Workflow Steps

The workflow executes the following steps:

1. 🚀 Start Workflow
2. 📥 Checkout Repository
3. 🏷️ Update Issue Labels - In Progress
4. ✅ Verify Pre-installed Software (Node.js, Python, uv, Copilot CLI)
5. ⚙️ Configure MCP Servers (fetched from central repo)
6. 🧰 Check MCP Access
7. 🌿 Create Feature Branch
8. 🤖 Implement Changes with Copilot
9. 💾 Commit Changes
10. 🚀 Push Branch
11. 📬 Create Pull Request
12. 💬 Add Completion Comment to Issue
13. 🏷️ Update Issue Labels - Completed
14. 📦 Publish Logs

### Accessing Logs

Workflow logs are published as artifacts:

1. Go to the workflow run
2. Scroll to **Artifacts** section
3. Download **copilot-logs** artifact

## 🔍 Step 7: Monitor Workflow Execution

Create a simple test issue to verify the setup:

```markdown
## 📋 Task Description
Create a simple "Hello World" Python script.

## 🎯 Acceptance Criteria
- [ ] Create hello.py file
- [ ] Script should print "Hello, World!"
- [ ] Include proper documentation

## 📚 Technical Details
### Technology Stack
- Python 3.x

### Requirements
- Simple, clean code
- Add a main function
```

1. Create this issue
2. Add the `copilot` label
3. Wait for the workflow to complete
4. Review the generated PR

## 🧪 Step 8: Test the Setup

### Token Security

- **Never commit tokens** to the repository
- Use **GitHub Secrets** for all sensitive data
- Rotate tokens regularly
- Use minimum required permissions

### Workflow Permissions

The workflow requires these permissions (configured in workflow file):

```yaml
permissions:
  contents: write        # Create branches and commits
  issues: write          # Update issue labels and comments
  pull-requests: write   # Create pull requests
```

## 🌐 GHES-Specific Configuration

### Custom GHES Hostname

If your GHES instance uses a custom hostname, ensure:

1. The `GH_TOKEN` is from your GHES instance
2. Git remote URLs point to your GHES instance
3. API calls use your GHES hostname

### Self-Hosted Runners - Pre-Installation Required

⚠️ **CRITICAL REQUIREMENT**: All required software must be pre-installed on self-hosted runners using the provided setup scripts.

#### Why Pre-Installation is Required

Enterprise networks typically:
- Block outbound internet access during workflow execution
- Require proxy configuration for external downloads
- Have slow or restricted access to package repositories (npm, apt, pip)
- Experience timeouts when installing software during workflow runs

**Solution:** Install all software once on the runner using the automated setup script.

#### Automated Setup (Recommended)

**For Linux/Mac runners:**

```bash
# On the runner VM
git clone https://<your-ghes-host>/<your-org>/GHES_CodingAgent.git
cd GHES_CodingAgent
sudo ./scripts/setup-runner.sh
```

**For Windows runners:**

```powershell
# On the runner machine (PowerShell as Administrator)
git clone https://<your-ghes-host>/<your-org>/GHES_CodingAgent.git
cd GHES_CodingAgent
.\scripts\setup-runner.ps1
```

The setup script installs:
- GitHub CLI (gh) v2.62.0
- Node.js 22.x
- Python 3.x
- uv/uvx
- GitHub Copilot CLI

#### Manual Installation (If Automated Setup Fails)

If the setup script cannot reach external repositories, you can download all installers on a machine with internet access and transfer them to the runner. See the setup script source code for detailed installation steps and exact versions.

#### Runner Labels

Configure runner labels in the workflow:

```yaml
runs-on: [self-hosted, linux]
```

## 📊 Monitoring and Maintenance

### Workflow Performance

Monitor workflow execution times:

- **Average execution**: 2-4 minutes (faster with pre-installed software)
- **Success rate**: Should be >90%

### Regular Maintenance

1. **Update runner software**: Periodically run the setup script to update to newer versions
2. **Review logs**: Check for MCP server issues
3. **Update dependencies**: Keep MCP servers updated
4. **Clean up branches**: Delete merged feature branches

## 🆘 Troubleshooting

### Common Issues

#### ❌ Software Not Found Errors

**Error**: `command not found: node`, `command not found: copilot`, etc.

**Cause**: Required software is not pre-installed on the runner.

**Solution**:
1. SSH/RDP into the runner machine
2. Run the setup script: `sudo ./scripts/setup-runner.sh` (Linux/Mac) or `.\scripts\setup-runner.ps1` (Windows)
3. Verify all software is installed correctly

#### ❌ GitHub CLI Authentication Failed (HTTP 401)

**Error**: `error validating token: HTTP 401: Bad credentials`

**Cause**: The `GH_TOKEN` secret is either:
1. Created on github.com instead of your GHES instance
2. Expired or invalid
3. Missing required scopes/permissions

**Solution**:

1. **Verify token origin**: The token MUST be created on your GHES instance:
   - ✅ Correct: `https://<your-ghes-instance>/settings/tokens`
   - ❌ Wrong: `https://github.com/settings/tokens`

2. **Test the token manually** on the runner:
   ```bash
   # Replace <your-ghes-host> and <your-token>
   curl -H "Authorization: token <your-token>" \
     https://<your-ghes-host>/api/v3/user
   ```
   
   If this returns 401, the token is invalid for your GHES instance.

3. **Create a new token on GHES** with required permissions:
   - `repo` (full control)
   - `workflow` (update workflows)
   - `read:org` (if using org-level features)

4. **Update the repository secret**:
   - Go to repository Settings → Secrets and variables → Actions
   - Update `GH_TOKEN` with the new GHES token

For more issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Copilot CLI](https://github.com/github/copilot-cli)
- [MCP Protocol](https://modelcontextprotocol.io/)
- [GHES Documentation](https://docs.github.com/en/enterprise-server)

## 🤝 Support

For issues or questions:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review workflow logs
3. Create an issue in this repository
