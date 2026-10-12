# 产品经理工作流 Skill 套件

> 仓库地址:[github.com/bxffast-sketch/pm-workflow](https://github.com/bxffast-sketch/pm-workflow)

一套面向 Claude Code 的产品经理全流程 skill,把 PM 标准工作流拆成五个阶段 + 一个可选分支 + 一个路由,每阶段对应一个可独立调用的指令,也支持前一阶段质量门通过后自动询问是否进入下一阶段。

设计目标是打造一套「切实可用」的产品经理 agent,而不是方法论的罗列——每个框架都落地成可执行的评分模板、提问清单或自检表。

## 套件总览

| 指令 | 阶段 | 职责 |
|---|---|---|
| `/pm` | 路由 | 查需求池现状,某需求定位到哪一步,给出下一步指令建议 |
| `/pm-collect` | ① 需求挖掘与收集 | 记录一句话需求 → 标准化需求卡片 → 写入飞书需求池 |
| `/pm-clarify` | ② 需求沟通与澄清 | 生成结构化沟通提纲 → 回填结果 → 产出「真实需求」结论 |
| `/pm-value` | ③ 需求甄别与价值判断 | 5 Whys + 刚需度/频次度/温度 + RICE + KANO + 俞军公式 → P0-P3 定级 |
| `/pm-research` | ③.5 市场竞品调研(可选) | 窄范围功能点对标 / 宽范围竞争格局摸底,双模式 |
| `/pm-prd` | ④ 产品方案设计 | 背景/功能清单/业务流程图/角色/用例/规则/状态机,PRD 骨架 |
| `/pm-proto` | ⑤ 原型设计与交互定义 | 交互规格(IA/5态/尼尔森自检/WCAG)→ 可选委托 HTML 高保真原型 |

阶段串联方式:每个 skill 结束时跑质量门(PASS/BLOCKER),PASS 后主动问「是否进入下一阶段」等待用户确认才继续;BLOCKER 则列出缺项,不询问是否继续。

## 核心设计原则

- **防伪造规则**:任何具体数字(评分、竞品功能细节、基线数据)只能来自用户给出的事实、标注依据的推断、或留空标「待确认」,禁止凭训练数据的模糊印象编造。
- **多轮澄清原则**:信息缺失时先向用户提问,一次只问一个,不批量甩问题,也不跳过提问直接套用默认值或待确认标记。
- **输入面板**:每个 skill 开场检查前置条件是否满足,缺失则引导用户先跑上游 skill。
- **委托而非重写**:原型阶段的 HTML 高保真生成委托给专门的设计 skill,不重新实现这个能力。

## 数据与状态设计

飞书多维表格存索引和结构化字段(团队可见、可筛选、可统计),本地存长文档(PRD、交互规格等),两边用需求 ID 对齐。

```
pm-workspace/
  config.json              # 飞书 app token、table id、字段映射(不提交,见 .gitignore)
  requirements/
    REQ-YYYYMMDD-NNN-简短标题/
      01-collect.md
      02-clarify.md
      03-value.md
      research-competitor.md   # 可选,/pm-research 窄范围模式产出
      research-landscape.md    # 可选,/pm-research 宽范围模式产出
      04-prd.md
      05-interaction.md
      prototype/               # 高保真原型产出
```

## 安装

本仓库自带 `.claude/skills/`,克隆到项目目录下即可在该项目使用。要在任意项目目录下全局可用,运行:

```bash
./scripts/install-pm-skills.sh
```

该脚本用软链接把六个 skill 链接到 `~/.claude/skills/`,之后仓库里的更新会自动同步到全局。

首次调用 `/pm-collect` 时,如果检测到 `pm-workspace/config.json` 不存在,会询问建表位置并自动在飞书创建多维表格,token 写入本地配置(该文件已被 gitignore,不会提交)。参考 `pm-workspace/config.json.example` 了解字段结构。

## 设计文档

完整设计思路见 [`docs/superpowers/specs/2026-10-12-pm-workflow-skills-design.md`](docs/superpowers/specs/2026-10-12-pm-workflow-skills-design.md),实施计划见 [`docs/superpowers/plans/2026-10-12-pm-workflow-skills.md`](docs/superpowers/plans/2026-10-12-pm-workflow-skills.md)。

## License

[MIT](LICENSE)
