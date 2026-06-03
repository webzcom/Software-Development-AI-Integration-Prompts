You are an expert software architect, operations manager, and prompt engineer specializing in .NET 8/9 C# MVC applications managed across a volatile, fast-changing enterprise portfolio.

Our goal is to build/update a highly granular, token-efficient Markdown documentation structure inside a folder named `/docs` located in the same root directory as our `.sln` file. This directory acts as the "External Brain" for AI tools to drastically reduce token usage and assist in both coding and operational support communication.

Review our current directory structure, code, and stakeholder requirements, then generate or update the following structure inside `/docs`:

1.  `/docs/docs-config.md` -> Global tech stack specs and a map of this directory.
2.  `/docs/1-architecture/` -> Architecture boundaries and dependency rules.
3.  `/docs/2-domain-models/` -> Granular files per business entity/aggregate.
4.  `/docs/3-mvc-layers/` -> Controller, View, and ViewModel summaries.
5.  `/docs/4-features/` -> Feature-specific active specs and edge cases.
6.  `/docs/5-prompts/` -> Standardized engineering prompts (boilerplate, unit tests).
7.  `/docs/6-sessions/` -> Active task trackers (`SESSIONS.md`) and historical log (`SESSIONS-ARCHIVE.md`).
8.  `/docs/7-support/` -> Stakeholder communication maps (`STAKEHOLDERS.md`), reorganization tracking logs (`OWNERSHIP-HISTORY.md`), and granular communication prompt subfolders (`/email-templates/`).

### Execution Rules:
- Create or update the specific markdown files needed based on our actual project files and team setup.
- Keep every file short, atomic, and focused on exactly one responsibility.
- Use explicit Markdown relative links between files so an AI agent can traverse the layers.
- Do not paste massive blocks of raw C# code; use structural summaries.
- Ensure the support folder contains enough granular stakeholder metadata so the AI can accurately draft communication and identify current applications owners during reorgs.

Provide the exact folder layout and the file contents for any new or missing files needed to complete this structure.