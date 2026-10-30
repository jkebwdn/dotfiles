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
#include <QDateTime>
#include <QCryptographicHash>
#include <cmath>
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
static QImage preparedPicture(const QString& path,QSize limit) {
    QImageReader reader(path);const auto size=reader.size();
    if(reader.format()!="png" || !size.isValid() || size.width()>limit.width() || size.height()>limit.height() || QFileInfo(path).size()>512*1024) return {};
    return picture(path,limit);
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
        result.prepareWallpaper(picture(wallpaper["shared"].toObject()["path"].toString(),settings["lockScreen"].toObject()["effects"].toObject()["blur"].toBool(true) ? QSize(1920,1080) : QSize(3840,2160)));
    // Optional display-only snapshots: never network, MPRIS, or an auth object.
    const auto layout=settings["lockScreen"].toObject();
    const auto elements=layout["elements"].toObject();
    const auto effects=layout["effects"].toObject();
    const auto now=QDateTime::currentSecsSinceEpoch();
    const auto cache=QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation)+"/magi";
    auto text=[](QJsonValue v) { auto t=v.toString().simplified().left(160);t.remove(QRegularExpression("[\\x{0000}-\\x{001f}\\x{007f}]"));return t; };
    if (elements["weather"].toObject()["visible"].toBool()) {
        const auto prefs=settings["weather"].toObject();
        const auto weather=read(cache+"/weather/current.json");
        const auto key=QString::fromLatin1(QCryptographicHash::hash(prefs["location"].toString().trimmed().toUtf8(),QCryptographicHash::Sha256).toHex());
        const double observed=weather["observed"].toDouble(-1), temp=weather["temperature"].toDouble(999);
        const int code=weather["code"].toInt(-1);
        QString condition;
        if(code==0) condition="Clear";else if(code<=2 && code>=1) condition="Partly cloudy";
        else if(code==3) condition="Cloudy";else if(code==45 || code==48) condition="Foggy";
        else if(QList<int>{51,53,55,56,57,61,63,65,66,67}.contains(code)) condition="Rainy";else if(QList<int>{71,73,75,77}.contains(code)) condition="Snowy";
        else if(code>=80 && code<=82) condition="Rainy";else if(code==85 || code==86) condition="Snowy";
        else if(code==95 || code==96 || code==99) condition="Thunderstorms";
        if(prefs["enabled"].toBool() && weather["key"].toString()==key && observed<=now+900 && observed>=now-10800
            && std::isfinite(temp) && temp>=-100 && temp<=70 && !condition.isEmpty()) {
            const bool imperial=prefs["units"].toString()=="imperial";
            QVariantMap display{{"available",true},{"temperature",QString::number(qRound(imperial ? temp*9/5+32 : temp))+(imperial ? "°F" : "°C")},{"condition",condition}};
            if(effects["location"].toBool()) display["location"]=text(weather["place"].toObject()["name"]).section(',',0,0);
            result.values["weather"]=display;
        }
    }
    result.refreshMedia(state);
    // Prepared cutout import is deferred. Only a bounded, wallpaper-matched
    // local prepared asset can opt into compositing; absent/invalid is quiet.
    if(effects["depth"].toBool()) {
        const auto depth=read(data+"/magi/lock-depth/current.json");
        const auto source=wallpaper["shared"].toObject()["path"].toString();
        const QFileInfo wall(source);
        const auto path=data+"/magi/lock-depth/subject.png";
        QImageReader reader(path);
        const auto dimensions=reader.size();
        const auto originalSize=QImageReader(source).size();
        if(!source.isEmpty() && depth["wallpaper"].toString()==source
            && depth["size"].toDouble()==wall.size() && depth["modified"].toDouble()==wall.lastModified().toSecsSinceEpoch()
            && reader.format()=="png" && dimensions.isValid() && originalSize.isValid()
            && qAbs(double(dimensions.width())/dimensions.height()-double(originalSize.width())/originalSize.height())<.01 && dimensions.width()<=960 && dimensions.height()<=960
            && QFileInfo(path).size()<=4*1024*1024) {
            auto image=reader.read();
            if(!image.isNull() && image.hasAlphaChannel()) result.depth=image;
        }
    }
    result.values["depthAvailable"]=!result.depth.isNull();
    return result;
}
bool VisualData::refreshMedia(const QString& state) {
    const auto layout=QJsonObject::fromVariantMap(values.value("lockScreen").toMap());
    const auto elements=layout["elements"].toObject();const auto effects=layout["effects"].toObject();
    const auto now=QDateTime::currentSecsSinceEpoch();
    const auto snapshot=read(state+"/magi/lock-auxiliary/media.json");
    const auto observed=snapshot["observed"].toDouble(-1);
    const bool fresh=observed<=now+60 && observed>=now-10800;
    const auto revision=fresh ? QJsonDocument(snapshot).toJson(QJsonDocument::Compact) : QByteArray();
    if(revision==mediaRevision_) return false;
    mediaRevision_=revision;
    const auto before=values.value("media");
    values.remove("media");media={};mediaIcon={};
    auto& result=*this;
    auto text=[](QJsonValue v) { auto t=v.toString().simplified().left(160);t.remove(QRegularExpression("[\\x{0000}-\\x{001f}\\x{007f}]"));return t; };
    if (elements["media"].toObject()["visible"].toBool()) {
        const auto media=snapshot;
        const auto observed=media["observed"].toDouble(-1);
        const auto title=text(media["title"]);
        if(observed<=now+60 && observed>=now-10800 && !title.isEmpty()) {
            QVariantMap display{{"available",true},{"title",title},{"artist",text(media["artist"])},{"playing",media["playing"].toBool()}};
            const QFileInfo file(media["artwork"].toString());
            if(effects["artwork"].toBool(true) && file.canonicalPath()==QFileInfo(state+"/magi/lock-auxiliary/artwork").canonicalFilePath() && !file.canonicalPath().isEmpty())
                result.media=preparedPicture(file.canonicalFilePath(),{256,256});
            result.mediaIcon=preparedPicture(state+"/magi/lock-auxiliary/media-icon.png",{96,96});
            display["artwork"]=!result.media.isNull();display["icon"]=!result.mediaIcon.isNull();result.values["media"]=display;
        }
    }
    return before!=values.value("media");
}
void VisualData::prepareWallpaper(const QImage& source) {
    wallpaper=values.value("lockScreen").toMap().value("effects").toMap().value("blur",true).toBool() ? blurWallpaper(source) : source;
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
static VisualData& currentSnapshot() {
    static auto snapshot=VisualData::load(QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)+"/quickshell/magi",
        qEnvironmentVariable("XDG_STATE_HOME",QDir::homePath()+"/.local/state"),
        QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation));
    return snapshot;
}
const VisualData& VisualData::current() { return currentSnapshot(); }
bool VisualData::refreshCurrentMedia() {
    return currentSnapshot().refreshMedia(qEnvironmentVariable("XDG_STATE_HOME",QDir::homePath()+"/.local/state"));
}
}
