type variants =
  | Variant1 of int
  | Variant2

[@entry]
let main (p : variants) (s : int) : operation list * int =
  let s2 = match p with
    | Variant1 x -> s + x
    | Variant2 -> s
    in
  (([] : operation list), s2)
