function code_config_font
    code_common ~/.config/fontconfig && exit
end

function kate_config_sysctl
    kate /etc/sysctl.d/99-sysctl.conf
end
