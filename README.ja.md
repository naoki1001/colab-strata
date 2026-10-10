# colab-strata

[English](README.md) | [日本語](README.ja.md)

Google ColabのGPU上で、[Strata](https://github.com/Niko1221/Strata)を使ってQwen3.8-Flash-Nextを実行するPoCです。[公式Colab CLI](https://github.com/googlecolab/google-colab-cli)を利用し、ノートブックを作成せずに、ローカルからSSH経由でStrataのWeb UIとOpenAI互換APIにアクセスできます。

## 前提条件

- A100 High-RAMを利用できるGoogle Colabアカウント（Compute Unitsの残量やランタイムの空き状況によっては利用できません）
- LinuxまたはmacOS。WindowsではWSL2を使用（Colab CLIはWindowsネイティブ環境を公式にはサポートしていません）
- [`mise`](https://mise.jdx.dev/)、`git`、OpenSSH（`ssh`、`ssh-keygen`）、`curl`
- Colab VM上に約90 GB以上の空き容量

## クイックスタート

```bash
git clone https://github.com/naoki1001/colab-strata.git
cd colab-strata
mise install
mise run up
mise run status
```

初回実行時はGoogleアカウントでの認証が必要です。`mise run up`を実行するとColabランタイムを確保し、StrataのセットアップとSSH接続を開始します。モデルの起動完了は待たないため、`mise run status`で進捗を確認してください。

起動後は以下のURLからアクセスできます。

- **Web UI（Chat / Monitor / About）**：http://localhost:8080/
- **OpenAI互換API**：http://localhost:8080/v1

APIの動作確認には、次のコマンドを実行します。

```bash
curl -fsS http://localhost:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen","messages":[{"role":"user","content":"Say hello in Japanese."}],"max_tokens":64}'
```

Compute Unitsの残量を確認し、利用後はランタイムを停止します。

```bash
mise run usage
mise run down
mise run status
```

SSHトンネルを切断しただけではColabランタイムが解放されるとは限りません。利用後は`mise run down`を実行してください。

## 設定

| 環境変数 | デフォルト値 | 説明 |
| --- | --- | --- |
| `COLAB_SESSION` | `colab-strata` | Colabセッション名 |
| `COLAB_GPU` | `A100` | 要求するGPU |
| `COLAB_HIGH_MEM` | `1` | High-RAMランタイムを要求（`1`で有効） |
| `COLAB_LOCAL_PORT` | `8080` | Web UIとAPIのローカルポート |

Strataは割り当てられたハードウェアに応じて量子化形式とコンテキスト長を自動選択します。画像入力（Vision）も有効です。

## 動作確認環境

Colab A100-SXM4-80GBで、Strata `v0.1.41`とQwen3.8-Flash-Next（`IQ3_XXS`、コンテキスト長131,072トークン、Vision有効）の動作を確認しました。CLIからのセットアップ、API推論、Web UIでの画像理解、ランタイム停止を検証済みです。新規セッションでも、Colab VMに手動で変更を加えずに起動できることを確認しています。

## 制限事項

- Colabランタイムを新しく作成するたびに、モデルのダウンロードと準備が必要です。モデルのキャッシュは永続化していません。
- ColabランタイムがColab CLI経由のSSH接続に対応している必要があります。
- APIはローカル側のループバックアドレスで待ち受けます。WindowsからWSL2上のサービスにアクセスできるかどうかは、WSLのネットワーク設定に依存します。
- 推論はGoogleが管理するインフラ上で実行されるため、Googleからの会話内容の秘匿は保証されません。
- 一時的なColab VMへのSSH接続では、ホストキー検証を無効化しています。

## ライセンス

[MIT](LICENSE)
