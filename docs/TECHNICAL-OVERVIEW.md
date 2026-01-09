# 🏗️ Technical Architecture Overview

> **A comprehensive guide to understanding how the GitHub Copilot Coder and Reviewer agents work under the hood**

---

## 📋 Table of Contents

- [Introduction](#-introduction)
- [High-Level Architecture](#-high-level-architecture)
- [Copilot Coder Agent](#-copilot-coder-agent)
- [Copilot PR Reviewer Agent](#-copilot-pr-reviewer-agent)
- [MCP Servers Explained](#-mcp-servers-explained)
- [Data Sources & Integration](#-data-sources--integration)
- [Security Considerations](#-security-considerations)
- [Frequently Asked Questions](#-frequently-asked-questions)

---

## 🎯 Introduction

This repository provides two AI-powered automation agents for GitHub Enterprise Server (GHES):

| Agent | Purpose | Trigger |
|-------|---------|---------|
| **Copilot Coder** | Automatically generates code from issue descriptions | Add `copilot` label to an Issue |
| **Copilot PR Reviewer** | Analyzes pull requests for security, performance, and quality issues | Add `copilot` label to a Pull Request |

Both agents leverage **GitHub Copilot CLI** running within **GitHub Actions workflows** to provide AI-powered automation without requiring any external services beyond GitHub's own infrastructure.

---

## 🏛️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Your GHES Organization                            │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    GHES_CodingAgent (Central Repository)            │   │
│  │                                                                     │   │
│  │   📄 Master Workflows          📜 Scripts           📚 Docs        │   │
│  │   ├─ copilot-coder-master     ├─ deploy-to-repo    ├─ README       │   │
│  │   └─ copilot-reviewer-master  ├─ prepare-commit    └─ Setup guides │   │
│  │                               └─ push-branch                        │   │
│  │                                                                     │   │
│  │   ⚙️ MCP Config                📋 Instructions                     │   │
│  │   └─ mcp-config.json           └─ copilot-instructions.md          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    ▲                                        │
│                                    │ uses (reusable workflows)              │
│                                    │                                        │
│  ┌─────────────────────────────────┴───────────────────────────────────┐   │
│  │                    Target Repository (e.g., my-project)             │   │
│  │                                                                     │   │
│  │   📄 Caller Workflows Only (~35 lines each)                        │   │
│  │   ├─ copilot-coder.yml   → calls master coder workflow             │   │
│  │   └─ copilot-reviewer.yml → calls master reviewer workflow         │   │
│  │                                                                     │   │
│  │   ✨ Your Code                                                      │   │
│  │   └─ (whatever you're building!)                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Design Principles

| Principle | Implementation | Benefit |
|-----------|----------------|---------|
| **Centralized Control** | Master workflows in one repo | Update once, all repos benefit |
| **Minimal Footprint** | Only 2 small YAML files per target repo | Easy to deploy and maintain |
| **Enterprise Ready** | Works in air-gapped GHES environments | No external dependencies required |
| **Label-Driven** | Triggered by adding `copilot` label | Simple, intuitive user experience |

---

## 🤖 Copilot Coder Agent

### What It Does

The Coder Agent automatically implements code changes based on GitHub Issue descriptions. Simply write what you want, add a label, and let Copilot do the rest.

### Workflow Sequence

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Copilot Coder Workflow                              │
│                                                                             │
│   👤 User                    🔄 GitHub Actions              🤖 Copilot CLI │
│                                                                             │
│   ┌──────────────┐                                                         │
│   │ Create Issue │                                                         │
│   │ with details │                                                         │
│   └──────┬───────┘                                                         │
│          │                                                                  │
│          ▼                                                                  │
│   ┌──────────────┐                                                         │
│   │ Add 'copilot'│                                                         │
│   │    label     │────────────────────┐                                    │
│   └──────────────┘                    │                                    │
│                                       ▼                                    │
│                              ┌────────────────┐                            │
│                              │ Workflow       │                            │
│                              │ Triggers       │                            │
│                              └───────┬────────┘                            │
│                                      │                                     │
│                                      ▼                                     │
│                              ┌────────────────┐                            │
│                              │ 1. Update label│                            │
│                              │ → 'in-progress'│                            │
│                              └───────┬────────┘                            │
│                                      │                                     │
│                                      ▼                                     │
│                              ┌────────────────┐                            │
│                              │ 2. Create      │                            │
│                              │ feature branch │                            │
│                              │ copilot/{num}  │                            │
│                              └───────┬────────┘                            │
│                                      │                                     │
│                                      ▼                                     │
│                              ┌────────────────┐     ┌────────────────┐    │
│                              │ 3. Pass issue  │────▶│ Copilot CLI    │    │
│                              │ description    │     │ generates code │    │
│                              └────────────────┘     └───────┬────────┘    │
│                                                             │              │
│                                      ┌──────────────────────┘              │
│                                      ▼                                     │
│                              ┌────────────────┐                            │
│                              │ 4. Commit with │                            │
│                              │ co-author      │                            │
│                              └───────┬────────┘                            │
│                                      │                                     │
│                                      ▼                                     │
│                              ┌────────────────┐                            │
│                              │ 5. Push branch │                            │
│                              │ & create PR    │                            │
│                              └───────┬────────┘                            │
│                                      │                                     │
│                                      ▼                                     │
│                              ┌────────────────┐                            │
│                              │ 6. Update label│                            │
│                              │ → 'ready-for-  │                            │
│                              │    review'     │                            │
│                              └───────┬────────┘                            │
│          ┌───────────────────────────┘                                     │
│          ▼                                                                  │
│   ┌──────────────┐                                                         │
│   │ Review PR &  │                                                         │
│   │    Merge     │                                                         │
│   └──────────────┘                                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### How Issue Data Is Obtained

**Important**: No GitHub MCP server is used. Issue details come directly from the GitHub Actions event context:

```yaml
# These are native GitHub Actions context variables
env:
  ISSUE_NUMBER: ${{ github.event.issue.number }}
  ISSUE_TITLE: ${{ github.event.issue.title }}
  ISSUE_BODY: ${{ github.event.issue.body }}
  ISSUE_CREATOR: ${{ github.event.issue.user.login }}
```

| Data | Source | How It's Accessed |
|------|--------|-------------------|
| Issue Number | GitHub Actions Event | `github.event.issue.number` |
| Issue Title | GitHub Actions Event | `github.event.issue.title` |
| Issue Body | GitHub Actions Event | `github.event.issue.body` |
| Issue Creator | GitHub Actions Event | `github.event.issue.user.login` |
| Issue Assignee | GitHub Actions Event | `github.event.issue.assignee.login` |

### Copilot CLI Invocation

The workflow passes the issue description directly to Copilot CLI:

```bash
# Issue body is saved to a file to avoid shell injection
printf '%s' "${ISSUE_BODY}" > /tmp/issue_description.txt

# Copilot CLI is invoked with the description as a prompt
copilot -p "Implement the GitHub issue following the description details: $(cat /tmp/issue_description.txt)" \
  --add-dir "$(pwd)" \        # Give Copilot access to workspace files
  --allow-all-tools \         # Enable MCP servers (Context7, Fetch, etc.)
  --log-level all \           # Capture detailed logs
  --model "${MODEL}"          # Use configured AI model (e.g., claude-haiku-4.5)
```

### Output Files Generated

Copilot CLI is instructed (via `copilot-instructions.md`) to create two files:

| File | Purpose | Used For |
|------|---------|----------|
| `copilot-summary.md` | Implementation summary | Pull Request description |
| `commit-message.md` | Conventional commit message | Git commit message |

---

## 🔍 Copilot PR Reviewer Agent

### What It Does

The Reviewer Agent analyzes pull request changes and posts AI-generated review comments identifying security vulnerabilities, performance issues, and code quality concerns.

### Workflow Sequence

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Copilot PR Reviewer Workflow                          │
│                                                                             │
│   👤 User                    🔄 GitHub Actions              🤖 Copilot CLI │
│                                                                             │
│   ┌──────────────┐                                                         │
│   │ Create PR    │                                                         │
│   │ with changes │                                                         │
│   └──────┬───────┘                                                         │
│          │                                                                  │
│          ▼                                                                  │
│   ┌──────────────┐                                                         │
│   │ Add 'copilot'│                                                         │
│   │    label     │────────────────────┐                                    │
│   └──────────────┘                    │                                    │
│                                       ▼                                    │
│                              ┌────────────────┐                            │
│                              │ Workflow       │                            │
│                              │ Triggers       │                            │
│                              └───────┬────────┘                            │
│                                      │                                     │
│                                      ▼                                     │
│                              ┌────────────────┐                            │
│                              │ 1. Get list of │                            │
│                              │ changed files  │                            │
│                              │ (REST API)     │                            │
│                              └───────┬────────┘                            │
│                                      │                                     │
│                                      ▼                                     │
│                              ┌────────────────┐                            │
│                              │ 2. Download    │                            │
│                              │ file contents  │                            │
│                              │ (REST API)     │                            │
│                              └───────┬────────┘                            │
│                                      │                                     │
│                                      ▼                                     │
│                              ┌────────────────┐     ┌────────────────┐    │
│                              │ 3. Pass files  │────▶│ Copilot CLI    │    │
│                              │ to analyze     │     │ reviews code   │    │
│                              └────────────────┘     └───────┬────────┘    │
│                                                             │              │
│                                      ┌──────────────────────┘              │
│                                      ▼                                     │
│                              ┌────────────────┐                            │
│                              │ 4. Generate    │                            │
│                              │ analysis files │                            │
│                              │ (*_analysis.md)│                            │
│                              └───────┬────────┘                            │
│                                      │                                     │
│                                      ▼                                     │
│                              ┌────────────────┐                            │
│                              │ 5. Post review │                            │
│                              │ comments       │                            │
│                              │ (REST API)     │                            │
│                              └───────┬────────┘                            │
│          ┌───────────────────────────┘                                     │
│          ▼                                                                  │
│   ┌──────────────┐                                                         │
│   │ Review       │                                                         │
│   │ AI feedback  │                                                         │
│   └──────────────┘                                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### How PR Data Is Obtained

The Reviewer uses a **hybrid approach**:

#### 1. PR Metadata (from GitHub Actions Event Context)

```yaml
# Native GitHub Actions context - no API calls needed
github.event.pull_request.number       # PR number
github.event.pull_request.head.ref     # Source branch
github.event.pull_request.base.ref     # Target branch  
github.event.pull_request.head.sha     # Source commit SHA
github.event.repository.name           # Repository name
```

#### 2. Changed Files & Contents (from GitHub REST API)

```bash
# Get list of changed files
curl -H "Authorization: Bearer $GH_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     "$API_BASE/repos/$OWNER/$REPO/pulls/$PR_NUMBER/files"

# Download each file's content
curl -H "Authorization: Bearer $GH_TOKEN" \
     -H "Accept: application/vnd.github.v3.raw" \
     "$API_BASE/repos/$OWNER/$REPO/contents/$filepath?ref=$HEAD_SHA"
```

#### 3. Post Review Comments (via GitHub REST API)

```bash
# Post analysis as PR review comment
curl -X POST \
     -H "Authorization: Bearer $GH_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     -d '{"body": "...", "event": "COMMENT"}' \
     "$API_BASE/repos/$OWNER/$REPO/pulls/$PR_NUMBER/reviews"
```

### Data Sources Summary

| Data Needed | Source | Method |
|-------------|--------|--------|
| PR Number | GitHub Actions Event | `github.event.pull_request.number` |
| Source Branch | GitHub Actions Event | `github.event.pull_request.head.ref` |
| Target Branch | GitHub Actions Event | `github.event.pull_request.base.ref` |
| Commit SHA | GitHub Actions Event | `github.event.pull_request.head.sha` |
| **List of Changed Files** | **GitHub REST API** | `GET /repos/{owner}/{repo}/pulls/{pr}/files` |
| **File Contents** | **GitHub REST API** | `GET /repos/{owner}/{repo}/contents/{path}` |
| **Post Comments** | **GitHub REST API** | `POST /repos/{owner}/{repo}/pulls/{pr}/reviews` |

### Analysis Output Structure

```
pr-analysis/
├── source/                          # Files from the PR (HEAD branch)
│   ├── src/
│   │   ├── api/
│   │   │   └── handler.js           # Changed file
│   │   └── utils/
│   │       └── validate.py          # Changed file
│   └── pr-comments/                 # Copilot-generated analysis
│       ├── src_api_handler_js_analysis.md
│       └── src_utils_validate_py_analysis.md
├── target/                          # Files from target branch (BASE)
└── metadata/
    └── pr-info.json                 # PR metadata
```

### Example Review Comment

```markdown
# 🔬 src/api/handler.js analysis

## 📊 Overview
This file handles API request routing and response formatting.

## ⚠️ Issues and Recommendations

### 🔴 [Security]: SQL Injection vulnerability

```javascript
// Problematic code
const query = "SELECT * FROM users WHERE id = " + userId;
```

**Problem:** String concatenation allows SQL injection attacks.

**Recommendation:** Use parameterized queries.

```javascript
// Fixed code
const query = "SELECT * FROM users WHERE id = ?";
db.execute(query, [userId]);
```

### ⚡ [Performance]: Inefficient loop

```javascript
// Problematic code
for (let i = 0; i < items.length; i++) {
  results.push(await fetchItem(items[i]));
}
```

**Problem:** Sequential async calls in a loop.

**Recommendation:** Use Promise.all for parallel execution.

```javascript
// Fixed code
const results = await Promise.all(items.map(fetchItem));
```

## ✅ Summary
- **Overall Status:** ⚠️ Needs Attention
- **Priority:** High
- **Action Required:** Yes
```

---

## 🔌 MCP Servers Explained

### What is MCP?

**Model Context Protocol (MCP)** is an open standard that allows AI models to interact with external tools and data sources. MCP servers extend Copilot CLI's capabilities beyond just code generation.

### Configured MCP Servers

The project configures three MCP servers in `mcp-config.json`:

```json
{
  "mcpServers": {
    "context7": {
      "type": "local",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    },
    "fetch": {
      "type": "local",
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    },
    "time": {
      "type": "local",
      "command": "uvx",
      "args": ["mcp-server-time"]
    }
  }
}
```

### MCP Server Details

| Server | Package | Runner | Purpose | Example Use Case |
|--------|---------|--------|---------|------------------|
| **Context7** | `@upstash/context7-mcp` | `npx` (Node.js) | Fetches library documentation and best practices | "Look up React 18 useEffect patterns" |
| **Fetch** | `mcp-server-fetch` | `uvx` (Python) | Retrieves web content from URLs | "Read the API spec at https://..." |
| **Time** | `mcp-server-time` | `uvx` (Python) | Provides time-based operations | Get current timestamp |

### How MCP Servers Run

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         MCP Server Lifecycle                                │
│                                                                             │
│   Workflow Start                                                            │
│        │                                                                    │
│        ▼                                                                    │
│   ┌────────────────┐                                                       │
│   │ Install deps   │                                                       │
│   │ • Node.js 22   │ ← Required for npx (Context7)                        │
│   │ • Python + uv  │ ← Required for uvx (Fetch, Time)                     │
│   └───────┬────────┘                                                       │
│           │                                                                 │
│           ▼                                                                 │
│   ┌────────────────┐                                                       │
│   │ Fetch MCP      │                                                       │
│   │ config from    │ ← Downloaded from central GHES_CodingAgent repo      │
│   │ central repo   │                                                       │
│   └───────┬────────┘                                                       │
│           │                                                                 │
│           ▼                                                                 │
│   ┌────────────────┐         ┌────────────────┐                            │
│   │ Copilot CLI    │────────▶│ MCP Servers    │                            │
│   │ starts         │         │ spawned        │                            │
│   │                │◀────────│ on-demand      │                            │
│   └───────┬────────┘         └────────────────┘                            │
│           │                         │                                       │
│           │    When Copilot needs   │                                       │
│           │    external data...     │                                       │
│           │         ┌───────────────┘                                       │
│           │         ▼                                                       │
│           │   ┌────────────────┐                                           │
│           │   │ Context7:      │                                           │
│           │   │ "Get React     │                                           │
│           │   │  docs for      │                                           │
│           │   │  useState"     │                                           │
│           │   └────────────────┘                                           │
│           │                                                                 │
│           ▼                                                                 │
│   Workflow Complete                                                         │
│   (MCP servers terminate)                                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Points About MCP Servers

| Aspect | Details |
|--------|---------|
| **Type** | All servers are `"local"` - run as subprocesses |
| **Lifecycle** | Spawned on-demand, terminate when workflow ends |
| **Configuration** | Centrally managed in `GHES_CodingAgent` repo |
| **Updates** | Change `mcp-config.json` once, all repos benefit |
| **Optional** | Workflow functions without them (just with reduced capabilities) |

---

## 📊 Data Sources & Integration

### Why No GitHub MCP Server?

A common question: **"Why isn't there a GitHub MCP server to fetch issue/PR details?"**

The answer is **intentional design**:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Data Flow - No GitHub MCP Needed                         │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │                     GitHub Actions Runtime                          │  │
│   │                                                                     │  │
│   │   When an issue/PR is labeled, GitHub Actions automatically        │  │
│   │   provides ALL metadata in the event payload:                      │  │
│   │                                                                     │  │
│   │   github.event.issue.number     github.event.pull_request.number   │  │
│   │   github.event.issue.title      github.event.pull_request.title    │  │
│   │   github.event.issue.body       github.event.pull_request.head.sha │  │
│   │   github.event.issue.user       github.event.pull_request.base.ref │  │
│   │                                                                     │  │
│   │   ✅ NO API calls needed for basic metadata!                       │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│   For additional data (file contents, posting comments):                    │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │                     GitHub REST API (via curl)                      │  │
│   │                                                                     │  │
│   │   Simple curl commands work perfectly:                             │  │
│   │   • GET  /repos/{owner}/{repo}/pulls/{pr}/files                    │  │
│   │   • GET  /repos/{owner}/{repo}/contents/{path}                     │  │
│   │   • POST /repos/{owner}/{repo}/pulls/{pr}/reviews                  │  │
│   │                                                                     │  │
│   │   ✅ Works in air-gapped GHES environments                         │  │
│   │   ✅ No additional dependencies                                     │  │
│   │   ✅ Full control over API calls                                   │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Comparison: Event Context vs REST API vs MCP

| Approach | When to Use | Used In This Project |
|----------|-------------|---------------------|
| **GitHub Actions Event Context** | Issue/PR metadata from the triggering event | ✅ Yes - primary source |
| **GitHub REST API** | Additional data not in event (file contents, etc.) | ✅ Yes - for reviewer |
| **GitHub MCP Server** | Complex queries, search across repos, GraphQL | ❌ Not needed |

### Benefits of This Approach

| Benefit | Explanation |
|---------|-------------|
| **Simplicity** | No additional MCP server to configure or maintain |
| **GHES Compatibility** | Works in air-gapped enterprise environments |
| **Performance** | Event data is instant; no API round-trips for basic info |
| **Reliability** | Fewer moving parts = fewer points of failure |
| **Portability** | Works on any GitHub instance (GHES or github.com) |

---

## 🔒 Security Considerations

### Token Management

| Token | Purpose | Scope | Storage |
|-------|---------|-------|---------|
| `GH_TOKEN` | Repository operations | `repo`, `workflow` | Repository Secret |
| `COPILOT_TOKEN` | Copilot API access | Copilot-specific | Repository Secret |
| `CONTEXT7_API_KEY` | Context7 documentation | Context7-specific | Repository Secret (Optional) |

### Best Practices Implemented

| Practice | Implementation |
|----------|----------------|
| **Secrets never logged** | All tokens passed via environment variables |
| **Input sanitization** | Issue/PR bodies saved to files to prevent shell injection |
| **Minimal permissions** | Workflow permissions explicitly declared |
| **Token rotation** | Recommend regular PAT rotation (90+ days) |
| **Classic PAT requirement** | Fine-grained PATs have GraphQL issues on GHES |

### Workflow Permissions

```yaml
permissions:
  contents: write       # Push code to branches
  issues: write         # Update issue labels, add comments
  pull-requests: write  # Create PRs, post review comments
```

---

## ❓ Frequently Asked Questions

### General Questions

<details>
<summary><strong>Q: Can this work on github.com (not just GHES)?</strong></summary>

**A:** Yes! The workflows are designed for GHES but work on github.com as well. The only differences are:
- API base URL changes from `https://{ghes-host}/api/v3` to `https://api.github.com`
- Self-hosted runners may need to be replaced with GitHub-hosted runners

</details>

<details>
<summary><strong>Q: Why do you use Classic PAT instead of Fine-grained PAT?</strong></summary>

**A:** Fine-grained Personal Access Tokens have known issues with GraphQL operations on GHES, causing "Resource not accessible by personal access token" errors. Classic PATs with `repo` and `workflow` scopes work reliably.

</details>

<details>
<summary><strong>Q: What AI models can I use?</strong></summary>

**A:** The workflow supports multiple models via the `MODEL` environment variable:
- `claude-haiku-4.5` (default - fast, low cost)
- `claude-sonnet-4` (balanced)
- `gpt-4o` (GPT-4 equivalent)
- `o1-preview` (reasoning-focused)
- `o1-mini` (light reasoning)

</details>

### MCP Questions

<details>
<summary><strong>Q: Do I need to configure MCP servers in each repository?</strong></summary>

**A:** No! MCP configuration is **centrally managed** in the `GHES_CodingAgent` repository. The master workflow fetches `mcp-config.json` at runtime, so all repositories automatically use the latest configuration.

</details>

<details>
<summary><strong>Q: Can I add custom MCP servers?</strong></summary>

**A:** Yes! Edit `mcp-config.json` in the central `GHES_CodingAgent` repository. The change will apply to all subsequent workflow runs across all repositories.

</details>

<details>
<summary><strong>Q: What if an MCP server fails to start?</strong></summary>

**A:** The workflow will continue with reduced capabilities. MCP servers are optional enhancements - Copilot CLI can still generate code without them.

</details>

### Troubleshooting

<details>
<summary><strong>Q: The workflow isn't triggering when I add the label</strong></summary>

**A:** Check these common issues:
1. Label must be exactly `copilot` (case-sensitive)
2. Workflow file must be in `.github/workflows/`
3. Workflow must be enabled in the Actions tab
4. User must have write access to the repository

</details>

<details>
<summary><strong>Q: I get "Bad credentials" errors</strong></summary>

**A:** Your `GH_TOKEN` is likely invalid or expired:
1. Go to `https://{your-ghes}/settings/tokens`
2. Check if the token has expired
3. Verify it has `repo` and `workflow` scopes
4. Update the repository secret if needed

</details>

---

## 📚 Additional Resources

- [README.md](../README.md) - Quick start guide
- [GHES-SETUP.md](./GHES-SETUP.md) - Detailed GHES setup instructions
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Deploying to repositories
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues and solutions
- [COPILOT-REVIEWER.md](./COPILOT-REVIEWER.md) - PR Reviewer details

---

<div align="center">

**Built with ❤️ for GitHub Enterprise Server**

*Powered by GitHub Copilot CLI and Model Context Protocol*

</div>
