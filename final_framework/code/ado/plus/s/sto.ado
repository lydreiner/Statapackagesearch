program def sto 
*! NJC 1.0.0 8 December 1999 toggles trace on and off 
	version 6.0 
	local onoff : set trace 
	local which = cond("`onoff'" == "on", "off", "on") 
	set trace `which' 
end 	
