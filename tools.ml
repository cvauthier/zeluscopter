
let rd_initialized = ref false

let random_init () =
	let t = 1000.0 *. (Sys.time ()) in
	Random.init (int_of_float t);
	rd_initialized := true

let random_float bound = 
	if not !rd_initialized then random_init ();
	Random.float bound
	
