#include "wayland_owner.hpp"
#include "presentation.hpp"
#include <QDateTime>
#include <QCoreApplication>
#include <QDebug>
#include <QImage>
#include <algorithm>
#include <cerrno>
#include <cstring>
#include <sys/mman.h>
#include <unistd.h>
#include <time.h>
#include <wayland-cursor.h>

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

#if MAGI_LOCK_INPUT_DIAGNOSTICS
void WaylandOwner::traceInput(const char* event, wl_keyboard* eventKeyboard, wl_surface* eventSurface) {
    if (inputTraceCount_++ >= 256) return;
    timespec now{}; clock_gettime(CLOCK_MONOTONIC, &now);
    const auto input = input_.readiness();
    unsigned output = 0; std::uint64_t lifetime = 0;
    for (const auto& [id, entry] : nativeOutputs_)
        if (entry->surface == (eventSurface ? eventSurface : focusedSurface_) && entry->surface) {
            output = id; lifetime = entry->lifetime; break;
        }
    const char* gate = stopping_ ? "stopping" : controller_.state() != State::Locked ? "not-locked"
        : !currentFocus() ? "no-owned-focus" : input.blocked ? "sleep-blocked"
        : !input.keymap ? "no-keymap" : !input.focused ? "not-focused"
        : !input.modifiers ? "no-modifiers" : "routing-ready";
    qInfo().nospace() << "INPUT_DIAG mono_us=" << (qint64(now.tv_sec)*1000000 + now.tv_nsec/1000)
        << " event=" << event << " keyboard_epoch=" << keyboardEpoch_
        << " keyboard_present=" << bool(keyboard_) << " event_current=" << (!eventKeyboard || eventKeyboard == keyboard_)
        << " keyboard_capable=" << keyboardCapable_ << " seat=" << seatId_
        << " output=" << output << " lifetime=" << lifetime << " auth_generation=" << auth_.generation()
        << " owned_focus=" << currentFocus() << " sleep_blocked=" << input.blocked
        << " keymap=" << input.keymap << " focused=" << input.focused << " modifiers=" << input.modifiers
        << " auth_editable=" << auth_.presentation().active
        << " gate=" << gate << " trace_remaining=" << (256-inputTraceCount_);
}
#endif

bool WaylandOwner::ownsSurface(wl_surface* surface) const {
    if (!surface) return false;
    for (const auto& [id, output] : nativeOutputs_) { (void)id; if (output->surface == surface) return true; }
    return false;
}
bool WaylandOwner::currentFocus() const {
    const auto it = nativeOutputs_.find(focusedOutput_);
    return focusedSurface_ && it != nativeOutputs_.end()
        && it->second->surface == focusedSurface_ && it->second->lifetime == focusedLifetime_;
}
void WaylandOwner::rememberFocus(wl_surface* surface) {
    focusedSurface_ = nullptr; focusedOutput_ = 0; focusedLifetime_ = 0;
    for (const auto& [id, output] : nativeOutputs_) if (surface && output->surface == surface) {
        focusedSurface_ = surface; focusedOutput_ = id; focusedLifetime_ = output->lifetime; return;
    }
}
void WaylandOwner::cancelPower() {
    pressedPower_ = -1;
    if (powerIntent_.pending() != PowerIntent::None) {
        powerIntent_.cancel(); powerExpiry_.stop();
        if (auth_.changed) auth_.changed();
    }
}
void WaylandOwner::pointerButton(std::uint32_t button, std::uint32_t state) {
    if (button != 0x110 || stopping_ || sleeping_ || !controller_.secureLockReady()) return;
    int hit = -1;
    for (const auto& [id, output] : nativeOutputs_) {
        (void)id;
        if (output->surface != pointerSurface_ || !pointerSurface_) continue;
        for (int i=0; i<3; ++i) if (output->powerRegions[i].contains(pointerPosition_)) hit = i;
    }
    if (state == WL_POINTER_BUTTON_STATE_PRESSED) { pressedPower_ = hit; return; }
    const bool same = hit >= 0 && hit == pressedPower_;
    pressedPower_ = -1;
    if (!same || powerProcess_.state() != QProcess::NotRunning) return;
    if (hit == 2) { cancelPower(); return; }
    const auto action = hit == 0 ? PowerIntent::Reboot : PowerIntent::Suspend;
    if (powerIntent_.click(action, powerClock_.elapsed())) {
        powerExpiry_.stop();
        // Same systemctl/logind authority as shell actions. Never force, ignore
        // inhibitors, invoke a shell, or authorize an interactive escalation.
        powerMessage_ = "Requesting power action…";
        powerProcess_.start("/usr/bin/systemctl", {"--no-ask-password", "--check-inhibitors=yes", hit == 0 ? "reboot" : "suspend"});
        powerDeadline_.start(5000);
    } else powerExpiry_.start(10000);
    if (auth_.changed) auth_.changed();
}
void WaylandOwner::setArrow(std::uint32_t serial) {
    if(!pointer_ || !shm_ || !compositor_) return;
    if(!cursorTheme_) cursorTheme_=wl_cursor_theme_load(nullptr,48,shm_);
    if(!cursorTheme_) return;
    auto* cursor=wl_cursor_theme_get_cursor(cursorTheme_,"left_ptr");
    if(!cursor) cursor=wl_cursor_theme_get_cursor(cursorTheme_,"default");
    if(!cursor || !cursor->image_count) return;
    if(!cursorSurface_) cursorSurface_=wl_compositor_create_surface(compositor_);
    if(!cursorSurface_) return;
    auto* image=cursor->images[0];auto* buffer=wl_cursor_image_get_buffer(image);if(!buffer)return;
    const int density=(image->width%2==0 && image->height%2==0) ? 2 : 1;
    wl_surface_set_buffer_scale(cursorSurface_,density);
    wl_pointer_set_cursor(pointer_,serial,cursorSurface_,image->hotspot_x/density,image->hotspot_y/density);
    wl_surface_attach(cursorSurface_,buffer,0,0);wl_surface_damage_buffer(cursorSurface_,0,0,image->width,image->height);wl_surface_commit(cursorSurface_);
}
const wl_pointer_listener WaylandOwner::pointerListener{
    [](void* data, wl_pointer* pointer, uint32_t serial, wl_surface* surface, wl_fixed_t x, wl_fixed_t y) {
        auto& self = *static_cast<WaylandOwner*>(data);
        if (pointer != self.pointer_) return;
        self.cancelPower(); self.pointerSurface_ = self.ownsSurface(surface) ? surface : nullptr;
        self.pointerPosition_ = {wl_fixed_to_double(x), wl_fixed_to_double(y)};
        if(self.pointerSurface_) self.setArrow(serial);
    },
    [](void* data, wl_pointer* pointer, uint32_t, wl_surface*) {
        auto& self = *static_cast<WaylandOwner*>(data);
        if (pointer == self.pointer_) { self.pointerSurface_ = nullptr; self.cancelPower(); }
    },
    [](void* data, wl_pointer* pointer, uint32_t, wl_fixed_t x, wl_fixed_t y) {
        auto& self = *static_cast<WaylandOwner*>(data);
        if (pointer == self.pointer_) self.pointerPosition_ = {wl_fixed_to_double(x), wl_fixed_to_double(y)};
    },
    [](void* data, wl_pointer* pointer, uint32_t, uint32_t, uint32_t button, uint32_t state) {
        auto& self = *static_cast<WaylandOwner*>(data);
        if (pointer == self.pointer_) self.pointerButton(button, state);
    },
    [](void*, wl_pointer*, uint32_t, uint32_t, wl_fixed_t) {},
    [](void*, wl_pointer*) {},
    [](void*, wl_pointer*, uint32_t) {},
    [](void*, wl_pointer*, uint32_t, uint32_t) {},
    [](void*, wl_pointer*, uint32_t, int32_t) {},
    [](void*, wl_pointer*, uint32_t, int32_t) {},
    [](void*, wl_pointer*, uint32_t, uint32_t) {},
    nullptr // warp requires a newer pointer version than the bound seat v7.
};
const wl_seat_listener WaylandOwner::seatListener{
    [](void* data, wl_seat* seat, std::uint32_t capabilities) {
        auto& self = *static_cast<WaylandOwner*>(data);
        if ((capabilities & WL_SEAT_CAPABILITY_POINTER) && !self.pointer_) {
            self.pointer_ = wl_seat_get_pointer(seat);
            if (self.pointer_) wl_pointer_add_listener(self.pointer_, &pointerListener, &self);
        } else if (!(capabilities & WL_SEAT_CAPABILITY_POINTER) && self.pointer_) {
            wl_pointer_release(self.pointer_); self.pointer_ = nullptr; self.pointerSurface_ = nullptr; self.cancelPower();
        }
        self.keyboardCapable_ = capabilities & WL_SEAT_CAPABILITY_KEYBOARD;
        self.traceInput("seat-capabilities");
        if (self.keyboardCapable_) {
            if (!self.keyboard_) {
                self.keyboard_ = wl_seat_get_keyboard(seat);
#if MAGI_LOCK_INPUT_DIAGNOSTICS
                ++self.keyboardEpoch_;
#endif
                self.traceInput("keyboard-created");
                if (self.keyboard_) wl_keyboard_add_listener(self.keyboard_, &keyboardListener, &self);
            }
        } else if (self.keyboard_) {
            self.focusedSurface_ = nullptr; self.input_.focus(false);
            self.traceInput("keyboard-destroy-capability");
            wl_keyboard_release(self.keyboard_); self.keyboard_ = nullptr;
        }
    },
    [](void*, wl_seat*, const char*) {}
};
const wl_keyboard_listener WaylandOwner::keyboardListener{
    [](void* data, wl_keyboard* eventKeyboard, std::uint32_t format, int fd, std::uint32_t size) {
        auto& self = *static_cast<WaylandOwner*>(data);
        if (!eventKeyboard || eventKeyboard != self.keyboard_) { close(fd); return; }
        self.traceInput("keymap-received", eventKeyboard);
        self.input_.keymap({}); self.haveModifiers_ = false;
        if (format != WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1 || !size || size > 1024*1024) { close(fd); return; }
        void* map = mmap(nullptr, size, PROT_READ, MAP_PRIVATE, fd, 0); close(fd);
        if (map == MAP_FAILED) return;
        const bool okay = self.input_.keymap({static_cast<const char*>(map), size});
        munmap(map, size);
        if (okay) qInfo("Native keyboard keymap initialized");
        else qWarning("Native keyboard unavailable; remaining locked");
        self.input_.focus(okay && self.currentFocus() && self.controller_.state() == State::Locked);
        self.traceInput("keymap-applied", eventKeyboard);
    },
    [](void* data, wl_keyboard* eventKeyboard, std::uint32_t, wl_surface* surface, wl_array* keys) {
        auto& self = *static_cast<WaylandOwner*>(data);
        if (!eventKeyboard || eventKeyboard != self.keyboard_) return;
        self.haveModifiers_ = false;
        self.rememberFocus(surface);
        std::span<const unsigned> held;
        if (keys && keys->size <= 768*sizeof(unsigned) && keys->size % sizeof(unsigned) == 0)
            held = {static_cast<const unsigned*>(keys->data), keys->size/sizeof(unsigned)};
        // An enter can refer to a surface removed earlier in the event batch.
        // Suspend input in that case without cancelling the session attempt.
        self.input_.focus(self.focusedSurface_ && self.controller_.state() == State::Locked, held, true);
        self.traceInput("enter", eventKeyboard, surface);
    },
    [](void* data, wl_keyboard* eventKeyboard, std::uint32_t, wl_surface*) {
        auto& self = *static_cast<WaylandOwner*>(data);
        if (!eventKeyboard || eventKeyboard != self.keyboard_) return;
        self.traceInput("leave", eventKeyboard);
        self.focusedSurface_ = nullptr; self.input_.focus(false, {}, true);
        self.traceInput("leave-applied", eventKeyboard);
    },
    [](void* data, wl_keyboard* eventKeyboard, std::uint32_t, std::uint32_t, std::uint32_t key, std::uint32_t state) {
        auto& self = *static_cast<WaylandOwner*>(data);
        if (!eventKeyboard || eventKeyboard != self.keyboard_) return;
        if (state == WL_KEYBOARD_KEY_STATE_PRESSED) self.cancelPower();
        // Never log keycode/text: physical codes can reconstruct passwords.
        self.traceInput(state == WL_KEYBOARD_KEY_STATE_PRESSED ? "key-pressed" : "key-released", eventKeyboard);
        if (!self.stopping_ && self.controller_.state() == State::Locked && self.currentFocus())
            self.input_.key(key, state == WL_KEYBOARD_KEY_STATE_PRESSED);
        else self.input_.focus(false, {}, true);
    },
    [](void* data, wl_keyboard* eventKeyboard, std::uint32_t, std::uint32_t depressed, std::uint32_t latched, std::uint32_t locked, std::uint32_t group) {
        auto& self = *static_cast<WaylandOwner*>(data);
        if (!eventKeyboard || eventKeyboard != self.keyboard_) return;
        self.modifiers_ = {depressed, latched, locked, group}; self.haveModifiers_ = true;
        if (!self.stopping_ && self.controller_.state() == State::Locked && self.currentFocus())
            self.input_.modifiers(depressed, latched, locked, group);
        else self.input_.focus(false, {}, true);
        self.traceInput("modifiers", eventKeyboard);
    },
    [](void* data, wl_keyboard* eventKeyboard, std::int32_t, std::int32_t) {
        static_cast<WaylandOwner*>(data)->traceInput("repeat-info", eventKeyboard);
    } // No key repeat in this proof.
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
    [](void* data, wl_output*) {auto& output=*static_cast<NativeOutput*>(data);
        if(output.owner && !output.owner->stopping_ && output.lockSurface) {output.owner->controller_.refresh();output.owner->flush();}},
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
    powerClock_.start();
    powerExpiry_.setSingleShot(true); powerDeadline_.setSingleShot(true);
    connect(&powerExpiry_, &QTimer::timeout, this, [this] { cancelPower(); });
    connect(&powerDeadline_, &QTimer::timeout, this, [this] { powerProcess_.kill(); });
    powerProcess_.setStandardOutputFile(QProcess::nullDevice());
    powerProcess_.setStandardErrorFile(QProcess::nullDevice());
    connect(&powerProcess_, &QProcess::finished, this, [this](int code, QProcess::ExitStatus status) {
        powerDeadline_.stop();
        powerMessage_ = code == 0 && status == QProcess::NormalExit ? "" : "Power action unavailable or inhibited";
        if (auth_.changed) auth_.changed();
    });
    connect(&powerProcess_, &QProcess::errorOccurred, this, [this](QProcess::ProcessError) {
        powerMessage_ = "Power action unavailable";
        if (auth_.changed) auth_.changed();
    });
    fingerprint_.changed = [this] { if (auth_.changed) auth_.changed(); };
    fingerprint_.succeeded = [this](fingerprint::Binding binding) {
        if (!stopping_ && authenticate_ && (!unlockAllowed || unlockAllowed())
            && controller_.fingerprintUnlock(fingerprint_, binding)) flush();
    };
    auth_.succeeded = [this](std::uint64_t generation) {
        if (!stopping_ && authenticate_ && (!unlockAllowed || unlockAllowed()) && controller_.authenticatedUnlock(auth_, generation)) flush();
    };
    // One-shot QML scenes do not own timers. Refresh through the existing
    // lifetime-checked output path; never retain QML objects across outputs.
    clockRefresh_.setInterval(1000);
    connect(&clockRefresh_, &QTimer::timeout, this, [this, lastMinute = qint64(-1)]() mutable {
        const auto minute = QDateTime::currentSecsSinceEpoch() / 60;
        if (!stopping_ && (VisualData::refreshCurrentMedia() || minute != lastMinute)) { lastMinute = minute; controller_.refresh(); flush(); }
    });
    clockRefresh_.start();
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
void WaylandOwner::prepareSleep() {
    sleeping_ = true; cancelPower();
    fingerprint_.cancel();
    controller_.blockForSleep(true);
    input_.blockForSleep(true);
    haveModifiers_ = false;
    traceInput("sleep-blocked");
    qInfo("SLEEP PREPARATION: input blocked, credential cleared, auth cancelled");
}
void WaylandOwner::resumeSleep() {
    if (stopping_) return;
    traceInput("resume-begin");
    input_.blockForSleep(false);
    traceInput("sleep-unblocked");
    focusedSurface_ = nullptr; haveModifiers_ = false; modifiers_ = {};
    // Fresh keyboard object gives keymap/enter/modifiers in compositor order.
    // Old queued events cannot restore focus or modifiers to this object.
    traceInput("keyboard-destroy-resume");
    if (keyboard_) wl_keyboard_release(keyboard_);
    keyboard_ = nullptr;
    if (seat_ && authenticate_ && keyboardCapable_) {
        keyboard_ = wl_seat_get_keyboard(seat_);
#if MAGI_LOCK_INPUT_DIAGNOSTICS
        ++keyboardEpoch_;
#endif
        traceInput("keyboard-created-resume");
        if (keyboard_) wl_keyboard_add_listener(keyboard_, &keyboardListener, this);
    }
    sleeping_ = false;
    controller_.blockForSleep(false);
    if (authenticate_ && controller_.secureLockReady()) fingerprint_.start();
    controller_.refresh(); flush();
    traceInput("resume-reconstructed");
    qInfo("RESUME: still locked; fresh keyboard state required");
}
bool WaylandOwner::start() {
    if (started_) return !stopping_;
    started_ = true;
    display_ = wl_display_connect(nullptr);
    if (!display_) { stopFailure("Cannot connect to Wayland display; no lock requested"); return false; }
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
    pointerSurface_ = nullptr; cancelPower();
    auto it = nativeOutputs_.find(id);
    if (it == nativeOutputs_.end()) return;
    auto& output = *it->second;
    traceInput("surface-removing", nullptr, output.surface);
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
    self.cancelPower(); output.powerRegions = {};
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
    std::size_t allocated = 0;
    for (const auto& b : buffers_) allocated += b->size;
    int density=std::clamp(it->second->scale,1,4);
    auto fits=[&](int factor){return validGeometry({c.serial,c.width*unsigned(factor),c.height*unsigned(factor)})
        && std::size_t(c.width)*c.height*4*factor*factor<=totalBufferLimit-allocated;};
    while(density>1 && !fits(density)) --density;
    if(!fits(density)) return FrameResult::Failed;
    const int pixelWidth=int(c.width)*density,pixelHeight=int(c.height)*density;
    const std::size_t bytes=std::size_t(pixelWidth)*pixelHeight*4;
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
    buffer->proxy = wl_shm_pool_create_buffer(pool, 0, pixelWidth, pixelHeight, pixelWidth * 4, WL_SHM_FORMAT_XRGB8888);
    wl_shm_pool_destroy(pool);
    if (!buffer->proxy) return FrameResult::Failed;
    wl_buffer_add_listener(buffer->proxy, &bufferListener, buffer.get());
    QImage image(static_cast<uchar*>(buffer->mapping), pixelWidth, pixelHeight, pixelWidth * 4, QImage::Format_RGB32);
    image.setDevicePixelRatio(density);
    const auto state = stateName(controller_.state());
    const QString notice = developmentSeconds_
        ? QString("UNSAFE DEVELOPMENT: automatic unlock %1 seconds after confirmation").arg(developmentSeconds_)
        : (authenticate_ ? QString()
                         : QStringLiteral("NO AUTHENTICATION / NO UNLOCK — NOT FOR PRODUCTION USE"));
    auto presentation = auth_.presentation();
    presentation.powerConfirmation = powerIntent_.pending();
    presentation.fingerprintStatus = fingerprint_.status();
    presentation.powerStatus = powerMessage_;
    const bool rendered = Presentation::render(image, QString("Output registry id %1").arg(id),
                                               QString::fromUtf8(state.data(), qsizetype(state.size())), notice, {}, presentation, nullptr, &it->second->powerRegions);
    auto& output = *it->second;
    if (!rendered) {
        Presentation::fallback(image, auth_.presentation());
        if (!output.fallbackLogged) qWarning() << "Native solid fallback activated for output" << id;
        output.fallbackLogged = true;
    }
    // Geometry and hit regions stay surface-local; only the pixel buffer scales.
    // Integer output density also supplies oversampling on fractional outputs.
    // Retain NORMAL transform and the existing bounded buffer ownership rules.
    if (acknowledge) ext_session_lock_surface_v1_ack_configure(output.lockSurface, c.serial);
    wl_surface_set_buffer_scale(output.surface, density);
    wl_surface_set_buffer_transform(output.surface, WL_OUTPUT_TRANSFORM_NORMAL);
    wl_surface_attach(output.surface, buffer->proxy, 0, 0);
    wl_surface_damage_buffer(output.surface, 0, 0, pixelWidth, pixelHeight);
    wl_surface_commit(output.surface);
    buffer->busy = true;
    buffers_.push_back(std::move(buffer));
    if (output.presentationLogs++ < 8)
        qInfo() << "Output committed" << id << "lifetime" << output.lifetime
                << "serial" << c.serial << "acknowledged" << acknowledge << "buffer density" << density
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
    if (self.authenticate_ && self.currentFocus()) {
        self.input_.focus(true);
        if (self.haveModifiers_) self.input_.modifiers(self.modifiers_[0], self.modifiers_[1], self.modifiers_[2], self.modifiers_[3]);
    }
    self.controller_.refresh();
    if (self.secureReady) self.secureReady();
    if (self.authenticate_ && !self.sleeping_) self.fingerprint_.start();
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
    qInfo("AUTHENTICATED UNLOCK: current validated authentication success");
    unlockAndSync();
}
void WaylandOwner::unlockAndSync() {
    fingerprint_.cancel();
    auth_.cancel();
    focusedSurface_ = nullptr; input_.focus(false, {}, true);
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
    fingerprint_.changed = {}; fingerprint_.succeeded = {}; fingerprint_.cancel();
    auth_.changed = {}; auth_.succeeded = {}; auth_.cancel();
    focusedSurface_ = nullptr; input_.focus(false);
    pointerSurface_ = nullptr; cancelPower();
    dispose(cursorSurface_);
    if(cursorTheme_) {wl_cursor_theme_destroy(cursorTheme_);cursorTheme_=nullptr;}
    dispose(pointer_); dispose(keyboard_); dispose(seat_);
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
