
let rd_initialized = ref false

let random_init () =
	let t = 1000.0 *. (Sys.time ()) in
	Random.init (int_of_float t);
	rd_initialized := true

let random_float bound = 
	if not !rd_initialized then random_init ();
	Random.float bound

(* Box-Muller transform *)

let random_normal () =
	let u1 = random_float 1.0 and u2 = random_float 1.0 in
	let v1 = sqrt ( -2.0 *. (log u1)) and v2 = cos (2.0 *. 3.141592654 *. u2) in
	v1 *. v2

