A temporary repo as part of ongoing development. Tested on a Digital Ocean droplet (Docker will need installing on your droplet).

Clone then build and start with:

```
docker build -t bp .

docker run -it --device=/dev/kvm --cap-add=net_admin --network host bp
```

To use a custom image instead of the default, mount the image in `img/` inside the container (`.zip` files and `.img` files are both supported).

Override default configuration options by passing environment variables during the Docker run process:

`docker run -it -e "DISK=32G" --device=/dev/kvm --cap-add=net_admin --network host bp`

Defaults:

```
CORES=4
DISK=8G
MEM=512M
```

At present, only one instance can be running at a time. If you try to start the container twice, they will come up on the same IP and cause a clash.
