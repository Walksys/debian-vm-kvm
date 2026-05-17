# 🐳 Enterprise Debian VM inside Docker (KVM/QEMU)

An advanced, cloud-optimized **Debian 11 (Bullseye) Virtual Machine** operating seamlessly inside a Docker container via QEMU hypervisor orchestration. This image bypasses standard interactive OS setups by launching a pre-baked cloud image instantly, allowing fully customizable dynamic hardware profiles (RAM, CPU, Storage) and direct user provisioning at runtime.


## ⚡ Core Engine Capabilities

* 🚀 **Instant Boot Architecture:** Powered by official Debian Cloud `.qcow2` image layers—zero setup waiting times.
* 🖥️ **HTML5 VNC Interface:** Integrated clientless VNC desktop streaming over standard WebSockets via **noVNC**.
* ⚙️ **Dynamic Sizing Configurations:** Control compute resources and automatically expand storage limits via initialization flags.
* 🔐 **Automated Secure Provisioning:** Built-in **cloud-init** configurations to inject specific deployment profiles instantly.

## 🔐 **Quick Access Credentials** 

* **Default Username**: root
* **Default Password**: root
* **Access**: root / root

## 🚀 Usage & Deployment Profiles

Fire up your Virtual Private Server (VPS) by passing your desired hardware capacity directly to the `docker run` statement through environment variables (`-e`):

### ⚡ Balanced VPS Profile (4GB RAM, 2 CPU Cores, 25GB Storage Disk)

```bash
docker run -it \
  -p 2026:2026 \
  -e RAM=4G \
  -e CORES=2 \
  -e DISK_SIZE=25G \
  walksysdev/debian-vm-kvm

```

### 💻 Performance Profile (8GB RAM, 4 CPU Cores, 50GB Storage Disk)

```bash
docker run -it \
  -p 2026:2026 \
  -e RAM=8G \
  -e CORES=4 \
  -e DISK_SIZE=50G \
  walksysdev/debian-vm-kvm

```

### 📦 Fallback Standard Mode (Defaults: 4GB RAM, 2 Cores, 20GB Storage Disk)

```bash
docker run -it -p 2026:2026 walksysdev/debian-vm-kvm

```


## 🌐 Network Routing & Access Protocols

Once the container initialization is running, you can interact with your newly spawned Debian machine through your web browser or terminal:

| Access Type | Protocol / Command | Default Credentials |
| --- | --- | --- |
| 🔐 **Secure SSH Console** | `ssh root@localhost -p 2026` | Username: `root` <br>

<br> Password: `root` |


## 🛠️ Infrastructure Build Management

If you want to pull down the source configurations or compile the container manually:

### Image Download Command

```bash
docker pull walksysdev/debian-vm-kvm:latest

```

### Manual Compilation Pipeline

```bash
docker build -t walksysdev/debian-vm-kvm .

```


*Maintained with absolute precision by 🚀 [@walksysdev](https://hub.docker.com/r/walksysdev).*
