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
    QImage wallpaper_, avatar_, avatarFrame_, media_, mediaIcon_, depth_;
    QVariantMap palette_;
public:
    explicit VisualImages(const magi::VisualData& data) : QQuickImageProvider(Image), wallpaper_(data.wallpaper), media_(data.media), depth_(data.depth), palette_(data.values) {
        mediaIcon_=data.mediaIcon.convertToFormat(QImage::Format_ARGB32_Premultiplied);
        if(!mediaIcon_.isNull()) {QPainter ink(&mediaIcon_);ink.setCompositionMode(QPainter::CompositionMode_SourceIn);ink.fillRect(mediaIcon_.rect(),QColor(data.values.value("text").toString()));}
        if (!data.avatar.isNull()) {
            avatar_=QImage(192,192,QImage::Format_ARGB32_Premultiplied); avatar_.fill(Qt::transparent);
            const auto scaled=data.avatar.scaled(192,192,Qt::KeepAspectRatioByExpanding,Qt::SmoothTransformation);
            QPainter painter(&avatar_);
            painter.drawImage(QPoint((192-scaled.width())/2,(192-scaled.height())/2),scaled);
            // An antialiased alpha mask, rather than a raster clip. QML displays
            // this inside a two-unit inset of the 124-unit avatar frame.
            const auto effects=data.values.value("lockScreen").toMap().value("effects").toMap();
            const double outerRadius=effects.value("avatar").toString()=="frame" ? 4.0 : data.values.value("avatarRadius",12).toDouble();
            const double radius=std::max(0.0,outerRadius-2.0)*192.0/120.0;
            QImage mask(192,192,QImage::Format_ARGB32_Premultiplied);mask.fill(Qt::transparent);
            QPainter maskPainter(&mask);maskPainter.setRenderHint(QPainter::Antialiasing);
            maskPainter.setPen(Qt::NoPen);maskPainter.setBrush(Qt::white);
            maskPainter.drawRoundedRect(QRectF(0,0,192,192),radius,radius);maskPainter.end();
            painter.setCompositionMode(QPainter::CompositionMode_DestinationIn);
            painter.drawImage(0,0,mask);
            // Compact avatar and its border are one supersampled image, so
            // separate scaled scene nodes cannot leave a jagged seam.
            constexpr int extent=496;
            avatarFrame_=QImage(extent,extent,QImage::Format_ARGB32_Premultiplied);avatarFrame_.fill(Qt::transparent);
            QPainter frame(&avatarFrame_);frame.setRenderHints(QPainter::Antialiasing|QPainter::SmoothPixmapTransform);
            const auto cover=data.avatar.scaled(extent,extent,Qt::KeepAspectRatioByExpanding,Qt::SmoothTransformation);
            frame.drawImage(QPoint((extent-cover.width())/2,(extent-cover.height())/2),cover);
            QImage frameMask(extent,extent,QImage::Format_ARGB32_Premultiplied);frameMask.fill(Qt::transparent);
            QPainter alpha(&frameMask);alpha.setRenderHint(QPainter::Antialiasing);alpha.setPen(Qt::NoPen);alpha.setBrush(Qt::white);
            alpha.drawRoundedRect(QRectF(0,0,extent,extent),outerRadius*4,outerRadius*4);alpha.end();
            frame.setCompositionMode(QPainter::CompositionMode_DestinationIn);frame.drawImage(0,0,frameMask);
            frame.setCompositionMode(QPainter::CompositionMode_SourceOver);
            frame.setPen(QPen(QColor(data.values.value("accent").toString()),16));frame.setBrush(Qt::NoBrush);
            frame.drawRoundedRect(QRectF(8,8,extent-16,extent-16),std::max(0.0,outerRadius*4-8),std::max(0.0,outerRadius*4-8));

        }
    }
    QImage fingerprint(const QString& state) const {
        QImage image(96,96,QImage::Format_ARGB32_Premultiplied);image.fill(Qt::transparent);
        QPainter painter(&image);painter.setRenderHint(QPainter::Antialiasing);painter.scale(4,4);
        const auto role=state=="failed" || state=="unavailable" ? "danger" : state=="retry" || state=="timeout" ? "warning" : "accent";
        painter.setPen(QPen(QColor(palette_.value(role).toString()),1.65,Qt::SolidLine,Qt::RoundCap,Qt::RoundJoin));painter.setBrush(Qt::NoBrush);
        QPainterPath path;
        if(state=="waiting") {
            path.moveTo(4,9);path.cubicTo(4,1,20,1,20,9);
            path.moveTo(2,13);path.cubicTo(2,7,5,4,12,4);path.cubicTo(19,4,22,8,22,13);
            path.moveTo(6,20);path.cubicTo(8,17,7,13,8,10);path.cubicTo(9,6,16,6,17,11);path.cubicTo(18,15,16,19,20,21);
            path.moveTo(3,18);path.cubicTo(5,15,4,11,6,9);
            path.moveTo(10,22);path.cubicTo(13,18,10,14,12,11);
            path.moveTo(15,22);path.cubicTo(13,18,16,14,14,11);
        } else if(state=="matched") {path.moveTo(4,12);path.lineTo(9,17);path.lineTo(20,6);}
        else if(state=="failed" || state=="timeout") {
            path.addEllipse(QRectF(3,3,18,18));
            if(state=="failed"){path.moveTo(8,8);path.lineTo(16,16);path.moveTo(16,8);path.lineTo(8,16);}
            else {path.moveTo(12,6);path.lineTo(12,12);path.lineTo(16,14);}
        } else if(state=="retry") {
            path.arcMoveTo(QRectF(4,4,16,16),30);path.arcTo(QRectF(4,4,16,16),30,300);
            path.moveTo(20,3);path.lineTo(20,9);path.lineTo(14,9);
        } else if(state=="unavailable") {
            path.moveTo(12,3);path.lineTo(22,21);path.lineTo(2,21);path.closeSubpath();path.moveTo(12,9);path.lineTo(12,14);path.moveTo(12,17);path.lineTo(12,18);
        }
        painter.drawPath(path);return image;
    }
    QImage requestImage(const QString& id, QSize* size, const QSize&) override {
        auto result=id.startsWith("fingerprint/") ? fingerprint(id.mid(12)) : id=="avatar-frame" ? avatarFrame_ : id=="wallpaper" ? wallpaper_ : id=="avatar" ? avatar_ : id=="media" ? media_ : id=="media-icon" ? mediaIcon_ : id=="depth" ? depth_ : QImage();
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
    painter.drawText(QRect(QPoint(0,0),image.deviceIndependentSize().toSize()), Qt::AlignCenter | Qt::TextWordWrap,
        QStringLiteral("MAGI LOCK\n") + QString::fromLatin1(auth.keyboardUnavailable ? "Keyboard state unavailable: press and release Shift" : authStateName(auth.state))
        + (auth.capsKnown && auth.caps ? QStringLiteral("\nCaps Lock") : QString()));
}
bool Presentation::render(QImage& image, const QString& output, const QString& state,
                          const QString& notice, const QByteArray& testSource, AuthPresentation auth, const VisualData* visual, std::array<QRectF, 3>* powerRegions) {
    if (powerRegions) *powerRegions = {};
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
    const auto logical=image.deviceIndependentSize().toSize();
    window.setGeometry(0, 0, logical.width(), logical.height());
    auto target=QQuickRenderTarget::fromPaintDevice(&image);target.setDevicePixelRatio(image.devicePixelRatio());
    window.setRenderTarget(target);
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
    item->setProperty("powerStatus", QString::fromUtf8(auth.powerStatus));
    item->setProperty("powerConfirmation", auth.powerConfirmation);
    item->setProperty("fingerprintStatus", QString::fromUtf8(auth.fingerprintStatus));
    auto displayValues=data.values;displayValues["nativeArtwork"]=true;
    item->setProperty("visual", displayValues);
    const auto now=QDateTime::currentDateTime();
    const auto format=data.values.value("timeFormat").toString();
    item->setProperty("timeLabel", format=="12h" ? QLocale().toString(now.time(), "h:mm AP")
        : format=="24h" ? QLocale().toString(now.time(), "HH:mm") : QLocale().toString(now.time(), QLocale::ShortFormat));
    item->setProperty("dateLabel", QLocale().toString(now.date(), QStringLiteral("dddd, d MMMM")));
    item->setProperty("wallpaperAvailable", !data.wallpaper.isNull());
    item->setProperty("avatarAvailable", !data.avatar.isNull());
    item->setParentItem(window.contentItem());
    item->setWidth(logical.width());
    item->setHeight(logical.height());
    control.polishItems();
    control.sync();
    control.render();
    if (!renderError && powerRegions && testSource.isEmpty()) {
        const char* names[] = {"powerReboot", "powerSuspend", "powerCancel"};
        for (unsigned i=0; i<3; ++i) {
            auto* target = item->findChild<QQuickItem*>(names[i]);
            if (target && target->isVisible()) {
                const auto rect = target->mapRectToScene(target->boundingRect());
                if (QRectF(QPointF(0,0),logical).contains(rect)) (*powerRegions)[i] = rect;
            }
        }
    }
    control.invalidate();
    if (renderError) fallback(image, auth);
    return !renderError;
}
}
