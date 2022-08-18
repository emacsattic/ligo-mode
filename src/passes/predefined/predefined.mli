module Tree_abstraction : sig
  open Stage_common

  val pseudo_module_to_string : Constant.constant' -> string
  val constants      : string -> Constant.rich_constant option
  val constant_to_string      : Constant.rich_constant -> string
end

module Michelson : sig
  include module type of Helpers.Michelson
  open Stage_common
  val get_operators : Environment.Protocols.t -> Constant.constant' -> predicate option
end
