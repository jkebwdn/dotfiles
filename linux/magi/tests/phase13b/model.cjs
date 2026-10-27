const fs=require('fs'),vm=require('vm'),assert=require('assert'),path=require('path');
const root=path.resolve(__dirname,'../..'),c=vm.createContext({});
for(const file of ['native/lock/qml/LockLayout.js','.config/quickshell/magi/settings/SettingsSchema.js','.config/quickshell/magi/settings/SettingsMigrations.js']) vm.runInContext(fs.readFileSync(path.join(root,file),'utf8'),c);
const plain=x=>JSON.parse(JSON.stringify(x));
const input=JSON.parse(fs.readFileSync(process.argv[2]));assert.equal(input.schemaVersion,20);
const migrated=plain(c.migrate(input)),expected=structuredClone(input);expected.schemaVersion=22;expected.lockScreen.effects=plain(c.effects(null));
assert.deepStrictEqual(migrated,expected);assert.deepStrictEqual(plain(c.migrate(migrated)),migrated);
assert.deepStrictEqual(migrated.lockScreen.elements,input.lockScreen.elements);
assert.equal(c.analyze(migrated).errors.length,0);
const normalized=plain(c.normalize(migrated.lockScreen));
for(const id of ['time','identity','authentication'])assert.deepStrictEqual(normalized.elements[id],input.lockScreen.elements[id]);
for(const id of ['weather','media']) assert.equal(normalized.elements[id].visible,false);
for(const name of ['centered','editorial','corner','split','minimal']){
 const l=plain(c.preset(name));for(const id of ['weather','media']) l.elements[id].visible=true;
 assert.deepStrictEqual(plain(c.normalize(l)),l);
 for(const [w,h] of [[1920,1080],[1920,1200],[3440,1440],[400,700]]) for(const id of c.ids()){
  const b=c.position(l.elements[id],w,h,300,150);assert(b.x>=16&&b.y>=16&&b.x+300<=w-16&&b.y+150<=h-48);
 }
 for(const id of c.ids())if(id!=='authentication')assert(l.elements[id].z<l.elements.authentication.z);
}
for(const key of ['credential','avatar','weather','media','location','artwork','depth']){
 const bad={};bad[key]={invalid:true};assert.deepStrictEqual(plain(c.effects(bad)),plain(c.effects(null)));
}
for(const key of ['credential','avatar','weather','media'])for(const choice of key==='credential'?['dots','line','segments','ring','minimal']:key==='avatar'?['plain','ring','glow','frame']:key==='weather'?['compact','standard','minimal']:['compact','artwork','minimal'])assert.equal(c.effects({[key]:choice})[key],choice);
console.log('Phase13B model PASS: copied custom layout preserved exactly; optional modules off; styles, bounds, layering and migration idempotence');

// A schema-20 layout has no optional Media entry. The publisher must receive a
// boolean false, not undefined (which produces a live QML binding warning).
const publisher=fs.readFileSync(path.join(root,'.config/quickshell/magi/services/LockAuxiliary.qml'),'utf8');
const enabledExpression=publisher.match(/readonly property bool enabled: (.*)/)[1];
for(const layout of [{},{elements:{}},{elements:{media:{visible:false}}}])
 assert.strictEqual(vm.runInNewContext(enabledExpression,{Settings:{ready:true},layout}),false);
assert.strictEqual(vm.runInNewContext(enabledExpression,{Settings:{ready:true},layout:{elements:{media:{visible:true}}}}),true);
console.log('Phase13B legacy optional-media enabled binding PASS');

const box=(x,y,width=100,height=20,scale=1)=>({x,y,width,height,scale});
assert(!c.overlaps(box(0,0),box(500,0),8));
assert(c.overlaps(box(0,0),box(90,0),8));
assert(!c.overlaps(box(0,0),box(108,0),8));
assert(c.overlaps(box(0,0,100,20,2),box(190,30),8));
assert(!c.overlaps(box(0,0,100,0),box(0,0),8));
console.log('Phase13B scaled media/auth intersection PASS');
