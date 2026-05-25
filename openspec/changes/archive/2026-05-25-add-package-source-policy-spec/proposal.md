## Why

lolterm needs a formal package source policy so future installer and helper-script changes preserve its Fedora-first, reviewable, risk-aware installation model. Existing guidance lives in README, SECURITY, and AGENTS text, but package-source decisions should be captured as OpenSpec requirements.

## What Changes

- Add a `package-source-policy` capability spec.
- Define Fedora official DNF packages as the preferred trusted source.
- Require documented records for non-default sources, COPRs, external repos, and Fedora package exceptions.
- Ban lolterm from consuming third-party remote installer scripts as install paths.
- Require checksum verification for executable/installable release artifacts.
- Define rules for language package managers, optional modules, experimental/high-risk modules, and update convenience behavior.
- Establish `PACKAGES.md` and `EXPERIMENTAL_PACKAGES.md` as intended package/source documentation locations.

## Impact

- Adds OpenSpec requirements only.
- No installer code changes are included in this change.
- Future package/source changes should conform to this policy.
