---
name: release-pickr
description: "Release Pickr to GitHub. Use when the user asks to cut, publish, or ship a Pickr release: inspect changes since the previous GitHub release tag, choose a semantic version, update the manifest and changelog, review the README, commit, tag, push, and create a comparison-link-only GitHub release."
---

# Release Pickr

Carry out the complete release workflow when explicitly invoked to release.
Creating or editing this skill is not a request to execute it. If the user asks
only for a preview or version recommendation, stop before changing files or
publishing. Otherwise, invocation authorizes the release commit, tag, push, and
GitHub release; do not add a routine approval step. Ask only when a concrete
ambiguity or blocker prevents choosing the correct release scope or baseline.

Use `gh` for GitHub operations, Git for repository operations, and dedicated
file tools for edits. Prefer Lua if helper code is needed. Follow `AGENTS.md`.
Track progress, report the selected baseline and version rationale before
editing, and continue through publication and verification.

## 1. Establish the release baseline and scope

1. Inspect `git status --short`, `git diff`, `git diff --cached`,
   `git log --oneline -10`, `git remote -v`, and branch/upstream tracking.
   Resolve the GitHub owner/repository and default branch with `gh repo view`.
   Pickr normally uses `javoscript/herdr-pickr`; derive URLs from the verified
   remote rather than assuming a fork is the upstream repository.
2. Fetch the release remote and tags without force. Check the intended release
   branch against its remote. Normally release from the default branch; honor
   an explicitly requested release branch. Do not silently switch branches,
   merge, rebase, discard work, or publish another branch's work.
3. Inspect GitHub releases using `gh api --paginate
   'repos/OWNER/REPO/releases?per_page=100'`, and inspect remote tags using
   `git ls-remote --tags REMOTE`. Select the most recent published, non-draft,
   non-prerelease SemVer release on the intended release lineage. Check tag
   ancestry with `git merge-base --is-ancestor PREVIOUS_TAG HEAD` and resolve
   its commit with `git rev-parse PREVIOUS_TAG^{commit}`. Reconcile publication
   dates, version ordering, and ancestry rather than blindly trusting the
   first API result, a local nearest tag, or GitHub's manually assigned Latest
   label. Explain and ask if parallel release lines make the baseline ambiguous.
4. If no GitHub release exists, use the newest applicable remote SemVer tag
   on the release lineage and state this fallback. If no remote release tag
   exists at all, stop to establish the initial baseline with the user. Offer
   to tag a verified historical release commit (for example, the actual
   `0.1.0` baseline), then compare against it. Do not invent an old tag, tag
   today's HEAD as historical code, or emit a nonexistent comparison URL.
   Creating a historical baseline tag requires explicit agreement on its commit.
5. Read the manifest at the previous tag and at HEAD. Review the entire range:
   `git log --reverse PREVIOUS_TAG..HEAD`,
   `git diff --stat PREVIOUS_TAG..HEAD`, and
   `git diff PREVIOUS_TAG..HEAD`. Include local committed work that will be
   pushed, not only commits already visible on GitHub. Read implementation,
   tests, documentation, and relevant OpenSpec artifacts to understand behavior.
   Conventional Commit subjects are evidence, not a substitute for the diff.
6. Release completed implementation, not pending proposals. Open OpenSpec
   changes do not automatically belong to the release or require archiving.
   If in-scope behavior is unfinished or its required verification is pending,
   resolve that blocker before publishing; do not implement unrelated features
   or mark tasks complete merely to cut a release.
7. Existing uncommitted/staged work must be understood before proceeding. Do not
   sweep it into a release commit or stash/discard it. If it is intended release
   content, ask for scope clarification unless already explicit, commit it
   separately with an appropriate Conventional Commit, then recompute the range.
   Unrelated work must not enter the release or invalidate release verification.

If there are no unreleased changes and no interrupted publication to finish,
report that there is nothing to release; do not create an empty release.

## 2. Choose the semantic version

Use the previous released version as the baseline. Determine the highest-impact
change across the complete release, treating public action/entrypoint IDs,
configuration keys and validation, dependencies, default shortcuts, and
documented behavior as part of Pickr's public contract.

| Change | While major is `0` | Once major is `1` or higher |
| --- | --- | --- |
| Compatible bug fixes, documentation, internal maintenance | Patch | Patch |
| New user-facing functionality | Minor, reset patch to zero | Minor, reset patch to zero |
| Incompatible public contract or migration requirement | Minor, reset patch to zero | Major, reset minor and patch to zero |

This is Pickr's explicit pre-1.0 policy; SemVer itself does not promise stability
for `0.y.z`. Do not choose `1.0.0` just because a pre-1.0 change breaks
compatibility: that milestone needs an explicit decision to promise stability.
One release containing several changes gets one bump, not one bump per proposal.
For example, pane picking plus unified picker types/scopes and configuration
migration would warrant `0.1.0` -> `0.2.0` if actually included in the diff.
Never hardcode that example as the next version.

If the working manifest was already bumped, reconcile it with the baseline and
the selected version instead of bumping twice. Explain conflicting versions or
user-requested overrides. Check both remote/local tags and GitHub releases for
collisions before editing; distinguish an interrupted release from an already
published version. Never reuse a published version for different code.

`min_herdr_version` is independent of Pickr's version. Keep it unless shipped
APIs/manifest fields require a newer Herdr; verify that requirement against
Herdr documentation/source before changing it. Herdr's plugin `version` is
metadata, not an upgrade resolver. Unpinned installation fetches default-branch
HEAD; `--ref vX.Y.Z` selects a tag, and reinstalling preserves user config/state.

## 3. Prepare release files and notes

- Update only the top-level plugin `version` in `herdr-plugin.toml` to `X.Y.Z`
  (no `v` prefix).
- Review `README.md` against shipped features, launch commands, settings,
  defaults, dependency minimums, supported platforms, and installation/update
  instructions. Update it where behavior changed. Document migration steps for
  renamed actions/settings and changed shortcuts. Show pinned installation
  with `herdr plugin install OWNER/REPO --ref vX.Y.Z` when useful. Do not claim
  compatibility or interactive checks that were not performed.
- Create or maintain root `CHANGELOG.md` in the workmux style: newest release
  first, a persistent `## Unreleased` section, dated version headings, and
  concise user-facing bullet points. Use the actual release date. Preserve
  historical entries and move only shipped Unreleased bullets into the new
  release, reconciling them with the diff and removing duplicates. Retain
  genuinely future items under Unreleased. Do not invent historical entries.
- Describe outcomes rather than dumping commit subjects. Include features,
  fixes, meaningful dependency changes, and explicit **Breaking:** bullets with
  migration guidance. Link real issues/PRs when known; never fabricate links.
  No need to copy workmux's website frontmatter or skipped-version comments.

Example changelog shape:

```markdown
# Changelog

## Unreleased

## vX.Y.Z (YYYY-MM-DD)

- Add ...
- Fix ... ([#123](https://github.com/OWNER/REPO/pull/123))
- **Breaking:** Rename ... Update ...

## vPREVIOUS (YYYY-MM-DD)

- Existing historical notes remain here.
```

The GitHub release title is `vX.Y.Z`. Its body is **exactly one line**:

```text
**Full Changelog**: https://github.com/OWNER/REPO/compare/PREVIOUS_TAG...vX.Y.Z
```

Detailed release notes live in `CHANGELOG.md`, not in the GitHub release body.
Use the actual previous tag spelling. Do not use `--generate-notes`, append
installation instructions, attach build artifacts, or copy changelog bullets
into the release body. References: https://github.com/raine/workmux/releases
and https://github.com/raine/workmux/blob/main/CHANGELOG.md.

## 4. Verify and commit

1. Run the current repository's release checks. At skill creation, the aggregate
   regression entrypoint is `lua tests/test.lua`, including real-fzf checks.
   Inspect the current runner/docs for additional required checks and runtime
   dependencies. Complete required interactive acceptance for included changes,
   or ask for the missing verification when it cannot be performed. Do not
   publish after failed or unavailable required checks.
2. Run `git diff --check`. Review the exact release diff and ensure manifest
   version, changelog heading/date, migration docs, proposed tag, and notes URL
   agree. Ensure no secrets or unrelated files are staged. Review `git status`,
   `git diff`, and `git log --oneline -10` before committing.
3. Stage only intended release files by explicit path, normally
   `herdr-plugin.toml`, `CHANGELOG.md`, and `README.md` if edited.
   Inspect `git diff --cached`, then commit as `chore(release): vX.Y.Z`.
   Honor hooks; do not bypass hooks or amend commits. Resolve failed hooks and
   retry with a new commit as appropriate.
4. Record the release commit SHA. Verify its committed manifest and changelog,
   and confirm it contains every reviewed release commit and the previous tag.

## 5. Tag, push, and publish

Replace placeholders below with the verified values. Use an annotated tag on
the exact release commit and push only the intended branch and release tag:

```sh
git tag -a "$NEW_TAG" "$RELEASE_COMMIT" -m "$NEW_TAG"
git push --atomic "$REMOTE" "HEAD:refs/heads/$RELEASE_BRANCH" "refs/tags/$NEW_TAG:refs/tags/$NEW_TAG"
gh release create "$NEW_TAG" --repo "$REPO" --verify-tag --title "$NEW_TAG" --notes "**Full Changelog**: https://github.com/$REPO/compare/$PREVIOUS_TAG...$NEW_TAG"
```

Do not force-push, push all tags, overwrite an existing tag, or use an empty
commit. A non-fast-forward rejection requires inspecting new remote changes
and reassessing the release, not forcing through them. If atomic push is
unsupported, push the explicit branch then explicit tag and verify both before
creating the release. Never allow `gh release create` to auto-create the tag.

Verify remote branch and peeled tag commit with `git ls-remote`; both must
match the intended release commit at publication. Use `gh release view` to
verify tag, title, body, URL, and non-draft/non-prerelease status. Check the
GitHub compare endpoint resolves the two tags and intended commit range.
Inspect any configured release CI and report its actual status, waiting for
required publication checks where applicable.

### Resume interrupted publication

Before repeating a failed step, inspect local/remote tags, release commit,
manifest/changelog, and GitHub release state. Reuse the prepared version and
commit only when they match the intended release. If the push succeeded but
release creation failed, create the missing release with the same tag; do not
bump again. If the release already exists and matches, verify and report it.
If anything conflicts, explain the exact mismatch rather than deleting or
rewriting published history. Never report publication success until verified.

## Final report

Return the released version and brief bump rationale, previous tag and compare
URL, release commit SHA, checks performed, updated files, push outcome, and
GitHub release URL. If blocked or partially published, state precisely what
completed and the next action needed to finish.
