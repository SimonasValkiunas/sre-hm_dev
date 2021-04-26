# Cookbook:: sre_hme
# Recipe:: recording_rules

# create recording rules file
file '/opt/prometheus-2.25.2/rules/node_exporter_recording_rules.yml' do
    content '"groups":
    - "name": "node-exporter.rules"
      "rules":
      - "expr": |
          count without (cpu) (
            count without (mode) (
              node_cpu_seconds_total{job="node"}
            )
          )
        "record": "instance:node_num_cpu:sum"
      - "expr": |
          1 - avg without (cpu, mode) (
            rate(node_cpu_seconds_total{job="node", mode="idle"}[1m])
          )
        "record": "instance:node_cpu_utilisation:rate1m"
      - "expr": |
          (
            node_load1{job="node"}
          /
            instance:node_num_cpu:sum{job="node"}
          )
        "record": "instance:node_load1_per_cpu:ratio"
      - "expr": |
          1 - (
            node_memory_MemAvailable_bytes{job="node"}
          /
            node_memory_MemTotal_bytes{job="node"}
          )
        "record": "instance:node_memory_utilisation:ratio"
      - "expr": |
          rate(node_vmstat_pgmajfault{job="node"}[1m])
        "record": "instance:node_vmstat_pgmajfault:rate1m"
      - "expr": |
          rate(node_disk_io_time_seconds_total{job="node", device!=""}[1m])
        "record": "instance_device:node_disk_io_time_seconds:rate1m"
      - "expr": |
          rate(node_disk_io_time_weighted_seconds_total{job="node", device!=""}[1m])
        "record": "instance_device:node_disk_io_time_weighted_seconds:rate1m"
      - "expr": |
          sum without (device) (
            rate(node_network_receive_bytes_total{job="node", device!="lo"}[1m])
          )
        "record": "instance:node_network_receive_bytes_excluding_lo:rate1m"
      - "expr": |
          sum without (device) (
            rate(node_network_transmit_bytes_total{job="node", device!="lo"}[1m])
          )
        "record": "instance:node_network_transmit_bytes_excluding_lo:rate1m"
      - "expr": |
          sum without (device) (
            rate(node_network_receive_drop_total{job="node", device!="lo"}[1m])
          )
        "record": "instance:node_network_receive_drop_excluding_lo:rate1m"
      - "expr": |
          sum without (device) (
            rate(node_network_transmit_drop_total{job="node", device!="lo"}[1m])
          )
        "record": "instance:node_network_transmit_drop_excluding_lo:rate1m"'
    mode '0755'
    owner 'prometheus'
    group 'prometheus'
  end