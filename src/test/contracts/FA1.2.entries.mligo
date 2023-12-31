type transfer =
  [@layout:comb]
  { [@annot:from] address_from : address;
    [@annot:to] address_to : address;
    value : nat }

type approve =
  [@layout:comb]
  { spender : address;
    value : nat }

type allowance_key =
  [@layout:comb]
  { owner : address;
    spender : address }

type getAllowance =
  [@layout:comb]
  { request : allowance_key;
    callback : nat contract }

type getBalance =
  [@layout:comb]
  { owner : address;
    callback : nat contract }

type getTotalSupply =
  [@layout:comb]
  { request : unit ;
    callback : nat contract }

type tokens = (address, nat) big_map
type allowances = (allowance_key, nat) big_map

type storage = {
  tokens : tokens;
  allowances : allowances;
  total_supply : nat;
}

type result = operation list * storage

[@inline]
let positive (n : nat) : nat option =
  if n = 0n
  then (None : nat option)
  else Some n

[@entry]
let transfer (param : transfer) (storage : storage) : result =
  let allowances = storage.allowances in
  let tokens = storage.tokens in
  let allowances =
    if Tezos.get_sender () = param.address_from
    then allowances
    else
      let allowance_key = { owner = param.address_from ; spender = Tezos.get_sender () } in
      let authorized_value =
        match Big_map.find_opt allowance_key allowances with
        | Some value -> value
        | None -> 0n in
      let authorized_value =
        match is_nat (authorized_value - param.value) with
        | None -> (failwith "NotEnoughAllowance" : nat)
        | Some authorized_value -> authorized_value in
      Big_map.update allowance_key (positive authorized_value) allowances in
  let tokens =
    let from_balance =
      match Big_map.find_opt param.address_from tokens with
      | Some value -> value
      | None -> 0n in
    let from_balance =
      match is_nat (from_balance - param.value) with
      | None -> (failwith "NotEnoughBalance" : nat)
      | Some from_balance -> from_balance in
    Big_map.update param.address_from (positive from_balance) tokens in
  let tokens =
    let to_balance =
      match Big_map.find_opt param.address_to tokens with
      | Some value -> value
      | None -> 0n in
    let to_balance = to_balance + param.value in
    Big_map.update param.address_to (positive to_balance) tokens in
  (([] : operation list), { storage with tokens = tokens; allowances = allowances })

[@entry]
let approve (param : approve) (storage : storage) : result =
  let allowances = storage.allowances in
  let allowance_key = { owner = Tezos.get_sender () ; spender = param.spender } in
  let previous_value =
    match Big_map.find_opt allowance_key allowances with
    | Some value -> value
    | None -> 0n in
  begin
    if previous_value > 0n && param.value > 0n
    then (failwith "UnsafeAllowanceChange")
    else ();
    let allowances = Big_map.update allowance_key (positive param.value) allowances in
    (([] : operation list), { storage with allowances = allowances })
  end

[@entry]
let getAllowance (param : getAllowance) (storage : storage) : operation list * storage =
  let value =
    match Big_map.find_opt param.request storage.allowances with
    | Some value -> value
    | None -> 0n in
  [Tezos.transaction value 0mutez param.callback], storage

[@entry]
let getBalance (param : getBalance) (storage : storage) : operation list * storage =
  let value =
    match Big_map.find_opt param.owner storage.tokens with
    | Some value -> value
    | None -> 0n in
  [Tezos.transaction value 0mutez param.callback], storage

[@entry]
let getTotalSupply (param : getTotalSupply) (storage : storage) : operation list * storage =
  let total = storage.total_supply in
  [Tezos.transaction total 0mutez param.callback],storage

(* These are helpers written for testing *)

let bad_transfer (_param, storage : transfer * unit) : operation list * unit =
  (([] : operation list), storage)
