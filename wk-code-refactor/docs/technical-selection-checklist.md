# Technical Selection Checklist

Use this during planning before final plan confirmation.

## Layout

- [ ] Identify whether current code uses Masonry, SnapKit, native Auto Layout, frame layout, or a mix.
- [ ] State the allowed layout strategy for this refactor.
- [ ] Avoid mixing frame and constraints in the same lifecycle unless existing code requires it and the plan explains why.

## RTL

- [ ] Identify semantic direction handling.
- [ ] Distinguish physical edges from logical leading/trailing.
- [ ] Check mirrored assets and text alignment.
- [ ] Check rounded corners and side presentation behavior.
- [ ] Add or identify RTL tests where behavior can change.

## Internationalization

- [ ] Identify KString or the existing local i18n entry.
- [ ] List new or touched keys.
- [ ] Do not introduce a parallel i18n wrapper.
- [ ] Verify fallback and missing-key behavior if relevant.

## Resources

- [ ] Identify bundle lookup and asset paths.
- [ ] Confirm resource_bundles/resources behavior in podspec when relevant.
- [ ] Decide whether missing local test resources are environmental noise or a hard failure.
- [ ] Avoid hardcoded remote production image URLs as fallbacks.

## Routing And API

- [ ] Prefer typed APIs and existing bridges.
- [ ] Avoid runtime selector dispatch, `NSClassFromString`, and `NSSelectorFromString` unless explicitly approved.
- [ ] Confirm public API compatibility.

## Build And Verification

- [ ] Determine whether `pod install` is needed.
- [ ] Pick workspace, scheme, and destination.
- [ ] Use unique `-derivedDataPath` for flaky or parallel builds.
- [ ] Define targeted tests and full test/build requirements.
