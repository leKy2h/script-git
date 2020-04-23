.SUFFIXES: .f90 .c .o

EXECS = crt4run_shf90 crtfil4tbtf90 getiv2datf90 lmpdum2posf90
all: $(EXECS)

FC=ifort
FC:=ifort
cc=icc
cc:=icc

LDLIBS= -lreadline

getiv2dat_obj= getiv2dat.o
crt4run_sh_obj= crt4run_sh.o jsu_readline.o FCreadline.o 
crtfil4tbt_obj= crtfil4tbt.o jsu_readline.o FCreadline.o
lmpdum2pos_obj= lmpdum2pos.o jsu_readline.o FCreadline.o manual.o Lammps2fdf.o changeatnum.o

getiv2datf90: $(getiv2dat_obj)
	$(FC) -o $@ $^
crt4run_shf90: $(crt4run_sh_obj)
	$(FC) -o $@ $^ $(LDLIBS)
crtfil4tbtf90: $(crtfil4tbt_obj)
	$(FC) -o $@ $^ $(LDLIBS)
lmpdum2posf90: $(lmpdum2pos_obj)
	$(FC) -o $@ $^ $(LDLIBS)
.f90.o:
	$(FC) -c $<
.c.o:
	$(cc) -c $<

jsu_readline.o: FCreadline.o
crt4run_sh.o: jsu_readline.o
crtfil4tbt.o: jsu_readline.o
lmpdum2pos.o: jsu_readline.o manual.o Lammps2fdf.o changeatnum.o

clean:
	@echo "cleaning up..."
	rm -f $(EXECS) *.o *.mod
