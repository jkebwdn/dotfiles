#include "presentation.hpp"
#include <QQmlComponent>
#include <QQmlEngine>
#include <QQuickItem>
#include <QQuickRenderControl>
#include <QQuickRenderTarget>
#include <QQuickWindow>
#include <memory>
#include <QPainter>
#include <algorithm>

static void initializeResources() {
    static const bool initialized = [] { Q_INIT_RESOURCE(proof_qml); return true; }();
    (void)initialized;
}
namespace magi {
void Presentation::fallback(QImage& image) { image.fill(QColor("#181825")); }
void Presentation::fallback(QImage& image, AuthPresentation auth) {
    fallback(image);
    if (image.isNull()) return;
    QPainter painter(&image);
    painter.setPen(QColor("#cdd6f4"));
    QFont font; font.setPixelSize(24); painter.setFont(font);
    painter.drawText(image.rect(), Qt::AlignCenter | Qt::TextWordWrap,
        QStringLiteral("MAGI LOCK\n") + QString::fromLatin1(authStateName(auth.state))
        + (auth.caps ? QStringLiteral("\nCaps Lock") : QString()));
}
bool Presentation::render(QImage& image, const QString& output, const QString& state,
                          const QString& notice, const QByteArray& testSource, AuthPresentation auth) {
    fallback(image, auth);
    if (image.isNull()) return false;
    initializeResources();
    // Software render control uses public Qt APIs, no initialize/beginFrame/
    // endFrame (those are for RHI). All objects die before the buffer is sent.
    QQuickRenderControl control;
    QQuickWindow window(&control);
    bool renderError = false;
    QObject::connect(&window, &QQuickWindow::sceneGraphError, &window,
                     [&renderError](QQuickWindow::SceneGraphError, const QString&) {
                         renderError = true;
                     });
    window.setColor(QColor("#181825"));
    window.setGeometry(0, 0, image.width(), image.height());
    window.setRenderTarget(QQuickRenderTarget::fromPaintDevice(&image));
    QQmlEngine engine;
    QQmlComponent component(&engine);
    if (testSource.isEmpty()) component.loadUrl(QUrl("qrc:/magi-lock/qml/Proof.qml"));
    else component.setData(testSource, QUrl("qrc:/magi-lock/test.qml"));
    if (component.status() != QQmlComponent::Ready) return false;
    std::unique_ptr<QObject> object(component.create());
    auto* item = qobject_cast<QQuickItem*>(object.get());
    if (!item) return false;
    item->setProperty("outputLabel", output);
    item->setProperty("nativeState", state);
    item->setProperty("developmentNotice", notice);
    item->setProperty("characterCount", int(std::min(auth.count, 511u)));
    item->setProperty("inputActive", auth.active);
    item->setProperty("capsLock", auth.caps);
    item->setProperty("authStatus", QString::fromLatin1(authStateName(auth.state)));
    item->setParentItem(window.contentItem());
    item->setWidth(image.width());
    item->setHeight(image.height());
    control.polishItems();
    control.sync();
    control.render();
    control.invalidate();
    if (renderError) fallback(image, auth);
    return !renderError;
}
}
