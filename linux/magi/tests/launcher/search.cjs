const fs = require('fs'), vm = require('vm'), assert = require('assert');
const c = vm.createContext({});
vm.runInContext(fs.readFileSync('.config/quickshell/magi/services/LauncherSearch.js','utf8'),c);
const apps = [
 {id:'web',name:'Zen Browser',genericName:'Web Browser',keywords:['internet']},
 {id:'editor',name:'Zén',genericName:'Editor',keywords:['text']},
 {id:'files',name:'Files',genericName:'File Manager',keywords:['folders']}
];
const rank=(q,h={})=>Array.from(c.rank(apps,q,h),a=>a.id);
assert.deepEqual(rank('zen'),['editor','web']);
assert.deepEqual(rank('web internet'),['web']);
assert.deepEqual(rank('folders'),['files']);
assert.deepEqual(rank('file manager'),['files']);
assert.deepEqual(rank('not an app'),[]);
assert.deepEqual(rank('   '),rank(''));
assert.equal(rank('',{web:20})[0],'web');
assert.equal(rank('zen',{web:20})[0],'editor');
assert.equal(c.rank([...apps,apps[0]],'',{}).length,3);
console.log('Launcher search accents, token matching, ranking, deduplication PASS');
for (const query of ['', 'zen', 'web internet', 'internet']) {
 assert.ok(!Array.from(c.rank(apps,query,{web:999},['web']),a=>a.id).includes('web'));
}
assert.equal(c.rank(apps,'internet',{},[])[0].id,'web');
assert.equal(c.rank(apps,'',{},['removed.desktop']).length,3);
console.log('Hidden IDs excluded before ranking, keywords and frequency; restore PASS');
