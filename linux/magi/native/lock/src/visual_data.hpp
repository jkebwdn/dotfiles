#pragma once
#include <QImage>
#include <QVariantMap>
namespace magi {
// Immutable, display-only snapshot. No shell IPC, authentication or input objects.
struct VisualData {
    QVariantMap values;
    QImage wallpaper, avatar, media, mediaIcon, depth;
    void prepareWallpaper(const QImage& source);
    static VisualData load(const QString& config, const QString& state, const QString& data);
    static const VisualData& current();
};
}
