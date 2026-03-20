# install_and_sync GitHub root URL 安裝失敗

## 問題分析

執行：

```bash
./install_and_sync.sh https://github.com/imxv/Pretty-mermaid-skills
```

出現錯誤：

```text
Error: Missing --path for GitHub URL.
```

追查後確認 `install_and_sync.sh` 只是把 `--url` 原樣轉交給 `skill-installer/scripts/install-skill-from-github.py`。真正拋錯的位置在 `install-skill-from-github.py` 的 `_resolve_source()`。

## Root Cause

- 當 `--url` 是 GitHub repo 根網址，例如 `https://github.com/imxv/Pretty-mermaid-skills`，解析後 `url_path` 會是空值。
- 原本程式在這種情況下不會把 repo root 視為合法 skill path，而是直接要求一定要有 `--path` 或 `/tree/<ref>/<path>`。
- 但 `Pretty-mermaid-skills` 這個 repo 的 `SKILL.md` 就在 repo root，因此這個限制過度嚴格，造成誤判。

## 解決方法

- 修改 `skill-installer/scripts/install-skill-from-github.py`：
  - 當 GitHub URL 指向 repo root 且未提供 `--path` 時，預設改用 `"."` 作為 skill path。
  - 當安裝 path 是 repo root (`"."`) 時，預設 skill 名稱改用 repo 名稱，避免產生非法名稱 `"."`。

## 結果

修正後，repo root 型態的 skill repo 可以正確往下執行安裝流程，不會再提早因為 `Missing --path for GitHub URL.` 中止。
