#!/bin/bash

# Default values
output_dir="./"
num_groups=1
create_dir=false
force_overwrite=false

# Function to generate a random password
generate_password() {
    LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12
}

# Function to ensure output directory ends with a slash
ensure_trailing_slash() {
    [[ "$1" != */ ]] && echo "$1"/ || echo "$1"
}

# Parse command-line arguments
while getopts "d:n:cf" opt; do
    case ${opt} in
        d ) output_dir=$(ensure_trailing_slash "$OPTARG") ;;
        n ) num_groups=$OPTARG ;;
        c ) create_dir=true ;;
        f ) force_overwrite=true ;;
        \? ) echo "Usage: cmd [-d output_directory] [-n number_of_groups] [-c] [-f]" ;;
    esac
done

# Check if directory exists, is writable, and prompt to create if not
if [ ! -d "$output_dir" ]; then
    if [ "$create_dir" = true ]; then
        mkdir -p "$output_dir"
        if [ $? -ne 0 ]; then
            echo "Failed to create directory: $output_dir"
            exit 1
        fi
    else
        echo "Directory does not exist: $output_dir. Use -c option to create it."
        exit 1
    fi
elif [ ! -w "$output_dir" ]; then
    echo "Directory is not writable: $output_dir"
    exit 1
fi

# Validate number of groups
if [[ $num_groups -lt 1 || $num_groups -gt 99 ]]; then
    echo "Number of groups must be between 1 and 99."
    exit 1
fi

# Check for existing files and -f option
check_and_write() {
    local file=$1
    local content=$2
    if [[ -f "$file" && $force_overwrite != true ]]; then
        echo "File $file already exists. Use -f to overwrite."
        exit 1
    fi
    echo "$content" > "$file"
}

# Generate and write passwords
admin_pass=$(generate_password)
check_and_write "${output_dir}admin.htpasswd" "admin:$admin_pass"
check_and_write "${output_dir}global.htpasswd" "admin:$admin_pass"
echo "admin,$admin_pass"

# Loop to create group files and add both admin and group user
for i in $(seq -w 1 $num_groups); do
    group_pass=$(generate_password)
    check_and_write "${output_dir}group$i.htpasswd" "group$i:$group_pass
admin:$admin_pass"
    # Append group user to global.htpasswd
    echo "group$i:$group_pass" >> "${output_dir}global.htpasswd"
    
    # Display group username and password
    echo "group$i,$group_pass"
done

# Final permissions adjustment, if needed
chmod 600 ${output_dir}*.htpasswd

