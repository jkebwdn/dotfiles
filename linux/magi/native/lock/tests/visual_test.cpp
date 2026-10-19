#include "presentation.hpp"
#include "wallpaper_blur.hpp"
#include <QGuiApplication>
#include <QQuickWindow>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QTemporaryDir>
#include <QFile>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QElapsedTimer>
#include <iostream>
#include <memory>
#define CHECK(x) do { if (!(x)) { std::cerr<<"Visual check failed: "<<__LINE__<<"\n"; return 1; } } while(false)
int main(int argc,char** argv) {
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);
    QGuiApplication app(argc,argv);
    QTemporaryDir temp; CHECK(temp.isValid());
    auto write=[&](QString name,QByteArray contents) { QFile f(temp.path()+name); if(!f.open(QIODevice::WriteOnly)) return false; return f.write(contents)==contents.size(); };
    auto data=magi::VisualData::load(temp.path(),temp.path(),temp.path());
    CHECK(data.wallpaper.isNull() && data.avatar.isNull());
    CHECK(data.values["background"]=="#1e1e2e");
    CHECK(write("/settings.json",R"({"profile":{"displayName":"<b>literal name</b>","avatar":"avatar:../../etc/passwd"},"calendar":{"timeFormat":"12h"},"appearance":{"theme":"custom"}})"));
    QDir(temp.path()).mkpath("theme/palettes");
    QDir(temp.path()).mkpath("magi/wallpaper");
    CHECK(write("/theme/palettes/registry.json",R"({"formatVersion":1,"themes":[{"id":"custom","roles":{"background":"#ffffff","surface":"#eeeeee","text":"#111111","subtext":"#222222","accent":"#332244","danger":"#aa0000","warning":"#664400"}}]})"));
    CHECK(write("/magi/wallpaper/state.json",R"({"version":1,"shared":{"path":"https://invalid/image"}})"));
    data=magi::VisualData::load(temp.path(),temp.path(),temp.path());
    CHECK(data.values["background"]=="#ffffff" && data.values["timeFormat"]=="12h");
    CHECK(data.avatar.isNull() && data.wallpaper.isNull());
    CHECK(write("/theme/palettes/registry.json","invalid"));
    data=magi::VisualData::load(temp.path(),temp.path(),temp.path());
    CHECK(data.values["background"]=="#1e1e2e");
    CHECK(write("/broken.png","not an image"));
    CHECK(write("/magi/wallpaper/state.json",QJsonDocument(QJsonObject{{"version",1},{"shared",QJsonObject{{"path",temp.path()+"/broken.png"}}}}).toJson()));
    data=magi::VisualData::load(temp.path(),temp.path(),temp.path()); CHECK(data.wallpaper.isNull());
    QImage art(128,64,QImage::Format_RGB32); art.fill(Qt::green); CHECK(art.save(temp.path()+"/art.png"));
    CHECK(write("/magi/wallpaper/state.json",QJsonDocument(QJsonObject{{"version",1},{"shared",QJsonObject{{"path",temp.path()+"/art.png"}}}}).toJson()));
    data=magi::VisualData::load(temp.path(),temp.path(),temp.path()); CHECK(!data.wallpaper.isNull());
    CHECK(!data.values["displayName"].toString().isEmpty());
    CHECK(magi::blurWallpaper({}).isNull());
    QImage bright(1920,1080,QImage::Format_RGB32); bright.fill(Qt::white);
    data.prepareWallpaper(bright);
    CHECK(data.wallpaper.size()==QSize(960,540));
    CHECK(data.values["wallpaperTint"].toDouble()==magi::wallpaperMaximumTint);
    CHECK(data.wallpaper.pixelColor(320,180)==QColor(Qt::white));
    auto dark=data;
    QImage darkImage(64,64,QImage::Format_RGB32); darkImage.fill(Qt::black);
    dark.prepareWallpaper(darkImage); CHECK(dark.values["wallpaperTint"].toDouble()==magi::wallpaperTint);
    darkImage.fill(QColor("#808080")); dark.prepareWallpaper(darkImage);
    CHECK(dark.values["wallpaperTint"].toDouble()>magi::wallpaperTint && dark.values["wallpaperTint"].toDouble()<magi::wallpaperMaximumTint);
    dark.prepareWallpaper({}); CHECK(dark.values["wallpaperTint"].toDouble()==magi::wallpaperTint && dark.wallpaper.isNull());
    QImage detail(640,360,QImage::Format_RGB32);
    for(int y=0;y<detail.height();++y) for(int x=0;x<detail.width();++x)
        detail.setPixel(x,y,((x/2+y/2)%2)?qRgb(255,255,255):qRgb(0,0,0));
    const auto blurred=magi::blurWallpaper(detail);
    int minimum=255, maximum=0;
    for(int y=60;y<300;++y) for(int x=60;x<580;++x) {
        const auto value=qRed(blurred.pixel(x,y)); minimum=std::min(minimum,value); maximum=std::max(maximum,value);
    }
    CHECK(maximum-minimum<8 && minimum>100 && maximum<150);
    const auto cacheKey=data.wallpaper.cacheKey();
    const auto cachedTint=data.values["wallpaperTint"];
    CHECK(&magi::VisualData::current()==&magi::VisualData::current());
    unsigned renders=0;
    QElapsedTimer elapsed; elapsed.start();
    // Each render destroys its scene, just as output replacement does. Logical
    // geometry is authoritative at every compositor scale; no scale multiplication.
    for (auto size:{QSize(800,600),QSize(1920,1080),QSize(2560,1440),QSize(360,640)}) {
        for (auto state:{magi::AuthState::Editing,magi::AuthState::Authenticating,magi::AuthState::Failed,magi::AuthState::WorkerError}) {
            QImage image(size,QImage::Format_RGB32);
            CHECK(magi::Presentation::render(image,"synthetic output","Locked","",{}, {511,true,true,state},&data));
            CHECK(qAlpha(image.pixel(0,0))==255); ++renders;
        }
    }
    CHECK(data.wallpaper.cacheKey()==cacheKey && data.values["wallpaperTint"]==cachedTint);
    QQmlEngine engine;
    QQmlComponent component(&engine,QUrl("qrc:/magi-lock/qml/LockScreen.qml"));
    CHECK(component.isReady());
    std::unique_ptr<QObject> root(component.create()); CHECK(root);
    CHECK(root->metaObject()->indexOfProperty("password")==-1);
    CHECK(root->metaObject()->indexOfProperty("credential")==-1);
    CHECK(root->metaObject()->indexOfProperty("authController")==-1);
    root->setProperty("visual",data.values);
    root->setProperty("wallpaperAvailable",true);
    auto* design=root->findChild<QObject*>("visualTokens"); CHECK(design);
    root->setProperty("width",1920); root->setProperty("height",1080);
    CHECK(design->property("visualScale").toDouble()==1.0);
    root->setProperty("width",2560); root->setProperty("height",1440);
    CHECK(design->property("visualScale").toDouble()>1.10 && design->property("visualScale").toDouble()<=1.15);
    root->setProperty("width",360); root->setProperty("height",640);
    CHECK(design->property("visualScale").toDouble()==0.8);
    CHECK(design->property("ink").value<QColor>()==QColor(data.values["text"].toString()));
    auto* status=root->findChild<QObject*>("displayStatus"); CHECK(status);
    root->setProperty("inputActive",true);
    root->setProperty("authStatus","Authenticating"); CHECK(status->property("message")=="Verifying…");
    root->setProperty("authStatus","Authentication failed"); CHECK(status->property("failed").toBool());
    root->setProperty("authStatus","Unsupported PAM conversation"); CHECK(status->property("message")=="Authentication unavailable");
    root->setProperty("authStatus","Enter password, then Enter"); CHECK(status->property("message")=="Enter your password");
    root->setProperty("characterCount",5); CHECK(status->property("message")=="Press Enter to unlock");
    for (const auto* state:{"Authenticating","Authentication failed","Authentication unavailable"}) {
        root->setProperty("authStatus",state); CHECK(!status->property("message").toString().contains("Press Enter"));
    }
    root->setProperty("capsKnown",false); CHECK(!status->property("capsKnown").toBool());
    root->setProperty("authStatus","Keyboard state unavailable: press and release Shift");
    CHECK(status->property("message")=="Keyboard state unavailable: press and release Shift");
    root->setProperty("capsKnown",true); CHECK(status->property("capsKnown").toBool());
    auto* dot=root->findChild<QObject*>("credentialDots"); CHECK(dot);
    auto* row=dot->findChild<QObject*>("dotRow"); CHECK(row);
    const auto areaHeight=dot->property("height");
    for (auto count:{-1,0,1,16,17,511,1000000}) {
        dot->setProperty("characterCount",count);
        CHECK(dot->property("visibleCount").toInt()==qBound(0,count,16));
        CHECK(row->property("visible").toBool()==(count>0));
        CHECK(dot->property("height")==areaHeight && dot->property("implicitHeight").toInt()==26);
    }
    std::cout<<renders<<" logical-size/state recreation renders; asset/palette rejection and count boundaries passed in "<<elapsed.elapsed()<<" ms\n";
}
