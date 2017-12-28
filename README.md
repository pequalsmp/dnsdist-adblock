# What is this?

[dnsdist](http://dnsdist.org/) is an amazing piece of software and it did everything i asked for (and more), but after lots of searching i haven't found a good example of someone doing domain blacklisting in an automated manner.

Usually the examples are referring to a single domain or wildcard blacklisting, but i wanted to do something more robust.

Intro
-

This repository contains a couple of scripts that can be used for automated & aggregated domain blacklisting (usually used for ad/malware/malicious/phishing blocking). Depending on the use-case and implementation, some scripts might more applicable. Choose carefully and test to see, what works best for you.

Installation
-

1. Add the following to your `dnsdist.conf`

```lua
-- Include additional configuration
includeDirectory("/etc/dnsdist/conf.d")
```
_Note: Change the dir path, accordingly on your system!_

2. Rename the file (containing your preferred blocking method) from `<file>.lua` to `<file>.conf`.

e.g:

`addLuaAction.lua` becomes `addLuaAction.conf`

3. Customize your chosen method. `dnsdist`'s [documentation](http://dnsdist.org/README/) is just a glimpse into how powerful dnsdist really is. Remember, the configuration files are actually `Lua` scripts, with all the power that comes from a scripting language

Methods
-

### addDomainBlock

This method utilizes, `dnsdist` built-in `addDomainBlock` method.

Pros:

- Simple
- Uses built-in method

Cons:

- Really slow at startup (especially with more than a few thousand domains). So slow in fact that the default configuration times-out
- No control over the response


### addLuaAction

This method adds a blank rule (as example, you can easily customize this by changing `AllRule()` condition).

Pros:

- Customizable - it allows you to choose the response type, the type of domain-matching, the action that follows, etc.
- Fast - this will skip querying upstream and it will immediately return `NXDOMAIN` (some software treats this as filtering and reverts to hard-coded ips).
- Fastest?

Cons:

- Complicated - its inserted in every query

### blockFilter

This method utilizes the built-in method `blockFilter`.

Pros:

- Simple - it relies on a built-in method for domain blocking.
- Fastest?

Cons:

- `dnsdist` will send the query upstream, it simply won't respond.
- No control over the response - this means that `dnsdist` will not respond to a matched query, which will leave clients hanging for a long periods of time (5-15s), until the software decides to timeout.


### suffixMatchSpoof

This method utilizes `dnsdist`'s `SuffixMatchNode` method and we're simply pre-loading the domains as new domains in a `SuffixMatchNode`.

Pros:

- Uses built-in methods and the comparison is done entirely by `dnsdist`
- Customizable - by changing the parameters passed to `addAction` you can change the behaviour (block,allow,modify) for a matched domain.

Cons:

- As we create a new object for every domain, this approach has really high memory requirements, even for small lists, with a few thousand domains.

Improvements
-

- There are probably more efficient ways of comparing a domain (from a query) to a domain, in a  blacklist.
- Use built-in methods, but reduce memory usage, as using the built-in methods is more flexible approach, when it comes to a domain declaration (usage of wildcard etc.)
- Integrate with `dnsdist`'s API, so a user can: track blocked domains, monitor usage and manage domains on-the-go.

Limitations
-

- The blacklist domains are currently case-sensitive.
- The only way to reload the blacklist is by restarting `dnsdist` itself.
