Zeluscopter
===========

Build instructions
------------------

Required software:
* Zélus v2: https://github.com/inria/zelus
* Sundials/ML: http://inria-parkas.github.io/sundialsml/
* Irrlicht Engine: http://irrlicht.sourceforge.net/

Installation instructions
```
apt install libsundials-dev libgtk2.0-dev libirrlicht-dev
opam install ocamlfind sundialsml lablgtk menhir
git clone git@github.com:INRIA/zelus.git
(cd zelus; ./configure; make)
```

Then update the `Makefile`, setting the `ZELUS` variable to the path to the 
compiled Zélus binary and library files.

Type `make` to build the simulator and visualizer.

The visualizer
--------------

The visualizer operates in two modes:

* Camera mode (the default): the arrow keys and `w`/`s` control, 
  respectively, the angle and zoom of the windows point-of-view relative to 
  the drone.

* Command mode: the arrow keys and `w`/`s` set, respectively, the drone's 
  desired x/y position and height. By default the commands are synchronized 
  with the drone controller's sampling period. The `n` key toggles 
  synchronization on and off.

The `c` key switches between the modes.

