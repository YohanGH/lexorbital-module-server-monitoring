# Security Policy – LexOrbital

LexOrbital is a project **built around compliance and security by design**.  
This policy describes:

- which versions receive security updates,
- how to report vulnerabilities,
- what maintainers commit to in terms of handling and disclosure.

---

## Supported Versions

LexOrbital is currently in its early development phase.  
At this stage, **only the `main` branch and the latest stable minor release** receive security fixes.

| Version / Branch         | Status                  | Security Support |
| ------------------------ | ----------------------- | ---------------- |
| `main` (development)     | Active development      | ✅ Supported     |
| `0.1.x` (first stable)   | Early stable            | ✅ Supported     |
| `< 0.1.0` (experimental) | Obsolete / experimental | ❌ Not supported |

> ⚠️ Tags or branches marked as `experimental`, `playground`, or similar  
> must **not** be used in production and are not covered by any security commitment.

As the project evolves, this section will be updated to define:

- LTS versions,
- support duration per branch,
- backport policy for patches.

---

## Reporting a Vulnerability

Please **do not open a public issue** to report a security problem.

Use one of the private channels below:

### 1. GitHub Security Advisories (recommended)

If enabled on the repository, use:

**Security → “Report a vulnerability”**

This creates a private and encrypted channel between you and the maintainers.

### 2. Private contact (fallback)

If Security Advisories are not available, please contact the maintainer privately  
(email or secure channel indicated in the project README).

Please use the subject line:

**`[LexOrbital] Security Report`**

Include the following information:

- Affected version/branch (`main`, `0.1.x`, etc.)
- Affected module (e.g. `lexorbital-core`, `lexorbital-module-auth`)
- Clear description of the vulnerability
- Steps to reproduce / Proof of Concept (if possible)
- Estimated impact (data leak, privilege escalation, RCE, DoS, etc.)
- Environment/context (OS, Node version, configuration)

---

## Response Time & Process

Maintainers aim to:

- **acknowledge receipt** within **7 business days**,
- **review** the vulnerability and classify severity promptly,
- **prepare or plan** a fix for supported versions.

You can expect:

1. Initial acknowledgement
2. Technical assessment (severity, scope, affected modules)
3. Estimated timeline for a fix
4. Proposal for **coordinated disclosure**

---

## Responsible Disclosure

LexOrbital follows a **responsible disclosure** model.

Please:

- Do **not** publish technical details, PoCs, or exploits  
  **until a fix is available** for supported versions.
- After the fix is released, maintainers may:
  - credit you in the release notes (optional),
  - publish a technical explanation of the issue without exposing sensitive details.

For critical vulnerabilities (e.g., data exfiltration, RCE):

- a priority fix will be prepared,
- a dedicated release may be issued,
- a clear notice will be added to the changelog or documentation.

---

## Scope of This Policy

This security policy applies to:

- `lexorbital-core`
- official modules (`lexorbital-module-*`)
- orchestration stacks (`lexorbital-stack`)
- infra (`lexorbital-infra`)

It **does not** cover:

- third-party modules,
- forks,
- community-maintained variants.

Such repositories must define their own security policies.

---

Thank you for helping make **LexOrbital** a project aligned with its mission:  
**simplicity, modularity, compliance, and security by design.**
