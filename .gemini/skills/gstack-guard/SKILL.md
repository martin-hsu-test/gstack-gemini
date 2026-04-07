---
name: guard
description: |
  完整安全模式 = careful + freeze 組合。危險指令警告（rm -rf、DROP TABLE、force-push
  等）+ 限制在指定目錄外不能編輯。碰正式環境或線上除錯時使用。
  說「guard 模式」、「完整安全模式」、「鎖住」、「最高安全」時觸發。
---
<!-- AUTO-GENERATED from SKILL.md.tmpl — do not edit directly -->
<!-- Regenerate: bun run gen:skill-docs -->
> **安全提示：** 本 skill 包含安全檢查，會在執行前掃描 bash 指令中的破壞性操作（rm -rf、DROP TABLE、force-push、git reset --hard 等），並在套用前驗證檔案編輯是否在允許的範圍邊界內，以及驗證檔案寫入是否在允許的範圍邊界內。使用本 skill 時，執行可能有破壞性的操作前請暫停確認。若不確定某個指令是否安全，請先向用戶確認再繼續。


# /guard — 完整安全模式

同時啟動破壞性指令警告與目錄範圍編輯限制。
這是將 `/careful` + `/freeze` 合併成單一指令執行。

**相依性說明：** 本 skill 參照同層級 `/careful` 和 `/freeze` skill 目錄中的 hook 腳本。兩者都必須已安裝（gstack 安裝腳本會一併安裝）。

```bash
mkdir -p ~/.gstack/analytics
```

## 設定

詢問用戶要將編輯限制在哪個目錄。使用 AskUserQuestion：

- 問題：「Guard 模式：編輯應限制在哪個目錄？破壞性指令警告會一律啟用。選定路徑以外的檔案將禁止編輯。」
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

告知用戶：
- 「**Guard 模式已啟動。** 目前有兩道防護正在運作：」
- 「1. **破壞性指令警告** — rm -rf、DROP TABLE、force-push 等執行前會發出警告（可覆蓋）」
- 「2. **編輯邊界** — 檔案編輯限制在 `<path>/`。此目錄以外的編輯將被封鎖。」
- 「若要移除編輯邊界，執行 `/unfreeze`。若要停用所有防護，結束 session 即可。」

## 受保護的操作

破壞性指令模式完整清單及安全例外請參閱 `/careful`。
編輯邊界的執行方式請參閱 `/freeze`。
