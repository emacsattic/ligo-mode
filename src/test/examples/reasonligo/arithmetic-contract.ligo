(*_*
  name: ReasonLIGO Contract
  language: reasonligo
  compile:
    entrypoint: main
  dryRun:
    entrypoint: main
    parameters: Increment (1)
    storage: 0
  deploy:
    entrypoint: main
    storage: 0
  evaluateValue:
    entrypoint: ""
  evaluateFunction:
    entrypoint: add
    parameters: (5, 6)
  generateDeployScript:
<<<<<<< HEAD
    tool: tezos-client
=======
>>>>>>> bc2d95d6f6dd4959097e5b6cdb19bce0cc6b3c01
    entrypoint: main
    storage: 0
*_*)
type storage = int;

/* variant defining pseudo multi-entrypoint actions */

type action =
  | Increment(int)
  | Decrement(int);

let add = ((a,b): (int, int)): int => a + b;
let sub = ((a,b): (int, int)): int => a - b;

/* real entrypoint that re-routes the flow based on the action provided */

let main = ((p,storage): (action, storage)) => {
  let storage =
    switch (p) {
    | Increment(n) => add((storage, n))
    | Decrement(n) => sub((storage, n))
    };
  ([]: list(operation), storage);
};
