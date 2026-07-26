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

    # Step 1: Commit if needed
    set -l changes (git status --porcelain)
    if test -n "$changes"
        echo "Changes detected. Staging and committing..."
        git add .; and git commit -m "$commit_msg"; or begin
            echo "Error: Git commit failed. Exiting."
            return 1
        end
    else
        echo "No local changes to commit. Working tree is clean."
    end

    # Step 2: Push if needed
    git fetch origin >/dev/null 2>&1

    set -l local_head (git rev-parse HEAD)
    set -l upstream_head (git rev-parse '@{upstream}')

    if test "$local_head" != "$upstream_head"
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
