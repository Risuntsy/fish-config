# Define SSH servers

# Generate SSH functions
if set -q ssh_servers
    for server in $ssh_servers
        set -l name (string split ':' $server)[1]
        set -l address (string split ':' $server)[2]

        # SSH function
        eval "
function ssh_$name
    ssh $address
end
"

        # SSH-copy-id function
        eval "
function ssh_copy_id_$name
    ssh-copy-id $address
end
"

        # Transfer function (Rsync or SCP)
        eval "
function scp_$name
    set -l src \$argv[1]
    set -l dst \$argv[2]
    if command -v rsync >/dev/null
        rsync -avz \$src $address:\$dst
    else
        scp -r \$src $address:\$dst
    end
end
"

        eval "
function ssh_remove_key_$name
    ssh-keygen -R $(string split '@' $address)[2]
end
"

    end
end

# SSH-copy-id to all servers
function ssh_copy_id_all
    for server in $ssh_servers
        set -l address (string split ':' $server)[2]
        ssh-copy-id $address
    end
end

function ssh_agent
    set key_path $argv[1]
    set command_to_run $argv[2..-1]
    if test -z "$key_path"
        echo "Usage: ssh_agent <keyPath> ...commands"
        return 1
    end
    ssh-agent bash -c "ssh-add $key_path && $command_to_run"
end

if set -q ssh_keys
    for key in $ssh_keys
        set -l path (string split ':' $key)[1]
        set -l id (string split ':' $key)[2]

        eval "
function ssh_agent_$id
    ssh_agent \"$path\" \$argv
end
"
    end
end
