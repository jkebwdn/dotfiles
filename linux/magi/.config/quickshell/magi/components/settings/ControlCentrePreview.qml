pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
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
    readonly property real sectionPaletteHeight: 30 + structureBoard.order("structure").length * 40
    readonly property real componentPaletteHeight: structureBoard.order("availableStructure").length ? 30 + structureBoard.order("availableStructure").length * 40 : 80
    readonly property real modulePaletteY: sectionPaletteHeight + componentPaletteHeight + 24
    readonly property bool paletteBeside: editing
    readonly property real paletteX: canvasWidth + 24
    readonly property real paletteWidth: 300
    readonly property real decorationSpace: !editing && layout.decoration.enabled && layout.decoration.asset
        ? Math.min(340, layout.decoration.height * layout.decoration.asset.bounds[2] / layout.decoration.asset.bounds[3]) + 8 : 0
    readonly property real sceneWidth: editing ? paletteX + paletteWidth : canvasWidth + decorationSpace
    readonly property real sceneHeight: Math.max(composition.height, editing ? Math.max(structureBoard.implicitHeight, moduleBoard.implicitHeight) : 0)
    readonly property real fitScale: Math.min(1, width / sceneWidth, height / Math.max(1, sceneHeight))
    readonly property var order: structureBoard.preview ? structureBoard.order("structure") : layout.layout
    readonly property var composition: compose()
    readonly property string fingerprint: JSON.stringify([layout.layout, layout.controls, layout.actions, layout.sliders])
    implicitHeight: Math.max(400, composition.height + 28)
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
        if (editing)
            result.push({
                id: "available",
                label: "Available controls",
                x: paletteX,
                y: modulePaletteY,
                width: paletteWidth,
                height: Math.ceil(moduleBoard.order("available").length / 3) * 66 + 38,
                keys: moduleBoard.order("available"),
                columns: Math.max(1, Math.floor(paletteWidth / 100)),
                cellWidth: 88,
                cellHeight: 54
            });
        if (editing) {
            let y = modulePaletteY + Math.ceil(moduleBoard.order("available").length / 3) * 66 + 50
            for (const id of ["controls", "sliders", "actions"]) {
                if (result.some(lane => lane.id === id)) continue
                result.push({id:id, label:labels[id], x:paletteX, y:y, width:paletteWidth, height:72,
                    keys:[], columns:1, cellWidth:paletteWidth, cellHeight:48, emptyTarget:true})
                y += 80
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
                    x: lane.x + (index % lane.columns) * (lane.cellWidth + (lane.gap ?? 12)),
                    y: lane.y + (lane.id === "available" || lane.emptyTarget ? 30 : 0) + Math.floor(index / lane.columns) * (lane.cellHeight + (lane.gap ?? 12)),
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
    function structureGeometry() {
        return [
            {id:"structure", label:"Sections", x:paletteX, y:0, width:paletteWidth,
                height:sectionPaletteHeight, keys:structureBoard.order("structure")},
            {id:"availableStructure", label:structureBoard.order("availableStructure").length ? "Available sections" : "",
                emptyLabel:"Drag here to remove", x:paletteX, y:sectionPaletteHeight + 8,
                width:paletteWidth, height:Math.max(editing ? 28 : 0, componentPaletteHeight),
                keys:structureBoard.order("availableStructure")}
        ]
    }
    function structureLocation(key, regions) {
        const lane = regions.find(l => l.keys.includes(key))
        if (!lane) return {lane:{id:""}, index:-1, x:0, y:0, width:0}
        const index = lane.keys.indexOf(key)
        return {lane:lane, index:index, x:lane.x + 4, y:lane.y + 30 + index * 40,
            width:lane.width - 8, height:36}
    }
    Flickable {
        id: view
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: height
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
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
                        radius: Theme.Theme.radius("action", 8, width, height)
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
                width: root.sceneWidth
                visible: true
                removeLane: "available"
                viewport: view
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
                            anchors.bottomMargin: parent.lane === "available" ? 18 : 0
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
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
            SettingsReorderBoard {
                id: structureBoard
                rowHeight: 36
                objectName: "ccStructureBoard"
                width: root.sceneWidth
                visible: root.editing
                removeLane: "availableStructure"
                viewport: view
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
                            text: parent.entry.label
                            color: Theme.Theme.text
                            font.bold: true
                            font.pixelSize: 12
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
                panelPresent: !root.editing
                panelReady: panelPresent
                panelRect: Qt.rect(root.decorationSpace, 0, root.canvasWidth, root.composition.height)
            }
        }
    }
}
