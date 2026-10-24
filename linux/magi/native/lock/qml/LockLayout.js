// Pure presentation geometry. No input, IPC, file access or authentication authority.
function ids() { return ["time", "identity", "authentication"] }
function anchors() { return ["top-left","top-center","top-right","center-left","center","center-right","bottom-left","bottom-center","bottom-right"] }
function copy(v) { return JSON.parse(JSON.stringify(v)) }
function element(anchor, x, y, size, visible, z) {
    return {anchor:anchor, offsetX:x, offsetY:y, size:size, visible:visible, alignment:"center", z:z}
}
function preset(name) {
    const e = {
        time: element("top-center",0,.06,1,true,0),
        identity: element("center",0,0,1,true,1),
        authentication: element("bottom-center",0,-.12,1,true,2)
    }
    // Content flow is an explicit coordinate space, not a separate renderer.
    let space = "screen"
    if (name === "centered") space = "composition"
    else if (name === "editorial") {
        e.time = element("top-left",.06,.08,1.15,true,0)
        e.time.alignment = "left"
        e.identity = element("center-right",-.06,0,1,true,1)
        e.authentication = element("bottom-right",-.06,-.08,1,true,2)
    } else if (name === "corner") {
        e.time = element("top-left",.05,.05,.85,true,0)
        e.time.alignment = "left"
        e.identity = element("bottom-right",-.05,-.3,.85,true,1)
        e.authentication = element("bottom-right",-.05,-.06,1,true,2)
    } else if (name === "split") {
        e.time = element("center-right",-.06,-.12,1,true,0)
        e.identity = element("center-left",.06,0,1,true,1)
        e.authentication = element("bottom-right",-.06,-.15,1,true,2)
    } else if (name === "minimal") {
        e.time = element("top-center",0,.16,.85,true,0)
        e.identity.visible = false
    } else return preset("centered")
    return {layoutVersion:1, preset:name, space:space, elements:e}
}
function normalize(input) {
    const fallback = preset("centered")
    if (!input || input.layoutVersion !== 1) return fallback
    // The compact migration value denotes the unchanged original composition.
    if (input.preset === "centered" && input.elements && Object.keys(input.elements).length === 0) return fallback
    if (!["screen","composition"].includes(input.space) || !input.elements) return fallback
    if (Object.keys(input.elements).sort().join() !== ids().sort().join()) return fallback
    const out = copy(fallback), used = []
    out.space = input.space
    out.preset = ["centered","editorial","corner","split","minimal","custom"].includes(input.preset) ? input.preset : "custom"
    for (const id of ids()) {
        const e = input.elements[id]
        if (!e || !anchors().includes(e.anchor) || !["left","center","right"].includes(e.alignment)
            || typeof e.visible !== "boolean" || !Number.isInteger(e.z) || e.z < 0 || e.z > 2 || used.includes(e.z)) return fallback
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
