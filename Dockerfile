FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 TERM=xterm-256color

RUN userdel -r ubuntu 2>/dev/null || true

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git gnupg openssh-server sudo \
    python3 python3-pip python3-venv build-essential \
    sqlite3 jq nano vim-tiny tree htop tmux screen \
    dnsutils iputils-ping iproute2 net-tools procps lsof rsync unzip zip \
    figlet openssl gawk \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g pm2 pnpm yarn typescript tsx nodemon \
    && mkdir -p /run/sshd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY branding/commandor-welcome.sh /etc/profile.d/commandor-welcome.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /etc/profile.d/commandor-welcome.sh \
    && echo '[ -f /etc/profile.d/commandor-welcome.sh ] && . /etc/profile.d/commandor-welcome.sh' >> /etc/bash.bashrc

EXPOSE 22
CMD ["/usr/local/bin/entrypoint.sh"]
