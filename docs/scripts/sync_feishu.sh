#!/usr/bin/env bash
# 飞书 md 同步脚本 — 在新知识库中创建 6 个文档
# 前置：lark-cli auth login --recommend（bot 已加入目标知识库）
# 用法：
#   bash scripts/sync_feishu.sh              # 同步全部
#   bash scripts/sync_feishu.sh contract     # 只同步一个
#   bash scripts/sync_feishu.sh contract --dry-run

set -euo pipefail
cd "$(dirname "$0")/.."

# 目标知识库 space_id（新建）
WIKI_SPACE="7625648528720284882"

# key | md 文件 | 文档标题
MAPPING=(
  "readme|README.md|TikTok ROI 智能运营平台"
  "todo|TODO.md|待完成任务"
  "meeting|会议纪要-TikTok电商运营流程与AI改造方案.md|0405会议纪要"
  "data|数据平台调研报告.md|TikTok 电商数据平台调研报告"
  "cost|MVP成本估算.md|MVP 阶段成本估算"
  "contract|软件开发服务合同.md|软件开发服务合同"
)

DRY=""
ONLY=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY="--dry-run" ;;
    *) ONLY="$arg" ;;
  esac
done

sync_one () {
  local key="$1" file="$2" title="$3"
  echo "==> [$key] $file -> ${title}"
  [[ -f "$file" ]] || { echo "   ⚠ 跳过（文件不存在）"; return; }

  lark-cli docs +create \
    --as user \
    --wiki-space "$WIKI_SPACE" \
    --title "$title" \
    --markdown "$(cat "$file")" \
    $DRY
  echo "   ✓ done"
}

if [[ -z "$ONLY" ]]; then
  for row in "${MAPPING[@]}"; do
    IFS='|' read -r k f t <<< "$row"
    sync_one "$k" "$f" "$t" || echo "   ✗ 失败，继续下一个"
  done
else
  for row in "${MAPPING[@]}"; do
    IFS='|' read -r k f t <<< "$row"
    if [[ "$k" == "$ONLY" ]]; then sync_one "$k" "$f" "$t"; exit 0; fi
  done
  echo "未知 key: $ONLY (支持: readme|todo|meeting|data|cost|contract)"
  exit 1
fi
