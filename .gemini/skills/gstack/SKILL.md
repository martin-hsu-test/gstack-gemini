---
name: gstack
description: |
  gstack 技能套件的主入口。用於 Gemini CLI 的快速開發工具集，涵蓋瀏覽器測試、
  設計審查、程式碼品質、部署流程等 33 個專業技能。各子技能依情境自動啟動。
  適用場景：測試網站、驗證部署、審查設計、執行品質檢查、提交程式碼、監控部署。
---

## Preamble (run first)

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
GSTACK_ROOT="$HOME/.gemini/skills/gstack"
[ -n "$_ROOT" ] && [ -d "$_ROOT/.gemini/skills/gstack" ] && GSTACK_ROOT="$_ROOT/.gemini/skills/gstack"
GSTACK_BIN="$GSTACK_ROOT/bin"
GSTACK_BROWSE="$GSTACK_ROOT/browse/dist"
GSTACK_DESIGN="$GSTACK_ROOT/design/dist"
_UPD=$($GSTACK_BIN/gstack-update-check 2>/dev/null || .gemini/skills/gstack/bin/gstack-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
mkdir -p ~/.gstack/sessions
touch ~/.gstack/sessions/"$PPID"
_SESSIONS=$(find ~/.gstack/sessions -mmin -120 -type f 2>/dev/null | wc -l | tr -d ' ')
find ~/.gstack/sessions -mmin +120 -type f -exec rm {} + 2>/dev/null || true
_PROACTIVE=$($GSTACK_BIN/gstack-config get proactive 2>/dev/null || echo "true")
_PROACTIVE_PROMPTED=$([ -f ~/.gstack/.proactive-prompted ] && echo "yes" || echo "no")
_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $_BRANCH"
_SKILL_PREFIX=$($GSTACK_BIN/gstack-config get skill_prefix 2>/dev/null || echo "false")
echo "PROACTIVE: $_PROACTIVE"
echo "PROACTIVE_PROMPTED: $_PROACTIVE_PROMPTED"
echo "SKILL_PREFIX: $_SKILL_PREFIX"
source <($GSTACK_BIN/gstack-repo-mode 2>/dev/null) || true
REPO_MODE=${REPO_MODE:-unknown}
echo "REPO_MODE: $REPO_MODE"
_LAKE_SEEN=$([ -f ~/.gstack/.completeness-intro-seen ] && echo "yes" || echo "no")
echo "LAKE_INTRO: $_LAKE_SEEN"
_SESSION_ID="$$-$(date +%s)"
# Learnings count
eval "$($GSTACK_BIN/gstack-slug 2>/dev/null)" 2>/dev/null || true
_LEARN_FILE="${GSTACK_HOME:-$HOME/.gstack}/projects/${SLUG:-unknown}/learnings.jsonl"
if [ -f "$_LEARN_FILE" ]; then
  _LEARN_COUNT=$(wc -l < "$_LEARN_FILE" 2>/dev/null | tr -d ' ')
  echo "LEARNINGS: $_LEARN_COUNT entries loaded"
  if [ "$_LEARN_COUNT" -gt 5 ] 2>/dev/null; then
    $GSTACK_BIN/gstack-learnings-search --limit 3 2>/dev/null || true
  fi
else
  echo "LEARNINGS: 0"
fi
# Session timeline: record skill start (local-only, never sent anywhere)
$GSTACK_BIN/gstack-timeline-log '{"skill":"gstack","event":"started","branch":"'"$_BRANCH"'","session":"'"$_SESSION_ID"'"}' 2>/dev/null &
# Check if CLAUDE.md has routing rules
_HAS_ROUTING="no"
if [ -f CLAUDE.md ] && grep -q "## Skill routing" CLAUDE.md 2>/dev/null; then
  _HAS_ROUTING="yes"
fi
_ROUTING_DECLINED=$($GSTACK_BIN/gstack-config get routing_declined 2>/dev/null || echo "false")
echo "HAS_ROUTING: $_HAS_ROUTING"
echo "ROUTING_DECLINED: $_ROUTING_DECLINED"
# Vendoring deprecation: detect if CWD has a vendored gstack copy
_VENDORED="no"
if [ -d ".gemini/skills/gstack" ] && [ ! -L ".gemini/skills/gstack" ]; then
  if [ -f ".gemini/skills/gstack/VERSION" ] || [ -d ".gemini/skills/gstack/.git" ]; then
    _VENDORED="yes"
  fi
fi
echo "VENDORED_GSTACK: $_VENDORED"
# Detect spawned session (OpenClaw or other orchestrator)
[ -n "$OPENCLAW_SESSION" ] && echo "SPAWNED_SESSION: true" || true
```

如果 `PROACTIVE` 為 `"false"`，則不要主動建議 gstack 技能，也不要根據對話上下文自動調用技能。僅運行用戶明確輸入的技能（例如 `/qa`、`/ship`）。如果您原本會自動調用某個技能，請改為簡要說明：「我認為 `/skillname` 可能有幫助——需要我運行它嗎？」並等待確認。用戶已選擇退出主動行為。

如果 `SKILL_PREFIX` 為 `"true"`，用戶已為技能名稱添加命名空間。在建議或調用其他 gstack 技能時，使用 `/gstack-` 前綴（例如 `/gstack-qa` 而不是 `/qa`，`/gstack-ship` 而不是 `/ship`）。磁碟路徑不受影響——始終使用 `$GSTACK_ROOT/[skill-name]/SKILL.md` 來讀取技能檔案。

如果輸出顯示 `UPGRADE_AVAILABLE <old> <new>`：讀取 `$GSTACK_ROOT/gstack-upgrade/SKILL.md` 並遵循「內聯升級流程」（如果已配置則自動升級，否則使用 AskUserQuestion 提供 4 個選項，如果拒絕則寫入暫停狀態）。如果顯示 `JUST_UPGRADED <from> <to>`：告訴用戶「正在運行 gstack v{to}（剛剛更新！）」並繼續。

如果 `LAKE_INTRO` 為 `no`：在繼續之前，介紹完整性原則。告訴用戶：「gstack 遵循 **煮沸整個湖** 原則——當 AI 使邊際成本接近零時，始終做完整的事情。了解更多：https://garryslist.org/posts/boil-the-ocean」然後提議在其默認瀏覽器中打開該文章：

```bash
open https://garryslist.org/posts/boil-the-ocean
touch ~/.gstack/.completeness-intro-seen
```

僅在用戶同意時運行 `open`。始終運行 `touch` 以標記為已查看。這只會發生一次。

如果 `VENDORED_GSTACK` 為 `yes`：在繼續之前告知用戶。說：

「⚠️ **您的項目有一個已棄用的 gstack 副本。** gstack 現在從 `~/.gemini/skills/gstack` 運行（自動更新）。請運行 `/gstack-upgrade vendor-remove` 來清理舊的副本。」

不要在每個響應中都提到這一點——只在檢測到時提一次，然後繼續。

如果 `HAS_ROUTING` 為 `yes` 且 `ROUTING_DECLINED` 為 `false`：遵循 CLAUDE.md 中的路由規則。該文件包含用戶定義的 gstack 調用模式（例如「推送到主分支時始終運行 `/canary`」）。用戶已選擇加入自定義路由。

如果 `HAS_ROUTING` 為 `no` 且 `ROUTING_DECLINED` 為 `false` 且 `PROACTIVE_PROMPTED` 為 `no`：僅在此會話中提示一次。說：

「💡 gstack 可以從 CLAUDE.md 學習您的路由偏好（例如『在合併 PR 後始終運行 canary 檢查』）。想要設置嗎？」

如果用戶說是：打開 `$GSTACK_ROOT/routing/SKILL.md` 並運行安裝流程。如果用戶說否：運行 `gstack-config set routing_declined true` 並繼續。無論哪種方式，都運行 `touch ~/.gstack/.proactive-prompted` 以防止再次詢問。

---

## 核心概念

### Browse 工具整合

gstack 技能大量使用 browse 守護程序進行視覺驗證。當技能請求「打開瀏覽器並檢查 X」時：

1. 運行 `node $GSTACK_BROWSE/start.js` 啟動守護程序（如果尚未運行）
2. 使用 `node $GSTACK_BROWSE/action.js [command]` 運行操作
3. 守護程序在會話之間保持打開狀態以提高速度（~100 毫秒/命令）
4. 截圖保存到 `.gstack/screenshots/[timestamp].png`

**可用操作：**

```bash
# 導航和基本操作
node $GSTACK_BROWSE/action.js goto <url>
node $GSTACK_BROWSE/action.js screenshot [selector]  # 可選的元素選擇器
node $GSTACK_BROWSE/action.js click <selector>
node $GSTACK_BROWSE/action.js type <selector> <text>
node $GSTACK_BROWSE/action.js wait <ms>
node $GSTACK_BROWSE/action.js refresh

# 狀態檢查
node $GSTACK_BROWSE/action.js get-text <selector>
node $GSTACK_BROWSE/action.js exists <selector>  # 返回 "true" 或 "false"
node $GSTACK_BROWSE/action.js get-property <selector> <property>

# 效能和控制台
node $GSTACK_BROWSE/action.js get-metrics  # Core Web Vitals
node $GSTACK_BROWSE/action.js get-console  # 控制台錯誤/警告

# 生命週期
node $GSTACK_BROWSE/action.js close  # 關閉瀏覽器並清理
```

**最佳實踐：**

- 在操作之間使用 `wait` 以便動態內容載入
- 使用 `screenshot` 為錯誤報告提供視覺證據
- 始終在技能結束時運行 `close` 以清理

### 狀態標記

技能使用標準化標記報告進度：

- `DONE` 完成：任務已成功完成，無問題
- `DONE_WITH_CONCERNS` 完成但有疑慮：任務已完成，但有小問題（記錄在 CONCERNS.md）
- `BLOCKED` 阻塞：無法繼續，需要用戶輸入或外部修復
- `PARTIAL` 部分：某些項目已完成，其他項目被跳過或失敗
- `NEEDS_CONTEXT` 需要上下文：在繼續之前需要額外的信息

當技能返回 `BLOCKED` 或 `NEEDS_CONTEXT` 時，向用戶解釋需要什麼並停止。不要猜測或繼續執行不完整的工作。

### 交接模式

gstack 技能遵循交接模式以實現連續工作流程：

```
/plan-ceo-review  →  /plan-design-review  →  /design-html  →  /qa  →  /ship
```

每個技能在其輸出中寫入「下一個建議的技能：X」。閱讀此內容並提議下一步（如果 `PROACTIVE` 為 `true`）或等待用戶命令。

範例：

```
計劃已通過設計審查。下一個建議的技能：/design-html
```

您會說：「設計審查完成！準備好運行 `/design-html` 將計劃轉換為 HTML 了嗎？」

### 始終提交修復

當技能修復問題時（例如 `/qa` 修復視覺錯誤、`/health` 修復 lint 錯誤、`/design-review` 修復間距問題），它會在每次修復後提交。這樣可以建立原子修復歷史記錄並簡化審查。

提交訊息格式：

```
[skill-name] 修復：簡短描述

詳細說明修復的內容。

Co-authored-by: gstack <gstack@example.com>
```

不要對此進行編輯或重新表述——使用技能提供的確切提交訊息。

---

## 完整性原則

gstack 遵循 **煮沸整個湖** 原則：當 AI 使某事的邊際成本接近零時，始終做完整的事情。不要僅僅抽查或修復您看到的第一個問題——運行完整的審計、修復所有實例、測試所有邊緣情況。

**範例：**

- ❌ 「我看到登錄頁面有一個間距問題」 → 手動修復
- ✅ 「運行 `/design-review` 審計所有頁面的間距不一致」 → 自動修復所有問題

用戶應該期望完整的結果，而不是部分的建議。

---

## 何時使用 gstack 技能

**您應該調用技能當：**

1. 用戶明確請求它（「運行 `/qa`」、「檢查設計」）
2. 任務與技能的核心能力匹配（「測試登錄流程」 → `/browse`）
3. 技能的「使用時機」或「主動建議時機」部分與情況匹配
4. `PROACTIVE` 為 `true` 且用戶的意圖清晰

**您不應該調用技能當：**

1. `PROACTIVE` 為 `false`（改為建議並等待確認）
2. 任務很簡單，您可以更快地完成（讀取 1-2 個文件、小編輯）
3. 技能的「不應建議時機」部分與情況匹配
4. 用戶明確表示「不使用技能」或「手動執行」

**不確定時：** 簡要建議該技能（「我認為 `/health` 可以在這裡提供幫助」）並讓用戶決定。

---

## 技能清單

### 設計與實作

#### `/design-consultation`
**功能：** 設計諮詢——了解您的產品，研究景觀，提出完整的設計系統（美學、排版、顏色、佈局、間距、動作），並生成字體和顏色預覽頁面。創建 DESIGN.md 作為項目的設計真實來源。對於現有網站，使用 `/plan-design-review` 來推斷系統。

**使用時機：** 「設計系統」、「品牌指南」或「創建 DESIGN.md」。

**主動建議時機：** 在沒有現有設計系統或 DESIGN.md 的情況下開始新項目的 UI 時。

**語音觸發：** 無

---

#### `/design-shotgun`
**功能：** 設計散彈槍——生成多個 AI 設計變體，打開比較面板，收集結構化反饋並迭代。您可以隨時運行的獨立設計探索。

**使用時機：** 「探索設計」、「顯示選項」、「設計變體」、「視覺頭腦風暴」或「我不喜歡它的外觀」。

**主動建議時機：** 當用戶描述 UI 功能但尚未看到它可能的樣子時。

**語音觸發：** 無

---

#### `/design-html`
**功能：** 設計最終定稿——生成生產級 Pretext 原生 HTML/CSS。使用來自 `/design-shotgun` 的批准模型、來自 `/plan-ceo-review` 的 CEO 計劃、來自 `/plan-design-review` 的設計審查上下文，或從頭開始使用用戶描述。文本實際重排，高度計算，佈局動態。30KB 開銷，零依賴。智能 API 路由——為每種設計類型選擇正確的 Pretext 模式。

**使用時機：** 「完成此設計」、「將其轉換為 HTML」、「為我構建一個頁面」、「實施此設計」或在任何規劃技能之後。

**主動建議時機：** 當用戶批准設計或計劃準備就緒時。

**語音觸發：** 「構建設計」、「編碼模型」、「使其真實」

---

#### `/design-review`
**功能：** 設計師之眼 QA——發現視覺不一致、間距問題、層次結構問題、AI 粗糙模式和緩慢的交互——然後修復它們。迭代修復源代碼中的問題，以原子方式提交每個修復並使用前後截圖重新驗證。對於計劃模式設計審查（實施之前），使用 `/plan-design-review`。

**使用時機：** 「審計設計」、「視覺 QA」、「檢查它是否看起來不錯」或「設計打磨」。

**主動建議時機：** 當用戶提到視覺不一致或想要打磨實時網站的外觀時。

**語音觸發：** 無

---

### 品質與審查

#### `/qa`
**功能：** 手動 QA 工作流程——在瀏覽器中打開網站，測試關鍵用戶流程（註冊、登錄、主要功能），截取錯誤截圖，在 BUGS.md 中記錄問題並附上證據，修復發現的問題。迭代直到沒有阻塞問題。

**使用時機：** 「測試網站」、「QA 此功能」、「檢查錯誤」、「手動測試」。

**主動建議時機：** 在發送 PR、部署到生產環境或用戶報告「它不起作用」之後。

**語音觸發：** 「測試它」、「檢查錯誤」

---

#### `/health`
**功能：** 代碼質量儀表板。包裝現有項目工具（類型檢查器、linter、測試運行器、死代碼檢測器、shell linter），計算加權綜合 0-10 分數，並隨時間跟蹤趨勢。

**使用時機：** 「健康檢查」、「代碼質量」、「代碼庫有多健康」、「運行所有檢查」、「質量評分」。

**主動建議時機：** 在大型重構或合併來自外部貢獻者的 PR 之後。

**語音觸發：** 無

---

#### `/codex`
**功能：** OpenAI Codex CLI 包裝器——三種模式。代碼審查：通過 `codex review` 進行獨立差異審查，並帶有通過/失敗門。挑戰：試圖破壞您代碼的對抗模式。諮詢：詢問 codex 任何問題，並提供會話連續性以進行後續跟進。「200 IQ 自閉症開發者」第二意見。

**使用時機：** 「codex 審查」、「codex 挑戰」、「詢問 codex」、「第二意見」或「諮詢 codex」。

**主動建議時機：** 在棘手的調試問題或架構決策之後。

**語音觸發：** 「code x」、「code ex」、「獲得另一個意見」

---

#### `/cso`
**功能：** 首席安全官模式。基礎設施優先的安全審計：機密考古、依賴供應鏈、CI/CD 管道安全、LLM/AI 安全、技能供應鏈掃描，以及 OWASP Top 10、STRIDE 威脅建模和主動驗證。兩種模式：每日（零噪音，8/10 置信度門）和全面（每月深度掃描，2/10 門檻）。跨審計運行的趨勢跟蹤。

**使用時機：** 「安全審計」、「威脅模型」、「滲透測試審查」、「OWASP」、「CSO 審查」。

**主動建議時機：** 在發佈之前、添加新依賴項之後或處理敏感數據時。

**語音觸發：** 「see-so」、「see so」、「安全審查」、「安全檢查」、「漏洞掃描」、「運行安全」

---

### 測試與品質保證

#### `/browse`
**功能：** 用於 QA 測試和網站狗食的快速無頭瀏覽器。導航頁面，與元素交互，驗證狀態，比較前後差異，截取帶註釋的截圖，測試響應式佈局、表單、上傳、對話框，並捕獲錯誤證據。

**使用時機：** 被要求打開或測試網站、驗證部署、狗食用戶流程或使用截圖提交錯誤時。

**主動建議時機：** 當用戶提到「它看起來不對」、「測試這個」或「截圖」時。

**語音觸發：** 無

---

#### `/benchmark`
**功能：** 使用 browse 守護程序進行效能回歸檢測。建立頁面加載時間、Core Web Vitals 和資源大小的基線。在每個 PR 上比較前後。隨時間跟蹤效能趨勢。

**使用時機：** 「效能」、「基準測試」、「頁面速度」、「lighthouse」、「web vitals」、「包大小」、「加載時間」。

**主動建議時機：** 在添加新依賴項、重構渲染邏輯或用戶報告「速度慢」之後。

**語音觸發：** 「速度測試」、「檢查效能」

---

### 基礎設施與部署

#### `/ship`
**功能：** 端到端發佈工作流程。運行測試和 linter，暫存更改，編寫詳細的提交訊息，推送到功能分支，創建 PR 並附上完整描述、測試計劃和截圖，等待 CI，可選地合併並驗證部署。

**使用時機：** 「發佈它」、「創建 PR」、「提交此項」、「推送代碼」、「準備好進行審查」。

**主動建議時機：** 當用戶說「完成」、「準備好」或在運行 `/qa` 且無錯誤之後。

**語音觸發：** 「發送它」、「準備好進行審查」

---

#### `/land-and-deploy`
**功能：** 合併和部署工作流程。合併 PR，等待 CI 和部署，通過 canary 檢查驗證生產健康。在 `/ship` 創建 PR 後接管。

**使用時機：** 「合併」、「著陸」、「部署」、「合併並驗證」、「著陸它」、「將其發佈到生產環境」。

**主動建議時機：** 在 PR 被批准並且 CI 通過之後。

**語音觸發：** 無

---

#### `/canary`
**功能：** 部署後 canary 監控。使用 browse 守護程序監視實時應用程序的控制台錯誤、效能回歸和頁面故障。定期截取截圖，與部署前基線進行比較，並對異常情況發出警報。

**使用時機：** 「監控部署」、「canary」、「部署後檢查」、「監視生產」、「驗證部署」。

**主動建議時機：** 在 `/land-and-deploy` 完成或用戶推送到主分支之後。

**語音觸發：** 無

---

### 規劃與策略

#### `/plan-ceo-review`
**功能：** CEO 視角計劃審查——評估用戶價值、範圍控制、隱藏債務和發佈時間表。通過/失敗門：清晰的範圍和可衡量的價值。如果通過，寫入 PLAN.md 並建議 `/plan-design-review`。

**使用時機：** 「審查此計劃」、「這值得構建嗎」、「CEO 審查」、「範圍檢查」。

**主動建議時機：** 當用戶描述新功能或重大重構時。

**語音觸發：** 無

---

#### `/plan-design-review`
**功能：** 設計師視角計劃審查——評估視覺層次結構、間距系統、組件選擇和實施可行性。通過/失敗門：設計系統一致性和清晰的視覺規範。如果通過，更新 PLAN.md 並建議 `/plan-eng-review`。

**使用時機：** 「設計審查」、「這看起來不錯嗎」、「檢查設計」。

**主動建議時機：** 在 `/plan-ceo-review` 通過或用戶描述 UI 更改之後。

**語音觸發：** 無

---

#### `/plan-eng-review`
**功能：** 工程師視角計劃審查——評估技術可行性、架構適配、測試策略和邊緣情況。通過/失敗門：清晰的實施路徑且無阻塞問題。如果通過，更新 PLAN.md 並建議 `/plan-devex-review`。

**使用時機：** 「工程審查」、「這可行嗎」、「技術審查」。

**主動建議時機：** 在 `/plan-design-review` 通過或用戶描述技術方法之後。

**語音觸發：** 無

---

#### `/plan-devex-review`
**功能：** DevEx 視角計劃審查——評估開發者人體工學、API 設計、文檔質量和入職時間。通過/失敗門：清晰的開發者路徑且無摩擦。如果通過，更新 PLAN.md 並建議開始實施。

**使用時機：** 「DevEx 審查」、「檢查 DX」、「開發者體驗」。

**主動建議時機：** 在 `/plan-eng-review` 通過或構建面向開發者的 API/工具時。

**語音觸發：** 「dx 審查」、「檢查開發者體驗」

---

#### `/devex-review`
**功能：** 實時開發者體驗審計。使用 browse 工具實際測試開發者體驗：導航文檔，嘗試入門流程，計時 TTHW，截取錯誤訊息截圖，評估 CLI 幫助文本。生成帶有證據的 DX 記分卡。如果存在 `/plan-devex-review` 分數，則與之比較（迴旋鏢：計劃說 3 分鐘，實際說 8 分鐘）。

**使用時機：** 「測試 DX」、「DX 審計」、「開發者體驗測試」或「嘗試入職」。

**主動建議時機：** 在發佈面向開發者的功能之後。

**語音觸發：** 「dx 審計」、「測試開發者體驗」、「嘗試入職」、「開發者體驗測試」

---

#### `/office-hours`
**功能：** YC Office Hours——兩種模式。創業公司模式：六個強制性問題，揭示需求現實、現狀、絕望的具體性、最窄楔子、觀察和未來適應性。構建者模式：為副項目、黑客馬拉松、學習和開源進行設計思維頭腦風暴。保存設計文檔。

**使用時機：** 「頭腦風暴此項」、「我有一個想法」、「幫我思考這個問題」、「辦公時間」或「這值得構建嗎」。

**主動建議時機：** 當用戶描述新產品想法、詢問某事是否值得構建、希望在任何代碼編寫之前考慮不存在的事物的設計決策，或在 `/plan-ceo-review` 或 `/plan-eng-review` 之前探索概念時。

**語音觸發：** 無

---

#### `/autoplan`
**功能：** 自動審查管道——從磁碟讀取完整的 CEO、設計、工程和 DX 審查技能，並使用 6 個決策原則按順序運行它們並進行自動決策。在最終批准門顯示品味決策（接近的方法、邊緣範圍、codex 分歧）。一個命令，完全審查的計劃輸出。

**使用時機：** 「自動審查」、「autoplan」、「運行所有審查」、「自動審查此計劃」或「為我做決定」。

**主動建議時機：** 當用戶有計劃文件並希望運行完整的審查流程而無需回答 15-30 個中間問題時。

**語音觸發：** 「auto plan」、「automatic review」

---

### 工作流程與元

#### `/checkpoint`
**功能：** 保存和恢復工作狀態檢查點。捕獲 git 狀態、已做出的決策和剩餘工作，以便您可以準確地從離開的地方繼續——即使跨分支之間的 Conductor 工作空間交接。

**使用時機：** 「checkpoint」、「保存進度」、「我在哪裡」、「恢復」、「我在做什麼」或「從我離開的地方繼續」。

**主動建議時機：** 當會話結束、用戶切換上下文或長時間休息之前時。

**語音觸發：** 無

---

#### `/learn`
**功能：** 管理項目學習。審查、搜索、修剪和導出 gstack 在會話之間學到的內容。

**使用時機：** 「我們學到了什麼」、「顯示學習」、「修剪陳舊的學習」或「導出學習」。

**主動建議時機：** 當用戶詢問過去的模式或想知道「我們之前沒有修復這個嗎？」時。

**語音觸發：** 無

---

#### `/document-release`
**功能：** 發佈後文檔更新。讀取所有項目文檔，交叉引用差異，更新 README/ARCHITECTURE/CONTRIBUTING/CLAUDE.md 以匹配已發佈的內容，打磨 CHANGELOG 語氣，清理 TODOS，並可選地提升 VERSION。

**使用時機：** 「更新文檔」、「同步文檔」或「發佈後文檔」。

**主動建議時機：** 在合併 PR 或發佈代碼之後。

**語音觸發：** 無

---

#### `/gstack-upgrade`
**功能：** 將 gstack 升級到最新版本。檢測全域與供應商安裝，運行升級並顯示新增功能。

**使用時機：** 「升級 gstack」、「更新 gstack」或「獲取最新版本」。

**主動建議時機：** 在檢測到 `UPGRADE_AVAILABLE` 時。

**語音觸發：** 「upgrade the tools」、「update the tools」、「gee stack upgrade」、「g stack upgrade」

---

#### `/careful`
**功能：** 破壞性命令的安全護欄。在 `rm -rf`、`DROP TABLE`、force-push、`git reset --hard`、`kubectl delete` 和類似的破壞性操作之前發出警告。用戶可以覆蓋每個警告。

**使用時機：** 觸碰生產環境、調試實時系統或在共享環境中工作時。被要求「小心」、「安全模式」、「生產模式」或「小心模式」時。

**主動建議時機：** 當用戶即將推送到主分支、刪除文件或運行數據庫遷移時。

**語音觸發：** 無

---

#### `/freeze`
**功能：** 在會話期間將文件編輯限制到特定目錄。阻止在允許路徑之外進行編輯和寫入。在調試時使用以防止意外「修復」不相關的代碼，或當您希望將更改範圍限制到一個模組時。

**使用時機：** 「freeze」、「限制編輯」、「僅編輯此文件夾」或「鎖定編輯」。

**主動建議時機：** 在調試單個模組或用戶說「不要觸碰 X」時。

**語音觸發：** 無

---

#### `/guard`
**功能：** 完整安全模式：破壞性命令警告 + 目錄範圍的編輯。結合 `/careful`（在 `rm -rf`、`DROP TABLE`、force-push 等之前發出警告）與 `/freeze`（阻止在指定目錄之外進行編輯）。在觸碰生產環境或調試實時系統時使用以實現最大安全性。

**使用時機：** 「guard 模式」、「完整安全」、「鎖定它」或「最大安全」。

**主動建議時機：** 在調試生產問題或用戶說「不要破壞任何東西」時。

**語音觸發：** 無

---

#### `/investigate`
**功能：** 系統化調試與根本原因調查。四個階段：調查、分析、假設、實施。鐵律：沒有根本原因就不修復。

**使用時機：** 「調試這個」、「修復這個錯誤」、「為什麼這個壞了」、「調查此錯誤」或「根本原因分析」。

**主動建議時機：** 當用戶報告錯誤、500 錯誤、堆棧跟蹤、意外行為、「昨天還能用」或正在排除故障為什麼某些東西停止工作時，主動調用此技能（不要直接調試）。

**語音觸發：** 無

---

#### `/open-gstack-browser`
**功能：** 啟動 GStack Browser——內置側邊欄擴展的 AI 控制 Chromium。打開一個可見的瀏覽器窗口，您可以實時觀看每個操作。側邊欄顯示實時活動源和聊天。內置反機器人隱身。

**使用時機：** 「打開 gstack 瀏覽器」、「啟動瀏覽器」、「連接 chrome」、「打開 chrome」、「真實瀏覽器」、「啟動 chrome」、「側面板」或「控制我的瀏覽器」。

**主動建議時機：** 當用戶需要檢查需要 JavaScript 或身份驗證的網站，或希望觀看測試運行時。

**語音觸發：** 「顯示瀏覽器」

---

## 技能路由（CLAUDE.md）

如果 `HAS_ROUTING` 為 `yes`：項目有一個帶有 `## Skill routing` 部分的 CLAUDE.md 文件。這定義了用戶偏好的 gstack 調用模式。

**範例規則：**

```markdown
## Skill routing

- 在合併 PR 後，始終運行 `/canary` 監控生產
- 在推送到主分支後，運行 `/benchmark` 檢查效能回歸
- 在創建面向公眾的頁面後，運行 `/design-review` 檢查視覺一致性
```

解析這些規則並遵循它們。用戶已選擇加入自定義路由。

**設置流程：**（僅當 `HAS_ROUTING` 為 `no` 且 `ROUTING_DECLINED` 為 `false` 且 `PROACTIVE_PROMPTED` 為 `no` 時）

1. 詢問用戶是否要設置路由規則
2. 如果是：打開 `$GSTACK_ROOT/routing/SKILL.md` 並遵循安裝流程
3. 如果否：運行 `gstack-config set routing_declined true`
4. 無論哪種方式：運行 `touch ~/.gstack/.proactive-prompted`

---

## 主動建議

如果 `PROACTIVE` 為 `true`：根據對話上下文主動建議技能。使用每個技能的「主動建議時機」部分來指導您。

**何時建議：**

- 用戶的意圖清楚地與技能的用例匹配
- 技能可以提供用戶可能不知道的價值
- 任務受益於自動化（例如完整的 QA 審計與手動檢查）

**如何建議：**

- 簡要說明原因（「我注意到您推送了一個視覺更改——`/design-review` 可以捕獲不一致之處」）
- 提出運行它（「準備好運行 `/design-review` 了嗎？」）
- 如果用戶說是：運行技能
- 如果用戶說否：繼續不使用技能

**不要過度建議：**

- 每轉最多提及 1-2 個技能
- 如果用戶拒絕技能兩次，停止為該會話建議它
- 不要為簡單的任務建議技能（讀取文件、小編輯）

---

## 使用規則

1. **閱讀完整的技能文件：** 在運行技能之前，閱讀 `$GSTACK_ROOT/[skill-name]/SKILL.md` 以了解其完整的使用說明。不要假設——技能經常更新。

2. **遵循輸出：** 技能在其輸出中提供明確的下一步驟（「下一個建議的技能：X」、「BLOCKED：需要 Y」）。閱讀並遵循它們。

3. **不要混淆手動與技能工作：** 如果技能處理任務（例如 `/ship` 創建 PR），不要手動執行（不要運行 `git commit`、`gh pr create`）。讓技能完成其工作。

4. **尊重 PROACTIVE 設置：** 如果 `PROACTIVE` 為 `false`，僅在用戶明確請求時才運行技能。不要自動調用。

5. **使用 SKILL_PREFIX：** 如果 `SKILL_PREFIX` 為 `true`，在調用技能時使用 `/gstack-qa` 而不是 `/qa`。磁碟路徑保持不變。

6. **檢查依賴項：** 某些技能需要其他技能（例如 `/design-html` 在 `/plan-design-review` 之後效果最佳）。如果技能說「首先運行 X」，請遵循它。

7. **清理：** 始終在技能末尾關閉 browse 守護程序（`node $GSTACK_BROWSE/action.js close`）以防止資源洩漏。

---

## 多技能編排

某些工作流程需要鏈接技能：

```
/office-hours  →  /plan-ceo-review  →  /plan-design-review  →  /design-html  →  /qa  →  /ship  →  /land-and-deploy  →  /canary
```

**規則：**

- 按順序運行技能——不要跳過步驟（例如不要在沒有 `/plan-design-review` 的情況下運行 `/design-html`）
- 檢查每個技能的輸出狀態（`DONE`、`BLOCKED` 等）
- 如果技能返回 `BLOCKED` 或 `NEEDS_CONTEXT`，停止並向用戶詢問
- 如果技能建議下一個技能，遵循它（如果 `PROACTIVE` 為 `true` 則提議，否則等待命令）

**範例流程：**

1. 用戶：「構建一個登錄頁面」
2. 您：「讓我們從 `/office-hours` 開始頭腦風暴設計」
3. 運行 `/office-hours` → 輸出：「下一個建議的技能：`/plan-ceo-review`」
4. 您：「Office hours 完成！準備好運行 `/plan-ceo-review` 來驗證計劃了嗎？」
5. 用戶：「是」
6. 運行 `/plan-ceo-review` → 輸出：「通過。下一個建議的技能：`/plan-design-review`」
7. 繼續鏈...

---

## 學習系統

gstack 在會話之間存儲項目特定的學習（模式、決策、陷阱）。

**位置：** `~/.gstack/projects/[slug]/learnings.jsonl`

**何時顯示學習：**

- 如果 preamble 輸出顯示 `LEARNINGS: N entries loaded` 且 N > 5
- 前 3 個相關學習自動顯示
- 範例輸出：

```
LEARNINGS: 12 entries loaded
1. [2024-01-15] 認證：始終在 API 路由中檢查 session.user — 我們在 /api/profile 中忘記了這一點
2. [2024-01-10] 測試：模擬 Stripe webhook 事件以進行付款測試 — 使用 stripe-mock
3. [2024-01-08] 部署：在推送到生產之前運行 `/canary` — 上次捕獲了一個關鍵的 CSS 錯誤
```

**在代碼中使用學習：**

- 如果學習提到特定的模式或陷阱，在編寫代碼時應用它
- 如果學習說「始終做 X」，在相關任務中做 X
- 如果學習說「避免 Y」，不要做 Y

**添加新學習：**

```bash
$GSTACK_BIN/gstack-learnings-add "類別：簡短標題 — 詳細說明。範例或代碼片段。"
```

範例：

```bash
$GSTACK_BIN/gstack-learnings-add "測試：模擬時間相關測試的日期 — 使用 jest.useFakeTimers() 而不是實際延遲。範例：jest.useFakeTimers(); jest.advanceTimersByTime(1000);"
```

**搜索學習：**

```bash
$GSTACK_BIN/gstack-learnings-search "query" --limit 5
```

---

## 導航

**技能位置：** `$GSTACK_ROOT/[skill-name]/SKILL.md`

**範例：**

- `/qa` → `$GSTACK_ROOT/qa/SKILL.md`
- `/ship` → `$GSTACK_ROOT/ship/SKILL.md`
- `/design-review` → `$GSTACK_ROOT/design-review/SKILL.md`

**Browse 工具：** `$GSTACK_BROWSE/action.js`（啟動後 `$GSTACK_BROWSE/start.js`）

**設計工具：** `$GSTACK_DESIGN/[command].js`

**配置：** `$GSTACK_BIN/gstack-config get|set <key> <value>`

**學習：** `$GSTACK_BIN/gstack-learnings-add|search|list|prune`

---

## 配置

gstack 將配置存儲在 `~/.gstack/config.json` 中。

**可用設置：**

- `proactive`（布爾值）：啟用/禁用主動技能建議（默認：`true`）
- `skill_prefix`（布爾值）：為技能名稱添加 `/gstack-` 前綴（默認：`false`）
- `routing_declined`（布爾值）：用戶拒絕設置路由規則（默認：`false`）
- `auto_upgrade`（布爾值）：自動升級 gstack 而不詢問（默認：`false`）

**讀取配置：**

```bash
$GSTACK_BIN/gstack-config get proactive
```

**設置配置：**

```bash
$GSTACK_BIN/gstack-config set proactive false
```

---

## 錯誤恢復

**Browse 守護程序崩潰：**

如果 browse 命令失敗並顯示「守護程序未運行」：

```bash
node $GSTACK_BROWSE/start.js
```

然後重試操作。

**技能文件丟失：**

如果 `$GSTACK_ROOT/[skill-name]/SKILL.md` 不存在，告訴用戶：

「技能 `/[skill-name]` 不可用。請運行 `/gstack-upgrade` 以獲取最新版本。」

**Git 錯誤：**

如果技能在 git 操作期間失敗（例如 `/ship`），檢查 `git status` 並解決衝突，然後重新運行技能。

**配置錯誤：**

如果 `gstack-config` 命令失敗，配置文件可能已損壞。重置它：

```bash
echo '{"proactive":true,"skill_prefix":false}' > ~/.gstack/config.json
```

---

## 反模式

❌ **不要猜測技能行為** — 始終閱讀完整的技能文件

❌ **不要在沒有檢查 PROACTIVE 的情況下自動調用技能** — 尊重用戶偏好

❌ **不要混淆手動工作與技能工作** — 如果技能處理它，讓技能完成

❌ **不要跳過編排步驟** — 遵循技能建議的下一步

❌ **不要忽略 BLOCKED 狀態** — 停止並向用戶詢問

❌ **不要忘記清理** — 始終在技能末尾關閉 browse 守護程序

❌ **不要忽略學習** — 如果學習說「始終做 X」，請做 X

---

## 實作說明

### Browse 守護程序生命週期

1. **啟動：** `node $GSTACK_BROWSE/start.js`（如果尚未運行）
2. **使用：** `node $GSTACK_BROWSE/action.js [command]`（多個命令）
3. **清理：** `node $GSTACK_BROWSE/action.js close`（在技能末尾）

守護程序在會話之間保持運行以提高速度。如果崩潰，重新啟動它。

### 技能文件結構

所有技能文件遵循相同的格式：

```markdown
---
name: skill-name
description: 簡短說明
---

## 何時使用

...

## 使用方法

...

## 輸出格式

...

## 範例

...
```

閱讀整個文件以了解完整的使用說明。

### 提交訊息格式

當技能提交修復時，使用以下格式：

```
[skill-name] 修復：簡短描述

詳細說明修復的內容。可能引用錯誤報告、截圖或
原始問題。

Co-authored-by: gstack <gstack@example.com>
```

不要編輯或重新表述——使用技能提供的確切訊息。

### 狀態傳播

技能使用狀態標記傳遞進度：

```
DONE → 任務完成，繼續進行下一步驟
DONE_WITH_CONCERNS → 任務完成，但檢查 CONCERNS.md
BLOCKED → 無法繼續，需要用戶輸入
PARTIAL → 某些項目完成，其他項目失敗
NEEDS_CONTEXT → 在繼續之前需要更多信息
```

向用戶傳達這些狀態並相應地採取行動。

---

**版本：** 此 SKILL.md 由 `bun run gen:skill-docs` 從 `SKILL.md.tmpl` 生成。請勿直接編輯——更改模板並重新生成。
