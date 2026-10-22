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
#include <QQuickImageProvider>
#include <QDateTime>
#include <QLocale>
#include <QPainterPath>
namespace {
class VisualImages final : public QQuickImageProvider {
    QImage wallpaper_, avatar_;
public:
    explicit VisualImages(const magi::VisualData& data) : QQuickImageProvider(Image), wallpaper_(data.wallpaper) {
        if (!data.avatar.isNull()) {
            avatar_=QImage(192,192,QImage::Format_ARGB32_Premultiplied); avatar_.fill(Qt::transparent);
            QPainter painter(&avatar_); painter.setRenderHint(QPainter::Antialiasing);
            QPainterPath clip; const auto radius=data.values.value("avatarRadius",12).toDouble()*2;
            clip.addRoundedRect(avatar_.rect(),radius,radius); painter.setClipPath(clip);
            const auto scaled=data.avatar.scaled(192,192,Qt::KeepAspectRatioByExpanding,Qt::SmoothTransformation);
            painter.drawImage(QPoint((192-scaled.width())/2,(192-scaled.height())/2),scaled);
        }
    }
    QImage requestImage(const QString& id, QSize* size, const QSize&) override {
        auto result=id=="wallpaper" ? wallpaper_ : id=="avatar" ? avatar_ : QImage();
        if(size) *size=result.size();
        return result;
    }
};
}

static void initializeResources() {
    static const bool initialized = [] { Q_INIT_RESOURCE(proof_qml); return true; }();
    (void)initialized;
}
namespace magi {
void Presentation::fallback(QImage& image) { image.fill(QColor(VisualData::current().values.value("background").toString())); }
void Presentation::fallback(QImage& image, AuthPresentation auth) {
    fallback(image);
    if (image.isNull()) return;
    QPainter painter(&image);
    painter.setPen(QColor(VisualData::current().values.value("text").toString()));
    QFont font; font.setPixelSize(24); painter.setFont(font);
    painter.drawText(image.rect(), Qt::AlignCenter | Qt::TextWordWrap,
        QStringLiteral("MAGI LOCK\n") + QString::fromLatin1(auth.keyboardUnavailable ? "Keyboard state unavailable: press and release Shift" : authStateName(auth.state))
        + (auth.capsKnown && auth.caps ? QStringLiteral("\nCaps Lock") : QString()));
}
bool Presentation::render(QImage& image, const QString& output, const QString& state,
                          const QString& notice, const QByteArray& testSource, AuthPresentation auth, const VisualData* visual) {
    fallback(image, auth);
    if (image.isNull()) return false;
    initializeResources();
    const auto& data = visual ? *visual : VisualData::current();
    // Software render control uses public Qt APIs, no initialize/beginFrame/
    // endFrame (those are for RHI). All objects die before the buffer is sent.
    QQuickRenderControl control;
    QQuickWindow window(&control);
    bool renderError = false;
    QObject::connect(&window, &QQuickWindow::sceneGraphError, &window,
                     [&renderError](QQuickWindow::SceneGraphError, const QString&) {
                         renderError = true;
                     });
    window.setColor(QColor(data.values.value("background").toString()));
    window.setGeometry(0, 0, image.width(), image.height());
    window.setRenderTarget(QQuickRenderTarget::fromPaintDevice(&image));
    QQmlEngine engine;
    engine.addImageProvider("visual", new VisualImages(data));
    QQmlComponent component(&engine);
    if (testSource.isEmpty()) component.loadUrl(QUrl("qrc:/magi-lock/qml/LockScreen.qml"));
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
    item->setProperty("capsKnown", auth.capsKnown);
    item->setProperty("authStatus", QString::fromLatin1(auth.keyboardUnavailable ? "Keyboard state unavailable: press and release Shift" : authStateName(auth.state)));
    item->setProperty("fingerprintStatus", QString::fromUtf8(auth.fingerprintStatus));
    item->setProperty("visual", data.values);
    const auto now=QDateTime::currentDateTime();
    const auto format=data.values.value("timeFormat").toString();
    item->setProperty("timeLabel", format=="12h" ? QLocale().toString(now.time(), "h:mm AP")
        : format=="24h" ? QLocale().toString(now.time(), "HH:mm") : QLocale().toString(now.time(), QLocale::ShortFormat));
    item->setProperty("dateLabel", QLocale().toString(now.date(), QStringLiteral("dddd, d MMMM")));
    item->setProperty("wallpaperAvailable", !data.wallpaper.isNull());
    item->setProperty("avatarAvailable", !data.avatar.isNull());
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
