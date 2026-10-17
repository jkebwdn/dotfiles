#include "credential.hpp"
#include <algorithm>
#include <cstdint>
namespace magi {
bool Credential::append(std::span<const char> text) {
    if (text.empty() || text.size() > capacity - size_) return false;
    std::size_t units = 0;
    // Strict UTF-8 scalars, no control/NUL/surrogate/overlong input.
    for (std::size_t i = 0; i < text.size();) {
        auto b = static_cast<unsigned char>(text[i++]);
        std::uint32_t cp = b; unsigned rest = 0; std::uint32_t minimum = 0;
        if (b >= 0xc2 && b <= 0xdf) { cp = b & 31; rest = 1; minimum = 0x80; }
        else if (b >= 0xe0 && b <= 0xef) { cp = b & 15; rest = 2; minimum = 0x800; }
        else if (b >= 0xf0 && b <= 0xf4) { cp = b & 7; rest = 3; minimum = 0x10000; }
        else if (b >= 0x80) return false;
        if (rest > text.size() - i) return false;
        while (rest > 0) {
            --rest;
            auto next = static_cast<unsigned char>(text[i++]);
            if ((next & 0xc0) != 0x80) return false;
            cp = (cp << 6) | (next & 63);
        }
        if (cp < minimum || cp > 0x10ffff || (cp >= 0xd800 && cp <= 0xdfff)
            || cp < 0x20 || (cp >= 0x7f && cp <= 0x9f)) return false;
        ++units;
    }
    std::copy(text.begin(), text.end(), data_.begin() + size_);
    size_ += text.size(); units_ += units;
    return true;
}
void Credential::backspace() {
    if (!size_) return;
    const auto end = size_;
    --size_;
    while (size_ && (static_cast<unsigned char>(data_[size_]) & 0xc0) == 0x80) --size_;
    explicit_bzero(data_.data() + size_, end - size_);
    --units_;
}
}
