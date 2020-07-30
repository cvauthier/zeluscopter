OCAMLC?= ocamlc -I /home/cv/.opam/4.08.0/lib/ocaml

GLMLITE = -I /home/cv/.opam/4.08.0/lib/glMLite

LABLGTK2 = -I /home/cv/.opam/4.08.0/lib/lablgtk2

SUNDIALS=-I /home/cv/.opam/4.08.0/lib/sundialsml
SUNDIALS_CVODE = sundials.cma

ZLSTDLIBS = bigarray.cma unix.cma $(SUNDIALS) $(SUNDIALS_CVODE)
ZLEXTRALIBS = zllib.cma
ZLGTKLIBS = $(LABLGTK2) lablgtk.cma zllibgtk.cma

ZELUC = ../zelus/bin/zeluc
ZLLIB = ../zelus/lib
ZLEXTRALIBS = $(ZLGTKLIBS)

PRODUCED_ML=parameters.ml matrix.ml controller.ml physics.ml drone.ml drone3d.ml drone_main.ml drone3d_main.ml
OBJS=tools.cmo parameters.cmo matrix.cmo physics.cmo controller.cmo drone.cmo 
OBJS3D=$(OBJS) world.cmo drone3d.cmo

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

drone3d.byte: INCLUDES += -I +lablgtk2 $(SUNDIALS) $(GLMLITE)
drone3d.byte: ZLEXTRALIBS += GL.cma Glu.cma Glut.cma
drone3d.byte: $(OBJS3D) drone3d_main.ml
	$(OCAMLC) $(OCAMLFLAGS) -o $@ $(INCLUDES) -I $(ZLLIB) $(ZLSTDLIBS) $(ZLEXTRALIBS) $(OBJS3D) drone3d_main.ml

drone3d_main.ml: 
	$(ZELUC) $(ZELUCFLAGS) -gtk2 -s main drone3d.zls
	mv main.ml drone3d_main.ml

drone_main.ml:
	$(ZELUC) $(ZELUCFLAGS) -gtk2 -s main drone.zls
	mv main.ml drone_main.ml

drone.byte: $(OBJS) drone_main.ml
	$(OCAMLC) $(OCAMLFLAGS) -o $@ $(INCLUDES) -I $(ZLLIB) $(ZLSTDLIBS) $(ZLEXTRALIBS) $(OBJS) drone_main.ml

world.cmo: INCLUDES += $(GLMLITE)
drone.ml: tools.zci
drone3d.ml: world.zci

clean:
	-@rm -f *.o *.cm[oix] *.annot *.obc *.zci $(PRODUCED_ML)
	-@rm -f drone.byte drone3d.byte 

