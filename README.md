What is this?
---

[dnsdist](http://dnsdist.org/) is an amazing piece of software and it did everything i asked for (and more).

However, after lots of searching, i haven't found a good example of someone doing domain blocking in an automated manner.

Usually the examples are referring to a single domain or wildcard blocking, but i wanted to do something more robust.

Intro
---

This repository contains scripts that can be used for automated & aggregated domain blocking/spoofing (usually used for ad/malware/phishing protection).

Installation
---

1. Copy `conf.d` folder to your `dnsdist` configuration folder. The default is `/etc/dnsdist`

2. Customize the `dagg.lua` file to match your setup, i.e. change `dagg.config.blocklist.path` and `dagg.config.reload.target`

3. Add the following to your `dnsdist.conf`

```lua
-- Include additional configuration
includeDirectory("/etc/dnsdist/conf.d")
```
_Note: Change the dir path, accordingly on your system!_

4. Restart dnsdist

5. Trigger blocklist reload by sending a query for `dagg.config.reload.target` to your dnsdist instance

6. Integrate the query lookup into your script/program and run it, whenever the blocklist has been updated

Improvements
---

- There are probably, more efficient ways of comparing a domain, from a query, to a domain, in a blocklist.
- Use built-in methods, but reduce memory usage. Built-in methods are a more flexible approach, when it comes to a domain declaration (usage of wildcard etc.)
- Integrate with `dnsdist`'s API for: track blocked domains, monitor usage and manage domains on-the-go.


Notes
---

- You can find experimental implementations utilizing `dnsdist` API, in the `misc` directory.

- The scripts expect a blocklist in the following format - single `IDNA`-encoded domain per line, seperated by a UNIX newline `0xA`.
