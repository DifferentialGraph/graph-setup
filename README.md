# Graph Setup
Repository containing the setup for a graph node with the option of dynamically adding or removing different blockchains as well as the possibility of creating multiple indexers running in parallel each of them operating either on the mainnet or goerli. The repositories offers in addition various tools to monitor and manage your graph node.

## Installation
In order to setup you graph node first create a copy of the `.env` file named `.env.user`. Fill with the options that suits your framework. The majority of the options are preset and you can leave the defaults values. You must fill correctly the options in the following categories:
- Host;
- Blockchains Supported;
- Indexer Info.
Refer to the **Options** section to know how to fill the variables.

In order to install you graph setup you just have to run, from within the graph-setup folder:
```sh
./install.sh <name-of-your-node> <network>
```
In `<name-of-your-node>` choose the name for your graph node. This will create a group of docker containers related to the specific name you chose. A specific docker network will be created as well. This means that you can run multiple indexers in parallel on the same machine. `<network>` can be set to either `main`, to operate on the ethereum mainnet, or `test`, to operate on ethereum goerli.

Be aware that you should not run multiple indexers on the mainnet from the same server. We developed this framework in order to handle the MIPS on the goerli test net while running our main indexer on the mainnet using only one server. For instance we created our main graph setup, operating on the mainnet, with
```sh
./install.sh main main
```
and the MIPS graph setup, operating on the goerli net, with
```sh
./install.sh mips test
```
There is no need to install docker or other packages. If the necessary packages are not present on your machine the installation script will take care of them.

Once you installed the graph setup once you can run the installation again in order to include potential updates. During the first installation and environment file `.env.<name-of-your-node>` is automatically created. If you want to change any option you can edit directly this file. Nevertheless, if you want to create another graph node setup you have to edit the original `.env.user` environment file.

## Monitor & Manage
In order to have additional features to handle and monitor your graph node add to your `.bashrc`, if you are using bash shell, or `.zshrc` if you are using zsh shell, the following line:
```sh
source </path/to/graph-setup>/utils/manage
```
and source for the changes to have effect
```sh
source ~/.bashrc(~/.zshrc)
```
In order to monitor your graph node just type
```sh
graph-monitor <name-of-your-node>
```
This will create a tmux session with the following windows:
- **indexer-cli**: in this window you can operate from within the indexer-cli container. This useful to perform the most common operations such opening/closing allocations or setting cost models.
- **graphman**: in this window you can operate from within the query-node container. This useful in order to operate with graphman to handle subgraphs assignment and sync as well block cache related stuff. Good practice is to stop the index-node container before you perform any operation.
- **indexer-agent**: log of the indexer-agent container. Shows all the operation performed by your agent.
- **indexer-service**: log of the indexer-service container. Shows all the queries processed by your indexer service.
- **indexer-node**: log of the indexer-node container. your agent.
- **query-node**: log of the query-node container.
In order to start and stop the graph node after having installed it use `graph-start <name-of-your-node>` and `graph-stop <name-of-your-node>`. You can start and shutdown different "modules" of your graph node by
```sh
graph-start(stop) <name-of-your-node> <module>
```
`<module>` can be set to: 
- `node` -> operate on index-node and query node services.
- `indexer` -> operate on indexer-cli, indexer-agent and indexer-service services.
- `monitor` -> operate on prometheus and grafana services.
- `all` -> operate on all the services.
At the moment you also have the opportunity to start and stop separately the reverse proxy by passing `proxy`. This options will be separated from this repository in the future.

## Options
### Host
- `HOST` -> this is the domain linked to your server. It is necessary in order to receive queries (the indexer-service will handle it) as well as access to your Grafana/Prometheus dashboard.
- `EMAIL` -> this is necessary only to create the SSL certificate.
- `PROXY` -> this allows you to choose which reverse proxy you want to use in order to handle connections to your server. At the moment we support only **nginx** but **traefik** is going to be implemented in a short (`WHITELIST` is an option reserved traefik reverse proxy and it will allow to filter incoming connections based on the ip address).

### Blockchains Supported
- `CHAIN_NAME` -> it is an array variable. Here you should specify the chains that you want to support your graph node, e.g. `CHAIN_NAME=(mainnet gnosis)`. Available chains after the MIPS program: `mainnet`, `gnosis`, `matic`, `celo`, `arbitrum-one`, `avalanche`, `fantom`, `optimism`.
- `CHAIN_RPC` -> it is an array variable. Here you should specify the RPC for the chains you specified the CHAIN_NAME variable, e.g. `CHAIN_RPC=(http(s)://<ethereum-rpc> http(s)://<gnosis-rpc>)`.
- `TXN_RPC_MAIN` -> the RPC for transaction in case your indexer operates on the **mainnet**.
- `TXN_RPC_MAIN` -> the RPC for transaction in case your indexer operates on the **testnet** (goerli).

### Indexer Info
These variables identify information regarding your indexer:
- `OPERATOR_MNEMONIC` -> the mnemonic of your operator wallet.
- `STAKING_ADDRESS` -> the address of your indexer.
- `GEO_COORDINATES` -> coordinates defining the location of your server.

### Agent Properties
This category defines different options to control the behavior of your indexer agent:
- `INJECT_DAI` -> automatically define the DAI variable in you cost model.
- `GAS_PRICE_MAX` -> the agent will not perform any transaction if the current gas price is above to the specified threshold.
- `REBATE*` and `VOUCHER*` -> this variables defines the behavior of the indexer when claiming queries. Refer to the official documentation for more info.
More options will be added gradually.

### Graph Node & Agent/Service Databases Settings
The name of the variables in category are self explanatory. They define name, user and password for the databases connected to the graph node and the indexer agent/service.

### Grafana & Prometheus Settings
The name of the variables in category are self explanatory. They define user and password for accessing your Grafana and Prometheus dashboard.

### Autoagora Settings
Set `AUTOAGORA` to either **true** or **false** to activate or deactivate *autoagora*. The other variables define name, user and password of the database connected to autoagora as well as user and password for rabbitmq.