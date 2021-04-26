#
# Cookbook:: sre_academy
# Recipe:: default
#
# The MIT License (MIT)
#
# Copyright:: 2021, The Authors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# install prometheus
node.override['prometheus-platform']['components']['prometheus']['install?'] = true
# install node_exporter
node.override['prometheus-platform']['components']['node_exporter']['install?'] = true

# configures node exported to listen on 9100 port
listen_ip = '127.0.0.1'
node_exporter 'main' do
  web_listen_address "#{listen_ip}:9100"
  action [:enable, :start]
end

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

# configures prometheus to scrape data from node exporter
node.override['prometheus-platform']['components']['prometheus']['config']['scrape_configs'] = {
  'index_1' =>
  {
    'job_name' => 'node',
    'scrape_interval' => '15s',
    'static_configs' => {
      'index_1' => {
        'targets' => ['localhost:9100']
      }
    }
  }
}

# include necessary recipes
include_recipe 'prometheus-platform::default'
include_recipe 'prometheus_exporters::node'

# install and configure grafana
grafana_install 'grafana'

service 'grafana-server' do
  action [:enable, :start]
  subscribes :restart, ['template[/etc/grafana/grafana.ini]', 'template[/etc/grafana/ldap.toml]'], :delayed
end

# create datasource for prometheus
grafana_datasource 'Prometheus' do
  datasource(
    access: "proxy",
    basicAuth: false,
    basicAuthPassword: "",
    basicAuthUser: "",
    database: "",
    id: 3,
    isDefault: true,
    jsonData: {httpMethod: "POST"},
    name: "Prometheus",
    orgId: 1,
    password: "",
    readOnly: false,
    secureJsonFields: {},
    type: "prometheus",
    typeLogoUrl: "",
    url: "http://localhost:9090",
    user: "",
    version: 1,
    withCredentials: false
  )
  action :create
end

# create dashboard file
file '/etc/grafana/provisioning/dashboards/node-dash.json' do
  content '{
    "__inputs": [],
    "__requires": [
      {
        "type": "grafana",
        "id": "grafana",
        "name": "Grafana",
        "version": "7.4.3"
      },
      {
        "type": "panel",
        "id": "graph",
        "name": "Graph",
        "version": ""
      },
      {
        "type": "datasource",
        "id": "prometheus",
        "name": "Prometheus",
        "version": "1.0.0"
      }
    ],
    "annotations": {
      "list": []
    },
    "editable": false,
    "gnetId": 13978,
    "graphTooltip": 0,
    "hideControls": false,
    "id": null,
    "links": [],
    "refresh": "",
    "rows": [
      {
        "collapse": false,
        "collapsed": false,
        "panels": [
          {
            "aliasColors": {},
            "bars": false,
            "dashLength": 10,
            "dashes": false,
            "datasource": "$datasource",
            "fill": 1,
            "fillGradient": 0,
            "gridPos": {},
            "id": 2,
            "legend": {
              "alignAsTable": false,
              "avg": false,
              "current": false,
              "max": false,
              "min": false,
              "rightSide": false,
              "show": true,
              "sideWidth": null,
              "total": false,
              "values": false
            },
            "lines": true,
            "linewidth": 1,
            "links": [],
            "nullPointMode": "null",
            "percentage": false,
            "pointradius": 5,
            "points": false,
            "renderer": "flot",
            "repeat": null,
            "seriesOverrides": [],
            "spaceLength": 10,
            "span": 6,
            "stack": true,
            "steppedLine": false,
            "targets": [
              {
                "expr": "(\n  (1 - rate(node_cpu_seconds_total{job=\"node\", mode=\"idle\", instance=\"$instance\"}[$__interval]))\n/ ignoring(cpu) group_left\n  count without (cpu)( node_cpu_seconds_total{job=\"node\", mode=\"idle\", instance=\"$instance\"})\n)\n",
                "format": "time_series",
                "interval": "1m",
                "intervalFactor": 5,
                "legendFormat": "{{cpu}}",
                "refId": "A"
              }
            ],
            "thresholds": [],
            "timeFrom": null,
            "timeShift": null,
            "title": "CPU Usage",
            "tooltip": {
              "shared": true,
              "sort": 0,
              "value_type": "individual"
            },
            "type": "graph",
            "xaxis": {
              "buckets": null,
              "mode": "time",
              "name": null,
              "show": true,
              "values": []
            },
            "yaxes": [
              {
                "format": "percentunit",
                "label": null,
                "logBase": 1,
                "max": 1,
                "min": 0,
                "show": true
              },
              {
                "format": "percentunit",
                "label": null,
                "logBase": 1,
                "max": 1,
                "min": 0,
                "show": true
              }
            ]
          },
          {
            "aliasColors": {},
            "bars": false,
            "dashLength": 10,
            "dashes": false,
            "datasource": "$datasource",
            "fill": 0,
            "fillGradient": 0,
            "gridPos": {},
            "id": 3,
            "legend": {
              "alignAsTable": false,
              "avg": false,
              "current": false,
              "max": false,
              "min": false,
              "rightSide": false,
              "show": true,
              "sideWidth": null,
              "total": false,
              "values": false
            },
            "lines": true,
            "linewidth": 1,
            "links": [],
            "nullPointMode": "null",
            "percentage": false,
            "pointradius": 5,
            "points": false,
            "renderer": "flot",
            "repeat": null,
            "seriesOverrides": [],
            "spaceLength": 10,
            "span": 6,
            "stack": false,
            "steppedLine": false,
            "targets": [
              {
                "expr": "node_load1{job=\"node\", instance=\"$instance\"}",
                "format": "time_series",
                "intervalFactor": 2,
                "legendFormat": "1m load average",
                "refId": "A"
              },
              {
                "expr": "node_load5{job=\"node\", instance=\"$instance\"}",
                "format": "time_series",
                "intervalFactor": 2,
                "legendFormat": "5m load average",
                "refId": "B"
              },
              {
                "expr": "node_load15{job=\"node\", instance=\"$instance\"}",
                "format": "time_series",
                "intervalFactor": 2,
                "legendFormat": "15m load average",
                "refId": "C"
              },
              {
                "expr": "count(node_cpu_seconds_total{job=\"node\", instance=\"$instance\", mode=\"idle\"})",
                "format": "time_series",
                "intervalFactor": 2,
                "legendFormat": "logical cores",
                "refId": "D"
              }
            ],
            "thresholds": [],
            "timeFrom": null,
            "timeShift": null,
            "title": "Load Average",
            "tooltip": {
              "shared": true,
              "sort": 0,
              "value_type": "individual"
            },
            "type": "graph",
            "xaxis": {
              "buckets": null,
              "mode": "time",
              "name": null,
              "show": true,
              "values": []
            },
            "yaxes": [
              {
                "format": "short",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": 0,
                "show": true
              },
              {
                "format": "short",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": 0,
                "show": true
              }
            ]
          }
        ],
        "repeat": null,
        "repeatIteration": null,
        "repeatRowId": null,
        "showTitle": false,
        "title": "Dashboard Row",
        "titleSize": "h6",
        "type": "row"
      },
      {
        "collapse": false,
        "collapsed": false,
        "panels": [
          {
            "aliasColors": {},
            "bars": false,
            "dashLength": 10,
            "dashes": false,
            "datasource": "$datasource",
            "fill": 1,
            "fillGradient": 0,
            "gridPos": {},
            "id": 4,
            "legend": {
              "alignAsTable": false,
              "avg": false,
              "current": false,
              "max": false,
              "min": false,
              "rightSide": false,
              "show": true,
              "sideWidth": null,
              "total": false,
              "values": false
            },
            "lines": true,
            "linewidth": 1,
            "links": [],
            "nullPointMode": "null",
            "percentage": false,
            "pointradius": 5,
            "points": false,
            "renderer": "flot",
            "repeat": null,
            "seriesOverrides": [],
            "spaceLength": 10,
            "span": 9,
            "stack": true,
            "steppedLine": false,
            "targets": [
              {
                "expr": "(\n  node_memory_MemTotal_bytes{job=\"node\", instance=\"$instance\"}\n-\n  node_memory_MemFree_bytes{job=\"node\", instance=\"$instance\"}\n-\n  node_memory_Buffers_bytes{job=\"node\", instance=\"$instance\"}\n-\n  node_memory_Cached_bytes{job=\"node\", instance=\"$instance\"}\n)\n",
                "format": "time_series",
                "intervalFactor": 2,
                "legendFormat": "memory used",
                "refId": "A"
              },
              {
                "expr": "node_memory_Buffers_bytes{job=\"node\", instance=\"$instance\"}",
                "format": "time_series",
                "intervalFactor": 2,
                "legendFormat": "memory buffers",
                "refId": "B"
              },
              {
                "expr": "node_memory_Cached_bytes{job=\"node\", instance=\"$instance\"}",
                "format": "time_series",
                "intervalFactor": 2,
                "legendFormat": "memory cached",
                "refId": "C"
              },
              {
                "expr": "node_memory_MemFree_bytes{job=\"node\", instance=\"$instance\"}",
                "format": "time_series",
                "intervalFactor": 2,
                "legendFormat": "memory free",
                "refId": "D"
              }
            ],
            "thresholds": [],
            "timeFrom": null,
            "timeShift": null,
            "title": "Memory Usage",
            "tooltip": {
              "shared": true,
              "sort": 0,
              "value_type": "individual"
            },
            "type": "graph",
            "xaxis": {
              "buckets": null,
              "mode": "time",
              "name": null,
              "show": true,
              "values": []
            },
            "yaxes": [
              {
                "format": "bytes",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": 0,
                "show": true
              },
              {
                "format": "bytes",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": 0,
                "show": true
              }
            ]
          },
          {
            "cacheTimeout": null,
            "colorBackground": false,
            "colorValue": false,
            "colors": [
              "rgba(50, 172, 45, 0.97)",
              "rgba(237, 129, 40, 0.89)",
              "rgba(245, 54, 54, 0.9)"
            ],
            "datasource": "$datasource",
            "format": "percent",
            "gauge": {
              "maxValue": 100,
              "minValue": 0,
              "show": true,
              "thresholdLabels": false,
              "thresholdMarkers": true
            },
            "gridPos": {},
            "id": 5,
            "interval": null,
            "links": [],
            "mappingType": 1,
            "mappingTypes": [
              {
                "name": "value to text",
                "value": 1
              },
              {
                "name": "range to text",
                "value": 2
              }
            ],
            "maxDataPoints": 100,
            "nullPointMode": "connected",
            "nullText": null,
            "postfix": "",
            "postfixFontSize": "50%",
            "prefix": "",
            "prefixFontSize": "50%",
            "rangeMaps": [
              {
                "from": "null",
                "text": "N/A",
                "to": "null"
              }
            ],
            "span": 3,
            "sparkline": {
              "fillColor": "rgba(31, 118, 189, 0.18)",
              "full": false,
              "lineColor": "rgb(31, 120, 193)",
              "show": false
            },
            "tableColumn": "",
            "targets": [
              {
                "expr": "100 -\n(\n  avg(node_memory_MemAvailable_bytes{job=\"node\", instance=\"$instance\"})\n/\n  avg(node_memory_MemTotal_bytes{job=\"node\", instance=\"$instance\"})\n* 100\n)\n",
                "format": "time_series",
                "intervalFactor": 2,
                "legendFormat": "",
                "refId": "A"
              }
            ],
            "thresholds": "80, 90",
            "title": "Memory Usage",
            "type": "singlestat",
            "valueFontSize": "80%",
            "valueMaps": [
              {
                "op": "=",
                "text": "N/A",
                "value": "null"
              }
            ],
            "valueName": "current"
          }
        ],
        "repeat": null,
        "repeatIteration": null,
        "repeatRowId": null,
        "showTitle": false,
        "title": "Dashboard Row",
        "titleSize": "h6",
        "type": "row"
      },
      {
        "collapse": false,
        "collapsed": false,
        "panels": [
          {
            "aliasColors": {},
            "bars": false,
            "dashLength": 10,
            "dashes": false,
            "datasource": "$datasource",
            "fill": 0,
            "fillGradient": 0,
            "gridPos": {},
            "id": 6,
            "legend": {
              "alignAsTable": false,
              "avg": false,
              "current": false,
              "max": false,
              "min": false,
              "rightSide": false,
              "show": true,
              "sideWidth": null,
              "total": false,
              "values": false
            },
            "lines": true,
            "linewidth": 1,
            "links": [],
            "nullPointMode": "null",
            "percentage": false,
            "pointradius": 5,
            "points": false,
            "renderer": "flot",
            "repeat": null,
            "seriesOverrides": [
              {
                "alias": "/ read| written/",
                "yaxis": 1
              },
              {
                "alias": "/ io time/",
                "yaxis": 2
              }
            ],
            "spaceLength": 10,
            "span": 6,
            "stack": false,
            "steppedLine": false,
            "targets": [
              {
                "expr": "rate(node_disk_read_bytes_total{job=\"node\", instance=\"$instance\", device!=\"\"}[$__interval])",
                "format": "time_series",
                "interval": "1m",
                "intervalFactor": 2,
                "legendFormat": "{{device}} read",
                "refId": "A"
              },
              {
                "expr": "rate(node_disk_written_bytes_total{job=\"node\", instance=\"$instance\", device!=\"\"}[$__interval])",
                "format": "time_series",
                "interval": "1m",
                "intervalFactor": 2,
                "legendFormat": "{{device}} written",
                "refId": "B"
              },
              {
                "expr": "rate(node_disk_io_time_seconds_total{job=\"node\", instance=\"$instance\", device!=\"\"}[$__interval])",
                "format": "time_series",
                "interval": "1m",
                "intervalFactor": 2,
                "legendFormat": "{{device}} io time",
                "refId": "C"
              }
            ],
            "thresholds": [],
            "timeFrom": null,
            "timeShift": null,
            "title": "Disk I/O",
            "tooltip": {
              "shared": true,
              "sort": 0,
              "value_type": "individual"
            },
            "type": "graph",
            "xaxis": {
              "buckets": null,
              "mode": "time",
              "name": null,
              "show": true,
              "values": []
            },
            "yaxes": [
              {
                "format": "bytes",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": null,
                "show": true
              },
              {
                "format": "s",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": null,
                "show": true
              }
            ]
          },
          {
            "aliasColors": {},
            "bars": false,
            "dashLength": 10,
            "dashes": false,
            "datasource": "$datasource",
            "fill": 1,
            "fillGradient": 0,
            "gridPos": {},
            "id": 7,
            "legend": {
              "alignAsTable": false,
              "avg": false,
              "current": false,
              "max": false,
              "min": false,
              "rightSide": false,
              "show": true,
              "sideWidth": null,
              "total": false,
              "values": false
            },
            "lines": true,
            "linewidth": 1,
            "links": [],
            "nullPointMode": "null",
            "percentage": false,
            "pointradius": 5,
            "points": false,
            "renderer": "flot",
            "repeat": null,
            "seriesOverrides": [
              {
                "alias": "used",
                "color": "#E0B400"
              },
              {
                "alias": "available",
                "color": "#73BF69"
              }
            ],
            "spaceLength": 10,
            "span": 6,
            "stack": true,
            "steppedLine": false,
            "targets": [
              {
                "expr": "sum(\n  max by (device) (\n    node_filesystem_size_bytes{job=\"node\", instance=\"$instance\", fstype!=\"\"}\n  -\n    node_filesystem_avail_bytes{job=\"node\", instance=\"$instance\", fstype!=\"\"}\n  )\n)\n",
                "format": "time_series",
                "intervalFactor": 2,
                "legendFormat": "used",
                "refId": "A"
              },
              {
                "expr": "sum(\n  max by (device) (\n    node_filesystem_avail_bytes{job=\"node\", instance=\"$instance\", fstype!=\"\"}\n  )\n)\n",
                "format": "time_series",
                "intervalFactor": 2,
                "legendFormat": "available",
                "refId": "B"
              }
            ],
            "thresholds": [],
            "timeFrom": null,
            "timeShift": null,
            "title": "Disk Space Usage",
            "tooltip": {
              "shared": true,
              "sort": 0,
              "value_type": "individual"
            },
            "type": "graph",
            "xaxis": {
              "buckets": null,
              "mode": "time",
              "name": null,
              "show": true,
              "values": []
            },
            "yaxes": [
              {
                "format": "bytes",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": 0,
                "show": true
              },
              {
                "format": "bytes",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": 0,
                "show": true
              }
            ]
          }
        ],
        "repeat": null,
        "repeatIteration": null,
        "repeatRowId": null,
        "showTitle": false,
        "title": "Dashboard Row",
        "titleSize": "h6",
        "type": "row"
      },
      {
        "collapse": false,
        "collapsed": false,
        "panels": [
          {
            "aliasColors": {},
            "bars": false,
            "dashLength": 10,
            "dashes": false,
            "datasource": "$datasource",
            "fill": 0,
            "fillGradient": 0,
            "gridPos": {},
            "id": 8,
            "legend": {
              "alignAsTable": false,
              "avg": false,
              "current": false,
              "max": false,
              "min": false,
              "rightSide": false,
              "show": true,
              "sideWidth": null,
              "total": false,
              "values": false
            },
            "lines": true,
            "linewidth": 1,
            "links": [],
            "nullPointMode": "null",
            "percentage": false,
            "pointradius": 5,
            "points": false,
            "renderer": "flot",
            "repeat": null,
            "seriesOverrides": [],
            "spaceLength": 10,
            "span": 6,
            "stack": false,
            "steppedLine": false,
            "targets": [
              {
                "expr": "rate(node_network_receive_bytes_total{job=\"node\", instance=\"$instance\", device!=\"lo\"}[$__interval])",
                "format": "time_series",
                "interval": "1m",
                "intervalFactor": 2,
                "legendFormat": "{{device}}",
                "refId": "A"
              }
            ],
            "thresholds": [],
            "timeFrom": null,
            "timeShift": null,
            "title": "Network Received",
            "tooltip": {
              "shared": true,
              "sort": 0,
              "value_type": "individual"
            },
            "type": "graph",
            "xaxis": {
              "buckets": null,
              "mode": "time",
              "name": null,
              "show": true,
              "values": []
            },
            "yaxes": [
              {
                "format": "bytes",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": 0,
                "show": true
              },
              {
                "format": "bytes",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": 0,
                "show": true
              }
            ]
          },
          {
            "aliasColors": {},
            "bars": false,
            "dashLength": 10,
            "dashes": false,
            "datasource": "$datasource",
            "fill": 0,
            "fillGradient": 0,
            "gridPos": {},
            "id": 9,
            "legend": {
              "alignAsTable": false,
              "avg": false,
              "current": false,
              "max": false,
              "min": false,
              "rightSide": false,
              "show": true,
              "sideWidth": null,
              "total": false,
              "values": false
            },
            "lines": true,
            "linewidth": 1,
            "links": [],
            "nullPointMode": "null",
            "percentage": false,
            "pointradius": 5,
            "points": false,
            "renderer": "flot",
            "repeat": null,
            "seriesOverrides": [],
            "spaceLength": 10,
            "span": 6,
            "stack": false,
            "steppedLine": false,
            "targets": [
              {
                "expr": "rate(node_network_transmit_bytes_total{job=\"node\", instance=\"$instance\", device!=\"lo\"}[$__interval])",
                "format": "time_series",
                "interval": "1m",
                "intervalFactor": 2,
                "legendFormat": "{{device}}",
                "refId": "A"
              }
            ],
            "thresholds": [],
            "timeFrom": null,
            "timeShift": null,
            "title": "Network Transmitted",
            "tooltip": {
              "shared": true,
              "sort": 0,
              "value_type": "individual"
            },
            "type": "graph",
            "xaxis": {
              "buckets": null,
              "mode": "time",
              "name": null,
              "show": true,
              "values": []
            },
            "yaxes": [
              {
                "format": "bytes",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": 0,
                "show": true
              },
              {
                "format": "bytes",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": 0,
                "show": true
              }
            ]
          }
        ],
        "repeat": null,
        "repeatIteration": null,
        "repeatRowId": null,
        "showTitle": false,
        "title": "Dashboard Row",
        "titleSize": "h6",
        "type": "row"
      }
    ],
    "schemaVersion": 14,
    "style": "dark",
    "tags": [],
    "templating": {
      "list": [
        {
          "current": {
            "text": "Prometheus",
            "value": "Prometheus"
          },
          "hide": 0,
          "label": null,
          "name": "datasource",
          "options": [],
          "query": "prometheus",
          "refresh": 1,
          "regex": "",
          "type": "datasource"
        },
        {
          "allValue": null,
          "current": {},
          "datasource": "$datasource",
          "hide": 0,
          "includeAll": false,
          "label": null,
          "multi": false,
          "name": "instance",
          "options": [],
          "query": "label_values(node_exporter_build_info{job=\"node\"}, instance)",
          "refresh": 2,
          "regex": "",
          "sort": 0,
          "tagValuesQuery": "",
          "tags": [],
          "tagsQuery": "",
          "type": "query",
          "useTags": false
        }
      ]
    },
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "timepicker": {
      "refresh_intervals": [
        "5s",
        "10s",
        "30s",
        "1m",
        "5m",
        "15m",
        "30m",
        "1h",
        "2h",
        "1d"
      ],
      "time_options": [
        "5m",
        "15m",
        "1h",
        "6h",
        "12h",
        "24h",
        "2d",
        "7d",
        "30d"
      ]
    },
    "timezone": "browser",
    "title": "node-dash",
    "version": 0,
    "description": "A quickstart to setup Prometheus Node Exporter with preconfigured dashboards, alerting rules, and recording rules."
  }'
  mode '0755'
  owner 'grafana'
  group 'grafana'
end

# load dashboard
grafana_dashboard 'node-dash' do
  dashboard(
    path: '/etc/grafana/provisioning/dashboards/node-dash.json'
  )
end
