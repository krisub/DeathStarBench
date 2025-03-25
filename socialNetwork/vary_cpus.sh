#!/bin/bash

run_workload() {
    echo "Running workload with CPU limit: $1"
    output_path="$2"
    sudo ../wrk2/wrk -D exp -t 8 -c 1000 -d 30s -L -s ./wrk2/scripts/social-network/compose-post.lua http://node0.krisub-247336.ldos-ut-pg0.wisc.cloudlab.us:8080/wrk2-api/post/compose -R 200 > "${output_path}"
}

services=($(sudo docker service ls --format '{{.Name}}' | while read service; do
    image=$(sudo docker service inspect --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' "$service" | cut -d'@' -f1)
    if [[ "$image" == "deathstarbench/social-network-microservices:latest" ]]; then
        echo "$service"
    fi
done))

# trying just one service...
# services=("socnetapp_text-service")
total_services=${#services[@]}

for service in "${services[@]}"; do
    echo "Setting CPU limits for service '${service}'"
    output_dir=limit_"${service}"
    for cpu_limit in $(seq 0.1 0.1 1.0); do
        echo "Setting CPU limit for service '${service}' to ${cpu_limit}"
        echo "Before docker service update!"
        sudo docker service update --limit-cpu "${cpu_limit}" --force "${service}"
        echo "After docker service update!"
        start_time=$(($(date +%s%N)/1000))

        cd ./jaeger_traces
        mkdir -p "${output_dir}"
        cd ..
        
        run_workload "${cpu_limit}" "jaeger_traces/${output_dir}/traces_${service}_${cpu_limit}.log"
        wait
        ./dump_jaeger.sh "${start_time}" "${output_dir}" "${cpu_limit}"

        echo "Waiting 5 seconds before next run..."
        sleep 5
    done
done