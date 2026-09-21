function cat
    bat $argv
end

# function ls
#     eza --color=always $argv
# end

function df
    duf $argv
end

function real_df
    command df $argv
end

function real_ls
    command ls $argv
end

function real_cat
    command cat $argv
end


function mpv
    if command --query mpv
        command mpv $argv --really-quiet --no-terminal --hwdec=auto
    else
        echo "mpv not found, do nothing"
        return 1
    end
end


function mpv_top
    if command --query mpv
        command mpv $argv --really-quiet --no-terminal --ontop --hwdec=auto
    else
        echo "mpv not found, do nothing"
        return 1
    end
end


function rm
    set filtered_argv
    for arg in $argv
        switch $arg
            case '-r' '-R' '-f' '-rf' '-fr'
                # skip these options
            case '*'
                if test -e $arg; or test -L $arg
                    set filtered_argv $filtered_argv $arg
                end
        end
    end

    if test -z "$filtered_argv"
        echo "rm: missing operand"
        return 1
    end

    if command --query trash
        trash $filtered_argv
    else
        echo "trash not found, do nothing"
        return 1
    end
end

