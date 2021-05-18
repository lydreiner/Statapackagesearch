#delim ;
prog def parmby, rclass;
version 16.0;
*
 Call an estimation command followed by parmest
 (possibly with by-variables),
 creating an output data set containing the by-variables
 together with the parameter sequence number parmseq
 and all the variables in a -parmest- output data set.
*! Author: Roger Newson
*! Date: 31 December 2020
*;


gettoken cmd 0: 0;
if `"`cmd'"' == `""' {;error 198;};

syntax, [  LIst(passthru) FRAme(string asis) SAving(passthru) noREstore FAST * ];
/*
list() contains a varlist of variables to be listed,
  expected to be present in the output data set
  and referred to by the new names if REName is specified,
  together with optional if and/or in subsetting clauses and/or list_options
  as allowed by the list command.
frame() specifies a Stata data frame in which to create the output data set.
saving() specifies a file in which to save the output data set.
norestore specifies that the pre-existing data set
  is not restored after the output data set has been produced
  (set to norestore if FAST is present).
fast is now synonymous with norestore
  and is retained for backwards compatibility.
Other options are passed to _parmby.
*/


*
 Set restore to norestore if fast is present
 and check that the user has specified one of the four options:
 list and/or nd/or frame and/or saving and/or norestore and/or fast.
*;
if "`fast'"!="" {;
    local restore="norestore";
};
if (`"`list'"'=="")&(`"`frame'"'=="")&(`"`saving'"'=="")&("`restore'"!="norestore")&("`fast'"=="") {;
    disp as error "You must specify at least one of the five options:"
      _n "list(), frame(), saving(), norestore, and fast."
      _n "If you specify list(), then the output variables specified are listed."
      _n "f you specify frame(), then the new data set is output to a data frame."
      _n "If you specify saving(), then the new data set is output to a disk file."
      _n "If you specify norestore and/or fast, then the new data set is created in the current ata frame,"
      _n "and any existing data set in the current data frame is destroyed."
      _n "For more details, see {help parmest:on-line help for parmby and parmest}.";
    error 498;
};


*
 Parse frame() option if present
*;
if `"`frame'"'!="" {;
  cap frameoption `frame';
  if _rc {;
    disp as error `"Illegal frame option: `frame'"';
    error 498;
  };
  local framename "`r(namelist)'";
  local framereplace "`r(replace)'";
  local framechange "`r(change)'";
  if `"`framename'"'=="`c(frame)'" {;
    disp as error "frame() option may not specify current frame."
      _n "Use norestore or fast instead.";
    error 498;
  };
  if "`framereplace'"=="" {;
    cap noi conf new frame `framename';
    if _rc {;
      error 498;
    };
  };
};
if "`framename'"!="" {;
  local passframe "frame(`framename', `framereplace' `framechange')";
};


*
 Name temporary frame
 and pass it to _parmby with the other options
 and add returned results to returned results for parmby
*;
tempname tempframe;
_parmby `"`cmd'"', `list' tempframe(`tempframe') `saving' `options';
return add;


*
 Copy new frame to old frame if requested
*;
local oldframe=c(frame);
if "`restore'"=="norestore" {;
  frame copy `tempframe' `oldframe', replace;
};


*
 Rename temporary frame to frame name (if frame is specified)
 and change current frame to frame name (if requested)
*;
if "`framename'"!="" {;
  if "`framereplace'"=="replace" {;
    cap frame drop `framename';
  };
  frame rename `tempframe' `framename';
  if "`framechange'"!="" {;
    frame change `framename';
  };
};


end;


prog def _parmby, rclass sortpreserve;
*
 Do the work for parmby,
 returning a temporary frame
 that can be copied to the old frame
 and/or renamed as the output frame.
*;


gettoken cmd 0: 0;
if `"`cmd'"' == `""' {;error 198;};

syntax [ , LIst(string asis) TEMPFRAME(name) SAving(string asis) FList(string)
   BY(varlist) COMmand * ];
/*
list() contains a varlist of variables to be listed,
  expected to be present in the output data set
  and referred to by the new names if REName is specified,
  together with optional if and/or in subsetting clauses and/or list_options
  as allowed by the list command.
tempframe() specifies a temporary frame (passed by parmby)
  in which to create the output dataset.
saving() specifies a file in which to save the output data set.
flist() is a global macro name,
  belonging to a macro containing a filename list (possibly empty),
  to which parmest will append the name of the data set
  specified in the SAving() option.
  This enables the user to build a list of filenames
  in a global macro,
  containing the output of a sequence of model fits,
  which may later be concatenated using dsconcat (if installed) or append.
by is a list of by-variables.
command specifies that the estimation command is saved in the output data set
  as a string variable named command.
Other options are passed to parmest.
*/


* Echo the command and by-variables *;
disp as text "Command: " as result `"`cmd'"';
if "`by'"!="" {;
  disp as text "By variables: " as result "`by'";
};


*
 Create temporary names for temporary frames
*;;
tempname byframe curdframe currframe;


*
 Execute the command once or once per by-group,
 depending on whether -by()- is specified,
 saving the output data set in memory.
*;
if "`by'"=="" {;
  *
   Beginning of non-by-group section.
   (Execute the command and -parmest- only once for the whole data set.)
  *;
  cap noi {;
    `cmd';
  };
  if _rc!=0 {;
    disp as error "Command was not completed successfully";
    error 498;
  };
  else {;
    parmest, frame(`tempframe', replace) `options';
    * Add parmest results to return results *;
    return clear;
    return add;
  };
  * Create sequenced results in temporary frame *;
  frame `tempframe' {;
    * Error if no parameters, otherwise sort and sequence parameters *;
    if _N==0 {;
      disp as error "No parameters estimated";
      error 498;
    };
    qui {;
      gene long parmseq=_n;
      compress parmseq;
      order parmseq;
      sort parmseq;
      lab var parmseq "Parameter sequence number";
    }; 
  };
  *
   End of non-by-group section.
  *;
};
else {;
  *
   Beginning of by-group section.
   (Create grouping variable group defining by-group
   and data fframe byframe with 1 obs per by-group,
   and execute the command and parmest on each by-group in turn,
   concatenating the results to tempframe.)
  *;
  sort `by', stable;
  *
   Create frame byframe with 1 obs per by group
   and data on by variables
  *;
  frame put `by', into(`byframe');
  tempvar group seqnum inmin inmax;
  qui frame `byframe' {;
    sort `by';
    by `by': gene long `group'=_n==1;
    replace `group'=sum(`group');
    gene long `seqnum'=_n;
    sort `group' `seqnum';
    by `group': gene long `inmin'=`seqnum'[1];
    by `group': gene long `inmax'=`seqnum'[_N];
    drop `seqnum';
    by `group': keep if _n==1;
    compress `group' `inmin' `inmax';
    keep `by' `group' `inmin' `inmax';
    local ngroup=`group'[_N];
  };
  * Add by-group variable to old current frame *;
  qui {;
    tempvar bylink;
    frlink m:1 `by', frame(`byframe') gene(`bylink');
    frget `group'=`group', from(`bylink');
    drop `bylink';
  };
  *
   Create concatenated results frame in tempframe
  *;
  frame create `tempframe';
  forv i1=1(1)`ngroup' {;
    * Create current data frame *;
    frame `byframe' {;
      local imin=`inmin'[`i1'];
      local imax=`inmax'[`i1'];
    };
    frame put in `imin'/`imax', into(`curdframe');
    *
     Create current results frame using data in current data frame
     and append to tempframe if successful
    *;
    frame `curdframe' {;
      sort `by', stable;
      cap noi {;
       by `by': list if 0;
       `cmd';
      };
      if _rc==0 {;
        *
         Create current sequenced results frame and append to tempframe
        *;
        parmest, frame(`currframe', replace) `options';
        *
         Add parmest results to returned results
         (so returned results include last parmest results)
        *;
        return clear;
        return add;
        * Create sequenced results in current results frame *;
        qui frame `currframe' {;
          gene long `group'=`i1';
          gene long parmseq=_n;
          compress `group' parmseq;
          order `group'  parmseq;
          sort `group' parmseq;
          lab var parmseq "Parameter sequence number";
        };
        frame `tempframe': _appendframe `currframe', drop fast;
      };
    };
    * Drop current data frame *;
    frame drop `curdframe';
  };
  * Fail if no parameters estimated for any by-group *;
  frame `tempframe' {;
    if _N==0 {;
      disp as error "No parameters estimated for any by-group";
      error 498;
    };
  };
  *
   End of by-group section
  *;
};


*
 Beginning of tempframe block (NOT INDENTED)
*;
frame `tempframe' {;


*
 Add variable command if requested
*;
if "`command'"!="" {;
  qui gene str1 command="";
  qui replace command=`"`cmd'"';
  lab var command "Estimation command";
  order parmseq command;
};


*
 Rename variables if requested
 (including parmseq and command, which cannot be renamed by parmest)
 and create macros parmseqv and commandv,
 containing -parmseq- and -command- variable names
*;
local parmseqv "parmseq";
if "`command'"=="" {;local commandv "";};
else {;local commandv "command";};
if "`rename'"!="" {;
    local nrename:word count `rename';
    if mod(`nrename',2) {;
        disp as text 
          "Warning: odd number of variable names in rename list - last one ignored";
        local nrename=`nrename'-1;
    };
    local nrenp=`nrename'/2;
    local i1=0;
    while `i1'<`nrenp' {;
        local i1=`i1'+1;
        local i3=`i1'+`i1';
        local i2=`i3'-1;
        local oldname:word `i2' of `rename';
        local newname:word `i3' of `rename';
        cap{;
            confirm var `oldname';
            confirm new var `newname';
        };
        if _rc!=0 {;
            disp as text
             "Warning: it is not possible to rename `oldname' to `newname'";
        };
        else {;
            rename `oldname' `newname';
            if "`oldname'"=="parmseq" {;local parmseqv "`newname'";};
            if "`oldname'"=="command" {;local commandv "`newname'";};
        };
    };
};


*
 Format variables if requested
*;
if `"`format'"'!="" {;
    local vlcur "";
    foreach X in `format' {;
        if strpos(`"`X'"',"%")!=1 {;
            * varlist item *;
            local vlcur `"`vlcur' `X'"';
        };
        else {;
            * Format item *;
            unab Y : `vlcur';
            conf var `Y';
            cap format `Y' `X';
            local vlcur "";
        };
    };
};


* Add by-variables from frame byframe if present *;
if "`by'"!="" {;
  qui {;
    tempvar `bylink';
    frlink m:1 `group', frame(`byframe') gene(`bylink');
    foreach B in `by' {;
      cap frget `B'=`B', from(`bylink');
    };
    drop `bylink' `group';
    order `by';
    sort `by' `parmseqv';
    frame drop `byframe';
  };
};


*
 List variables if requested
*;
if `"`list'"'!="" {;
    if "`by'"=="" {;
        disp _n as text "Listing of results:";
        list `list';
    };
    else {;
        disp _n as text "Listing of results by: " as result "`by'";
        by `by':list `list';
    };
};


*
 Save data set if requested
*;
if(`"`saving'"'!=""){;
  capture noisily save `saving';
    if(_rc!=0){;
      disp as error `"saving(`saving') invalid"';
      exit 498;
  };
  tokenize `"`saving'"', parse(" ,");
  local fname `"`1'"';
  if(strpos(`"`fname'"'," ")>0){;
      local fname `""`fname'""';
  };
  * Add filename to file list in FList if requested *;
  if(`"`flist'"'!=""){;
    if(`"$`flist'"'==""){;
        global `flist' `"`fname'"';
    };
    else{;
        global `flist' `"$`flist' `fname'"';
    };
  };
};


};
*
 End of tempframe block (NOT INDENTED)
*;


* Return results *;
return local by "`by'";
return local command `"`cmd'"';


end;


prog def frameoption, rclass;
version 16.0;
*
 Parse frame() option
*;

syntax name [, replace CHange ];

return local change "`change'";
return local replace "`replace'";
return local namelist "`namelist'";

end;


#delim cr

program define _appendframe
/*
 Append one or more frames to the current frame.
 This program uses code modified
 from Jeremy Freese's SSC package frameappend.
*/

	version 16.0

	syntax namelist(name=frame_list) [, drop fast]
	/*
	  drop specifies that the from frame will be dropped.
	  fast speciffies that no work will be done to preserve the to frame
	    if the user presses Brak or other failure occurs
	*/

	* Check that all frame names belong to frames *
	foreach frame_name in `frame_list' {
	  confirm frame `frame_name'
	}

	* Preserve old dataset if requested *
	if "`fast'"=="" {
		preserve
	}
	
	* Beginning of frame loop *
	foreach frame_name in `frame_list' {
	* Beginning of main quietly block *
	quietly {
	
		* Get varlists from old dataset *
		ds
		local to_varlist "`r(varlist)'"
		* Get varlists from dataset to be appended *
		frame `frame_name': ds
		local from_varlist "`r(varlist)'"
		local shared_varlist : list from_varlist & to_varlist
		local new_varlist : list from_varlist - shared_varlist

		* Check modes of shared variables (numeric or string) *
		if "`shared_varlist'" != "" {
			foreach type in numeric string {
				ds `shared_varlist', has(type `type')
				local `type'_to "`r(varlist)'"
				frame `frame_name': ds `shared_varlist', has(type `type')
				local `type'_from "`r(varlist)'"
				local `type'_eq: list `type'_to === `type'_from
			}
			if (`numeric_eq' == 0) | (`string_eq' == 0) {
				di as err "shared variables in frames being combined must be both numeric or both string"
				error 109
			}
		}
		
		* get size of new dataframe *
		frame `frame_name' : local from_N = _N
		local to_N = _N
		local from_start = `to_N' + 1
		local new_N = `to_N' + `from_N'

		* Create variables for linkage in the 2 datasets *
		set obs `new_N'
		tempvar temp_n temp_link
		gen double `temp_n' = _n
		frame `frame_name' {
			gen double `temp_n' = _n + `to_N'
		}
	
		* Create linkage between the 2 datasets *
		frlink 1:1 `temp_n', frame(`frame_name') gen(`temp_link')
		
		* Import shared variables to old dataset *
		if "`shared_varlist'"!="" {
		  tempvar temphome
		  foreach X of varlist `shared_varlist' {
		    frget `temphome'=`X', from(`temp_link')
		    replace `X'=`temphome' in `=`to_N'+1' / `new_N'
		    drop `temphome'
		  }
		}
	
		* Import new variables to old dataset *
		if "`new_varlist'" != "" {
		  tempvar temphome2
		  foreach X in `new_varlist' {
		    frget `X'=`X', from(`temp_link')
		  }
	        }
	        
	        * Order variables (old ones first) *
	        order `to_varlist' `new_varlist'

	}
        * End of main quietly block *
        }
        * End of frame loop *

        * Restore old dataset if requested and necessary *
	if "`fast'"=="" {
        	restore, not
	}

	* Drop appended frame if requested *
	if "`drop'" == "drop" {
		foreach frame_name in `frame_list' {
			frame drop `frame_name'
		}
	}
		
end
