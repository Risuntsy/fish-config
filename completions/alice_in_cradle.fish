# Flags handled by _game_run; anything else is forwarded to the game executable.
complete -c alice_in_cradle -l enable-wayland -d "Enable Proton Wayland"
complete -c alice_in_cradle -l disable-gamemode -d "Disable GameMode"
complete -c alice_in_cradle -l enable-mangohud -d "Enable MangoHud"
complete -c alice_in_cradle -l labwc -d "Run inside a nested labwc session"
complete -c alice_in_cradle -l headless -d "Use the headless WLR backend (labwc only)"
complete -c alice_in_cradle -l disable-wayvnc -d "Disable wayVNC (headless labwc only)"
