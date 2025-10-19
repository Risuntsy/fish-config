function nixos_rebuild_switch
    set original_path (pwd)
    cd ~/Note/memo/os/linux/distro/nix/
    ./rebuild.sh
    cd $original_path
end
