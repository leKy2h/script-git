! 
! Copyright (C) 1996-2016	The SIESTA group
!  This file is distributed under the terms of the
!  GNU General Public License: see COPYING in the top directory
!  or http://www.gnu.org/copyleft/gpl.txt.
! See Docs/Contributors.txt for a list of contributors.
!

      program grid2cube

c****************************************************************************
c GRID2CUBE   version 1.1.1
c
c This program GRID2CUBE transform files with info on the grid from SIESTA
c to the Gaussian CUBE format, that can be read by packages like MOLEKEL
c and MOLDEN, to plot charges, potentials, etc. on real space.
c
c Written by P. Ordejon, August 2002
C Last modification: June 2003
c****************************************************************************
c CAVEATS:
c 
c This version only works with ORTHOGONAL cells, where the cell vectors
c are in the X, Y and Z directions. Extension to non-orthogonal cells
c might be done in future versions.
c****************************************************************************
c USAGE:
c 
c This program reads files generated from SIESTA, with information of
c physical quantities on the real space grid, such as charge densities
c (filename.RHO, filename.DRHO, filename.LDOS) or potentials (filename.VH,
c filename.VT) and translates them to the Gaussian CUBE format, that
c can be used as an input for visualization packages like MOLEKEL and
c MOLDEN.
c
c The program needs three input files:
c
c 1) Main input file, read by standard input. A sample of input file is:
c
c    --- begin input file ---
c        h2o
c        rho
c        4.0 6.0 5.0
c        2
c        unformatted
c    --- end input file ---
c
c    where:
c    - The first line is the label of the system, as in SIESTA SystemLabel.
c      Files will be searched as SystemLabel.* (in the example, h2o.RHO).
c    - The second line is the task, which should be one of the following:
c      rho, drho, ldos, vh or vt (in lowercase!!).
c    - The third line is a shift of the origin of coordinates (in bohr).
c      This is useful, for instance, when plotting molecules, if the
c      center of the molecule is close to the simulation cell walls.
c      In that case, the molecule would appear split, due to the 
c      contributions from multiple images. Shifting the molecule will 
c      make it to appear centered in the image, and make it look
c      as a single object
c    - The forth line is an integer (nskip) that specifies the density of 
c      grid points in the output. For each direction, only one of every
c      'nskip' points from the input will be written to the output.
c      nskip = 1 will yield an output with the same number of grid points 
c      than the input; nskip = N will provide an output N**3 less dense
c      than the input. This option is provided because some
c      visualization programs can not handle the large memory involved
c      in large systems with very fine grids, so the grid must be
c      made coarser.
c    - The fifth line indicates if the grid data file SystemLabel.TASK
c      is formatted or unformatted (the latter being the standard option
c      in SIESTA)
c     
c 2) SystemLabel.XV file: this is a file generated by SIESTA, with the
c    information on the lattice vectors and the atomic positions.
c    In example above: h2o.XV. You should copy it from the directory
c    with your SIESTA output files.
c
c 3) SystemLabel.TASK file: this is a file generated by SIESTA, with 
c    the values of the appropriate quantity on the grid.
c    In example above: h2o.RHO. You should copy it from the directory
c    with your SIESTA output files.
c
c
c The program generates some informative output on standard output, 
c and writes one or two files with the converted grid data. 
c If your SIESTA calculation was not spin polarized, there will be only
c one output file: SystemLabel.TASK.cube with the information in Gaussian
c CUBE format.
c If your SIESTA calculation was spin polarized, there will be two
c output files: SystemLabel.TASK.UP.cube and SystemLabel.TASK.DN.cube,
c with the information of the physical quantity for the two spin components,
c in Gaussian CUBE format (except for the Hartree potential, VH, which
c has the same value for both spins, and therefore is only plotted once
c in SystemLabel.VH.cube).
c****************************************************************************

      implicit none

      integer           maxp, natmax, nskip

      parameter         (maxp = 12000000)
      parameter         (natmax = 1000)

      integer           ipt, isp, ix, iy, iz, i, ip, natoms, np, 
     .                  mesh(3), nspin, Ind, id(3), iix, iiy,
     .                  iiz, ii, length, lb
      integer           is(natmax), izat(natmax)

      character         sysname*70, fnamein*75, fnameout(2)*75, 
     .                  fnamexv*75, paste*74, task*5, fform*12

      real              rho(maxp,2), rhot(maxp,2)

      double precision  cell(3,3), xat(natmax,3), cm(3), rt(3),
     .                  delta(3), dr(3), residual

      external  paste, lb

c ---------------------------------------------------------------------------


      read(5,*) sysname
      read(5,*) task
      read(5,*) rt(1),rt(2),rt(3)
      read(5,*) nskip
      read(5,*) fform

      fnamexv = paste(sysname,'.XV')
      if (task .eq. 'rho') then
        fnamein = paste(sysname,'.RHO')
      else if (task .eq. 'drho') then 
        fnamein = paste(sysname,'.DRHO')
      else if (task .eq. 'ldos') then 
        fnamein = paste(sysname,'.LDOS')
      else if (task .eq. 'vt') then 
        fnamein = paste(sysname,'.VT')
      else if (task .eq. 'vh') then 
        fnamein = paste(sysname,'.VH')
      else if (task .eq. 'bader') then 
        fnamein = paste(sysname,'.BADER')
      else
        write(6,*) 'Wrong task'
        write(6,*) 'Accepted values:  rho, drho, ldos, vh, vt, bader'
        write(6,*) '(in lower case!!!!)'
        stop
      endif


      length = lb(fnamein)
      write(6,*) 
      write(6,*) 'Reading grid data from file ',fnamein(1:length)

c read function from the 3D grid --------------------------------------------

      open( unit=1, file=fnamein, form=fform, status='old' )

      if (fform .eq. 'unformatted') then
        read(1) cell
      else if (fform .eq. 'formatted') then
        do ix=1,3
          read(1,*) (cell(iy,ix),iy=1,3)
        enddo
      else
        stop 'ERROR: last input line must be formatted or unformatted'
      endif
  

      write(6,*) 
      write(6,*) 'Cell vectors'
      write(6,*) 
      write(6,*) cell(1,1),cell(2,1),cell(3,1)
      write(6,*) cell(1,2),cell(2,2),cell(3,2)
      write(6,*) cell(1,3),cell(2,3),cell(3,3)

      residual = 0.0d0
      do ix=1,3
      do iy=ix+1,3
        residual = residual + cell(ix,iy)**2
      enddo
      enddo

      if (residual .gt. 1.0d-6) then
        write(6,*) 
        write(6,*) 'ERROR: this progam can only handle orthogonal cells'
        write(6,*) ' with vectors pointing in the X, Y and Z directions'
        stop
      endif

      if (fform .eq. 'unformatted') then
        read(1) mesh, nspin
      else
        read(1,*) mesh, nspin
      endif

      write(6,*) 
      write(6,*) 'Grid mesh: ',mesh(1),'x',mesh(2),'x',mesh(3)
      write(6,*) 
      write(6,*) 'nspin = ',nspin
      write(6,*) 

      do ix=1,3
        dr(ix)=cell(ix,ix)/mesh(ix)
      enddo

      np = mesh(1) * mesh(2) * mesh(3)
      if (np .gt. maxp) stop 'grid2d: Parameter MAXP too small'
C      read(1) ( (rho(ip,isp), ip = 1, np), isp = 1,nspin)
      do isp=1,nspin
        Ind=0
        if (fform .eq. 'unformatted') then
          do iz=1,mesh(3)
          do iy=1,mesh(2)
            read(1) (rho(Ind+ix,isp),ix=1,mesh(1))
            Ind=Ind+mesh(1)
          enddo
          enddo
        else
          do iz=1,mesh(3)
          do iy=1,mesh(2)
            read(1,'(e15.6)') (rho(Ind+ix,isp),ix=1,mesh(1))
            Ind=Ind+mesh(1)
          enddo
          enddo
        endif
      enddo

C translate cell
      do ix=1,3
        delta(ix) = rt(ix)/dr(ix)
        id(ix) = delta(ix)
        delta(ix) = rt(ix) - id(ix) * dr(ix)
      enddo

      do iz=1,mesh(3)
      do iy=1,mesh(2)
      do ix=1,mesh(1)
        iix=ix+id(1)
        iiy=iy+id(2)
        iiz=iz+id(3)
        if (iix .lt. 1) iix=iix+mesh(1)
        if (iiy .lt. 1) iiy=iiy+mesh(2)
        if (iiz .lt. 1) iiz=iiz+mesh(3)
        if (iix .gt. mesh(1)) iix=iix-mesh(1)
        if (iiy .gt. mesh(2)) iiy=iiy-mesh(2)
        if (iiz .gt. mesh(3)) iiz=iiz-mesh(3)

        if (iix .lt. 1) stop 'ix < 0'
        if (iiy .lt. 1) stop 'iy < 0'
        if (iiz .lt. 1) stop 'iz < 0'
        if (iix .gt. mesh(1)) stop 'ix > cell'
        if (iiy .gt. mesh(2)) stop 'iy > cell'
        if (iiz .gt. mesh(3)) stop 'iz > cell'
        i=ix+(iy-1)*mesh(1)+(iz-1)*mesh(1)*mesh(2)
        ii=iix+(iiy-1)*mesh(1)+(iiz-1)*mesh(1)*mesh(2)
        do isp=1,nspin
          rhot(ii,isp)=rho(i,isp)
        enddo
      enddo
      enddo
      enddo

      close(1)

      open( unit=3, file=fnamexv, status='old', form='formatted')
      read(3,*)
      read(3,*)
      read(3,*)
      read(3,*) natoms
      do i=1,natoms
        read(3,*) is(i),izat(i),(xat(i,ix),ix=1,3)
      enddo

      do i=1,natoms
        do ix=1,3
          xat(i,ix)=xat(i,ix)+rt(ix)-delta(ix)
          if (xat(i,ix) .lt. 0.0) xat(i,ix)=xat(i,ix)+cell(ix,ix)
          if (xat(i,ix) .gt. cell(ix,ix)) 
     .        xat(i,ix)=xat(i,ix)-cell(ix,ix)
        enddo
      enddo
      close(3)



      if (nspin .eq. 1) then
        fnameout(1) = paste(fnamein,'.cube')
      else if (nspin .eq. 2) then
        fnameout(1) = paste(fnamein,'.UP.cube')
        fnameout(2) = paste(fnamein,'.DN.cube')
      else 
        stop 'nspin must be either 1 or 2'
      endif

      do isp=1,nspin

      length = lb(fnameout(isp))
      write(6,*) 'Writing CUBE file ',fnameout(isp)(1:length)

C      open( unit=2, file=fnameout(isp), status='new', form='formatted')
      open( unit=2, file=fnameout(isp), form='formatted')

      length = lb(fnameout(isp))
      write(2,*) fnameout(isp)(1:length)
      write(2,*) fnameout(isp)(1:length)
      write(2,'(i5,4f12.6)') natoms, 0.0,0.0,0.0

      do ix=1,3
        ii = mesh(ix)/nskip
        if (ii*nskip .ne. mesh(ix)) ii = ii+1
        write(2,'(i5,4f12.6)') 
     .    ii,(cell(ix,iy)/ii,iy=1,3)
      enddo

      do i=1,natoms
        write(2,'(i5,4f12.6)') izat(i),0.0,(xat(i,ix),ix=1,3)
      enddo



      do ix=1,mesh(1),nskip
      do iy=1,mesh(2),nskip

        write(2,'(6e13.5)') 
     .  (rhot(ix+(iy-1)*mesh(1)+(iz-1)*mesh(1)*mesh(2),isp), 
     .   iz=1,mesh(3),nskip)

      enddo
      enddo

      close(2)

      enddo

      write(6,*) 

      end


      CHARACTER*(*) FUNCTION PASTE( STR1, STR2 )

C CONCATENATES THE STRINGS STR1 AND STR2 REMOVING BLANKS IN BETWEEN
C Writen by Jose M. Soler

      CHARACTER*(*) STR1, STR2
      DO 10 L = LEN( STR1 ), 1, -1
         IF (STR1(L:L) .NE. ' ') GOTO 20
   10 CONTINUE
   20 PASTE = STR1(1:L)//STR2
      END


      INTEGER FUNCTION LB ( STR1 )

C RETURNS THE SIZE IF STRING STR1 WITH BLANKS REMOVED
C Writen by P. Ordejon from Soler's paste.f

      CHARACTER*(*) STR1
      DO 10 L = LEN( STR1 ), 1, -1
         IF (STR1(L:L) .NE. ' ') GOTO 20
   10 CONTINUE
   20 LB = L
      END