# 🚀 Deploying Copilot Workflows to New Repositories

This guide explains how to deploy the GitHub Copilot Coder and Reviewer workflows to any repository on your GitHub Enterprise Server.

## 📋 Prerequisites Summary

Before deploying, ensure these prerequisites are met:

### Self-Hosted Runner Requirements

All software must be pre-installed on the runner using the setup script. The workflows no longer install software at runtime for better performance.

| Component | Required | Installation |
|-----------|----------|--------------|
| **GitHub CLI (`gh`)** | ✅ Yes | **Pre-install using setup script** |
| **Node.js 22.x** | ✅ Yes | **Pre-install using setup script** |
| **Python 3.x** | ✅ Yes | **Pre-install using setup script** |
| **uv/uvx** | ✅ Yes | **Pre-install using setup script** |
| **GitHub Copilot CLI** | ✅ Yes | **Pre-install using setup script** |

**⚠️ IMPORTANT:** All software must be installed ONCE on each runner before running any workflows. Use the provided setup script:

**Linux/Mac:**
```bash
sudo ./scripts/setup-runner.sh
```

**Windows (PowerShell as Administrator):**
```powershell
.\scripts\setup-runner.ps1
```

### Organization or Repository Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `GH_TOKEN` | ✅ Yes | **Classic PAT** from GHES with `repo` and `workflow` scopes |
| `COPILOT_TOKEN` | ✅ Yes | Token for GitHub Copilot API access |
| `CONTEXT7_API_KEY` | ❌ Optional | API key for Context7 documentation service |

### Required Labels

These labels are created automatically by the deployment script:

| Label | Color | Purpose |
|-------|-------|---------|
| `copilot` | `#7057ff` | Triggers code generation and PR review workflows |
| `in-progress` | `#fbca04` | Applied while workflow is running |
| `ready-for-review` | `#0e8a16` | Applied when PR is ready |

---

## 🔧 Automated Deployment (Recommended)

Use the deployment script to automatically set up everything:

### PowerShell (Windows)

```powershell
# From the GHES_CodingAgent repository
.\scripts\deploy-to-repo.ps1 `
    -GhesHost "ghes.company.com" `
    -Owner "myorg" `
    -Repo "my-new-repo" `
    -GhToken "ghp_xxxxxxxxxxxx"
```

### Bash (Linux/Mac/Git Bash)

```bash
./scripts/deploy-to-repo.sh ghes.company.com myorg my-new-repo ghp_xxxxxxxxxxxx
```

### What the Script Does

1. ✅ Clones the target repository
2. ✅ Copies lightweight caller workflow files (2 files only)
3. ✅ Updates organization reference in workflows
4. ✅ Creates required labels
5. ✅ Creates a Pull Request with setup instructions

### What Gets Deployed

Only **2 small files** are deployed to target repositories:

| File | Size | Description |
|------|------|-------------|
| `.github/workflows/copilot-coder.yml` | ~30 lines | Calls master coder workflow |
| `.github/workflows/copilot-reviewer.yml` | ~35 lines | Calls master reviewer workflow |

### After Running the Script

1. **Verify pre-installed software** on the runner
2. **Review and merge** the created PR  
3. **Add repository secrets** (see below)

---

## 🔐 Creating the GH_TOKEN

The `GH_TOKEN` **must be a Classic PAT** created on your GHES instance (not github.com).

### Steps

1. Go to `https://<your-ghes-host>/settings/tokens`
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Set expiration (recommend 90 days or longer)
4. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
5. Click **Generate token**
6. Copy and save the token securely

### ⚠️ Important Notes

- **Do NOT use Fine-grained PATs** - They have issues with GraphQL operations on GHES
- **Create on GHES, not github.com** - The token must be from your GHES instance
- **Rotate regularly** - Set calendar reminders for token expiration

---

## 🖥️ Self-Hosted Runner Setup

### One-Time Software Installation (Required)

All required software must be pre-installed on each runner before executing any workflows. We provide automated setup scripts for this purpose.

#### Linux/Mac Setup

SSH into your runner VM and run:

```bash
# Clone or download the GHES_CodingAgent repository
git clone <your-ghes-host>/your-org/GHES_CodingAgent.git
cd GHES_CodingAgent

# Run the setup script
sudo ./scripts/setup-runner.sh
```

The script will install:
- GitHub CLI (gh) v2.62.0
- Node.js 22.x
- Python 3.x
- uv/uvx (Python package installer)
- GitHub Copilot CLI

#### Windows Setup

Run PowerShell as Administrator and execute:

```powershell
# Clone or download the GHES_CodingAgent repository
git clone <your-ghes-host>/your-org/GHES_CodingAgent.git
cd GHES_CodingAgent

# Run the setup script
.\scripts\setup-runner.ps1
```

#### Manual Installation (If Automatic Setup Fails)

If your runner cannot reach external package repositories, you may need to download binaries on another machine and transfer them to the runner. See the setup script source code for detailed manual installation instructions.

---

## ✅ Verification Checklist

After deployment, verify everything is set up correctly:

- [ ] **All software pre-installed on runner** (run `scripts/setup-runner.sh` or `setup-runner.ps1`)
- [ ] Workflows visible in **Actions** tab
- [ ] All 3 labels created (`copilot`, `in-progress`, `ready-for-review`)
- [ ] `GH_TOKEN` secret configured
- [ ] `COPILOT_TOKEN` secret configured
- [ ] Runner is online and idle

### Verify Runner Software

SSH/RDP into your runner and verify all required software:

```bash
# Check all required components
gh --version          # Should show v2.62.0 or later
node --version        # Should show v22.x.x
npm --version         # Should be installed with Node.js
python3 --version     # Should show v3.x.x
uv --version          # Should be installed
copilot --version     # Should show installed version
```

### Test the Setup

1. Create a test issue with a simple task description
2. Add the `copilot` label
3. Watch the workflow run in the Actions tab
4. Verify PR is created successfully

---

## 🔄 Updating Deployed Workflows

Since target repositories use **caller workflows** that reference the master workflows in `GHES_CodingAgent`:

- **No action needed!** Updates to master workflows automatically apply to all repositories
- Only re-deploy if the caller workflow file structure changes

---

## 🆘 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| `Software not found` errors in workflow | Run `scripts/setup-runner.sh` on the runner |
| `gh: command not found` | Run setup script to install all software |
| `node: command not found` | Run setup script to install all software |
| `copilot: command not found` | Run setup script to install all software |
| `HTTP 401: Bad credentials` | Token is invalid or from wrong server |
| `Resource not accessible by personal access token` | Use Classic PAT instead of Fine-grained |

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more solutions.
