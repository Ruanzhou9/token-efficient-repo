# token-efficient-repo

> 优化开源项目结构，让任何 agent 使用你的项目时 token 消耗最低。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 这是什么

一个 **Agent Skill**（标准 SKILL.md 格式，Hermes / Codex / Claude Code / OpenCode / Cursor 通用），指导 agent 三步优化任意开源项目：

1. **审计** — 扫描文件结构，输出 token 浪费报告
2. **优化** — 加 AGENTS.md、精简 README、分层 SKILL.md、清理无效文件
3. **验证** — 估算 token 节省，过自检清单

## 效果

| 指标 | 优化前 | 优化后 | 节省 |
|------|--------|--------|------|
| 首读文件数 | 15 个 | 5 个 | ~66% |
| 必读 KB | 50 KB | 15 KB | ~70% |
| 估算 token | ~15K | ~5K | ~66% |

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

## 输出

一份 Token 优化报告，包含变更清单和 token 节省估算。

## License

MIT