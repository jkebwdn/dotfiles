module.exports = function expected18(input) {
 const doc=structuredClone(input);doc.schemaVersion=18;
 doc.controlCentre ??= {}; const cc=doc.controlCentre, flags=cc.sections || {};
 const ids=["profile","controls","sliders","actions","media"], map={controls:"quickControls"};
 cc.layout ??= ids.filter(id=>flags[map[id]||id]!==false && !(id==="media" && doc.media?.enabled===false));
 delete cc.sections;if(doc.media)delete doc.media.enabled;
 doc.appearance ??= {};
 if(doc.appearance.roundness?.roles && doc.appearance.roundness.roles.secondaryControl===undefined)
  doc.appearance.roundness.roles.secondaryControl=doc.appearance.roundness.roles.action ?? null;
 return doc;
};
