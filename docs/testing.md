# Testing

`./tests/run.sh` covers profile expansion, stable dependency ordering, network selection, dry-run side effects, xdotter checksum, conflict refusal, and forbidden unsafe patterns.

Real installation is allowed only inside `glcr.rd.ubtrobot.com/rosa/images/rust:ubuntu24.04` with a temporary HOME and XDG directories. Run `./scripts/docker-build-test.sh`; it prints the follow-up verification command. Measure shell cold and warm startup separately and reject any startup network access.
