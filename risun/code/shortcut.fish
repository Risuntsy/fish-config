# Defines a pair of editor shortcuts for one path:
#   code_<prefix>_<name>   ->  code <path> [--profile <code-profile>]
#   zed_<prefix>_<name>    ->  zed <path>
#
#   --name             suffix of the generated function names (required)
#   --path             path to open (required unless --path-command)
#   --path-command     command run at call time to produce the path
#   --code-profile     profile passed to code only
#   --prefix           namespace of the function names, default "config"
#   --require-command  bail out when that command is missing
#   --require-path     bail out when the path does not exist
#   --mkdir            create the path before opening it
function _define_config_shortcut --description "Define code_<prefix>_<name> and zed_<prefix>_<name> for a path"
    argparse name= path= path-command= code-profile= prefix= require-command= require-path mkdir -- $argv
    or return 1

    if test -z "$_flag_name"
        echo "_define_config_shortcut: --name is required" >&2
        return 1
    end

    if test -z "$_flag_path" -a -z "$_flag_path_command"
        echo "_define_config_shortcut: --path or --path-command is required" >&2
        return 1
    end

    set -l prefix config
    if test -n "$_flag_prefix"
        set prefix $_flag_prefix
    end

    # Both functions share the same guards and path resolution, so build that
    # part once and paste it into each body.
    set -l body

    if test -n "$_flag_require_command"
        set -a body "    if not command -q $_flag_require_command
        echo \"$_flag_require_command not found\" >&2
        return 1
    end"
    end

    if test -n "$_flag_path_command"
        set -a body "    set -l path ($_flag_path_command)"
    else
        # A quoted path ("~/.config/fish") never went through the caller's
        # tilde expansion, so do it here.
        set -l path (string replace -r '^~' $HOME -- $_flag_path)
        set -a body "    set -l path "(string escape -- $path)
    end

    if set -q _flag_mkdir
        set -a body "    mkdir -p \$path"
    end

    if set -q _flag_require_path
        set -a body "    if not test -e \$path
        echo \"\$path not found\" >&2
        return 1
    end"
    end

    set -l prelude "$(string join \n -- $body)"

    set -l profile ""
    if test -n "$_flag_code_profile"
        set profile " --profile $_flag_code_profile"
    end

    set -l suffix {$prefix}_{$_flag_name}

    eval "
function code_$suffix --description \"Open the $_flag_name $prefix in code\"
$prelude
    code \$path$profile \$argv
end

function zed_$suffix --description \"Open the $_flag_name $prefix in zed\"
$prelude
    zed \$path \$argv
end
"
end


# --- config ------------------------------------------------------------------

_define_config_shortcut \
    --name fish \
    --path ~/.config/fish \
    --code-profile common

_define_config_shortcut \
    --name maa \
    --path-command 'maa dir config' \
    --require-command maa \
    --code-profile web

_define_config_shortcut \
    --name gradle \
    --path ~/.gradle \
    --require-path \
    --code-profile java

if _is_linux
    _define_config_shortcut \
        --name hosts \
        --path /etc/hosts \
        --code-profile web
else if _is_macos
    _define_config_shortcut \
        --name hosts \
        --path /private/etc/hosts \
        --code-profile web
end

_define_config_shortcut \
    --name dotfile \
    --path ~/DEV/dotfiles \
    --code-profile web

_define_config_shortcut \
    --name nix \
    --path ~/DEV/dotfiles/nix \
    --code-profile common

_define_config_shortcut \
    --name arch \
    --path ~/DEV/scripts/system-setup/arch \
    --code-profile common

_define_config_shortcut \
    --name fedora \
    --path ~/DEV/scripts/system-setup/fedora \
    --code-profile common

_define_config_shortcut \
    --name cachyos \
    --path ~/DEV/scripts/system-setup/cachyos \
    --code-profile common

_define_config_shortcut \
    --name systemd \
    --path ~/.config/systemd/user \
    --code-profile common

_define_config_shortcut \
    --name proxy \
    --path ~/DEV/scripts/infrastructure/proxy \
    --code-profile web

_define_config_shortcut \
    --name scripts \
    --path ~/DEV/scripts \
    --code-profile web

_define_config_shortcut \
    --name learning \
    --path ~/DEV/learning \
    --code-profile common

if _is_linux
    _define_config_shortcut \
        --name container \
        --path ~/.config/containers \
        --code-profile common

    _define_config_shortcut \
        --name fcitx_rime \
        --path ~/.local/share/fcitx5/rime/ \
        --require-path \
        --code-profile web

    # Older name kept around: the zed shortcut used to be zed_config_fcitx.
    function zed_config_fcitx --description "Alias of zed_config_fcitx_rime"
        zed_config_fcitx_rime $argv
    end
end

_define_config_shortcut \
    --name opencode \
    --path ~/.config/opencode \
    --code-profile web

_define_config_shortcut \
    --name antigravity_cli \
    --path ~/.gemini/antigravity-cli \
    --code-profile web

_define_config_shortcut \
    --name gemini \
    --path ~/.gemini \
    --code-profile web

_define_config_shortcut \
    --name mangohud \
    --path ~/.config/MangoHud \
    --mkdir \
    --code-profile web

_define_config_shortcut \
    --name codex \
    --path ~/.codex \
    --code-profile web

_define_config_shortcut \
    --name claude \
    --path ~/.claude \
    --code-profile web

_define_config_shortcut \
    --name pi \
    --path ~/.pi/agent \
    --mkdir \
    --code-profile web


# --- obsidian vaults --------------------------------------------------------

_define_config_shortcut \
    --prefix note \
    --name personal \
    --path ~/Documents/ObsidianVault/Personal \
    --code-profile web

_define_config_shortcut \
    --prefix note \
    --name work \
    --path ~/Documents/ObsidianVault/Work \
    --code-profile web

_define_config_shortcut \
    --prefix note \
    --name private \
    --path ~/Documents/ObsidianVault/Private \
    --code-profile web

_define_config_shortcut \
    --name zed \
    --path ~/.config/zed \
    --code-profile web
