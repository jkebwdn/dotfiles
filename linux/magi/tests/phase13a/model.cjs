const fs=require('fs'),vm=require('vm'),assert=require('assert'),path=require('path');
const root=process.argv[2], context=vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(root,'native/lock/qml/LockLayout.js'),'utf8'),context);
const plain=v=>JSON.parse(JSON.stringify(v)), model=context;
for(const preset of ['centered','editorial','corner','split','minimal']) {
 const layout=plain(model.preset(preset));assert.deepStrictEqual(plain(model.normalize(layout)),layout);
 for(const [w,h] of [[1920,1080],[1920,1200],[3440,1440],[360,640]])
  for(const id of model.ids()) {
   const box=model.position(layout.elements[id],w,h,Math.min(600,w-32),150);
   assert(box.x>=16&&box.y>=16&&box.x+Math.min(600,w-32)<=w-16&&box.y+150<=h-48);
  }
}
const fallback=plain(model.preset('centered'));
const swapped=plain(fallback);swapped.elements.time.z=1;swapped.elements.identity.z=0;assert.equal(model.normalize(swapped).elements.time.z,1);
for(const mutate of [l=>l.elements.time.anchor='unknown',l=>l.elements.time.offsetX=NaN,l=>l.elements.time.offsetY=1e6,l=>l.elements.time.size=-1,l=>delete l.elements.identity,l=>l.elements.other={},l=>l.elements.time.z=2,l=>l.elements.authentication.visible=false,l=>l.elements.authentication.size=.75,l=>l.layoutVersion=88]) {
 const l=plain(model.preset('split'));mutate(l);assert.deepStrictEqual(plain(model.normalize(l)),fallback);
}
assert.equal(model.snap(395,200,1000,[],false).value,400);
assert.equal(model.snap(395,200,1000,[],true).value,395);
assert.equal(model.snap(195,200,1000,[200],false).guide,200);
for(const anchor of model.anchors()) {
 const e=model.element(anchor,0,0,1,true,0), positioned=model.place(e,200,150,1000,700,300,100);
 const p=model.position(positioned,1000,700,300,100);assert(Math.abs(p.x-200)<.1);assert(Math.abs(p.y-150)<.1);
}
const schema=vm.createContext({});
for(const name of ['SettingsSchema.js','SettingsMigrations.js']) vm.runInContext(fs.readFileSync(path.join(root,'.config/quickshell/magi/settings',name),'utf8'),schema);
const input=process.argv[3] ? JSON.parse(fs.readFileSync(process.argv[3])) : {schemaVersion:19,appearance:{theme:'nord',globalBlur:{managed:true,size:12}},custom:{preserved:42}};
assert.equal(input.schemaVersion,19);
const migrated=plain(schema.migrate(input)), expected=plain(input);expected.schemaVersion=21;expected.lockScreen=plain(schema.defaults().lockScreen);
assert.deepStrictEqual(migrated,expected);assert.deepStrictEqual(plain(schema.migrate(migrated)),migrated);
assert.deepStrictEqual(plain(model.normalize(migrated.lockScreen)),fallback);
assert.equal(schema.analyze(migrated).errors.length,0);
for(const name of ['centered','editorial','corner','split','minimal']) {const s=plain(schema.defaults());s.lockScreen=plain(model.preset(name));assert.equal(schema.analyze(s).errors.length,0)}
const bad=plain(schema.defaults());bad.lockScreen=plain(model.preset('split'));bad.lockScreen.elements.authentication.visible=false;
assert(schema.analyze(bad).errors.length);assert.deepStrictEqual(plain(schema.analyze(bad).effective.lockScreen),plain(schema.defaults().lockScreen));
console.log('Phase13A model/migration PASS: presets, bounds, anchors, snapping, malformed fallback, auth floor, exact preservation and idempotence');
