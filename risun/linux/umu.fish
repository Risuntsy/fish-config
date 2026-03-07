set -g umu_configs \
    "hypegryph_launcher:~/App/umu/hypegryph_launcher/launcher.toml"

if set -q umu_configs
    for entry in $umu_configs
        set -l name (string split ':' $entry)[1]
        set -l path (string split ':' $entry)[2]
        eval "
function umu_$name
    kde-inhibit --power --screenSaver umu-run --config $path \$argv
end
"
    end
end
