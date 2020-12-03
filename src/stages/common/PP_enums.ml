open Format
open Types

(** old code
let operation ppf (o : Memory_proto_alpha.Protocol.Alpha_context.packed_internal_operation) : unit =
  let print_option f ppf o =
    match o with
      Some (s) -> fprintf ppf "%a" f s
    | None -> fprintf ppf "None"
  in
    let open Tezos_micheline.Micheline in
  let rec prim ppf (node : (_,Memory_proto_alpha.Protocol.Alpha_context.Script.prim) node)= match node with
    | Int (l , i) -> fprintf ppf "Int (%i, %a)" l Z.pp_print i
    | String (l , s) -> fprintf ppf "String (%i, %s)" l s
    | Bytes (l, b) -> fprintf ppf "B (%i, %s)" l (Bytes.to_string b)
    | Prim (l , p , nl, a) -> fprintf ppf "P (%i, %s, %a, %a)" l
        (Memory_proto_alpha.Protocol.Michelson_v1_primitives.string_of_prim p)
        (list_sep_d prim) nl
        (list_sep_d (fun ppf s -> fprintf ppf "%s" s)) a
    | Seq (l, nl) -> fprintf ppf "S (%i, %a)" l
        (list_sep_d prim) nl
  in
  let l ppf (l: Memory_proto_alpha.Protocol.Alpha_context.Script.lazy_expr) =
    let oo = Data_encoding.force_decode l in
    match oo with
      Some o -> fprintf ppf "%a" prim (Tezos_micheline.Micheline.root o)
    | None  -> fprintf ppf "Fail decoding"
  in

  let op ppf (type a) : a Memory_proto_alpha.Protocol.Alpha_context.manager_operation -> unit = function
    | Reveal (s: Tezos_protocol_environment_ligo006_PsCARTHA__Environment.Signature.Public_key.t) ->
      fprintf ppf "R %a" Tezos_protocol_environment_ligo006_PsCARTHA__Environment.Signature.Public_key.pp s
    | Transaction {amount; parameters; entrypoint; destination} ->
      fprintf ppf "T {%a; %a; %s; %a}"
        Memory_proto_alpha.Protocol.Alpha_context.Tez.pp amount
        l parameters
        entrypoint
        Memory_proto_alpha.Protocol.Alpha_context.Contract.pp destination

    | Origination {delegate; script; credit; preorigination} ->
      fprintf ppf "O {%a; %a; %a; %a}"
        (print_option Tezos_protocol_environment_ligo006_PsCARTHA__Environment.Signature.Public_key_hash.pp) delegate
        l script.code
        Memory_proto_alpha.Protocol.Alpha_context.Tez.pp credit
        (print_option Memory_proto_alpha.Protocol.Alpha_context.Contract.pp) preorigination

    | Delegation so ->
      fprintf ppf "D %a" (print_option Tezos_protocol_environment_ligo006_PsCARTHA__Environment.Signature.Public_key_hash.pp) so
  in
  let Internal_operation {source;operation;nonce} = o in
  fprintf ppf "{source: %s; operation: %a; nonce: %i"
    (Memory_proto_alpha.Protocol.Alpha_context.Contract.to_b58check source)
    op operation
    nonce

*)

let operation ppf (o: bytes) : unit =
  fprintf ppf "%s" @@ Bytes.to_string o

let constant' ppf : constant' -> unit = function
  | C_INT                   -> fprintf ppf "INT"
  | C_UNIT                  -> fprintf ppf "UNIT"
  | C_NIL                   -> fprintf ppf "NIL"
  | C_NOW                   -> fprintf ppf "NOW"
  | C_IS_NAT                -> fprintf ppf "IS_NAT"
  | C_SOME                  -> fprintf ppf "SOME"
  | C_NONE                  -> fprintf ppf "NONE"
  | C_ASSERTION             -> fprintf ppf "ASSERTION"
  | C_ASSERT_INFERRED       -> fprintf ppf "ASSERT_INFERRED"
  | C_ASSERT_SOME           -> fprintf ppf "ASSERT_SOME"
  | C_FAILWITH              -> fprintf ppf "FAILWITH"
  | C_UPDATE                -> fprintf ppf "UPDATE"
  (* Loops *)
  | C_ITER                  -> fprintf ppf "ITER"
  | C_FOLD                  -> fprintf ppf "FOLD"
  | C_FOLD_WHILE            -> fprintf ppf "FOLD_WHILE"
  | C_FOLD_CONTINUE         -> fprintf ppf "CONTINUE"
  | C_FOLD_STOP             -> fprintf ppf "STOP"
  | C_LOOP_LEFT             -> fprintf ppf "LOOP_LEFT"
  | C_LOOP_CONTINUE         -> fprintf ppf "LOOP_CONTINUE"
  | C_LOOP_STOP             -> fprintf ppf "LOOP_STOP"
  (* MATH *)
  | C_NEG                   -> fprintf ppf "NEG"
  | C_ABS                   -> fprintf ppf "ABS"
  | C_ADD                   -> fprintf ppf "ADD"
  | C_SUB                   -> fprintf ppf "SUB"
  | C_MUL                   -> fprintf ppf "MUL"
  | C_EDIV                  -> fprintf ppf "EDIV"
  | C_DIV                   -> fprintf ppf "DIV"
  | C_MOD                   -> fprintf ppf "MOD"
  (* LOGIC *)
  | C_NOT                   -> fprintf ppf "NOT"
  | C_AND                   -> fprintf ppf "AND"
  | C_OR                    -> fprintf ppf "OR"
  | C_XOR                   -> fprintf ppf "XOR"
  | C_LSL                   -> fprintf ppf "LSL"
  | C_LSR                   -> fprintf ppf "LSR"
  (* COMPARATOR *)
  | C_EQ                    -> fprintf ppf "EQ"
  | C_NEQ                   -> fprintf ppf "NEQ"
  | C_LT                    -> fprintf ppf "LT"
  | C_GT                    -> fprintf ppf "GT"
  | C_LE                    -> fprintf ppf "LE"
  | C_GE                    -> fprintf ppf "GE"
  (* Bytes/ String *)
  | C_SIZE                  -> fprintf ppf "SIZE"
  | C_CONCAT                -> fprintf ppf "CONCAT"
  | C_SLICE                 -> fprintf ppf "SLICE"
  | C_BYTES_PACK            -> fprintf ppf "BYTES_PACK"
  | C_BYTES_UNPACK          -> fprintf ppf "BYTES_UNPACK"
  | C_CONS                  -> fprintf ppf "CONS"
  (* Pair *)
  | C_PAIR                  -> fprintf ppf "PAIR"
  | C_CAR                   -> fprintf ppf "CAR"
  | C_CDR                   -> fprintf ppf "CDR"
  | C_LEFT                  -> fprintf ppf "LEFT"
  | C_RIGHT                 -> fprintf ppf "RIGHT"
  (* Set *)
  | C_SET_EMPTY             -> fprintf ppf "SET_EMPTY"
  | C_SET_LITERAL           -> fprintf ppf "SET_LITERAL"
  | C_SET_ADD               -> fprintf ppf "SET_ADD"
  | C_SET_REMOVE            -> fprintf ppf "SET_REMOVE"
  | C_SET_ITER              -> fprintf ppf "SET_ITER"
  | C_SET_FOLD              -> fprintf ppf "SET_FOLD"
  | C_SET_MEM               -> fprintf ppf "SET_MEM"
  (* List *)
  | C_LIST_EMPTY            -> fprintf ppf "LIST_EMPTY"
  | C_LIST_LITERAL          -> fprintf ppf "LIST_LITERAL"
  | C_LIST_ITER             -> fprintf ppf "LIST_ITER"
  | C_LIST_MAP              -> fprintf ppf "LIST_MAP"
  | C_LIST_FOLD             -> fprintf ppf "LIST_FOLD"
  | C_LIST_HEAD_OPT         -> fprintf ppf "LIST_HEAD_OPT"
  | C_LIST_TAIL_OPT         -> fprintf ppf "LIST_TAIL_OPT"
  (* Maps *)
  | C_MAP                   -> fprintf ppf "MAP"
  | C_MAP_EMPTY             -> fprintf ppf "MAP_EMPTY"
  | C_MAP_LITERAL           -> fprintf ppf "MAP_LITERAL"
  | C_MAP_GET               -> fprintf ppf "MAP_GET"
  | C_MAP_GET_FORCE         -> fprintf ppf "MAP_GET_FORCE"
  | C_MAP_ADD               -> fprintf ppf "MAP_ADD"
  | C_MAP_REMOVE            -> fprintf ppf "MAP_REMOVE"
  | C_MAP_UPDATE            -> fprintf ppf "MAP_UPDATE"
  | C_MAP_ITER              -> fprintf ppf "MAP_ITER"
  | C_MAP_MAP               -> fprintf ppf "MAP_MAP"
  | C_MAP_FOLD              -> fprintf ppf "MAP_FOLD"
  | C_MAP_MEM               -> fprintf ppf "MAP_MEM"
  | C_MAP_FIND              -> fprintf ppf "MAP_FIND"
  | C_MAP_FIND_OPT          -> fprintf ppf "MAP_FIND_OP"
  (* Big Maps *)
  | C_BIG_MAP               -> fprintf ppf "BIG_MAP"
  | C_BIG_MAP_EMPTY         -> fprintf ppf "BIG_MAP_EMPTY"
  | C_BIG_MAP_LITERAL       -> fprintf ppf "BIG_MAP_LITERAL"
  (* Crypto *)
  | C_SHA256                -> fprintf ppf "SHA256"
  | C_SHA512                -> fprintf ppf "SHA512"
  | C_BLAKE2b               -> fprintf ppf "BLAKE2b"
  | C_HASH                  -> fprintf ppf "HASH"
  | C_HASH_KEY              -> fprintf ppf "HASH_KEY"
  | C_CHECK_SIGNATURE       -> fprintf ppf "CHECK_SIGNATURE"
  | C_CHAIN_ID              -> fprintf ppf "CHAIN_ID"
  (* Blockchain *)
  | C_CALL                  -> fprintf ppf "CALL"
  | C_CONTRACT              -> fprintf ppf "CONTRACT"
  | C_CONTRACT_OPT          -> fprintf ppf "CONTRACT_OPT"
  | C_CONTRACT_ENTRYPOINT   -> fprintf ppf "CONTRACT_ENTRYPOINT"
  | C_CONTRACT_ENTRYPOINT_OPT -> fprintf ppf "CONTRACT_ENTRYPOINT_OPT"
  | C_AMOUNT                -> fprintf ppf "AMOUNT"
  | C_BALANCE               -> fprintf ppf "BALANCE"
  | C_SOURCE                -> fprintf ppf "SOURCE"
  | C_SENDER                -> fprintf ppf "SENDER"
  | C_ADDRESS               -> fprintf ppf "ADDRESS"
  | C_SELF                  -> fprintf ppf "SELF"
  | C_SELF_ADDRESS          -> fprintf ppf "SELF_ADDRESS"
  | C_IMPLICIT_ACCOUNT      -> fprintf ppf "IMPLICIT_ACCOUNT"
  | C_SET_DELEGATE          -> fprintf ppf "SET_DELEGATE"
  | C_CREATE_CONTRACT       -> fprintf ppf "CREATE_CONTRACT"
  | C_CONVERT_TO_RIGHT_COMB -> fprintf ppf "CONVERT_TO_RIGHT_COMB"
  | C_CONVERT_TO_LEFT_COMB  -> fprintf ppf "CONVERT_TO_LEFT_COMB"
  | C_CONVERT_FROM_RIGHT_COMB -> fprintf ppf "CONVERT_FROM_RIGHT_COMB"
  | C_CONVERT_FROM_LEFT_COMB  -> fprintf ppf "CONVERT_FROM_LEFT_COMB"
  | C_TRUE                  -> fprintf ppf "TRUE"
  | C_FALSE                 -> fprintf ppf "FALSE"
  | C_TEST_ORIGINATE -> fprintf ppf "TEST_ORIGINATE"
  | C_TEST_SET_NOW -> fprintf ppf "TEST_SET_NOW"
  | C_TEST_SET_SOURCE -> fprintf ppf "TEST_SET_SOURCE"
  | C_TEST_SET_BALANCE -> fprintf ppf "TEST_SET_BALANCE"
  | C_TEST_EXTERNAL_CALL -> fprintf ppf "TEST_EXTERNAL_CALL"
  | C_TEST_GET_STORAGE -> fprintf ppf "TEST_GET_STORAGE"
  | C_TEST_GET_BALANCE -> fprintf ppf "TEST_GET_BALANCE"
  | C_TEST_ASSERT_FAILURE -> fprintf ppf "TEST_ASSERT_FAILURE"
  | C_TEST_LOG -> fprintf ppf "TEST_LOG"


let literal ppf (l : literal) =
  match l with
  | Literal_unit -> fprintf ppf "unit"
  | Literal_int z -> fprintf ppf "%a" Z.pp_print z
  | Literal_nat z -> fprintf ppf "+%a" Z.pp_print z
  | Literal_timestamp z -> fprintf ppf "+%a" Z.pp_print z
  | Literal_mutez z -> fprintf ppf "%amutez" Z.pp_print z
  | Literal_string s -> fprintf ppf "%a" Ligo_string.pp s
  | Literal_bytes b -> fprintf ppf "0x%a" Hex.pp (Hex.of_bytes b)
  | Literal_address s -> fprintf ppf "@%S" s
  | Literal_operation o -> fprintf ppf "Operation(%a)" operation o
  | Literal_key s -> fprintf ppf "key %s" s
  | Literal_key_hash s -> fprintf ppf "key_hash %s" s
  | Literal_signature s -> fprintf ppf "Signature %s" s
  | Literal_chain_id s -> fprintf ppf "Chain_id %s" s