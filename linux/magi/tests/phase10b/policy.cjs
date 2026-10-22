const fs=require('fs'),vm=require('vm'),assert=require('assert');
const root=process.argv[2]; const ctx=vm.createContext({});
vm.runInContext(fs.readFileSync(root+'/components/bar/OutputPolicy.js','utf8'),ctx);
assert.equal(ctx.eligible(undefined).length,0);assert.equal(ctx.main(undefined),null);
const e={name:'eDP-1',width:1920,height:1080,scale:2}, h={name:'HDMI-A-1',width:2560,height:1440,scale:1.5};
assert.equal(ctx.main([h,e]),e); assert.equal(ctx.main([h],e),h);
assert.equal(ctx.selected([e,h],e,false).length,1);assert.equal(ctx.selected([e,h],e,true).length,2);
assert.equal(ctx.main([{name:'DP-1',width:0,height:0}]),null);
const d={name:'DP-1',width:1920,height:1080}, inactive={name:'DP-9',width:0,height:0};
assert.equal(ctx.main([h,e],h,h.name),e); // Internal always wins.
assert.equal(ctx.main([h,d],h,d.name),h); // Focus changes cannot move retained main.
assert.equal(ctx.main([h,d],null,h.name),h); // Focus beats alphabetical fallback once.
assert.equal(ctx.main([h,d],e,h.name),h); // Removed previous output selects focused active output.
assert.equal(ctx.main([h,d],e,inactive.name),d); // Inactive focus is ignored.
assert.equal(ctx.main([d,h],null,'missing'),d);assert.equal(ctx.main([h,d],null,'missing'),d);
assert.equal(ctx.main([h,d],null,h.name),ctx.main([d,h],null,h.name));
const reconnected={...h};assert.notEqual(reconnected,h);assert.equal(ctx.main([reconnected],h),reconnected);
for(const screen of [e,h,{width:320,height:240},{width:80,height:60}])
 for(const inset of [0,16,64]) for(const offset of [0,12,32]) for(const bottom of [false,true]) {
  const g=ctx.geometry(screen.width,screen.height,inset,offset,bottom,600);
  assert(g.width>=0 && g.width<=screen.width);assert(g.y>=0 && g.y+48<=screen.height);
  const expected=48+Math.min(offset,Math.max(0,screen.height-48));
  assert.equal(g.reservation,expected);assert.equal(g.top+g.bottom,expected);
  assert.equal(g.bottom,bottom?expected:0);assert.equal(g.top,bottom?0:expected);
  assert.equal(g.y,bottom?screen.height-48-g.edgeOffset:g.edgeOffset);
 }
vm.runInContext(fs.readFileSync(root+'/settings/SettingsSchema.js','utf8')+'\n'+fs.readFileSync(root+'/settings/SettingsMigrations.js','utf8'),ctx);
const before=JSON.parse(fs.readFileSync(root+'/settings.json','utf8'));before.schemaVersion=13;
const after=ctx.analyze(ctx.migrate(before));assert.equal(after.effective.schemaVersion,16);
const defaults=ctx.defaults();assert.equal(defaults.bar.externalDisplays,false);assert.equal(defaults.bar.position,'top');
assert.equal(defaults.bar.horizontalInset,0);assert.equal(defaults.bar.edgeOffset,0);
for(const key of ['externalDisplays','position','horizontalInset','edgeOffset'])
 assert.equal(after.effective.bar[key],before.bar[key]===undefined?defaults.bar[key]:before.bar[key]);
before.appearance = before.appearance || {};
before.appearance.hubSelectionRole ??= before.appearance.hubToggleRole ?? "accent";
for(const key of Object.keys(before)) if(key!=='schemaVersion') assert.equal(JSON.stringify(after.document[key]),JSON.stringify(before[key]),key);
for(const [key,value] of [['position','left'],['horizontalInset',65],['edgeOffset',33],['externalDisplays','yes']]) {
 const input=ctx.defaults();input.bar[key]=value;assert(ctx.analyze(input).errors.length>0,key);
}
console.log('Phase 10B policy, mixed logical sizes/scales, reservation and lossless v13 migration PASS');
