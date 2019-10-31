      program car2Lammps

      integer*4 i, j, k, l, m, n, num, tid(200000), check_name(20)
      integer*4 id(200000), eid(200000), num_ele(20), no, ele
      integer*4 sort(20,200000), types, isa1, isa2, count
      integer*4 z_sort(20,200000), cc
      integer*4 atom1(20), atom2(20)
      real*8    cell(6), tpos(200000,3), epos(200000,3), pos(200000,3)
      character*64 dummy
      character*64 filename
      character*2  element(200000), name(20)
      character*3  aa

      call getarg(1,filename)
      open(10,FILE=filename, form='formatted', status='old',
     $     err=99, access='sequential')
      open(20,FILE='position.fdf', form='formatted', status='unknown',
     $     access='sequential')
      
C      read(10,'(1X,20(A2,1X))')(name(i),i=1,20)

C      do i=1, 20
C         write(*,'(A2)')name(i)
C         if(name(i) == '  ') then
C            types = i-1
C            exit
C         end if
C      end do

      do i=1, 20
         num_ele(i) = 0
      end do

      do i=1, 4
         read(10,'(A64)') dummy
      end do

      read(10,'(3X,6(F10.4))') (cell(i),i=1,6)
      write(*,*)  (cell(i),i=1,6)

      aa ='aaa'
      write(*,*)'aaa=', aa
      num = 0
      do l=1, 200000
         num = num+1
         read(10,'(A3,2X,3(F15.9),21X,A2)') 
     $        aa,(tpos(num,i),i=1,3), element(num)
        if(aa =='end')go to 100
        write(*,*)num,element(num), (tpos(num,i),i=1,3)
         if(num == 1) then
            name(1) = element(num)
            num_ele(1) = num_ele(1)+1
            sort(1,1) = num
            ele = 1
            tid(1) = ele
         else
            do i= 1, ele
               if(name(i) == element(num)) then
                  num_ele(i) = num_ele(i)+1
                  sort(i,num_ele(i)) = num
                  tid(num) = i
                  go to 50
               endif
            end do
            ele = ele+1
            name(ele) = element(num)
            num_ele(ele) = num_ele(ele)+1
            sort(ele,num_ele(ele)) = num
            tid(num) = ele
         endif
                  

C         element(num)(2:2)=' '
C         do i=1, num-1
C            if(element(num)==element(i)) then
C               tid(num) = i
C               num_ele(i) = num_ele(i)+1
C               sort(i,num_ele(i)) = num
C               go to 50
C            endif
C         end do
 50   end do
 100  continue
C      num = num-1
C      do i=1, num
C         write(*,*) i, tid(i)
C      end do

      num = 0
      do i=1, ele
         atom1(i) = num+1
         atom2(i) = num+num_ele(i)
         num = num+num_ele(i)
         write(*,*) 'num ele',i, '=',num_ele(i)
      end do
      
      do i=1, ele
         isa1 = atom1(i)
         isa2 = atom2(i)
         count = 0
        do j= isa1, isa2
            count = count+1
            no = sort(i,count)
            eid(j) = tid(no)
            epos(j,1) = tpos(no,1)
            epos(j,2) = tpos(no,2)
            epos(j,3) = tpos(no,3)
         end do
      end do

      do i=1, ele
         isa1 = atom1(i)
         isa2 = atom2(i)
         count = 0
         do j=isa1, isa2
            if(j == isa1) then
               z_sort(i,1) = j
            else 
               count = count+1
               do k=1, count
                  if(epos(j,3) <= epos((z_sort(i,k)),3)) then
                     n = count-k+1
                     do l=1, n
                        z_sort(i,count-l+2) = z_sort(i,count-l+1)
                     end do
                     z_sort(i,k) = j
                     go to 300
                  else if(k == count) then
                     z_sort(i,count+1) = j
                  endif
               end do
            endif
 300     end do

         do m=1, count+1
            no = z_sort(i,m)
            write(*,'(I5,1X,I2,1X,3(F10.5))')
     $           m, eid(no), epos(no,1), epos(no,2), epos(no,3)
         end do
         
         cc =0
         do m=isa1, isa2
            cc = cc+1
            no = z_sort(i,cc)
            id(m) = eid(no)
            pos(m,1) = epos(no,1)
            pos(m,2) = epos(no,2)
            pos(m,3) = epos(no,3)
         end do
      end do

      write(20,*)'%block AtomicCoordinatesAndAtomicSpecies'
      do i=1, num
         write(20,'(3(F12.7),1X,I2,1X,A2)') 
     $        (pos(i,j),j=1,3),id(i),name(id(i))
      end do
      write(20,*)'%endblock AtomicCoordinatesAndAtomicSpecies'

 99   stop
      end

