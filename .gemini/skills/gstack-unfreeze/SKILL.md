---
name: unfreeze
description: |
  清除 /freeze 設定的編輯邊界，讓所有目錄都可以編輯。不需要結束 session，
  直接擴大編輯範圍。
  說「解凍」、「解除限制」、「取消 freeze」、「unfreeze」時觸發。
---
<!-- AUTO-GENERATED from SKILL.md.tmpl — do not edit directly -->
<!-- Regenerate: bun run gen:skill-docs -->

# /unfreeze — 清除 Freeze 邊界

移除 `/freeze` 設定的編輯限制，允許編輯所有目錄。

```bash
mkdir -p ~/.gstack/analytics
```

## 清除邊界

```bash
STATE_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.gstack}"
if [ -f "$STATE_DIR/freeze-dir.txt" ]; then
  PREV=$(cat "$STATE_DIR/freeze-dir.txt")
  rm -f "$STATE_DIR/freeze-dir.txt"
  echo "Freeze boundary cleared (was: $PREV). Edits are now allowed everywhere."
else
  echo "No freeze boundary was set."
fi
```

告知用戶執行結果。注意 `/freeze` hook 在這個 session 中仍然是已註冊的狀態——只是因為 state 檔案不存在，所以會放行所有操作。若要重新 freeze，再執行 `/freeze` 即可。
