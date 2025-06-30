# makefile for onprema development container

IMAGE_NAME := onprema108/dev-container
TAG := latest
FULL_IMAGE := $(IMAGE_NAME):$(TAG)

.PHONY: help build run run-docker push clean release

# default target
help:
	@echo "onprema development container"
	@echo ""
	@echo "available commands:"
	@echo "  make build      - build the development container image"
	@echo "  make run        - run container with current directory mounted"
	@echo "  make run-docker - run container with docker socket for docker-in-docker"
	@echo "  make push       - push image to docker hub (requires docker login)"
	@echo "  make clean      - remove local image"
	@echo "  make release    - build and push in one command"

# build the container image
build:
	@echo "building $(FULL_IMAGE)..."
	docker build -t $(FULL_IMAGE) .
	@echo "build complete!"

# run the container with workspace mounted
run:
	@echo "running $(FULL_IMAGE) with current directory mounted..."
	docker run -it --rm \
		-v $(PWD):/home/hacker/workspace \
		$(FULL_IMAGE)

# run with docker socket mounted (for docker-in-docker)
run-docker:
	@echo "running $(FULL_IMAGE) with docker socket mounted..."
	docker run -it --rm \
		-v $(PWD):/home/hacker/workspace \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$(FULL_IMAGE)

# push to docker hub (requires docker login)
push:
	@echo "pushing $(FULL_IMAGE) to docker hub..."
	docker push $(FULL_IMAGE)
	@echo "push complete!"

# remove local image
clean:
	@echo "removing local image $(FULL_IMAGE)..."
	docker rmi $(FULL_IMAGE) || true
	@echo "cleanup complete!"

# build and push in one command
release: build push
	@echo "release complete!"
