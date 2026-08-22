# Accepts the installer via --installer.
complete -c hypergryph_launcher_install -f
complete -c hypergryph_launcher_install -l installer -d "Path to the Hypergryph installer .exe" \
    -r -a '(__fish_complete_suffix .exe)'
