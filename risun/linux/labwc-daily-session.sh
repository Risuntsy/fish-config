#!/usr/bin/env sh

enable_wayvnc=1
output=HEADLESS-1

while test "$#" -gt 0; do
    case "$1" in
        --auto-output)
            output=
            shift
            ;;
        --disable-wayvnc)
            enable_wayvnc=0
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            break
            ;;
    esac
done

wayvnc_pid=
control_socket=

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    if test -n "$wayvnc_pid"; then
        kill "$wayvnc_pid" 2>/dev/null || :
        wait "$wayvnc_pid" 2>/dev/null || :
    fi
    if test -n "$control_socket"; then
        unlink "$control_socket" 2>/dev/null || :
    fi
    exit "$status"
}

trap cleanup EXIT HUP INT TERM

if test -z "$output"; then
    output=$(wlr-randr | awk 'NR == 1 { print $1; exit }')
fi

if test -z "$output"; then
    echo "labwc-daily-session: no output found" >&2
    exit 1
fi

if ! wlr-randr --output "$output" --custom-mode 1920x1080; then
    echo "labwc-daily-session: failed to configure $output as 1920x1080" >&2
    exit 1
fi

if test "$enable_wayvnc" -eq 0; then
    "$@"
    exit $?
fi

lock_file="${XDG_RUNTIME_DIR:-/tmp}/labwc-daily-wayvnc-$(id -u).lock"
exec 9>"$lock_file"
flock 9

wayvnc_port=5900
while test -n "$(ss -H -ltn "sport = :$wayvnc_port")"; do
    wayvnc_port=$((wayvnc_port + 1))
    if test "$wayvnc_port" -gt 65535; then
        echo "labwc-daily-session: no available VNC port" >&2
        exit 1
    fi
done

control_socket="${XDG_RUNTIME_DIR:-/tmp}/labwc-daily-wayvnc-$$.ctl"
wayvnc --socket="$control_socket" --output "$output" 127.0.0.1 "$wayvnc_port" &
wayvnc_pid=$!

# Keep port selection serialized until wayvnc has either bound the port or
# failed, so concurrently starting sessions cannot select the same port.
wayvnc_ready=0
attempt=0
while test "$attempt" -lt 100; do
    if ! kill -0 "$wayvnc_pid" 2>/dev/null; then
        break
    fi
    if test -n "$(ss -H -ltn "sport = :$wayvnc_port")"; then
        wayvnc_ready=1
        break
    fi
    sleep 0.05
    attempt=$((attempt + 1))
done

flock -u 9
exec 9>&-

if test "$wayvnc_ready" -ne 1; then
    echo "labwc-daily-session: wayvnc failed to listen on port $wayvnc_port" >&2
    exit 1
fi

printf 'labwc-daily-session: wayVNC listening on 127.0.0.1:%s\n' "$wayvnc_port"
"$@"
