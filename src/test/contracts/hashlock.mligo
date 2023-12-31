type commit = {
  date        : timestamp;
  salted_hash : bytes;
}

type commit_set = (address, commit) big_map

type storage = {
  hashed  : bytes;
  unused  : bool;
  commits : commit_set
}

type reveal = {
  hashable : bytes;
  message  : unit -> operation list
}

type parameter =
  Commit of bytes
| Reveal of reveal

type return = operation list * storage

(* We use hash-commit so that a baker can not steal *)

let commit (p : bytes) (s : storage) : return =
  let commit : commit =
    {date = Tezos.get_now () + 86_400; salted_hash = p} in
  let updated_map: commit_set =
    Big_map.update (Tezos.get_sender ()) (Some commit) s.commits in
  let s = {s with commits = updated_map}
  in ([] : operation list), s

let reveal (p : reveal) (s : storage) : return =
  if not s.unused
  then
    (failwith "This contract has already been used." : return)
  else
    let commit : commit =
      match Big_map.find_opt (Tezos.get_sender ()) s.commits with
    | Some c -> c
    | None ->
       (failwith "You have not made a commitment to hash against yet."
        : commit)
    in
    if Tezos.get_now () < commit.date
    then
      (failwith "It has not been 24 hours since your commit yet.": return)
    else
      let salted =
        Crypto.sha256 (Bytes.concat p.hashable (Bytes.pack (Tezos.get_sender ()))) in
      if salted <> commit.salted_hash
      then
        (failwith "This reveal does not match your commitment.": return)
      else
        if s.hashed = Crypto.sha256 p.hashable
        then
          let s : storage = {s with unused = false}
          in p.message (), s
        else (failwith "Your commitment did not match the storage hash."
              : return)

[@entry]
let main (p : parameter) (s : storage) : return =
  match p with
  | Commit c -> commit c s
  | Reveal r -> reveal r s
