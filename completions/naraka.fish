# Flags handled by _game_run; anything else is forwarded to the game executable.
complete -c naraka -l enable-wayland -d "Enable Proton Wayland"
complete -c naraka -l disable-gamemode -d "Disable GameMode"
complete -c naraka -l enable-mangohud -d "Enable MangoHud"
complete -c naraka -l labwc -d "Run inside a nested labwc session"
complete -c naraka -l headless -d "Use the headless WLR backend (labwc only)"
complete -c naraka -l disable-wayvnc -d "Disable wayVNC (headless labwc only)"
