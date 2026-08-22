# Flags handled by _game_run; anything else is forwarded to the game executable.
complete -c arknights -l enable-wayland -d "Enable Proton Wayland"
complete -c arknights -l enable-gamemode -d "Enable GameMode"
complete -c arknights -l enable-mangohud -d "Enable MangoHud"
complete -c arknights -l labwc -d "Run inside a nested labwc session"
complete -c arknights -l headless -d "Use the headless WLR backend (labwc only)"
complete -c arknights -l disable-wayvnc -d "Disable wayVNC (headless labwc only)"
