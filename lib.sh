#!/bin/bash

#set -o errexit
#set -o nounset
#set -o pipefail


function stress::initialize() {
  export rundir="$(readlink -f "$1")"
  export httperf_log_file="$rundir/httperf.log"
  export container_args="-p 8080:8080" # -m 75m"
  export label="$2-stress-test"
  export image_name="$2-sample-app"
  export perf_args="--server 127.0.0.1 --port 8080 --hog --timeout 60"

  mkdir -p "$rundir"
  if [ ! -z "$(ls -A "$rundir")" ]; then
    log_info "Directory $rundir is not empty, exiting"
    exit 1
  fi

  trap cleanup EXIT SIGINT

  log_info "Logging httperf into $httperf_log_file"
}

# Execute command on remote host
function remote() {
  ssh openshiftdev "$@"
}

function log_info() {
  echo "---> $(date +%T)     $*"
}

function cleanup() {
  log_info "Cleaning up"
  ids=$(remote docker ps -q --filter="label=$label")
  if [ -n "$ids" ]; then
    remote docker stop $ids
    remote docker rm -v $ids
  fi
}

function set_container_envs() {
  export container_envs="$*"
}

function set_label() {
  export label_tag="$*"
}

function create_container() {
  args="$container_args $container_envs --label=$label=$label_tag"
  log_info "Starting $image_name with following args: $args"
  container=$(remote docker run $args -d "$image_name")
  export container
  log_info "Started $container"
  #remote docker logs $container
  #log_info "  Limit is `remote docker exec $container cat /sys/fs/cgroup/memory/memory.limit_in_bytes` bytes"
}

function set_stats_file() {
  export stats_file="$rundir/$1"
  log_info "Logging statistics into $stats_file"
}

function reset_stats() {
  stats="${label_tag:-0}"
  collect_stats
}

function collect_stats() {
usage=$(remote docker exec "$container" cat /sys/fs/cgroup/memory/memory.max_usage_in_bytes)
  stats="$stats,$usage"
  export stats
}

function write_stats() {
  if [ $# -gt 0 ]; then
    echo "$@" >> "$stats_file"
  else
    echo "${stats:-}" >> "$stats_file"
  fi
}

function write_httperf() {
  echo "$@" >> "$httperf_log_file"
}

# Test function. Run httperf 2 times to make sure memory is maxed-out.
function http_test() {
  conns=$1; shift
  rate=$1; shift
  log_info ".. Testing with $conns connections, rate $rate"
  for i in $(seq 2); do
    write_httperf "#### Run $i"
    httperf $perf_args --num-conns "$conns" --rate "$rate" >> "$httperf_log_file" 2>&1
  done
  collect_stats
}

function send_graph() {
  graph_file="$rundir"/graph.png
  /home/mnagy/work/stress_test/bytes_to_megs.py -o "$graph_file" "$rundir"/*.csv
  tbfoto "$graph_file"
}
