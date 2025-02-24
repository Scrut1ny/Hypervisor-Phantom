import requests
from urllib.parse import urlparse, parse_qs

url = 'https://system-test.onvue.com/system_test?customer=pearson_vue'

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36'
}

response = requests.get(url, headers=headers, allow_redirects=True)
new_url = response.url

parsed_url = urlparse(new_url)
query_params = parse_qs(parsed_url.query)

access_code = query_params.get('access_code', [None])[0]
session_id = query_params.get('session_id', [None])[0]

final_uri = f'https://candidatelaunchst.onvue.com/delivery?session_id={session_id}&access_code={access_code}&locale=en-US&token=undefined'

print("\033[H\033[J", end="")
print("\n=====# Pearson | VUE: System Test - Exam Generator #=====\n")
print(f"# Download Page: \033[94m{new_url}\033[0m")
print(f"# Live Exam: \033[94m{final_uri}\033[0m\n")
print(f"# Shortcut: \033[94mhttps://vueop.startpractice.com\033[0m\n")
