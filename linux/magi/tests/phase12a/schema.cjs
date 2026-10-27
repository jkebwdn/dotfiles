const fs=require('fs'),vm=require('vm'),assert=require('assert'),path=require('path');
const base=path.resolve(__dirname,'../../.config/quickshell/magi/settings');
const ctx=vm.createContext({});
for(const n of ['SettingsSchema.js','SettingsMigrations.js']) vm.runInContext(fs.readFileSync(path.join(base,n),'utf8'),ctx);
const evaluate=s=>JSON.parse(JSON.stringify(vm.runInContext(s,ctx)));
const original=evaluate('defaults()');original.schemaVersion=15;delete original.appearance.hubSelectionRole;
original.appearance.hubToggleRole='teal';original.appearance.navigationAccent='green';original.extra={preserved:[1,2,3]};
function check(input){ctx.input=input;const migrated=evaluate('migrate(input)');const expected=structuredClone(input);expected.schemaVersion=18;expected.appearance=expected.appearance||{};expected.appearance.hubSelectionRole=expected.appearance.hubToggleRole??'accent';assert.deepStrictEqual(migrated,require("../settings/expected-current.cjs")(expected));ctx.input=migrated;assert.deepStrictEqual(evaluate('migrate(input)'),migrated);return migrated;}
check(original);check({schemaVersion:15});
if(process.argv[2])check(JSON.parse(fs.readFileSync(process.argv[2])));
assert(Number.isInteger(evaluate('defaults().schemaVersion')) && evaluate('defaults().schemaVersion') >= 16);
for(const value of ['always','active','playing','hidden']) {ctx.value=value;assert.equal(evaluate('analyze({schemaVersion:16,media:{controlsVisibility:value}}).errors').length,0);}
ctx.input=original;assert.equal(evaluate('analyze(migrate(input)).effective.appearance.hubSelectionRole'),'teal');
assert(evaluate('analyze({schemaVersion:16,appearance:{hubSelectionRole:"#ff0000"}}).warnings').length);
console.log('Phase12A schema migration: exact preservation, idempotence, roles, media modes PASS');
