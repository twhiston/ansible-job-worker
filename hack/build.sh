#!/bin/bash -e
# This script is used to build, test and squash the OpenShift Docker images.
#
# Name of resulting image will be: 'NAMESPACE/BASE_IMAGE_NAME-VERSION-OS'.
#
# BASE_IMAGE_NAME - Usually name of the main component within container.
# OS - Specifies distribution - "rhel7" or "centos7"
# VERSION - Specifies the image version - (must match with subdirectory in repo)
# TEST_MODE - If set, build a candidate image and test it
# TAG_ON_SUCCESS - If set, tested image will be re-tagged as a non-candidate
#       image, if the tests pass.
# VERSIONS - Must be set to a list with possible versions (subdirectories)
# OPENSHIFT_NAMESPACES - Which of available versions (subdirectories) should be
#       put into openshift/ namespace.

OS=${1-$OS}
VERSION=${2-$VERSION}

DOCKERFILE_PATH=""

NAMESPACE="tomwhiston"

# Versions are stored in subdirectories. You should specify VERSION variable
# If using make this is handled by the argument
dir="context/${SUBSET}"

IMAGE_NAME="${NAMESPACE}/${BASE_IMAGE_NAME}"
TAG="${IMAGE_NAME}:latest"

test -z "$BASE_IMAGE_NAME" && {
  BASE_DIR_NAME=$(echo $(basename `pwd`) | sed -e 's/-[0-9]*$//g')
  BASE_IMAGE_NAME="${BASE_DIR_NAME#s2i-}"
}

# Cleanup the temporary Dockerfile created by docker build with version
trap "rm -f ${DOCKERFILE_PATH}.version" SIGINT SIGQUIT EXIT

# Perform docker build but append the LABEL with GIT commit id at the end
function docker_build_with_version {

  local dockerfile="$1"
  # Use perl here to make this compatible with OSX
  DOCKERFILE_PATH=$(perl -MCwd -e 'print Cwd::abs_path shift' $dockerfile)
  cp ${DOCKERFILE_PATH} "${DOCKERFILE_PATH}.version"
  git_version=$(git rev-parse HEAD)

  echo "LABEL io.openshift.builder-version=\"${git_version}\"" >> "${dockerfile}.version"

  # Use dont cache if necessary
  if [ "$NOCACHE" == "true" ]; then
    docker build --no-cache -t ${TAG} -f "${dockerfile}.version" --build-arg BUILD_ENV="${SUBSET}" .
  else
    docker build -t ${TAG} -f "${dockerfile}.version" . --build-arg BUILD_ENV="${SUBSET}"
  fi

  if [[ "${SKIP_SQUASH}" != "1" ]]; then
    squash "${dockerfile}.version"
  fi
  rm -f "${DOCKERFILE_PATH}.version"
}

# Install the docker squashing tool[1] and squash the result image
# [1] https://github.com/goldmann/docker-scripts
function squash {
  # You MUST have docker-squash installed to use this
  # pip install docker-squash
  docker-squash ${TAG} -t ${TAG}
}


echo "---> Building ${IMAGE_NAME} ..."

pushd ${dir} > /dev/null
docker_build_with_version Dockerfile

popd > /dev/null
