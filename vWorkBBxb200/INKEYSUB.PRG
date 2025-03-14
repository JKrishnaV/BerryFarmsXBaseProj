//---------------------------------------------------------------------------
// Application: Billing Information System                                 
// Description: Substitute for Inkey() used in traffic control             
//              systems.                                                   
//                                                                         
//   File Name: INKEYSUB.PRG                                               
//      Author: Bill Hepler                                                
// Date created: 03-28-96              
// Time created: 05:06:12pm            
// Copyright: (c) 1996 by Bill Hepler
//---------------------------------------------------------------------------


function InkeySub1( nTime )
	local nReturn

	if valType(nTime)=='U'
		nReturn := inkey()
	else
		nReturn := inkey( nTime )
	endif

return( nReturn )

