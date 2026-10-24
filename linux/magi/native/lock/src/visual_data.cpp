#include "visual_data.hpp"
#include "wallpaper_blur.hpp"
#include <pwd.h>
#include <unistd.h>
#include <array>
#include <algorithm>
#include <QColor>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QImageReader>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QDir>
namespace magi {
namespace {
QJsonObject read(const QString& path) {
    QFile file(path);
    if (!QFileInfo(path).isFile() || !file.open(QIODevice::ReadOnly) || file.size()>1024*1024) return {};
    const auto bytes=file.read(1024*1024+1);
    if (bytes.size()>1024*1024) return {};
    return QJsonDocument::fromJson(bytes).object();
}
QImage picture(const QString& path, QSize limit) {
    QFileInfo file(path);
    if (!file.isAbsolute() || !file.isFile() || file.size()>32*1024*1024) return {};
    QImageReader reader(path);
    const auto format=reader.format().toLower();
    if (format!="png" && format!="jpeg" && format!="webp" && format!="bmp") return {};
    const auto size=reader.size();
    if (!size.isValid() || size.width()>16384 || size.height()>16384 || qint64(size.width())*size.height()>64000000) return {};
    reader.setAutoTransform(true);
    reader.setScaledSize(size.scaled(limit, Qt::KeepAspectRatio));
    return reader.read();
}
}
VisualData VisualData::load(const QString& config, const QString& state, const QString& data) {
    VisualData result;
    std::array<char,16384> buffer{}; passwd account{}, *found=nullptr;
    const bool resolved=getpwuid_r(getuid(),&account,buffer.data(),buffer.size(),&found)==0 && found && found->pw_name;
    const QString identity=resolved ? QString::fromLocal8Bit(found->pw_name).left(64) : QString::number(getuid());
    result.values={{"background","#1e1e2e"},{"surface","#313244"},{"text","#cdd6f4"},
        {"subtext","#bac2de"},{"accent","#b4befe"},{"danger","#f38ba8"},{"warning","#f9e2af"},
        {"wallpaperTint",wallpaperTint},{"fontFamily","JetBrainsMono Nerd Font"},{"displayName",identity},{"avatarRadius",12.0}};
    const auto settings=read(config+"/settings.json");
    // Bounded JSON data only; the presentation normalizer rejects malformed layouts.
    result.values["lockScreen"]=settings["lockScreen"].toObject().toVariantMap();
    const auto appearance=settings["appearance"].toObject();
    const auto registry=read(config+"/theme/palettes/registry.json");
    if (registry["formatVersion"].toInt()==1) {
        QJsonObject selected, fallback;
        for (auto entry:registry["themes"].toArray()) {
            const auto theme=entry.toObject();
            if (theme["id"].toString()=="catppuccin-mocha") fallback=theme;
            if (theme["id"].toString()==appearance["theme"].toString()) selected=theme;
        }
        if (selected.isEmpty()) selected=fallback;
        const auto roles=selected["roles"].toObject();
        static const QRegularExpression color("^#[0-9a-fA-F]{6}$");
        bool valid=true;
        const QStringList names={"background","surface","text","subtext","accent","danger","warning"};
        for (const auto& name:names) valid &= color.match(roles[name].toString()).hasMatch();
        if (valid) for (const auto& name:names) result.values[name]=roles[name].toString();
    }
    const auto format=settings["calendar"].toObject()["timeFormat"].toString();
    result.values["timeFormat"]=(format=="12h" || format=="24h") ? format : "locale";
    const auto profile=settings["profile"].toObject();
    auto name=profile["displayName"].toString().simplified().left(64);
    if (!name.isEmpty()) result.values["displayName"]=name;
    const auto roundness=appearance["roundness"].toObject();
    const QJsonValue radius=roundness["roles"].toObject().value("avatar");
    result.values["avatarRadius"]=qBound(0.0,12.0*radius.toDouble(roundness["master"].toDouble(1.0)),48.0);
    static const QRegularExpression avatar("^avatar:([a-f0-9]{64}\\.(png|jpg|webp))$");
    const auto match=avatar.match(profile["avatar"].toString());
    if (match.hasMatch()) result.avatar=picture(data+"/magi/avatars/"+match.captured(1),{192,192});
    // Use the shared Wallpaper Manager assignment. Connector overrides require
    // an exact monitor description; do not guess identity from a connector name.
    const auto wallpaper=read(state+"/magi/wallpaper/state.json");
    if (wallpaper["version"].toInt()==1)
        result.prepareWallpaper(picture(wallpaper["shared"].toObject()["path"].toString(),{1920,1080}));
    return result;
}
void VisualData::prepareWallpaper(const QImage& source) {
    wallpaper=blurWallpaper(source);
    values["wallpaperTint"]=wallpaperTint;
    if (wallpaper.isNull()) return;
    const QColor background(values.value("background").toString());
    double brightness=0;
    // Fixed 16x16 whole-image sample grid, once per cached wallpaper. Perceptual
    // RGB brightness is sufficient for this restrained, clamped visual treatment.
    constexpr int samples=16;
    for(int y=0;y<samples;++y) for(int x=0;x<samples;++x) {
        const auto pixel=wallpaper.pixelColor((wallpaper.width()-1)*(2*x+1)/(2*samples),
            (wallpaper.height()-1)*(2*y+1)/(2*samples));
        const double alpha=pixel.alphaF();
        brightness+=0.2126*(alpha*pixel.redF()+(1-alpha)*background.redF())
            +0.7152*(alpha*pixel.greenF()+(1-alpha)*background.greenF())
            +0.0722*(alpha*pixel.blueF()+(1-alpha)*background.blueF());
    }
    brightness/=samples*samples;
    const double amount=std::clamp((brightness-wallpaperDimStart)/(wallpaperDimFull-wallpaperDimStart),0.0,1.0);
    values["wallpaperTint"]=wallpaperTint+(wallpaperMaximumTint-wallpaperTint)*amount;
}
const VisualData& VisualData::current() {
    static const auto snapshot=load(QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)+"/quickshell/magi",
        qEnvironmentVariable("XDG_STATE_HOME",QDir::homePath()+"/.local/state"),
        QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation));
    return snapshot;
}
}
