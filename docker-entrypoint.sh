#!/bin/bash
set -e
echo -e "\n\n~~~~~~~~~~~~~~~~~~~~~~~~~> $(date)\n"
if [ ! -n "$MESH_USER" ]; then
  MESH_USER=root
fi
if [ -f /root/MESH_USER ]; then
  if [ ! "$MESH_USER" = "$(cat /root/MESH_USER)" ]; then
    echo -e "\nMESH_USER ($MESH_USER) environment variable and previous MESH_USER ($(cat /root/MESH_USER)) do not match! Running with previous MESH_USER!"
    echo -e "Please delete the data/root directory on the host device"
    MESH_USER=$(cat /root/MESH_USER)
  fi
fi
echo -e "\nInstalling Mesh Agent..."
if [ ! -d /usr/local/mesh_daemons ]; then
  if [ -n "$SERVER_URL" ] && [ -n "$TOKEN" ]; then
    curl -sSL $SERVER_URL/meshagents?script=1 | bash -s -- $SERVER_URL $TOKEN || echo -e "Mesh Agent installer script download failed!\nServer URL Provided: $SERVER_URL\nToken Provided: $TOKEN\nMesh User Provided: $MESH_USER\n\nExiting!\n$(exit 1)"
  else
    echo -e "\nSERVER_URL and/or TOKEN are missing!"
    echo -e "  Please set them in the '.env' file.\n"
    exit 1
  fi
else
  echo -e "\n  Mesh Agent install found!"
  echo -e "    Skipping install.\n"
fi
echo "$MESH_USER" > /root/MESH_USER
#if [ ! -f /root/.bashrc ]; then
#  echo -e "\nModifying .bashrc"
#  echo "ssh -o StrictHostKeyChecking=no $MESH_USER@localhost && exit" >> /root/.bashrc
#fi
if [ ! -f /root/.ssh/id_rsa.pub ]; then
  echo -e "\nModifying .bashrc"
  echo "ssh -o StrictHostKeyChecking=no $MESH_USER@localhost && exit" >> /root/.bashrc
  echo -e "\nGenerating ssh keys..."
  ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa
fi
echo -e "\n\nIf \`chroot\` fails, run the following command on the host device as the \"$MESH_USER\" user$(if [ $MESH_USER = root ]; then echo ' (`su -`)'; fi) to allow the Mesh Agent passwordless terminal access:"
if [ "$MESH_USER" = "root" ]; then
  echo "echo \"$(cat ~/.ssh/id_rsa.pub)\" >> /root/.ssh/authorized_keys"
  if uname -a | grep -q NixOS; then
    DEFAULT_INTERFACE=$(ip route show default | awk '/default/ {print $5}')
    IP_ADDRESS=$(ip addr show "$DEFAULT_INTERFACE" | awk '/inet / {print $2}' | cut -d/ -f1)
    echo -e "\n\n\n\nYou may want to add the following to your Nix configuration:\n\`\`\`\nservices.openssh = {\n  enable = true;\n  permitRootLogin = \"prohibit-password\";\n  extraConfig = ''\n    Match Address $IP_ADDRESS\n      PermitRootLogin yes\n  '';\n};\n\nusers.users.$MESH_USER.openssh.authorizedKeys.keys = [\n  \"$(cat ~/.ssh/id_rsa.pub)\"\n];\n\`\`\`\n\n\n"
  fi
else
  echo "echo \"$(cat ~/.ssh/id_rsa.pub)\" >> /home/$MESH_USER/.ssh/authorized_keys"
fi
for dir in /*; do
    if [ "$dir" != "/host" ] && [ -d "$dir" ]; then
        parent_dir_name=$(basename "$dir")
        file_name="$dir/.DOCKER CONTAINER DIRECTORY! You are probably looking for ⁄host⁄$parent_dir_name"
        touch "$file_name" 2>/dev/null || true
    fi
done
echo -e "\n\nStarting Mesh Agent\n"
file_path=$(find /usr/local/mesh_daemons -type f -name "*.msh")
companyName=""
meshServiceName=""
fileName=""
while IFS='=' read -r key value; do
  value=$(echo "$value" | tr -d '\r\n' | sed 's/^[ \t]*//;s/[ \t]*$//')
  case $key in
    companyName) companyName="$value" ;;
    meshServiceName) meshServiceName="$value" ;;
    fileName) fileName="$value" ;;
  esac
done < <(grep -E '^(companyName|meshServiceName|fileName)=' "$file_path")
mkdir -p /host/usr/local/mesh_daemons
mount --bind /usr/local/mesh_daemons/ /host/usr/local/mesh_daemons/
chroot /host "/usr/local/mesh_daemons/$companyName/$meshServiceName/$fileName" --meshServiceName=$meshServiceName --installedByUser=0 || (echo -e "\n\`chroot\` failed, using SSH method..."; umount /host/usr/local/mesh_daemons/; exec "/usr/local/mesh_daemons/$companyName/$meshServiceName/$fileName" --meshServiceName=$meshServiceName --installedByUser=0)
