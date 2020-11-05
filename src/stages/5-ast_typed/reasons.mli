type t =
  | Forall
  | Forall_TC
  | Builtin_type
  | Propagator_break_ctor of string
  | Propagator_specialize_apply
  | Propagator_specialize_tf
  | Propagator_specialize_targ
  | Propagator_specialize_eq
  | Todo of string

val wrap : t -> 'v -> 'v Location.wrap