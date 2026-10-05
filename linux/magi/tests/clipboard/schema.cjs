const fs = require('fs'), vm = require('vm'), assert = require('assert');
const base = '.config/quickshell/magi/settings/';
const context = vm.createContext({});
for (const name of ['SettingsSchema.js', 'SettingsMigrations.js'])
    vm.runInContext(fs.readFileSync(base + name, 'utf8'), context);
const run = expression => JSON.parse(JSON.stringify(vm.runInContext(expression, context)));
assert.equal(run('migrate({schemaVersion:5,custom:7}).schemaVersion'), 9);
assert.equal(run('migrate({schemaVersion:5,custom:7}).custom'), 7);
assert.equal(run('analyze(migrate({schemaVersion:5})).effective.clipboard.persistHistory'), false);
for (const value of [10, 100, 200])
    assert.equal(run(`analyze({schemaVersion:6,clipboard:{historyLimit:${value}}}).effective.clipboard.historyLimit`), value);
for (const value of [0, 201, 10.5, '"40"', 'null'])
    assert.equal(run(`analyze({schemaVersion:6,clipboard:{historyLimit:${value}}}).effective.clipboard.historyLimit`), 100);
for (const key of ['enabled','includeImages','includeFiles','persistHistory']) {
    assert.equal(run(`analyze({schemaVersion:6,clipboard:{${key}:false}}).effective.clipboard.${key}`), false);
    assert.ok(run(`analyze({schemaVersion:6,clipboard:{${key}:"bad"}}).errors`).length);
}
console.log('Clipboard v5→v6 defaults, preservation, validation PASS');
