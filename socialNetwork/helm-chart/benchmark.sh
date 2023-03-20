function grace() {
    grace=10
    [ -n "$2" ] && grace="$2"
    while true; do
        eval $1
        if [ $? -eq 0 ]; then
            sleep 1
            grace=10
            [ -n "$2" ] && grace="$2"
            continue
        fi
        if [ $grace -gt 0 ]; then
            sleep 1
            echo "grace period: $grace"
            grace=$(($grace-1))
            continue
        fi
        break
    done
}

helm install social-network ./socialnetwork -n social-network \
    --set compose-post-service.replicas=3      \
    --set home-timeline-service.replicas=3     \
    --set media-service.replicas=3             \
    --set nginx-thrift.replicas=3              \
    --set post-storage-service.replicas=3      \
    --set social-graph-service.replicas=3      \
    --set text-service.replicas=3              \
    --set unique-id-service.replicas=3         \
    --set url-shorten-service.replicas=3       \
    --set user-mention-service.replicas=3      \
    --set user-service.replicas=3              \
    --set uuser-timeline-service.replicas=3

grace "kubectl get pods --all-namespaces | grep social-network | grep -v Running" 30

# --set graph choose from socfb-Reed98, ego-twitter, soc-twitter-follows-mun
# --set args.compose=true to intialize with up to 20 posts per user
helm install init-social-network ./init-social-graph -n social-network --set args.graph=socfb-Reed98

while kubectl get jobs -n social-network \
            | grep init-social-graph \
            | grep -qv 1/1; do
        sleep 10
done

#  --set wrk2.script choose from compose-post.lua  mixed-workload.lua  read-home-timeline.lua  read-user-timeline.lua
helm install wrk2-benchmark ./wrk2 -n social-network \
    --set wrk2.RPS=2000                         \
    --set wrk2.duration=20                      \
    --set wrk2.connections=128                  \
    --set wrk2.initDelay=6                      \
    --set wrk2.script=read-user-timeline.lua    \
    --set wrk2.appImage=registry.cn-hangzhou.aliyuncs.com/jkhe/wrk2:2.6

while kubectl get jobs -n social-network \
            | grep wrk2-benchmark \
            | grep -qv 1/1; do
        sleep 10
done

kubectl logs -n social-network job/wrk2-benchmark

helm delete wrk2-benchmark -n social-network
helm delete init-social-network -n social-network
helm delete social-network -n social-network
