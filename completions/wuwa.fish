# Flags handled by _game_run; anything else is forwarded to the game executable.
complete -c wuwa -l enable-wayland -d "Enable Proton Wayland"
complete -c wuwa -l disable-gamemode -d "Disable GameMode"
complete -c wuwa -l enable-mangohud -d "Enable MangoHud"
complete -c wuwa -l labwc -d "Run inside a nested labwc session"
complete -c wuwa -l headless -d "Use the headless WLR backend (labwc only)"
complete -c wuwa -l disable-wayvnc -d "Disable wayVNC (headless labwc only)"
complete -c wuwa -l enable-dx11 -d "Enable DX11 mode"
