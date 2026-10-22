const fs=require('fs'),vm=require('vm'),assert=require('assert');
const root=process.argv[2],c=vm.createContext({});
for(const file of ['SettingsSchema.js','SettingsMigrations.js']) vm.runInContext(fs.readFileSync(root+'/settings/'+file,'utf8'),c);
const plain=x=>JSON.parse(JSON.stringify(x));
assert.deepEqual(plain(c.defaults().powerIdle),{lockAfter:300,displayOffAfter:600,suspendAfter:0});
const before=JSON.parse(fs.readFileSync(root+'/settings.json'));before.schemaVersion=14;before.unknown={future:'kept'};
const after=c.analyze(c.migrate(before));assert.equal(after.effective.schemaVersion,16);
before.appearance = before.appearance || {};
before.appearance.hubSelectionRole ??= before.appearance.hubToggleRole ?? "accent";
for(const key of Object.keys(before))if(key!=='schemaVersion')assert.deepEqual(plain(after.document[key]),before[key]);
assert.equal(c.analyze({schemaVersion:17,powerIdle:{future:true}}).future,true);
for(const p of [{lockAfter:0,displayOffAfter:0,suspendAfter:0},{lockAfter:300,displayOffAfter:0,suspendAfter:1800},{lockAfter:0,displayOffAfter:600,suspendAfter:1800}])
 assert.equal(c.analyze({schemaVersion:15,powerIdle:p}).errors.length,0);
for(const p of [{lockAfter:600,displayOffAfter:300},{lockAfter:900,suspendAfter:300},{lockAfter:true},{displayOffAfter:17},{suspendAfter:60}])
 assert(c.analyze({schemaVersion:15,powerIdle:p}).errors.length>0);
console.log('Phase 10C.1 schema, ordering, Never and lossless v14 migration PASS');
