# token-efficient-repo

> 优化开源项目结构，让任何 agent 使用你的项目时 token 消耗最低，**并在优化前后都做安全扫描**。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 10 秒速览
- **这是什么**：Agent Skill，**五步闭环**优化任意项目让 agent 省 token：安全扫描 → 审计 → 优化 → 验证 → 安全扫描
- **什么时候用**：有人说「用我的项目 token 太高」「怎么让 agent 读我的项目更快」「检查这个 skill 安不安全」
- **什么时候不用**：项目已极简（单文件 CLI）、闭源项目不可改结构
- **快速开始**：`bash scripts/audit.sh .` 扫描当前项目
- **依赖**：仅 bash（深度扫描可选装 NVIDIA SkillSpector）

---

## 是什么

一个 **Agent Skill**（标准 SKILL.md 格式，Hermes / Codex / Claude Code / OpenCode / Cursor 通用），指导 agent **五步闭环**优化任意开源项目：

1. **安全扫描** — 优化前确认项目安全可信（快速脚本 + NVIDIA SkillSpector 双路径）
2. **审计** — 扫描文件结构，输出 token 浪费报告（支持 `scripts/audit.sh` 快速扫描）
3. **优化** — 加 AGENTS.md、精简 README、分层 SKILL.md、清理无效文件
4. **验证** — 估算 token 节省，过自检清单
5. **安全扫描** — 优化后重新过安全关，重点核查新增/变更文件（出门放行）

> **闭环设计**：第 1 步「进门检查」确保优化前项目可信；第 5 步「出门放行」确保优化引入的新脚本/文件仍安全，才能交付。

## 效果

| 指标 | 优化前 | 优化后 | 节省 |
|------|--------|--------|------|
| 首读文件数 | 15 个 | 5 个 | ~66% |
| 必读 KB | 50 KB | 15 KB | ~70% |
| 估算 token | ~15K | ~5K | ~66% |

## 安全扫描（双路径：快速脚本 + NVIDIA SkillSpector）

安装第三方 skill 前，用内置安全检查确认是否可信。支持快速脚本与 NVIDIA SkillSpector 深度扫描两级：

```bash
# 快速粗扫（轻量脚本，秒级，无需网络）
bash scripts/security-scan.sh /path/to/skill

# 递归扫描整个库
bash scripts/security-scan.sh --recursive ~/.hermes/skills/

# 深度扫描（NVIDIA SkillSpector 官方引擎，14.4k⭐；Hermes 环境需 env -u PYTHONPATH）
env -u PYTHONPATH skillspector scan /path/to/skill/ --no-llm
```

**结果判定**（SkillSpector 0-100 分）：`0-35` 可信可装；`35-60` 多为规范建议（无 permissions 字段、npx 未 pin 版）核实后可接受；`>60` 逐条核查 HIGH 是否涉真危险代码。

详见 [`references/security-scan-guide.md`](references/security-scan-guide.md)。

## 真实案例：Hermes 128 Skill 全库扫描

作为参考，对 Hermes 全库 128 个 skill 做了完整安全扫描和 Token 估算：

- **全量注入**：~279.6k tokens / 次对话
- **按需加载**：~5–20k tokens / 次对话（节省 93–98%）
- **财务对比**：日 50 轮对话，全量注入约 $7/天，按需加载约 $0.15–0.50/天

详见 [`references/token-estimation-report.md`](references/token-estimation-report.md)。

## 安装

```bash
# 克隆到任意 Agent 技能目录
git clone https://github.com/Ruanzhou9/token-efficient-repo.git \
  ~/.hermes/skills/token-efficient-repo/
# 或共享到所有 Agent
cp -r ~/.hermes/skills/token-efficient-repo ~/.agents/skills/
```

## 使用

```text
用 token-efficient-repo 优化我的项目 /path/to/project
```

或先快速扫描：
```bash
bash scripts/audit.sh /path/to/project
```

## 仓库结构

```
AGENTS.md           — 项目导航（agent 入口）
SKILL.md            — 完整方法论（五步闭环）
README.md           — 本文档
references/
  agent-md-template.md      — AGENTS.md 模板
  audit-example.md          — 审计报告示例
  security-scan-guide.md    — 安全检查指南（SkillSpector 用法 + 结果判定）
  token-estimation-report.md — 真实 token 成本与安全扫描报告
scripts/
  audit.sh              — 文件结构快速扫描脚本
  security-scan.sh      — 快速安全检查脚本（HIGH/MED/LOW 分级）
```

## License

MIT