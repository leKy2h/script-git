##############################################################################
# Shell Script: Run the simulation and generate file (that can be used by    #
# VESTA/Molekel/... for visualizing (open the file and Surfaces > Grid Data, #
# It is possible to open various files in only one window))                  #
#                                                                            #
# - To run it:                                                               #
# $ sh run-denchar.sh     	                                             #
#                                                                            #
# - The program denchar must be already compiled in the                      #
#      siesta folder (folder where siesta was installed).                    #
#    - Compile denchar (/home/guest/src/siesta-3.2-pl-5/Util/Denchar/Src)    #
#           $ make                                                           #
#                                                                            #
##############################################################################

D=/home/guest/src/siesta-3.2-pl-5 # Location of the siesta folder (folder
                                        # where siesta was installed) in the
                                        # computer being used

PATH=$D/Obj:$D/Util/Denchar/Src:$PATH # Location of gnubands
                                                        # and Eig2DOS programs
                                                        # in the siesta folder

label=denchar

denchar < ${label}.fdf | tee ${label}.out
