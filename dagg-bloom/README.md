dagg-bloom
---

This approach uses a bloom filter to match query to a domain in a blocklist. Guarantees false-negatives are not possible, but false-positives are probabilistic and depend on the chosen probaility.

Pros
----
- Tunable memory usage. You can tweak the false-positive `probability` ratio in order to increase/decrease the memory usage.

Cons
----
- More complex, requires setting up file-system paths and setting up the directories correctly
- More resource-intensive (every domain query has to hashed with the `xxHash` algorithm; though the algorithm is very fast)