// Keep actual workspace objects, including their reactive focused state.
// Special, named and sentinel workspaces do not belong in the numbered strip.
function normalWorkspaces(values) {
    return values.filter(function(workspace) {
        return Number.isInteger(workspace.id) && workspace.id > 0
            && /^[1-9][0-9]*$/.test(workspace.name)
    }).slice().sort(function(a, b) { return a.id - b.id })
}
