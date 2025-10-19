function jdk_chmod_all
    set jdk_dir ~/Library/Java/JavaVirtualMachines
    if not test -d $jdk_dir
        return
    end

    chmod -R a+x $jdk_dir
end


function mvnj11
    set -l latest_jdk_path (command ls -d ~/Library/Java/JavaVirtualMachines/liberica-11.*/ | sort -r | head -n 1)

    if test -d "$latest_jdk_path"
        echo "--- Using Java from: $latest_jdk_path"
        env JAVA_HOME="$latest_jdk_path" mvn $argv
    else
        echo "Error: No Liberica 11 JDK found matching '~/Library/Java/JavaVirtualMachines/liberica-11.*'" >&2
        return 1
    end
end

function mvnj21
    set -l latest_jdk_path (command ls -d ~/Library/Java/JavaVirtualMachines/liberica-21.*/ | sort -r | head -n 1)

    if test -d "$latest_jdk_path"
        echo "--- Using Java from: $latest_jdk_path"
        env JAVA_HOME="$latest_jdk_path" mvn $argv
    else
        echo "Error: No Liberica 21 JDK found matching '~/Library/Java/JavaVirtualMachines/liberica-21.*'" >&2
        return 1
    end
end

function clean_idea_jdk_table
    switch (uname)
        case "Darwin"
            rm ~/Library/Application\ Support/JetBrains/IntelliJIdea*/options/jdk.table.xml
        case "Linux"
            echo "TODO"
        case "*"
            echo "?"
    end
end