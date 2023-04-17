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


# consul
# jaeger
# ---
# frontend
# ---
# search
# ---
# geo
# mongodb-geo
# ---
# profile
# memcached-profile
# mongodb-profile
# ---
# rate
# memcached-rate
# mongodb-rate
# ---
# reservation
# memcached-reserve
# mongodb-reservation
# ---
# recommendation
# mongodb-recommendation
# ---
# user
# mongodb-user

kubectl create ns hotel-reserve
kubectl label ns hotel-reserve istio.io/dataplane-mode=ambient
replicas=3
helm install hotel-reserve ./hotelreservation -n hotel-reserve \
    --set consul.nodeName=snic-val17  \
    --set geo.nodeName=snic-val17  \
    --set memcached-profile.nodeName=snic-val17  \
    --set memcached-reserve.nodeName=snic-val17  \
    --set mongodb-profile.nodeName=snic-val17  \
    --set mongodb-recommendation.nodeName=snic-val17  \
    --set mongodb-user.nodeName=snic-val17  \
    --set rate.nodeName=snic-val17  \
    --set reservation.nodeName=snic-val17  \
    --set user.nodeName=snic-val17  \
    --set jaeger.nodeName=snic-val17  \
    --set memcached-rate.nodeName=snic-val17  \
    --set mongodb-geo.nodeName=snic-val17  \
    --set mongodb-rate.nodeName=snic-val17  \
    --set mongodb-reservation.nodeName=snic-val17  \
    --set profile.nodeName=snic-val17  \
    --set recommendation.nodeName=snic-val17  \
    --set search.nodeName=snic-val17  \
    --set frontend.nodeName=val16

helm install hotel-reserve ./hotelreservation -n hotel-reserve \
    --set consul.nodeName=val17  \
    --set geo.nodeName=val17  \
    --set memcached-profile.nodeName=val17  \
    --set memcached-reserve.nodeName=val17  \
    --set mongodb-profile.nodeName=val17  \
    --set mongodb-recommendation.nodeName=val17  \
    --set mongodb-user.nodeName=val17  \
    --set rate.nodeName=val17  \
    --set reservation.nodeName=val17  \
    --set user.nodeName=val17  \
    --set jaeger.nodeName=val17  \
    --set memcached-rate.nodeName=val17  \
    --set mongodb-geo.nodeName=val17  \
    --set mongodb-rate.nodeName=val17  \
    --set mongodb-reservation.nodeName=val17  \
    --set profile.nodeName=val17  \
    --set recommendation.nodeName=val17  \
    --set search.nodeName=val17  \
    --set frontend.nodeName=val16

    # --set frontend.replicas=$replicas          \
    # --set geo.replicas=$replicas     \
    # --set profile.replicas=$replicas           \
    # --set rate.replicas=$replicas         \
    # --set recommendation.replicas=$replicas       \
    # --set reservation.replicas=$replicas           \
    # --set search.replicas=$replicas               \
    # --set user.replicas=$replicas   

grace "kubectl get pods --all-namespaces | grep hotel-reserve | grep -v Running" 30

#  --set wrk2.script choose from mixed-workload_type_1.lua recommend.lua reserve.lua search_hotel.lua
helm install wrk2-benchmark ./wrk2 -n hotel-reserve \
    --set wrk2.RPS=2                         \
    --set wrk2.duration=120                      \
    --set wrk2.connections=2                  \
    --set wrk2.initDelay=10                      \
    --set wrk2.script=mixed-workload_type_1.lua   \
    --set wrk2.appImage=registry.cn-hangzhou.aliyuncs.com/jkhe/wrk2:2.6 \
    --set nodeName=val16

while kubectl get jobs -n hotel-reserve \
            | grep wrk2-benchmark \
            | grep -qv 1/1; do
        sleep 10
done


kubectl label node snic-val17 offmesh.test.waypoint.target=target
kubectl label node val17 offmesh.test.waypoint.target=target

helm install hotel-reserve-gateway ./gateways -n hotel-reserve

helm delete hotel-reserve-gateway -n hotel-reserve

kubectl label node val17 offmesh.test.waypoint.target-
kubectl label node snic-val17 offmesh.test.waypoint.target-

kubectl logs -n hotel-reserve job/wrk2-benchmark

helm delete wrk2-benchmark -n hotel-reserve
helm delete hotel-reserve -n hotel-reserve
