#!/bin/ash

set -e

cat > /etc/apk/repositories << EOF; $(echo)

http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/main
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing

EOF

apk update

apk add docker qemu-guest-agent tailscale curl logrotate

mkdir -p /etc/docker

cat > /etc/docker/daemon.json << EOF; $(echo)
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "20m",
    "max-file": "6",
    "compress": "true"
  }
}
EOF

rc-update add docker
rc-service docker start

rc-update add qemu-guest-agent
rc-service qemu-guest-agent start

rc-update add tailscale
rc-service tailscale start

mkdir -p /var/lib/docker/stack_configs

tailscale up --advertise-tags tag:server

docker network inspect tailnet > /dev/null 2>&1 || docker network create -d bridge -o com.docker.network.bridge.host_binding_ipv4=$(tailscale ip | head -n1) tailnet

docker login ghcr.io

docker inspect dockerstack-root > /dev/null 2>&1 || docker run --init --restart=unless-stopped -d -it -v /var/lib/docker/stack_configs:/configs -v /var/run/docker.sock:/var/run/docker.sock -v /etc/hostname:/app/hostname:ro -e CONFIGS_DIR=/var/lib/docker/stack_configs --name dockerstack-root -l dockerstack-root ghcr.io/keenfamily-us/dockerstack-keenland:main
