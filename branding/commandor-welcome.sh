#!/usr/bin/env bash
# COMMANDOR banner — shown once per interactive shell
[[ $- == *i* ]] || return 0
[[ -n "${COMMANDOR_BANNER_SHOWN:-}" ]] && return 0
export COMMANDOR_BANNER_SHOWN=1
[ -f /etc/commandor-env.sh ] && . /etc/commandor-env.sh

C='\033[1;36m'; W='\033[1;37m'; G='\033[1;32m'; Y='\033[1;33m'; D='\033[0;90m'; R='\033[0m'
LINE="${D}────────────────────────────────────────────────────────${R}"
row() { printf "  ${D}%-10s${R} ${W}%s${R}\n" "$1" "$2"; }

clear
echo -e "${C}"
figlet -f slant COMMANDOR 2>/dev/null || echo "COMMANDOR"
echo -e "${R}${W}           HOSTING SERVER${R}  ${G}@xpT_T${R}\n"

echo -e "$LINE\n ${C}SYSTEM${R}"
row Hostname "$(hostname)"
row OS "$(. /etc/os-release && echo "$PRETTY_NAME")"
row Kernel "$(uname -r)"
row Uptime "$(uptime -p 2>/dev/null | sed 's/^up //')"
[[ -n "${RAILWAY_SERVICE_NAME:-}" ]] && row Service "$RAILWAY_SERVICE_NAME (${RAILWAY_ENVIRONMENT_NAME:-?})"

echo -e "\n ${C}RESOURCES${R}"
# container limits (cgroup v2 / v1), fallback to host values
cpu_idle=$(top -bn1 2>/dev/null | awk -F'[, ]+' '/Cpu\(s\)/{for(i=1;i<=NF;i++) if($i=="id") print $(i-1)}')
row CPU "$(nproc) vCPU · ${cpu_idle:+$(awk "BEGIN{printf \"%.0f\", 100-$cpu_idle}")% used}"
if [[ -r /sys/fs/cgroup/memory.max ]]; then
  lim=$(cat /sys/fs/cgroup/memory.max); use=$(cat /sys/fs/cgroup/memory.current)
  [[ "$lim" == "max" ]] && lim=$(awk '/MemTotal/{print $2*1024}' /proc/meminfo)
  row Memory "$(awk "BEGIN{printf \"%.0fMB / %.0fMB (%.0f%%)\", $use/1048576, $lim/1048576, $use*100/$lim}")"
else
  row Memory "$(free -m | awk 'NR==2{printf "%dMB / %dMB (%.0f%%)", $3,$2,$3*100/$2}')"
fi
row Disk "$(df -h / | awk 'NR==2{printf "%s / %s (%s)", $3,$2,$5}')"

echo -e "\n ${C}TOOLS${R}"
command -v node    >/dev/null && row Node.js "$(node -v)"
command -v npm     >/dev/null && row npm "v$(npm -v)"
command -v python3 >/dev/null && row Python "$(python3 -V | awk '{print $2}')"
command -v pm2     >/dev/null && row PM2 "v$(pm2 -v 2>/dev/null | tail -1)"

echo -e "\n ${C}LISTENING PORTS${R}"
ports=$(ss -tlnH 2>/dev/null | awk '{n=split($4,a,":"); print a[n]}' | sort -un | tr '\n' ' ')
row Ports "${ports:-none}"

if command -v pm2 >/dev/null 2>&1; then
  echo -e "\n ${C}PM2${R}"
  pm2 jlist 2>/dev/null | python3 -c '
import sys, json
try:
    procs = json.loads(sys.stdin.read() or "[]")
except Exception:
    procs = []
if not procs:
    print("  \033[0;90mno processes — pm2 start app.js --name app\033[0m")
else:
    print("  \033[0;90m%-16s %-9s %-6s %-8s %s\033[0m" % ("NAME","STATUS","CPU","MEM","PID"))
    for p in procs:
        st = p.get("pm2_env", {}).get("status", "?")
        col = "\033[1;32m" if st == "online" else "\033[1;31m"
        m = p.get("monit", {})
        print("  %-16s %s%-9s\033[0m %-6s %-8s %s" % (
            p.get("name","?")[:16], col, st, str(m.get("cpu",0))+"%",
            "%dMB" % (m.get("memory",0)//1048576), p.get("pid","-")))
' 2>/dev/null
fi

echo -e "\n$LINE"
echo -e "  ${Y}pm2 list${R} · ${Y}pm2 logs${R} · ${Y}htop${R} · ${Y}tmux${R}      ${G}COMMANDOR${R} ${D}|${R} ${W}@xpT_T${R}"
echo -e "$LINE\n"
