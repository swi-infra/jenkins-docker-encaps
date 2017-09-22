#!/usr/bin/env bats


setup() {
    TEMP_DIR=$(mktemp --directory)
    export PATH="${PWD}:${PATH}"
}

teardown() {
    rm -rf "$TEMP_DIR"
}

get_tini() {
    TINI_VERSION=v0.16.1
    wget -O "${TEMP_DIR}/tini" https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static
    chmod +x "${TEMP_DIR}/tini"
}

@test "Run with tini provided by the host" {
    export DOCKER_ENCAPS_NAME="encaps-test-$(basename $TEMP_DIR)"
    export DOCKER_ENCAPS_TINI_PATH="/tini"
    export DOCKER_ENCAPS_CONTAINER_SHARING=false
    export DOCKER_ENCAPS_CONTAINER_ARGS="--volume ${TEMP_DIR}/tini:/tini"

    get_tini

    # Prepare a script to trigger encaps
    tee "${TEMP_DIR}/test.sh" <<EOF
#!/usr/bin/env encaps
cat /etc/os-release
EOF
    chmod +x "${TEMP_DIR}/test.sh"

    # Run script, that should start a container and run the script in it
    "${TEMP_DIR}/test.sh"

    # Make sure that we can run something in the container with the name that we provided
    docker exec "$DOCKER_ENCAPS_NAME" cat /etc/os-release

    # Clean-up
    encaps-cleanup

    # Make sure that we are not leaving anything behind
    run docker inspect --type=container "$DOCKER_ENCAPS_NAME"
    [ $status -ne 0 ]
}

# Creates a container with sole purpose to provide tini
create_tini_container() {
    local name=$1
    local tini_volume=$2

    docker run --detach \
               --name "$name" \
               --volume "$tini_volume" \
               --cidfile "${TEMP_DIR}/tini-cid" \
               alpine:latest \
                 tail -f /dev/null
    docker exec "$name" apk add --no-cache tini
    docker exec "$name" /bin/sh -c "cp \$(which tini) ${tini_volume}"
}

remove_tini_container() {
    local name=$1

    docker kill "$name"
    docker rm --force "$name"
}

@test "Run with tini provided by another container (from var DOCKER_ENCAPS_CONTAINER_ID)" {
    export DOCKER_ENCAPS_NAME="encaps-test-$(basename $TEMP_DIR)"
    export DOCKER_ENCAPS_TINI_PATH="/path/to/tini"
    export DOCKER_ENCAPS_CONTAINER_ID="encaps-test-$(basename $TEMP_DIR)-tini"

    create_tini_container "$DOCKER_ENCAPS_CONTAINER_ID" "/path/to"

    # Prepare a script to trigger encaps
    tee "${TEMP_DIR}/test.sh" <<EOF
#!/usr/bin/env encaps
cat /etc/os-release
EOF
    chmod +x "${TEMP_DIR}/test.sh"

    # Run script, that should start a container and run the script in it
    "${TEMP_DIR}/test.sh"

    # Make sure that we can run something in the container with the name that we provided
    docker exec "$DOCKER_ENCAPS_NAME" cat /etc/os-release

    # Clean-up
    encaps-cleanup

    # Make sure that we are not leaving anything behind
    run docker inspect --type=container "$DOCKER_ENCAPS_NAME"
    [ $status -ne 0 ]

    remove_tini_container "$DOCKER_ENCAPS_CONTAINER_ID"
}

@test "Run with tini provided by another container (from file /tmp/container.id)" {
    export DOCKER_ENCAPS_NAME="encaps-test-$(basename $TEMP_DIR)"
    local tini_container_name="encaps-test-$(basename $TEMP_DIR)-tini"

    # Tini container uses the default path for tini (=/opt/tini/tini)
    create_tini_container "$tini_container_name" "/opt/tini"

    # Export container.id
    cp "${TEMP_DIR}/tini-cid" "/tmp/container.id"

    # Prepare a script to trigger encaps
    tee "${TEMP_DIR}/test.sh" <<EOF
#!/usr/bin/env encaps
cat /etc/os-release
EOF
    chmod +x "${TEMP_DIR}/test.sh"

    # Run script, that should start a container and run the script in it
    "${TEMP_DIR}/test.sh"

    # Make sure that we can run something in the container with the name that we provided
    docker exec "$DOCKER_ENCAPS_NAME" cat /etc/os-release

    # Clean-up
    encaps-cleanup

    # Make sure that we are not leaving anything behind
    run docker inspect --type=container "$DOCKER_ENCAPS_NAME"
    [ $status -ne 0 ]

    # Remove tini container
    remove_tini_container "$tini_container_name"
}

