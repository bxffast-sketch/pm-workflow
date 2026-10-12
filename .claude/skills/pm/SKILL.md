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
2. 读取飞书记录的"当前阶段"字段做交叉验证——如果本地文件存在但飞书阶段字段没更新(或反过来),提示不一致,建议用户确认实际进度。提示不一致后,仍按本地文件状态继续给出第 3 步的建议(本 skill 只读不写,不会因为不一致而阻塞,但建议文字里要带上"检测到状态不一致,建议先确认"的提示)。
3. "最新文件"按阶段编号判定(01<02<03<04<05 取编号最大的已存在文件),不是按文件修改时间判定——即使更早阶段的文件被重新编辑过,只要更后阶段的文件已存在,仍以后阶段文件为准。根据存在的最新文件,给出下一步建议指令:

| 已存在的最新文件 | 建议下一步 |
|---|---|
| 无 | `/pm-collect` |
| `01-collect.md` | `/pm-clarify` |
| `02-clarify.md` | `/pm-value` |
| `03-value.md`(非 P3) | `/pm-prd` |
| `03-value.md`(P3) | 提示"该需求定级 P3,通常不继续推进,如需继续运行 /pm-prd 并显式确认" |
| `04-prd.md` | `/pm-proto` |
| `05-interaction.md` | 流程已走完,如需生成原型可运行 `/pm-proto` 的委托步骤 |

判断 `03-value.md` 是否为 P3:优先级从 `03-value.md` 文件内容的综合定级结论或对应飞书记录的"优先级"字段读取,两者都能读到时以飞书字段为准(本地文件可能滞后)。

异常处理:如果发现比当前"最新文件"编号更小的某个文件缺失(比如存在 03-value.md 但不存在 02-clarify.md),不要直接按表格给建议,先提示用户"检测到 REQ-ID 的 02-clarify.md 缺失,但更后阶段的文件已存在,流程可能被跳过或文件被误删,建议先确认实际情况",再问用户是否仍要按最新文件给出下一步建议。

## 质量检查(生成前自检)

- [ ] 本地文件状态和飞书阶段字段的不一致情况被检测并提示,不是直接信任某一边
- [ ] 下一步建议和 Task 1-5 里各 skill 实际产出的文件名完全对应,没有拼错文件名

## 与其他 Skill 的关系

本 skill 是其余五个的只读查询层,不修改任何需求记录。
