FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive

# Install core cloud virtualization dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    qemu-utils \
    wget \
    cloud-image-utils \
    && rm -rf /var/lib/apt/lists/*

# Create working directories
RUN mkdir -p /seed

# Download the Official Debian 11 Cloud qcow2 Image
RUN wget -q https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2 -O /debian-base.qcow2

# Configure Cloud-Init automated provisioning
RUN cat > /seed/user-data << 'CLOUDCFG'
#cloud-config
hostname: walksysdev
prefer_fqdn_over_hostname: true

users:
  - name: root
    plain_text_passwd: "root"
    lock_passwd: false
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL

ssh_pwauth: true
disable_root: false
chpasswd:
  expire: false
CLOUDCFG

RUN touch /seed/meta-data
RUN cloud-localds /seed.img /seed/user-data /seed/meta-data

# Create startup script using heredoc (NOT echo with \n escapes)
RUN cat > /start-vps.sh << 'SCRIPT'
#!/bin/bash
set -e

# Parse user runtime specifications via docker environment flags
VM_RAM="${RAM:-4G}"
VM_CORES="${CORES:-2}"
VM_DISK_SIZE="${DISK_SIZE:-20G}"

echo "⚙️ Provisioning Headless Virtual Private Server..."
echo "   -> Target User   : root"
echo "   -> Disk Name     : walksysdev.qcow2 | Capacity=${VM_DISK_SIZE}"
echo "   -> Virtual Specs : ${VM_RAM} RAM | ${VM_CORES} CPU Cores"

# Initialize the persistent disk from the raw base template if it does not exist
if [ ! -f /walksysdev.qcow2 ]; then
    cp /debian-base.qcow2 /walksysdev.qcow2
    qemu-img resize /walksysdev.qcow2 "${VM_DISK_SIZE}" > /dev/null
fi

echo "🚀 Booting Debian CLI VM via QEMU..."
echo "========================================================================="
echo " ✅ VPS Virtual Cloud Engine is Active!"
echo " 🔐 Direct SSH Network : ssh root@localhost -p 2026 (Pass: root)"
echo "========================================================================="

# Boot the Qemu VM with VNC totally disabled
qemu-system-x86_64 \
    -drive file=/walksysdev.qcow2,format=qcow2,if=virtio \
    -drive file=/seed.img,format=raw,if=virtio \
    -m "${VM_RAM}" \
    -smp "${VM_CORES}" \
    -device virtio-net,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::2026-:22 \
    -vnc none \
    -nographic
SCRIPT

RUN chmod +x /start-vps.sh

EXPOSE 2026

CMD ["/start-vps.sh"]
