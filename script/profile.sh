#!/bin/bash

# Profile represents the profiling data for a specific file.
# Fields: FileName, Mode, Blocks, TotalStmt, CoveredStmt, MissedStmt
profile() {
    echo "{"
    echo "  \"FileName\": \"$1\","
    echo "  \"Mode\": \"$2\","
    echo "  \"Blocks\": ["
    for ((i = 0; i < ${#3[@]}; i++)); do
        echo "    {"
        echo "      \"StartLine\": ${3[$i]},"
        echo "      \"StartCol\": ${4[$i]},"
        echo "      \"EndLine\": ${5[$i]},"
        echo "      \"EndCol\": ${6[$i]},"
        echo "      \"NumStmt\": ${7[$i]},"
        echo "      \"Count\": ${8[$i]}"
        if ((i == ${#3[@]} - 1)); then
            echo "    }"
        else
            echo "    },"
        fi
    done
    echo "  ],"
    echo "  \"TotalStmt\": $9,"
    echo "  \"CoveredStmt\": ${10},"
    echo "  \"MissedStmt\": ${11}"
    echo "}"
}

# ProfileBlock represents a single block of profiling data.
# Fields: StartLine, StartCol, EndLine, EndCol, NumStmt, Count
profile_block() {
    echo "{"
    echo "  \"StartLine\": $1,"
    echo "  \"StartCol\": $2,"
    echo "  \"EndLine\": $3,"
    echo "  \"EndCol\": $4,"
    echo "  \"NumStmt\": $5,"
    echo "  \"Count\": $6"
    echo "}"
}

# ByFileName sorts Profiles by FileName.
by_file_name() {
    echo "${@}" | tr ' ' '\n' | sort | tr '\n' ' '
}

# ParseProfiles parses profile data in the specified file and returns a Profile for each source file described therein.
parse_profiles() {
    local fileName="$1"
    local mode=""
    local files=()
    local blocks=()
    local totalStmt=0
    local coveredStmt=0
    local missedStmt=0

    while read -r line; do
        if [ -z "$mode" ]; then
            mode=$(echo "$line" | cut -d' ' -f2)
            continue
        fi

        local fn
        local b
        IFS=',' read -r fn b <<<"$line"
        local startLine
        local startCol
        local endLine
        local endCol
        local numStmt
        local count
        IFS='.' read -r startLine startCol <<<"$b"
        IFS=',' read -r endLine endCol numStmt count <<<"$fn"

        files+=("$fn")
        blocks+=("$(profile_block "$startLine" "$startCol" "$endLine" "$endCol" "$numStmt" "$count")")

        totalStmt=$((totalStmt + numStmt))
        if [ "$count" -gt 0 ]; then
            coveredStmt=$((coveredStmt + numStmt))
        fi
    done <"$fileName"

    missedStmt=$((totalStmt - coveredStmt))

    local uniqueFiles
    local uniqueBlocks
    uniqueFiles=$(echo "${files[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    uniqueBlocks=$(echo "${blocks[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')

    local modeVal
    if [ "$mode" == "set" ]; then
        modeVal="\"set\""
    elif [ "$mode" == "count" ]; then
        modeVal="\"count\""
    elif [ "$mode" == "atomic" ]; then
        modeVal="\"atomic\""
    else
        modeVal="\"unknown\""
    fi

    echo "$(profile "$uniqueFiles" "$modeVal" "$uniqueBlocks" "$totalStmt" "$coveredStmt" "$missedStmt")"
}

# Main script execution
parse_profiles "$1"