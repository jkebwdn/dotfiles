const fs = require('fs'), vm = require('vm'), assert = require('assert');
const base = process.argv[2];
const context = vm.createContext({});
for (const name of ['SettingsSchema.js', 'SettingsMigrations.js'])
    vm.runInContext(fs.readFileSync(base + '/' + name, 'utf8'), context);
const run = expression => JSON.parse(JSON.stringify(vm.runInContext(expression, context)));
assert.equal(run('analyze(defaults()).errors').length, 0);
assert.equal(run('analyze(migrate({palette:"everforest",barCenterPlugins:[],custom:7})).effective.appearance.theme'), 'everforest-dark-hard');
assert.deepEqual(run('migrate({palette:"catppuccin",barCenterPlugins:[]}).bar.center'), []);
assert.equal(run('migrate({palette:"catppuccin",custom:7}).custom'), 7);
assert.equal(run('migrate({schemaVersion:1,appearance:{theme:"catppuccin-latte"}}).schemaVersion'), 3);
assert.deepEqual(run('analyze({schemaVersion:3}).effective.bar.center'), ['workspaces']);
assert.equal(run('analyze({schemaVersion:3,appearance:{roundness:{master:-4}}}).effective.appearance.roundness.master'), 1);
assert.equal(run('analyze({schemaVersion:3,appearance:{theme:"unknown"}}).effective.appearance.theme'), 'unknown');
assert.equal(run('analyze({schemaVersion:4}).future'), true);
assert.deepEqual(run('analyze({schemaVersion:3,bar:{left:["wifi"],right:["wifi","bogus","volume"]}}).effective.bar.right'), ['volume']);
assert.throws(() => run('analyze(JSON.parse(\'{"schemaVersion":1,"__proto__":{}}\'))'));
assert.throws(() => run('migrate({palette:"catppuccin",appearance:{}})'));
assert.equal(run('analyze({schemaVersion:3,profile:{displayName:"Ada",subtitle:"Ready",avatar:null}}).effective.profile.displayName'), 'Ada');
assert.equal(run('analyze({schemaVersion:3,profile:{avatar:"/tmp/nope"}}).effective.profile.avatar'), null);
const migrated=run('migrate({schemaVersion:2,controlCentre:{columns:4,sections:{},controls:['
    + '{key:"sound",module:"volume",enabled:true,presentation:"tile"},'
    + '{key:"wireless",module:"bluetooth",enabled:true,presentation:"tile"},'
    + '{key:"network",module:"wifi",enabled:true,presentation:"tile"},'
    + '{key:"power",module:"battery",enabled:true,presentation:"tile"}]}})');
assert.deepEqual(migrated.controlCentre.controls.map(e=>e.module),['wifi','bluetooth','power-saver','airplane-mode']);
assert.deepEqual(migrated.controlCentre.actions.map(e=>e.module),['vpn','dnd','caffeine','lock','hibernate','shutdown']);
assert.equal(migrated.controlCentre.actionColumns,6);
const custom=run('migrate({schemaVersion:2,controlCentre:{sections:{},controls:[{key:"network",module:"wifi",enabled:false,presentation:"tile"}]}})');
assert.deepEqual(custom.controlCentre.controls.map(e=>e.module),['wifi']);
assert.deepEqual(run('analyze(migrate({schemaVersion:2})).effective.controlCentre.actions.map(e=>e.module)'),
    ['vpn','dnd','caffeine','lock','hibernate','shutdown']);
console.log('Schema: v0→v3, defaults, validation and CC action migration PASS');
