function import
    if test -f $argv[1]
        source $argv[1]
        return
    end
    if not test -d $argv[1]
        return
    end
    set -l folder $argv[1]
    for f in $folder/*.fish
        if test -f $f
            source $f
        end
    end
end

if test -f ~/.config/fish/risun/secret.fish
    source ~/.config/fish/risun/secret.fish
end

import ~/.config/fish/risun/functions
import ~/.config/fish/risun/utils
import ~/.config/fish/risun/env
import ~/.config/fish/risun/work
import ~/.config/fish/risun/alias
import ~/.config/fish/risun/code
import ~/.config/fish/risun/unix

if _is_macos
    import ~/.config/fish/risun/darwin
end

if _is_linux
    import ~/.config/fish/risun/linux
end
