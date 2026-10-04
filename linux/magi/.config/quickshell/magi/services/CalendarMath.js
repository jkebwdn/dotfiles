// Civil local dates at noon avoid midnight/DST arithmetic. No ISO-string parsing.
function civil(year, month, day) {
    const value = new Date(0)
    value.setHours(12, 0, 0, 0)
    value.setFullYear(year, month, day)
    return value
}
function day(value) { return civil(value.getFullYear(), value.getMonth(), value.getDate()) }
function same(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
}
function addDays(value, amount) { return civil(value.getFullYear(), value.getMonth(), value.getDate() + amount) }
function monthDays(year, month) { return civil(year, month + 1, 0).getDate() }
function addMonths(value, amount) {
    const first = civil(value.getFullYear(), value.getMonth() + amount, 1)
    return civil(first.getFullYear(), first.getMonth(), Math.min(value.getDate(), monthDays(first.getFullYear(), first.getMonth())))
}
function isoWeek(value) {
    // Convert civil fields to UTC only for week arithmetic, never for display.
    const date = new Date(0)
    date.setUTCHours(0, 0, 0, 0)
    date.setUTCFullYear(value.getFullYear(), value.getMonth(), value.getDate())
    date.setUTCDate(date.getUTCDate() + 4 - (date.getUTCDay() || 7))
    const year = date.getUTCFullYear()
    const start = new Date(0)
    start.setUTCHours(0, 0, 0, 0); start.setUTCFullYear(year, 0, 1)
    return {year: year, week: Math.ceil(((date - start) / 86400000 + 1) / 7)}
}
function grid(year, month, firstDay, adjacent, today, selected) {
    const first = civil(year, month, 1)
    const offset = (first.getDay() - firstDay + 7) % 7
    const cells = []
    for (let i = 0; i < 42; ++i) {
        const date = civil(year, month, 1 - offset + i)
        const inMonth = date.getMonth() === month && date.getFullYear() === year
        cells.push({date: date, day: date.getDate(), inMonth: inMonth,
            shown: inMonth || adjacent, today: same(date, today), selected: same(date, selected)})
    }
    return cells
}
function weeks(cells) {
    // Each row is labelled by its Thursday: ISO weeks even for Sunday-first grids.
    const result = []
    for (let row = 0; row < 6; ++row) {
        const first = cells[row * 7].date
        result.push(isoWeek(addDays(first, (4 - first.getDay() + 7) % 7)))
    }
    return result
}
