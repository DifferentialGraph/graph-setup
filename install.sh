#!/bin/bash

# Load functions
source utils/configure

# Install requirements
base-config

# Check if project name is defined
if [ -z "$1" ]; then
  echo "No project defined" >&2
  exit 1
else
  PROJECT=$1
fi

# Check if the network is defined
if [ -z "$2" ]; then
  echo "No network defined" >&2
  exit 1
else
  NETWORK=$2
fi

# Generate configurartion file if not existing
if [ ! -f .env.$PROJECT ]; then
  echo "Generating environment file..."
  # Load user configuration file
  source .env.user

  # Set project variables
  echo "COMPOSE_PROJECT_NAME=$PROJECT" > .env.$PROJECT

  # Hosts
  echo "INDEX_HOST=index-$PROJECT.$HOST" >> .env.$PROJECT
  echo "GRAFANA_HOST=dashboard-$PROJECT.$HOST" >> .env.$PROJECT
  echo "PROMETHEUS_HOST=prometheus-$PROJECT.$HOST" >> .env.$PROJECT

  if [ "$NETWORK" = "main" ]; then
    echo "You are chosing to operate on the MAIN network"
    
    # Agent / Service
    echo "TXN_RPC=$TXN_RPC_MAIN" >> .env.$PROJECT
    echo "ETHEREUM_NETWORK="mainnet"" >> .env.$PROJECT
    echo "NETWORK_SUBGRAPH_ENDPOINT="https://gateway.thegraph.com/network"" >> .env.$PROJECT
    # echo "NETWORK_SUBGRAPH_ENDPOINT="https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-mainnet"" >> .env.$PROJECT

    # Agent
    echo "DAI_CONTRACT="0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"" >> .env.$PROJECT
    echo "COLLECT_RECEIPTS_ENDPOINT="https://gateway.network.thegraph.com/collect-receipts"" >> .env.$PROJECT
    echo "EPOCH_SUBGRAPH_ENDPOINT="https://api.thegraph.com/subgraphs/name/graphprotocol/mainnet-epoch-block-oracle"" >> .env.$PROJECT

    # Service
    echo "CLIENT_SIGNER_ADDRESS="0x982D10c56b8BBbD6e09048F5c5f01b43C65D5aE0"" >> .env.$PROJECT
  elif [ "$NETWORK" = "test" ]; then
    echo "You are chosing to operate on the TEST network"

    # Agent / Service
    echo "TXN_RPC=$TXN_RPC_TEST" >> .env.$PROJECT
    echo "ETHEREUM_NETWORK="goerli"" >> .env.$PROJECT
    echo "NETWORK_SUBGRAPH_ENDPOINT="https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-goerli"" >> .env.$PROJECT
    # echo "ETHEREUM_NETWORK="arbitrum-goerli"" >> .env.$PROJECT
    # echo "NETWORK_SUBGRAPH_ENDPOINT="https://api.thegraph.com/subgraphs/name/graphprotocol/graph-network-arbitrum-goerli"" >> .env.$PROJECT
    
    # Agent
    echo "DAI_CONTRACT="0x9e7e607afd22906f7da6f1ec8f432d6f244278be"" >> .env.$PROJECT
    echo "COLLECT_RECEIPTS_ENDPOINT="https://gateway.testnet.thegraph.com/collect-receipts"" >> .env.$PROJECT
    echo "EPOCH_SUBGRAPH_ENDPOINT="https://api.thegraph.com/subgraphs/name/graphprotocol/goerli-epoch-block-oracle"" >> .env.$PROJECT
    # echo "COLLECT_RECEIPTS_ENDPOINT="https://gateway-testnet-arbitrum.network.thegraph.com/collect-receipts"" >> .env.$PROJECT
    # echo "EPOCH_SUBGRAPH_ENDPOINT="https://api.thegraph.com/subgraphs/name/juanmardefago/arb-goerli-epoch-block-oracle"" >> .env.$PROJECT

    # Service
    echo "CLIENT_SIGNER_ADDRESS="0xe1EC4339019eC9628438F8755f847e3023e4ff9c"" >> .env.$PROJECT
    # echo "INDEXER_SERVICE_CLIENT_SIGNER_ADDRESS="0xac01B0b3B2Dc5D8E0D484c02c4d077C15C96a7b4"" >> .env.$PROJECT
  else
    echo "Choose either main or test" >&2
    exit 1
  fi

  # Project configuration file
  cat .env.user >> .env.$PROJECT
else
  echo 'Envinroment file found.'
  source .env.$PROJECT
fi

# Index/Query Node
docker volume create ${PROJECT}_node-config
NODE_CONFIG_FILE=/var/lib/docker/volumes/${PROJECT}_node-config/_data/config.toml
generate-node-config $NODE_CONFIG_FILE

# Prometheus
export PROJECT
docker volume create ${PROJECT}_prometheus-config
envsubst '${PROJECT}' < prometheus/alert.rules > /var/lib/docker/volumes/${PROJECT}_prometheus-config/_data/alert.rules
envsubst < prometheus/prometheus.yml > /var/lib/docker/volumes/${PROJECT}_prometheus-config/_data/prometheus.yml

# Grafana
docker volume create ${PROJECT}_grafana-provisioning
cp -R grafana/dashboards/ grafana/datasources/ /var/lib/docker/volumes/${PROJECT}_grafana-provisioning/_data
envsubst < grafana/dashboards/indexing-performance-metrics.json > /var/lib/docker/volumes/${PROJECT}_grafana-provisioning/_data/dashboards/indexing-performance-metrics.json

# Alertmanager
docker volume create ${PROJECT}_alertmanager-config
cp alertmanager/config.yml /var/lib/docker/volumes/${PROJECT}_alertmanager-config/_data

# Start services
if $AUTOAGORA; then 
  COMPOSE_FILE=services/graph-setup.yml:services/autoagora.yml
  COMPOSE_PROFILES=autoagora
  # docker stop ${PROJECT}-indexer-service
  # docker compose --env-file .env.$PROJECT up -d --build
else
  COMPOSE_FILE=services/graph-setup.yml
  COMPOSE_PROFILES=no-autoagora
fi

# Graph Node
COMPOSE_FILE=$COMPOSE_FILE COMPOSE_PROFILES=$COMPOSE_PROFILES docker compose --env-file .env.$PROJECT up -d --remove-orphans --build

# Attach Graph Node to Local Blockchains
for node in "${CHAIN_NAME[@]}"
do
  if [ $node == 'mainnet' ]; then 
    node=ethereum 
  fi
  if [ "$(docker network ls -f name=$node -q)" ]; then
    docker network connect $node ${PROJECT}-index-node
    docker network connect $node ${PROJECT}-query-node
  fi
done

# Reverse Proxy
if [ "$( docker container inspect -f '{{.State.Status}}' proxy-nginx )" != "running" ]; then
  echo "NGINX-PROXY not running"
  docker volume create proxy_nginx-htpasswd
  COMPOSE_PROJECT_NAME=proxy COMPOSE_PROFILES=$PROXY EMAIL=email@$HOST WHITELIST=$WHITELIST docker compose -f services/reverse-proxy.yml up -d --remove-orphans --build
  docker cp nginx/nginx.conf proxy-nginx:/etc/nginx
fi

# Attach proxy-nginx to the project network
net_present=false
for net in $(docker container inspect --format '{{range $net,$v := .NetworkSettings.Networks}}{{printf "%s\n" $net}}{{end}}' proxy-nginx)
do
  if [ "$net" = ${PROJECT}-indexer ]; then
    net_present=true
  fi
done
if [ "$net_present" == false ] ; then
  echo "Connecting proxy-nginx..."
  htpasswd -c -b /var/lib/docker/volumes/proxy_nginx-htpasswd/_data/prometheus-$PROJECT.$HOST $PROMETHEUS_USER $PROMETHEUS_PASS
  docker network connect ${PROJECT}-indexer proxy-nginx
fi

# Populate with subgraph sizes for grafana
sleep 5
docker exec -it $PROJECT-postgres-node psql -U ${DB_NODE_USER} ${DB_NODE_NAME} -c "refresh materialized view info.subgraph_sizes;"

# Unset environment variables
unset PROJECT