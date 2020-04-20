# practice of makefile
# @ not show this line but show the content of echo
# name: execute line must have a tab at beginning
#

#fdf2xyz.o: #fdf2xyz.f90
#$(FC) -c fdf2xyz.f90
#fdf2xyzf90: #fdf2xyz.f90
#$(FC) -o fdf2xyz.f90 fdf2xyz.o
	#"$<" meaning?
	#$@ $^ meaning?
	#.f source file, .o target file
	#$< source file, $@ target file
	#$< first prerequisite
	#$^ all prerequisite
	#$@ all target file
	#$@ all, $< abc.f90, $^ abc.f90 def.f90
# suffixes rules .a.b, like .f.o, when you see .f, make a .o file
.SUFFIXES: .f90 .f .c .o

all: say_hello fdf2xyzf90

FC=ifort
FC:=ifort
cc=icc
cc:=icc

LDLIBS= -lreadline

OBJ= fdf2xyz.o \
		 fdf2xyz_print.o \
		 fdf2xyz_inputfilename.o \
		 jsu_readline.o \
		 FCreadline.o \
		 fdf2xyz_readfile.o \
		 fdf2xyz_read2end.o \
		 fdf2xyz_allocatable.o \
		 readcharlen.o \
		 readatomname.o \
		 userread.o \
		 writefilecheck.o

say_hello:
	@echo "Hello man"

fdf2xyzf90: $(OBJ)
	$(FC) -o $@ $^ $(LDLIBS)

.f90.o: 
	$(FC) -c $< 

.f.o: 
	$(FC) -c $<

.c.o: 
	$(cc) -c $< 

#writefilecheck.o: fdf2xyz_print.o
#userread.o: fdf2xyz_allocatable.o jsu_readline.o
#readatomname.o: fdf2xyz_allocatable.o
fdf2xyz_readfile.o: fdf2xyz_read2end.o readcharlen.o fdf2xyz_allocatable.o readatomname.o userread.o \
			writefilecheck.o #fdf2xyz_print.o 
jsu_readline.o: FCreadline.o
fdf2xyz_inputfilename.o: fdf2xyz_print.o
fdf2xyz.o: fdf2xyz_inputfilename.o jsu_readline.o fdf2xyz_readfile.o #fdf2xyz_print.o 

clean:
	@echo "cleaning up..."
	rm -f *.o *.mod fdf2xyzf90
