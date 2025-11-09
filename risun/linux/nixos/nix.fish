function nixos_rebuild_switch
    set original_path (pwd)
    cd ~/Note/memo/os/linux/distro/nix/
    ./rebuild.sh
    cd $original_path
end

function nixos_update
    sudo nix-channel --update; or return $status
    sudo nix flake update --flake /etc/nixos; or return $status
    nixos_rebuild_switch
end

function direnv_nix_setup
    echo "{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [

  ];
}
" | tee ./shell.nix
    echo "use nix shell.nix" | tee .envrc
    direnv allow
end
