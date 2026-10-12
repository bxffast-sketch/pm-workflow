# 产品经理全流程 Skill 套件 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建 6 个 Claude Code skill(`/pm-collect` `/pm-clarify` `/pm-value` `/pm-prd` `/pm-proto` `/pm`),实现产品经理标准工作流的五阶段 + 路由,先装本仓库 `.claude/skills/`,验证通过后提供同步到全局的脚本。

**Architecture:** 每个阶段是一个自包含的 SKILL.md(遵循 superpowers:writing-skills 的 CSO 规范:frontmatter 只有 name/description,description 以"Use when..."开头且不透露流程),共享输入面板/防伪造规则/质量门词汇等约定(各自内联,不做跨文件引用)。数据层是飞书多维表格(运行时通过 `lark-base` skill 建表)+ 本地 `pm-workspace/requirements/<REQ-ID>/` 长文档,两边用需求 ID 对齐。原型高保真生成委托给已装的 `huashu-design` skill,不重新实现。

**Tech Stack:** Claude Code Skill(Markdown + YAML frontmatter)、`lark-cli`(飞书多维表格 CRUD)、Mermaid(流程图/状态机语法)、Bash(本地 workspace 操作)。

**测试方法:** 遵循 superpowers:writing-skills 的 RED-GREEN 流程——每个 skill 写完后,先用 Agent 工具派一个**没有加载该 skill**的 subagent 跑同一个压力场景(fixture),记录它在没有规则约束时会怎么编造数字/跳过澄清/漏掉异常流(RED,证明 skill 确实需要存在);然后派一个**显式要求使用该 skill**的 subagent 跑同一场景,确认它遵守输入面板、防伪造规则、质量门(GREEN)。两轮都用 `docs/superpowers/plans/fixtures/sample-requirement.md` 里的同一个样例需求,保证六个 skill 的测试可比。

---

## Task 0: 共享 fixture + workspace 配置骨架

**Files:**
- Create: `docs/superpowers/plans/fixtures/sample-requirement.md`
- Create: `pm-workspace/config.json.example`

**说明:** 六个 skill 的 RED/GREEN 测试都要用同一个样例需求,避免每个 skill 测不同场景导致结果不可比。样例需求故意设计成"原始诉求 ≠ 真实需求"(呼应设计文档 §5.3 的"导出 Excel 做周报"案例),这样可以验证 `/pm-clarify` 和 `/pm-value` 是否真的做了深挖,而不是直接照抄用户的表面说法。

- [ ] **Step 1: 写样例需求 fixture**

Create `docs/superpowers/plans/fixtures/sample-requirement.md`:

```markdown
# 测试用样例需求(六个 skill 的 RED/GREEN 测试共用)

## 原始对话(模拟用户在飞书群里的一句话需求)

> "运营同事说,后台的订单列表能不能加一个导出 Excel 的按钮?他们现在每周要手动把订单数据复制到 Excel 里做给老板看的周报,挺麻烦的。昨天还跟我抱怨了一次,说复制粘贴老出错,上周就因为漏了一行数据被老板问了。"

## 关键线索(用于验证 skill 是否正确挖掘,而不是照抄表面诉求)

- 表面诉求(Request):导出 Excel 按钮
- 真实需求线索(Need,需要 skill 通过追问挖出来):运营需要的是"趋势可视化",不是"原始数据表格"——现有图表看不出趋势,所以才退而求其次用 Excel 自己画图
- 频次线索:"每周"
- 紧急度线索:"上周被老板问了"——有一次具体的负面后果,但语气不算非常紧急
- 影响范围线索:"运营同事"(单数,需要 skill 追问是否只有一个人在用,还是整个运营团队)
- 提出人:运营同事(通过"我"转达,不是运营本人直接提出——需要 skill 识别"二级转述"这个情况并追问原始提出人)

## 用于测试「单一样本陷阱」识别的追加信息(供 /pm-value 阶段使用)

如果 skill 直接问"还有谁需要这个功能",模拟回答:"目前只听这一个同事说过,其他人没提。"
正确的 skill 行为:应该把这个标记为"可能是单一样本"的风险信号,而不是直接按"运营团队都需要"来打分。

## 用于测试异常流识别的追加信息(供 /pm-prd 阶段使用)

订单数据量级:单次导出可能上万行。
正确的 skill 行为:应该在 PRD 的业务流程图里识别出"导出超时""导出中网络断开""并发导出"等异常分支,而不是只画"点击导出 → 下载文件"的理想路径。
```

- [ ] **Step 2: 写 workspace 配置骨架**

Create `pm-workspace/config.json.example`:

```json
{
  "feishu": {
    "bitable_app_token": "",
    "bitable_table_id": "",
    "field_map": {
      "req_id": "需求ID",
      "submitter": "提出人",
      "submitted_at": "提出时间",
      "source_channel": "来源渠道",
      "scenario": "场景描述",
      "expected_result": "预期结果",
      "urgency": "紧急程度",
      "raw_request": "原始诉求",
      "real_need": "真实需求",
      "user_role": "用户角色",
      "usage_scenario": "使用场景",
      "pain_point": "核心痛点",
      "rigidity_score": "刚需度",
      "frequency_score": "频次度",
      "temperature_score": "温度",
      "rice_reach": "RICE-Reach",
      "rice_impact": "RICE-Impact",
      "rice_confidence": "RICE-Confidence",
      "rice_effort": "RICE-Effort",
      "rice_total": "RICE综合分",
      "kano_category": "KANO分类",
      "priority": "优先级",
      "prd_link": "PRD链接",
      "prototype_link": "原型链接",
      "current_stage": "当前阶段",
      "updated_at": "更新时间"
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd "/Users/mac/vibe coding/产品经理工作agent"
git add docs/superpowers/plans/fixtures/sample-requirement.md pm-workspace/config.json.example
git commit -m "Add shared test fixture and workspace config template for PM skill suite"
```

---

## Task 1: `/pm-collect` —— 需求挖掘与收集

**Files:**
- Create: `.claude/skills/pm-collect/SKILL.md`

**说明:** 这是六个 skill 里最简单的一个,优先实现用来验证飞书自动建表链路。核心约束:只做忠实记录,不替用户下结论"真实需求"是什么。

- [x] **Step 1: 写 SKILL.md 草稿**

Create `.claude/skills/pm-collect/SKILL.md`:

```markdown
---
name: pm-collect
description: Use when a one-line feature request, user complaint, or stakeholder ask needs to be captured into the requirement pool before any judgment about priority or feasibility — triggers on phrases like "记录一个需求" "有人要加个功能" "需求池" "新增一条需求". Covers intake from feedback, complaints, market research, competitor moves, internal ops asks, exec strategy, or tech-debt requests.
---

# pm-collect · 需求挖掘与收集

## 设计哲学

这一步只做**忠实记录**,不做价值判断。用户说"我需要一匹快的马",这一步只记录"用户说要一匹快的马"(原始诉求/Request),不替用户猜"他其实需要的是更快的交通方式"(真实需求/Need)——那个判断留给 `/pm-clarify`。提前下结论的记录,会把后续澄清步骤的起点污染成"确认我的猜测"而不是"挖掘真相"。

## 触发

**触发词**:记录需求、新增需求、需求池、有人要加个功能、用户反馈说、客户投诉、这个需求记一下
**不触发**:已经讨论清楚要不要做、只是想查已有需求状态(→ `/pm`)、要澄清一个已记录需求的细节(→ `/pm-clarify`)

## 输入要求

### 必须有(缺失则问,一次只问一个问题,不猜不假设)

- **提出人**:谁提的?如果是转述("运营同事说"),要追问转述人和原始提出人分别是谁,原始提出人才是记录对象
- **提出时间**:今天还是之前?
- **来源渠道**:枚举之一 —— 用户反馈 / 客户投诉 / 市场调研 / 竞品动态 / 业务运营需求 / 老板战略方向 / 技术重构性能优化
- **场景描述**:什么情况下产生这个需求(不是"要什么功能",是"什么场景逼出了这个诉求")
- **预期结果**:用户/提出人期望看到什么结果

### 可以推断(标注 `⚠️ 推断:[依据]`)

- **紧急程度**:根据措辞语气、是否提及截止时间或已发生的负面后果推断。例如提到"上周被老板问了"这种已发生的具体后果,比单纯"挺麻烦的"语气更接近高优先级,但仍需在记录里写明推断依据,不能直接定成 P0

### 不允许猜测

- **原始诉求之外的任何"真实需求"判断**。即使你从场景描述里已经能看出表面诉求和真实需求可能不一致(比如"要导出 Excel"背后可能是"要看趋势图"),这一步也只记录表面诉求,把你的直觉写进"⚠️ 待澄清线索"字段供下一步使用,不要替用户下结论

## 输出

- 飞书需求池新记录(字段见下方"写入飞书"小节)
- 本地 `pm-workspace/requirements/<REQ-ID>/01-collect.md`

## 执行流程

### Step 0 — 输入面板(开始前必须完成)

```
✅ 已确认:[字段] = [值]
❌ 必须明确:[字段] → 影响:[不明确会导致下游什么问题]
⚠️ 已推断:[字段] = [推断值](依据:[原因])
```

❌ 项一次只问一个,不批量甩问题给用户。全部 ❌ 清空后才能进入正式流程。

### Step 1 — 检查需求池是否已配置

读取 `pm-workspace/config.json`。如果文件不存在或 `feishu.bitable_app_token` 为空:

1. 问用户:"需求池还没建,你想建在哪个飞书文件夹里?"
2. 用 `lark-base` skill 的建表能力,创建一张多维表格,字段按下方"写入飞书"小节的 24 个字段创建(参考 `lark-base` 的 `references/lark-base-field-schema.md` 确定每个字段的类型)
3. 建 3 个视图:按优先级看板(分组字段=优先级)、待澄清(筛选=当前阶段=collect)、待评估(筛选=当前阶段=clarify)
4. 把生成的 `app_token` 和 `table_id` 写回 `pm-workspace/config.json`

如果已配置,跳到 Step 2。

### Step 2 — 生成需求 ID

格式:`REQ-YYYYMMDD-NNN-简短标题`。`YYYYMMDD` 用今天日期,`NNN` 是当天序号(查本地 `pm-workspace/requirements/` 目录下已有多少个同日期前缀的文件夹,取 +1,补零到 3 位),简短标题是场景的 4-8 字概括(如"订单导出")。

### Step 3 — 走输入面板,收集五个必填字段 + 一个推断字段

按"输入要求"小节的顺序逐一确认。❌ 项一次问一个。

### Step 4 — 写入飞书

创建一条新记录,字段:

| 字段 | 来源 |
|---|---|
| 需求ID | Step 2 生成 |
| 提出人 | Step 3 收集 |
| 提出时间 | Step 3 收集 |
| 来源渠道 | Step 3 收集(枚举值之一) |
| 场景描述 | Step 3 收集 |
| 预期结果 | Step 3 收集 |
| 紧急程度 | Step 3 推断,写入时带 "⚠️ 推断" 前缀 + 依据 |
| 原始诉求 | 用户原话或贴近原话的转述,不要改写成功能描述 |
| 当前阶段 | 固定写 `collect` |
| 更新时间 | 当前时间 |

其余字段(澄清组/价值组/交付组)留空,后续阶段补。

### Step 5 — 写本地文件

Create `pm-workspace/requirements/<REQ-ID>/01-collect.md`,内容是 Step 0-4 的完整记录(输入面板 + 五个字段 + 推断字段及依据 + 原始诉求原文)。

### Step 6 — 质量门

**BLOCKER 判据**(命中任一,列出缺项,不放行,不询问是否继续):
- 场景描述为空
- 紧急程度与场景描述矛盾(例如标"紧急"但场景描述里没有任何截止时间或负面后果线索,或反过来场景描述提到强烈负面后果却标"不急")

**PASS 时**,问用户:"`/pm-collect` 已完成,需求 ID 是 `<REQ-ID>`。是否现在进入 `/pm-clarify` 做需求澄清?"

## 常见设计错误

> 把"场景描述"写成"功能描述"。例如把"运营每周要手动复制订单数据做周报"写成"需要一个导出按钮"——这就是提前下结论,后续 `/pm-clarify` 会失去挖掘空间。

> 跳过"转述人 vs 原始提出人"的区分。二级转述的需求,提出人应该是原始说话的人,不是转达消息的同事。

## 质量检查(生成前自检)

- [ ] 场景描述是情境,不是解决方案
- [ ] 原始诉求是原话或贴近原话,没有被改写成功能点
- [ ] 紧急程度如果是推断的,依据写清楚了
- [ ] 需求 ID 格式正确且在本地目录里不重复

## 与其他 Skill 的关系

| Skill | 关系 |
|---|---|
| `/pm-clarify` | 下游。读取本 skill 产出的 `01-collect.md` 和飞书记录,做结构化澄清 |
| `/pm` | 并行。路由器会读取飞书需求池展示所有需求的阶段,不依赖本 skill 的执行顺序 |
| `huashu-design` | 无直接关系 |
```

- [x] **Step 2: RED 基线测试(不加载 skill)**

用 Agent 工具派一个 subagent,prompt 里**不要提到 pm-collect skill**,只给它 `docs/superpowers/plans/fixtures/sample-requirement.md` 的原始对话片段,要求"帮我把这条需求记录下来,整理成一个需求卡片"。观察并记录它的行为:预期它会直接把"导出 Excel 按钮"当作记录内容(而不是场景描述),可能会跳过"转述人 vs 原始提出人"的区分,可能会编造一个紧急程度而不说明依据。把观察结果记在这个 Task 下方的注释里(不用写文件,口头确认即可继续)。

- [x] **Step 3: GREEN 验证(加载 skill)**

用 Agent 工具派一个 subagent,prompt 里明确要求"使用 pm-collect skill 处理这条需求"(并告知 subagent 它可以用 Skill 工具加载 `pm-collect`),给同样的 fixture 内容。确认它:
1. 走了 Step 0 输入面板,且识别出"运营同事说"是转述,追问了原始提出人
2. 把场景描述和功能描述分开记录,场景描述里没有出现"导出 Excel 按钮"这个解决方案
3. 紧急程度标了 `⚠️ 推断` 并写明依据
4. 生成的需求 ID 格式正确

如果有任何一项不符合,回到 Step 1 修改 SKILL.md 内容(常见漏洞:触发条件不够明确、Step 3 顺序描述不清晰导致 agent 跳步),重新跑 Step 3 直到通过。

- [x] **Step 4: Commit**

```bash
cd "/Users/mac/vibe coding/产品经理工作agent"
git add .claude/skills/pm-collect/SKILL.md
git commit -m "Add pm-collect skill for requirement intake stage"
```

---

## Task 2: `/pm-value` —— 需求甄别与价值判断

**Files:**
- Create: `.claude/skills/pm-value/SKILL.md`

**说明:** 设计文档排序里这是第二优先,因为评分模型最多、最容易被滥用编造数字。核心约束是防伪造规则——RICE 分、频次度等具体数字只能来自用户确认、标注依据的推断、或留空待确认,三种来源之外禁止出现。

- [x] **Step 1: 写 SKILL.md 草稿**

Create `.claude/skills/pm-value/SKILL.md`:

```markdown
---
name: pm-value
description: Use when a clarified requirement (one with a confirmed "real need" from pm-clarify) needs prioritization scoring before solution design — triggers on phrases like "这个需求值不值得做" "优先级怎么排" "算一下 RICE" "是不是伪需求" "P0 还是 P1". Not for raw unclarified asks (use pm-clarify first) or for scoring already-built features' performance.
---

# pm-value · 需求甄别与价值判断

## 设计哲学

这一步最容易出的问题不是"算错公式",而是**编造没有依据的数字去填满一张看起来完整的表格**。一个 RICE 评分表全是具体数字,看起来很专业,但如果 Reach=5000、Confidence=80% 都是凭空编的,它比"不打分"更危险——因为它制造了精确的假象。本 skill 的核心约束是防伪造规则,所有打分模型都服务于这条规则,不是反过来。

## 防伪造规则(最高优先级,凌驾本 skill 其余所有流程)

任何具体数字(刚需度/频次度/温度/RICE 各分项/KANO 分类依据的量表答案),只能来自三种来源之一:

1. **用户在对话中明确给出的数字或可推导的事实**(例如用户说"大概有200个客户遇到这个问题",可以直接用)
2. **标注 `⚠️ 推断:[推断依据]` 的估算**,依据必须具体可追溯(例如"⚠️ 推断:频次度=中,依据=场景描述提到'每周'一次"),不能写"⚠️ 推断:经验判断"这种无法验证的依据
3. **没有依据时留空并标 `⚠️ 待确认`**,绝不为了让表格看起来完整而编一个数字

每打一个分之前,先问自己:这个数字的来源是上面三种里的哪一种?如果答不出来,就是在编造。

## 触发

**触发词**:这个需求值不值得做、优先级怎么排、算一下 RICE、是不是伪需求、P0 还是 P1、需求评分
**不触发**:需求还没经过 `/pm-clarify` 澄清(没有"真实需求"结论可打分)、要评估已上线功能的实际效果(这是数据分析,不是需求优先级判断)

## 输入要求

### 必须有

- **「真实需求」结论**(来自 `/pm-clarify` 产出的 `02-clarify.md`,如果没有这个文件,先引导用户跑 `/pm-clarify`)
- **影响范围**:有多少用户/客户遇到这个问题(具体数字,或"只有一个样本"这种明确说明)

### 可以推断(标注依据)

- 刚需度/频次度/温度三维评分、RICE 四项、KANO 分类——全部允许推断,但每一项推断都要单独写依据,不能笼统写"综合判断"

### 不允许猜测

- Confidence 低于 50% 时**不纳入 RICE 计算**,必须停下来问用户或标 `⚠️ 待确认`,不能为了算出一个总分硬凑一个 Confidence 值

## 执行流程

### Step 0 — 输入面板

同其他 skill 格式,但额外检查:`02-clarify.md` 是否存在且包含「真实需求」结论。如果不存在,❌ 项直接是"需要先跑 /pm-clarify",不进入后续流程。

### Step 1 — 5 Whys

对「真实需求」结论连续追问"为什么",每一层的回答都要记录,禁止在同一条链上跳步(例如从"为什么要导出"直接跳到"因为要做决策",中间跳过的层次要补问)。参考案例(来自测试 fixture):

```
需求表面:导出 Excel 数据表格
为什么? → 要给老板做周报
为什么? → 现有的图表没法直接看出趋势
本质需求 → 系统需要增加可视化趋势图表,而不是导表格
```

如果追问到第 2-3 层就停下来,大概率还没到本质——继续追问直到答案变成"系统/流程/习惯层面的根因",而不是停留在"任务层面的理由"。

### Step 2 — 刚需度/频次度/温度三维评分

三个维度各打一个档位(高/中/低),每个档位必须标明来源(用户确认 / ⚠️推断+依据 / ⚠️待确认)。

### Step 3 — RICE

- **Reach**:影响用户数,按时间周期计(如"每月 X 个用户")
- **Impact**:massive=3 / high=2 / medium=1 / low=0.5 / minimal=0.25,五档之一,不允许用中间值
- **Confidence**:100%(高,有直接数据或多个用户确认)/ 80%(中,有间接证据)/ 50%(低,主要靠推断)。**低于 50% 的点子不纳入计算**,改为标注"⚠️ 待确认,证据不足以估算 RICE"
- **Effort**:人月
- **公式**:`(Reach × Impact × Confidence) / Effort`
- **B端调节**:如果 Reach 对应的是单一大客户或单一样本(呼应 fixture 里"目前只听这一个同事说过"的情况),必须额外叠加战略契合度/合规要求/合同义务三项中至少一项的说明,不能让一个样本量=1 的 Reach 直接乘出一个看起来合理的总分

### Step 4 — KANO

对需求点配一组问句:
- 功能性问题:"如果有这个功能,你感觉如何?"
- 非功能性问题:"如果没有这个功能,你感觉如何?"

两个问题的答案都用 5 级量表:我喜欢这样 / 我希望这样 / 中立 / 可以忍受 / 我不喜欢这样。

两个答案组合查下表定类:

| 功能性\非功能性 | 我喜欢这样 | 我希望这样 | 中立 | 可以忍受 | 我不喜欢这样 |
|---|---|---|---|---|---|
| **我喜欢这样** | Q | A | A | A | O |
| **我希望这样** | R | I | I | I | M |
| **中立** | R | I | I | I | M |
| **可以忍受** | R | I | I | I | M |
| **我不喜欢这样** | R | R | R | R | Q |

(M=必备型 / O=期望型 / A=魅力型 / I=无差异型 / R=反向型 / Q=可疑型,Q 代表两个答案自相矛盾,需要重新向用户确认)

Better-Worse 系数(多个相关功能点对比时用):
- SI(满意度增加量)= (A+O) / (A+O+M+I)
- DSI(不满意度增加量)= -(O+M) / (A+O+M+I)

### Step 5 — 俞军用户价值公式校验

`用户价值 = (新体验 − 旧体验) − 替换成本`

替换成本必须显式写出来,包含:用户迁移操作习惯的成本、学习新交互的成本、历史数据/工作方式迁移的代价。这一项最容易被漏算——如果你发现自己只写了"新体验"和"旧体验"却没有替换成本这一行,回去补上。

### Step 6 — 综合定级

- **P0**:核心主流程阻断 / 重大违规或安全漏洞 / 高频且高价值
- **P1**:明显提升体验 / 能带来量化收益
- **P2**:锦上添花的小体验优化
- **P3**:伪需求 / ROI 极低 / 技术成本极高

定级要引用 Step 1-5 的具体结论,不能只写"综合考虑后定为 P1",要说明是哪个维度的分数或哪个反模式判断支撑了这个定级。

### Step 7 — 质量门

**BLOCKER 判据**(命中任一且未被识别讨论,列出缺项,不放行):
- **单一样本陷阱**:Reach 或影响范围只来自一个用户/客户,但打分时按"普遍需求"处理,没有标注这是单一样本风险
- **竞品陷阱**:理由主要是"竞品有这个功能",没有独立评估对本产品用户的价值
- **老板需求未经验证**:来源渠道是"老板战略方向"但价值判断全部跳过,直接定为高优先级
- **历史同类功能使用率为零**:如果有历史同类功能上线后使用率很低这个信息,但新需求评分时没有引用这个事实

**PASS 时**,问用户:"`/pm-value` 已完成,定级为 `<P几>`。是否现在进入 `/pm-prd` 做方案设计?"(如果定级是 P3,改问:"这个需求定级为 P3,通常不建议继续投入方案设计。是否仍要继续?")

## 常见设计错误

> 为了让 RICE 总分"好看",反向调整 Impact 或 Confidence 的档位。打分顺序应该是先看证据定档位,再算总分,不是先想好要什么总分再倒着选档位。

> 把"竞品有这个功能"直接等同于"这个功能对我们用户有价值"——这是竞品陷阱的典型表现,必须被识别为 BLOCKER。

## 质量检查(生成前自检)

- [ ] 5 Whys 每一层都有记录,没有跳步
- [ ] 每个评分维度的数字都标明了来源(用户确认/推断+依据/待确认),没有凭空出现的数字
- [ ] Confidence 低于 50% 的情况被正确处理(未纳入计算),不是硬凑出一个总分
- [ ] 俞军公式里的"替换成本"被显式计算,不是只写了新旧体验对比
- [ ] 四个反模式(单一样本/竞品陷阱/老板需求未验证/历史使用率为零)逐一检查过,不是漏检

## 特殊场景

### 场景 1 — 用户直接给出一个"数据支撑的"数字,但来源可疑

例如用户说"这个需求影响2000个用户",但场景描述里只提到"运营同事"一个人反馈。这时不能直接按用户给的 2000 作为 Reach,要追问"这 2000 是怎么统计出来的,是实际数据还是估算",把来源记录清楚再决定是否采信。

## 产出写入 Feishu

更新对应需求记录的价值组字段:刚需度、频次度、温度、RICE-Reach、RICE-Impact、RICE-Confidence、RICE-Effort、RICE综合分、KANO分类、优先级。本地写 `pm-workspace/requirements/<REQ-ID>/03-value.md`,内容是 Step 1-6 的完整打分过程和依据(不是只写最终结论,过程必须保留,方便复核)。当前阶段更新为 `value`。

## 与其他 Skill 的关系

| Skill | 关系 |
|---|---|
| `/pm-clarify` | 上游。本 skill 要求 `02-clarify.md` 已存在,否则引导先跑该 skill |
| `/pm-prd` | 下游。P0-P2 的需求 PASS 后可进入;P3 需要用户二次确认才继续 |
```

- [x] **Step 2: RED 基线测试(不加载 skill)**

用 Agent 工具派一个 subagent,不提及 pm-value skill,给它 fixture 里"单一样本"的追加信息("目前只听这一个同事说过,其他人没提"),要求"帮这个需求算一下 RICE 分和优先级"。预期它会:直接把 Reach 设成一个具体数字(没有标注这是单一样本的风险),可能跳过 Confidence 低于 50% 时不纳入计算的规则,可能不会提到俞军公式的替换成本项。记录观察结果。

- [x] **Step 3: GREEN 验证(加载 skill)**

派一个 subagent 明确要求使用 `pm-value` skill,同样的输入。确认它:
1. 把"单一样本"识别为 BLOCKER 风险并提出讨论,而不是直接打分通过
2. 每个数字都标了来源(用户确认/推断+依据/待确认)
3. 如果 Confidence 推断出来低于 50%,正确处理为不纳入计算而不是硬凑总分
4. 俞军公式里显式写了替换成本

不符合则回 Step 1 修改,常见问题是质量门判据描述不够具体导致 agent 没触发 BLOCKER 判断。

- [x] **Step 4: Commit**

```bash
cd "/Users/mac/vibe coding/产品经理工作agent"
git add .claude/skills/pm-value/SKILL.md
git commit -m "Add pm-value skill for requirement prioritization stage"
```

---

## Task 3: `/pm-clarify` —— 需求沟通与细节碰撞

**Files:**
- Create: `.claude/skills/pm-clarify/SKILL.md`

- [x] **Step 1: 写 SKILL.md 草稿**

Create `.claude/skills/pm-clarify/SKILL.md`:

```markdown
---
name: pm-clarify
description: Use when a recorded requirement's underlying scenario, trigger, and real need are still unclear and someone needs to go have a structured conversation before priority or design work starts — triggers on phrases like "需求澄清" "沟通提纲" "真实需求是什么" "去跟用户/业务方谈谈". Produces an interview outline first, then processes the conversation's results after the PM talks to the stakeholder.
---

# pm-clarify · 需求沟通与细节碰撞

## 设计哲学

这一步分两阶段:**先生成提纲,再处理回填**。不是让 AI 代替 PM 去猜真实需求,是让 AI 把"该问什么"结构化出来,PM 带着提纲去跟真实的人聊完,再回来让 AI 帮忙提炼结论。追问方式借用 The Mom Test 的原则——问对方过去的具体行为,不问对未来的假设性意见,因为"你会用这个功能吗"这种问题得到的答案几乎总是不可靠的礼貌性肯定。

## 触发

**触发词**:需求澄清、沟通提纲、真实需求是什么、去跟用户谈谈、细节碰撞
**不触发**:需求还没被记录(→ `/pm-collect`)、已经有澄清结论要打分(→ `/pm-value`)

## 输入要求

### 必须有

- 已存在的 `01-collect.md`(本 skill 读取其中的场景描述和原始诉求作为起点)

### 两步流程里的"回填"阶段额外输入(四种任选一种)

- 直接贴文字总结
- 本地文件路径
- 飞书文档链接(用 `lark-doc` 的 `+fetch` 读取)
- 飞书妙记链接(用 `lark-meeting` 的 `note +detail` 拉取逐字稿)

## 执行流程

### Step 0 — 输入面板

检查 `01-collect.md` 是否存在。不存在则引导先跑 `/pm-collect`。

### Step 1 — 生成沟通提纲

覆盖以下维度,每条配一句 Mom Test 风格的追问话术(问具体过去行为,不问假设性意见):

| 维度 | 要问什么 | 追问话术示例 |
|---|---|---|
| 用户角色(Who) | 谁在实际使用/受影响? | "除了你,还有谁会遇到同样的情况?" |
| 使用场景(Where/When) | 什么时间、什么环境下发生? | "上一次遇到这个情况,具体是在做什么的时候?" |
| 核心痛点(What) | 不解决会怎样? | "如果一直没有这个功能,你们现在是怎么应对的?" |
| 触发条件 | 什么情况下这个问题才会出现? | "是每次都会遇到,还是只在某些特定情况下?" |
| 当前变通方案(workaround) | 现在怎么绕过去的? | "上次遇到的时候,你是怎么处理的,花了多久?" |
| 影响范围/人数 | 多少人/多频繁受影响? | "团队里还有几个人也这么做?" |
| 不解决的后果 | 不做这个事会有什么具体损失? | "上次因为没有这个功能,具体造成了什么后果?"(呼应 fixture 里"上周被老板问了"这种具体后果) |
| 成功判定标准 | 怎么才算解决了? | "如果这个问题解决了,你觉得会有什么不一样?" |
| 边界(不做什么) | 哪些情况明确不需要覆盖? | "有没有哪种情况,即使出现了也不需要处理?" |
| 依赖方 | 这件事还牵扯到谁? | "做这件事需要跟谁对齐,或者谁会受到影响?" |

生成后给用户,PM 带着去跟真实的人谈。

### Step 2 — 回填结果

PM 谈完后回来,提供四种输入源之一。skill 自动识别类型(文字/本地文件路径/飞书文档 URL 模式/飞书妙记 URL 模式),读取内容。

### Step 3 — 提炼「真实需求」结论

从回填内容里,针对 Step 1 的十个维度逐一提炼,如果某个维度没有被谈到或谈的不够清楚,标注 `⚠️ 待确认`,不要替用户补全没谈到的内容。

把提炼出的「真实需求」与 `01-collect.md` 里的「原始诉求」并列对比展示,如果两者有差异,说明差异的具体原因(例如引用追问时得到的某句回答);如果两者几乎一致,也要说明"为什么深挖之后结论没变"(可能是真的就是表面诉求,也可能是深挖不够,需要诚实判断是哪一种)。

### Step 4 — 质量门

**BLOCKER 判据**:
- 提纲没有覆盖十个必答维度就直接产出总结
- 「真实需求」结论与「原始诉求」完全一致,但没有解释为什么深挖之后结论没变(这通常意味着追问没有真正发生,只是把原始诉求换了个说法)

**PASS 时**,问用户:"`/pm-clarify` 已完成,「真实需求」结论是:[结论]。是否现在进入 `/pm-value` 做价值判断?"

## 常见设计错误

> 回填阶段看到用户贴的文字里提到了功能性方案(比如"用户说希望加个导出按钮"),直接把这个方案当成「真实需求」写进结论——这是把"对方描述的解决方案"误当成"真实需求"。真实需求应该是解决方案背后的那层诉求(呼应 fixture:表面要导出按钮,真实需求是要看趋势)。

## 质量检查(生成前自检)

- [ ] 提纲十个维度都生成了对应的追问话术,不是只写了维度名没写问法
- [ ] 回填结论和原始诉求的对比明确写出了"相同"或"不同",以及原因
- [ ] 没有把回填内容里的"用户建议的解决方案"直接当成「真实需求」

## 产出写入 Feishu

更新澄清组字段:真实需求、用户角色、使用场景、核心痛点。本地写 `02-clarify.md`,内容含完整提纲 + 回填原文摘要 + 对比结论。当前阶段更新为 `clarify`。

## 与其他 Skill 的关系

| Skill | 关系 |
|---|---|
| `/pm-collect` | 上游,读取其产出作为起点 |
| `/pm-value` | 下游,要求本 skill 的「真实需求」结论已存在 |
| `lark-doc` / `lark-meeting` | 子工具,用于读取飞书文档链接或妙记链接 |
```

- [x] **Step 2: RED 基线测试**

派 subagent(不提及 skill),给 fixture 的原始对话,要求"帮我生成一份需求澄清的沟通提纲"。预期它可能给出泛泛的"你需要什么功能"类问题,不会用 Mom Test 式的过去行为提问,维度覆盖可能不全(只问 Who/What/When 三要素,漏掉触发条件/workaround/边界等)。

> 实测:RED 基线实际表现好于预期,十个维度都有覆盖,且大部分问题也锚定在过去具体事件;自评中承认在"成功标准/边界"两处仍带了评价性/偏好色彩。与 GREEN 的差距主要在于结构化程度和"是否明确对照十个维度自检",而非完全答非所问。

- [x] **Step 3: GREEN 验证**

派 subagent 明确要求用 `pm-clarify` skill。确认提纲覆盖十个维度且追问话术是具体过去行为式提问,而非假设性意见提问。再模拟一轮回填(用 fixture 里"真实需求是趋势可视化"的线索作为回填内容),确认它正确识别出"原始诉求=导出按钮,真实需求=趋势图表"的差异,而不是直接把回填里提到的"导出按钮"当成真实需求。

> 实测:GREEN 十个维度全部覆盖,追问话术锚定过去具体事件;回填阶段正确识别"原始诉求=导出按钮,真实需求=趋势图表(数据可视化)",未将回填中提到的"Excel"字面意思当成真实需求,显式引用了 SKILL.md 的"常见设计错误"规避该陷阱。一轮通过,无需修订。

- [x] **Step 4: Commit**

```bash
cd "/Users/mac/vibe coding/产品经理工作agent"
git add .claude/skills/pm-clarify/SKILL.md
git commit -m "Add pm-clarify skill for requirement clarification stage"
```

---

## Task 4: `/pm-prd` —— 产品方案设计

**说明:** 本 Task 的内容已依据公司实际使用的《PRD 模板 V1.1.1》(来源:飞书云空间文件,`https://gaotuedu.feishu.cn/file/RFl9bYZwkoHnXnxiT3ccIsnVnHh`)重新设计,比原设计文档 §5.4 更丰富。新增:元信息头 + 变更历史、量化的产品目标及价值(含基线数据要求)、功能类型三分类(新增/旧功能升级优化/Bugfix)、对其他系统的影响、产品交互总览(轻量级,区别于 `/pm-proto` 的详细交互规格)、非功能需求(数据/性能/监控/安全/兼容性)、风险与运营、相关文档附件。公司模板里的"PRD 衡量标准"是面向评审会议的 100 分制人工评分表(产品目标价值 25 分/产品设计无明显缺陷 25 分/变更历史 5 分/名词解释 5 分/交互表达 15 分/需求变更控制 15 分/运营规划 10 分),其中"产品设计无明显缺陷"这类维度需要人工判断力,不适合让 AI 自己打出一个具体分数——那正是防伪造规则要拦的"制造虚假精确度"。因此本 skill 把这套标准转成**自检清单**(逐项标 ✅已覆盖 / ⚠️部分覆盖,需人工评审确认 / ❌未覆盖),交给人工评审会判断最终分数,而不是自己生成一个"82分"。

**Files:**
- Create: `.claude/skills/pm-prd/SKILL.md`

- [x] **Step 1: 写 SKILL.md 草稿**

Create `.claude/skills/pm-prd/SKILL.md`:

```markdown
---
name: pm-prd
description: Use when a prioritized requirement (P0-P2, scored by pm-value) needs to become a structured product specification with flows, roles, use cases, and rules — triggers on phrases like "写 PRD" "产品方案设计" "画个流程图" "状态机设计" "需求文档". Not for raw or unscored requirements, and not for pure UI/interaction specs (use pm-proto for that).
---

# pm-prd · 产品方案设计

## 触发

**触发词**:写 PRD、产品方案设计、画流程图、状态机设计、需求文档、功能逻辑设计
**不触发**:需求还没打分(→ `/pm-value`)、只需要交互层面的规格而不是业务逻辑(→ `/pm-proto`)

## 输入要求

### 必须有

- `03-value.md` 已存在,且优先级为 P0/P1/P2
- `02-clarify.md` 已存在(「真实需求」结论,背景章节要引用)

### 前置拦截

如果优先级是 P3:停下来问用户"这个需求定级为 P3,通常不建议投入方案设计资源。是否仍要继续(可能有非量化的战略理由)?"用户确认继续才往下走,否则终止。

### 防伪造规则适用范围

本 skill 延续 `/pm-value` 的防伪造规则:背景章节的"基线数据"、产品目标及价值的"量化目标值",任何具体数字只能来自①用户给出或可推导的事实,②标注 `⚠️ 推断:[依据]` 的估算,③留空标 `⚠️ 待确认`。不允许为了让 PRD 看起来有数据支撑而编造基线数字或目标值。

## 执行流程

### Step 0 — 输入面板

检查 `03-value.md` 是否存在及其优先级,检查 `02-clarify.md` 是否存在。

### Step 1 — 元信息头与变更历史

写入文档头部元信息表:

| 字段 | 来源 |
|---|---|
| PRD 审核人 | 问用户(一般为撰写人的导师、直接上级或项目组成员) |
| 重要性 | 直接取 `03-value.md` 的优先级并映射:P0/P1→高,P2→中,P3→低 |
| 紧迫性 | 直接取 `01-collect.md` 的紧急程度(高/中/低),不重新问 |
| PRD 撰写人 | 问用户(多人共同撰写要全部列出) |
| PRD 提交日期 | 当前日期 |
| 需求变更控制时间点 | 问用户,可用时间点或阶段描述(如"设计阶段之后,编码阶段之前") |

版本号规则:3 位版本号(重大版本首位更新、功能模块类新增或优化次位更新、Bugfix 及小优化末位更新),首次创建为 `V1.0.0`。

初始化变更历史表(之后每次修改 PRD 都要追加一行,不是这个 skill 当次执行的职责,但要把表格结构建好):

| PRD 更新时间 | 变更内容 | 变更提出人 | 变更理由 |
|---|---|---|---|
| [提交日期] | PRD 文档 [版本号] 新建 | [撰写人] | 首次创建 |

**跟踪提示**:如果后续变更历史累计到 3 条以上(对应公司标准"需求变更半天以上不超过3项"),在变更历史表下方加一句提示,建议召集相关方review变更原因是否集中在某一类(业务变动/需求识别不准/产品设计缺陷/技术原因),但这不是本 skill 单次执行时的 BLOCKER——变更次数是 PRD 生命周期内持续累积的指标,不是首次写作时能判断的。

### Step 2 — 背景

引用 `02-clarify.md` 的「真实需求」结论(不是重复「原始诉求」),说明这个需求从哪来、解决什么问题。

如果 `02-clarify.md` 或此前的沟通中提到了调研数据(比如某个历史指标、某次调研发现),按防伪造规则列出基线数据和来源;没有基线数据就标 `⚠️ 待确认:暂无基线数据支撑,建议对比类似历史迭代效果`,不要为了显得有依据而编一个百分比。

### Step 3 — 名词解释

列出文档中出现的新名词、概念或简略语,给出定义。如果业务方和研发方可能对同一个词有不同理解(常见于新引入的业务概念),显式拉齐,避免埋藏歧义。没有新名词则这一节写"无"。

### Step 4 — 产品目标及价值

**量化目标表**,每个目标写清楚是以下四种类型中的哪一种:

| 目标类型 | 说明 | 示例 |
|---|---|---|
| 正向度量 | 某个指标从 A 提升到 B | 用户注册成功率从 70% 提升至 85% |
| 负向度量 | 某个负面指标从 A 降低到 B | 填写错误率从 10% 降低至 5% |
| 范围型 | 某个指标不超过/不低于某阈值 | 支付失败比率不高于 1% |
| 里程碑型 | 结果是二元的(成功/失败),多用于 0→1 型项目 | XX 日前发布样机及配套 APP V1.0 |

每个目标都要给出基线值(当前现状)和目标值,按 Step 2 的防伪造规则标注数据来源。

**上线后复盘提示**:在本节末尾写一句"迭代上线后复盘时,需按实际数据与本节预期目标对比,总结得与失",提醒这是闭环的一部分(不要求本次 skill 执行时就填复盘结果)。

### Step 5 — 产品概述

**用户角色**:列出涉及的角色及描述。**特别注意识别真正的"客户"**——如果需求来自二手转述(呼应 `/pm-clarify` 阶段可能发现的"业务管理者转达"情况),要在角色描述里标注谁是最终使用者,不要把转述人当成唯一的用户视角来源。

**总体流程图**(Mermaid flowchart,主流程):

```
flowchart TD
    A[用户触发功能] --> B[系统处理]
    B --> C[返回结果]
```

(实际内容按本需求替换,若是复杂迭代,还可以附加模块关系图)

**功能清单**,每条功能点标注类型(三选一)和优先级:

| 序号 | 功能模块/页面 | 功能点 | 功能类型 | 功能描述 | 优先级 |
|---|---|---|---|---|---|
| 1 | [模块名] | [功能点] | 新增 / 旧功能升级优化 / Bugfix | [一句话描述,标注对应 Step 2 的哪个用户痛点] | 高/中/低 |

**对其他系统的影响**:本次迭代涉及的外部系统接口关系;如果接口较多或复杂,建议用图形方式表示;如果本期没有外部接口依赖,这一项写"无"。

**产品交互总览**(轻量级概览,不是详细交互规格——详细规格是 `/pm-proto` 的职责):一段话或一张简表,说明本次迭代涉及的页面之间如何跳转,让读者在不看完整交互稿的情况下建立大致的页面关系认知。

### Step 6 — 功能详述

对 Step 5 功能清单里的每个功能模块,逐一展开:

**6.1 功能概述**:这个模块的内容和效果。

**6.2 业务流程图**(Mermaid flowchart):必须含主流程 + 分支流程 + 异常流程。异常流程覆盖以下清单,逐项过一遍,不适用的要写"不适用"而非留空:

空态 / 加载态 / 错误态 / 无权限 / 离线 / 超时 / 部分失败 / 并发冲突 / 幂等重试

Mermaid 语法示例:

```
flowchart TD
    A[用户点击导出] --> B{数据量是否超过阈值?}
    B -->|否| C[同步生成文件]
    B -->|是| D[异步生成任务]
    D --> E{生成是否超时?}
    E -->|否| F[通知用户下载]
    E -->|是| G[标记失败,提示重试]
    C --> H{下载是否中断?}
    H -->|否| I[下载完成]
    H -->|是| J[保留临时文件,支持续传]
```

**6.3 页面布局**:简述页面组成(表单/列表/详情等),如果有现成的墨刀/Figma 稿可以引用链接;本节不是 `/pm-proto` 的详细交互稿,只需说明布局要点。

**6.4 功能模块详述**,逐项覆盖:
- **用户场景**:用户通过什么操作或途径触发
- **约束条件**:前置条件(触发该功能的必要条件)、后置条件(执行完后数据和页面如何变化)
- **输入/输出**:不同输入如何处理,提交时系统做什么校验,不同结果返回什么
- **异常处理**:网络错误、接口异常、服务器内部错误时产品该如何反馈
- **状态转换**(如果本功能涉及状态机,用 Mermaid stateDiagram-v2):

```
stateDiagram-v2
    [*] --> 待生成
    待生成 --> 生成中: 用户点击导出
    生成中 --> 已完成: 生成成功
    生成中 --> 失败: 超时或系统错误
    失败 --> 生成中: 用户重试
    已完成 --> [*]
    失败 --> [*]: 用户放弃
```

**完备性自检**(写进质量门):每个状态必须可达、必须可退出(除终态外不能有死胡同)、每条转换标注触发事件 + 前置条件 + 后置动作。

- **界面排序规则**:列表页的默认排序逻辑,是否支持多维度排序;详情页/表单页各元素的排序规则
- **数据字典**:涉及哪些数据字段,**数据字段约束表**列出每个关键字段的必填/选填、类型、长度、格式、默认值、唯一性、校验提示文案

### Step 7 — 非功能需求

逐项检查以下五类,**适用则详细描述,不适用则写明理由(不能留空)**:

| 类型 | 要点 |
|---|---|
| 数据需求 | 如需统计 PV/点击/转化率等,列出需要埋点的事件,同步给研发 |
| 性能需求 | 最大并发数、响应时间等特殊要求 |
| 监控需求 | 接口/服务异常时是否需要特殊告警 |
| 安全需求 | 敏感字段加密、批量操作审批/监控等 |
| 兼容性需求 | 浏览器/设备/系统版本兼容范围 |

### Step 8 — 角色与用例

角色权限边界(在 Step 5 用户角色基础上,细化每个角色能做什么)。

**用例说明**:遵循 INVEST 原则(独立/可协商/有价值/可估算/小/可测试)写用户故事,格式:`作为 <角色>,我想要 <目标>,以便 <价值>`。验收标准用 Gherkin 格式:

```
Given <前置条件>
When <触发动作>
Then <期望结果>
```

每个用例至少写一条正向 + 一条异常的验收标准。

### Step 9 — 风险与运营

- **风险应对**:该版本上线后可能带来的风险及应对措施(从业务与技术——监控、模块依赖等——两个角度考虑)
- **跨部门影响**:是否涉及上下游产研或业务团队
- **上线步骤**:是否需要历史数据回溯、灰度发布等
- **推广与运营计划**:上线后的推广/运营计划,需要哪些团队协助支持

### Step 10 — 相关文档

列出与本 PRD 相关的附件:原型图文件或协作地址、UI 切图文件、产品功能介绍 PPT 等。没有则写"无"。

### Step 11 — 质量门

**BLOCKER 判据**(命中任一,列出缺项,不放行,不执行写入):
- Step 6 的业务流程图只有主流程,没有异常流程分支
- Step 6 状态机存在不可达或不可退出的死胡同状态
- Step 6 数据字段约束表里有字段缺少校验规则
- Step 8 验收标准不是 Given-When-Then 格式
- Step 4 产品目标及价值里一个可量化的目标都没有(全部是模糊描述,没有任何基线值或目标值,也没有标 `⚠️ 待确认`)
- Step 1 变更历史表缺失或格式不完整

**质量自检清单**(人工评审会参考,不由本 skill 自己打分;对应公司 100 分制评审标准的判断维度,但产品设计是否"无明显缺陷"等需要人工判断力的维度留给评审会,不自动打分):

- [ ] ✅已覆盖 / ⚠️部分覆盖(需人工评审确认)/ ❌未覆盖 —— 产品目标及价值识别准确,收益可量化,基线数据有来源
- [ ] 同上 —— 文档变更历史描述完整
- [ ] 同上 —— 新引入概念有专门的名词解释
- [ ] 同上 —— 产品设计无明显缺陷(架构可拓展性、功能抽象合理性、场景覆盖完整性、逻辑自洽性)——**此项必须留给人工评审,本 skill 只整理证据,不自行判定"无缺陷"**
- [ ] 同上 —— 产品逻辑及交互表述清晰、易于理解(多用表格/脑图/流程图/用例/状态机表述)
- [ ] 同上 —— 产品上线后的推广及运营规划清晰

**PASS 时**(BLOCKER 清空后),问用户:"`/pm-prd` 已完成。是否现在进入 `/pm-proto` 做原型与交互定义?"

## 常见设计错误

> 异常流清单走过场,九项里有几项直接写"不适用"却没有说明为什么不适用。"不适用"必须附一句理由(比如"离线场景不适用,因为这是纯后台管理功能,不支持离线操作"),不能是偷懒的默认值。

> 产品目标写成"提升用户体验"这种无法量化的话,没有给出基线值和目标值。即使暂时没有数据支撑,也要标 `⚠️ 待确认` 并说明打算怎么补(比如"建议对比历史同类迭代的转化率变化"),不能用模糊形容词代替数字。

> 把"产品设计无明显缺陷"这种需要人工判断的维度,自己打一个"25/25分"给出来——这是在制造虚假精确度,本 skill 只整理证据,最终判断交给评审会。

## 质量检查(生成前自检)

- [ ] 业务流程图的异常分支覆盖了九项清单里确实适用的部分,不适用的写了理由
- [ ] 状态机里每个状态都做了可达性和可退出性检查
- [ ] 字段约束表没有空白的校验规则列
- [ ] 验收标准全部是 Given-When-Then 格式
- [ ] 产品目标及价值至少有一个可量化的目标(或显式标 ⚠️待确认 并说明理由)
- [ ] 非功能需求五类都有结论(适用的写要求,不适用的写理由)
- [ ] 变更历史表已初始化

## 产出写入 Feishu

更新交付组的 PRD链接(本地文件路径或后续同步的飞书文档链接)。本地写 `pm-workspace/requirements/<REQ-ID>/04-prd.md`,内容是 Step 1-10 全部章节。当前阶段更新为 `prd`。

## 与其他 Skill 的关系

| Skill | 关系 |
|---|---|
| `/pm-value` | 上游,要求优先级已确定且非 P3(或用户显式确认继续) |
| `/pm-clarify` | 上游,背景章节引用其「真实需求」结论 |
| `/pm-proto` | 下游,本 skill 的"产品交互总览"只是轻量概览,详细交互规格由 `/pm-proto` 负责 |
```

- [x] **Step 2: RED 基线测试**

派 subagent(不提及 skill),给它 fixture 里"订单数据量级可能上万行"的信息,要求"帮我写一份这个导出功能的 PRD,包含产品目标、业务流程图"。预期它会:(a) 画的流程图只有"点击导出→生成→下载"的理想路径,不会主动识别超时/并发/网络中断等异常分支;(b) 产品目标写成"提升运营效率"这类无法量化的描述,不会给基线值/目标值或标待确认;(c) 不会主动写变更历史表或元信息头。

- [x] **Step 3: GREEN 验证**

派 subagent 明确要求用 `pm-prd` skill,同样输入。确认:
1. 业务流程图包含至少 3 种异常分支(呼应 fixture 的"导出超时/网络断开/并发导出"提示),状态机每个状态都有退出路径,验收标准是 Given-When-Then 格式
2. 产品目标及价值章节给出的目标是四种量化类型之一,如果没有真实基线数据,标注了 `⚠️ 待确认` 而不是编造一个数字
3. 元信息头和变更历史表的结构正确初始化
4. 质量自检清单里"产品设计无明显缺陷"这一项没有被 skill 自己判定为"✅已覆盖"并打分,而是正确标注为需要人工评审确认

如果有任何一项不符合,回到 Step 1 修改,最多 2 轮,仍不过则报告 BLOCKED。

- [x] **Step 4: Commit**

```bash
cd "/Users/mac/vibe coding/产品经理工作agent"
git add .claude/skills/pm-prd/SKILL.md
git commit -m "Add pm-prd skill for product solution design stage"
```

Then update plan doc: mark Task 4's checkboxes `[x]` in `docs/superpowers/plans/2026-10-12-pm-workflow-skills.md`, commit separately: `git commit -m "Mark Task 4 steps complete in plan"`.

---

## Task 5: `/pm-proto` —— 原型设计与交互定义

**Files:**
- Create: `.claude/skills/pm-proto/SKILL.md`

- [x] **Step 1: 写 SKILL.md 草稿**

Create `.claude/skills/pm-proto/SKILL.md`:

```markdown
---
name: pm-proto
description: Use when a PRD-backed requirement needs an interaction specification (page list, IA, component states, usability checklist) before any visual mockup gets built — triggers on phrases like "交互设计" "原型规格" "UI状态" "尼尔森原则自检" "画原型". Produces the interaction spec first; delegates actual HTML prototype generation to the huashu-design skill only after the spec is confirmed.
---

# pm-proto · 原型设计与交互定义

## 触发

**触发词**:交互设计、原型规格、UI 状态、尼尔森原则自检、画原型、交互规格文档
**不触发**:业务逻辑还没定(→ `/pm-prd`)、要直接出 HTML 高保真原型而规格还没写(先走本 skill 第一步)

## 输入要求

### 必须有

- `04-prd.md` 已存在(本 skill 的页面清单和交互逻辑要对应 PRD 里的功能清单和业务流程)

## 执行流程

### Step 0 — 输入面板

检查 `04-prd.md` 是否存在。

### Step 1 — 页面清单 + 信息架构

列出 PRD 功能清单对应的页面,画出页面层级(树状列表)。

### Step 2 — 每个组件/页面的 5 态(UI Stack)

**必须逐一填写,不能只做理想态**:

| 状态 | 要定义什么 |
|---|---|
| 理想态 | 正常数据下的展示 |
| 空态 | 没有数据时显示什么(不是空白页面,要有引导性文案) |
| 错误态 | 出错时的提示文案和恢复路径 |
| 部分态 | 数据部分加载/部分失败时怎么显示 |
| 加载态 | 等待时的反馈形式 |

每个 PRD 里标为"主流程"的页面/组件,这五态必须全部填写;异常流程对应的页面可以只填相关的几态,但要说明跳过的理由。

### Step 3 — 尼尔森 10 大可用性原则自检表

逐条检查交互设计是否违反以下原则(NNGroup 现行措辞):

| 原则 | 自检问题 |
|---|---|
| 系统状态可见性 | 用户任何操作后,是否有明确反馈? |
| 匹配用户心智模型 | 术语和流程是否符合用户已有认知,而非系统内部逻辑? |
| 用户控制与自由 | 是否有退出/撤销路径? |
| 一致性与标准 | 同类操作的交互方式是否统一? |
| 防错优于纠错 | 能否在用户犯错前就阻止,而不是事后提示错误? |
| 识别优于记忆 | 用户需要记住的信息是否最小化? |
| 灵活高效 | 是否对高频操作提供快捷方式? |
| 简洁美学 | 界面是否只保留必要信息? |
| 帮助识别诊断恢复错误 | 错误提示是否说明原因和解决方法? |
| 帮助文档 | 复杂操作是否有可查阅的说明? |

逐条写明"符合"或"需要改进",需要改进的给出具体修改建议,不能空泛写"待优化"。

### Step 4 — WCAG 2.2 关键数值标注

- 正文对比度 ≥ 4.5:1
- 大字号(18pt+)/UI 控件对比度 ≥ 3:1
- 触控目标 ≥ 24×24 CSS px
- 焦点状态必须可见
- 核心操作支持键盘完成(不依赖鼠标)

在交互规格里对涉及文字颜色、按钮尺寸的部分,标注对应数值要求。

### Step 5 — 响应反馈节奏

- 0.1 秒内:无需特殊反馈
- 1-10 秒:需要反馈但不打断(如 loading 动画)
- 超过 10 秒:必须用进度条,且告知预估剩余时间

对应 PRD 里标为"异步/耗时"的操作(如 fixture 里的大数据量导出),标注预期响应时间档位和对应的反馈形式。

### Step 6 — 主题色与语义色

primary / success / warning / danger / info 五个语义色的使用场景说明(不需要给出具体色值,这是设计师的工作,PM 只需定义语义)。

### Step 7 — 质量门

**BLOCKER 判据**:
- 任一主流程组件缺少 5 态中的任一态
- 没有做尼尔森 10 原则自检(或自检表是空的)
- 没有标注任何 WCAG 数值

**PASS 时**,问用户:"`/pm-proto` 交互规格已完成。是否调用 huashu-design 生成 HTML 高保真原型?"

### Step 8 — 委托高保真原型(用户确认后)

如果用户确认,把 `05-interaction.md` 的内容作为上下文,触发 `huashu-design` skill 生成 HTML 原型。本 skill 不实现任何 HTML/CSS 生成逻辑,只负责把交互规格整理成 `huashu-design` 能理解的输入。产出放在 `pm-workspace/requirements/<REQ-ID>/prototype/` 目录。

## 常见设计错误

> 只填了理想态,空态/错误态写"同理想态"或留空——这正是质量门要拦的 BLOCKER,UI Stack 五态存在的意义就是逼着不漏掉非理想情况。

## 质量检查(生成前自检)

- [ ] 主流程组件的 5 态全部填写,没有用"同上"偷懒
- [ ] 尼尔森自检表 10 条全部有具体结论,不是空表格
- [ ] WCAG 数值标注落到了具体的文字/按钮描述上,不是只在文档开头提一句

## 产出写入 Feishu

更新交付组的原型链接。本地写 `05-interaction.md`;若委托 huashu-design 生成原型,产出落 `prototype/` 子目录,链接写回飞书。当前阶段更新为 `proto`。

## 与其他 Skill 的关系

| Skill | 关系 |
|---|---|
| `/pm-prd` | 上游 |
| `huashu-design` | 下游子工具,仅在用户确认后委托,本 skill 不重新实现 HTML 原型生成能力 |
```

- [x] **Step 2: RED 基线测试**

派 subagent(不提及 skill),要求"帮我设计这个导出功能的交互,包含状态和可用性检查"。预期它可能只描述理想态交互,不会系统性填 5 态;可能提到"易用性"但不会逐条过尼尔森 10 原则;大概率不会提具体 WCAG 数值。

- [x] **Step 3: GREEN 验证**

派 subagent 明确要求用 `pm-proto` skill。确认 5 态表格完整、尼尔森 10 条逐一有结论、WCAG 数值标注落到具体元素上。确认它在 Step 7 PASS 后主动问是否委托 huashu-design,而不是自己尝试写 HTML。

- [x] **Step 4: Commit**

```bash
cd "/Users/mac/vibe coding/产品经理工作agent"
git add .claude/skills/pm-proto/SKILL.md
git commit -m "Add pm-proto skill for interaction specification stage"
```

---

## Task 6: `/pm` —— 路由

**Files:**
- Create: `.claude/skills/pm/SKILL.md`

**说明:** 依赖前五个 skill 已存在,最后实现。职责很薄:查状态 + 给下一步建议,不做任何阶段性产出。

- [x] **Step 1: 写 SKILL.md 草稿**

Create `.claude/skills/pm/SKILL.md`:

```markdown
---
name: pm
description: Use when checking the status of the requirement pool as a whole, or looking up which stage a specific requirement has reached and what command to run next — triggers on phrases like "需求池现在什么状态" "这个需求走到哪一步了" "下一步该做什么". Not for performing any stage's actual work — it only reports status and suggests the next command.
---

# pm · 路由

## 触发

**触发词**:需求池现状、这个需求走到哪一步、下一步该做什么、查需求状态
**不触发**:要实际执行某个阶段的工作(直接调对应的 `/pm-collect` `/pm-clarify` `/pm-value` `/pm-prd` `/pm-proto`)

## 执行流程

### 无参数调用

读取 `pm-workspace/config.json` 里配置的飞书多维表格,列出所有记录及其"当前阶段"字段,按阶段分组展示。如果 `config.json` 不存在,提示"还没有任何需求记录,运行 /pm-collect 开始"。

### 带需求 ID 调用

1. 检查 `pm-workspace/requirements/<REQ-ID>/` 目录下存在哪些文件(`01-collect.md` ~ `05-interaction.md` 及 `prototype/`)
2. 读取飞书记录的"当前阶段"字段做交叉验证——如果本地文件存在但飞书阶段字段没更新(或反过来),提示不一致,建议用户确认实际进度
3. 根据存在的最新文件,给出下一步建议指令:

| 已存在的最新文件 | 建议下一步 |
|---|---|
| 无 | `/pm-collect` |
| `01-collect.md` | `/pm-clarify` |
| `02-clarify.md` | `/pm-value` |
| `03-value.md`(非 P3) | `/pm-prd` |
| `03-value.md`(P3) | 提示"该需求定级 P3,通常不继续推进,如需继续运行 /pm-prd 并显式确认" |
| `04-prd.md` | `/pm-proto` |
| `05-interaction.md` | 流程已走完,如需生成原型可运行 `/pm-proto` 的委托步骤 |

## 质量检查(生成前自检)

- [ ] 本地文件状态和飞书阶段字段的不一致情况被检测并提示,不是直接信任某一边
- [ ] 下一步建议和 Task 1-5 里各 skill 实际产出的文件名完全对应,没有拼错文件名

## 与其他 Skill 的关系

本 skill 是其余五个的只读查询层,不修改任何需求记录。
```

- [x] **Step 2: GREEN 验证(路由器逻辑简单,跳过 RED,直接验证产出的建议是否正确)**

用 Bash 在本地手动创建一个 `pm-workspace/requirements/REQ-20261012-999-测试路由/` 目录,放一个空的 `01-collect.md` 和 `02-clarify.md`(不放 `03-value.md`)。派 subagent 要求用 `pm` skill 查询 `REQ-20261012-999-测试路由` 的状态。确认它正确识别出"最新文件是 02-clarify.md",建议下一步是 `/pm-value`。

验证完成后删除这个测试目录:

```bash
cd "/Users/mac/vibe coding/产品经理工作agent"
rm -rf "pm-workspace/requirements/REQ-20261012-999-测试路由"
```

- [x] **Step 3: Commit**

```bash
cd "/Users/mac/vibe coding/产品经理工作agent"
git add .claude/skills/pm/SKILL.md
git commit -m "Add pm router skill for requirement pool status queries"
```

---

## Task 7: 全局同步脚本

**Files:**
- Create: `scripts/install-pm-skills.sh`

**说明:** 本仓库验证通过后(前 6 个 Task 全部 GREEN),用这个脚本把六个 skill 同步到 `~/.claude/skills/`,这样在任何项目目录下都能用。脚本用软链接而不是复制,这样以后在本仓库改 skill 内容,全局也会同步更新,不需要重复同步。

- [ ] **Step 1: 写安装脚本**

Create `scripts/install-pm-skills.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS=(pm-collect pm-clarify pm-value pm-prd pm-proto pm)
TARGET_DIR="$HOME/.claude/skills"

mkdir -p "$TARGET_DIR"

for skill in "${SKILLS[@]}"; do
  src="$REPO_DIR/.claude/skills/$skill"
  dest="$TARGET_DIR/$skill"

  if [ ! -d "$src" ]; then
    echo "跳过 $skill:本仓库里找不到 $src" >&2
    continue
  fi

  if [ -L "$dest" ]; then
    echo "已存在软链接,跳过: $dest"
    continue
  fi

  if [ -e "$dest" ]; then
    echo "警告: $dest 已存在且不是软链接,跳过以避免覆盖。如需替换请先手动删除。" >&2
    continue
  fi

  ln -s "$src" "$dest"
  echo "已链接: $dest -> $src"
done

echo "完成。六个 PM skill 现在可以在任何项目目录下通过 /pm-collect /pm-clarify /pm-value /pm-prd /pm-proto /pm 调用。"
```

- [ ] **Step 2: 赋予执行权限**

```bash
cd "/Users/mac/vibe coding/产品经理工作agent"
chmod +x scripts/install-pm-skills.sh
```

- [ ] **Step 3: 验证脚本(dry-run 到临时目录,不污染真实的 ~/.claude/skills)**

```bash
cd "/Users/mac/vibe coding/产品经理工作agent"
HOME=/tmp/pm-skills-install-test bash scripts/install-pm-skills.sh
ls -la /tmp/pm-skills-install-test/.claude/skills/
rm -rf /tmp/pm-skills-install-test
```

Expected: 输出列出六个 `已链接:` 行,临时目录下能看到六个指向本仓库的软链接。

- [ ] **Step 4: Commit**

```bash
cd "/Users/mac/vibe coding/产品经理工作agent"
git add scripts/install-pm-skills.sh
git commit -m "Add install script to symlink PM skills into global ~/.claude/skills"
```

**此时提示用户:** "六个 skill 已在本仓库验证通过。运行 `./scripts/install-pm-skills.sh` 可以把它们同步到 `~/.claude/skills/`,之后在任何项目目录下都能用 `/pm-collect` 等指令。要现在运行吗?"(这一步需要用户显式确认才执行,因为它会修改 `~/.claude/skills/` 这个全局目录。)

---

## Plan Self-Review

**Spec coverage:** 设计文档 §3 的六个 skill 全部对应 Task 1-6;§4 共享机制(防伪造规则、输入面板、需求 ID、质量门)内联进了每个 skill 而非单独抽成文件,符合调研到的 sdd:pm-* "扁平命名空间、无跨文件引用"惯例;§5 每个阶段的字段/流程/模板/质量门在对应 Task 的 SKILL.md 草稿里都有具体内容,没有占位符;§6 数据结构在 Task 0 的 config.json 模板和各 Task 的"产出写入 Feishu"小节里落地;§7 实施顺序(collect→value→clarify→prd→proto→pm)对应 Task 1-6 的顺序;§8 技术前提已在设计阶段验证,不需要重复任务。

**Placeholder scan:** 检查每个 Task 的 SKILL.md 内容,没有 TBD/TODO/"后续补充"类占位符;唯一的"留空"情况(如 `/pm-proto` 的主题色不给具体色值)是设计上刻意的职责边界(PM 定义语义,设计师定具体值),不是遗漏。

**Type/字段一致性:** 核对了 Task 0 的 `config.json.example` 字段名和 Task 1-5 各 SKILL.md "产出写入 Feishu"小节引用的字段名一致(如 `需求ID` `原始诉求` `真实需求` `RICE综合分` 等,前后拼写统一);核对了 Task 6 路由器引用的文件名(`01-collect.md` ~ `05-interaction.md`)和 Task 1-5 各自"本地写文件"步骤产出的文件名完全对应。

无遗留 gap。

---

**Plan complete and saved to `docs/superpowers/plans/2026-10-12-pm-workflow-skills.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - 我给每个 Task 派一个新的 subagent,Task 之间我做 review,快速迭代

**2. Inline Execution** - 在当前会话里按 Task 顺序执行,批量执行,中间设检查点

**选哪种?**
