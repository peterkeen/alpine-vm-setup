#!/bin/ash

set -e

mkdir /root/.ssh

wget -O /root/.ssh/authorized_keys https://github.com/peterkeen.keys

cat > /etc/apk/repositories << EOF; $(echo)

http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/main
http://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/community
http://dl-cdn.alpinelinux.org/alpine/edge/testing

EOF

apk update

apk add docker

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

mkdir -p /var/lib/docker/stack_configs

docker login ghcr.io

docker run --init --restart=unless-stopped -d -it -v /var/lib/docker/stack_configs:/configs -v /var/run/docker.sock:/var/run/docker.sock -v /etc/hostname:/app/hostname:ro -e CONFIGS_DIR=/var/lib/docker/stack_configs --name dockerstack-root -l dockerstack-root ghcr.io/keenfamily-us/dockerstack-keenland:main
