#!/bin/bash

new_report() {
    old_cov="$1"
    new_cov="$2"
    changed_files=("$3")
    changed_packages=$(changed_packages "${changed_files[@]}")

    echo "{"
    echo "  \"Old\": $old_cov,"
    echo "  \"New\": $new_cov,"
    echo "  \"ChangedFiles\": ["
    for file in "${changed_files[@]}"; do
        echo "    \"$file\","
    done
    echo "  ],"
    echo "  \"ChangedPackages\": ["
    for pkg in "${changed_packages[@]}"; do
        echo "    \"$pkg\","
    done
    echo "  ]"
    echo "}"
}

changed_packages() {
    changed_files=("$@")
    packages=()
    for file in "${changed_files[@]}"; do
        pkg=$(dirname "$file")
        packages["$pkg"]=true
    done
    echo "${!packages[@]}"
}

title() {
    old_cov_pkgs="$1"
    new_cov_pkgs="$2"
    changed_pkgs=("$3")
    num_increase=0
    num_decrease=0

    for pkg in "${changed_pkgs[@]}"; do
        old_percent=0
        new_percent=0
        if [ -n "${old_cov_pkgs["$pkg"]}" ]; then
            old_percent="${old_cov_pkgs["$pkg"]}"
        fi
        if [ -n "${new_cov_pkgs["$pkg"]}" ]; then
            new_percent="${new_cov_pkgs["$pkg"]}"
        fi

        new_p=$(round "$new_percent" 2)
        old_p=$(round "$old_percent" 2)
        if (( $(echo "$new_p > $old_p" | bc -l) )); then
            num_increase=$((num_increase + 1))
        elif (( $(echo "$new_p < $old_p" | bc -l) )); then
            num_decrease=$((num_decrease + 1))
        fi
    done

    if [ "$num_increase" -eq 0 ] && [ "$num_decrease" -eq 0 ]; then
        echo "### Merging this branch will **not change** overall coverage"
    elif [ "$num_increase" -gt 0 ] && [ "$num_decrease" -eq 0 ]; then
        echo "### Merging this branch will **increase** overall coverage"
    elif [ "$num_increase" -eq 0 ] && [ "$num_decrease" -gt 0 ]; then
        echo "### Merging this branch will **decrease** overall coverage"
    else
        echo "### Merging this branch changes the coverage ($num_decrease decrease, $num_increase increase)"
    fi
}

emoji_score() {
    new_percent="$1"
    old_percent="$2"
    diff=$(echo "$new_percent - $old_percent" | bc -l)
    emoji=""
    diff_str=""

    if (( $(echo "$diff < -50" | bc -l) )); then
        emoji=":skull: :skull: :skull: :skull: :skull: "
        diff_str="**$(printf "%+.2f%%" "$diff")**"
    elif (( $(echo "$diff < -10" | bc -l) )); then
        skulls=$((0 - $(printf "%.0f" "$(echo "$diff / 10" | bc -l)")))
        emoji=$(yes ":skull: " | head -n $skulls | tr -d '\n')
        diff_str="**$(printf "%+.2f%%" "$diff")**"
    elif (( $(echo "$diff < 0" | bc -l) )); then
        emoji=":thumbsdown:"
        diff_str="**$(printf "%+.2f%%" "$diff")**"
    elif (( $(echo "$diff > 20" | bc -l) )); then
        emoji=":star2:"
        diff_str="**$(printf "%+.2f%%" "$diff")**"
    elif (( $(echo "$diff > 10" | bc -l) )); then
        emoji=":tada:"
        diff_str="**$(printf "%+.2f%%" "$diff")**"
    elif (( $(echo "$diff > 0" | bc -l) )); then
        emoji=":thumbsup:"
        diff_str="**$(printf "%+.2f%%" "$diff")**"
    else
        emoji=""
        diff_str="ø"
    fi

    echo "$emoji $diff_str"
}

round() {
    val="$1"
    places="$2"
    if (( $(echo "$val == 0" | bc -l) )); then
        echo "0"
        exit
    fi

    pow=$(echo "10 ^ $places" | bc -l)
    digit=$(echo "($pow * $val + 0.5) / 1" | bc)
    echo "scale=$places; $digit / $pow" | bc
}

report_json() {
    echo "$(new_report "$1" "$2" "$3")"
}

trim_prefix() {
    name="$1"
    prefix="$2"
    trimmed=$(echo "$name" | sed "s|^$prefix||")
    trimmed=$(echo "$trimmed" | sed "s|^/||")
    if [ -z "$trimmed" ]; then
        trimmed="."
    fi

    echo "$trimmed"
}