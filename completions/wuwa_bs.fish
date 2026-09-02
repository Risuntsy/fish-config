# Flags handled by _game_run; anything else is forwarded to the launcher executable.
complete -c wuwa_bs -l enable-wayland -d "Enable Proton Wayland"
complete -c wuwa_bs -l disable-gamemode -d "Disable GameMode"
complete -c wuwa_bs -l enable-mangohud -d "Enable MangoHud"
complete -c wuwa_bs -l labwc -d "Run inside a nested labwc session"
complete -c wuwa_bs -l headless -d "Use the headless WLR backend (labwc only)"
complete -c wuwa_bs -l disable-wayvnc -d "Disable wayVNC (headless labwc only)"
