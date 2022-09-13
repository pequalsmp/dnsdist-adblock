addDomainBlock
---

This variant utilizes, `dnsdist` built-in method - `addDomainBlock`.

Pros
----
- Simple
- Uses built-in method
- Load on startup

Cons
----
- Really slow at startup (especially with more than a few thousand domains). So slow, that the default configuration times-out
- No control over the response

Installation
---

1. Create a `conf.d` folder in your `dnsdist` configuration folder (the default is `/etc/dnsdist`)
2. Copy `addDomainBlock.lua` (from `dagg/addDomainBlock.lua`), rename it to `.conf` (e.g. `/etc/dnsdist/conf.d/addDomainBlock.conf`) 
3. Customize it to match your setup:
3.1. Change the path to your blocklist by modifying the `blocklistPath` variable
4. Add the following snippet at the end of your `dnsdist` configuration file (usually `/etc/dnsdist/dnsdist.conf`)

```lua
-- Include additional configuration
includeDirectory("/etc/dnsdist/conf.d")
```

_Note: Change the path of the directory, accordingly on your system!_

5. Restart `dnsdist` (e.g. `systemctl restart dnsdist` or `service dnsdist restart`)
