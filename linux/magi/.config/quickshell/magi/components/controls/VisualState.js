function greeting(hour) {
    return hour >= 5 && hour < 12 ? "Good morning"
        : hour >= 12 && hour < 18 ? "Good afternoon"
        : hour >= 18 && hour < 23 ? "Good evening" : "Good night"
}
function progress(position, duration, supported) {
    return supported && isFinite(position) && isFinite(duration) && duration > 0
        ? Math.max(0, Math.min(1, position / duration)) : -1
}
// Clockwise rounded perimeter, starting at top centre. Canvas and tests share it.
function perimeter(width, height, radius, inset) {
    const w = Math.max(0, width - inset * 2), h = Math.max(0, height - inset * 2)
    const r = Math.max(0, Math.min(radius, w / 2, h / 2))
    const points = [[width / 2, inset]]
    for (const corner of [[inset+w-r,inset+r,-90],[inset+w-r,inset+h-r,0],
        [inset+r,inset+h-r,90],[inset+r,inset+r,180]]) {
        for (let i = 0; i <= 12; ++i) {
            const angle = (corner[2] + i * 90 / 12) * Math.PI / 180
            points.push([corner[0] + r * Math.cos(angle), corner[1] + r * Math.sin(angle)])
        }
    }
    points.push(points[0])
    return points
}
