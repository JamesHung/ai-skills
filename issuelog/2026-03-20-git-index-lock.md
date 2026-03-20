# 2026-03-20 git index.lock 問題紀錄

## 問題分析

在執行 `git commit -m "docs: prefer subagent delegation by default"` 時，Git 回報 `.git/index.lock` 已存在，導致提交失敗。

## Root Cause

鎖檔很可能是前一個被中斷或未完整結束的 Git 流程殘留；後續重新檢查時，`.git/index.lock` 已不存在，表示屬於暫時性鎖定或殘留狀態。

## 解決方法

1. 先檢查 `.git/index.lock` 是否仍存在。
2. 再次檢查工作樹狀態，確認 staged 內容仍正確。
3. 於鎖檔消失後重新執行 `git commit`，提交成功。
