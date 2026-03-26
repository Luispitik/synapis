# /clone -- Project Cloning

> Clone a successful project as the foundation for a new one.
> Copies skills, configuration, structure, and optionally instincts.

---

## Trigger

Run with `/clone` or "clone this project".

---

## Process

### Step 1: Select Source

```
PROJECT CLONING

  Source options:
  1. Current project ({project-name})
  2. Select from known projects:

  #  Project              Skills  Instincts  Last Active
  a. project-alpha          12       45      2 days ago
  b. project-beta            8       23      1 week ago
  c. project-gamma           5       12      3 weeks ago

  Enter number/letter or project path: _
```

### Step 2: Configure Target

```
  New project name: _
  New project path: _
  Description (optional): _
```

### Step 3: Select What to Clone

```
  What should the new project inherit?

  [x] .claude/commands/ (all installed skills)
  [x] CLAUDE.md (project configuration)
  [ ] Instincts (project-scoped patterns)
  [ ] Passive rules
  [ ] Observation log
  [ ] Custom commands
  [ ] Environment structure (.env.local template)

  Toggle with numbers, [A] All, [N] None, [Enter] Confirm
```

### Step 4: Customize

```
  What should change in the new project?

  - Project name: {old} -> {new}
  - Any tech stack changes? (e.g., different DB, framework)
  - Any skills to remove? (not needed for new project)
  - Any skills to add? (new requirements)

  Describe changes or [Enter] to keep as-is: _
```

### Step 5: Execute

1. Create target directory structure
2. Copy selected files, applying name/path substitutions
3. Modify CLAUDE.md with new project context
4. Register new project in `_projects.json`
5. Create project blueprint in `_operator-state.json`
6. If instincts were copied, reset their occurrence counters

### Step 6: Confirm

```
CLONE COMPLETE

  Source: project-alpha
  Target: new-project at /path/to/new-project

  Copied:
    12 skills
    CLAUDE.md (customized)
    45 instincts (counters reset)

  New project registered in _projects.json
  Blueprint saved for future cloning

  Next steps:
  - cd /path/to/new-project
  - Review CLAUDE.md for any needed adjustments
  - Run /system-status to verify setup
```
