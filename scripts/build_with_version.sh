#!/bin/bash
# ============================================================
# build_with_version.sh
# 执行 flutter build web，并自动注入 git commit 版本信息
# ============================================================
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/web"

echo "=== 1. 获取 master 分支最新 commit hash ==="
cd "$PROJECT_DIR"
COMMIT_HASH=$(git rev-parse --short=8 HEAD)
COMMIT_FULL=$(git rev-parse HEAD)
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "  Commit: $COMMIT_HASH"
echo "  Time:   $BUILD_TIME"

echo ""
echo "=== 2. Flutter Web 构建 ==="
flutter build web --release

echo ""
echo "=== 3. 注入版本信息到 build/web/index.html ==="
META_TAG="  <meta name=\"cw-version\" content=\"$COMMIT_HASH\" data-build-time=\"$BUILD_TIME\">"
# 在 <title> 标签前插入版本 meta 标签
sed -i "/<title>/i $META_TAG" "$BUILD_DIR/index.html"

# 替换 description 为更准确的描述
sed -i "s|<meta name=\"description\" content=\".*\">|<meta name=\"description\" content=\"CW Player - 莫尔斯电码练习器 ($COMMIT_HASH)\">|" "$BUILD_DIR/index.html"

echo ""
echo "=== 4. 生成 version.json ==="
cat > "$BUILD_DIR/version.json" << EOF
{
  "commit": "$COMMIT_HASH",
  "commitFull": "$COMMIT_FULL",
  "buildTime": "$BUILD_TIME",
  "project": "flutter_cw"
}
EOF

echo ""
echo "=== 构建完成 ==="
echo "  版本: $COMMIT_HASH"
echo "  输出: $BUILD_DIR"
echo "  version.json 和 meta 标签已注入"
