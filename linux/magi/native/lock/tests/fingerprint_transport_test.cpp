#include "model.hpp"
#include <cassert>
#include <cerrno>
#include <cstdio>
#include <sys/socket.h>
#include <unistd.h>
int main() {
    using namespace magi::fingerprint;
    const auto packet=encode({{42,7,1000},Event::Match});
    int sockets[2];assert(socketpair(AF_UNIX,SOCK_SEQPACKET|SOCK_CLOEXEC,0,sockets)==0);
    const auto sent=send(sockets[0],packet.data(),packet.size(),0);
    if(sent<0 && (errno==EPERM || errno==EACCES)) {
        std::perror("Sandbox denied private SOCK_SEQPACKET send; transport validation pending");
        close(sockets[0]);close(sockets[1]);return 77;
    }
    assert(sent==32);Packet received{};assert(recv(sockets[1],received.data(),received.size(),MSG_TRUNC)==32);assert(received==packet);
    close(sockets[0]);assert(recv(sockets[1],received.data(),received.size(),0)==0);close(sockets[1]);
}
