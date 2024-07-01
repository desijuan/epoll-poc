const std = @import("std");

const linux = std.os.linux;

const print = std.debug.print;

const READ_SIZE = 16;
const MAX_EVENTS = 8;

var buffer: [READ_SIZE]u8 = undefined;

pub fn main() u8 {
    const epoll_fd: i32 = @intCast(linux.epoll_create1(0));

    if (epoll_fd == -1) {
        print("Failed to create epoll file descriptor\n", .{});
        return 1;
    }

    var epoll_event = linux.epoll_event{
        .events = linux.EPOLL.IN,
        .data = .{
            .fd = 0,
        },
    };

    if (linux.epoll_ctl(epoll_fd, linux.EPOLL.CTL_ADD, 0, &epoll_event) != 0) {
        print("Failed to add file descriptor to epoll\n", .{});
        _ = linux.close(epoll_fd);
        return 1;
    }

    var epoll_events: [MAX_EVENTS]linux.epoll_event = undefined;

    var bytes_read: usize = 0;

    loop: while (true) {
        print("Polling for input...\n", .{});

        const event_count = linux.epoll_wait(epoll_fd, &epoll_events, @as(u32, MAX_EVENTS), -1);
        print("\n{d} ready events\n", .{event_count});

        for (0..event_count) |i| {
            const fd = epoll_events[i].data.fd;
            print("Reading file descriptor {d} -- ", .{fd});
            bytes_read = linux.read(fd, &buffer, READ_SIZE);
            print("{d} bytes read.\n", .{bytes_read});
            print("Read: {s}\n", .{buffer[0..bytes_read]});

            if (std.mem.eql(u8, buffer[0..4], "stop"))
                break :loop;
        }
    }

    if (linux.close(epoll_fd) != 0) {
        print("Failed to close epoll file descriptor\n", .{});
        return 1;
    }

    return 0;
}
