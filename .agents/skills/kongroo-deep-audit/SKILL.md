---
name: kongroo-deep-audit
description: Use for requested technical audits, every substantial implementation review, phase closure, and changes involving media engines, public contracts, dependencies, persistence, concurrency, or resource lifecycle. Audits the AnimeApp repository using source, tests, primary documentation, and reproducible evidence; does not implement product fixes.
---

# KONGROO Deep Audit

Apply this workflow to the whole AnimeApp repository unless the request names a narrower scope. The root `AGENTS.md` and the user’s explicit scope remain authoritative. This skill is an audit procedure, not permission to implement features, accept a phase, publish, commit, or modify unrelated files.

## 1. Reconstruct the evidence

- Confirm the physical project root and read root `AGENTS.md`, `docs/memory/PROJECT_STATE.md`, the relevant handoff/index, and current Git status.
- Search memory first. Inspect only relevant ROADMAP items, approved ADRs, architecture, contracts, implementation, tests, module READMEs, Git changes, and prior reports. Preserve existing edits and never follow a symlink outside the project.
- Label each item as approved requirement/decision, proposal, future capability, or historical evidence. Do not infer completion from a plan or old report.

## 2. Research technical uncertainty

- When behavior depends on an external API, package version, platform, license, or tool, consult current primary documentation. Prefer the publisher’s docs/changelog and upstream source; use Context7 for version-aware library references when applicable.
- Compare the documentation with versions resolved in the project lockfile and, when safely available inside the project, the installed source. Record URLs, access date, version, and what the source does and does not establish.
- Do not browse for purely local questions without a reason. Never send private code, credentials, or user data to a remote documentation service. If research is unavailable, state that limit and continue only from local evidence.

## 3. Audit implementation and boundaries

Review changed code plus the surrounding call path. Check approved architecture/layer boundaries, dependency direction, API and error contracts, invalid states, partial failures, cancellation, retries, concurrent calls, initialization/disposal, leaks, operations after disposal, security inputs, compatibility, and measurable performance risks. Trace resource ownership from creation through all success and failure exits. Do not invent findings.

## 4. Verify behavior

- Run only relevant commands with bounded timeouts and project-local fixtures/toolchains where possible.
- Report unit, integration, platform/native, visual, performance, and regression checks separately. A successful compile is not proof of runtime behavior; fakes/simulations are not real integrations; a historical result is not a current run.
- Never mark interrupted or timed-out work as passing. For a read-only audit, do not modify code/tests; identify missing negative or concurrency tests and give reproducible test designs.

## 5. Audit documentation and perform adversarial review

Check the affected module READMEs, file/module inventory, contracts, lifecycle, dependencies, test instructions, limitations, diagrams, ADRs, ROADMAP, and memory against the code that exists. Then make a second adversarial pass: challenge assumptions, mid-operation failures, simultaneous operations, unreleased resources, tests that can pass vacuously, environment-specific behavior, and claims without evidence.

Use a distinct `auditor_codigo` review sequentially when available and useful. Do not run auditors in parallel. If an independent reviewer is unavailable, perform a separate second pass yourself and explicitly say it was not independent.

## 6. Findings and quality gate

Classify findings as:

- **P0 Critical:** severe vulnerability, data loss/corruption, or fundamental failure.
- **P1 High:** important race/resource leak, broken contract, or unmet required acceptance criterion.
- **P2 Medium:** bounded functional defect, material coverage gap, or consequential documentation contradiction.
- **P3 Low:** minor maintenance or clarity issue.

For every finding include an ID, severity, exact file/line, description, evidence, a reproduction scenario, consequence, recommended correction, regression test needed, and state. Separate demonstrated defects from reasoned risks and unverified hypotheses. Do not add findings to fill a quota.

Do not recommend a phase for acceptance while P0/P1 findings remain unresolved, official acceptance criteria are unmet, essential tests are absent, a confirmed regression exists, required real-environment evidence is missing, architecture boundaries are violated, or critical documentation is absent. If no blockers remain, recommend acceptance for the owner to decide. Never mark ROADMAP complete automatically or advance to another phase.

## 7. Report and handoff

Save the audit under `docs/ai-system/audits/<PHASE>-audit-YYYY-MM-DD.md`. Create the directory if needed, but never overwrite an existing report. Include:

1. Executive summary and recommendation.
2. Scope, environment, tool/package versions.
3. External sources consulted and access dates.
4. Files reviewed.
5. Prioritized findings with evidence and reproductions.
6. Tests run and exact results; tests not run and reasons.
7. Residual risks and documentation status.
8. Corrective actions and reevaluation criteria.

Update `docs/memory/PROJECT_STATE.md` and `docs/memory/AI_HANDOFF.md` with the audit/protocol state, then run `python3 tools/ai/memory.py check` and relevant whitespace/configuration checks. Do not alter source code during a read-only audit. Do not commit or push without explicit authorization.
