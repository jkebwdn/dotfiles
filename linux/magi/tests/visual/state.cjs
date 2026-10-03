const fs = require('fs'), vm = require('vm'), assert = require('assert');
const base = '.config/quickshell/magi/';
function load(path) { const scope = vm.createContext({}); vm.runInContext(fs.readFileSync(base + path, 'utf8'), scope); return scope; }
const state = load('icons/IconState.js');
for (const [level, role] of [[0,'low'],[1,'low'],[34,'low'],[35,'medium'],[64,'medium'],[65,'high'],[89,'high'],[90,'full'],[100,'full']]) {
 assert.equal(state.batteryRole(true,false,level), 'battery-'+role);
 assert.equal(state.batteryRole(true,true,level),'battery-charging');
}
assert.equal(state.batteryRole(false,true,100),'battery-unknown');
for (const [level,role] of [[0,'muted'],[1,'low'],[33,'low'],[34,'medium'],[66,'medium'],[67,'high'],[100,'high']]) {
 assert.equal(state.volumeRole(true,false,level),'volume-'+role);
 assert.equal(state.volumeRole(true,true,level),'volume-muted');
}
assert.equal(state.volumeRole(false,false,100),'volume-muted');
for (const [level,role] of [[0,'low'],[24,'low'],[49,'low'],[50,'medium'],[74,'medium'],[75,'high'],[100,'high']]) assert.equal(state.signalRole(level),'wifi-'+role);
const workspaces=load('plugins/bar/workspaces/WorkspaceModel.js');
const ws=id=>({id,name:String(id)}), ids=values=>Array.from(workspaces.normalWorkspaces(values), w=>w.id);
assert.deepEqual(ids([ws(1)]),[1]); assert.deepEqual(ids([ws(2),ws(1)]),[1,2]);
const input=[ws(1),ws(3),ws(2),ws(-1),ws(0),{id:-99,name:'special:chat'},{id:4,name:'named'}];
assert.deepEqual(ids(input),[1,2,3]); assert.equal(input[1].id,3);
assert.deepEqual(ids(input.filter(w=>w.id!==2)),[1,3]);
assert.deepEqual(ids([...input,ws(10)]),[1,2,3,10]);
input[0].name='special:move';assert.deepEqual(ids(input),[2,3]);
console.log('PASS: battery/volume/signal boundaries; normal workspace filtering, sorting, creation, removal, rename, one/two workspaces');
const visual=load('components/controls/VisualState.js');
for(const [hour,text] of [[0,'night'],[4,'night'],[5,'morning'],[11,'morning'],[12,'afternoon'],[17,'afternoon'],[18,'evening'],[22,'evening'],[23,'night']]) assert.equal(visual.greeting(hour),'Good '+text);
assert.equal(visual.progress(10,100,true),.1); assert.equal(visual.progress(0,0,true),-1); assert.equal(visual.progress(10,100,false),-1); assert.equal(visual.progress(200,100,true),1);
const perimeter=visual.perimeter(70,70,10,1); assert.deepEqual(perimeter[0],perimeter.at(-1)); assert(perimeter.every(p=>p.every(v=>isFinite(v)&&v>=1&&v<=69)));
console.log('PASS: local-hour greetings; real-only progress, rounded bounded perimeter');
