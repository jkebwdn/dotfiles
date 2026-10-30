// Pure presentation geometry. No input, IPC, file access or authentication authority.
function ids() { return ["time", "identity", "authentication", "weather", "media"] }
function anchors() { return ["top-left","top-center","top-right","center-left","center","center-right","bottom-left","bottom-center","bottom-right"] }
function copy(v) { return JSON.parse(JSON.stringify(v)) }
function element(anchor, x, y, size, visible, z) {
    return {anchor:anchor, offsetX:x, offsetY:y, size:size, visible:visible, alignment:"center", z:z}
}
function preset(name) {
    const e = {
        time: element("top-center",0,.06,1,true,0),
        identity: element("center",0,0,1,true,1),
        authentication: element("bottom-center",0,-.12,1,true,2),
        weather: element("top-right",-.05,.05,1,false,-2),
        media: element("bottom-left",.05,-.08,1,false,-1)
    }
    // Content flow is an explicit coordinate space, not a separate renderer.
    let space = "screen"
    if (name === "centered") space = "composition"
    else if (name === "editorial") {
        e.time = element("top-left",.06,.08,1.15,true,0)
        e.time.alignment = "left"
        e.identity = element("center-right",-.06,0,1,true,1)
        e.authentication = element("bottom-right",-.06,-.08,1,true,2)
    } else if (name === "split-corners") {
        e.identity = element("top-left",.03,.04,.75,true,1)
        e.identity.alignment = "left"
        e.time = element("top-left",.12,.04,1,true,0)
        e.time.alignment = "left"
        e.authentication = element("bottom-right",-.03,-.05,1,true,2)
        e.authentication.alignment = "right"
        e.media.visible = true
    } else if (name === "corner") {
        e.time = element("top-left",.05,.05,.85,true,0)
        e.time.alignment = "left"
        e.identity = element("bottom-right",-.05,-.3,.85,true,1)
        e.authentication = element("bottom-right",-.05,-.06,1,true,2)
    } else if (name === "split") {
        e.time = element("center-right",-.06,-.12,1,true,0)
        e.identity = element("center-left",.06,0,1,true,1)
        e.authentication = element("bottom-right",-.06,-.15,1,true,2)
    } else if (name === "media" || name === "compact") {
        e.identity.visible = name === "compact"
        e.media.visible = name === "media"
        e.authentication.alignment = "center"
    } else if (name === "minimal") {
        e.time = element("top-center",0,.16,.85,true,0)
        e.identity.visible = false
    } else return preset("centered")
    return {layoutVersion:1, preset:name, space:space, elements:e, effects:effects(name === "split-corners" ? {media:"title",artwork:false} : null)}
}
function normalize(input) {
    const fallback = preset("centered")
    if (!input || input.layoutVersion !== 1) return fallback
    if (!["centered","editorial","corner","split","minimal","split-corners","media","compact","custom"].includes(input.preset)) return fallback
    // The compact migration value denotes the unchanged original composition.
    if (input.preset === "centered" && input.elements && Object.keys(input.elements).length === 0) {fallback.effects=effects(input.effects);return fallback}
    if (!["screen","composition"].includes(input.space) || !input.elements) return fallback
    if (Object.keys(input.elements).some(id => !ids().includes(id))) return fallback
    input = copy(input)
    for (const id of ["weather","media"]) if (!input.elements[id]) input.elements[id] = copy(fallback.elements[id])
    const out = copy(fallback), used = []
    out.effects = effects(input.effects)
    out.space = input.space
    out.preset = ["centered","editorial","corner","split","minimal","split-corners","media","compact","custom"].includes(input.preset) ? input.preset : "custom"
    for (const id of ids()) {
        const e = input.elements[id]
        if (!e || !anchors().includes(e.anchor) || !["left","center","right"].includes(e.alignment)
            || typeof e.visible !== "boolean" || !Number.isInteger(e.z) || e.z < -2 || e.z > 2 || used.includes(e.z)) return fallback
        for (const k of ["offsetX","offsetY","size"]) if (typeof e[k] !== "number" || !isFinite(e[k])) return fallback
        if (Math.abs(e.offsetX) > 1 || Math.abs(e.offsetY) > 1 || e.size < .75 || e.size > 1.25) return fallback
        if (id === "authentication" && (!e.visible || e.z !== 2 || e.size < 1)) return fallback
        out.elements[id] = {anchor:e.anchor, offsetX:e.offsetX, offsetY:e.offsetY, size:e.size, visible:e.visible, alignment:e.alignment, z:e.z}
        used.push(e.z)
    }
    return out
}
function axis(anchor) {
    return [anchor.includes("left") ? 0 : anchor.includes("right") ? 1 : .5,
            anchor.includes("top") ? 0 : anchor.includes("bottom") ? 1 : .5]
}
function position(e,w,h,ew,eh) {
    const a=axis(e.anchor), margin=16
    return {x:Math.max(margin,Math.min(Math.max(margin,w-ew-margin),a[0]*(w-ew)+e.offsetX*w)),
            y:Math.max(margin,Math.min(Math.max(margin,h-eh-48),a[1]*(h-eh)+e.offsetY*h))}
}
function place(e,x,y,w,h,ew,eh) {
    const out=copy(e), a=axis(e.anchor)
    out.offsetX=Math.round((x-a[0]*(w-ew))/w*10000)/10000
    out.offsetY=Math.round((y-a[1]*(h-eh))/h*10000)/10000
    return out
}
function snap(value,extent,limit,others,bypass) {
    if (bypass) return {value:value,guide:-1}
    let best=8, result={value:value,guide:-1}
    const guides=[16,limit/3,limit/2,limit*2/3,limit-16].concat(others || [])
    for (const guide of guides) for (const edge of [0,extent/2,extent]) {
        const distance=Math.abs(value+edge-guide)
        if (distance<best) {best=distance;result={value:guide-edge,guide:guide}}
    }
    return result
}

// Optional appearance data only; unknown values never reach presentation.
function effects(value) {
    const v=value && typeof value === "object" ? value : {}
    function choice(key,allowed,fallback) { return allowed.includes(v[key]) ? v[key] : fallback }
    return {credential:choice("credential",["dots","line","segments","ring","minimal"],"dots"),
        avatar:choice("avatar",["plain","ring","glow","frame"],"plain"),
        weather:choice("weather",["compact","standard","minimal"],"standard"),
        media:choice("media",["compact","artwork","minimal","title"],"compact"),
        date:v.date !== false, curated:v.curated === true, blur:v.blur !== false, location:v.location === true, artwork:v.artwork !== false, depth:v.depth === true}
}

// Hosts share the presentation plane and use a top-left scale origin.
// Padding is expressed in that plane, including the authentication backdrop.
function overlaps(a, b, padding) {
    return a.width > 0 && a.height > 0 && b.width > 0 && b.height > 0
        && a.x < b.x + b.width * b.scale + padding
        && a.x + a.width * a.scale > b.x - padding
        && a.y < b.y + b.height * b.scale + padding
        && a.y + a.height * a.scale > b.y - padding
}

// Curated flows use the existing bounded hosts, measured content and logical units.
// Raw/legacy layouts keep their anchor engine, snapping and designer coordinates.
function curatedPositions(layout,w,h,boxes) {
    if(!layout.effects.curated || !["centered","minimal","editorial","media","compact"].includes(layout.preset)) return null
    const gap=24,margin=24,bottom=h-64, result={}
    function bw(id){return boxes[id].width*boxes[id].scale}
    function bh(id){return layout.elements[id].visible ? boxes[id].height*boxes[id].scale : 0}
    function put(id,x,y){result[id]={x:Math.max(16,Math.min(w-bw(id)-16,x)),y:Math.max(16,Math.min(h-bh(id)-48,y))}}
    function center(id,y){put(id,(w-bw(id))/2,y)}
    const time=bh("time"),identity=bh("identity"),media=bh("media"),weather=bh("weather"),auth=bh("authentication")
    if(layout.preset==="centered") {
        const active=["time","identity","media","authentication"].filter(id=>bh(id)>0)
        const total=active.reduce((n,id)=>n+bh(id),0)+gap*(active.length-1)
        let y=Math.max(margin,(h-48-total)/2)
        for(const id of active){center(id,y);y+=bh(id)+gap}
    } else if(layout.preset==="minimal") {
        center("time",Math.max(margin,h*.22));center("authentication",bottom-auth)
    } else if(layout.preset==="compact") {
        const row=Math.max(time,identity),total=row+auth+(media ? media+16 : 0)+24
        const y=Math.max(margin,bottom-total)
        const rowWidth=bw("time")+(identity ? bw("identity")+16 : 0)
        put("identity",(w-rowWidth)/2,y);put("time",(w-rowWidth)/2+(identity ? bw("identity")+16 : 0),y+(row-time)/2)
        if(media)center("media",y+row+12)
        center("authentication",bottom-auth)
    } else if(layout.preset==="media") {
        center("time",Math.max(margin,h*.07))
        center("media",Math.max(result.time.y+time+gap,(h-media)/2-24))
        center("authentication",Math.max(result.media.y+media+gap,bottom-auth))
    } else {
        put("time",w*.06,Math.max(margin,h*.08))
        put("weather",w*.06,result.time.y+time+gap)
        put("identity",w-bw("identity")-w*.06,w<900 ? result.time.y+time+(weather ? weather+gap : 0)+gap : h*.38)
        put("authentication",w-bw("authentication")-w*.06,bottom-auth)
    }
    for(const id of ids())if(!result[id])put(id,margin,margin)
    return result
}
