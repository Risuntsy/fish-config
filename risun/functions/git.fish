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
