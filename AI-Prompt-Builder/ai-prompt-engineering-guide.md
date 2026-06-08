# AI Prompt Engineering for Software Development Teams
### A Practical Guide for Developers

---

## Table of Contents

1. [Introduction](#introduction)
2. [The Anatomy of an Excellent Prompt](#the-anatomy-of-an-excellent-prompt)
3. [Personas](#1-personas)
4. [Context](#2-context)
5. [Giving the AI Permission to Fail](#3-giving-the-ai-permission-to-fail)
6. [Formatting Instructions](#4-formatting-instructions)
7. [Chain of Thought Prompting](#5-chain-of-thought-prompting)
8. [Extended Thinking](#6-extended-thinking)
9. [Complete Prompt Examples](#complete-prompt-examples)
10. [Reducing Cost and Improving ROI](#reducing-cost-and-improving-roi)

---

## Introduction

AI coding assistants are only as good as the instructions you give them. A vague prompt produces vague results. A well-engineered prompt produces production-quality output, reduces iterations, and — critically — reduces the token cost of getting to a usable answer.

This guide covers the core techniques every developer on your team should internalize:

- How to frame the AI's **persona** so it responds at the right level
- How to supply the right **context** so it doesn't guess
- How to explicitly **permit failure** so it doesn't hallucinate
- How to specify **formatting** so output drops cleanly into your workflow
- How to use **chain of thought** for complex reasoning tasks
- How to trigger **extended thinking** for architecture-level problems
- How to **reduce cost** without sacrificing quality

---

## The Anatomy of an Excellent Prompt

Every high-quality prompt has five layers. Think of them as a checklist:

```
[ ] Persona      — Who is the AI playing?
[ ] Context      — What does it need to know?
[ ] Task         — What exactly do you want?
[ ] Permission   — What should it do if it doesn't know?
[ ] Format       — How should the output be structured?
```

Weak prompts skip most of these. Strong prompts include all five.

---

## 1. Personas

### What it is

A persona tells the AI what role, experience level, and mindset to adopt. It primes the model to respond with the right vocabulary, depth, and assumptions.

### Why it matters

Without a persona, the model defaults to a generic helpful assistant. With a persona, you get responses calibrated to your team's stack, seniority level, and standards.

### Patterns

| Goal | Persona Phrasing |
|---|---|
| Production-grade code | "You are a senior backend engineer with 10+ years in distributed systems." |
| Security review | "You are an application security engineer specializing in OWASP Top 10 vulnerabilities." |
| Code explanation for juniors | "You are a patient staff engineer who mentors junior developers." |
| Architecture decisions | "You are a principal engineer evaluating trade-offs for a high-scale SaaS platform." |
| Code review | "You are a meticulous senior engineer conducting a production readiness review." |

### Examples

**Weak:**
```
Explain this code to me.
```

**Strong:**
```
You are a senior software engineer who specializes in Python and has deep experience 
with async programming patterns. Explain the following code to a mid-level developer 
who understands Python basics but hasn't worked with asyncio before.
```

**Weak:**
```
Review this SQL query.
```

**Strong:**
```
You are a database performance engineer with expertise in PostgreSQL query optimization 
and execution plans. Review the following query for performance issues, assuming this 
table has 50 million rows and is hit 500 times per second.
```

### Tips

- Match the persona's seniority to the complexity of the task.
- Include the specific technology stack in the persona when it matters.
- For teaching/explanation tasks, define the *audience* level, not just the AI's level.

---

## 2. Context

### What it is

Context is everything the AI needs to know that it cannot infer from your question alone: your stack, constraints, existing patterns, team conventions, and the "why" behind the request.

### Why it matters

Without context, the AI makes assumptions. Those assumptions are often wrong. You end up with solutions that technically answer your question but don't fit your codebase, architecture, or constraints.

### What to include

- **Tech stack**: Language, framework, version, cloud provider
- **Constraints**: Performance requirements, security policies, existing patterns
- **Existing code**: Relevant functions, interfaces, or data models
- **The "why"**: Business or technical reason behind the request
- **What you've already tried**: Avoid getting suggestions you've already ruled out
- **Definition of done**: What does success look like?

### Examples

**Weak:**
```
Write a function to cache API responses.
```

**Strong:**
```
We are building a Node.js 20 / Express 5 API that calls three downstream services 
(user profile, inventory, pricing). The app runs in AWS Lambda with 512MB memory 
and a 3-second timeout budget. We are already using Redis (ioredis v5) for session 
storage. We cannot add new infrastructure dependencies.

Write a middleware function that caches downstream API responses in Redis with a 
configurable TTL per route. The cache key should include the user's tenant ID to 
prevent cross-tenant data leakage.
```

**Weak:**
```
Help me fix this bug.
[pastes 300 lines of code]
```

**Strong:**
```
Stack: React 18, TypeScript 5, React Query v5, Axios.

The following component intermittently throws "Cannot read properties of undefined 
reading 'items'" on the second render cycle only. This does NOT happen in local dev 
but consistently reproduces in our staging environment which uses SSR (Next.js 14).

Here is the component and the relevant React Query hook. The API contract guarantees 
that `items` is always present when `status === 'success'`, but we are seeing this 
crash with status still in loading state.

[code]
```

### Tips

- Paste relevant code snippets rather than describing them.
- Specify versions. `"We use React"` and `"We use React 18.3 with the new compiler"` produce very different answers.
- State constraints as hard rules: "We cannot use X" or "This must run under Y ms."

---

## 3. Giving the AI Permission to Fail

### What it is

Explicitly instructing the AI to admit uncertainty, ask clarifying questions, or say "I don't know" rather than inventing a plausible-sounding but incorrect answer.

### Why it matters

Language models are trained to be helpful and to produce fluent, confident-sounding text. Without explicit instruction, they will fill gaps in their knowledge with hallucinated details — wrong library names, non-existent API methods, fabricated version numbers. In software development, this can introduce subtle bugs that take hours to debug.

### The core techniques

**1. Explicit uncertainty permission**
```
If you are not certain about any part of this answer, say so explicitly. 
Do not fabricate API names, method signatures, or version details.
```

**2. Confidence signaling**
```
For each recommendation, indicate your confidence level: 
[HIGH] I am certain this is correct, [MEDIUM] this is likely correct but verify, 
[LOW] this is my best guess and needs validation.
```

**3. Clarification requests**
```
If my request is ambiguous or you need more information to give a useful answer, 
ask me up to three clarifying questions before proceeding.
```

**4. Scope limiting**
```
Only answer based on the code I have provided. Do not assume the existence 
of functions, variables, or modules I have not shown you.
```

**5. Fallback instruction**
```
If you don't know the correct answer for our specific stack, provide the 
general pattern and tell me what I need to look up to implement it correctly.
```

### Examples

**Without permission to fail:**
```
What is the method to enable HTTP/2 push in Express.js?
```
*(High risk: the AI may confidently describe a method that doesn't exist or was removed.)*

**With permission to fail:**
```
What is the method to enable HTTP/2 push in Express.js 5? 

If this feature has been removed, deprecated, or was never part of Express core, 
tell me that directly. Do not describe an approach that doesn't exist. If you're 
uncertain, say so and point me to where I can verify.
```

### Tips

- Add permission-to-fail language to any prompt involving specific APIs, version-specific behavior, or recent library releases.
- For code generation tasks, add: *"If a step requires a library you are not confident about, note it as 'needs verification' rather than guessing the import."*
- Treat high-confidence AI output on niche or recent topics with the same skepticism you'd apply to a Stack Overflow answer from 2019.

---

## 4. Formatting Instructions

### What it is

Explicit instructions that define the structure, length, style, and delivery format of the AI's response.

### Why it matters

Without formatting instructions, the AI picks a format it thinks is appropriate. That format is often too verbose, insufficiently structured for your workflow, or mixed in ways that are hard to parse programmatically. Clear formatting instructions make output drop directly into your code, tickets, or docs.

### Common formatting patterns for developers

**Code-first responses:**
```
Provide the complete code first, then the explanation. 
Do not interleave explanation with code.
```

**Structured sections:**
```
Structure your response as:
1. Summary (2-3 sentences)
2. Code (complete, runnable)
3. Usage example
4. Edge cases and limitations
```

**Diff format:**
```
Show changes as a diff. Only include the lines that change, with 5 lines 
of surrounding context. Do not rewrite files I didn't ask you to change.
```

**Markdown for docs:**
```
Format the output as Markdown suitable for a GitHub README. 
Use ## for section headers, fenced code blocks with language tags, 
and a table for configuration options.
```

**Minimal output:**
```
Return only the code. No explanation, no preamble, no sign-off. 
I will ask follow-up questions if I need clarification.
```

**JSON for programmatic use:**
```
Return your analysis as a JSON array. Each item should have:
{ "issue": string, "severity": "high"|"medium"|"low", "line": number, "fix": string }
Do not include any text outside the JSON array.
```

### Tips

- If you're piping output into a tool, use the "return only X" pattern aggressively.
- For code review tasks, the JSON format for issues integrates cleanly into scripts or ticket creation.
- Specify language tags in code blocks: the AI won't always choose the right one automatically.

---

## 5. Chain of Thought Prompting

### What it is

Chain of thought (CoT) prompting instructs the AI to reason step by step before arriving at an answer. Instead of jumping to a conclusion, it works through the problem out loud — surfacing assumptions, intermediate steps, and decision points.

### Why it matters

Complex engineering problems — debugging, architecture choices, algorithm design, performance analysis — benefit enormously from explicit reasoning. When the AI "shows its work," you can catch flawed assumptions early, understand the trade-offs it considered, and trust the conclusion more.

Without CoT, the model pattern-matches to a solution. With CoT, it *reasons* to one.

### Trigger phrases

```
Think through this step by step before giving your final answer.
```
```
Before writing any code, reason through the approach: what are the trade-offs, 
what edge cases exist, and what could go wrong?
```
```
Work through this problem out loud. Show your reasoning at each step.
```
```
First, analyze the problem. Then, consider at least two approaches. 
Then, recommend one with justification.
```

### When to use it

| Situation | Use CoT? |
|---|---|
| Simple boilerplate generation | No |
| Bug that defies obvious explanation | Yes |
| Architecture decision with trade-offs | Yes |
| Explaining a complex algorithm | Yes |
| Performance optimization | Yes |
| Writing a standard CRUD endpoint | No |
| Evaluating a security vulnerability | Yes |
| Renaming a variable | No |

### Example

**Without CoT:**
```
Should we use a message queue or direct HTTP calls for communication 
between our order service and inventory service?
```

**With CoT:**
```
You are a principal engineer designing a microservices architecture for an 
e-commerce platform. Our order service needs to communicate with our inventory 
service to decrement stock when an order is placed.

Before recommending an approach, think through this step by step:
- What are the failure modes of each approach?
- How does each handle the case where the inventory service is temporarily unavailable?
- What are the consistency trade-offs?
- What is the operational complexity of each?

After your analysis, recommend one approach for our context: 
we have 10,000 orders/day peak, a small DevOps team, and we are already running 
AWS SQS for another workflow.
```

### Structured CoT pattern

For complex tasks, you can scaffold the reasoning explicitly:

```
Answer in this order:
1. UNDERSTAND: Restate the problem in your own words to confirm you understand it.
2. ANALYZE: Identify the key constraints, unknowns, and risks.
3. OPTIONS: List 2-3 possible approaches with their trade-offs.
4. RECOMMEND: Choose one approach and justify it against the constraints.
5. IMPLEMENTATION: Provide the code or steps to implement your recommendation.
```

---

## 6. Extended Thinking

### What it is

Extended thinking is a mode available in frontier AI models (such as Claude's extended thinking mode) where the model is explicitly given a larger reasoning budget — more internal computation — before producing its response. It is distinct from chain of thought in that the model's reasoning happens internally before the visible response, rather than being shown inline.

From a prompting perspective, you activate extended thinking either through API parameters (e.g., `thinking: { type: "enabled", budget_tokens: 10000 }` in the Anthropic API) or by crafting prompts that signal the task requires deep, careful reasoning.

### Why it matters

For routine tasks, standard responses are fast, cheap, and sufficient. But for genuinely hard problems — complex debugging, architectural design, security analysis, algorithm design — the additional reasoning budget produces qualitatively better answers: fewer logical gaps, more thorough trade-off analysis, and edge cases you would have otherwise missed.

### When to use extended thinking

Use it for problems where a human expert would need to sit and think for 20+ minutes:

- System design and architecture decisions
- Complex bug investigations with non-obvious root causes
- Security threat modeling
- Performance bottleneck analysis across multiple system layers
- Evaluating a major library migration or refactor
- Algorithm design for non-standard problems
- Compliance and audit risk analysis in code

Do **not** use it for:
- Boilerplate generation
- Simple transformations
- Renaming, formatting, or style fixes
- Standard CRUD implementations
- Anything where speed matters more than depth

### Prompt patterns that trigger deep reasoning

Even without explicit API-level extended thinking, these prompt patterns signal to the model that depth is required:

```
This is a complex problem. Take as much space as you need to reason through it 
carefully before giving your final recommendation.
```
```
Do not rush to an answer. I would rather have a thorough, well-reasoned analysis 
than a fast response.
```
```
Consider this from multiple angles before concluding. What would a skeptical 
reviewer challenge in each approach?
```
```
This decision will be hard to reverse. Treat it accordingly — analyze it with 
the rigor you would apply to a production incident post-mortem.
```

### API-level extended thinking (Anthropic)

When using the Anthropic API directly, you can enable extended thinking programmatically:

```javascript
const response = await anthropic.messages.create({
  model: "claude-opus-4-5",
  max_tokens: 16000,
  thinking: {
    type: "enabled",
    budget_tokens: 10000   // How much reasoning budget to allocate
  },
  messages: [{
    role: "user",
    content: yourComplexPrompt
  }]
});
```

The response will include a `thinking` block (the model's internal reasoning) and a `text` block (the final answer). You can surface the thinking block in developer tools for transparency.

### Extended thinking prompt example

```
You are a principal engineer at a fintech company. We are considering migrating 
our authentication system from session-based auth (Express + Redis sessions) to 
JWT-based auth (short-lived access tokens + refresh tokens stored in httpOnly cookies).

This decision affects 12 microservices, 2 million active users, and must be 
completed with zero downtime.

This is a complex, high-stakes architectural decision. Take as much space as you 
need to reason through it carefully. Do not rush to a recommendation.

Analyze:
1. Security implications of each approach in our context
2. The migration path — how do we run both systems in parallel during cutover?
3. Operational complexity: what breaks when a JWT signing key needs rotation?
4. Failure modes: what happens if the refresh token store goes down?
5. The specific risks of doing this across 12 services vs. a monolith

After thorough analysis, give a concrete recommendation with implementation milestones.
If there are aspects of this decision you cannot evaluate without more information, 
list them explicitly rather than assuming.
```

---

## Complete Prompt Examples

The following are full, production-quality prompt examples that use all five techniques together.

---

### Example 1: Complex Bug Investigation

```
PERSONA:
You are a senior Node.js engineer with deep expertise in the V8 event loop, 
async/await, and memory profiling. You specialize in diagnosing production 
issues that don't reproduce locally.

CONTEXT:
Stack: Node.js 20.11, Express 4.18, Prisma 5.x, PostgreSQL 15, deployed on 
AWS ECS Fargate (1 vCPU, 2GB RAM). 

We are seeing a memory leak in production that causes containers to restart 
every 6-8 hours. The leak does not appear in local development or staging. 
It correlates with high traffic (500+ req/min) but we cannot reproduce it 
under load testing.

Here is our middleware stack and the two request handlers that were deployed 
just before the leak appeared:

[paste relevant code here]

We have already ruled out:
- Prisma connection pool exhaustion (pool metrics are stable)
- Log accumulation (we've verified log streaming is working)
- Third-party SDK memory issues (we disabled all third-party SDKs and the 
  leak persisted)

TASK:
Diagnose the most likely cause of the memory leak. Think through this step 
by step — reason about each code path, identify closure captures, event 
listener registrations, and any async patterns that could accumulate state.

PERMISSION TO FAIL:
If you cannot identify the root cause from the code alone, tell me exactly 
what diagnostic data you need (heap snapshots, specific metrics, additional 
code paths) and why. Do not speculate without labeling your speculation as such.

FORMAT:
1. Root cause hypothesis (most likely → least likely, with reasoning)
2. Evidence from the code supporting each hypothesis  
3. Diagnostic steps to confirm the root cause
4. Fix for the most likely cause
5. Any code patterns to refactor regardless of root cause
```

---

### Example 2: Architecture Design with Extended Thinking

```
PERSONA:
You are a principal engineer with experience designing data pipelines at scale. 
You have built systems processing millions of events per day on AWS and have 
strong opinions about operational simplicity vs. technical sophistication.

CONTEXT:
We are a 12-person startup. Our product is a B2B SaaS analytics platform. 
We need to build an event ingestion pipeline that:
- Receives 50,000–200,000 events/hour (spiky, not constant)
- Stores raw events for 90-day replay capability
- Powers real-time dashboard aggregations (< 5 second latency)
- Must be maintained by a team of 3 backend engineers who are not data engineers
- Budget: under $2,000/month for this component at peak load
- AWS is our cloud provider; we already use RDS (Postgres), S3, and Lambda

TASK:
Design the event ingestion and processing architecture for these requirements.

This is a non-trivial architectural decision that we will live with for 2-3 years. 
Take as much space as you need to reason through it carefully. Consider at least 
three different architectural patterns before recommending one.

For each pattern, evaluate:
- Cost at our stated scale
- Operational burden on a small team
- Ability to replay historical events
- Latency characteristics for real-time dashboards
- What happens when volume spikes 5x unexpectedly

PERMISSION TO FAIL:
If my requirements contain contradictions or underspecified constraints that would 
materially affect your recommendation, identify them before proceeding. If your 
cost estimates are rough approximations, say so.

FORMAT:
1. REQUIREMENTS VALIDATION — flag any conflicts or ambiguities
2. ARCHITECTURAL OPTIONS — 3 options with trade-off analysis
3. RECOMMENDATION — one architecture with justification
4. IMPLEMENTATION ROADMAP — phased rollout in 3 milestones
5. RISKS AND MITIGATIONS — top 3 risks with specific mitigations
6. OPEN QUESTIONS — what you'd need to know to sharpen the recommendation
```

---

### Example 3: Security Code Review

```
PERSONA:
You are an application security engineer specializing in web application vulnerabilities, 
OWASP Top 10, and secure coding patterns for Node.js/TypeScript APIs. You conduct 
reviews with the mindset of an adversarial attacker, not a defensive developer.

CONTEXT:
This is a REST API endpoint that handles user authentication and returns a JWT. 
It is exposed to the public internet. Our users include enterprise customers with 
SOC 2 compliance requirements. We are preparing for a third-party security audit 
in 6 weeks.

[paste authentication code]

TASK:
Conduct a security review of this code. Think through each vulnerability class 
systematically before summarizing findings. Reason about how an attacker would 
approach this endpoint.

Consider at minimum:
- Injection vulnerabilities (SQL, NoSQL, command)
- Authentication and session management flaws
- Sensitive data exposure
- Rate limiting and brute force susceptibility
- Timing attacks on credential comparison
- JWT configuration and secret management
- Error message information leakage
- Dependency vulnerabilities in the libraries used

PERMISSION TO FAIL:
If you identify a potential vulnerability but cannot confirm it without seeing 
additional code (e.g., the ORM configuration, middleware stack, environment 
variable handling), flag it as "suspected — needs investigation" with specific 
instructions for what to check. Do not mark something as safe if you haven't 
seen the relevant code.

FORMAT:
Return findings as a structured list:

**[CRITICAL | HIGH | MEDIUM | LOW | INFO]** — Vulnerability name  
*Location:* function name / line reference  
*Description:* What the vulnerability is  
*Attack scenario:* How an attacker would exploit it  
*Remediation:* Specific code fix  

End with a summary section: overall security posture assessment and top 3 
priority fixes before the audit.
```

---

### Example 4: Code Explanation for Team Knowledge Transfer

```
PERSONA:
You are a staff engineer and technical educator who excels at making complex 
systems understandable. You explain things using concrete analogies and always 
connect abstract concepts to practical consequences.

CONTEXT:
I am preparing a knowledge transfer document for mid-level developers on my team 
(3-5 years experience, strong in application code, limited exposure to distributed 
systems concepts). They will be maintaining the following service after I move to 
a new role.

[paste complex code]

TASK:
Explain this code so that a mid-level developer could:
1. Understand what it does and why it exists
2. Safely make changes to it
3. Debug it when something goes wrong
4. Know what questions to ask if they're unsure

Think through the explanation step by step — start with the big picture, then 
zoom into the non-obvious parts. Don't explain things that are obvious to a 
mid-level developer; focus your attention on the parts that require domain 
knowledge or non-obvious reasoning.

PERMISSION TO FAIL:
If there are parts of the code whose purpose or behavior is genuinely unclear 
(e.g., undocumented magic values, patterns that are unusual or potentially buggy), 
flag them explicitly rather than inventing a confident explanation. Those flags 
are valuable for the knowledge transfer document.

FORMAT:
## Overview
[What this code does in 3-5 sentences]

## Why it exists
[Business or technical context]

## How it works
[Walk through the key logic — use numbered steps for sequential flows]

## The non-obvious parts
[Explain anything that would confuse a mid-level developer]

## How to safely change it
[What to watch out for, what tests to run, what could break]

## Danger zones
[Parts that are fragile, have known issues, or need a senior engineer's eyes]
```

---

## Reducing Cost and Improving ROI

Token cost is real. At scale — hundreds of developers, CI pipelines, automated reviews — poorly engineered prompts burn significant budget. More importantly, expensive prompts often produce worse results than well-designed cheaper ones.

### Understanding what drives cost

Cost is driven by:
1. **Input tokens** — everything you send to the model (system prompt + conversation history + your prompt)
2. **Output tokens** — everything the model returns
3. **Model tier** — frontier models (e.g., Claude Opus) cost significantly more than mid-tier (e.g., Claude Sonnet) or fast models (e.g., Claude Haiku)

Output tokens are typically more expensive than input tokens. Verbose responses = higher cost.

---

### Strategy 1: Match model tier to task complexity

Not every task needs a frontier model. Route tasks to the right model:

| Task | Recommended tier |
|---|---|
| Boilerplate generation, renaming, formatting | Fast/cheap model (e.g., Haiku) |
| Standard feature implementation, unit tests | Mid-tier (e.g., Sonnet) |
| Architecture design, complex debugging, security review | Frontier (e.g., Opus) |
| Code explanation, documentation | Mid-tier |
| CI-automated tasks (linting, PR summaries) | Fast/cheap model |

**Cost impact:** Routing a task from a frontier model to a fast model can reduce cost by 10-50x with no quality loss for simple tasks.

---

### Strategy 2: Be specific to reduce output length

Verbose prompts that accept verbose responses are expensive. Precision cuts both sides.

**Expensive (generates long, unfocused output):**
```
Tell me about error handling in our API.
```

**Cheaper (scoped output, focused answer):**
```
List the top 3 error handling gaps in the following Express middleware. 
For each: one sentence describing the gap, one code snippet showing the fix. 
No other output.
```

**Why it's cheaper:** The scoped version generates 80% fewer output tokens and produces a more actionable result.

---

### Strategy 3: Use system prompts for repeated context

If you are building a tool or automation that calls the AI repeatedly, don't repeat your context in every user message. Put stable context in the system prompt — it can be cached.

**Expensive pattern (context repeated in every call):**
```javascript
// Every API call includes this in the user message
const userMessage = `
  We use TypeScript 5, Express 5, Prisma 5, PostgreSQL 15, deployed on AWS ECS.
  Our coding standards require: JSDoc on all public functions, error handling via 
  a Result type, no raw SQL...
  
  Now: ${actualUserRequest}
`;
```

**Cheaper pattern (context in system prompt, cached):**
```javascript
const systemPrompt = `
  You are a senior engineer working in our codebase.
  Stack: TypeScript 5, Express 5, Prisma 5, PostgreSQL 15, AWS ECS.
  Standards: JSDoc on all public functions, Result type for errors, no raw SQL.
`;

// User messages stay lean
const userMessage = actualUserRequest;
```

**Cost impact:** Anthropic's prompt caching can reduce repeated context costs by up to 90% for high-frequency use cases.

---

### Strategy 4: Ask for the minimum viable output

A common mistake: asking for a full explanation when you only need the code.

**Over-generating (expensive):**
```
Refactor this function to use async/await.
```
*(Model will often explain what it changed, why, and add caveats.)*

**Lean output (cheap):**
```
Refactor this function to use async/await. Return only the refactored code. 
No explanation.
```

**When to use:** Automated pipelines, CI tasks, any case where you're processing the output programmatically.

**When NOT to use:** Learning contexts, code review, anything where understanding the reasoning matters.

---

### Strategy 5: Use few-shot examples instead of long instructions

Long instruction sets that try to describe output format in prose are both expensive (more input tokens) and unreliable. A short example is cheaper and more effective.

**Expensive instruction approach:**
```
Return your findings as a list. Each finding should have a severity level 
(which should be one of: critical, high, medium, low, or informational). 
Include the line number where the issue appears. Describe the issue in plain 
language. Then provide a suggested fix. Separate each finding with a blank line...
[continues for 8 more sentences]
```

**Cheaper few-shot approach:**
```
Return findings in this format (one per issue, no other text):

SEVERITY | LINE | ISSUE | FIX
HIGH | 42 | SQL query built with string concatenation | Use parameterized query: db.query(sql, [params])
MEDIUM | 87 | Password logged in error handler | Remove req.body from error log

Now analyze:
[code]
```

---

### Strategy 6: Break compound tasks into targeted calls

One expensive mega-prompt that does five things is usually worse (in quality and cost) than five targeted prompts.

**Expensive mega-prompt:**
```
Review this code for bugs, security issues, performance problems, style violations, 
and suggest refactoring opportunities. Also write unit tests for it and update 
the README.
```

**Cheaper targeted approach:**

```
# Call 1 — fast model
Find syntax errors and obvious bugs in this code. Return line numbers only.

# Call 2 — mid-tier model  
Review this code for security vulnerabilities. Return structured findings only.

# Call 3 — mid-tier model
Write unit tests for the public API of this function. No explanation.

# Call 4 — fast model
Update the README's "Usage" section to reflect this new function signature.
```

**Why this is better:** Each call is scoped, uses the appropriate model tier, and produces focused output. Total cost is often lower than one sprawling prompt, and the results are more actionable.

---

### Strategy 7: Conversation management for iterative tasks

In long iterative sessions (e.g., working through a complex refactor), conversation history grows and every message re-sends the full history. Prune aggressively.

**Expensive (default behavior):**
Long conversations where every message costs tokens for the full history.

**Cheaper:**
- Summarize resolved threads: *"We've decided to use JWT. Proceed assuming that decision is final."*
- Start fresh conversations for new subtasks rather than extending old ones
- Use the model to generate a concise context summary you can paste into a new conversation

---

### Cost optimization quick reference

| Technique | Cost Impact | Quality Impact |
|---|---|---|
| Route simple tasks to fast/cheap models | Very High ↓ | Neutral |
| Scope output format explicitly | High ↓ | Neutral or better |
| System prompt caching for repeated context | Very High ↓ (at scale) | Neutral |
| "No explanation, code only" for automation | High ↓ | Neutral for automation |
| Few-shot format examples vs. prose instructions | Medium ↓ | Neutral or better |
| Break compound tasks into targeted calls | Medium ↓ | Better |
| Prune conversation history | Medium ↓ (at scale) | Neutral |
| Extended thinking only for hard problems | Medium ↓ | Better on hard problems |

---

## Summary

The highest-leverage habits for your team:

1. **Always assign a persona** — it takes 10 seconds and meaningfully improves output quality.
2. **Paste context, don't describe it** — show code, not summaries of code.
3. **Grant permission to fail** on any prompt involving specific APIs or recent library versions.
4. **Specify output format** as a default habit — your future self (and your pipelines) will thank you.
5. **Use chain of thought** whenever you catch yourself wanting to ask follow-up questions — ask them up front.
6. **Reserve extended thinking** for decisions you'll live with for more than a quarter.
7. **Right-size your model** — most daily development tasks do not require a frontier model.
8. **Scope your outputs** — verbosity costs money and often reduces clarity.

Good prompting is a skill that compounds. The team members who invest in it now will be dramatically more productive as AI capabilities continue to improve.

---

*Last updated: June 2026*
*Maintained by: [Your team's designated AI integration lead]*
