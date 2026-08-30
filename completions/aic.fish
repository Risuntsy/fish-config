# Flags handled by _game_run; anything else is forwarded to the game executable.
complete -c aic -l enable-wayland -d "Enable Proton Wayland"
complete -c aic -l disable-gamemode -d "Disable GameMode"
complete -c aic -l enable-mangohud -d "Enable MangoHud"
complete -c aic -l labwc -d "Run inside a nested labwc session"
complete -c aic -l headless -d "Use the headless WLR backend (labwc only)"
complete -c aic -l disable-wayvnc -d "Disable wayVNC (headless labwc only)"
