#!/bin/sh
# Brings the marketing site on this box to whatever this repository's latest
# release holds — and brings itself to whatever `main` holds.
#
# Nothing here is shared with the application. Its own repository, its own
# checkout, its own timer, its own state directory and its own unprivileged
# user. Publishing a page must not wait for an API release, and must not be
# able to cause one. The two pipelines meet at exactly one file, Caddy's
# configuration, which routes /v1 to the API and everything else to the
# directory this script fills.
#
# It pulls. Nothing in GitHub holds a credential for this machine, which also
# runs Postgres and the API — see the application repository's
# docs/runbooks/vps-architecture.md for why that direction is not negotiable.
set -eu

REPO=https://github.com/NikolaiKushner/quiet-poker-site
CHECKOUT=${QP_SITE_CHECKOUT:-/opt/quiet-poker-site}
ROOT=${QP_SITE_ROOT:-/srv/quiet-poker-site}
RELEASES=$ROOT/releases
CURRENT=$ROOT/current
STATE=${STATE_DIRECTORY:-/var/lib/quiet-poker-site}/release
KEEP=5

log() { echo "$*"; }

# --- bring the script up to date before it does anything ------------------
#
# A change to this file has to reach the box the same way a change to a page
# does: by being pushed. Otherwise the deploy machinery is the one thing on the
# site's side that still needs a hand on the server.
#
# ls-remote rather than fetch, because it answers "is there anything new" and
# "can GitHub be reached at all" in one call, and costs nothing on the ticks
# where the answer is no. The unit file is deliberately not updated here — see
# site-bootstrap.sh.
if [ -z "${QP_SITE_REEXEC:-}" ] && [ -d "$CHECKOUT/.git" ]; then
  head_remote=$(git -C "$CHECKOUT" ls-remote origin refs/heads/main 2>/dev/null | cut -f1) || head_remote=
  head_local=$(git -C "$CHECKOUT" rev-parse HEAD 2>/dev/null) || head_local=
  if [ -n "$head_remote" ] && [ "$head_remote" != "$head_local" ]; then
    log "checkout is behind; moving it to $head_remote"
    git -C "$CHECKOUT" fetch --quiet origin main
    git -C "$CHECKOUT" reset --hard --quiet FETCH_HEAD
    # exec, so the rest of this run is the code that was just fetched rather
    # than the code that fetched it. The guard stops it looping if the reset
    # somehow does not take.
    QP_SITE_REEXEC=1 exec sh "$CHECKOUT/infra/site-deploy.sh"
  fi
fi

# --- then publish whatever has been released ------------------------------
#
# Follows the /releases/latest redirect instead of asking api.github.com. The
# API would answer this in one call, but unauthenticated it allows 60 requests
# an hour from this address for everything together, and a timer should not be
# living inside that. The redirect is a plain web request with no such budget
# and needs no token, which is the point of the repository being public.
location=$(curl -fsSI -o /dev/null -w '%{redirect_url}' "$REPO/releases/latest" 2>/dev/null) \
  || { log "cannot reach GitHub"; exit 1; }

# No releases yet answers with the releases page rather than a tag. Not an
# error — the site simply has not been published yet.
case "$location" in
  */releases/tag/*) ;;
  *) exit 0 ;;
esac

TAG=${location##*/releases/tag/}
[ -n "$TAG" ] || { log "could not read a tag out of $location"; exit 1; }

if [ -f "$STATE" ] && [ "$(cat "$STATE")" = "$TAG" ] && [ -d "$RELEASES/$TAG" ]; then
  exit 0
fi

log "site release $TAG is newer than what is on disk; fetching"

WORK=$(mktemp -d "$ROOT/.incoming.XXXXXX")
# Whatever happens next, a half-downloaded release does not survive to be
# unpacked on the following tick.
trap 'rm -rf "$WORK"' EXIT INT TERM

base="$REPO/releases/download/$TAG"

# A release can exist for a few seconds before its assets finish uploading.
# That is the normal middle of a publish, not a fault, so say nothing and let
# the next tick find it complete.
curl -fsSL -o "$WORK/site.tar.gz" "$base/site.tar.gz" 2>/dev/null || exit 0
curl -fsSL -o "$WORK/site.tar.gz.sha256" "$base/site.tar.gz.sha256" 2>/dev/null || exit 0

# Proves the transfer, not the source — both come from the same place. What it
# catches is a truncated download being unpacked over a working site.
expected=$(cat "$WORK/site.tar.gz.sha256")
actual=$(sha256sum "$WORK/site.tar.gz" | cut -d' ' -f1)
[ "$expected" = "$actual" ] || {
  log "digest mismatch for $TAG: expected $expected, got $actual"
  exit 1
}

mkdir "$WORK/tree"
tar -xzf "$WORK/site.tar.gz" -C "$WORK/tree"
[ -f "$WORK/tree/index.html" ] || {
  log "$TAG unpacked without an index.html; not publishing it"
  exit 1
}
# The URL is compiled into shipped app binaries and is what App Store Connect
# has under App Information. A build that lost it is a build that must not go
# live, whatever else is in it.
[ -f "$WORK/tree/privacy.html" ] || {
  log "$TAG unpacked without a privacy.html; not publishing it"
  exit 1
}

mkdir -p "$RELEASES"
rm -rf "$RELEASES/$TAG"
mv "$WORK/tree" "$RELEASES/$TAG"

# ln -sfn writes a new symlink beside the old one and renames it over the top,
# which is atomic. Removing and recreating would leave a window in which the
# path does not exist, and Caddy would answer 404 to whoever asked during it.
ln -sfn "$RELEASES/$TAG" "$CURRENT.new"
mv -T "$CURRENT.new" "$CURRENT"

mkdir -p "$(dirname "$STATE")"
printf '%s\n' "$TAG" > "$STATE"

# Keep a handful to roll back into. Rolling back is moving the symlink; there
# is nothing to rebuild and nothing to restart.
ls -1dt "$RELEASES"/* 2>/dev/null | tail -n +$((KEEP + 1)) | while read -r old; do
  case "$old" in
    "$RELEASES"/*) rm -rf "$old" ;;
  esac
done

log "site is now $TAG"
