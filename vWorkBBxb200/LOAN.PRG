// -------------------------------------------------------------------------
//  Application: Berry Payment System
//  Description: Does advances, pays a single grower a given amount
//               and sets a repay.....
//    File Name: LOAN.PRG - formerly called "ADVANCE"
//       Author: Bill Hepler
//
//  July 2014 - stuff for GST put in.
//  May 2021  - more audit trail for loans etc
//  Feb 2023  - Quick Change for Jass to allow for their odd business practice
//
// Copyright: (c) 1995-2014,20212023 by Bill Hepler & Crafted Industrial Software Ltd.
// -------------------------------------------------------------------------

#include 'window.ch'
#include 'BerryPay.ch'
#include 'bsgstd.ch'
#include 'account.ch'
#include 'sysvalue.ch'
#include 'valid.ch'
#include 'inkey.ch'
#include "indexord.ch"
#include "field.ch"
#include "events.ch"

function LoanChq()
   local aWin
	local getList := {}
	local nRec, nChoice
	local nGrower, nYr, dDate, nAmount
	local cNote
   local lPrintLoan := .t.
	local nAcct_Uniq
	local nDeduced_AcctUniq

	if !openMainStuff( DB_EXCLUSIVE )
		close databases
		return( nil )
	endif

	cNote         := space(30 )
	nYr           := sysValue(SYS_CURRENT_YEAR)
	dDate         := date()
	nGrower       := 0
	nAmount       := 0.00

   bsgScreen( 'Crop Advance (Loan)' )
   create window at 5,5,20,73 title 'Generate an Advance (Loan) Cheque' to aWin
	display window aWin

	do while .t.
      in window aWin @ 8,2 winsay ;
       'This procedure allows you to generate a manual cheque for an'
      in window aWin @ 9,2 winsay ;
        'amount you specify to a grower. The system also creates a'
      in window aWin @10,2 winsay ;
       'reversing entry to help you track the loan, so that it will'
      in window aWin @11,2 winsay ;
       'be paid back.  Normally, the PAYBACK will be deducted from'
      in window aWin @12,2 winsay ;
       'a cheque to the grower.'


      in window aWin @14,2 winsay ;
       'This procedure is easy to do - BUT you may find it makes'
      in window aWin @15,2 winsay ;
       'reconciling the grower ledger more complex!'


		in window aWin @ 2,2 winsay  'Grower ID:      ' winget nGrower ;
		 picture NumBlankPic( FLD_GROWER ) ;
		 valid validTest( V_GROWER, nGrower, VT_MESSAGE ) ;
       LOOKUP( LU_GROWER,'Enter a Grower ID or [F5] to Browse')

		in window aWin @ 3,2  winsay 'Trans. Date:    ' winget dDate ;
		  picture '@D' GET_MESSAGE 'Set Transaction Date'

      in window aWin @ 4,2 winsay  "Reason for Loan " winGet cNote ;
         get_message 'Remind yourself why you are doing this!'

		in window aWin @ 5,2 winsay  'Amount of Cheque' winget nAmount ;
       picture '9999999.99'  ;
       when AmtShow(nAmount,aWin) ;
       valid nAmount > 0 .and. AmtShow(nAmount,aWin) ;
		 get_message "This transaction will be automatically reversed - NO GST on this Cheque!"

      in window aWin @ 6,2 winsay  "Show word Loan on Cheque" winGet lPrintLoan ;
         picture 'Y' ;
         get_message 'This means the system will NOT insert the word Loan on this transaction'

		read

		if lastkey() <> K_ESC
			nChoice := thinChoice({'Edit','Run Cheque','X - eXit'})
			do case
			case nChoice == 1
				loop
			case nChoice == 2
         	if empty( cNote )
            	if !YesNo({'You should put in a note to explain this', ;
                         'Do you want to continue anyway?' })
               	loop
               endif
            endif

            if !lPrintLoan
            	WaitInfo({'This is a LOAN, but the Cheque and some other reports', ;
                         'will not always say this...be sure that you want to override this.'})
            endif

            if !ValidTest(V_GROWER,nGrower,VT_MESSAGE)
					loop
				endif

            if Grower->onHold
               WaitHand({'This grower is on hold!  You should not do this', ;
                 'You can remove Grower '+lstrim(nGrower)+' from hold', ;
                 'and then do this.  You may then set him back to ONHOLD', ;
                 'once you have issued the Cheque.'})
               loop
            endif

            if !yesno({'Are you sure you want to do this?  You will probably', ;
                      'find it more difficult to reconcile this grower later.', ;
                      'We suggest that if possible you issue an advance', ;
                      'against product recieved...','', ;
                      'Are you sure you want to do this?'})
               waitInfo({'Good - you are not going to do this procedure now'})
               exit
            endif

            if !ValidTest(V_GROWER,nGrower,VT_MESSAGE)
					loop
				endif

            // July 2009 - NOTE THIS SHOULD BE CHANGED-ADVANCE LOAN!!
				// July 28, 2014
				nAcct_Uniq := NextAcctUniq( )

				Account->(AddRecord())
				Account->currency := Grower->currency
            Account->number  := nGrower
            Account->date    := dDate
            Account->type    := TT_MISCELLANEOUS
				Account->dollars := nAmount
				Account->gst_est :=  0.00

            if lPrintLoan .and. !empty( cNote )
            	// this is what it does
	            Account->desc    := 'Loan: '+cNote
            else
            	Account->desc    := cNote
            endif

				Account->year    := nYr
				Account->acct_uniq := nAcct_Uniq

				nRec := Account->(recno())

				nDeduced_AcctUniq := NextAcctUniq( )

				// reversing entry...
				Account->(addRecord())
				Account->currency := Grower->currency
				Account->number   := nGrower
				Account->date     := dDate
				Account->type     := TT_DEDUCT
				Account->class    := D_CL_MISCELLANEOUS
				Account->dollars  := -nAmount
				Account->gst_est  := 0.00

            if lPrintLoan .and. !empty( cNote )
	            Account->desc     := 'Loan Owing '+cNote
            else
            	Account->desc     := alltrim( padr(cNote,23))+' Owing'
            endif

				Account->year     := nYr
				Account->acct_uniq := nDeduced_AcctUniq

				AudAcct->(addRecord())
				AudAcct->acct_uniq  := nAcct_Uniq         // Initate
				AudAcct->acct_child := nDeduced_AcctUniq  // theLoan
				AudAcct->(dbCommit())
				AudAcct->(dbUnLock())

            Cheques(Grower->Currency, CHEQUE_TYPE_LOAN, ;
					 nYr, nGrower, ;
					  'N', .f., ;
				 space(FLD_PAYGRP), dDate, nRec )

            LogAnEvent( EVT_TYPE_CHEQUE_LOAN_ISSUED , ;
                      {'Issued Loan to ' + var2char( nGrower)+ ' Amount $'+var2char( nAmount), ;
                       'effective '+var2char( dDate), cNote })
			endcase
		endif
		exit
	enddo

	kill window aWin
	close databases

return( nil )

static function AmtShow( nAmount, aWin )

   in window aWin @ 5,35 winsay transform(nAmount,'$99,999,999.99')

return( .t. )



