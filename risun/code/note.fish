function code_note_app
    code ~/App --profile web
end

function code_note_memo
    code ~/Note/memo --profile web
end

function code_note_note
    code ~/Note --profile web
end

function code_note_config
    code ~/Note/config --profile web
end

function code_note_config_push
    set origin_path (pwd)
    cd ~/Note/config
    ./push.sh
    cd $origin_path
end
