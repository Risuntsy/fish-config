# Flags handled by _game_run; anything else is forwarded to the game executable.
complete -c wuwa_daily -l enable-mangohud -d "Enable MangoHud"
complete -c wuwa_daily -l headless -d "Use the headless WLR backend (labwc only)"
complete -c wuwa_daily -l disable-wayvnc -d "Disable wayVNC (headless labwc only)"
complete -c wuwa_daily -l enable-dx11 -d "Enable DX11 mode"
complete -c wuwa_daily -l disable-csharp -d "Leave the C# environment to the server"
