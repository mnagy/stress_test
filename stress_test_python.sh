#!/bin/bash

source lib.sh

set -o errexit
set -o nounset
set -o pipefail

stress::initialize "/home/mnagy/work/stress_test/sti-python/run_tmp" "perl"

#for exp in 1 10 16; do
#for exp in 14 15 16; do
for exp in 10; do
  #for slp in 0 0.5 1; do
  for slp in 0 ; do
    set_stats_file "run_${slp}_${exp}.csv"
    write_stats "# sleep=$slp, exp=$exp"
    #for i in $(seq 2 4 32); do
    for i in 2 32; do
      set_label $i
      set_container_envs -e APP_MODULE=wsgi:wsgi_handler -e GUNICORN_WORKERS=$i -e TEST_SLEEP=$slp -e TEST_EXP=$exp

      create_container

      # Run tests:
      reset_stats
      http_test 300 110
      #http_test 300 110
      #http_test 2000 70
      #http_test 1000 10

      #http_test 10000 1000
      #http_test 10000 2500
      #http_test 10000 5000
      write_stats

      log_info "Cleaning up $container"
      remote docker stop "$container" >/dev/null
      remote docker logs "$container" &> "$rundir"/"$container.log"
      remote docker rm -v "$container" >/dev/null
    done
  done
done

send_graph
