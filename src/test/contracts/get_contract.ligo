type storage is unit
type return is list (operation) * storage

function cb (const s : storage) : return is block {
  const c : contract (unit) = Tezos.get_contract (Tezos.get_sender(unit))
} with (list [Tezos.transaction (unit, 0tez, c)], s)


function cbo (const s : unit) : return is
  block {
    const c : contract (unit) =
      case (Tezos.get_contract_opt (Tezos.get_sender(unit)) : option (contract (unit))) of [
        Some (contract) -> contract
      | None -> (failwith ("contract not found") : contract (unit))
      ]
  } with (list [Tezos.transaction (unit, 0tez, c)], s)
