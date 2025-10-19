function git_svn_rebase
    # Check if there are local changes
    set local_changes (git status --porcelain --untracked-files=no)
    if test -z "$local_changes"
        # No local changes, just rebase
        git svn rebase; or return $status
    else
        # Has local changes, stash first
        echo "Local changes detected, stashing..."
        git stash push -m "Auto-stash before git svn rebase"; or return $status
        
        # Rebase
        git svn rebase; or return $status
        
        # Pop the stash
        git stash pop; or return $status
    end
end


function git_svn_dcommit
    # Always rebase first to get latest changes
    echo "Updating from SVN repository..."
    
    # Check if there are local changes
    set local_changes (git status --porcelain --untracked-files=no)
    if test -n "$local_changes"
        # Has local changes, stash first
        echo "Local changes detected, stashing..."
        git stash push -m "Auto-stash before git svn operations"; or return $status
    end
    
    # Always rebase first
    git svn rebase; or return $status

    # Now dcommit
    git svn dcommit; or return $status
    
    # Restore stash if we had local changes
    if test -n "$local_changes"
        git stash pop; or return $status
    end
end
