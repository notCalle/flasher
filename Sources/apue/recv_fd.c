//
//  recv_fd.c
//  flasher
//
//  Created by Calle Englund on 2019-09-22.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

#include "include/recv_fd.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/termios.h>
#include <sys/ioctl.h>

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <sys/socket.h>
#include <sys/un.h>

#define MAXLINE 4096            /* max line length */

int recv_fd(int fd)
{
    static struct cmsghdr *cmptr = NULL;

    if (NULL == cmptr) {
        if (!(cmptr = calloc(1, CMSG_LEN(sizeof(int))))) {
            return -1;
        }
    }

    for (;;) {
        char buf[MAXLINE];
        char *ptr;
        struct iovec iov[1];
        struct msghdr msg;
        ssize_t nr;
        int newfd = -1;

        iov[0].iov_base = buf;
        iov[0].iov_len = sizeof(buf);
        msg.msg_iov = iov;
        msg.msg_iovlen = 1;
        msg.msg_name = NULL;
        msg.msg_namelen = 0;
        msg.msg_control = cmptr;
        msg.msg_controllen = CMSG_LEN(sizeof(int));
        if (0 > (nr = recvmsg(fd, &msg, 0))) {
            fprintf(stderr, "recvmsg error");
            return -1;
        } else if (0 == nr) {
            fprintf(stderr, "connection closed");
            return -1;
        }
        for (ptr = buf; ptr < &buf[nr]; ) {
            struct cmsghdr *cmp;
            int status = -1;

            if (0 == *ptr++) {
                if (ptr != &buf[nr-1]) {
                    fprintf(stderr, "message format error");
                    return -1;
                }
                status = *ptr & 0xFF;
                if (0 == status) {
                    if (CMSG_LEN(sizeof(int)) != msg.msg_controllen) {
                        fprintf(stderr, "status = 0, but no fd was sent");
                        return -1;
                    }
                    for (cmp = CMSG_FIRSTHDR(&msg);
                         NULL != cmp;
                         cmp = CMSG_NXTHDR(&msg, cmp))
                    {
                        if (SOL_SOCKET != cmp->cmsg_level) continue;

                        if (SCM_RIGHTS == cmp->cmsg_type) {
                            newfd = *(int *)CMSG_DATA(cmp);
                            break;
                        }
                    }
                } else {
                    newfd = -status;
                }
                nr -= 2;
            }
        }
        return newfd;
    }
}
