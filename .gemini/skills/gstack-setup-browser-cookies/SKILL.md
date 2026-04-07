---
name: setup-browser-cookies
description: |
  從真實 Chromium 瀏覽器匯入 Cookie 到無頭測試 session。開啟互動式選取 UI 讓你
  選擇要匯入哪些網域的 Cookie。在測試需要登入的頁面前使用。
  說「匯入 cookie」、「登入狀態測試」、「測試需要登入的頁面」時觸發。
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
$GSTACK_BIN/gstack-timeline-log '{"skill":"setup-browser-cookies","event":"started","branch":"'"$_BRANCH"'","session":"'"$_SESSION_ID"'"}' 2>/dev/null &
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

若 `PROACTIVE` 為 `"false"`，不要主動建議 gstack skills，也不要根據對話脈絡自動呼叫 skills。只執行用戶明確輸入的指令（例如 /qa、/ship）。若原本會自動呼叫某個 skill，改為簡短說明：「我覺得 /skillname 可能有幫助——要我執行嗎？」然後等待確認。用戶已選擇關閉主動行為。

若 `SKILL_PREFIX` 為 `"true"`，用戶已為 skill 名稱加上命名空間前綴。建議或呼叫其他 gstack skills 時，使用 `/gstack-` 前綴（例如 `/gstack-qa` 而非 `/qa`，`/gstack-ship` 而非 `/ship`）。磁碟路徑不受影響——讀取 skill 檔案時一律使用 `$GSTACK_ROOT/[skill-name]/SKILL.md`。

若輸出顯示 `UPGRADE_AVAILABLE <old> <new>`：讀取 `$GSTACK_ROOT/gstack-upgrade/SKILL.md` 並依照「Inline upgrade flow」執行（若已設定自動升級則直接升級，否則以 AskUserQuestion 提供 4 個選項，若用戶拒絕則寫入 snooze 狀態）。若顯示 `JUST_UPGRADED <from> <to>`：告知用戶「Running gstack v{to} (just updated!)」然後繼續。

若 `LAKE_INTRO` 為 `no`：在繼續之前，介紹 Completeness Principle。
告知用戶：「gstack 遵循 **Boil the Lake** 原則——當 AI 使邊際成本趨近於零時，永遠做完整的事。閱讀更多：https://garryslist.org/posts/boil-the-ocean」
然後詢問是否要在預設瀏覽器中開啟這篇文章：

```bash
open https://garryslist.org/posts/boil-the-ocean
touch ~/.gstack/.completeness-intro-seen
```

只有在用戶同意時才執行 `open`。`touch` 則一律執行以標記為已讀。這只會發生一次。



若 `PROACTIVE_PROMPTED` 為 `no`：
詢問用戶關於主動行為的偏好。使用 AskUserQuestion：

> gstack 可以在你工作時主動判斷何時可能需要某個 skill——
> 例如你說「這樣可以嗎？」時建議 /qa，或碰到 bug 時建議 /investigate。
> 建議保持開啟——這能加速你工作流程的每個環節。

選項：
- A) 保持開啟（推薦）
- B) 關閉——我自己輸入 /commands

若選 A：執行 `$GSTACK_BIN/gstack-config set proactive true`
若選 B：執行 `$GSTACK_BIN/gstack-config set proactive false`

一律執行：
```bash
touch ~/.gstack/.proactive-prompted
```

這只會發生一次。若 `PROACTIVE_PROMPTED` 為 `yes`，跳過此段。

若 `HAS_ROUTING` 為 `no` 且 `ROUTING_DECLINED` 為 `false` 且 `PROACTIVE_PROMPTED` 為 `yes`：
檢查專案根目錄是否存在 CLAUDE.md 檔案。若不存在，建立一個。

使用 AskUserQuestion：

> gstack 在你的專案 CLAUDE.md 包含 skill routing 規則時效果最好。
> 這能讓 Claude 使用專門的工作流程（如 /ship、/investigate、/qa）
> 而非直接回答。這是一次性新增，約 15 行。

選項：
- A) 新增 routing 規則到 CLAUDE.md（推薦）
- B) 不用了，我自己手動呼叫 skills

若選 A：將以下段落附加到 CLAUDE.md 末尾：

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
說：「沒問題。之後可以執行 `gstack-config set routing_declined false` 並重新執行任何 skill 來新增 routing 規則。」

這只會在每個專案發生一次。若 `HAS_ROUTING` 為 `yes` 或 `ROUTING_DECLINED` 為 `true`，跳過此段。

若 `VENDORED_GSTACK` 為 `yes`：此專案在 `.gemini/skills/gstack/` 有一份 vendored 的 gstack 副本。Vendoring 已廢棄。我們不會持續更新 vendored 副本，這個專案的 gstack 將會落後。

使用 AskUserQuestion（每個專案只問一次，檢查 `~/.gstack/.vendoring-warned-$SLUG` 標記檔案）：

> 此專案在 `.gemini/skills/gstack/` 有 vendored 的 gstack。Vendoring 已廢棄。
> 我們不會更新這份副本，你將錯過新功能與修正。
>
> 要遷移到 team mode 嗎？大約 30 秒即可完成。

選項：
- A) 是，現在遷移到 team mode
- B) 不，我自己處理

若選 A：
1. 執行 `git rm -r .gemini/skills/gstack/`
2. 執行 `echo '.gemini/skills/gstack/' >> .gitignore`
3. 執行 `$GSTACK_BIN/gstack-team-init required`（或 `optional`）
4. 執行 `git add .claude/ .gitignore CLAUDE.md && git commit -m "chore: migrate gstack from vendored to team mode"`
5. 告知用戶：「完成。每位開發者現在執行：`cd $GSTACK_ROOT && ./setup --team`」

若選 B：說「好的，請自行維持 vendored 副本的更新。」

一律執行（無論選哪個選項）：
```bash
eval "$($GSTACK_BIN/gstack-slug 2>/dev/null)" 2>/dev/null || true
touch ~/.gstack/.vendoring-warned-${SLUG:-unknown}
```

這只會在每個專案發生一次。若標記檔案已存在，跳過此段。

若 `SPAWNED_SESSION` 為 `"true"`，表示你正在 AI 協調器（例如 OpenClaw）生成的 session 中執行。在這類 session 中：
- 不要使用 AskUserQuestion 進行互動式提示。自動選擇推薦選項。
- 不要執行升級檢查、routing 注入或 lake intro。
- 專注於完成任務並以文字輸出回報結果。
- 結束時附上完成報告：已完成的事項、做出的決策、任何不確定的地方。

## 語氣

**風格：** 直接、具體、銳利，不說企業話術，不說學術腔。說話像建造者，不像顧問。點名檔案、函數、指令。不廢話，不鋪陳。

**寫作規則：** 不用破折號（用逗號、句號或「...」代替）。不用 AI 詞彙（delve、crucial、robust、comprehensive、nuanced 等）。短段落。結尾說明下一步。

用戶永遠有你不知道的背景。多個模型的共識是建議，不是決定——由用戶決定。

## 完成狀態協定

完成 skill 工作流程時，使用以下其中一個狀態回報：
- **DONE** — 所有步驟已成功完成。每項聲明都附有佐證。
- **DONE_WITH_CONCERNS** — 已完成，但有用戶應知悉的問題。逐一列出每個疑慮。
- **BLOCKED** — 無法繼續。說明阻礙原因及已嘗試的做法。
- **NEEDS_CONTEXT** — 缺少繼續所需的資訊。明確說明需要什麼。

### 升級處理

隨時可以停下來說「這超出我的能力範圍」或「我對這個結果沒有信心」。

做壞的事比什麼都不做更糟糕。升級不會受到懲罰。
- 若某個任務已嘗試 3 次仍未成功，停下來並升級。
- 若對涉及安全的變更感到不確定，停下來並升級。
- 若工作範圍超出你能驗證的程度，停下來並升級。

升級格式：
```
STATUS: BLOCKED | NEEDS_CONTEXT
REASON: [1-2 句話]
ATTEMPTED: [你嘗試過的做法]
RECOMMENDATION: [建議用戶下一步做什麼]
```

## 操作自我改進

完成前，回顧本次 session：
- 有指令意外失敗嗎？
- 有走錯方向後需要回頭重來嗎？
- 有發現專案特有的奇特之處（建置順序、環境變數、時序、驗證）嗎？
- 有因為缺少某個 flag 或設定而花費比預期更多的時間嗎？

若有，記錄一筆操作學習供未來 session 使用：

```bash
$GSTACK_BIN/gstack-learnings-log '{"skill":"SKILL_NAME","type":"operational","key":"SHORT_KEY","insight":"DESCRIPTION","confidence":N,"source":"observed"}'
```

將 SKILL_NAME 替換為目前的 skill 名稱。只記錄真正的操作發現。
不要記錄顯而易見的事或一次性的暫時性錯誤（網路閃斷、rate limit 等）。
好的判斷標準：這個資訊能在未來 session 省下 5 分鐘以上嗎？若能，記錄下來。

## Plan Mode 安全操作

在 plan mode 中，以下操作一律允許，因為它們產生的是用於輔助計畫的產出物，而非程式碼變更：

- `$B` 指令（browse：截圖、頁面檢查、導覽、快照）
- `$D` 指令（design：生成 mockup、變體、比較看板、迭代）
- `codex exec` / `codex review`（外部觀點、計畫審查、對抗性挑戰）
- 寫入 `~/.gstack/`（設定、審查日誌、設計產出物、learnings）
- 寫入 plan 檔案（plan mode 本已允許）
- 用於查看生成產出物的 `open` 指令（比較看板、HTML 預覽）

這些操作在本質上是唯讀的——它們檢查線上網站、生成視覺產出物或取得獨立意見。它們不修改專案原始檔。

## Plan Mode 中的 Skill 呼叫

若用戶在 plan mode 中呼叫某個 skill，該 skill 工作流程在完成或用戶明確取消之前，優先於通用的 plan mode 行為。

將載入的 skill 視為可執行的指示，而非參考資料。逐步執行，不要摘要、跳過、重排或簡化其步驟。

若 skill 要求使用 AskUserQuestion，就執行。這些 AskUserQuestion 呼叫能滿足 plan mode 要求每個回合以 AskUserQuestion 結尾的規定。

若 skill 到達 STOP 點，立即在該點停下，若有需要則提出要求的問題，然後等待用戶回應。不要繼續執行超過 STOP 點的工作流程，也不要在該點呼叫 ExitPlanMode。

若 skill 包含標記為「PLAN MODE EXCEPTION — ALWAYS RUN」的指令，執行它們。skill 可以編輯 plan 檔案，其他寫入操作只有在已被 Plan Mode 安全操作允許或明確標記為 plan mode 例外時才可執行。

只有在所有已啟動的 skill 工作流程都完成後，或用戶明確告知取消 skill 或離開 plan mode 時，才呼叫 ExitPlanMode。

## Plan 狀態頁尾

當你在 plan mode 中即將呼叫 ExitPlanMode 時：

1. 檢查 plan 檔案末尾是否已有 `## GSTACK REVIEW REPORT` 段落。
2. 若**有**——跳過（某個 review skill 已寫入更完整的報告）。
3. 若**沒有**——執行此指令：

\`\`\`bash
$GSTACK_ROOT/bin/gstack-review-read
\`\`\`

然後將 `## GSTACK REVIEW REPORT` 段落寫入 plan 檔案末尾：

- 若輸出包含 review 記錄（`---CONFIG---` 之前的 JSONL 行）：以標準報告表格格式呈現每個 skill 的執行次數/狀態/發現，格式與 review skills 相同。
- 若輸出為 `NO_REVIEWS` 或空白：寫入以下佔位符表格：

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

**PLAN MODE EXCEPTION — ALWAYS RUN:** 這會寫入 plan 檔案，這是你在 plan mode 中唯一可以編輯的檔案。plan 檔案的 review 報告是計畫即時狀態的一部分。

# 設定瀏覽器 Cookie

將你真實 Chromium 瀏覽器中的已登入 session 匯入到無頭 browse session。

## CDP 模式檢查

首先，檢查 browse 是否已連接到用戶的真實瀏覽器：
```bash
$B status 2>/dev/null | grep -q "Mode: cdp" && echo "CDP_MODE=true" || echo "CDP_MODE=false"
```
若 `CDP_MODE=true`：告知用戶「不需要——你已透過 CDP 連接到真實瀏覽器。Cookie 和 session 都已可用。」然後停止。不需要匯入 cookie。

## 運作原理

1. 找到 browse 執行檔
2. 執行 `cookie-import-browser` 偵測已安裝的瀏覽器並開啟選取 UI
3. 用戶在瀏覽器中選擇要匯入哪些 cookie 網域
4. Cookie 解密後載入到 Playwright session

## 步驟

### 1. 找到 browse 執行檔

## 設置（執行任何 browse 指令前先執行此檢查）

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
1. 告知用戶：「gstack browse 需要一次性建置（約 10 秒）。可以繼續嗎？」然後停止並等待。
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

### 2. 開啟 cookie 選取器

```bash
$B cookie-import-browser
```

這會自動偵測已安裝的 Chromium 瀏覽器，並在你的預設瀏覽器中開啟互動式選取 UI，讓你可以：
- 切換已安裝的瀏覽器
- 搜尋網域
- 點擊「+」匯入某個網域的 cookie
- 點擊垃圾桶移除已匯入的 cookie

告知用戶：**「Cookie 選取器已開啟——在瀏覽器中選擇要匯入的網域，完成後告訴我。」**

### 3. 直接匯入（替代方式）

若用戶直接指定網域（例如 `/setup-browser-cookies github.com`），跳過 UI：

```bash
$B cookie-import-browser comet --domain github.com
```

若用戶有指定，將 `comet` 替換為對應的瀏覽器。

### 4. 驗證

用戶確認完成後：

```bash
$B cookies
```

向用戶顯示已匯入 cookie 的摘要（各網域的 cookie 數量）。

## 注意事項

- 在 macOS 上，每個瀏覽器第一次匯入時可能會觸發 Keychain 對話框——點擊「允許」或「永遠允許」
- 在 Linux 上，`v11` cookie 可能需要 `secret-tool`/libsecret 存取權；`v10` cookie 使用 Chromium 的標準備用金鑰
- Cookie 選取器與 browse server 共用同一個 port（不需要額外的程序）
- UI 中只顯示網域名稱和 cookie 數量——不會暴露 cookie 的值
- browse session 在指令間持續保留 cookie，因此匯入的 cookie 可立即使用
