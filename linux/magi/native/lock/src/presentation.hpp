#pragma once
#include <QImage>
#include <QRectF>
#include <array>
#include "visual_data.hpp"
#include "auth_presentation.hpp"
#include <QString>
namespace magi {
// Offline renderer only: no native QWindow is shown and no Wayland connection
// is made here. The caller owns both the image and real protocol surfaces.
class Presentation {
public:
    static bool render(QImage& image, const QString& output, const QString& state,
                       const QString& notice, const QByteArray& testSource = {}, AuthPresentation auth = {}, const VisualData* visual = nullptr, std::array<QRectF, 3>* powerRegions = nullptr);
    static void fallback(QImage& image);
    static void fallback(QImage& image, AuthPresentation auth);
};
}
