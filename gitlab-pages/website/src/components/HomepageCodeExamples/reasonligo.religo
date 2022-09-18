type storage = int;

type parameter =
  Increment (int)
| Decrement (int)
| Reset;

// Two entrypoints

let add = ((store, delta) : (storage, int)) => store + delta;
let sub = ((store, delta) : (storage, int)) => store - delta;

/* Main access point that dispatches to the entrypoints according to
   the smart contract parameter. */

let main = ((action, store) : (parameter, storage)) => {
 ([],    // No operations
 (switch (action) {
  | Increment (n) => add ((store, n))
  | Decrement (n) => sub ((store, n))
  | Reset         => 0}))
};

/* Tests for main access point */

let test_initial_storage = {
  let initial_storage = 42;
  let (taddr, _, _) = Test.originate(main, initial_storage, 0tez);
  assert (Test.get_storage(taddr) == initial_storage)
};

let test_increment = {
  let initial_storage = 42;
  let (taddr, _, _) = Test.originate(main, initial_storage, 0tez);
  let contr = Test.to_contract(taddr);
  let _ = Test.transfer_to_contract_exn(contr, (Increment (1)), 1mutez);
  assert (Test.get_storage(taddr) == initial_storage + 1)
};