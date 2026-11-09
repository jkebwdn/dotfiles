const fs = require('fs'), vm = require('vm'), assert = require('assert');
const ctx = vm.createContext({});
for (const name of ['SettingsSchema', 'SettingsMigrations'])
    vm.runInContext(fs.readFileSync(`.config/quickshell/magi/settings/${name}.js`, 'utf8'), ctx);
const plain = value => JSON.parse(JSON.stringify(value));
const base = plain(ctx.defaults());
assert.deepEqual(base.bar.left, ['clock', 'date']);
assert.equal(base.bar.modules.customImage, undefined);
const asset = {id:'bar-image:' + 'a'.repeat(64) + '.gif', width:443, height:443, bounds:[3,167,427,147]};
for (const region of ['left', 'center', 'right']) {
    const doc = structuredClone(base);
    doc.bar[region].push('customImage');
    doc.bar.modules.customImage = {asset, height:32, trim:true};
    const result = ctx.analyze(ctx.migrate(doc));
    assert.deepEqual(plain(result.errors), []);
    assert.deepEqual(plain(result.effective.bar), doc.bar);
    assert.deepEqual(plain(ctx.analyze(JSON.parse(JSON.stringify(result.document))).effective.bar), doc.bar);
}
for (const bad of [{asset:{...asset, id:'file:///tmp/x.gif'}}, {asset:{...asset,bounds:[3,167,441,147]}},
    {asset:{...asset,bounds:[0,0,0,0]}}, {height:100}, {height:31.5}, {trim:'yes'}, {asset:[]}, {asset:{...asset,width:5000}}]) {
    const doc = structuredClone(base); doc.bar.modules.customImage = bad;
    assert(ctx.analyze(doc).errors.length > 0, JSON.stringify(bad));
}
console.log('Custom Image schema, placement, round trip and old defaults PASS');
