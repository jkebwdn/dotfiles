const fs=require('fs'),vm=require('vm'),assert=require('assert'),path=require('path');
const r=path.resolve(__dirname,'../../.config/quickshell/magi/settings'),c=vm.createContext({});
for(const p of ['SettingsSchema.js','SettingsMigrations.js'])vm.runInContext(fs.readFileSync(path.join(r,p),'utf8'),c);
const plain=v=>JSON.parse(JSON.stringify(v));
const old=process.env.MAGI_PHASE12G_FIXTURE ? JSON.parse(fs.readFileSync(process.env.MAGI_PHASE12G_FIXTURE)) : plain(c.defaults());
if(!process.env.MAGI_PHASE12G_FIXTURE){old.schemaVersion=18;delete old.appearance.globalBlur;delete old.applicationAppearance;delete old.lockScreen;}
assert.equal(old.schemaVersion,18);
const migrated=plain(c.migrate(old)), expected=structuredClone(old);
expected.appearance.globalBlur={managed:false,size:8};expected.schemaVersion=22;expected.lockScreen=plain(c.defaults().lockScreen);expected.applicationAppearance=plain(c.defaults().applicationAppearance);
assert.deepEqual(migrated,expected);assert.deepEqual(plain(c.migrate(migrated)),migrated);
assert.deepEqual(plain(c.analyze(migrated).errors),[]);
assert(!('windows' in c.defaults()));
assert.deepEqual(Object.keys(migrated.applicationAppearance).sort(),['backgroundOpacity','blurEnabled','managed']);
for(const a of [1,.88,.5]){
 const d=structuredClone(migrated);d.applicationAppearance={managed:true,backgroundOpacity:a,blurEnabled:false};
 assert.deepEqual(plain(c.analyze(d).errors),[]);
 delete d.applicationAppearance;delete d.appearance.globalBlur;delete d.schemaVersion;delete d.lockScreen;const prev=structuredClone(old);delete prev.schemaVersion;
 assert.deepEqual(d,prev,'all existing settings preserved');
}
for(const value of [.49,1.01,'0.9',null]){
 const d=structuredClone(migrated);d.applicationAppearance.backgroundOpacity=value;
 assert(c.analyze(d).errors.length>0);
}
console.log('Phase12G appearance semantics through schema20: preservation, idempotence, bounds and no window-opacity fields PASS');
