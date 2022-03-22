What is this?
---

[dnsdist](http://dnsdist.org/) is an amazing piece of software, and it did everything I asked for (and more).

However, after lots of searching, I haven't found a good example of someone doing domain blocking in an automated manner.

Usually the examples are referring to a single domain or wildcard blocking, but I wanted to do something more robust.

Intro
---

This repository contains scripts that can be used for automated & aggregated domain blocking/spoofing (usually used for ad/malware/phishing protection).

Installation
---

1. Create `conf.d` folder in your `dnsdist` configuration folder (the default is `/etc/dnsdist`)

2. Copy `dagg.lua` (from `dagg/dagg.lua`), rename the file to `.conf` (e.g. `/etc/dnsdist/conf.d/dagg.conf`) 

3. Customize it to match your setup, i.e. change `Dagg.config.blocklist.path` and `Dagg.config.reload.target`

4. Add the following snippet to your `dnsdist.conf`

```lua
-- Include additional configuration
includeDirectory("/etc/dnsdist/conf.d")
```
_Note: Change the path of the directory, accordingly on your system!_

5. Restart `dnsdist` (e.g. `systemctl restart dnsdist` or `service dnsdist restart`)

6. Reload the blocklist by sending a query for `Dagg.config.reload.target` to your `dnsdist` instance

Notes
--- 

1. To prevent DNS outages, the blocklist is *NOT* automatically loaded at startup, this has to be done manually (via script) or you can simply edit the script to your liking
2. It's recommended to query the `reload` domain, every-time you update your blocklist
3. You can specify anything for `reload` domain, however sticking to pre-defined reserved-use domains (like `.local`) is recommended

Improvements
---

- There are probably, more efficient ways of comparing a domain, from a query, to a domain, in a blocklist.
- Use built-in methods, but reduce memory usage. Built-in methods are a more flexible approach, when it comes to a domain declaration (usage of wildcard etc.)
- Integrate with `dnsdist`'s API for: track blocked domains, monitor usage and manage domains on-the-go.


Notes
---

- You can find experimental implementations utilizing `dnsdist` API, in the `misc` directory.

- The scripts expect a blocklist in the following format - single `IDNA`-encoded domain per line, separated by a UNIX newline `0xA`.
