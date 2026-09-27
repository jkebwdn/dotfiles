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
assert.deepEqual(run('analyze({schemaVersion:1}).effective.bar.center'), ['workspaces']);
assert.equal(run('analyze({schemaVersion:1,appearance:{roundness:{master:-4}}}).effective.appearance.roundness.master'), 1);
assert.equal(run('analyze({schemaVersion:1,appearance:{theme:"unknown"}}).effective.appearance.theme'), 'unknown');
assert.equal(run('analyze({schemaVersion:2}).future'), true);
assert.deepEqual(run('analyze({schemaVersion:1,bar:{left:["wifi"],right:["wifi","bogus","volume"]}}).effective.bar.right'), ['volume']);
assert.throws(() => run('analyze(JSON.parse(\'{"schemaVersion":1,"__proto__":{}}\'))'));
assert.throws(() => run('migrate({palette:"catppuccin",appearance:{}})'));
console.log('Schema: 11 assertions PASS');
