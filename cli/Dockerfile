FROM node:20.17.0-bookworm-slim as build

ENV NODE_ENV production

RUN apt update && apt install -y build-essential bc git python3 curl httpie jq nano wget bsdmainutils base58 netcat-traditional net-tools libsecret-1-dev clang cmake

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs >> /tmp/rustup.sh && sh /tmp/rustup.sh -y
ENV PATH="/root/.cargo/bin:$PATH"

# CLI version
ARG VERSION
ARG INDEXER_NAME

WORKDIR /root/
RUN git clone -b ${VERSION} https://github.com/graphprotocol/indexer /root/.npm-global/lib/node_modules/@graphprotocol/indexer-cli
WORKDIR /root/.npm-global/lib/node_modules/@graphprotocol/indexer-cli
RUN git checkout ${VERSION}

WORKDIR /root/.npm-global/lib/node_modules/@graphprotocol/indexer-cli
RUN yarn --global --frozen-lockfile --non-interactive --production=false

RUN ln -s /root/.npm-global/lib/node_modules/@graphprotocol/indexer-cli/packages/indexer-cli/bin/graph-indexer /usr/bin/graph

RUN mkdir -p "/root/.config/graph-cli/"
RUN echo "api = \"http://${INDEXER_NAME}-indexer-agent:8000/\"" >> "/root/.config/graph-cli/indexing.toml"
RUN echo "export PROMPT_COMMAND='history -a' && export HISTFILE=/history/.bash_history" >> "/root/.bashrc"

WORKDIR /root/
ENTRYPOINT ["cat"]