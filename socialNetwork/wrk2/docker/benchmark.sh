#!/bin/ash

conn=10
rps=10
dur=60
init_delay=0
wrk_timeout=10

usage() {
    echo " -c <connections> - Number of concurrent connections. Default: $conn"
    echo " -r <rps> - Target rate of requests per second. Default: $rps"
    echo " -d <duration> - Test duration in seconds. Default: $dur"
    echo " -i <duration> - Initial delay (sleep time before start) in seconds"
    echo "                 Default: $init_delay"
    echo "                     Use 'stdout' to just print to standard output."
    echo "                     Use 'null' to suppress output (for debugging)."
    echo " -o <wrk_timeout> "
    echo " -s <lua_file_name> "
}

# --

[ -z "$1" -o "help" = "$1" -o "-h" = "$1" -o "--help" = "$1" ] && {
    usage
    exit 0
}

servers=""
lua_file=""
i=1; next=""
for arg do
    [ "$arg" = "-c" ] &&  { next="conn"; continue; }
    [ "$arg" = "-r" ] &&  { next="rps"; continue; }
    [ "$arg" = "-d" ] &&  { next="dur"; continue; }
    [ "$arg" = "-i" ] &&  { next="init_delay"; continue; }
    [ "$arg" = "-o" ] &&  { next="wrk_timeout"; continue; }
    [ "$arg" = "-s" ] &&  { next="lua_file"; continue; }

    [ -n "$next" ] && { eval $next="$arg"; next=""; continue; }

    servers="$servers $arg"
done

[ $init_delay -ne 0 ] && {
    echo "Init delay: sleeping for $init_delay seconds."
    sleep "$init_delay"
    echo "Slept well, now starting benchmark"
}

duration_mul=$(echo "$dur" \
                   | awk '/s$/{print "1"} /m$/{print "60"} /h$/{print "3600"}')
[ -z "$duration_mul" ] && duration_mul=1
duration_val=$(echo "$dur" | sed 's/[^0-9]\+//g')
duration_s=$(( $duration_val * $duration_mul ))

echo
echo "Running stresser with:"
echo "   conn: $conn"
echo "   rps: $rps"
echo "   duration: $dur ($duration_s s)"
echo "   servers: $servers"
echo

sleep 1
first_server=$(echo $servers | sed 's/ .*//g')

# wait until first endpoint becomes available.
echo "Waiting for '$first_server' to become available"
timeout=120
st=$(date +%s)
ts="$st"
while [ $((st + timeout)) -ge $ts ]; do
    echo "    Trying $first_server (for $((st+timeout-ts)) more seconds) ..."
    curl -s -m 5 "$first_server" >/dev/null && break
    ts=$(date +%s)
    sleep 1
done
echo "'$first_server' responded, starting benchmark."
echo "----"
echo

echo --- benchmark start at $(date) ---

/usr/local/bin/wrk \
    --latency \
    -s /scripts/$lua_file \
    -U -R "$rps" -c "$conn" -t "$conn" -d "$dur" \
    -T "$wrk_timeout" \
    $first_server 

echo --- benchmark end at $(date) ---
