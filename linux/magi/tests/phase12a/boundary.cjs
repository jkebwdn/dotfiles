const fs=require('fs'),path=require('path'),assert=require('assert');
const root=path.resolve(__dirname,'../../.config/quickshell/magi');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const preview=['ControlCentrePreview.qml','CCControlPreview.qml','CCSectionPreview.qml'].map(n=>read('components/settings/'+n)).join('\n');
// Presenters may read Settings; backend dispatch belongs exclusively to production CC.
assert.deepEqual([...new Set([...preview.matchAll(/Services\.(\w+)/g)].map(m=>m[1]))],['Settings']);
for(const token of ['ControlCatalog','Quickshell.Io','Process {','onPrimaryTriggered','onSecondaryTriggered','onValueMoved','onTriggered:'])assert(!preview.includes(token),token);
for(const presenter of ['CC.ProfileHeader','CC.ControlTile','Controls.IconSlider','CC.ActionButton','CC.MediaSection'])assert(preview.includes(presenter),presenter);
assert(preview.includes('SectionLayout.compose('));
const grid=read('components/settings/PreviewControlGrid.qml');
assert(!grid.includes('Services.') && !grid.includes('Process'));
assert(/enabled:\s*false/.test(grid));
const media=read('plugins/bar/controlcentre/MediaSection.qml');
assert.equal((media.match(/if \(root.interactive\)/g)||[]).length,3);
const hub=read('components/hub/HubContent.qml');assert(hub.includes('hubSelectionColor'));assert(!hub.includes('hubToggleColor'));
const toggle=read('components/settings/SettingsToggle.qml');assert(toggle.includes('hubToggleColor'));assert(!toggle.includes('hubSelectionColor'));
const nav=read('components/settings/SettingsNavigationItem.qml');assert(nav.includes('Theme.Theme.navigationAccent'));assert(!nav.includes('hubSelectionColor')&&!nav.includes('hubToggleColor'));
console.log('Phase12A presenter reuse, action boundary and colour consumers PASS');
