# Flags handled by _game_run; anything else is forwarded to the game executable.
complete -c endfield_daily -l enable-gamemode -d "Enable GameMode"
complete -c endfield_daily -l enable-mangohud -d "Enable MangoHud"
complete -c endfield_daily -l headless -d "Use the headless WLR backend (labwc only)"
complete -c endfield_daily -l disable-wayvnc -d "Disable wayVNC (headless labwc only)"
