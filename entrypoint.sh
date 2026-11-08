#!/usr/bin/env bash
# COMMANDOR HOSTING SERVER — SSH entrypoint (root login, Railway)
set -Eeuo pipefail

# ---------- ROOT PASSWORD (REQUIRED) ----------
if [[ -z "${ROOT_PASSWORD:-}" ]]; then
  {
    echo "=========================================="
    echo "Error: ROOT_PASSWORD is required!"
    echo "Railway -> Variables -> + New Variable"
    echo "Name : ROOT_PASSWORD"
    echo "Value: your-strong-password"
    echo "Then redeploy."
    echo "=========================================="
  } >&2
  exit 1
fi
printf 'root:%s\n' "$ROOT_PASSWORD" | chpasswd
echo "[COMMANDOR] root password set"

# ---------- HOSTNAME (OPTIONAL) ----------
if [[ -n "${HOSTNAME:-}" ]]; then
  echo "$HOSTNAME" > /etc/hostname 2>/dev/null || true
  hostname "$HOSTNAME" 2>/dev/null || true
  echo "[COMMANDOR] hostname set to $HOSTNAME"
fi

# ---------- SECONDARY SUDO USER (OPTIONAL) ----------
if [[ -n "${SSH_USERNAME:-}" && -n "${SSH_PASSWORD:-}" ]]; then
  if [[ ! "$SSH_USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    echo "Invalid SSH_USERNAME." >&2; exit 1
  fi
  if ! id "$SSH_USERNAME" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$SSH_USERNAME"
    usermod -aG sudo "$SSH_USERNAME" 2>/dev/null || true
    echo "$SSH_USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$SSH_USERNAME"
    chmod 440 "/etc/sudoers.d/$SSH_USERNAME"
    echo "[COMMANDOR] user $SSH_USERNAME created with sudo"
  fi
  printf '%s:%s\n' "$SSH_USERNAME" "$SSH_PASSWORD" | chpasswd
fi

# ---------- AUTHORIZED KEYS (OPTIONAL, root) ----------
if [[ -n "${AUTHORIZED_KEYS:-}" ]]; then
  install -d -m 700 /root/.ssh
  printf '%s\n' "$AUTHORIZED_KEYS" > /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  echo "[COMMANDOR] authorized_keys installed for root"
fi

# ---------- EXPORT RAILWAY VARS FOR THE LOGIN BANNER ----------
{
  env | grep -E '^RAILWAY_(SERVICE_NAME|ENVIRONMENT_NAME|PROJECT_NAME|PRIVATE_DOMAIN|TCP_PROXY_DOMAIN|TCP_PROXY_PORT|PUBLIC_DOMAIN)=' \
    | sed -E "s/^([A-Z_]+)=(.*)$/export \1='\2'/"
} > /etc/commandor-env.sh 2>/dev/null || true

# ---------- SSHD ----------
mkdir -p /run/sshd
ssh-keygen -A
cat > /etc/ssh/sshd_config <<'SSHD'
Port 22
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding no
AllowTcpForwarding yes
AllowAgentForwarding yes
PrintMotd no
ClientAliveInterval 30
ClientAliveCountMax 4
Subsystem sftp /usr/lib/openssh/sftp-server
SSHD

echo "[COMMANDOR] starting SSH server on port 22..."
exec /usr/sbin/sshd -D -e
