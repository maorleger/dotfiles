---
name: code-review
description: Review code changes in azure sdk for correctness, performance, and consistency with project conventions. Use when reviewing PRs or code changes.
---

## Determining What to Review

Based on the input provided, determine which type of review to perform:

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
7. **Don't flag what CI catches.** Do not flag issues that a linter, typechecker, compiler, analyzer, or CI build step would catch, e.g., missing usings, unsupported syntax, formatting. Assume CI will run separately.
8. **Avoid false positives.** Before flagging any issue:
   - **Verify the concern actually applies** given the full context, not just the diff. Open the surrounding code to check. Confirm the issue isn't already handled by a caller, callee, or wrapper layer before claiming something is missing.
   - **Skip theoretical concerns with negligible real-world probability.** "Could happen" is not the same as "will happen."
   - **If you're unsure, either investigate further until you're confident, or surface it explicitly as a low-confidence question rather than a firm claim.** Do not speculate about issues you have no concrete basis for. Every comment should be worth the reader's time.
   - **Trust the author's context.** The author knows their codebase. If a pattern seems odd but is consistent with the repo, assume it's intentional.
   - **Never assert that something "does not exist," "is deprecated," or "is unavailable" based on training data alone.** Your knowledge has a cutoff date. When uncertain, ask rather than assert.
9. **Ensure code suggestions are valid.** Any code you suggest must be syntactically correct and complete. Ensure any suggestion would result in working code.
10. **Label in-scope vs. follow-up.** Distinguish between issues the PR should fix and out-of-scope improvements. Be explicit when a suggestion is a follow-up rather than a blocker.

## Multi-Model Review

When the environment supports launching sub-agents with different models (e.g., the `task` tool with a `model` parameter), run the review in parallel across multiple model families to get diverse perspectives. Different models catch different classes of issues. If the environment does not support this, proceed with a single-model review.

**How to execute (when supported):**
1. Inspect the available model list and select one model from each distinct model family (e.g., one Anthropic Claude, one Google Gemini, one OpenAI GPT). Use at least 2 and at most 4 models. **Model selection rules:**
   - Pick only from models explicitly listed as available in the environment. Do not guess or assume model names.
   - From each family, pick the model with the highest capability tier (prefer "premium" or "standard" over "fast/cheap").
   - Never pick models labeled "mini", "fast", or "cheap" for code review.
   - If multiple standard-tier models exist in the same family (e.g., `gpt-5` and `gpt-5.1`), pick the one with the highest version number.
   - Do not select the same model that is already running the primary review (i.e., your own model). The goal is diverse perspectives from different model families.
2. Launch a sub-agent for each selected model in parallel, giving each the same review prompt: the PR diff, the review rules from this skill, and instructions to produce findings in the severity format defined above.
3. Wait for all agents to complete, then synthesize: deduplicate findings that appear across models, elevate issues flagged by multiple models (higher confidence), and include unique findings from individual models that meet the confidence bar. **Timeout handling:** If a sub-agent has not completed after 10 minutes and you have results from other agents, proceed with the results you have. Do not block the review indefinitely waiting for a single slow model. Note in the output which models contributed.
4. Present a single unified review to the user, noting when an issue was flagged by multiple models.

---

## Review Output Format

When presenting the final review (whether as a PR comment or as output to the user), use the following structure. This ensures consistency across reviews and makes the output easy to scan.

### Structure

```
## 🤖 Copilot Code Review — PR #<number>

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
  > "I am not sure why is this needed. ... It's not immediately obvious whether this happens only for the bridge comparison tests or whether it can happen for real-life scenarios too."

- **Challenge every addition with "Do we need this?"** New code, APIs, abstractions, and flags must justify their existence. If an addition can be avoided without sacrificing correctness or meaningful capability, it should be.
  > "I don't think we should take this change, at all. A change which makes the VS runner see the same assets as the CLI runner, sure. But random extra hacking on the side, no."

- **Demand real-world use cases and customer scenarios.** Hypothetical benefits are insufficient motivation for expanding API surface area or adding features. Require evidence that real users need this.
  > "It is not clear to me whether you can hit a real-world scenario on 32-bit platforms where it makes a difference."

### Evidence & Data

- **Require measurable performance data before accepting optimization PRs.** Demand BenchmarkDotNet results or equivalent proof — never accept performance claims at face value.
  > "Can you please share a benchmark using BenchmarkDotNet against public System.Text.Json APIs that demonstrates the improvement?"

- **Distinguish real performance wins from micro-benchmark noise.** Trivial benchmarks with predictable inputs overstate gains from jump tables, branch elimination, and similar tricks. Require evidence from realistic, varied inputs.
  > "Try to benchmark it with an input that varies randomly. Jump tables are great for trivial micro-benchmarks, but they are less great for real world code."

- **Investigate and explain regressions before merging.** Even if a PR shows a net improvement, regressions in specific scenarios must be understood and explicitly addressed — not hand-waved.
  > "Could you please inspect the regressions on why exactly it's an improvement there?"

### Approach & Alternatives

- **Check whether the PR solves the right problem at the right layer.** Look for whether it addresses root cause or applies a band-aid. Prefer fixing the actual source of an issue over adding workarounds to production code.
  > "The offset behind `Flags.IndexMask` should always be correct. Instead of checking that the index is in range in all its usages, we should fix the root cause where the offset wasn't computed/updated correctly."

- **When a PR takes a fundamentally wrong approach, redirect early.** Don't iterate on implementation details of a flawed design. Push back on the overall direction before the contributor invests more time.
  > "I'm still hesitating whether separating FEATURE_HW_INTRINSICS from SIMD and MASKED_HW_INTRINSICS is the right approach ... An alternative would be to handle them like #113689 and fix the value numbering."

- **Ask "Why not just X?" — always prefer the simplest solution.** When a PR uses a complex approach, challenge it with the simplest alternative that could work. The burden of proof is on the complex solution.
  > "Wouldn't it be simpler to just do a regular mono stackwalk when we need to record and raise a sample?"

### Cost-Benefit & Complexity

- **Explicitly weigh whether the change is a net positive.** A performance trade-off that shifts costs around is not automatically beneficial. Demand clarity that the change is a win in the typical configuration, not just in a narrow scenario.
  > "It is a performance trade-off. You will shift the costs around. It is not clear to me whether it would be a win at the end in the typical configuration."

- **Reject overengineering — complexity is a first-class cost.** Unnecessary abstraction, extra indirections, and elaborate solutions for marginal gains are actively rejected.
  > "This optimization smells funny. It seems overly complicated for little win. Is this path hot? Can we instead store the home directory?"

- **Every addition creates a maintenance obligation.** Long-term maintenance cost outweighs short-term convenience. Code that is hard to maintain, increases surface area, or creates technical debt needs stronger justification.
  > "The primary goal of this project is to minimize our long-term maintenance costs. Building multiple optimizing code generators would go against that goal."

### Scope & Focus

- **Require large or mixed PRs to be split into focused changes.** Each PR should address one concern. Mixed concerns make review harder and increase regression risk.
  > "I think I'm going to break this into two pieces, even though that's more work."

- **Defer tangential improvements to follow-up PRs.** Police scope creep by asking contributors to separate concerns. Even good ideas should wait if they're not part of the PR's core purpose.
  > "Should probably be a separate PR."

### Risk & Compatibility

- **Flag breaking changes and require formal process.** Any behavioral change that could affect downstream consumers needs documentation, API review, and explicit approval — even when the change improves the codebase internally.
  > "Introduce the new API in this PR. Remove the old check in another PR, mark it as breaking change and document it (as any other breaking change)."

- **Assess regression risk proportional to the change's blast radius.** High-risk changes to stable code need proportionally higher value and more thorough validation.
  > "I wanted to backport this change to .NET 10, potentially .NET 9, and wouldn't want to introduce any risky changes."

### Codebase Fit & History

- **Ensure new code matches existing patterns and conventions.** Deviations from established patterns create confusion and inconsistency. If a rename or restructuring is warranted, do it uniformly in a dedicated PR — not piecemeal.
  > "This change is inconsistent with the rest of the global pointers. If we want to consider renaming these, I think we should do it in a separate PR and apply it consistently to all global pointers."

- **Check whether a similar approach has been tried and rejected before.** If a prior attempt didn't work, require a clear explanation of what's different this time.
  > "If it's not worthwhile, especially if it was previously tried and it wasn't obviously beneficial, then we should close the issue."

---

## Correctness & Safety

### Correctness Patterns

- **Fix root cause, not symptoms or workarounds.** Investigate and fix the root cause rather than adding workarounds or suppressing warnings. Revert broken commits before layering fixes.
  > "Let's try to investigate the root cause instead of taking this fix as-is since there could be other issues/AVs related to the mangling of the list." — jkotas

- **Delete dead code and unnecessary wrappers.** Remove dead code, unnecessary wrappers, obsolete fields, and unused variables when encountered or when the only caller changes.
  > "Unnecessary wrapper", "Dead code that I happen to notice", "This is the only use of m_canBeRuntimeImpl. It can be deleted." — jkotas

---

## Azure SDK Design Guidelines

- **Follow established Azure SDK design guidelines.** Ensure public APIs follow the Azure SDK design guidelines for JavaScript / TypeScript, including naming conventions, async patterns, configuration patterns, and error handling.

---

### 1. Naming & Namespaces

| ID | Level | Rule |
|----|-------|------|
| `ts-azure-scope` | MUST | Publish to the `@azure` npm scope (DPG) or `@azure-rest` scope (RLC). |
| `ts-npm-package-name-prefix` | MUST | Prefix data-plane package names with the kebab-case version of the appropriate namespace. |
| `ts-npm-package-name-follow-conventions` | SHOULD | Follow the casing conventions of existing stable packages in the `@azure` scope. |
| `ts-namespace-serviceclient` | MUST | Pick a package name that lets consumers tie it to the service. Use compressed service name. Avoid marketing names that may change. |
| `general-namespaces-shortened-name` | MUST | Use a shortened, stable service name (not marketing names). |
| `general-namespaces-mgmt` | MUST | Place management (ARM) APIs in the `management` group. |
| `general-namespaces-similar-names` | MUST NOT | Choose similar names for clients that do different things. |
| `general-namespaces-registration` | MUST | Register chosen namespace with the Architecture Board. |

**Good examples**: `@azure/cosmos`, `@azure/storage-blob`, `@azure/digital-twins-core`
**Bad examples**: `@microsoft/cosmos` (wrong scope), `@azure/digitaltwins` (not kebab-cased)

---

### 2. Client Design

| ID | Level | Rule |
|----|-------|------|
| `ts-apisurface-serviceclientnaming` | MUST | Name service client types with the `Client` suffix. |
| `ts-apisurface-serviceclientnamespace` | MUST | Place primary service client types as top-level exports. |
| `ts-apisurface-serviceclientconstructor` | MUST | Allow constructing a client with minimal information needed to connect and authenticate. |
| `ts-apisurface-supportallfeatures` | MUST | Support 100% of the features provided by the Azure service. |
| `ts-apisurface-standardized-verbs` | MUST | Standardize verb prefixes within client libraries for a service. |
| `ts-approved-verbs` | SHOULD | Use approved verbs: `create<Noun>`, `upsert<Noun>`, `set<Noun>`, `update<Noun>`, `replace<Noun>`, `append<Noun>`, `add<Noun>`, `get<Noun>`, `list<Noun>s`, `<noun>Exists`, `delete<Noun>`, `remove<Noun>`. |
| `ts-naming-drop-noun` | MUST NOT | Include the noun when operating on the resource itself (e.g., `client.delete()` not `client.deleteItem()`). |
| `ts-naming-subclients` | MUST | Prefix methods that create/vend subclients with `get` and suffix with `client` (e.g., `getBlobClient()`). |
| `ts-use-constructor-overloads` | SHOULD | Provide overloaded constructors for all construction scenarios. Prefix static constructors with `from`. |
| `ts-use-overloads-over-unions` | SHOULD | Prefer overloads over unions when parameters are correlated or users want tailored docs. |

#### Hierarchical Clients

| ID | Level | Rule |
|----|-------|------|
| `ts-hierarchy-clients` | MUST | Create a client type for each level in the hierarchy. |
| `ts-hierarchy-direct-construction` | MUST | Support directly constructing clients at any hierarchy level. |
| `ts-hierarchy-get-child` | MUST | Provide `get<Child>Client()` methods. These MUST NOT make network requests. |
| `ts-hierarchy-create-methods` | SHOULD | Provide `create<Child>()` methods on parent clients. |

---

### 3. Service Versions

| ID | Level | Rule |
|----|-------|------|
| `ts-service-versions-use-latest` | MUST | Default to the highest supported service API version. |
| `ts-service-versions-select-api-version` | MUST | Allow the consumer to explicitly select a supported service API version. |
| `general-service-apiversion-1` | MUST | Only target GA service API versions when releasing a stable client library. |
| `general-service-apiversion-3` | MUST | Target the latest preview API version by default in beta releases. |
| `general-service-apiversion-4` | MUST | Include all supported service API versions in a `ServiceVersion` enum. |
| `general-service-apiversion-5` | MUST | Document the default service API version. |
| `general-service-apiversion-7` | MUST | Replace `api-version` on any service-returned URI with the configured version. |

---

### 4. Options & Parameters

| ID | Level | Rule |
|----|-------|------|
| `ts-naming-options` | MUST | Name option bag types as `<ClassName>Options` or `<MethodName>Options`. |
| `ts-options-abortSignal` | MUST | Name abort signal options `abortSignal`. |
| `ts-options-suffix-durations` | MUST | Suffix durations with `In<Unit>` (e.g., `timeoutInMs`, `delayInSeconds`). |
| `general-params-client-validation` | MUST | Validate client parameters (null checks, empty strings for required path params). |
| `general-params-server-validation` | MUST NOT | Validate service parameters — let the service validate. |
| `general-params-server-defaults` | MUST NOT | Encode default values for service parameters (defaults can change between api-versions). |

---

### 5. Response Formats

| ID | Level | Rule |
|----|-------|------|
| `ts-return-logical-entities` | MUST | Return the logical entity for a request (what 99%+ of callers need). |
| `ts-return-document-raw-stream` | MUST | Document how to access raw/streamed responses with samples. |
| `general-return-no-headers-if-confusing` | MUST NOT | Return headers unless it's obvious which HTTP request they correspond to. |
| `general-dont-use-value` | SHOULD NOT | Use property names `object` or `value` within logical entities. |

---

### 6. Authentication

| ID | Level | Rule |
|----|-------|------|
| `general-auth-provide-token-client-constructor` | MUST | Accept `TokenCredential` from Azure Core in client constructors. |
| `general-auth-use-core` | MUST | Use authentication policy implementations from Azure Core. |
| `general-auth-support` | MUST | Support all authentication schemes the service supports. |
| `general-auth-reserve-when-not-suported` | MUST | Reserve API surface for TokenCredential even if not yet supported by the service. |
| `general-auth-connection-strings` | MUST NOT | Support connection strings unless available in tooling for copy/paste. |
| `auth-client-no-token-persistence` | MUST NOT | Persist, cache, or reuse tokens from the token credential. |
| `general-auth-credential-type-prefix` | MUST | Prepend custom credential type names with the service name. |
| `general-auth-credential-type-suffix` | MUST | Append `Credential` (singular) to custom credential type names. |
| `general-authimpl-no-persisting` | MUST NOT | Persist, cache, or reuse security credentials. |

---

### 7. Pagination

| ID | Level | Rule |
|----|-------|------|
| `ts-pagination-provide-list` | MUST | Return `PagedAsyncIterableIterator` from `list` methods. |
| `ts-pagination-take-continuationToken` | MUST | Accept `continuationToken` in `byPage()`. Continuation token on page type must be named `continuationToken`. |
| `ts-pagination-provide-bypage-settings` | MUST NOT | Provide page-related settings other than `continuationToken` to `byPage()`. |
| `general-pagination-distinct-types` | MUST | Use different types for list vs. get if they have different shapes. |
| `general-pagination-no-item-iterators` | MUST NOT | Expose item iterator if it causes additional service requests. |
| `general-pagination-support-toArray` | MUST NOT | Provide an API to get a paginated collection into an array. |
| `general-pagination-expose-lists-equally` | MUST | Expose non-paginated lists identically to paginated lists. |

---

### 8. Long Running Operations (LRO)

| ID | Level | Rule |
|----|-------|------|
| `ts-lro-return-poller` | MUST | Return a poller object with APIs for: state query, completion notification, cancellation, disinterest, manual poll, progress reporting. |
| `ts-lro-support-options` | MUST | Support `pollInterval` and `resumeFrom` options. |
| `ts-lro-continuation` | MUST | Allow instantiating a poller from serialized state of another poller. |
| `ts-lro-cancellation` | MUST NOT | Cancel the long-running operation itself when cancellation token fires — only cancel polling. |
| `ts-lro-progress-reporting` | MUST | Expose progress reporting if the service supports it. |

---

### 9. Error Handling

| ID | Level | Rule |
|----|-------|------|
| `general-errors-for-failed-requests` | MUST | Produce an error for any HTTP request with a non-success status code. Log as errors. |
| `general-errors-include-request-response` | MUST | Include HTTP response (status, headers) and request (URL, query params, headers) in errors. |
| `general-errors-rich-info` | MUST | Surface rich service error information (from headers/body) via service-specific properties. |
| `general-errors-documentation` | MUST | Document errors produced by each method. |
| `general-errors-no-new-types` | SHOULD NOT | Create new error types unless they enable alternate remediation actions. Base on Azure Core types. |
| `general-errors-use-system-types` | MUST NOT | Create new error types when language-built-in types suffice. |
| `ts-error-handling` | MUST | Use `TypeError`, `RangeError`, or `Error` as appropriate. |
| `ts-error-handling-coercion` | SHOULD | Coerce incorrect types when possible (JavaScript fuzziness). |
| `ts-error-use-name` | SHOULD | Check `error.name` in catch clauses rather than `instanceof`. |

---

### 10. Logging

| ID | Level | Rule |
|----|-------|------|
| `ts-logging-use-debug-module` | MUST | Use the `debug` module for logging. |
| `ts-logging-prefix-channel-names` | MUST | Prefix channels with `azure:<service-name>`. |
| `ts-logging-channels` | MUST | Create channels: `:error`, `:warning`, `:info`, `:verbose`. |
| `ts-logging-top-level-exports` | MUST | Expose all log channels as top-level exports. |
| `general-logging-no-sensitive-info` | MUST | Only log headers/query params from the allow-list. Redact all others. |
| `general-logging-requests` | MUST | Log request line and headers at `Informational` level. |
| `general-logging-responses` | MUST | Log response line, headers, and timing at `Informational` level. |
| `general-logging-cancellations` | MUST | Log cancellation at `Informational` level with request ID and reason. |
| `general-logging-exceptions` | MUST | Log exceptions at `Warning` level; stack trace at `Verbose`. |

---

### 11. Distributed Tracing

| ID | Level | Rule |
|----|-------|------|
| `general-tracing-opentelemetry` | MUST | Support OpenTelemetry for distributed tracing. |
| `general-tracing-accept-context` | MUST | Accept a context from calling code via `OperationOptions.tracingOptions`. |
| `general-tracing-new-span-per-method` | MUST | Create one span per user-facing client method call. |
| `general-tracing-suppress-client-spans-for-inner-methods` | MUST | Suppress inner client method spans when called from another public client method. |
| `general-tracing-new-span-per-rest-call` | MUST | Create a child span for each REST call. |
| `general-tracing-new-span-per-method-naming` | MUST | Use `{Namespace}.{Interface}.{OperationName}` as span name. |
| `general-tracing-new-span-per-method-failure` | MUST | Record error details on span if method throws. |

---

### 12. Network & HTTP Pipeline

| ID | Level | Rule |
|----|-------|------|
| `ts-use-core-rest-pipeline` | MUST | Use `@azure/core-rest-pipeline` for HTTP communication. |
| `ts-pipeline-use-default-policies` | MUST | Include standard policies: User-Agent, Telemetry, Request ID, Retry, Logging, Authentication, Tracing. |
| `ts-network-accept-abort-signal` | MUST | Accept `abortSignal` on all async service methods. |
| `ts-network-no-leak-implementation` | MUST NOT | Leak protocol transport implementation details. |
| `general-network-no-leakage` | MUST NOT | Expose underlying protocol transport types to consumers. |
| `general-requests-use-pipeline` | MUST | Use the HTTP pipeline from Azure Core. |

---

### 13. Telemetry

| ID | Level | Rule |
|----|-------|------|
| `ts-telemetry-useragent-header` | MUST | Send `User-Agent` in format: `azsdk-js-<package-name>/<package-version> <platform-info>`. |
| `ts-telemetry-no-pii` | MUST NOT | Include PII in telemetry headers. |
| `ts-telemetry-no-sensitive-data` | MUST NOT | Include sensitive data in telemetry headers, even encoded. |
| `azurecore-http-telemetry-appid-length` | MUST | Enforce application ID is no more than 24 characters. |

---

### 14. Repeatable Requests

| ID | Level | Rule |
|----|-------|------|
| `general-repeatable-requests-request-headers` | MUST | Add `Repeatability-Request-ID` (UUID) and `Repeatability-First-Sent` (IMF fixdate) headers before sending. Values must remain the same across retries. |
| `general-repeatable-requests-parameters` | SHOULD NOT | Offer explicit parameters to set repeatability headers. |
| `general-repeatable-requests-support-response-headers` | MUST | Expose `Repeatability-Result` response header in the response model. |

---

## 15. TypeScript & Language Rules

| ID | Level | Rule |
|----|-------|------|
| `ts-use-typescript` | MUST | Implement in TypeScript. |
| `ts-ship-type-declarations` | MUST | Include type declarations. |
| `ts-use-promises` | MUST | Use built-in promises for async. Do not import a polyfill. |
| `ts-use-async-functions` | SHOULD | Use `async` functions for async APIs. |
| `ts-use-iterators` | MUST | Use Iterators and Async Iterators for sequences/streams. |
| `ts-use-interface-parameters` | SHOULD | Prefer interface types over class types for parameters. |
| `ts-avoid-extending-cross-package` | MUST | Not extend classes from a different package. |
| `ts-no-namespaces` | SHOULD NOT | Use TypeScript namespaces. Use ESM imports/exports. |
| `ts-no-const-enums` | SHOULD NOT | Use `const enum` (incompatible with Babel 7). |
| `ts-use-extensible-enums` | MUST | Use string literal unions for service enumerations. |
| `ts-no-typescript-enums` | MUST NOT | Use TypeScript `enum` for service-defined enumerations. |
| `ts-extensible-enum-namespace` | SHOULD | Provide a `Known<EnumName>` namespace with known value constants. |
| `ts-modules-only-named` | MUST | Only have named exports at top level. |
| `ts-modules-no-default` | MUST NOT | Have a default export at top level. |

---

## 16. tsconfig.json

| ID | Level | Rule |
|----|-------|------|
| `ts-config-strict` | MUST | Set `compilerOptions.strict` to `true`. |
| `ts-config-esModuleInterop` | MUST | Set `compilerOptions.esModuleInterop` to `true`. |
| `ts-config-allowSyntheticDefaultImports` | MUST | Set `compilerOptions.allowSyntheticDefaultImports` to `true`. |
| `ts-config-forceConsistentCasingInFileNames` | MUST | Set `compilerOptions.forceConsistentCasingInFileNames` to `true`. |
| `ts-config-declaration` | MUST | Set `compilerOptions.declaration` to `true`. |
| `ts-config-sourceMap` | MUST | Set `compilerOptions.sourceMap` and `declarationMap` to `true`. |
| `ts-config-importHelpers` | MUST | Set `compilerOptions.importHelpers` to `true`. |
| `ts-config-no-experimentalDecorators` | MUST NOT | Set `compilerOptions.experimentalDecorators` to `true`. |
| `ts-config-lib` | MUST NOT | Use `compilerOptions.lib`. |

---

## 17. Package Structure & package.json

| ID | Level | Rule |
|----|-------|------|
| `ts-package-json-name` | MUST | Set `name` to `@azure/<name>` (kebab-case). |
| `ts-package-json-homepage` | MUST | Set `homepage` to the library's README URL in the repo. |
| `ts-package-json-bugs` | MUST | Set `bugs.url` to `https://github.com/Azure/azure-sdk-for-js/issues`. |
| `ts-package-json-repo` | MUST | Set `repository` to `github:Azure/azure-sdk-for-js`. |
| `ts-package-json-author` | MUST | Set `author` to `"Microsoft Corporation"`. |
| `ts-package-json-license` | MUST | Set `license` to `"MIT"`. |
| `ts-package-json-sideeffects` | MUST | Set `sideEffects` to `false`. |
| `ts-package-json-main-is-cjs` | MUST | Set `main` to a CJS or UMD module. |
| `ts-package-json-main-is-not-es6` | MUST NOT | Set `main` to include ESM syntax. |
| `ts-package-json-module` | MUST | Set `module` to the ESM entrypoint. |
| `ts-package-json-types` | MUST | Set `types` to the TypeScript type declarations. |
| `ts-package-json-engine-is-present` | MUST | Set `engine` to supported Node versions. |
| `ts-package-json-keywords` | MUST | Include at least `"Azure"`, `"cloud"`, and the service name in `keywords`. |
| `ts-package-json-files-required` | MUST | Set `files` to an array of package content paths. |
| `ts-package-json-required-scripts` | MUST | Include at least `"build"` and `"test"` scripts. |
| `ts-no-npmignore` | MUST NOT | Use `.npmignore`. Use `files` in package.json. |
| `ts-no-tsconfig` | MUST NOT | Include `tsconfig.json` in the published package. |

---

## 18. Distributions & Modules

| ID | Level | Rule |
|----|-------|------|
| `ts-include-cjs` | MUST | Include a CJS or UMD build for Node support. |
| `ts-flatten-umd` | MUST | Flatten the CJS/UMD module (use Rollup). |
| `ts-include-esm` | MUST | Include an ESM build. |
| `ts-include-esm-not-flattened` | MUST NOT | Flatten the ESM build. |
| `ts-no-browser-bundle` | MUST NOT | Include a browser bundle in the package. |
| `ts-include-original-source` | MUST | Include source code in source map `sourcesContent` via `inlineSources`. |

---

## 19. Dependencies

| ID | Level | Rule |
|----|-------|------|
| `ts-dependencies-azure-core` | MUST | Depend on Azure Core for common functionality. |
| `ts-dependencies-no-other-packages` | MUST NOT | Depend on packages other than Azure Core in the distribution. Build deps are OK. |
| `ts-dependencies-consider-vendoring` | SHOULD | Consider vendoring required code to avoid external dependencies. |
| `ts-dependencies-no-tiny-libraries` | SHOULD NOT | Depend on tiny libraries (cost adds up). |
| `ts-dependencies-no-polyfills` | SHOULD NOT | Depend on polyfills that modify global scope. Document requirements in README instead. |
| `general-dependencies-concrete` | MUST NOT | Depend on concrete logging, DI, or config technologies (except Azure Core). |

**Pre-approved production dependencies**: `rhea`, `rhea-promise` (AMQP only).

---

## 20. Versioning

| ID | Level | Rule |
|----|-------|------|
| `ts-versioning-semver` | MUST | Version with semver. |
| `ts-versioning-no-ga-prerelease` | MUST NOT | Use pre-release version or build metadata for stable packages. |
| `ts-versioning-beta` | MUST | Use `1.0.0-beta.X` format for beta packages. |
| `ts-versioning-no-version-0` | MUST NOT | Use major version 0, even for beta packages. |
| `general-versioning-bump` | MUST | Change the version number when ANYTHING changes. |
| `general-versioning-patch` | MUST | Increment patch for bug fixes only. |
| `general-versioning-no-features-in-patch` | MUST NOT | Include new features in a patch release. |
| `general-versioning-no-breaking-changes` | MUST NOT | Make breaking changes. If absolutely required, get Architecture Board approval and bump major. |
| `ts-npm-dist-tag-beta` | MUST | Tag beta packages with `beta` dist-tag. |
| `ts-npm-dist-tag-next` | MUST | Tag GA packages with `latest` dist-tag. |

---

## 21. Platform Support

| ID | Level | Rule |
|----|-------|------|
| `ts-node-support` | MUST | Support all LTS Node versions and newer up to latest release. |
| `ts-browser-support` | MUST | Support Safari (latest 2), Chrome (latest 2), Edge (all supported), Firefox (latest 2). |
| `ts-no-ie11-support` | SHOULD NOT | Support IE11. |
| `ts-support-ts` | MUST | Compile without errors on all TypeScript versions less than 2 years old. |
| `ts-register-dropped-platforms` | MUST | Get Architecture Board approval to drop platform support. |

---

## 22. Testing

| ID | Level | Rule |
|----|-------|------|
| `ts-use-vitest` | MUST | Use vitest as the test framework. |
| `ts-test-unit-tests` | MUST | Write unit tests without network calls. |
| `ts-test-integration-tests` | MUST | Write integration tests against the live service. |
| `ts-test-support-recording` | MUST | Support recording/playback of HTTP interactions via `@azure-tools/test-recorder`. |
| `ts-test-coverage` | MUST | Maintain >90% coverage for core, 100% for critical paths (auth, retries, errors), tests for all public API surface. |
| `ts-test-independent` | MUST | Tests must be independent and order-agnostic. |
| `ts-test-cleanup` | MUST | Clean up resources created during tests. |
| `general-testing-3` | MUST | Use unique, descriptive test case names. |
| `general-testing-5` | MUST NOT | Rely on pre-existing test resources or leave resources behind after tests. |
| `general-testing-6` | MUST | All tests must work without network connectivity. |
| `general-testing-7` | MUST | Use mock service implementation with recorded tests per service version. |
| `general-testing-9` | MUST | Enable network-mocked tests to also connect to live service with unchanged assertions. |
| `general-testing-10` | MUST NOT | Include sensitive information in recorded tests. |
| `general-testing-mocking` | MUST | Support mocking of service client methods. |

---

## 23. Documentation & Samples

| ID | Level | Rule |
|----|-------|------|
| `general-docs-contentdev` | MUST | Include content developer in Architecture Board reviews. |
| `general-docs-style-guide` | MUST | Follow Microsoft Writing Style Guide and Cloud Style Guide. |
| `general-docs-to-silence` | SHOULD | Document into silence — preempt usage questions. |
| `general-docs-include-snippets` | MUST | Include code snippets demonstrating common operations and champion scenarios. |
| `general-docs-build-snippets` | MUST | Build and test snippets in CI. |
| `general-docs-snippets-in-docstrings` | MUST | Include snippets in docstrings for API reference. |
| `general-docs-operation-combinations` | MUST NOT | Combine multiple operations in one snippet (unless in addition to atomic snippets). |
| `ts-readme-ts-config` | MUST | Document required `tsconfig.json` settings in README under "Configure TypeScript". |
| `ts-need-js-samples` | MUST | Have JavaScript samples. |
| `ts-need-ts-samples` | SHOULD | Have TypeScript samples. |
| `ts-need-browser-samples` | SHOULD | Have browser-tailored samples. |

---

## 24. Code Quality & Tooling

| ID | Level | Rule |
|----|-------|------|
| `ts-use-eslint` | MUST | Use ESLint for static analysis. |
| `ts-use-azure-eslint-plugin` | SHOULD | Use `@azure-tools/eslint-plugin-azure-sdk`. |
| `ts-eslint-no-warnings` | MUST | Pass ESLint with no errors or warnings. |
| `ts-use-prettier` | MUST | Use Prettier for formatting. |
| `ts-prettier-consistent` | MUST | Use the same Prettier config across all Azure SDK JS packages. |
| `ts-use-api-extractor` | MUST | Use API Extractor to validate public API surface. |
| `ts-api-extractor-review` | MUST | Review and commit `.api.md` files. |
| `ts-strict-mode` | MUST | Enable TypeScript strict mode. |
| `ts-no-compilation-errors` | MUST | Code must compile without errors or warnings. |
| `ts-use-tshy` | MUST | Use `tshy` for multi-format builds (ESM, CJS, Browser, React Native). |

**Prettier configuration** (must match):
```json
{
  "arrowParens": "always",
  "bracketSpacing": true,
  "endOfLine": "lf",
  "printWidth": 100,
  "semi": true,
  "singleQuote": false,
  "tabWidth": 2,
  "trailingComma": "es5"
}
```

---

## 25. Configuration

| ID | Level | Rule |
|----|-------|------|
| `general-config-global-config` | MUST | Use relevant global configuration settings by default or when requested. |
| `general-config-for-different-clients` | MUST | Allow different clients of the same type to use different configurations. |
| `general-config-optout` | MUST | Allow consumers to opt out of all global configuration at once. |
| `general-config-global-overrides` | MUST | Allow all global settings to be overridden by client options. |
| `general-config-behaviour-changes` | MUST NOT | Change behavior based on config changes after client construction (except log level and tracing on/off). |
| `general-config-envvars-prefix` | MUST | Prefix Azure-specific environment variables with `AZURE_`. |
| `general-config-envvars-format` | MUST | Use `AZURE_<ServiceName>_<ConfigurationKey>` syntax. |
| `general-config-envvars-posix-compatible` | MUST NOT | Use non-alphanumeric chars in env var names (except underscore). |
| `general-config-envvars-get-approval` | MUST | Get Architecture Board approval for every new environment variable. |

---

## 26. Conditional Requests

| ID | Level | Rule |
|----|-------|------|
| `ts-conditional-request-options-1` | MUST | When model has `etag`: provide `onlyIfChanged`, `onlyIfUnchanged`, `onlyIfMissing`, `onlyIfPresent` options. |
| `ts-conditional-request-options-2` | MUST | When model has no `etag`: provide `conditions` property with `ifMatch`, `ifNoneMatch`, `ifModifiedSince`, `ifUnmodifiedSince`. |
| `ts-conditional-request-no-dupe-options` | MUST | Throw if both option sets are provided. |

---

## 27. Azure Core Usage

| ID | Level | Rule |
|----|-------|------|
| `ts-core-types-must` | MUST | Use packages from Azure Core: `core-rest-pipeline`, `logger`, `core-tracing`, `core-auth`, `core-lro`. |

---

## 28. Retry Policy (Azure Core)

| ID | Level | Rule |
|----|-------|------|
| `azurecore-http-retry-options` | MUST | Offer config: retry type (exponential/fixed), max retries, delay, max delay, retryable status codes. |
| `azurecore-http-retry-reset-data-stream` | MUST | Reset request data stream to position 0 before retrying. |
| `azurecore-http-retry-honor-cancellation` | MUST | Honor cancellation before retries are attempted. |
| `azurecore-http-retry-hardware-failure` | MUST | Retry on hardware network failures. |
| `azurecore-http-retry-service-not-found` | MUST | Retry on "service not found" errors. |
| `azurecore-http-retry-throttling` | MUST | Retry when service indicates throttling. |
| `azurecore-http-retry-after` | MUST NOT | Retry 400-level responses unless `Retry-After` header is present. |
| `azurecore-http-retry-requestid` | MUST NOT | Change client-side request ID on retries. |
| `azurecore-http-retry-defaults` | SHOULD | Default: 3 retries, 0.8s exponential + jitter, 60s max delay. |

---

## 29. Compatibility

| Level | Rule |
|-------|------|
| Principle | Libraries must be as compatible or better than the base libraries of their language. |
| Principle | All non-explicitly-compatible changes must be reviewed by the Architecture Board. |
| Principle | API additions are not necessarily non-breaking (depends on language). Refer to language-specific guidelines. |
| Principle | Logging changes (new entries, new schema) are allowed only in major/minor versions, not patch. |

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
8. **Logging**: Uses `debug` module, channels prefixed `azure:<service>`, no sensitive data
9. **Tracing**: OpenTelemetry support, proper span naming and hierarchy
10. **Dependencies**: Only Azure Core deps in production, no polyfills, no tiny libraries
11. **Versioning**: Semver, no v0.x, beta uses `1.0.0-beta.X`, no features in patches
12. **Tests**: Vitest, independent, supports recording, >90% coverage, no sensitive data in recordings
13. **Package.json**: All required fields present, correct values, `sideEffects: false`
14. **TypeScript**: Strict mode, no `const enum`, no namespaces, type declarations shipped
15. **Documentation**: Snippets in docstrings, built in CI, README has "Configure TypeScript" section

## Consistency with Codebase Patterns

### PR Hygiene

- **Keep PRs focused on their stated scope.** No accidental file modifications, no unrelated refactoring, no whitespace noise, no build artifacts. Each PR should serve a single purpose.
  > "Please be more deliberate about your pull requests... it makes for a very muddy source history." — bartonjs

- **Do large refactorings and renames in separate PRs.** Separate no-diff refactors from functional changes. Mechanical renames should be separate from logic changes.
  > "I always prefer to do the no-diff refactors first and build the diff changes on top." — AndyAyersMS

### Code Reuse & Deduplication

- **Extract duplicated logic into shared helper methods.** Fix improvements inside shared helpers so all callers benefit.
  > "Would it be better to move this to a helper method instead of duplicating it?" — tarekgh

- **Use existing APIs instead of creating parallel ones.** Before introducing new types, enums, or helpers, check if existing ones serve the same purpose. Fix existing utilities rather than introducing duplicates.
  > "Can you use the existing SignatureAttributes.Instance instead? It means the same thing." — jkotas

- **Delete dead code and unused declarations aggressively.** When removing code, also remove helper methods, enum values, function declarations, and resx strings that are no longer used.
  > "This function isn't used. Please delete." — davidwrighton

### Established Conventions

- **Sort lists and entries alphabetically.** Lists of areas, configuration entries, resx entries, entrypoint/export lists, and ref source members should be maintained in alphabetical order.
  > "The list of areas looks sorted in alphabetical order." — jkotas

- **Don't modify auto-generated files or `eng/common` manually.** Change the generator or source definition instead. Files in `eng/common` are synced from azure/azure-sdk.

- **Match existing style in modified files.** The existing style in a file takes precedence over general guidelines. Do not change existing code for style alone.
  > "If a file happens to differ in style from these guidelines, the existing style in that file takes precedence." — huoyaoyuan

## Testing

- **Always add regression tests for bug fixes and behavior changes.** Prefer adding `[InlineData]` test cases to existing test files rather than creating new ones. Ensure new test files are included in the csproj.
  > "The PR needs a regression test added. TypeInfoTests.cs is a good place to add it (add new InlineData)." — jkotas

- **Test edge cases, error paths, and all affected types.** Include empty strings, negative values, boundary conditions, Turkish 'i', surrogate pairs. Test both true and false for boolean options. Choose inputs that can't accidentally pass if output wasn't touched.
  > "Pick an input that doesn't decode to all 0s so that the test can't pass even if the output wasn't touched at all." — MihaZupan

- **Delete flaky and low-value tests rather than patching them.** Do not add tests known to be flaky. If a test relies on fragile runtime details and cannot be made reliable, prefer deletion.
  > "It would be better to delete the test. No point in adding flaky tests." — jkotas

---

## Documentation & Comments

- **Comments should explain why, not restate code.** Delete comments like `// Get the types` that just duplicate the code in English. Don't include historical context about why code changed.
  > "Comments that just duplicate the code in plain English are not very useful. This comment should explain why we are doing this." — jkotas

- **Delete or update obsolete comments when code changes.** Stale comments describing old behavior are worse than no comments.
  > "The whole comment starting with `Note:` can be deleted. It is no longer applicable." — jkotas

- **Track deferred work with GitHub issues and searchable TODOs.** Reference a tracking issue in TODO comments with a consistent prefix (e.g., `TODO-Async:`). Remove ancient TODOs that will never be addressed.
  > "Could you please tag all these places that need review with async TODO so that they can be found easily and none of them falls through the cracks?" — jkotas

- **Don't duplicate comments on interface implementations.** Documentation comments belong on the interface definition. Duplicating leads to divergence.
  > "It is enough to have these comments on the interface. Duplicating them is just going to lead to the comments diverging over time." — jkotas

- **Use SHA-specific or commit-based links in documentation.** Don't use branch-relative links that break when files move.
  > "Best to use sha-specific links." — richlander

- **Retain copyright headers and license information.** All C# and C++ source files must include the standard license header, including test files. When porting from other projects, retain original copyright and update THIRD-PARTY-NOTICES.TXT.

---
