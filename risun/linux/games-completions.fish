# Loaded by risun/import.fish with the other Linux configuration files.
for game in alice_in_cradle arknights endfield endfield_daily hypergryph_launcher naraka re1999 wuwa wuwa_bs wuwa_daily
    set -l labwc_only " (labwc only)"
    set -l headless_only " (headless labwc only)"
    if contains -- $game endfield_daily wuwa_daily
        set labwc_only ""
        set headless_only " (headless only)"
    else
        complete -c $game -l disable-gamemode -d "Disable GameMode"
        complete -c $game -l labwc -d "Run inside a nested labwc session"
    end

    complete -c $game -l disable-wayland -d "Disable Proton Wayland"
    complete -c $game -l enable-mangohud -d "Enable MangoHud"
    complete -c $game -l proton -r -a 'dw ge' -d "Proton family (system first) or build directory"
    complete -c $game -l headless -d "Use the headless WLR backend and start wayVNC$labwc_only"
    complete -c $game -l disable-wayvnc -d "Disable wayVNC$headless_only"
end

for game in wuwa wuwa_daily
    complete -c $game -l enable-dx11 -d "Enable DX11 mode"
    complete -c $game -l disable-csharp -d "Leave the C# environment to the server"
end

complete -c aic --wraps alice_in_cradle

for game in aic alice_in_cradle arknights endfield endfield_daily naraka wineserver wuwa wuwa_daily
    complete -c {$game}_kill -f
end

for game in aic alice_in_cradle arknights endfield endfield_daily naraka wuwa wuwa_daily
    complete -c {$game}_kill -l proton -r -a 'dw ge' -d "Proton family (system first) or build directory"
end

# hypergryph_launcher: the common game flags above, plus one action at a time.
set -l hypergryph_action '__fish_seen_argument -l install -l kill'
# No condition on --install: it would also hide the .exe paths after the flag.
complete -c hypergryph_launcher -l install -d "Extract a Hypergryph installer .exe into the prefix" \
    -r -F -a '(__fish_complete_suffix .exe)'
complete -c hypergryph_launcher -n "not $hypergryph_action" -l kill -d "Kill the launcher's wineserver"

set -l re1999_action '__fish_seen_argument -l install -l kill'
complete -c re1999 -l install -d "Run a Reverse: 1999 installer .exe in the game prefix" \
    -r -F -a '(__fish_complete_suffix .exe)'
complete -c re1999 -n "not $re1999_action" -l kill -d "Kill the game's wineserver"

# wuwa_launcher: one action at a time; plain launch accepts the usual game flags.
set -l wuwa_launcher_action '__fish_seen_argument -l install -l patch -l restore -l kill'
complete -c wuwa_launcher -f
# No condition on --install: it would also hide the .exe paths after the flag.
complete -c wuwa_launcher -l install -d "Run a Wuthering Waves installer .exe in the launcher prefix" \
    -r -F -a '(__fish_complete_suffix .exe)'
complete -c wuwa_launcher -n "not $wuwa_launcher_action" -l patch -d "Apply the WebView2 and launcher_main.dll fix only"
complete -c wuwa_launcher -n "not $wuwa_launcher_action" -l restore -d "Restore the unpatched launcher_main.dll"
complete -c wuwa_launcher -n "not $wuwa_launcher_action" -l kill -d "Kill the launcher's wineserver"
complete -c wuwa_launcher -l proton -r -a 'dw ge' -d "Proton family (system first) or build directory"
complete -c wuwa_launcher -n '__fish_not_contain_opt kill' -l launcher-dir -r -a '(__fish_complete_directories)' \
    -d "Launcher install directory"
complete -c wuwa_launcher -n '__fish_not_contain_opt patch restore kill' -l disable-gamemode -d "Disable GameMode"
complete -c wuwa_launcher -n '__fish_not_contain_opt patch restore kill' -l enable-mangohud -d "Enable MangoHud"
complete -c wuwa_launcher -n '__fish_not_contain_opt patch restore kill' -l labwc -d "Run inside a nested labwc session"
complete -c wuwa_launcher -n '__fish_not_contain_opt patch restore kill' -l headless -d "Use the headless WLR backend and start wayVNC (labwc only)"
complete -c wuwa_launcher -n '__fish_not_contain_opt patch restore kill' -l disable-wayvnc -d "Disable wayVNC (headless labwc only)"
