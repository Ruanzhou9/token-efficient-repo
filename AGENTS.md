# AGENTS.md — token-efficient-repo 项目导航

## 一句话

优化开源项目结构，让任何 agent 使用你的项目时 token 消耗最低。

## 核心入口（agent 首读，按顺序）

| 文件 | 作用 | 是否必读 |
|------|------|----------|
| `SKILL.md` | 完整的方法论（审计 → 优化 → 验证） | ✅ 必读 |
| `README.md` | 项目概述与安装方式 | ✅ 必读 |

## 参考模板

| 文件 | 作用 | 是否必读 |
|------|------|----------|
| `references/agent-md-template.md` | AGENTS.md 模板，可直接复制使用 | ⚠️ 需要时读 |
| `references/audit-example.md` | 审计报告示例 | ⚠️ 需要时读 |
| `references/token-estimation-report.md` | 真实 Token 扫描与成本对比报告（含 128 skill 实测数据） | ⚠️ 需要时读 |

## 工具脚本

| 文件 | 作用 | 是否必读 |
|------|------|----------|
| `scripts/audit.sh` | 快速扫描项目文件大小和结构，辅助审计 | ⚠️ 需要时读 |

## 可直接跳过的文件

| 文件 | 理由 |
|------|------|
| `LICENSE` | 标准 MIT 协议，不需读 |
| `.gitignore` | 标准忽略规则 |

## 依赖清单

无运行时依赖。audit.sh 需要 bash 环境。

## 快速验证

```bash
bash scripts/audit.sh .           # 扫描本项目的文件结构
grep 'description' SKILL.md       # 确认 description ≤60 字符