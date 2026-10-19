#include "presentation.hpp"
#include "auth_controller.hpp"
#include "controller.hpp"
#include <QGuiApplication>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <iostream>
#include <vector>
#include <QElapsedTimer>
#include <QThread>
#include <functional>
struct LockBackend final : magi::Backend {
    int unlocks = 0;
    bool requestLock() override { return true; }
    bool createSurface(std::uint32_t) override { return true; }
    void removeSurface(std::uint32_t) override {}
    magi::FrameResult present(std::uint32_t, magi::Configure, bool) override { return magi::FrameResult::Fallback; }
    void diagnostic(std::string_view) override {}
    void disconnect() override {}
    void authenticatedUnlockAndSync() override { ++unlocks; }
};
int main(int argc, char** argv) {
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);
    QGuiApplication app(argc, argv);
    // Test real software Qt Quick rendering directly into caller-owned pixels,
    // matching native SHM layout, without opening a Wayland connection/window.
    std::vector<QRgb> pixels(800 * 600, 0);
    QImage image(reinterpret_cast<uchar*>(pixels.data()), 800, 600, 800 * 4, QImage::Format_RGB32);
    if (!magi::Presentation::render(image, "Output 7", "Locked", "TEST ONLY")) return 1;
    unsigned different = 0;
    const QRgb background = QColor(magi::VisualData::current().values.value("background").toString()).rgb();
    for (auto pixel : pixels) {
        if (qAlpha(pixel) != 255) return 2;
        if (pixel != background) ++different;
    }
    if (different < 100) { std::cerr << "No lock composition rendered into native buffer\n"; return 3; }
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
    LockBackend backend;
    magi::Controller lock(backend); lock.acquire(); lock.locked();
    magi::Credential credential;
    constexpr char secret[] = "MAGI_TEST_SECRET_7df1_PRESENTATION";
    if (!credential.append({secret, sizeof(secret)-1})) return 8;
    for (auto state : {magi::AuthState::Editing, magi::AuthState::Authenticating,
                       magi::AuthState::Failed, magi::AuthState::WorkerError, magi::AuthState::Succeeded}) {
        magi::AuthPresentation view{unsigned(credential.units()), true, true, state};
        if (!magi::Presentation::render(image, "Output", "Locked", "TEST", {}, view)) return 9;
        if (backend.unlocks || lock.state()!=magi::State::Locked) return 10;
        if (magi::Presentation::render(image, "Output", "Locked", "TEST", "invalid QML", view)) return 11;
        magi::Presentation::fallback(image, view);
        unsigned textPixels=0;
        for (auto pixel : pixels) { if (qAlpha(pixel)!=255) return 12; if (pixel!=background) ++textPixels; }
        if (textPixels<100 || backend.unlocks || lock.state()!=magi::State::Locked) return 13;
    }
    credential.clear();
    if (argc != 2) return 14;
    auto wait = [](const std::function<bool()>& done) {
        QElapsedTimer timer; timer.start();
        while (!done() && timer.elapsed()<3000) { QCoreApplication::processEvents(); QThread::msleep(2); }
        return done();
    };
    // A failed per-output renderer has no access to auth cancellation. The
    // multi-output suite exercises fallback during a live synthetic attempt.
    magi::AuthController auth(std::string(argv[1])+"/fixture-delayed-success",1000,20);
    auth.setInputActive(true);
    constexpr char input[]="MAGI_TEST_SECRET_7df1_CPP";
    if (!auth.append({input,sizeof(input)-1}) || !auth.submit()) return 15;
    auth.succeeded=[&](auto generation) { lock.authenticatedUnlock(auth,generation); };
    if (magi::Presentation::render(image,"Output","Locked","TEST","invalid QML",auth.presentation())) return 18;
    magi::Presentation::fallback(image,auth.presentation());
    if (!wait([&] { return backend.unlocks==1; })) return 20;
    std::cout << "Real offscreen QML/native-buffer render, invalid QML, wrong root and solid fallback passed\n";
}
