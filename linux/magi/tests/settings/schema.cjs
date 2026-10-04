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
assert.equal(run('migrate({schemaVersion:1,appearance:{theme:"catppuccin-latte"}}).schemaVersion'), 6);
assert.deepEqual(run('analyze({schemaVersion:4}).effective.bar.center'), ['workspaces']);
assert.equal(run('analyze({schemaVersion:4,appearance:{roundness:{master:-4}}}).effective.appearance.roundness.master'), 1);
assert.equal(run('analyze({schemaVersion:4,appearance:{theme:"unknown"}}).effective.appearance.theme'), 'unknown');
assert.equal(run('analyze({schemaVersion:7}).future'), true);
assert.deepEqual(run('analyze({schemaVersion:4,bar:{left:["wifi"],right:["wifi","bogus","volume"]}}).effective.bar.right'), ['volume']);
assert.throws(() => run('analyze(JSON.parse(\'{"schemaVersion":1,"__proto__":{}}\'))'));
assert.throws(() => run('migrate({palette:"catppuccin",appearance:{}})'));
assert.equal(run('analyze({schemaVersion:4,profile:{displayName:"Ada",subtitle:"Ready",avatar:null}}).effective.profile.displayName'), 'Ada');
assert.equal(run('analyze({schemaVersion:4,profile:{avatar:"/tmp/nope"}}).effective.profile.avatar'), null);
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
const v3=run('migrate({schemaVersion:3,controlCentre:{controls:['
    + '{key:"network",module:"wifi",enabled:true,presentation:"tile"},'
    + '{key:"wireless",module:"bluetooth",enabled:true,presentation:"tile"},'
    + '{key:"power-saver",module:"power-saver",enabled:true,presentation:"tile"},'
    + '{key:"airplane-mode",module:"airplane-mode",enabled:true,presentation:"tile"}]}})');
assert.equal(v3.schemaVersion,6);
assert.deepEqual(v3.controlCentre.controls.map(e=>e.accent),['teal','blue','green','lavender']);
const customAccent=run('migrate({schemaVersion:3,controlCentre:{controls:['
    + '{key:"network",module:"wifi",accent:"red",enabled:true,presentation:"tile"}]}})');
assert.equal(customAccent.controlCentre.controls[0].accent,'red');
const invalidAccent=run('analyze({schemaVersion:4,controlCentre:{controls:['
    + '{key:"network",module:"wifi",accent:"rosewater",enabled:true,presentation:"tile"}]}})');
assert.equal(invalidAccent.effective.controlCentre.controls[0].accent,'teal');
assert.ok(invalidAccent.errors.some(e=>e.includes('.accent')));
console.log('Schema: v0→v6, defaults, validation, CC action and semantic-accent migration PASS');

assert.equal(run('defaults().appearance.visual.statusIconSize'), 18);
assert.equal(run('analyze({schemaVersion:4,appearance:{visual:{statusIconSize:22}}}).effective.appearance.visual.statusIconSize'), 22);
for (const key of ['tileBackgroundShade','tileBorderShade']) {
    for (const value of [-1, 0, 1])
        assert.equal(run(`analyze({schemaVersion:4,appearance:{visual:{${key}:${value}}}}).effective.appearance.visual.${key}`), value);
    for (const value of ['2', '-2', '"dark"', 'null'])
        assert.equal(run(`analyze({schemaVersion:4,appearance:{visual:{${key}:${value}}}}).effective.appearance.visual.${key}`), run(`defaults().appearance.visual.${key}`));
}
console.log('Visual defaults, saved size preservation and signed shade validation PASS');
