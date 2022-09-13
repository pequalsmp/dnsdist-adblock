blockFilter
---

This variant utilizes, `dnsdist` built-in method - `blockFilter`.

Pros
----
- Simple
- Uses built-in method
- Loads on startup
- Fastest?

Cons
----
- `dnsdist` will send the query upstream
- No control over the response - this means that `dnsdist` will not respond to a matched query, which will leave clients hanging for a long periods of time (5-15s), until the software decides to timeout.

Installation
---

1. Create a `conf.d` folder in your `dnsdist` configuration folder (the default is `/etc/dnsdist`)
2. Copy `blockFilter.lua` (from `dagg/blockFilter.lua`), rename it to `.conf` (e.g. `/etc/dnsdist/conf.d/blockFilter.conf`) 
3. Customize it to match your setup:
3.1. Change the path to your blocklist by modifying the `blocklistPath` variable
4. Add the following snippet at the end of your `dnsdist` configuration file (usually `/etc/dnsdist/dnsdist.conf`)

```lua
-- Include additional configuration
includeDirectory("/etc/dnsdist/conf.d")
```

_Note: Change the path of the directory, accordingly on your system!_

5. Restart `dnsdist` (e.g. `systemctl restart dnsdist` or `service dnsdist restart`)
