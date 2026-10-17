#include "presentation.hpp"
#include <QGuiApplication>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <iostream>
#include <vector>
int main(int argc, char** argv) {
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);
    QGuiApplication app(argc, argv);
    // Test real software Qt Quick rendering directly into caller-owned pixels,
    // matching native SHM layout, without opening a Wayland connection/window.
    std::vector<QRgb> pixels(800 * 600, 0);
    QImage image(reinterpret_cast<uchar*>(pixels.data()), 800, 600, 800 * 4, QImage::Format_RGB32);
    if (!magi::Presentation::render(image, "Output 7", "Locked", "TEST ONLY")) return 1;
    unsigned different = 0;
    const QRgb background = QColor("#181825").rgb();
    for (auto pixel : pixels) {
        if (qAlpha(pixel) != 255) return 2;
        if (pixel != background) ++different;
    }
    if (different < 100) { std::cerr << "No proof text rendered into native buffer\n"; return 3; }
    for (const auto& invalid : {QByteArray("import QtQuick\nNotAType {}"),
                                QByteArray("import QtQml\nQtObject {}")}) {
        if (magi::Presentation::render(image, "Output 7", "Locked", "TEST", invalid)) return 4;
        magi::Presentation::fallback(image);
        for (auto pixel : pixels) if (pixel != background) return 5;
    }
    QImage portrait(360, 640, QImage::Format_RGB32);
    if (!magi::Presentation::render(portrait, "Rotated output", "Locked", "TEST")) return 6;
    QImage null;
    if (magi::Presentation::render(null, "", "", "")) return 7;
    std::cout << "Real offscreen QML/native-buffer render, invalid QML, wrong root and solid fallback passed\n";
}
