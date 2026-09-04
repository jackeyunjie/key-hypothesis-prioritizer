# key-hypothesis-prioritizer

> 关键假设排序器 · Rank business hypotheses by prerequisite & fatal risk
>
> An AI-agent Skill that turns a fuzzy business question into a ranked, testable hypothesis list. Pure methodology, zero external dependencies, self-contained (~16 KB). Works in any agent that can load a Skill.

**中文一句话**：把模糊的业务问题拆成带优先级的假设清单——前置假设优先，风险高的优先。

## Core Rule / 核心规则

```text
前置假设优先，风险高的优先。
Validate prerequisite hypotheses first; among comparable ones, validate the highest fatal-risk one first.
```

For early businesses, risk usually decreases in this direction / 早期业务风险通常沿此方向递减：

```text
需求 → 解决方案/产品内核 → 商业模式/单元模型 → 增长 → 壁垒
Demand → Solution/Product Core → Business Model/Unit Economics → Growth → Moat
```

Do not test later-stage hypotheses while earlier fatal assumptions remain unknown, unless the test is nearly free and does not distract the main decision.
/ 前置致命假设未明时，不要测试后置假设——除非测试几乎零成本且不干扰主线决策。

## Workflow / 五步工作流

**1. Locate the stage · 定位阶段**

| Stage | Main question |
|---|---|
| Opportunity pre-judgment | Should we enter this? |
| Demand / 需求 | Does this user/scenario/problem really exist and matter? |
| Solution / product core / 解决方案 | Does this form solve the problem better enough? |
| Business model / 商业模式 | Can one unit make money? |
| Growth / 增长 | Can we acquire and scale repeatably? |
| Moat / 壁垒 | Can the advantage persist? |

**2. Split until testable · 拆到可测试**

Break each broad claim into / 把笼统主张拆成：

```text
用户/对象 + 场景 + 问题 + 解决方案 + 行为信号 + 成立标准
who + scenario + problem + solution + behavior signal + pass criterion
```

Two-sided or multi-role businesses: split by role first.
/ 双边/多角色业务先按角色拆分——买家和分销商即使可能是同一个人，也是不同用户。

**3. Score · 打分（1–5）**

| Dimension | Meaning |
|---|---|
| Prerequisite / 前置性 | If false, later hypotheses become irrelevant |
| Fatality / 致死率 | If false, the project should stop or pivot |
| Uncertainty / 不确定性 | Current evidence is weak or contradictory |
| Testability / 可测试性 | Can get evidence quickly and cheaply |
| Decision leverage / 决策杠杆 | Result changes resource allocation |

```text
priority = prerequisite + fatality + uncertainty + decision leverage - test cost
```

Highest priority is not the most interesting idea; it is the highest prerequisite and fatal-risk uncertainty. Use judgment, not false precision.

**4. Map common wording · 常见说法归层**

| User says | Usually belongs to |
|---|---|
| target users, pain, price sensitivity | Demand |
| product form, core feature, delivery effect, tool adoption | Solution / product core |
| price, CAC, delivery cost, unit economics, LTV | Business model |
| channel, funnel, referral, ROI, ceiling | Growth |
| "which country/channel first" after model works | Growth / channel exploration |

**5. Output · 输出模板**

```markdown
## 关键假设排序
### 1. 当前阶段判断（阶段 / 判断依据）
### 2. 假设池（编号 | 阶段 | 假设 | 为假后果 | 现有证据 | 优先级）
### 3. 验证顺序（先验证哪个 + 为什么）
### 4. 暂不验证（依赖哪个前置假设，现在测浪费资源）
```

## Guardrails / 红线

- Do not let AI speed replace hypothesis splitting. / 不让 AI 的速度取代假设拆分。
- Do not rank low-cost but low-risk tests above fatal hypotheses. / 不把低成本低风险测试排在致死假设之上。
- Do not treat a growth-channel question as urgent before demand, product core, and model risks are understood. / 需求、产品内核、模型风险未明时，不把增长渠道问题当紧急。
- When evidence is thin, prefer disconfirming the highest-risk assumption rather than proving the whole business. / 证据薄时，优先证伪最高风险假设，而非证明整个业务。

## Install / 安装

```bash
# All platforms / 全部平台（Codex, Kimi, Qoder, Trae）
bash install.sh --targets all

# Selected platforms / 指定平台
bash install.sh --targets codex,kimi
```

Same-name rules / 同名规则：identical copies are skipped; different copies are NOT overwritten — use `--force` only after confirming backup and replacement.
/ 同名且一致则跳过；同名但不同则停止，不覆盖——确认备份后才用 `--force`。

## Structure / 目录结构

```text
.
├── README.md
├── install.sh                 # one-click install for 4 platforms / 四端一键安装
├── SHA256SUMS                 # integrity checksums / 完整性校验
├── scripts/skill_publisher.sh # validate / install / package / publish
└── skills/key-hypothesis-prioritizer/
    ├── SKILL.md               # methodology / 方法论本体
    ├── references/stage-map.md # fast layer-mapping / 阶段速查
    └── agents/openai.yaml     # Codex sidecar launcher (optional) / 可选启动配置
```

## Related tools / 相似工具区分

- **pm-prioritization-engine**（RICE/Kano）：ranks *which feature/requirement to build* — 需求排期。
- **This skill**：ranks *which hypothesis to validate first* — 验证顺序。

Different questions: one decides the backlog, the other decides the experiment order.
/ 两者回答不同问题：一个决定先做什么功能，一个决定先验证哪个假设。
