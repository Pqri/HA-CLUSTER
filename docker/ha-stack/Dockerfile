FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 TZ=Asia/Jakarta

RUN apt-get update \
 && apt-get install -y --no-install-recommends software-properties-common gnupg ca-certificates curl \
 && add-apt-repository -y universe \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      pacemaker corosync pcs \
      resource-agents-base resource-agents-extra \
      drbd-utils \
      iproute2 iputils-ping net-tools dnsutils \
      openssl \
      supervisor procps vim less \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd -r haclient 2>/dev/null || true \
 && id -u hacluster >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin hacluster \
 && echo 'hacluster:123' | chpasswd \
 && mkdir -p /etc/corosync /etc/pacemaker /var/lib/pacemaker /var/lib/pcsd \
            /var/log/pcsd /var/log/supervisor /etc/supervisor/conf.d \
 && chgrp -R haclient /var/lib/pcsd || true && chmod 750 /var/lib/pcsd

# supervisor main
RUN cat <<'EOF' > /etc/supervisor/supervisord.conf
[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
childlogdir=/var/log/supervisor

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[include]
files = /etc/supervisor/conf.d/*.conf
EOF

# program yang diawasi
RUN cat <<'EOF' > /etc/supervisor/conf.d/pacemaker.conf
[program:pcsd]
command=/bin/bash -lc "mkdir -p /var/log/pcsd /var/lib/pcsd; chgrp -R haclient /var/lib/pcsd || true; chmod 750 /var/lib/pcsd; exec /usr/sbin/pcsd"
autorestart=true
priority=10
stderr_logfile=/var/log/supervisor/pcsd.err.log
stdout_logfile=/var/log/supervisor/pcsd.out.log

[program:corosync]
command=/usr/sbin/corosync -f
autorestart=true
priority=20
stderr_logfile=/var/log/supervisor/corosync.err.log
stdout_logfile=/var/log/supervisor/corosync.out.log

[program:pacemaker]
command=/usr/sbin/pacemakerd -f
autorestart=true
priority=30
stderr_logfile=/var/log/supervisor/pacemakerd.err.log
stdout_logfile=/var/log/supervisor/pacemakerd.out.log
EOF

HEALTHCHECK --interval=10s --timeout=3s --retries=15 \
  CMD corosync-cmapctl totem.nodeid >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]

