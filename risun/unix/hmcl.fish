function hmcl
    if test -f ~/App/hmcl/hmcl.jar
        java -jar ~/App/hmcl/hmcl.jar
    else
        echo "HMCL not found" && return 1
    end
end
