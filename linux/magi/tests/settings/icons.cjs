const fs=require('fs'),vm=require('vm'),assert=require('assert'),path=require('path');
const base=process.argv[2];
const index=JSON.parse(fs.readFileSync(base+'/packs/registry.json'));
const registry={packs:index.manifests.map(name=>({...JSON.parse(fs.readFileSync(base+'/packs/'+name)),baseUrl:'file://'+path.resolve(base+'/packs/'+path.dirname(name))+'/'}))};
const ctx=vm.createContext({});
for (const file of ['IconResolver.js','IconState.js']) vm.runInContext(fs.readFileSync(base+'/'+file,'utf8'),ctx);
const canonical=registry.packs.find(p=>p.id==='magi-default');
const settings={pack:'alternate',modulePacks:{wifi:'magi-legacy'},overrides:{global:{wifi:{source:'user',assetId:'retired'}}}};
const alternate={id:'alternate',baseUrl:'file:///tmp/pack/',parent:'ignored',roles:{wifi:{asset:'alternate-wifi.svg',colorMode:'fixed'}}};
registry.packs.push(alternate);
const resolve=role=>ctx.resolve(registry,settings,role);
assert.equal(resolve('wifi').icon.url,'file:///tmp/pack/alternate-wifi.svg'); // A
assert.equal(resolve('wifi').sourcePack,'alternate');
assert.equal(resolve('wifi').icon.colorMode,'fixed');
function sameDefault(role) {
 const result=resolve(role), expected=ctx.descriptor(canonical,role);
 assert(expected, 'default mapping missing: '+role);
 assert.equal(JSON.stringify(result.icon),JSON.stringify(expected),role);
 assert.equal(result.sourcePack,'magi-default',role);
 assert.notEqual(result.icon.text,'?');
 if(result.icon.kind==='managed') assert(fs.existsSync(new URL(result.icon.url)),role);
}
sameDefault('bluetooth'); // B
assert.equal(resolve('not-a-role').icon.kind,'placeholder'); // C
assert.equal(resolve('not-a-role').icon.text,undefined);
// Deliberately remove the same existing role from both fixture packs.
const saved=canonical.roles.brightness;delete canonical.roles.brightness;
assert.equal(resolve('brightness').icon.kind,'placeholder');canonical.roles.brightness=saved;
const states=new Set();
for(const available of [false,true]) for(const charging of [false,true]) for(const percent of [0,1,10,34,35,64,65,80,89,90,100]) {
 const role=ctx.batteryRole(available,charging,percent);states.add(role);sameDefault(role); // D
}
assert.deepEqual([...states].sort(),['battery-unknown','battery-charging','battery-full','battery-high','battery-medium','battery-low'].sort());
for(let n=0;n<=90;n+=10) sameDefault('battery-'+n);
for(const role of ['settings','lock','hibernate','shutdown','reboot','dnd','caffeine','vpn','power-saver','airplane-mode','brightness','notifications','profile','media-play','media-pause',
 'volume-muted','volume-low','volume-medium','volume-high','wifi-off','wifi-disconnected','wifi-low','wifi-medium','wifi-high','bluetooth-off','bluetooth-on','bluetooth-connected']) sameDefault(role); // E
for (const value of [null,{}, {asset:'../../escape.svg'},{text:''},{text:'?'}]) {
 alternate.roles.wifi=value;sameDefault('wifi'); // F
}
alternate.roles=null;sameDefault('wifi');
settings.pack='unknown';sameDefault('wifi');sameDefault('battery-high'); // G
assert.equal(ctx.resolve(null,null,'wifi').icon.kind,'placeholder');
// Entire default vocabulary has no blank or question-mark descriptors.
for(const role of Object.keys(canonical.roles)) sameDefault(role);
const renderer=fs.readFileSync(base+'/../components/controls/Icon.qml','utf8');
assert(!renderer.includes('text: asset.status'));
assert(renderer.includes('magi-default/missing.svg'));
assert(!renderer.includes('assetId'));
assert(!fs.existsSync(base+'/../components/settings/pages/IconsPage.qml'));
const store=fs.readFileSync(base+'/../settings/SettingsStore.qml','utf8');assert(!store.includes('setIconOverride'));
const app=fs.readFileSync(base+'/../services/LauncherIcons.qml','utf8');
assert(app.includes('Quickshell.iconPath(app.icon, true)'));assert(!app.includes('IconRegistry'));
console.log('A–H semantic fallback: selected → same-ID default → SVG placeholder; all battery/CC roles; overrides retired PASS');
