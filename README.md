# Synapis v3.2

### The skill system for Claude Code that learns and adapts to you.

> Stop explaining the same thing twice. Synapis remembers, learns, and gets better with every session.

---

## What is Synapis?

Synapis is an intelligent skill management system for [Claude Code](https://claude.ai/code). It solves a fundamental problem: **Claude Code forgets everything between sessions.**

Every time you start a new session, Claude starts from zero. Your preferences, your tech stack, your workflows, your past decisions — all gone. You end up repeating yourself. Again. And again.

**Synapis fixes this.** It gives Claude Code:

- **Memory that persists** across sessions and projects
- **Skills that load on demand** instead of all at once
- **A learning engine** that observes what you do and creates reusable patterns
- **A router** that knows which tools you need for each project

Think of it as going from a dumb terminal to an assistant that actually knows you.

---

## The Problem (Before Synapis)

| Issue | Impact |
|-------|--------|
| All skills loaded every session | ~25,000 tokens wasted before you say a word |
| No memory between sessions | You explain your stack, preferences, and context every time |
| No memory between projects | Decisions in project A don't carry to project B |
| No skill management | 50+ skills compete for attention, most irrelevant |
| No learning | Claude doesn't improve from session to session |

**In short: you do the same work over and over, and Claude never gets smarter.**

---

## The Solution (With Synapis)

| Feature | How it works |
|---------|-------------|
| **Skills on Demand** | Only loads the skills your current project needs (~2,500 tokens vs ~25,000) |
| **Operator State** | Your identity, stack, and decisions persist across ALL projects |
| **Synapsis Engine** | Observes your work silently, detects patterns, creates reusable skills |
| **Skill Router** | Matches your intent to the right skills from a dormant catalog |
| **Passive Rules** | Technical guardrails that fire automatically (security, quality, workflow) |
| **Project Cloning** | Clone a successful project as the base for a new one — skills, structure, and all |

**Result: 90% less token waste. Zero repetition. Claude that actually improves.**

---

## Quick Start

### Requirements
- [Claude Code](https://claude.ai/code) installed
- Git

### Installation

**macOS / Linux:**
```bash
git clone https://github.com/Luispitik/synapis.git
cd synapis
chmod +x install.sh
./install.sh
```

**Windows:**
```cmd
git clone https://github.com/Luispitik/synapis.git
cd synapis
install.bat
```

**That's it.** Open Claude Code in any project. Synapis handles the rest.

---

## What Happens After Install

1. **You open Claude Code** in any project folder
2. **Synapis detects it's your first time** and launches onboarding
3. **It searches for existing context** (prior CLAUDE.md, memory files, git history)
4. **If it finds something**, it shows you: "I found this about you. Correct?"
5. **If not**, it offers two paths:
   - **Quick** — 3 questions, start working in 30 seconds
   - **Complete** — Tell me everything, never repeat yourself again
6. **Your context is saved** in the Operator State — applies to ALL future projects

From that point on, every session starts with Claude already knowing who you are, what you use, and how you work.

---

## How It Works

### The Session Flow

```
Open Claude Code
       |
       v
  CLAUDE.md loads
  (entry point)
       |
       v
  Read Operator State
  (your identity + decisions)
       |
       v
  Launcher appears:
  [1] Skills on Demand
  [2] Skill Picker (manual)
  [3] Freestyle (vanilla)
       |
       v
  Skill Router matches
  your project to skills
       |
       v
  Install ONLY what
  you need (2,500 tokens
  instead of 25,000)
       |
       v
  You work normally
  Synapsis observes silently
```

### The Learning Loop

```
  You work on your project
         |
         v
  Synapsis detects patterns
  ("You've done this 3 times...")
         |
         v
  Creates an Instinct
  (atomic rule + confidence 0-100%)
         |
         v
  When confidence >= 80%
  /evolve suggests promotion
         |
         v
  You choose: create Skill,
  Command, Agent, Rule, or Skip
         |
         v
  New skill added to catalog
  Available for ALL projects
         |
         v
  Cycle repeats.
  Every session feeds the next.
```

---

## Commands

| Command | What it does |
|---------|-------------|
| `/system-status` | Full dashboard: skills, tokens, projects, health |
| `/evolve` | Analyze mature patterns, create skills/rules/commands |
| `/clone` | Clone a project as base for a new one |
| `/skill-audit` | Deep scan of installed skills with cleanup proposals |
| `/passive-status` | Which passive rules fire, which never triggered |
| `/instinct-status` | All learned patterns with confidence scores |
| `/analyze-observations` | Process observation logs, suggest new skills |
| `/promote` | Promote project-specific patterns to global |
| `/projects` | List all known projects with stats |

---

## Architecture

```
~/.claude/
  CLAUDE.md                  <-- Entry point (loaded every session)
  skills/
    skill-router/            <-- Orchestrator (always active)
    synapis-learning/        <-- Learning engine (always active)
    synapis-instincts/       <-- Knowledge base (always active)
    synapis-researcher/      <-- Deep research (always active)
    synapis-optimizer/       <-- Context optimization (always active)
    _library/                <-- Dormant skills (installed on demand)
    _archived/               <-- Retired skills (recoverable)
    _catalog.json            <-- Skill registry with token estimates
    _passive-rules.json      <-- Automatic guardrails
    _operator-state.json     <-- Your identity + decisions (cross-project)
    _projects.json           <-- Project registry
  commands/                  <-- Slash commands (/evolve, /clone, etc.)
```

### Token Budget

| Component | Tokens | When |
|-----------|--------|------|
| 5 global skills | ~2,700 | Every session |
| Passive rules | ~155 | Every session |
| Operator state | ~200-500 | Every session |
| Project skills | ~500-2,000 | Per project |
| **Total** | **~3,500-5,500** | vs ~25,000 before |

---

## For Existing Users

Already have skills installed? Run `/skill-audit` after installing Synapis.

It will:
1. Scan all your existing skills and commands
2. Calculate token overhead per skill
3. Detect duplicates and conflicts
4. Propose a cleanup plan with token savings
5. Ask permission before changing anything

**Nothing is deleted without your approval.** Everything archived is recoverable.

---

## FAQ

**Does this work with any Claude Code project?**
Yes. Synapis is project-agnostic. It adapts to whatever you're building.

**Will it slow down Claude?**
The opposite. By reducing token overhead by 90%, Claude has more context for actual work.

**Can I use it without the learning system?**
Yes. Choose [3] Freestyle in the launcher for vanilla Claude Code.

**Can I create my own skills?**
Yes. Use `/evolve` to turn mature patterns into skills, or create them manually in `_library/`.

**Does it work on Windows, Mac, and Linux?**
Yes. Installers for all three platforms included.

---

## Want More?

Synapis is the open-source foundation. If you want:

- **Custom skills** for your business or industry
- **Mentoring** on how to build and optimize your own skill system
- **Advanced features** like marketplace integration and team sharing
- **Training** for your team on Claude Code + Synapis

Visit **[salgadoia.com](https://salgadoia.com)** for mentoring, courses, and consulting.

---

## License

Synapis is **source-available** under a custom license:

- **Free** for personal and internal business use
- **Free** to study, modify, and learn from
- **Commercial exploitation** exclusively reserved to Luis Salgado / SalgadoIA

See [LICENSE](LICENSE) for full terms.

---

## Credits

Built by [Luis Salgado](https://salgadoia.com) — AI consultant, developer, and educator.

Powered by [Claude Code](https://claude.ai/code) by Anthropic.

---

*Synapis: because your AI assistant should remember who you are.*
