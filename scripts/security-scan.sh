#!/usr/bin/env bash
# security-scan.sh — 技能安全检查器
# 对 Agent Skill 目录做静态安全扫描，类似 NVIDIA SkillSpector 的基础检查
# 用法: bash security-scan.sh /path/to/skill
#       bash security-scan.sh --recursive /path/to/skills-dir

set -e

TARGET="${2:-${1:-.}}"
RECURSIVE=false
[[ "$1" == "--recursive" ]] && RECURSIVE=true && TARGET="${2:-.}"

# 颜色
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL_ISSUES=0
TOTAL_HIGH=0
TOTAL_MED=0
TOTAL_LOW=0

scan_skill() {
  local dir="$1"
  local name=$(basename "$dir")
  local issues=0
  local high=0 med=0 low=0

  echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
  echo -e "${BLUE}  扫描: $name${NC}"
  echo -e "${BLUE}═══════════════════════════════════════${NC}"

  # 1. 检查 SKILL.md 是否存在
  local sk_file="$dir/SKILL.md"
  if [ ! -f "$sk_file" ]; then
    echo -e "  ${YELLOW}[MED] 无 SKILL.md — 可能不是标准 Agent Skill${NC}"
    ((med++))
  else
    # 1a. 检查 description 是否 ≤60 字符
    local desc=$(grep -E "^description:" "$sk_file" 2>/dev/null | sed 's/^description: *//')
    local desc_len=${#desc}
    if [ "$desc_len" -gt 60 ] 2>/dev/null; then
      echo -e "  ${YELLOW}[MED] description 过长 (${desc_len}字符, 建议≤60)${NC}"
      ((med++))
    fi

    # 1b. 检查是否有 permissions 声明
    if ! grep -qi "permissions" "$sk_file" 2>/dev/null; then
      echo -e "  ${YELLOW}[MED] 无 permissions 声明 — 建议声明权限需求${NC}"
      ((med++))
    fi

    # 1c. 检查危险模式 (exec, eval, 未固定的 npx)
    local dangerous=0
    if grep -nE "^\s*(eval|exec|execSync|execFile)\(" "$sk_file" 2>/dev/null | grep -v "grep\|#\|//" | head -5 > /dev/null; then
      echo -e "  ${RED}[HIGH] 发现 eval/exec 调用 — 可能执行任意代码${NC}"
      ((high++)); dangerous=1
    fi
    if grep -nE "npx (skills|remotion|create-)" "$sk_file" 2>/dev/null | grep -vE "@[0-9]+\.[0-9]+\.[0-9]+" | head -5 > /dev/null; then
      echo -e "  ${YELLOW}[MED] npx 命令未固定版本 — 建议 pin 版本${NC}"
      ((med++))
    fi
    if grep -nE "curl |wget |fetch\(|https?://(?!.*github\.com|.*npmjs\.com|.*pypi\.org)" "$sk_file" 2>/dev/null | head -5 > /dev/null; then
      echo -e "  ${YELLOW}[LOW] 发现外部网络请求 — 需确认是否必要${NC}"
      ((low++))
    fi
    if grep -nE "rm\s+-rf|rmdir|chmod\s+777|chown" "$sk_file" 2>/dev/null | head -3 > /dev/null; then
      echo -e "  ${RED}[HIGH] 发现危险文件操作 — 确认是否必要${NC}"
      ((high++))
    fi
    if grep -nE "export\s+[A-Z_]+_API_KEY|export\s+[A-Z_]+_TOKEN|export\s+[A-Z_]+_SECRET" "$sk_file" 2>/dev/null | head -3 > /dev/null; then
      echo -e "  ${RED}[HIGH] 发现 API Key/Token 暴露 — 建议使用环境变量引用${NC}"
      ((high++))
    fi
  fi

  # 2. 检查目录中是否有可执行脚本
  local scripts=$(find "$dir" -maxdepth 2 \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.mjs" \) 2>/dev/null | wc -l)
  if [ "$scripts" -gt 0 ] 2>/dev/null; then
    echo -e "  ${YELLOW}[LOW] 发现 ${scripts} 个可执行脚本 — 建议逐文件审查${NC}"
    ((low+=scripts))
  fi

  # 3. 检查大文件
  local big=$(find "$dir" -type f -size +100k -not -path "*/.git/*" -not -name "*.png" -not -name "*.jpg" -not -name "*.mp3" -not -name "*.mp4" 2>/dev/null | wc -l)
  if [ "$big" -gt 0 ] 2>/dev/null; then
    echo -e "  ${YELLOW}[LOW] 发现 ${big} 个大文件 (>100KB) — 建议验证内容${NC}"
    ((low+=big))
  fi

  # 4. 检查是否有 .git 子模块/子仓库
  local submodules=$(find "$dir" -maxdepth 3 -name ".git" -type d -not -path "$dir/.git" 2>/dev/null | wc -l)
  if [ "$submodules" -gt 0 ] 2>/dev/null; then
    echo -e "  ${YELLOW}[MED] 发现 ${submodules} 个内嵌 git 仓库 — 建议用 submodule 或复制${NC}"
    ((med+=submodules))
  fi

  # 5. 检查是否有敏感文件
  if find "$dir" -maxdepth 3 \( -name "*.env" -o -name ".env*" -o -name "*.pem" -o -name "*.key" -o -name "id_rsa*" -o -name "credentials.json" -o -name "token*" \) 2>/dev/null | grep -q .; then
    echo -e "  ${RED}[HIGH] 发现敏感文件 (.env, .pem, .key, token) — 可能泄露凭据${NC}"
    ((high++))
  fi

  # 6. 检查是否有 README 和协议
  if [ ! -f "$dir/README.md" ]; then
    echo -e "  ${YELLOW}[LOW] 无 README.md — 建议补充说明${NC}"
    ((low++))
  fi
  if [ ! -f "$dir/LICENSE" ] && [ ! -f "$dir/LICENCE" ]; then
    echo -e "  ${YELLOW}[LOW] 无 LICENSE 文件 — 建议明确开源协议${NC}"
    ((low++))
  fi

  local total=$((high + med + low))
  echo -e "\n  结果: ${RED}${high} HIGH${NC} / ${YELLOW}${med} MED${NC} / ${GREEN}${low} LOW${NC} / ${total} 总计"
  TOTAL_ISSUES=$((TOTAL_ISSUES + total))
  TOTAL_HIGH=$((TOTAL_HIGH + high))
  TOTAL_MED=$((TOTAL_MED + med))
  TOTAL_LOW=$((TOTAL_LOW + low))
}

if [ "$RECURSIVE" = true ]; then
  echo "递归扫描: $TARGET"
  for d in "$TARGET"/*/; do
    [ -d "$d" ] && scan_skill "$d"
  done
  echo ""
  echo "═══════════════════════════════════════"
  echo "  全库汇总: ${RED}${TOTAL_HIGH} HIGH${NC} / ${YELLOW}${TOTAL_MED} MED${NC} / ${GREEN}${TOTAL_LOW} LOW${NC} / ${TOTAL_ISSUES} 总计"
  echo "═══════════════════════════════════════"
else
  scan_skill "$TARGET"
fi