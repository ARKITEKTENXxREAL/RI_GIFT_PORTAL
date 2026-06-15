Purpose

Short guidance for Copilot CLI/agents working in this repository: where the site and authoritative docs live, how to build/verify, and important repo-specific conventions to avoid breaking integrity checks.

Build, test, and lint commands

- CI (deploys site): .github/workflows/jekyll-gh-pages.yml uses actions/jekyll-build-pages and actions/deploy-pages to build and publish the site on pushes to main.
- Local Jekyll build/preview (common):
  - bundle exec jekyll build           # builds site (requires Ruby + bundler + jekyll)
  - bundle exec jekyll serve --incremental --livereload  # preview at http://localhost:4000
  - Docker alternative: docker run --rm -v "$(pwd):/srv/jekyll" -p 4000:4000 jekyll/jekyll jekyll serve
- PLG integrity check (explicit): the repository uses a SHA256 file to lock PLG_SMART_CONTRACT.md.
  - Compute new hash and update .plg file:
    sha256sum PLG_SMART_CONTRACT.md | awk '{print $1}' > .plg/PLG_SMART_CONTRACT.sha256
  - Quick local verify (single command):
    H=$(sha256sum PLG_SMART_CONTRACT.md | awk '{print $1}'); E=$(cat .plg/PLG_SMART_CONTRACT.sha256 | tr -d '[:space:]'); test "$H" = "$E" && echo "OK" || (echo "HASH MISMATCH"; exit 1)
- Tests and linters: none are present in the repo by default (no test/CI scripts or lint config files detected). Add any test/lint tooling explicitly if you introduce language-specific code.

High-level architecture (big picture)

- Primary purpose: documentation and static site (Jekyll-compatible) rooted at repo root (index.html, many .md files). GitHub Actions builds and deploys the site to Pages.
- Authoritative contract: PLG_SMART_CONTRACT.md (root) is integrity-guarded by .plg/PLG_SMART_CONTRACT.sha256 — workflow plg-verify.yml enforces the checksum on PRs/pushes to main.
- Subprojects: RI_CHILD_TECH/ contains nested projects (e.g., LITTLE_LIGHTWORKER/) with their own README and content; treat these as independent doc/submodule areas.
- Dev environment: .devcontainer exists for consistent development environments when present.

Key conventions and patterns (repo-specific)

- PLG integrity lock: Any change to PLG_SMART_CONTRACT.md must be accompanied by updating .plg/PLG_SMART_CONTRACT.sha256; otherwise plg-verify workflow will fail the PR.
- Docs-first layout: Markdown files in root are the primary artifacts (not source code). Changes to docs are what trigger CI/docs builds.
- CI-driven site build: Do not rely on local Node tooling unless package.json is added; the repository uses the jekyll build action which installs dependencies for the build step.
- Signatures & licensing: MIT_LICENSE.md and SIGNATUR.md are authoritative license/signature files; preserve their headers when touching top-level docs.

Files and locations Copilot should prioritize

- PLG_SMART_CONTRACT.md (root) — authoritative contract text
- .plg/PLG_SMART_CONTRACT.sha256 — integrity lock
- README.md and index.html — entry points for site/docs
- .github/workflows/*.yml — CI behaviour (jekyll build & plg-verify)
- RI_CHILD_TECH/ — subproject content (scan their README before making repo-wide assumptions)

Notes for Copilot/agents

- Confirm checksum operations before proposing automated edits to PLG_SMART_CONTRACT.md; include an instruction to update .plg/.sha256 in the same PR.
- If adding code, include explicit test and lint configs (and document how to run them) so future Copilot sessions can run verification.
- Avoid editing .github/workflows unless the change is explicitly requested; these govern site deploys and integrity checks.

If you want, I can:
- Add a lightweight test/lint matrix (e.g., markdownlint) and CI jobs
  - Example local setup (Node required):
    - npm init -y && npm install --save-dev markdownlint-cli
    - Run a single file: npx markdownlint README.md
    - Run all markdown files: npx markdownlint "**/*.md"
  - I can add a GitHub Actions job to run markdownlint on push/PR.
- Create a dev README for the .devcontainer describing how to open the container and common commands (jekyll build/serve, checksum verify).

Additional per-subproject guidance

- RI_CHILD_TECH/LITTLE_LIGHTWORKER/: content-first subproject. Read its README before making changes. If executable code is added, include a manifest (package.json or pyproject.toml) and tests so CI can be extended.
- Any new code or language should introduce explicit test and lint configs (and update this file to document how to run them).

Example PR checklist (copy into PR template or use manually)

- [ ] Run local Jekyll build: bundle exec jekyll build
- [ ] If PLG_SMART_CONTRACT.md changed, update .plg/PLG_SMART_CONTRACT.sha256:
      sha256sum PLG_SMART_CONTRACT.md | awk '{print $1}' > .plg/PLG_SMART_CONTRACT.sha256
- [ ] Verify checksum locally:
      H=$(sha256sum PLG_SMART_CONTRACT.md | awk '{print $1}'); E=$(cat .plg/PLG_SMART_CONTRACT.sha256 | tr -d '[:space:]'); test "$H" = "$E" && echo "OK" || (echo "HASH MISMATCH"; exit 1)
- [ ] Run markdownlint (if added): npx markdownlint "**/*.md"
- [ ] Preserve headers in MIT_LICENSE.md and SIGNATUR.md
- [ ] Do not modify .github/workflows without explicit review from maintainers

If preferred, I can create a PR template and add the above checklist as .github/PULL_REQUEST_TEMPLATE.md.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
