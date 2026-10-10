# colab-strata

A CLI-based proof of concept for running **Qwen3.8-Flash-Next** with [Strata](https://github.com/Niko1221/Strata) on a Google Colab GPU. The [official Colab CLI](https://github.com/googlecolab/google-colab-cli) provides an SSH tunnel to Strata's Web UI and OpenAI-compatible API on your local machine, without creating a notebook.

## Requirements

- A Google Colab account with sufficient compute units and access to an **A100 High-RAM** runtime (GPU availability is not guaranteed).
- **Linux or macOS**, or **Windows with WSL2** (the Colab CLI does not officially support native Windows).
- [`mise`](https://mise.jdx.dev/), `git`, OpenSSH (`ssh` and `ssh-keygen`), and `curl`.
- Approximately **80 GB or more of free disk space on the Colab VM** for Strata and the model.

## Getting started

```bash
git clone https://github.com/naoki1001/colab-strata.git
cd colab-strata
mise install
mise run up
mise run status
```

On first use, follow the Google sign-in prompt. `up` allocates the runtime, starts Strata installation in the background, and establishes a local SSH tunnel. **It returns before the model is ready.** Run `mise run status` to see installation logs and API readiness.

Once ready, connect to:

- **Web UI (Chat / Monitor / About):** http://127.0.0.1:8080/
- **OpenAI-compatible API:** http://127.0.0.1:8080/v1

Test an inference request:

```bash
curl -sS http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen","messages":[{"role":"user","content":"Say hello in Japanese."}],"max_tokens":64}'
```

Check compute units and stop the session when finished:

```bash
mise run usage
mise run down
```

Disconnecting the SSH tunnel alone does **not** necessarily stop the Colab runtime or its compute-unit consumption.

## Configuration

The following environment variables are optional:

| Variable | Default | Purpose |
| --- | --- | --- |
| `COLAB_SESSION` | `colab-strata` | Colab session name |
| `COLAB_GPU` | `A100` | Requested GPU |
| `COLAB_HIGH_MEM` | `1` | Request High-RAM runtime |
| `COLAB_LOCAL_PORT` | `8080` | Local port for the Web UI and API |

Strata chooses its recommended quantization and context length for the available hardware. Vision input is enabled.

## Limitations

- **Experimental:** this setup has not yet been verified end-to-end on an allocated Colab GPU.
- Every fresh Colab runtime downloads and sets up the model again; no persistent model cache is configured.
- The allocated runtime must support Colab CLI SSH access. If `up` fails, check `mise run usage` and `mise run status` to confirm the session was released.
- The local API binds to `127.0.0.1`. On WSL2, access from Windows also depends on WSL networking settings.
- Inference runs on Google infrastructure. Prompts and outputs are not guaranteed to be inaccessible to the provider. The current SSH configuration disables host-key verification for the ephemeral VM.

## License

[MIT](LICENSE)
