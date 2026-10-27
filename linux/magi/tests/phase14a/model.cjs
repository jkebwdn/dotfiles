const fs=require('fs'),vm=require('vm'),assert=require('assert');
const base='.config/quickshell/magi/';
const c=vm.createContext({});vm.runInContext(fs.readFileSync(base+'components/tray/TrayActions.js','utf8'),c);
let calls=[];const item={id:'app',title:'App',hasMenu:true,menu:{},onlyMenu:false,activate(){calls.push('primary')},secondaryActivate(){calls.push('secondary')},scroll(d,h){calls.push([d,h])}};
const menu=()=>calls.push('menu');
for(const action of ['primary','menu','secondary'])assert(c.invoke(item,action,menu));
item.onlyMenu=true;assert(c.invoke(item,'primary',menu));
assert(c.scroll(item,120,-240));assert.deepEqual(calls,['primary','menu','secondary','menu',[-240,false],[120,true]]);
item.hasMenu=false;assert(!c.invoke(item,'primary',menu));assert(!c.invoke(null,'menu',menu));assert(!c.invoke({},'primary',menu));
assert(!c.invoke({activate(){throw Error('dead')}},'primary',menu));
assert.equal(c.name({}),'Background application');assert.equal(c.tooltip({}),'');
assert(c.tooltip({title:'x'.repeat(1000),tooltipDescription:'y'.repeat(5000)}).length<=781);
for(let n=0;n<70;n++)for(const width of [38,80,130,240]){
 const input=Array.from({length:n},(_,i)=>i),p=c.partition(input,width,30);
 assert.deepEqual([...p.visible,...p.overflow],input);
 assert(8+(p.visible.length+(p.overflow.length?1:0))*30<=width);
}
const s=vm.createContext({});for(const f of ['SettingsSchema','SettingsMigrations'])vm.runInContext(fs.readFileSync(base+'settings/'+f+'.js','utf8'),s);
assert.equal(s.defaults().schemaVersion,22);
assert(['left','center','right'].every(region=>!s.defaults().bar[region].includes('tray')));
const doc=s.defaults();doc.bar.left=['tray'];doc.bar.center=['tray'];doc.bar.right=['tray'];
const result=s.analyze(doc);assert.equal(result.effective.bar.left.concat(result.effective.bar.center,result.effective.bar.right).filter(x=>x==='tray').length,1);
if(process.argv[2]){const operator=JSON.parse(fs.readFileSync(process.argv[2]));const after=s.migrate(operator);assert.deepEqual(JSON.parse(JSON.stringify(after)),operator);for(const lane of ['left','center','right'])assert.deepEqual(after.bar[lane],operator.bar[lane]);}
console.log('Phase14A actions, malformed data, long content, overflow bounds, singleton, schema21/operator layout PASS');
