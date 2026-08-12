# 审计报告示例

以下是一个典型项目优化前后的审计报告示例。

## 优化前：douyin-to-obsidian

```
项目根目录/
├── README.md          (15KB)  ← 混装着装说明+使用方法+API
├── SKILL.md           (15KB)  ← 无导航表，511行
├── AGENTS.md           ❌ 缺失
├── promo.html          🟡 在根目录，agent 可能误读
├── scripts/
│   ├── douyin_extract.py (32KB) ← 大文件无内部导航
│   └── douyin_browser_fallback.py
└── ...
```

**首读成本：~15 个文件，~50KB，~15K token**

## 优化后

```
项目根目录/
├── README.md           (3KB)  ← 顶部加 10秒速览
├── SKILL.md            (8KB)  ← 加导航表，加 description≤60字符
├── AGENTS.md            ✅ 已加
├── docs/
│   ├── promo.html       ← 从根目录移入
│   └── api.md           ← 从 README 拆出
├── scripts/
│   ├── douyin_extract.py (32KB) ← 加内部导航注释
│   └── douyin_browser_fallback.py
└── ...
```

**首读成本：~5 个文件，~15KB，~5K token（节省约 66%）**