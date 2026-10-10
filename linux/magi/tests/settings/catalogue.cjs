const fs = require('fs'), vm = require('vm'), assert = require('assert');
const base = '.config/quickshell/magi';
const ctx = vm.createContext({});
for (const name of ['settings/SettingsSchema.js', 'settings/SettingsMigrations.js', 'icons/IconResolver.js'])
    vm.runInContext(fs.readFileSync(`${base}/${name}`, 'utf8'), ctx);
const plain = value => JSON.parse(JSON.stringify(value));
const definitions = plain(ctx.controlDefinitions());
assert.equal(new Set(definitions.map(d => d.id)).size, definitions.length);
assert.deepEqual(definitions.map(d => d.id), ['wifi','bluetooth','power-saver','airplane-mode','battery','settings','volume','brightness','vpn','dnd','caffeine','lock','hibernate','shutdown','reboot','apps','notifications','emoji','clipboard']);
for (const mode of ['apps','notifications','emoji','clipboard']) {
    const d = definitions.find(d => d.id === mode);
    assert.equal(d.route, 'hub'); assert.equal(d.mode, mode);
    assert.deepEqual(d.presentations, ['action']);
}
const original = plain(ctx.defaults());
assert.deepEqual(original.controlCentre.actions.map(d => d.module), ['vpn','dnd','caffeine','lock','hibernate','shutdown']);
const custom = plain(original);
custom.controlCentre.columns = 7; custom.controlCentre.actionColumns = 2;
custom.controlCentre.controls.reverse(); custom.controlCentre.sliders.reverse();
custom.controlCentre.actions.reverse(); custom.controlCentre.actions[0].enabled = false;
assert.deepEqual(plain(ctx.analyze(ctx.migrate(custom)).effective.controlCentre), custom.controlCentre);
for (const d of definitions) for (const presentation of d.presentations.filter(p => p !== 'detail')) {
    const doc = plain(custom), group = {tile:'controls',slider:'sliders',action:'actions'}[presentation];
    doc.controlCentre[group] = [{key:d.id,module:d.id,enabled:true,presentation,accent:d.accent}];
    const result = ctx.analyze(doc);
    assert.equal(result.errors.length, 0, d.id);
    assert.equal(result.effective.controlCentre[group][0].module, d.id);
}
const duplicate = plain(custom);
duplicate.controlCentre.actions.push(duplicate.controlCentre.actions[0]);
assert(ctx.analyze(duplicate).errors.length);
const registry = JSON.parse(fs.readFileSync(`${base}/icons/packs/registry.json`));
for (const pack of ['magi-legacy','magi-default']) for (const d of definitions) {
    const resolved = ctx.resolve(registry, {pack}, d.icon, d.id);
    assert(!resolved.diagnostic, d.id);
    assert.notEqual(resolved.icon.text, '?', d.id);
    if (resolved.icon.kind === 'svg') assert(fs.existsSync(`${base}/icons/packs/${resolved.icon.path}`));
}
assert.deepEqual(plain(ctx.defaults()), original, 'validation never mutates reset defaults');
console.log('Catalogue IDs, eligibility, preservation, defaults, duplicate rejection and icons PASS');
