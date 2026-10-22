#pragma once
#include "model.hpp"
#include <string>
namespace magi::fingerprint {
// Phase 11A adapter contract, no live implementation. Methods must be bounded;
// a future D-Bus adapter must be asynchronous and pin the daemon's unique owner.
class Device {
public:
    virtual ~Device()=default;
    virtual bool claim()=0; // owner UID only, never an arbitrary UI username
    virtual bool verifyStart()=0;
    virtual bool verifyStop()=0;
    virtual bool release()=0;
};
class Session {
public:
    Session(Model& model, Device& device) : model_(model),device_(device) {}
    ~Session(){ cancel(); }
    bool start(std::string daemon, std::string path, std::uint64_t now, bool secureLockReady);
    void status(Binding subscription, std::string_view daemon,std::string_view path,std::string_view status,bool done, std::uint64_t now);
    void tick(std::uint64_t now);
    void cancel();
    void lost(bool daemon);
private:
    bool cleanup();
    Model& model_; Device& device_;
    Binding binding_{};
    std::string daemon_,path_;
    std::uint64_t started_=0,next_=0;
    bool claimed_=false,verifying_=false,active_=false;
};
}
