# PromptArchitect — Reproduction Prompts

This file contains a set of prompts you can give to an AI coding assistant (such as Claude) to regenerate the **PromptArchitect** application from scratch — including the HTML, CSS, and JavaScript files, the persona JSON schema, and the included persona files.

The prompts are ordered the way the application was actually built. You can run them **one at a time, in sequence**, in a single conversation — each prompt builds on the output of the one before it. Alternatively, the **Master Prompt** in Step 1 alone is detailed enough to produce a complete working v1 of the app in one shot; Steps 2–4 layer on the refinements that followed.

---

## How to use this file

1. Start a new conversation with an AI coding assistant that can create files (HTML/CSS/JS) and has a code execution / artifact environment.
2. Paste **Prompt 1** first and let it generate the three core files.
3. Paste **Prompt 2** to upgrade the visual design.
4. Paste **Prompt 3** to add the persona loader system and the four included persona files.
5. Paste **Prompt 4** to upgrade the cost estimator to the side-by-side comparison view.
6. (Optional) Use the **Persona Generation Template** in Step 5 to create additional team personas, and the **Persona Token-Reduction Prompt** in Step 6 if any persona file grows too large.

Each prompt is a complete, self-contained instruction — copy everything inside the fenced code block for that step.

---

## Step 1 — Core Application (HTML + CSS + JS)

This produces the initial three-file application: a 5-step guided prompt builder covering Persona, Context, Task, Permission, and Format, plus a live preview and a cost estimator.

```text
You are a senior software developer with 10+ years building custom web applications
that are HTML5 and Vanilla JavaScript based.

Build a solution made up of a single HTML file plus a separate CSS file and a separate
JavaScript file that the HTML file references. Ensure the application works with CORS
rules by using external CSS/JS file references, and use JavaScript event listeners on
DOM elements for all interactivity (no inline onclick attributes).

Build an interactive web application called "PromptArchitect" that walks a developer
through the process of creating an excellent AI prompt. The app must guide the user
through five sections, in this order:

1. Persona — Who is the AI playing? Fields: Role/Job Title (required text input),
   Experience Level (select: Junior 0–3 years / Mid-level 3–7 years / Senior 7–15 years /
   Expert world-class), Personality Traits (optional text input). Show a live preview
   sentence that updates as the user types, e.g. "You are a senior Tax Attorney. You are
   concise, pragmatic."

2. Context — What does it need to know? Fields: Background/Situation (required textarea),
   Target Audience (optional text input), Constraints/Guardrails (optional text input).

3. Task — What exactly do you want? Fields: Action Verb (select: Write, Analyze,
   Summarize, Review, Generate, Compare, Explain, Create, Debug, Translate, Rewrite, List),
   The Deliverable (required text input), Desired Outcome/Goal (optional text input).

4. Permission — What should it do if it doesn't know? A radio button group with these
   four options (exact values matter, they are reused later):
     - "Say 'I don't know' clearly rather than guessing"
     - "Ask a clarifying question before proceeding"
     - "Make a clearly labelled assumption and continue"
     - "Provide a best-effort answer with a confidence caveat"
   Plus an optional free-text "Additional Permissions / Restrictions" field.

5. Format — How should the output be structured? Fields: Output Format (select with these
   exact values: "Respond in plain prose paragraphs", "Use markdown with headers and bullet
   points", "Return a numbered list", "Return a markdown table", "Return valid JSON only, no
   prose", "Use code blocks with explanations below each", "Use a step-by-step numbered
   format", "Write in Q&A format"), Length/Depth (select with these exact values: "Be
   concise — aim for under 150 words", "Aim for 250–400 words", "Be thorough — 500–800
   words is acceptable", "Be exhaustive and comprehensive — length is not a concern"), and
   an optional "Additional Format Notes" text input.

A 6th "Preview" step assembles all the fields into a single final prompt using markdown
section headers (## Persona, ## Context, ## Task, ## Permission & Limits, ## Output
Format), shows a quality badge (Excellent / Good / Basic / Empty based on how many of the
5 sections are filled), and provides Copy-to-clipboard and Reset buttons.

Navigation: a header with pill-shaped buttons for each of the 6 steps that jump directly
to that step, plus Next/Back buttons at the bottom of each step card. Only one step card
is visible at a time.

Right-hand sidebar (sticky, always visible):
  - A "Live prompt preview" panel showing the assembled prompt so far in a monospace font,
    updating on every keystroke, plus an estimated token count (use the heuristic:
    word count × 1.35, rounded).
  - A "Prompt completeness" panel with 5 small dot indicators (one per section: Persona,
    Context, Task, Permission, Format) that turn from empty/grey to filled/green as each
    section's required fields are completed, plus a progress bar and an "X / 5 sections
    complete" label.
  - A "Cost estimator" panel (build this with placeholder logic for now — it will be
    replaced in a later step) showing per-call cost based on Anthropic API pricing for
    three models: Claude Haiku 4.5 ($1.00 input / $5.00 output per million tokens), Claude
    Sonnet 4.6 ($3.00 / $15.00), and Claude Opus 4.8 ($5.00 / $25.00). Assume a fixed 300
    output tokens for now. Include a monthly volume slider with presets: 100, 1,000, 5,000,
    10,000, 50,000, 100,000 calls/month, and show the projected monthly cost.
  - A "Prompt tips" panel with a short static bulleted list of prompt-engineering tips.

A toast notification element at the bottom of the screen for "Copied to clipboard" and
"Prompt cleared" messages.

Use semantic HTML5, a dark theme to start with, and make sure every interactive element
has an appropriate ARIA label where relevant. Output three files: prompt-builder.html,
prompt-builder.css, prompt-builder.js.
```

---

## Step 2 — Visual Redesign

This prompt takes the plain dark-mode v1 and gives each of the five steps its own
signature color, adds a light theme, and improves overall visual hierarchy.

```text
The HTML application looks very plain. Update the CSS to make the page more colorful and
improve usability, with the following specific changes:

1. Switch from a dark theme to a light theme: background #f0f2f8, card surfaces white
   (#ffffff) and very light grey (#f7f8fc), with a subtle 40px CSS grid-line pattern drawn
   across the page background using two linear-gradients at 4% opacity violet.

2. Give each of the 5 builder steps its own accent color, applied consistently to that
   step's badge, top border, description callout border, input focus rings, buttons, and
   radio selection states:
     - Step 1 Persona  → violet  (#6d5ef5, light #edeaff, mid #bdb5fb)
     - Step 2 Context  → cyan    (#0ea8d5, light #e0f6fd, mid #87d9ee)
     - Step 3 Task     → orange  (#e8590c, light #fff0e8, mid #f7b98a)
     - Step 4 Permission → pink  (#d42e8c, light #fde8f4, mid #f09fd1)
     - Step 5 Format   → green   (#1db870, light #e4f9ed, mid #78d9a4)
     - Step 6 Preview  → violet (same as Step 1)

3. Each step card should have a 5px colored gradient band across the top (from the step's
   main color to its "mid" color), a 48x48px rounded badge with the step number in a
   tinted background matching the step color, and the step description text in a
   left-bordered callout box using the step's "light" background and "mid" border color.

4. Use CSS custom properties (--step-color, --step-light, --step-mid) set at the :root
   level, and update them dynamically via JavaScript whenever the user navigates to a
   different step, so the right-hand sidebar panels also pick up the active step's accent
   color (e.g. the colored dot before each panel title).

5. Style the header navigation pills so the active step pill uses the step's accent color,
   and completed steps (steps before the current one) turn green with a checkmark style.

6. Improve form field styling: 1.5px borders, generous padding, focus states that add a
   colored glow using the active step's color via color-mix(), and select dropdowns with a
   custom chevron icon.

7. Style the radio button group for the Permission step as a responsive 2-column grid of
   bordered cards that highlight when selected.

8. Keep the final prompt output (Step 6) on a dark terminal-style background (#0f1117)
   regardless of the light theme elsewhere, with syntax-friendly monospace styling and a
   colored quality badge (green for Excellent, violet for Good, amber for Basic).

9. Give each right-sidebar panel card a colored 3px top border: violet for the live
   preview, green for the cost estimator, orange for the tips panel.

Update prompt-builder.css (and prompt-builder.js where needed for the dynamic
--step-color/--step-light/--step-mid updates on navigation) to implement all of this.
Do not change the HTML structure except where a wrapper div is needed for the new card
layout.
```

---

## Step 3 — Persona Loader System + Persona JSON Files

This prompt adds the ability to load a `.json` persona file that pre-fills all five
steps, and creates the persona schema plus four example team persona files.

```text
Add a persona-loading system to the application:

1. UI: Add a new panel card at the top of the right sidebar titled "Load persona". It
   should contain:
   - A drag-and-drop zone (also clickable to open a file picker) that accepts .json files,
     with a dashed border, file-upload icon, and "Drop a persona .json file here / or
     click to browse" text.
   - A hidden <input type="file" accept=".json,application/json">.
   - A "loaded persona" card (hidden by default) that displays once a file is loaded,
     showing: a 2-letter initials icon, the persona's display name, its version number,
     its description, a row of tag pills, and a small "✕" button to clear it.
   - An error display area (hidden by default, red-tinted) for validation errors.
   - A short instructional hint block explaining the JSON format and listing the included
     persona files.

2. JSON schema: Create a file called personas/persona-schema.json (JSON Schema draft-07)
   that documents a persona file format with these top-level keys:
   - meta: { name (required string), description (required string), version, author, tags
     (array of strings) }
   - persona: { role (required string), experience (enum: "a junior", "a mid-level",
     "a senior", "a world-class expert", ""), traits (string) }
   - context: { background (string), audience (string), constraints (string) }
   - task: { verb (enum matching the Task step's action verbs, or ""), deliverable
     (string), goal (string) }
   - permission: { onUnknown (enum matching the 4 exact Permission radio values, or ""),
     extra (string) }
   - format: { type (enum matching the 8 exact Format-type select values, or ""), length
     (enum matching the 4 exact Format-length select values, or ""), extra (string) }
   Only meta.name, meta.description, and persona.role are required. Document every enum's
   allowed values in the schema's "description" fields.

3. JavaScript loader logic:
   - On file select or drop, read the file as text, JSON.parse it, and validate: check
     required fields are present and non-empty, and check that any enum-constrained value
     (experience, task.verb, permission.onUnknown, format.type, format.length) exactly
     matches one of the schema's allowed values. If validation fails, show all error
     messages in the error display area and do not modify the form.
   - If validation passes: populate every matching form field across all 5 steps (text
     inputs, textareas, selects by matching <option value>, and the correct radio button
     by value), update the internal JS state object to match, trigger the existing live
     preview / completeness meter / cost estimator update functions, show the "loaded
     persona" card with the file's meta information and tags, and show a success toast.
   - The "✕" clear button should reset the form back to empty (reuse the existing Reset
     logic) and show the drop zone again.
   - Support both drag-and-drop (dragenter/dragover/dragleave/drop with a "drag-over"
     CSS state) and click-to-browse.

4. Create the following 4 persona JSON files conforming to the schema above, in a
   personas/ subfolder:

   a) personas/senior-csharp-mvc-developer.json
      Role: "Senior C# ASP.NET Core MVC Web Developer", experience "a senior". Background
      should describe an enterprise team building ASP.NET Core 8 MVC apps with C# 12, EF
      Core, Razor views, SQL Server, xUnit, Azure DevOps, following SOLID and MVC
      separation of concerns. Constraints: C# idioms, async/await, Microsoft naming
      conventions, .NET 8 target, no unsolicited third-party libraries. Permission:
      "Ask a clarifying question before proceeding"; flag security concerns (SQL
      injection, CSRF, over-posting) proactively. Format: "Use code blocks with
      explanations below each", "Be thorough — 500–800 words is acceptable"; include XML
      doc comments, show using statements, and show the corresponding ViewModel/Service
      interface for any Controller action.

   b) personas/project-manager.json
      Role: "Senior Software Project Manager", experience "a senior". Background:
      manages delivery of the team's web app projects, 2-week Agile/Scrum sprints, Azure
      DevOps backlog, RAG status reporting. Audience: mixed technical and non-technical
      stakeholders. Permission: "Make a clearly labelled assumption and continue"; may
      suggest Agile/PRINCE2/PMI frameworks, flag scope creep, offer "direct" vs
      "diplomatic" message variants. Format: "Use markdown with headers and bullet
      points", "Aim for 250–400 words"; use tables for status summaries, bold for
      decisions/risks/owners, every action item needs an owner and due-date placeholder.

   c) personas/software-tester.json
      Role: "Senior Software QA Engineer", experience "a senior". Background: tests the
      team's ASP.NET Core MVC apps, 2-week sprint cycle, xUnit + Playwright, Azure DevOps
      test case management. Constraints: bug reports need steps to reproduce / expected
      vs actual / environment / severity / screenshot placeholder; test cases must map to
      an acceptance criterion. Permission: "Ask a clarifying question before proceeding";
      proactively suggest edge cases (empty inputs, max-length, concurrency, unauthorised
      access, browser compatibility). Format: "Use a step-by-step numbered format", "Be
      thorough — 500–800 words is acceptable"; test cases as ID | Title | Preconditions |
      Steps | Expected Result | Pass/Fail table rows, bug reports with Critical/High/
      Medium/Low severity labels.

   d) personas/podgrabber-senior-frontend-developer.json
      Role: "Senior Frontend Developer at PodGrabber.com", experience "a senior". Tags
      should include html5, vanilla-js, static-site, podcasts, csharp, powershell,
      frontend, media, independent. Background: PodGrabber.com is an independent podcast
      discovery and live-radio media platform built entirely with HTML5 and Vanilla
      JavaScript (no frameworks, no npm, no build tools). All content pages are static
      HTML generated offline by a pipeline of C# .NET 8 console apps and PowerShell 7
      scripts that scrape podcast RSS feeds and render: (1) individual podcast archive
      pages under /archive/, (2) genre/category section pages (e.g. /business/,
      /cybersecurity/, /comedy/) each with an active listing and an archive index, (3)
      genre archive index pages, (4) daily aggregated episode pages, (5) topic deep-dive
      pages under /topics/ organised by subject (celebrities, cybersecurity topics,
      history, trending news, paranormal, public figures, rockstars), and (6) live
      internet radio streaming pages under /live/ for ~19 music/talk genres. Client-side
      JS handles interactivity only (audio player controls, live stream embedding, search/
      filter, lazy-loading images, keyboard nav) — never content rendering, since SEO
      requires all content to exist in the static HTML at generation time. Constraints: no
      frameworks/npm/TypeScript/jQuery/preprocessors, must degrade gracefully with JS
      disabled, valid HTML5, target Chrome/Firefox/Safari/Edge 90+/88+/14+/90+, served from
      a plain static host. File naming: /archive/{Podcast-Title-Hyphenated}.html, lowercase
      kebab genre directories, /topics/{category}/{Subject-Name}-podcasts.html. Permission:
      "Ask a clarifying question before proceeding"; reference MDN as canonical; flag
      anything requiring a build tool/package manager; flag accessibility issues
      proactively; flag RSS/metadata edge cases that could break the C#/PowerShell
      generators; note SEO requirements (unique title/meta description) for /topics/ pages
      and HTTPS mixed-content risks for /live/ pages. Format: "Use code blocks with
      explanations below each", "Be thorough — 500–800 words is acceptable"; annotate HTML
      templates with <!-- GENERATED: field.name --> comments, JSDoc on JS functions, full
      method bodies for C# generation code, commented pipeline stages for PowerShell,
      always show the output file path.

Validate every JSON file against the schema's enum constraints before finalizing — every
experience/verb/onUnknown/format.type/format.length value must match the allowed list
exactly, character-for-character (including the em-dash and en-dash characters used in
the format.length options).
```

---

## Step 4 — Cost Estimator Redesign

This prompt replaces the single-model-tab cost estimator with a side-by-side
all-models comparison.

```text
The cost estimator is confusing because it only shows one model's cost at a time (via
tabs) and the monthly volume figure dominates over the actual per-call cost. Redesign the
"Cost estimator" panel as follows:

1. Remove the model tabs entirely. Replace with:

2. A "token summary" row at the top showing two values side by side: the current prompt's
   estimated input token count, and the estimated output token count (default 300),
   separated by a "+" symbol.

3. An "Adjust expected response length" slider with 6 steps mapped to output token counts:
   100, 200, 300, 600, 1000, 2000. Show "Short" and "Long" labels at the slider ends, and a
   row of small preset labels (~100, ~200, ~300, ~600, ~1 000, ~2 000) below the slider,
   with the currently-selected preset highlighted/bolded in the step's accent color.

4. A side-by-side comparison table (dark terminal-style background, #0f1117) with one row
   per model — Haiku 4.5, Sonnet 4.6, Opus 4.8 — each row showing: a colored dot (cyan for
   Haiku, violet for Sonnet, amber for Opus), the model name and its per-MTok input/output
   rates, then three right-aligned numeric columns: input cost, output cost, and a bold
   green "per call" total. Automatically highlight (subtle green background) whichever
   row currently has the lowest total cost for the user's prompt.

5. Below the table, a single-line "best value" callout with a checkmark icon that says
   something like "Sonnet 4.6 is the most cost-effective for this prompt (balanced quality
   and speed). Haiku is 40% cheaper than Opus per call." — recalculated live. If the
   prompt is empty, show "Fill in your prompt to see cost estimates."

6. Below that, put the monthly volume projection inside a collapsible <details>/<summary>
   element titled "Monthly volume projection" (collapsed by default), containing: the
   existing volume slider (100 / 1,000 / 5,000 / 10,000 / 50,000 / 100,000 calls/mo) with
   its label, and three rows (one per model, each with its colored dot) showing the
   projected monthly cost for that model at the selected volume.

7. All calculations should update live as the user types in any field, moves the output
   length slider, or moves the volume slider. Use the same per-MTok pricing as before:
   Haiku 4.5 $1.00/$5.00, Sonnet 4.6 $3.00/$15.00, Opus 4.8 $5.00/$25.00 per million input/
   output tokens. Format currency adaptively: 6 decimal places below $0.01, fewer decimals
   as the value grows, and standard 2-decimal formatting above $100.

Update prompt-builder.html, prompt-builder.css, and prompt-builder.js accordingly. Remove
any now-unused CSS classes and JS variables related to the old model-tab UI.
```

---

## Step 5 — Persona Generation Template (for new team personas)

Use this template whenever you want to create an additional persona file for a new role.
Fill in the bracketed sections.

```text
Create a new persona JSON file at personas/[file-name].json conforming to
personas/persona-schema.json, for the following role:

ROLE: [Job title, e.g. "Senior DevOps Engineer"]
EXPERIENCE LEVEL: [one of: a junior / a mid-level / a senior / a world-class expert]

BACKGROUND: [Describe the team, tech stack, tools, and domain knowledge this person has.
Be specific — name actual tools, frameworks, versions, and processes rather than generic
descriptions.]

AUDIENCE: [Who reads this person's output]

CONSTRAINTS: [Hard rules — languages/tools to use or avoid, conventions to follow, things
that must never be suggested]

DEFAULT TASK VERB: [one of: Write, Analyze, Summarize, Review, Generate, Compare, Explain,
Create, Debug, Translate, Rewrite, List, or leave blank]

ON UNKNOWN: [exactly one of:
  "Say 'I don't know' clearly rather than guessing"
  "Ask a clarifying question before proceeding"
  "Make a clearly labelled assumption and continue"
  "Provide a best-effort answer with a confidence caveat"]

ADDITIONAL PERMISSIONS: [Any extra things this persona is allowed/expected to do, e.g.
proactively flag certain issue types, cite certain authoritative sources]

OUTPUT FORMAT TYPE: [exactly one of the 8 schema-allowed format.type values]
OUTPUT LENGTH: [exactly one of the 4 schema-allowed format.length values]
ADDITIONAL FORMAT NOTES: [Any structural conventions specific to this role's deliverables]

Keep the file concise — aim for roughly 500-700 total words across all fields combined to
keep the persona's token footprint low. Avoid repeating the same idea in multiple fields,
avoid narrative framing ("Has experience with...", "Is familiar with..."), and prefer
dense keyword lists over full sentences where the meaning is still clear. Validate every
enum field against persona-schema.json before finalizing.
```

---

## Step 6 — Persona Token-Reduction Prompt

If an existing persona file grows too large (its background, constraints, or permission
fields become bloated with redundant prose), use this prompt to trim it.

```text
Update the persona file at personas/[file-name].json to cut back on tokens used. Apply
these specific edits:

1. Remove narrative openers like "Experienced in...", "Has a background in...", "Is
   familiar with..." — replace with dense, comma- or keyword-separated lists of the
   underlying tools/techniques/concepts. The model doesn't need to be told it's familiar
   with something; listing the term is sufficient.

2. Remove any sentence that restates information already conveyed by persona.role or
   meta.name (e.g. don't repeat "20 years of experience" if the role title or experience
   level already implies seniority).

3. Shorten meta.description to 1-2 sentences — it's a UI label, not a prompt input the
   model needs to reason over in depth.

4. Collapse multi-sentence constraint lists into single dense sentences using semicolons
   rather than separate sentences with repeated subjects.

5. Preserve every concrete fact: tool names, technique names, version numbers, file path
   conventions, structural templates (e.g. finding report formats), and all enum-valued
   fields must remain unchanged and schema-valid.

6. After editing, report the word count of context.background, context.constraints,
   permission.extra, and format.extra before and after, and the overall percentage
   reduction.

Re-validate all enum fields (persona.experience, task.verb, permission.onUnknown,
format.type, format.length) against personas/persona-schema.json after editing — they
must still match an allowed value character-for-character.
```

---

## Reference — Files Produced

Running Steps 1–4 in sequence (or the Master Prompt in Step 1 followed by Steps 2–4)
produces the following file structure:

```
prompt-architect/
├── prompt-builder.html
├── prompt-builder.css
├── prompt-builder.js
├── personas/
│   ├── persona-schema.json
│   ├── senior-csharp-mvc-developer.json
│   ├── project-manager.json
│   ├── software-tester.json
│   └── podgrabber-senior-frontend-developer.json
└── README.md   (see Step 7, optional)
```

---

## Step 7 — README Generation (optional)

```text
Generate a README.md file for this GitHub repository that explains how to use the
PromptArchitect application: how to open it (no build step, no server required), a
walkthrough of each of the 5 builder steps and what each field does, how the cost
estimator works and what it shows, how to load a persona JSON file (drag-and-drop or
click-to-browse), a table of the included personas, instructions and a full schema
reference for creating custom persona files (including every enum's allowed values),
the repository's file structure, browser compatibility notes, and a contributing section.
```
