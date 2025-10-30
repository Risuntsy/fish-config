function cat
    bat $argv
end

function ls
    eza --color=always $argv
end

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
        command mpv $argv --really-quiet --no-terminal
    else
        echo "mpv not found, do nothing"
        return 1
    end
end


function mpv_top
    if command --query mpv
        command mpv $argv --really-quiet --no-terminal --ontop
    else
        echo "mpv not found, do nothing"
        return 1
    end
end