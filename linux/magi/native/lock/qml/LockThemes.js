.import "LockLayout.js" as Layout
// Curated appearance definitions. No service, authentication or credential access.
function catalogue() {
    return [
        {id:"split-corners",name:"Split Corners",description:"Identity and time above, authentication opposite.",controls:["avatar","avatarStyle","clockSize","media","weather","edgeInset"],modules:{identity:"optional",media:"optional",weather:"optional"},composition:"corners"},
        {id:"centered",name:"Centered",description:"A balanced column with a quiet sense of focus.",controls:["avatar","avatarStyle","clockSize","media"],modules:{identity:"optional",media:"optional",weather:"unsupported"},composition:"column"},
        {id:"minimal",name:"Minimal",description:"Time and authentication, with almost no visual chrome.",controls:["clockSize","date"],modules:{identity:"unsupported",media:"unsupported",weather:"unsupported"},composition:"minimal"},
        {id:"editorial",name:"Editorial",description:"Bold time, a small identity and generous open space.",controls:["avatar","avatarStyle","clockSize","date","weather"],modules:{identity:"optional",media:"unsupported",weather:"optional"},composition:"editorial"},
        {id:"media",name:"Media",description:"The current song takes centre stage.",controls:["artwork","clockSize","date"],modules:{identity:"unsupported",media:"required",weather:"unsupported"},composition:"media"},
        {id:"compact",name:"Compact",description:"A small, orderly composition for tighter spaces.",controls:["avatar","clockSize","date","media"],modules:{identity:"optional",media:"optional",weather:"unsupported"},composition:"compact"}
    ]
}
function defaultId() { return "centered" }
function definition(id) { return catalogue().find(t=>t.id===id) || catalogue().find(t=>t.id===defaultId()) }
function known(id) { return catalogue().some(t=>t.id===id) }
function matchesCorners(raw) {
    if (!raw || raw.preset!=="custom" || raw.space!=="screen" || !raw.elements) return false
    const l=Layout.normalize(raw),e=l.elements
    return l.preset==="custom" && e.time.visible && e.identity.visible && !e.weather.visible
        && e.time.anchor==="top-left" && e.identity.anchor==="top-left" && e.authentication.anchor==="bottom-right"
        && e.time.alignment==="left" && e.identity.alignment==="left" && e.authentication.alignment==="right"
        && Math.abs(e.time.offsetY-e.identity.offsetY)<.02 && e.identity.offsetX>=0 && e.identity.offsetX<=.15
        && e.time.offsetX>=e.identity.offsetX && e.time.offsetX<=.3
        && e.identity.offsetY>=0 && e.identity.offsetY<=.15
        && e.authentication.offsetX<=0 && e.authentication.offsetX>=-.15
        && e.authentication.offsetY<=0 && e.authentication.offsetY>=-.2
        && l.effects.media==="title"
}
function selection(raw) {
    if (matchesCorners(raw)) return {id:"split-corners",legacy:false,unavailable:false}
    if (raw && known(raw.preset)) return {id:raw.preset,legacy:false,unavailable:false}
    if (raw && ["custom","corner","split"].includes(raw.preset)) return {id:"legacy",legacy:true,unavailable:false}
    return {id:defaultId(),legacy:false,unavailable:!!raw}
}
// Metadata-only recognition: preserve every coordinate, style and unrecognized field.
function migrate(raw) {
    const next=Layout.copy(raw)
    if (matchesCorners(next)) next.preset="split-corners"
    return next
}
function create(id, previous) {
    const theme=definition(id),next=Layout.preset(theme.id)
    next.preset=theme.id
    next.effects.curated=theme.id!=="split-corners"
    next.effects.date=true
    next.effects.depth=false
    next.elements.time.size=theme.id==="split-corners" ? .75 : ["compact","media"].includes(theme.id) ? .75 : 1
    if(theme.id==="compact") {next.elements.identity.size=.75;next.elements.identity.alignment="left";next.elements.time.alignment="left"}
    next.elements.authentication.alignment=theme.id==="editorial" ? "right" : theme.id==="split-corners" ? "right" : "center"
    for(const module of ["identity","media","weather"]) next.elements[module].visible=theme.modules[module]==="required" || (module==="identity" && theme.modules[module]==="optional")
    if(theme.id==="split-corners") next.elements.media.visible=true
    next.effects.media=theme.id==="media" ? "artwork" : "title"
    next.effects.artwork=theme.id==="media"
    next.effects.weather="compact"
    // Shared user choices survive theme switching. Per-theme options take defaults.
    if(previous && previous.effects) {
        next.effects.blur=previous.effects.blur!==false
        next.effects.credential=Layout.effects(previous.effects).credential
    }
    return next
}
function supports(id,control) { return definition(id).controls.includes(control) }
function customize(raw,key,value) {
    const selectionState=selection(raw)
    if(selectionState.legacy || selectionState.unavailable) return Layout.copy(raw)
    const next=Layout.normalize(migrate(raw)),theme=definition(selectionState.id)
    next.effects=Object.assign({},Layout.effects(next.effects))
    if(key==="blur") next.effects.blur=value===true
    else if(key==="credential" && ["dots","line","segments","ring","minimal"].includes(value)) next.effects.credential=value
    else if(!supports(theme.id,key)) return next
    else if(key==="avatar") next.elements.identity.visible=value===true
    else if(key==="avatarStyle" && ["plain","ring","glow","frame"].includes(value)) next.effects.avatar=value
    else if(key==="clockSize" && [.75,1,1.15].includes(value)) {next.elements.time.size=value;if(["split-corners","compact"].includes(theme.id))next.elements.identity.size=value}
    else if(key==="date") next.effects.date=value===true
    else if(key==="media" || key==="weather") next.elements[key].visible=value===true
    else if(key==="artwork") {next.effects.artwork=value===true;next.effects.media=value ? "artwork" : "minimal"}
    else if(key==="edgeInset" && [.03,.05,.08].includes(value)) {
        next.elements.identity.offsetX=value;next.elements.identity.offsetY=value+.01
        next.elements.time.offsetY=value+.01
        next.elements.authentication.offsetX=-value;next.elements.authentication.offsetY=-value-.02
    }
    return next
}
