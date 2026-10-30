#include "power_intent.hpp"
#include <iostream>
#define CHECK(x) do { if (!(x)) { std::cerr << "Power intent check failed: " << __LINE__ << '\n'; return 1; } } while(false)
int main() {
    using P=magi::PowerIntent;
    for(auto action:{P::Reboot,P::Suspend}) {
        P intent;
        CHECK(!intent.click(action,100));
        CHECK(intent.pending()==action);
        CHECK(!intent.click(action,200)); // double-click cannot confirm
        CHECK(!intent.click(action,899));
        CHECK(intent.click(action,900));
        CHECK(intent.pending()==P::None);
        CHECK(!intent.click(action,1000));
        intent.cancel();
        CHECK(!intent.click(action,2000)); // typing/sleep/topology cancellation
        CHECK(!intent.click(action,12001)); // expired intent only re-arms
        CHECK(!intent.click(P::None,13000));
        CHECK(intent.pending()==P::None);
        CHECK(!intent.click(action,14000));
        CHECK(!intent.click(action==P::Reboot?P::Suspend:P::Reboot,15000));
    }
    std::cout << "Native power intent confirmation/cancel/expiry PASS\n";
}
