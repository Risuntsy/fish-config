function git_pull_rebase
    # Check if there are local changes
    set local_changes (git status --porcelain --untracked-files=no)
    if test -z "$local_changes"
        # No local changes, just pull with rebase
        git pull --rebase; or return $status
    else
        # Has local changes, stash first
        echo "Local changes detected, stashing..."
        git stash push -m "Auto-stash before git pull --rebase"; or return $status

        # Pull with rebase
        git pull --rebase; or return $status

        # Pop the stash
        git stash pop; or return $status
    end
end

function git_rebase_push
    # Always pull with rebase first to get latest changes
    echo "Updating from remote repository..."

    # Check if there are local changes
    set local_changes (git status --porcelain --untracked-files=no)
    if test -n "$local_changes"
        # Has local changes, stash first
        echo "Local changes detected, stashing..."
        git stash push -m "Auto-stash before git push"; or return $status
    end

    # Always pull with rebase first
    git pull --rebase; or return $status

    # Now push
    git push; or return $status

    # Restore stash if we had local changes
    if test -n "$local_changes"
        git stash pop; or return $status
    end
end


function git_push_now
    set -l msg $argv[1]
    set -l commit_msg (date +%s)
    if test -n "$msg"
        set commit_msg "$commit_msg - $msg"
    end

    set -l status_lines (git status --porcelain --branch)
    set -l changes
    if test (count $status_lines) -gt 1
        set changes $status_lines[2..-1]
    end
    set -l need_push 0
    if string match -q -r '\[ahead' -- $status_lines[1]
        set need_push 1
    end

    if test -n "$changes"
        echo "Changes detected. Staging and committing..."
        git add .; and git commit -m "$commit_msg"; or begin
            echo "Error: Git commit failed. Exiting."
            return 1
        end
        set need_push 1
    else
        echo "No local changes to commit. Working tree is clean."
    end

    if test $need_push -eq 1
        echo "Unpushed commits found. Pushing to remote..."
        git push; or begin
            echo "Error: Git push failed."
            return 1
        end
        echo "Successfully pushed changes."
    else
        echo "Local branch is up-to-date with remote. Nothing to push."
    end
end
