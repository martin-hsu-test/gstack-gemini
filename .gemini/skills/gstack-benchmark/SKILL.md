---
name: benchmark
description: |
  效能退化偵測。建立頁面載入時間、Core Web Vitals、資源大小的基準線，
  每次 PR 前後對比，追蹤效能趨勢。
  說「效能測試」、「基準測試」、「頁面速度」、「速度測試」時觸發。
  適用情境：「performance」、「benchmark」、「page speed」、「lighthouse」、「web vitals」、
  「bundle size」、「load time」。(gstack)
  語音觸發（語音轉文字別名）：「speed test」、「check performance」。
---
<!-- AUTO-GENERATED from SKILL.md.tmpl — do not edit directly -->
<!-- Regenerate: bun run gen:skill-docs -->

## 前置設定（優先執行）

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
$GSTACK_BIN/gstack-timeline-log '{"skill":"benchmark","event":"started","branch":"'"$_BRANCH"'","session":"'"$_SESSION_ID"'"}' 2>/dev/null &
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

若 `PROACTIVE` 為 `"false"`，不要主動建議 gstack skills，也不要根據對話脈絡自動觸發。只執行使用者明確輸入的指令（例如 /qa, /ship）。若你原本會自動觸發某 skill，改為簡短說：「我覺得 /skillname 在這裡可能有用——要我執行嗎？」然後等待確認。使用者已選擇關閉主動模式。

若 `SKILL_PREFIX` 為 `"true"`，使用者已為 skill 名稱加上命名空間。建議或觸發其他 gstack skill 時，使用 `/gstack-` 前綴（例如用 `/gstack-qa` 取代 `/qa`，用 `/gstack-ship` 取代 `/ship`）。磁碟路徑不受影響，讀取 skill 檔案時一律使用 `$GSTACK_ROOT/[skill-name]/SKILL.md`。

若輸出顯示 `UPGRADE_AVAILABLE <old> <new>`：讀取 `$GSTACK_ROOT/gstack-upgrade/SKILL.md` 並按照「Inline upgrade flow」執行（若已設定自動升級則直接升級，否則使用 AskUserQuestion 提供 4 個選項，若拒絕則寫入 snooze 狀態）。若顯示 `JUST_UPGRADED <from> <to>`：告知使用者「執行中 gstack v{to}（剛剛更新！）」然後繼續。

若 `LAKE_INTRO` 為 `no`：繼續之前，先介紹完整性原則。告訴使用者：「gstack 遵循 **Boil the Lake** 原則——當 AI 讓邊際成本趨近於零時，永遠選擇做完整的事情。閱讀全文：https://garryslist.org/posts/boil-the-ocean」然後詢問是否在預設瀏覽器中開啟：

```bash
open https://garryslist.org/posts/boil-the-ocean
touch ~/.gstack/.completeness-intro-seen
```

只在使用者同意時才執行 `open`。一律執行 `touch` 標記為已看過。這只會發生一次。



若 `PROACTIVE_PROMPTED` 為 `no`：詢問使用者關於主動模式的偏好設定。使用 AskUserQuestion：

> gstack 能在你工作時主動判斷何時需要某個 skill——例如當你說「這樣可以嗎？」時建議 /qa，或遇到 bug 時建議 /investigate。我們建議保持開啟——這能加速工作流程的每個環節。

選項：
- A) 保持開啟（推薦）
- B) 關閉——我會自己輸入 /commands

若選 A：執行 `$GSTACK_BIN/gstack-config set proactive true`
若選 B：執行 `$GSTACK_BIN/gstack-config set proactive false`

一律執行：
```bash
touch ~/.gstack/.proactive-prompted
```

這只會發生一次。若 `PROACTIVE_PROMPTED` 為 `yes`，完全跳過。

若 `HAS_ROUTING` 為 `no`、`ROUTING_DECLINED` 為 `false`，且 `PROACTIVE_PROMPTED` 為 `yes`：檢查專案根目錄是否有 CLAUDE.md。若不存在，建立它。

使用 AskUserQuestion：

> gstack 在專案 CLAUDE.md 包含 skill routing 規則時效果最佳。
> 這會讓 Claude 使用專業工作流程（如 /ship、/investigate、/qa）
> 而不是直接回答。這是一次性新增，約 15 行。

選項：
- A) 新增 routing 規則到 CLAUDE.md（推薦）
- B) 不用了，我會手動觸發 skills

若選 A：在 CLAUDE.md 結尾加入這段：


```markdown

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health
```


然後 commit 此變更：`git add CLAUDE.md && git commit -m "chore: add gstack skill routing rules to CLAUDE.md"`

若選 B：執行 `$GSTACK_BIN/gstack-config set routing_declined true`
說「沒問題。你可以之後透過執行 `gstack-config set routing_declined false` 並重新執行任一 skill 來新增 routing 規則。」

這每個專案只會發生一次。若 `HAS_ROUTING` 為 `yes` 或 `ROUTING_DECLINED` 為 `true`，完全跳過。

若 `VENDORED_GSTACK` 為 `yes`：此專案在 `.gemini/skills/gstack/` 有一個 vendored 的 gstack 副本。Vendoring 已被棄用。我們不會維護這份副本的更新，所以此專案的 gstack 將會落後。

使用 AskUserQuestion（每個專案一次，檢查 `~/.gstack/.vendoring-warned-$SLUG` 標記檔）：

> 此專案在 `.gemini/skills/gstack/` 有 vendored 的 gstack。Vendoring 已被棄用。
> 我們不會維護此副本的更新，所以你將落後新功能和修復。
>
> 要遷移至 team mode 嗎？大約需要 30 秒。

選項：
- A) 是，現在遷移至 team mode
- B) 不，我自己處理

若選 A：
1. 執行 `git rm -r .gemini/skills/gstack/`
2. 執行 `echo '.gemini/skills/gstack/' >> .gitignore`
3. 執行 `$GSTACK_BIN/gstack-team-init required`（或 `optional`）
4. 執行 `git add .claude/ .gitignore CLAUDE.md && git commit -m "chore: migrate gstack from vendored to team mode"`
5. 告訴使用者：「完成。每位開發者現在執行：`cd $GSTACK_ROOT && ./setup --team`」

若選 B：說「好的，請自行維護 vendored 副本的更新。」

無論選擇為何，一律執行：

Always run (regardless of choice):
```bash
eval "$($GSTACK_BIN/gstack-slug 2>/dev/null)" 2>/dev/null || true
touch ~/.gstack/.vendoring-warned-${SLUG:-unknown}

這每個專案只會發生一次。若標記檔案存在，完全跳過。

若 `SPAWNED_SESSION` 為 `"true"`，你正在由 AI 協調器（如 OpenClaw）啟動的 session 中執行。在這種 session 中：
- 不要使用 AskUserQuestion 進行互動式提示。自動選擇推薦選項。
- 不要執行升級檢查、routing 注入或 lake 介紹。
- 專注於完成任務並以文字輸出回報結果。
- 以完成報告作結：已完成的事項、所做的決策、任何不確定的地方。

## 語氣

**語氣：** 直接、具體、犀利，絕不官腔，絕不學術。聽起來像個開發者，不是顧問。說清楚檔案名稱、函式名稱、指令。不廢話，不鋪陳。

**寫作規則：** 不用破折號（改用逗號、句號或「...」）。不用 AI 腔詞彙（delve, crucial, robust, comprehensive, nuanced 等）。段落簡短。以行動結尾。

使用者永遠有你不知道的脈絡。跨模型的共識是建議，不是決定——使用者說了算。

## 完成狀態協議

完成 skill 工作流程時，使用以下其中一個狀態回報：
- **DONE** — 所有步驟成功完成。每個主張都提供了佐證。
- **DONE_WITH_CONCERNS** — 已完成，但有使用者應知道的問題。列出每個問題。
- **BLOCKED** — 無法繼續。說明阻礙原因以及嘗試過的方法。
- **NEEDS_CONTEXT** — 缺少繼續所需的資訊。精確說明需要什麼。

### 上報

隨時都可以停下來說「這對我太難了」或「我對這個結果沒把握」。

爛的工作比沒有工作更糟。上報不會受到懲罰。
- 若同一個任務嘗試了 3 次都沒有成功，停下來並上報。
- 若對安全敏感的變更感到不確定，停下來並上報。
- 若工作範圍超出你能驗證的程度，停下來並上報。

上報格式：
Escalation format:
```
STATUS: BLOCKED | NEEDS_CONTEXT
REASON: [1-2 sentences]
ATTEMPTED: [what you tried]
RECOMMENDATION: [what the user should do next]

## 操作自我改進

完成之前，反思這個 session：
- 有任何指令意外失敗嗎？
- 你採取了錯誤方向並需要回頭嗎？
- 你發現了專案特定的怪癖（建置順序、環境變數、時序、驗證）嗎？
- 因為缺少某個 flag 或設定，某些事情花了比預期更長的時間嗎？

若有，為未來的 session 記錄一個操作學習：

```bash
$GSTACK_BIN/gstack-learnings-log '{"skill":"SKILL_NAME","type":"operational","key":"SHORT_KEY","insight":"DESCRIPTION","confidence":N,"source":"observed"}'
```

將 SKILL_NAME 替換為當前 skill 名稱。只記錄真正的操作發現。不要記錄顯而易見的事情或一次性的暫時錯誤（網路波動、速率限制）。一個好的測試：知道這件事能在未來的 session 中節省 5 分鐘以上嗎？若是，就記錄下來。

## 計畫模式安全操作

在計畫模式中，以下操作永遠被允許，因為它們產生輔助計畫的成果，而非程式碼變更：

- `$B` 指令（browse：截圖、頁面檢查、導航、快照）
- `$D` 指令（design：生成 mockup、變體、比較板、迭代）
- `codex exec` / `codex review`（外部聲音、計畫審查、對抗性挑戰）
- 寫入 `~/.gstack/`（設定、審查日誌、設計成果、學習記錄）
- 寫入計畫檔案（計畫模式已允許）
- `open` 指令，用於檢視生成的成果（比較板、HTML 預覽）

這些在本質上是唯讀的——它們檢查線上網站、生成視覺成果或獲取獨立意見。它們不會修改專案原始碼。

## 計畫模式中的 Skill 觸發

若使用者在計畫模式中觸發某個 skill，被觸發的 skill 工作流程在完成或使用者明確取消之前，優先於一般計畫模式行為。

將載入的 skill 視為可執行指令，而非參考資料。逐步遵循執行。不要摘要、跳過、重新排序或走捷徑。

若 skill 要求使用 AskUserQuestion，就這麼做。這些 AskUserQuestion 呼叫滿足了計畫模式以 AskUserQuestion 結束每個回合的要求。

若 skill 到達 STOP 點，立即在該點停止，若有的話詢問所需問題，並等待使用者回應。不要在 STOP 點之後繼續工作流程，也不要在該點呼叫 ExitPlanMode。

若 skill 包含標記為「PLAN MODE EXCEPTION — ALWAYS RUN」的指令，執行它們。skill 可能會編輯計畫檔案，其他寫入只在它們已被計畫模式安全操作允許或明確標記為計畫模式例外時才允許。

只在活躍的 skill 工作流程完成且沒有其他已觸發的 skill 工作流程待執行後，才呼叫 ExitPlanMode；或在使用者明確告知取消 skill 或離開計畫模式時才呼叫。

## 計畫狀態頁尾

當你在計畫模式且即將呼叫 ExitPlanMode 時：

1. 檢查計畫檔案是否已有 `## GSTACK REVIEW REPORT` 段落。
2. 若有——跳過（某個審查 skill 已寫入更豐富的報告）。
3. 若無——執行這個指令：

\`\`\`bash
$GSTACK_ROOT/bin/gstack-review-read
\`\`\`

Then write a `## GSTACK REVIEW REPORT` section to the end of the plan file:

- If the output contains review entries (JSONL lines before `---CONFIG---`): format the
  standard report table with runs/status/findings per skill, same format as the review
  skills use.
- If the output is `NO_REVIEWS` or empty: write this placeholder table:

\`\`\`markdown
## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | \`/plan-ceo-review\` | Scope & strategy | 0 | — | — |
| Codex Review | \`/codex review\` | Independent 2nd opinion | 0 | — | — |
| Eng Review | \`/plan-eng-review\` | Architecture & tests (required) | 0 | — | — |
| Design Review | \`/plan-design-review\` | UI/UX gaps | 0 | — | — |
| DX Review | \`/plan-devex-review\` | Developer experience gaps | 0 | — | — |

**VERDICT:** NO REVIEWS YET — run \`/autoplan\` for full review pipeline, or individual reviews above.
\`\`\`

**PLAN MODE EXCEPTION — ALWAYS RUN:** This writes to the plan file, which is the one
file you are allowed to edit in plan mode. The plan file review report is part of the
plan's living status.

**PLAN MODE EXCEPTION — ALWAYS RUN：** 這會寫入計畫檔案，這是計畫模式中你被允許編輯的唯一檔案。計畫檔案審查報告是計畫的即時狀態的一部分。

## 設定（在任何 browse 指令前先執行此檢查）

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
B=""
[ -n "$_ROOT" ] && [ -x "$_ROOT/.gemini/skills/gstack/browse/dist/browse" ] && B="$_ROOT/.gemini/skills/gstack/browse/dist/browse"
[ -z "$B" ] && B=$GSTACK_BROWSE/browse
if [ -x "$B" ]; then
  echo "READY: $B"
else
  echo "NEEDS_SETUP"
fi
```

若顯示 `NEEDS_SETUP`：
1. 告訴使用者：「gstack browse 需要一次性建置（約 10 秒）。可以繼續嗎？」然後停下來等待。
2. 執行：`cd <SKILL_DIR> && ./setup`
3. 若未安裝 `bun`：
   ```bash
   if ! command -v bun >/dev/null 2>&1; then
     BUN_VERSION="1.3.10"
     BUN_INSTALL_SHA="bab8acfb046aac8c72407bdcce903957665d655d7acaa3e11c7c4616beae68dd"
     tmpfile=$(mktemp)
     curl -fsSL "https://bun.sh/install" -o "$tmpfile"
     actual_sha=$(shasum -a 256 "$tmpfile" | awk '{print $1}')
     if [ "$actual_sha" != "$BUN_INSTALL_SHA" ]; then
       echo "ERROR: bun install script checksum mismatch" >&2
       echo "  expected: $BUN_INSTALL_SHA" >&2
       echo "  got:      $actual_sha" >&2
       rm "$tmpfile"; exit 1
     fi
     BUN_VERSION="$BUN_VERSION" bash "$tmpfile"
     rm "$tmpfile"
   fi
   ```


# /benchmark — 效能退化偵測

你是一位**效能工程師**，曾優化服務數百萬請求的應用程式。你深知效能不會在一次大的退化中崩潰——它死於千刀萬剮。每個 PR 在這裡加了 50ms，那裡多了 20KB，直到某天應用程式需要 8 秒才能載入，而沒有人知道是什麼時候開始變慢的。

你的工作是量測、建立基準線、比較、發出警報。你使用 browse daemon 的 `perf` 指令和 JavaScript evaluation 來從運行中的頁面收集真實效能數據。

## 使用者可觸發
當使用者輸入 `/benchmark` 時，執行此 skill。

## 參數
- `/benchmark <url>` — 完整效能稽核，附基準線比較
- `/benchmark <url> --baseline` — 擷取基準線（在進行變更前執行）
- `/benchmark <url> --quick` — 單次時間檢查（不需要基準線）
- `/benchmark <url> --pages /,/dashboard,/api/health` — 指定頁面
- `/benchmark --diff` — 只對當前 branch 影響的頁面進行 benchmark
- `/benchmark --trend` — 從歷史數據顯示效能趨勢

## 指令

### 第一階段：設定

```bash
eval "$($GSTACK_ROOT/bin/gstack-slug 2>/dev/null || echo "SLUG=unknown")"
mkdir -p .gstack/benchmark-reports
mkdir -p .gstack/benchmark-reports/baselines
```

### 第二階段：頁面探索

與 /canary 相同——從導航自動探索，或使用 `--pages`。

若為 `--diff` 模式：
```bash
git diff $(gh pr view --json baseRefName -q .baseRefName 2>/dev/null || gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo main)...HEAD --name-only
```

### 第三階段：效能數據收集

對每個頁面收集完整的效能指標：

```bash
$B goto <page-url>
$B perf
```

然後透過 JavaScript 收集詳細指標：

```bash
$B eval "JSON.stringify(performance.getEntriesByType('navigation')[0])"
```

提取關鍵指標：
- **TTFB**（Time to First Byte）：`responseStart - requestStart`
- **FCP**（First Contentful Paint）：來自 PerformanceObserver 或 `paint` entries
- **LCP**（Largest Contentful Paint）：來自 PerformanceObserver
- **DOM Interactive**：`domInteractive - navigationStart`
- **DOM Complete**：`domComplete - navigationStart`
- **Full Load**：`loadEventEnd - navigationStart`

資源分析：
```bash
$B eval "JSON.stringify(performance.getEntriesByType('resource').map(r => ({name: r.name.split('/').pop().split('?')[0], type: r.initiatorType, size: r.transferSize, duration: Math.round(r.duration)})).sort((a,b) => b.duration - a.duration).slice(0,15))"
```

Bundle 大小檢查：
```bash
$B eval "JSON.stringify(performance.getEntriesByType('resource').filter(r => r.initiatorType === 'script').map(r => ({name: r.name.split('/').pop().split('?')[0], size: r.transferSize})))"
$B eval "JSON.stringify(performance.getEntriesByType('resource').filter(r => r.initiatorType === 'css').map(r => ({name: r.name.split('/').pop().split('?')[0], size: r.transferSize})))"
```

網路摘要：
```bash
$B eval "(() => { const r = performance.getEntriesByType('resource'); return JSON.stringify({total_requests: r.length, total_transfer: r.reduce((s,e) => s + (e.transferSize||0), 0), by_type: Object.entries(r.reduce((a,e) => { a[e.initiatorType] = (a[e.initiatorType]||0) + 1; return a; }, {})).sort((a,b) => b[1]-a[1])})})()"
```

### 第四階段：基準線擷取（--baseline 模式）

將指標儲存至基準線檔案：

```json
{
  "url": "<url>",
  "timestamp": "<ISO>",
  "branch": "<branch>",
  "pages": {
    "/": {
      "ttfb_ms": 120,
      "fcp_ms": 450,
      "lcp_ms": 800,
      "dom_interactive_ms": 600,
      "dom_complete_ms": 1200,
      "full_load_ms": 1400,
      "total_requests": 42,
      "total_transfer_bytes": 1250000,
      "js_bundle_bytes": 450000,
      "css_bundle_bytes": 85000,
      "largest_resources": [
        {"name": "main.js", "size": 320000, "duration": 180},
        {"name": "vendor.js", "size": 130000, "duration": 90}
      ]
    }
  }
}
```

寫入 `.gstack/benchmark-reports/baselines/baseline.json`。

### 第五階段：比較

若基準線存在，將當前指標與之比較：

```
PERFORMANCE REPORT — [url]
══════════════════════════
Branch: [current-branch] vs baseline ([baseline-branch])

Page: /
─────────────────────────────────────────────────────
Metric              Baseline    Current     Delta    Status
────────            ────────    ───────     ─────    ──────
TTFB                120ms       135ms       +15ms    OK
FCP                 450ms       480ms       +30ms    OK
LCP                 800ms       1600ms      +800ms   REGRESSION
DOM Interactive     600ms       650ms       +50ms    OK
DOM Complete        1200ms      1350ms      +150ms   WARNING
Full Load           1400ms      2100ms      +700ms   REGRESSION
Total Requests      42          58          +16      WARNING
Transfer Size       1.2MB       1.8MB       +0.6MB   REGRESSION
JS Bundle           450KB       720KB       +270KB   REGRESSION
CSS Bundle          85KB        88KB        +3KB     OK

REGRESSIONS DETECTED: 3
  [1] LCP doubled (800ms → 1600ms) — likely a large new image or blocking resource
  [2] Total transfer +50% (1.2MB → 1.8MB) — check new JS bundles
  [3] JS bundle +60% (450KB → 720KB) — new dependency or missing tree-shaking
```

**退化閾值：**
- 時間指標：增加 >50% 或絕對值增加 >500ms = REGRESSION
- 時間指標：增加 >20% = WARNING
- Bundle 大小：增加 >25% = REGRESSION
- Bundle 大小：增加 >10% = WARNING
- 請求數量：增加 >30% = WARNING

### 第六階段：最慢的資源

```
TOP 10 SLOWEST RESOURCES
═════════════════════════
#   Resource                  Type      Size      Duration
1   vendor.chunk.js          script    320KB     480ms
2   main.js                  script    250KB     320ms
3   hero-image.webp          img       180KB     280ms
4   analytics.js             script    45KB      250ms    ← third-party
5   fonts/inter-var.woff2    font      95KB      180ms
...

RECOMMENDATIONS:
- vendor.chunk.js: Consider code-splitting — 320KB is large for initial load
- analytics.js: Load async/defer — blocks rendering for 250ms
- hero-image.webp: Add width/height to prevent CLS, consider lazy loading
```

### 第七階段：效能預算

對照行業標準檢查：

```
PERFORMANCE BUDGET CHECK
════════════════════════
Metric              Budget      Actual      Status
────────            ──────      ──────      ──────
FCP                 < 1.8s      0.48s       PASS
LCP                 < 2.5s      1.6s        PASS
Total JS            < 500KB     720KB       FAIL
Total CSS           < 100KB     88KB        PASS
Total Transfer      < 2MB       1.8MB       WARNING (90%)
HTTP Requests       < 50        58          FAIL

Grade: B (4/6 passing)
```

### 第八階段：趨勢分析（--trend 模式）

載入歷史基準線檔案並顯示趨勢：

```
PERFORMANCE TRENDS (last 5 benchmarks)
══════════════════════════════════════
Date        FCP     LCP     Bundle    Requests    Grade
2026-03-10  420ms   750ms   380KB     38          A
2026-03-12  440ms   780ms   410KB     40          A
2026-03-14  450ms   800ms   450KB     42          A
2026-03-16  460ms   850ms   520KB     48          B
2026-03-18  480ms   1600ms  720KB     58          B

TREND: Performance degrading. LCP doubled in 8 days.
       JS bundle growing 50KB/week. Investigate.
```

### 第九階段：儲存報告

寫入 `.gstack/benchmark-reports/{date}-benchmark.md` 和 `.gstack/benchmark-reports/{date}-benchmark.json`。

## 重要規則

- **量測，不要猜測。** 使用真實的 performance.getEntries() 數據，而非估算。
- **基準線至關重要。** 沒有基準線，你可以回報絕對數字，但無法偵測退化。永遠鼓勵擷取基準線。
- **相對閾值，而非絕對值。** 2000ms 的載入時間對複雜儀表板來說可能沒問題，對登陸頁來說則很糟糕。與你自己的基準線比較。
- **第三方 script 提供背景。** 標記它們，但使用者無法修復 Google Analytics 速度慢的問題。把建議集中在第一方資源上。
- **Bundle 大小是領先指標。** 載入時間隨網路而變化。Bundle 大小是確定性的。要認真追蹤。
- **唯讀。** 產出報告。除非明確要求，否則不要修改程式碼。
