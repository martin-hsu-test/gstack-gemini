---
name: freeze
description: |
  限制本次 session 只能在指定目錄內編輯。在指定路徑外的 Edit 和 Write 都會被攔截。
  除錯時防止誤改無關程式碼，或想把改動範圍限在單一模組時使用。
  說「凍結」、「限制編輯」、「只能編這個資料夾」、「freeze」時觸發。
---
<!-- AUTO-GENERATED from SKILL.md.tmpl — do not edit directly -->
<!-- Regenerate: bun run gen:skill-docs -->
> **安全提示：** 本 skill 包含安全檢查，會在套用前驗證檔案編輯是否在允許的範圍邊界內，以及驗證檔案寫入是否在允許的範圍邊界內。使用本 skill 時，執行可能有破壞性的操作前請暫停確認。若不確定某個指令是否安全，請先向用戶確認再繼續。


# /freeze — 限制編輯至指定目錄

將檔案編輯鎖定在特定目錄。任何針對允許路徑以外檔案的 Edit 或 Write 操作將被**封鎖**（不只是警告）。

```bash
mkdir -p ~/.gstack/analytics
```

## 設定

詢問用戶要將編輯限制在哪個目錄。使用 AskUserQuestion：

- 問題：「要將編輯限制在哪個目錄？此路徑以外的檔案將禁止編輯。」
- 文字輸入（非多選）——用戶自行輸入路徑。

用戶提供目錄路徑後：

1. 解析為絕對路徑：
```bash
FREEZE_DIR=$(cd "<user-provided-path>" 2>/dev/null && pwd)
echo "$FREEZE_DIR"
```

2. 確保結尾有斜線並儲存至 freeze state 檔案：
```bash
FREEZE_DIR="${FREEZE_DIR%/}/"
STATE_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.gstack}"
mkdir -p "$STATE_DIR"
echo "$FREEZE_DIR" > "$STATE_DIR/freeze-dir.txt"
echo "Freeze boundary set: $FREEZE_DIR"
```

告知用戶：「編輯現在已限制在 `<path>/`。此目錄以外的任何 Edit 或 Write 都將被封鎖。若要變更邊界，再次執行 `/freeze`。若要移除限制，執行 `/unfreeze` 或結束 session。」

## 運作原理

hook 從 Edit/Write 工具輸入的 JSON 中讀取 `file_path`，然後檢查路徑是否以 freeze 目錄開頭。若否，回傳 `permissionDecision: "deny"` 封鎖操作。

freeze 邊界透過 state 檔案在 session 期間持續生效。hook 腳本在每次 Edit/Write 呼叫時都會讀取此檔案。

## 注意事項

- freeze 目錄結尾的 `/` 可防止 `/src` 誤匹配 `/src-old`
- Freeze 只影響 Edit 和 Write 工具——Read、Bash、Glob、Grep 不受影響
- 這是防止意外編輯的機制，並非安全邊界——`sed` 等 Bash 指令仍可修改邊界以外的檔案
- 若要停用，執行 `/unfreeze` 或結束對話
