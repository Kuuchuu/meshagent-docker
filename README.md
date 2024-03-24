MeshCentral Agent in a Debian Docker container. Created for use on NixOS, but should work wherever Docker does (in fact, should work better on non-immutable/declarative systems).
Images will be built for use later on, for now clone the repo, copy and edit the .env file, and built the image. Usage shown below.

After building/starting the image/container, you will want to run `docker logs meshagent` and check for further instructions on adding the container's SSH key to the host system's authorized_keys file, for passwordless terminal access in MeshCentral.
If using the root user as the Mesh User, you will need to ensure root SSH access is allowed. You can restrict the root SSH access to the host system's IP address. Instructions on how to do so on NixOS should be in the Docker container logs.

.env file takes
  - Your MeshCentral server url
  - A Mesh agent token (can be obtained from clicking "Add Agent" > "Linux / BSD". Copy the token enclosed in the single quote characters inside the installation command, include the quote characters in the .env file.)
  - A Mesh User (for connecting via SSH to the host system, defaults to root)

## Usage:
```
git clone https://github.com/Kuuchuu/meshagent-docker.git
cd meshagent-docker
cp .env.example .env
nano .env
docker compose up --build
docker logs meshagent
```

### Known Issues:
  - **Desktop tab in MeshCentral does not work, exploring options**
  - Files tab in MeshCentral does not connect directly to host system when not using chroot mode. Workaround implemented (/host directory in Files tab)

### To Do:
  - [ ] Alpine Image
  - [ ] More Environment Variables
  - [ ] Pre-built Images
