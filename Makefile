OCAMLC?= ocamlc -I /home/cv/.opam/4.08.0/lib/ocaml

LABLGTK2 = -I /home/cv/.opam/4.08.0/lib/lablgtk2

SUNDIALS=-I /home/cv/.opam/4.08.0/lib/sundialsml
SUNDIALS_CVODE = sundials.cma

ZLSTDLIBS = bigarray.cma unix.cma $(SUNDIALS) $(SUNDIALS_CVODE)
ZLEXTRALIBS = zllib.cma
ZLGTKLIBS = $(LABLGTK2) lablgtk.cma zllibgtk.cma

ZELUC = ../zelus/bin/zeluc
ZLLIB = ../zelus/lib
ZLEXTRALIBS = $(ZLGTKLIBS)

PRODUCED_ML=parameters.ml matrix.ml controller.ml physics.ml drone.ml drone_main.ml drone3d_main.ml
OBJS=world.cmo parameters.cmo matrix.cmo physics.cmo controller.cmo drone.cmo 

.SUFFIXES : .mli .ml .cmi .cmo .cmx .zls .zli .zci .byte 

all: drone.byte drone3d.byte

%.cmi: %.mli
	$(OCAMLC) $(OCAMLFLAGS) -c -I $(ZLLIB) $(INCLUDES) $<

%.cmo: %.ml
	$(OCAMLC) $(OCAMLFLAGS) -c -I $(ZLLIB) $(INCLUDES) $<

%.zci: %.zli
	$(ZELUC) $(ZELUCFLAGS) $<

%.ml: %.zls
	$(ZELUC) $(ZELUCFLAGS) $<

drone3d.byte: INCLUDES += -I +lablgtk2 $(SUNDIALS) 
drone3d.byte: $(OBJS3D) drone3d_main.ml visualizer
	$(OCAMLC) $(OCAMLFLAGS) -o $@ $(INCLUDES) -I $(ZLLIB) $(ZLSTDLIBS) $(ZLEXTRALIBS) $(OBJS) drone3d_main.ml

drone3d_main.ml: 
	$(ZELUC) $(ZELUCFLAGS) -gtk2 -s main3d drone.zls
	mv main3d.ml drone3d_main.ml

drone_main.ml:
	$(ZELUC) $(ZELUCFLAGS) -gtk2 -s main drone.zls
	mv main.ml drone_main.ml

drone.byte: $(OBJS) drone_main.ml
	$(OCAMLC) $(OCAMLFLAGS) -o $@ $(INCLUDES) -I $(ZLLIB) $(ZLSTDLIBS) $(ZLEXTRALIBS) $(OBJS) drone_main.ml

visualizer:
	g++ -o visualizer visualizer.cpp -lIrrlicht

world.cmo: world.zci

clean:
	-@rm -f *.o *.cm[oix] *.annot *.obc *.zci $(PRODUCED_ML)
	-@rm -f drone.byte drone3d.byte visualizer

