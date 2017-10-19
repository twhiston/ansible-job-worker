SKIP_SQUASH?=1

build = hack/build.sh

OS := centos7

script_env = \
	SKIP_SQUASH=$(SKIP_SQUASH)                     \
	VERSIONS="$(VERSIONS)"                          \
	OS=$(OS)                                        \
	VERSION=$(VERSION)                              \
	BASE_IMAGE_NAME=$(BASE_IMAGE_NAME)              \
	OPENSHIFT_NAMESPACES="$(OPENSHIFT_NAMESPACES)"

.PHONY: prod
prod:
	$(script_env) SUBSET=prod $(build)

.PHONY: prod-nocache
prod-nocache:
	$(script_env) SUBSET=prod NOCACHE=true $(build)
