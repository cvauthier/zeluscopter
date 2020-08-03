(* Uses Florent Monnier's OpenGL bindings for Ocaml:
 *   http://www.linux-nantes.org/~fmonnier/ocaml/GL/?p=home
 *)

open GL
open Glu
open Glut

let update_period = 4

let lightOnePosition = (280.0, 100.0, 50.0, 0.0)
let lightAmbient = (0.5, 0.5, 0.5, 1.0)
let lightDiffuse = (0.2, 0.2, 0.2, 1.0)

let rad_to_deg alpha = 180. *. alpha /. 3.1416

let read_state fin =
  try 
    let s = input_line fin in
		let rec aux i = function
			| 1 -> [float_of_string (String.sub s i (String.length s - i))]
			| n -> let j = String.index_from s i ',' in
						 (float_of_string (String.sub s i (j-i)))::(aux (j+1) (n-1)) in
		match (aux 0 6) with
			| [x;y;z;phi;theta;psi] -> Some((x,y,z),(phi,theta,psi))
			| _ -> None
  with _ -> None

let draw_floor () =
  glPushMatrix ();
  glColor3 0.0 0.5 0.0;
  glTranslate 0.0 0.0 (-. 1.0);
  glScale 1.0 1.0 0.01;
  glutSolidCube 200.0;
  glPopMatrix ()

let draw_drone () =
	let l = 1. in
	let drone_triangles = [ ([(0.,-. l,0.);(l,0.,0.);(0.,l,0.)],      (0.5,0.5,0.5));
													([(0.,-. l,0.);(-. l,0.,0.);(0.,l,0.)],   (0.5,0.5,0.5));
													([(0.,l,0.);(l,0.,0.);(0.,0.,-. l)],		  (1.0,0.0,0.0));
													([(0.,-. l,0.);(l,0.,0.);(0.,0.,-. l)],   (0.0,1.0,0.0));
													([(-. l,0.,0.);(0.,-. l,0.);(0.,0.,-. l)],(0.0,0.0,1.0));
													([(-. l,0.,0.);(0.,l,0.);(0.,0.,-. l)],		(1.0,1.0,0.0))] in 
	let aux (x,y,z) = glVertex3 x y z in
	glBegin GL_TRIANGLES;
	List.iter (fun (l,(r,g,b)) -> glColor3 r g b; List.iter aux l) drone_triangles;
	glEnd ()

let display pos angles () =
	let (x,y,z) = !pos and (phi,theta,psi) = !angles in

  glClear [GL_COLOR_BUFFER_BIT; GL_DEPTH_BUFFER_BIT];
  glLoadIdentity();

	gluLookAt 0.0 10.0 10.0 0.0 0.0 10.0 0.0 0.0 1.0;
  glPushMatrix();
  
	glLight (GL_LIGHT 0) (Light.GL_POSITION lightOnePosition);

  draw_floor ();
  
	glScale (-. 1.0) (-. 1.0) (-. 1.0);
	glTranslate x y z;
	glRotate (rad_to_deg psi) 0.0 0.0 1.0;
	glRotate (rad_to_deg theta) 0.0 1.0 0.0;
	glRotate (rad_to_deg phi) 1.0 0.0 0.0;

  glMaterial GL_FRONT (Material.GL_AMBIENT (1.0, 1.0, 1.0, 1.0));
  draw_drone ();

  glPopMatrix();

  glutSwapBuffers()

(* initialisation and interface with glut *)

let make_model_functions pos0 angles0 fin =
  let pos = ref pos0 in
  let angles = ref angles0 in

  let rec update ~value:() =
    match read_state fin with
    | None -> schedule_update ()
    | Some(npos,nangles) ->
        begin
          pos := npos;
          angles := nangles;
          schedule_update ();
          glutPostRedisplay ()
        end
  and schedule_update () =
    glutTimerFunc ~msecs:update_period ~timer:update ~value:()

  in (display pos angles, update, schedule_update)

let reshape ~width:w ~height:h =
  glViewport 0 0 w h;
  glMatrixMode GL_PROJECTION;
  glLoadIdentity();
  let aspect = ((float w) /. (float (max 1 h))) in
  gluPerspective ~fovy:60.0 ~aspect ~zNear:0.5 ~zFar:100.0;
  glMatrixMode GL_MODELVIEW;
  glutPostRedisplay()

let gl_init () =
  glShadeModel GL_SMOOTH;
  glClearColor 0.0 0.0 0.3 0.0;
  glClearDepth 1.0;
  glEnable GL_DEPTH_TEST;

  glLight (GL_LIGHT 0) (Light.GL_POSITION lightOnePosition);
  glLight (GL_LIGHT 0) (Light.GL_DIFFUSE  lightDiffuse);
  glLight (GL_LIGHT 0) (Light.GL_AMBIENT  lightAmbient);
  glEnable GL_LIGHT0;
  glEnable GL_LIGHTING;
  glColorMaterial GL_FRONT_AND_BACK GL_AMBIENT_AND_DIFFUSE;
  glEnable GL_COLOR_MATERIAL

let run_glut_loop pos angles fin =
  Random.self_init ();
  ignore (glutInit Sys.argv);

  glutInitDisplayMode [GLUT_RGB; GLUT_DOUBLE; GLUT_DEPTH];
  ignore(glutCreateWindow "Drone visualisation");
  glutReshapeWindow ~width:800 ~height:600;

  glutSetCursor GLUT_CURSOR_LEFT_ARROW;

  gl_init ();

  let (display, timer, start_timer) = make_model_functions pos angles fin in

  glutDisplayFunc  ~display;
  glutReshapeFunc  ~reshape;

  start_timer ();
  glutMainLoop()

type t = out_channel

let create pos angles =
  let input, output = Unix.pipe () in
  let outch = Unix.out_channel_of_descr output in
  match Unix.fork () with
  | 0 -> (Unix.close input; Unix.sleep 2; outch) (* child *)
  | _ -> (* parent process *)
      begin
        Unix.close output;
        Unix.set_nonblock input;
				Unix.dup2 input Unix.stdin;
				Unix.execv "visualizer" [||];
        (*run_glut_loop pos angles (Unix.in_channel_of_descr input); (* Never returns *)*)
        outch
      end

let update fout (x,y,z) (phi,theta,psi) =
  Printf.fprintf fout "%e,%e,%e,%e,%e,%e\n" x y z phi theta psi;
  flush fout

