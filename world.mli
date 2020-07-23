type t

val create : (float*float*float) -> (float*float*float) -> t

val update: t -> (float*float*float) -> (float*float*float) -> unit

