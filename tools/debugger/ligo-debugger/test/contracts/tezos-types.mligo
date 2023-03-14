let main (_, s : unit * int) : operation list * int =
  let s1 = Tezos.get_balance() in
  let s2 = Tezos.get_now() in
  let s3 = Tezos.get_sender() in
  let () = ignore s1 in
  let () = ignore s2 in
  let () = ignore s3 in
  (([] : operation list), s)
