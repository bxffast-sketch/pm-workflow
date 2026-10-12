#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS=(pm-collect pm-clarify pm-value pm-prd pm-proto pm)
TARGET_DIR="$HOME/.claude/skills"

mkdir -p "$TARGET_DIR"

for skill in "${SKILLS[@]}"; do
  src="$REPO_DIR/.claude/skills/$skill"
  dest="$TARGET_DIR/$skill"

  if [ ! -d "$src" ]; then
    echo "跳过 $skill:本仓库里找不到 $src" >&2
    continue
  fi

  if [ -L "$dest" ]; then
    echo "已存在软链接,跳过: $dest"
    continue
  fi

  if [ -e "$dest" ]; then
    echo "警告: $dest 已存在且不是软链接,跳过以避免覆盖。如需替换请先手动删除。" >&2
    continue
  fi

  ln -s "$src" "$dest"
  echo "已链接: $dest -> $src"
done

echo "完成。六个 PM skill 现在可以在任何项目目录下通过 /pm-collect /pm-clarify /pm-value /pm-prd /pm-proto /pm 调用。"
