#!/bin/sh
# Stands the marketing site up on the VPS, and is safe to run again.
#
# One script rather than a runbook's worth of commands because every run of it
# is an SSH session, and that box's fail2ban counts those — a session per
# command is how the owner gets locked out of their own server.
#
# Run it as root, from a checkout of this repository on the box, or straight
# off GitHub:
#
#   curl -fsSL https://raw.githubusercontent.com/NikolaiKushner/quiet-poker-site/main/infra/site-bootstrap.sh | sudo sh
#
# After this, nothing about the site needs a hand here again: the timer follows
# the repository's releases, and the deploy script follows `main`. The one
# thing this does not install is Caddy's configuration, which is shared with
# the API and lives in the application repository.
set -eu

REPO=https://github.com/NikolaiKushner/quiet-poker-site.git
CHECKOUT=/opt/quiet-poker-site
ROOT=/srv/quiet-poker-site
ACCOUNT=quiet-poker-site

[ "$(id -u)" = 0 ] || { echo "run this as root"; exit 1; }
command -v git >/dev/null || { echo "git is not installed"; exit 1; }

# A system account with no home, no shell and no password. It owns the checkout
# and the served tree and nothing else on this machine.
if ! id -u "$ACCOUNT" >/dev/null 2>&1; then
  useradd --system --no-create-home --home-dir /nonexistent \
          --shell /usr/sbin/nologin "$ACCOUNT"
  echo "created the $ACCOUNT account"
fi

if [ -d "$CHECKOUT/.git" ]; then
  git -C "$CHECKOUT" fetch --quiet origin main
  git -C "$CHECKOUT" reset --hard --quiet FETCH_HEAD
else
  git clone --quiet "$REPO" "$CHECKOUT"
fi
chown -R "$ACCOUNT:$ACCOUNT" "$CHECKOUT"

install -d -m 755 -o "$ACCOUNT" -g "$ACCOUNT" "$ROOT"
install -d -m 755 -o "$ACCOUNT" -g "$ACCOUNT" "$ROOT/releases"

# Copied into /etc rather than linked out of the checkout, and this is the one
# thing here that is deliberately not self-updating. The checkout is writable by
# an unprivileged account; a unit file read from it would let that account
# choose what systemd runs, and as whom. Changing the unit is therefore a
# deliberate act: push the change, then run this script again.
# Always out of the checkout, never out of the working directory: this script
# is meant to be runnable by piping it from GitHub, where there is no working
# directory to speak of.
install -m 644 "$CHECKOUT/infra/quiet-poker-site.service" /etc/systemd/system/quiet-poker-site.service
install -m 644 "$CHECKOUT/infra/quiet-poker-site.timer" /etc/systemd/system/quiet-poker-site.timer

systemctl daemon-reload
# Advisory, not a gate. It warns about directives a given systemd does not know,
# and under `set -e` that would abort the stand-up over a line that is merely
# ignored — leaving the timer uninstalled for a reason nobody reads.
systemd-analyze verify quiet-poker-site.service || echo "systemd-analyze had something to say about the unit; see above"
systemctl enable --now quiet-poker-site.timer >/dev/null

# Fetch whatever has already been published rather than waiting for a tick. It
# exits quietly when nothing has been published yet.
systemctl start quiet-poker-site.service || true

echo
echo "--- state ---"
echo "checkout: $(git -C "$CHECKOUT" rev-parse --short HEAD)"
echo "account:  $ACCOUNT"
echo "current:  $(readlink "$ROOT/current" 2>/dev/null || echo 'none')"
echo "recorded: $(cat /var/lib/quiet-poker-site/release 2>/dev/null || echo 'none')"
echo "releases: $(ls -1 "$ROOT/releases" 2>/dev/null | wc -l | tr -d ' ')"
echo "timer:    $(systemctl is-active quiet-poker-site.timer)"
echo
if [ -e "$ROOT/current" ]; then
  echo "Files are on disk. Caddy still has to be told about them, once, from the"
  echo "application repository — see its docs/runbooks/site-deploy.md."
else
  echo "Nothing published yet, so there is nothing on disk. Push to main."
fi
echo
echo "--- log ---"
journalctl -u quiet-poker-site --since -1h --no-pager 2>/dev/null | tail -20
