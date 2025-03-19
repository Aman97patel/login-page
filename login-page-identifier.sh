#!/bin/bash

# Check if input file is provided
if [ $# -ne 2 ]; then
  echo "Usage: $0 <input_file> <output_file>"
  exit 1
fi

# Input and output files
input_file=$1
output_file=$2

# Login paths to check
login_paths=("/admin" "/login" "/login/user" "/admin/login" "/user/login" "/signin" "/auth" "/account" "/adminpanel" "/register" "/signup")

# Create or clear the output file
> "$output_file"

# Function to check if a path is a login page based on title and content
check_login_page() {
  local domain=$1
  local path=$2
  local url=$3
  
  # Fetch the page content and extract the title
  page_content=$(curl -s "$url")
  
  # Extract the title tag using sed (matches between <title> and </title>)
  title=$(echo "$page_content" | sed -n 's/.*<title>\(.*\)<\/title>.*/\1/p')
  
  # Check for login or admin-related keywords in the title and content
  if [[ "$title" =~ "login" || "$title" =~ "signin" || "$title" =~ "admin" || "$title" =~ "account" || "$title" =~ "authentication" ]]; then
    echo "$url - Possible Login/Registration Page (Title: $title)" >> "$output_file"
  else
    # Search for login form keywords in the content
    if echo "$page_content" | grep -iqE "login|signin|admin|authentication|signup"; then
      echo "$url - Possible Login/Registration Page (Content contains login form)" >> "$output_file"
    else
      echo "$url - Not Found or Invalid" >> "$output_file"
    fi
  fi
}

# Function to check root directory for login page
check_root_login_page() {
  local domain=$1
  local url=$2
  
  # Fetch the page content and extract the title
  page_content=$(curl -s "$url")
  
  # Extract the title tag using sed (matches between <title> and </title>)
  title=$(echo "$page_content" | sed -n 's/.*<title>\(.*\)<\/title>.*/\1/p')
  
  # Check for login or admin-related keywords in the title and content
  if [[ "$title" =~ "login" || "$title" =~ "signin" || "$title" =~ "admin" || "$title" =~ "account" || "$title" =~ "authentication" ]]; then
    echo "$url - Possible Login/Registration Page at Root (Title: $title)" >> "$output_file"
  else
    # Search for login form keywords in the content
    if echo "$page_content" | grep -iqE "login|signin|admin|authentication|signup"; then
      echo "$url - Possible Login/Registration Page at Root (Content contains login form)" >> "$output_file"
    else
      echo "$url - Not Found or Invalid at Root" >> "$output_file"
    fi
  fi
}

# Loop through each domain/subdomain in the input file
while IFS= read -r domain; do
  # Check both http:// and https:// protocols
  for protocol in "http" "https"; do
    # Check root directory first
    check_root_login_page "$domain" "$protocol://$domain/"
    
    # Then, check all other login paths
    for path in "${login_paths[@]}"; do
      check_login_page "$domain" "$path" "$protocol://$domain$path"
    done
  done
done < "$input_file"

echo "Script completed. Results saved to $output_file."

