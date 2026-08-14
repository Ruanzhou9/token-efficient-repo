---
name: token-efficient-repo
description: 当用户要优化项目结构节省 agent token 消耗时使用。
---

# Token-Efficient Repo — 让项目对 agent 省 token

> 优化开源项目的结构，使得任何 agent（Hermes / Codex / Claude Code / OpenCode / Cursor）在阅读和使用该项目时，token 消耗最小化。

## 何时读哪个文件

| 文件 | 什么时候读 |
|------|-----------|
| 整个 SKILL.md | 首次使用时通读 |
| `references/agent-md-template.md` | 需要加 AGENTS.md 时 |
| `references/audit-example.md` | 需要参考审计报告格式时 | ⚠️ 需要时读 |
| `references/token-estimation-report.md` | 需要参考真实 Token 成本数据与财务对比时 | ⚠️ 需要时读 |
| `references/security-scan-guide.md` | 需要检查第三方 skill 安全性时 | ⚠️ 需要时读 |
| `scripts/audit.sh` | 需要快速扫描项目文件结构时 |

## 核心原则

省 token 不是「写更少的代码」，是**让 agent 知道哪儿该看、哪儿可以跳过**。

| 原则 | 说明 |
|------|------|
| **导航优先** | 加 AGENTS.md，agent 一眼定位核心文件 |
| **渐进披露** | 主文档只告诉够启动的信息，深层细节移进 references |
| **跳过有理** | 明确告诉 agent 哪些文件不需要读 |
| **入口单一** | 每个功能只有一个明确的 CLI/API 入口 |
| **自描述边界** | 模块边界清晰，依赖单向，agent 只读相关文件 |

## 五步工作流

### 第一步：安全扫描（Security Scan）

在开始优化之前，先检查项目是否安全可信。详见 `references/security-scan-guide.md`。

**1.1 安全检查（快速脚本 + 深度 SkillSpector 双路径）**

```bash
# 快速粗扫（本项目的轻量脚本，秒级，无需网络）
bash scripts/security-scan.sh /path/to/project

# 深度扫描（NVIDIA SkillSpector 引擎，先已在机更佳；Hermes 环境必须 env -u PYTHONPATH）
env -u PYTHONPATH skillspector scan /path/to/project/ --no-llm
```

> 两步都做更稳妥：快速脚本查「本库常见危险模式」，SkillSpector 查「NVIDIA 全量规则库 + 供应链」。若 SkillSpector 未安装，完整安装命令见下方第 5.2 步。

**1.2 安全检查清单**

- [ ] 来源可信（作者/组织、star 数、最近更新）
- [ ] 有开源协议（LICENSE 文件）
- [ ] 无危险代码（eval、exec、未固定版本的 npx）
- [ ] 无硬编码 API Key 或 Token
- [ ] 无敏感文件（.env、.pem、.key）
- [ ] 无外链发送数据（可疑的 curl/wget 到非官方地址）
- [ ] 有 permissions 声明（如果支持）
- [ ] 脚本文件数量合理，可审查

**1.3 误报处理**

自动化扫描工具偏向保守标记，常见误报包括：
- 含真实脚本的官方工具被标记为 HIGH
- CDN 库引用被标记为「外部传输」
- 文档中的 SEO 链接被标记为「隐藏指令」

**遇到 HIGH 评分不要直接拒绝，先看具体命中再判断。**

### 第二步：审计（Audit）

扫描项目，输出 token 浪费报告。逐项检查：

**2.1 文件级 token 浪费**

| 检查项 | 问题 | 严重程度 |
|--------|------|----------|
| 大文件（>10KB）无内部导航 | agent 必须从头读到尾 | 🔴 高 |
| README 混装着装说明 + 使用方法 + API 文档 | agent 读完 README 才能判断是否要装 | 🔴 高 |
| SKILL.md > 500 行且无分层 | agent 加载整个 skill 才找到入口 | 🔴 高 |
| 无 AGENTS.md | agent 没有入口导航，只能遍历所有文件 | 🔴 高 |
| 宣传页/HTML 在项目根目录 | agent 可能误读 `promo.html` / `index.html` | 🟡 中 |
| 配置文件（pyproject.toml / package.json / Makefile）无说明 | agent 不确定哪些是开发依赖 | 🟡 中 |
| 测试文件在根目录 | agent 把测试当核心代码读 | 🟢 低 |

**2.2 结构级 token 浪费**

| 检查项 | 问题 |
|--------|------|
| 模块依赖方向混乱 | agent 为理解一个模块被迫读 3-5 个文件 |
| 文件过多（>50）且无目录分组 | agent 无法按路径判断文件是否相关 |
| 类和函数签名无类型注释 | agent 读实现体以理解接口 |
| 文档和代码分离太远 | agent 读完文档再去代码里找对应 |

**2.3 快速审计脚本**

如果项目有 shell 环境，运行 `scripts/audit.sh` 获取文件大小和结构统计：

```bash
bash scripts/audit.sh /path/to/project
```

输出示例：
```
📊 文件统计
  总文件数: 47
  大文件 (>10KB): 3
    - src/main.ts (32KB) ⚠️ 建议加内部导航
    - README.md (15KB) ⚠️ 建议拆分为 README + docs/
    - package-lock.json (120KB) 🔇 可跳过

📁 结构
  .gitignore        ✅ 有
  AGENTS.md         ❌ 缺失（建议加）
  LICENSE           ✅ 有
  README.md         ✅ 有
```

**1.4 输出审计报告格式**

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

### 第三步：优化（Optimize）

按优先级执行以下操作：

**3.1 加 AGENTS.md（最高优先级）**

在项目根目录创建 `AGENTS.md`，格式见 `references/agent-md-template.md`。

**3.2 精简 README（高优先级）**

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

**3.3 精简 SKILL.md（如果项目含 SKILL.md）**

- 确保 SKILL.md 的 `description` 字段 ≤60 字符（触发用）
- 将 SKILL.md 主体限制在 ≤300 行，深层逻辑移进 `references/`
- 在 SKILL.md 顶部加「何时读哪个文件」表格

**3.4 优化项目结构（中优先级）**

- 将 `promo.html`、`demo/`、`examples/` 等非核心文件移入 `docs/` 或项目子目录
- 确保 `pyproject.toml` / `package.json` 等元数据文件中的 `description` 字段准确（agent 常读它）
- 为 >10KB 的源文件加内部目录注释（`# ════ 函数名 ════`）

### 第四步：验证（Verify）

**4.1 自检清单**

- [ ] AGENTS.md 已创建，agent 能 3 秒定位入口
- [ ] 项目根目录无 agent 可能误读的无关文件
- [ ] README 顶部有「10 秒速览」
- [ ] 最大文件 ≤10KB 或有内部导航
- [ ] 所有 SKILL.md/CLAUDE.md 的 description ≤60 字符
- [ ] 所有元数据文件（package.json/pyproject.toml）的 description 字段准确
- [ ] 依赖方向单向：核心模块不反向依赖 CLI/测试

**4.2 token 节省估算**

```markdown
### Token 节省估算

| 指标 | 优化前 | 优化后 | 节省 |
|------|--------|--------|------|
| 首读文件数 | {N} | {N/3} | ~{N/3} 个 |
| 必读 KB | {X} KB | {X/3} KB | ~{X/3} KB |
| 估算 token | ~{Y} | ~{Y/3} | ~{Y/3} token |
|```

### 第五步：安全扫描（Security Scan）⭐ 最终安检

**与第 1 步的区别：第 1 步是「进门检查」（优化前项目是否可信），本步是「出门放行」（优化后是否仍安全）。** 优化可能新增了脚本、重写了 README、移动了文件——这些**新引入的变数必须重新过安全关**，才能算交付。详见 `references/security-scan-guide.md`。

**5.0 重点核查优化过程新增/变更项**
- [ ] 优化中新增的 `.sh/.py` 脚本是否无 eval/exec、无外发数据
- [ ] 新写的 AGENTS.md 是否含隐藏指令 / 覆盖 agent 系统提示
- [ ] 重写的 README 是否仍无硬编码 API Key
- [ ] 移动后的文件路径是否正确、无越权路径（`../`、绝对路径外传）

**5.1 快速安全检查（用本项目的脚本）**

```bash
bash scripts/security-scan.sh /path/to/skill
```

**5.2 深度安全检查（用 NVIDIA SkillSpector）**

> SkillSpector 是 NVIDIA 官方开源的 Agent Skill 安全扫描器（14.4k ⭐）。**本机通常已装好**，先检测，缺失才安装。

```bash
# a. 检测是否已安装（Hermes 环境必须 env -u PYTHONPATH，否则 pydantic 冲突报 ImportError）
if command -v skillspector >/dev/null 2>&1; then
  echo "✅ 已安装: $(env -u PYTHONPATH skillspector --version)"
else
  echo "未安装，执行安装（需先装 uv）..."
  env -u PYTHONPATH uv tool install --python 3.12 \
    "git+https://github.com/NVIDIA/skillspector.git"
fi

# b. 扫描单个 skill
env -u PYTHONPATH skillspector scan /path/to/skill/ --no-llm

# c. 递归扫描整库
env -u PYTHONPATH skillspector scan ~/.hermes/skills/ --recursive --no-llm
```

**5.2.1 结果解读（扫描后必须人工核验，勿盲信总分）**

SkillSpector 输出一个 0-100 的风险分 + HIGH/MEDIUM/LOW 级别。判定规则：

| 总分区间 | 建议动作 |
|---------|---------|
| `< 35` | ✅ 可信，可安装（仍需过一遍清单） |
| `35–60` | ⚠️ 看具体命中——多数是规范建议（无 permissions 字段、npx 未 pin 版本），人工核实后通常可接受 |
| `> 60` | 🔴 逐条人工核查 HIGH/CRITICAL 命中，确认涉真实危险代码（eval/外泄/敏感文件）才拒绝；若全为误报则记录后通过 |

实际命中类型（结合本库扫描实测）：HIGH 评分里大部分是「无 permissions 声明」「含可执行脚本待审查」等规范项，**不是真危险**。只有命中「硬编码 API Key」「外发 curl 到非官方地址」「eval(用户输入)」等才真拒绝。

**5.2.2 判定三连问（每遇 HIGH 自答）**
1. 这一条命中是否指向**真实可控的资产风险**（凭据外泄 / 任意命令执行 / 数据外传）？
2. 命中所在的文件**作者是否可信、依赖是否 pin 版本**？
3. 有无官方说明该行为**确实需要**（如视频渲染需要 ffmpeg 调用）？
三问全「安全」才放行，否则拒绝或要求改进。

**5.3 安全检查清单**

- [ ] 来源可信（作者/组织、star 数、最近更新）
- [ ] 有开源协议（LICENSE 文件）
- [ ] 无危险代码（eval、exec、未固定版本的 npx）
- [ ] 无硬编码 API Key 或 Token
- [ ] 无敏感文件（.env、.pem、.key）
- [ ] 无外链发送数据（可疑的 curl/wget 到非官方地址）
- [ ] 有 permissions 声明（如果支持）
- [ ] 脚本文件数量合理，可审查

**5.4 误报处理**

自动化扫描工具（如 SkillSpector）偏向保守标记，常见误报：
- 含真实脚本的官方工具被标记为 HIGH（如 NFT 官方工具、视频渲染工具）
- CDN 库引用（jsdelivr、unpkg）被标记为「外部传输」
- 文档中的 SEO 链接被标记为「隐藏指令」

**遇到 HIGH 评分不要直接拒绝，先看具体命中再判断。**

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
1. 安全检查 → 通过（MIT 协议，无危险代码，来源可信）
2. 审计 → 发现：无 AGENTS.md、promo.html 在根目录、README 混装
3. 加 AGENTS.md → 指引 agent 从 `scripts/douyin_extract.py` 入口、跳过 `promo.html`
4. 精简 README → 顶部加「10 秒速览」
5. 移 promo.html → `docs/promo.html`
6. 验证 → 首读文件从 15 个→ 5 个，token 节省约 60%

**输入：** 「优化我的 Node.js 项目 /path/to/project」

**输出：**
1. 审计 → 发现：无 AGENTS.md、package.json 的 description 为空白、测试文件在根目录
2. 加 AGENTS.md → 入口 `src/index.js`，跳过 `node_modules/`、`__tests__/`
3. 补 package.json 的 description 字段
4. 移测试文件入 `__tests__/` 目录
5. 验证 → 首读文件从 12 个→ 4 个，token 节省约 65%

**输入：** 「优化我的 Python 项目 /path/to/project」

**输出：**
1. 审计 → 发现：无 AGENTS.md、README 混装着装说明+API 文档、pyproject.toml 无 description
2. 加 AGENTS.md → 入口 `src/core.py`，跳过 `tests/`、`venv/`
3. 精简 README → 顶部加「10 秒速览」，API 文档移入 `docs/api.md`
4. 补 pyproject.toml 的 description 字段
5. 验证 → 首读文件从 18 个→ 6 个，token 节省约 65%

## 边界与盲点

- 本 skill 优化的是**项目结构**，不优化代码本身的算法效率
- 对于已经极简的项目（如单文件 CLI），优化空间有限
- token 节省是估算值，实际节省取决于 agent 实现和上下文窗口配置
- 本 skill 不修改源代码逻辑，只调整文件结构、文档和导航
- 对于闭源项目，只优化公开可见的文档层

## 关联

- 本 skill 的输出是一个 AGENTS.md + 优化后的项目结构
- 与 `skill-creator` 配合：先优化项目，再用 skill-creator 打包为 agent skill