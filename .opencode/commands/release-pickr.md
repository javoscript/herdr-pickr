---
description: "Release Pickr: choose a version, update changelog, tag, push, and publish to GitHub"
agent: build
---

Load the `release-pickr` skill and follow its complete workflow. If the skill is
not available through the skill tool, read `.agents/skills/release-pickr/SKILL.md`
and follow those instructions directly.

With no arguments, publish the next Pickr release, including the release commit,
tag, push, and GitHub release. Choose the semantic version using the skill's
policy and the changes since the previous release.

Treat the following arguments as additional release instructions. If they request
a preview or version recommendation only, perform read-only analysis without
editing files, committing, tagging, pushing, or creating a GitHub release.

**Provided arguments:** $ARGUMENTS
