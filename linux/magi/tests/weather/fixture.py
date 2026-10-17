"""Network replacement only: production parser/cache still run in the real worker."""
import json
import os
from pathlib import Path
import sys
import time
from weather_backend import fetch
config=json.loads(sys.stdin.readline())
cache=Path(os.environ['XDG_CACHE_HOME'])/'magi/weather/current.json'
def get(url,params):
    with open(Path(os.environ['XDG_CACHE_HOME']).parent/'weather-requests.log','a') as stream:
        stream.write(('geocode' if 'geocoding' in url else 'forecast')+'\n')
    time.sleep(.15)
    if config['location']=='Timeout': raise TimeoutError()
    if 'geocoding' in url:
        return {'results':[{'name':config['location'],'latitude':53,'longitude':-1}]}
    return {'current':{'temperature_2m':12,'weather_code':63,'time':int(time.time())},'current_units':{'temperature_2m':'°C'}}
print(json.dumps(fetch(config,cache,get=get)))
