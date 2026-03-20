function systemd_user_restart --description "Reload user manager and restart user units"
    if test (count $argv) -eq 0
        echo "Usage: systemd_user_restart <unit...>"
        return 1
    end

    systemctl --user daemon-reload; or return $status
    systemctl --user restart $argv
end

function systemd_user_stop --description "Reload user manager and stop user units"
    if test (count $argv) -eq 0
        echo "Usage: systemd_user_stop <unit...>"
        return 1
    end

    systemctl --user daemon-reload; or return $status
    systemctl --user stop $argv
end

function systemd_user_start --description "Start user units"
    if test (count $argv) -eq 0
        echo "Usage: systemd_user_start <unit...>"
        return 1
    end

    systemctl --user daemon-reload; or return $status
    systemctl --user start $argv
end

function systemd_user_status --description "Show status for user units"
    if test (count $argv) -eq 0
        echo "Usage: systemd_user_status <unit...>"
        return 1
    end

    systemctl --user daemon-reload; or return $status
    systemctl --user status $argv
end
