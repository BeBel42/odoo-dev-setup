#!/usr/bin/env bash

# git helpers for the odoo repositories, meant to be sourced by other scripts
# requires lib/log.bash
#
# expected globals:
#   project_dir, community_dir, enterprise_dir, upgrade_dir
#   pull_branch, pull_upgrade
#   checkout_branch, checkout_community, checkout_enterprise, checkout_upgrade

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
