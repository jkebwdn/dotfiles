#pragma once
#include "controller.hpp"
#include "auth_controller.hpp"
#include "native_input.hpp"
#include <QObject>
#include <QSocketNotifier>
#include <QTimer>
#include <memory>
#include <map>
#include <vector>
#include <wayland-client.h>
#include "session-lock.h"
namespace magi {
class WaylandOwner final : public QObject, public Backend {
public:
    explicit WaylandOwner(unsigned developmentSeconds, bool authenticate, std::string worker, int authTimeoutMs = 120000);
    ~WaylandOwner() override;
    bool start(); // The ONLY entry point which can connect/request a real lock.
    bool requestLock() override;
    bool createSurface(std::uint32_t id) override;
    void removeSurface(std::uint32_t id) override;
    FrameResult present(std::uint32_t id, Configure configure, bool acknowledge = true) override;
    void diagnostic(std::string_view message) override;
    void disconnect() override;
    void authenticatedUnlockAndSync() override;
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    void developmentUnlockAndSync() override;
#endif
private:
    struct NativeOutput {
        WaylandOwner* owner = nullptr;
        std::uint32_t id = 0;
        wl_output* output = nullptr;
        wl_surface* surface = nullptr;
        ext_session_lock_surface_v1* lockSurface = nullptr;
        int scale = 1;
        int transform = WL_OUTPUT_TRANSFORM_NORMAL;
        unsigned configureLogs = 0;
        bool fallbackLogged = false;
    };
    struct Buffer {
        WaylandOwner* owner = nullptr;
        std::uint32_t outputId = 0;
        wl_buffer* proxy = nullptr;
        void* mapping = nullptr;
        std::size_t size = 0;
        bool busy = false;
        ~Buffer();
    };
    void flush();
    void unlockAndSync();
    bool ownsSurface(wl_surface* surface) const;
    static const wl_seat_listener seatListener;
    static const wl_keyboard_listener keyboardListener;
    void dispatch();
    void stopFailure(const char* message);
    void releaseBuffer(Buffer* buffer);
    static void registryGlobal(void*, wl_registry*, std::uint32_t, const char*, std::uint32_t);
    static void registryRemove(void*, wl_registry*, std::uint32_t);
    static void surfaceConfigure(void*, ext_session_lock_surface_v1*, std::uint32_t, std::uint32_t, std::uint32_t);
    static void lockConfirmed(void*, ext_session_lock_v1*);
    static void lockFinished(void*, ext_session_lock_v1*);
    static void discoveryDone(void*, wl_callback*, std::uint32_t);
    static void syncDone(void*, wl_callback*, std::uint32_t);
    static void bufferReleased(void*, wl_buffer*);
    static const wl_registry_listener registryListener;
    static const wl_output_listener outputListener;
    static const ext_session_lock_surface_v1_listener surfaceListener;
    static const ext_session_lock_v1_listener lockListener;
    static const wl_callback_listener discoveryListener;
    static const wl_callback_listener syncListener;
    static const wl_buffer_listener bufferListener;
    wl_seat* seat_ = nullptr;
    wl_keyboard* keyboard_ = nullptr;
    wl_surface* focusedSurface_ = nullptr;
    std::uint32_t seatId_ = 0;
    std::array<unsigned, 4> modifiers_{};
    bool haveModifiers_ = false;
    bool repaintQueued_ = false;
    bool authenticate_;
    AuthController auth_;
    NativeInput input_;
    wl_display* display_ = nullptr;
    wl_registry* registry_ = nullptr;
    wl_compositor* compositor_ = nullptr;
    wl_shm* shm_ = nullptr;
    ext_session_lock_manager_v1* manager_ = nullptr;
    ext_session_lock_v1* lock_ = nullptr;
    wl_callback* sync_ = nullptr;
    std::uint32_t compositorId_ = 0, shmId_ = 0, managerId_ = 0;
    std::map<std::uint32_t, std::unique_ptr<NativeOutput>> nativeOutputs_;
    std::vector<std::unique_ptr<Buffer>> buffers_;
    std::unique_ptr<QSocketNotifier> reader_, writer_;
    QTimer deadline_;
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    QTimer developmentTimer_;
#endif
    unsigned developmentSeconds_;
    bool stopping_ = false;
    Controller controller_; // Must be cleaned while Backend still exists.
};
}
