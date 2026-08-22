# Flags handled by _game_run; anything else is forwarded to the game executable.
complete -c endfield -l enable-wayland -d "Enable Proton Wayland"
complete -c endfield -l disable-gamemode -d "Disable GameMode"
complete -c endfield -l enable-mangohud -d "Enable MangoHud"
complete -c endfield -l labwc -d "Run inside a nested labwc session"
complete -c endfield -l headless -d "Use the headless WLR backend (labwc only)"
complete -c endfield -l disable-wayvnc -d "Disable wayVNC (headless labwc only)"
