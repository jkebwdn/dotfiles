// Independent expected migration shape; only the current version comes from defaults.
module.exports = function expectedCurrent(input) {
 const fs=require('fs'),vm=require('vm'),path=require('path');
 const schema=vm.createContext({});
 vm.runInContext(fs.readFileSync(path.resolve(__dirname,'../../.config/quickshell/magi/settings/SettingsSchema.js'),'utf8'),schema);
 const doc=structuredClone(input);doc.schemaVersion=schema.defaults().schemaVersion;
 doc.lockScreen ??= {layoutVersion:1,preset:"centered",elements:{}};
 doc.lockScreen.effects ??= {credential:"dots",avatar:"plain",weather:"standard",media:"compact",location:false,artwork:true,depth:false,blur:true};
 if(doc.bar)delete doc.bar.trayVisibility;
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
