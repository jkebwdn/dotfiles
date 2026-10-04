// MAGI's bounded data-control reader. No clipboard content is logged.
// Protocol bindings are generated from the installed, licensed Wayland XML.
#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <poll.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/prctl.h>
#include <time.h>
#include <unistd.h>
#include <wayland-client.h>
#include "data-control.h"

#define LIMIT (8 * 1024 * 1024)
struct offer { struct ext_data_control_offer_v1 *proxy; const char *mime; int rank; bool sensitive; };
static struct wl_display *display;
static struct wl_seat *seat;
static struct ext_data_control_manager_v1 *manager;
static bool initial = true, images = false, files = false, finished = false;

static void frame(const char *mime, const void *bytes, size_t size) {
    printf("%s\n%zu\n", mime, size);
    if (size) fwrite(bytes, 1, size, stdout);
    fflush(stdout);
}
static long milliseconds(void) {
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1000 + t.tv_nsec / 1000000;
}
static void mime_offer(void *data, struct ext_data_control_offer_v1 *proxy, const char *mime) {
    (void)proxy;
    struct offer *offer = data;
    if (!strcmp(mime, "x-kde-passwordManagerHint") || !strcmp(mime, "application/x-keepassxc")) offer->sensitive = true;
    const char *candidate = NULL; int rank = 0;
    if (files && !strcmp(mime, "text/uri-list")) { candidate = "text/uri-list"; rank = 70; }
    if (images && !strcmp(mime, "image/png")) { candidate = "image/png"; rank = 60; }
    if (images && !strcmp(mime, "image/jpeg")) { candidate = "image/jpeg"; rank = 50; }
    if (!strcmp(mime, "text/plain;charset=utf-8")) { candidate = "text/plain;charset=utf-8"; rank = 40; }
    if (!strcmp(mime, "text/plain")) { candidate = "text/plain"; rank = 30; }
    if (!strcmp(mime, "UTF8_STRING")) { candidate = "UTF8_STRING"; rank = 20; }
    if (!strcmp(mime, "text/html")) { candidate = "text/html"; rank = 10; }
    if (rank > offer->rank) { offer->mime = candidate; offer->rank = rank; }
}
static const struct ext_data_control_offer_v1_listener offer_listener = {mime_offer};
static void new_offer(void *data, struct ext_data_control_device_v1 *device, struct ext_data_control_offer_v1 *proxy) {
    (void)data; (void)device;
    struct offer *offer = calloc(1, sizeof(*offer));
    if (!offer) exit(2);
    offer->proxy = proxy;
    ext_data_control_offer_v1_add_listener(proxy, &offer_listener, offer);
}
static void discard(struct ext_data_control_offer_v1 *proxy) {
    if (!proxy) return;
    free(ext_data_control_offer_v1_get_user_data(proxy));
    ext_data_control_offer_v1_destroy(proxy);
}
static void selection(void *data, struct ext_data_control_device_v1 *device, struct ext_data_control_offer_v1 *proxy) {
    (void)data; (void)device;
    // Never request the pre-existing selection, including on re-enable/reconnect.
    if (initial) { initial = false; discard(proxy); frame("ready", NULL, 0); return; }
    if (!proxy) return;
    struct offer *offer = ext_data_control_offer_v1_get_user_data(proxy);
    if (offer->sensitive || !offer->mime) { discard(proxy); return; }
    int fds[2];
    if (pipe(fds) < 0) { discard(proxy); return; }
    ext_data_control_offer_v1_receive(proxy, offer->mime, fds[1]);
    close(fds[1]);
    wl_display_flush(display);
    unsigned char *bytes = malloc(LIMIT + 1);
    if (!bytes) exit(2);
    size_t size = 0; bool complete = false;
    const long deadline = milliseconds() + 1500;
    while (size <= LIMIT) {
        long remaining = deadline - milliseconds();
        if (remaining <= 0) break;
        struct pollfd fd = {.fd = fds[0], .events = POLLIN};
        int result = poll(&fd, 1, (int)remaining);
        if (result < 0 && errno == EINTR) continue;
        if (result <= 0) break;
        ssize_t count = read(fds[0], bytes + size, LIMIT + 1 - size);
        if (count == 0) { complete = true; break; }
        if (count < 0) { if (errno == EINTR) continue; break; }
        size += (size_t)count;
    }
    close(fds[0]);
    if (complete && size && size <= LIMIT) frame(offer->mime, bytes, size);
    free(bytes); discard(proxy);
}
static void primary(void *data, struct ext_data_control_device_v1 *device, struct ext_data_control_offer_v1 *proxy) {
    (void)data; (void)device; discard(proxy);
}
static void finish(void *data, struct ext_data_control_device_v1 *device) {
    (void)data; (void)device; finished = true;
}
static const struct ext_data_control_device_v1_listener device_listener = {new_offer, selection, finish, primary};
static void global(void *data, struct wl_registry *registry, uint32_t name, const char *interface, uint32_t version) {
    (void)data; (void)version;
    if (!strcmp(interface, "wl_seat") && !seat) seat = wl_registry_bind(registry, name, &wl_seat_interface, 1);
    if (!strcmp(interface, "ext_data_control_manager_v1") && !manager)
        manager = wl_registry_bind(registry, name, &ext_data_control_manager_v1_interface, 1);
}
static void removed(void *data, struct wl_registry *registry, uint32_t name) { (void)data; (void)registry; (void)name; }
static const struct wl_registry_listener registry_listener = {global, removed};
int main(int argc, char **argv) {
    const pid_t parent = getppid();
    prctl(PR_SET_PDEATHSIG, SIGTERM);
    if (getppid() != parent) return 1;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "--images")) images = true;
        if (!strcmp(argv[i], "--files")) files = true;
    }
    display = wl_display_connect(NULL);
    if (!display) return 3;
    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);
    if (wl_display_roundtrip(display) < 0 || !manager || !seat) return 4;
    struct ext_data_control_device_v1 *device = ext_data_control_manager_v1_get_data_device(manager, seat);
    ext_data_control_device_v1_add_listener(device, &device_listener, NULL);
    while (!finished && wl_display_dispatch(display) >= 0) {}
    wl_display_disconnect(display);
    return 5;
}
