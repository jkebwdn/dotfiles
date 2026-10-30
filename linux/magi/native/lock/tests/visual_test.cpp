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
    auto sharp=data;
    sharp.values["lockScreen"]=QVariantMap{{"effects",QVariantMap{{"blur",false}}}};
    sharp.prepareWallpaper(detail); CHECK(sharp.wallpaper==detail);
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
    // Verify native software masking with a high-contrast real avatar input.
    auto portrait=data;portrait.avatar=QImage(192,192,QImage::Format_RGB32);portrait.avatar.fill(Qt::white);
    portrait.values["avatarRadius"]=12.0;
    QImage avatarProbe(192,192,QImage::Format_RGB32);
    CHECK(magi::Presentation::render(avatarProbe,"","","",R"(import QtQuick
Rectangle { color: "black"; Image { anchors.fill: parent; source: "image://visual/avatar" } })",{},&portrait));
    CHECK(qRed(avatarProbe.pixel(0,0))==0 && qRed(avatarProbe.pixel(96,96))==255);
    unsigned edgePixels=0;
    for(int y=0;y<24;++y)for(int x=0;x<24;++x){const int v=qRed(avatarProbe.pixel(x,y));if(v>0 && v<255)++edgePixels;}
    CHECK(edgePixels>4); // Smooth alpha transition rather than a hard raster clip.
    QImage framedProbe(124,124,QImage::Format_RGB32);
    CHECK(magi::Presentation::render(framedProbe,"","","",R"(import QtQuick
Rectangle { color: "black"; Image { anchors.fill: parent; smooth:true; source: "image://visual/avatar-frame" } })",{},&portrait));
    CHECK(qRed(framedProbe.pixel(0,0))<5);
    const auto border=QColor(portrait.values["accent"].toString());
    CHECK(std::abs(qRed(framedProbe.pixel(62,2))-border.red())<5);
    CHECK(qRed(framedProbe.pixel(62,8))==255);
    QImage iconProbe(24,24,QImage::Format_RGB32);
    CHECK(magi::Presentation::render(iconProbe,"","","",R"(import QtQuick
import "qrc:/magi-lock/qml" as Lock
Rectangle { color: "black"; Lock.LockFingerprint { anchors.centerIn: parent; width:22; height:24; nativeArtwork:true; status:"Touch fingerprint sensor"; tokens:QtObject {property color accent:"white";property color danger:"white";property color warning:"white"} } })",{},&portrait));
    unsigned iconInk=0,iconEdges=0;
    for(int y=0;y<24;++y)for(int x=0;x<24;++x){const int v=qRed(iconProbe.pixel(x,y));if(v>0)++iconInk;if(v>0 && v<255)++iconEdges;}
    CHECK(iconInk>20 && iconEdges>20); // Vector icon is visible and antialiased before native render returns.
    for(const char* state:{"waiting","retry","failed","timeout","unavailable","matched"}) {
        const QByteArray probe=QByteArray("import QtQuick\nRectangle { color: \"black\"; Image { anchors.centerIn: parent; width:22; height:22; smooth:true; source: \"image://visual/fingerprint/")+state+"\" } }";
        CHECK(magi::Presentation::render(iconProbe,"","","",probe,{},&portrait));
        unsigned ink=0;for(int y=0;y<24;++y)for(int x=0;x<24;++x)if(qRed(iconProbe.pixel(x,y))>0)++ink;
        CHECK(ink>15);
    }
    // Physical pixels increase with DPR while geometry and power hit targets stay logical.
    QImage densityProbe(100,100,QImage::Format_RGB32);densityProbe.setDevicePixelRatio(2);
    CHECK(magi::Presentation::render(densityProbe,"","","",R"(import QtQuick
Rectangle {color:"black";Rectangle{x:10;y:10;width:10;height:10;color:"white"}})",{},&portrait));
    CHECK(qRed(densityProbe.pixel(25,25))==255 && qRed(densityProbe.pixel(5,5))==0 && qRed(densityProbe.pixel(45,45))==0);
    std::array<QRectF,3> lowTargets,highTargets;
    QImage low(1920,1080,QImage::Format_RGB32),high(3840,2160,QImage::Format_RGB32);high.setDevicePixelRatio(2);
    CHECK(magi::Presentation::render(low,"","","",{},{},&portrait,&lowTargets));
    CHECK(magi::Presentation::render(high,"","","",{},{},&portrait,&highTargets));
    CHECK(lowTargets==highTargets && !highTargets[0].isEmpty());
    // First-frame glyphs must be separated, including the operator's .75 module scale.
    for(int density:{1,2}) for(double moduleScale:{.75,1.0}) {
        QImage clockProbe(600*density,124*density,QImage::Format_RGB32);clockProbe.setDevicePixelRatio(density);
        const auto probe=QByteArray("import QtQuick\nimport \"qrc:/magi-lock/qml\" as Lock\nRectangle { color: \"black\"; Lock.LockClock { width:600; fitHeight:124; scale:")+QByteArray::number(moduleScale)+R"(; transformOrigin:Item.TopLeft;alignment:"left";timeLabel:"12:09";dateLabel:"Friday, 30 October";tokens:QtObject {property string family:"JetBrainsMono Nerd Font";property color ink:"white";property color secondary:"red";property int clockSize:112;property int dateSize:17} } })";
        CHECK(magi::Presentation::render(clockProbe,"","","",probe,{},&portrait));
        int timeTop=clockProbe.height(),timeBottom=-1,dateTop=clockProbe.height(),dateBottom=-1;
        for(int y=0;y<clockProbe.height();++y)for(int x=0;x<clockProbe.width();++x){
            const auto c=clockProbe.pixelColor(x,y);
            if(c.red()>100 && c.green()>100 && c.blue()>100){timeTop=std::min(timeTop,y);timeBottom=std::max(timeBottom,y);}
            if(c.red()>100 && c.green()<40 && c.blue()<40){dateTop=std::min(dateTop,y);dateBottom=std::max(dateBottom,y);}
        }
        CHECK(timeTop<=2*density && timeBottom>timeTop && dateBottom>dateTop);
        CHECK(dateTop-timeBottom>=4*moduleScale*density);
        CHECK(std::abs(dateBottom-124*moduleScale*density)<=3*density);
    }
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
