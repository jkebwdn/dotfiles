const fs=require('fs'), vm=require('vm'), assert=require('assert'), path=require('path');
const dir=path.resolve(__dirname,'../../.config/quickshell/magi/settings'), ctx=vm.createContext({});
for(const file of ['SettingsSchema.js','SettingsMigrations.js']) vm.runInContext(fs.readFileSync(path.join(dir,file),'utf8'),ctx);
const plain=x=>JSON.parse(JSON.stringify(x));
const old={schemaVersion:22,bar:{visual:{statusPills:{enabled:true,role:'elevated',opacity:.6}},modules:{wifi:{accentRole:'red'},bluetooth:{accentRole:'blue'}}}};
assert.deepEqual(plain(ctx.migrate(old)),old);
const effective=plain(ctx.analyze(old).effective);
assert.equal(effective.bar.visual.statusPills.role,'elevated');
assert.equal(effective.bar.modules.wifi.backgroundRole,undefined);
assert.equal(effective.bar.modules.battery,undefined);
for(const id of ['wifi','bluetooth','volume','controlcentre','battery','tray','clock','date','notifications','clipboard']) {
 const doc=plain(ctx.defaults()); doc.bar.modules[id]={...doc.bar.modules[id],backgroundRole:'green',foregroundRole:'red'};
 assert.equal(ctx.analyze(doc).errors.length,0);
 assert.deepEqual(plain(ctx.analyze(JSON.parse(JSON.stringify(doc))).effective.bar.modules[id]),doc.bar.modules[id]);
 for(const bad of ['#ff0000','bogus',4,{},[]]) { doc.bar.modules[id].backgroundRole=bad; const result=ctx.analyze(doc); assert(result.errors.length); assert.equal(result.effective.bar.modules[id].backgroundRole,undefined); }
 doc.bar.modules[id].backgroundRole=null; assert.equal(ctx.analyze(doc).errors.length,0);
}
const battery=plain(ctx.defaults());battery.bar.modules.battery={backgroundRole:'blue',percentageBackgroundRole:'green',percentageForegroundRole:'background',showPercentage:false};
assert.equal(ctx.analyze(battery).errors.length,0);
assert.deepEqual(plain(ctx.analyze(battery).effective.bar.modules.battery),battery.bar.modules.battery);
battery.bar.modules.battery.showPercentage='false'; assert(ctx.analyze(battery).errors.length);
console.log('Daily polish schema PASS: sparse inheritance, independent roles, serialization, invalid overrides, schema 22 unchanged');
