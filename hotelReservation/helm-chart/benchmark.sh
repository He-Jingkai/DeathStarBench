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

replicas=3
helm install hotel-reservation ./hotelreservation -n hotel-reservation \
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

helm install hotel-reservation ./hotelreservation -n hotel-reservation \
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

grace "kubectl get pods --all-namespaces | grep hotel-reservation | grep -v Running" 30

#  --set wrk2.script choose from mixed-workload_type_1.lua recommend.lua reserve.lua search_hotel.lua
helm install wrk2-benchmark ./wrk2 -n hotel-reservation \
    --set wrk2.RPS=10                         \
    --set wrk2.duration=20                      \
    --set wrk2.connections=2                  \
    --set wrk2.initDelay=10                      \
    --set wrk2.script=recommend.lua    \
    --set wrk2.appImage=registry.cn-hangzhou.aliyuncs.com/jkhe/wrk2:2.6 \
    --set nodeName=val16

while kubectl get jobs -n hotel-reservation \
            | grep wrk2-benchmark \
            | grep -qv 1/1; do
        sleep 10
done


kubectl label node snic-val17 offmesh.test.waypoint.target=target
kubectl label node val17 offmesh.test.waypoint.target=target
kubectl label node snic-val16 offmesh.test.waypoint.target=target
helm install hotel-reservation-gateway ./gateways -n hotel-reservation

helm delete hotel-reservation-gateway -n hotel-reservation

kubectl label node snic-val16 offmesh.test.waypoint.target-

kubectl logs -n hotel-reservation job/wrk2-benchmark

helm delete wrk2-benchmark -n hotel-reservation
helm delete hotel-reservation -n hotel-reservation
