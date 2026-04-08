#!/usr/bin/env bash
# gstack-gemini install — link gstack skills to Gemini CLI
#
# ┌─────────────────────────────────────────────────────────────┐
# │  風險等級控制（預設：僅安裝低風險技能）                          │
# │                                                             │
# │  用法：                                                      │
# │    ./install-gemini.sh               # 僅低風險 (預設)        │
# │    RISK=medium ./install-gemini.sh   # 低風險 + 中風險        │
# │    RISK=all    ./install-gemini.sh   # 全部安裝（含高風險）     │
# │                                                             │
# │  🔴 高風險技能（RISK=all 才安裝）：                            │
# │    gstack-setup-browser-cookies — 讀取瀏覽器 Cookie          │
# │    gstack-cso          — 掃描 secrets/.env/CI pipeline       │
# │    gstack-open-gstack-browser — AI 控制真實 Chrome           │
# │                                                             │
# │  🟡 中風險技能（RISK=medium 或 RISK=all 才安裝）：             │
# │    gstack-browse       — 截圖/爬取網頁內容                    │
# │    gstack-canary       — 監控 production 截圖                │
# │    gstack-ship         — 自動 commit/push/建 PR              │
# │    gstack-land-and-deploy — 自動 merge 並部署                │
# │    gstack-qa           — 瀏覽器自動化 QA                      │
# │    gstack-devex-review — 瀏覽內部文件站測試                   │
# │    gstack-design-review — 截圖 live site 分析                │
# │    gstack-benchmark    — 對內部系統發 HTTP 測速請求            │
# │    gstack-investigate  — 深度讀取 config/log 除錯             │
# │    gstack-retro        — 讀取 git log 含敏感 commit message   │
# └─────────────────────────────────────────────────────────────┘
set -e

# 讀取風險等級參數，預設為 low（僅安裝低風險技能）
RISK="${RISK:-low}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GEMINI_SKILLS_DIR="$HOME/.gemini/skills"

echo "🚀 gstack-gemini installer"
echo "=========================="
echo "風險等級：$RISK"
echo ""

# Check Gemini CLI
if ! command -v gemini >/dev/null 2>&1; then
  echo "❌ Gemini CLI not found. Install it first:"
  echo "   npm install -g @google/gemini-cli"
  exit 1
fi

echo "✅ Gemini CLI found: $(gemini --version 2>/dev/null || echo 'unknown')"

# Check for generated skill files
if [ ! -d "$SCRIPT_DIR/.gemini/skills" ]; then
  echo "❌ Generated skills not found. Run build first:"
  echo "   bun install && bun run gen:skill-docs --host gemini"
  exit 1
fi

# Create skills directory
mkdir -p "$GEMINI_SKILLS_DIR"

# Link each skill
echo ""
echo "📦 Installing skills..."
SKILL_COUNT=0
for skill_dir in "$SCRIPT_DIR"/.gemini/skills/gstack*; do
  skill_name="$(basename "$skill_dir")"
  # 永遠跳過 upgrade（透過其他方式更新）
  [ "$skill_name" = "gstack-upgrade" ] && continue

  # 🔴 高風險技能：僅在 RISK=all 時安裝
  if [ "$RISK" != "all" ]; then
    [ "$skill_name" = "gstack-setup-browser-cookies" ] && continue  # 讀取 Cookie
    [ "$skill_name" = "gstack-cso" ] && continue                   # 掃描 secrets
    [ "$skill_name" = "gstack-open-gstack-browser" ] && continue   # AI 控制瀏覽器
  fi

  # 🟡 中風險技能：僅在 RISK=medium 或 RISK=all 時安裝
  if [ "$RISK" = "low" ]; then
    [ "$skill_name" = "gstack-browse" ] && continue
    [ "$skill_name" = "gstack-canary" ] && continue
    [ "$skill_name" = "gstack-ship" ] && continue
    [ "$skill_name" = "gstack-land-and-deploy" ] && continue
    [ "$skill_name" = "gstack-qa" ] && continue
    [ "$skill_name" = "gstack-devex-review" ] && continue
    [ "$skill_name" = "gstack-design-review" ] && continue
    [ "$skill_name" = "gstack-benchmark" ] && continue
    [ "$skill_name" = "gstack-investigate" ] && continue
    [ "$skill_name" = "gstack-retro" ] && continue
  fi
  target="$GEMINI_SKILLS_DIR/$skill_name"

  # Remove existing link/dir
  if [ -L "$target" ]; then
    rm "$target"
  elif [ -d "$target" ]; then
    echo "   ⚠️  Skipping $skill_name (directory exists, not a symlink)"
    continue
  fi

  ln -s "$skill_dir" "$target"
  SKILL_COUNT=$((SKILL_COUNT + 1))
done

echo "   ✅ Linked $SKILL_COUNT skills to $GEMINI_SKILLS_DIR"

# Link shared runtime assets (bin, browse, etc.)
GSTACK_RUNTIME="$GEMINI_SKILLS_DIR/gstack"
if [ -L "$GSTACK_RUNTIME" ] || [ -d "$GSTACK_RUNTIME" ]; then
  echo ""
  echo "📂 Runtime assets:"
  # Ensure bin/ is accessible from the gstack root skill
  for asset in bin browse/dist browse/bin ETHOS.md; do
    asset_src="$SCRIPT_DIR/$asset"
    if [ -e "$asset_src" ]; then
      echo "   ✅ $asset available via gstack skill link"
    fi
  done
fi

# Browse binary is optional — only needed for browser-based skills
# (qa, browse, design-review, benchmark, canary, devex-review)
if [ ! -f "$SCRIPT_DIR/browse/dist/browse" ]; then
  echo ""
  echo "ℹ️  Browse binary not built (optional)."
  echo "   Only needed for: qa, browse, design-review, benchmark, canary, devex-review"
  echo "   To build: cd $(basename "$SCRIPT_DIR") && bun install && bun run build"
fi

echo ""
echo "🎉 Installation complete!"
echo ""
echo "Verify with:  gemini skills list"
echo ""
echo "Available skills:"
echo "  /gstack-review      — Deep code review"
echo "  /gstack-qa          — Automated QA testing"
echo "  /gstack-ship        — Pre-flight checks & PR creation"
echo "  /gstack-investigate  — Root cause debugging"
echo "  /gstack-office-hours — Brainstorm & idea reframing"
echo "  ... and 30 more!"
echo ""
echo "Try it:  gemini    then type /gstack-review"
