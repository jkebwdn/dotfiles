const fs=require('fs'),vm=require('vm'),assert=require('assert'),path=require('path');
const c=vm.createContext({});
for(const f of ['SettingsSchema.js','SettingsMigrations.js']) vm.runInContext(fs.readFileSync(path.join(__dirname,'../../.config/quickshell/magi/settings',f),'utf8'),c);
assert.equal(c.migrate({schemaVersion:9}).schemaVersion,14);
assert.equal(c.analyze(c.defaults()).errors.length,0);
for(const [key,value] of [['directories',['relative']],['directories',['/bad\npath']],['directories',null],['directories',Array(17).fill('/x')],['directories',['/x','/x']],['thumbnailSize',40],['thumbnailSize',221.5],['enabled',1]])
 assert.ok(c.analyze({schemaVersion:10,wallpaper:{[key]:value}}).errors.length,key);
for(const directories of [[],['~/Pictures/wallpapers'],['/one','/two']]) assert.equal(c.analyze({schemaVersion:10,wallpaper:{directories}}).errors.length,0);
assert.equal(c.analyze({schemaVersion:15}).future,true);
console.log('Wallpaper schema validation and migration PASS');
