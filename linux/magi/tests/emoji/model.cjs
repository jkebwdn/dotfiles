const fs=require('fs'),vm=require('vm'),assert=require('assert');
const base='.config/quickshell/magi/';
const c=vm.createContext({}); vm.runInContext(fs.readFileSync(base+'services/EmojiSearch.js','utf8'),c);
const data=JSON.parse(fs.readFileSync(base+'data/emoji/emoji.json','utf8'));
const entries=c.prepare(data);
assert.equal(data.unicodeVersion,'17.0'); assert.equal(entries.length,3944);
assert.equal(new Set(entries.map(e=>e.emoji)).size,entries.length);
assert.equal(c.categories(entries).length,9);
assert.throws(()=>c.prepare({...data,entries:[data.entries[0],data.entries[0]]}));
assert.throws(()=>c.prepare({...data,entries:[{...data.entries[0],emoji:'broken'}]}));
assert.throws(()=>c.prepare({}));
assert.equal(c.normalize('  CAFÉ__Heart-EYES  '),'cafe heart eyes');
for (const emoji of ['🔥','❤️','👍🏽','👩🏽‍💻','👨‍👩‍👧‍👦','🇬🇧','🏴󠁧󠁢󠁥󠁮󠁧󠁿']) {
 const index=entries.findIndex(e=>e.emoji===emoji);
 assert.ok(index>=0,emoji); assert.equal(c.sequenceAt(entries,index),emoji);
 assert.equal(c.rank(entries,emoji,'Flags',[])[0].emoji,emoji);
}
assert.equal(c.sequenceAt(entries,-1),''); assert.equal(c.sequenceAt(entries,1.2),'');
assert.equal(c.rank(entries,'fire','Flags',[])[0].emoji,'🔥');
assert.ok(c.rank(entries,'laugh','All',[]).some(e=>e.emoji==='🤣'));
assert.ok(c.rank(entries,'heart','All',[]).some(e=>e.emoji==='❤️'));
assert.ok(c.rank(entries,'thumb','All',[]).some(e=>e.emoji==='👍🏽'));
assert.equal(c.rank(entries,'cat','All',[])[0].emoji,'🐈');
assert.equal(c.rank(entries,'CAT','All',[])[0].emoji,'🐈');
assert.ok(c.rank(entries,'face smiling','All',[]).length);
assert.ok(c.rank(entries,'','Flags',[]).every(e=>e.group==='Flags'));
assert.equal(c.rank(entries,'missing nonsense','All',[]).length,0);
assert.equal(c.rank(entries,'','Recently Used',['missing','1F525'])[0].emoji,'🔥');
assert.deepEqual(Array.from(c.promote(['1F525','1F600'],'1F600',2)),['1F600','1F525']);
assert.equal(c.promote(['1F525'],'1F600',0).length,0);
assert.deepEqual(Array.from(c.promote(['1F525','1F600'],'1F601',2)),['1F601','1F525']);
// Warm per-keystroke ranking is measured, not a timing-sensitive test gate.
const start=performance.now(); for(let i=0;i<100;i++) c.rank(entries,'thumb','All',[]);
console.log('Emoji dataset, exact sequences, normalization, ranking, categories, Recents PASS; average search ms:',((performance.now()-start)/100).toFixed(2));
