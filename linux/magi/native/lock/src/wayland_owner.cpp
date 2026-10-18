#include "wayland_owner.hpp"
#include "presentation.hpp"
#include <QCoreApplication>
#include <QDebug>
#include <QImage>
#include <algorithm>
#include <cerrno>
#include <cstring>
#include <sys/mman.h>
#include <unistd.h>

namespace magi {
namespace {
// Local proxy disposal only: no wire requests. Used when abandoning a lock or
// after connection loss. The compositor enforces client-death policy.
template<class T> void dispose(T*& proxy) {
    if (proxy) wl_proxy_destroy(reinterpret_cast<wl_proxy*>(proxy));
    proxy = nullptr;
}
constexpr std::size_t totalBufferLimit = 256 * 1024 * 1024;
const wl_shm_listener shmListener{[](void*, wl_shm*, std::uint32_t) {}};
const wl_surface_listener wlSurfaceListener{
    [](void*, wl_surface*, wl_output*) {},
    [](void*, wl_surface*, wl_output*) {},
    [](void*, wl_surface*, std::int32_t) {},
    [](void*, wl_surface*, std::uint32_t) {}
};
}

bool WaylandOwner::ownsSurface(wl_surface* surface) const {
    if (!surface) return false;
    for (const auto& [id, output] : nativeOutputs_) { (void)id; if (output->surface == surface) return true; }
    return false;
}
const wl_seat_listener WaylandOwner::seatListener{
    [](void* data, wl_seat* seat, std::uint32_t capabilities) {
        auto& self = *static_cast<WaylandOwner*>(data);
        if (capabilities & WL_SEAT_CAPABILITY_KEYBOARD) {
            if (!self.keyboard_) {
                self.keyboard_ = wl_seat_get_keyboard(seat);
                if (self.keyboard_) wl_keyboard_add_listener(self.keyboard_, &keyboardListener, &self);
            }
        } else if (self.keyboard_) {
            self.focusedSurface_ = nullptr; self.input_.focus(false);
            wl_keyboard_release(self.keyboard_); self.keyboard_ = nullptr;
        }
    },
    [](void*, wl_seat*, const char*) {}
};
const wl_keyboard_listener WaylandOwner::keyboardListener{
    [](void* data, wl_keyboard*, std::uint32_t format, int fd, std::uint32_t size) {
        auto& self = *static_cast<WaylandOwner*>(data);
        self.input_.keymap({}); self.haveModifiers_ = false;
        if (format != WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1 || !size || size > 1024*1024) { close(fd); return; }
        void* map = mmap(nullptr, size, PROT_READ, MAP_PRIVATE, fd, 0); close(fd);
        if (map == MAP_FAILED) return;
        const bool okay = self.input_.keymap({static_cast<const char*>(map), size});
        munmap(map, size);
        if (okay) qInfo("Native keyboard keymap initialized");
        else qWarning("Native keyboard unavailable; remaining locked");
        self.input_.focus(okay && self.ownsSurface(self.focusedSurface_) && self.controller_.state() == State::Locked);
    },
    [](void* data, wl_keyboard*, std::uint32_t, wl_surface* surface, wl_array* keys) {
        auto& self = *static_cast<WaylandOwner*>(data);
        self.haveModifiers_ = false;
        self.focusedSurface_ = self.ownsSurface(surface) ? surface : nullptr;
        std::span<const unsigned> held;
        if (keys && keys->size <= 768*sizeof(unsigned) && keys->size % sizeof(unsigned) == 0)
            held = {static_cast<const unsigned*>(keys->data), keys->size/sizeof(unsigned)};
        // An enter can refer to a surface removed earlier in the event batch.
        // Suspend input in that case without cancelling the session attempt.
        self.input_.focus(self.focusedSurface_ && self.controller_.state() == State::Locked, held, true);
    },
    [](void* data, wl_keyboard*, std::uint32_t, wl_surface*) {
        auto& self = *static_cast<WaylandOwner*>(data);
        self.focusedSurface_ = nullptr; self.input_.focus(false, {}, true);
    },
    [](void* data, wl_keyboard*, std::uint32_t, std::uint32_t, std::uint32_t key, std::uint32_t state) {
        auto& self = *static_cast<WaylandOwner*>(data);
        if (!self.stopping_ && self.controller_.state() == State::Locked && self.ownsSurface(self.focusedSurface_))
            self.input_.key(key, state == WL_KEYBOARD_KEY_STATE_PRESSED);
    },
    [](void* data, wl_keyboard*, std::uint32_t, std::uint32_t depressed, std::uint32_t latched, std::uint32_t locked, std::uint32_t group) {
        auto& self = *static_cast<WaylandOwner*>(data);
        self.modifiers_ = {depressed, latched, locked, group}; self.haveModifiers_ = true;
        self.input_.modifiers(depressed, latched, locked, group);
    },
    [](void*, wl_keyboard*, std::int32_t, std::int32_t) {} // No key repeat in this proof.
};

const wl_registry_listener WaylandOwner::registryListener{registryGlobal, registryRemove};
const ext_session_lock_surface_v1_listener WaylandOwner::surfaceListener{surfaceConfigure};
const ext_session_lock_v1_listener WaylandOwner::lockListener{lockConfirmed, lockFinished};
const wl_callback_listener WaylandOwner::discoveryListener{discoveryDone};
const wl_callback_listener WaylandOwner::syncListener{syncDone};
const wl_buffer_listener WaylandOwner::bufferListener{bufferReleased};
const wl_output_listener WaylandOwner::outputListener{
    [](void* data, wl_output*, int32_t, int32_t, int32_t, int32_t, int32_t,
       const char*, const char*, int32_t transform) {
        static_cast<NativeOutput*>(data)->transform = transform;
    },
    [](void*, wl_output*, uint32_t, int32_t, int32_t, int32_t) {},
    [](void*, wl_output*) {},
    [](void* data, wl_output*, int32_t scale) { static_cast<NativeOutput*>(data)->scale = scale; },
    [](void* data, wl_output*, const char* name) { static_cast<NativeOutput*>(data)->connector = name ? name : ""; },
    [](void*, wl_output*, const char*) {}
};
WaylandOwner::Buffer::~Buffer() {
    // Caller must dispose proxy first on disconnect. Destroying a busy buffer
    // during output removal is allowed; backing store remains compositor-held.
    if (proxy) wl_buffer_destroy(proxy);
    if (mapping && mapping != MAP_FAILED) munmap(mapping, size);
}
WaylandOwner::WaylandOwner(unsigned seconds, bool authenticate, std::string worker, int authTimeoutMs)
    : authenticate_(authenticate), auth_(std::move(worker), authTimeoutMs), input_(auth_), developmentSeconds_(seconds), controller_(*this) {
    auth_.changed = [this] {
        if (stopping_ || repaintQueued_) return;
        repaintQueued_ = true;
        QTimer::singleShot(16, this, [this] {
            repaintQueued_ = false;
            if (!stopping_) { controller_.refresh(); flush(); }
        });
    };
    auth_.succeeded = [this](std::uint64_t generation) {
        if (!stopping_ && authenticate_ && controller_.authenticatedUnlock(auth_, generation)) flush();
    };
    deadline_.setSingleShot(true);
    connect(&deadline_, &QTimer::timeout, this, [this] {
        stopFailure("Protocol deadline exceeded; disconnecting WITHOUT unlock");
    });
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    developmentTimer_.setSingleShot(true);
    developmentTimer_.setTimerType(Qt::PreciseTimer);
    connect(&developmentTimer_, &QTimer::timeout, this, [this] {
        if (!stopping_ && controller_.developmentUnlock(developmentSeconds_ != 0)) flush();
    });
#endif
}
WaylandOwner::~WaylandOwner() { controller_.cleanup(); }
bool WaylandOwner::start() {
    display_ = wl_display_connect(nullptr);
    if (!display_) { qCritical("Cannot connect to Wayland display; no lock requested"); return false; }
    registry_ = wl_display_get_registry(display_);
    if (!registry_) { stopFailure("Cannot create registry"); return false; }
    wl_registry_add_listener(registry_, &registryListener, this);
    sync_ = wl_display_sync(display_);
    if (!sync_) { stopFailure("Cannot request registry sync"); return false; }
    wl_callback_add_listener(sync_, &discoveryListener, this);
    reader_ = std::make_unique<QSocketNotifier>(wl_display_get_fd(display_), QSocketNotifier::Read);
    writer_ = std::make_unique<QSocketNotifier>(wl_display_get_fd(display_), QSocketNotifier::Write);
    writer_->setEnabled(false);
    connect(reader_.get(), &QSocketNotifier::activated, this, [this] { dispatch(); });
    connect(writer_.get(), &QSocketNotifier::activated, this, [this] { flush(); });
    deadline_.start(5000);
    flush();
    return !stopping_;
}
void WaylandOwner::dispatch() {
    if (stopping_) return;
    // This process is the sole reader of this display; Qt uses offscreen QPA.
    // dispatch is called ONLY for a readable socket and no nested event loop
    // or roundtrip is used. No Qt Wayland plugin/second dispatch thread exists.
    if (wl_display_dispatch(display_) < 0) {
        const wl_interface* interface = nullptr;
        std::uint32_t object = 0;
        const auto code = wl_display_get_protocol_error(display_, &interface, &object);
        qCritical() << "Wayland disconnect/error" << wl_display_get_error(display_)
                    << "protocol code" << code << "object" << object
                    << "interface" << (interface ? interface->name : "none");
        controller_.disconnected();
        stopFailure("Compositor connection lost; security state cannot be transferred");
        return;
    }
    flush();
}
void WaylandOwner::flush() {
    if (stopping_ || !display_) return;
    if (wl_display_flush(display_) < 0) {
        if (errno == EAGAIN) { if (writer_) writer_->setEnabled(true); }
        else stopFailure("Wayland flush failed; no unlock requested");
    } else if (writer_) writer_->setEnabled(false);
}
void WaylandOwner::stopFailure(const char* message) {
    if (stopping_) return;
    stopping_ = true;
    qCritical() << message;
    controller_.fatal();
    deadline_.stop();
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    developmentTimer_.stop();
#endif
    if (reader_) reader_->setEnabled(false);
    if (writer_) writer_->setEnabled(false);
    // Exit after callbacks unwind. Destruction disconnects, never unlocks.
    QTimer::singleShot(0, QCoreApplication::instance(), [] { QCoreApplication::exit(2); });
}
void WaylandOwner::diagnostic(std::string_view message) {
    qWarning().noquote() << QString::fromUtf8(message.data(), qsizetype(message.size()));
}
void WaylandOwner::registryGlobal(void* data, wl_registry* registry, std::uint32_t id,
                                  const char* interface, std::uint32_t version) {
    auto& self = *static_cast<WaylandOwner*>(data);
    if (self.stopping_) return;
    if (!std::strcmp(interface, wl_compositor_interface.name) && !self.compositor_) {
        if (version < 4) { self.stopFailure("wl_compositor version >=4 required"); return; }
        self.compositor_ = static_cast<wl_compositor*>(wl_registry_bind(registry, id, &wl_compositor_interface, 4));
        self.compositorId_ = id;
    } else if (!std::strcmp(interface, wl_shm_interface.name) && !self.shm_) {
        self.shm_ = static_cast<wl_shm*>(wl_registry_bind(registry, id, &wl_shm_interface, 1));
        self.shmId_ = id;
        if (self.shm_) wl_shm_add_listener(self.shm_, &shmListener, &self);
    } else if (!std::strcmp(interface, ext_session_lock_manager_v1_interface.name) && !self.manager_) {
        self.manager_ = static_cast<ext_session_lock_manager_v1*>(wl_registry_bind(registry, id, &ext_session_lock_manager_v1_interface, 1));
        self.managerId_ = id;
        qInfo("ext-session-lock-v1 manager bound at version 1");
    } else if (!std::strcmp(interface, wl_seat_interface.name) && self.authenticate_ && !self.seat_) {
        if (version < 7) { self.stopFailure("wl_seat version >=7 required for native input"); return; }
        self.seat_ = static_cast<wl_seat*>(wl_registry_bind(registry, id, &wl_seat_interface, 7));
        self.seatId_ = id;
        if (self.seat_) wl_seat_add_listener(self.seat_, &seatListener, &self);
    } else if (!std::strcmp(interface, wl_output_interface.name)) {
        if (self.nativeOutputs_.contains(id)) return;
        if (self.nativeOutputs_.size() >= 64) { self.stopFailure("Output registry resource limit exceeded"); return; }
        auto output = std::make_unique<NativeOutput>();
        output->id = id;
        output->owner = &self;
        output->output = static_cast<wl_output*>(wl_registry_bind(registry, id, &wl_output_interface, std::min(version, 4u)));
        if (!output->output) { self.stopFailure("Output allocation failed"); return; }
        wl_output_add_listener(output->output, &outputListener, output.get());
        self.nativeOutputs_.emplace(id, std::move(output));
        qInfo() << "Output discovered, registry id" << id;
        self.controller_.addOutput(id);
    }
}
void WaylandOwner::registryRemove(void* data, wl_registry*, std::uint32_t id) {
    auto& self = *static_cast<WaylandOwner*>(data);
    if (self.stopping_) return;
    auto it = self.nativeOutputs_.find(id);
    if (it != self.nativeOutputs_.end()) {
        self.controller_.removeOutput(id);
        auto* output = it->second->output;
        if (wl_output_get_version(output) >= 3) wl_output_release(output);
        else wl_output_destroy(output);
        self.nativeOutputs_.erase(it);
        qInfo() << "Output removed, registry id" << id;
    } else if (id == self.seatId_) {
        self.focusedSurface_ = nullptr; self.input_.focus(false);
        if (self.keyboard_) wl_keyboard_release(self.keyboard_);
        self.keyboard_ = nullptr;
        if (self.seat_) wl_seat_release(self.seat_);
        self.seat_ = nullptr; self.seatId_ = 0;
        qWarning("Keyboard seat removed; remaining locked");
    } else if (id == self.managerId_ || id == self.compositorId_ || id == self.shmId_) {
        self.stopFailure("Required protocol global removed; no unlock requested");
    }
}
void WaylandOwner::discoveryDone(void* data, wl_callback* callback, std::uint32_t) {
    auto& self = *static_cast<WaylandOwner*>(data);
    wl_callback_destroy(callback);
    self.sync_ = nullptr;
    if (self.stopping_) return;
    if (!self.manager_ || !self.compositor_ || !self.shm_) {
        self.stopFailure("Required globals absent; NO fake-lock fallback");
        return;
    }
    if (!self.controller_.acquire()) { self.stopFailure("Acquisition request failed"); return; }
    self.deadline_.start(15000); // Never unlock on timeout, even if accepted late.
}
bool WaylandOwner::requestLock() {
    lock_ = ext_session_lock_manager_v1_lock(manager_);
    if (!lock_) return false;
    ext_session_lock_v1_add_listener(lock_, &lockListener, this);
    qInfo("Lock requested: state Acquiring (NOT confirmed locked)");
    return true;
}
bool WaylandOwner::createSurface(std::uint32_t id) {
    auto it = nativeOutputs_.find(id);
    if (it == nativeOutputs_.end() || !lock_) return false;
    auto& output = *it->second;
    output.lifetime = controller_.outputs().at(id).lifetime;
    if (output.surface || output.lockSurface) return false;
    output.surface = wl_compositor_create_surface(compositor_);
    if (!output.surface) return false;
    wl_surface_add_listener(output.surface, &wlSurfaceListener, &output);
    // Role is assigned BEFORE any attach/commit. This is never xdg/layer shell.
    output.lockSurface = ext_session_lock_v1_get_lock_surface(lock_, output.surface, output.output);
    if (!output.lockSurface) {
        wl_surface_destroy(output.surface); output.surface = nullptr;
        return false;
    }
    ext_session_lock_surface_v1_add_listener(output.lockSurface, &surfaceListener, &output);
    qInfo() << "Lock surface created for registry output" << id << "lifetime" << output.lifetime
            << "auth generation" << auth_.generation() << "authentication enabled" << authenticate_;
    return true;
}
void WaylandOwner::removeSurface(std::uint32_t id) {
    auto it = nativeOutputs_.find(id);
    if (it == nativeOutputs_.end()) return;
    auto& output = *it->second;
    if (focusedSurface_ == output.surface) { focusedSurface_ = nullptr; input_.focus(false, {}, true); }
    if (output.lockSurface) ext_session_lock_surface_v1_destroy(output.lockSurface);
    if (output.surface) wl_surface_destroy(output.surface);
    output.lockSurface = nullptr;
    output.surface = nullptr;
    std::erase_if(buffers_, [id](const auto& b) { return b->outputId == id; });
    qInfo() << "Output resources removed" << id << "lifetime" << output.lifetime
            << "global state" << int(controller_.state()) << "auth generation" << auth_.generation();
}
void WaylandOwner::surfaceConfigure(void* data, ext_session_lock_surface_v1*,
                                    std::uint32_t serial, std::uint32_t width, std::uint32_t height) {
    auto& output = *static_cast<NativeOutput*>(data);
    auto& self = *output.owner;
    if (self.stopping_) return;
    if (output.configureLogs++ < 8)
        qInfo() << "Configure output" << output.id << "serial" << serial << "logical size" << width << height;
    else if (output.configureLogs == 9) qInfo() << "Further configure logs suppressed for output" << output.id;
    self.controller_.configure(output.id, {serial, width, height}, output.lifetime);
}
FrameResult WaylandOwner::present(std::uint32_t id, Configure c, bool acknowledge) {
    const auto it = nativeOutputs_.find(id);
    if (it == nativeOutputs_.end() || !it->second->lockSurface || !validGeometry(c)) return FrameResult::Failed;
    // Never repaint memory until the compositor releases it. Keep at most two
    // in-flight frames/output; coalesce pending configures in Controller.
    std::erase_if(buffers_, [](const auto& b) { return !b->busy; });
    const auto count = std::count_if(buffers_.begin(), buffers_.end(), [id](const auto& b) { return b->outputId == id; });
    if (count >= 2) return FrameResult::Deferred;
    const std::size_t bytes = std::size_t(c.width) * c.height * 4;
    std::size_t allocated = 0;
    for (const auto& b : buffers_) allocated += b->size;
    if (bytes > totalBufferLimit - allocated) return FrameResult::Failed;
    auto buffer = std::make_unique<Buffer>();
    buffer->owner = this;
    buffer->outputId = id;
    buffer->lifetime = it->second->lifetime;
    buffer->size = bytes;
    const int fd = memfd_create("magi-lock-proof-frame", MFD_CLOEXEC);
    if (fd < 0) return FrameResult::Failed;
    if (ftruncate(fd, off_t(bytes)) < 0) { close(fd); return FrameResult::Failed; }
    buffer->mapping = mmap(nullptr, bytes, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (buffer->mapping == MAP_FAILED) { close(fd); return FrameResult::Failed; }
    auto* pool = wl_shm_create_pool(shm_, fd, int(bytes));
    close(fd);
    if (!pool) return FrameResult::Failed;
    buffer->proxy = wl_shm_pool_create_buffer(pool, 0, int(c.width), int(c.height), int(c.width * 4), WL_SHM_FORMAT_XRGB8888);
    wl_shm_pool_destroy(pool);
    if (!buffer->proxy) return FrameResult::Failed;
    wl_buffer_add_listener(buffer->proxy, &bufferListener, buffer.get());
    QImage image(static_cast<uchar*>(buffer->mapping), int(c.width), int(c.height), int(c.width * 4), QImage::Format_RGB32);
    const auto state = stateName(controller_.state());
    const QString notice = developmentSeconds_
        ? QString("UNSAFE DEVELOPMENT: automatic unlock %1 seconds after confirmation").arg(developmentSeconds_)
        : (authenticate_ ? QStringLiteral("AUTHENTICATION PROOF — NOT FOR PRODUCTION USE")
                         : QStringLiteral("NO AUTHENTICATION / NO UNLOCK — NOT FOR PRODUCTION USE"));
    const bool rendered = Presentation::render(image, QString("Output registry id %1").arg(id),
                                               QString::fromUtf8(state.data(), qsizetype(state.size())), notice, {}, auth_.presentation());
    auto& output = *it->second;
    if (!rendered) {
        Presentation::fallback(image, auth_.presentation());
        if (!output.fallbackLogged) qWarning() << "Native solid fallback activated for output" << id;
        output.fallbackLogged = true;
    }
    // Surface-local dimensions are authoritative. Scale 1 and NORMAL buffer
    // transform are legal on HiDPI/rotated outputs; compositor maps the surface.
    // Native-resolution/fractional quality is deferred, coverage is not.
    if (acknowledge) ext_session_lock_surface_v1_ack_configure(output.lockSurface, c.serial);
    wl_surface_set_buffer_scale(output.surface, 1);
    wl_surface_set_buffer_transform(output.surface, WL_OUTPUT_TRANSFORM_NORMAL);
    wl_surface_attach(output.surface, buffer->proxy, 0, 0);
    wl_surface_damage_buffer(output.surface, 0, 0, int(c.width), int(c.height));
    wl_surface_commit(output.surface);
    buffer->busy = true;
    buffers_.push_back(std::move(buffer));
    if (output.presentationLogs++ < 8)
        qInfo() << "Output committed" << id << "lifetime" << output.lifetime
                << "serial" << c.serial << "acknowledged" << acknowledge
                << "native fallback" << !rendered << "global state" << int(controller_.state())
                << "auth generation" << auth_.generation();
    return rendered ? FrameResult::Presented : FrameResult::Fallback;
}
void WaylandOwner::bufferReleased(void* data, wl_buffer*) {
    auto* buffer = static_cast<Buffer*>(data);
    buffer->owner->releaseBuffer(buffer);
}
void WaylandOwner::releaseBuffer(Buffer* buffer) {
    buffer->busy = false;
    const auto id = buffer->outputId;
    const auto lifetime = buffer->lifetime;
    // Never delete listener data or mutate controller output map reentrantly.
    QTimer::singleShot(0, this, [this, id, lifetime] {
        if (stopping_) return;
        const auto found = controller_.outputs().find(id);
        if (found == controller_.outputs().end() || found->second.lifetime != lifetime)
            qInfo() << "Stale output release ignored" << id << "lifetime" << lifetime;
        controller_.bufferAvailable(id, lifetime);
        flush();
    });
}
void WaylandOwner::lockConfirmed(void* data, ext_session_lock_v1*) {
    auto& self = *static_cast<WaylandOwner*>(data);
    if (self.stopping_) return;
    if (!self.controller_.locked()) { self.stopFailure("Unexpected locked event"); return; }
    self.deadline_.stop();
    qInfo("COMPOSITOR CONFIRMED LOCKED: ext_session_lock_v1.locked");
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    if (self.developmentSeconds_) self.developmentTimer_.start(int(self.developmentSeconds_ * 1000));
#endif
    if (self.authenticate_ && self.ownsSurface(self.focusedSurface_)) {
        self.input_.focus(true);
        if (self.haveModifiers_) self.input_.modifiers(self.modifiers_[0], self.modifiers_[1], self.modifiers_[2], self.modifiers_[3]);
    }
    self.controller_.refresh();
}
void WaylandOwner::lockFinished(void* data, ext_session_lock_v1*) {
    auto& self = *static_cast<WaylandOwner*>(data);
    qWarning() << "Lock finished by compositor; previously confirmed:" << self.controller_.confirmed();
    self.controller_.finished();
    self.stopFailure("Lock denied/retired: disconnect without an unlock request");
}
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
void WaylandOwner::developmentUnlockAndSync() {
    qWarning("UNSAFE DEVELOPMENT TIMER UNLOCK: authenticated acceptance FAILED");
    auth_.cancel();
    unlockAndSync();
}
#endif
void WaylandOwner::authenticatedUnlockAndSync() {
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    developmentTimer_.stop();
#endif
    qInfo("AUTHENTICATED UNLOCK: current PAM Success");
    unlockAndSync();
}
void WaylandOwner::unlockAndSync() {
    ext_session_lock_v1_unlock_and_destroy(lock_);
    lock_ = nullptr;
    sync_ = wl_display_sync(display_);
    if (!sync_) { stopFailure("Unlock sync allocation failed; final state unknown"); return; }
    wl_callback_add_listener(sync_, &syncListener, this);
    deadline_.start(5000);
}
void WaylandOwner::syncDone(void* data, wl_callback* callback, std::uint32_t) {
    auto& self = *static_cast<WaylandOwner*>(data);
    wl_callback_destroy(callback);
    self.sync_ = nullptr;
    if (!self.controller_.unlockSynced()) { self.stopFailure("Unexpected unlock sync"); return; }
    self.deadline_.stop();
    self.stopping_ = true;
    qInfo("Explicit unlock processed by compositor; exiting");
    QCoreApplication::quit();
}
void WaylandOwner::disconnect() {
    stopping_ = true;
    deadline_.stop();
#if MAGI_LOCK_DEVELOPMENT_UNLOCK
    developmentTimer_.stop();
#endif
    auth_.changed = {}; auth_.succeeded = {}; auth_.cancel();
    focusedSurface_ = nullptr; input_.focus(false);
    dispose(keyboard_); dispose(seat_);
    reader_.reset(); writer_.reset();
    // Dispose every proxy locally before disconnect; never marshal cleanup
    // unlock/destroy requests on the lock object, even when confirmed.
    for (auto& [id, output] : nativeOutputs_) {
        (void)id;
        dispose(output->lockSurface); dispose(output->surface); dispose(output->output);
    }
    nativeOutputs_.clear();
    for (auto& buffer : buffers_) dispose(buffer->proxy);
    buffers_.clear();
    dispose(sync_); dispose(lock_); dispose(manager_); dispose(shm_);
    dispose(compositor_); dispose(registry_);
    if (display_) wl_display_disconnect(display_);
    display_ = nullptr;
}
}
