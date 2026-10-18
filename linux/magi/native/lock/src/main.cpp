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
#include <sys/resource.h>
#include <unistd.h>

int main(int argc, char** argv) {
    std::vector<std::string_view> arguments;
    for (int i = 1; i < argc; ++i) arguments.emplace_back(argv[i]);
    const auto options = magi::parseOptions(arguments);
    if (!options.error.empty()) { std::cerr << options.error << '\n'; return 64; }
    if (options.buildInfo) {
        std::cout << "MAGI lock protocol proof; development-unlock="
                  << MAGI_LOCK_DEVELOPMENT_UNLOCK << "; failure-injection=" << MAGI_LOCK_FAILURE_INJECTION << "; native-authentication=1; explicit --authenticate required\n";
        return 0;
    }
    if (options.help) {
#if MAGI_LOCK_FAILURE_INJECTION
        std::cout << "--development-auth-failure=crash|hang  SYNTHETIC ONLY; requires authentication and emergency timer\n";
#endif
        std::cout << "MAGI lock protocol proof — NOT a production locker\n"
                     "--build-info  Offline build information; no display connection\n"
                     "--acquire-session-lock  Acquire REAL lock; requires operator approval\n"
                     "--authenticate  Enable native keyboard and private PAM worker\n";
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
        std::cout << "--unsafe-development-unlock-after=N  REQUIRED with acquisition in this\n"
                     "development build; auto-unlock N=10..300 seconds AFTER confirmation\n";
#else
        std::cout << "This build has no unauthenticated unlock. Authenticated proof still requires approval.\n";
#endif
        return 0;
    }
    std::cerr << "REAL SESSION LOCK REQUESTED. Explicit proof, not production routing.\n";
    const rlimit coreLimit{0, 0};
    if (setrlimit(RLIMIT_CORE, &coreLimit) || getuid() == 0 || getuid() != geteuid() || getgid() != getegid()) {
        std::cerr << "Ordinary-user/core-limit validation failed\n"; return 64;
    }
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
    const std::string configuredWorker = MAGI_LOCK_AUTH_WORKER;
    auto worker = configuredWorker.empty()
        ? (QCoreApplication::applicationDirPath() + "/magi-lock-auth").toStdString() : configuredWorker;
    int authTimeoutMs = 120000;
#if MAGI_LOCK_FAILURE_INJECTION
    if (!options.failureFixture.empty()) {
        worker = std::string(MAGI_LOCK_FAILURE_DIRECTORY) + "/fixture-" + options.failureFixture;
        authTimeoutMs = 5000;
        qWarning("SYNTHETIC FAILURE INJECTION: no PAM; use fake input only");
    }
#endif
    if (options.authenticate && access(worker.c_str(), X_OK)) { qCritical("Auth worker unavailable; no lock requested"); return 64; }
    magi::WaylandOwner owner(options.developmentSeconds, options.authenticate, worker, authTimeoutMs);
    QTimer::singleShot(0, &app, [&owner] { if (!owner.start()) QCoreApplication::exit(2); });
    return app.exec();
}
