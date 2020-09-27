# Matchmaker

Hacky, quick, dirty and very much brute force one-sided marriage problem
solver. Will assign participants to groups based on their preferences,
optimizing for participants "happiness"

## Usage

```
cat data.csv | GROUP_SIZE=10 ROUNDS=500 matchmaker
```

Where data.csv a 2 column file with participants with their ranked preferred choices:

```csv
Participants, Choices
Participant A, Group 1
Participant A, Group 2
Participant A, Group 3
Participant B, Group 3
Participant B, Group 1
Participant B, Group 2
...
```

And

* `GROUP_SIZE` Number of places available per group (default 1)
* `ROUNDS` Number of permutations to build before choosing the best one (default 1000)
* `VERBOSE` Print stats about the results (default false)

