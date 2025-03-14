//-------------------------------------------------------------------------
//  For Berry Payment System
//  Description: Checks for errors before a cheque run
//               Does not bother to check transactions that are not going
//               to be paid against.
//
// File Name: CHEK4ERR.PRG
// Author: Bill Hepler
// Date created: 06-24-00
// Revised     : Aug-2001 to have INCLUDES & EXCLUDES
//               May 2020 add a couple additional minor checks
//               Nov 2022 improve message
//
// Copyright: (c) 2000,2001 by Bill Hepler
// Copyright: (c) 2015, 2020, 2022 by Bill Hepler & Crafted Industrial Software Ltd.
// -------------------------------------------------------------------------

#include "BerryPay.ch"
#include "printer.ch"
#include "field.ch"
#include "indexord.ch"
#include "bsgstd.ch"
#include "valid.ch"
#include 'errors.ch'

function GoofyParam( nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp   )
	// checks that Parameters make some sense....
	// is called by Check4Err() & other routines..

	local lReturn := .t.

	do case
	case nIncGrower > 0 .and. !empty(cIncPayGrp)
		waitHand({'Hey - either pick a grower or a group'})
	case nExcGrower > 0 .and. !empty(cExcPayGrp)
		waitHand({'Hey - either exclude one grower or a group'})
	case nExcGrower > 0 .and. nIncGrower > 0
		waitHand({'Hey - either exclude one guy or include one'})
	case !empty(cExcPayGrp) .and. !empty(cIncPayGrp)
		waitHand({'Hey - either exclude a group or include one'})
	case nIncGrower > 0 .and. !empty(cExcPayGrp)
		waitHand({'Hey - too fancy !'})
	otherwise
		lReturn := .f.
	endcase
return( lReturn )

function Check4Err(  dLastDate, cProduct, cProcess, ;
       nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp, nAdvance   )
	local lReturn := .t.
   local aHead
   local bWhile, bFor
   local n

	if GoofyParam( nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp   )
		return( .f. )
	endif

	msgLine('Checking that all prices are valid...')
   Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))
	Daily->(dbSetRelat( 'Grower', { || str( Daily->number, FLD_GROWER)}, ;
		'str( Daily->number,'+ lStrim( FLD_GROWER)+')' ))

   bFor := { || .t. }
   //2BFIXED - noted in Oct 2013 - looking for UnFinal...
	//   July 2015 - not sure about this...
   if nAdvance >= 1
      aHead  := {'Unposted Transaction Errors for Advance '+str(nAdvance,1) }
      do case
      case nAdvance==1
         bFor := { || Daily->post_bat1==0  }
      case nAdvance==2
         bFor := { || Daily->post_bat2==0 }
      case nAdvance==3
         bFor := { || Daily->post_bat3==0 }
      otherwise
         appError( APP_ERR_UNKNOWN_ADVANCE_TYPE2, ;
          { 'Can not do this - Advance Type is not known!'})
         return( .f. )
      endcase
   else
      // Final Payment
      aHead  := {'Final Payment Errors'}
	endif

   Daily->(OrdSetFocus( DAILY_FINAL_DATE_ORD))
   bWhile := { || Daily->fin_bat==0 .and. Daily->date <= dLastDate }

   if !empty( cProduct )
      aadd( aHead, 'Product = '+cProduct )
   endif
   if !empty( cProcess )
      aadd( aHead, 'Process = '+cProcess )
   endif
   if nIncGrower <> 0
      aadd( aHead, 'Grower # = '+lStrim(nIncGrower) )
   endif
   if nExcGrower <> 0
      aadd( aHead, 'Grower # <> '+lStrim(nExcGrower) )
   endif
   if !empty(cIncPayGrp)
      aadd( aHead, 'Pay Group = '+cIncPayGrp )
   endif
   if !empty(cExcPayGrp)
      aadd( aHead, 'Pay Group <> '+cExcPayGrp )
   endif

	Daily->(dbGoTop())

   if FndErrLoop( .f., nAdvance,  bFor, bWhile, cProduct, cProcess, ;
			 nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp  )

		lReturn := .f.

		if SelectPrn('ERRORS.TXT')
			Daily->(dbGoTop())

			PRINT_ON  RPT_OVERWRITE
         nuQprnOut()
         nuQprnOut( padr(shMDY(date()),25)+padc(aHead[1],35) )
         nuQprnOut( ;
          padr(time(),25)+     padc( iif( len(aHead) >=2,aHead[2],''),35) )

         for n := 3 to len(aHead)
            nuQPrnOut( space(25)+padc( aHead[n], 35) )
         next
         nuQprnOut()

         FndErrLoop( .t. , nAdvance,bFor, bWhile, cProduct, cProcess, ;
				 nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp )

         nuQprnOut()
         nuQprnOut( 'End.'  )
			PRINT_OFF  RPT_COMPLETE_EJECT
		endif
	endif

return( lReturn )


static function FndErrLoop( lPrint,nAdvance,bFor, bWhile,cProduct,cProcess, ;
		 nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp )
	local lErr, lPrice
   local nFinal
	local nErrs := 0
	local lReturn := .f.
	local lTest
   local lFound  := .f.
	local aErrors := {}

	lErr := .f.

	do while !Daily->(eof()) .and. eval(bWhile)
      showProg( str(Daily->number, FLD_GROWER )+str(Daily->(recno()),6) )
		lErr := .f.
		nAdvance := 0.00
		nFinal   := 0.00
		lPrice   := .f.

      if (nIncGrower==0 .or. nIncGrower==Daily->number) .and. ;
         (nExcGrower<>Daily->number) .and. eval( bFor )

			lTest := .t.
			if ValidTest( V_GROWER, Daily->number, VT_MESSAGE )
				if !empty(cIncPayGrp)
					if !(Grower->payGrp==cIncPayGrp)
						lTest := .f.
					endif
				endif
				if !empty(cExcPayGrp)
					if Grower->payGrp==cExcPayGrp
						lTest := .f.
					endif
				endif

				if lTest
            	// added May 20, 2020, this seems to trap some errors...
					do case
					case !empty( Daily->product )
						if !ValidTest( V_PRODUCT, Daily->product, VT_NO_MESSAGE )
							WaitInfo({'Receipt: ' + Daily->depot+'-'+var2char( Daily->recpt )+ Daily->RECPTLTR+'  Can NOT find PRODUCT: '+Daily->product, ;
							          'Grower #='+ var2char( Daily->number)+'    Recpt Date='+shMdy(Daily->date), ;
										 'Prod/Proc/Grade: '+ Daily->product+'/'+daily->Process+'/'+var2char( Daily->grade), ;
							          'This is an Unusual situation that you should correct before posting.' })
							lTest := .f.
							lErr  := .t.
						else
							if empty( Daily->process ) .or. Daily->grade > MAX_NO_OF_GRADES .or. empty( Daily->grade )
								WaitInfo({'Receipt: ' + Daily->depot+'-'+var2char( Daily->recpt )+ ' Problem with Process/Grade', ;
							          'Grower #='+ var2char( Daily->number)+'    Recpt Date='+shMdy(Daily->date), ;
										 'Prod/Proc/Grade: '+ Daily->product+'/'+daily->Process+'/'+var2char( Daily->grade), ;
							          'This is an Unusual situation that you should correct before posting.' })
								lTest := .f.
								lErr  := .t.
							endif
						endif
					case !empty( Daily->process )
						WaitInfo({'Receipt: ' + Daily->depot+'-'+var2char( Daily->recpt )+ ' Problem with Prod/Process/Grade', ;
								    'Grower #='+ var2char( Daily->number)+'    Recpt Date='+shMdy(Daily->date), ;
								    'Prod/Proc/Grade: '+ Daily->product+'/'+daily->Process+'/'+var2char( Daily->grade), ;
								    'This is an Unusual situation that you should correct before posting.' })
						lTest := .f.
						lErr  := .t.
					endcase
				endif
			else
				lTest := .f.
				lErr  := .t.
			endif


			if lTest  // i.e. test futher...
            lFound := .t.

	         if forPP( cProduct, cProcess )
	            if !Daily->(fValidPrice())
	               lErr := .t.
						aadd( aErrors, TicketIDstring( 'Price Not Found' ))
	            else
                  nAdvance := Daily->(TotAdvPrice())
	               nFinal   := Daily->(FinalPrice())

                  if (nFinal < nAdvance .and. str(nFinal,12,2)<>str(0,12,2)) ;
	                        .or. ;
                     ( nAdvance==0 .and. str(nFinal,12,2) <  str(nAdvance,12,2) )

                     lErr   := .t.
                     lPrice := .t.
							aadd( aErrors, TicketIDstring( 'Invalid Price' ) )
	               endif

	               if Daily->number==0 .or. Daily->number <> Grower->number
	                  lErr := .t.
							aadd( aErrors, TicketIDstring( 'Grower # Err' )  )
	               endif
	            endif

				endif
         endif

         if lErr
				nErrs++
            lReturn := .t.

				if !lPrint
					exit    // we found some error
				else
					if NearPageBottom( 9 )
						NuFormFeed()
						NuQPrnOut()
						NuQprnOut( ;
						 shMDY(date())+space(10)+' Error Report Continued...')
						NuQprnOut()
						NuQprnOut()
					endif

					NuQprnOut( 'Grower: '+str(Daily->number,FLD_GROWER)+ ;
					 '   Rcpt:'+ str(Daily->recpt, FLD_RECPT)+' '+ ;
						 shMDY(Daily->date)+ '   Prd: '+ ;
						  Daily->product+' '+Daily->process+ ;
						  str(Daily->grade,FLD_GRADE)  )
					if lPrice
						NuQQprnOut( ' *Price* ')
						if !Price->(eof())
							NuQQprnOut( lStrim(Price->priceID) )
						endif
					endif
				endif
			endif
		endif
		Daily->(dbSkip())
	enddo

	do case
	case nErrs >= 1 .and. len( aErrors) <= 12
		aadd( aErrors , 'There were '+lStrim(nErrs)+' errors found.' )
		WaitInfo( aErrors )
	case nErrs >= 1 .and. len( aErrors) >= 12
		aadd( aErrors , 'There were '+lStrim(nErrs)+' errors found.' )
		WinArrayVu( aErrors, 'Info on Errors')
	case !lFound
      WaitInfo({'We did not seem to find any Receipts that met the', ;
       'criteria you set!'})
   endcase

return( lReturn )


static function TicketIDstring( cDesc)
	local cReturn := ''

	if Daily->Number > 0
		cReturn := 'Grower ID: ' + str( Daily->Number, FLD_GROWER)+', '
	else
		cReturn := 'GrowID Err ' + str( Daily->Number, FLD_GROWER)+', '
	endif

	cReturn += 'Receipt#: '+Daily->depot + str( Daily->Recpt, FLD_RECPT) + Daily->RecptLtr + ;
                 Daily->product+' '+Daily->process+ var2char( Daily->grade) +  ;
   '  '+shMDY( Daily->date)+' '+cDesc

return( cReturn )

/* ---------------------------------------------------------  Too Much Work Nov 2019
static Function CheckAmounts( )
	local nDailyPostPrice := 0
	local nFoundTotPrice  := 0
	local aAcctRec :=

	Audit->(dbOrdSetFocus( AUDIT_DAY_ACCT_ORD ))
	Audit->(dbSeek( str( Daily->day_uniq, FLD_DOCUMENT ))
	do while !Audit->(eof())

	if NotEqual0( Daily->post_bat1 )
		// We posted it
		nDailyPostPrice += Daily->adv_pr1

----------------------------------------------------------------------- */




