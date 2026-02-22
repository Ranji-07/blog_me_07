import urllib.request
import json

try:
    req = urllib.request.Request("http://localhost:8000/api/admin/seed", method="POST")
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode())
        print(f"Server responded: {result}")
except Exception as e:
    print(f"Failed to hit seed endpoint: {e}")
