# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project

**TikTok ROI 智能运营平台** — AI-driven operations tool for TikTok Japan cross-border e-commerce, centered on ROI (break-even ≥2.5) as the core decision metric.

Currently **docs-only**: no application code yet. Planning, contracts, and research live in `docs/`.

## Repository Layout

- `docs/README.md` — project overview, team, roadmap, tech stack
- `docs/TODO.md` — phased task list with owners/deadlines
- `docs/MVP产品设计.md` — Phase 1 spec: "ROI 定价决策工作台" web app with 7 features (F1–F7)
- `docs/MVP成本估算.md` — cost estimate (dev + data platforms + cloud + API)
- `docs/数据平台调研报告.md` — data source research (FastMoss, TikTok APIs, 1688 via Onebound/Pangolin)
- `docs/会议纪要-*.md` — meeting notes on workflow and AI改造 plans
- `docs/尧的视频会议.txt` — raw meeting transcript
- `docs/软件开发服务合同.md` — dev services contract
- `docs/scripts/sync_feishu.sh` — Feishu wiki sync via `lark-cli` (requires prior `lark-cli auth login`)

## Phase 1 Scope (32 working days, ~21.5 days dev)

Single web app. Seven features F1–F7:

| # | Feature | Days |
|---|---|---|
| F1 | 运费计算器 | 2 |
| F2 | ROI 计算器 & 盈亏模拟 | 3 |
| F3 | 竞品价格带分析 + 类目爆款榜 (FastMoss, growth_rate 驱动) | 3 |
| F4 | LLM 智能定价建议 (Claude Sonnet 4.6) | 3 |
| F5 | 商品工作台 + 决策存档 + 运营回填实测 (Phase 1 灵魂) | 3.5 |
| F6 | 1688 图搜反查货源 (Onebound) | 1 |
| F7 | 达人分佣预估 (FastMoss creator suite) | 3 + 1 Phase 0 quota 预测试 |

**Removed from Phase 1**: 原 F6「店铺自测 Dashboard」延后至多店铺阶段；单店当前直接看 TikTok 商家后台。

**Out of Phase 1 scope** (do NOT expand without explicit approval): 达人评估系统完整版, 投流优化, 内容/视频/标题生成, 浏览器插件, 订单分拣, 活动提醒, 官方活动推荐, 多店铺/多租户, TikTok Ads API, 多语言 UI, SSO, 审批流. 完整 25 项不含清单见合同 §6.1.2.

## Planned Tech Stack

- Frontend: Web app (no browser extension in MVP)
- Data: FastMoss OpenAPI, TikTok Shop Partner API v2, TikTok Ads API, EchoTik, Kalodata, Onebound (primary) + Pangolin (failover) for 1688
- AI: Claude Sonnet 4.6 for pricing suggestions, title/description generation

## Team

- 创世跨境 (owner) · 李远哲 (BD) · 孙栩尧 (ops lead) · 张翼翔 (dev)

## Working Notes

- Docs are primarily in Chinese; preserve Chinese terminology when editing.
- When implementation begins, create source directories alongside `docs/` (e.g. `apps/`, `packages/`) and update this file with build/test/lint commands.
- Contract pricing and MVP timelines in `docs/软件开发服务合同.md` are authoritative for scope negotiations.
