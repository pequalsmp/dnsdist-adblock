blockFilter
---

This method utilizes the built-in method `blockFilter`.

Pros
----
- Simple - it relies on a built-in method for domain blocking.
- Fastest?

Cons
----
- `dnsdist` will send the query upstream
- No control over the response - this means that `dnsdist` will not respond to a matched query, which will leave clients hanging for a long periods of time (5-15s), until the software decides to timeout.