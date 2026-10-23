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
assert.equal(run('migrate({schemaVersion:1,appearance:{theme:"catppuccin-latte"}}).schemaVersion'),18);
assert.deepEqual(run('analyze({schemaVersion:4}).effective.bar.center'), ['workspaces']);
assert.equal(run('analyze({schemaVersion:4,appearance:{roundness:{master:-4}}}).effective.appearance.roundness.master'), 1);
assert.equal(run('analyze({schemaVersion:4,appearance:{theme:"unknown"}}).effective.appearance.theme'), 'unknown');
assert.equal(run('analyze({schemaVersion:19}).future'), true);
assert.deepEqual(run('analyze({schemaVersion:4,bar:{left:["wifi"],right:["wifi","bogus","volume"]}}).effective.bar.right'), ['volume']);
assert.throws(() => run('analyze(JSON.parse(\'{"schemaVersion":1,"__proto__":{}}\'))'));
assert.throws(() => run('migrate({palette:"catppuccin",appearance:{}})'));
assert.equal(run('analyze({schemaVersion:4,profile:{displayName:"Ada",subtitle:"Ready",avatar:null}}).effective.profile.displayName'), 'Ada');
assert.equal(run('analyze({schemaVersion:4,profile:{avatar:"/tmp/nope"}}).effective.profile.avatar'), null);
const migrated=run('migrate({schemaVersion:2,controlCentre:{columns:4,sections:{},controls:['
    + '{key:"sound",module:"volume",enabled:true,presentation:"tile"},'
    + '{key:"wireless",module:"bluetooth",enabled:true,presentation:"tile"},'
    + '{key:"network",module:"wifi",enabled:true,presentation:"tile"},'
    + '{key:"power",module:"battery",enabled:true,presentation:"tile"}]}})');
assert.deepEqual(migrated.controlCentre.controls.map(e=>e.module),['wifi','bluetooth','power-saver','airplane-mode']);
assert.deepEqual(migrated.controlCentre.actions.map(e=>e.module),['vpn','dnd','caffeine','lock','hibernate','shutdown']);
assert.equal(migrated.controlCentre.actionColumns,6);
const custom=run('migrate({schemaVersion:2,controlCentre:{sections:{},controls:[{key:"network",module:"wifi",enabled:false,presentation:"tile"}]}})');
assert.deepEqual(custom.controlCentre.controls.map(e=>e.module),['wifi']);
assert.deepEqual(run('analyze(migrate({schemaVersion:2})).effective.controlCentre.actions.map(e=>e.module)'),
    ['vpn','dnd','caffeine','lock','hibernate','shutdown']);
const v3=run('migrate({schemaVersion:3,controlCentre:{controls:['
    + '{key:"network",module:"wifi",enabled:true,presentation:"tile"},'
    + '{key:"wireless",module:"bluetooth",enabled:true,presentation:"tile"},'
    + '{key:"power-saver",module:"power-saver",enabled:true,presentation:"tile"},'
    + '{key:"airplane-mode",module:"airplane-mode",enabled:true,presentation:"tile"}]}})');
assert.equal(v3.schemaVersion,18);
assert.deepEqual(v3.controlCentre.controls.map(e=>e.accent),['teal','blue','green','lavender']);
const customAccent=run('migrate({schemaVersion:3,controlCentre:{controls:['
    + '{key:"network",module:"wifi",accent:"red",enabled:true,presentation:"tile"}]}})');
assert.equal(customAccent.controlCentre.controls[0].accent,'red');
const invalidAccent=run('analyze({schemaVersion:4,controlCentre:{controls:['
    + '{key:"network",module:"wifi",accent:"rosewater",enabled:true,presentation:"tile"}]}})');
assert.equal(invalidAccent.effective.controlCentre.controls[0].accent,'teal');
assert.ok(invalidAccent.errors.some(e=>e.includes('.accent')));
console.log('Schema: v0→v14, defaults, validation, CC action and semantic-accent migration PASS');

assert.equal(run('defaults().appearance.visual.statusIconSize'), 18);
assert.equal(run('analyze({schemaVersion:4,appearance:{visual:{statusIconSize:22}}}).effective.appearance.visual.statusIconSize'), 22);
for (const key of ['tileBackgroundShade','tileBorderShade']) {
    for (const value of [-1, 0, 1])
        assert.equal(run(`analyze({schemaVersion:4,appearance:{visual:{${key}:${value}}}}).effective.appearance.visual.${key}`), value);
    for (const value of ['2', '-2', '"dark"', 'null'])
        assert.equal(run(`analyze({schemaVersion:4,appearance:{visual:{${key}:${value}}}}).effective.appearance.visual.${key}`), run(`defaults().appearance.visual.${key}`));
}
console.log('Visual defaults, saved size preservation and signed shade validation PASS');

for (const id of ['notifications', 'clipboard']) {
    assert(!Object.values(run('defaults().bar')).flat().includes(id));
    assert.deepEqual(run(`analyze({schemaVersion:10,bar:{left:[],center:[],right:["${id}"]}}).effective.bar.right`), [id]);
}
console.log('Optional Notifications/Clipboard Bar placements accepted; absent from defaults PASS');

const geometry = {primaryIconSize:[16,32,48], primaryContainerSize:[60,68,96],
    secondaryIconSize:[16,32,36], avatarSize:[48,76,112], mediaArtworkSize:[48,80,112]};
for (const [key, values] of Object.entries(geometry)) {
    assert.equal(run(`defaults().appearance.visual.${key}`), values[1]);
    for (const value of values)
        assert.equal(run(`analyze({schemaVersion:11,appearance:{visual:{${key}:${value}}}}).effective.appearance.visual.${key}`), value);
    for (const value of [0, -1, values[2]+1, '"big"', 'null']) {
        const result=run(`analyze({schemaVersion:11,appearance:{visual:{${key}:${value}}}})`);
        assert.equal(result.effective.appearance.visual[key], values[1]);
        assert(result.errors.some(e=>e.includes(key)));
    }
}
const upgraded=run('analyze(migrate({schemaVersion:10,custom:42,appearance:{visual:{avatarSize:100,controlOn:"peach"},roundness:{roles:{action:1.5,avatar:.7}}}}))');
assert.equal(upgraded.effective.schemaVersion,18);
assert.equal(upgraded.effective.appearance.visual.avatarSize,100);
assert.equal(upgraded.effective.appearance.visual.controlOn,'peach');
assert.equal(upgraded.effective.appearance.roundness.roles.albumArt,1.5);
assert.equal(upgraded.effective.appearance.roundness.roles.avatar,.7);
assert.equal(upgraded.document.custom,42);
assert.equal(run('migrate({schemaVersion:10,appearance:{roundness:{roles:{action:1.5,albumArt:.2}}}}).appearance.roundness.roles.albumArt'),.2);
for (const role of ['avatar','albumArt']) {
    for (const value of [0,1,2,null]) assert.equal(run(`analyze({schemaVersion:11,appearance:{roundness:{roles:{${role}:${value}}}}}).effective.appearance.roundness.roles.${role}`),value);
    for (const value of [-1,3]) assert.equal(run(`analyze({schemaVersion:11,appearance:{roundness:{roles:{${role}:${value}}}}}).effective.appearance.roundness.roles.${role}`),null);
}
console.log('CC sizes, independent artwork roundness, v10 migration and preserved values PASS');

for (const [key,def,min,max] of [["profileGreetingSize",16,12,24],["profileWeatherSize",12,10,20],["profileThirdLineSize",11,10,20],
    ...["profileControlsGap","controlsSlidersGap","slidersActionsGap","actionsMediaGap"].map(k=>[k,20,0,48])]) {
    assert.equal(run(`analyze(migrate({schemaVersion:10})).effective.appearance.visual.${key}`),def);
    for (const value of [min,max,def]) {
        assert.equal(run(`analyze({schemaVersion:11,appearance:{visual:{${key}:${value}}}}).effective.appearance.visual.${key}`),value);
    }
    for (const value of [min-1,max+1,min+.5]) {
        assert(run(`analyze({schemaVersion:11,appearance:{visual:{${key}:${value}}}}).errors`).length);
        assert.equal(run(`analyze({schemaVersion:11,appearance:{visual:{${key}:${value}}}}).effective.appearance.visual.${key}`),def);
    }
}
console.log('Profile typography and section gaps: Schema 10→11 defaults, integer bounds PASS');

// Phase 2C: header-only artwork is additive; retired raw preferences are preserved.
for (const [key, def, good, bad] of [
    ['headerRadius',12,[0,24,75],[-1,76,1.5]],
    ['headerBorderWidth',1,[0,4,8],[-1,9,1.5]],
    ['headerFit','cover',['cover','contain'],['stretch',false]],
    ['headerBorderRole','border',['border','rim','accent','subtext'],['red','#fff',false]]
]) {
    assert.equal(run(`analyze({schemaVersion:11}).effective.launcher.${key}`),def);
    for (const value of good) assert.equal(run(`analyze({schemaVersion:11,launcher:{${key}:${JSON.stringify(value)}}}).effective.launcher.${key}`),value);
    for (const value of bad) assert(run(`analyze({schemaVersion:11,launcher:{${key}:${JSON.stringify(value)}}}).errors`).length);
}
const retired = run('analyze({schemaVersion:11,launcher:{backgroundEnabled:true,backgroundImage:"/tmp/old.png",headerPosition:"bottom"}})');
assert.equal(retired.document.launcher.backgroundImage,'/tmp/old.png');
assert.equal(retired.effective.launcher.headerPosition,'bottom');
assert(!Object.hasOwn(run('defaults().launcher'),'backgroundEnabled'));
assert(!Object.hasOwn(run('defaults().launcher'),'backgroundImage'));
console.log('Hub header fit/roundness/border validation and retired raw data preservation PASS');

// Phase 2E: migration preserves existing tuning and rejects invalid new input.
const v12 = run('analyze(migrate({schemaVersion:11,appearance:{visual:{primaryIconSize:27}},hub:{verticalPosition:.4}})).effective');
assert.equal(v12.schemaVersion,18);
assert.equal(v12.appearance.visual.primaryIconSize,27);
assert.equal(v12.hub.verticalPosition,.4);
assert.equal(v12.notifications.retentionHours,6);
for (const hours of [0,2,6,24]) assert.equal(run(`analyze({schemaVersion:12,notifications:{retentionHours:${hours}}}).effective.notifications.retentionHours`),hours);
for (const hours of [-1,3,48]) assert.equal(run(`analyze({schemaVersion:12,notifications:{retentionHours:${hours}}}).effective.notifications.retentionHours`),6);
for (const family of ['surfaceBorders','notificationBorders']) {
    for (const width of [0,1,5]) assert.equal(run(`analyze({schemaVersion:12,appearance:{${family}:{width:${width},role:"accent"}}}).effective.appearance.${family}.width`),width);
    for (const width of [-1,6]) assert.equal(run(`analyze({schemaVersion:12,appearance:{${family}:{width:${width}}}}).effective.appearance.${family}.width`),1);
    assert.equal(run(`analyze({schemaVersion:12,appearance:{${family}:{role:"bad"}}}).effective.appearance.${family}.role`),'border');
}
for (const value of ['always','active','hidden']) assert.equal(run(`analyze({schemaVersion:12,media:{controlsVisibility:"${value}"}}).effective.media.controlsVisibility`),value);
for (const position of ['above','below']) assert.equal(run(`analyze({schemaVersion:12,hub:{selectorPosition:"${position}"}}).effective.hub.selectorPosition`),position);
for (const fraction of [-1,2]) assert.equal(run(`analyze({schemaVersion:12,hub:{verticalPosition:${fraction}}}).effective.hub.verticalPosition`),2/3);
assert(!run('defaults().bar.right').includes('notifications'));
assert(!run('defaults().bar.right').includes('clipboard'));
console.log('Schema 12 borders, Hub, media, retention, migration and optional Bar defaults PASS');

assert.equal(run('defaults().appearance.notificationBorders.clipboard'),true);
assert.equal(run('analyze({schemaVersion:12,appearance:{notificationBorders:{clipboard:false}}}).effective.appearance.notificationBorders.clipboard'),false);
assert.equal(run('analyze({schemaVersion:12,appearance:{notificationBorders:{clipboard:7}}}).effective.appearance.notificationBorders.clipboard'),true);
console.log('Schema 12 Clipboard card border enable validation PASS');
// Phase 2E.2 stays inside the single 11→12 migration.
const final = run('analyze(migrate({schemaVersion:11,appearance:{visual:{avatarBorderWidth:3,profileGreetingSize:22}},profile:{displayName:"jkebwdn"}})).effective');
assert.equal(final.schemaVersion,18); assert.equal(final.appearance.visual.avatarBorderWidth,3);
assert.equal(final.profile.greetingStyle,'compact'); assert.equal(final.profile.displayName,'jkebwdn');
assert.deepEqual(JSON.parse(JSON.stringify(final.weather)),{enabled:false,location:'',units:'metric'});
for(const key of ['profileGreetingWeight','profileWeatherWeight','profileThirdLineWeight','mediaTitleWeight','mediaArtistWeight']) {
 for(const value of [400,700]) assert.equal(run(`analyze({schemaVersion:12,appearance:{visual:{${key}:${value}}}}).effective.appearance.visual.${key}`),value);
 for(const value of [0,500,900,'"bold"']) assert(run(`analyze({schemaVersion:12,appearance:{visual:{${key}:${value}}}}).errors.length`) > 0);
}
for(const [key,range] of [['mediaTitleSize',[10,24]],['mediaArtistSize',[10,20]],['mediaProgressBorderWidth',[0,5]]]) {
 for(const value of range) assert.equal(run(`analyze({schemaVersion:12,appearance:{visual:{${key}:${value}}}}).effective.appearance.visual.${key}`),value);
 for(const value of [range[0]-1,range[1]+1]) assert(run(`analyze({schemaVersion:12,appearance:{visual:{${key}:${value}}}}).errors.length`) > 0);
}
assert(run('analyze({schemaVersion:12,appearance:{visual:{mediaTitleSize:12.5}}}).errors.length')>0);
for(const toggleStyle of ['pill','filled','minimal']) assert.equal(run(`analyze({schemaVersion:12,appearance:{toggleStyle:"${toggleStyle}"}}).effective.appearance.toggleStyle`),toggleStyle);
assert.equal(run('analyze({schemaVersion:12,appearance:{navigationAccent:"red"}}).effective.appearance.navigationAccent'),'red');
assert.equal(run('analyze({schemaVersion:12,appearance:{navigationAccent:"#abcdef",toggleStyle:"bad"}}).effective.appearance.navigationAccent'),'accent');
for(const units of ['metric','imperial']) assert.equal(run(`analyze({schemaVersion:12,weather:{units:"${units}",location:"Newark-on-Trent"}}).effective.weather.units`),units);
assert(run('analyze({schemaVersion:12,weather:{enabled:1,location:123,units:"kelvin"},profile:{greetingStyle:"bad"}}).errors.length')===4);
console.log('Schema 12 final navigation/toggles/profile/weather/media validation and old tuning preservation PASS');

const oldIcons = {schemaVersion:12, custom:{untouched:42}, icons:{pack:'alternate',overrides:{global:{wifi:{broken:true}}},modulePacks:{wifi:'other'},extra:7},appearance:{theme:'everforest-dark-hard',visual:{statusIconSize:23}},emoji:{recents:['1F525']}};
const before=JSON.stringify(oldIcons);
context.oldIcons=oldIcons;
const result=run('analyze(migrate(oldIcons))');
assert.equal(JSON.stringify(oldIcons),before);
assert.equal(result.effective.schemaVersion,18);
assert.equal(result.errors.length,0);
assert.deepEqual(result.document.icons,{pack:'alternate',extra:7});
assert.equal(result.document.custom.untouched,42);
assert.equal(result.effective.appearance.theme,'everforest-dark-hard');
assert.equal(result.effective.appearance.visual.statusIconSize,23);
assert.deepEqual(result.effective.emoji.recents,['1F525']);
for (const key of ['mediaProgressRole','hubToggleRole']) {
 assert.equal(result.effective.appearance[key],'accent');
 assert.equal(run(`analyze({schemaVersion:13,appearance:{${key}:'nonsense'}}).effective.appearance.${key}`),'accent');
 assert.equal(run(`analyze({schemaVersion:13,appearance:{${key}:'teal'}}).effective.appearance.${key}`),'teal');
}
assert.equal(run('defaults().icons.pack'),'magi-default');
assert.equal(run('analyze({schemaVersion:12,icons:{overrides:17,modulePacks:false}}).errors.length'),0);
console.log('Phase 10A migration retires overrides, preserves preferences/history and defaults semantic roles PASS');
