# Include common Makefile code.
BASE_IMAGE_NAME = ansible-job-worker
VERSIONS = prod
OPENSHIFT_NAMESPACES = ansible,job,cronjob

# Include common Makefile code.
include hack/common.mk
