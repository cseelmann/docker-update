#!/bin/bash
# upgraded version from https://blog.christophersmart.com/2019/12/15/automatically-updating-containers-with-docker/ (sorry did not find a git repo to fork)
# this script uses watchtower instead of runlike, as runlike cannot handle container networking other than bridge and watchtower auto prunes unused images

# Abort on all errors, set -x
set -o errexit

# Get the containers from first argument, else get all containers
CONTAINER_LIST="${1:-$(docker ps -q -a)}"

for container in ${CONTAINER_LIST}; do
  # Get the image and hash of the running container
  CONTAINER_IMAGE="$(docker inspect --format "{{.Config.Image}}" --type container ${container})"
  RUNNING_IMAGE="$(docker inspect --format "{{.Image}}" --type container "${container}")"

  # Pull in latest version of the container and get the hash
  docker pull "${CONTAINER_IMAGE}"
  LATEST_IMAGE="$(docker inspect --format "{{.Id}}" --type image "${CONTAINER_IMAGE}")"

  # Restart the container if the image is different
  if [[ "${RUNNING_IMAGE}" != "${LATEST_IMAGE}" ]]; then

    # get container name for watchtower
    CONTAINER_NAME="$(docker inspect --format "{{.Name}}" --type container "${container}")"

    echo "Updating ${container} - ${CONTAINER_NAME} with image ${CONTAINER_IMAGE}"
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --run-once "${CONTAINER_NAME}" --cleanup

        curl -s \
                  --form-string "token=" \
                  --form-string "user=" \
                  --form-string "message=Container ${CONTAINER_NAME} updated" \
                  https://api.pushover.net/1/messages.json
  fi
done
