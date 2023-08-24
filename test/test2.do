/* This will test the packagesearch package */
/* Note this will run the *local* version, not the to-be-installed version */
/* expected output: 

Test 2-1:

  Processing file data/test2/longwords_nounderscores.do
w_axthisisalongwordxgoingxupxtoxh invalid name
             st_addvar():  3300  argument out of range
               wordbag():     -  function returned error
            mm_txttool():     -  function returned error
                 <istmt>:     -  function returned error
Error: file data/test2/longwords_nounderscores.do contains long string unable t
> o be processed. It has been omitted from the scanning process.

Test 2-2:


     +-----------
     |   match   
     |-----------
  1. | reghdfe   
     +-----------

. exit, clear STA

*/


include "test/install.do"
which packagesearch
packagesearch, codedir(data/test2) 
exit, clear STATA
