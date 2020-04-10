      module m_read2end

        private
        public read2end

        contains

          subroutine read2end(fileindex, ln)

            implicit none

            integer r2e
            integer, intent(in) :: fileindex
            integer, intent(out) :: ln
            character(256) dummy

            ln = 0

            do
            read(fileindex,'(a)', iostat=r2e) dummy
            if(r2e/=0)then
              goto 999
            else
              ln = ln + 1
            endif
            enddo

999     continue

            rewind(fileindex)

            endsubroutine read2end

          endmodule




