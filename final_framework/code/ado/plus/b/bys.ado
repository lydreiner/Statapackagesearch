*! 1.1.0  (March 3, 1996)  Jeroen Weesie/ICS
program define bys
   version 5.0
   if "`*'" == "" { exit 198 }

   parse "`*'", parse(":()")
   if index(substr("`1'",1,1),":()") > 0 { exit 198 }
        
   unabbrev `1', min(1)
   local vlist $S_1
   mac shift

   if "`1'" == "(" {
      if "`3'" ~= ")" { exit 198 }
      unabbrev `2', min(1)
      local vbylist " $S_1"
      mac shift 3
   }

   if "`1'" ~= ":" { exit 198 }
   mac shift 
       
   * only sort and, consequently, change sort-order, if necessary
   local sorder : sortedby
   if ("`sorder'"=="") | (index("#`sorder'","#`vlist'`vbylist'")==0) { 
      sort `vlist' `vbylist'
   }
       
   by `vlist' : `*'
end