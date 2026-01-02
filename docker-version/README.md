(1) update & upgrade packages

    sudo apt-get update
    sudo apt-get upgrade

(2) install go

    sudo apt install golang-go

(3) install docker:

    sudo apt-get install ca-certificates curl gnupg lsb-release
    sudo mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-compose
    sudo systemctl status docker
    sudo systemctl start docker

(4) install fabric samples:

    mkdir fabric
    cd fabric
    pip install setuptools
    sudo usermod -aG docker $USER
    restart computer
    cd fabric
    curl -sSL http://bit.ly/2ysbOFE | bash -s -- 2.0.0-beta 1.4.4 0.4.18
    cd fabric-samples

(5) install KalimaHLF chaincode

    add the kalimaHLF/ folder to fabric-samples/ folder and 
    chaincode/kalimaHLF folder to fabric-samples/chaincode folder
    
    cd kalimaHLF
    ./startFabric.sh

(7) ...
