const fs=require('fs'),vm=require('vm'),assert=require('assert'),path=require('path');
const root=path.resolve(__dirname,'../../.config/quickshell/magi');
const c=vm.createContext({});for(const name of ['SettingsSchema.js','SettingsMigrations.js'])vm.runInContext(fs.readFileSync(root+'/settings/'+name,'utf8'),c);
const plain=x=>JSON.parse(JSON.stringify(x));
const base=plain(c.defaults());assert.equal(base.schemaVersion,18);assert.deepEqual(plain(c.analyze(base).errors),[]);
const old=structuredClone(base);old.schemaVersion=17;delete old.controlCentre.layout;old.controlCentre.sections={profile:true,quickControls:true,sliders:true,actions:true,media:true};old.media.enabled=true;delete old.appearance.roundness.roles.secondaryControl;
const fixtures=[old];
for(const key of Object.keys(old.controlCentre.sections)){const d=structuredClone(old);d.controlCentre.sections[key]=false;fixtures.push(d)}
for(const group of ['controls','actions','sliders']){const d=structuredClone(old);d.controlCentre[group]=[];fixtures.push(d)}
const custom=structuredClone(old);custom.controlCentre.controls.reverse();custom.controlCentre.controls[0].enabled=false;custom.controlCentre.controls[1].accent='red';custom.controlCentre.actions.reverse();custom.media.enabled=false;custom.appearance.roundness.roles.action=.65;fixtures.push(custom);
if(process.argv[2])fixtures.push(JSON.parse(fs.readFileSync(process.argv[2])));
for(const input of fixtures){const migrated=plain(c.migrate(input));assert.deepEqual(migrated,require('../settings/expected18.cjs')(input));assert.deepEqual(plain(c.migrate(migrated)),migrated);assert.deepEqual(plain(c.analyze(migrated).errors),[]);
 const effective=plain(c.analyze(migrated).effective);for(const group of ['controls','actions','sliders'])assert.deepEqual(effective.controlCentre[group],plain(c.analyze(input).effective.controlCentre[group]));
 assert(!('sections' in migrated.controlCentre));assert(!('enabled' in (migrated.media||{})));
 for(const section of Object.keys(input).filter(k=>!['schemaVersion','controlCentre','appearance','media'].includes(k)))assert.deepEqual(migrated[section],input[section]);
}
for(const layout of [['media','profile','sliders','actions','controls'],[],['profile']]){const d=structuredClone(base);d.controlCentre.layout=layout;assert.deepEqual(plain(c.analyze(d).errors),[])}
for(const layout of [['profile','profile'],['bogus'],'profile']){const d=structuredClone(base);d.controlCentre.layout=layout;assert(c.analyze(d).errors.length)}
const defs=plain(c.controlDefinitions());for(const d of defs)assert(d.presentations.includes('slider')?!d.presentations.includes('tile'):d.presentations.includes('tile')&&d.presentations.includes('action'));
const section=vm.createContext({});vm.runInContext(fs.readFileSync(root+'/plugins/bar/controlcentre/SectionLayout.js','utf8'),section);
assert.deepEqual(plain(section.compose(['media','profile','actions'],[true,true,false,true,true],[10,20,30,40,50],[1,2,3,4,5])),{positions:[55,0,0,66,0],height:106});
const parts=['ControlCentrePreview.qml','CCControlPreview.qml','CCSectionPreview.qml'].map(n=>fs.readFileSync(root+'/components/settings/'+n,'utf8')).join('\n');
for(const token of ['ControlCatalog','Process {','onPrimaryTriggered:','onSecondaryTriggered:','onValueMoved:'])assert(!parts.includes(token));
assert(parts.includes('SectionLayout.compose'));for(const presenter of ['CC.ProfileHeader','CC.MediaSection','CC.ControlTile','CC.ActionButton','Controls.IconSlider'])assert(parts.includes(presenter));
console.log('Phase12D migration/composition/registry/presenter-boundary PASS: '+fixtures.length+' fixtures');
