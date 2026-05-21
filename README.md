# ollama-deploy <!-- omit from toc -->

A Docker Compose setup for running [Ollama](https://ollama.com) locally with a full supporting stack: a chat UI, a transparent metrics proxy, and a pre-wired Prometheus + Grafana monitoring stack.

## Table of Contents <!-- omit from toc -->
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
  - [Models](#models)
  - [Ports and credentials](#ports-and-credentials)
- [Running](#running)
  - [CPU](#cpu)
  - [NVIDIA](#nvidia)
  - [AMD](#amd)
- [Endpoints](#endpoints)
- [Monitoring](#monitoring)
  - [How it works](#how-it-works)
  - [Grafana dashboard](#grafana-dashboard)
- [Tested hardware](#tested-hardware)
    - [NVIDIA](#nvidia-1)
    - [AMD](#amd-1)

## Architecture

```mermaid
graph TB
    User(["👤 User"])

    subgraph Docker["Docker Compose Stack"]
        OpenWebUI["open-webui\n:8080"]
        OllamaMetrics["ollama-metrics\n:11435\n(transparent proxy)"]
        Ollama["ollama\n:11434"]
        ModelManager["model-manager\n(init container)"]
        Prometheus["prometheus\n:9090"]
        Grafana["grafana\n:3000"]
    end

    subgraph GPU["Hardware (GPU)"]
        NVIDIA["NVIDIA / AMD / CPU"]
    end

    subgraph Volumes["Named Volumes"]
        OllamaVol[("ollama")]
        OpenWebUIVol[("open-webui")]
        PrometheusVol[("prometheus")]
        GrafanaVol[("grafana")]
    end

    User -->|"chat / API"| OpenWebUI
    User -->|"dashboards"| Grafana

    OpenWebUI -->|"LLM requests"| OllamaMetrics
    OllamaMetrics -->|"proxied requests"| Ollama
    OllamaMetrics -->|"/metrics scrape"| Prometheus
    Prometheus -->|"data source"| Grafana

    ModelManager -->|"pull models on startup"| Ollama
    Ollama <-->|"inference"| NVIDIA

    Ollama --- OllamaVol
    OpenWebUI --- OpenWebUIVol
    Prometheus --- PrometheusVol
    Grafana --- GrafanaVol
```

The stack has five long-running services and one init container:

| Service            | Role                                                                         |
| ------------------ | ---------------------------------------------------------------------------- |
| **ollama**         | Runs the LLM inference engine and exposes the Ollama API                     |
| **model-manager**  | Init container that syncs the model list on startup then exits               |
| **ollama-metrics** | Transparent HTTP proxy in front of Ollama; exposes `/metrics` for Prometheus |
| **open-webui**     | Web-based chat interface; routes all requests through ollama-metrics         |
| **prometheus**     | Scrapes metrics from ollama-metrics every 15 s                               |
| **grafana**        | Visualizes Prometheus data; ships with a pre-built Ollama dashboard          |

## Prerequisites

| Tool                                                                                                               | Required | Purpose                                        |
| ------------------------------------------------------------------------------------------------------------------ | -------- | ---------------------------------------------- |
| [`docker`](https://docs.docker.com/get-docker/)                                                                    | Yes      | Container runtime                              |
| [`docker compose`](https://docs.docker.com/compose/install/) v2+                                                   | Yes      | Multi-container orchestration                  |
| [`nvidia-container-toolkit`](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) | No       | NVIDIA GPU passthrough                         |
| `curl`                                                                                                             | No       | Downloading models or testing the API manually |
| `jq`                                                                                                               | No       | Parsing JSON output from the Ollama API        |
| `htop` / `nvtop`                                                                                                   | No       | System and GPU usage monitoring                |

Verify your installation:
```sh
docker --version
docker compose version
nvidia-smi          # NVIDIA only
nvidia-ctk --version  # NVIDIA only
```

## Configuration

All configuration lives in `env/dev/.env`. Copy and edit it before running.

### Models

The `OLLAMA_MODELS` variable is a comma-separated list of models to pull. The **model-manager** init container runs on every startup and keeps the local model store in sync with this list — it pulls anything missing and removes anything no longer listed.

```sh
# env/dev/.env
OLLAMA_MODELS="llama3.2:3b,qwen3.5:4b,gemma3:4b,mistral:7b,tinyllama:latest"
```

Browse available models at [ollama.com/library](https://ollama.com/library).

### Ports and credentials

All host-side ports and the Grafana admin password are configurable in the same file:

| Variable                     | Default | Description                              |
| ---------------------------- | ------- | ---------------------------------------- |
| `OLLAMA_HOST_PORT`           | `11434` | Ollama API                               |
| `OLLAMA_METRICS_HOST_PORT`   | `11435` | ollama-metrics proxy                     |
| `OPEN_WEBUI_HOST_PORT`       | `8080`  | Open WebUI                               |
| `PROMETHEUS_HOST_PORT`       | `9090`  | Prometheus                               |
| `GF_HOST_PORT`               | `3000`  | Grafana                                  |
| `GF_SECURITY_ADMIN_PASSWORD` | `admin` | Grafana admin password — **change this** |

---

## Running

Choose the compose override that matches your hardware. The base `compose.yml` is always included.

### CPU

```sh
docker compose -f compose.yml -f compose.cpu.yml --env-file ./env/dev/.env up
```

### NVIDIA

Requires `nvidia-container-toolkit`. See [NVIDIA's installation guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).

```sh
docker compose -f compose.yml -f compose.nvidia.yml --env-file ./env/dev/.env up
```

### AMD

Uses the `ollama:rocm` image for ROCm-based GPU acceleration.

```sh
docker compose -f compose.yml -f compose.amd.yml --env-file ./env/dev/.env up
```

---

## Endpoints

Once the stack is up, the following are available on localhost:

| Service        | URL                    | Description                                   |
| -------------- | ---------------------- | --------------------------------------------- |
| Open WebUI     | http://localhost:8080  | Chat interface for interacting with models    |
| Ollama API     | http://localhost:11434 | Ollama REST API                               |
| ollama-metrics | http://localhost:11435 | Proxied Ollama API + `/metrics` endpoint      |
| Prometheus     | http://localhost:9090  | Metrics storage and query UI                  |
| Grafana        | http://localhost:3000  | Dashboards (default login: `admin` / `admin`) |

---

## Monitoring

### How it works

Ollama does not expose a native Prometheus metrics endpoint. This setup uses [ollama-metrics](https://github.com/NorskHelsenett/ollama-metrics) as a transparent HTTP proxy that sits between Open WebUI and Ollama. Every request passes through it unchanged, but ollama-metrics instruments each one and exposes the aggregated data at `/metrics` for Prometheus to scrape every 15 seconds.

### Grafana dashboard

A pre-built **Ollama Overview** dashboard is provisioned automatically on startup via Grafana's file-based provisioning — no manual import or setup needed. It is available immediately at http://localhost:3000.

The dashboard covers:

| Panel                                | Description                                                 |
| ------------------------------------ | ----------------------------------------------------------- |
| Request Rate                         | Requests per second hitting the Ollama API                  |
| Request Duration                     | Overall latency distribution across all requests            |
| Request Duration p95 (by Model)      | 95th-percentile latency broken down per model               |
| Token Generation Time p95 (by Model) | How long generation takes at the 95th percentile, per model |
| Token Generation Rate (by Model)     | Tokens generated per second, per model                      |
| Generated Tokens by Model            | Total completion tokens over time, per model                |
| Prompt Tokens by Model               | Total prompt tokens over time, per model                    |
| Token Prompt Rate (by Model)         | Prompt tokens processed per second, per model               |
| Average Time per Token by Model      | Mean milliseconds per generated token, per model            |

<img src="docs/grafana_screenshot_01.png" alt="Ollama Overview dashboard" width="100%">

---

## Tested hardware

This setup has been validated on the following machines:

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
