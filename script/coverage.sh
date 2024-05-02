#!/bin/bash

parse_coverage() {
    filename="$1"
    parse_profiles "$filename"
    if [ $? -ne 0 ]; then
        echo "Failed to parse profiles"
        exit 1
    fi
    new_coverage
}

new_coverage() {
    # Define variables
    files=()
    total_stmt=0
    covered_stmt=0
    missed_stmt=0

    # Loop through profiles
    for profile in "${profiles[@]}"; do
        add_profile "$profile"
    done
}

add_profile() {
    p="$1"
    if [ -z "$p" ]; then
        return
    fi

    file="${p%%:*}"
    total_stmt=$(($total_stmt + ${p%%:*}))
    covered_stmt=$(($covered_stmt + ${p%%:*}))
    missed_stmt=$(($missed_stmt + ${p%%:*}))

    files["$file"]=$p
}

percent() {
    if [ "$total_stmt" -eq 0 ]; then
        echo "0"
        exit
    fi

    echo "scale=2; $covered_stmt / $total_stmt * 100" | bc
}

by_package() {
    packages=()
    for file in "${!files[@]}"; do
        pkg=$(dirname "$file")
        packages["$pkg"]+="$file "
    done

    pkg_covs=()
    for pkg in "${!packages[@]}"; do
        profiles=()
        for file in ${packages["$pkg"]}; do
            profiles+=("${files["$file"]}")
        done
        pkg_covs["$pkg"]=$(new_coverage)
    done
}

trim_prefix() {
    prefix="$1"
    for file in "${!files[@]}"; do
        unset "files[$file]"
        files["$(trim_prefix "$file" "$prefix")"]="${files[$file]}"
    done
}

# Usage: trim_prefix prefix string
trim_prefix() {
    echo "$2" | sed "s|^$1||"
}

# Usage: parse_profiles filename
parse_profiles() {
    # Your implementation to parse profiles goes here
    # For the sake of this example, let's assume it's a placeholder function that returns an array
    profiles=("file1:100:50:50" "file2:200:100:100")
}

# Main script execution
parse_coverage "$1"

# Print results
echo "TotalStmt: $total_stmt"
echo "CoveredStmt: $covered_stmt"
echo "MissedStmt: $missed_stmt"
echo "Coverage: $(percent)%"
by_package
echo "Coverage by Package:"
for pkg in "${!pkg_covs[@]}"; do
    echo "Package: $pkg"
    echo "    TotalStmt: ${pkg_covs["$pkg"]['total_stmt']}"
    echo "    CoveredStmt: ${pkg_covs["$pkg"]['covered_stmt']}"
    echo "    MissedStmt: ${pkg_covs["$pkg"]['missed_stmt']}"
    echo "    Coverage: $(percent ${pkg_covs["$pkg"]['covered_stmt']} ${pkg_covs["$pkg"]['total_stmt']})%"
done
