---
name: anti-bot-fallback-workflow
description: Use when a third-party website is readable in a browser but server-side fetch/curl is blocked by anti-bot protections such as Vercel Security Checkpoint, Cloudflare challenges, or similar mitigations. Guides a workflow that first verifies raw HTTP behavior, then verifies browser-readable DOM state, and only then decides whether to add a browser fallback, switch to a stable API, or keep the current fetch path.
---

# Anti-Bot Fallback Workflow

Use this skill when a site integration fails in server-side code but appears to work in a real browser.

## Inputs

- Target URL or URL pattern
- Current fetch/parser code location
- Current failure symptom
- Data that must be extracted
- Existing tests and validation commands
- Deployment/runtime constraints for headless browsers

## Workflow

1. Define success first.
   State exactly what must be extracted, what response shape is required, and what failure mode is acceptable.

2. Reproduce with raw HTTP.
   Use `curl` or the existing server-side `fetch` path.
   Capture:
   - status code
   - response headers
   - body markers such as `403`, `429`, `Security Checkpoint`, `captcha`, `challenge`, `x-vercel-mitigated`

3. Classify the failure.
   Decide whether the issue is:
   - parser drift
   - upstream content change
   - anti-bot or challenge page
   - network, DNS, or timeout

4. Verify with browser automation.
   Use Chrome MCP or Playwright to open the same URL.
   Wait for rendered state, then confirm whether the required data is present in the DOM.

5. Compare HTTP vs browser behavior.
   If browser can read the data and raw HTTP cannot, treat the problem as anti-bot or challenge behavior.

6. Choose the cheapest stable source.
   Prefer, in order:
   - stable public API or JSON payload
   - stable metadata embedded in HTML
   - browser fallback
   Do not introduce a browser fallback if a reliable cheaper source exists.

7. Implement a guarded fallback.
   Keep the existing fast path.
   Only trigger browser fallback on explicit blocked signals such as:
   - `403`
   - `429`
   - mitigation headers
   - known checkpoint HTML markers

8. Reuse existing parsers when possible.
   The browser fallback should return the same kind of artifact the parser already understands, usually HTML.

9. Add regression coverage.
   Include:
   - unit tests for blocked-signal detection
   - tests that confirm fast path remains unchanged
   - tests for fallback success and fallback failure
   - end-to-end verification when the user-facing flow depends on it

10. Validate operational impact.
    If the fix adds a runtime dependency such as Playwright or Chromium, verify build, startup, and deployment compatibility.

## Acceptance Criteria

- The previously failing URL class now works or fails in the intended way
- Existing working URL classes still work
- Browser fallback is conditional, not unconditional
- Tests cover both fast path and fallback path
- Build and runtime validation pass
- Deployment implications are explicitly documented if runtime dependencies changed

## Common Failure Modes

- Tweaking request headers repeatedly without first proving the browser can read the target data
- Replacing the entire fetch path with browser automation instead of adding a guarded fallback
- Failing to wait for the DOM element that actually contains the required data
- Adding browser fallback without checking deployment support
- Testing only mocked success HTML and never testing real blocked responses
- Running validation steps in parallel when they mutate shared output directories

## Output Expectations

The final deliverable should usually include:

- root cause summary
- chosen extraction strategy
- code changes
- regression tests
- live verification notes
- deployment/runtime caveats if applicable

## Example Prompts

- Use `anti-bot-fallback-workflow` to fix a third-party skill page URL that fails with server-side fetch but works manually in a browser.
- Apply `anti-bot-fallback-workflow` and decide whether this site needs an API-based solution or a Playwright fallback.
- Use `anti-bot-fallback-workflow` to reproduce a `403` challenge page, confirm browser-readable DOM state, and implement the narrowest safe fallback.
