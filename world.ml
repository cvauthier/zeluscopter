
type t = out_channel

let create pos angles =
  let input, output = Unix.pipe () in
  let outch = Unix.out_channel_of_descr output in
  match Unix.fork () with
  | 0 -> (Unix.close input; outch) (* child *)
  | _ -> (* parent process *)
      begin
        Unix.close output;
        Unix.set_nonblock input;
				Unix.dup2 input Unix.stdin;
				Unix.execv "visualizer" [||];
        outch
      end

let update fout (x,y,z) (phi,theta,psi) =
  Printf.fprintf fout "%e,%e,%e,%e,%e,%e\n" x y z phi theta psi;
  flush fout

