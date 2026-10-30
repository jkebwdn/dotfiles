#include "visual_data.hpp"
#include <QGuiApplication>
#include <QQuickWindow>
#include <QElapsedTimer>
#include <iostream>
#include "presentation.hpp"
#include <QTemporaryDir>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDateTime>
#include <QCryptographicHash>
#include <cassert>
static void write(const QString& path,const QJsonObject& value) {QFile f(path);assert(f.open(QIODevice::WriteOnly));f.write(QJsonDocument(value).toJson());}
int main(int argc,char** argv) {
 QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);QGuiApplication app(argc,argv);QTemporaryDir t;assert(t.isValid());
 const auto config=t.path()+"/config",state=t.path()+"/state",data=t.path()+"/data",cache=t.path()+"/cache";
 for(const auto& p:{config,state+"/magi/lock-auxiliary",data,cache+"/magi/weather",state+"/magi/lock-auxiliary/artwork"})assert(QDir().mkpath(p));
 qputenv("XDG_CACHE_HOME",cache.toUtf8());
 QJsonObject settings{{"weather",QJsonObject{{"enabled",true},{"location","Sample city"},{"units","metric"}}},
 {"lockScreen",QJsonObject{{"elements",QJsonObject{{"weather",QJsonObject{{"visible",true}}},{"media",QJsonObject{{"visible",true}}}}},{"effects",QJsonObject{{"location",false},{"depth",true}}}}}};
 write(config+"/settings.json",settings);
 auto empty=magi::VisualData::load(config,state,data);assert(!empty.values.contains("weather")&&!empty.values.contains("media")&&empty.depth.isNull());
 const auto now=QDateTime::currentSecsSinceEpoch();
 QJsonObject weather{{"key",QString::fromLatin1(QCryptographicHash::hash("Sample city",QCryptographicHash::Sha256).toHex())},{"observed",now},{"temperature",12},{"code",2},{"place",QJsonObject{{"name","Sample city, Region"},{"latitude",12.12345}}}};
 write(cache+"/magi/weather/current.json",weather);
 QImage image(32,32,QImage::Format_ARGB32);image.fill(Qt::red);assert(image.save(state+"/magi/lock-auxiliary/artwork/test.png"));
 QJsonObject media{{"observed",now},{"title","Sample track"},{"artist","Sample artist"},{"artwork",state+"/magi/lock-auxiliary/artwork/test.png"}};
 write(state+"/magi/lock-auxiliary/media.json",media);
 auto good=magi::VisualData::load(config,state,data);
 assert(good.values["weather"].toMap()["temperature"]=="12°C");assert(!good.values["weather"].toMap().contains("location"));
 assert(good.values["media"].toMap()["title"]=="Sample track"&&!good.media.isNull());
 // Refresh changed metadata without reloading the immutable wallpaper/avatar snapshot.
 const auto wallpaperKey=good.wallpaper.cacheKey();
 media["title"]="Next track";write(state+"/magi/lock-auxiliary/media.json",media);
 assert(good.refreshMedia(state));assert(good.values["media"].toMap()["title"]=="Next track");
 assert(!good.refreshMedia(state));assert(good.wallpaper.cacheKey()==wallpaperKey);
 QFile::remove(state+"/magi/lock-auxiliary/media.json");assert(good.refreshMedia(state));assert(!good.values.contains("media"));
 media["title"]="Sample track";write(state+"/magi/lock-auxiliary/media.json",media);
 assert(good.refreshMedia(state));
 media["artwork"]="https://invalid/art.png";write(state+"/magi/lock-auxiliary/media.json",media);
 auto remote=magi::VisualData::load(config,state,data);assert(remote.media.isNull()&&remote.values.contains("media"));
 weather["observed"]=now-10801;media["observed"]=now-10801;
 write(cache+"/magi/weather/current.json",weather);write(state+"/magi/lock-auxiliary/media.json",media);
 auto stale=magi::VisualData::load(config,state,data);assert(!stale.values.contains("weather")&&!stale.values.contains("media"));
 // Prepared depth requires a matching wallpaper, bounded decode and alpha.
 assert(QDir().mkpath(data+"/magi/lock-depth"));assert(QDir().mkpath(state+"/magi/wallpaper"));
 QImage wall(160,90,QImage::Format_RGB32);wall.fill(Qt::blue);assert(wall.save(data+"/wall.png"));
 write(state+"/magi/wallpaper/state.json",{{"version",1},{"shared",QJsonObject{{"path",data+"/wall.png"}}}});
 const QFileInfo wallInfo(data+"/wall.png");
 write(data+"/magi/lock-depth/current.json",{{"wallpaper",data+"/wall.png"},{"size",wallInfo.size()},{"modified",wallInfo.lastModified().toSecsSinceEpoch()}});
 QImage mask(96,54,QImage::Format_ARGB32);mask.fill(Qt::transparent);mask.setPixelColor(40,40,Qt::red);assert(mask.save(data+"/magi/lock-depth/subject.png"));
 assert(!magi::VisualData::load(config,state,data).depth.isNull());
 QImage wrong(96,96,QImage::Format_ARGB32);wrong.fill(Qt::transparent);assert(wrong.save(data+"/magi/lock-depth/subject.png"));
 assert(magi::VisualData::load(config,state,data).depth.isNull());
 QFile invalid(data+"/magi/lock-depth/subject.png");assert(invalid.open(QIODevice::WriteOnly));invalid.write("bad image");invalid.close();
 assert(magi::VisualData::load(config,state,data).depth.isNull());
 // Real software presenter, synthetic data only. Baseline and enriched timing.
 QJsonObject elements;
 int z=-2;
 for(const auto& id:{"weather","media","time","identity","authentication"}) elements[id]=QJsonObject{{"anchor","center"},{"offsetX",0},{"offsetY",0},{"size",1},{"visible",true},{"alignment","center"},{"z",z++}};
 QJsonObject layout{{"layoutVersion",1},{"preset","custom"},{"space","screen"},{"elements",elements}};
 QImage frame(1920,1080,QImage::Format_RGB32);QElapsedTimer elapsed;
 auto sample=good;sample.depth=mask;sample.values["depthAvailable"]=true;
 assert(magi::Presentation::render(frame,"warmup","Locked","",{}, {},&empty));
 elapsed.start();
 for(int i=0;i<5;++i)assert(magi::Presentation::render(frame,"fixture","Locked","",{}, {},&empty));
 const auto plainTime=elapsed.elapsed();elapsed.restart();
 for(const auto& style:{"dots","line","segments","ring","minimal"}) {
  layout["effects"]=QJsonObject{{"credential",style},{"avatar","glow"},{"depth",true},{"media","artwork"}};
  sample.values["lockScreen"]=layout;
  magi::AuthPresentation auth;auth.count=6;
  assert(magi::Presentation::render(frame,"fixture","Locked","",{},auth,&sample));
 }
 std::cout<<"Five plain frames: "<<plainTime<<" ms; five enriched frames: "<<elapsed.elapsed()<<" ms\n";
 for(const auto& style:{"dots","line","segments","ring","minimal"}) {
  const QByteArray source=QByteArray("import QtQuick\nimport \"qrc:/magi-lock/qml\" as Lock\nItem {id:root;property int characterCount:0;Lock.LockTokens{id:tokens} Lock.LockCredential{anchors.centerIn:parent;width:300;tokens:tokens;characterCount:root.characterCount;style:\"")+style+"\"}}";
  // Only synthetic counts reach the presenter; never password text. Every style
  // gives incremental editing feedback with the existing dots cap/overflow policy.
  magi::AuthPresentation auth;auth.count=0;
  assert(magi::Presentation::render(frame,"fixture","Locked","",source,auth,&empty));const auto cleared=frame.copy();
  auth.count=1;assert(magi::Presentation::render(frame,"fixture","Locked","",source,auth,&empty));const auto one=frame.copy();assert(one!=cleared);
  auth.count=2;assert(magi::Presentation::render(frame,"fixture","Locked","",source,auth,&empty));assert(frame!=one);
  auth.count=1;assert(magi::Presentation::render(frame,"fixture","Locked","",source,auth,&empty));assert(frame==one);
  auth.count=17;assert(magi::Presentation::render(frame,"fixture","Locked","",source,auth,&empty));const auto capped=frame.copy();
  auth.count=100;assert(magi::Presentation::render(frame,"fixture","Locked","",source,auth,&empty));assert(frame==capped);
  auth.count=0;assert(magi::Presentation::render(frame,"fixture","Locked","",source,auth,&empty));assert(frame==cleared);
 }
 settings["lockScreen"]=QJsonObject{};write(config+"/settings.json",settings);
 assert(!magi::VisualData::load(config,state,data).values.contains("media"));
}
