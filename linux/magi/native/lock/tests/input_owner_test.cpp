#include "wayland_owner.hpp"
#include <QCoreApplication>
#include <QThread>
#include <iostream>
#include <stdexcept>
#define CHECK(x) do { if (!(x)) throw std::runtime_error("owner check failed at " + std::to_string(__LINE__)); } while(false)
namespace magi {
struct InputOwnerTestAccess {
 static void run(const std::string& keymap) {
  WaylandOwner owner(0,true,"/not-used",100);
  // Opaque identities only: never connected, marshalled or destroyed by libwayland.
  auto* surface=reinterpret_cast<wl_surface*>(std::uintptr_t(0x1000));
  auto* keyboard=reinterpret_cast<wl_keyboard*>(std::uintptr_t(0x2000));
  auto* staleKeyboard=reinterpret_cast<wl_keyboard*>(std::uintptr_t(0x3000));
  auto output=std::make_unique<WaylandOwner::NativeOutput>();
  output->id=77;output->lifetime=2;output->surface=surface;
  owner.nativeOutputs_[77]=std::move(output);owner.keyboard_=keyboard;
  // Cleanup even on assertion failure, so synthetic identities never reach teardown.
  struct Cleanup { WaylandOwner& o; ~Cleanup(){o.focusedSurface_=nullptr;o.keyboard_=nullptr;o.nativeOutputs_.clear();} } cleanup{owner};
  owner.rememberFocus(surface);CHECK(owner.currentFocus());
  owner.nativeOutputs_[77]->lifetime=3;CHECK(!owner.currentFocus());
  owner.rememberFocus(surface);CHECK(owner.currentFocus());
  CHECK(owner.input_.keymap({keymap.c_str(),keymap.size()+1}));
  owner.input_.focus(true);QThread::msleep(15);QCoreApplication::processEvents();
  owner.input_.key(30,true);CHECK(owner.input_.pendingCount()==1);
  owner.keyboardListener.modifiers(&owner,staleKeyboard,0,0,0,0,0);
  CHECK(owner.input_.pendingCount()==1 && !owner.input_.readiness().modifiers);
  owner.nativeOutputs_[77]->lifetime=4;
  owner.keyboardListener.modifiers(&owner,keyboard,0,0,0,0,0);
  CHECK(owner.input_.pendingCount()==0 && !owner.currentFocus());
  CHECK(owner.auth_.presentation().count==0);
  owner.rememberFocus(surface);CHECK(owner.currentFocus());
  owner.nativeOutputs_.clear();CHECK(!owner.currentFocus());
  owner.keyboardListener.key(&owner,keyboard,0,0,30,WL_KEYBOARD_KEY_STATE_PRESSED);
  CHECK(owner.input_.pendingCount()==0 && owner.auth_.presentation().count==0);
  owner.keyboard_=nullptr;
  owner.keyboardListener.enter(&owner,keyboard,0,surface,nullptr);
  CHECK(!owner.currentFocus());
 }
};
}
int main(int argc,char** argv){
 QCoreApplication app(argc,argv);
 try {
  auto* context=xkb_context_new(XKB_CONTEXT_NO_FLAGS);
  xkb_rule_names names{};names.layout="us";
  auto* map=xkb_keymap_new_from_names(context,&names,XKB_KEYMAP_COMPILE_NO_FLAGS);CHECK(map);
  auto* raw=xkb_keymap_get_as_string(map,XKB_KEYMAP_FORMAT_TEXT_V1);CHECK(raw);
  std::string text(raw);free(raw);xkb_keymap_unref(map);xkb_context_unref(context);
  magi::InputOwnerTestAccess::run(text);
  std::cout<<"Production owner: stale keyboard, output lifetime replacement/removal, destroyed keyboard rejected; no live Wayland/PAM\n";
  return 0;
 }catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}
}
