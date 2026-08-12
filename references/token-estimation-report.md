# Hermes 全量 Skill 安全扫描与 Token 预估对比报告

> 扫描日期：2026-08-11
> 扫描工具：NVIDIA SkillSpector v2.8.2
> 扫描范围：Hermes ~/.hermes/skills/（128 个技能）
> 背景：评估全量注入 vs 按需加载的 token 成本差异

---

## 总览

| 指标 | 数值 |
|------|------|
| 总技能数 | 128 |
| 总 SKILL.md 大小 | 1,229 KB |
| 全部注入单次对话 | ~279.6k tokens |

## 三种场景对比（核心结论）

| 场景 | 每次对话 Token 消耗 | 节省 |
|------|:-------------------:|:----:|
| **A** 全库注入（128 个全部进 system prompt） | **~279.6k** | — |
| **B** 仅注入有风险/声明的 skill（10 个） | **~40.1k** | 节省 239.5k (86%) |
| **C** 按需加载（仅匹配当前任务的 5–20 个） | **~5–20k** | 节省 93–98% |

## 风险分布

| 级别 | 数量 | 大小 | 约 Token | 占比 |
|------|:----:|:----:|:--------:|:----:|
| 🟢 LOW | 118 | 1,052 KB | 239.5k | 86% |
| 🟡 MEDIUM | 7 | 120 KB | 27.3k | 10% |
| 🔴 HIGH/CRITICAL | 3 | 56 KB | 12.8k | 5% |

> **注**：3 个 HIGH/CRITICAL（huashu-nuwa 91分、skill-creator 76分、video-shotcraft 63分）经逐条核实均为误报（无 permissions 字段、CDN 库引用、npx 未 pin 版本），无真实恶意。

## Token 消耗 TOP 10

| 技能 | 大小 | Token | 风险 |
|------|:----:|:-----:|:----:|
| design-taste-frontend | 85.2 KB | 19.4k | 🟢 |
| wang-yangming-perspective | 44.3 KB | 10.1k | 🟢 |
| huashu-nuwa | 40.8 KB | 9.3k | 🔴 误报 |
| imagegen-frontend-mobile | 39.4 KB | 9.0k | 🟢 |
| imagegen-frontend-web | 36.0 KB | 8.2k | 🟡 |
| image-to-code | 35.6 KB | 8.1k | 🟢 |
| zeng-guofan-perspective | 30.7 KB | 7.0k | 🟢 |
| naval-perspective | 30.3 KB | 6.9k | 🟡 |
| mao-zedong-perspective | 29.8 KB | 6.8k | 🟢 |
| lieflat-charts | 28.8 KB | 6.6k | 🟡 |

## 财务估算

以 DeepSeek-V4 约 $0.5/1M tokens 计：

| 场景 | 每次对话 | 日 50 轮 | 月（30天） |
|------|:--------:|:--------:|:----------:|
| A 全量注入 | $0.14 | $7.00 | $210 |
| B 仅风险 > 0 | $0.02 | $1.00 | $30 |
| C 按需加载 | $0.003–0.01 | $0.15–0.50 | $4.50–$15 |

## 对项目优化的启示

1. **SKILL.md 大小直接影响 token 成本** — 128 个 skill 共 1.2 MB，若全部注入约 280k tokens
2. **按需加载是最优策略** — 相比全量注入节省 93–98%
3. **最大单文件可优化** — `design-taste-frontend`（85 KB / 19.4k tokens）是最大单文件
4. **安全扫描可行** — SkillSpector 可自动检测无 permissions 字段、CDN 引用、未 pin 版本等常见问题
5. **误报率高** — 3 个 HIGH 全部为误报，需人工复核而非全信自动化评分

## 扫描命令

```bash
# 扫描单个 skill
env -u PYTHONPATH ~/.local/bin/skillspector scan path/to/skill/ --no-llm

# 扫描整个 skills 目录（递归）
env -u PYTHONPATH ~/.local/bin/skillspector scan ~/.hermes/skills/ --recursive --no-llm
```

> 注意：Hermes 环境 PYTHONPATH 被注入，需 `env -u PYTHONPATH` 否则 pydantic_core 加载失败。