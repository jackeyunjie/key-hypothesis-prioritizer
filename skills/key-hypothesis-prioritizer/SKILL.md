---
name: key-hypothesis-prioritizer
description: Use when a user needs to identify, split, and rank business key hypotheses by stage, dependency, and fatal risk. Trigger on 关键假设、前置假设优先、风险高优先、假设排序、五步法拆假设、致死率最高假设、业务成败判断、需求/解决方案/商业模式/增长/壁垒拆解, or when deciding what to validate first.
---

# Key Hypothesis Prioritizer

Use this skill to turn a fuzzy business question into a ranked hypothesis list. The core rule is: validate prerequisite hypotheses first, and among comparable hypotheses validate the highest fatal-risk one first.

## Read Order

Read in this order:

1. `SKILL.md`
2. `references/stage-map.md`

Use the reference when the user mixes阶段、假设层级、会议类型、业务问题 and you need a faster classification anchor.

## Core Rule

```
前置假设优先，风险高的优先。
```

For early businesses, risk usually decreases in this direction:

```
需求 → 解决方案/产品内核 → 商业模式/单元模型 → 增长 → 壁垒
```

Do not test later-stage hypotheses while earlier fatal assumptions remain unknown, unless the test is nearly free and does not distract the main decision.

## Workflow

### 1. Locate The Stage

| Stage | Main question | Typical hypotheses |
|---|---|---|
| Opportunity pre-judgment | Should we enter this? | industry trend, market timing, resources, unfair advantage |
| Demand | Does this user/scenario/problem really exist and matter? | user segment, pain intensity, frequency, willingness to switch |
| Solution / product core | Does this form solve the problem better enough? | product form, core feature, packaging, delivery effect, repeat use |
| Business model | Can one unit make money? | price band, CAC, delivery cost, gross margin, LTV, payback period |
| Growth | Can we acquire and scale repeatably? | channel, content hook, funnel, referral, incentive, ROI, ceiling |
| Moat | Can the advantage persist? | brand, data, supply chain, network, switching cost, organization |

### 2. Split The Problem Until It Is Testable

Break each broad claim into:

```
用户/对象 + 场景 + 问题 + 解决方案 + 行为信号 + 成立标准
```

For two-sided or multi-role businesses, split by role first. A buyer and a distributor are different users even if they may be the same person.

For old businesses, do not jump to "new product or not." First diagnose with business formula: which indicator is declining, and is the decline caused by demand, product aging, model failure, or channel blockage?

### 3. Score Hypotheses

Use a simple 1-5 score. The highest priority is not the most interesting idea; it is the highest prerequisite and fatal-risk uncertainty.

| Dimension | Meaning |
|---|---|
| Prerequisite | If false, later hypotheses become irrelevant |
| Fatality | If false, the business or project should stop or pivot |
| Uncertainty | Current evidence is weak or contradictory |
| Testability | Can get evidence quickly and cheaply |
| Decision leverage | Result changes resource allocation |

Priority heuristic:

```
priority = prerequisite + fatality + uncertainty + decision leverage - test cost
```

Use judgment, not false precision.

### 4. Map Common Hypotheses

| User wording | Usually belongs to |
|---|---|
| target users, scenarios, pain, price sensitivity | Demand |
| product form, core feature, packaging, course quality, tool adoption | Solution / product core |
| price, product bundle, delivery cost, unit economics, LTV | Business model |
| content channel, paid traffic, referral, discount, conversion hook | Growth |
| "which country/channel first" after product/model works | Growth/channel exploration |

Pricing needs context:

- Price band sensitivity is often demand.
- Product package and value framing are solution/business model.
- Exact price and unit economics are business model.
- Coupons, discounts, promotions are growth.

## Output Template

```markdown
## 关键假设排序

### 1. 当前阶段判断
- 阶段：
- 判断依据：

### 2. 假设池
| 编号 | 阶段 | 假设 | 为假后果 | 现有证据 | 优先级 |
|---|---|---|---|---|---|
| H1 |  |  |  |  |  |

### 3. 验证顺序
1. H__：先验证，因为：
2. H__：在 ___ 通过后验证，因为：

### 4. 暂不验证
- H__：依赖前置假设 ___，现在测会浪费资源。
```

## Guardrails

- Do not let AI speed replace hypothesis splitting.
- Do not rank low-cost but low-risk tests above fatal hypotheses.
- Do not treat a growth-channel question as urgent before demand, product core, and model risks are understood.
- When evidence is thin, prefer disconfirming the highest-risk assumption rather than proving the whole business.

## Sidecar Agent

This skill also includes `agents/openai.yaml`.

Use it as:

- a display/launcher config for a dedicated “关键假设排序” entry
- a short default prompt for jumping into this workflow faster

Do not treat the sidecar as extra methodology. The method is defined in `SKILL.md`; the yaml only packages a cleaner entry point.
