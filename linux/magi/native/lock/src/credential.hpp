#pragma once
#include <array>
#include <cstddef>
#include <span>
#include <string.h>
namespace magi {
// No QString, allocation growth, copy/move, serialization or formatting API.
class Credential {
public:
    static constexpr std::size_t capacity = 511;
    Credential() = default;
    ~Credential() { clear(); }
    Credential(const Credential&) = delete;
    Credential& operator=(const Credential&) = delete;
    bool append(std::span<const char> text);
    void backspace();
    void clear() { explicit_bzero(data_.data(), data_.size()); size_ = units_ = 0; }
    std::span<const char> bytes() const { return {data_.data(), size_}; }
    std::size_t units() const { return units_; }
    bool empty() const { return size_ == 0; }
private:
    friend struct AuthTestAccess;
    std::array<char, capacity> data_{};
    std::size_t size_ = 0, units_ = 0;
};
}
