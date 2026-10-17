#pragma once
#include <QImage>
#include <QString>
namespace magi {
// Offline renderer only: no native QWindow is shown and no Wayland connection
// is made here. The caller owns both the image and real protocol surfaces.
class Presentation {
public:
    static bool render(QImage& image, const QString& output, const QString& state,
                       const QString& notice, const QByteArray& testSource = {});
    static void fallback(QImage& image);
};
}
