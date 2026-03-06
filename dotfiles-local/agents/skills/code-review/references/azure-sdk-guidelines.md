# Azure SDK Design Guidelines — JavaScript / TypeScript

Full reference for Azure SDK design guidelines. Consult the relevant sections when reviewing
public API surface, packaging, or cross-cutting concerns.

---

### 1. Naming & Namespaces

| ID                                       | Level    | Rule                                                                                                                               |
| ---------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `ts-azure-scope`                         | MUST     | Publish to the `@azure` npm scope (DPG) or `@azure-rest` scope (RLC).                                                              |
| `ts-npm-package-name-prefix`             | MUST     | Prefix data-plane package names with the kebab-case version of the appropriate namespace.                                          |
| `ts-npm-package-name-follow-conventions` | SHOULD   | Follow the casing conventions of existing stable packages in the `@azure` scope.                                                   |
| `ts-namespace-serviceclient`             | MUST     | Pick a package name that lets consumers tie it to the service. Use compressed service name. Avoid marketing names that may change. |
| `general-namespaces-shortened-name`      | MUST     | Use a shortened, stable service name (not marketing names).                                                                        |
| `general-namespaces-mgmt`                | MUST     | Place management (ARM) APIs in the `management` group.                                                                             |
| `general-namespaces-similar-names`       | MUST NOT | Choose similar names for clients that do different things.                                                                         |
| `general-namespaces-registration`        | MUST     | Register chosen namespace with the Architecture Board.                                                                             |

**Good examples**: `@azure/cosmos`, `@azure/storage-blob`, `@azure/digital-twins-core`
**Bad examples**: `@microsoft/cosmos` (wrong scope), `@azure/digitaltwins` (not kebab-cased)

---

### 2. Client Design

| ID                                       | Level    | Rule                                                                                                                                                                                                       |
| ---------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ts-apisurface-serviceclientnaming`      | MUST     | Name service client types with the `Client` suffix.                                                                                                                                                        |
| `ts-apisurface-serviceclientnamespace`   | MUST     | Place primary service client types as top-level exports.                                                                                                                                                   |
| `ts-apisurface-serviceclientconstructor` | MUST     | Allow constructing a client with minimal information needed to connect and authenticate.                                                                                                                   |
| `ts-apisurface-supportallfeatures`       | MUST     | Support 100% of the features provided by the Azure service.                                                                                                                                                |
| `ts-apisurface-standardized-verbs`       | MUST     | Standardize verb prefixes within client libraries for a service.                                                                                                                                           |
| `ts-approved-verbs`                      | SHOULD   | Use approved verbs: `create<Noun>`, `upsert<Noun>`, `set<Noun>`, `update<Noun>`, `replace<Noun>`, `append<Noun>`, `add<Noun>`, `get<Noun>`, `list<Noun>s`, `<noun>Exists`, `delete<Noun>`, `remove<Noun>`. |
| `ts-naming-drop-noun`                    | MUST NOT | Include the noun when operating on the resource itself (e.g., `client.delete()` not `client.deleteItem()`).                                                                                                |
| `ts-naming-subclients`                   | MUST     | Prefix methods that create/vend subclients with `get` and suffix with `client` (e.g., `getBlobClient()`).                                                                                                  |
| `ts-use-constructor-overloads`           | SHOULD   | Provide overloaded constructors for all construction scenarios. Prefix static constructors with `from`.                                                                                                    |
| `ts-use-overloads-over-unions`           | SHOULD   | Prefer overloads over unions when parameters are correlated or users want tailored docs.                                                                                                                   |

#### Hierarchical Clients

| ID                                 | Level  | Rule                                                                        |
| ---------------------------------- | ------ | --------------------------------------------------------------------------- |
| `ts-hierarchy-clients`             | MUST   | Create a client type for each level in the hierarchy.                       |
| `ts-hierarchy-direct-construction` | MUST   | Support directly constructing clients at any hierarchy level.               |
| `ts-hierarchy-get-child`           | MUST   | Provide `get<Child>Client()` methods. These MUST NOT make network requests. |
| `ts-hierarchy-create-methods`      | SHOULD | Provide `create<Child>()` methods on parent clients.                        |

---

### 3. Service Versions

| ID                                       | Level | Rule                                                                           |
| ---------------------------------------- | ----- | ------------------------------------------------------------------------------ |
| `ts-service-versions-use-latest`         | MUST  | Default to the highest supported service API version.                          |
| `ts-service-versions-select-api-version` | MUST  | Allow the consumer to explicitly select a supported service API version.       |
| `general-service-apiversion-1`           | MUST  | Only target GA service API versions when releasing a stable client library.    |
| `general-service-apiversion-3`           | MUST  | Target the latest preview API version by default in beta releases.             |
| `general-service-apiversion-4`           | MUST  | Include all supported service API versions in a `ServiceVersion` enum.         |
| `general-service-apiversion-5`           | MUST  | Document the default service API version.                                      |
| `general-service-apiversion-7`           | MUST  | Replace `api-version` on any service-returned URI with the configured version. |

---

### 4. Options & Parameters

| ID                                 | Level    | Rule                                                                                     |
| ---------------------------------- | -------- | ---------------------------------------------------------------------------------------- |
| `ts-naming-options`                | MUST     | Name option bag types as `<ClassName>Options` or `<MethodName>Options`.                  |
| `ts-options-abortSignal`           | MUST     | Name abort signal options `abortSignal`.                                                 |
| `ts-options-suffix-durations`      | MUST     | Suffix durations with `In<Unit>` (e.g., `timeoutInMs`, `delayInSeconds`).                |
| `general-params-client-validation` | MUST     | Validate client parameters (null checks, empty strings for required path params).        |
| `general-params-server-validation` | MUST NOT | Validate service parameters — let the service validate.                                  |
| `general-params-server-defaults`   | MUST NOT | Encode default values for service parameters (defaults can change between api-versions). |

---

### 5. Response Formats

| ID                                       | Level      | Rule                                                                      |
| ---------------------------------------- | ---------- | ------------------------------------------------------------------------- |
| `ts-return-logical-entities`             | MUST       | Return the logical entity for a request (what 99%+ of callers need).      |
| `ts-return-document-raw-stream`          | MUST       | Document how to access raw/streamed responses with samples.               |
| `general-return-no-headers-if-confusing` | MUST NOT   | Return headers unless it's obvious which HTTP request they correspond to. |
| `general-dont-use-value`                 | SHOULD NOT | Use property names `object` or `value` within logical entities.           |

---

### 6. Authentication

| ID                                              | Level    | Rule                                                                              |
| ----------------------------------------------- | -------- | --------------------------------------------------------------------------------- |
| `general-auth-provide-token-client-constructor` | MUST     | Accept `TokenCredential` from Azure Core in client constructors.                  |
| `general-auth-use-core`                         | MUST     | Use authentication policy implementations from Azure Core.                        |
| `general-auth-support`                          | MUST     | Support all authentication schemes the service supports.                          |
| `general-auth-reserve-when-not-suported`        | MUST     | Reserve API surface for TokenCredential even if not yet supported by the service. |
| `general-auth-connection-strings`               | MUST NOT | Support connection strings unless available in tooling for copy/paste.            |
| `auth-client-no-token-persistence`              | MUST NOT | Persist, cache, or reuse tokens from the token credential.                        |
| `general-auth-credential-type-prefix`           | MUST     | Prepend custom credential type names with the service name.                       |
| `general-auth-credential-type-suffix`           | MUST     | Append `Credential` (singular) to custom credential type names.                   |
| `general-authimpl-no-persisting`                | MUST NOT | Persist, cache, or reuse security credentials.                                    |

---

### 7. Pagination

| ID                                        | Level    | Rule                                                                                                         |
| ----------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------ |
| `ts-pagination-provide-list`              | MUST     | Return `PagedAsyncIterableIterator` from `list` methods.                                                     |
| `ts-pagination-take-continuationToken`    | MUST     | Accept `continuationToken` in `byPage()`. Continuation token on page type must be named `continuationToken`. |
| `ts-pagination-provide-bypage-settings`   | MUST NOT | Provide page-related settings other than `continuationToken` to `byPage()`.                                  |
| `general-pagination-distinct-types`       | MUST     | Use different types for list vs. get if they have different shapes.                                          |
| `general-pagination-no-item-iterators`    | MUST NOT | Expose item iterator if it causes additional service requests.                                               |
| `general-pagination-support-toArray`      | MUST NOT | Provide an API to get a paginated collection into an array.                                                  |
| `general-pagination-expose-lists-equally` | MUST     | Expose non-paginated lists identically to paginated lists.                                                   |

---

### 8. Long Running Operations (LRO)

| ID                          | Level    | Rule                                                                                                                                    |
| --------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `ts-lro-return-poller`      | MUST     | Return a poller object with APIs for: state query, completion notification, cancellation, disinterest, manual poll, progress reporting. |
| `ts-lro-support-options`    | MUST     | Support `pollInterval` and `resumeFrom` options.                                                                                        |
| `ts-lro-continuation`       | MUST     | Allow instantiating a poller from serialized state of another poller.                                                                   |
| `ts-lro-cancellation`       | MUST NOT | Cancel the long-running operation itself when cancellation token fires — only cancel polling.                                           |
| `ts-lro-progress-reporting` | MUST     | Expose progress reporting if the service supports it.                                                                                   |

---

### 9. Error Handling

| ID                                        | Level      | Rule                                                                                               |
| ----------------------------------------- | ---------- | -------------------------------------------------------------------------------------------------- |
| `general-errors-for-failed-requests`      | MUST       | Produce an error for any HTTP request with a non-success status code. Log as errors.               |
| `general-errors-include-request-response` | MUST       | Include HTTP response (status, headers) and request (URL, query params, headers) in errors.        |
| `general-errors-rich-info`                | MUST       | Surface rich service error information (from headers/body) via service-specific properties.        |
| `general-errors-documentation`            | MUST       | Document errors produced by each method.                                                           |
| `general-errors-no-new-types`             | SHOULD NOT | Create new error types unless they enable alternate remediation actions. Base on Azure Core types. |
| `general-errors-use-system-types`         | MUST NOT   | Create new error types when language-built-in types suffice.                                       |
| `ts-error-handling`                       | MUST       | Use `TypeError`, `RangeError`, or `Error` as appropriate.                                          |
| `ts-error-handling-coercion`              | SHOULD     | Coerce incorrect types when possible (JavaScript fuzziness).                                       |
| `ts-error-use-name`                       | SHOULD     | Check `error.name` in catch clauses rather than `instanceof`.                                      |

---

### 10. Logging

| ID                                  | Level | Rule                                                                  |
| ----------------------------------- | ----- | --------------------------------------------------------------------- |
| `ts-logging-use-azure-logger`       | MUST  | Use `@azure/logger` (which wraps the `debug` module) for logging.     |
| `ts-logging-prefix-channel-names`   | MUST  | Prefix channels with `azure:<service-name>`.                          |
| `ts-logging-channels`               | MUST  | Create channels: `:error`, `:warning`, `:info`, `:verbose`.           |
| `ts-logging-top-level-exports`      | MUST  | Expose all log channels as top-level exports.                         |
| `general-logging-no-sensitive-info` | MUST  | Only log headers/query params from the allow-list. Redact all others. |
| `general-logging-requests`          | MUST  | Log request line and headers at `Informational` level.                |
| `general-logging-responses`         | MUST  | Log response line, headers, and timing at `Informational` level.      |
| `general-logging-cancellations`     | MUST  | Log cancellation at `Informational` level with request ID and reason. |
| `general-logging-exceptions`        | MUST  | Log exceptions at `Warning` level; stack trace at `Verbose`.          |

---

### 11. Distributed Tracing

| ID                                                        | Level | Rule                                                                              |
| --------------------------------------------------------- | ----- | --------------------------------------------------------------------------------- |
| `general-tracing-opentelemetry`                           | MUST  | Support OpenTelemetry for distributed tracing.                                    |
| `general-tracing-accept-context`                          | MUST  | Accept a context from calling code via `OperationOptions.tracingOptions`.         |
| `general-tracing-new-span-per-method`                     | MUST  | Create one span per user-facing client method call.                               |
| `general-tracing-suppress-client-spans-for-inner-methods` | MUST  | Suppress inner client method spans when called from another public client method. |
| `general-tracing-new-span-per-rest-call`                  | MUST  | Create a child span for each REST call.                                           |
| `general-tracing-new-span-per-method-naming`              | MUST  | Use `{Namespace}.{Interface}.{OperationName}` as span name.                       |
| `general-tracing-new-span-per-method-failure`             | MUST  | Record error details on span if method throws.                                    |

---

### 12. Network & HTTP Pipeline

| ID                                  | Level    | Rule                                                                                                   |
| ----------------------------------- | -------- | ------------------------------------------------------------------------------------------------------ |
| `ts-use-core-rest-pipeline`         | MUST     | Use `@azure/core-rest-pipeline` for HTTP communication.                                                |
| `ts-pipeline-use-default-policies`  | MUST     | Include standard policies: User-Agent, Telemetry, Request ID, Retry, Logging, Authentication, Tracing. |
| `ts-network-accept-abort-signal`    | MUST     | Accept `abortSignal` on all async service methods.                                                     |
| `ts-network-no-leak-implementation` | MUST NOT | Leak protocol transport implementation details.                                                        |
| `general-network-no-leakage`        | MUST NOT | Expose underlying protocol transport types to consumers.                                               |
| `general-requests-use-pipeline`     | MUST     | Use the HTTP pipeline from Azure Core.                                                                 |

---

### 13. Telemetry

| ID                                      | Level    | Rule                                                                                      |
| --------------------------------------- | -------- | ----------------------------------------------------------------------------------------- |
| `ts-telemetry-useragent-header`         | MUST     | Send `User-Agent` in format: `azsdk-js-<package-name>/<package-version> <platform-info>`. |
| `ts-telemetry-no-pii`                   | MUST NOT | Include PII in telemetry headers.                                                         |
| `ts-telemetry-no-sensitive-data`        | MUST NOT | Include sensitive data in telemetry headers, even encoded.                                |
| `azurecore-http-telemetry-appid-length` | MUST     | Enforce application ID is no more than 24 characters.                                     |

---

### 14. Repeatable Requests

| ID                                                     | Level      | Rule                                                                                                                                                   |
| ------------------------------------------------------ | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `general-repeatable-requests-request-headers`          | MUST       | Add `Repeatability-Request-ID` (UUID) and `Repeatability-First-Sent` (IMF fixdate) headers before sending. Values must remain the same across retries. |
| `general-repeatable-requests-parameters`               | SHOULD NOT | Offer explicit parameters to set repeatability headers.                                                                                                |
| `general-repeatable-requests-support-response-headers` | MUST       | Expose `Repeatability-Result` response header in the response model.                                                                                   |

---

### 15. TypeScript & Language Rules

| ID                                 | Level      | Rule                                                              |
| ---------------------------------- | ---------- | ----------------------------------------------------------------- |
| `ts-use-typescript`                | MUST       | Implement in TypeScript.                                          |
| `ts-ship-type-declarations`        | MUST       | Include type declarations.                                        |
| `ts-use-promises`                  | MUST       | Use built-in promises for async. Do not import a polyfill.        |
| `ts-use-async-functions`           | SHOULD     | Use `async` functions for async APIs.                             |
| `ts-use-iterators`                 | MUST       | Use Iterators and Async Iterators for sequences/streams.          |
| `ts-use-interface-parameters`      | SHOULD     | Prefer interface types over class types for parameters.           |
| `ts-avoid-extending-cross-package` | MUST       | Not extend classes from a different package.                      |
| `ts-no-namespaces`                 | SHOULD NOT | Use TypeScript namespaces. Use ESM imports/exports.               |
| `ts-no-const-enums`                | SHOULD NOT | Use `const enum` (incompatible with Babel 7).                     |
| `ts-use-extensible-enums`          | MUST       | Use string literal unions for service enumerations.               |
| `ts-no-typescript-enums`           | MUST NOT   | Use TypeScript `enum` for service-defined enumerations.           |
| `ts-extensible-enum-namespace`     | SHOULD     | Provide a `Known<EnumName>` namespace with known value constants. |
| `ts-modules-only-named`            | MUST       | Only have named exports at top level.                             |
| `ts-modules-no-default`            | MUST NOT   | Have a default export at top level.                               |

---

### 16. tsconfig.json

| ID                                           | Level    | Rule                                                              |
| -------------------------------------------- | -------- | ----------------------------------------------------------------- |
| `ts-config-strict`                           | MUST     | Set `compilerOptions.strict` to `true`.                           |
| `ts-config-esModuleInterop`                  | MUST     | Set `compilerOptions.esModuleInterop` to `true`.                  |
| `ts-config-allowSyntheticDefaultImports`     | MUST     | Set `compilerOptions.allowSyntheticDefaultImports` to `true`.     |
| `ts-config-forceConsistentCasingInFileNames` | MUST     | Set `compilerOptions.forceConsistentCasingInFileNames` to `true`. |
| `ts-config-declaration`                      | MUST     | Set `compilerOptions.declaration` to `true`.                      |
| `ts-config-sourceMap`                        | MUST     | Set `compilerOptions.sourceMap` and `declarationMap` to `true`.   |
| `ts-config-importHelpers`                    | MUST     | Set `compilerOptions.importHelpers` to `true`.                    |
| `ts-config-no-experimentalDecorators`        | MUST NOT | Set `compilerOptions.experimentalDecorators` to `true`.           |
| `ts-config-lib`                              | MUST NOT | Use `compilerOptions.lib`.                                        |

---

### 17. Package Structure & package.json

| ID                                  | Level    | Rule                                                                       |
| ----------------------------------- | -------- | -------------------------------------------------------------------------- |
| `ts-package-json-name`              | MUST     | Set `name` to `@azure/<name>` (kebab-case).                                |
| `ts-package-json-homepage`          | MUST     | Set `homepage` to the library's README URL in the repo.                    |
| `ts-package-json-bugs`              | MUST     | Set `bugs.url` to `https://github.com/Azure/azure-sdk-for-js/issues`.      |
| `ts-package-json-repo`              | MUST     | Set `repository` to `github:Azure/azure-sdk-for-js`.                       |
| `ts-package-json-author`            | MUST     | Set `author` to `"Microsoft Corporation"`.                                 |
| `ts-package-json-license`           | MUST     | Set `license` to `"MIT"`.                                                  |
| `ts-package-json-sideeffects`       | MUST     | Set `sideEffects` to `false`.                                              |
| `ts-package-json-main-is-cjs`       | MUST     | Set `main` to a CJS or UMD module.                                         |
| `ts-package-json-main-is-not-es6`   | MUST NOT | Set `main` to include ESM syntax.                                          |
| `ts-package-json-module`            | MUST     | Set `module` to the ESM entrypoint.                                        |
| `ts-package-json-types`             | MUST     | Set `types` to the TypeScript type declarations.                           |
| `ts-package-json-engine-is-present` | MUST     | Set `engine` to supported Node versions.                                   |
| `ts-package-json-keywords`          | MUST     | Include at least `"Azure"`, `"cloud"`, and the service name in `keywords`. |
| `ts-package-json-files-required`    | MUST     | Set `files` to an array of package content paths.                          |
| `ts-package-json-required-scripts`  | MUST     | Include at least `"build"` and `"test"` scripts.                           |
| `ts-no-npmignore`                   | MUST NOT | Use `.npmignore`. Use `files` in package.json.                             |
| `ts-no-tsconfig`                    | MUST NOT | Include `tsconfig.json` in the published package.                          |

---

### 18. Distributions & Modules

| ID                             | Level    | Rule                                                                    |
| ------------------------------ | -------- | ----------------------------------------------------------------------- |
| `ts-include-cjs`               | MUST     | Include a CJS or UMD build for Node support.                            |
| `ts-flatten-umd`               | MUST     | Flatten the CJS/UMD module (use Rollup).                                |
| `ts-include-esm`               | MUST     | Include an ESM build.                                                   |
| `ts-include-esm-not-flattened` | MUST NOT | Flatten the ESM build.                                                  |
| `ts-no-browser-bundle`         | MUST NOT | Include a browser bundle in the package.                                |
| `ts-include-original-source`   | MUST     | Include source code in source map `sourcesContent` via `inlineSources`. |

---

### 19. Dependencies

| ID                                   | Level      | Rule                                                                                   |
| ------------------------------------ | ---------- | -------------------------------------------------------------------------------------- |
| `ts-dependencies-azure-core`         | MUST       | Depend on Azure Core for common functionality.                                         |
| `ts-dependencies-no-other-packages`  | MUST NOT   | Depend on packages other than Azure Core in the distribution. Build deps are OK.       |
| `ts-dependencies-consider-vendoring` | SHOULD     | Consider vendoring required code to avoid external dependencies.                       |
| `ts-dependencies-no-tiny-libraries`  | SHOULD NOT | Depend on tiny libraries (cost adds up).                                               |
| `ts-dependencies-no-polyfills`       | SHOULD NOT | Depend on polyfills that modify global scope. Document requirements in README instead. |
| `general-dependencies-concrete`      | MUST NOT   | Depend on concrete logging, DI, or config technologies (except Azure Core).            |

**Pre-approved production dependencies**: `rhea`, `rhea-promise` (AMQP only).

---

### 20. Versioning

| ID                                        | Level    | Rule                                                                                           |
| ----------------------------------------- | -------- | ---------------------------------------------------------------------------------------------- |
| `ts-versioning-semver`                    | MUST     | Version with semver.                                                                           |
| `ts-versioning-no-ga-prerelease`          | MUST NOT | Use pre-release version or build metadata for stable packages.                                 |
| `ts-versioning-beta`                      | MUST     | Use `1.0.0-beta.X` format for beta packages.                                                   |
| `ts-versioning-no-version-0`              | MUST NOT | Use major version 0, even for beta packages.                                                   |
| `general-versioning-bump`                 | MUST     | Change the version number when ANYTHING changes.                                               |
| `general-versioning-patch`                | MUST     | Increment patch for bug fixes only.                                                            |
| `general-versioning-no-features-in-patch` | MUST NOT | Include new features in a patch release.                                                       |
| `general-versioning-no-breaking-changes`  | MUST NOT | Make breaking changes. If absolutely required, get Architecture Board approval and bump major. |
| `ts-npm-dist-tag-beta`                    | MUST     | Tag beta packages with `beta` dist-tag.                                                        |
| `ts-npm-dist-tag-next`                    | MUST     | Tag GA packages with `latest` dist-tag.                                                        |

---

### 21. Platform Support

| ID                              | Level      | Rule                                                                                    |
| ------------------------------- | ---------- | --------------------------------------------------------------------------------------- |
| `ts-node-support`               | MUST       | Support all LTS Node versions and newer up to latest release.                           |
| `ts-browser-support`            | MUST       | Support Safari (latest 2), Chrome (latest 2), Edge (all supported), Firefox (latest 2). |
| `ts-no-ie11-support`            | SHOULD NOT | Support IE11.                                                                           |
| `ts-support-ts`                 | MUST       | Compile without errors on all TypeScript versions less than 2 years old.                |
| `ts-register-dropped-platforms` | MUST       | Get Architecture Board approval to drop platform support.                               |

---

### 22. Testing

| ID                          | Level    | Rule                                                                                                                |
| --------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------- |
| `ts-use-vitest`             | MUST     | Use vitest as the test framework.                                                                                   |
| `ts-test-unit-tests`        | MUST     | Write unit tests without network calls.                                                                             |
| `ts-test-integration-tests` | MUST     | Write integration tests against the live service.                                                                   |
| `ts-test-support-recording` | MUST     | Support recording/playback of HTTP interactions via `@azure-tools/test-recorder`.                                   |
| `ts-test-coverage`          | MUST     | Maintain >90% coverage for core, 100% for critical paths (auth, retries, errors), tests for all public API surface. |
| `ts-test-independent`       | MUST     | Tests must be independent and order-agnostic.                                                                       |
| `ts-test-cleanup`           | MUST     | Clean up resources created during tests.                                                                            |
| `general-testing-3`         | MUST     | Use unique, descriptive test case names.                                                                            |
| `general-testing-5`         | MUST NOT | Rely on pre-existing test resources or leave resources behind after tests.                                          |
| `general-testing-6`         | MUST     | All tests must work without network connectivity.                                                                   |
| `general-testing-7`         | MUST     | Use mock service implementation with recorded tests per service version.                                            |
| `general-testing-9`         | MUST     | Enable network-mocked tests to also connect to live service with unchanged assertions.                              |
| `general-testing-10`        | MUST NOT | Include sensitive information in recorded tests.                                                                    |
| `general-testing-mocking`   | MUST     | Support mocking of service client methods.                                                                          |

---

### 23. Documentation & Samples

| ID                                    | Level    | Rule                                                                                |
| ------------------------------------- | -------- | ----------------------------------------------------------------------------------- |
| `general-docs-contentdev`             | MUST     | Include content developer in Architecture Board reviews.                            |
| `general-docs-style-guide`            | MUST     | Follow Microsoft Writing Style Guide and Cloud Style Guide.                         |
| `general-docs-to-silence`             | SHOULD   | Document into silence — preempt usage questions.                                    |
| `general-docs-include-snippets`       | MUST     | Include code snippets demonstrating common operations and champion scenarios.       |
| `general-docs-build-snippets`         | MUST     | Build and test snippets in CI.                                                      |
| `general-docs-snippets-in-docstrings` | MUST     | Include snippets in docstrings for API reference.                                   |
| `general-docs-operation-combinations` | MUST NOT | Combine multiple operations in one snippet (unless in addition to atomic snippets). |
| `ts-readme-ts-config`                 | MUST     | Document required `tsconfig.json` settings in README under "Configure TypeScript".  |
| `ts-need-js-samples`                  | MUST     | Have JavaScript samples.                                                            |
| `ts-need-ts-samples`                  | SHOULD   | Have TypeScript samples.                                                            |
| `ts-need-browser-samples`             | SHOULD   | Have browser-tailored samples.                                                      |

---

### 24. Code Quality & Tooling

| ID                           | Level  | Rule                                                                  |
| ---------------------------- | ------ | --------------------------------------------------------------------- |
| `ts-use-eslint`              | MUST   | Use ESLint for static analysis.                                       |
| `ts-use-azure-eslint-plugin` | SHOULD | Use `@azure-tools/eslint-plugin-azure-sdk`.                           |
| `ts-eslint-no-warnings`      | MUST   | Pass ESLint with no errors or warnings.                               |
| `ts-use-prettier`            | MUST   | Use Prettier for formatting.                                          |
| `ts-prettier-consistent`     | MUST   | Use the same Prettier config across all Azure SDK JS packages.        |
| `ts-use-api-extractor`       | MUST   | Use API Extractor to validate public API surface.                     |
| `ts-api-extractor-review`    | MUST   | Review and commit `.api.md` files.                                    |
| `ts-strict-mode`             | MUST   | Enable TypeScript strict mode.                                        |
| `ts-no-compilation-errors`   | MUST   | Code must compile without errors or warnings.                         |
| `ts-use-tshy`                | MUST   | Use `tshy` for multi-format builds (ESM, CJS, Browser, React Native). |

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

### 25. Configuration

| ID                                        | Level    | Rule                                                                                                     |
| ----------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------- |
| `general-config-global-config`            | MUST     | Use relevant global configuration settings by default or when requested.                                 |
| `general-config-for-different-clients`    | MUST     | Allow different clients of the same type to use different configurations.                                |
| `general-config-optout`                   | MUST     | Allow consumers to opt out of all global configuration at once.                                          |
| `general-config-global-overrides`         | MUST     | Allow all global settings to be overridden by client options.                                            |
| `general-config-behaviour-changes`        | MUST NOT | Change behavior based on config changes after client construction (except log level and tracing on/off). |
| `general-config-envvars-prefix`           | MUST     | Prefix Azure-specific environment variables with `AZURE_`.                                               |
| `general-config-envvars-format`           | MUST     | Use `AZURE_<ServiceName>_<ConfigurationKey>` syntax.                                                     |
| `general-config-envvars-posix-compatible` | MUST NOT | Use non-alphanumeric chars in env var names (except underscore).                                         |
| `general-config-envvars-get-approval`     | MUST     | Get Architecture Board approval for every new environment variable.                                      |

---

### 26. Conditional Requests

| ID                                       | Level | Rule                                                                                                                           |
| ---------------------------------------- | ----- | ------------------------------------------------------------------------------------------------------------------------------ |
| `ts-conditional-request-options-1`       | MUST  | When model has `etag`: provide `onlyIfChanged`, `onlyIfUnchanged`, `onlyIfMissing`, `onlyIfPresent` options.                   |
| `ts-conditional-request-options-2`       | MUST  | When model has no `etag`: provide `conditions` property with `ifMatch`, `ifNoneMatch`, `ifModifiedSince`, `ifUnmodifiedSince`. |
| `ts-conditional-request-no-dupe-options` | MUST  | Throw if both option sets are provided.                                                                                        |

---

### 27. Azure Core Usage

| ID                   | Level | Rule                                                                                                   |
| -------------------- | ----- | ------------------------------------------------------------------------------------------------------ |
| `ts-core-types-must` | MUST  | Use packages from Azure Core: `core-rest-pipeline`, `logger`, `core-tracing`, `core-auth`, `core-lro`. |

---

### 28. Retry Policy (Azure Core)

| ID                                        | Level    | Rule                                                                                                 |
| ----------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------- |
| `azurecore-http-retry-options`            | MUST     | Offer config: retry type (exponential/fixed), max retries, delay, max delay, retryable status codes. |
| `azurecore-http-retry-reset-data-stream`  | MUST     | Reset request data stream to position 0 before retrying.                                             |
| `azurecore-http-retry-honor-cancellation` | MUST     | Honor cancellation before retries are attempted.                                                     |
| `azurecore-http-retry-hardware-failure`   | MUST     | Retry on hardware network failures.                                                                  |
| `azurecore-http-retry-service-not-found`  | MUST     | Retry on "service not found" errors.                                                                 |
| `azurecore-http-retry-throttling`         | MUST     | Retry when service indicates throttling.                                                             |
| `azurecore-http-retry-after`              | MUST NOT | Retry 400-level responses unless `Retry-After` header is present.                                    |
| `azurecore-http-retry-requestid`          | MUST NOT | Change client-side request ID on retries.                                                            |
| `azurecore-http-retry-defaults`           | SHOULD   | Default: 3 retries, 0.8s exponential + jitter, 60s max delay.                                        |

---

### 29. Compatibility

| Level     | Rule                                                                                                         |
| --------- | ------------------------------------------------------------------------------------------------------------ |
| Principle | Libraries must be as compatible or better than the base libraries of their language.                         |
| Principle | All non-explicitly-compatible changes must be reviewed by the Architecture Board.                            |
| Principle | API additions are not necessarily non-breaking (depends on language). Refer to language-specific guidelines. |
| Principle | Logging changes (new entries, new schema) are allowed only in major/minor versions, not patch.               |
