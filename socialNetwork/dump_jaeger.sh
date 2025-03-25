#!/bin/bash

start_time="$1"  # passed in
end_time=$(($(date +%s%N)/1000))  # now

# mkdir -p jaeger_traces

output_dir="$2"
cpu_limit="$3"

# cd ./jaeger_traces
# mkdir -p "${output_dir}"
# cd ..

# for service in $(curl -s "http://node0.krisub-247336.ldos-ut-pg0.wisc.cloudlab.us:16686/api/services" | jq -r '.data[]'); do
#     echo "Fetching traces for service: ${service}"
    
#     curl -s "http://node0.krisub-247336.ldos-ut-pg0.wisc.cloudlab.us:16686/api/traces?service=$service&start=$start_time&end=$end_time" \
#         | jq '.' > "jaeger_traces/${output_dir}/traces_${service}.json"
# done

service="compose-post-service"
echo "Fetching traces for service: ${service}"
curl -s "http://node0.krisub-247336.ldos-ut-pg0.wisc.cloudlab.us:16686/api/traces?service=$service&start=$start_time&end=$end_time" \
    | jq '.' > "jaeger_traces/${output_dir}/traces_${service}_${cpu_limit}.json"