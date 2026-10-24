-- Approved native bootstrap fixture; replaces the rejected all-client block.
-- MAGI APPLICATION BACKGROUND BEGIN -- after operator rules/includes
-- One immutable Ghostty-only rule. No opacity options or generated include.
do
    local uuid = assert(io.open("/proc/sys/kernel/random/uuid", "r"))
    magi_application_background = {
        generation = assert(uuid:read("*l")),
        rule = hl.window_rule({
            name = "magi-ghostty-background-no-blur",
            match = {class = "^com\\.mitchellh\\.ghostty$"},
            enabled = false,
            no_blur = true,
        }),
    }
    uuid:close()
end
-- MAGI APPLICATION BACKGROUND END
