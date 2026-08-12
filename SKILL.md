---
name: token-efficient-repo
description: "优化开源项目结构，让其他 agent 和开发者使用项目时 token 消耗最低。当用户说「优化一下我的项目，让它对 agent 省 token」「帮我让这个 repo 更省 token」「给项目加 AGENTS.md」「做 token-efficient 优化」时使用。也适用于用户说「别人用我的项目 token 太高」「怎么让 agent 读我的项目更快」。"
---

# Token-Efficient Repo — 让项目对 agent 省 token

> 优化开源项目的结构，使得任何 agent（Hermes / Codex / Claude Code / OpenCode / Cursor）在阅读和使用该项目时，token 消耗最小化。

## 核心原则

省 token 不是「写更少的代码」，是**让 agent 知道哪儿该看、哪儿可以跳过**。

| 原则 | 说明 |
|------|------|
| **导航优先** | 加 AGENTS.md，agent 一眼定位核心文件 |
| **渐进披露** | 主文档只告诉够启动的信息，深层细节移进 references |
| **跳过有理** | 明确告诉 agent 哪些文件不需要读 |
| **入口单一** | 每个功能只有一个明确的 CLI/API 入口 |
| **自描述边界** | 模块边界清晰，依赖单向，agent 只读相关文件 |

## 三步工作流

### 第一步：审计（Audit）

扫描项目，输出 token 浪费报告。逐项检查：

**1.1 文件级 token 浪费**

| 检查项 | 问题 | 严重程度 |
|--------|------|----------|
| 大文件（>10KB）无内部导航 | agent 必须从头读到尾 | 🔴 高 |
| README 混着装说明 + 使用方法 + API 文档 | agent 读完 README 才能判断是否要装 | 🔴 高 |
| SKILL.md > 500 行且无分层 | agent 加载整个 skill 才找到入口 | 🔴 高 |
| 无 AGENTS.md | agent 没有入口导航，只能遍历所有文件 | 🔴 高 |
| 宣传页/HTML 在项目根目录 | agent 可能误读 `promo.html` / `index.html` | 🟡 中 |
| 配置文件（pyproject.toml / package.json / Makefile）无说明 | agent 不确定哪些是开发依赖 | 🟡 中 |
| 测试文件在根目录 | agent 把测试当核心代码读 | 🟢 低 |

**1.2 结构级 token 浪费**

| 检查项 | 问题 |
|--------|------|
| 模块依赖方向混乱 | agent 为理解一个模块被迫读 3-5 个文件 |
| 文件过多（>50）且无目录分组 | agent 无法按路径判断文件是否相关 |
| 类和函数签名无类型注释 | agent 读实现体以理解接口 |
| 文档和代码分离太远 | agent 读完文档再去代码里找对应 |

**1.3 输出审计报告格式**

```markdown
## Token 审计报告：{项目名}

### 高优先级（必须修）
- [ ] 无 AGENTS.md → 加导航文件
- [ ] README 混装 → 分拆为 README + docs/
- [ ] 文件「{path}」{size}KB 无内部导航 → 加目录

### 中优先级（建议修）
- [ ] {path} 可能被误读 → 移入 docs/ 目录

### 当前 token 估算
- 首读成本：约 {N} token（遍历所有文件）
- 优化后目标：约 {N/3} token（r/o AGENTS.md → 核心文件）
```

### 第二步：优化（Optimize）

按优先级执行以下操作：

**2.1 加 AGENTS.md（最高优先级）**

在项目根目录创建 `AGENTS.md`，格式：

```markdown
# AGENTS.md — {项目名} 项目导航

## 一句话
{项目 1 句话说明}

## 核心入口（agent 首读，按顺序）
| 文件 | 作用 | 是否必读 |
|------|------|----------|
| `{入口文件}` | {作用} | ✅ 必读 |

## 核心逻辑
| 文件 | 作用 | 是否必读 |
|------|------|----------|
| `{核心模块}` | {作用} | ⚠️ 需要时读 |

## 可直接跳过的文件
| 文件 | 理由 |
|------|------|
| `{文件}` | {理由} |

## 依赖清单
{一行一个依赖}

## 快速验证
```bash
{一行命令验证项目是否可用}
```
```

**2.2 精简 README（高优先级）**

在 README 顶部加「10 秒速览」区（≤10 行，让 agent 立刻判断是否与己相关），其余内容分拆到 `docs/` 目录：

```markdown
# {项目名}

> 一句话：{项目做什么}

## 10 秒速览
- **这是什么**：{1 行}
- **什么时候用**：{1 行}
- **什么时候不用**：{1 行}
- **快速开始**：{1 行命令}
- **依赖**：{1 行}

---

{以下为详细内容，agent 需要时再读}
```

**2.3 精简 SKILL.md（如果项目含 SKILL.md）**

- 确保 SKILL.md 的 `description` 字段 ≤60 字符（触发用）
- 将 SKILL.md 主体限制在 ≤300 行，深层逻辑移进 `references/`
- 在 SKILL.md 顶部加「何时读哪个文件」表格

**2.4 优化项目结构（中优先级）**

- 将 `promo.html`、`demo/`、`examples/` 等非核心文件移入 `docs/` 或项目子目录
- 确保 `pyproject.toml` / `package.json` 等元数据文件中的 `description` 字段准确（agent 常读它）
- 为 >10KB 的源文件加内部目录注释（`# ════ 函数名 ════`）

### 第三步：验证（Verify）

**3.1 自检清单**

- [ ] AGENTS.md 已创建，agent 能 3 秒定位入口
- [ ] 项目根目录无 agent 可能误读的无关文件
- [ ] README 顶部有「10 秒速览」
- [ ] 最大文件 ≤10KB 或有内部导航
- [ ] 所有 SKILL.md/CLAUDE.md 的 description ≤60 字符
- [ ] 所有元数据文件（package.json/pyproject.toml）的 description 字段准确
- [ ] 依赖方向单向：核心模块不反向依赖 CLI/测试

**3.2 token 节省估算**

```markdown
### Token 节省估算

| 指标 | 优化前 | 优化后 | 节省 |
|------|--------|--------|------|
| 首读文件数 | {N} | {N/3} | ~{N/3} 个 |
| 必读 KB | {X} KB | {X/3} KB | ~{X/3} KB |
| 估算 token | ~{Y} | ~{Y/3} | ~{Y/3} token |
```

## 输出格式

```markdown
## Token 优化报告

### 项目
{项目名} — {项目路径}

### 变更
- [x] 加 AGENTS.md（{路径}）
- [x] 精简 README（{路径}）
- [x] 移动文件：{旧路径} → {新路径}
- [ ] {待处理项}

### Token 节省
{估算表}
```

## 示例

**输入：** 「优化我的 douyin-to-obsidian 项目，让它对 agent 省 token」

**输出：**
1. 审计 → 发现：无 AGENTS.md、promo.html 在根目录、README 混装
2. 加 AGENTS.md → 指引 agent 从 `scripts/douyin_extract.py` 入口、跳过 `promo.html`
3. 精简 README → 顶部加「10 秒速览」
4. 移 promo.html → `docs/promo.html`
5. 验证 → 首读文件从 15 个→ 5 个，token 节省约 60%

## 边界与盲点

- 本 skill 优化的是**项目结构**，不优化代码本身的算法效率
- 对于已经极简的项目（如单文件 CLI），优化空间有限
- token 节省是估算值，实际节省取决于 agent 实现和上下文窗口配置
- 本 skill 不修改源代码逻辑，只调整文件结构、文档和导航
- 对于闭源项目，只优化公开可见的文档层

## 关联

- 本 skill 的输出是一个 AGENTS.md + 优化后的项目结构
- 与 `skill-creator` 配合：先优化项目，再用 skill-creator 打包为 agent skill