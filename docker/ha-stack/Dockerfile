FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 TZ=${TZ:-Asia/Jakarta}

RUN apt-get update \
 && apt-get install -y --no-install-recommends software-properties-common gnupg ca-certificates curl \
 && add-apt-repository -y universe \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      pacemaker corosync pcs pacemaker-cli-utils \
      resource-agents-base resource-agents-extra \
      drbd-utils \
      iproute2 iputils-ping net-tools dnsutils \
      openssl \
      supervisor procps vim less \
 && rm -rf /var/lib/apt/lists/*

# users & dirs
RUN groupadd -r haclient 2>/dev/null || true \
 && id -u hacluster >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin hacluster \
 && echo 'hacluster:123' | chpasswd \
 && mkdir -p /etc/corosync /etc/pacemaker /var/lib/pacemaker /var/lib/pcsd \
            /var/log/pcsd /var/log/supervisor /etc/supervisor/conf.d

# supervisor main
COPY ../../cluster/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY ../../cluster/supervisor/pacemaker.conf /etc/supervisor/conf.d/pacemaker.conf

HEALTHCHECK --interval=10s --timeout=3s --retries=15 CMD corosync-cmapctl totem.nodeid >/dev/null 2>&1 || exit 1
ENTRYPOINT ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]
