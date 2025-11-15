#!/usr/bin/env bash
set -euo pipefail

# show some logs
echo "Starting container at $(date)"
echo "RDP user: ${RDP_USER}"
# don't print password in logs in production
echo "Starting xfce + xrdp..."

# Ensure xrdp service files exist
# Start xrdp
service xrdp start || (cat /var/log/xrdp-sesman.log || true; exit 1)

# Start tailscaled in background. Use userspace networking so it works inside container.
echo "Starting tailscaled..."
tailscaled --state=/tmp/tailscaled.state --tun=userspace-networking &

# wait a bit for tailscaled to spin up
sleep 2

if [ -z "${TAILSCALE_AUTH_KEY:-}" ]; then
  echo "ERROR: TAILSCALE_AUTH_KEY is empty. Set it as a secret in Render dashboard."
  echo "Tailscale will NOT be brought up."
else
  echo "Bringing up tailscale with userspace networking..."
  # Use --accept-routes only if you want to accept advertised routes
  tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --hostname="render-$(hostname)" --accept-dns=false --tun=userspace-networking || {
    echo "tailscale up failed; logs:"
    tailscale status || true
  }
fi

# print Tailscale IP (wait for assignment)
for i in {1..12}; do
  TSIP=$(tailscale ip -4 2>/dev/null || true)
  if [ -n "$TSIP" ]; then
    echo "Tailscale IP: $TSIP"
    break
  fi
  sleep 2
done

# Keep container running and print heartbeat
while true; do
  echo "[$(date)] container running. Tailscale IP: $(tailscale ip -4 2>/dev/null || echo 'n/a')"
  sleep 300
done
