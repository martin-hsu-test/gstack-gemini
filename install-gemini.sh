#!/usr/bin/env bash
# ============================================================
# gstack-gemini 安裝腳本
# 將 gstack 技能以「符號連結（symlink）」方式安裝到 Gemini CLI
#
# 原理：
#   本腳本不複製檔案，而是建立 symlink：
#   gstack/.gemini/skills/gstack-xxx  ──►  ~/.gemini/skills/gstack-xxx
#   這樣修改 SKILL.md 後 Gemini CLI 會立即看到變更，不需重跑安裝。
#
# 使用方式：
#   bash install-gemini.sh
#
# 若要還原（移除所有技能）：
#   bash uninstall-gemini.sh
# ============================================================
set -e

# 取得此腳本所在目錄（即 gstack 專案根目錄）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Gemini CLI 的技能存放位置（固定路徑）
GEMINI_SKILLS_DIR="$HOME/.gemini/skills"

echo "🚀 gstack-gemini 安裝程式"
echo "=========================="
echo ""

# ── 步驟 1：確認 Gemini CLI 已安裝 ──────────────────────────
if ! command -v gemini >/dev/null 2>&1; then
  echo "❌ 找不到 Gemini CLI，請先安裝："
  echo "   npm install -g @google/gemini-cli"
  exit 1
fi

echo "✅ Gemini CLI 已安裝：$(gemini --version 2>/dev/null || echo '版本未知')"

# ── 步驟 2：確認技能檔案已產生 ──────────────────────────────
# 技能檔案位於 .gemini/skills/，由 bun run gen:skill-docs 產生
if [ ! -d "$SCRIPT_DIR/.gemini/skills" ]; then
  echo "❌ 找不到產生的技能檔案，請先執行建置："
  echo "   bun install && bun run gen:skill-docs --host gemini"
  exit 1
fi

# ── 步驟 3：建立 ~/.gemini/skills/ 目錄（若不存在）─────────
mkdir -p "$GEMINI_SKILLS_DIR"

# ── 步驟 4：為每個 gstack-* 技能目錄建立 symlink ────────────
echo ""
echo "📦 安裝技能中..."
SKILL_COUNT=0
for skill_dir in "$SCRIPT_DIR"/.gemini/skills/gstack*; do
  skill_name="$(basename "$skill_dir")"

  # 跳過 gstack-upgrade（此技能在 Gemini 版本中不適用）
  [ "$skill_name" = "gstack-upgrade" ] && continue

  target="$GEMINI_SKILLS_DIR/$skill_name"

  # 若目標已存在 symlink，先刪除舊連結再重建
  if [ -L "$target" ]; then
    rm "$target"
  elif [ -d "$target" ]; then
    # 若是真實目錄（非 symlink），跳過以免誤刪使用者資料
    echo "   ⚠️  跳過 $skill_name（目標是真實目錄，非 symlink）"
    continue
  fi

  # 建立 symlink：~/.gemini/skills/gstack-xxx → 本專案目錄
  ln -s "$skill_dir" "$target"
  SKILL_COUNT=$((SKILL_COUNT + 1))
done

echo "   ✅ 已連結 $SKILL_COUNT 個技能到 $GEMINI_SKILLS_DIR"

# ── 步驟 5：確認共用執行資源（bin、browse 等）可存取 ────────
# gstack 主技能的 symlink 同時讓 bin/ 和 browse/ 可被其他技能使用
GSTACK_RUNTIME="$GEMINI_SKILLS_DIR/gstack"
if [ -L "$GSTACK_RUNTIME" ] || [ -d "$GSTACK_RUNTIME" ]; then
  echo ""
  echo "📂 共用資源狀態："
  for asset in bin browse/dist browse/bin ETHOS.md; do
    asset_src="$SCRIPT_DIR/$asset"
    if [ -e "$asset_src" ]; then
      echo "   ✅ $asset 可透過 gstack 技能連結存取"
    fi
  done
fi

# ── 步驟 6：檢查瀏覽器執行檔（選用）───────────────────────
# browse binary 只有以下技能需要：
#   qa, browse, design-review, benchmark, canary, devex-review
# 若不用瀏覽器相關技能，可跳過此建置步驟
if [ ! -f "$SCRIPT_DIR/browse/dist/browse" ]; then
  echo ""
  echo "ℹ️  瀏覽器執行檔尚未建置（選用）"
  echo "   只有以下技能需要：qa, browse, design-review, benchmark, canary, devex-review"
  echo "   如需啟用，請執行：bun install && bun run build"
fi

echo ""
echo "🎉 安裝完成！"
echo ""
echo "驗證安裝：  gemini skills list"
echo ""
echo "可用技能（輸入 /技能名稱 呼叫）："
echo "  /gstack-review       — PR 程式碼審查"
echo "  /gstack-qa           — 自動化 QA 測試並修復"
echo "  /gstack-ship         — 完整發布工作流"
echo "  /gstack-investigate  — 系統性除錯（根本原因調查）"
echo "  /gstack-office-hours — 產品思考與創意腦力激盪"
echo "  ... 以及另外 28 個技能！"
echo ""
echo "開始使用：  gemini    然後輸入 /gstack-review"
