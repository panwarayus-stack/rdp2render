FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    RDP_USER=rdpuser \
    RDP_PASSWORD=ChangeMe123!

# install packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    xrdp \
    xfce4 xfce4-terminal xfce4-goodies \
    wget \
    ca-certificates \
    sudo \
    net-tools \
    iproute2 \
    curl \
    gnupg \
    lsb-release \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# create user and give password
RUN useradd -m -s /bin/bash ${RDP_USER} && \
    echo "${RDP_USER}:${RDP_PASSWORD}" | chpasswd && \
    usermod -aG sudo ${RDP_USER}

# Setup XFCE for xrdp
RUN mkdir -p /home/${RDP_USER}/.xsession && \
    echo "xfce4-session" > /home/${RDP_USER}/.xsession && \
    chown -R ${RDP_USER}:${RDP_USER} /home/${RDP_USER}

# Install Tailscale user-mode client
RUN wget -qO- https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | gpg --dearmor >/usr/share/keyrings/tailscale-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu focal main" > /etc/apt/sources.list.d/tailscale.list \
 && apt-get update \
 && apt-get install -y tailscale \
 && rm -rf /var/lib/apt/lists/*

# Copy start script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose xrdp port (optional, not used if you access via Tailscale)
EXPOSE 3389

CMD ["/usr/local/bin/start.sh"]
