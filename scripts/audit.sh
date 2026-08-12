#!/usr/bin/env bash
# audits project file structure for token-efficient optimization
# usage: bash audit.sh /path/to/project

set -e

TARGET="${1:-.}"
cd "$TARGET"

echo "📊 文件统计"
echo "=========="

TOTAL=$(find . -type f -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/venv/*" -not -path "*/__pycache__/*" -not -path "*/.venv/*" | wc -l)
echo "  总文件数: $TOTAL"

echo ""
echo "  大文件 (>10KB):"
BIG=$(find . -type f -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/venv/*" \
  -not -path "*/__pycache__/*" -not -path "*/__pycache__/*" -not -path "*/.venv/*" \
  -size +10k -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $NF}' | sort -rh | head -15)
if [ -z "$BIG" ]; then
  echo "    无"
else
  echo "$BIG" | while read line; do
    size=$(echo "$line" | awk '{print $1}')
    file=$(echo "$line" | awk '{print $2}')
    if [ "$(echo "$file" | grep -cE '\.(lock|png|jpg|svg|ico|woff2|mp3|mp4)')" -gt 0 ]; then
      echo "    - $file ($size) 🔇 可跳过"
    else
      echo "    - $file ($size) ⚠️ 建议加内部导航"
    fi
  done
fi

echo ""
echo "📁 结构检查"
echo "=========="

check_file() {
  if [ -f "$1" ]; then echo "  $1 ✅ 存在"; else echo "  $1 ❌ 缺失（建议加）"; fi
}

check_file "AGENTS.md"
check_file "README.md"
check_file "LICENSE"
check_file ".gitignore"

echo ""
echo "📄 README 检查"
echo "=============="
if [ -f "README.md" ]; then
  LINES=$(wc -l < README.md)
  echo "  行数: $LINES"
  HEAD=$(head -1 README.md)
  echo "  标题: $HEAD"
  if grep -q "10 秒速览" README.md 2>/dev/null; then
    echo "  10秒速览: ✅ 有"
  else
    echo "  10秒速览: ❌ 缺失（建议加）"
  fi
else
  echo "  README.md 不存在"
fi

echo ""
echo "📦 SKILL.md 检查（如果有）"
echo "=========================="
if [ -f "SKILL.md" ]; then
  LINES=$(wc -l < SKILL.md)
  DESC=$(grep -E "^description:" SKILL.md | head -1 | wc -c)
  echo "  行数: $LINES"
  echo "  description 长度: $DESC 字符"
  if [ "$DESC" -gt 60 ] 2>/dev/null; then
    echo "  ⚠️ description ≥60 字符（建议压缩）"
  fi
  if [ "$LINES" -gt 300 ] 2>/dev/null; then
    echo "  ⚠️ SKILL.md >300 行（建议分拆到 references/）"
  fi
  if grep -q "何时读哪个文件" SKILL.md 2>/dev/null; then
    echo "  导航表: ✅ 有"
  else
    echo "  导航表: ❌ 缺失（建议加）"
  fi
else
  echo "  无 SKILL.md"
fi

echo ""
echo "🚀 快速验证命令"
echo "==============="
if [ -f "package.json" ]; then
  echo "  npm test"
elif [ -f "Makefile" ]; then
  echo "  make test"
elif [ -f "pyproject.toml" ]; then
  echo "  pytest"
elif [ -f "Cargo.toml" ]; then
  echo "  cargo test"
else
  echo "  未检测到标准构建文件，手动判断"
fi