#!/bin/bash

# Fetch effective URL after redirects
new_url=$(curl -sLo /dev/null -w '%{url_effective}' -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36' 'https://system-test.onvue.com/system_test?customer=pearson_vue')

# Extract query parameters
access_code=${new_url##*access_code=}; access_code=${access_code%%&*}
session_id=${new_url##*session_id=}; session_id=${session_id%%&*}

# Output results
clear
cat <<EOF

=====# Pearson | VUE: System Test - Exam Generator #=====

# Download Page: $(printf '\033[94m%s\033[0m' "$new_url")
# Live Exam: $(printf '\033[94m%s\033[0m' "https://candidatelaunchst.onvue.com/delivery?session_id=${session_id}&access_code=${access_code}&locale=en-US&token=undefined")

# Shortcut: $(printf '\033[94mhttps://vueop.startpractice.com\033[0m')

EOF
