#!/bin/bash
# exec -a vary_cpus.sh bash ./vary_cpus.sh

run_workload() {
    echo "running workload with CPU limit: $1"
    output_path="$2"
    sudo ../wrk2/wrk -D exp -t 8 -c 1000 -d 30s -L -s ./wrk2/scripts/social-network/compose-post.lua http://ms1311.utah.cloudlab.us:8080/wrk2-api/post/compose -R 200 > "${output_path}"
}

services=($(sudo docker service ls --format '{{.Name}}' | while read service; do
    image=$(sudo docker service inspect --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' "$service" | cut -d'@' -f1)
    if [[ "$image" == "deathstarbench/social-network-microservices:latest" ]]; then
        echo "$service"
    fi
done))

# trying just one service...
# services=("socnetapp_compose-post-service")
total_services=${#services[@]}

# workload warmup
echo "warming up workload..."
for i in $(seq 1 3); do
    echo "warmup iteration $i"
    run_workload 1.0 "jaeger_traces/warmup_no_limit_${i}.log"
done
echo "warmup complete. starting CPU limit tests..."

for service in "${services[@]}"; do
    echo
    echo "setting CPU limits for service '${service}'"
    output_dir=limit_"${service}"
    for cpu_limit in $(seq 0.1 0.1 1.0); do
        echo "setting CPU limit for service '${service}' to ${cpu_limit}"
        echo
        echo "before docker service update!"
        sudo docker service update --limit-cpu "${cpu_limit}" --force "${service}"
        echo "after docker service update!"
        echo
        start_time=$(($(date +%s%N)/1000))

        # run workload once after update (output prints to stdout)
        
        sudo ../wrk2/wrk -D exp -t 8 -c 1000 -d 30s -L -s ./wrk2/scripts/social-network/compose-post.lua http://ms1311.utah.cloudlab.us:8080/wrk2-api/post/compose -R 200
        
        # cd ./jaeger_traces
        # mkdir -p "${output_dir}"
        # cd ..
        ### traces_${service}_${cpu_limit}
        
        
        echo "starting profiler for trace_${service}_${cpu_limit}..."
        sudo /users/krisub/LDOS/profiler.bt vary_cpus.sh > /users/krisub/LDOS/traces/trace_${service}_${cpu_limit}.txt &
        BPF_PID=$!

        # run logged workload
        echo
        echo "running workload..."
        run_workload "${cpu_limit}" "jaeger_traces/${output_dir}/traces_${cpu_limit}.log"

        kill -9 $BPF_PID 2>/dev/null || true
        echo "profiler stopped..."
        
        echo
        echo "dumping jaeger traces for service '${service}' with CPU limit ${cpu_limit}..."
        sudo ./dump_jaeger.sh "${start_time}" "${output_dir}" "${cpu_limit}"
        echo "jaeger traces dumped..."
        wait
        echo
        echo "next cpu limit..."
    done
    echo "next service..."
done


# at low cpu (0.1 and 0.2), compose post service logs have connection issues:
# compose post service is likely not getting enough CPU cycles to accept or process incoming connections,
# leading to connection issues from the workload, which sends 200 requests per second
# makes sense since workload is focused on composing posts