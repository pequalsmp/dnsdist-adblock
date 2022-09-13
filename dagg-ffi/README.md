dagg-ffi
---

Using a [binary fuse filter](https://github.com/FastFilter/xor_singleheader) and [xxhash](https://github.com/Cyan4973/xxHash), this should allow for a more scalable in-memory blocklist.

Pros
---

- (should be) faster
- (should) scale further

Cons
---

- More complex, requires an external library (`libdagg`, part of this project)

Requirements
---

1. `LuaJIT` with `ffi` built-in and enabled
2. `gcc`
3. `make`
4. `sed` as post-processing workaround

Installation
---

1. Create a `conf.d` folder in your `dnsdist` configuration folder (the default is `/etc/dnsdist`)
2. Copy `dagg-ffi.lua` (from `dagg-ffi/dagg-ffi.lua`), rename it to `.conf` (e.g. `/etc/dnsdist/conf.d/dagg-ffi.conf`)
3. Customize it to match your setup,
    - Set `Dagg.config.blocklist.path`
    - Set `Dagg.config.reload.target` to a non-existant FQDN, in order to trigger re/load of the blocklist
4. Add the following snippet at the end of your `dnsdist` configuration file (usually `/etc/dnsdist/dnsdist.conf`)

```lua
-- Include additional configuration
includeDirectory("/etc/dnsdist/conf.d")
```

_Note: Change the path of the directory, accordingly on your system!_

5. Compile `libdagg` (there's a paragraph below on how to do this)
6. Place `libdagg.so` in `/usr/local/lib/` (or the equivalent on your system)
7. Restart `dnsdist` (e.g. `systemctl restart dnsdist` or `service dnsdist restart`)
8. Reload the blocklist (by sending a query to the FQDN you set as `Dagg.config.reload.target`) to your `dnsdist` instance

`libdagg` Compilation
---

1. Clone this project
2. Run `git submodule init` and `git submodule update`
3. `cd` into `dagg-ffi/libdagg`
4. Run `make clean` and `make`
5. Copy the resulting file (`libdagg.so`), to a directory within your `LD_LIBRARY_PATH`

Re/Loading
--- 

1. To prevent DNS outages, the blocklist is *NOT* automatically loaded at startup, this has to be done manually or via script
2. It's recommended to query the `reload` domain, every-time you update your blocklist
3. You can specify anything for `reload` domain, however sticking to pre-defined reserved-use domains (like `.local`) is recommended
