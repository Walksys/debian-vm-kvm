FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive

# Install core cloud virtualization and web-access dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    qemu-utils \
    wget \
    python3 \
    novnc \
    websockify \
    cloud-image-utils \
    && rm -rf /var/lib/apt/lists/*

# Download the Official Debian 11 Cloud qcow2 Image directly as our master template
RUN wget -q https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2 -O /debian-base.qcow2

# Configure Cloud-Init automated provisioning for the 'walksysdev' VPS user
RUN mkdir -p /seed
RUN bash -c 'cat > /seed/user-data' <<EOF
#cloud-config
users:
  - name: root
    plain_text_passwd: "password"
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

# Create dynamic VPS execution startup script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Parse user runtime specifications via docker environment flags\n\
VM_RAM="${RAM:-4G}"\n\
VM_CORES="${CORES:-2}"\n\
VM_DISK_SIZE="${DISK_SIZE:-20G}"\n\
\n\
echo "⚙️ Provisioning Virtual Private Server..."\n\
echo "   -> Target User   : root"\n\
echo "   -> Disk Name     : walksysdev.qcow2 | Provisioned Capacity=${VM_DISK_SIZE}"\n\
echo "   -> Virtual Specs : Allocation=${VM_RAM} RAM | Compute=${VM_CORES} CPU Cores"\n\
\n\
# Initialize the persistent disk from the raw base template if it doesn not exist\n\
if [ ! -f /walksysdev.qcow2 ]; then\n\
    cp /debian-base.qcow2 /walksysdev.qcow2\n\
    qemu-img resize /walksysdev.qcow2 "${VM_DISK_SIZE}" > /dev/null\n\
fi\n\
\n\
# Boot the Qemu VM directly using the expanded qcow2 virtual disk partition\n\
qemu-system-x86_64 \\\n\
    -drive file=/walksysdev.qcow2,format=qcow2,if=virtio \\\n\
    -drive file=/seed.img,format=raw,if=virtio \\\n\
    -m "${VM_RAM}" \\\n\
    -smp "${VM_CORES}" \\\n\
    -device virtio-net,netdev=net0 \\\n\
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \\\n\
    -vnc 0.0.0.0:0 \\\n\
    -nographic &\n\
\n\
sleep 3\n\
# Fire up the noVNC Web UI stream connection gateway\n\
websockify --web /usr/share/novnc/ 6080 localhost:5900 &\n\
\n\
echo "========================================================================="\n\
echo " ✅ VPS Virtual Cloud Engine is Active!"\n\
echo " 🌐 Remote Web VNC Access : http://localhost:6080/vnc.html"\n\
echo " 🔐 Direct SSH Network     : ssh root@localhost -p 2222 (Pass: password)"\n\
echo "========================================================================="\n\
tail -f /dev/null\n' > /start-vps.sh && chmod +x /start-vps.sh

EXPOSE 6080 2222

CMD ["/start-vps.sh"]
