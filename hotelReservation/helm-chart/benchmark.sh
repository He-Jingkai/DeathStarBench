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
helm install hotel-reservation ./hotelreservation -n hotel-reservation \
    --set frontend.replicas=$replicas          \
    --set geo.replicas=$replicas     \
    --set profile.replicas=$replicas           \
    --set rate.replicas=$replicas         \
    --set recommendation.replicas=$replicas       \
    --set reservation.replicas=$replicas           \
    --set search.replicas=$replicas               \
    --set user.replicas=$replicas   

grace "kubectl get pods --all-namespaces | grep hotel-reservation | grep -v Running" 30

#  --set wrk2.script choose from mixed-workload_type_1.lua
helm install wrk2-benchmark ./wrk2 -n hotel-reservation \
    --set wrk2.RPS=2000                         \
    --set wrk2.duration=20                      \
    --set wrk2.connections=128                  \
    --set wrk2.initDelay=6                      \
    --set wrk2.script=mixed-workload_type_1.lua    \
    --set wrk2.appImage=registry.cn-hangzhou.aliyuncs.com/jkhe/wrk2:2.6

while kubectl get jobs -n hotel-reservation \
            | grep wrk2-benchmark \
            | grep -qv 1/1; do
        sleep 10
done

kubectl logs -n hotel-reservation job/wrk2-benchmark

helm delete wrk2-benchmark -n hotel-reservation
helm delete hotel-reservation -n hotel-reservation
