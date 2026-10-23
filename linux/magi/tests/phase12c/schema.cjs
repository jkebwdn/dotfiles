const fs=require('fs'),vm=require('vm'),assert=require('assert'),path=require('path');
const root=path.resolve(__dirname,'../../.config/quickshell/magi');
const ctx=vm.createContext({});
for(const name of ['SettingsSchema.js','SettingsMigrations.js'])vm.runInContext(fs.readFileSync(root+'/settings/'+name,'utf8'),ctx);
const plain=x=>JSON.parse(JSON.stringify(x));
const base=plain(ctx.defaults());assert.equal(base.schemaVersion,18);assert.deepEqual(plain(ctx.analyze(base).errors),[]);
const fixture=process.argv[2]?JSON.parse(fs.readFileSync(process.argv[2])):{schemaVersion:16,bar:{left:['wifi'],center:[],right:['bluetooth']},appearance:{roundness:{master:1.3,roles:{barPill:.8}},surfaceBorders:{wifi:true,bluetooth:false,role:'red',width:3}},extra:{preserved:true}};
const migrated=plain(ctx.migrate(fixture)),expected=structuredClone(fixture);expected.schemaVersion=18;
assert.deepEqual(migrated,require("../settings/expected18.cjs")(expected));assert.deepEqual(plain(ctx.migrate(migrated)),migrated);
const effective=plain(ctx.analyze(migrated).effective);
assert.equal(effective.bar.visual.host.enabled,false);assert.equal(effective.bar.visual.statusPills.role,'surface');assert.equal(effective.bar.visual.statusPills.opacity,1);assert.equal(effective.bar.visual.workspacePills.roundness,null);
for(const id of ['wifi','bluetooth'])assert.equal(effective.bar.modules[id].accentRole,'accent');
for(const family of ['host','statusPills'])for(const [key,bad] of [['enabled',1],['role','#fff'],['opacity',-1],['opacity',1.1],['opacity','0.5'],['opacity',null]]){
 const doc=structuredClone(base);doc.bar.visual[family][key]=bad;assert(ctx.analyze(doc).errors.length,`${family}.${key}`);
}
for(const value of [0,.25,.5,1]){const doc=structuredClone(base);doc.bar.visual.statusPills.opacity=value;assert.equal(ctx.analyze(doc).errors.length,0)}
const accents=structuredClone(base);accents.bar.modules.wifi.accentRole='red';accents.bar.modules.bluetooth.accentRole='lavender';accents.bar.visual.statusPills.opacity=.55;accents.appearance.roundness.roles.barPill=1.4;
assert.equal(ctx.analyze(accents).errors.length,0);assert.deepEqual(Object.keys(accents.bar.modules.wifi),['accentRole']);
for(const lane of ['left','center','right']){const doc=structuredClone(base);doc.bar[lane]=[];assert.equal(ctx.analyze(doc).errors.length,0)}
const duplicates=structuredClone(base);duplicates.bar.left=['wifi'];duplicates.bar.right=['wifi'];assert(ctx.analyze(duplicates).warnings.length);assert.deepEqual(plain(ctx.analyze(duplicates).effective.bar.right),[]);
const schemaSource=fs.readFileSync(root+'/settings/SettingsSchema.js','utf8');const barSource=fs.readFileSync(root+'/components/bar/Bar.qml','utf8');
for(const id of vm.runInContext('barIds',ctx))assert(barSource.includes('"'+id+'":'),id);
assert(!fs.existsSync(root+'/components/settings/pages/SurfacesPage.qml'),'Phase12E retires Surfaces; Bar ownership remains in BarInspector');
console.log('Phase12C schema: exact migration preservation, defaults, bounds, semantic roles, singleton registry and ownership PASS');
