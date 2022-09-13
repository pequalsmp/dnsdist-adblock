dagg
---

This is a very basic approach to domain filtering. It's reads the blocklist upon reload and keeps the domains in memory. Thus it is not feasible for large lists or multiple DAG lists.

Pros
----
- Simple, no external dependencies (other than `sed`)

Cons
----
- High memory usage (depends on the size of the blocklist, roughly a million entries consumes > 150MiB)

Requirements
---

- `sed` as a post-processing workaround

Installation
---

1. Create a `conf.d` folder in your `dnsdist` configuration folder (the default is `/etc/dnsdist`)
2. Copy `dagg.lua` (from `dagg/dagg.lua`), rename it to `.conf` (e.g. `/etc/dnsdist/conf.d/dagg.conf`) 
3. Customize it to match your setup, 
    - Set `Dagg.config.blocklist.path`
    - Set `Dagg.config.reload.target` to a non-existant FQDN, in order to trigger re/load of the blocklist
4. Add the following snippet at the end of your `dnsdist` configuration file (usually `/etc/dnsdist/dnsdist.conf`)

```lua
-- Include additional configuration
includeDirectory("/etc/dnsdist/conf.d")
```

_Note: Change the path of the directory, accordingly on your system!_

5. Restart `dnsdist` (e.g. `systemctl restart dnsdist` or `service dnsdist restart`)
6. Reload the blocklist (by sending a query to the FQDN you set as `Dagg.config.reload.target`) to your `dnsdist` instance

Re/Loading
--- 

1. To prevent DNS outages, the blocklist is *NOT* automatically loaded at startup, this has to be done manually or via script
2. It's recommended to query the `reload` domain, every-time you update your blocklist
3. You can specify anything for `reload` domain, however sticking to pre-defined reserved-use domains (like `.local`) is recommended
