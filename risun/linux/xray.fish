function update_xray --description 'Update an official-script Xray installation on Fedora'
    if not _is_fedora
        echo 'update_xray is only supported on Fedora.' >&2
        return 1
    end

    if not test -x /usr/local/bin/xray; or not test -f /etc/systemd/system/xray.service; or not test -d /usr/local/etc/xray; or rpm -qf /usr/local/bin/xray >/dev/null 2>&1
        echo 'No official-script Xray installation found.' >&2
        return 1
    end

    curl -fsSL https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh | sudo bash -s -- install
    test (string join , $pipestatus) = 0,0
end
