OCAMLC    ?= ocamlc -I /home/cv/.opam/4.08.0/lib/ocaml
OCAMLFLAGS    ?= -annot

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

# implicit rules

.SUFFIXES : .mli .ml .cmi .cmo .cmx .zls .zli .byte 

%.cmi: %.mli
	$(OCAMLC) $(OCAMLFLAGS) -c $(INCLUDES) $<

%.cmo %.cmi: %.ml
	$(OCAMLC) $(OCAMLFLAGS) -c -I $(ZLLIB) $(INCLUDES) $<

%.zci: %.zli
	$(ZELUC) $(ZELUCFLAGS) $<

%.ml: %.zls
	$(ZELUC) $(ZELUCFLAGS) $<

all:  drone.byte drone3d.byte

drone3d.byte: INCLUDES += -I +lablgtk2 $(SUNDIALS) $(GLMLITE)
drone3d.byte: ZLEXTRALIBS += GL.cma Glu.cma Glut.cma
drone3d.byte: world.cmo drone.cmo matrix.cmo drone3d.cmo drone3d_main.ml
	$(OCAMLC) $(OCAMLFLAGS) -o $@ $(INCLUDES) -I $(ZLLIB) $(ZLSTDLIBS) $(ZLEXTRALIBS) \
						matrix.cmo drone.cmo world.cmo drone3d.cmo drone3d_main.ml

drone3d.ml drone3d_main.ml: drone3d.zls drone.zci world.zci
	$(ZELUC) $(ZELUCFLAGS) -gtk2 -s main $<
	mv main.ml drone3d_main.ml

world.cmi: world.mli

world.cmo: INCLUDES += $(GLMLITE)
world.cmo: world.ml world.cmi

world.zci: world.zli

drone.byte: drone.cmo matrix.cmo drone_main.ml
	$(OCAMLC) $(OCAMLFLAGS) -o $@ $(INCLUDES) -I $(ZLLIB) $(ZLSTDLIBS) $(ZLEXTRALIBS) \
						matrix.cmo drone.cmo drone_main.ml

drone.ml: matrix.cmi matrix.zci

clean:
	-@rm -f *.o *.cm[oix] *.annot *.obc *.zci
	-@rm -f drone.ml matrix.ml drone_main.ml drone3d.ml drone3d_main.ml
	-@rm -f drone3d.byte 

realclean cleanall: clean

# Common rules
.SUFFIXES : .ml .zls .zci

matrix.ml matrix.zci: matrix.zls
	$(ZELUC) $(ZELUCFLAGS) $<

%.ml %.zci: %.zls
	$(ZELUC) $(ZELUCFLAGS) -s main -sampling 9 -gtk2 $<
	mv main.ml $(<:.zls=)_main.ml

