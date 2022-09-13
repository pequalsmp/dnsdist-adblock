What is this?
---

[dnsdist](http://dnsdist.org/) is an amazing piece of software, and it did everything I asked for (and more).

However, after lots of searching, I haven't found a good example of someone doing domain blocking in an automated manner.

Usually the examples are referring to a single domain or wildcard blocking, but I wanted to do something more robust.

Intro
---

This repository contains scripts that can be used for automated & aggregated domain blocking/spoofing (usually used for ad/malware/phishing filtering).

Format
---

- The scripts expect a blocklist in the following format - single `IDNA`-encoded domain per line, followed by a UNIX newline - `0xA`.

For example:

```
github.com
www.github.com
```

Variants
---

- dagg

This is a simple, plain-text comparison, where the domains are being loaded in RAM. Simple, but consumes lots of memory and it can only do direct comparisons.

- dagg-ffi

More complex version (it needs external library) of `dagg`. Introduces the usage of probabilistic filters (binary fuse filter).

This version uses far less resources (theoretically, it should use about 8 MiB per million entries), though the probabilistic nature of the filters may not
be suitable for everyone

- misc/addDomainBlock

Uses built-in methods within `dnsdist`. This offers more customization and flexibility, but it's not very efficient and it can't handle larger blocklists.

- misc/blockFilter

Uses built-in methods within `dnsdist`. This offers more customization and flexibility, but it's not very efficient and it can't handle larger blocklists.
It also sinkholes domains without responding to the client, allowing them to timeout. Useful when you want to drop queries.

- misc/suffixMatchSpoof

Uses built-in methods within `dnsdist`. This is being used as part of `dagg`, in order to handle wildcard domains.

What variant should i pick?
---

It depends on your use-case (and functionality), but, in general, if all you care about is domain count:

- 1 - 100000 domains

Pick any of the `misc` approaches. This gives you the most flexibility and are generally the easiest to use / implement

- 100,000 - 1,000,000 domains

Pick `dagg`, it'll need a few hundred MiB of RAM, but you don't have to compile additional libraries and it's a bit faster, per-query

- more than 1,000,000 domains

Pick `dagg-ffi`. It's the most restrictive, but with so much domains, you could drastically slow-down `dnsdist` if you're using any
of the previous methods.

These are just generic suggestions. It's best to try out the different methods and see which suits you best.

What does `dagg` mean?
---

Nothing. It is a portmanteau of domain aggregator.

TODO
---

- There are probably, more efficient ways for domain comparison, within `dnsdist` engine
- Use built-in methods, but reduce memory usage. Built-in methods are a more flexible approach, when it comes to a domain declaration (usage of wildcard etc.)

