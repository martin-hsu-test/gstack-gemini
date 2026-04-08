#!/usr/bin/env bash
# gstack-gemini install — link gstack skills to Gemini CLI
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GEMINI_SKILLS_DIR="$HOME/.gemini/skills"

echo "🚀 gstack-gemini installer"
echo "=========================="
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
  # 🔴 高風險：主動存取 Cookie/secrets/瀏覽器，可能洩漏公司機密
  [ "$skill_name" = "gstack-upgrade" ] && continue
  [ "$skill_name" = "gstack-setup-browser-cookies" ] && continue
  [ "$skill_name" = "gstack-cso" ] && continue
  [ "$skill_name" = "gstack-open-gstack-browser" ] && continue
  # 🟡 中風險：截圖/爬取內部頁面、自動部署、深度讀取 config
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
