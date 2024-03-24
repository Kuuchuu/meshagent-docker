FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl nano wget procps openssh-client iproute2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#    apt-get install -y curl nano wget procps openssh-client iproute2 x11-apps && \

SHELL ["/bin/bash", "-c"]
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
