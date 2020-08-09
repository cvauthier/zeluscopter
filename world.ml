
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

type t = out_channel * in_channel

let create pos angles =
  let input, output = Unix.pipe () and input2,output2 = Unix.pipe () in
  let outch = Unix.out_channel_of_descr output in
	let inch = Unix.in_channel_of_descr input2 in
  match Unix.fork () with
  | 0 -> (Unix.close input; Unix.close output2; Unix.set_nonblock input2; (outch,inch)) (* child *)
  | _ -> (* parent process *)
      begin
        Unix.close output;
        Unix.close input2;
				Unix.set_nonblock input;
				Unix.dup2 input Unix.stdin;
				Unix.dup2 output2 Unix.stdout;
				ignore (Unix.execv "visualizer" [||]);
      	(outch,inch)
			end

let xd = ref 0.0
let yd = ref 0.0
let zd = ref 0.0
let init_command = ref false

let read_command fin =
  try 
    let s = input_line fin in
		let rec aux i = function
			| 1 -> [float_of_string (String.sub s i (String.length s - i))]
			| n -> let j = String.index_from s i ',' in
						 (float_of_string (String.sub s i (j-i)))::(aux (j+1) (n-1)) in
		match (aux 0 3) with
			| [x;y;z] -> xd := x; yd := y; zd := z; true
			| _ -> false
  with _ -> false

let update (fout,fin) (x,y,z) (phi,theta,psi) =
  Printf.fprintf fout "%e,%e,%e,%e,%e,%e\n" x y z phi theta psi;
  flush fout;
	if not !init_command then begin
		init_command := true;
		xd := x; yd := y; zd := z;
	end;
	while (read_command fin) do () done;
	(!xd,!yd,!zd)

