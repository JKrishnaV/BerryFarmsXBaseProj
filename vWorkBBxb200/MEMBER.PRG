// member.prg
// May 26, 1994
// written by B.H.
// the system must be able to say whether someone is a member
// in a given time Frame.

#include 'common.ch'
#include 'bsgstd.ch'
#include 'BerryPay.ch'
#include "indexord.ch"
#include "field.ch"

function MemberStatus( nGrower )
   // is Member at this Date.
   local nStatus := 1
	local nRec := 0, nOrd := -1


	// June 95, this is changed, we have 2 Member statuses
	if Grower->number <> nGrower
		nOrd := Grower->(IndexOrd())
		if !Grower->(eof())
			nRec := Grower->(recno())
		endif
      Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
		Grower->(dbSeek( str(nGrower,FLD_GROWER),HARDSEEK))
	endif
	nStatus := Grower->status
	if nOrd >= 0
      Grower->(OrdSetFocus( nOrd ))
	endif
	if nRec > 0
		Grower->(dbGoto(nRec))
	endif

	// we don't look at Shares  - June 95, Peggy.
   // Shares->(OrdSetFocus(SHARES_NUMBER_ORD))
   // Shares->(dbSeek(str(nGrower,FLD_GROWER),HARDSEEK) )

   // do while !Shares->(eof()) .and. shares->number== nGrower
   //	if SharesOSat( dDate)
   //		lReturn := .t.
   //		exit
   //	endif
   //	Shares->(dbSkip())
   // enddo

return( nStatus )

/*
	function isMemberDuring( nGrower, d1, d2)
			// if he is a member at ANY TIME during this period.

			local lReturn := .f., dFrom, dTo

		   DEFAULT d1 TO date()-36500  // 100 years ago
		   DEFAULT d2 TO date()+36500  // 100 years from now

			dFrom := min(d1,d2)
			dTo := max(d1,d2)

         Shares->(OrdSetFocus(SHARES_NUMBER_ORD))
		   Shares->(dbSeek(str(nGrower,FLD_GROWER),HARDSEEK) )

		   do while !Shares->(eof()) .and. shares->number== nGrower
		   	if SharesOSfrom(dFrom,dTo)
		   		lReturn := .t.
		   		exit
		   	endif
		   	Shares->(dbSkip())
		   enddo

	return( lReturn )
*/

/*
	function SharesOSat( dDate )
		// are shares outstanding as of this date ?
		local lReturn := .f.
	  	do case
	  	 case empty(Shares->dt_redeem) .and. Shares->dt_active <= dDate
	  		lReturn := .t.
	  	 case Shares->dt_redeem >= dDate .and. Shares->dt_active <= dDate
	  	 	lReturn := .t.
		endcase
	return( lReturn )


	function SharesOSfrom( d1, d2)
		// are shares outstanding in this date range ?

		local lReturn := .f., dFrom, dTo

		dFrom := min(d1,d2)
		dTo := max(d1,d2)

	  	do case
	  	 case empty(Shares->dt_redeem) .and. Shares->dt_active <= dTo
	  		lReturn := .t.
	  	 case Shares->dt_redeem >= dFrom .and. Shares->dt_active <= dTo
	  	 	lReturn := .t.
		endcase
	return( lReturn )
*/
