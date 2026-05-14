# ollama-deploy <!-- omit from toc -->

Deploy ollama locally using Docker

## Table of Contents <!-- omit from toc -->
- [Requirements](#requirements)
  - [Software Requirements](#software-requirements)
  - [Optional Requirements](#optional-requirements)
  - [Hardware Requirements](#hardware-requirements)
    - [NVIDIA](#nvidia)
    - [AMD](#amd)
- [Running based on environment](#running-based-on-environment)
  - [NVIDIA](#nvidia-1)
  - [AMD](#amd-1)

## Requirements

### Software Requirements

1. `docker`
2. `docker-compose`
3. `nvidia` drivers (optional)
4. `nvidia-container-toolkit` (optional)

**Run the following to check for missing requirements:**
```
docker --version
docker compose version
nvidia-smi
nvidia-ctk --version
```

### Optional Requirements

1. `curl` - for downloads
2. `git` - for repo management
3. `jq` - for JSON parsing in scripts
4. `htop` / `nvtop` - for monitoring (nvtop shows GPU usage nicely)

### Hardware Requirements

This homelab was done on the following systems

#### NVIDIA
```
OS: Fedora Linux 42 (Workstation Edition) x86_64
CPU: AMD Ryzen 7 3700X (16) @ 4.43 GHz
GPU: NVIDIA GeForce RTX 2070 SUPER [Discrete]
Memory: 16 GiB
Swap: 8.00 GiB
```

#### AMD
```
OS: Fedora Linux 43 (Workstation Edition) x86_64
CPU: AMD Ryzen AI 9 365 (20) @ 2.00 GHz
GPU: AMD Radeon 880M Graphics [Integrated]
Memory: 24 GiB
Swap: 8 GiB
```

## Running based on environment

### NVIDIA
```
docker compose -f compose.yml -f compose.nvidia.yml --env-file ./env/dev/.env up
```

### AMD
```
docker compose -f compose.yml -f compose.amd.yml --env-file ./env/dev/.env up
```

