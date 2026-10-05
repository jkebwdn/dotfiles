const fs=require('fs'),vm=require('vm'),assert=require('assert');
const c=vm.createContext({});
for(const f of ['SettingsSchema','SettingsMigrations']) vm.runInContext(fs.readFileSync('.config/quickshell/magi/settings/'+f+'.js','utf8'),c);
const old={schemaVersion:8,calendar:{firstDay:'monday'},custom:42};
const r=c.analyze(c.migrate(old)); assert.equal(r.effective.schemaVersion,9);
assert.equal(old.schemaVersion,8); assert.equal(r.effective.custom,42); assert.equal(r.effective.calendar.firstDay,'monday');
assert.equal(r.effective.emoji.recentLimit,24); assert.equal(c.analyze(c.defaults()).errors.length,0);
assert.equal(c.analyze({schemaVersion:10}).future,true);
for(const [key,value] of Object.entries({enabled:1,gridColumns:3,emojiSize:49,recentLimit:61,showCategories:null,closeOnSelect:'yes',recents:['1F600','1F600']})) {
 const result=c.analyze({schemaVersion:9,emoji:{[key]:value}}); assert.ok(result.errors.length,key);
 assert.deepEqual(result.effective.emoji[key],c.defaults().emoji[key]);
}
for(const recents of [null,['broken'],['1F600',4],Array(61).fill('1F600')]) assert.ok(c.analyze({schemaVersion:9,emoji:{recents}}).errors.length);
assert.deepEqual(Array.from(c.analyze({schemaVersion:9,emoji:{recents:['1F600','1F525'],recentLimit:1}}).effective.emoji.recents),['1F600']);
assert.equal(c.analyze({schemaVersion:9,emoji:{recents:['1F600'],recentLimit:0}}).effective.emoji.recents.length,0);
assert.equal(c.analyze({schemaVersion:9,emoji:{recents:['1F469-1F3FD-200D-1F4BB']}}).errors.length,0);
console.log('Emoji v8→v9 migration, preservation, settings validation and bounded history PASS');
