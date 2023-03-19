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
replicas=3

helm install media-microsvcs ./mediamicroservices -n media-microsvcs \
    --set cast-info-service.replicas=$replicas          \
    --set compose-review-service.replicas=$replicas     \
    --set movie-id-service.replicas=$replicas           \
    --set movie-info-service.replicas=$replicas         \
    --set movie-review-service.replicas=$replicas       \
    --set nginx-web-server.replicas=$replicas           \
    --set page-service.replicas=$replicas               \
    --set plot-service.replicas=$replicas               \
    --set rating-service.replicas=$replicas             \
    --set review-storage-service.replicas=$replicas     \
    --set text-service.replicas=$replicas               \
    --set unique-id-service.replicas=$replicas          \
    --set user-review-service.replicas=$replicas        \
    --set user-service.replicas=$replicas

grace "kubectl get pods --all-namespaces | grep media-microsvcs | grep -v Running" 30

# --set graph choose from socfb-Reed98, ego-twitter, soc-twitter-follows-mun
# --set args.compose=true to intialize with up to 20 posts per user
helm install init-media-microsvcs ./init-media-microsvcs -n media-microsvcs --set args.graph=socfb-Reed98

while kubectl get jobs -n media-microsvcs \
            | grep init-media-microsvcs \
            | grep -qv 1/1; do
        sleep 10
done

#  --set wrk2.script choose from compose-post.lua  mixed-workload.lua  read-home-timeline.lua  read-user-timeline.lua
helm install wrk2-benchmark ./wrk2 -n media-microsvcs \
    --set wrk2.RPS=2000                         \
    --set wrk2.duration=20                      \
    --set wrk2.connections=128                  \
    --set wrk2.initDelay=6                      \
    --set wrk2.script=read-user-timeline.lua    \
    --set wrk2.appImage=registry.cn-hangzhou.aliyuncs.com/jkhe/wrk2:2.5

while kubectl get jobs -n media-microsvcs \
            | grep wrk2-benchmark \
            | grep -qv 1/1; do
        sleep 10
done

kubectl logs -n media-microsvcs job/wrk2-benchmark

helm delete wrk2-benchmark -n media-microsvcs
helm delete init-media-microsvcs -n media-microsvcs
helm delete media-microsvcs -n media-microsvcs
