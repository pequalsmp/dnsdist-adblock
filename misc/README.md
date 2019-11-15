addDomainBlock
---

This method utilizes, `dnsdist` built-in `addDomainBlock` method.

Pros:

- Simple
- Uses built-in method

Cons:

- Really slow at startup (especially with more than a few thousand domains). So slow in fact that the default configuration times-out
- No control over the response

blockFilter
---

This method utilizes the built-in method `blockFilter`.

Pros:

- Simple - it relies on a built-in method for domain blocking.
- Fastest?

Cons:

- `dnsdist` will send the query upstream, it simply won't respond.
- No control over the response - this means that `dnsdist` will not respond to a matched query, which will leave clients hanging for a long periods of time (5-15s), until the software decides to timeout.


suffixMatchSpoof
---

This method utilizes `dnsdist`'s `SuffixMatchNode` method and we're simply pre-loading the domains as new domains in a `SuffixMatchNode`.

Pros:

- Uses built-in methods and the comparison is done entirely by `dnsdist`
- Customizable - by changing the parameters passed to `addAction` you can change the behaviour (block,allow,modify) for a matched domain.

Cons:

- As we create a new object for every domain, this approach has really high memory requirements, even for small lists, with a few thousand domains.
