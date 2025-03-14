// common.prg
// called from other programs
// were duplicate copies of this stuff...

#include 'BerryPay.ch'
#include 'bsgstd.ch'
#include 'inkey.ch'
#include 'colors.ch'
#include 'sysValue.ch'
#include 'common.ch'
#include 'browser.ch'
#include "field.ch"
#include "indexord.ch"


// these 2 functions are so PROCESSED are dealt with correctly !
// June 95

function TotalProd()
	local nReturn

	// Not Needed any more
	nReturn := Field->net

return( nReturn )

function ConInOuter( cVar )
	local nReturn
	local cIn, cOut

	cIn  := cVar+'_IN'
	cOut:= cVar+'_OUT'

	nReturn :=  eval(fieldBlock( cOut)) - eval(fieldBlock( cIn))

return( nReturn )


function PrettyChequeNo()
	// sb called Cheque->(PrettyChequeNo())

	field cheque, series
	local cReturn
	cReturn := series +' '+strZero(abs(cheque),FLD_CHEQUE)+iif(cheque<0,'-',' ')
return( cReturn )

function SetGrow4Rpt( lPayGrp, cPayGrp ,cOrder )
   // cOrder == 'N' or 'D', Numeric or Pay Group
   // cPayGrp is for a specific PayGrp
   // lPayGrp is are we in Pay Group order ?

	local lReturn := .t.

	msgLine('Getting ready to Print')
	if !empty(cPayGrp)
		Grower->(dbSetFilter({ || Grower->payGrp==cPayGrp} ))
	else
		Grower->(dbClearFilter( ))
	endif

	IF cORDER=='N'
	   IF lPayGrp
         Grower->(OrdSetFocus(GROWER_PAYGRP_NUMBER_ORD))
	   else
         Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
	   endif
	else
	   IF lPayGrp
         Grower->(OrdSetFocus(GROWER_PAYGRP_NAME_ORD))
	   else
         Grower->(OrdSetFocus(GROWER_NAME_ORD))
	   endif
	endif

	Grower->(dbGoTOp())
	if Grower->(eof())
		Grower->(dbClearFilter())
		waitInfo({'No Growers meet these criteria'})
		lReturn := .f.
	endif

return(lReturn)

/*
	shares ONLY

	function AddDel( lAdd, nGrower)
		local nReturn := SIG_FORCE_REDRAW

		if lAdd
			if Yesno({'Add Record?'})
	   		if Shares->(addRecord())
	   			Shares->number := nGrower
	   		endif
	   	endif
	   else
	   	if Yesno({'Delete Record?'})
	   		Shares->(DeleteRecord())
	   		if !Shares->(dbSeek( str(nGrower,FLD_GROWER),HARDSEEK))
	   			nReturn := SIG_EXIT
	   		endif
	   	endif
	   endif


	return( nReturn )
*/


