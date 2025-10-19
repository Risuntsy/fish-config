function config_font
    code ~/.config/fontconfig --profile common && exit
end

function config_arch
    code ~/Note/memo/os/linux/distro/arch --profile web && exit
end

function config_sysctl
    kate /etc/sysctl.d/99-sysctl.conf
end

function config_hosts
    EDITOR=vim sudo -e /etc/hosts
end
