# colab-strata

Run [Strata](https://github.com/Niko1221/Strata) with **Qwen3.8-Flash-Next** on a Google Colab GPU from the command line. The [official Colab CLI](https://github.com/googlecolab/google-colab-cli) connects Strata's Web UI and OpenAI-compatible API to localhost over SSH, without creating a notebook.

## Requirements

- Google Colab access with sufficient compute units and an available **A100 High-RAM** runtime. Availability is not guaranteed.
- Linux or macOS; Windows via WSL2 (the Colab CLI does not officially support native Windows).
- [`mise`](https://mise.jdx.dev/), `git`, OpenSSH (`ssh` and `ssh-keygen`), and `curl`.
- Sufficient free storage on the Colab VM for the model and setup files (approximately **90 GB or more** recommended).

## Getting started

```bash
git clone https://github.com/naoki1001/colab-strata.git
cd colab-strata
mise install
mise run up
mise run status
```

Follow the Google sign-in prompt on first use. `up` allocates a Colab runtime, launches Strata setup in the background, and opens the SSH tunnel; **it does not wait until the model is ready**. Check progress with `mise run status` until the API reports `ready`.

Once ready:

- **Web UI (Chat / Monitor / About):** http://127.0.0.1:8080/
- **OpenAI-compatible API:** http://127.0.0.1:8080/v1

For example, send a chat request:

```bash
curl -fsS http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen","messages":[{"role":"user","content":"Say hello in Japanese."}],"max_tokens":64}'
```

Check remaining compute units and stop the runtime when finished:

```bash
mise run usage
mise run down
mise run status
```

Stopping the SSH tunnel alone does not necessarily release the Colab runtime or stop compute-unit consumption.

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `COLAB_SESSION` | `colab-strata` | Colab session name |
| `COLAB_GPU` | `A100` | Requested GPU |
| `COLAB_HIGH_MEM` | `1` | Request High-RAM runtime |
| `COLAB_LOCAL_PORT` | `8080` | Local port for the Web UI and API |

Strata chooses quantization and context length based on the allocated hardware. Vision input is enabled.

## Verified setup

This PoC has been tested end-to-end on **Colab A100-SXM4-80GB** with Strata `v0.1.41` and Qwen3.8-Flash-Next (`IQ3_XXS`, 131,072-token context, vision enabled), including CLI provisioning, local API inference, Web UI image understanding, and runtime shutdown. A fresh session was also provisioned successfully without manual changes to the remote VM.

## Limitations

- Each new Colab runtime downloads and prepares the model again; no persistent cache is configured.
- The runtime must support SSH through the Colab CLI. GPU allocation and compute-unit consumption depend on your Colab account and availability.
- The API binds to localhost. Access from Windows to a service running under WSL2 depends on WSL networking configuration.
- Inference runs on Google-managed infrastructure. The SSH connection uses relaxed host-key verification for the ephemeral VM; it does not guarantee confidentiality from the infrastructure provider.

## License

[MIT](LICENSE)
