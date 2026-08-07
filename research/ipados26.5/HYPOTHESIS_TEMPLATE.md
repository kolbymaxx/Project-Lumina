# Hypothesis template — A12X / iPadOS 26.5

Copy into a P00N card or standalone note.  
**Mandatory** before any Lab = Yes.

## Statement
One paragraph. Label Path A vs Path B. Do not call it a jailbreak.

## (1) Evidence
Must include **more than advisory text alone**. Prefer:
- Apple CVE + **binary/diff signal** (hunk summary, symbol, size-check site)
- and/or citable writeup with version bounds

Advisory-only → keep as **docs-only watch** (Lab = No).

## (2) Concrete test
On-device **or** offline. Name the artifact, command, or API **already cited** in evidence.
No invented selectors.

## (3) Fail-closed
If wrong, what observable ends the hypothesis? (e.g. no delta in kext; unreachable client; N trials no panic.)

## Success does **not** mean
- “We have a jailbreak”
- “PPL is done”
- Status line flip without matrix + FILTER update
