function sing_box_config_refresh
    if command -q curl and test -d /opt/homebrew/etc/sing-box
        curl https://myriad.risun.icu/sing-box?sign=79bbbd29fc \
            -o /opt/homebrew/etc/sing-box/config.json
        brew services restart sing-box
    end
end
