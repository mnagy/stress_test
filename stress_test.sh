#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

export httperf_log_file=`mktemp /tmp/stress_test_httperf_log.XXXX`
export container_args="-p 8080:8080"
export label="ruby-stress-test"
export image_name="ruby-sample-app"
export perf_args="--server 127.0.0.1 --port 8080 --timeout 1"

# Execute command on remote host
function remote() {
  ssh openshiftdev "$@"
}

function log_info() {
  echo "---> `date +%T`     $@"
}

function cleanup() {
  log_info "Cleaning up"
  ids=`remote docker ps -q --filter="label=$label"`
  if [ -n "$ids" ]; then
    remote docker stop $ids
    remote docker rm $ids
  fi
}
trap cleanup EXIT SIGINT

function create_container() {
  args="$container_args $container_envs --label=$label=$threads"
  log_info "Starting $image_name with following args: $args"
  container=`remote docker run $args -d $image_name`
  export container
  log_info "Started $container"
  #log_info "  Limit is `remote docker exec $container cat /sys/fs/cgroup/memory/memory.limit_in_bytes` bytes"
}

function reset_stats() {
  stats="${threads:-0}"
  collect_stats
}

function collect_stats() {
  usage=`remote docker exec $container cat /sys/fs/cgroup/memory/memory.max_usage_in_bytes`
  stats="$stats,$usage"
  export stats
}

function write_stats() {
  echo "${stats:-}" >> $stats_file
}

# Test function. Run httperf 2 times to make sure memory is maxed-out.
function http_test() {
  conns=$1; shift
  rate=$1; shift
  log_info ".. Testing with $conns connections, rate $rate"
  for i in `seq 2`; do
    httperf $perf_args --num-conns $conns --rate $rate >> $httperf_log_file 2>&1
  done
  collect_stats
}

# Start
#log_info "Logging statistics into $stats_file"
log_info "Logging httperf into $httperf_log_file"


for exp in 1 10 16; do
  for wrk in `seq 8`; do
    #for slp in 0 0.5 1; do
    for slp in 0.1; do
      export stats_file="/tmp/run_04/run_${wrk}_${slp}_${exp}.csv"
      echo "# sleep=$slp, workers=$wrk, exp=$exp" >> $stats_file
      for i in `seq 2 2 32`; do
        export threads=$i
        export container_envs="-e PUMA_MAX_THREADS=$i -e TEST_SLEEP=$slp -e TEST_EXP=$exp -e TEST_WORKERS=$wrk"

        create_container

        # Run tests:
        reset_stats
        http_test 1000 100
        http_test 1000 250
        http_test 1000 500
        write_stats

        log_info "Cleaning up $container"
        remote docker stop $container >/dev/null
        remote docker rm $container >/dev/null
      done
      #cat $stats_file | /home/mnagy/work/stress_test/bytes_to_megs.py | tb
    done
  done
done

/home/mnagy/work/stress_test/bytes_to_megs.py /tmp/run_04/*.csv
tbfoto /tmp/graph.png
log_info "Statistics:"
#cat $stats_file
log_info "End of $stats_file"
