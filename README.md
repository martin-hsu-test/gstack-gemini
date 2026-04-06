# gstack-gemini

> [garrytan/gstack](https://github.com/garrytan/gstack) ported for **Google Gemini CLI** — with all telemetry removed.

gstack is Garry Tan's AI coding skills collection — 35 specialist skills that turn your AI coding assistant into a virtual engineering team. This fork makes them work with [Gemini CLI](https://github.com/google-gemini/gemini-cli) and strips all telemetry/analytics for privacy.

## 繁體中文

### 簡介

這是 [garrytan/gstack](https://github.com/garrytan/gstack) 的 Gemini CLI 移植版本。原版專為 Claude Code 設計，本 fork 將所有 35 個技能轉換為 Gemini CLI 相容格式，並完全移除遙測（telemetry）功能以保護隱私安全。

### 安裝方式

**方法一：使用安裝腳本（推薦）**

```bash
git clone https://github.com/martin-hsu-test/gstack-gemini.git
cd gstack-gemini
chmod +x install-gemini.sh
./install-gemini.sh
```

**方法二：手動安裝**

```bash
git clone https://github.com/martin-hsu-test/gstack-gemini.git
cd gstack-gemini

# 建立 symlink 到 Gemini skills 目錄
mkdir -p ~/.gemini/skills
for dir in .gemini/skills/gstack*; do
  name=$(basename "$dir")
  ln -sfn "$(pwd)/$dir" "$HOME/.gemini/skills/$name"
done
```

**方法三：使用 Gemini CLI 內建指令**

```bash
git clone https://github.com/martin-hsu-test/gstack-gemini.git
cd gstack-gemini
for dir in .gemini/skills/gstack*; do
  gemini skills link "$dir"
done
```

### 驗證安裝

```bash
gemini skills list
```

應該會看到 35 個 gstack 技能全部顯示為 enabled。

### 使用方式

在 Gemini CLI 中直接呼叫技能名稱即可：

```
# 程式碼審查
請幫我 review 這個 PR

# 安全稽核
請執行 CSO 安全審查

# 調查 bug
幫我 investigate 這個錯誤

# 設計系統
幫我做 design consultation
```

### 已移除的遙測功能

- ❌ 本地 JSONL 追蹤（skill-usage.jsonl、eureka.jsonl）
- ❌ Supabase 遠端同步
- ❌ 更新檢查 ping
- ❌ 分析腳本與儀表板
- ❌ 完成事件遙測

所有資料僅留在本地，不會傳送到任何遠端伺服器。

---

## English

### Overview

This is a [garrytan/gstack](https://github.com/garrytan/gstack) port for **Google Gemini CLI**. The original was built for Claude Code — this fork converts all 35 skills to Gemini CLI format and completely removes all telemetry/analytics for privacy.

### Installation

**Method 1: Install Script (Recommended)**

```bash
git clone https://github.com/martin-hsu-test/gstack-gemini.git
cd gstack-gemini
chmod +x install-gemini.sh
./install-gemini.sh
```

**Method 2: Manual Symlinks**

```bash
git clone https://github.com/martin-hsu-test/gstack-gemini.git
cd gstack-gemini

mkdir -p ~/.gemini/skills
for dir in .gemini/skills/gstack*; do
  name=$(basename "$dir")
  ln -sfn "$(pwd)/$dir" "$HOME/.gemini/skills/$name"
done
```

**Method 3: Gemini CLI Built-in**

```bash
git clone https://github.com/martin-hsu-test/gstack-gemini.git
cd gstack-gemini
for dir in .gemini/skills/gstack*; do
  gemini skills link "$dir"
done
```

### Verify Installation

```bash
gemini skills list
```

You should see all 35 gstack skills listed as enabled.

### Available Skills (35)

| Category | Skills | Description |
|----------|--------|-------------|
| **Core** | `gstack` | Root skill — orchestrates all sub-skills |
| **Review** | `review` | Code review with spec verification |
| **Planning** | `plan-ceo-review`, `plan-eng-review`, `plan-design-review`, `plan-devex-review` | Multi-perspective plan review pipeline |
| **Design** | `design-consultation`, `design-html`, `design-review`, `design-shotgun` | Design system, HTML generation, visual QA |
| **QA** | `qa`, `qa-only`, `browse`, `benchmark` | Browser-based QA, benchmarking |
| **Security** | `cso` | OWASP + STRIDE security audit |
| **Ship** | `ship`, `land-and-deploy`, `document-release` | PR creation, deploy, docs update |
| **Debug** | `investigate`, `health` | Root cause analysis, code quality dashboard |
| **Safety** | `careful`, `freeze`, `guard`, `unfreeze` | Destructive command warnings, edit scoping |
| **Workflow** | `checkpoint`, `learn`, `retro`, `office-hours`, `autoplan` | Session management, retrospectives, brainstorming |
| **DevEx** | `devex-review` | Developer experience audit |
| **Monitor** | `canary` | Post-deploy canary monitoring |
| **Browser** | `open-gstack-browser`, `setup-browser-cookies`, `setup-deploy` | Browser launch, cookie setup |
| **Meta** | `skill-creator`, `gstack-upgrade` | Create new skills, upgrade gstack |

### Usage

Invoke skills naturally in Gemini CLI:

```
# Code review
Please review this PR

# Security audit
Run a CSO security review

# Debug
Investigate this error

# Design
Help me with design consultation

# Ship
Ship this as a PR
```

### Telemetry Removed

This fork removes **all** telemetry from the original gstack:

- ❌ Local JSONL tracking (skill-usage.jsonl, eureka.jsonl)
- ❌ Supabase remote sync
- ❌ Update-check pings
- ❌ Analytics scripts & dashboards
- ❌ Completion event telemetry

All data stays local. Nothing is sent to any remote server.

### Updating from Upstream

```bash
git fetch upstream
git merge upstream/main
# Regenerate Gemini skills (requires bun):
bun install && bun run gen:skill-docs --host gemini
```

### Requirements

- [Gemini CLI](https://github.com/google-gemini/gemini-cli) v0.1+ installed
- Git
- (Optional) [Bun](https://bun.sh/) — only needed if regenerating skills from source

## Credits

- Original: [garrytan/gstack](https://github.com/garrytan/gstack) by [Garry Tan](https://x.com/garrytan) — MIT License
- Gemini port & telemetry removal: [martin-hsu-test/gstack-gemini](https://github.com/martin-hsu-test/gstack-gemini)

## License

MIT — same as the original gstack.
