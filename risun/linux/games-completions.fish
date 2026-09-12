# Loaded by risun/import.fish with the other Linux configuration files.
for game in alice_in_cradle arknights endfield endfield_daily hypergryph_launcher naraka wuwa wuwa_bs wuwa_daily
    set -l labwc_only " (labwc only)"
    set -l headless_only " (headless labwc only)"
    if contains -- $game endfield_daily wuwa_daily
        set labwc_only ""
        set headless_only " (headless only)"
    else
        complete -c $game -l enable-wayland -d "Enable Proton Wayland"
        complete -c $game -l disable-gamemode -d "Disable GameMode"
        complete -c $game -l labwc -d "Run inside a nested labwc session"
    end

    complete -c $game -l enable-mangohud -d "Enable MangoHud"
    complete -c $game -l headless -d "Use the headless WLR backend and start wayVNC$labwc_only"
    complete -c $game -l disable-wayvnc -d "Disable wayVNC$headless_only"
end

for game in wuwa wuwa_daily
    complete -c $game -l enable-dx11 -d "Enable DX11 mode"
    complete -c $game -l disable-csharp -d "Leave the C# environment to the server"
end

complete -c aic --wraps alice_in_cradle

for game in aic alice_in_cradle arknights endfield endfield_daily hypergryph_launcher naraka wineserver wuwa wuwa_daily
    complete -c {$game}_kill -f
end

complete -c hypergryph_launcher_install -f
complete -c hypergryph_launcher_install -l installer -d "Path to the Hypergryph installer .exe" \
    -r -a '(__fish_complete_suffix .exe)'
