FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive

# Install core cloud virtualization dependencies (Removed noVNC and websockify)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    qemu-utils \
    wget \
    cloud-image-utils \
    && rm -rf /var/lib/apt/lists/*

# Create working directories properly to avoid construction errors
RUN mkdir -p /seed

# Download the Official Debian 11 Cloud qcow2 Image directly
RUN wget -q https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2 -O /debian-base.qcow2

# Configure Cloud-Init automated provisioning for the 'walksysdev' VPS user
RUN bash -c 'cat > /seed/user-data' <<EOF
#cloud-config
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
EOF

RUN touch /seed/meta-data
RUN cloud-localds /seed.img /seed/user-data /seed/meta-data

# Create dynamic VPS execution startup script (Terminal ONLY)
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Parse user runtime specifications via docker environment flags\n\
VM_RAM="${RAM:-4G}"\n\
VM_CORES="${CORES:-2}"\n\
VM_DISK_SIZE="${DISK_SIZE:-20G}"\n\
\n\
echo "⚙️ Provisioning Headless Virtual Private Server..."\n\
echo "   -> Target User   : root"\n\
echo "   -> Disk Name     : walksysdev.qcow2 | Capacity=${VM_DISK_SIZE}"\n\
echo "   -> Virtual Specs : ${VM_RAM} RAM | ${VM_CORES} CPU Cores"\n\
\n\
# Initialize the persistent disk from the raw base template if it does not exist\n\
if [ ! -f /walksysdev.qcow2 ]; then\n\
    cp /debian-base.qcow2 /walksysdev.qcow2\n\
    qemu-img resize /walksysdev.qcow2 "${VM_DISK_SIZE}" > /dev/null\n\
fi\n\
\n\
echo "🚀 Booting Debian CLI VM via QEMU..."\n\
echo "========================================================================="\n\
echo " ✅ VPS Virtual Cloud Engine is Active!"\n\
echo " 🔐 Direct SSH Network : ssh rootv@localhost -p 2026 (Pass: password)"\n\
echo "========================================================================="\n\
\n\
# Boot the Qemu VM with VNC totally disabled (-vnc none)\n\
qemu-system-x86_64 \\\n\
    -drive file=/walksysdev.qcow2,format=qcow2,if=virtio \\\n\
    -drive file=/seed.img,format=raw,if=virtio \\\n\
    -m "${VM_RAM}" \\\n\
    -smp "${VM_CORES}" \\\n\
    -device virtio-net,netdev=net0 \\\n\
    -netdev user,id=net0,hostfwd=tcp::2026-:22 \\\n\
    -vnc none \\\n\
    -nographic\n' > /start-vps.sh && chmod +x /start-vps.sh

# Only expose SSH networking port now
EXPOSE 2026

CMD ["/start-vps.sh"]
