#!/usr/bin/env bash

# git helpers for the odoo repositories, meant to be sourced by other scripts
# requires lib/log.bash
#
# expected globals:
#   project_dir, community_dir, enterprise_dir, upgrade_dir
#   pull_branch, pull_upgrade
#   checkout_branch, checkout_community, checkout_enterprise, checkout_upgrade

# warn (but do not fail) when the repo at $1 has staged or unstaged changes
# untracked files are ignored on purpose
warn_if_repo_dirty() {
    local repo="$1" changes
    changes="$(git -C "$repo" status --porcelain --untracked-files=no)"
    if [[ -n "$changes" ]]; then
        print_warning "uncommitted changes in $repo (the new worktree is made from HEAD):
$changes"
    fi
}

# create a detached worktree of the repository $1 at the path $2
add_detached_worktree() {
    local repo="$1" dest="$2"
    if [[ -e "$dest" ]]; then
        print_error "\"$dest\" already exists, refusing to create a worktree there."
        exit 1
    fi
    warn_if_repo_dirty "$repo"
    echo "Creating detached worktree of $repo at $dest..."
    git -C "$repo" worktree add --detach "$dest" HEAD
}

# every direct subdirectory of $1 that is a git repository
list_sub_repositories() {
    local src="$1" dir
    for dir in "$src"/*/; do
        [[ -e "$dir/.git" ]] || continue
        basename "$dir"
    done
}

# create a worktree of the root repository $1 (and of each of its sub
# repositories) at the path $2, then set the new worktree up
create_worktrees() {
    local src dest name
    src="$(cd -- "$1" &>/dev/null && pwd)"
    dest="$2"
    # a bare name is created next to the source worktree
    [[ "$dest" != */* ]] && dest="$(dirname "$src")/$dest"

    add_detached_worktree "$src" "$dest"
    dest="$(cd -- "$dest" &>/dev/null && pwd)"

    for name in $(list_sub_repositories "$src"); do
        add_detached_worktree "$src/$name" "$dest/$name"
    done

    echo "Setting the new worktree up..."
    (cd "$dest" && ./o --setup --setup-skip-git-config)

    echo "Linking ./notes/tasks.org to the one of $src..."
    mkdir -p "$dest/notes"
    ln -sfn "$src/notes/tasks.org" "$dest/notes/tasks.org"

    echo "Worktree ready: $dest"
}

# every worktree of the repository $1, except the repository itself
list_other_worktrees() {
    local repo="$1" self line path
    self="$(cd -- "$repo" &>/dev/null && pwd)"
    git -C "$repo" worktree list --porcelain | while read -r line; do
        [[ "$line" = worktree\ * ]] || continue
        path="${line#worktree }"
        [[ "$path" = "$self" ]] || echo "$path"
    done
}

# stash the staged and unstaged changes of the repository $1, if any
# echoes the random id of the created stash, so it can be popped back later on
stash_worktree_changes() {
    local repo="$1" stash_id
    git -C "$repo" diff --quiet HEAD -- && return 0

    # the random part lets us pop that exact stash, whatever was pushed meanwhile
    stash_id="$(basename "$repo")_sync-stash_$(head -c 16 /dev/urandom | md5sum | cut -d' ' -f1)"
    print_warning "uncommitted changes in $repo, stashing them as \"$stash_id\":
$(git -C "$repo" status --porcelain --untracked-files=no)"
    git -C "$repo" stash push --message "$stash_id" >/dev/null
    echo "$stash_id"
}

# pop the stash created by stash_worktree_changes in the repository $1
# $2 is the id it echoed: when empty, there is nothing to pop
unstash_worktree_changes() {
    local repo="$1" stash_id="$2" stash_ref
    [[ -z "$stash_id" ]] && return 0

    stash_ref="$(git -C "$repo" stash list | grep -F "$stash_id" | head -n1 | cut -d: -f1)"
    if [[ -z "$stash_ref" ]]; then
        print_warning "could not find back the stash \"$stash_id\" in $repo."
        return 0
    fi
    echo "Restoring the stashed changes of $repo..."
    # a conflicting pop leaves the stash in place on purpose: nothing is lost
    git -C "$repo" stash pop "$stash_ref" ||
        print_warning "could not restore \"$stash_id\" in $repo, it is kept in the stash list."
}

# move the worktree $1 onto the commit $2
# the worktree is rebased, detached or not, so the commits it carries are
# replayed on top of $2 instead of being thrown away
# staged and unstaged changes are stashed beforehand and popped afterwards
sync_worktree_to() {
    local repo="$1" commit="$2" name stash_id
    # only used to tell the user what is being rebased
    name="$(git -C "$repo" symbolic-ref --quiet --short HEAD || echo "detached HEAD")"
    stash_id="$(stash_worktree_changes "$repo")"

    echo "Rebasing $name ($repo) onto $commit..."
    # a failed rebase is left as is: the user has to resolve it
    git -C "$repo" rebase "$commit" || {
        print_warning "the rebase of $name ($repo) failed. Resolve it (or run \"git rebase --abort\")${stash_id:+, then run \"git stash pop\" to get \"$stash_id\" back}."
        return 0
    }

    unstash_worktree_changes "$repo" "$stash_id"
}

# rebase every other worktree of the root repository $1 onto the HEAD of $1
# the sub repositories are left alone: each worktree keeps its own odoo version
sync_worktrees() {
    local src worktree commit
    src="$(cd -- "$1" &>/dev/null && pwd)"
    commit="$(git -C "$src" rev-parse HEAD)"

    for worktree in $(list_other_worktrees "$src"); do
        echo "Syncing the worktree $worktree..."
        sync_worktree_to "$worktree" "$commit"
    done

    echo "Done syncing the worktrees of $src."
}

# warn when community and enterprise are on different branches
warn_user_if_needed() {
    cd "$project_dir/community" &&
        community_branch=$(git rev-parse --abbrev-ref HEAD)
    cd "$project_dir/enterprise" &&
        enterprise_branch=$(git rev-parse --abbrev-ref HEAD)
    cd "$project_dir"
    if ! [[ "$community_branch" == "$enterprise_branch" ]]; then
        echo -e "\e[33m" # start yellow text
        echo -e "\033[1;33mWarning\033[0m: community and enterprise branches differ.
	community_branch=$community_branch
	enterprise_branch=$enterprise_branch" 1>&2
        echo -e "\e[0m" # end yellow text
    fi
}

# checkout $1 (target repo) to the commit closest in time to $2's HEAD commit
sync_repo_commit() {
    if [ "$#" -ne 2 ]; then
        echo "Error for $0: two arguments should be passed:
$0 <source_repository> <target_repository>" >&2
        exit 1
    fi

    target_repository="$1"
    source_repository="$2"
    commit_sha=$(git -C "$source_repository" rev-parse HEAD)

    # Get commit timestamp
    timestamp=$(git -C "$source_repository" show -s --format=%ct "$commit_sha")
    timestamp_minute=$(((timestamp / 60 + 1) * 60))
    echo "Commit $commit_sha has timestamp: $timestamp_minute"

    # Find closest commit in before this timestamp in target_repository
    matching_commit=$(git -C "$target_repository" rev-list master --timestamp | awk -v ts="$timestamp_minute" '$1 < ts {print $2, $1}' | sort -k2 -nr | head -n1 | cut -d' ' -f1)

    if [ -z "$matching_commit" ]; then
        echo "❎ No commit found before $timestamp_minute in $target_repository" >&2
        exit 1
    fi

    matching_timestamp=$(git -C "$target_repository" show -s --format=%ct "$matching_commit")

    echo "✔ Source repository: $source_repository"
    echo "  ➡ Checkout on $commit_sha (ts: $timestamp_minute)"
    echo "✔ Target repository : $target_repository"
    echo "  ➡ Closest commit: $matching_commit (ts: $matching_timestamp)"

    git -C "$target_repository" checkout "$matching_commit"
    echo "✅ Checked out $target_repository to match $source_repository."
}

# rebase the current branch of the repository in the cwd onto $1
# unstaged changes are stashed beforehand and popped afterwards
# uses the pull_branch global: when 1, $1 is pulled before rebasing onto it
rebase_current_branch() {
    # Define the target branch
    target_branch=$1

    # Get the current branch name
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    if ! git diff-index --quiet HEAD --; then
        echo "Stashing uncommitted changes..."
        git stash push --include-untracked --message "auto-stash before rebase from $current_branch onto $target_branch"
        stashed=1
    else
        stashed=0
    fi

    # Pull the latest changes into the target branch
    if [[ $pull_branch = 1 ]]; then
        echo "Fetching latest changes from origin/$target_branch..."
        git fetch origin "$target_branch"
        echo "Pulling latest changes into $target_branch..."
        git checkout "$target_branch"
        git pull --ff-only origin "$target_branch"
        git checkout "$current_branch"
    else
        echo "\"--pull\" has not been specified. $target_branch won't be pulled"
    fi

    echo "Rebasing $current_branch onto $target_branch..."
    git rebase "$target_branch"

    if [[ $stashed = 1 ]]; then
        echo "Unstashing changes..."
        git stash pop
    fi

    echo "$current_branch has been rebased on $target_branch in $(pwd)"
}

# checkout / pull the community, enterprise and upgrade repositories
# refuses to run when a repo has staged or unstaged changes
handle_branch_switch() {
    # default to "-c" value if not specified
    [[ "$checkout_community" = "" ]] && checkout_community="$checkout_branch"
    [[ "$checkout_enterprise" = "" ]] && checkout_enterprise="$checkout_branch"

    # define arrays for mapping of branches to directories
    dirs=("$community_dir" "$enterprise_dir" "$upgrade_dir")
    branches=("$checkout_community" "$checkout_enterprise" "$checkout_upgrade")
    pulls=("$pull_branch" "$pull_branch" "$pull_upgrade")

    # check for unstaged or staged changes in git repositories
    for i in "${!dirs[@]}"; do
        dir="${dirs[$i]}"
        branch="${branches[$i]}"
        should_pull="${pulls[$i]}"

        # no need to do anything for this dir
        if [[ $should_pull = 0 && "$branch" = "" ]]; then
            echo "No need to do git operations for $dir"
            continue
        fi

        cd "$dir" || exit 1
        if ! git diff --cached --quiet; then
            print_error "you cannot pull/checkout when there are staged changes in $dir."
            cd - >/dev/null
            exit 1
        fi
        if ! git diff --quiet; then
            print_error "you cannot pull/checkout when there are unstaged changes in $dir."
            cd - >/dev/null
            exit 1
        fi
        cd - >/dev/null
    done

    # Switch branches in both repositories
    for i in "${!dirs[@]}"; do
        dir="${dirs[$i]}"
        branch="${branches[$i]}"
        should_pull="${pulls[$i]}"

        cd "$dir" || exit 1
        if [[ $branch != "" ]]; then
            echo "Checking out $dir to $branch..."
            git checkout "$branch"
        fi
        if [[ $should_pull = 1 ]]; then
            current_branch="$(git rev-parse --abbrev-ref HEAD)"
            echo '"-p" has been specified.' "Pulling $dir ($current_branch) to latest changes..."
            git pull --ff-only origin "$current_branch"
        fi
        cd - >/dev/null
    done

    echo "Done git branch operations."
}
