FROM node:16.15-bullseye-slim

RUN apt update && apt install -y build-essential bc git python3 curl httpie jq nano wget bsdmainutils base58 netcat net-tools libsecret-1-dev clang cmake
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs >> /tmp/rustup.sh && sh /tmp/rustup.sh -y
ENV PATH="/root/.cargo/bin:$PATH"

# CLI version
ARG VERSION

# Clone repo
RUN git clone -b ${VERSION} https://github.com/graphprotocol/indexer /root/.npm-global/lib/node_modules/@graphprotocol/indexer-cli

WORKDIR /root/.npm-global/lib/node_modules/@graphprotocol/indexer-cli
RUN yarn --global --frozen-lockfile --non-interactive --production=false

RUN ln -s /root/.npm-global/lib/node_modules/@graphprotocol/indexer-cli/packages/indexer-cli/bin/graph-indexer /usr/bin/graph

RUN mkdir -p "/root/.config/graph-cli/"
ARG PROJECT
RUN echo "api = \"http://$PROJECT-indexer-agent:8000/\"" >> "/root/.config/graph-cli/indexing.toml"
RUN echo "export PROMPT_COMMAND='history -a' && export HISTFILE=/history/.bash_history" >> "/root/.bashrc"
WORKDIR /root/