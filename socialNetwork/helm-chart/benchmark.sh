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
    --set compose-post-service.nodeName=val17  \
    --set home-timeline-service.nodeName=val17     \
    --set home-timeline-redis.nodeName=val17      \
    --set jaeger.nodeName=val17      \
    --set media-frontend.nodeName=val16      \
    --set media-memcached.nodeName=val17      \
    --set media-mongodb.nodeName=val17      \
    --set media-service.nodeName=val17             \
    --set nginx-thrift.nodeName=val16              \
    --set post-storage-memcached.nodeName=val17      \
    --set post-storage-mongodb.nodeName=val17      \
    --set post-storage-service.nodeName=val17      \
    --set social-graph-mongodb.nodeName=val17      \
    --set social-graph-redis.nodeName=val17      \
    --set social-graph-service.nodeName=val17      \
    --set text-service.nodeName=val17             \
    --set unique-id-service.nodeName=val17         \
    --set url-shorten-memcached.nodeName=val17       \
    --set url-shorten-mongodb.nodeName=val17       \
    --set url-shorten-service.nodeName=val17       \
    --set user-mention-service.nodeName=val17      \
    --set user-memcached.nodeName=val17              \
    --set user-mongodb.nodeName=val17              \
    --set user-service.nodeName=val17              \
    --set user-timeline-service.nodeName=val17    \
    --set user-timeline-mongodb.nodeName=val17    \
    --set user-timeline-redis.nodeName=val17    
    # --set compose-post-service.replicas=3      \
    # --set home-timeline-service.replicas=3     \
    # --set media-service.replicas=3             \
    # --set nginx-thrift.replicas=3              \
    # --set post-storage-service.replicas=3      \
    # --set social-graph-service.replicas=3      \
    # --set text-service.replicas=3              \
    # --set unique-id-service.replicas=3         \
    # --set url-shorten-service.replicas=3       \
    # --set user-mention-service.replicas=3      \
    # --set user-service.replicas=3              \
    # --set user-timeline-service.replicas=3    \

helm install social-network ./socialnetwork -n social-network \
    --set compose-post-service.nodeName=snic-val17  \
    --set home-timeline-service.nodeName=snic-val17     \
    --set home-timeline-redis.nodeName=snic-val17      \
    --set jaeger.nodeName=snic-val17      \
    --set media-frontend.nodeName=val16      \
    --set media-memcached.nodeName=snic-val17      \
    --set media-mongodb.nodeName=snic-val17      \
    --set media-service.nodeName=snic-val17             \
    --set nginx-thrift.nodeName=val16              \
    --set post-storage-memcached.nodeName=snic-val17      \
    --set post-storage-mongodb.nodeName=snic-val17      \
    --set post-storage-service.nodeName=snic-val17      \
    --set social-graph-mongodb.nodeName=snic-val17      \
    --set social-graph-redis.nodeName=snic-val17      \
    --set social-graph-service.nodeName=snic-val17      \
    --set text-service.nodeName=snic-val17             \
    --set unique-id-service.nodeName=snic-val17         \
    --set url-shorten-memcached.nodeName=snic-val17       \
    --set url-shorten-mongodb.nodeName=snic-val17       \
    --set url-shorten-service.nodeName=snic-val17       \
    --set user-mention-service.nodeName=snic-val17      \
    --set user-memcached.nodeName=snic-val17              \
    --set user-mongodb.nodeName=snic-val17              \
    --set user-service.nodeName=snic-val17              \
    --set user-timeline-service.nodeName=snic-val17    \
    --set user-timeline-mongodb.nodeName=snic-val17    \
    --set user-timeline-redis.nodeName=snic-val17  

    
grace "kubectl get pods --all-namespaces | grep social-network | grep -v Running" 30

kubectl label node snic-val17 offmesh.test.waypoint.target=target
kubectl label node val17 offmesh.test.waypoint.target=target
kubectl label node snic-val16 offmesh.test.waypoint.target=target
helm install social-network-gateway ./gateways -n social-network 

# --set graph choose from socfb-Reed98, ego-twitter, soc-twitter-follows-mun
# --set args.compose=true to intialize with up to 20 posts per user
helm install init-social-network ./init-social-graph -n social-network --set args.graph=socfb-Reed98 --set nodeName=val16

while kubectl get jobs -n social-network \
            | grep init-social-graph \
            | grep -qv 1/1; do
        sleep 10
done

#  --set wrk2.script choose from compose-post.lua  mixed-workload.lua  read-home-timeline.lua  read-user-timeline.lua
#  --set wrk2.url http://nginx-thrift.social-network:8080/wrk2-api/home-timeline/read http://nginx-thrift.social-network:8080/wrk2-api/user-timeline/read 
# http://nginx-thrift.social-network:8080/wrk2-api/post/compose
helm install wrk2-benchmark ./wrk2 -n social-network \
    --set wrk2.RPS=10                         \
    --set wrk2.duration=150                      \
    --set wrk2.connections=2                  \
    --set wrk2.initDelay=10                      \
    --set wrk2.script=read-user-timeline.lua   \
    --set wrk2.appImage=registry.cn-hangzhou.aliyuncs.com/jkhe/wrk2:2.6   \
    --set wrk2.url=http://nginx-thrift.social-network:8080/wrk2-api/user-timeline/read \
    --set nodeName=val16

while kubectl get jobs -n social-network \
            | grep wrk2-benchmark \
            | grep -qv 1/1; do
        sleep 10
done

kubectl logs -n social-network job/wrk2-benchmark

helm delete social-network-gateway -n social-network

kubectl label node snic-val16 offmesh.test.waypoint.target-

helm delete wrk2-benchmark -n social-network
helm delete init-social-network -n social-network
helm delete social-network -n social-network
