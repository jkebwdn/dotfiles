const fs=require('fs'),vm=require('vm'),assert=require('assert');
const c=vm.createContext({});
for(const f of ['SettingsSchema','SettingsMigrations']) vm.runInContext(fs.readFileSync('.config/quickshell/magi/settings/'+f+'.js','utf8'),c);
assert.equal(c.migrate({schemaVersion:6,custom:12}).schemaVersion,8);
assert.equal(c.migrate({schemaVersion:6,custom:12}).custom,12);
assert.equal(c.analyze(c.defaults()).errors.length,0);
for(const [key,value] of Object.entries({layout:'bad',panelWidth:0,gridColumns:99,iconSize:1,headerImage:'https://example.com/a',enabled:'yes',position:'bottom',visibleRows:2.5})) {
 const result=c.analyze({schemaVersion:7,launcher:{[key]:value}});
 assert.ok(result.errors.length,key);
 assert.equal(result.effective.launcher[key],c.defaults().launcher[key]);
}
assert.equal(c.analyze({schemaVersion:7,launcher:{layout:'grid',headerImage:'/tmp/a.png'}}).effective.launcher.layout,'grid');
assert.equal(c.analyze({schemaVersion:7,launcher:{showIcons:false,showLabels:false}}).effective.launcher.showLabels,true);
console.log('Launcher migration, ranges, enums, local paths, identifiable entries PASS');
assert.equal(c.analyze({schemaVersion:7,launcher:{layout:'grid'}}).effective.launcher.hiddenIds.length,0);
const ids=['org.example.App.desktop','nested-app.desktop'];
assert.deepEqual(Array.from(c.analyze({schemaVersion:7,launcher:{hiddenIds:ids}}).effective.launcher.hiddenIds),ids);
assert.equal(c.analyze(c.migrate({schemaVersion:6})).effective.launcher.hiddenIds.length,0);
for (const hiddenIds of [null,{},'bad',[1],[''],['../app.desktop'],['dir/app.desktop'],['bad\n.desktop'],['a.desktop','a.desktop'],['app']]) {
 const result=c.analyze({schemaVersion:7,launcher:{hiddenIds}});
 assert.ok(result.errors.length,JSON.stringify(hiddenIds));
 assert.equal(result.effective.launcher.hiddenIds.length,0);
}
console.log('Hidden IDs additive defaults, validation, duplicate rejection and preservation PASS');
