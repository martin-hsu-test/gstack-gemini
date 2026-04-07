---
name: careful
description: |
  危險指令安全護欄。在執行 rm -rf、DROP TABLE、force-push、git reset --hard、
  kubectl delete 等破壞性操作前發出警告。用戶可覆蓋每個警告。
  碰正式環境、除錯線上系統或共享環境時使用。
  說「小心一點」、「安全模式」、「正式環境模式」、「careful」時觸發。
---
<!-- AUTO-GENERATED from SKILL.md.tmpl — do not edit directly -->
<!-- Regenerate: bun run gen:skill-docs -->
> **安全提示：** 本 skill 包含安全檢查，會在執行前掃描 bash 指令中的破壞性操作（rm -rf、DROP TABLE、force-push、git reset --hard 等）。使用本 skill 時，執行可能有破壞性的操作前請暫停確認。若不確定某個指令是否安全，請先向用戶確認再繼續。


# /careful — 破壞性指令護欄

安全模式已 **啟動**。每條 bash 指令在執行前都會檢查破壞性模式。偵測到危險指令時會發出警告，你可以選擇繼續或取消。

```bash
mkdir -p ~/.gstack/analytics
```

## 受保護的操作

| 模式 | 範例 | 風險 |
|---------|---------|------|
| `rm -rf` / `rm -r` / `rm --recursive` | `rm -rf /var/data` | 遞迴刪除 |
| `DROP TABLE` / `DROP DATABASE` | `DROP TABLE users;` | 資料遺失 |
| `TRUNCATE` | `TRUNCATE orders;` | 資料遺失 |
| `git push --force` / `-f` | `git push -f origin main` | 歷史覆寫 |
| `git reset --hard` | `git reset --hard HEAD~3` | 未提交變更遺失 |
| `git checkout .` / `git restore .` | `git checkout .` | 未提交變更遺失 |
| `kubectl delete` | `kubectl delete pod` | 影響正式環境 |
| `docker rm -f` / `docker system prune` | `docker system prune -a` | 容器/映像檔遺失 |

## 安全例外

以下模式允許直接執行，不需警告：
- `rm -rf node_modules` / `.next` / `dist` / `__pycache__` / `.cache` / `build` / `.turbo` / `coverage`

## 運作原理

hook 從工具輸入的 JSON 中讀取指令，對照上述模式進行檢查，若有符合的結果則回傳 `permissionDecision: "ask"` 並附上警告訊息。你隨時可以覆蓋警告並繼續執行。

若要停用，結束對話或開啟新對話即可。hook 的作用域為單一 session。
