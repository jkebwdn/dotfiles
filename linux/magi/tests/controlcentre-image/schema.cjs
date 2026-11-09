const fs = require('fs'), vm = require('vm'), assert = require('assert');
const ctx = vm.createContext({});
for (const name of ['SettingsSchema','SettingsMigrations'])
    vm.runInContext(fs.readFileSync(`.config/quickshell/magi/settings/${name}.js`, 'utf8'), ctx);
const plain = x => JSON.parse(JSON.stringify(x));
const base = plain(ctx.defaults());
assert.equal(base.schemaVersion, 22);
assert.deepEqual(base.controlCentre.decoration, {enabled:false,asset:null,height:340,overlap:8,verticalOffset:0,duration:180,flip:false});
const old = structuredClone(base); delete old.controlCentre.decoration;
const analyzed = ctx.analyze(old);
assert.deepEqual(plain(analyzed.document), old, 'additive defaults never rewrite old Settings');
assert.deepEqual(plain(analyzed.effective.controlCentre.decoration), base.controlCentre.decoration);
const asset = {id:'decoration-image:' + 'a'.repeat(64) + '.png',width:100,height:200,bounds:[10,10,85,180]};
const doc = structuredClone(base);
doc.controlCentre.decoration = {enabled:true,asset,height:420,overlap:14,verticalOffset:-50,duration:320,flip:true};
const result = ctx.analyze(ctx.migrate(doc));
assert.deepEqual(plain(result.errors), []);
assert.deepEqual(plain(result.effective), doc);
assert.deepEqual(plain(ctx.analyze(JSON.parse(JSON.stringify(result.document))).effective), doc);
for (const bad of [{enabled:1},{height:119},{height:601},{height:320.5},{overlap:-1},{overlap:25},
    {verticalOffset:301},{duration:10},{duration:501},{flip:'yes'},{asset:{...asset,id:'file:///tmp/x.png'}},
    {asset:{...asset,id:asset.id.replace('.png','.webp')}},{asset:{...asset,bounds:[0,0,101,200]}}]) {
    const input=structuredClone(doc); Object.assign(input.controlCentre.decoration,bad);
    assert(ctx.analyze(input).errors.length,JSON.stringify(bad));
}
const gif = structuredClone(doc); gif.controlCentre.decoration.asset.id = asset.id.replace('.png','.gif');
assert.deepEqual(plain(ctx.analyze(gif).errors), []);
assert.deepEqual(plain(ctx.analyze(JSON.parse(JSON.stringify(gif))).effective.controlCentre.decoration), gif.controlCentre.decoration);
const slow = structuredClone(doc); slow.controlCentre.decoration.duration = 500;
assert.deepEqual(plain(ctx.analyze(slow).errors), []);
console.log('Control Centre decoration defaults, validation and persistence PASS');
