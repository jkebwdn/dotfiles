const fs=require('fs'),vm=require('vm'),assert=require('assert'),path=require('path');
const root=path.resolve(__dirname,'../../.config/quickshell/magi');
const ctx=vm.createContext({});
for(const name of ['SettingsSchema.js','SettingsMigrations.js'])vm.runInContext(fs.readFileSync(path.join(root,'settings',name),'utf8'),ctx);
const evaluate=s=>JSON.parse(JSON.stringify(vm.runInContext(s,ctx)));
const registry=JSON.parse(fs.readFileSync(path.join(root,'theme/palettes/registry.json')));
const fixture=process.argv[2]?JSON.parse(fs.readFileSync(process.argv[2])):evaluate('defaults()');
ctx.input=fixture;const normalized=evaluate('analyze(migrate(input)).effective');
assert.equal(normalized.schemaVersion,18);
for(const theme of registry.themes){
 const expected=structuredClone(normalized);expected.appearance.theme=theme.id;ctx.input=expected;
 assert.deepStrictEqual(evaluate('migrate(input)'),expected);
 assert.deepStrictEqual(evaluate('analyze(input).effective'),expected);
}
ctx.input=fixture;assert.equal(evaluate('analyze(migrate(input)).effective.appearance.theme'),fixture.appearance.theme);
console.log('Phase12B schema16: all 18 IDs, unchanged migration and unrelated values PASS');
