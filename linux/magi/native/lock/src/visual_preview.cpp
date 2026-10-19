#include "presentation.hpp"
#include "wallpaper_blur.hpp"
#include <QPainter>
#include <QElapsedTimer>
#include <QGuiApplication>
#include <QQuickWindow>
#include <QDir>
#include <QTextStream>
// Separate offline executable: no Wayland owner, logind adapter, request wrapper,
// auth controller instance, input handler or worker. It writes synthetic PNGs only.
int main(int argc, char** argv) {
    qputenv("QT_QPA_PLATFORM","offscreen");
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);
    QGuiApplication app(argc,argv);
    if (argc!=2) { QTextStream(stderr)<<"Usage: magi-lock-preview OUTPUT_DIRECTORY\n"; return 2; }
    QDir directory(QString::fromLocal8Bit(argv[1]));
    if (!directory.mkpath(".")) return 2;
    QElapsedTimer timer; timer.start();
    const auto live=magi::VisualData::current();
    QTextStream(stdout)<<"Asset decode + cached blur: "<<timer.elapsed()<<" ms\n";
    auto plain=live; plain.wallpaper={}; plain.avatar={};
    auto bright=live;
    QImage synthetic(1920,1080,QImage::Format_RGB32); synthetic.fill(Qt::white);
    {
        QPainter painter(&synthetic);
        painter.fillRect(0,0,600,1080,QColor("#ffdd55"));
        painter.fillRect(1320,0,600,1080,QColor("#80eeff"));
        for(int y=0;y<1080;y+=24) for(int x=0;x<1920;x+=24)
            if((x/24+y/24)%2) painter.fillRect(x,y,12,12,QColor("#202020"));
    }
    timer.restart(); bright.prepareWallpaper(synthetic);
    QTextStream(stdout)<<"Synthetic bright blur: "<<timer.elapsed()<<" ms\n";
    auto longName=live; longName.values["displayName"]="Alexandra Very Long Display Identity With Multiple Family Names";
    struct Scene { const char* name; QSize size; unsigned count; magi::AuthState state; bool caps; const magi::VisualData* data; };
    const Scene scenes[]={
        {"ready-laptop",{1920,1080},0,magi::AuthState::Editing,false,&live},
        {"ready-external",{2560,1440},0,magi::AuthState::Editing,false,&live},
        {"typing-external",{2560,1440},8,magi::AuthState::Editing,false,&live},
        {"verifying",{1920,1080},0,magi::AuthState::Authenticating,false,&live},
        {"failed",{1920,1080},0,magi::AuthState::Failed,true,&live},
        {"missing-assets-portrait",{360,640},511,magi::AuthState::Editing,true,&plain},
        {"unavailable",{1920,1080},0,magi::AuthState::WorkerError,false,&live},
        {"bright-wallpaper",{1920,1080},0,magi::AuthState::Editing,false,&bright},
        {"max-credential-count",{1920,1080},511,magi::AuthState::Editing,false,&live},
        {"long-username",{1920,1080},0,magi::AuthState::Editing,false,&longName}};
    for(const auto& scene:scenes) {
        QImage image(scene.size,QImage::Format_RGB32);
        if(!magi::Presentation::render(image,"Preview","Locked","VISUAL PREVIEW",{},
              {scene.count,true,scene.caps,scene.state},scene.data)
            || !image.save(directory.filePath(QString::fromLatin1(scene.name)+".png"))) return 1;
    }
    QTextStream(stdout)<<"10 offline synthetic previews rendered; no session lock or PAM\n";
}
