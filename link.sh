#!/usr/bin/env bash
# ==============================================================================
#  link.sh —— 将本 nvim 配置仓库软链接到 ~/.config/nvim
#  本仓库独立于 dotfiles 管理，链接也由本脚本自行维护，重复执行安全（幂等）。
# ==============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 已经是正确的软链接，直接结束
if [[ -L "$TARGET" && "$(readlink -f "$TARGET")" == "$REPO_DIR" ]]; then
    echo -e "${GREEN}✓ 已链接: $TARGET -> $REPO_DIR${NC}"
    exit 0
fi

# 清理/备份已存在的目标，避免误删
if [[ -L "$TARGET" ]]; then
    if [[ ! -e "$TARGET" ]]; then
        # 失效的软链接，直接删除
        echo -e "${YELLOW}⚠ 失效软链接，删除: $TARGET${NC}"
        rm -f "$TARGET"
    else
        backup="$TARGET.bak.$(date +%Y%m%d%H%M%S)"
        echo -e "${YELLOW}⚠ 目标已存在，备份到: $backup${NC}"
        mv "$TARGET" "$backup"
    fi
elif [[ -e "$TARGET" ]]; then
    backup="$TARGET.bak.$(date +%Y%m%d%H%M%S)"
    echo -e "${YELLOW}⚠ 目标已存在，备份到: $backup${NC}"
    mv "$TARGET" "$backup"
fi

mkdir -p "$(dirname "$TARGET")"
ln -s "$REPO_DIR" "$TARGET"
echo -e "${GREEN}✓ 已链接: $TARGET -> $REPO_DIR${NC}"
