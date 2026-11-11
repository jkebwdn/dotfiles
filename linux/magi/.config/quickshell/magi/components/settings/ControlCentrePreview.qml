pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../services" as Services
import "../../theme" as Theme
import "../../settings/SettingsSchema.js" as Schema
import "../controls" as Controls
import "../bar" as BarUI
import "../../plugins/bar/controlcentre/SectionLayout.js" as SectionLayout

Item {
    id: root
    readonly property color color: Theme.Theme.roles[Services.Settings.data.appearance.controlCentreBackgroundRole]
    property bool editing: false
    property bool playing: true
    property string selectedKey: ""
    property alias moduleBoard: moduleBoard
    property alias structureBoard: structureBoard
    property alias viewport: view
    property Flickable editorViewport: null
    property Item availableCard: null
    readonly property var palette: availableCard || fallbackPalette
    readonly property var availableSections: structureBoard.order("availableStructure")
    signal selected(string key)
    readonly property var layout: Services.Settings.data.controlCentre
    readonly property var ids: ["profile", "controls", "sliders", "actions", "media"]
    readonly property var labels: ({
            profile: "Profile Header",
            controls: "Primary Controls",
            sliders: "Sliders",
            actions: "Secondary Controls",
            media: "Media Player"
        })
    // Stable logical geometry keeps the complete composition visible at every window size.
    property int outputWidth: 1920
    property int outputHeight: 1080
    property real measuredProfileHeight: Theme.RenderTokens.profileHeight
    property real measuredMediaHeight: Theme.RenderTokens.mediaHeight
    readonly property var geometry: SectionLayout.geometry(Object.assign({}, layout, {layout:order}), {
        availableWidth: Math.max(88, outputWidth - 28), availableHeight: Math.max(80, outputHeight - 90),
        padding: Theme.RenderTokens.padding, topPadding: 12,
        tileSize: Theme.RenderTokens.tileSize, actionSize: Theme.RenderTokens.actionSize,
        sliderHeight: Theme.RenderTokens.sliderHeight,
        controls: count("controls"), actions: count("actions"), sliders: count("sliders"),
        profile: !!(Services.Settings.data.profile.displayName || Services.Settings.data.profile.subtitle || Services.Settings.data.profile.avatar),
        profileHeight: measuredProfileHeight, mediaHeight: measuredMediaHeight,
        gaps: [Theme.Theme.visual.profileControlsGap, Theme.Theme.visual.controlsSlidersGap,
            Theme.Theme.visual.slidersActionsGap, Theme.Theme.visual.actionsMediaGap, Theme.Theme.visual.mediaSectionGap]
    })
    readonly property real canvasWidth: geometry.width
    readonly property real decorationSpace: layout.decoration.enabled && layout.decoration.asset
        ? Math.min(340, layout.decoration.height * layout.decoration.asset.bounds[2] / layout.decoration.asset.bounds[3]) + 8 : 0
    readonly property real sceneWidth: canvasWidth + decorationSpace + (editing && !availableCard ? 324 : 0)
    readonly property real sceneHeight: composition.height
    readonly property real fitScale: Math.min(1, width / sceneWidth, editorViewport ? 1 : height / Math.max(1, sceneHeight))
    readonly property var order: structureBoard.preview ? structureBoard.order("structure") : layout.layout
    readonly property var composition: compose()
    readonly property string fingerprint: JSON.stringify([layout.layout, layout.controls, layout.actions, layout.sliders])
    implicitHeight: composition.height * Math.min(1, width / sceneWidth)
    function entries(group) {
        return layout[group].filter(e => e.enabled);
    }
    function columns(group) {
        return group === "controls" ? geometry.columns : group === "actions" ? geometry.actionColumns : group === "sliders" ? Math.max(1, count(group)) : 1
    }
    function gap(group) { return group === "actions" ? 8 : group === "sliders" ? Theme.RenderTokens.sliderGap : 12 }
    function cellWidth(group) {
        return group === "controls" ? size(group) : (geometry.innerWidth - (columns(group) - 1) * gap(group)) / columns(group)
    }
    function size(group) { return group === "controls" ? Theme.RenderTokens.tileSize : group === "sliders" ? Theme.RenderTokens.sliderHeight : Theme.RenderTokens.actionSize }
    function count(group) { return moduleBoard.preview ? moduleBoard.order(group).length : entries(group).length }
    function sectionHeight(id) { return geometry.heights[ids.indexOf(id)] || 0 }
    function compose() {
        const positions = {}
        ids.forEach((id, i) => { if (geometry.visible[i]) positions[id] = geometry.sections.positions[i] + 12 })
        return {positions:positions, height:geometry.height}
    }
    function moduleEntries() {
        return Schema.controlDefinitions().map(d => {
            let group = "available", entry = null;
            for (const g of ["controls", "actions", "sliders"]) {
                const e = layout[g].find(e => e.module === d.id);
                if (e && (!entry || e.enabled)) {
                    entry = e;
                    if (e.enabled && layout.layout.includes(g))
                        group = g;
                }
            }
            return {
                key: d.id,
                label: d.label,
                lane: group,
                position: group === "available" ? Schema.controlDefinitions().findIndex(x => x.id === d.id) : entries(group).findIndex(e => e.module === d.id),
                data: entry || {
                    key: d.id,
                    module: d.id,
                    accent: d.accent || "lavender"
                }
            };
        });
    }
    function regionGeometry() {
        const result = [];
        for (const id of ["controls", "sliders", "actions"]) {
            const exists = composition.positions[id] !== undefined;
            if (exists)
                result.push({
                    id: id,
                    label: "",
                    x: Theme.RenderTokens.padding,
                    y: composition.positions[id],
                    width: geometry.innerWidth,
                    height: sectionHeight(id),
                    keys: moduleBoard.order(id),
                    columns: columns(id),
                    cellHeight: size(id),
                    cellWidth: cellWidth(id),
                    gap: gap(id)
                });
        }
        if (editing) {
            const box = paletteRect(palette), cells = paletteRect(palette.controlsArea)
            const cols = palette.columns
            result.push({id:"available",label:"",emptyLabel:"",x:box.x,y:box.y,width:box.width,height:box.height,
                contentX:cells.x,contentY:cells.y,keys:moduleBoard.order("available"),columns:cols,
                cellWidth:cells.width / cols,cellHeight:54 / fitScale,gap:0,rowGap:12 / fitScale})
            // Empty sections have no runtime height. Offer a narrow insertion target
            // only while dragging a compatible control; never cover another control.
            for (const id of ["controls", "sliders", "actions"]) {
                if (result.some(lane => lane.id === id) || !moduleBoard.dragging || !moduleBoard.canPlace(moduleBoard.dragKey,id)) continue
                const following = order.slice(order.indexOf(id) + 1).find(key => composition.positions[key] !== undefined)
                const y = following ? composition.positions[following] - 10 : composition.height - 10
                result.push({id:id,label:"",emptyLabel:"",x:Theme.RenderTokens.padding,y:Math.max(1,y),width:geometry.innerWidth,height:8,
                    keys:[],columns:1,cellWidth:geometry.innerWidth,cellHeight:8,emptyTarget:true})
            }
        }
        return result;
    }
    function moduleLocation(key, regions) {
        for (const lane of regions) {
            const index = lane.keys.indexOf(key);
            if (index >= 0)
                return {
                    lane: lane,
                    index: index,
                    hidden: lane.id === "available" && !palette.expanded,
                    x: (lane.contentX ?? lane.x) + (index % lane.columns) * (lane.cellWidth + (lane.gap ?? 12)),
                    y: (lane.contentY ?? lane.y) + Math.floor(index / lane.columns) * (lane.cellHeight + (lane.rowGap ?? lane.gap ?? 12)),
                    width: lane.cellWidth,
                    height: lane.cellHeight
                };
        }
        return {
            lane: {
                id: ""
            },
            index: -1,
            x: 0,
            y: 0,
            width: 0,
            height: 0
        };
    }
    function structures() {
        return ids.map(id => ({key:id, label:labels[id],
            lane:layout.layout.includes(id) ? "structure" : "availableStructure",
            position:layout.layout.includes(id) ? layout.layout.indexOf(id) : ids.indexOf(id)}))
    }
    function paletteRect(item) {
        // Read layout dependencies so mapped coordinates track column stacking,
        // wrapping, disclosure and preview-scale changes without polling.
        let revision = fitScale
        for (let ancestor = item; ancestor; ancestor = ancestor.parent)
            revision += ancestor.x + ancestor.y + ancestor.width + ancestor.height + ancestor.scale
        for (let ancestor = fittedScene; ancestor; ancestor = ancestor.parent)
            revision += ancestor.x + ancestor.y + ancestor.width + ancestor.height + ancestor.scale
        const point = item.mapToItem(fittedScene,0,0)
        const end = item.mapToItem(fittedScene,item.width,item.height)
        return {x:point.x,y:point.y,width:end.x-point.x,height:end.y-point.y,revision:revision}
    }
    function structureGeometry() {
        const box = paletteRect(palette)
        return [
            {id:"structure",label:"",emptyLabel:"",x:0,y:0,width:canvasWidth,
                height:composition.height,keys:structureBoard.order("structure")},
            {id:"availableStructure",label:"",emptyLabel:"",x:box.x,y:box.y,width:box.width,height:box.height,
                keys:structureBoard.order("availableStructure")}
        ]
    }
    function structureLocation(key, regions) {
        const lane = regions.find(l => l.keys.includes(key))
        if (!lane) return {lane:{id:""},index:-1,x:0,y:0,width:0,height:0}
        const index = lane.keys.indexOf(key)
        if (lane.id === "structure") return {lane:lane,index:index,x:0,y:composition.positions[key] ?? 0,
            width:canvasWidth,height:sectionHeight(key) || 1,hidden:composition.positions[key] === undefined}
        const box = paletteRect(palette.sectionsArea),cols=palette.columns
        return {lane:lane,index:index,x:box.x+(index%cols)*box.width/cols,y:box.y+Math.floor(index/cols)*40/fitScale,
            width:box.width/cols,height:36/fitScale,hidden:!palette.expanded}
    }
    CCAvailableControls {
        id: fallbackPalette
        objectName: "ccStandaloneAvailableControls"
        visible: root.editing && !root.availableCard
        preview: root
        x: (root.canvasWidth + root.decorationSpace + 24) * root.fitScale
        width: 300 * root.fitScale
    }
    Flickable {
        id: view
        // The editor's shared board also owns palette handles outside the panel.
        // Its viewport must contain those handles for pointer delivery, while the
        // painted preview and its layout allocation remain panel-sized.
        width: root.editorViewport ? Math.max(root.width, root.palette.mapToItem(root,root.palette.width,0).x) : root.width
        height: root.editorViewport ? Math.max(root.height, root.palette.mapToItem(root,0,root.palette.height).y) : root.height
        clip: !root.editorViewport
        contentWidth: width
        contentHeight: height
        interactive: false
        boundsBehavior: Flickable.StopAtBounds

        Item {
            id: fittedScene
            x: root.decorationSpace * root.fitScale
            width: root.sceneWidth - root.decorationSpace
            height: root.sceneHeight
            scale: root.fitScale
            transformOrigin: Item.TopLeft
            Rectangle {
                width: root.canvasWidth
                height: root.composition.height
                color: Theme.Theme.roles[Services.Settings.data.appearance.controlCentreBackgroundRole]
                radius: Theme.RenderTokens.outerRadius
                Controls.SurfaceBorder {
                    surfaceId: "controlcentre"
                    radius: parent.radius
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { root.forceActiveFocus(Qt.MouseFocusReason); root.selected("") }
                }
            }
            Repeater {
                model: root.order
                Item {
                    id: region
                    required property string modelData
                    objectName: "ccAppearanceRegion-" + modelData
                    property bool pointerFocus: false
                    onActiveFocusChanged: if (!activeFocus) pointerFocus = false
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: root.labels[modelData] + " appearance"
                    Accessible.onPressAction: root.selected(modelData)
                    Keys.onSpacePressed: { pointerFocus = false; root.selected(modelData) }
                    Keys.onReturnPressed: { pointerFocus = false; root.selected(modelData) }
                    x: Theme.RenderTokens.padding
                    y: root.composition.positions[modelData] ?? 0
                    width: root.geometry.innerWidth
                    height: root.sectionHeight(modelData)
                    visible: root.composition.positions[modelData] !== undefined
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { region.forceActiveFocus(Qt.MouseFocusReason); region.pointerFocus = true; root.selected(parent.modelData) }
                    }
                    CCSectionPreview {
                        width: parent.width
                        height: parent.height
                        section: parent.modelData
                        liveData: true
                        onNaturalHeightChanged: {
                            if (section === "profile") root.measuredProfileHeight = naturalHeight
                            if (section === "media") root.measuredMediaHeight = naturalHeight
                        }
                        renderControls: false
                        playing: root.playing
                    }
                    Rectangle {
                        anchors.fill: parent
                        objectName: "ccFamilyHighlight-" + region.modelData
                        visible: root.selectedKey === region.modelData || region.activeFocus
                        color: Qt.alpha(Theme.Theme.accent, 0.04)
                        border.width: region.activeFocus && !region.pointerFocus ? 2 : 1
                        border.color: Qt.alpha(Theme.Theme.accent, region.activeFocus && !region.pointerFocus ? 1 : 0.4)
                        radius: Theme.Theme.radius("surface", 8, width, height)
                    }
                    MouseArea {
                        anchors.fill: parent
                        visible: ["profile", "media"].includes(parent.modelData)
                        onClicked: { region.forceActiveFocus(Qt.MouseFocusReason); region.pointerFocus = true; root.selected(parent.modelData) }
                    }
                }
            }
            SettingsReorderBoard {
                id: moduleBoard
                canvasContentMargin: 0
                objectName: "ccModuleBoard"
                width: Math.max(root.canvasWidth, root.paletteRect(root.palette).x + root.paletteRect(root.palette).width)
                visible: true
                removeLane: "available"
                viewport: root.editorViewport || view
                canvasMode: true
                editing: root.editing
                selectedKey: root.selectedKey
                canonicalRevision: root.fingerprint
                entries: root.moduleEntries()
                lanes: [
                    {
                        id: "controls",
                        label: "Primary Controls"
                    },
                    {
                        id: "actions",
                        label: "Secondary Controls"
                    },
                    {
                        id: "sliders",
                        label: "Sliders"
                    },
                    {
                        id: "available",
                        label: "Available",
                        ordered: false
                    }
                ]
                geometryProvider: () => root.regionGeometry()
                locationProvider: (key, regions) => root.moduleLocation(key, regions)
                canPlace: function (key, lane) {
                    return lane === "available" || Schema.controlDefinitions().find(d => d.id === key)?.presentations.includes({
                        controls: "tile",
                        actions: "action",
                        sliders: "slider"
                    }[lane]) === true;
                }
                onSelected: key => root.selected(key)
                onMoveRequested: (key, lane, position) => Services.Settings.placeCCModule(key, lane, position)
                rowContent: Component {
                    Item {
                        readonly property var entry: parent.entry
                        readonly property string lane: parent.previewLane
                        CCControlPreview {
                            anchors.fill: parent
                            anchors.bottomMargin: parent.lane === "available" ? 18 / root.fitScale : 0
                            entry: parent.entry.data
                            family: parent.lane === "available" ? "actions" : parent.lane
                        }
                        Text {
                            visible: parent.lane === "available"
                            anchors.bottom: parent.bottom
                            width: parent.width
                            text: parent.entry.label
                            elide: Text.ElideRight
                            color: Theme.Theme.text
                            font.pixelSize: parent.lane === "available" ? 10 / root.fitScale : 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
            SettingsReorderBoard {
                id: structureBoard
                rowHeight: 36
                canvasHandleWidth: Theme.RenderTokens.padding
                objectName: "ccStructureBoard"
                width: Math.max(root.canvasWidth, root.paletteRect(root.palette).x + root.paletteRect(root.palette).width)
                visible: root.editing
                removeLane: "availableStructure"
                viewport: root.editorViewport || view
                canvasMode: true
                editing: visible
                selectedKey: root.selectedKey
                canonicalRevision: root.fingerprint
                canPlace: (key, lane) => lane === "structure" || !["controls", "actions"].includes(key)
                entries: root.structures()
                lanes: [
                    {
                        id: "structure",
                        label: "Composition"
                    },
                    {
                        id: "availableStructure",
                        label: "Available components",
                        ordered: false
                    }
                ]
                geometryProvider: () => root.structureGeometry()
                locationProvider: (key, regions) => root.structureLocation(key, regions)
                onSelected: key => root.selected(key)
                onMoveRequested: (key, lane, position) => Services.Settings.placeCCSection(key, lane === "structure" ? position : -1)
                rowContent: Component {
                    Item {
                        readonly property var entry: parent.entry
                        readonly property bool placed: parent.previewLane === "structure"
                        Text {
                            x: parent.placed ? 0 : Theme.RenderTokens.padding
                            width: parent.width - x
                            text: parent.placed ? "⋮" : parent.entry.label
                            color: Theme.Theme.text
                            font.pixelSize: parent.placed ? 14 : 11 / root.fitScale
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
        Item {
            width: root.sceneWidth
            height: root.sceneHeight
            scale: root.fitScale
            transformOrigin: Item.TopLeft
            z: 10
            BarUI.ControlCentreDecoration {
                objectName: "decorationPreview"
                animate: false
                playbackEnabled: false
                panelPresent: true
                panelReady: panelPresent
                panelRect: Qt.rect(root.decorationSpace, 0, root.canvasWidth, root.composition.height)
            }
        }
    }
}
