# PromptArchitect

A browser-based tool that walks developers, project managers, and QA engineers through building structured, high-quality AI prompts — step by step. Load a team persona from a JSON file, fill in the guided fields, and copy a production-ready prompt in seconds.

No frameworks. No build step. No server. Drop the files in a folder and open `prompt-builder.html`.

---

## Features

- **5-step guided prompt builder** covering Persona, Context, Task, Permission, and Format
- **Live prompt preview** that rebuilds on every keystroke, with estimated token count
- **Prompt completeness meter** showing which sections are filled
- **API cost estimator** with real Anthropic pricing for Haiku 4.5, Sonnet 4.6, and Opus 4.8
- **Persona loader** — drag-and-drop or browse for a `.json` persona file to pre-fill all fields instantly
- **Included team personas** for a Senior C# MVC Developer, Project Manager, and Software Tester
- Fully vanilla HTML5, CSS3, and JavaScript — no dependencies, no build tools

---

## Getting Started

### 1. Clone or download the repository

```bash
git clone https://github.com/your-org/prompt-architect.git
cd prompt-architect
```

### 2. Open the application

Open `prompt-builder.html` directly in any modern browser:

```
prompt-builder.html   ← open this
prompt-builder.css
prompt-builder.js
personas/
  senior-csharp-mvc-developer.json
  project-manager.json
  software-tester.json
  persona-schema.json
```

> **Note:** Because the persona loader uses the `FileReader` API to read files you select yourself, no local web server is required. Simply double-click `prompt-builder.html` or use your IDE's "Open in Browser" feature.

If you prefer to serve it locally (e.g. for team access on a LAN):

```bash
# Python 3
python -m http.server 8080

# Node.js (npx)
npx serve .
```

Then visit `http://localhost:8080/prompt-builder.html`.

---

## Building a Prompt

The builder walks through five sequential sections. Each can be navigated using the pill navigation in the header, or the **Next / Back** buttons inside each step.

### Step 1 — Persona
Define who the AI is playing.

| Field | Required | Notes |
|---|---|---|
| Role / Job Title | Yes | e.g. `Senior C# ASP.NET Core MVC Web Developer` |
| Experience Level | No | Junior / Mid-level / Senior / Expert |
| Personality Traits | No | Comma-separated, e.g. `concise, opinionated about clean architecture` |

A live preview sentence updates as you type, showing exactly how the persona will open the prompt.

### Step 2 — Context
Tell the AI what it needs to know before it can help.

| Field | Required | Notes |
|---|---|---|
| Background / Situation | Yes | Tech stack, team structure, project domain |
| Target Audience | No | Who will read the output |
| Constraints / Guardrails | No | Rules to follow: language, libraries to avoid, word limits |

### Step 3 — Task
Specify the exact deliverable.

| Field | Required | Notes |
|---|---|---|
| Action Verb | Yes | Choose from Write, Analyze, Debug, Review, Generate, etc. |
| The Deliverable | Yes | What you want produced |
| Desired Outcome / Goal | No | Why you need it — helps the AI calibrate depth and tone |

### Step 4 — Permission
Tell the AI what to do when it is uncertain.

Choose one behaviour:
- Say "I don't know" clearly rather than guessing
- Ask a clarifying question before proceeding
- Make a clearly labelled assumption and continue
- Provide a best-effort answer with a confidence caveat

An optional free-text field lets you add specific permissions (e.g. "You may cite official Microsoft docs") or restrictions (e.g. "Do not speculate on legal matters").

### Step 5 — Preview
The finished prompt is assembled and displayed. From here you can:
- **Copy** the prompt to the clipboard with one click
- **Reset** all fields to start fresh
- Review the **quality rating** (Excellent / Good / Basic / Empty) based on how many sections are complete

---

## Cost Estimator

The right-hand panel shows a running cost estimate as you build your prompt, based on official [Anthropic API pricing](https://www.anthropic.com/pricing) (June 2026).

| Model | Input | Output |
|---|---|---|
| Claude Haiku 4.5 | $1.00 / MTok | $5.00 / MTok |
| Claude Sonnet 4.6 | $3.00 / MTok | $15.00 / MTok |
| Claude Opus 4.8 | $5.00 / MTok | $25.00 / MTok |

Switch between models using the tab selector. The **monthly volume slider** scales the per-call cost across 6 presets (100 → 100,000 calls/month) so you can forecast spend before committing to a model tier.

> Pricing shown is for informational purposes. Always verify current rates at [anthropic.com/pricing](https://www.anthropic.com/pricing).

---

## Persona Files

Persona files let any team member load a pre-configured set of defaults for their role. All five sections can be pre-filled, so a developer working in C# never has to re-type the tech stack context for every prompt session.

### Loading a persona

1. In the **Load persona** panel (top of the right sidebar), click the drop zone or drag a `.json` file onto it
2. All matching fields are populated instantly across every step
3. Edit any field — the loaded values are just starting points
4. Click **✕** on the loaded persona card to clear all fields and start fresh

### Included personas

| File | Role |
|---|---|
| `personas/senior-csharp-mvc-developer.json` | Senior C# ASP.NET Core MVC Web Developer |
| `personas/project-manager.json` | Senior Software Project Manager |
| `personas/software-tester.json` | Senior Software QA Engineer |

### Creating a custom persona

Copy any existing persona file and edit it. Only two fields are required:

```json
{
  "meta": {
    "name": "My Custom Persona",
    "description": "One or two sentences about what this persona is best used for."
  },
  "persona": {
    "role": "The job title the AI should adopt"
  }
}
```

All other fields are optional. If a field is absent, the corresponding form field is left blank for the user to fill in.

#### Full schema reference

```json
{
  "$schema": "./personas/persona-schema.json",

  "meta": {
    "name":        "Display name (shown in the persona card)",
    "description": "Short description of the persona's purpose",
    "version":     "1.0.0",
    "author":      "Team or individual who created this file",
    "tags":        ["tag1", "tag2"]
  },

  "persona": {
    "role":       "Job title the AI adopts",
    "experience": "a senior",
    "traits":     "concise, pragmatic, detail-oriented"
  },

  "context": {
    "background":  "Tech stack, domain knowledge, team setup",
    "audience":    "Who will read the output",
    "constraints": "Rules the AI must follow"
  },

  "task": {
    "verb":        "Write",
    "deliverable": "Leave blank — users fill this in per session",
    "goal":        "Leave blank — users fill this in per session"
  },

  "permission": {
    "onUnknown": "Ask a clarifying question before proceeding",
    "extra":     "Additional permissions or restrictions"
  },

  "format": {
    "type":   "Use code blocks with explanations below each",
    "length": "Be thorough — 500–800 words is acceptable",
    "extra":  "Any additional formatting instructions"
  }
}
```

#### Allowed values for constrained fields

Some fields must match a dropdown or radio option exactly. Refer to `personas/persona-schema.json` for the complete list. The most commonly customised ones are:

**`persona.experience`**
```
"a junior" | "a mid-level" | "a senior" | "a world-class expert"
```

**`task.verb`**
```
"Write" | "Analyze" | "Summarize" | "Review" | "Generate" |
"Compare" | "Explain" | "Create" | "Debug" | "Translate" | "Rewrite" | "List"
```

**`permission.onUnknown`**
```
"Say 'I don't know' clearly rather than guessing"
"Ask a clarifying question before proceeding"
"Make a clearly labelled assumption and continue"
"Provide a best-effort answer with a confidence caveat"
```

**`format.type`**
```
"Respond in plain prose paragraphs"
"Use markdown with headers and bullet points"
"Return a numbered list"
"Return a markdown table"
"Return valid JSON only, no prose"
"Use code blocks with explanations below each"
"Use a step-by-step numbered format"
"Write in Q&A format"
```

**`format.length`**
```
"Be concise — aim for under 150 words"
"Aim for 250–400 words"
"Be thorough — 500–800 words is acceptable"
"Be exhaustive and comprehensive — length is not a concern"
```

If a value doesn't match exactly, the loader will display a clear validation error and refuse to apply the file until it is corrected.

---

## File Structure

```
prompt-architect/
├── prompt-builder.html       # Main application — open this in a browser
├── prompt-builder.css        # All styles
├── prompt-builder.js         # All interactivity and persona loader logic
├── personas/
│   ├── persona-schema.json   # Full JSON schema and field documentation
│   ├── senior-csharp-mvc-developer.json
│   ├── project-manager.json
│   └── software-tester.json
└── README.md
```

---

## Browser Compatibility

| Browser | Minimum version |
|---|---|
| Chrome / Edge | 88+ |
| Firefox | 85+ |
| Safari | 14+ |

The application uses `FileReader`, `navigator.clipboard`, CSS custom properties, and `:has()` — all supported in any browser released since early 2021.

---

## Contributing

To add a new team persona, create a `.json` file in the `personas/` folder following the schema above, and open a pull request. The schema file (`persona-schema.json`) is the canonical reference for all allowed values.

For changes to the application itself, all logic is in the three root-level files. There is no build step — edit and refresh.

---

## License

MIT — see `LICENSE` for details.
