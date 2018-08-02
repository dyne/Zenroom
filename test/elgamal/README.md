## Keygen

```
zenroom keygen.lua > key.json
```


## Initialize the votes to 0

```
zenroom -k key.json init.lua > votes.json
```

and verify that all votes are 0

```
zenroom -a votes.json verify_init.lua
```

## Vote 

```
zenroom -a votes.json vote.lua > votes2.json; mv votes2.json votes.json
zenroom -a votes.json verify_vote.lua
```

and verify that votes are all 0 or 1, and the sum of all the addition is 1

- On the voting ballot we only add 1 or 0
- We don't add multiple votes (various 1's)


## Tally

```
zenroom -k key.json -a votes.json tally.lua 
```




# Execute all!

```
zenroom keygen.lua > key.json

zenroom -k key.json init.lua > votes.json
zenroom -a votes.json verify_init.lua

zenroom -a votes.json vote.lua > votes2.json; mv votes2.json votes.json
zenroom -a votes.json verify_vote.lua
zenroom -a votes.json vote.lua > votes2.json; mv votes2.json votes.json
zenroom -a votes.json verify_vote.lua
zenroom -a votes.json vote.lua > votes2.json; mv votes2.json votes.json
zenroom -a votes.json verify_vote.lua
zenroom -a votes.json vote.lua > votes2.json; mv votes2.json votes.json
zenroom -a votes.json verify_vote.lua

zenroom -k key.json -a votes.json tally.lua 
```