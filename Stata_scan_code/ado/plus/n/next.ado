capture program drop next
program define next, eclass
	version 15.1
	syntax varlist(min=2 max=2) [if] [in] [fw] [, threshold(real 0) minorder(integer 1) maxorder(integer 3) bins(integer 0) bins_graph(integer 0) alpha_spe(real 0.02) regtype(string) kernel(string) details]
	local Y: word 1 of `varlist'
	local X: word 2 of `varlist'
	local isreg = "`regtype'" ==""
	local regtype = cond(`isreg',"regress", "`regtype'")
	local iskernel = "`kernel'" ==""
	local kernel = cond(`iskernel',"all", "`kernel'")
	tempvar X_weight BIN BW_O_K_OBS weight_main INCLUDE weight_left weight_right weight_final yes BW_O_K_OBS_EWA TEMP_BW_O_K_OBS_EWA BW_O_K_OBS_EWA_SQERROR TEMP_WEIGHT SPE_O_K_OBS SPE_O_K_OBS_EWA yhat yhat_left yhat_right
	* STOP THE ANALYSIS IF THE REGRESSION TYPE IS MISSPECIFIED
	if "`regtype'"~="regress" & "`regtype'"~="probit" & "`regtype'"~="logit" {
		display as error "Regresion type must be regress, probit, or logit" 
		display as error "Change the entry before continuing"
	}
	* STOP THE ANALYSIS IF MAXORDER<MINORDER
	else if `maxorder'<`minorder' {
		display as error "The maximum order must be >= the minimum order."
		display as error "Change the value before continuing."
	}
	* STOP THE ANALYSIS IF MINORDER IS NEGATIVE
	else if `minorder'<0 {
		display as error "The minimum order that will be considered must be an integer >=0."
		display as error "Change the value before continuing."
	}
	* STOP THE ANALYSIS IF MAXORDER IS NEGATIVE
	else if `maxorder'<0 {
		display as error "The maximum order that will be considered must be an integer >=0."
		display as error "Change the value before continuing."
	}
	* STOP THE ANALYSIS IF ALPHA_SPE IS <=0 or >1
	else if `alpha_spe'<=0 | `alpha_spe'>1 {
		display as error "The value of alpha_spe must be >0 & <=1"
		display as error "Change the value before continuing."
	}
	* STOP THE ANALYSIS IF KERNEL TYPE IS MISSPECIFIED
	else if "`kernel'"~="all" & "`kernel'"~="uniform" & "`kernel'"~="triangular" & "`kernel'"~="epanechnikov" {
		display as error "kernel must be all, uniform, triangular, or epanechnikov" 
		display as error "Change the entry before continuing"
	}
	else {
		preserve
		* Restrict the sample as desired by the user
		if "`if'"~="" {
			qui keep `if'
		}
		if "`in'"~="" {
			qui keep `in'
		}
		* Restrict the data to those with non-missing values of Y and X
		qui drop if `Y'==. | `X'==.
		sort `X'
		* Collapse data such that each unique value of X is included as one observation (with weight proportional to number of cases)
		* Preserve labels for X and Y
		foreach v of var `X' `Y' {
			local l`v' : variable label `v'
			if `"`l`v''"' == "" {
				local l`v' "`v'"
			}
		}
		if "`exp'"=="" {
			gen `X_weight'=1
		}
		else {
			gen `X_weight'`exp'
		}
		qui replace `Y'=`Y'*`X_weight'
		collapse (sum) `Y' `X_weight', by(`X')
		qui replace `Y'=`Y'/`X_weight'
		* If bins are selected as an option, collapse the data such that x and y values are collapsed within the bin.
		if `bins'>0 {
			* Note: bins constructed such that they don't straddle the threshold.
			qui sum `X'
			local number_bins_left=int(`bins'*(`threshold'-r(min))/(r(max)-r(min)))
			local number_bins_right=`bins'-`number_bins_left'
			gen `BIN'=(`X'<`threshold')*int(`number_bins_left'*(`X'-r(min))/(`threshold'-r(min)))+(`X'>=`threshold')*(`number_bins_left'+int(`number_bins_right'*(`X'-`threshold')/(r(max)-`threshold')))
			qui replace `Y'=`Y'*`X_weight'
			qui replace `X'=`X'*`X_weight'
			collapse (sum) `Y' `X' `X_weight', by(`BIN')
			qui replace `Y'=`Y'/`X_weight'
			qui replace `X'=`X'/`X_weight'
			drop `BIN'
		}
		* EVALUATE IF THE NUMBER OF OBSERVATIONS (BINNED OR UNBINNED) IS TOO SMALL
		local GOODTOGO=1
		qui count if `X'<`threshold'
		if r(N)<5+`maxorder' {
			local GOODTOGO=0
		}
		if `GOODTOGO'==0 {
			display as error "There is an insufficient number of observations on the left side"
			display as error "of the threshold given (a) the desired maximum order of specification"
			display as error "to be considered or (b) the extent of binning of the data selected."
			display as error "Change the values of maxorder and/or bins before continuing."
			display as error "Note that the minimum number of observations on each side = 5+maxorder"
		}
		else {
			qui count if `X'>=`threshold'
			if r(N)<5+`maxorder' {
				local GOODTOGO=0
			}
			if `GOODTOGO'==0 {
				display as error "There is an insufficient number of observations on the right side"
				display as error "of the threshold given (a) the desired maximum order of specification"
				display as error "to be considered or (b) the extent of binning of the data selected."
				display as error "Change the values of maxorder and/or bins before continuing."
				display as error "Note that the minimum number of observations on each side = 5+maxorder"
			}
			else {
				local message1 "Thank you for your patience."
				local message2 "We will be with you shortly."
				local message3 "Our agents are assisting other data."
				local message4 "Your research is very valuable to us."
				local message5 "If you would like to leave us a message..."
				local message6 "The current wait time is ... unknown."
				local message7 "Have you considered binning the data?"
				local message8 "This RD will get you the Nobel Prize."
				local message9 "Take a walk, get some fresh air."
				local message10 "Have a nice day!"
				local message_counter=1
				* restore labels for X and Y
				foreach v of var `X' `Y' {
					label var `v' "`l`v''"
				}
				if "`kernel'"=="all" {
					local kphrase "UNIFORM TRIANGULAR EPANECHNIKOV"
				}
				else if "`kernel'"=="uniform" {
					local kphrase "UNIFORM"
				}
				else if "`kernel'"=="triangular" {
					local kphrase "TRIANGULAR"
				}
				else if "`kernel'"=="epanechnikov" {
					local kphrase "EPANECHNIKOV"
				}
				forvalues LEFT=1(-1)0 {
					display "______________________________________________________________________________"	
					if `LEFT'==1 {
						display "WORKING ON THE LEFT SIDE OF THE THRESHOLD"
						local SIDE="left"
						qui count if `X'<`threshold'
						local N=r(N)
					}
					else {
						display "WORKING ON THE RIGHT SIDE OF THE THRESHOLD"
						local SIDE="right"
						qui count if `X'>=`threshold'
						local N=r(N)
					}
					display "______________________________________________________________________________"	
					local GLOBAL_BEST_SPE=.
					local GLOBAL_BEST_ORDER=.
					local GLOBAL_BEST_BANDWIDTH=.
					local GLOBAL_BEST_KERNEL=""
					if `LEFT'==1 {
						local MINOBS=`maxorder'+4
						local RANGE="`MINOBS'/`N'"
						local MINOBS2=`maxorder'+5
						local RANGE2="`MINOBS2'/`N'"
					}
					else {
						qui count
						local FULLN=r(N)
						local MINOBS=`FULLN'-(`maxorder'+3)
						local MINOBS2=`FULLN'-(`maxorder'+4)
						local MAXOBS=0
						forvalues i=1/`FULLN' {
							if `MAXOBS'==0 & `X'[`i']>=`threshold' {
								local MAXOBS=`i'
							}
						}
						local RANGE="`MINOBS'(-1)`MAXOBS'"
						local RANGE2="`MINOBS2'(-1)`MAXOBS'"
					}
					forvalues ORDER=`minorder'/`maxorder' {
						forvalues i=0/`maxorder' {
							tempvar X`i'
							gen `X`i''=`X'^`i'
							order `X`i'', last
						}
						local RHS 
						forvalues Q=0/`ORDER' {
							local RHS `RHS' `X`Q''
						}
						foreach K in `kphrase' {
							display "THE CURRENT TIME IS $S_TIME ON $S_DATE"
							if `LEFT'==1 {
								display "LEFT: Order=`ORDER' | Kernel=`K':"
							}
							else {
								display "RIGHT: Order=`ORDER' | Kernel=`K':"
							}
							if "`K'" == "UNIFORM" {
								local STEM="UNIF"
							}
							else if "`K'" == "TRIANGULAR" {
								local STEM="TRI."
							}
							else {
								local STEM="EPAN"
							}
							* Identify the best bandwidth for predicting each observartion using this order and kernel
							qui gen `BW_O_K_OBS'=.
							qui forvalues OBS = `RANGE' {
								if `OBS'==`MINOBS' {
									local counter=1
									if `LEFT'==1 {
										local temp=`N'+1-`MINOBS'
									}
									else {
										local temp=`MINOBS'+1-`MAXOBS'
									}
									noi display "{hline 4}{c +}{hline 3} 1 {hline 3}{c +}{hline 3} 2 {hline 3}{c +}{hline 3} 3 {hline 3}{c +}{hline 3} 4 {hline 3}{c +}{hline 3} 5"
									noi display "Finding Best Bandwidths: `temp' observations to process"
								}
								noi display "." _continue
								if `counter'-int(`counter'/50)*50 == 0 {
									if `counter'-int(`counter'/250)*250 == 0 {
											noi display "`counter' `message`message_counter''", _newline(0)
											local message_counter=`message_counter'+1
											if `message_counter'==11 {
												local message_counter=1
											}
									}
									else {
										noi display `counter', _newline(0)
									}
								}
								local counter=`counter'+1
								local lowest_SPE=.
								if `LEFT'==1 {
									local Xmax1=`OBS'-1
									local Xmax2=`OBS'-1-`ORDER'
									local RANGE3="1/`Xmax2'"
								}
								else {
									local Xmax1=`OBS'+1
									local Xmax2=`OBS'+1+`ORDER'
									local RANGE3="`FULLN'(-1)`Xmax2'"
								}
								forvalues Z=`RANGE3' {
									if `LEFT'==1 {
										gen `INCLUDE'=(_n>=`Z' & _n<=`Xmax1')
									}
									else {
										gen `INCLUDE'=(_n>=`Xmax1' & _n<=`Z')
									}
									if "`K'"=="UNIFORM" {
										gen `weight_main'= `X_weight'*`INCLUDE'
									}
									else if "`K'"=="TRIANGULAR" {
										count if `INCLUDE'==1
										if r(N)>=2 {
											local extender=	(r(N)+1)/r(N)
											gen `weight_main'= `X_weight'*`INCLUDE'*(1 - (`X'[`Xmax1']-`X')/(`extender'*(`X'[`Xmax1']-`X'[`Z'])))
										}
										else {
											gen `weight_main'= `X_weight'*`INCLUDE'
										}
									}
									else {
										count if `INCLUDE'==1
										if r(N)>=2 {
											local extender=	(r(N)+1)/r(N)
											gen `weight_main'= `X_weight'*`INCLUDE'*(0.75*(1-((`X'[`Xmax1']-`X')/(`extender'*(`X'[`Xmax1']-`X'[`Z'])))^2))
										}
										else {
											gen `weight_main'= `X_weight'*`INCLUDE'
										}
									}
									drop `INCLUDE'
									qui sum `weight_main'
									qui replace `weight_main'=`weight_main'/(r(N)*r(mean))
									if `ORDER'==0 {
										sum `Y' [aweight=`weight_main']
										local SPE_temp=(`Y'[`OBS']-r(mean))^2
										drop `weight_main'
									}
									else if  "`regtype'"=="regress" {
										regress `Y' `RHS' [pweight=`weight_main'], noconstant 
										predict `yhat'
										local SPE_temp=(`Y'[`OBS']-`yhat'[`OBS'])^2
										drop `yhat' `weight_main'
									}
									else {
										sum `Y' [aweight=`weight_main']
										if  r(sd)==0 {
											gen `yhat'=r(mean)
										}
										else {
											count if `Y'>0 & `Y'<1 & `weight_main'~=0 
											if r(N) > 0 {
												glm `Y' `RHS' [pweight=`weight_main'], link(`regtype') family(binomial) noconstant nodisplay iterate(100) asis
											}
											else {
												`regtype' `Y' `RHS' [pweight=`weight_main'], noconstant asis
											}
											predict `yhat'
										}
										local SPE_temp=(`Y'[`OBS']-`yhat'[`OBS'])^2
										drop `yhat' `weight_main'
									}
									if `SPE_temp'<`lowest_SPE' {
										if `LEFT'==1 {
											replace `BW_O_K_OBS'=(1+`Xmax1'-`Z')/(1+`Xmax1'-1) if _n==`OBS'
										}
										else {
											replace `BW_O_K_OBS'=(1+`Z'-`Xmax1')/(1+`FULLN'-`Xmax1') if _n==`OBS'
										}
										local lowest_SPE=`SPE_temp'
									}
								}
							}
							display, _newline(0)
							* Remove the noise in the bandwidth by using an exponential weighted average. 
							* Select weight that minimizes squared prediction error of next bandwidth. 
							* This weight accounts for spacing between X values and weights of X values.
							qui gen `BW_O_K_OBS_EWA'=.
							local min_squared_error=.
							qui foreach ALPHA_BW in 1.00 0.96 0.92 0.88 0.84 0.80 0.76 0.72 0.68 0.64 0.60 0.56 0.52 0.48 0.44 0.40 0.36 0.32 0.28 0.24 0.20 0.16 0.12 0.10 0.08 0.06 0.04 0.03 0.02 0.01 0.005 0.0025 0.001 0.0004 1.00E-04 1.00E-05 1.00E-06 1.00E-07 1.00E-09 1.00E-11 1.00E-14 1.00E-17 1.00E-20 1.00E-23 {
								gen `TEMP_BW_O_K_OBS_EWA'=.
								if `LEFT'==1 {
									gen `TEMP_WEIGHT'=`X_weight'*`ALPHA_BW'^(1-(`X'-`X'[`MINOBS'])/(`X'[`N']-`X'[`MINOBS'])) if _n>=`MINOBS' & _n<=`N'										
								}
								else {
									gen `TEMP_WEIGHT'=`X_weight'*`ALPHA_BW'^(1-(`X'[`MINOBS']-`X')/(`X'[`MINOBS']-`X'[`MAXOBS'])) if _n>=`MAXOBS' & _n<=`MINOBS'										
								}
								forvalues OBS=`RANGE' {
									if `LEFT'==1 {
										sum `BW_O_K_OBS' [aw=`TEMP_WEIGHT'] if _n<=`OBS'
									}
									else {
										sum `BW_O_K_OBS' [aw=`TEMP_WEIGHT'] if _n>=`OBS'
									}
									replace `TEMP_BW_O_K_OBS_EWA'=r(mean) if _n==`OBS'
								}
								if `LEFT'==1 {
									gen `BW_O_K_OBS_EWA_SQERROR'=(`BW_O_K_OBS'[_n+1]-`TEMP_BW_O_K_OBS_EWA')^2 if `TEMP_BW_O_K_OBS_EWA'~=. & _n<`N'
								}
								else {
									gen `BW_O_K_OBS_EWA_SQERROR'=(`BW_O_K_OBS'[_n-1]-`TEMP_BW_O_K_OBS_EWA')^2 if `TEMP_BW_O_K_OBS_EWA'~=. & _n>`MAXOBS'
								}
								sum `BW_O_K_OBS_EWA_SQERROR' [aw=`TEMP_WEIGHT']
								if r(mean)<`min_squared_error' {
									local min_squared_error=r(mean)
									replace `BW_O_K_OBS_EWA'=`TEMP_BW_O_K_OBS_EWA'
									local BEST_ALPHA_BW=`ALPHA_BW'
									if `LEFT'==1 {
										local BANDWIDTH=`BW_O_K_OBS_EWA'[`N']
									}
									else {
										local BANDWIDTH=`BW_O_K_OBS_EWA'[`MAXOBS']
									}
								}
								drop `TEMP_BW_O_K_OBS_EWA' `BW_O_K_OBS_EWA_SQERROR' `TEMP_WEIGHT'
							}	
							* Now, compute a series of SPEs (Squared Prediction Errors) using this series of Bandwidths
							qui gen `SPE_O_K_OBS'=.
							qui forvalues OBS = `RANGE2' {
								if `OBS'==`MINOBS2' {
									local counter=1
									if `LEFT'==1 {
										local temp=`N'+1-`MINOBS2'
									}
									else {
										local temp=`MINOBS2'+1-`MAXOBS'
									}
									noi display "Computing Squared Prediction Errors: `temp' observations to process"
								}
								noi display "." _continue
								if `counter'-int(`counter'/50)*50 == 0 {
									if `counter'-int(`counter'/250)*250 == 0 {
											noi display "`counter' `message`message_counter''", _newline(0)
											local message_counter=`message_counter'+1
											if `message_counter'==11 {
												local message_counter=1
											}
									}
									else {
										noi display `counter', _newline(0)
									}
								}
								local counter=`counter'+1
								if `LEFT'==1 {
									local Xmax=`OBS'-1
								}
								else {
									local Xmax=`OBS'+1
								}
								if `LEFT'==1 {
									gen `INCLUDE'=(_n>=`OBS'-max(3+`ORDER',round((`OBS'-1)*`BW_O_K_OBS_EWA'[`OBS'-1])) & _n<=`OBS'-1)
									if "`K'"~="UNIFORM" {
										local FIRST=0
										forvalues Z=1/`Xmax' {
											if `INCLUDE'[`Z']==1 & `FIRST'==0 {
												local FIRST=`Z'
											}
										}
									}
								}
								else {
									gen `INCLUDE'=(_n>=`OBS'+1 & _n<=`OBS'+max(3+`ORDER',round((`FULLN'-`OBS')*`BW_O_K_OBS_EWA'[`OBS'+1])))
									if "`K'"~="UNIFORM" {
										local FIRST=0
										forvalues Z=`FULLN'(-1)`Xmax' {
											if `INCLUDE'[`Z']==1 & `FIRST'==0 {
												local FIRST=`Z'
											}
										}
									}
								}
								if "`K'"=="UNIFORM" {
									gen `weight_main'= `X_weight'*`INCLUDE'
								}
								else if "`K'"=="TRIANGULAR" {
									count if `INCLUDE'==1
									if r(N)>=2 {
										local extender=	(r(N)+1)/r(N)
										gen `weight_main'= `X_weight'*`INCLUDE'*(1 - (`X'[`Xmax']-`X')/(`extender'*(`X'[`Xmax']-`X'[`FIRST'])))
									}
									else {
										gen `weight_main'= `X_weight'*`INCLUDE'
									}	
								}
								else {
									count if `INCLUDE'==1
									if r(N)>=2 {
										local extender=	(r(N)+1)/r(N)
										gen `weight_main'= `X_weight'*`INCLUDE'*(0.75*(1-((`X'[`Xmax']-`X')/(`extender'*(`X'[`Xmax']-`X'[`FIRST'])))^2))
									}
									else {
										gen `weight_main'= `X_weight'*`INCLUDE'
									}
								}
								drop `INCLUDE'
								qui sum `weight_main'
								qui replace `weight_main'=`weight_main'/(r(N)*r(mean))
								if `ORDER'==0 {
									sum `Y' [aweight=`weight_main']
									replace `SPE_O_K_OBS'=(`Y'[`OBS']-r(mean))^2 if _n==`OBS'
									drop `weight_main'
								}
								else if  "`regtype'"=="regress" {
									regress `Y' `RHS' [pweight=`weight_main'], noconstant 
									predict `yhat'
									replace `SPE_O_K_OBS'=(`Y'[`OBS']-`yhat'[`OBS'])^2 if _n==`OBS'
									drop `yhat' `weight_main'
								}
								else {
									sum `Y' [aweight=`weight_main']
									if  r(sd)==0 {
										gen `yhat'=r(mean)
									}
									else {
										count if `Y'>0 & `Y'<1 & `weight_main'~=0 
										if r(N) > 0 {
											glm `Y' `RHS' [pweight=`weight_main'], link(`regtype') family(binomial) noconstant nodisplay iterate(100) asis
										}
										else {
											`regtype' `Y' `RHS' [pweight=`weight_main'], noconstant asis
										}
										predict `yhat'
									}
									replace `SPE_O_K_OBS'=(`Y'[`OBS']-`yhat'[`OBS'])^2 if _n==`OBS'
									drop `yhat' `weight_main'
								}
							}
							display, _newline(0)
							* Reduce noise in the SPE by using an exponential weighted average. 
							* This weight accounts for spacing between X values and weights of X values.
							qui gen `SPE_O_K_OBS_EWA'=.
							local min_squared_error=.
							if `LEFT'==1 {
								qui gen `TEMP_WEIGHT'=`X_weight'*`alpha_spe'^(1-(`X'-`X'[`MINOBS2'])/(`X'[`N']-`X'[`MINOBS2'])) if _n>=`MINOBS2' & _n<=`N'										
							}
							else {
								qui gen `TEMP_WEIGHT'=`X_weight'*`alpha_spe'^(1-(`X'[`MINOBS2']-`X')/(`X'[`MINOBS2']-`X'[`MAXOBS'])) if _n>=`MAXOBS' & _n<=`MINOBS2'									
							}
							qui forvalues OBS=`RANGE2' {
								if `LEFT'==1 {
									sum `SPE_O_K_OBS' [aw=`TEMP_WEIGHT'] if _n<=`OBS'
								}
								else {
									sum `SPE_O_K_OBS' [aw=`TEMP_WEIGHT'] if _n>=`OBS'
								}
								replace `SPE_O_K_OBS_EWA'=r(mean) if _n==`OBS'
							}
							qui sum `SPE_O_K_OBS' [aw=`TEMP_WEIGHT']	
							local PREDICTED_SPE=r(mean)
							drop `TEMP_WEIGHT' 
							if "`details'"~="" {
								display "OBS | Best BW | Best BW EWA | SPE | SPE EWA"
								forvalues OBS = `RANGE' {
									local temp1=`BW_O_K_OBS'[`OBS']
									local temp2=`BW_O_K_OBS_EWA'[`OBS']
									local temp3=`SPE_O_K_OBS'[`OBS']
									local temp4=`SPE_O_K_OBS_EWA'[`OBS']
									display "`OBS' | " %9.4f `temp1' " | " %9.4f `temp2' " | " %9.4f `temp3' " | " %9.4f `temp4'
								}
								display "Optimal bandwidth to predict next observation = `BANDWIDTH'" 
								display "Value of alpha used to smooth the bandwidth = `BEST_ALPHA_BW'" 
								display "Predicted squared prediction error for next observation = `PREDICTED_SPE'" 
							}
							drop `BW_O_K_OBS' `BW_O_K_OBS_EWA' `SPE_O_K_OBS' `SPE_O_K_OBS_EWA'
							if `PREDICTED_SPE'<`GLOBAL_BEST_SPE' {
								local GLOBAL_BEST_SPE=`PREDICTED_SPE'
								local GLOBAL_BEST_ORDER=`ORDER'
								local GLOBAL_BEST_KERNEL="`K'"
								local GLOBAL_BEST_BANDWIDTH=`BANDWIDTH'
							}
							local NEXT_`ORDER'_`K'="Order=`ORDER' | `STEM' | Bandwidth=`BANDWIDTH' | SPE-hat=`PREDICTED_SPE'"
							display ""
							display "______________________________________________________________________________"	
						}					
					}
					forvalues i=0/`maxorder' {
						drop `X`i''
					}
					display "THE CURRENT TIME IS $S_TIME ON $S_DATE"
					display ""
					display "POLYN. ORDER, KERNEL, BANDWIDTH, AND PREDICTED SQ. PREDICTION ERROR FOR NEXT OBS.:"
					forvalues ORDER=`minorder'/`maxorder' {
						foreach K in `kphrase' {
							display "`NEXT_`ORDER'_`K''"
						}
					}
					display ""
					if `LEFT'==1 {
						display "THE GLOBAL BEST SPECIFICATION FOR THE LEFT-HAND SIDE IS:"
						display "Order=`GLOBAL_BEST_ORDER' | Kernel=`GLOBAL_BEST_KERNEL' | Bandwidth=`GLOBAL_BEST_BANDWIDTH'"
						if "`GLOBAL_BEST_KERNEL'"=="UNIFORM" {
							local LEFT_BEST_KERNEL="Uniform"
						}
						else if "`GLOBAL_BEST_KERNEL'"=="TRIANGULAR" {
							local LEFT_BEST_KERNEL="Triangular"
						}							
						else {
							local LEFT_BEST_KERNEL="Epanechnikov"
						}
						local LEFT_BEST_ORDER=`GLOBAL_BEST_ORDER'
						local LEFT_BEST_BANDWIDTH=`GLOBAL_BEST_BANDWIDTH'
					}
					else {
						display "THE GLOBAL BEST SPECIFICATION FOR THE RIGHT-HAND SIDE IS:" 
						display "Order=`GLOBAL_BEST_ORDER' | Kernel=`GLOBAL_BEST_KERNEL' | Bandwidth=`GLOBAL_BEST_BANDWIDTH'"
						display "______________________________________________________________________________"
						if "`GLOBAL_BEST_KERNEL'"=="UNIFORM" {
							local RIGHT_BEST_KERNEL="Uniform"
						}
						else if "`GLOBAL_BEST_KERNEL'"=="TRIANGULAR" {
							local RIGHT_BEST_KERNEL="Triangular"
						}
						else {
							local RIGHT_BEST_KERNEL="Epanechnikov"
						}
						local RIGHT_BEST_ORDER=`GLOBAL_BEST_ORDER'
						local RIGHT_BEST_BANDWIDTH=`GLOBAL_BEST_BANDWIDTH'
						* Restore the original data
						restore	
						* Preserve the original data
						preserve
						* Restrict the sample as desired by the user
						if "`if'"~="" {
							qui keep `if'
						}
						if "`in'"~="" {
							qui keep `in'
						}
						* Restrict the data to those with non-missing values of Y and X
						qui drop if `Y'==. | `X'==.
						sort `X'
						* Create the weights
						if "`exp'"=="" {
							gen `X_weight'=1
						}
						else {
							gen `X_weight'`exp'
						}
						if "`LEFT_BEST_KERNEL'"=="Uniform" {
							gen `weight_left'=`X_weight'*(`X'>=`threshold' - `LEFT_BEST_BANDWIDTH'*(`threshold'-`X'[1]) & `X'<`threshold')
						}
						else if "`LEFT_BEST_KERNEL'"=="Triangular" {
							qui count if (`X'>=`threshold' - `LEFT_BEST_BANDWIDTH'*(`threshold'-`X'[1]) & `X'<`threshold')
							local extender=(r(N)+1)/r(N)
							gen `weight_left'=`X_weight'*(`X'>=`threshold' - `LEFT_BEST_BANDWIDTH'*(`threshold'-`X'[1]) & `X'<`threshold')*((`threshold'-`X'[1])*`LEFT_BEST_BANDWIDTH'*`extender'-(`threshold'-`X')) 
						}
						else {
							qui count if (`X'>=`threshold' - `LEFT_BEST_BANDWIDTH'*(`threshold'-`X'[1]) & `X'<`threshold')
							local extender=(r(N)+1)/r(N)
							gen `weight_left'=`X_weight'*(`X'>=`threshold' - `LEFT_BEST_BANDWIDTH'*(`threshold'-`X'[1]) & `X'<`threshold')*0.75*(1-((`threshold'-`X')/((`threshold'-`X'[1])*`LEFT_BEST_BANDWIDTH'*`extender'))^2)
						}
						qui count if `weight_left'>0
						if r(N)<`LEFT_BEST_ORDER'+2 {
							display as red "*** CAUTION ***"
							display as text "The best bandwidth for the left side is so narrow that the number of"
							display as text "observations with X in this bandwidth is less than 2 + the best polynomial"
							display as text "order. Consequently, the bandwidth is being widened so that there will be"
							display as text "enough observations to estimate this polynomial. Widening it *just* enough"
							display as text "would yield a prediction at the threshold with no variance. So, this command"
							display as text "produces a weight that includes observations = 2 + the best polynomial order."
							display as text "The user should be cautioned that this is very few observations to use."
							qui count if `X'<`threshold'
							local N=r(N)
							gen `yes'=(`X'>=`X'[`N'-1-`LEFT_BEST_ORDER'] & `X'<`threshold')
							if "`LEFT_BEST_KERNEL'"=="Uniform" {
								qui replace `weight_left'=`X_weight'*`yes'
							}
							else if "`LEFT_BEST_KERNEL'"=="Triangular" {
								qui count if `yes'==1
								local extender=(r(N)+1)/r(N)
								qui replace `weight_left'=`X_weight'*`yes'*((`threshold'-`X'[`N'-1-`LEFT_BEST_ORDER'])*`extender'-(`threshold'-`X')) 
							}							
							else {
								qui count if `yes'==1
								local extender=(r(N)+1)/r(N)
								qui replace `weight_left'=`X_weight'*`yes'*0.75*(1-((`threshold'-`X')/((`threshold'-`X'[`N'-1-`LEFT_BEST_ORDER'])*`extender'))^2)
							}
							drop `yes'
						}
						* Scale the weight so that it equals 1.
						qui sum `weight_left'
						qui replace `weight_left'=`weight_left'/(r(N)*r(mean))
						qui count
						local FULLN=r(N)
						if "`RIGHT_BEST_KERNEL'"=="Uniform" {
							gen `weight_right'=`X_weight'*(`X'>=`threshold' & `X'<=`threshold'+`RIGHT_BEST_BANDWIDTH'*(`X'[`FULLN']-`threshold'))
						}
						else if "`RIGHT_BEST_KERNEL'"=="Triangular" {
							qui count if (`X'>=`threshold' & `X'<=`threshold'+`RIGHT_BEST_BANDWIDTH'*(`X'[`FULLN']-`threshold'))
							local extender=(r(N)+1)/r(N)
							gen `weight_right'=`X_weight'*(`X'>=`threshold' & `X'<=`threshold'+`RIGHT_BEST_BANDWIDTH'*(`X'[`FULLN']-`threshold'))*((`X'[`FULLN']-`threshold')*`RIGHT_BEST_BANDWIDTH'*`extender'-(`X'-`threshold'))
						}
						else {
							qui count if (`X'>=`threshold' & `X'<=`threshold'+`RIGHT_BEST_BANDWIDTH'*(`X'[`FULLN']-`threshold'))
							local extender=(r(N)+1)/r(N)
							gen `weight_right'=`X_weight'*(`X'>=`threshold' & `X'<=`threshold'+`RIGHT_BEST_BANDWIDTH'*(`X'[`FULLN']-`threshold'))*0.75*(1-((`X'-`threshold')/((`X'[`FULLN']-`threshold')*`RIGHT_BEST_BANDWIDTH'*`extender'))^2)
						}
						qui count if `weight_right'>0
						if r(N)<`RIGHT_BEST_ORDER'+2 {
							display as red "*** CAUTION ***"
							display as text "The best bandwidth for the right side is so narrow that the number of"
							display as text "observations with X in this bandwidth is less than 2 + the best polynomial"
							display as text "order. Consequently, the bandwidth is being widened so that there will be"
							display as text "enough observations to estimate this polynomial. Widening it *just* enough"
							display as text "would yield a prediction at the threshold with no variance. So, this command"
							display as text "produces a weight that includes observations = 2 + the best polynomial order."
							display as text "The user should be cautioned that this is very few observations to use."
							gen `yes'=(`X'>=`threshold' & `X'<=`X'[`MAXOBS'+1+`RIGHT_BEST_ORDER'])
							qui count if `X'>=`threshold'
							local N=r(N)
							if "`RIGHT_BEST_KERNEL'"=="Uniform" {
								qui replace `weight_right'=`X_weight'*`yes'
							}
							else if "`RIGHT_BEST_KERNEL'"=="Triangular" {
								qui count if `yes'==1
								local extender=(r(N)+1)/r(N)
								qui replace `weight_right'=`X_weight'*`yes'*((`X'[`MAXOBS'+1+`RIGHT_BEST_ORDER']-`threshold')*`extender'-(`X'-`threshold')) 
							}							
							else {
								qui count if `yes'==1
								local extender=(r(N)+1)/r(N)
								qui replace `weight_right'=`X_weight'*`yes'*0.75*(1-((`X'-`threshold')/((`X'[`MAXOBS'+1+`RIGHT_BEST_ORDER']-`threshold') *`extender'))^2)
							}
							drop `yes'
						}
						* Scale the weight so that it equals 1.
						qui sum `weight_right'
						qui replace `weight_right'=`weight_right'/(r(N)*r(mean))
						* Now stictch the left and right sides together
						gen `weight_final'=`weight_right'+`weight_left'
						* X reset to X-Threshold
						quietly replace `X'=`X'-`threshold'
						* Run the regression
						display "BELOW IS REGRESSION USING THE OPTIMAL SPECIFICATIONS, BANDWIDTHS, AND KERNELS" 
						if "`regtype'"=="regress" {
							display "*Left-to-Right Discontinuity* GIVES THE LOCAL AVERAGE TREATMENT EFFECT"
						}
						else {
							display "*Left-to-Right Discontinuity* GIVES THE DIFFERENCE IN LEFT AND RIGHT INTERCEPTS (COEFFICIENTS)"
							display "*Marginal Effect* GIVES THE LOCAL AVERAGE TREATMENT EFFECT"
						}
						display "(i.e. THE JUMP MOVING FROM LEFT TO RIGHT OF THRESHOLD)"
						display "NOTE: ASSIGNMENT VARIABLE HAS BEEN RECODED SO THAT THRESHOLD IS SET AT ZERO"
						display "(i.e., X reset to X-Threshold)"
						display "______________________________________________________________________________"	
						local RHS 
						forvalues Q=0/`LEFT_BEST_ORDER' {
							tempvar LEFT_POLY`Q'
							gen `LEFT_POLY`Q''=(`X'^`Q')*(`X'<0)
							local RHS `RHS' `LEFT_POLY`Q''
						}
						forvalues Q=0/`RIGHT_BEST_ORDER' {
							tempvar RIGHT_POLY`Q'
							gen `RIGHT_POLY`Q''=(`X'^`Q')*(`X'>=0)
							local RHS `RHS' `RIGHT_POLY`Q'' 
							}
						qui count if `Y'>0 & `Y'<1 & `weight_final'~=0
						if  "`regtype'"=="regress" | r(N)==0 {
							qui `regtype' `Y' `RHS' [pweight=`weight_final'], noconstant vce(robust)
							local glm=0
						}
						else {
							qui glm `Y' `RHS' [pweight=`weight_final'], link(`regtype') family(binomial) iterate(100) noconstant vce(robust)
							local glm=1
						}
						tempname B
						tempname V
						matrix `B'=e(b)
						matrix `V'=e(V)
						if "`regtype'"=="regress" {
							local tz="t"
						}
						else {
							local tz="z"
						}
						display "Variable                      Coef.       Robust SE       `tz'         P>|t|"				
						display "______________________________________________________________________________"	
						local counter=1
						local b=`B'[1,`counter']
						local se=(`V'[`counter',`counter'])^0.5
						local t=`b'/`se'
						if "`regtype'"=="regress" {
							local df=e(df_r)
							local p=2*ttail(`df', abs(`t'))					
						}
						else {
							local p=2*(1-normal(abs(`t')))		
						}
						display "Left-side, Intercept:        " %9.0g `b' "   " %9.0g `se' "   " %9.2f `t' "   " %9.4f `p'
						if `LEFT_BEST_ORDER'>0 {
							forvalues Q=1/`LEFT_BEST_ORDER' {
								local counter=`counter'+1
								local b=`B'[1,`counter']
								local se=(`V'[`counter',`counter'])^0.5
								local t=`b'/`se'
								if "`regtype'"=="regress" {
									local p=2*ttail(`df', abs(`t'))					
								}
								else {
									local p=2*(1-normal(abs(`t')))		
								}
								display "Left-side, X^`Q':              " %9.0g `b' "   " %9.0g `se' "   " %9.2f `t' "   " %9.4f `p'
							}
						}
						local counter=`counter'+1
						local b=`B'[1,`counter']
						local se=(`V'[`counter',`counter'])^0.5
						local t=`b'/`se'
						if "`regtype'"=="regress" {
							local p=2*ttail(`df', abs(`t'))					
						}
						else {
							local p=2*(1-normal(abs(`t')))		
						}
						display "Right-side, Intercept:       " %9.0g `b' "   " %9.0g `se' "   " %9.2f `t' "   " %9.4f `p'
						if `RIGHT_BEST_ORDER'>0 {
							forvalues Q=1/`RIGHT_BEST_ORDER' {
								local counter=`counter'+1
								local b=`B'[1,`counter']
								local se=(`V'[`counter',`counter'])^0.5
								local t=`b'/`se'
								if "`regtype'"=="regress" {
									local p=2*ttail(`df', abs(`t'))					
								}
								else {
									local p=2*(1-normal(abs(`t')))		
								}
								display "Right-side, X^`Q':             " %9.0g `b' "   " %9.0g `se' "   " %9.2f `t' "   " %9.4f `p'
							}
						}
						display "______________________________________________________________________________"
						local b=_b[`RIGHT_POLY0']-_b[`LEFT_POLY0']
						qui test `LEFT_POLY0'=`RIGHT_POLY0'
						if "`regtype'"=="regress" {
							local t=r(F)^0.5
							local se=(abs(`b')/`t')
							local p=r(p)
							noisily display "Left-to-Right Discontinuity: " %9.0g `b' "   " %9.0g `se' "   " %9.2f `t' "   " %9.4f `p'
							ereturn scalar LATE = `b'
							ereturn scalar LATE_t = `t'
							ereturn scalar LATE_se = `se'
							ereturn scalar LATE_p = `p'
						}
						else if "`regtype'"=="logit" {
							display "Left-to-Right Discontinuity: " %9.0g `b' " | Chi2(1) = " %9.2f `r(chi2)' " | Prob>(Chi2) = " %6.4f `r(p)'
							ereturn scalar LtoR_DISCONTINUITY = `b'
							ereturn scalar LtoR__Chi2 = `r(chi2)'
							ereturn scalar LtoR__DISC_p = `r(p)'
							display "Marginal Effect:"
							display "  Predicted likelihood that Y=1 just to left of threshold = " exp(_b[`LEFT_POLY0'])/(1+exp(_b[`LEFT_POLY0']))
							display "  Predicted likelihood that Y=1 just to right of threshold = " exp(_b[`RIGHT_POLY0'])/(1+exp(_b[`RIGHT_POLY0']))
							display "  Local Average Treatment Effect = " exp(_b[`RIGHT_POLY0'])/(1+exp(_b[`RIGHT_POLY0'])) - exp(_b[`LEFT_POLY0'])/(1+exp(_b[`LEFT_POLY0']))
							ereturn scalar LATE = exp(_b[`RIGHT_POLY0'])/(1+exp(_b[`RIGHT_POLY0'])) - exp(_b[`LEFT_POLY0'])/(1+exp(_b[`LEFT_POLY0']))
							qui testnl exp(_b[`RIGHT_POLY0'])/(1+exp(_b[`RIGHT_POLY0'])) = exp(_b[`LEFT_POLY0'])/(1+exp(_b[`LEFT_POLY0']))
							display "  Local Average Treatment Effect, Chi(1) = "`r(chi2)'
							display "  Local Average Treatment Effect, p-value = "`r(p)'
						}
						else if "`regtype'"=="probit" {
							display "Left-to-Right Discontinuity: " %9.0g `b' " | Chi2(1) = " %9.2f `r(chi2)' " | Prob>(Chi2) = " %6.4f `r(p)'
							ereturn scalar LtoR_DISCONTINUITY = `b'
							ereturn scalar LtoR__Chi2 = `r(chi2)'
							ereturn scalar LtoR__DISC_p = `r(p)'
							display "Marginal Effect:"
							display "  Predicted likelihood that Y=1 just to left of threshold = " normal(_b[`LEFT_POLY0'])
							display "  Predicted likelihood that Y=1 just to right of threshold = " normal(_b[`RIGHT_POLY0'])
							display "  Local Average Treatment Effect = " normal(_b[`RIGHT_POLY0']) - normal(_b[`LEFT_POLY0'])
							ereturn scalar LATE=normal(_b[`RIGHT_POLY0']) - normal(_b[`LEFT_POLY0'])
							qui testnl normal(_b[`RIGHT_POLY0']) = normal(_b[`LEFT_POLY0'])
							display "  Local Average Treatment Effect, Chi(1) = "`r(chi2)'
							display "  Local Average Treatment Effect, p-value = "`r(p)'
						}							
						display "______________________________________________________________________________"
						display "Number of Obs =    " e(N)
						if "`regtype'"=="regress" {
							display "R-Squared     = " %9.4f e(r2)
							display "Adj R-Squared = " %9.4f e(r2_a)
						}
						qui predict `yhat'
						qui gen `yhat_left'=`yhat' if `X'<0 & `weight_final'>0
						qui gen `yhat_right'=`yhat' if `X'>=0 & `weight_final'>0
						foreach v of var `X' `Y' {
							local l`v' : variable label `v'
							if `"`l`v''"' == "" {
								local l`v' "`v'"
							}
						}
						local xtext 
						if `threshold'~=0 {
							local xtext=" Minus Threshold"
						}
						* If bins_graph is selected as an option, collapse the data such that x and y values are collapsed within the bin.
						if `bins_graph'>0 {
							* Note: bins constructed such that they don't straddle the threshold.
							qui sum `X'
							local number_bins_left=int(`bins_graph'*(0-r(min))/(r(max)-r(min)))
							local number_bins_right=`bins_graph'-`number_bins_left'
							gen `BIN'=(`X'<0)*int(`number_bins_left'*(`X'-r(min))/(0-r(min)))+(`X'>=0)*(`number_bins_left'+int(`number_bins_right'*(`X'-0)/(r(max)-0)))
							foreach Z of var `Y' `X' {
								qui replace `Z'=`Z'*`X_weight'
							}
							foreach Z of var `yhat_left' `yhat_right' {
								qui replace `Z'=`Z'*`weight_final'
							}
							collapse (sum) `Y' `X' `yhat_left' `yhat_right' `X_weight' `weight_final', by(`BIN')
							foreach Z of var `Y' `X' {
								qui replace `Z'=`Z'/`X_weight'
							}
							foreach Z of var `yhat_left' `yhat_right' {
								qui replace `Z'=`Z'/`weight_final'
							}
							qui replace `yhat_left'=. if `X'>=0
							qui replace `yhat_right'=. if `X'<0
						}
						* Collapse data by distinct value of x
						qui replace `Y'=`Y'*`X_weight'
						foreach Z of var `yhat_left' `yhat_right' {
							qui replace `Z'=`Z'*`weight_final'
						}
						collapse (sum) `Y' `yhat_left' `yhat_right' `X_weight' `weight_final', by(`X')
						qui replace `Y'=`Y'/`X_weight'
						foreach Z of var `yhat_left' `yhat_right' {
							qui replace `Z'=`Z'/`weight_final'
						}
						qui replace `yhat_left'=. if `X'>=0
						qui replace `yhat_right'=. if `X'<0
						graph set window fontface "LM Roman 12"
						qui count 
						local gray_pct=min(30,max(15,round(1000/`r(N)')))
						local black_pct=`gray_pct'
						qui sum `X_weight'
						if r(max)/r(min)>20 {
							local msize="vsmall"
						}
						else if r(max)/r(min)>10 {
							local msize="small"
						}
						else {
							local msize="medsmall"
						}
						twoway (scatter `Y' `X' [fweight=`X_weight'], msize(`msize') msymbol(O) mlwidth(vthin) mlcolor(black%`black_pct') mfcolor(gray%`gray_pct') xline(0, lcolor(gray))) (line `yhat_left' `X', lcolor(red%80) lwidth(thick)) (line `yhat_right' `X', lcolor(midblue%80) lwidth(thick) scheme(s1color) legend(off) xtitle(" " "`l`X''`xtext'") ytitle("`l`Y''" " ")) 
						graph set window fontface default
					}
				}
			}
		}
		restore
	}
	display "NEXT program is complete"
end
