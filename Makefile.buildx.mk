# Copyright 2020 The OpenEBS Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ifeq (${TAG}, )
	export TAG=ci
endif

# default list of platforms for which multiarch image is built
ifeq (${PLATFORMS}, )
	export PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7,linux/ppc64le"
endif

# if IMG_RESULT is unspecified, by default the image will be pushed to registry
ifeq (${IMG_RESULT}, load)
	export PUSH_ARG="--load"
	# if load is specified, image will be built only for the build machine architecture.
	export PLATFORMS="local"
else ifeq (${IMG_RESULT}, cache)
	# if cache is specified, image will only be available in the build cache, it won't be pushed or loaded
	# therefore no PUSH_ARG will be specified
else
	export PUSH_ARG="--push"
endif

DOCKERX_IMAGE_PROVISIONER_NFS:=${IMAGE_ORG}/provisioner-nfs:${TAG}

.PHONY: docker.buildx
docker.buildx:
	export DOCKER_CLI_EXPERIMENTAL=enabled
	@if ! docker buildx ls | grep -q container-builder; then\
		docker buildx create --platform ${PLATFORMS} --name container-builder --use;\
	fi
	@docker buildx build --platform ${PLATFORMS} \
		-t "$(DOCKERX_IMAGE_NAME)" ${DBUILD_ARGS} -f $(PWD)/buildscripts/$(COMPONENT)/$(COMPONENT).Dockerfile \
		. ${PUSH_ARG}
	@echo "--> Build docker image: $(DOCKERX_IMAGE_NAME)"
	@echo

.PHONY: docker.buildx.provisioner-nfs
docker.buildx.provisioner-nfs: DOCKERX_IMAGE_NAME=$(DOCKERX_IMAGE_PROVISIONER_NFS)
docker.buildx.provisioner-nfs: COMPONENT=$(PROVISIONER_NFS)
docker.buildx.provisioner-nfs: docker.buildx

.PHONY: buildx.push.provisioner-nfs
buildx.push.provisioner-nfs:
	BUILDX=true DIMAGE=${IMAGE_ORG}/provisioner-nfs ./buildscripts/push.sh
