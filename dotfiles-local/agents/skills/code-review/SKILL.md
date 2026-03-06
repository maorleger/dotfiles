---
name: code-review
description: Review code changes in azure sdk for correctness, performance, and consistency with project conventions. Use when reviewing PRs or code changes.
---

## Determining What to Review

Based on the input provided (`$ARGUMENTS` is the text the user typed after the skill invocation, e.g. a commit hash, branch name, or PR URL), determine which type of review to perform:

1. **No arguments (default)**: Review all uncommitted changes
   - Run: `git diff` for unstaged changes
   - Run: `git diff --cached` for staged changes
   - Run: `git status --short` to identify untracked (net new) files

2. **Commit hash** (40-char SHA or short hash): Review that specific commit
   - Run: `git show $ARGUMENTS`

3. **Branch name**: Compare current branch to the specified branch
   - Run: `git diff $ARGUMENTS...HEAD`

4. **PR URL or number** (contains "github.com" or "pull" or looks like a PR number): Review the pull request
   - Run: `gh pr view $ARGUMENTS` to get PR context
   - Run: `gh pr diff $ARGUMENTS` to get the diff

Use best judgement when processing input.

---

**Reviewer mindset:** Be polite but very skeptical. Your job is to help speed the review process for maintainers, which includes not only finding problems the PR author may have missed but also questioning the value of the PR in its entirety. Treat the PR description and linked issues as claims to verify, not facts to accept. Question the stated direction, probe edge cases, and don't hesitate to flag concerns even when unsure.

## Review Process

### Step 0: Gather Code Context (No PR Narrative Yet)

Before analyzing anything, collect as much relevant **code** context as you can. **Critically, do NOT read the PR description, linked issues, or existing review comments yet.** You must form your own independent assessment of what the code does, why it might be needed, what problems it has, and whether the approach is sound — before being exposed to the author's framing. Reading the author's narrative first anchors your judgment and makes you less likely to find real problems.

1. **Diff and file list**: Fetch the full diff and the list of changed files.
2. **Full source files**: For every changed file, read the **entire source file** (not just the diff hunks). You need the surrounding code to understand invariants, locking protocols, call patterns, and data flow. Diff-only review is the #1 cause of false positives and missed issues.
3. **Consumers and callers**: If the change modifies a public/internal API, a type that others depend on, or a virtual/interface method, search for how consumers use the functionality. Grep for callers, usages, and test sites. Understanding how the code is consumed reveals whether the change could break existing behavior or violate caller assumptions.
4. **Key utility/helper files**: If the diff calls into shared utilities, read those to understand the contracts (thread-safety, idempotency, etc.).
5. **Git history**: Check recent commits to the changed files (`git log --oneline -20 -- <file>`). Look for related recent changes, reverts, or prior attempts to fix the same problem. This reveals whether the area is actively churning, whether a similar fix was tried and reverted, or whether the current change conflicts with recent work.

### Step 1: Form an Independent Assessment

Based **only** on the code context gathered above (without the PR description or issue), answer these questions:

1. **What does this change actually do?** Describe the behavioral change in your own words by reading the diff and surrounding code. What was the old behavior? What is the new behavior?
2. **Why might this change be needed?** Infer the motivation from the code itself. What bug, gap, or improvement does it appear to address?
3. **Is this the right approach?** Would a simpler alternative be more consistent with the codebase? Could the goal be achieved with existing functionality? Are there correctness, performance, or safety concerns?
4. **What problems do you see?** Identify bugs, edge cases, missing validation, thread-safety issues, performance regressions, API design problems, test gaps, and anything else that concerns you.

Write down your independent assessment before proceeding. You must produce a holistic assessment (see [Holistic PR Assessment](#holistic-pr-assessment)) at this stage.

### Step 2: Incorporate PR Narrative and Reconcile

Now read the PR description, labels, linked issues (in full), author information, existing review comments, and any related open issues in the same area. Treat all of this as **claims to verify**, not facts to accept.

1. **PR metadata**: Fetch the PR description, labels, linked issues, and author. Read linked issues in full — they often contain the repro, root cause analysis, and constraints the fix must satisfy.
2. **Related issues**: Search for other open issues in the same area (same labels, same component). This can reveal known problems the PR should also address, or constraints the author may not be aware of.
3. **Existing review comments**: Check if there are already review comments on the PR to avoid duplicating feedback.
4. **Reconcile your assessment with the author's claims.** Where your independent reading of the code disagrees with the PR description or issue, investigate further — but do not simply defer to the author's framing. If the PR claims a bug fix, a performance improvement, or a behavioral correction, verify those claims against the code and any provided evidence. If your independent assessment found problems the PR narrative doesn't acknowledge, those problems are more likely to be real, not less.
5. **Update your holistic assessment** if the additional context reveals information that genuinely changes your evaluation (e.g., a linked issue proves the bug is real, or an existing review comment already identified the same concern). But do not soften findings just because the PR description sounds reasonable.

### Step 3: Detailed Analysis

1. **Focus on what matters.** Prioritize bugs, performance regressions, safety issues, race conditions, resource management problems, incorrect assumptions about data or state, and API design problems. Do not comment on trivial style issues unless they violate an explicit rule below.
2. **Consider collateral damage.** For every changed code path, actively brainstorm: what other scenarios, callers, or inputs flow through this code? Could any of them break or behave differently after this change? If you identify any plausible risk — even one you can't fully confirm — surface it so the author can evaluate. Do not dismiss behavioral changes because you believe the fix justifies them. The tradeoff is the author's decision — your job is to make it visible.
3. **Be specific and actionable.** Every comment should tell the author exactly what to change and why. Reference the relevant convention. Include evidence of how you verified the issue is real, e.g., "looked at all callers and none of them validate this parameter".
4. **Flag severity clearly:**
   - ❌ **error** — Must fix before merge. Bugs, security issues, API violations, test gaps for behavior changes.
   - ⚠️ **warning** — Should fix. Performance issues, missing validation, inconsistency with established patterns.
   - 💡 **suggestion** — Consider changing. Style improvements, minor readability wins, optional optimizations.
5. **Don't pile on.** If the same issue appears many times, flag it once on the primary file with a note listing all affected files. Do not leave separate comments for each occurrence.
6. **Respect existing style.** When modifying existing files, the file's current style takes precedence over general guidelines.
7. **Don't flag what CI catches.** Do not flag issues that a linter, typechecker, compiler, analyzer, or CI build step would catch, e.g., missing imports, unsupported syntax, formatting. Assume CI will run separately.
8. **Avoid false positives.** Before flagging any issue:
   - **Verify the concern actually applies** given the full context, not just the diff. Open the surrounding code to check. Confirm the issue isn't already handled by a caller, callee, or wrapper layer before claiming something is missing.
   - **Skip theoretical concerns with negligible real-world probability.** "Could happen" is not the same as "will happen."
   - **If you're unsure, either investigate further until you're confident, or surface it explicitly as a low-confidence question rather than a firm claim.** Do not speculate about issues you have no concrete basis for. Every comment should be worth the reader's time.
   - **Trust the author's context.** The author knows their codebase. If a pattern seems odd but is consistent with the repo, assume it's intentional.
   - **Never assert that something "does not exist," "is deprecated," or "is unavailable" based on training data alone.** Your knowledge has a cutoff date. When uncertain, ask rather than assert.
9. **Ensure code suggestions are valid.** Any code you suggest must be syntactically correct and complete. Ensure any suggestion would result in working code.
10. **Label in-scope vs. follow-up.** Distinguish between issues the PR should fix and out-of-scope improvements. Be explicit when a suggestion is a follow-up rather than a blocker.

---

## Review Output Format

When presenting the final review (whether as a PR comment or as output to the user), use the following structure. This ensures consistency across reviews and makes the output easy to scan.

### Structure

```
## Code Review — PR #<number>

### Holistic Assessment

**Motivation**: <1-2 sentences on whether the PR is justified and the problem is real>

**Approach**: <1-2 sentences on whether the fix/change takes the right approach>

**Summary**: <✅ LGTM / ⚠️ Needs Human Review / ⚠️ Needs Changes / ❌ Reject>. <2-3 sentence summary of the overall verdict and key points. If "Needs Human Review," explicitly state which findings you are uncertain about and what a human reviewer should focus on.>

---

### Detailed Findings

#### ✅/⚠️/❌ <Category Name> — <Brief description>

<Explanation with specifics. Reference code, line numbers, interleavings, etc.>

(Repeat for each finding category. Group related findings under a single heading.)
```

### Guidelines

- **Holistic Assessment** comes first and covers Motivation, Approach, and Summary.
- **Detailed Findings** uses emoji-prefixed category headers:
  - ✅ for things that are correct / look good (use to confirm important aspects were verified)
  - ⚠️ for warnings or impactful suggestions (should fix, or follow-up)
  - ❌ for errors (must fix before merge)
  - 💡 for minor suggestions or observations (nice-to-have)
- **Cross-cutting analysis** should be included when relevant: check whether related code (sibling types, callers, other platforms) is affected by the same issue or needs a similar fix.
- **Test quality** should be assessed as its own finding when tests are part of the PR.
- **Summary** gives a clear verdict: LGTM (no blocking issues — use only when confident), Needs Human Review (code may be correct but you have unresolved concerns or uncertainty that require human judgment), Needs Changes (with blocking issues listed), or Reject (explaining why this should be closed outright). **Never give a blanket LGTM when you are unsure.** When in doubt, use "Needs Human Review" and explain what a human should focus on.
- Keep the review concise but thorough. Every claim should be backed by evidence from the code.

### Verdict Consistency Rules

The summary verdict **must** be consistent with the findings in the body. Follow these rules:

1. **The verdict must reflect your most severe finding.** If you have any ⚠️ findings, the verdict cannot be "LGTM." Use "Needs Human Review" or "Needs Changes" instead. Only use "LGTM" when all findings are ✅ or 💡 and you are confident the change is correct and complete.

2. **When uncertain, always escalate to human review.** If you are unsure whether a concern is valid, whether the approach is sufficient, or whether you have enough context to judge, the verdict must be "Needs Human Review" — not LGTM. Your job is to surface concerns for human judgment, not to give approval when uncertain. A false LGTM is far worse than an unnecessary escalation.

3. **Separate code correctness from approach completeness.** A change can be correct code that is an incomplete approach. If you believe the code is right for what it does but the approach is insufficient (e.g., treats symptoms without investigating root cause, silently masks errors that should be diagnosed, fixes one instance but not others), the verdict must reflect the gap — do not let "the code itself looks fine" collapse into LGTM.

4. **Classify each ⚠️ and ❌ finding as merge-blocking or advisory.** Before writing your summary, decide for each finding: "Would I be comfortable if this merged as-is?" If any answer is "no," the verdict must be "Needs Changes." If any answer is "I'm not sure," the verdict must be "Needs Human Review."

5. **Devil's advocate check before finalizing.** Re-read all your ⚠️ findings. For each one, ask: does this represent an unresolved concern about the approach, scope, or risk of masking deeper issues? If so, the verdict must reflect that tension. Do not default to optimism because the diff is small or the code is obviously correct at a syntactic level.

---

## Holistic PR Assessment

Before reviewing individual lines of code, evaluate the PR as a whole. Consider whether the change is justified, whether it takes the right approach, and whether it will be a net positive for the codebase.

### Motivation & Justification

- **Every PR must articulate what problem it solves and why.** Don't accept vague or absent motivation. Ask "What's the rationale?" and block progress until the contributor provides a clear answer.
- **Challenge every addition with "Do we need this?"** New code, APIs, abstractions, and flags must justify their existence. If an addition can be avoided without sacrificing correctness or meaningful capability, it should be.
- **Demand real-world use cases and customer scenarios.** Hypothetical benefits are insufficient motivation for expanding API surface area or adding features. Require evidence that real users need this.

### Evidence & Data

- **Require measurable performance data before accepting optimization PRs.** Demand benchmark results or equivalent proof — never accept performance claims at face value.
- **Distinguish real performance wins from micro-benchmark noise.** Trivial benchmarks with predictable inputs overstate gains. Require evidence from realistic, varied inputs.
- **Investigate and explain regressions before merging.** Even if a PR shows a net improvement, regressions in specific scenarios must be understood and explicitly addressed — not hand-waved.

### Approach & Alternatives

- **Check whether the PR solves the right problem at the right layer.** Look for whether it addresses root cause or applies a band-aid. Prefer fixing the actual source of an issue over adding workarounds to production code.
- **When a PR takes a fundamentally wrong approach, redirect early.** Don't iterate on implementation details of a flawed design. Push back on the overall direction before the contributor invests more time.
- **Ask "Why not just X?" — always prefer the simplest solution.** When a PR uses a complex approach, challenge it with the simplest alternative that could work. The burden of proof is on the complex solution.

### Cost-Benefit & Complexity

- **Explicitly weigh whether the change is a net positive.** A performance trade-off that shifts costs around is not automatically beneficial. Demand clarity that the change is a win in the typical configuration, not just in a narrow scenario.
- **Reject overengineering — complexity is a first-class cost.** Unnecessary abstraction, extra indirections, and elaborate solutions for marginal gains should be rejected.
- **Every addition creates a maintenance obligation.** Long-term maintenance cost outweighs short-term convenience. Code that is hard to maintain, increases surface area, or creates technical debt needs stronger justification.

### Scope & Focus

- **Require large or mixed PRs to be split into focused changes.** Each PR should address one concern. Mixed concerns make review harder and increase regression risk.
- **Defer tangential improvements to follow-up PRs.** Police scope creep by asking contributors to separate concerns. Even good ideas should wait if they're not part of the PR's core purpose.

### Risk & Compatibility

- **Flag breaking changes and require formal process.** Any behavioral change that could affect downstream consumers needs documentation, API review, and explicit approval — even when the change improves the codebase internally.
- **Assess regression risk proportional to the change's blast radius.** High-risk changes to stable code need proportionally higher value and more thorough validation.

### Codebase Fit & History

- **Ensure new code matches existing patterns and conventions.** Deviations from established patterns create confusion and inconsistency. If a rename or restructuring is warranted, do it uniformly in a dedicated PR — not piecemeal.
- **Check whether a similar approach has been tried and rejected before.** If a prior attempt didn't work, require a clear explanation of what's different this time.

---

## Correctness & Safety

- **Fix root cause, not symptoms or workarounds.** Investigate and fix the root cause rather than adding workarounds or suppressing warnings. Revert broken commits before layering fixes.
- **Delete dead code and unnecessary wrappers.** Remove dead code, unnecessary wrappers, obsolete fields, and unused variables when encountered or when the only caller changes.

---

## Azure SDK Design Guidelines

- **Follow established Azure SDK design guidelines.** Ensure public APIs follow the Azure SDK design guidelines for JavaScript / TypeScript, including naming conventions, async patterns, configuration patterns, and error handling.
- For the full set of rules (sections 1–29 covering naming, client design, versioning, pagination, LRO, auth, logging, testing, packaging, and more), consult the full [Azure SDK Design Guidelines](references/azure-sdk-guidelines.md).

---

## Quick Reference: Common PR Review Checklist

When reviewing a PR, check for these high-impact items:

1. **Naming**: Client suffix, approved verbs, kebab-case package names, no dropped nouns on self-operations
2. **Exports**: Named exports only, no default exports, extensible string unions instead of TypeScript enums
3. **Options**: Proper `*Options` naming, `abortSignal` present, duration suffixes (`InMs`)
4. **Errors**: Uses built-in error types, includes HTTP response info, documented
5. **Pagination**: Returns `PagedAsyncIterableIterator`, uses `continuationToken`
6. **LRO**: Methods prefixed with `begin`, returns poller, supports `resumeFrom`
7. **Auth**: Accepts `TokenCredential`, uses Azure Core auth policies, no credential caching
8. **Logging**: Uses `@azure/logger`, channels prefixed `azure:<service>`, no sensitive data
9. **Tracing**: OpenTelemetry support, proper span naming and hierarchy
10. **Dependencies**: Only Azure Core deps in production, no polyfills, no tiny libraries
11. **Versioning**: Semver, no v0.x, beta uses `1.0.0-beta.X`, no features in patches
12. **Tests**: Vitest, independent, supports recording, >90% coverage, no sensitive data in recordings
13. **Package.json**: All required fields present, correct values, `sideEffects: false`
14. **TypeScript**: Strict mode, no `const enum`, no namespaces, type declarations shipped
15. **Documentation**: Snippets in docstrings, built in CI, README has "Configure TypeScript" section

---

## Consistency with Codebase Patterns

### PR Hygiene

- **Keep PRs focused on their stated scope.** No accidental file modifications, no unrelated refactoring, no whitespace noise, no build artifacts. Each PR should serve a single purpose.
- **Do large refactorings and renames in separate PRs.** Separate no-diff refactors from functional changes. Mechanical renames should be separate from logic changes.

### Code Reuse & Deduplication

- **Extract duplicated logic into shared helper methods.** Fix improvements inside shared helpers so all callers benefit.
- **Use existing APIs instead of creating parallel ones.** Before introducing new types, enums, or helpers, check if existing ones serve the same purpose. Fix existing utilities rather than introducing duplicates.
- **Delete dead code and unused declarations aggressively.** When removing code, also remove helper methods, enum values, function declarations, and strings that are no longer used.

### Established Conventions

- **Sort lists and entries alphabetically.** Lists of areas, configuration entries, entrypoint/export lists, and similar sorted structures should be maintained in alphabetical order.
- **Don't modify auto-generated files or `eng/common` manually.** Change the generator or source definition instead. Files in `eng/common` are synced from azure/azure-sdk.
- **Match existing style in modified files.** The existing style in a file takes precedence over general guidelines. Do not change existing code for style alone.

## Testing

- **Always add regression tests for bug fixes and behavior changes.** Prefer adding test cases to existing test files rather than creating new ones.
- **Test edge cases, error paths, and all affected types.** Include empty strings, negative values, boundary conditions, and Unicode edge cases. Test both true and false for boolean options. Choose inputs that can't accidentally pass if output wasn't touched.
- **Delete flaky and low-value tests rather than patching them.** Do not add tests known to be flaky. If a test relies on fragile runtime details and cannot be made reliable, prefer deletion.

---

## Documentation & Comments

- **Comments should explain why, not restate code.** Delete comments that just duplicate the code in plain English. Don't include historical context about why code changed.
- **Delete or update obsolete comments when code changes.** Stale comments describing old behavior are worse than no comments.
- **Track deferred work with GitHub issues and searchable TODOs.** Reference a tracking issue in TODO comments with a consistent prefix. Remove ancient TODOs that will never be addressed.
- **Don't duplicate comments on interface implementations.** Documentation comments belong on the interface definition. Duplicating leads to divergence.
- **Use SHA-specific or commit-based links in documentation.** Don't use branch-relative links that break when files move.
- **Retain copyright headers and license information.** All source files must include the standard license header, including test files. When porting from other projects, retain original copyright and update THIRD-PARTY-NOTICES.TXT.

---
