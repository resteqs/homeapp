import urllib.request, json
with open('lib/main.dart') as f:
    lines = f.readlines()
url = [l for l in lines if 'url: ' in l][0].split("url: '")[1].split("'")[0]
key = [l for l in lines if 'anonKey: ' in l][0].split("anonKey: '")[1].split("'")[0]

req = urllib.request.Request(url + "/rest/v1/?apikey=" + key)
with urllib.request.urlopen(req) as response:
    data = json.loads(response.read().decode())
    
print("ITEM SCHEMA:")
print(data['definitions']['grocery_list_items']['properties'])
