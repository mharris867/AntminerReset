# Raspberry pi iot edge on raspian
1. Start Raspberry Pi Imager
    - select Raspberry Pi Os Lite 32-bit
    - configure hostname
    - enable ssh
    - set password
    - configure wireless lan
    - set timezone
Write to SD and put in pi wen finished. I used rpi4iotedge.local as a hostname


2. ssh pi@rpi4iotedge.local
    -sudo raspi-config
    - advance options -> expand file system
    - interface options -> enable SPI and GPIO
    - update

3. portal.azure.com
    - Create IOT Hub (rpi4iothub)
    - Create Iot Edge Device (rpi4device)

4. Install IOT Edge https://docs.microsoft.com/en-us/azure/iot-edge/how-to-provision-single-device-linux-symmetric?view=iotedge-2020-11&tabs=visual-studio-code%2Crpios on Raspberry Pi OS


curl https://packages.microsoft.com/config/debian/stretch/multiarch/prod.list > ./microsoft-prod.list
sudo cp ./microsoft-prod.list /etc/apt/sources.list.d/

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo cp ./microsoft.gpg /etc/apt/trusted.gpg.d/

5. Install Container engine from same do on Raspberry Pi OS

sudo apt-get update; \
  sudo apt-get install moby-engine

6. Install IoT Edge runtime from doc above

sudo apt-get update; \
  sudo apt-get install aziot-edge

7. Created default modules on iot edge device
    - $edgeAgent
    - $edgeHub

7. provision device with cloud identity in doc above using "Primary Connection String" from IoT Edge device

sudo iotedge config mp --connection-string 'PASTE_DEVICE_CONNECTION_STRING_HERE'

sudo iotedge config apply -c '/etc/aziot/config.toml'

    - Test your connectivity between cloud and rpi with
        sudo iotedge check


1. arm32v7 Remote development requires docker group to run on pi without sudo ssh to pi and:
groupadd docker
usermod -aG docker $USER
newgrp docker 
 -test setting like this
docker run hello-world 

    - https://devblogs.microsoft.com/iotdev/easily-build-and-debug-iot-edge-modules-on-your-remote-device-with-azure-iot-edge-for-vs-code-1-9-0/
    https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-20-04
2. in vs code user settings from command line pallet add these lines only ip of rpi works for some reason do not try name
    "azure-iot-edge.executor.env": {
        "DOCKER_HOST": "ssh://pi@192.168.2.75"
    },


3. during sample build getting internet connectivity errors and not able to restore packages on rpi:
 - sudo iotedge check was also throwing container connectivity errors doc: https://docs.microsoft.com/en-us/azure/iot-edge/troubleshoot-common-errors?view=iotedge-2020-11
sudo nano /etc/sysctl.conf
    - uncomment line below
net.ipv4.ip_forward=1
sudo systemctl restart docker
 If there are errors with pulling local image from local repository in devcontainer.json uncomment:
 "forwardPorts": [5000, 5001],
4. Nuget restore throws errors so trying this dns setting to see if it helps (IT WORKS!)
    - https://docs.microsoft.com/en-us/azure/iot-edge/troubleshoot-common-errors?view=iotedge-2020-11#edge-agent-module-reports-empty-config-file-and-no-modules-start-on-the-device
{
    "dns": ["1.1.1.1"]
}
#trying to point dns to my router (This seems to work too..)
{
    "dns": ["My.network.router.ipaddress"]
}

    - in /etc/docker/daemon.json file
    - Then:
sudo systemctl restart docker

1. running powershell from c#
https://docs.microsoft.com/en-us/powershell/scripting/developer/hosting/windows-powershell-host-quickstart?view=powershell-7.2 

1. Pushing to the Docker Registry had credential issues. Had to set docker login on both dev and build systems before I could push to docker hub. Still dont know if this is what actually made it work:
docker -u mharris867 -p password (on both dev and build)

1. Building a github runner out of my raspberry pi...
- https://github.com/mharris867/AntminerReset/settings/actions/runners/new?arch=arm
- Configure runner service https://docs.github.com/en/actions/hosting-your-own-runners/configuring-the-self-hosted-runner-application-as-a-service
2. Installed powershell to rpi
curl -L -o /tmp/powershell.tar.gz "https://github.com/PowerShell/PowerShell/releases/download/v7.2.3/powershell-7.2.3-linux-arm32.tar.gz"
sudo mkdir -p /opt/microsoft/powershell/7 
sudo tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7
sudo chmod +x /opt/microsoft/powershell/7/pwsh
sudo ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh