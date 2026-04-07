---
name: autoplan
description: |
  自動執行完整規劃審查流程。依序執行 CEO、設計師、工程師、DX 四個視角的審查，
  並根據 6 個決策原則自動做出判斷。最後彙整「口味決策」（接近方案、模糊範疇）
  等待你確認。
  說「自動規劃」、「幫我全面審查」、「跑所有審查」時觸發。
  Use when asked to "auto review", "autoplan", "run all reviews", "review this plan
  automatically", or "make the decisions for me".
  Proactively suggest when the user has a plan file and wants to run the full review
  gauntlet without answering 15-30 intermediate questions. (gstack)
  Voice triggers (speech-to-text aliases): "auto plan", "automatic review".
---
<!-- AUTO-GENERATED from SKILL.md.tmpl — do not edit directly -->
<!-- Regenerate: bun run gen:skill-docs -->

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
$GSTACK_BIN/gstack-timeline-log '{"skill":"autoplan","event":"started","branch":"'"$_BRANCH"'","session":"'"$_SESSION_ID"'"}' 2>/dev/null &
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

If `PROACTIVE` is `"false"`, do not proactively suggest gstack skills AND do not
auto-invoke skills based on conversation context. Only run skills the user explicitly
types (e.g., /qa, /ship). If you would have auto-invoked a skill, instead briefly say:
"I think /skillname might help here — want me to run it?" and wait for confirmation.
The user opted out of proactive behavior.

If `SKILL_PREFIX` is `"true"`, the user has namespaced skill names. When suggesting
or invoking other gstack skills, use the `/gstack-` prefix (e.g., `/gstack-qa` instead
of `/qa`, `/gstack-ship` instead of `/ship`). Disk paths are unaffected — always use
`$GSTACK_ROOT/[skill-name]/SKILL.md` for reading skill files.

If output shows `UPGRADE_AVAILABLE <old> <new>`: read `$GSTACK_ROOT/gstack-upgrade/SKILL.md` and follow the "Inline upgrade flow" (auto-upgrade if configured, otherwise AskUserQuestion with 4 options, write snooze state if declined). If `JUST_UPGRADED <from> <to>`: tell user "Running gstack v{to} (just updated!)" and continue.

If `LAKE_INTRO` is `no`: Before continuing, introduce the Completeness Principle.
Tell the user: "gstack follows the **Boil the Lake** principle — always do the complete
thing when AI makes the marginal cost near-zero. Read more: https://garryslist.org/posts/boil-the-ocean"
Then offer to open the essay in their default browser:

```bash
open https://garryslist.org/posts/boil-the-ocean
touch ~/.gstack/.completeness-intro-seen
```

只在使用者同意時執行 `open`。永遠執行 `touch` 來標記已看過。這只會發生一次。



如果 `PROACTIVE_PROMPTED` 是 `no`：
詢問使用者關於主動行為的設定。使用 AskUserQuestion：

> gstack 可以在你工作時主動判斷何時你可能需要某個技能——
> 例如當你說「這個能用嗎？」時建議 /qa，或遇到 bug 時建議 /investigate。
> 我們建議保持開啟——這會加速你工作流程的每個環節。

選項：
- A）保持開啟（建議）
- B）關閉——我會自己輸入 /指令

如果選 A：執行 `$GSTACK_BIN/gstack-config set proactive true`
如果選 B：執行 `$GSTACK_BIN/gstack-config set proactive false`

永遠執行：
```bash
touch ~/.gstack/.proactive-prompted
```

這只會發生一次。如果 `PROACTIVE_PROMPTED` 是 `yes`，完全跳過這部分。

如果 `HAS_ROUTING` 是 `no` 且 `ROUTING_DECLINED` 是 `false` 且 `PROACTIVE_PROMPTED` 是 `yes`：
檢查專案根目錄是否存在 CLAUDE.md 檔案。如果不存在，建立它。

使用 AskUserQuestion：

> gstack 在你的專案 CLAUDE.md 包含技能路由規則時效果最好。
> 這會告訴 Claude 使用專業化工作流程（如 /ship、/investigate、/qa）
> 而不是直接回答。這是一次性新增，大約 15 行。

選項：
- A）新增路由規則到 CLAUDE.md（建議）
- B）不用了，我會手動調用技能

如果選 A：在 CLAUDE.md 結尾附加此區段：

```markdown

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

- /office-hours → Product brainstorming and design thinking
- /qa → Test the app end-to-end with real browser interactions
- /ship → Execute a plan (write code, test, commit, create PR)
- /investigate → Systematic debugging with root cause investigation
- /design-shotgun → Explore multiple design directions with visual mocks
- /plan-ceo-review → Product review (scope, market fit, risks)
- /plan-design-review → Design review (UI/UX, accessibility, polish)
- /plan-eng-review → Engineering review (architecture, security, performance)
```

然後執行：
```bash
$GSTACK_BIN/gstack-config set has_routing true
```

如果選 B：執行：
```bash
$GSTACK_BIN/gstack-config set routing_declined true
```

這只會發生一次。如果 `HAS_ROUTING` 是 `yes` 或 `ROUTING_DECLINED` 是 `true`，跳過此步驟。

如果 `VENDORED_GSTACK` 是 `yes`：在第一次輸出時警告使用者他們有舊的 vendored 安裝方式已過時。
只警告一次（檢查 session state）：

```sql
CREATE TABLE IF NOT EXISTS session_state (key TEXT PRIMARY KEY, value TEXT);
INSERT OR IGNORE INTO session_state (key, value) VALUES ('vendor_warned', '0');
SELECT value FROM session_state WHERE key = 'vendor_warned';
```

如果是 `'0'`，顯示此訊息：

```markdown
**注意：** 偵測到你有舊式的 vendored gstack 安裝（`.gemini/skills/gstack` 資料夾）。
這種方式已過時，建議改用全域安裝：

1. 刪除專案中的 gstack：`rm -rf .gemini/skills/gstack`
2. 執行全域安裝：`curl -fsSL https://gstack.sh/install.sh | bash`
3. （選擇性）在專案中建立符號連結：`ln -s ~/.gemini/skills/gstack .gemini/skills/gstack`

全域安裝可以在所有專案間共享更新。需要幫忙遷移嗎？
```

然後更新狀態：
```sql
UPDATE session_state SET value = '1' WHERE key = 'vendor_warned';
```

---

## 目標

這個技能提供一個**無需人工介入的規劃審查流程**：

1. **依序執行四個審查視角**：CEO、設計師、工程師、DX
2. **自動做決策**：使用 6 個決策原則來判斷應該「接受」、「增強」或「跳過」每個建議
3. **彙整口味決策**：將「接近但不明確」的決定收集起來，在最終閘門由使用者確認
4. **輸出準備執行的規劃**：審查完畢後直接輸出更新後的 `plan.md`

當使用者說：
* 「自動規劃」、「auto review」、「autoplan」
* 「幫我全面審查」、「run all reviews」
* 「自動做決策」、「make the decisions for me」

**核心理念：** 大多數審查建議都有明確的正確答案（security bugs 一定修、明顯超出範疇的一定刪）。只有少數需要你的判斷（兩種設計方案都合理、功能範疇的邊界模糊）。autoplan 會自動處理明確的 95%，只把真正需要你判斷的 5% 拿出來確認。

---

## 工作流程

### 1. 讀取規劃檔案

讀取 `plan.md`（或使用者指定的檔案）。如果檔案不存在，詢問使用者要審查哪個檔案。

### 2. 依序執行四個審查

按照以下順序執行每個審查技能：

#### 2.1 CEO 審查 (`gstack-plan-ceo-review`)

讀取 `$GSTACK_ROOT/gstack-plan-ceo-review/SKILL.md` 並執行 CEO 審查。

CEO 審查會輸出建議清單。對於每個建議，套用**決策原則**（見下方）來自動判斷應該：
* **AUTO_ACCEPT**：直接採納並更新 plan.md
* **AUTO_ENHANCE**：補強規劃但保持原範疇
* **AUTO_SKIP**：明確拒絕（不符合範疇/約束）
* **TASTE**：標記為「口味決策」，留待最終確認

將每個決定記錄到 SQL session database：

```sql
CREATE TABLE IF NOT EXISTS review_decisions (
  review_stage TEXT,
  item_id TEXT,
  item_summary TEXT,
  decision TEXT,
  reasoning TEXT,
  applied INTEGER DEFAULT 0,
  PRIMARY KEY (review_stage, item_id)
);

INSERT INTO review_decisions (review_stage, item_id, item_summary, decision, reasoning)
VALUES ('ceo', 'mvp-scope-1', 'Narrow MVP to core authentication only', 'AUTO_ACCEPT', 'Clear scope reduction aligns with constraints');
```

**自動應用變更：**
* 對於 `AUTO_ACCEPT` 和 `AUTO_ENHANCE` 決策：立即更新 `plan.md` 的相應區段
* 使用 `edit` 工具進行外科手術式修改
* 每個決策做成一個 atomic edit
* 在 `review_decisions` 表中設定 `applied = 1`

**顯示進度：**

```
✓ CEO 審查完成（18 秒）
  • 自動採納：3 項
  • 自動增強：1 項
  • 自動跳過：0 項
  • 待確認：2 項
```

#### 2.2 設計師審查 (`gstack-plan-design-review`)

讀取 `$GSTACK_ROOT/gstack-plan-design-review/SKILL.md` 並執行設計審查。

套用相同的**決策原則**來自動處理設計建議（UI/UX、視覺設計、互動模式等）。

記錄決策並自動應用變更，顯示進度。

#### 2.3 工程師審查 (`gstack-plan-eng-review`)

讀取 `$GSTACK_ROOT/gstack-plan-eng-review/SKILL.md` 並執行工程審查。

套用**決策原則**來自動處理工程建議（架構、技術債、風險、效能等）。

**特別注意安全性與資料遺失風險：**
* Security bugs, XSS, SQL injection, CSRF → 永遠 `AUTO_ACCEPT`
* 資料遺失風險、race conditions → 永遠 `AUTO_ACCEPT`
* 技術債「需要重寫一切」 → `AUTO_SKIP`（超出範疇）

記錄決策並應用變更，顯示進度。

#### 2.4 DX 審查 (`gstack-plan-devex-review`)

讀取 `$GSTACK_ROOT/gstack-plan-devex-review/SKILL.md` 並執行 DX 審查。

套用**決策原則**來自動處理 DX 建議（開發者體驗、API 設計、文件、錯誤訊息等）。

記錄決策並應用變更，顯示進度。

---

### 3. 收集口味決策

查詢所有標記為 `TASTE` 的決策：

```sql
SELECT review_stage, item_id, item_summary, reasoning
FROM review_decisions
WHERE decision = 'TASTE'
ORDER BY review_stage;
```

如果沒有口味決策，跳到步驟 4。

如果有口味決策，顯示清單並請使用者確認。格式化為易讀的摘要，每個決策包含：
* 來源審查階段（CEO/Design/Eng/DX）
* 簡短標題
* 選項或權衡說明
* 為什麼這需要使用者判斷

範例輸出：

```markdown
## 🎨 口味決策（需要你的判斷）

以下 3 個建議沒有明確的對錯，需要你的產品判斷：

### CEO 審查

**1. 定價模型選擇** (`ceo-pricing`)
兩種方案都合理：
- 選項 A：免費增值（免費 → $49/月）
- 選項 B：僅付費（$29/月起）

兩者都在合理範圍內，取決於你的成長策略偏好。

**2. 國際化時程** (`ceo-i18n`)
建議在 v1.0 加入多語系支援。可以延後到 v1.1，但可能錯過國際市場的早期採用者。

### 設計審查

**3. 深色模式** (`design-dark-mode`)
建議在 launch 時包含深色模式。可以稍後新增，但這是使用者高度期待的功能。

---

你的決定？回覆如下格式：
- `accept ceo-pricing` 或 `accept ceo-pricing-A`（如果有多個選項）
- `skip ceo-i18n`
- `accept design-dark-mode`

或：
- `accept all` — 採納所有建議的預設選項
- `skip all` — 跳過所有口味決策
- `let me review each` — 逐項互動確認
```

**處理使用者回覆：**

解析使用者的指令，更新決策表：

```sql
UPDATE review_decisions
SET decision = 'USER_ACCEPT'  -- 或 'USER_SKIP'
WHERE item_id = 'ceo-pricing';
```

對於 `USER_ACCEPT` 的項目，應用變更到 `plan.md`（如果還沒應用）：

```sql
UPDATE review_decisions
SET applied = 1
WHERE item_id = 'ceo-pricing';
```

然後實際編輯 `plan.md` 來整合該建議。

---

### 4. 產生最終審查報告

彙總所有審查階段的結果：

```sql
SELECT
  CASE decision
    WHEN 'AUTO_ACCEPT' THEN '自動採納'
    WHEN 'AUTO_ENHANCE' THEN '自動增強'
    WHEN 'AUTO_SKIP' THEN '自動跳過'
    WHEN 'USER_ACCEPT' THEN '使用者確認後採納'
    WHEN 'USER_SKIP' THEN '使用者確認後跳過'
    ELSE decision
  END as decision_zh,
  COUNT(*) as count
FROM review_decisions
GROUP BY decision;
```

顯示最終摘要：

```markdown
## ✅ 自動規劃完成

完整審查流程已執行，共處理 **42 個建議**：

| 決策類型 | 數量 | 說明 |
|---------|------|------|
| 自動採納 | 28 | 明確改善，已整合到 plan.md |
| 自動增強 | 8 | 補強規劃，已更新 plan.md |
| 自動跳過 | 3 | 超出範疇或與約束衝突 |
| 使用者確認後採納 | 2 | 口味決策，已套用你的選擇 |
| 使用者確認後跳過 | 1 | 口味決策，已跳過 |

**主要改進：**
- ✅ 加入 CSRF 保護和 rate limiting（security）
- ✅ 縮減 MVP 範疇：移除社交登入和即時通知（scope reduction）
- ✅ 改善錯誤訊息和載入狀態（UX enhancement）
- ✅ 加入資料庫 migration 策略（engineering）
- ✅ 補充 API 錯誤碼文件（DX）

**plan.md 已更新。** 審查後的完整規劃如下：
```

接著使用 `view` 工具讀取並顯示更新後的完整 `plan.md` 內容。

---

## 決策原則（6 個核心規則）

autoplan 使用以下 6 個原則來自動判斷每個建議應該「接受」、「增強」、「跳過」或「留待確認」：

### 原則 1：Safety & Security = AUTO_ACCEPT

任何關於**安全性、資料完整性、隱私、法規遵循**的建議，一律自動採納。

**範例：**
* ✅ 「Add CSRF protection」 → AUTO_ACCEPT
* ✅ 「Hash passwords with bcrypt」 → AUTO_ACCEPT
* ✅ 「Add rate limiting to prevent DDoS」 → AUTO_ACCEPT
* ✅ 「Validate file uploads to prevent malicious scripts」 → AUTO_ACCEPT
* ✅ 「Add GDPR data export endpoint」 → AUTO_ACCEPT
* ✅ 「Sanitize user input to prevent XSS」 → AUTO_ACCEPT
* ✅ 「Use parameterized queries to prevent SQL injection」 → AUTO_ACCEPT

**理由：** 安全性沒有折衷空間。即使增加工作量也必須做。這些不是「功能 A vs. 功能 B」的權衡，而是「正確 vs. 有安全漏洞」的差別。

---

### 原則 2：Obvious Bugs = AUTO_ACCEPT

明顯的 bug、race condition、資料遺失風險、錯誤處理缺失，一律自動採納。

**範例：**
* ✅ 「Fix race condition in payment processing」 → AUTO_ACCEPT
* ✅ 「Handle null pointer when user has no avatar」 → AUTO_ACCEPT
* ✅ 「Prevent duplicate email signups with unique constraint」 → AUTO_ACCEPT
* ✅ 「Fix off-by-one error in pagination」 → AUTO_ACCEPT
* ✅ 「Add error handling for failed API calls」 → AUTO_ACCEPT
* ✅ 「Catch division by zero in statistics calculation」 → AUTO_ACCEPT

**理由：** 這些是客觀錯誤，不是「功能 vs. 功能」的權衡。不修就是有 bug。

---

### 原則 3：Clear Scope Reduction = AUTO_ACCEPT

建議**縮小範疇、移除非必要功能、簡化複雜度、延後次要功能**的，如果不影響核心價值，自動採納。

**範例：**
* ✅ 「Remove social login, just use email/password for MVP」 → AUTO_ACCEPT
* ✅ 「Defer real-time notifications to v1.1, use polling for v1.0」 → AUTO_ACCEPT
* ✅ 「Skip admin dashboard for MVP, add in v1.1」 → AUTO_ACCEPT
* ✅ 「Remove export to PDF feature, focus on core editing」 → AUTO_ACCEPT
* ✅ 「Limit MVP to English-only, add i18n later」 → AUTO_ACCEPT

**但是：**
* ⚠️ 「Remove user authentication entirely」 → **TASTE**（這可能破壞核心功能，需要確認）
* ⚠️ 「Remove payment processing to simplify」 → **TASTE**（如果產品就是要收費，這會破壞商業模式）

**理由：** 在約束條件下（時間、資源），減少範疇通常是正確的。MVP 的精神就是「最小」。

---

### 原則 4：Clear Scope Creep = AUTO_SKIP

建議**增加新功能、新整合、新平台、擴大範疇**的，除非明顯是核心必要功能或標準實踐的一部分，否則自動跳過。

**範例：**
* ❌ 「Add blockchain integration for decentralized storage」 → AUTO_SKIP（明顯超出範疇）
* ❌ 「Build iOS and Android apps in addition to web」 → AUTO_SKIP（新平台 = scope creep）
* ❌ 「Add AI chatbot support」 → AUTO_SKIP（除非這是產品核心）
* ❌ 「Integrate with Salesforce CRM」 → AUTO_SKIP（新整合，unless 規劃中已明確包含）
* ❌ 「Add gamification with badges and leaderboards」 → AUTO_SKIP（新功能類別）

**但是：**
* ✅ 「Add forgot password flow」 → **AUTO_ACCEPT**（auth 系統的標準組成部分，不是 scope creep）
* ✅ 「Add email verification for security」 → **AUTO_ACCEPT**（security 標準實踐，屬於原則 1）
* ✅ 「Add HTTPS」 → **AUTO_ACCEPT**（security 標準，不是 scope creep）

**如何區分「標準組成部分」vs.「scope creep」：**
* 標準組成部分：如果你說「auth 系統」，業界都期待包含 forgot password
* Scope creep：如果你說「auth 系統」，沒人會期待包含 OAuth 整合 10 種第三方服務

**理由：** 功能蔓延是專案失敗的首要原因。預設說「不」，除非明顯必要。

---

### 原則 5：Enhancement Without Scope Change = AUTO_ENHANCE

建議**改善現有功能、提升品質、增加細節、補充文件**，但不改變功能範疇或增加新功能，自動採納並標記為「增強」。

**範例：**
* ✅ 「Add loading states to all async operations」 → AUTO_ENHANCE
* ✅ 「Improve error messages to be more actionable」 → AUTO_ENHANCE
* ✅ 「Add input validation with helpful feedback」 → AUTO_ENHANCE
* ✅ 「Use semantic HTML and ARIA labels for accessibility」 → AUTO_ENHANCE
* ✅ 「Add API documentation with example requests」 → AUTO_ENHANCE
* ✅ 「Add database indexes for common queries」 → AUTO_ENHANCE
* ✅ 「Improve contrast ratios to meet WCAG AA」 → AUTO_ENHANCE

**理由：** 這些是「做現有功能，但做得更好」，符合 Boil the Lake 原則。AI 的邊際成本接近零，所以「完整做好」比「只做一半」更合理。

**Enhancement vs. Scope Creep 的界線：**
* Enhancement：為已規劃的功能加入品質屬性（loading state、error handling、文件）
* Scope creep：加入新功能（即使是「小功能」）

---

### 原則 6：Close Call or Taste = TASTE

如果建議屬於以下情況，標記為「口味決策」留待使用者確認：

* **兩種方案都合理**（A 方案 vs. B 方案，沒有明確的對錯）
* **範疇邊界模糊**（可能是 MVP 的一部分，也可能不是，需要產品判斷）
* **商業判斷**（定價策略、目標市場、成長優先順序、時程權衡）
* **美學偏好**（兩種設計都符合最佳實踐，但風格不同）
* **技術選擇無明確優劣**（兩種技術都成熟，取決於團隊經驗或生態系偏好）

**範例：**
* ⚠️ 「Use REST API vs. GraphQL」 → TASTE（兩者都可行，取決於團隊偏好和需求）
* ⚠️ 「Free tier with 100 requests/day vs. $9/month unlimited」 → TASTE（定價策略，商業判斷）
* ⚠️ 「Launch with English only vs. English + Spanish」 → TASTE（市場策略）
* ⚠️ 「Dark mode: launch with it vs. add later」 → TASTE（優先順序判斷，兩者都合理）
* ⚠️ 「Use PostgreSQL vs. MySQL」 → TASTE（兩者都成熟，無明確對錯）
* ⚠️ 「Serif vs. sans-serif for body text」 → TASTE（設計偏好）

**理由：** 這些需要產品直覺、商業判斷、或個人品味。AI 不應該代替你做這些決定，因為它們沒有「正確答案」，只有「你想要的答案」。

---

## 決策原則的應用順序

當遇到一個建議時，按照此順序檢查：

1. **是否為 Security/Safety？** → YES = AUTO_ACCEPT（原則 1）
2. **是否為明顯 bug？** → YES = AUTO_ACCEPT（原則 2）
3. **是否為明顯的 scope creep？** → YES = AUTO_SKIP（原則 4）
4. **是否為明確的 scope reduction？** → YES = AUTO_ACCEPT（原則 3）
5. **是否為 enhancement（不改變範疇）？** → YES = AUTO_ENHANCE（原則 5）
6. **以上皆非** → TASTE（原則 6）

**注意順序：** Security（原則 1）和 bugs（原則 2）優先於 scope 考量。即使某個 security fix 看起來像 scope creep，仍然要 AUTO_ACCEPT。

---

## 決策推理範例

### 範例 1：「Add rate limiting to API endpoints」

* 檢查原則 1：是否為 security？ → **是（防止 DDoS）** → **AUTO_ACCEPT**

決策：`AUTO_ACCEPT`  
理由：「Security requirement to prevent denial of service attacks」

---

### 範例 2：「Build a Chrome extension in addition to web app」

* 檢查原則 1-2：不是 security 或 bug
* 檢查原則 4：是否為 scope creep？ → **是（新平台）** → **AUTO_SKIP**

決策：`AUTO_SKIP`  
理由：「Scope creep — adds entirely new platform beyond original plan」

---

### 範例 3：「Add loading spinners to all buttons」

* 檢查原則 1-4：不是 security、bug、scope change
* 檢查原則 5：是否為 enhancement？ → **是（改善現有 async operations）** → **AUTO_ENHANCE**

決策：`AUTO_ENHANCE`  
理由：「UX enhancement — improves existing async operations without scope change」

---

### 範例 4：「Use Stripe vs. PayPal for payments」

* 檢查原則 1-5：不符合任何自動決策規則
* 檢查原則 6：是否為 close call？ → **是（兩個 payment provider 都是成熟方案）** → **TASTE**

決策：`TASTE`  
理由：「Both payment providers are viable — choice depends on target market and fee structure preferences」

提供選項：
- 選項 A：Stripe（更好的開發者體驗，北美市場主流）
- 選項 B：PayPal（更廣泛的消費者認知度）

---

### 範例 5：「Remove blog feature to focus on core product」

* 檢查原則 1-2：不是 security 或 bug
* 檢查原則 4：是否為 scope creep？ → 不是，這是 reduction
* 檢查原則 3：是否為 scope reduction？ → **需要判斷：blog 是否為核心功能？**

如果 plan.md 明確說「部落格平台」：
* **TASTE** — 移除核心功能需要確認

如果 plan.md 說「SaaS 產品，附帶行銷部落格」：
* **AUTO_ACCEPT** — 行銷部落格不是核心，可以先移除

**如何判斷：** 讀取 plan.md 的 "Core Value Proposition" 或 "MVP Scope" 區段。如果該功能是核心價值的一部分 → TASTE。如果是輔助功能 → AUTO_ACCEPT。

---

### 範例 6：「Add forgot password email with styled template」

這個建議包含兩部分：
1. Forgot password 功能
2. Styled email template

拆解分析：
* 「Add forgot password functionality」：
  * 檢查原則 1：部分 security（帳號復原）
  * 檢查原則 4：是否為 scope creep？ → **不是**，這是 auth 系統的標準組成部分
  * → **AUTO_ACCEPT**（原則 1 + 標準實踐）

* 「With styled email template」：
  * 檢查原則 5：是否為 enhancement？ → **是**（plain text email 也能用，styled 是品質提升）
  * → **AUTO_ENHANCE**

決策：`AUTO_ACCEPT` (forgot password) + `AUTO_ENHANCE` (styled template)  
理由：「Forgot password is standard auth functionality (security/completeness). Styled email template is a quality enhancement.」

**建議拆解原則：** 如果一個建議包含多個部分，分別評估每部分。有些可能是 AUTO_ACCEPT，有些可能是 ENHANCE，有些可能是 SKIP。

---

## 輸出格式

### 執行中的進度更新

在執行每個審查階段時，顯示簡潔的進度：

```
🔍 執行 CEO 審查...
```

審查完成後立即自動套用決策（AUTO_ACCEPT, AUTO_ENHANCE）並顯示：

```
✓ CEO 審查完成（18 秒）
  • 自動採納：3 項
  • 自動增強：1 項
  • 自動跳過：0 項
  • 待確認：2 項
```

**不要** 顯示每個建議的詳細內容（這會產生太多輸出）。只顯示統計摘要。

如果使用者想看細節，可以查詢：
```sql
SELECT * FROM review_decisions WHERE review_stage = 'ceo';
```

### 四個審查都完成後

如果沒有 TASTE 決策，直接跳到最終摘要。

如果有 TASTE 決策，顯示「口味決策」區段（格式見上方「步驟 3」）。

### 最終摘要

```markdown
## ✅ 自動規劃完成

完整審查流程已執行，共處理 **42 個建議**：

| 決策類型 | 數量 | 說明 |
|---------|------|------|
| 自動採納 | 28 | 明確改善，已整合到 plan.md |
| 自動增強 | 8 | 補強規劃，已更新 plan.md |
| 自動跳過 | 3 | 超出範疇或與約束衝突 |
| 使用者確認後採納 | 2 | 口味決策，已套用你的選擇 |
| 使用者確認後跳過 | 1 | 口味決策，已跳過 |

**主要改進：**
- ✅ 加入 CSRF 保護和 rate limiting（security）
- ✅ 縮減 MVP 範疇：移除社交登入和即時通知（scope reduction）
- ✅ 改善錯誤訊息和載入狀態（UX enhancement）
- ✅ 加入資料庫 migration 策略（engineering）
- ✅ 補充 API 錯誤碼文件（DX）

**plan.md 已更新。** 你可以：
- 📖 查看完整規劃（下方顯示）
- 🚀 執行 `/ship` 開始實作
- 📝 或執行 `git add plan.md && git commit -m "Reviewed plan with autoplan"` 儲存審查結果

---

## plan.md 完整內容
```

然後使用 `view` 工具讀取並顯示更新後的 plan.md。

---

## 錯誤處理

### 如果某個審查技能失敗

記錄錯誤並繼續下一個審查：

```markdown
⚠️ 工程師審查發生錯誤：[錯誤訊息]

繼續執行下一階段。稍後你可以手動執行相應的審查技能來補上。
```

將失敗記錄到 SQL：

```sql
INSERT INTO review_decisions (review_stage, item_id, item_summary, decision, reasoning)
VALUES ('eng', 'ERROR', 'Review stage failed', 'SKIPPED', '[error message]');
```

### 如果 plan.md 不存在

```markdown
找不到 `plan.md`。請指定要審查的規劃檔案路徑，或先建立一個規劃。

你可以：
- 執行 `/plan-ceo-review` 來開始規劃流程
- 指定其他檔案：`/autoplan docs/product-spec.md`
```

### 如果使用者取消口味決策確認

```markdown
已取消口味決策確認。

目前狀態：
- 已自動套用：36 個建議
- 待確認：3 個口味決策

plan.md 已根據自動決策更新。你可以：
- 稍後手動編輯 plan.md 來處理待確認的項目
- 或執行 `/autoplan --resume` 來繼續處理
```

儲存 session state：

```sql
INSERT OR REPLACE INTO session_state (key, value)
VALUES ('autoplan_paused', 'yes');
```

---

## 進階用法

### 僅執行特定審查

使用者可以指定只執行某些審查：

```
/autoplan --only ceo,design
```

只執行 CEO 和設計師審查，跳過工程師和 DX 審查。

解析 `--only` 參數並過濾要執行的審查清單。

### 恢復中斷的審查

如果使用者中斷流程後想繼續：

```
/autoplan --resume
```

檢查 session state：

```sql
SELECT value FROM session_state WHERE key = 'autoplan_paused';
```

如果是 `'yes'`，查詢待處理的 TASTE 決策並繼續口味決策確認流程。

### 手動模式（無自動決策）

如果使用者想要完全手動控制：

```
/autoplan --manual
```

執行所有審查但不做自動決策，所有建議都標記為 `TASTE` 待使用者逐一確認。

這等同於執行四個審查技能但以互動模式呈現每個建議。

### 指定規劃檔案

```
/autoplan docs/product-spec.md
```

審查指定的檔案而非預設的 `plan.md`。

---

## SQL Schema 參考

完整的 session database schema：

```sql
-- 審查決策記錄
CREATE TABLE IF NOT EXISTS review_decisions (
  review_stage TEXT,           -- 'ceo', 'design', 'eng', 'dx'
  item_id TEXT,                -- 唯一識別符（e.g., 'ceo-pricing', 'design-a11y-contrast'）
  item_summary TEXT,           -- 簡短描述
  decision TEXT,               -- 'AUTO_ACCEPT', 'AUTO_ENHANCE', 'AUTO_SKIP', 'TASTE', 'USER_ACCEPT', 'USER_SKIP'
  reasoning TEXT,              -- 決策理由（套用了哪個原則、為什麼）
  applied INTEGER DEFAULT 0,   -- 是否已套用到 plan.md（0 or 1）
  PRIMARY KEY (review_stage, item_id)
);

-- Session state（用於 --resume 等功能）
CREATE TABLE IF NOT EXISTS session_state (
  key TEXT PRIMARY KEY,
  value TEXT
);

-- 範例 session_state keys:
-- 'autoplan_paused' = 'yes'/'no'
-- 'vendor_warned' = '0'/'1'
-- 'plan_file' = 'plan.md' or custom path
```

---

## 實例演練

假設使用者有一個 plan.md 規劃「建立一個簡單的部落格系統」。

### 步驟 1：執行 autoplan

```
使用者：「自動規劃」
```

### 步驟 2：自動審查開始

```
🔍 執行 CEO 審查...
```

CEO 審查返回 5 個建議：
1. 「Narrow scope to CRUD only, remove comments」 → 原則 3（scope reduction）→ **AUTO_ACCEPT**
2. 「Remove social sharing buttons」 → 原則 3（scope reduction）→ **AUTO_ACCEPT**
3. 「Add comment system? It's on the MVP boundary」 → 原則 6（boundary unclear）→ **TASTE**
4. 「Clarify target audience: developers or general public?」 → 原則 6（strategic decision）→ **TASTE**
5. 「Add analytics to track post views」 → 原則 4（new feature）→ **AUTO_SKIP**

自動應用 AUTO_ACCEPT 決策（編輯 plan.md），顯示進度：

```
✓ CEO 審查完成（22 秒）
  • 自動採納：2 項（scope reduction: remove comments and social sharing）
  • 自動跳過：1 項（analytics = scope creep）
  • 待確認：2 項（comment system boundary, target audience）
```

```
🎨 執行設計師審查...
```

設計審查返回 6 個建議：
1. 「Ensure WCAG AA contrast」 → 原則 5（enhancement）→ **AUTO_ENHANCE**
2. 「Use semantic HTML」 → 原則 5（enhancement）→ **AUTO_ENHANCE**
3. 「Add loading states」 → 原則 5（enhancement）→ **AUTO_ENHANCE**
4. 「Responsive design for mobile」 → 原則 5（standard practice）→ **AUTO_ENHANCE**
5. 「Dark mode support」 → 原則 6（nice-to-have, can defer）→ **TASTE**
6. 「Add animation library like Framer Motion」 → 原則 4（new dependency）→ **AUTO_SKIP**

應用決策，顯示進度：

```
✓ 設計師審查完成（18 秒）
  • 自動採納：0 項
  • 自動增強：4 項（WCAG, semantic HTML, loading states, responsive）
  • 自動跳過：1 項（animation library = scope creep）
  • 待確認：1 項（dark mode timing）
```

```
⚙️ 執行工程師審查...
```

工程審查返回 9 個建議：
1. 「Add SQL injection protection」 → 原則 1（security）→ **AUTO_ACCEPT**
2. 「Add XSS protection」 → 原則 1（security）→ **AUTO_ACCEPT**
3. 「Add CSRF tokens」 → 原則 1（security）→ **AUTO_ACCEPT**
4. 「Add input validation」 → 原則 1（security/correctness）→ **AUTO_ACCEPT**
5. 「Add database indexes」 → 原則 5（enhancement）→ **AUTO_ENHANCE**
6. 「Add logging」 → 原則 5（enhancement）→ **AUTO_ENHANCE**
7. 「Add error handling」 → 原則 2（bug prevention）→ **AUTO_ACCEPT**
8. 「Rewrite as microservices」 → 原則 4（scope creep）→ **AUTO_SKIP**
9. 「Use Redis for caching」 → 原則 6（tech choice, can work without it for MVP）→ **TASTE**

應用決策，顯示進度：

```
✓ 工程師審查完成（31 秒）
  • 自動採納：5 項（SQL injection, XSS, CSRF, input validation, error handling）
  • 自動增強：2 項（indexes, logging）
  • 自動跳過：1 項（microservices = scope creep）
  • 待確認：1 項（Redis caching decision）
```

```
🧑‍💻 執行 DX 審查...
```

DX 審查返回 5 個建議：
1. 「Add README with setup steps」 → 原則 5（enhancement）→ **AUTO_ENHANCE**
2. 「Add API docs」 → 原則 5（enhancement）→ **AUTO_ENHANCE**
3. 「Improve error messages」 → 原則 5（enhancement）→ **AUTO_ENHANCE**
4. 「Add example requests」 → 原則 5（enhancement）→ **AUTO_ENHANCE**
5. 「Add GraphQL playground」 → 原則 4（new feature, only needed if using GraphQL）→ **AUTO_SKIP**

應用決策，顯示進度：

```
✓ DX 審查完成（15 秒）
  • 自動採納：0 項
  • 自動增強：4 項（README, API docs, error messages, examples）
  • 自動跳過：1 項（GraphQL playground not applicable）
  • 待確認：0 項
```

### 步驟 3：口味決策確認

```markdown
## 🎨 口味決策（需要你的判斷）

以下 4 個建議沒有明確的對錯，需要你的產品判斷：

### CEO 審查

**1. 評論系統** (`ceo-comments`)
建議加入評論功能讓讀者可以留言。

這在「簡單部落格」的範疇邊界上：
- 加入評論 = 更像社群平台，增加使用者黏著度，但也增加 moderation 負擔
- 不加評論 = 更簡單，專注在作者發文

兩者都合理，取決於你的產品定位。

**2. 目標受眾** (`ceo-audience`)
需要明確：這是給開發者的技術部落格，還是一般大眾的內容平台？

這會影響編輯器選擇（Markdown vs. WYSIWYG）、SEO 優化方式、UI 複雜度。

### 設計審查

**3. 深色模式** (`design-dark-mode`)
建議在 launch 時包含深色模式。可以稍後新增，但這是使用者高度期待的功能，特別是開發者受眾。

### 工程審查

**4. Redis caching** (`eng-redis`)
建議加入 Redis 來 cache 熱門文章。

對於 MVP：
- 不加 Redis = 更簡單，一個 database 就夠，適合初期流量
- 加 Redis = 更好的效能，但增加部署複雜度

取決於你預期的初期流量規模。

---

你的決定？回覆如下格式：
- `accept ceo-comments` 或 `skip ceo-comments`
- `accept ceo-audience` 或提供答案：「target audience is developers」
- `accept design-dark-mode` 或 `skip design-dark-mode`
- `accept eng-redis` 或 `skip eng-redis`

或直接說：
- `accept all` — 採納所有建議
- `skip all` — 跳過所有口味決策
```

### 步驟 4：使用者回覆

```
使用者：「skip ceo-comments，target audience is developers，accept design-dark-mode，skip eng-redis」
```

解析指令：
* `ceo-comments` → USER_SKIP
* `ceo-audience` → 使用者提供了答案「developers」，更新 plan.md 明確說明目標受眾
* `design-dark-mode` → USER_ACCEPT，編輯 plan.md 加入深色模式
* `eng-redis` → USER_SKIP

更新 SQL：

```sql
UPDATE review_decisions SET decision = 'USER_SKIP' WHERE item_id = 'ceo-comments';
UPDATE review_decisions SET decision = 'USER_ACCEPT' WHERE item_id = 'design-dark-mode';
UPDATE review_decisions SET decision = 'USER_SKIP' WHERE item_id = 'eng-redis';
```

對於 `ceo-audience`，這不是 accept/skip，而是需要將使用者的答案整合到 plan.md：

```sql
UPDATE review_decisions 
SET decision = 'USER_PROVIDED', reasoning = 'User clarified: target audience is developers'
WHERE item_id = 'ceo-audience';
```

應用變更：編輯 plan.md 加入深色模式的設計規劃，明確說明目標受眾是開發者。

### 步驟 5：最終輸出

```markdown
## ✅ 自動規劃完成

完整審查流程已執行，共處理 **25 個建議**：

| 決策類型 | 數量 | 說明 |
|---------|------|------|
| 自動採納 | 7 | Security 和明確改善 |
| 自動增強 | 10 | 品質提升（UX, DX, 效能） |
| 自動跳過 | 4 | 超出範疇（analytics, animations, microservices, GraphQL playground） |
| 使用者確認後採納 | 1 | 深色模式 |
| 使用者確認後跳過 | 2 | 評論系統、Redis caching（MVP 先不加） |
| 使用者提供答案 | 1 | 明確目標受眾為開發者 |

**主要改進：**
- ✅ 完整的安全防護（SQL injection、XSS、CSRF、input validation）
- ✅ 縮減範疇：移除社交分享、評論系統（延後）、analytics
- ✅ 無障礙設計、semantic HTML、響應式設計、loading states
- ✅ 完整的開發者文件（README、API docs、error messages）
- ✅ 加入深色模式支援
- ✅ 明確目標受眾：技術部落格（開發者）→ 使用 Markdown 編輯器

**plan.md 已更新。** 你可以：
- 🚀 執行 `/ship` 開始實作
- 💾 或執行 `git add plan.md && git commit -m "Reviewed plan with autoplan"` 儲存審查結果

---

## plan.md 完整內容
```

然後顯示更新後的 plan.md 完整內容。

---

## 與其他技能的整合

### 執行前：`/office-hours` 或 `/plan-ceo-review`

如果使用者還沒有 plan.md，建議先執行：
* `/office-hours` — 如果還在構思階段，用 design thinking 方法探索 idea
* `/plan-ceo-review` — 如果已有初步想法，直接進行 CEO 審查來建立規劃

### 執行後：`/ship` 或 `/qa`

autoplan 完成後，plan.md 已經過完整審查。接下來可以：
* `/ship` — 執行規劃，寫 code、測試、commit、建立 PR
* `/qa` — 如果已有部分實作，先進行 QA 測試

### 結合 `/investigate`

如果 autoplan 過程中發現規劃有重大問題（例如技術可行性疑慮），建議：
* 執行 `/investigate` 來深入研究該技術問題
* 更新 plan.md 後重新執行 `/autoplan`

---

## 最佳實踐

### 1. 先跑 autoplan，不要先手動審查

* autoplan 可以處理 95% 的明確決策
* 只在 autoplan 輸出口味決策後，才花時間思考
* 節省時間：從 30 分鐘的逐項審查 → 3 分鐘的口味決策確認

### 2. 信任決策原則

* 原則經過實戰驗證，涵蓋常見的規劃問題
* 如果 autoplan 自動採納了 security fix，不要質疑它
* 如果 autoplan 跳過了明顯的 scope creep，它是對的
* 如果有疑問，查詢決策推理：
  ```sql
  SELECT item_summary, decision, reasoning FROM review_decisions WHERE item_id = 'xxx';
  ```

### 3. 口味決策是真正需要你的判斷

* 不要在口味決策上隨便說「accept all」或「skip all」
* 這些是 AI 無法替你做的產品判斷
* 花時間思考每個口味決策對產品方向的影響
* 口味決策通常關乎：優先順序、定位、策略、美學

### 4. 檢視自動決策的推理

* 每個決策都記錄了 reasoning
* 如果對某個自動決策有疑問，查詢完整記錄：
  ```sql
  SELECT * FROM review_decisions WHERE review_stage = 'eng' AND decision = 'AUTO_SKIP';
  ```
* 你可以手動覆寫：直接編輯 plan.md，然後告訴 AI 你的更改

### 5. Autoplan 是可重複執行的

* 更新 plan.md 後，可以再次執行 `/autoplan`
* 只會處理新增或變更的部分（透過 diff 檢測）
* 用於迭代規劃：plan → autoplan → 手動調整 → autoplan again

---

## 疑難排解

### Q: 某個自動決策我不同意，怎麼辦？

A: 你可以：
1. 直接編輯 plan.md 改回你想要的版本
2. 查詢該決策的推理：
   ```sql
   SELECT * FROM review_decisions WHERE item_id = 'xxx';
   ```
3. 告訴 AI 你的想法：「我覺得 [item_id] 不應該被跳過，因為...」

如果是原則層面的分歧（例如你認為某個功能不是 scope creep），可以：
* 告訴 AI 你的專案脈絡：「這是一個 fintech 產品，compliance 功能永遠不是 scope creep」
* AI 會記錄到 learnings，下次 autoplan 會考慮這個脈絡

### Q: 我想要某個被跳過的建議，怎麼復原？

A: 查詢被跳過的建議：
```sql
SELECT item_id, item_summary, reasoning FROM review_decisions WHERE decision = 'AUTO_SKIP';
```

然後告訴 AI：「把 [item_id] 加回來」或「其實我想要 [feature]」。AI 會更新 plan.md。

### Q: 口味決策太多，很多其實有明確答案

A: 可能原因：
* 規劃本身模糊不清（缺少明確的 MVP scope、約束條件、目標受眾）
* 決策原則需要針對你的專案類型調整

解法：
* 先執行 `/plan-ceo-review` 來明確化規劃（特別是 constraints、non-goals）
* 告訴 AI 你的專案脈絡，讓它調整決策邏輯
* 提供 learnings：「對於這個專案，[pattern] 應該總是 accept/skip」

### Q: Autoplan 執行很慢（超過 2 分鐘）

A: 正常情況下，四個審查合計約 60-90 秒。如果超過 2 分鐘：
* 可能是某個審查 skill 卡住了
* 可能是 plan.md 太大（超過 5000 行）

臨時解法：
* 只執行最重要的審查：`/autoplan --only ceo,eng`
* 分段審查：先審查 plan.md 的一部分

長期解法：
* 未來版本會支援平行執行四個審查（預計速度提升 3-4 倍）

### Q: 某個審查失敗了，怎麼辦？

A: Autoplan 會跳過失敗的審查並繼續其他審查。完成後：
* 手動執行失敗的審查來補上：`/plan-eng-review`（例如）
* 或檢查錯誤訊息，修正問題後重新執行 `/autoplan`

---

## 設計哲學

autoplan 的核心設計哲學：

### 1. 預設行動，例外才問（Default to Action, Ask Only Exceptions）

* 大多數審查建議有明確的對錯（security 一定修、明顯的 scope creep 一定刪）
* AI 應該自動處理明確的 95%，只把真正曖昧的 5% 拿出來問
* **反模式：** 把每個建議都列出來讓使用者確認 → 這只是把工作丟給使用者，沒有提供價值

### 2. 決策原則 > 啟發式（Principles > Heuristics）

* 不用「這個看起來像 scope creep」的模糊判斷
* 用明確的原則：「增加新平台 = scope creep」、「security fix = 永遠 accept」
* 原則可以檢驗、可以溝通、可以改進
* **反模式：** 用 ML 模型預測「這個應該 accept」→ 不可解釋，使用者無法信任

### 3. 可驗證、可質疑（Verifiable and Challengeable）

* 每個決策都記錄推理（套用了哪個原則、為什麼）
* 使用者可以查詢、覆寫、學習
* 如果使用者覆寫了很多決策，這是 signal：原則需要調整或專案脈絡需要明確化
* **反模式：** 黑箱決策，使用者只能接受或全部重來

### 4. Boil the Lake（煮沸整個湖）

* 跑完整審查流程的邊際成本接近零（AI 執行，不是人工）
* 所以預設就是「全部跑」（CEO + Design + Eng + DX），不要只跑一半
* 四個視角互補：CEO 看產品、Design 看體驗、Eng 看技術、DX 看開發者
* **反模式：** 只跑 CEO 審查，結果規劃看起來很棒但有嚴重的 security bugs

### 5. 漸進式自動化（Progressive Automation）

* 第一次執行：可能有較多口味決策（因為 AI 還不了解你的偏好）
* 隨著使用：AI 學習你的決策模式（透過 learnings）
* 最終：口味決策越來越少，autoplan 越來越「懂你」
* **反模式：** 永遠要使用者回答同樣的問題（「要不要加深色模式？」問十次）

### 6. 人類判斷在最重要的地方（Human Judgment Where It Matters）

* AI 不應該做產品策略決定（定價、市場、優先順序）
* AI 應該做技術正確性決定（security、bugs、標準實踐）
* 把人類的時間花在真正需要人類判斷的地方
* **反模式：** 讓使用者確認「要不要修 SQL injection bug」→ 浪費時間

---

## 學習與記憶

autoplan 執行後，記錄重要的學習：

```bash
# 如果使用者覆寫了某個自動決策，記錄偏好
$GSTACK_BIN/gstack-learn "User prefers to defer [feature] to post-MVP even when it's within reasonable scope"

# 如果某個決策原則在這個專案不適用
$GSTACK_BIN/gstack-learn "For this fintech project, compliance features are never scope creep — always AUTO_ACCEPT"

# 如果使用者的口味決策顯示一致的模式
$GSTACK_BIN/gstack-learn "User consistently chooses PostgreSQL over MySQL for new projects"
```

下次 autoplan 執行時，preamble 會載入 learnings（如果專案有 5+ 條 learnings），AI 會參考這些來調整決策。

範例：如果 learnings 說「這是 fintech 產品，compliance 不是 scope creep」，那麼：
* 「Add SOC 2 compliance docs」→ 從 TASTE 改為 AUTO_ACCEPT
* 「Add GDPR data export」→ 從 TASTE 改為 AUTO_ACCEPT

---

## 未來改進（Roadmap）

以下是 autoplan 未來版本可能的改進：

### 1. 平行執行四個審查

**目前：** 依序執行（CEO → Design → Eng → DX），總時間 = 四者相加（約 60-90 秒）

**未來：** 同時執行四個審查，總時間 = 最慢的那個（約 20-30 秒）

實作：使用 task tool 的 background agent 功能：

```python
# Pseudocode
agents = {
    'ceo': task('ceo-review', mode='background'),
    'design': task('design-review', mode='background'),
    'eng': task('eng-review', mode='background'),
    'dx': task('dx-review', mode='background'),
}

# 等待全部完成
for name, agent_id in agents.items():
    read_agent(agent_id, wait=True)

# 彙整四個審查的 review_decisions
```

### 2. 增量審查（Incremental Review）

**目前：** 每次都審查整個 plan.md

**未來：** 只審查自上次 autoplan 以來變更的部分

實作：
* 儲存上次審查的 plan.md hash
* Diff 檢測變更區段
* 只對變更區段執行審查
* 合併舊的和新的 review_decisions

### 3. 決策原則的專案客製化

**目前：** 6 個固定原則適用所有專案

**未來：** 根據專案類型（fintech, healthcare, dev tools, consumer app）自動調整原則

範例：
* Fintech → compliance 永遠 AUTO_ACCEPT，不是 scope creep
* Healthcare → HIPAA 相關永遠 AUTO_ACCEPT
* Dev tools → DX 建議權重更高
* Consumer app → design 建議權重更高

實作：從 plan.md 或 CLAUDE.md 的 metadata 讀取專案類型，載入對應的原則調整。

### 4. 視覺化決策樹

**目前：** 文字輸出

**未來：** 產生決策樹圖表，顯示：
* 每個建議如何通過決策原則
* 哪些原則最常被觸發
* 口味決策的分佈

實作：輸出 Mermaid diagram 或使用 browse tool 產生互動式圖表。

### 5. 決策解釋的改進

**目前：** 簡短的 reasoning 文字

**未來：** 更豐富的解釋：
* 引用 plan.md 的相關區段來支持決策
* 顯示類似建議的歷史決策
* 提供「如果你選 A 會怎樣 vs. 選 B 會怎樣」的影響分析

---

## 回報問題

如果決策原則有 bug 或邊界案例沒涵蓋到，請記錄：

```sql
CREATE TABLE IF NOT EXISTS principle_feedback (
  item_id TEXT,
  expected_decision TEXT,
  actual_decision TEXT,
  user_feedback TEXT,
  plan_context TEXT,
  timestamp INTEGER DEFAULT (strftime('%s', 'now'))
);

INSERT INTO principle_feedback (item_id, expected_decision, actual_decision, user_feedback, plan_context)
VALUES (
  'design-dark-mode',
  'TASTE',
  'AUTO_SKIP',
  'Dark mode should be TASTE not AUTO_SKIP — both choices are reasonable for MVP, not clear scope creep',
  'MVP for a developer tool'
);
```

定期彙整這些 feedback 來改進決策原則。

如果多個使用者回報同一個 pattern，這表示原則需要調整或增加新原則。

---

## 結語

autoplan 讓你從「花 30 分鐘逐項審查規劃」變成「花 3 分鐘確認幾個口味決策」。

**什麼時候用 autoplan：**
* ✅ 你有一個 plan.md，想要快速得到四個視角的完整審查
* ✅ 你信任決策原則，只想專注在真正需要你判斷的事
* ✅ 你想要 AI 幫你處理明確的改進（security、bugs、scope reduction、quality enhancements）

**什麼時候不用 autoplan：**
* ❌ 你想要完全手動控制每個決定 → 用單獨的審查技能（`/plan-ceo-review` 等）並選擇互動模式
* ❌ 你的專案有非常特殊的約束，標準決策原則完全不適用 → 先明確化約束（更新 plan.md 的 Constraints 區段或 CLAUDE.md），然後再跑 autoplan
* ❌ plan.md 還在早期構思階段，內容不完整 → 先用 `/office-hours` 或 `/plan-ceo-review` 建立第一版完整規劃

**Autoplan 的價值：**
* ⏱️ 節省時間：從 30 分鐘 → 3 分鐘
* 🎯 聚焦判斷：只處理真正需要你的決策
* 🔒 提升品質：不會漏掉 security issues（AI 會自動補上）
* 📊 可追溯：每個決策都有記錄和推理
* 🔄 可重複：更新規劃後可以重新跑 autoplan

---

**Happy auto-planning! 🚀**
