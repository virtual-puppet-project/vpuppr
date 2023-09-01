# Contributing

This document is based off of the [Godot Engine contribution document](https://github.com/godotengine/godot/blob/master/CONTRIBUTING.md).

## Table of Contents

- [Bugs or Issues](#bugs-or-issues)
- [Features or Improvements](#features-or-improvments)
- [Pull Requests (PR)](#pull-requests-pr)
- [Communicating with Developers](#communicating-with-developers)

## Bugs or Issues

Please report bugs or issues using [GitHub issues for vpuppr](https://github.com/virtual-puppet-project/vpuppr/issues).
Use the search bar to check if the issue already exists to avoid duplication.

This makes it easier to track problems and make sure problems are not forgotten about.

## Features or Improvments

Please create a [GitHub issue for vpuppr](https://github.com/virtual-puppet-project/vpuppr/issues) so that
feature or improvment requests can be tracked. Use the search bar to check if the request already exists to avoid
duplication.

Additionally, vpuppr is developed as free and open source software (FOSS), so features are worked on when
maintainers have time or PRs are raised by contributors.

## Pull Requests (PR)

When opening a PR, make sure the following items are present/followed:

- [ ] A commit message that explains what changes are being made. PRs that fall under `BAD` and `TERRIBLE` will be rejected
    - `GREAT`:
    ```
    Add mediapipe tracking.

    Adds mediapipe tracker and associated tracking logic for 3d models. Tests have been added to cover all cases.

    Resolves issue #123.
    ```
    - `GOOD`: "Add mediapipe tracker, add tracking logic for 3d models"
    - `BAD`: "mediapipe"
    - `TERRIBLE`: "some changes"
- [ ] [Squash commits](https://git-scm.com/docs/git-rebase#_interactive_mode)
    - Example for squashing the last 5 commits: `git rebase -i HEAD~5`
- [ ] The PR only implements 1 feature
    - If multiple features are being worked on, please submit multiple PRs so that PRs can be tracked
- [ ] Test your changes
    - This item is here because untested PRs have been submitted before :)
- [ ] Make sure the PR touches as few files as possible

## Communicating with Developers

DO:

- Be polite
- Make requests and bug reports
- Understand that the vpuppr developers have their own lives

DON'T:

- Use insults
- Pester the vpuppr developers about requests/bugs
    - If you feel strongly about a feature request or bug, please refer to the [Pull Requests](#pull-requests-pr) section
- Act like the vpuppr developers owe you anything

---

youwin is reachable on the following channels:

- [Discord server](https://discord.com/invite/6mcdWWBkrr) (DMs are _not_ open)
- [Mastodon](https://mastodon.gamedev.place/@youwin)
- [Bluesky](https://bsky.app/profile/youwin.bsky.social)
