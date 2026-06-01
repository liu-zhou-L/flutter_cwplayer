#!/bin/bash
# ============================================================
# deploy_website.sh
# 将 build/web 推送到远程库的 website 分支
# 使用 git worktree 避免切换分支
# ============================================================
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/web"
BRANCH="website"
WORKTREE_DIR="/tmp/flutter_cw_website_deploy"

echo "=== 部署 build/web → $BRANCH 分支 ==="

cd "$PROJECT_DIR"

# 检查 build/web 是否存在
if [ ! -f "$BUILD_DIR/index.html" ]; then
  echo "错误: $BUILD_DIR/index.html 不存在，请先运行 scripts/build_with_version.sh"
  exit 1
fi

COMMIT_HASH=$(git rev-parse --short=8 HEAD)
DEPLOY_MSG="deploy: $COMMIT_HASH ($(date -u +"%Y-%m-%d %H:%M UTC"))"

echo "  目标分支: $BRANCH"
echo "  提交信息: $DEPLOY_MSG"
echo ""

# 清理旧 worktree
if [ -d "$WORKTREE_DIR" ]; then
  git worktree remove "$WORKTREE_DIR" 2>/dev/null || rm -rf "$WORKTREE_DIR"
fi

# 检查 website 分支是否存在
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "=== 检出已有 $BRANCH 分支 ==="
  git worktree add "$WORKTREE_DIR" "$BRANCH"
elif git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  echo "=== 从远程检出 $BRANCH 分支 ==="
  git worktree add "$WORKTREE_DIR" "origin/$BRANCH"
  cd "$WORKTREE_DIR"
  git checkout -b "$BRANCH"
else
  echo "=== 创建孤儿 $BRANCH 分支 ==="
  git worktree add "$WORKTREE_DIR"
  cd "$WORKTREE_DIR"
  git checkout --orphan "$BRANCH"
  git rm -rf --quiet . 2>/dev/null || true
fi

cd "$WORKTREE_DIR"

echo "=== 复制构建产物 ==="
# 清空旧文件（保留 .git）
find . -maxdepth 1 -not -name '.git' -not -name '.' -exec rm -rf {} + 2>/dev/null || true
# 复制新构建
cp -r "$BUILD_DIR"/* .
# 复制隐藏文件
cp "$BUILD_DIR"/.last_build_id . 2>/dev/null || true

echo "=== 提交 & 推送 ==="
git add -A
git commit -m "$DEPLOY_MSG" --allow-empty
git push -u origin "$BRANCH"

# 返回并清理
cd "$PROJECT_DIR"
git worktree remove "$WORKTREE_DIR"

echo ""
echo "=== 部署完成 ==="
echo "  分支: $BRANCH"
echo "  版本: $COMMIT_HASH"
echo "  访问: https://<your-repo>.github.io/flutter_cw/ 或对应 Pages URL"
