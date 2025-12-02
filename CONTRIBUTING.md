## 1. How to Contribute

You can contribute by:

- proposing ideas (Feature / Enhancement issue)
- reporting bugs
- improving documentation
- proposing a new module
- submitting pull requests
- helping test existing modules

Before contributing:

1. Read the **Code of Conduct**
2. Read the **Security Policy**
3. Understand the architecture (Meta-Kernel / Rings / Modules)

---

## 2. Architectural Principles

LexOrbital consists of three layers:

### **A. Meta-Kernel — Must not be modified without prior discussion**

Represents:

- global conventions,
- front/back contracts,
- compliance rules,
- security defaults,
- secret/env management.

🛑 Any change requires an **Architecture / Module Proposal** issue.

### **B. Rings (Front / Back)**

Contain:

- APIs,
- integration contracts,
- module docking protocols.

Minor adjustments allowed via standard PR.

### **C. Modules**

Modules must:

- use the official module template,
- be autonomous (docker, tests, doc),
- expose a manifest,
- avoid inter-module dependencies.

A proposal issue is required prior to development.

---

## 3. Git Conventions

### Commit messages — Conventional Commits

**Note** : Ce module est un **module d'infrastructure**. Les conventions de commit sont gérées par **pre-commit** (et non Husky/commitlint qui sont réservés aux modules applicatifs).

Examples:

- feat(ansible): add docker provisioning role
- fix(backup): prevent backup failure when directory is empty
- docs(security): update SSH hardening guide

### Branch naming

- feature/<short-name>
- fix/<short-name>
- docs/<topic>
- refactor/<topic>
- module/<name>

## 4. Creating a Module

1. Open an issue: **Architecture / Module Proposal**
2. Discuss manifest and structure
3. Clone the template module
4. Implement:
   - minimal Dockerfile
   - minimal CI
   - manifest file
   - tests
   - documentation
5. Submit the PR to the module repository
6. Maintainers will integrate into `lexorbital-core` via **git subtree**

🛑 Never open PRs directly modifying `lexorbital-core/modules/*`.

---

## 5. Pull Request Process

PRs must:

- follow project conventions,
- include a clear description,
- include tests if applicable,
- update documentation if needed,
- pass CI.

Maintainers may request:

- revisions,
- refactoring,
- clarification of APIs,
- diagrams for structural changes.

---

## 6. Reporting Issues

Use the GitHub templates:

- Bug report
- Feature request
- Documentation issue
- Architecture / Module proposal

Security issues must follow **SECURITY.md**  
and **must not be reported publicly**.

---

## 7. Local Development

### For this infrastructure module:

This is an **infrastructure module** (Bash + Ansible), not an applicative module.

**Setup**:
```bash
# Install Ansible
sudo apt install ansible  # Debian/Ubuntu
# or
brew install ansible      # macOS

# Install linting tools (recommended)
pip install ansible-lint yamllint
sudo apt install shellcheck shfmt  # or brew install
```

**Testing Ansible playbooks**:
```bash
cd ansible
ansible-playbook playbooks/site.yml --check  # Dry-run
ansible-playbook playbooks/site.yml --limit staging  # Test on staging
```

**Testing shell scripts**:
```bash
shellcheck scripts/*.sh
shfmt -d scripts/*.sh
```

### For lexorbital-core:

Modules appear under `/modules` via subtree.

---

## 8. Style Guides

### TypeScript

- strict mode recommended
- avoid unchecked `any`
- explicit types for public interfaces
- prefer pure functions over unnecessary classes

### Node.js / Backend

- minimal Express/Fastify
- structured JSON logs
- lightweight middlewares
- minimal dependencies

### React / Frontend

- function components only
- hooks for shared logic
- minimalistic, technical UI
- strict prop typing

---

# Thank you ❤️

Thank you for helping shape **LexOrbital** —
a modular, compliant, and secure orbital architecture for web systems.
