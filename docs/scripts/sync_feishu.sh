#!/usr/bin/env bash
# 飞书 md 同步脚本 — 将本地 md overwrite 到既有的飞书 Wiki 文档
#
# 功能：
#   1. 按 doc_id overwrite，不新建文档（保留飞书侧的节点树结构 + 评论）
#   2. 把正文里的团队成员姓名（张翼翔/孙栩尧/李远哲）转成飞书 <mention-user id="..."/>
#   3. 支持同步全部 / 单个文件 / --dry-run
#
# 前置：
#   - 本机已装 lark-cli 且 `lark-cli auth status` 正常（账号：张翼翔）
#   - Node 在 PATH（若 homebrew 未 link 则脚本会自动补 /opt/homebrew/opt/node/bin）
#   - 已在 MAPPING 里配好每个 md 对应的飞书 doc_id（首次创建可用旧版 create 模式）
#
# 用法：
#   bash scripts/sync_feishu.sh                # 同步全部（6 个文档）
#   bash scripts/sync_feishu.sh todo           # 只同步 TODO
#   bash scripts/sync_feishu.sh todo --dry-run # 不提交，只打印 payload
#   bash scripts/sync_feishu.sh --list         # 列出当前映射和用户 ID
#
# 如何找 doc_id：
#   lark-cli api GET /open-apis/wiki/v2/spaces/<space_id>/nodes \
#     --params '{"parent_node_token":"<parent>","page_size":50}' \
#     --jq '.data.items[]|{title,obj_token}'
#   obj_token 即 docx doc_id。

set -euo pipefail
cd "$(dirname "$0")/.."

# 确保 node 在 PATH（homebrew 下 node 经常只有 opt link）
export PATH="/opt/homebrew/opt/node/bin:${PATH}"

LARK_BIN="$(command -v lark-cli || echo /opt/homebrew/lib/node_modules/@larksuite/cli/bin/lark-cli)"
if [[ ! -x "$LARK_BIN" ]]; then
  echo "❌ 找不到 lark-cli；请先 npm i -g @larksuite/cli" >&2
  exit 1
fi

# ====== 配置区 ======

# 知识库 space_id（仅作参考，overwrite 模式不用）
WIKI_SPACE="7625648528720284882"

# 团队成员飞书 open_id（正文里的姓名会被替换为 <mention-user id="..."/>）
USER_ZHANG_YIXIANG="ou_7b3000af938aee4b035043e9635cd411"  # 张翼翔
USER_SUN_XUYAO="ou_e8b984948b6a87527333b52cf7164eb6"      # 孙栩尧
USER_LI_YUANZHE="ou_31a4483c766d771f4474dd2496f41149"     # 李远哲

# key | 本地 md 文件 | 飞书 doc_id（obj_token，非 node_token）
MAPPING=(
  "contract|软件开发服务合同.md|Sdm9dyCWsoIez4xpV0wcabkonzh"
  "meeting|会议纪要-TikTok电商运营流程与AI改造方案.md|KUbWdxKFkogW9HxzGITczN8onDb"
  "data|数据平台调研报告.md|FHNWdTxriosffgxiIkQcUr1RnZe"
  "todo|TODO.md|Hm6Td16TioDrdUxuPirc8C96n1b"
  "cost|MVP成本估算.md|T9ZndjFO3or41FxOVU9cNnq6nEh"
  "design|MVP产品设计.md|DO5wd67IcoplmXxBYEWcwSzDnjc"
)

# ====== 参数解析 ======

DRY=""
ONLY=""
LIST_ONLY=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY="--dry-run" ;;
    --list) LIST_ONLY="1" ;;
    -h|--help)
      sed -n '2,30p' "$0" | sed 's/^# //;s/^#//'
      exit 0
      ;;
    *) ONLY="$arg" ;;
  esac
done

if [[ -n "$LIST_ONLY" ]]; then
  echo "Wiki space: $WIKI_SPACE"
  echo
  echo "Users (will be converted to <mention-user/>):"
  printf "  %-10s %s\n" "张翼翔" "$USER_ZHANG_YIXIANG"
  printf "  %-10s %s\n" "孙栩尧" "$USER_SUN_XUYAO"
  printf "  %-10s %s\n" "李远哲" "$USER_LI_YUANZHE"
  echo
  echo "Documents:"
  printf "  %-10s %-60s %s\n" "KEY" "FILE" "DOC_ID"
  for row in "${MAPPING[@]}"; do
    IFS='|' read -r k f d <<< "$row"
    printf "  %-10s %-60s %s\n" "$k" "$f" "$d"
  done
  exit 0
fi

# ====== 核心：mention 转换 ======
# 把姓名转成 <mention-user id="..."/>。本地 md 保持纯文本可读，只在推送前做转换。
transform () {
  sed \
    -e "s|张翼翔|<mention-user id=\"${USER_ZHANG_YIXIANG}\"/>|g" \
    -e "s|孙栩尧|<mention-user id=\"${USER_SUN_XUYAO}\"/>|g" \
    -e "s|李远哲|<mention-user id=\"${USER_LI_YUANZHE}\"/>|g" \
    "$1"
}

# ====== 同步一个文档 ======
sync_one () {
  local key="$1" file="$2" doc_id="$3"
  echo "==> [$key] $file  →  $doc_id"
  if [[ ! -f "$file" ]]; then
    echo "   ⚠ 跳过（文件不存在）"
    return 1
  fi

  local markdown
  markdown="$(transform "$file")"

  if [[ -n "$DRY" ]]; then
    echo "   (dry-run) 字符数: ${#markdown}"
    # 可选：也打印前几行
    echo "$markdown" | head -5 | sed 's/^/   | /'
    return 0
  fi

  # overwrite 模式：覆盖整篇文档内容，保留节点位置/评论
  "$LARK_BIN" docs +update \
    --doc "$doc_id" \
    --mode overwrite \
    --markdown "$markdown" \
    2>&1 | grep -E '"success"|"message"|"error"|WARNING' | sed 's/^/   /' || true

  echo "   ✓ done"
}

# ====== 主循环 ======
if [[ -z "$ONLY" ]]; then
  for row in "${MAPPING[@]}"; do
    IFS='|' read -r k f d <<< "$row"
    sync_one "$k" "$f" "$d" || echo "   ✗ 失败，继续下一个"
  done
else
  for row in "${MAPPING[@]}"; do
    IFS='|' read -r k f d <<< "$row"
    if [[ "$k" == "$ONLY" ]]; then
      sync_one "$k" "$f" "$d"
      exit 0
    fi
  done
  echo "未知 key: $ONLY"
  echo "支持: contract | meeting | data | todo | cost | design"
  exit 1
fi
