#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as sudo ./create_tink_workflow.sh"
   exit 1
fi

export OS_CODENAME=bullseye
export MAC_ADDRESS=52:54:00:48:6c:40
export IP_ADDRESS=10.4.4.5
export NETMASK=255.255.255.0
export GATEWAY=10.4.4.1
export HOSTNAME=server001

#read -sp 'Enter new root password: ' ROOTPASSWORD
#printf "\n"
#read -sp 'Enter new user password: ' USERPASSWORD
#printf "\n"
#read -sp 'Enter new password salt: ' PASSWORDSALT
#printf "\n"

ROOTPASSWORD="abc123"
USERPASSWORD="abc123"
PASSWORDSALT="12345678"

export UUID=$(uuidgen|tr "[:upper:]" "[:lower:]")
export CRYPTEDROOTPASSWORD=$(printf '%s\n' "$ROOTPASSWORD" | mkpasswd --stdin --method=sha-512 --salt "$PASSWORDSALT")
export CRYPTEDUSERPASSWORD=$(printf '%s\n' "$USERPASSWORD" | mkpasswd --stdin --method=sha-512 --salt "$PASSWORDSALT")
echo "Generate $UUID.json"
cat ./hardware.json | envsubst  > $UUID.json
unset ROOTPASSWORD CRYPTEDROOTPASSWORD USERPASSWORD CRYPTEDUSERPASSWORD PASSWORDSALT

echo "Creating new Tinkerbell worker environment"
docker exec -i deploy_tink-cli_1 tink hardware push < ./$UUID.json
rm $UUID.json

#exit 0

#docker exec -i deploy_tink-cli_1 tink template create --name $OS_CODENAME < ./$OS_CODENAME.yml | tee ./template.txt
docker exec -i deploy_tink-cli_1 tink template create    < ./$OS_CODENAME.yml | tee ./template.txt
TEMPLATE_ID=$(cat ./template.txt | awk '/Created/{printf "%s", $3}' && rm ./template.txt)

docker exec -i deploy_tink-cli_1 tink workflow create --hardware '{"device_1":"'$MAC_ADDRESS'"}' --template "$TEMPLATE_ID" | tee ./workflow.txt
WORKFLOW_ID=$(cat ./workflow.txt | awk '/Created/{printf "%s", $3}' && rm ./workflow.txt)
echo "Run 'docker exec -i deploy_tink-cli_1 tink workflow events $WORKFLOW_ID' to view events."
