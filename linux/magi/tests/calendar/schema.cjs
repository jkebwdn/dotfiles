const fs=require('fs'),vm=require('vm'),assert=require('assert');
const c=vm.createContext({});
for(const f of ['SettingsSchema','SettingsMigrations']) vm.runInContext(fs.readFileSync('.config/quickshell/magi/settings/'+f+'.js','utf8'),c);
const old={schemaVersion:7,launcher:{hiddenIds:['a.desktop'],layout:'grid'},custom:42};
const migrated=c.analyze(c.migrate(old));
assert.equal(migrated.effective.schemaVersion,8);assert.equal(migrated.effective.custom,42);
assert.equal(migrated.effective.launcher.hiddenIds[0],'a.desktop');assert.equal(migrated.effective.launcher.layout,'grid');
assert.equal(migrated.effective.calendar.timeFormat,'24h');assert.equal(migrated.effective.calendar.dateFormat,'numeric');
assert.equal(c.analyze(c.defaults()).errors.length,0);
for(const [key,values] of Object.entries({firstDay:['locale','monday','sunday'],density:['compact','comfortable'],timeFormat:['locale','12h','24h'],dateFormat:['locale','numeric','iso'],showWeekNumbers:[true,false],showAdjacentDays:[true,false]})) {
 for(const value of values) assert.equal(c.analyze({schemaVersion:8,calendar:{[key]:value}}).effective.calendar[key],value);
 for(const value of [null,99,'bogus']) assert.ok(c.analyze({schemaVersion:8,calendar:{[key]:value}}).errors.length,key);
}
console.log('Calendar v7→v8 migration, preservation, format defaults and validation PASS');
