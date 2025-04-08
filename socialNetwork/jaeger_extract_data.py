import csv

def convert_txt_to_csv(input_file, output_file):
    with open(input_file, 'r') as txt_file, open(output_file, 'w', newline='') as csv_file:
        csv_writer = csv.writer(csv_file)

        csv_writer.writerow(['service_limited', 'cpus_given', 'tracing', 'jaeger_e2e'])
        
        lines = []
        for line in txt_file:
            line = line.strip()

            if line:
                lines.append(line)
            elif lines:
                if len(lines) == 4:
                    service_limited = lines[0]
                    tracing = lines[1]
                    cpus_given = lines[2]
                    jaeger_e2e = lines[3].replace(' ms', '') 

                    csv_writer.writerow([service_limited, cpus_given, tracing, jaeger_e2e])
                
                lines = []

        if lines and len(lines) == 4:
            service_limited = lines[0]
            tracing = lines[1]
            cpus_given = lines[2]
            jaeger_e2e = lines[3].replace(' ms', '')
            
            csv_writer.writerow([service_limited, cpus_given, tracing, jaeger_e2e])

    print(f"Conversion complete. Data saved to {output_file}")

input_file = "jaeger_e2e_v2.txt"
output_file = "jaeger_trace_data.csv"

convert_txt_to_csv(input_file, output_file)
