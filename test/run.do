/* This will test the packagesearch package */
/* Note this will run the *local* version, not the to-be-installed version */

packagesearch, codedir(data)

/* expected output: 

     +-------------------------------+
     |   match   rank   probFalsePos |
     |-------------------------------|
  1. | reghdfe      8              0 |
  2. |  ftools     10              0 |
     +-------------------------------+

*/
exit, clear
