FROM hejingkai/wrk2-prometheus:latest
COPY benchmark.sh /usr/local/bin/benchmark
RUN rm /usr/local/bin/multiple-endpoints-prometheus-metrics.lua /usr/local/bin/prometheus-export-wrapper
ENTRYPOINT ["/usr/local/bin/benchmark"]
# registry.cn-hangzhou.aliyuncs.com/jkhe/wrk2:2.6