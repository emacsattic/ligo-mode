let fold_map__list v state continue =
  let aux = fun (lst', state) elt ->
    let (elt', state) = continue elt state in
    (elt' :: lst' , state) in
  List.fold_left aux ([], state) v

let fold_map__option v state continue =
  match v with
    Some x -> continue x state
  | None -> None
