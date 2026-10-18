#include "instance_guard.hpp"
#include <sys/file.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
namespace magi {
InstanceGuard::~InstanceGuard() { if (fd_ >= 0) close(fd_); }
bool InstanceGuard::acquire(const std::string& directory, const std::string& display) {
    if (fd_ >= 0 || display.empty() || display.size()>100 || display.find_first_not_of("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.")!=std::string::npos) return false;
    const int dir = open(directory.c_str(), O_DIRECTORY|O_NOFOLLOW|O_CLOEXEC|O_RDONLY);
    if (dir<0) return false;
    struct stat st{};
    if (fstat(dir,&st) || st.st_uid!=getuid() || (st.st_mode&077)!=0) { close(dir); return false; }
    const auto name="magi-lock-"+display+".lock";
    const int fd=openat(dir,name.c_str(),O_CREAT|O_NOFOLLOW|O_CLOEXEC|O_RDWR,0600);
    close(dir);
    if (fd<0) return false;
    if (fstat(fd,&st) || !S_ISREG(st.st_mode) || st.st_uid!=getuid() || st.st_nlink!=1 || (st.st_mode&077)!=0 || flock(fd,LOCK_EX|LOCK_NB)) { close(fd); return false; }
    fd_=fd; return true; // Never unlink: avoids two concurrently locked inodes.
}
}
