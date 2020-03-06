type parameter is Default | Toto of int
type storage is nat
type return is list (operation) * storage


function main (const p : parameter; const s : storage) : return is
  block {
    const v : string = "%Toto" ;
    const self_contract: contract(int) = Tezos.self(v) ;
    const op : operation = Tezos.transaction (2, 300tz, self_contract) ;
  }
  with (list [op], s)