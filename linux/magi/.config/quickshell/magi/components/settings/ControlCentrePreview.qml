pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../services" as Services
import "../../theme" as Theme
import "../../settings/SettingsSchema.js" as Schema
import "../controls" as Controls
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
    readonly property real canvasWidth: 380
    readonly property bool paletteBeside: editing
    readonly property real paletteX: canvasWidth + 24
    readonly property real paletteWidth: 240
    readonly property real sceneWidth: editing ? paletteX + paletteWidth : canvasWidth
    readonly property real sceneHeight: Math.max(composition.height, editing ? Math.max(structureBoard.implicitHeight, moduleBoard.implicitHeight) : 0)
    readonly property real fitScale: Math.min(1, width / sceneWidth, height / Math.max(1, sceneHeight))
    readonly property var order: structureBoard.preview ? structureBoard.order("structure") : editing ? layout.layout.concat(["controls", "actions"].filter(id => !layout.layout.includes(id))) : layout.layout.concat(["controls", "actions", "sliders"].filter(id => !layout.layout.includes(id)))
    readonly property var composition: compose()
    readonly property string fingerprint: JSON.stringify([layout.layout, layout.controls, layout.actions, layout.sliders])
    implicitHeight: Math.max(400, composition.height + 28)
    function entries(group) {
        return layout[group].filter(e => e.enabled);
    }
    function columns(group) {
        if (["profile", "media"].includes(group))
            return 1;
        const desired = group === "controls" ? layout.columns : group === "actions" ? layout.actionColumns : Math.min(2, Math.max(1, count(group)));
        return Math.max(1, Math.min(desired, Math.floor((canvasWidth - 28 + 12) / (size(group) + 12))));
    }
    function gap(group) {
        return group === "actions" ? 8 : group === "sliders" ? 20 : 12;
    }
    function cellWidth(group) {
        return group === "controls" ? size(group) : (canvasWidth - 28 - (columns(group) - 1) * gap(group)) / columns(group);
    }
    function size(group) {
        return group === "controls" ? Theme.RenderTokens.tileSize : group === "sliders" ? 48 : Theme.RenderTokens.actionSize;
    }
    function count(group) {
        return moduleBoard.preview ? moduleBoard.order(group).length : entries(group).length;
    }
    function sectionHeight(id) {
        if (id === "profile")
            return Math.max(100, Theme.RenderTokens.profileHeight) + 12;
        if (id === "media")
            return Theme.RenderTokens.mediaHeight + 12;
        return Math.max(editing ? 48 : 0, Math.ceil(count(id) / columns(id)) * (size(id) + gap(id)) - (count(id) ? gap(id) : 0));
    }
    function compose() {
        const gap = [Theme.Theme.visual.profileControlsGap, Theme.Theme.visual.controlsSlidersGap, Theme.Theme.visual.slidersActionsGap, Theme.Theme.visual.actionsMediaGap, Theme.Theme.visual.mediaSectionGap];
        const visible = ids.map(id => order.includes(id));
        const arranged = SectionLayout.compose(order, visible, ids.map(id => sectionHeight(id) + 30), gap);
        const positions = {};
        ids.forEach((id, i) => {
            if (visible[i])
                positions[id] = arranged.positions[i] + 14;
        });
        return {
            positions: positions,
            height: arranged.height + 28
        };
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
                    x: 14,
                    y: composition.positions[id],
                    width: canvasWidth - 28,
                    height: sectionHeight(id) + 30,
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
                label: "Controls",
                x: paletteX,
                y: structureBoard.order("availableStructure").length || structureBoard.dragging ? 44 + Math.max(1, structureBoard.order("availableStructure").length) * 48 : 0,
                width: paletteWidth,
                height: Math.ceil(moduleBoard.order("available").length / Math.max(1, Math.floor(paletteWidth / 100))) * 78 + 38,
                keys: moduleBoard.order("available"),
                columns: Math.max(1, Math.floor(paletteWidth / 100)),
                cellWidth: 88,
                cellHeight: 62
            });
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
                    y: lane.y + 30 + Math.floor(index / lane.columns) * (lane.cellHeight + (lane.gap ?? 12)),
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
        const placed = layout.layout.concat(["controls", "actions"].filter(id => !layout.layout.includes(id)));
        return ids.map(id => ({
                    key: id,
                    label: labels[id],
                    lane: placed.includes(id) ? "structure" : "availableStructure",
                    position: placed.includes(id) ? placed.indexOf(id) : ids.indexOf(id)
                }));
    }
    function structureGeometry() {
        return [
            {
                id: "structure",
                label: "",
                x: 0,
                y: 0,
                width: canvasWidth,
                height: composition.height,
                keys: structureBoard.order("structure")
            },
            {
                id: "availableStructure",
                label: structureBoard.order("availableStructure").length || structureBoard.dragging ? "Components" : "",
                emptyLabel: "Drag here to remove",
                x: paletteX,
                y: paletteBeside ? 0 : composition.height + 20,
                width: paletteWidth,
                height: structureBoard.order("availableStructure").length || structureBoard.dragging ? 36 + Math.max(1, structureBoard.order("availableStructure").length) * 48 : 0,
                keys: structureBoard.order("availableStructure")
            }
        ];
    }
    function structureLocation(key, regions) {
        const lane = regions.find(l => l.keys.includes(key));
        if (!lane)
            return {
                lane: {
                    id: ""
                },
                index: -1,
                x: 0,
                y: 0,
                width: 0
            };
        const i = lane.keys.indexOf(key), placed = lane.id === "structure";
        return {
            lane: lane,
            index: i,
            x: lane.x + 14,
            y: placed ? (composition.positions[key] ?? 14) : lane.y + 30 + i * 48,
            width: lane.width - 28,
            height: placed ? (["profile", "media"].includes(key) ? sectionHeight(key) + 30 : 26) : 40
        };
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
            width: root.sceneWidth
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
                model: root.editing ? [] : root.order
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
                    x: 14
                    y: root.composition.positions[modelData] ?? 0
                    width: root.canvasWidth - 28
                    height: root.sectionHeight(modelData) + 30
                    visible: root.composition.positions[modelData] !== undefined
                    Text {
                        text: root.labels[parent.modelData]
                        color: root.selectedKey === region.modelData ? Theme.Theme.accent : Theme.Theme.subtext
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { region.forceActiveFocus(Qt.MouseFocusReason); region.pointerFocus = true; root.selected(parent.modelData) }
                    }
                    CCSectionPreview {
                        y: 30
                        width: parent.width
                        height: parent.height - 30
                        section: parent.modelData
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
                        CCSectionPreview {
                            y: 30
                            width: parent.width
                            height: parent.height - 30
                            visible: parent.placed && ["profile", "media"].includes(parent.entry.key)
                            section: parent.entry.key
                            playing: root.playing
                            entries: ["controls", "actions", "sliders"].includes(section) ? root.entries(section) : []
                            columns: root.columns(section)
                            cellSize: root.size(section)
                            cellWidth: root.cellWidth(section)
                            gap: root.gap(section)
                        }
                    }
                }
            }
        }
    }
}
