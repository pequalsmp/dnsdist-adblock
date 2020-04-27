dagg
---

This is a very basic approach to domain filtering. It's reading the list of the domains (when triggered via reload) and keeps the domains in memory. Thus it is not feasible for large lists or multiple DAG lists.

Pros
----
- Simple, no dependencies

Cons
----
- High memory usage, depending on the size of the blocklist