suffixMatchSpoof
---

This method utilizes `dnsdist`'s `SuffixMatchNode` method and we're simply pre-loading the domains as new domains in a `SuffixMatchNode`.

Pros
----
- Uses built-in methods and the comparison is done entirely by `dnsdist`
- Customizable - by changing the parameters passed to `addAction` you can change the behaviour (block,allow,modify) for a matched domain.

Cons
----
- As we create a new object for every domain, this approach has really high memory requirements, even for small lists, with a few thousand domains.
