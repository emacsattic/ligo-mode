type inner_storage = (int,"one",nat,"two") michelson_pair
type storage = (int,"three",inner_storage,"four") michelson_pair

type return = operation list * storage

[@entry]
let main (action : unit) (store : storage) : return =
  let foo = (3,(1,2n)) in
  (([] : operation list), (foo: storage))