#!/usr/bin/env python3
"""No Internet: fixtures exercise the production helper and cache/timeout policy."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import io
import json
import sys
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('weather', Path(__file__).resolve().parents[2]/'.config/quickshell/magi/services/weather.py')
w = importlib.util.module_from_spec(spec); spec.loader.exec_module(w)
NOW = 2_000_000_000
GEO = {'results':[{'latitude':53.07,'longitude':-.81,'name':'Newark-on-Trent','country':'United Kingdom'}]}
def current(now=NOW):
    return {'current':{'temperature_2m':12,'weather_code':63,'time':now},'current_units':{'temperature_2m':'°C'}}
class WeatherTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.path=Path(self.temp.name)/'current.json'; self.calls=[]
        self.config={'enabled':True,'location':'Newark-on-Trent','units':'metric'}
    def get(self,url,params):
        self.calls.append((url,params)); return GEO if 'geocoding' in url else current()
    def fetch(self,**kwargs): return w.fetch(self.config,self.path,now=kwargs.pop('now',NOW),get=kwargs.pop('get',self.get),**kwargs)
    def test_no_location_disabled(self):
        self.config['enabled']=False; self.assertEqual(self.fetch()['summary'],'')
        self.config.update(enabled=True,location=''); self.assertEqual(self.fetch()['error'],'Set a weather location'); self.assertFalse(self.calls)
    def test_resolution_metric_imperial_cache(self):
        self.assertEqual(self.fetch()['summary'],'Rainy · 12°C'); self.assertEqual(len(self.calls),2)
        self.config['units']='imperial'; self.assertEqual(self.fetch()['summary'],'Rainy · 54°F'); self.assertEqual(len(self.calls),2)
        self.assertEqual(self.calls[0][1]['name'],'Newark-on-Trent')
        self.assertNotIn('Newark-on-Trent',self.path.name)
        self.assertEqual(self.path.stat().st_mode & 0o777,0o600)
    def test_refresh_and_cached_geocoding(self):
        self.fetch(); self.fetch(now=NOW+w.REFRESH_SECONDS); self.assertEqual(len(self.calls),3)
        self.config['location']='Other town'; self.fetch(); self.assertEqual(len(self.calls),5)
    def test_failure_keeps_only_fresh_matching_cache(self):
        self.fetch()
        def fail(*args): raise TimeoutError('never show URL/query')
        result=self.fetch(now=NOW+1800,get=fail); self.assertEqual(result['summary'],'Rainy · 12°C'); self.assertEqual(result['error'],'Weather refresh unavailable')
        self.assertEqual(self.fetch(now=NOW+w.MAX_AGE+1,get=fail)['summary'],'')
        self.config['location']='Other'; self.assertEqual(self.fetch(get=fail)['summary'],'')
    def test_no_match_malformed(self):
        self.assertEqual(self.fetch(get=lambda *_:{})['error'],'Location not found')
        self.assertEqual(self.fetch(get=lambda url,_: GEO if 'geocoding' in url else {'current':{}})['summary'],'')
        for bad in [None,True,float('nan'),1000]:
            data=current(); data['current']['temperature_2m']=bad
            with self.assertRaises(ValueError): w.observation(data,NOW)
        data=current(NOW-w.MAX_AGE-1)
        with self.assertRaises(ValueError): w.observation(data,NOW)
    def test_codes(self):
        for code in [0,1,2,3,45,48,51,53,55,56,57,61,63,65,66,67,71,73,75,77,80,81,82,85,86,95,96,97,99]: self.assertTrue(w.condition(code))
        with self.assertRaises(ValueError): w.condition(42)
    def test_http_bounds_timeout(self):
        with patch.object(w,'urlopen',return_value=io.BytesIO(json.dumps(GEO).encode())) as opened:
            self.assertEqual(w.request('https://example.test',{'name':'Town & country'}),GEO)
            self.assertEqual(opened.call_args.kwargs['timeout'],8)
            self.assertIn('Town+%26+country',opened.call_args.args[0].full_url)
        with patch.object(w,'urlopen',return_value=io.BytesIO(b'x'*(w.MAX_RESPONSE+1))):
            with self.assertRaises(ValueError): w.request('https://example.test',{})
        with patch.object(w,'urlopen',side_effect=TimeoutError):
            with self.assertRaises(TimeoutError): w.request('https://example.test',{})
    def test_corrupt_cache(self):
        self.path.write_text('{'); self.assertEqual(self.fetch()['summary'],'Rainy · 12°C')
if __name__=='__main__': unittest.main()
