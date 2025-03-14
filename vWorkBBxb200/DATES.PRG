// dates.prg
// June 30, 1994

#include 'valid.ch'
#include 'sysValue.ch'
#include 'common.ch'
#include 'bsgstd.ch'

function validAcctYear( nYear, nMessage )
	local lReturn
   DEFAULT nMessage to VT_NO_MESSAGE

	lReturn := nYear >= sysValue(SYS_CURRENT_YEAR)-1  .and. ;
	           nYear <= sysValue(SYS_CURRENT_YEAR)+1

	if nMessage==VT_MESSAGE .and. !lReturn
		waitHand({'The year must be within one year of the current crop year', ;
		 'The current crop year is '+lstrim(sysValue(SYS_CURRENT_YEAR)), ;
		 'This is controlled from the System Settings in the', ;
		 'Housekeeping Menu.'})
	endif
return( lReturn )

function validCropDate( dDate, nMessage )
	local lReturn
   DEFAULT nMessage to VT_NO_MESSAGE

	lReturn := year(dDate)==sysValue(SYS_CURRENT_YEAR)

	if nMessage == VT_MESSAGE .and. !lReturn
		waitHand({'The date must be within the current crop year', ;
		 'The current crop year is '+lstrim(sysValue(SYS_CURRENT_YEAR)), ;
		 'This is controlled from the System Settings in the', ;
		 'Housekeeping Menu.'})
	endif
return( lReturn )

function validAcctDate( dDate, nMessage )
	local lReturn
   DEFAULT nMessage to VT_NO_MESSAGE

	lReturn := year(dDate) >= sysValue(SYS_CURRENT_YEAR)-1  .and. ;
	           year(dDate) <= sysValue(SYS_CURRENT_YEAR)+1

	if nMessage==VT_MESSAGE .and. !lReturn
		waitHand({'The date must be within one year of the current crop year', ;
		 'The current crop year is '+lstrim(sysValue(SYS_CURRENT_YEAR)), ;
		 'This is controlled from the System Settings in the', ;
		 'Housekeeping Menu.'})
	endif
return( lReturn )


