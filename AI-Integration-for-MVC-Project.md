You are an expert software architect, DevOps engineer, and prompt engineer specializing in .NET 8/9 C# MVC applications.

Our goal is to build/update a highly granular, token-efficient Markdown documentation structure inside a folder named `/docs` located in the same root directory as our `.sln` file. This directory acts as the "External Brain" for AI tools to reduce token usage and assist in coding and operational communication.

### STEP 1: Audit & Rename Existing Folders
Before generating new files, check if there are existing unnumbered folders (e.g., `architecture`, `features`, `support`) inside `/docs`. If they exist:
1. Rename them to include the correct hierarchical numbering prefix shown below.
2. Ingest any existing documentation (like `README.md` files) found inside them so that no historical context is lost.

### STEP 2: Unified Folder Structure
Generate or update the following structure inside `/docs`. For any file or folder that does not yet exist, create a scaffold template with headers and placeholders so the team can fill them out later:

- `/docs/docs-config.md` -> Global tech stack specs and an updated index map of this entire directory.
- `/docs/1-architecture/` -> System boundaries, dependency rules, and data flow. (Ingest existing `architecture/` content here).
- `/docs/2-domain-models/` -> Granular files per business entity/aggregate mapping fields and relationships.
- `/docs/3-mvc-layers/` -> Summaries of Controllers, Views, and ViewModels mirroring our C# projects.
- `/docs/4-features/` -> Feature-specific active specs, functional requirements, and edge cases. (Ingest existing `features/` content here).
- `/docs/5-prompts/` -> Standardized engineering prompt templates (boilerplate, tests, reviews).
- `/docs/6-sessions/` -> Containing active task trackers (`SESSIONS.md`) and historical logs (`SESSIONS-ARCHIVE.md`).
- `/docs/7-support/` -> Stakeholder maps (`STAKEHOLDERS.md`), reorg logs (`OWNERSHIP-HISTORY.md`), and communication prompts (`/email-templates/`). (Ingest existing `support/` content here).

### STEP 3: Scaffolding and Execution Rules
- **Preserve Context**: Blend existing markdown documentation seamlessly into the new numbered folders.
- **Scaffold Missing Files**: If a file listed above is missing, generate it with standard Markdown headers, bullet points, and brief `<!-- TODO: Fill this in -->` placeholders.
- **Granularity**: Keep files short, atomic, and focused on exactly one responsibility to minimize token overhead.
- **Interlinking**: Use explicit Markdown relative links between files (e.g., `[Architecture Rules](../1-architecture/readme.md)`) so an AI agent can traverse the layers autonomously.

Provide the exact folder layout and the scaffolded file contents for any new, renamed, or missing files needed to complete this unified structure.
