function jdk_chmod_all
    set jdk_dir ~/Library/Java/JavaVirtualMachines
    if not test -d $jdk_dir
        return
    end

    chmod -R a+x $jdk_dir
end


function _mvnj
    set -l jdk_ver $argv[1]
    set -l latest_jdk_path

    switch (uname)
        case Darwin
            set -l matches $HOME/Library/Java/JavaVirtualMachines/liberica-$jdk_ver.*/
            set latest_jdk_path (printf '%s\n' $matches | sort -r | head -n 1)
        case Linux
            set -l matches /usr/lib/jvm/java-$jdk_ver-*/
            set latest_jdk_path (printf '%s\n' $matches | sort -r | head -n 1)
    end

    if test -d "$latest_jdk_path"
        echo "--- Using Java from: $latest_jdk_path"
        env JAVA_HOME="$latest_jdk_path" mvn $argv[2..-1]
    else
        echo "Error: No JDK $jdk_ver found matching '/usr/lib/jvm/java-$jdk_ver-*/'" >&2
        return 1
    end
end

function mvnj11
    _mvnj 11 $argv
end

function mvnj21
    _mvnj 21 $argv
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