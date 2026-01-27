#!/bin/bash

url='https://system-test.onvue.com/system_test?customer=pearson_vue'

# Define headers
headers='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36'

# Fetch the URL and follow redirects
response=$(curl -s -L -A "$headers" -w "%{url_effective}" -o /dev/null "$url")
new_url=$(echo "$response" | tail -1)

# Parse query parameters
access_code=$(echo "$new_url" | grep -oP '(?<=access_code=)[^&]*')
session_id=$(echo "$new_url" | grep -oP '(?<=session_id=)[^&]*')

# Construct the final URI
final_uri="https://candidatelaunchst.onvue.com/delivery?session_id=${session_id}&access_code=${access_code}&locale=en-US&token=undefined"

# Clear the screen and print results
clear
echo -e "\n=====# Pearson | VUE: System Test - Exam Generator #=====\n"
echo -e "# Download Page: \033[94m${new_url}\033[0m"
echo -e "# Live Exam: \033[94m${final_uri}\033[0m\n"
echo -e "# Shortcut: \033[94mhttps://vueop.startpractice.com\033[0m\n"
