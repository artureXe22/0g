#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1 && curl -s https://api.nodes.guru/logo.sh | bash && sleep 1

NODE="0g"
export DAEMON_HOME=$HOME/.0gchain
export DAEMON_NAME=0gchaind
if [ -d "$DAEMON_HOME" ]; then
    new_folder_name="${DAEMON_HOME}_$(date +"%Y%m%d_%H%M%S")"
    mv "$DAEMON_HOME" "$new_folder_name"
fi
#CHAIN_ID=zgtendermint_9000-1
#echo 'export CHAIN_ID='\"${CHAIN_ID}\" >> $HOME/.bash_profile

if [ ! $VALIDATOR ]; then
    read -p "Enter validator name: " VALIDATOR
    echo 'export VALIDATOR='\"${VALIDATOR}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
source $HOME/.bash_profile
sleep 1
cd $HOME
sudo apt update
sudo apt install make unzip clang pkg-config lz4 libssl-dev build-essential git jq ncdu bsdmainutils htop -y < "/dev/null"

echo -e '\n\e[42mInstall Go\e[0m\n' && sleep 1
cd $HOME
VERSION=1.20.14
wget -O go.tar.gz https://go.dev/dl/go$VERSION.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go.tar.gz && rm go.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
go version

echo -e '\n\e[42mInstall software\e[0m\n' && sleep 1

sleep 1
cd $HOME
rm -rf 0g-chain
git clone -b v0.1.0 https://github.com/0glabs/0g-chain.git
./0g-chain/networks/testnet/install.sh
source .profile

SEEDS="c4d619f6088cb0b24b4ab43a0510bf9251ab5d7f@54.241.167.190:26656,44d11d4ba92a01b520923f51632d2450984d5886@54.176.175.48:26656,f2693dd86766b5bf8fd6ab87e2e970d564d20aff@54.193.250.204:26656,f878d40c538c8c23653a5b70f615f8dccec6fb9f@54.215.187.94:26656"
$DAEMON_NAME init "${VALIDATOR}" --chain-id zgtendermint_9000-1
sleep 1
$DAEMON_NAME config keyring-backend test
$DAEMON_NAME config chain-id zgtendermint_16600-1
wget -O $DAEMON_HOME/config/genesis.json https://github.com/0glabs/0g-chain/releases/download/v0.1.0/genesis.json
sed -i.bak -e "s/^seeds *=.*/seeds = \"${SEEDS}\"/" $DAEMON_HOME/config/config.toml
#sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.00252aevmos\"/" $DAEMON_HOME/config/app.toml

# Update peers in the config
PEERS="9e2febd1c051e695e99d0180141f13eb7da128a6@75.119.152.232:26656,91b4d967e322606eb89892d609904eb5a8d8125b@51.83.66.181:27656,1d138c148692ab5830fc99979f6d376e25994a50@213.199.41.243:26656,fe1dbb596ca2001c1e4da85fdcb355122bad1e2e@213.199.53.225:26656,09276ca89027a4357ea7e68d0bfc25e58fe77377@176.126.87.189:26656,9087a83002cbacaaa1cc7532c086410fa89d3a70@88.198.52.89:64656,840be9da0743cb195519fb48848d571598f46b87@88.198.82.151:26656,e2f0de202df1770b8e7e2780e1562e138caaf8a6@62.169.18.171:26656,3492fde06a28171cb8e257a5a00448ae10ef9d68@194.163.157.109:12656,fde6660ee4551f36ffefe549fefb4aa093ac7f29@194.35.120.148:12656,2b5e2dcb5a307529f064b08137e70295785df547@38.242.210.236:26656,773a0b5f35225210c0f04d78bf28bed2836c13c5@38.242.156.74:26656,c024d83af04b34f9afef7d6f8b00343978174a1c@37.27.117.171:26656,b962d4afb587406e20b9cbd8f017e330d3f9a8ff@51.91.74.124:26656,5d2074e5a5631c4b95b06a1469439e6a2dad0961@212.192.26.234:26656" && \
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.0gchain/config/config.toml && \


echo "[Unit]
Description=$NODE Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=$(which 0gchaind) start
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/$NODE.service
sudo mv $HOME/$NODE.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF

echo -e '\n\e[42mDownloading a snapshot\e[0m\n' && sleep 1
curl http://snapshots.liveraven.net/snapshots/testnet/zero-gravity/zgtendermint_16600-1_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $DAEMON_HOME
wget -O $DAEMON_HOME/config/addrbook.json https://snapshots.liveraven.net/snapshots/testnet/zero-gravity/addrbook.json

echo -e '\n\e[42mChecking a ports\e[0m\n' && sleep 1
#CHECK PORTS
PORT=335
if ss -tulpen | awk '{print $5}' | grep -q ":26656$" ; then
    echo -e "\e[31mPort 26656 already in use.\e[39m"
    sleep 2
    sed -i -e "s|:26656\"|:${PORT}56\"|g" $DAEMON_HOME/config/config.toml
    echo -e "\n\e[42mPort 26656 changed to ${PORT}56.\e[0m\n"
    sleep 2
fi
if ss -tulpen | awk '{print $5}' | grep -q ":26657$" ; then
    echo -e "\e[31mPort 26657 already in use\e[39m"
    sleep 2
    sed -i -e "s|:26657\"|:${PORT}57\"|" $DAEMON_HOME/config/config.toml
    echo -e "\n\e[42mPort 26657 changed to ${PORT}57.\e[0m\n"
    sleep 2
    $DAEMON_NAME config node tcp://localhost:${PORT}57
fi
if ss -tulpen | awk '{print $5}' | grep -q ":26658$" ; then
    echo -e "\e[31mPort 26658 already in use.\e[39m"
    sleep 2
    sed -i -e "s|:26658\"|:${PORT}58\"|" $DAEMON_HOME/config/config.toml
    echo -e "\n\e[42mPort 26658 changed to ${PORT}58.\e[0m\n"
    sleep 2
fi
if ss -tulpen | awk '{print $5}' | grep -q ":6060$" ; then
    echo -e "\e[31mPort 6060 already in use.\e[39m"
    sleep 2
    sed -i -e "s|:6060\"|:${PORT}60\"|" $DAEMON_HOME/config/config.toml
    echo -e "\n\e[42mPort 6060 changed to ${PORT}60.\e[0m\n"
    sleep 2
fi
if ss -tulpen | awk '{print $5}' | grep -q ":1317$" ; then
    echo -e "\e[31mPort 1317 already in use.\e[39m"
    sleep 2
    sed -i -e "s|:1317\"|:${PORT}17\"|" $DAEMON_HOME/config/app.toml
    echo -e "\n\e[42mPort 1317 changed to ${PORT}17.\e[0m\n"
    sleep 2
fi
if ss -tulpen | awk '{print $5}' | grep -q ":9090$" ; then
    echo -e "\e[31mPort 9090 already in use.\e[39m"
    sleep 2
    sed -i -e "s|:9090\"|:${PORT}90\"|" $DAEMON_HOME/config/app.toml
    echo -e "\n\e[42mPort 9090 changed to ${PORT}90.\e[0m\n"
    sleep 2
fi
if ss -tulpen | awk '{print $5}' | grep -q ":9091$" ; then
    echo -e "\e[31mPort 9091 already in use.\e[39m"
    sleep 2
    sed -i -e "s|:9091\"|:${PORT}91\"|" $DAEMON_HOME/config/app.toml
    echo -e "\n\e[42mPort 9091 changed to ${PORT}91.\e[0m\n"
    sleep 2
fi
if ss -tulpen | awk '{print $5}' | grep -q ":8545$" ; then
    echo -e "\e[31mPort 8545 already in use.\e[39m"
    sleep 2
    sed -i -e "s|:8545\"|:${PORT}45\"|" $DAEMON_HOME/config/app.toml
    echo -e "\n\e[42mPort 8545 changed to ${PORT}45.\e[0m\n"
    sleep 2
fi
if ss -tulpen | awk '{print $5}' | grep -q ":8546$" ; then
    echo -e "\e[31mPort 8546 already in use.\e[39m"
    sleep 2
    sed -i -e "s|:8546\"|:${PORT}46\"|" $DAEMON_HOME/config/app.toml
    echo -e "\n\e[42mPort 8546 changed to ${PORT}46.\e[0m\n"
    sleep 2
fi

#echo -e '\n\e[42mRunning a service\e[0m\n' && sleep 1
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable $NODE
sudo systemctl restart $NODE


echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service $NODE status | grep active` =~ "running" ]]; then
  echo -e "Your $NODE node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mservice 0g status\e[0m"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
else
  echo -e "Your $NODE node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
