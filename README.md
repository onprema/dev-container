# onprema development container

a ubuntu-based development environment for devops/platform engineering tutorials. includes common tools and a configured shell environment that anyone can run consistently.

## what's included

- **shell**: zsh with oh-my-zsh, autosuggestions, syntax highlighting, and fzf
- **editor**: vim with sensible defaults
- **devops tools**: docker cli, kubectl, helm, terraform, dagger
- **python tools**: python3, uv (package manager), ruff (linter/formatter)
- **development**: git, nodejs, build tools
- **utilities**: curl, wget, jq, tree, htop
- **permissions**: non-root user (hacker) with sudo access

## quick start

### option 1: use pre-built image

pull and run the container with your current directory mounted:

```bash
docker run -it --rm -v $(pwd):/home/hacker/workspace onprema/dev-container:latest
```

### option 2: build locally

clone this repo and use the makefile:

```bash
git clone <this-repo>
cd <repo-name>
make build
make run
```

## makefile commands

if you've cloned this repo, you can use these convenient commands:

- **`make build`** - build the container image locally
- **`make run`** - run container with current directory mounted
- **`make run-docker`** - run with docker socket for docker-in-docker
- **`make push`** - push to docker hub (after `docker login`)
- **`make clean`** - remove local image
- **`make release`** - build and push in one command

## using with your ide

1. open your project folder in your ide
2. run the container:
   ```bash
   # if using pre-built image
   docker run -it --rm -v $(pwd):/home/hacker/workspace onprema/dev-container:latest

   # or if you cloned this repo
   make run
   ```
3. edit files in vs code, run commands in the container terminal

## docker-in-docker

to run docker commands inside the container, you have a few options:

### option 1: using makefile (if you cloned this repo)
```bash
make run-docker
```

### option 2: manual docker command
```bash
docker run -it --rm \
  -v $(pwd):/home/hacker/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  onprema/dev-container:latest
```

**note**: this gives the container access to your host's docker daemon. only do this if you trust the code you're running.

## kubernetes

if you have a local kubernetes cluster (docker desktop, minikube, kind), mount your kubeconfig:

```bash
docker run -it --rm \
  -v $(pwd):/home/hacker/workspace \
  -v ~/.kube:/home/hacker/.kube:ro \
  onprema/dev-container:latest
```

## building locally

### option 1: using makefile
```bash
git clone <this-repo>
cd <repo-name>
make build
```

### option 2: manual docker build
```bash
git clone <this-repo>
cd <repo-name>
docker build -t onprema/dev-container:latest .
```

## customization

the container includes a basic vim config and zsh setup. you can:

1. mount your own dotfiles:
   ```bash
   docker run -it --rm \
     -v $(pwd):/home/hacker/workspace \
     -v ~/.vimrc:/home/hacker/.vimrc:ro \
     -v ~/.zshrc:/home/hacker/.zshrc:ro \
     onprema/dev-container:latest
   ```

2. create your own dockerfile based on this one
3. fork this repo and modify the configuration

## why this exists

this container provides a consistent development environment for onprema youtube tutorials. whether you're on macos, windows, or linux, you get the same tools and setup.
