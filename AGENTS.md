# Quiet Poker website — agent instructions

This repository is the public marketing site for Quiet Poker: the landing page,
the privacy policy, the terms, and the support page. Static files, built by
Astro, served from a directory on the same VPS that runs the app's API — beside
the backend and the database, never through them.

The application itself lives in a separate, private repository. Nothing from it
belongs here except the brand files and the screenshots, which are copies.

## No tests

Do not add tests, test runners, or a CI job that runs them. A static page has
nothing a test would assert that opening the page would not show. `astro build`
passing is the check.

## Never promise what has not shipped

Every feature named on this site must be in the App Store build people can
download today. Not in the plan queue, not on a branch, not behind a flag, not
"landing next week". Check before writing the sentence.

This is the rule most easily broken by accident, because the copy is written
while the feature is being built.

## Never print a price

Prices are set per region in App Store Connect and change without this
repository hearing about it. Name the tiers and what they include, and send the
reader to the Shop tab in the app for the price in their currency. The same
goes for chip pack amounts if they ever appear here.

## Required copy

These lines must stay on the site and must not be softened:

- This game is intended for an adult audience.
- This game does not offer real-money gambling or an opportunity to win real
  money or prizes.
- Practice or success in this game does not imply future success at real-money
  gambling.

Nothing here may suggest using the app to prepare for playing in a casino.

## Brand

Monochrome studio poker. The colours are in `src/styles/tokens.css`, generated
from the app's brand tokens. No teal. No spade-as-logo. The chip mark stays
black and white; suit red appears only on playing cards.

## Plain CSS, no framework

The brand is seven colours and one typeface. A CSS framework would be larger
than the site. Astro components share the markup; custom properties share the
colour.

Keep client-side JavaScript out unless a page genuinely cannot work without it.
Today no page needs any.

## English only

Everything committed here is in English — copy, comments, identifiers, commit
messages. Before finishing a change:

```sh
rg --pcre2 -n --hidden --glob '!.git/**' --glob '!node_modules/**' '\p{Cyrillic}' .
```

## Never push without being told to

Commit as often as the work needs. Do not run `git push` unless the user asks
for it in that message. A push here is visible to anyone: the repository is
public and the site is what the App Store points at.

## How a change reaches the server

Publishing a GitHub Release builds the site and attaches `site.tar.gz`. A timer
on the VPS notices the new release, checks the digest, unpacks it and moves a
symlink. Pushing to `main` deploys nothing.

The server pulls; nothing here holds a key to that machine. Do not add one, and
do not add a workflow that connects to it.
