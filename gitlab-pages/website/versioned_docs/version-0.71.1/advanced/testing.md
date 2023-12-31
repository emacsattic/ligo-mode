---
id: testing
title: Testing LIGO
---

import Syntax from '@theme/Syntax';
import Link from '@docusaurus/Link';

## Testing LIGO code

The LIGO command-line interpreter provides commands to
directly test your LIGO code. The three main commands we currently
support are:

* `ligo run test`

* `ligo run interpret`

* `ligo run dry-run`

We will show how to use the first two, while an example on how to use
the third one was already explained
[here](first-contract.md#dry-running-a-contract).

### Testing with `ligo run test`

The command `ligo run test` can be used to test a contract using LIGO.

> ⚠️ Please keep in mind that this command is still BETA, and that
> there are features that are work in progress and are subject to
> change. No real test procedure should rely on this command alone.

When running the `ligo run test` command, LIGO code has access to an
additional `Test` module. This module provides ways of originating
contracts and executing transactions, as well as additional helper
functions that allow to control different parameters of the Tezos
testing library.

> Note: The LIGO interpreter uses the [same library that Tezos internally uses for testing](https://gitlab.com/tezos/tezos/-/tree/master/src/proto_alpha/lib_protocol/test/helpers).

The function `Test.originate` allows to deploy a contract in the
testing environment. It takes a contract, which is represented as a
function of type `'parameter * 'storage -> operation list * 'storage`,
an initial storage of type `'storage`, and an initial balance for the
contract being deployed. This function deploys the contract, and
returns the type `('parameter, 'storage) typed_address`, the compiled
program in Michelson of type `michelson_program`, and the size of the
program of type `int`.

The storage of a deployed contract can be queried using the
`Test.get_storage` function, that given a typed address `('parameter,
'storage) typed_address`, returns the `'storage` value.

As a concrete example, suppose we have the following contract:
<Syntax syntax="pascaligo">

```pascaligo test-ligo group=frontpage
// This is testnew.ligo
type storage is int

type parameter is
  Increment of int
| Decrement of int
| Reset

type return is list (operation) * storage

// Two entrypoints
function add (const store : storage; const delta : int) : storage is
  store + delta

function sub (const store : storage; const delta : int) : storage is
  store - delta

(* Main access point that dispatches to the entrypoints according to
   the smart contract parameter. *)

function main (const action : parameter; const store : storage) : return is
 ((nil : list (operation)),    // No operations
  case action of [
    Increment (n) -> add (store, n)
  | Decrement (n) -> sub (store, n)
  | Reset         -> 0
  ])
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo test-ligo group=frontpage
// This is testnew.mligo
type storage = int

type parameter =
  Increment of int
| Decrement of int
| Reset

type return = operation list * storage

// Two entrypoints

let add (store, delta : storage * int) : storage = store + delta
let sub (store, delta : storage * int) : storage = store - delta

(* Main access point that dispatches to the entrypoints according to
   the smart contract parameter. *)

let main (action, store : parameter * storage) : return =
 ([] : operation list),    // No operations
 (match action with
   Increment (n) -> add (store, n)
 | Decrement (n) -> sub (store, n)
 | Reset         -> 0)
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo test-ligo group=frontpage
// This is testnew.jsligo
type storage = int;

type parameter =
  ["Increment", int]
| ["Decrement", int]
| ["Reset"];

type @return = [list<operation>, storage];

// Two entrypoints
const add = (store: storage, delta: int): storage => store + delta;
const sub = (store: storage, delta: int): storage => store - delta;

/* Main access point that dispatches to the entrypoints according to
   the smart contract parameter. */
const main = (action: parameter, store: storage) : @return => {
  return [
    list([]) as list<operation>,    // No operations
    match(action, {
      Increment:(n: int) => add (store, n),
      Decrement:(n: int) => sub (store, n),
      Reset: ()          => 0})
  ]
};
```

</Syntax>

We can deploy it and query the storage right after, to check that the
storage is in fact the one which we started with:

<Syntax syntax="pascaligo">

```pascaligo test-ligo group=frontpage
// This continues testnew.ligo

const test = {
  const initial_storage = 42;
  const (taddr, _, _) = Test.originate (main, initial_storage, 0tez);
  const storage = Test.get_storage (taddr);
} with storage = initial_storage;

```

</Syntax>
<Syntax syntax="cameligo">

```cameligo test-ligo group=frontpage
// This continues testnew.mligo

let test =
  let initial_storage = 42 in
  let taddr, _, _ = Test.originate_uncurried main initial_storage 0tez in
  assert (Test.get_storage taddr = initial_storage)
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo test-ligo group=frontpage
// This continues testnew.jsligo

let _test = () : bool => {
  let initial_storage = 42 as int;
  let [taddr, _, _] = Test.originate(main, initial_storage, 0 as tez);
  return (Test.get_storage(taddr) == initial_storage);
};

let test = _test();
```

</Syntax>

The test sub-command will evaluate all top-level definitions and print any
entries that begin with the prefix `test` as well as the value that these
definitions evaluate to. If any of the definitions are found to have
failed, a message will be issued with the line number where the problem
occurred.

<Syntax syntax="pascaligo">

```shell
ligo run test gitlab-pages/docs/advanced/src/testnew.ligo
// Outputs:
// Everything at the top-level was executed.
// - test exited with value true.
```

</Syntax>
<Syntax syntax="cameligo">

```shell
ligo run test gitlab-pages/docs/advanced/src/testnew.mligo
// Outputs:
// Everything at the top-level was executed.
// - test exited with value true.
```

</Syntax>

<Syntax syntax="jsligo">

```shell
ligo run test gitlab-pages/docs/advanced/src/testnew.jsligo
// Outputs:
// Everything at the top-level was executed.
// - test exited with value true.
```

</Syntax>

The function `Test.transfer_to_contract` allows to bake a transaction.
It takes a target account of type `'parameter contract`, the parameter
of type `'parameter` and an amount of type `tez`. This function
performs the transaction, and returns a `test_exec_result` which
can be matched on to know whether the transaction was successful or not.
In case of success you will get access to the gas consumed by the execution
of the contract and in case of failure you will get access to a `test_exec_error`
describing the error.
There is an alternative version, called `Test.transfer_to_contract_exn`
which performs the transaction and will only return the gas consumption,
failing in case that there was an error.

We can extend the previous example by executing a transaction that
increments the storage after deployment, we also print the gas consumption:
<Syntax syntax="pascaligo">

```pascaligo test-ligo group=frontpage
// This continues testnew.ligo

const test2 =
  {
    const initial_storage = 42;
    const (taddr, _, _) = Test.originate(main, initial_storage, 0tez);
    const contr = Test.to_contract(taddr);
    const gas_cons = Test.transfer_to_contract_exn(contr, Increment(1), 1mutez);
    Test.log (("gas consumption",gas_cons)) ;
    const storage = Test.get_storage(taddr);
  } with (storage = initial_storage + 1);
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo test-ligo group=frontpage
// This continues testnew.mligo

let test2 =
  let initial_storage = 42 in
  let taddr, _, _ = Test.originate_uncurried main initial_storage 0tez in
  let contr = Test.to_contract taddr in
  let gas_cons = Test.transfer_to_contract_exn contr (Increment (1)) 1mutez in
  let () = Test.log ("gas consumption",gas_cons) in
  assert (Test.get_storage taddr = initial_storage + 1)
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo test-ligo group=frontpage
// This continues testnew.jsligo

let _test2 = () : bool => {
  let initial_storage = 42 as int;
  let [taddr, _, _] = Test.originate(main, initial_storage, 0 as tez);
  let contr = Test.to_contract(taddr);
  let gas_cons = Test.transfer_to_contract_exn(contr, (Increment (1)), 1 as mutez);
  let _ = Test.log(["gas consumption", gas_cons]);
  return (Test.get_storage(taddr) == initial_storage + 1);
}

let test2 = _test2();
```

</Syntax>

The environment assumes a source for the operations which can be set
using the function `Test.set_source : address -> unit`.

### Transfers and originations with tickets

Originating contract storing tickets or transfering to contract accepting tickets requires some extra steps. We will first explain the problems with tickets
and then show you how to handle it.

#### The problem with tickets

There is two kind of operations in the protocol : external and internal.
`internal operations` are those created by smart contracts and `external operations` are those created from outside the chain
(e.g. using `Test.originate` or `tezos-client` for instance) [more information here](https://tezos.gitlab.io/active/michelson.html#semantics-of-smart-contracts-and-transactions)

In the protocol, both external and internal `transfer`/`origination` operations contains a piece of michelson code representing the `parameter`/`initial storage`.
Now imagine you have a value of type `parameter_ty`/`storage_ty` containing a ticket, that you want to transfer or originate,
in the operation data, tickets will be represented in Michelson as pairs:

```bash
> ligo compile expression cameligo 'Tezos.create_ticket 0x0202 10n'
(Pair "KT1DUMMYDUMMYDUMMYDUMMYDUMMYDUMu2oHG" 0x0202 10)
```

> ticketer address , ticket value , ticket amount

If we try to apply such an operation, the type wouldn't match: ticket of bytes VS some pair.
The protocol would not let you do that since you could be creating a ticket out of nowhere unless the operation happens to be forged from within a contract (i.e. "internally")!

In the testing framework - for now - it means using "proxy-contracts" forging the operations using provided a ticket value and a ticket amount.

#### Proxy ticket contracts

The LIGO standard library provides a `Proxy_ticket` module which helps in working with tickets in the Testing framework. Here is the interface of `Proxy_ticket`:

---
`init_transfer` accepts:

* a function `mk_param` which given a ticket must return a value of your parameter type

and returns the typed address of a "transfer proxy-contract" which can then be used to do multiple transfers of tickets with the same ticketer address

---

`transfer` accepts :

* the typed address of a "transfer proxy-contract"
* the ticket information (value and amount) together with the destination address

and returns a value of type `test_exec_result`

---

`originate` accepts:

* the ticket information (value and amount)
* a function `mk_storage` which given a ticket must return a value of your storage type
* your contract (having a ticket in its storage type)

---

> Note: Functions `mk_param` and `mk_storage` will be executed in the proxy contract itself

Find more detailed information on the API of [`Proxy_ticket` here](../reference/proxy_ticket.md)

#### Usages

##### Transfer

Here is an example using `Proxy_ticket.init_transfer` and `Proxy_ticket.transfer`:

1. import the module above as `Proxy_ticket`
2. define a contract `main` holding a ticket of string in its parameter type. The contract will just store the value of
  the received ticket and the address of the sender
3. originate contract `main`
4. initialize a "transfer proxy-contract" providing a function to build a parameter out of a ticket
5. transfer a ticket with a value `"hello"` and an amount of `10` to contract `main`
6. print the storage of contract `main`
7. transfer a ticket with a value `"world"` and an amount of `5` to contract `main`
8. print the storage of contract `main`

<Syntax syntax="cameligo">

```cameligo test-ligo group=usage_transfer
type param = int * string ticket

let main ( (p,_) : param * (string * address)) : operation list * (string * address) =
  let (_,ticket) = p in
  let (_,(v,_)) , _ = Tezos.read_ticket ticket in
  [] , (v, Tezos.get_sender ())

let test_transfer_to_contract =
  let (main_taddr, _ , _) = Test.originate_uncurried main ("bye",Test.nth_bootstrap_account 1) 1mutez in
  let main_addr = Tezos.address (Test.to_contract main_taddr) in

  (* Use this address everytime you want to send tickets from the same proxy-contract *)
  let proxy_taddr =
    (* mk_param is executed __by the proxy contract__ *)
    let mk_param : string ticket -> param = fun (t : string ticket) -> 42,t in
    (* initialize a proxy contract in charge of creating and sending your tickets *)
    Test.Proxy_ticket.init_transfer mk_param
  in
  let () = Test.log ("poxy addr:", proxy_taddr) in

  let _ =
    (* ticket_info lets you control the amount and the value of the tickets you send *)
    let ticket_info = ("hello",10n) in
    (* we send ticket to main through the proxy-contract *)
    Test.Proxy_ticket.transfer proxy_taddr (ticket_info,main_addr)
  in
  let () = Test.log (Test.get_storage main_taddr) in
  let _ =
    let ticket_info = ("world",5n) in
    Test.Proxy_ticket.transfer proxy_taddr (ticket_info,main_addr)
  in
  let () = Test.log (Test.get_storage main_taddr) in
  ()
```

</Syntax>


<Syntax syntax="jsligo">

```jsligo test-ligo group=usage_transfer
type param = [ int , ticket<string>]

const main = (p: param, _: [string , address]) : [list<operation> , [string , address]] => {
  let [_,ticket] = p ;
  let [[_,[v,_]] , _] = Tezos.read_ticket (ticket) ;
  return ([list([]) , [v, Tezos.get_sender ()]])
};

const test_transfer_to_contract_ = () : unit => {
  let [main_taddr, _ , _] = Test.originate (main, ["bye",Test.nth_bootstrap_account (1)], 1 as mutez) ;
  let main_addr = Tezos.address (Test.to_contract (main_taddr)) ;

  /* mk_param is executed __by the proxy contract__ */
  const mk_param = (t:ticket<string>) : param => { return [42,t] } ;
  /* Use this address everytime you want to send tickets from the same proxy-contract */
  /* initialize a proxy contract in charge of creating and sending your tickets */
  let proxy_taddr = Test.Proxy_ticket.init_transfer (mk_param) ;
  let _ = Test.log (["poxy addr:", proxy_taddr]) ;

  /* ticket_info lets you control the amount and the value of the tickets you send */
  let ticket_info1 = ["hello",10 as nat] ;
  /* we send ticket to main through the proxy-contract */
  let _ = Test.Proxy_ticket.transfer (proxy_taddr, [ticket_info1,main_addr]) ;
  let _ = Test.log (Test.get_storage (main_taddr)) ;

  let ticket_info2 = ["world",5 as nat] ;
  let _ = Test.Proxy_ticket.transfer (proxy_taddr, [ticket_info2,main_addr]) ;
  Test.log (Test.get_storage (main_taddr));
};

const test_transfer_to_contract = test_transfer_to_contract_ ();
```

</Syntax>

result:

```bash
> ligo run test transfer_ticket.mligo
("poxy addr:" , KT1QGANLjYsyJmw1QNww9Jkgb4ccQr6W2gsC)
("hello" , KT1QGANLjYsyJmw1QNww9Jkgb4ccQr6W2gsC)
("world" , KT1QGANLjYsyJmw1QNww9Jkgb4ccQr6W2gsC)
Everything at the top-level was executed.
- test_transfer_to_contract exited with value ().
```

> Note: note that the sender (stored in the contract) matches the address of the proxy contract

##### Origination

Here is an example using `Proxy_ticket.originate` and the type `unforged_ticket` :

1. import the module above as `Proxy_ticket`
2. define a contract `main` potentially holding a ticket of bytes in its storage. The contract will just reads the ticket
   in its storage if present. Note that we define two version of the contract storage type: one for the contract
   and one for the storage type that we would like to manipulate in our testing logic
3. we define the `mk_storage` function which simply wraps a ticket into an option type
4. we define the ticket information for a ticket of value `0x0202` and an amount of `15`
5. we call `originate` and retrieve the address of the newly originated contract
6. we use the address to fetch the current contract storage using `Test.get_storage_of_address` and decompile it
   as a `human_storage`
7. we read the content of the ticket and perform a serie of assertions

<Syntax syntax="cameligo">

```cameligo test-ligo group=usage_orig
(* originate.mligo *)

type storage = (bytes ticket) option
type unforged_storage = (bytes unforged_ticket) option

let main (() : unit) (s : storage) : operation list * storage =
  [] , (
    match s with
    | Some ticket ->
      let (_ , t) = Tezos.read_ticket ticket in
      Some t
    | None -> None
  )

let test_originate_contract =
  let mk_storage = fun (t:bytes ticket) -> Some t in
  let ticket_info = (0x0202, 15n) in
  let addr = Test.Proxy_ticket.originate ticket_info mk_storage main in
  let storage : michelson_program = Test.get_storage_of_address addr in
  let unforged_storage = (Test.decompile storage : unforged_storage) in

  (* the ticket 'unforged_storage' can be manipulated freely without caring about ticket linearity *)

  match unforged_storage with
  | Some { ticketer ; value ; amount } ->
    let () = Test.log ("unforged_ticket", unforged_storage) in
    let () = assert (value = ticket_info.0) in
    let () = assert (amount = ticket_info.1) in
    ()
  | None -> failwith "impossible"
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo test-ligo group=usage_orig
type storage = option< ticket<bytes> >
type unforged_storage = option< unforged_ticket<bytes> >

const main = (_: unit, s: storage) : [ list<operation> , storage] => {
  let x =
    match (s, {
      Some: (ticket: ticket<bytes>) => {
        let [_ , t] = Tezos.read_ticket (ticket) ;
        return Some (t)
      },
      None: () => { return None () }
    });
  return [list ([]), x]
};

const test_originate_contract_ = () : unit => {
  const mk_storage = (t:ticket<bytes>) : storage => { return (Some (t)) } ;
  let ticket_info = [0x0202, 15 as nat] ;
  let addr = Test.Proxy_ticket.originate (ticket_info, mk_storage, main) ;
  let storage : michelson_program = Test.get_storage_of_address (addr) ;
  let unforged_storage = (Test.decompile (storage) as unforged_storage) ;

  /* the ticket 'unforged_storage' can be manipulated freely without caring about ticket linearity */

  match (unforged_storage, {
  Some: (x: unforged_ticket<bytes>) => {
    let _ = Test.log (["unforged_ticket", x]) ;
    let { ticketer , value , amount } = x ;
    let _ = assert (value == ticket_info[0]) ;
    let _ = assert (amount == ticket_info[1]) ;
    return unit
  },
  None: () => failwith ("impossible")
  }
  )
};

const test_originate_contract = test_originate_contract_ ();
```

</Syntax>

result:

```bash
("unforged_ticket" , {amount = 15n ; ticketer = KT1Qp8u3v4seQHPYfpSw6eWvPG8CojH3m18G ; value = 0x0202})
Everything at the top-level was executed.
- test_originate_contract_ exited with value <fun>.
- test_originate_contract exited with value ().
```

### Unit testing a function

Consider a map binding addresses to amounts and a function removing all entries in that map having an amount less to a given threshold.

<Syntax syntax="cameligo">

```cameligo group=rmv_bal
(* This is remove-balance.mligo *)

type balances = (address, tez) map

let balances_under (b:balances) (threshold:tez) : balances =
  Map.fold
    (fun ((acc, (k, v)) : balances * (address * tez)) ->
       if v < threshold then Map.remove k acc else acc)
    b b
```

</Syntax>

<Syntax syntax="pascaligo">

```pascaligo group=rmv_bal
(* This is remove-balance.ligo *)

type balances is map (address, tez)

function balances_under (const b : balances ; const threshold : tez) is {
  const f =
    function (const x : balances * (address * tez)) is {
      const (acc, (k, v)) = x;
    } with if v < threshold then Map.remove (k, acc) else acc;
} with Map.fold (f, b, b)
```

</Syntax>
<Syntax syntax="jsligo">

```jsligo group=rmv_bal
// This is remove-balance.jsligo

type balances = map <address, tez>

const balances_under = (b : balances, threshold:tez) : balances => {
  let f = ([acc, kv] : [balances, [address , tez]] ) : balances => {
    let [k,v] = kv ;
    if (v < threshold) { return Map.remove (k,acc) } else {return acc}
  };
  return Map.fold (f,b,b);
}
```

</Syntax>

Let us imagine that we want to test this function against a range of thresholds with the LIGO test framework.

<!-- I divided unit-remove-balance in multiple part of clarity -->
First, let's include the file under test and reset the state with 5 bootstrap accounts (we are going to use
the bootstrap addresses later)

<Syntax syntax="cameligo">

```cameligo test-ligo group=rmv_bal_test
#include "./gitlab-pages/docs/advanced/src/remove-balance.mligo"
let _u = Test.reset_state 5n ([] : tez list)
```

</Syntax>
<Syntax syntax="pascaligo">

```pascaligo test-ligo group=rmv_bal_test
#include "./gitlab-pages/docs/advanced/src/remove-balance.ligo"
const _u = Test.reset_state (5n, (list [] : list (tez)))
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo test-ligo group=rmv_bal_test
#include "./gitlab-pages/docs/advanced/src/remove-balance.jsligo"
let x = Test.reset_state (5 as nat, list([]) as list <tez>);
```

</Syntax>

Now build the `balances` map that will serve as the input of our test.

<Syntax syntax="cameligo">

```cameligo test-ligo group=rmv_bal_test
let balances : balances =
  let a1, a2, a3 = Test.nth_bootstrap_account 1, Test.nth_bootstrap_account 2, Test.nth_bootstrap_account 3
  in Map.literal [(a1, 10tz); (a2, 100tz); (a3, 1000tz)]
```

</Syntax>
<Syntax syntax="pascaligo">

```pascaligo test-ligo group=rmv_bal_test
const balances : balances = {
  const a1 = Test.nth_bootstrap_account (1);
  const a2 = Test.nth_bootstrap_account (2);
  const a3 = Test.nth_bootstrap_account (3);
} with map [a1 -> 10tz; a2 -> 100tz; a3 -> 1000tz]
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo test-ligo group=rmv_bal_test
let balances : balances =
  Map.literal(list([[Test.nth_bootstrap_account(1), 10 as tez],
                    [Test.nth_bootstrap_account(2), 100 as tez],
                    [Test.nth_bootstrap_account(3), 1000 as tez]]));
```

</Syntax>

Our simple test loop will call `balances_under` with the compiled map
defined above, get the size of the resulting map and compare it to an
expected value with `Test.michelson_equal`.

The call to `balance_under` and the computation of the size of the resulting map is achieved through the primitive `Test.run`.
This primitive runs a function on an input, translating both (function and input)
to Michelson before running on the Michelson interpreter.
More concretely `Test.run f v` performs the following:

1. Compiles the function argument `f` to Michelson `f_mich`
2. Compiles the value argument `v` (which was already evaluated) to Michelson `v_mich`
3. Runs the Michelson interpreter on the code `f_mich` with the initial stack `[ v_mich ]`

The function that is being compiled is called `tester`.

We also print the actual and expected sizes for good measure.

<Syntax syntax="cameligo">

```cameligo test-ligo group=rmv_bal_test
let test =
  List.iter
    (fun ((threshold , expected_size) : tez * nat) ->
      let tester (balances, threshold : balances * tez) = Map.size (balances_under balances threshold) in
      let size = Test.run tester (balances, threshold) in
      let expected_size = Test.eval expected_size in
      let () = Test.log ("expected", expected_size) in
      let () = Test.log ("actual",size) in
      assert (Test.michelson_equal size expected_size)
    )
    [(15tez,2n);(130tez,1n);(1200tez,0n)]
```

</Syntax>
<Syntax syntax="pascaligo">

```pascaligo test-ligo group=rmv_bal_test
const test =
  List.iter (
    (function (const threshold : tez; const expected_size : nat) is {
        function tester (const input : balances * tez) is
          Map.size(balances_under (input.0, input.1));
        const size_ = Test.run (tester, (balances, threshold));
        const expected_size = Test.eval (expected_size);
        Test.log (("expected", expected_size));
        Test.log (("actual", size_));
      } with assert (Test.michelson_equal (size_, expected_size))),
    list [(15tez, 2n); (130tez, 1n); (1200tez, 0n)])
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo test-ligo group=rmv_bal_test
let test =
  List.iter
    ( ([threshold , expected_size] : [tez , nat]) : unit => {
      let tester = ([balances, threshold] : [balances, tez]) : nat => Map.size (balances_under (balances, threshold));
      let size = Test.run(tester, [balances, threshold]);
      let expected_size_ = Test.eval(expected_size) ;
      let unit_ = Test.log (["expected", expected_size]) ;
      let unit__ = Test.log (["actual",size]) ;
      return (assert (Test.michelson_equal (size,expected_size_)))
    },
    list ([ [15 as tez,2 as nat] , [130 as tez,1 as nat] , [1200 as tez,0 as nat]]) );
```

</Syntax>

You can now execute the test:

<Syntax syntax="cameligo">

```shell
> ligo run test gitlab-pages/docs/advanced/src/unit-remove-balance-mixed.mligo
// Outputs:
// ("expected" , 2)
// ("actual" , 2)
// ("expected" , 1)
// ("actual" , 1)
// ("expected" , 0)
// ("actual" , 0)
// Everything at the top-level was executed.
// - test exited with value ().
```

</Syntax>

<Syntax syntax="pascaligo">

```shell
> ligo run test gitlab-pages/docs/advanced/src/unit-remove-balance-mixed.ligo
// Outputs:
// ("expected" , 2)
// ("actual" , 2)
// ("expected" , 1)
// ("actual" , 1)
// ("expected" , 0)
// ("actual" , 0)
// Everything at the top-level was executed.
// - test exited with value ().
```

</Syntax>
<Syntax syntax="jsligo">

```shell
> ligo run test gitlab-pages/docs/advanced/src/unit-remove-balance-mixed.jsligo
// Outputs:
// ("expected" , 2)
// ("actual" , 2)
// ("expected" , 1)
// ("actual" , 1)
// ("expected" , 0)
// ("actual" , 0)
// Everything at the top-level was executed.
// - test exited with value ().
```

</Syntax>

### Testing with `ligo run interpret`

The command `ligo run interpret` allows to interpret an expression in a
context initialised by a source file. The interpretation is done using
Michelson's interpreter.

We can see how it works on an example. Suppose we want to test the following
contract.

<Syntax syntax="pascaligo">

```pascaligo
// This is testme.ligo

type storage is int

type parameter is
  Increment of int
| Decrement of int
| Reset

type return is list (operation) * storage

// Two entrypoints

function add (const store : storage; const delta : int) : storage is
  store + delta

function sub (const store : storage; const delta : int) : storage is
  store - delta

(* Main access point that dispatches to the entrypoints according to
   the smart contract parameter. *)

function main (const action : parameter; const store : storage) : return is
 ((nil : list (operation)),    // No operations
  case action of [
    Increment (n) -> add (store, n)
  | Decrement (n) -> sub (store, n)
  | Reset         -> 0
  ])
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo
// This is testme.mligo

type storage = int

type parameter =
  Increment of int
| Decrement of int
| Reset

type return = operation list * storage

// Two entrypoints

let add (store, delta : storage * int) : storage = store + delta
let sub (store, delta : storage * int) : storage = store - delta

(* Main access point that dispatches to the entrypoints according to
   the smart contract parameter. *)

let main (action, store : parameter * storage) : return =
 ([] : operation list),    // No operations
 (match action with
   Increment (n) -> add (store, n)
 | Decrement (n) -> sub (store, n)
 | Reset         -> 0)
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo
// This is testme.jsligo

type storage = int;

type parameter =
  ["Increment", int]
| ["Decrement", int]
| ["Reset"];

type @return = [list<operation>, storage];

// Two entrypoints

let add = (store: storage, delta: int): storage => store + delta;
let sub = (store: storage, delta: int): storage => store - delta;

/* Main access point that dispatches to the entrypoints according to
   the smart contract parameter. */

let main = (action: parameter, store: storage) : @return => {
  return [
    list([]) as list<operation>,    // No operations
    match(action, {
      Increment:(n: int) => add (store, n),
      Decrement:(n: int) => sub (store, n),
      Reset: ()          => 0})
  ]
};
```

</Syntax>

This contract keeps an integer as storage, and has three entry-points:
one for incrementing the storage, one for decrementing the storage,
and one for resetting the storage to `0`.

As a simple property, we check whether starting with a storage of
`10`, if we execute the entry-point for incrementing `32`, then we get
a resulting storage of `42`. For checking it, we can interpret the
`main` function:

<Syntax syntax="pascaligo">

```shell
ligo run interpret "main (Increment (32), 10)" --init-file gitlab-pages/docs/advanced/src/testing/testme.ligo
// Outputs:
// ( LIST_EMPTY() , 42 )
```

</Syntax>
<Syntax syntax="cameligo">

```shell
ligo run interpret "main (Increment (32), 10)" --init-file testme.mligo
// Outputs:
// ( LIST_EMPTY() , 42 )
```

</Syntax>

<Syntax syntax="jsligo">

```shell
ligo run interpret "main (Increment (32), 10)" --init-file testme.jsligo
// Outputs:
// ( LIST_EMPTY() , 42 )
```

</Syntax>

With the argument `--init-file` we pass the contract we want to test,
and the sub-command requires also the expression to evaluate in that
context, in this case, a call to our contract (`main`) with parameter
`Increment (32)` and storage `10`. As a result, we can check that the
resulting storage is `42` (the second component of the pair), and
there are no further operations to execute (the first component).

We can tune certain parameters of the execution by passing them as
arguments:

```
--amount=AMOUNT (absent=0)
    AMOUNT is the amount the Michelson interpreter will use for the
    transaction.
--balance=BALANCE (absent=0)
    BALANCE is the balance the Michelson interpreter will use for the
    contract balance.
--now=NOW
    NOW is the NOW value the Michelson interpreter will use
    (e.g. '2000-01-01T10:10:10Z')
--sender=SENDER
    SENDER is the sender the Michelson interpreter transaction will use.
--source=SOURCE
    SOURCE is the source the Michelson interpreter transaction will use.
```

### Event testing

Here is how you emit events and fetch them from your tests:

<Syntax syntax="pascaligo">

```pascaligo test-ligo group=test_ex
function main ( const x : (int*int) * unit ) is
  (list [Tezos.emit ("%foo", x.0) ; Tezos.emit ("%foo", x.0.0)], Unit)

const test_foo = {
  const (ta, _, _) = Test.originate (main, Unit, 0tez) ;
  const _ = Test.transfer_to_contract_exn (Test.to_contract (ta), (1,2), 0tez) ;
  const x = (Test.get_last_events_from (ta, "foo") : list (int*int)) ;
  const y = (Test.get_last_events_from (ta, "foo") : list (int)) ;
} with (x,y)
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo test-ligo group=test_ex
let main (p,_ : (int*int) * unit ) =
  [Tezos.emit "%foo" p ; Tezos.emit "%foo" p.0],()

let test_foo =
  let (ta, _, _) = Test.originate_uncurried main () 0tez in
  let _ = Test.transfer_to_contract_exn (Test.to_contract ta) (1,2) 0tez in
  (Test.get_last_events_from ta "foo" : (int*int) list),(Test.get_last_events_from ta "foo" : int list)
```

</Syntax>
<Syntax syntax="jsligo">

```jsligo test-ligo group=test_ex
let main = (p: [int, int], _: unit) => {
  let op1 = Tezos.emit("%foo", p);
  let op2 = Tezos.emit("%foo", p[0]);
  return [list([op1, op2]), unit];
  };

let test = (() : [list<[int,int]>, list<int>] => {
  let [ta, _, _] = Test.originate(main, unit, 0 as tez);
  let _ = Test.transfer_to_contract_exn(Test.to_contract(ta), [1,2], 0 as tez);
  return [Test.get_last_events_from(ta, "foo") as list<[int, int]>, Test.get_last_events_from(ta, "foo") as list<int>];
}) ();
```

</Syntax>

### Testing a contract declared as a module or namespace

When declaring the entry points of a contract using `@entry`, LIGO generates two hidden values in the module:

* an implicit `main` function, which can be obtained using the keyword `contract_of(C)` where `C` is the namespace or module containing the entry points, and
* the input type for that `main` function, which can be obtained using the keyword `parameter_of C`.

In the example below, `contract_of(C)` is returns the implicitly-declared `main` function that calls the `increment` or `decrement` entry points depending on the argument given, and `parameter_of C` is the [variant](https://ligolang.org/docs/language-basics/unit-option-pattern-matching#variant-types) `["Increment", int] | ["Decrement", int]`.

```jsligo group=tezos_specific
namespace C {
  type storage = int;

  // @entry
  const increment = (action: int, store: storage) : [list <operation>, storage] => [list([]), store + action];

  // @entry
  const decrement = (action: int, store: storage) : [list <operation>, storage] => [list([]), store - action];
};

const testC = () => {
    let initial_storage = 42;
    let [taddr, _contract, _size] = Test.originate_module(contract_of(C), initial_storage, 0 as tez);
    let contr : contract<parameter_of C> = Test.to_contract(taddr);
    let p : parameter_of C = Increment(1);
    let _ = Test.transfer_to_contract_exn(contr, p, 1 as mutez);
    return assert(Test.get_storage(taddr) == initial_storage + 1);
}
```

The special constructions `contract_of(C)` and `parameter_of C` are not first-class functions, they are special syntax which take a module or namespace name as a parameter. This means for example that `some_function(contract_of)` or `contract_of(some_variable)` are invalid uses of the syntax (a literal module or parameter name must always be passed as part of the syntax).