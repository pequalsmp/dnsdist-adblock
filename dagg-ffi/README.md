dagg-ffi
---

Using a [binary fuse filter](https://github.com/FastFilter/xor_singleheader) and [xxhash](https://github.com/Cyan4973/xxHash), this should allow for a more scalable in-memory blocklist.

Pros
----
- (should be) faster
- (should) scale further

Cons
----
- More complex, requires external library

Requirements
---

1. `dnsdist` compiled with `LuaJIT`
2. `sed` as a workaround to post-process the domain-list

Compile
---

1. Run `git submodule init` and `git submodule update`
2. Run `make clean` and `make`

Setup
---

1. Compile `libdagg`
2. Place `libdagg` in `/usr/local/lib/` (or the equivalent on your system)
3. Copy `dagg-ffi.lua` to `/etc/dnsdist/conf.d/dagg-ffi.conf`
4. Adjust the default settings in `/etc/dnsdist/conf/dagg-ffi.conf` (the file you just copied in the previous step) to match your Setup
