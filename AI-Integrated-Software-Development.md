# AI Prompt Engineering for Software Development Teams
### A Practical Guide for C# MVC Developers

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

All examples in this guide use our stack: **C#, ASP.NET Core MVC, Entity Framework Core, SQL Server, and Azure**.

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

A persona tells the AI what role, experience level, and mindset to adopt. It primes the model to respond with the right vocabulary, depth, and assumptions about your stack.

### Why it matters

Without a persona, the model defaults to a generic helpful assistant and may produce answers suited for a different stack (Node.js, Python, etc.). With a persona anchored to .NET and Microsoft tooling, you get responses that match your team's conventions, NuGet ecosystem, and Azure environment.

### Patterns

| Goal | Persona Phrasing |
|---|---|
| Production-grade C# code | "You are a senior .NET engineer with 10+ years building enterprise ASP.NET Core MVC applications." |
| Security review | "You are an application security engineer specializing in OWASP Top 10 vulnerabilities in ASP.NET Core web apps." |
| Code explanation for juniors | "You are a patient senior .NET developer who mentors junior C# developers." |
| Architecture decisions | "You are a principal engineer evaluating trade-offs for a high-traffic ASP.NET Core SaaS platform hosted on Azure." |
| Code review | "You are a meticulous senior .NET engineer conducting a production readiness review." |
| EF Core / data layer | "You are a senior .NET engineer with deep expertise in Entity Framework Core, SQL Server query optimization, and EF migration management." |
| Azure/DevOps | "You are a .NET-focused Azure solutions architect experienced with App Service, Azure SQL, and Azure DevOps pipelines." |

### Examples

**Weak:**
```
Explain this code to me.
```

**Strong:**
```
You are a senior .NET engineer with deep experience in ASP.NET Core MVC and 
dependency injection patterns. Explain the following C# service class to a 
mid-level developer who understands C# basics but has not worked with the 
built-in DI container or the options pattern before.
```

**Weak:**
```
Review this SQL query.
```

**Strong:**
```
You are a senior .NET engineer with expertise in Entity Framework Core 8 and 
SQL Server query optimization. Review the following LINQ query and its generated 
SQL for performance issues, assuming the Orders table has 20 million rows and 
this query runs on every page load for authenticated users.
```

### Tips

- Always anchor the persona to .NET / C# / ASP.NET Core — don't leave it generic or you may get Python or Node examples.
- Include the specific EF Core version when asking about data access patterns — behavior changed significantly between EF Core 6, 7, and 8.
- For teaching/explanation tasks, define the *audience* level, not just the AI's level.

---

## 2. Context

### What it is

Context is everything the AI needs to know that it cannot infer from your question alone: your .NET version, MVC conventions, EF Core setup, Azure environment, team coding standards, and the "why" behind the request.

### Why it matters

Without context, the AI makes assumptions. Those assumptions are often wrong for a Microsoft shop — it may suggest middleware patterns that don't exist in your version, EF Core approaches incompatible with your DbContext design, or Azure services you don't have provisioned.

### What to include

- **Tech stack**: .NET version, ASP.NET Core version, EF Core version, SQL Server version, Azure services in use
- **Constraints**: Performance SLAs, security policies, existing patterns your team follows
- **Existing code**: Relevant controllers, services, models, DbContext, or interfaces
- **The "why"**: Business or technical reason behind the request
- **What you've already tried**: Avoid getting suggestions you've already ruled out
- **Definition of done**: What does success look like?

### Examples

**Weak:**
```
Write a method to cache database results.
```

**Strong:**
```
We are building an ASP.NET Core 8 MVC application targeting .NET 8. We use 
Entity Framework Core 8 with SQL Server 2022. The app is hosted on Azure App 
Service. We are already using IMemoryCache for session data and have IDistributedCache 
configured with Azure Cache for Redis for session state. We cannot add new 
Azure resources.

Write a service method that caches the results of a frequently called EF Core 
query (product catalog, ~2,000 rows) using IMemoryCache with a 10-minute 
sliding expiration. The cache key must include the tenant ID from the current 
ClaimsPrincipal to prevent cross-tenant data leakage. Follow our existing 
repository pattern — the interface is included below.

[paste IProductRepository interface]
```

**Weak:**
```
Help me fix this bug.
[pastes 300 lines of code]
```

**Strong:**
```
Stack: ASP.NET Core 8 MVC, EF Core 8, SQL Server 2022, .NET 8.

The following controller action intermittently throws a 
"InvalidOperationException: A second operation was started on this context 
instance before a previous operation completed" in production only. 
It does NOT reproduce locally or in our staging environment.

Production runs on Azure App Service with 3 instances behind a load balancer. 
Our DbContext is registered with AddDbContext (scoped lifetime). 

Here is the controller action and the service it calls. The exception stack 
trace points to the async EF Core query inside the service.

[paste controller and service code]
```

### Tips

- Paste your actual model classes, interfaces, or DbContext registrations — don't describe them.
- Specify .NET and EF Core versions explicitly. Patterns for EF Core 6 async queries differ from EF Core 8.
- State constraints as hard rules: "We cannot use stored procedures" or "This action must respond in under 200ms."
- Include your DI registration style (constructor injection, `IServiceProvider`, etc.) when asking about services — it affects what solutions are valid.

---

## 3. Giving the AI Permission to Fail

### What it is

Explicitly instructing the AI to admit uncertainty, ask clarifying questions, or say "I don't know" rather than inventing a plausible-sounding but incorrect answer.

### Why it matters

Language models are trained to be helpful and produce fluent, confident-sounding text. Without explicit instruction, they will fill gaps in their knowledge with hallucinated details — non-existent EF Core methods, wrong ASP.NET Core attribute names, fabricated NuGet package versions, or middleware APIs that were removed in a prior release. In a C# codebase, these compile errors waste time and erode trust in AI tooling.

### The core techniques

**1. Explicit uncertainty permission**
```
If you are not certain about any part of this answer, say so explicitly. 
Do not fabricate method signatures, attribute names, or NuGet package versions.
```

**2. Confidence signaling**
```
For each recommendation, indicate your confidence level: 
[HIGH] I am certain this is correct for .NET 8, [MEDIUM] this is likely correct but verify 
against the docs, [LOW] this is my best guess and needs validation.
```

**3. Clarification requests**
```
If my request is ambiguous or you need more information to give a useful answer, 
ask me up to three clarifying questions before proceeding.
```

**4. Scope limiting**
```
Only answer based on the C# code I have provided. Do not assume the existence 
of extension methods, base classes, or middleware I have not shown you.
```

**5. Fallback instruction**
```
If you don't know the correct approach for our specific version of ASP.NET Core 
or EF Core, provide the general pattern and tell me exactly what to search in 
the Microsoft docs to implement it correctly.
```

### Examples

**Without permission to fail:**
```
What is the attribute to disable antiforgery token validation for a specific 
action in ASP.NET Core MVC?
```
*(Risk: the AI may confidently describe an attribute that was renamed, moved to a different namespace, or never existed in your version.)*

**With permission to fail:**
```
What is the correct attribute to disable antiforgery token validation for a 
specific MVC controller action in ASP.NET Core 8?

If the attribute name or namespace has changed across ASP.NET Core versions, 
tell me which version you are confident about and which ones you are not. 
Do not invent an attribute name. If you are unsure, point me to the Microsoft 
docs page I should verify against.
```

**Without permission to fail:**
```
Show me how to implement row-level security in EF Core.
```

**With permission to fail:**
```
Show me how to implement row-level security in EF Core 8 using query filters, 
so that every query automatically scopes results to the current user's TenantId.

If any part of this approach behaves differently in EF Core 8 vs. earlier versions, 
call it out explicitly. If there are edge cases where the global query filter is 
bypassed (e.g., raw SQL, explicit IgnoreQueryFilters calls), list them — do not 
present this as a complete security solution without noting its limitations.
```

### Tips

- Add permission-to-fail language to any prompt involving specific ASP.NET Core middleware, EF Core APIs, or Azure SDK methods — these change frequently across versions.
- For NuGet-dependent code: *"If a step requires a NuGet package you are not confident is current, note it as 'verify NuGet version' rather than guessing."*
- Be especially cautious with AI output on ASP.NET Core Identity, minimal API patterns, and Blazor — these areas evolved rapidly and training data may reflect older behavior.

---

## 4. Formatting Instructions

### What it is

Explicit instructions that define the structure, length, style, and delivery format of the AI's response.

### Why it matters

Without formatting instructions, the AI picks a format it thinks is appropriate — often too verbose, insufficiently structured for your workflow, or mixing explanation and code in ways that are hard to drop into Visual Studio. Clear formatting instructions make output paste cleanly into your controllers, services, and tests.

### Common formatting patterns for .NET developers

**Code-first responses:**
```
Provide the complete C# code first, then the explanation. 
Do not interleave explanation with code.
```

**Structured sections:**
```
Structure your response as:
1. Summary (2-3 sentences)
2. Complete C# code (compilable, with using statements)
3. Usage example showing how to call it from a controller action
4. Edge cases and limitations
```

**Diff format for targeted edits:**
```
Show only the lines that change. Include the method signature and 5 lines 
of surrounding context. Do not rewrite the entire class.
```

**Markdown for PR descriptions or docs:**
```
Format the output as Markdown suitable for an Azure DevOps pull request 
description. Use ## for section headers and fenced C# code blocks.
```

**Minimal output for automation:**
```
Return only the C# code. No explanation, no preamble, no using statements 
I didn't ask for, no sign-off. I will ask follow-up questions if I need clarification.
```

**Structured findings for code review:**
```
Return your review as a JSON array. Each item: 
{ "issue": string, "severity": "high"|"medium"|"low", "line": number, "fix": string }
No text outside the JSON array.
```

**Unit test output:**
```
Return only xUnit test methods. Use the Arrange/Act/Assert comment pattern. 
Name tests using the convention: MethodName_StateUnderTest_ExpectedBehavior.
No test class wrapper — I will paste the methods into my existing test class.
```

### Tips

- When asking for controller actions, specify whether you want the full action body or just the changed lines.
- For EF Core queries, ask for both the LINQ and the generated SQL when performance is a concern: *"Show the LINQ query and add a comment with the equivalent SQL it generates."*
- If you're integrating AI output into a CI pipeline or code generation script, use the JSON output pattern and validate it before processing.

---

## 5. Chain of Thought Prompting

### What it is

Chain of thought (CoT) prompting instructs the AI to reason step by step before arriving at an answer. Instead of jumping to a conclusion, it works through the problem out loud — surfacing assumptions, intermediate steps, and decision points.

### Why it matters

Complex .NET engineering problems — debugging async deadlocks, EF Core query optimization, DI lifetime mismatches, architecture choices — benefit enormously from explicit reasoning. When the AI shows its work, you can catch flawed assumptions early, understand the trade-offs it considered, and trust the conclusion more.

Without CoT, the model pattern-matches to a solution. With CoT, it *reasons* to one.

### Trigger phrases

```
Think through this step by step before giving your final answer.
```
```
Before writing any code, reason through the approach: what are the lifetime 
implications, what edge cases exist, and what could go wrong in production?
```
```
Work through this problem out loud. Show your reasoning at each step.
```
```
First, analyze the problem. Then, consider at least two approaches. 
Then, recommend one with justification for our .NET stack.
```

### When to use it

| Situation | Use CoT? |
|---|---|
| Scaffolding a standard CRUD controller | No |
| Async deadlock that defies obvious explanation | Yes |
| Choosing between service lifetime registrations (Scoped vs. Singleton) | Yes |
| Explaining a complex LINQ expression | Yes |
| EF Core N+1 query investigation | Yes |
| Adding a DTO property | No |
| Designing middleware pipeline ordering | Yes |
| Writing a straightforward xUnit test | No |
| Evaluating a SQL Server indexing strategy | Yes |
| Renaming a view model property | No |

### Example

**Without CoT:**
```
Should we use an in-memory cache or Azure Cache for Redis for our 
ASP.NET Core session state?
```

**With CoT:**
```
You are a senior .NET engineer designing the caching architecture for an 
ASP.NET Core 8 MVC application hosted on Azure App Service with 3 instances 
behind Azure Front Door.

Before recommending an approach, think through this step by step:
- What are the failure modes of in-memory cache (IMemoryCache) in a 
  multi-instance App Service deployment?
- How does Azure Cache for Redis handle the case where a cache node is 
  temporarily unavailable, and what does ASP.NET Core do in that scenario?
- What are the consistency implications of each option for user session data?
- What is the operational complexity of each for a team that does not have 
  a dedicated infrastructure engineer?

After your analysis, give a concrete recommendation for our context: 
we have 500 concurrent users at peak, session data is ~4KB per user, 
and we are already paying for an Azure Cache for Redis instance 
for another workload.
```

### Structured CoT pattern

For complex tasks, scaffold the reasoning explicitly:

```
Answer in this order:
1. UNDERSTAND: Restate the problem in your own words to confirm you understand it.
2. ANALYZE: Identify the key constraints, unknowns, and risks specific to our .NET stack.
3. OPTIONS: List 2-3 possible C# / ASP.NET Core approaches with their trade-offs.
4. RECOMMEND: Choose one approach and justify it against our constraints.
5. IMPLEMENTATION: Provide the complete, compilable C# code.
```

---

## 6. Extended Thinking

### What it is

Extended thinking is a mode available in frontier AI models (such as Claude's extended thinking mode) where the model is given a larger reasoning budget — more internal computation — before producing its response. It is distinct from chain of thought in that the model's reasoning happens internally before the visible response, rather than being shown inline.

From a prompting perspective, you activate extended thinking either through API parameters or by crafting prompts that signal the task requires deep, careful reasoning.

### Why it matters

For routine tasks, standard responses are fast, cheap, and sufficient. But for genuinely hard .NET problems — complex debugging, architectural refactors, EF Core schema design for a multi-tenant SaaS, evaluating a major upgrade from .NET Framework to .NET 8 — the additional reasoning budget produces qualitatively better answers: fewer logical gaps, more thorough trade-off analysis, and edge cases you would have otherwise missed.

### When to use extended thinking

Use it for problems where a senior .NET developer would need to sit and think for 20+ minutes:

- MVC application architecture decisions (monolith vs. modular, layered vs. vertical slice)
- Complex EF Core migration strategies for live production databases
- Multi-tenant data isolation architecture
- .NET Framework to .NET 8 migration planning
- ASP.NET Core middleware pipeline design for cross-cutting concerns
- Security threat modeling for an MVC application
- Performance bottleneck analysis involving EF Core, SQL Server, and Azure App Service together
- Evaluating a major NuGet dependency upgrade with breaking changes

Do **not** use it for:
- Scaffolding controllers or views
- Writing standard xUnit tests
- Simple LINQ transformations
- Adding validation attributes to a view model
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
.NET architect challenge in each approach?
```
```
This decision will be hard to reverse once we migrate the production database. 
Treat it with the rigor you would apply to a production incident post-mortem.
```

### API-level extended thinking (Anthropic)

When using the Anthropic API in a .NET integration or internal tool, you can enable extended thinking programmatically:

```csharp
// Example using Anthropic's API from C#
var requestBody = new
{
    model = "claude-opus-4-5",
    max_tokens = 16000,
    thinking = new
    {
        type = "enabled",
        budget_tokens = 10000   // Reasoning budget to allocate
    },
    messages = new[]
    {
        new { role = "user", content = yourComplexPrompt }
    }
};
```

The response will include a `thinking` block (internal reasoning) and a `text` block (final answer). Surface the thinking block in developer tooling for transparency and review.

### Extended thinking prompt example

```
You are a principal .NET engineer at a mid-size SaaS company. We are evaluating 
migrating our ASP.NET Core 8 MVC application from a single shared SQL Server 
database (with a TenantId column on every table) to a database-per-tenant model.

The application has:
- 200 tenants today, projected to 2,000 within 18 months
- 85 EF Core entity types, 40+ DbContext migrations in the migration history
- SQL Server 2022 hosted on Azure SQL Database (Standard tier, single database)
- A team of 5 .NET developers; no dedicated DBA
- Zero-downtime deployment requirements (Azure App Service deployment slots)

This is a complex, high-stakes architectural decision we will live with for 
3-5 years. Take as much space as you need to reason through it carefully. 
Do not rush to a recommendation.

Analyze:
1. The EF Core migration management problem: how do we apply 85 migrations 
   across 2,000 tenant databases during a deployment?
2. Azure SQL Database cost implications: per-database pricing vs. elastic pools
3. The application code changes required: DbContext factory pattern, 
   connection string resolution per tenant, and DI registration changes
4. The data migration path: how do we split one database into 200 without downtime?
5. Operational complexity: backup strategy, monitoring, and incident response 
   with 2,000 databases vs. 1

After thorough analysis, give a concrete recommendation with implementation 
milestones. If there are aspects of this decision you cannot evaluate without 
more information, list them explicitly rather than assuming.
```

---

## Complete Prompt Examples

The following are full, production-quality prompt examples that use all five techniques together — persona, context, task, permission to fail, and formatting.

---

### Example 1: Complex Bug Investigation — Async Deadlock

```
PERSONA:
You are a senior .NET engineer with deep expertise in ASP.NET Core async/await 
patterns, the Task Parallel Library, and diagnosing deadlocks in MVC applications. 
You specialize in production issues that don't reproduce locally.

CONTEXT:
Stack: ASP.NET Core 8 MVC, .NET 8, EF Core 8, SQL Server 2022, hosted on 
Azure App Service (2 vCPU, 3.5GB RAM, 3 instances).

We are seeing intermittent request hangs in production that eventually time out 
with a 503. The hangs correlate with traffic spikes (300+ concurrent users) but 
we cannot reproduce them under local load testing. Azure Application Insights 
shows the requests stall inside a service method — not at the SQL layer. No 
exceptions are thrown; the thread just never returns.

Here is the controller action and the service it calls:

[paste controller and service code]

We have already ruled out:
- SQL Server deadlocks (no deadlock events in Extended Events)
- EF Core connection pool exhaustion (connection count is stable)
- Azure App Service resource limits (CPU and memory are well within bounds)

TASK:
Diagnose the most likely cause of the hang. Think through this step by step — 
reason about each async call chain, look for .Result or .Wait() calls, 
ConfigureAwait usage, and any synchronization context capture that could 
cause a deadlock in an ASP.NET Core context.

PERMISSION TO FAIL:
If you cannot identify the root cause from the code alone, tell me exactly 
what diagnostic data you need (Application Insights traces, thread dumps, 
specific code paths) and why. Do not speculate without labeling it as speculation.

FORMAT:
1. Root cause hypothesis (most likely → least likely, with reasoning)
2. Evidence from the code supporting each hypothesis
3. Diagnostic steps to confirm the root cause
4. Code fix for the most likely cause
5. Any async patterns to refactor team-wide regardless of root cause
```

---

### Example 2: Architecture Design with Extended Thinking — Multi-Tenant MVC App

```
PERSONA:
You are a principal .NET engineer with experience designing multi-tenant 
ASP.NET Core MVC applications at scale. You have strong opinions about 
operational simplicity vs. technical sophistication and have led teams 
through Azure migrations.

CONTEXT:
We are a 15-person software company. Our product is a B2B SaaS MVC 
application built on ASP.NET Core 8, EF Core 8, SQL Server 2022 on 
Azure SQL Database, and Azure App Service. We need to add a background 
job processing system that:

- Processes 10,000–50,000 jobs per day (spiky, not constant)
- Allows jobs to be retried on failure with exponential backoff
- Provides a management UI visible to our support team (job status, 
  manual retrigger, failure details)
- Must be maintainable by 3 .NET developers who are not infrastructure engineers
- Budget: under $500/month for this component at peak load
- We are already using Azure Service Bus for event publishing

TASK:
Design the background job processing architecture for these requirements.

This is a non-trivial architectural decision we will live with for 2-3 years. 
Take as much space as you need to reason through it carefully. Consider at 
least three different approaches before recommending one.

For each approach, evaluate:
- Cost at our stated scale on Azure
- Operational burden on a small .NET team
- Retry and failure handling behavior
- How the management UI requirement is met
- What happens when job volume spikes 5x unexpectedly

PERMISSION TO FAIL:
If my requirements contain contradictions or underspecified constraints that 
would materially affect your recommendation, identify them before proceeding. 
If your Azure cost estimates are rough approximations, say so.

FORMAT:
1. REQUIREMENTS VALIDATION — flag any conflicts or ambiguities
2. ARCHITECTURAL OPTIONS — 3 options with .NET-specific trade-off analysis
3. RECOMMENDATION — one architecture with justification
4. IMPLEMENTATION ROADMAP — phased rollout in 3 milestones with NuGet packages needed
5. RISKS AND MITIGATIONS — top 3 risks with specific mitigations
6. OPEN QUESTIONS — what you'd need to know to sharpen the recommendation
```

---

### Example 3: Security Code Review — Authentication Controller

```
PERSONA:
You are an application security engineer specializing in ASP.NET Core web 
application vulnerabilities, OWASP Top 10, and secure coding patterns for 
C# MVC APIs. You conduct reviews with the mindset of an adversarial attacker, 
not a defensive developer.

CONTEXT:
This is an ASP.NET Core 8 MVC controller action that handles user login and 
issues an authentication cookie. It is the primary authentication entry point 
for our B2B SaaS application, exposed to the public internet. Our enterprise 
customers have SOC 2 Type II compliance requirements. We are preparing for a 
third-party penetration test in 6 weeks.

[paste AccountController.Login action and related service code]

TASK:
Conduct a security review of this code. Think through each vulnerability class 
systematically before summarizing findings. Reason about how an attacker would 
approach this controller action.

Consider at minimum:
- SQL injection and EF Core parameterization
- Authentication and session management flaws (ASP.NET Core cookie config)
- Sensitive data exposure in responses or logs
- Brute force and credential stuffing susceptibility (rate limiting, account lockout)
- Timing attacks on password comparison
- Antiforgery token validation
- Mass assignment vulnerabilities via model binding
- Information leakage in error messages and exception details
- Insecure direct object references in any ID parameters

PERMISSION TO FAIL:
If you identify a potential vulnerability but cannot confirm it without seeing 
additional code (e.g., the Startup/Program.cs middleware configuration, 
the Identity setup, the authentication cookie options), flag it as 
"suspected — needs investigation" with specific instructions for what to check. 
Do not mark something as safe if you haven't seen the relevant code.

FORMAT:
Return findings as a structured list:

**[CRITICAL | HIGH | MEDIUM | LOW | INFO]** — Vulnerability name
*Location:* method name / line reference
*Description:* What the vulnerability is
*Attack scenario:* How an attacker would exploit it
*Remediation:* Specific C# code fix

End with a summary section: overall security posture assessment and the top 3 
priority fixes to address before the penetration test.
```

---

### Example 4: Code Explanation for Team Knowledge Transfer

```
PERSONA:
You are a staff .NET engineer and technical educator who excels at making 
complex ASP.NET Core systems understandable. You explain things using concrete 
analogies and always connect abstract concepts to practical consequences for 
a .NET developer.

CONTEXT:
I am preparing a knowledge transfer document for mid-level C# developers on 
my team (3-5 years experience, strong in MVC controllers and EF Core basics, 
limited exposure to distributed systems and advanced DI patterns). They will 
be maintaining the following service after I move to a new role.

[paste complex service class using IHostedService, channels, or advanced DI]

TASK:
Explain this code so a mid-level .NET developer could:
1. Understand what it does and why it exists
2. Safely make changes to it
3. Debug it when something goes wrong in production
4. Know what questions to ask if they're unsure

Think through the explanation step by step — start with the big picture, then 
zoom into the non-obvious parts. Don't explain things obvious to a mid-level 
.NET developer (basic LINQ, standard controller patterns); focus on anything 
that requires deeper knowledge of the ASP.NET Core pipeline, DI lifetimes, 
or async patterns.

PERMISSION TO FAIL:
If there are parts of the code whose purpose or behavior is genuinely unclear 
(undocumented magic values, unusual patterns, or code that appears buggy), 
flag them explicitly rather than inventing a confident explanation. 
Those flags are valuable for the knowledge transfer document.

FORMAT:
## Overview
[What this code does in 3-5 sentences]

## Why it exists
[Business or technical context]

## How it works
[Walk through the key logic — use numbered steps for sequential flows]

## The non-obvious parts
[Explain anything that would confuse a mid-level .NET developer — 
DI lifetime decisions, async patterns, ASP.NET Core pipeline hooks]

## How to safely change it
[What to watch out for, what tests to run, what could break]

## Danger zones
[Parts that are fragile, have known issues, or need a senior engineer's eyes]
```

---

## Reducing Cost and Improving ROI

Token cost is real. At scale — a team of developers using AI tooling daily, CI pipelines running automated reviews, internal tools calling the AI API — poorly engineered prompts burn significant budget. More importantly, expensive prompts often produce *worse* results than well-designed cheaper ones.

### Understanding what drives cost

Cost is driven by:
1. **Input tokens** — everything you send to the model (system prompt + conversation history + your prompt + pasted code)
2. **Output tokens** — everything the model returns (typically more expensive per token than input)
3. **Model tier** — frontier models (e.g., Claude Opus) cost significantly more than mid-tier (e.g., Claude Sonnet) or fast models (e.g., Claude Haiku)

---

### Strategy 1: Match model tier to task complexity

Not every task needs a frontier model. Route tasks to the right tier:

| Task | Recommended tier |
|---|---|
| Scaffolding CRUD controllers, adding DTO properties | Fast/cheap model |
| Standard feature implementation, writing xUnit tests | Mid-tier |
| Architecture design, complex debugging, security review | Frontier |
| Code explanation, XML doc comments | Mid-tier |
| CI-automated tasks (PR summaries, linting feedback) | Fast/cheap model |
| EF Core migration review | Mid-tier |
| .NET Framework → .NET 8 migration planning | Frontier |

**Cost impact:** Routing a task from a frontier model to a fast model can reduce cost by 10-50x with no quality loss for simple tasks.

---

### Strategy 2: Be specific to reduce output length

Verbose prompts that accept verbose responses are expensive. Precision cuts both sides.

**Expensive (generates long, unfocused output):**
```
Tell me about error handling in our MVC controllers.
```

**Cheaper (scoped output, focused answer):**
```
List the top 3 error handling gaps in the following ASP.NET Core MVC controller. 
For each: one sentence describing the gap, one C# snippet showing the fix. 
No other output.

[paste controller code]
```

**Why it's cheaper:** The scoped version generates ~80% fewer output tokens and produces a more actionable result.

---

### Strategy 3: Use system prompts for repeated context

If you are building an internal tool or automation that calls the AI API repeatedly (e.g., a Visual Studio extension, an Azure DevOps pipeline step, or a code review bot), don't repeat your stack context in every user message. Put stable context in the system prompt — it can be cached.

**Expensive pattern (context repeated in every API call):**
```csharp
// Every API call includes this full context in the user message
string userMessage = $"""
    We use ASP.NET Core 8 MVC, EF Core 8, SQL Server 2022, Azure App Service.
    Our coding standards: XML doc comments on all public members, 
    repository pattern for data access, Result<T> for error handling, 
    no raw SQL in application code, xUnit + Moq for tests.
    
    Now: {actualUserRequest}
    """;
```

**Cheaper pattern (stable context in system prompt, cached):**
```csharp
string systemPrompt = """
    You are a senior .NET engineer working in our codebase.
    Stack: ASP.NET Core 8 MVC, EF Core 8, SQL Server 2022, Azure App Service.
    Standards: XML doc comments on all public members, repository pattern, 
    Result<T> for error handling, no raw SQL, xUnit + Moq for tests.
    """;

// User messages stay lean
string userMessage = actualUserRequest;
```

**Cost impact:** Anthropic's prompt caching can reduce repeated context costs by up to 90% for high-frequency use cases.

---

### Strategy 4: Ask for the minimum viable output

A common mistake: asking for a full explanation when you only need the code.

**Over-generating (expensive):**
```
Refactor this service method to be async.
```
*(Model will explain what it changed, why ConfigureAwait(false) matters, add caveats about SynchronizationContext, etc.)*

**Lean output (cheap):**
```
Refactor this C# service method to be async all the way down. 
Return only the refactored method. No explanation.

[paste method]
```

**When to use:** Automated pipelines, CI tasks, scaffolding, any case where you're processing the output programmatically.

**When NOT to use:** Learning contexts, architectural decisions, anything where understanding the reasoning matters.

---

### Strategy 5: Use few-shot examples instead of long prose instructions

Long instruction sets that describe output format in prose are both expensive (more input tokens) and unreliable. A short example is cheaper and more effective.

**Expensive instruction approach:**
```
Return your findings as a list. Each finding should have a severity level 
(which should be one of: critical, high, medium, low, or informational). 
Include the line number where the issue appears. Describe the issue in plain 
language. Then provide a suggested fix as a C# code snippet. 
Separate each finding with a blank line...
[continues for 8 more sentences]
```

**Cheaper few-shot approach:**
```
Return findings in this format (one per issue, no other text):

SEVERITY | LINE | ISSUE | FIX
HIGH | 42 | EF Core query uses string interpolation (SQL injection risk) | Use parameterized query: _db.Users.Where(u => u.Id == id)
MEDIUM | 87 | User ID logged in exception handler | Remove userId from the log.Error call

Now analyze:
[paste C# code]
```

---

### Strategy 6: Break compound tasks into targeted calls

One expensive mega-prompt that does five things is usually worse in both quality and cost than five targeted prompts.

**Expensive mega-prompt:**
```
Review this controller for bugs, security issues, performance problems, and 
style violations. Also write xUnit tests for it and update the XML doc comments.
```

**Cheaper targeted approach:**

```
# Call 1 — fast model
Find null reference risks and obvious C# bugs in this controller action. 
Return line numbers and one-line descriptions only.

# Call 2 — mid-tier model
Review this ASP.NET Core controller action for security vulnerabilities. 
Return structured findings only (no code, just issue + fix description).

# Call 3 — mid-tier model
Write xUnit tests for the public surface of this controller action using Moq. 
Follow the Arrange/Act/Assert pattern. No explanation.

# Call 4 — fast model
Write XML doc comments for all public methods in this class. 
Return only the comments, not the full class.
```

**Why this is better:** Each call is scoped, uses the appropriate model tier, and produces focused output. Total cost is often lower than one sprawling prompt, and the results are more actionable.

---

### Strategy 7: Conversation management for iterative tasks

In long iterative sessions (e.g., working through a complex refactor or EF Core schema redesign), conversation history grows and every message re-sends the full history. Prune aggressively.

**Expensive (default behavior):**
Long multi-turn conversations where every new message costs tokens for the entire prior history.

**Cheaper:**
- Summarize resolved threads: *"We've decided to use the repository pattern with a Unit of Work. Proceed assuming that decision is final."*
- Start fresh conversations for each new subtask rather than extending old ones
- Use the model to generate a concise context summary you paste into a new conversation: *"Summarize the architectural decisions we've made in this conversation in 5 bullet points so I can start a fresh context."*

---

### C# MVC-specific cost traps to avoid

| Trap | Why it's expensive | Fix |
|---|---|---|
| Pasting entire `DbContext` for a single-table query | 500+ tokens of irrelevant context | Paste only the relevant `DbSet` and entity class |
| "Explain this whole controller" | Forces verbose output | Ask about one action method at a time |
| Asking for xUnit tests + implementation + review in one prompt | Three tasks, three model calls baked into one | Split into three targeted calls |
| Re-explaining your DI setup every conversation | Repeated input tokens | Use a saved system prompt snippet |
| Asking for "best practices" without scoping to your version | Triggers broad, version-ambiguous output | Always specify .NET 8 / ASP.NET Core 8 / EF Core 8 |

---

### Cost optimization quick reference

| Technique | Cost Impact | Quality Impact |
|---|---|---|
| Route simple tasks to fast/cheap models | Very High ↓ | Neutral |
| Scope output format explicitly | High ↓ | Neutral or better |
| System prompt caching for repeated .NET stack context | Very High ↓ (at scale) | Neutral |
| "No explanation, code only" for automation | High ↓ | Neutral for automation |
| Few-shot format examples vs. prose instructions | Medium ↓ | Neutral or better |
| Break compound tasks into targeted calls | Medium ↓ | Better |
| Prune conversation history in long sessions | Medium ↓ (at scale) | Neutral |
| Extended thinking only for hard architectural problems | Medium ↓ | Better on hard problems |
| Paste only the relevant class/method, not entire files | Medium ↓ | Neutral or better |

---

## Summary

The highest-leverage habits for your .NET team:

1. **Always assign a .NET-anchored persona** — without it, you may get Node.js or Python patterns dressed up as C#.
2. **Paste context, don't describe it** — show the controller, service, and model, not a summary of them.
3. **Specify your versions every time** — `.NET 8`, `EF Core 8`, `ASP.NET Core 8`. Version ambiguity is the #1 source of hallucinated method signatures.
4. **Grant permission to fail** on any prompt involving specific ASP.NET Core middleware, EF Core APIs, or Azure SDK methods.
5. **Specify output format** as a default habit — your future self (and your pipelines) will thank you.
6. **Use chain of thought** whenever you catch yourself wanting to ask follow-up questions — ask them up front.
7. **Reserve extended thinking** for decisions you'll live with for more than a quarter — migrations, architecture, major refactors.
8. **Right-size your model** — scaffolding a CRUD controller does not need a frontier model.
9. **Scope your outputs** — verbosity costs money and often reduces clarity.

Good prompting is a skill that compounds. The team members who invest in it now will be dramatically more productive as AI capabilities continue to improve.

---

*Last updated: June 2026*
*Stack: ASP.NET Core 8 MVC · EF Core 8 · SQL Server 2022 · Azure*
*Maintained by: [Your team's designated AI integration lead]*
