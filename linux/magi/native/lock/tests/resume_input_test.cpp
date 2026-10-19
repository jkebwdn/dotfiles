#include "native_input.hpp"
#include <QCoreApplication>
#include <QThread>
#include <iostream>
#include <stdexcept>
#include <string>
#include <xkbcommon/xkbcommon-keysyms.h>
using namespace magi;
#define CHECK(x) do { if (!(x)) throw std::runtime_error("check failed at line " + std::to_string(__LINE__)); } while(false)
namespace magi {
struct AuthTestAccess {
    static bool same(const AuthController& a,const AuthController& b) {
        auto x=a.credential_.bytes(),y=b.credential_.bytes();
        return std::string_view(x.data(),x.size())==std::string_view(y.data(),y.size());
    }
    static bool equals(const AuthController& auth, const std::string& expected) {
        auto bytes=auth.credential_.bytes();
        return std::string_view(bytes.data(),bytes.size())==expected;
    }
};
}
static void settle() { QThread::msleep(15); QCoreApplication::processEvents(); }
int main(int argc,char** argv) {
 QCoreApplication app(argc,argv);
 try {
  auto* context=xkb_context_new(XKB_CONTEXT_NO_FLAGS);
  xkb_rule_names names{}; names.layout="us,gb";
  auto* map=xkb_keymap_new_from_names(context,&names,XKB_KEYMAP_COMPILE_NO_FLAGS); CHECK(map);
  char* raw=xkb_keymap_get_as_string(map,XKB_KEYMAP_FORMAT_TEXT_V1); CHECK(raw);
  std::string text(raw); free(raw);
  const auto mask=[&](const char* name) { auto i=xkb_keymap_mod_get_index(map,name); CHECK(i!=XKB_MOD_INVALID); return 1u<<i; };
  const auto shift=mask(XKB_MOD_NAME_SHIFT),caps=mask(XKB_MOD_NAME_CAPS),ctrl=mask(XKB_MOD_NAME_CTRL),alt=mask(XKB_MOD_NAME_ALT),logo=mask(XKB_MOD_NAME_LOGO);
  unsigned cases=0;
  // Compare deferred and normal production dispatch for first printable/control keys,
  // authoritative locked/latched/depressed masks and layout group. No real PAM.
  for (unsigned code:{3u,30u,42u,29u,56u,125u,58u,14u,28u,1u}) {
   for(unsigned variant=0;variant<7;++variant) {
    AuthController normal("/not-used",100,10),deferred("/not-used",100,10);
    NativeInput a(normal),b(deferred);
    CHECK(a.keymap({text.c_str(),text.size()+1}));CHECK(b.keymap({text.c_str(),text.size()+1}));
    a.focus(true);b.focus(true);settle();
    unsigned dep=variant==1?shift:variant==3?ctrl:variant==4?alt:variant==5?logo:0;
    unsigned lock=variant==2?caps:0,latched=variant==6?shift:0,group=variant==6?1:0;
    a.modifiers(dep,latched,lock,group);
    a.key(code,true);a.key(code,false);
    b.key(code,true);b.key(code,false);CHECK(b.pendingCount()==2);
    CHECK(deferred.presentation().count==0 && !deferred.presentation().capsKnown);
    // A 74us gap is modeled by event ordering, not a flaky scheduler sleep.
    b.modifiers(dep,latched,lock,group);CHECK(b.pendingCount()==0);
    CHECK(normal.presentation().count==deferred.presentation().count);
    CHECK(AuthTestAccess::same(normal,deferred));
    if (code==3 && variant==1) CHECK(AuthTestAccess::equals(deferred,"@"));
    if (code==3 && variant==6) CHECK(AuthTestAccess::equals(deferred,"\""));
    CHECK(normal.generation()==deferred.generation());
    CHECK(normal.presentation().caps==deferred.presentation().caps);
    CHECK(deferred.presentation().capsKnown);
    auto expected=normal.presentation().count;
    b.modifiers(dep,latched,lock,group);CHECK(deferred.presentation().count==expected);
    ++cases;
   }
  }
  for(unsigned scenario=0;scenario<18;++scenario) {
   AuthController auth("/not-used",100,10);NativeInput input(auth);
   auto km=[&]{CHECK(input.keymap({text.c_str(),text.size()+1}));};
   auto mods=[&]{input.modifiers(0,0,0,0);};
   km();input.focus(true);settle();
   input.key(30,true);CHECK(input.pendingCount()==1);CHECK(auth.presentation().count==0);
   switch(scenario) {
   case 0: // Exact live ordering: first press before modifiers; release afterwards.
    mods();input.key(30,false);CHECK(AuthTestAccess::equals(auth,"a"));
    input.key(48,true);input.key(48,false);CHECK(AuthTestAccess::equals(auth,"ab"));break;
   case 1: // Two bounded events; replay exactly once under Caps Lock.
    input.key(30,false);input.modifiers(0,0,caps,0);CHECK(AuthTestAccess::equals(auth,"A"));
    mods();CHECK(AuthTestAccess::equals(auth,"A"));break;
   case 2: input.focus(false,{},true);mods();CHECK(input.pendingCount()==0 && auth.presentation().count==0);break;
   case 3: input.focus(false,{},true);input.focus(true,{},true);mods();CHECK(auth.presentation().count==0);break;
   case 4: input.blockForSleep(true);mods();CHECK(input.pendingCount()==0 && auth.presentation().count==0);break;
   case 5: km();input.focus(true);mods();CHECK(auth.presentation().count==0);break;
   case 6: auth.cancel();mods();CHECK(input.pendingCount()==0 && auth.presentation().count==0);break;
   case 7: auth.clear();mods();CHECK(input.pendingCount()==0 && auth.presentation().count==0);break;
   case 8: // Overflow refuses ambiguous multiple presses, then real modifiers recover.
    input.key(48,true);CHECK(input.pendingCount()==0 && auth.presentation().keyboardUnavailable);
    mods();CHECK(!auth.presentation().keyboardUnavailable && auth.presentation().count==0);
    input.key(46,true);input.key(46,false);CHECK(AuthTestAccess::equals(auth,"c"));break;
   case 9: // No modifiers: finite raw metadata retention, no guessed state.
    QThread::msleep(NativeInput::pendingWaitMs+20);QCoreApplication::processEvents();
    CHECK(input.pendingCount()==0 && auth.presentation().keyboardUnavailable && !auth.presentation().capsKnown);
    input.key(48,true);CHECK(input.pendingCount()==0);
    mods();CHECK(auth.presentation().count==0 && auth.presentation().capsKnown);
    input.key(46,true);input.key(46,false);CHECK(AuthTestAccess::equals(auth,"c"));break;
   case 10: // Late modifier callback before timer dispatch still cannot replay expired data.
    QThread::msleep(NativeInput::pendingWaitMs+20);mods();CHECK(auth.presentation().count==0);break;
   case 11: // First Backspace applies normal editing, never text replay.
    auth.clear();CHECK(auth.append(std::span<const char>("xy",2)));
    input.key(14,true);input.key(14,false);mods();CHECK(AuthTestAccess::equals(auth,"x"));break;
   case 12: // Held enter keys are not replayed as credential events.
    input.focus(false,{},true);{unsigned held=30;input.focus(true,{&held,1},true);}
    input.key(30,true);CHECK(input.pendingCount()==0);input.key(30,false);mods();
    input.key(30,true);input.key(30,false);CHECK(AuthTestAccess::equals(auth,"a"));break;
   case 14: // Deferred Enter uses normal submit/generation; nonexistent worker, no PAM.
    auth.clear();CHECK(auth.append(std::span<const char>("synthetic",9)));
    input.key(28,true);input.key(28,false);mods();CHECK(auth.generation()==1 && input.pendingCount()==0);break;
   case 15: // External submission/cancellation cannot leave a deferred old-generation event.
    CHECK(auth.append(std::span<const char>("synthetic",9)));auth.submit();
    CHECK(auth.generation()==1 && input.pendingCount()==0);mods();CHECK(auth.presentation().count==0);break;
   case 16: // Enter before keymap: production owner reapplies verified focus after map.
    input.focus(false,{},true);input.focus(true);km();input.focus(true);settle();mods();
    input.key(30,true);input.key(30,false);CHECK(AuthTestAccess::equals(auth,"a"));break;
   case 17: // Pre-enter modifier notification cannot substitute for post-enter state.
    auth.clear();mods();input.focus(true,{},true);input.key(30,true);input.key(30,false);
    CHECK(input.pendingCount()==2 && auth.presentation().count==0);mods();CHECK(AuthTestAccess::equals(auth,"a"));break;
   case 13: // Invalid keymap cannot defer; no focus cannot defer.
    CHECK(!input.keymap({}));input.key(30,true);CHECK(input.pendingCount()==0);
    km();input.key(30,true);mods();CHECK(input.pendingCount()==0 && auth.presentation().count==0);break;
   }
   ++cases;
  }
  xkb_keymap_unref(map);xkb_context_unref(context);
  std::cout<<cases<<" bounded resume-input compatibility cases passed; no live Wayland/PAM\n";
  return 0;
 } catch(const std::exception& e) {std::cerr<<e.what()<<'\n';return 1;}
}
