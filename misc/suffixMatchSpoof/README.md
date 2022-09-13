suffixMatchSpoof
---

This variant utilizes, `dnsdist` built-in method - `SuffixMatchNode`.

Pros
----
- Simple
- Uses built-in methods 
- Customizable - by changing the parameters passed to `addAction` you can change the behaviour (block,allow,modify) for a matched domain.

Cons
----
- As we create a new object for every domain, it's not very efficient.


Installation
---

1. Create a `conf.d` folder in your `dnsdist` configuration folder (the default is `/etc/dnsdist`)
2. Copy `suffixMatchSpoof.lua` (from `dagg/suffixMatchSpoof.lua`), rename it to `.conf` (e.g. `/etc/dnsdist/conf.d/suffixMatchSpoof.conf`) 
3. Customize it to match your setup:
3.1. Change the path to your blocklist by modifying the `blocklistPath` variable
4. Add the following snippet at the end of your `dnsdist` configuration file (usually `/etc/dnsdist/dnsdist.conf`)

```lua
-- Include additional configuration
includeDirectory("/etc/dnsdist/conf.d")
```

_Note: Change the path of the directory, accordingly on your system!_

5. Restart `dnsdist` (e.g. `systemctl restart dnsdist` or `service dnsdist restart`)
