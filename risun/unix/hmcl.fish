function hmcl
    if test -f ~/App/hmcl/hmcl.jar
        cd ~/App/hmcl/
        java -jar ~/App/hmcl/hmcl.jar &>/dev/null
    else
        echo "HMCL not found" && return 1
    end
end
