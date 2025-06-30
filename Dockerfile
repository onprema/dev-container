# syntax=docker/dockerfile:1

# onprema development container
# a ubuntu-based development environment for devops/platform engineering tutorials
# includes common tools like docker cli, kubectl, helm, terraform, and a configured shell

FROM ubuntu:22.04 AS base

# avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# install base system packages and tools
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    vim \
    zsh \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    unzip \
    jq \
    tree \
    htop \
    nano \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    sudo

# download and install external tools stage
FROM base AS tools-installer

# install docker cli
RUN --mount=type=cache,target=/tmp/docker-install \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli

# install kubectl
RUN --mount=type=cache,target=/tmp/kubectl-install \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# install helm
RUN --mount=type=cache,target=/tmp/helm-install \
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update \
    && apt-get install -y helm

# install terraform
RUN --mount=type=cache,target=/tmp/terraform-install \
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform

# install uv (python package manager)
RUN --mount=type=cache,target=/tmp/uv-install \
    curl -LsSf https://astral.sh/uv/install.sh | sh

# install ruff (python linter/formatter)
RUN --mount=type=cache,target=/tmp/ruff-install \
    curl -LsSf https://astral.sh/ruff/install.sh | sh

# install dagger (ci/cd as code)
RUN --mount=type=cache,target=/tmp/dagger-install \
    curl -L https://dl.dagger.io/dagger/install.sh | sh

# final stage - user setup and configuration
FROM tools-installer AS final

# create a non-root user for development with sudo access
ARG UID=1000
ARG GID=1000
RUN groupadd --gid $GID hacker \
    && useradd --uid $UID --gid $GID --create-home --shell /bin/zsh hacker \
    && usermod -aG docker hacker 2>/dev/null || true \
    && usermod -aG sudo hacker \
    && echo 'hacker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# switch to non-root user for the rest of the setup
USER hacker
WORKDIR /home/hacker

# add astral tools to path
ENV PATH="/home/hacker/.cargo/bin:/home/hacker/.local/bin:$PATH"

# install oh-my-zsh
RUN --mount=type=cache,target=/tmp/oh-my-zsh,uid=$UID,gid=$GID \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# install fzf
RUN --mount=type=cache,target=/tmp/fzf,uid=$UID,gid=$GID \
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
    && ~/.fzf/install --all

# install zsh plugins
RUN --mount=type=cache,target=/tmp/zsh-plugins,uid=$UID,gid=$GID \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# configure zsh with useful plugins and aliases
RUN sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf)/' ~/.zshrc \
    && echo 'export EDITOR=vim' >> ~/.zshrc \
    && echo 'export PATH="/home/hacker/.cargo/bin:/home/hacker/.local/bin:$PATH"' >> ~/.zshrc \
    && echo 'alias ll="ls -la"' >> ~/.zshrc \
    && echo 'alias k="kubectl"' >> ~/.zshrc \
    && echo 'alias d="docker"' >> ~/.zshrc \
    && echo 'alias tf="terraform"' >> ~/.zshrc

# configure vim with sensible defaults
RUN echo 'set number' > ~/.vimrc \
    && echo 'set tabstop=4' >> ~/.vimrc \
    && echo 'set shiftwidth=4' >> ~/.vimrc \
    && echo 'set expandtab' >> ~/.vimrc \
    && echo 'syntax on' >> ~/.vimrc \
    && echo 'set background=dark' >> ~/.vimrc \
    && echo 'set autoindent' >> ~/.vimrc \
    && echo 'set smartindent' >> ~/.vimrc

# create workspace directory that will be mounted from host
RUN mkdir -p /home/hacker/workspace

# set default working directory
WORKDIR /home/hacker/workspace

# start with zsh
CMD ["/bin/zsh"]
