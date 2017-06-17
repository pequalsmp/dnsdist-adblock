# What is this?

[dnsdist](http://dnsdist.org/) is an amazing piece of software and did everything asked for (and more), but after lots of searching i haven't found someone doing domain blacklisting in an automated way.

Usually the examples are referring to a single domain or wildcard blacklisting, but i wanted something more robust.

Intro
-

This repository contains a couple of scripts that can be used for aggregated domain blacklisting (usually used for ad/malware/malicious/phishing blocking).

Installation
-

1. Add the following to your `dnsdist.conf`

```lua
-- Include additional configuration
includeDirectory("/etc/dnsdist/conf.d")
```
_Note: Change the path to the folder accordingly on your system_

2. Rename the file (containing your prefered blocking method) from `<file>.lua` to `<file>.conf`.

For example:

`addLuaAction.lua` becomes `addLuaAction.conf`

3. Customize the file however you wish. dnsdist's [documentation](http://dnsdist.org/README/) is just a glimpse into how powerful dnsdist really is. Remember, the configuration files are actually `Lua` scripts.

Methods
-

### addDomainBlock

This method utilizes, dnsdist built-in `addDomainBlock` method.

Pros:

- Simple
- Uses built-in method

Cons:

- Really slow at startup (especially with more than a few thousand domains). So slow in fact that the default configuration times-out
- No control over the response


### addLuaAction

This method adds a blank rule (as example, you can easily customize this by changing `AllRule()`).

Pros:

- Customizable - it allows you to choose what response type, the matching, the action etc. The current example will return `NXDOMAIN` and it will respond directly, saving traffic on the upstream.
- Fastest?

Cons:

- More complicated, its interested in every query, probably affecting the processing pipeline by inefficient comparisons

### blockFilter

This method utilizes the built-in method `blockFilter`.

Pros:

- Simple - it relies on a built-in method for exactly this purpose.
- Fastest?

Cons:

- No control over the response. This means that the blocked domains will timeout leaving the clients hanging for a long periods of time (5-15s).

### suffixMatchSpoof

This method utilizes dnsdist's SuffixMatchNode method and we're simply pre-loading the domains as new domains in a `SuffixMatchNode`.

Pros:

- Uses built-in methods and the comparison is done entirely by dnsdist
- Customizable, by changing the parameters passed to `addAction` you can change the behaviour of a modified domain

Cons:

- As we create new object for every domain, this approach has really high memory requirements even for small lists with a few thousand domains.

Improvements
-

- There are probably more efficient ways of comparing a domain in a query to a blacklist.
- Use built-in methods, but reduce the memory usage as using the built-in methods allows for more flexibility when it comes to a domain definition (usage of wildcard etc.)
- Integrate with the API, so the user has the capability to track blocked domains, monitor usage and feed domains on-the-go.

Limitations
-

- The blacklist domains are currently case-sensitive
- The only way to reload the blacklist is by restarting dnsdist itself
