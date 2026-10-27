const fs=require('fs'),vm=require('vm'),assert=require('assert'),path=require('path');
const root=path.resolve(__dirname,'../..'),c=vm.createContext({});
for(const file of ['SettingsSchema.js','SettingsMigrations.js'])vm.runInContext(fs.readFileSync(root+'/.config/quickshell/magi/settings/'+file,'utf8'),c);
const plain=x=>JSON.parse(JSON.stringify(x));
const input=JSON.parse(fs.readFileSync(process.argv[2],'utf8'));
assert.equal(input.schemaVersion,21);
const expected=structuredClone(input);expected.schemaVersion=22;
const actual=plain(c.migrate(input));assert.deepStrictEqual(actual,expected);assert.deepStrictEqual(plain(c.migrate(actual)),actual);
for(const mode of ['always','when-items','hidden']) {
 const value=structuredClone(actual);value.bar.trayVisibility=mode;
 const cleaned=plain(c.migrate(value));assert.deepStrictEqual(cleaned,actual);
 assert(!Object.hasOwn(c.defaults().bar,'trayVisibility'));
}
assert.equal(c.defaults().schemaVersion,22);assert.equal(c.analyze({schemaVersion:23}).future,true);
const bind=fs.readFileSync(path.resolve(root,'../t15g/hypr/.config/hypr/hyprland.lua'),'utf8');
for(const [key,route] of [['A','audio'],['T','tray']])assert(bind.includes('SUPER .. " + '+key+'", hl.dsp.exec_cmd("quickshell ipc -c magi call magi toggle '+route+'")'));
console.log('Phase14B schema22/operator preservation, retired visibility cleanup and shortcut source PASS');
