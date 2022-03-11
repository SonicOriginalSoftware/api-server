GO_ROOT            := $(shell go env GOROOT)

HOST               := localhost

OUT_DIR            := out
CERT               := $(OUT_DIR)/cert.pem
KEY                := $(OUT_DIR)/key.pem

EXECUTABLE_NAME    := server
EXECUTABLE_VERSION := latest

IMAGE_TAG          := $(EXECUTABLE_NAME):$(EXECUTABLE_VERSION)
IMAGE_TARGET       :=

GIT_TAG            := git
GIT_TARGET         :=

OUT_FILE           := $(OUT_DIR)/$(EXECUTABLE_NAME)

all: $(OUT_FILE) certs

clean-certs:
	$(info Cleaning cert files...)
	@rm -rf $(CERT) $(KEY)
	@echo Cleaned cert files!

clean-image-cache:
	$(info Cleaning image cache...)
	docker image prune -f
	docker buildx prune -f

clean-image:
	$(info Cleaning image...)
	-docker rmi $(IMAGE_TAG)

clean:
	$(info Cleaning...)
	@rm -rf $(OUT_FILE)
	@echo Cleaned!

clean-all: clean-certs clean clean-image clean-image-cache
ca: clean-all

$(OUT_DIR):
	mkdir $(OUT_DIR)

$(CERT) $(KEY) &: | $(OUT_DIR)
	$(info Creating cert files...)
	go run "$(GO_ROOT)/src/crypto/tls/generate_cert.go" --host $(HOST)
	mv *.pem $(OUT_DIR)

$(OUT_FILE): | $(OUT_DIR)
	go build -o $(OUT_FILE) -buildmode=pie -ldflags '-linkmode=external -extldflags "-static-pie"'

certs: $(CERT) $(KEY)
image-executable: $(OUT_FILE) certs

git:
	docker buildx build \
	  --progress=plain \
	  --tag $(GIT_TAG) \
		--target=$(GIT_TARGET) \
	  - < git.Dockerfile

image: git
	docker buildx build \
	  --build-arg OUT_FILE=$(OUT_FILE) \
	  --progress=plain \
	  --tag $(IMAGE_TAG) \
		--target=$(IMAGE_TARGET) \
		-f Dockerfile \
	  .

.PHONY: clean clean-certs clean-all clean-image-cache clean-image ca all \
	certs $(OUT_FILE) \
	image image-executable git
