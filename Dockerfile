FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Default values (Render overrides these with Environment Variables)
ENV RDP_USER=ayush
ENV RDP_PASSWORD=AyushBro@123
ENV TAILSCALE_AUTH_KEY=""

# --- Install XRDP, XFCE, deps ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    xrdp \
    xfce4 xfce4-terminal xfce4-goodies \
    sudo \
    curl wget ca-certificates \
    iproute2 net-tools \
    gnupg lsb-release unzip \
    && rm -rf /var/lib/apt/lists/*

# --- Create RDP User ---
RUN useradd -m -s /bin/bash ${RDP_USER} && \
    echo "${RDP_USER}:${RDP_PASSWORD}" | chpasswd && \
    usermod -aG sudo ${RDP_USER}

# --- Set XFCE session for XRDP ---
RUN echo "xfce4-session" > /home/${RDP_USER}/.xsession && \
    chown -R ${RDP_USER}:${RDP_USER} /home/${RDP_USER}

# --- Install Tailscale (userspace mode) ---
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | gpg --dearmor \
    | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu focal main" \
    > /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && apt-get install -y tailscale && \
    rm -rf /var/lib/apt/lists/*

# --- Copy Start Script ---
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# XRDP Port
EXPOSE 3389

CMD ["/usr/local/bin/start.sh"]
