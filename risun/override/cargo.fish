if command -q cargo
    function cargo
        command cargo --config net.git-fetch-with-cli=true $argv
    end
end
