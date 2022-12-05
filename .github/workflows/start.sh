#!/usr/bin/env bash
ARCH=$(uname -p)
RANDOM_PORT=$((RANDOM % 9999))

# Enable hardware acceleration if available
if ! ls /dev/kvm &> /dev/null; then
    echo "KVM hardware acceleration unavailable. Pass --device /dev/kvm in your Docker run command."
    exit 1
fi

# Set default cores to same as system if not specified
if [ ! -n "$CORES" ]; then
    CORES=$(nproc --all)
fi

# Set default space to same as available on system if not specified
if [ ! -n "$DISK" ]; then
    DISK=$(df -Ph . | tail -1 | awk '{print $4}')
fi

# Set default memory to same as system if not specified
if [ ! -n "$MEM" ]; then
    MEM=$(free -m | grep -oP '\d+' | head -n 1)M
fi

# Decompress any files passed in as images
if [ -f img/*.zip ]; then
    echo "Decompressing image files..."
    unzip -o *.zip
fi

# If user has provided another image file, use that instead of the default
if [ -f img/*.img ]; then
    echo "Converting image to qcow2..."
    qemu-img convert -f raw -O qcow2 img/*.img balena-source.qcow2
fi

# If image is not yet generated
if [ ! -f balena.qcow2 ]; then
    echo "Creating VM image..."
    qemu-img create -f qcow2 -F qcow2 -b balena-source.qcow2 balena.qcow2 "$DISK"
fi

if [ "$ARCH" == "aarch64" ]
then
    QEMU="qemu-system-aarch64"
elif [ "$ARCH" == "x86_64" ]
then
    QEMU="qemu-system-x86_64"
else
  echo "Architecture not supported."
  exit 1
fi

echo "Starting BalenaVirt Machine..."

# Start
exec "$QEMU" \
    -nographic \
    -machine q35 \
    -accel kvm \
    -cpu max \
    -smp "$CORES" \
    -m "$MEM" \
    -drive if=pflash,format=raw,unit=0,file=/usr/share/OVMF/OVMF_CODE.fd \
    -drive if=virtio,format=qcow2,unit=0,file=balena.qcow2 \
    -net nic,model=virtio,macaddr=52:54:00:b9:57:b8 \
    -net user \
    -netdev user,id=n0,hostfwd=tcp::1$RANDOM_PORT-:22,hostfwd=tcp::2$RANDOM_PORT-:2375 \
    -netdev socket,id=vlan,mcast=230.0.0.1:1234 \
    -device virtio-net-pci,netdev=n0 \
    -device virtio-net-pci,netdev=vlan
