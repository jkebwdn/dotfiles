module.exports = function expected18(input) {
 const doc=structuredClone(input);doc.schemaVersion=22;doc.lockScreen={layoutVersion:1,preset:"centered",elements:{},effects:{credential:"dots",avatar:"plain",weather:"standard",media:"compact",location:false,artwork:true,depth:false}};
 doc.controlCentre ??= {}; const cc=doc.controlCentre, flags=cc.sections || {};
 const ids=["profile","controls","sliders","actions","media"], map={controls:"quickControls"};
 cc.layout ??= ids.filter(id=>flags[map[id]||id]!==false && !(id==="media" && doc.media?.enabled===false));
 delete cc.sections;if(doc.media)delete doc.media.enabled;
 doc.appearance ??= {};doc.appearance.globalBlur ??= {managed:false,size:8};
 if(doc.appearance.roundness?.roles && doc.appearance.roundness.roles.secondaryControl===undefined)
  doc.appearance.roundness.roles.secondaryControl=doc.appearance.roundness.roles.action ?? null;
 doc.applicationAppearance ??= {managed:false,backgroundOpacity:1,blurEnabled:true};
 return doc;
};
