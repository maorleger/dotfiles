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
   - Run: `gh pr view $ARGUMENTS --json baseRefOid,headRefOid,files` to get revisions and files without the PR narrative
   - Run: `gh pr diff $ARGUMENTS` to get the diff
   - Read the PR description, issues, and comments only in Step 2.

Use best judgement when processing input.

Keep the review read-only unless the user authorizes changes or publication. Do not implement fixes or post comments automatically.

---

**Reviewer mindset:** Be polite but very skeptical. Your job is to help speed the review process for maintainers, which includes not only finding problems the PR author may have missed but also questioning the value of the PR in its entirety. Treat the PR description and linked issues as claims to verify, not facts to accept. Challenge the approach with evidence. Keep unresolved questions separate from confirmed findings.

## Review Process

### Step 0: Gather Code Context (No PR Narrative Yet)

Before analyzing anything, collect as much relevant **code** context as you can. **Critically, do NOT read the PR description, linked issues, or existing review comments yet.** You must form your own independent assessment of what the code does, why it might be needed, what problems it has, and whether the approach is sound — before being exposed to the author's framing. Reading the author's narrative first anchors your judgment and makes you less likely to find real problems.

1. **Current revisions, diff, and file list**: Fetch the current PR head, full diff, and list of changed files. Record the compared revisions. Read source from those revisions, not an unrelated local checkout. After feedback fixes or rebases, fetch the current head again. Do not rely on an old diff or previous findings without fresh verification.
2. **Full source files**: For every changed file, read the **entire source file** (not just the diff hunks). You need the surrounding code to understand invariants, locking protocols, call patterns, and data flow. Diff-only review is the #1 cause of false positives and missed issues.
3. **Consumers and callers**: If the change modifies a public/internal API, a type that others depend on, or a virtual/interface method, search for how consumers use the functionality. Grep for callers, usages, and test sites. Understanding how the code is consumed reveals whether the change could break existing behavior or violate caller assumptions.
4. **Key utility/helper files**: If the diff calls into shared utilities, read those to understand the contracts (thread-safety, idempotency, etc.).
5. **Git history**: Check recent commits to the changed files (`git log --oneline -20 -- <file>`). Look for related recent changes, reverts, or prior attempts to fix the same problem. This reveals whether the area is actively churning, whether a similar fix was tried and reverted, or whether the current change conflicts with recent work.
6. **Review guidance**: Read the repository and package-specific instructions. Load only the guidance relevant to the changed surface. Apply the target language's rules, not JavaScript conventions to every repository.

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
3. **Existing review comments**: Compare each candidate finding with current comments by root cause and failure scenario, not wording. Do not repeat an issue under a different symptom or file. Note existing blockers in the assessment without drafting duplicate comments. If the user requests only new findings, return only unreported issues.
4. **Reconcile your assessment with the author's claims.** Where your independent reading of the code disagrees with the PR description or issue, investigate further — but do not simply defer to the author's framing. If the PR claims a bug fix, a performance improvement, or a behavioral correction, verify those claims against the code and any provided evidence. If your independent assessment found problems the PR narrative doesn't acknowledge, those problems are more likely to be real, not less.
5. **Update your holistic assessment** if the additional context reveals information that genuinely changes your evaluation (e.g., a linked issue proves the bug is real, or an existing review comment already identified the same concern). But do not soften findings just because the PR description sounds reasonable.

### Step 3: Detailed Analysis

1. **Focus on what matters.** Prioritize bugs, performance regressions, safety issues, race conditions, resource management problems, incorrect assumptions about data or state, and API design problems. Do not comment on trivial style issues unless they violate an explicit rule below.
2. **Consider collateral damage.** Trace affected callers and inputs for every changed code path. Establish whether the failure scenario can reach this code. Inspect compiler checks, schemas, service contracts, and caller guards. Report confirmed regressions even when the fix otherwise helps. For unresolved material risks, state the evidence and missing facts under Questions for Human Review. Do not report impossible inputs or unsupported hypothetical failures as bugs.
3. **Be specific and actionable.** Give the exact file and lines at the reviewed revision. Explain the failure scenario, expected behavior, actual behavior, and smallest suitable fix. Reference the relevant contract or convention.
4. **Flag severity and merge impact separately:**
   - ❌ **error** — Must fix before merge. Bugs, security issues, API violations, test gaps for behavior changes.
   - ⚠️ **warning** — Material concern. State whether it blocks merge or is advisory; severity alone does not determine the verdict.
   - 💡 **suggestion** — Consider changing. Style improvements, minor readability wins, optional optimizations.
5. **Don't pile on.** If the same issue appears many times, flag it once on the primary file with a note listing all affected files. Do not leave separate comments for each occurrence.
6. **Respect existing style.** When modifying existing files, the file's current style takes precedence over general guidelines.
7. **Don't flag what CI catches.** Omit issues that existing lint, type-check, build, or other required CI checks enforce. Verify the relevant check before claiming that CI covers a concern. Do not confuse a test gap with an existing test that fails.
8. **Avoid false positives.** Before flagging any issue:
   - **Verify the concern actually applies** given the full context, not just the diff. Open the surrounding code to check. Confirm the issue isn't already handled by a caller, callee, or wrapper layer before claiming something is missing.
   - **Skip theoretical concerns with negligible real-world probability.** "Could happen" is not the same as "will happen."
   - **If you're unsure, investigate further.** If concrete evidence leaves a material uncertainty, put it under Questions for Human Review. State what fact or test can resolve it. Do not present uncertainty as a confirmed defect.
   - **Trust the author's context.** The author knows their codebase. If a pattern seems odd but is consistent with the repo, assume it's intentional.
   - **Verify external behavior from authoritative sources.** Use official specifications, documentation, or runtime source for the supported versions. Distinguish a specification guarantee from an observed implementation detail. Do not infer availability or deprecation from training data alone.
9. **Ensure code suggestions are valid.** Any code you suggest must be syntactically correct and complete. Ensure any suggestion would result in working code.
10. **Label in-scope vs. follow-up.** Apply the [scope and proportionality gate](#scope-and-proportionality-gate) before reporting findings. Distinguish between issues the PR should fix and out-of-scope improvements. Be explicit when a suggestion is a follow-up rather than a blocker.

### Evidence for Failures and Fixes

- **Provide a small demonstration.** For substantive behavior findings, include a minimal input, call sequence, or regression test. Prefer public interfaces and existing test patterns. Give the intended test filename when useful.
- **Run the smallest relevant reproduction when feasible.** State the reviewed revision, command, and observed result. If you cannot execute it, label the example unexecuted and state the limitation. Code reasoning can establish a finding, but do not claim an execution result without one.
- **Prove proposed fixes when authorized.** Demonstrate failure before the fix and success after it. Ensure the test exercises the reported scenario. A passing suite alone does not prove the fix. When useful, remove the behavior temporarily to confirm that the test detects its absence. Restore any temporary edits after the experiment.

### Cross-Cutting Analysis

Inspect relevant sibling packages, callers, and platforms for shared behavior or related defects.

#### Cross-Language Consistency

Use the four tier-1 languages as design references: JavaScript/TypeScript, Python, .NET, and Java. For JavaScript reviews, compare `azure-sdk-for-python`, `azure-sdk-for-net`, and `azure-sdk-for-java`, in that order. For another target language, skip its repository in that sequence and include `azure-sdk-for-js` as a reference.

**Prefer consistency within the target language over consistency between languages.** Start with its design guidelines, core libraries, and sibling packages. Use other languages to evaluate the design, not to copy their API shapes or implementation patterns. A different implementation is not itself a defect. Explain which language convention or runtime constraint justifies a difference.

Compare the layer that answers the design question:

| Changed behavior or design         | What to compare                                                                                                                                                                                                                   |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **LRO implementation**             | The same service operation, generated polling helper, core poller, and handwritten adapters. Trace initial-response access, operation IDs, result selection, polling intervals, cancellation, and resume behavior where relevant. |
| **Package implementation**         | Equivalent customer scenarios in the same service SDK. Compare shared-core versus package-specific logic, workarounds, serialization, error handling, retries, and resource lifetime.                                             |
| **Public API**                     | Equivalent capabilities and customer workflows: client hierarchy, options, returned information, pagination, LROs, and preview boundaries. Compare semantics and usability, not identical names, types, or async syntax.          |
| **Generator or protocol behavior** | Equivalent TypeSpec inputs and emitted clients, plus their runtime helpers. For streaming, compare framing, event dispatch, deserialization, errors, and cleanup against the protocol contract.                                   |

- **Ask whether the workaround is needed elsewhere.** If not, find the smoking gun that explains why the target language needs it. Trace the equivalent scenario through source and tests. Identify the contract, helper, callback, or runtime behavior that makes the difference.
- **Look for missing capabilities and simpler designs.** Ask: "Do we have the same parity, or are we missing anything?" Determine whether another implementation avoids the problem or merely shares it. Agreement between languages does not prove correctness.
- **Compare equivalent versions and scenarios.** Account for service API versions, core library versions, runtime support, and GA versus beta status. Use released packages when claiming shipped precedent. Cite the relevant source, tests, and revisions. State any limits on the comparison.
- **Keep the comparison focused.** Inspect only relevant packages and paths in the reference order. Do not audit every language repository for an unrelated local change. Other languages provide comparison and consistency evidence; they do not expand the requested implementation scope.

---

## Communication Style

**Before writing any review output**, load the `communicate-as-maorleger` skill using the skill tool. All review text — the holistic assessment, detailed findings, and any comments — must be written in that communication style. This means:

- Frame feedback as questions and suggestions, not directives
- Use the softening language patterns from the communication skill
- Match the tone: warm, approachable, confident but never condescending
- Use humor and emoji sparingly and naturally as described in that skill

The structural format below still applies (sections, severity markers, etc.), but the _prose within each section_ must follow the communication skill's voice and tone guidelines.

---

## Review Output Format

For a complete review, use the following structure. For a focused follow-up, answer only the requested question or scope. Do not repeat the full review unless requested.

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

**Merge impact**: <Merge-blocking / Advisory; omit for verified positives>

<Failure scenario, evidence, exact file/lines, and suggested change. Include a small reproduction when useful; state whether you executed it.>

(Repeat for each finding category. Group related findings under a single heading.)

### Questions for Human Review

<Include only unresolved material concerns. Give the evidence, missing fact or test, and effect on the merge decision. Omit this section when empty.>
```

### Guidelines

- **Holistic Assessment** comes first and covers Motivation, Approach, and Summary.
- **Detailed Findings** uses emoji-prefixed category headers:
  - ✅ for things that are correct / look good (use to confirm important aspects were verified)
  - ⚠️ for warnings or impactful suggestions (should fix, or follow-up)
  - ❌ for errors (must fix before merge)
  - 💡 for minor suggestions or observations (nice-to-have)
- **Cross-cutting analysis**: Apply the [cross-language consistency guidance](#cross-language-consistency) when relevant. Report meaningful design differences, missing capabilities, and the evidence that explains them. Prefer the target language's conventions.
- **Test quality** should be assessed as its own finding when tests are part of the PR.
- **Summary** gives a clear verdict: LGTM (no blocking issues — use only when confident), Needs Human Review (code may be correct but you have unresolved concerns or uncertainty that require human judgment), Needs Changes (with blocking issues listed), or Reject (explaining why this should be closed outright). **Never give a blanket LGTM when you are unsure.** When in doubt, use "Needs Human Review" and explain what a human should focus on.
- Keep the review concise but thorough. Every claim should be backed by evidence from the code.

### Copy-Paste Review Comments

When requested, provide one short, standalone comment per finding in the user's voice. Explain the failure and ask a concrete question. Prefer a small test when it demonstrates the issue more clearly than prose. Honor any requested limit or blockers-only scope. Include attribution only when requested. Recheck the PR head and existing comments before authorized publication.

### Verdict Consistency Rules

The summary verdict **must** be consistent with the findings in the body. Follow these rules:

1. **Base the verdict on merge safety, not emoji count.** Use "Needs Changes" for confirmed blockers. Use "Needs Human Review" for unresolved material risks. Advisory findings do not prevent "LGTM" if you are confident the change is correct and complete.

2. **Escalate material uncertainty to human review.** Identify the unresolved concern and the evidence needed to resolve it. Do not approve a change with unresolved doubts about its correctness or completeness. Unsupported hypothetical concerns do not justify escalation.

3. **Separate code correctness from approach completeness.** Judge completeness against the agreed problem and supported contract, not every neighboring edge case. A narrower correct approach is not incomplete merely because a broader solution is possible. If the approach fails the scoped goal or masks a required failure, the verdict must reflect that gap. Apply the [scope and proportionality gate](#scope-and-proportionality-gate) before treating additional work as a blocker.

4. **Classify each finding by merge impact.** Mark confirmed findings as merge-blocking or advisory. Reserve ❌ for confirmed blockers. Put unresolved material concerns under Questions for Human Review. If blockers and uncertainties coexist, use "Needs Changes" and also explain the unresolved concerns.

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
- **Verify concrete alternatives.** Consider built-ins in supported runtimes, existing core utilities, and fixes in the generator or source definition. Explain any constraint that makes the simpler solution insufficient. Base compatibility code on real consumers or documented contracts, not hypothetical future needs.

### Scope and Proportionality Gate

**Optimize for the smallest correct solution to the agreed problem, not the elimination of every adjacent imperfection.**

- **Establish the required invariant and non-goals.** State what this PR must guarantee and which existing behaviors it must preserve. Do not silently expand those requirements during review.
- **Separate a valid observation from a merge requirement.** Explain whether a finding exposes an introduced regression, prevents the scoped fix from working, or proposes additional hardening. A reproducible edge case establishes behavior; it does not automatically establish that this PR must change it.
- **Consider subtraction before addition.** When new machinery has a bug, first ask whether that machinery is necessary. Removing an unnecessary validator can be a better fix than making it increasingly comprehensive.
- **Separate correctness from policy.** Protocol validity, parsing strictness, compatibility, and scheduling policy are distinct decisions. Do not use a local correctness argument to introduce a new policy without making the tradeoff explicit.
- **Interrupt expanding feedback loops.** If successive fixes add special cases, validators, helpers, or contradictory behavior, stop patching locally. Reassess the whole approach against the original invariant. Present a smaller alternative or identify the decision that needs maintainer judgment.
- **Do not let incidental promises manufacture requirements.** Check whether descriptions and new tests express an intended contract or merely describe the current implementation. Correct an accidental overclaim rather than building a subsystem to satisfy it. Do not discard established contracts or necessary regression tests to make the patch smaller.
- **Respect explicit tradeoff decisions.** Record accepted limitations and their rationale. Do not repeatedly demand the rejected design without new evidence. Still surface newly demonstrated regressions or materially different consequences.
- **Use a bounded completion criterion.** The scoped defect is fixed, required behavior is preserved, and no material introduced regression remains. Optional hardening belongs in a separate proposal, not an endless sequence of blockers.

### Cost-Benefit & Complexity

- **Explicitly weigh whether the change is a net positive.** A performance trade-off that shifts costs around is not automatically beneficial. Demand clarity that the change is a win in the typical configuration, not just in a narrow scenario.
- **Reject overengineering — complexity is a first-class cost.** Unnecessary abstraction, extra indirections, and elaborate solutions for marginal gains should be rejected.
- **Every addition creates a maintenance obligation.** Long-term maintenance cost outweighs short-term convenience. Code that is hard to maintain, increases surface area, or creates technical debt needs stronger justification.

### Scope & Focus

- **Require large or mixed PRs to be split into focused changes.** Each PR should address one concern. Mixed concerns make review harder and increase regression risk.
- **Defer tangential improvements to follow-up PRs.** Police scope creep by asking contributors to separate concerns. Even good ideas should wait if they're not part of the PR's core purpose.

### Risk & Compatibility

- **Establish the released baseline.** Before calling a removal or signature change breaking, verify that it exists in the last released GA version. Do not use unreleased `main` or beta-only changes as the stable baseline.
- **Apply the package's stability policy.** Inspect whether affected models are reachable only through beta operations. A GA package does not make every operation or model stable. Verify precedent in released packages, not just current source.
- **Flag breaking changes and require formal process.** Apply the repository's approval and documentation requirements to confirmed breaks in the stable contract. Distinguish intentional breaks in a major release from accidental regressions.
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

- **Use the applicable authority.** Apply the repository's canonical reviewer instructions and current design guidelines for the target language and package type.
- Use the [JavaScript / TypeScript reference](references/azure-sdk-guidelines.md) and checklist below as an index, not universal rules. Load only relevant sections. If they conflict with current authoritative guidance, use that guidance. Do not impose SDK-only conventions on tooling or other languages.

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
