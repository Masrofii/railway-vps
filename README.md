# COMMANDOR HOSTING SERVER

Ubuntu 24.04 SSH container for Railway. Root login, Node 22, PM2, live banner.

## Variables (Railway -> Variables)

| Name | Required | Description |
|---|---|---|
| `ROOT_PASSWORD` | **yes** | Root password. Container exits without it |
| `HOSTNAME` | no | Custom hostname |
| `SSH_USERNAME` + `SSH_PASSWORD` | no | Extra sudo user |
| `AUTHORIZED_KEYS` | no | Public key(s) for root |

## Deploy

1. Push to GitHub, deploy on Railway
2. Set `ROOT_PASSWORD`
3. Settings -> Networking -> **TCP Proxy** -> port `22`
4. `ssh root@<proxy-host> -p <proxy-port>`

Connection string: `host:port:root:<ROOT_PASSWORD>`

Containers are ephemeral — attach a Volume for persistent data.
