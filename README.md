# ollama-deploy <!-- omit from toc -->

Deploy ollama locally using Docker

## Table of Contents <!-- omit from toc -->
- [Requirements](#requirements)
  - [Software Requirements](#software-requirements)
  - [Optional Requirements](#optional-requirements)
  - [Hardware Requirements](#hardware-requirements)

## Requirements

### Software Requirements

1. `docker`
2. `docker-compose`
3. `nvidia` drivers
4. `nvidia-container-toolkit`

**Run the following to check for missing requirements:**
```
docker --version
docker compose version
nvidia-smi
nvidia-ctk --version
```

### Optional Requirements

1. `curl` - for downloads
2. `git` - for repo management (obviously)
3. `jq` - for JSON parsing in scripts
4. `htop` / `nvtop` - for monitoring (nvtop shows GPU usage nicely)

### Hardware Requirements

This homelab was done with the following system

```
OS: Fedora Linux 42 (Workstation Edition) x86_64
CPU: AMD Ryzen 7 3700X (16) @ 4.43 GHz
GPU: NVIDIA GeForce RTX 2070 SUPER [Discrete]
Memory: 6.87 GiB / 15.55 GiB (44%)
Swap: 126.87 MiB / 8.00 GiB (2%)
Disk (/): 278.08 GiB / 475.35 GiB (58%) - btrfs
```

