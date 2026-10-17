#include "options.hpp"
#include "wayland_owner.hpp"
#include <QGuiApplication>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QTimer>
#include <QDebug>
#include <csignal>
#include <iostream>
#include <string_view>
#include <vector>

int main(int argc, char** argv) {
    std::vector<std::string_view> arguments;
    for (int i = 1; i < argc; ++i) arguments.emplace_back(argv[i]);
    const auto options = magi::parseOptions(arguments);
    if (!options.error.empty()) { std::cerr << options.error << '\n'; return 64; }
    if (options.buildInfo) {
        std::cout << "MAGI lock protocol proof; development-unlock="
                  << MAGI_LOCK_DEVELOPMENT_UNLOCK << "; no authentication\n";
        return 0;
    }
    if (options.help) {
        std::cout << "MAGI lock protocol proof — NOT a production locker\n"
                     "--build-info  Offline build information; no display connection\n"
                     "--acquire-session-lock  Acquire REAL lock; requires operator approval\n";
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
        std::cout << "--unsafe-development-unlock-after=N  REQUIRED with acquisition in this\n"
                     "development build; auto-unlock N=10..300 seconds AFTER confirmation\n";
#else
        std::cout << "This build has NO UNLOCK/AUTHENTICATION. Do not run it on your session.\n";
#endif
        return 0;
    }
    std::cerr << "REAL SESSION LOCK REQUESTED. This is a protocol proof, not authentication.\n";
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    std::cerr << "WARNING: UNSAFE DEVELOPMENT UNLOCK ENABLED for " << options.developmentSeconds
              << " seconds after compositor confirmation. Never deploy.\n";
#endif
    // Termination never unlocks. Reset inherited dispositions; SIGPIPE is not
    // an unlock route either. Default process death leaves protection to server.
    std::signal(SIGINT, SIG_DFL);
    std::signal(SIGTERM, SIG_DFL);
    std::signal(SIGUSR1, SIG_DFL);
    std::signal(SIGPIPE, SIG_IGN);
    // Qt renders OFFSCREEN ONLY. Do not let platform/plugin CLI options open a
    // second compositor connection or produce ordinary windows. No argv is
    // passed through to Qt, no QQml debugging enablement or arbitrary QML URL.
    qputenv("QT_QPA_PLATFORM", "offscreen");
    qputenv("QT_QUICK_BACKEND", "software");
    int qtArgc = 1;
    char* qtArgv[] = {argv[0], nullptr};
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);
    QGuiApplication app(qtArgc, qtArgv);
    app.setQuitOnLastWindowClosed(false);
    qInfo() << "Protocol proof PID" << QCoreApplication::applicationPid();
    magi::WaylandOwner owner(options.developmentSeconds);
    QTimer::singleShot(0, &app, [&owner] { if (!owner.start()) QCoreApplication::exit(2); });
    return app.exec();
}
