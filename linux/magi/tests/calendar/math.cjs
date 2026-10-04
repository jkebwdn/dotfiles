const fs=require('fs'),vm=require('vm'),assert=require('assert');
const c=vm.createContext({});
vm.runInContext(fs.readFileSync('.config/quickshell/magi/services/CalendarMath.js','utf8'),c);
const d=(y,m,day)=>c.civil(y,m,day), fields=x=>[x.getFullYear(),x.getMonth(),x.getDate()];
for(const [y,m,n] of [[2023,1,28],[2024,1,29],[1900,1,28],[2000,1,29],[2026,3,30],[2026,0,31]]) {
 assert.equal(c.monthDays(y,m),n);
 for(const first of [0,1]) {
  const cells=c.grid(y,m,first,true,d(y,m,12),d(y,m,13));
  assert.equal(cells.length,42); assert.equal(cells[0].date.getDay(),first);
  assert.equal(cells.filter(x=>x.inMonth).length,n);
  assert.equal(cells.findIndex(x=>x.inMonth),(d(y,m,1).getDay()-first+7)%7);
  assert.equal(cells.filter(x=>x.today).length,1); assert.equal(cells.filter(x=>x.selected).length,1);
  assert.equal(c.grid(y,m,first,false,d(y,m,1),d(y,m,1)).filter(x=>x.shown).length,n);
 }
}
assert.deepEqual(fields(c.addMonths(d(2026,11,31),1)),[2027,0,31]);
assert.deepEqual(fields(c.addMonths(d(2026,0,31),-1)),[2025,11,31]);
assert.deepEqual(fields(c.addMonths(d(2024,0,31),1)),[2024,1,29]);
assert.deepEqual(fields(c.addMonths(d(2023,0,31),1)),[2023,1,28]);
assert.deepEqual(fields(c.addDays(d(2024,1,28),1)),[2024,1,29]);
assert.deepEqual(fields(c.addDays(d(2026,2,28),2)),[2026,2,30]); // DST weekend
assert.deepEqual(fields(c.addDays(d(2026,9,24),2)),[2026,9,26]);
for(const [y,m,day,wy,week] of [[2021,0,1,2020,53],[2021,0,4,2021,1],[2024,11,30,2025,1],[2026,11,31,2026,53]]) {
 const w=c.isoWeek(d(y,m,day)); assert.equal(w.year,wy);assert.equal(w.week,week);
}
for(const first of [0,1]) {
 const weeks=c.weeks(c.grid(2021,0,first,true,d(2021,0,1),d(2021,0,1)));
 assert.equal(weeks[0].week,53);assert.equal(weeks[1].week,1);
}
assert.equal(d(99,0,1).getFullYear(),99);
console.log('Calendar month lengths, offsets, leap/century years, boundaries, DST civil navigation, adjacency and ISO weeks PASS');
