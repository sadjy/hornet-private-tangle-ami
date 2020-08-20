#!/bin/bash

sleep 60

set -xe

curl -fsSL https://ppa.iota.org/pubkey.gpg | sudo apt-key add - 
sudo add-apt-repository "deb [arch=amd64] https://ppa.iota.org/hornet stable main"

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

sudo apt update
sudo apt install moreutils jq git apt-transport-https ca-certificates curl software-properties-common docker-ce hornet -y

cd /var/lib/hornet 

if [ -z "$COO_SEED" ]; then
  COO_SEED=$(cat /dev/urandom |LC_ALL=C tr -dc 'A-Z9' | fold -w 81 | head -n 1)
  echo $COO_SEED
fi

jq '.node .alias += "Coordinator"' config.json | sudo sponge config.json
jq '.node .enablePlugins[.node .enablePlugins | length] |= .+ "Coordinator"' config.json | sudo sponge config.json

if [ ! -z "$SEC_LVL" ]; then
    jq --arg SEC_LVL "$SEC_LVL" '.coordinator .securityLevel = $SEC_LVL' config.json | sudo sponge config.json
fi

if [ ! -z "$DEPTH" ]; then
    jq --arg DEPTH "$DEPTH" '.coordinator .merkleTreeDepth = $DEPTH' config.json | sudo sponge config.json
fi

if [ ! -z "$MWM" ]; then
    jq --arg MWM "$MWM" '.coordinator .mwm = $MWM' config.json | sudo sponge config.json
fi

if [ ! -z "$TICK" ]; then
    jq --arg TICK "$TICK" '.coordinator .intervalSeconds = $TICK' config.json | sudo sponge config.json
fi

sudo git clone https://github.com/iotaledger/iota.go.git

sudo docker run --rm --name tree -v /var/lib/hornet/iota.go:/app/iota.go -w /app/iota.go/tools/merkle_calculator golang go build

TREE_ROOT=$(/var/lib/hornet/iota.go/tools/merkle_calculator/merkle_calculator -depth $DEPTH -securityLevel $SEC_LVL -seed $COO_SEED -parallelism 10 -output coordinator.tree 2>&1 >/dev/null | grep root | cut -d " " -f 6)

jq --arg COO_ADDR "$TREE_ROOT" '.coordinator .address = $COO_ADDR' config.json | sudo sponge config.json

jq '.db .path = "privatenet"' config.json | sudo sponge config.json
jq '.snapshots .loadType = "global"' config.json | sudo sponge config.json
jq '.snapshots .global .path = "snapshot.csv"' config.json | sudo sponge config.json
jq '.snapshots .global .spentAddressesPaths = []' config.json | sudo sponge config.json
jq '.snapshots .global .index = 0' config.json | sudo sponge config.json
echo -n $COO_SEED | sudo tee /var/lib/hornet/snapshot.csv
echo -n ";2779530283277761" | sudo tee -a /var/lib/hornet/snapshot.csv
sudo chown -R hornet:hornet /var/lib/hornet 
sudo -u hornet COO_SEED=$COO_SEED hornet --cooBootstrap &
sleep 40
sudo pkill hornet || true

sleep 20
echo "COO_SEED=$COO_SEED" | sudo tee -a /etc/default/hornet

sudo systemctl enable hornet.service 
