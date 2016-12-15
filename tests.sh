#!/usr/bin/env bats

setup() {
    export TEMP_DIR=$(mktemp -d --suffix="encaps-test")
    export PATH="$PWD:$PATH"
}

teardown() {
    rm -rf $TEMP_DIR
}

prepare_script() {
   tee $TEMP_DIR/script.sh <<SimpleRun
#!/usr/bin/env encaps

echo "Test"
hostname
cat /etc/os-release

SimpleRun
    chmod +x $TEMP_DIR/script.sh
}

@test "Run encaps and cleanup" {
    export DOCKER_ENCAPS_NAME="encaps-simple-test"
    prepare_script
    $TEMP_DIR/script.sh
    encaps-cleanup
}

@test "Run encaps with weight set" {
    export DOCKER_ENCAPS_NAME="encaps-weight-test"
    export DOCKER_ENCAPS_WEIGHT=2
    prepare_script
    $TEMP_DIR/script.sh
    [ $(docker inspect --format={{.HostConfig.CpuShares}} $DOCKER_ENCAPS_NAME) -eq $((DOCKER_ENCAPS_WEIGHT*1024)) ]
    encaps-cleanup
}
