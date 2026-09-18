FROM glcr.rd.ubtrobot.com/rosa/images/rust:ubuntu24.04

USER root
RUN apt-get update && apt-get install -y --no-install-recommends bash ca-certificates curl git shellcheck sudo && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash tester && echo 'tester ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/tester
COPY --chown=tester:tester . /opt/dotfiles
USER tester
WORKDIR /opt/dotfiles
ENV HOME=/home/tester XDG_CONFIG_HOME=/home/tester/.config XDG_DATA_HOME=/home/tester/.local/share XDG_STATE_HOME=/home/tester/.local/state XDG_CACHE_HOME=/home/tester/.cache
RUN ./tests/run.sh
RUN shellcheck setup.sh lib/*.sh modules/*/*.sh scripts/*.sh tests/*.sh
CMD ["bash"]
