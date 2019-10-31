      Program MakeModel
      
      integer*4    i, j, k, l,n, numt, target(1000000), tmp, nobe, sum
      integer*4    num(20), flag(20), num_work, atnum, elenum
      integer*4    id1(20), id2(20), id(1000000), num_ele(20), ele
      integer*4    count, ir, nume, isa1(20), isa2(20), nom, type
      integer*4    pick(20,1000000), stor(1000000), stay(1000000)
      integer*4    nid(1000000), natnum, nwork(20,1000000)
      real*8       xmin(20), xmax(20), ymin(20), ymax(20)
      real*8       zmin(20), zmax(20), cell(3), pos(1000000,3)
      real*8       x_range1, x_range2, y_range1, y_range2
      real*8       z_range1, z_range2, r, xpos, ypos, zpos
      real*8       npos(1000000,3), mass(20)
      real*8       xlo, xhi, ylo, yhi, zlo, zhi
      character*64 filename, dummy
      character*1  aflag
      character*2  name1(20), name2(20)
      character*3  mode

      call getarg(1,filename)

      open(10,FILE='makemodel.in', form='formatted', status='old',
     $     err=100, access='sequential')

      open(20,FILE=filename, form='formatted', status='old',
     $     err=99, access='sequential')
      
      open(30,FILE='newdata.lammps', form='formatted', 
     $     status='unknown', access='sequential')
      

      read(10,'(A3)')mode
      read(10,'(A3)')mode
      i=0
      do while(mode /= 'end')
         i = i+1
         read(10,'(A3,1X,I2,1X,I5,1X,6(F5.3,1X),I2)')
     $        mode,id1(i),num(i),xmin(i),xmax(i),
     $        ymin(i),ymax(i),zmin(i),zmax(i),id2(i)
         if(mode=='Rep') then
            flag(i) = 1
         else if(mode == 'Del') then
            flag(i) = 2
         endif
         if(id2(i) /= 0) then
            mass(id2(i)) = 10.0d0
         endif
      end do

      num_work = i-1
      write(*,*)'num_work=',num_work
      do i=1, num_work
         write(*,'(I2,1X,I2,1X,I5,1X,6(F5.3,1X),I2)')
     $        flag(i),id1(i),num(i),xmin(i),xmax(i),
     $        ymin(i),ymax(i),zmin(i),zmax(i),id2(i)
      end do

      write(*,*)'Type of coordination of atoms'
      write(*,*)'(1) absolute (2) partial'
      read(5,*) type

      read(20,'(A64)')dummy
      read(20,'(A64)')dummy
      read(20,'(I8)')atnum
      read(20,'(A64)')dummy
      read(20,*)elenum,dummy
      read(20,'(A64)')dummy
      read(20,*)xlo, xhi
      read(20,*)ylo, yhi
      read(20,*)zlo, zhi
      cell(1) = abs(xhi-xlo)
      cell(2) = abs(yhi-ylo)
      cell(3) = abs(zhi-zlo)
      do i=1, 3
         read(20,'(A64)')dummy
      end do
      do i=1, elenum
         read(20,'(4X,F10.6)')mass(i)
         num_ele(i) = 0
      end do
      do i=1, 3
         read(20,'(A64)')dummy
      end do

      do i=1, atnum
         read(20,*)nom, id(i),(pos(i,j),j=1,3)
        if(type == 2) then
            do k=1, 3
               pos(i,k) = pos(i,k)*cell(k)
            end do
         end if
C         write(*,*)nom, id(i),(pos(i,j),j=1,3)

         stay(i) = 0
         num_ele(id(i)) = num_ele(id(i))+1
      end do


      do i=1, num_work
         numt = 0
         target = 0
         x_range1 = xmin(i)*cell(1)+xlo
         x_range2 = xmax(i)*cell(1)+xlo
         y_range1 = ymin(i)*cell(2)+ylo
         y_range2 = ymax(i)*cell(2)+ylo
         z_range1 = zmin(i)*cell(3)+zlo
         z_range2 = zmax(i)*cell(3)+zlo
         write(*,*)'x_range1=',x_range1, 'x_range2=',x_range2
         write(*,*)'y_range1=',y_range1, 'y_range2=',y_range2
         write(*,*)'z_range1=',z_range1, 'z_range2=',z_range2
         ele = id1(i)
         do j=1, atnum
           if(id(j) == ele) then
              if(pos(j,1) >= x_range1 .and. pos(j,1) <= x_range2 .and.
     $             pos(j,2) >= y_range1 .and. pos(j,2) <= y_range2 .and.
     $             pos(j,3) >= z_range1 .and. pos(j,3) <= z_range2) then
                 numt = numt+1
                 target(numt) = j
              end if
           endif
        end do
 

        sum = 0
        count = 0
        nobe = 0
        write(*,*)'number of target=',numt

        if(num(i) == 0) then
           num(i) = numt
           do k=1, numt
              pick(i,k) = target(k)
              stay(pick(i,k)) = 1
           end do
        else
           call random_seed()
           do while(count < num(i))
              call random_number(r)
              ir = idint(r*numt)
              tmp = target(ir)
              do k=1, nobe
                 if(tmp == stor(k)) then
                    write(*,*)'No',tmp
                    go to 200
                 endif
              end do

              count = count+1
              pick(i,count) = tmp
C           xpos = pos(pick(i,count),1)
C           ypos = pos(pick(i,count),2)
C           zpos = pos(pick(i,count),3)
              nobe = nobe+1
              stor(nobe) = pick(i,count)
              stay(pick(i,count)) = 1
              sum = sum+stay(pick(i,count))
C           write(*,*)'OK',count,pick(i,count)
C,xpos, ypos, zpos, 
C     $          stay(pick(i,count))
 200       end do
        end if
        write(*,*) 'Finish work #',i
      end do

C---- Sorting ----
      do i=1, num_work
C         if(flag(i) == 1) then
            do j=1, num(i)
               if(j==1) then
                  nwork(i,j) = pick(i,j)
               else
                  do k=1, j-1
                     if(pick(i,j) <= nwork(i,k)) then
                        do n=1, j-k
                           nwork(i,j-n+1) = nwork(i,j-n)
                        end do
                        nwork(i,k) = pick(i,j)
                        go to 300
                     end if
                  end do
                  nwork(i,j) = pick(i,j)
               end if
 300        end do
C         endif
      end do

      do i=1, num_work
         write(*,*)'work #',i
         do j=1, num(i)
            write(*,*)j, nwork(i,j)
         end do
      end do

      natnum = 0
      do i=1, atnum
         if(stay(i) == 0) then
            natnum = natnum+1
            nid(natnum) = id(i)
            npos(natnum,1) = pos(i,1)
            npos(natnum,2) = pos(i,2)
            npos(natnum,3) = pos(i,3)
         endif
      end do

      do i=1, num_work
         if(flag(i) == 1) then
            do j=1, num(i)
               natnum = natnum+1
               nele = nwork(i,j)
               write(*,*)'nele=',nele
               nid(natnum) = id2(i)
               npos(natnum,1) = pos(nele,1)
               npos(natnum,2) = pos(nele,2)
               npos(natnum,3) = pos(nele,3)
            end do
         endif
      end do

      write(30,*)' Position data'
      write(30,*)' '
      write(30,'(I8,1X,A5)')natnum, 'atoms'
      write(30,*)' '
      write(30,'(I3,1X,A10)')nid(natnum), 'atom types'
      write(30,*)' '
      write(30,'(1X,F11.6,1X,F11.6,1X,A7)')xlo, xhi,'xlo xhi'
      write(30,'(1X,F11.6,1X,F11.6,1X,A7)')ylo, yhi,'ylo yhi'
      write(30,'(1X,F11.6,1X,F11.6,1X,A7)')zlo, zhi,'zlo zhi'
      write(30,*)' '
      write(30,*)' Masses'
      write(30,*)' '
      do i=1, nid(natnum)
         write(30,'(I3,1X,F10.6)')i,mass(i)
      end do
      write(30,*)' '
      write(30,*)' Atoms'
      write(30,*)' '
      do i=1, natnum
         write(30,'(1X,I6,1X,I2,3(F12.7))')i,nid(i),(npos(i,j),j=1,3)
C         write(*,'(I6,1X,I2,3(F12.7))')i,nid(i),(npos(i,j),j=1,3)
      end do

      close(30)

      go to 99

 100  continue
      write(*,2000)
      write(*,2100)
      read(5,'(A1)') aflag
      if((aflag == "Y").or.(aflag == "y")) then
         open(20,FILE='makemodel.in',form='formatted',status='unknown',
     $        access='sequential')
         write(20,'(A51)')
     $        'Mod Id Chnum x min x max y min y max z min z max Nw'
         write(20,'(A51)')
     $        '--- -- ----- ----- ----- ----- ----- ----- ----- --'
         write(20,'(A51)')
     $        'Rep  1 10000 0.000 1.000 0.000 1.000 0.000 1.000  3'
         write(20,'(A51)')
     $        'Del  2   100 0.000 1.000 0.000 1.000 0.000 1.000  0'
         write(20,'(A3)')'end'
         write(6,2300)
      endif

 2000 format("The makemodel.in can not be found.")
 2100 format("Do you want to create makemodel.in (y/n) ?")
 2300 format("The makemodel.in is Created.")

      close(10)
      close(20)
      
 99   stop
      end
