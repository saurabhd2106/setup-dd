# Ubuntu Dev VM Setup Scripts

This folder contains modular scripts for setting up an Ubuntu desktop VM with:

- VS Code
- Google Chrome
- Docker Engine, Docker Buildx, and Docker Compose plugin
- Terraform
- Ansible
- kubectl
- Graphviz (`dot`)
- Azure CLI (`az`)
- AWS CLI (`aws`)
- Python 3 (`python3`, `pip3`, `venv`, `pipx`, Poetry, `uv`)
- Java (`java`, `javac`) — OpenJDK 21 by default
- Node.js (`node`, `npm`, Corepack `yarn` / `pnpm`) — NodeSource LTS
- Maven (`mvn`)
- Gradle (`gradle`) — official binary distribution
- Go (`go`) — official tarball
- Rust (`rustc`, `cargo`) — rustup
- Ruby (`ruby`, `gem`, `bundler`)
- PHP (`php`, `composer`)
- .NET SDK (`dotnet`) — Ubuntu apt; prefers newest available SDK (10.0 when present)
- Claude Code (`claude`) — separate installer
- Databricks CLI (`databricks`) — separate installer
- GitHub Copilot CLI (`copilot`) — separate installer
- Playwright (`playwright`) — separate installer
- Playwright MCP (`@playwright/mcp`) — separate installer
- Cypress (`cypress`) — separate installer

The scripts are written for Ubuntu with `apt` and use official upstream package repositories where appropriate.

## Prerequisites

- Ubuntu 22.04 / 24.04 or newer
- `amd64` VM for Google Chrome
- A user with `sudo` access
- Internet access from the VM

## Run Everything

From the repository root:

```sh
bash setup-dd/setup.sh
```

The master script runs each installer in this order:

```text
vscode, chrome, docker, terraform, ansible, kubectl, graphviz, azure-cli, aws-cli,
python, java, node, maven, gradle, go, rust, ruby, php, dotnet
```

Each installer checks whether the tool is already installed before making changes.

## Install Only Some Tools

Use `--only` with a comma-separated list:

```sh
bash setup-dd/setup.sh --only docker,terraform,kubectl
```

Available tool names:

```text
vscode, chrome, docker, terraform, ansible, kubectl, graphviz, azure-cli, aws-cli,
python, java, node, maven, gradle, go, rust, ruby, php, dotnet
```

## Skip Tools

Use `SKIP_<TOOL>=true`:

```sh
SKIP_CHROME=true SKIP_VSCODE=true bash setup-dd/setup.sh
```

Supported skip variables:

```text
SKIP_VSCODE
SKIP_CHROME
SKIP_DOCKER
SKIP_TERRAFORM
SKIP_ANSIBLE
SKIP_KUBECTL
SKIP_GRAPHVIZ
SKIP_AZURE_CLI
SKIP_AWS_CLI
SKIP_PYTHON
SKIP_JAVA
SKIP_NODE
SKIP_MAVEN
SKIP_GRADLE
SKIP_GO
SKIP_RUST
SKIP_RUBY
SKIP_PHP
SKIP_DOTNET
```

## Run Individual Installers

Each installer can be run directly:

```sh
bash setup-dd/install-vscode.sh
bash setup-dd/install-chrome.sh
bash setup-dd/install-docker.sh
bash setup-dd/install-terraform.sh
bash setup-dd/install-ansible.sh
bash setup-dd/install-kubectl.sh
bash setup-dd/install-graphviz.sh
bash setup-dd/install-azure-cli.sh
bash setup-dd/install-aws-cli.sh
bash setup-dd/install-python.sh
bash setup-dd/install-java.sh
bash setup-dd/install-node.sh
bash setup-dd/install-maven.sh
bash setup-dd/install-gradle.sh
bash setup-dd/install-go.sh
bash setup-dd/install-rust.sh
bash setup-dd/install-ruby.sh
bash setup-dd/install-php.sh
bash setup-dd/install-dotnet.sh
bash setup-dd/install-databricks-cli.sh
bash setup-dd/install-claude-code.sh
bash setup-dd/install-github-copilot.sh
bash setup-dd/install-playwright.sh
bash setup-dd/install-playwright-mcp.sh
bash setup-dd/install-cypress.sh
```

Claude Code, Databricks CLI, GitHub Copilot CLI, Playwright, Playwright MCP, and Cypress are separate installers and are not run by `setup.sh` by default.

## Docker Without sudo

The Docker installer adds your user to the `docker` group:

```sh
sudo usermod -aG docker "$USER"
```

Group membership is not active in already-open shells. After the script finishes, log out and back in, or run:

```sh
newgrp docker
```

Then verify:

```sh
docker run hello-world
```

## kubectl Version

The kubectl installer uses the Kubernetes `pkgs.k8s.io` stable apt repository. By default it uses `v1.37`.

Override the Kubernetes minor version if needed:

```sh
KUBECTL_MINOR_VERSION=v1.36 bash setup-dd/install-kubectl.sh
```

## Languages and Package Managers

These installers are included in `setup.sh` and can also be run individually.

- **Python**: installs `python3`, `pip3`, and `python3-venv` from Ubuntu apt; adds `pipx` (apt), Poetry (`pipx install poetry`), and `uv` (Astral installer into `/usr/local/bin`)
- **Java**: installs OpenJDK via apt (`openjdk-21-jdk` by default; LTS available on Ubuntu 22.04 and 24.04)
- **Node.js**: installs Node.js and npm from the official NodeSource apt repository (Node 24 Active LTS by default); enables Corepack and activates `yarn` / `pnpm`
- **Maven**: installs `maven` from Ubuntu apt; installs Java first if needed
- **Gradle**: installs the official Gradle binary distribution to `/opt/gradle` and links `gradle` into `/usr/local/bin` (9.8.2 by default)
- **Go**: installs the official Go tarball under `/usr/local/go` and links `go` / `gofmt` into `/usr/local/bin` (Go 1.27.3 by default; modules are built-in)
- **Rust**: installs via rustup for the current user (`rustc`, `cargo`); adds `~/.cargo/bin` to PATH
- **Ruby**: installs `ruby-full` and `build-essential` from apt, then Bundler via `gem install bundler`
- **PHP**: installs `php-cli` plus common extensions from apt, then Composer into `/usr/local/bin`
- **.NET**: installs the newest Ubuntu apt SDK package available (`dotnet-sdk-10.0` when present, else 9.0 / 8.0; NuGet is built into `dotnet`)

Override defaults when needed:

```sh
JAVA_PACKAGE=openjdk-17-jdk bash setup-dd/install-java.sh
NODE_MAJOR_VERSION=22 bash setup-dd/install-node.sh
GRADLE_VERSION=9.8.2 bash setup-dd/install-gradle.sh
GO_VERSION=1.27.3 bash setup-dd/install-go.sh
DOTNET_SDK_PACKAGE=dotnet-sdk-8.0 bash setup-dd/install-dotnet.sh
```

On Ubuntu 24.04+, `dotnet-sdk-10.0` is usually available from the built-in Ubuntu feed and is preferred automatically. On 22.04 the installer falls back to `dotnet-sdk-8.0` unless you set `DOTNET_SDK_PACKAGE` or add the `dotnet/backports` PPA yourself.

## Verify Installation

Run these commands after setup:

```sh
code --version
google-chrome --version
docker --version
docker compose version
terraform version
ansible --version
kubectl version --client
dot -V
az version
aws --version
python3 --version
pip3 --version
pipx --version
poetry --version
uv --version
java -version
node --version
npm --version
yarn --version
pnpm --version
mvn --version
gradle --version
go version
rustc --version
cargo --version
ruby --version
bundler --version
php --version
composer --version
dotnet --version
databricks -v
claude --version
copilot --version
playwright --version
npm list -g --depth=0 @playwright/mcp
cypress --version
```

## Claude Code

Install Anthropic’s Claude Code CLI with the native installer (recommended; no Node.js required):

```sh
bash setup-dd/install-claude-code.sh
```

Optional channel or version pin:

```sh
CLAUDE_CODE_CHANNEL=stable bash setup-dd/install-claude-code.sh
CLAUDE_CODE_CHANNEL=2.1.89 bash setup-dd/install-claude-code.sh
```

The binary is installed under `~/.local/bin`. The script adds that directory to `PATH` in `~/.bashrc` or `~/.profile` when needed. Run as a regular user (not root). Claude Code requires a paid Claude plan or Anthropic Console API billing.

## GitHub Copilot CLI

Install the GitHub Copilot CLI with the official install script:

```sh
bash setup-dd/install-github-copilot.sh
```

Optional version pin:

```sh
COPILOT_VERSION=v0.0.369 bash setup-dd/install-github-copilot.sh
COPILOT_VERSION=prerelease bash setup-dd/install-github-copilot.sh
```

The binary is installed under `~/.local/bin`. The script adds that directory to `PATH` when needed. Run as a regular user (not root). Copilot CLI requires an active GitHub Copilot subscription.

## Playwright

Install the Playwright Test CLI globally, Ubuntu browser dependencies, and browser binaries:

```sh
bash setup-dd/install-playwright.sh
```

Optional browser filter (default installs Chromium, Firefox, and WebKit):

```sh
PLAYWRIGHT_BROWSERS=chromium bash setup-dd/install-playwright.sh
```

Browsers are cached under `~/.cache/ms-playwright`. Node.js is installed first if needed. Projects should still add `@playwright/test` as a local dependency (`npm init playwright@latest`).

## Playwright MCP

Install Microsoft’s Playwright MCP server (`@playwright/mcp`) globally. Node.js and Playwright browsers/deps are installed first if missing:

```sh
bash setup-dd/install-playwright-mcp.sh
```

Add the server to your MCP client config:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

With Claude Code:

```sh
claude mcp add playwright npx @playwright/mcp@latest
```

## Cypress

Install Cypress Linux prerequisites, a global `cypress` CLI, and the Cypress app binary cache:

```sh
bash setup-dd/install-cypress.sh
```

The binary is cached under `~/.cache/Cypress`. Node.js is installed first if needed. Projects should still add `cypress` as a local devDependency (`npm install cypress --save-dev`).

## Files

- `setup.sh`: master installer
- `lib/common.sh`: shared bash helpers
- `install-vscode.sh`: VS Code installer
- `install-chrome.sh`: Google Chrome installer
- `install-docker.sh`: Docker installer
- `install-terraform.sh`: Terraform installer
- `install-ansible.sh`: Ansible installer
- `install-kubectl.sh`: kubectl installer
- `install-graphviz.sh`: Graphviz / `dot` installer
- `install-azure-cli.sh`: Azure CLI installer
- `install-aws-cli.sh`: AWS CLI installer
- `install-python.sh`: Python 3 / pip / venv / pipx / Poetry / uv installer
- `install-java.sh`: OpenJDK installer
- `install-node.sh`: Node.js / npm / Corepack yarn / pnpm installer (NodeSource)
- `install-maven.sh`: Maven installer
- `install-gradle.sh`: Gradle installer
- `install-go.sh`: Go installer
- `install-rust.sh`: Rust / Cargo installer (rustup)
- `install-ruby.sh`: Ruby / gem / Bundler installer
- `install-php.sh`: PHP / Composer installer
- `install-dotnet.sh`: .NET SDK installer
- `install-databricks-cli.sh`: Databricks CLI installer
- `install-claude-code.sh`: Claude Code installer
- `install-github-copilot.sh`: GitHub Copilot CLI installer
- `install-playwright.sh`: Playwright installer
- `install-playwright-mcp.sh`: Playwright MCP server installer
- `install-cypress.sh`: Cypress installer

## Azure CLI on newer Ubuntu releases

Microsoft’s Azure CLI apt repo does not always publish a suite for the newest Ubuntu codenames (for example `resolute` on 26.04). In that case the installer falls back to a supported suite such as `noble`, and apt update automatically repairs a previously broken `azure-cli.list` / `azure-cli.sources` so other installers (including Databricks) are not blocked.

If apt is already broken on a student machine before these scripts run, repair it manually:

```bash
sudo mv -f /etc/apt/sources.list.d/azure-cli.sources /etc/apt/sources.list.d/azure-cli.sources.disabled 2>/dev/null || true
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ noble main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update
```

## Safety Notes

- The scripts do not store credentials or secrets.
- Official signing keys are installed under `/etc/apt/keyrings`.
- Official apt source files are installed under `/etc/apt/sources.list.d`.
- Package installation uses `sudo apt-get install -y`.
