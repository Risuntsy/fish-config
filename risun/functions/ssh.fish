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
function sshcid_$name
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

    end
end

# SSH-copy-id to all servers
function sshcid_all
    for server in $ssh_servers
        set -l address (string split ':' $server)[2]
        ssh-copy-id $address
    end
end
