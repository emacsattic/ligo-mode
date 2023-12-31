(*
module Var = Simple_utils.Var
module Trace = Simple_utils.Trace
open Main_errors
open Test_helpers


let get_program = get_program "./contracts/time-lock.ligo"

let compile_main ~raise () =
  Test_helpers.compile_main ~raise "./contracts/time-lock.ligo" ()


open Ligo_prim
open Ast_unified

let empty_op_list = e_list ~loc []

let empty_message =
  e_lambda_ez
    ~loc
    (Value_var.of_input_var ~loc "arguments")
    ~ascr:(tv_unit ~loc ())
    (Some (t_list ~loc (tv_operation ~loc ())))
    empty_op_list


let call msg = e_constructor ~loc {constructor = Label.of_string "Call" ; element = msg }

let mk_time ~(raise : ('a, _) Trace.raise) st =
  match Memory_proto_alpha.Protocol.Script_timestamp.of_string st with
  | Some s -> s
  | None -> raise.error @@ test_internal "bad timestamp notation"


let to_sec t = Memory_proto_alpha.Protocol.Script_timestamp.to_zint t
let storage st = e_timestamp_z ~loc (to_sec st)

let early_call ~raise () =
  let program = get_program ~raise () in
  let now = mk_time ~raise "2000-01-01T00:10:10Z" in
  let lock_time = mk_time ~raise "2000-01-01T10:10:10Z" in
  let init_storage = storage lock_time in
  let options =
    Proto_alpha_utils.Memory_proto_alpha.(make_options ~env:(test_environment ()) ~now ())
  in
  let exp_failwith = "Contract is still time locked" in
  expect_string_failwith
    ~raise
    ~options
    program
    "main"
    (e_pair ~loc (call empty_message) init_storage)
    exp_failwith


let call_on_time ~raise () =
  let program = get_program ~raise () in
  let now = mk_time ~raise "2000-01-01T10:10:10Z" in
  let lock_time = mk_time ~raise "2000-01-01T00:10:10Z" in
  let init_storage = storage lock_time in
  let options =
    Proto_alpha_utils.Memory_proto_alpha.(make_options ~env:(test_environment ()) ~now ())
  in
  expect_eq
    ~raise
    ~options
    program
    "main"
    (e_pair ~loc (call empty_message) init_storage)
    (e_pair ~loc empty_op_list init_storage)


let main =
  test_suite
    "Time lock"
    [ test_w "compile" compile_main
    ; test_w "early call" early_call
    ; test_w "call on time" call_on_time
    ]
*)
