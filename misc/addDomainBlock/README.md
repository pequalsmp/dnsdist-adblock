addDomainBlock
---

This method utilizes, `dnsdist` built-in `addDomainBlock` method.

Pros
----
- Simple - it relies on a built-in method for domain blocking.
- Uses built-in method

Cons
----
- Really slow at startup (especially with more than a few thousand domains). So slow in fact that the default configuration times-out
- No control over the response