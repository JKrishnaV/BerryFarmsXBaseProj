// Acct_l.prg
//    Prints Posted Summary Account Transactions.
//
// July 27, 2011
// Minor Rev Aug 5, 2011
// July 10, 2014 - Changes for GST
// Mar 08, 2019 - Legend
//
// Bill Hepler
// (c) 2011, 2014 by Bill Hepler
//          minor fix in November 2011


#include 'common.ch'
#include 'window.ch'
#include 'bsgstd.ch'
#include 'printer.ch'
#include 'BerryPay.ch'
#include 'inkey.ch'
#include 'sysvalue.ch'
#include 'valid.ch'
#include 'account.ch'
#include 'radio.ch'
#include "field.ch"
#include "indexord.ch"
#include "errors.ch"
#include 'berry_rpt.ch'
#include "rpt.ch"


function AcctLedger( )
	local aWin, getList :={}
	local nGrower
	local dFrom,dTo
	local cStatus := 'A'
	local nRadio := 1, n
	local aRadio
	local cRpt
	local bGrower
	local lConfigure := .f., lLegend := .f.,  lOk
	local bFor, bForAcc, bForPaid
	local aTitle, aRpt

	if !openMainStuff( DB_SHARED)
		close databases
		return( nil )
	endif

	dFrom   := stod( str( sysValue(SYS_CURRENT_YEAR),4)+'0101')
	dTo     := date()
	nGrower := 0

	create radiobox 07,12 using { ;
	 'All Types of Account Entries', ;
	 'Only Non Weekly Entries     ', ;
	 'Potential Loan Entries      '} title 'Type of Report' frame to aRadio
	nRadio := 1

	myBsgScreen( 'Grower Ledgers' )
	msgLine('Grower Ledger Reports')
	
	create window at 5,8,21,72 title 'Account Entries' to aWin
	display window aWin
	set cursor on

	in window aWin @ 14,2 winsay ;
	 'This ledger is a summary of POSTED transactions. It does not'
	in window aWin @ 15,2 winsay ;
	 'include UNPOSTED berry receipts, but can include entries for'
	in window aWin @ 16,2 winsay ;
	 'loans and other special adjustments.'

	do while .t.
		aTitle := {'',''}
		msgLine('[Esc] to Exit')
		nRadio := RadioDo(aRadio,nRadio)

		if lastkey()==K_ESC .or. nRadio <= 0
			exit
      endif

   	in window aWin @ 8,2  winsay 'From' winget dFrom picture '@d' ;
   	 GET_MESSAGE ;
   	 'Enter the Beginning Transaction Cut Off Date (REMEMBER +/- keys)'

   	in window aWin @ 9,2  winsay ' to ' winget dTo picture '@d' ;
   	 GET_MESSAGE ;
   	 'Enter the Ending Transaction Cut Off Date   (Remember the +/- keys)'

		in window aWin @10,2  winsay 'Specific Grower Only' winget nGrower ;
		 picture NumBlankPic( FLD_GROWER ) ;
       LOOKUP( LU_GROWER, ;
		 'Enter a Grower ID here, if you wish to print a ledger for 1 grower ONLY')

      in window aWin @11,2  winsay 'Payment Status' winGet cStatus ;
       picture '!' GET_MESSAGE ;
       'Payment Status, A=All, P=Paid Only, U=Unpaid Only'

      in window aWin @13,2  winsay 'Configure Report  ' winGet lConfigure ;
       picture 'Y' GET_MESSAGE ;
       'Select columns to print on the report'
		in window aWin @13,42 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

		READ


		do case
		case lastkey()==K_ESC
		 	exit
		case cStatus == 'A'
			aTitle[2] := 'Includes paid and unpaid transactions'
			bForPaid := { || .t. }
		case cStatus == 'P'
			aTitle[2] := 'Includes Paid transactions only'
			bForPaid := { || !empty( Account->SERIES) .or. ;
			 	                  Num2NotEqual0( Account->CHEQUE) }
		case cStatus == 'U'
			aTitle[2] :='Includes UnPaid transactions only'
			bForPaid := { || empty( Account->SERIES) .and. ;
			 	                  Num2Equal0( Account->CHEQUE) }
		otherwise
			waitHand({'Please correct Payment Status as All, Paid, or Unpaid'})
			loop
		endcase

		if selectPrn('ACCT_TRN.TXT')

			do case
			case nRadio==1
				cRpt := REPORTS_ACCT_LEDGER_ALL
				aTitle[1]  :=  'Shows any accrued (posted) transactions'

				bForAcc := { || .t. }
			case nRadio==2
			 	cRpt := REPORTS_ACCT_LEDGER_OTHER
			 	aTitle[1] := 'Excludes advances and final payments'
			 	bForAcc := { || !( Account->type $   TT_BERRY_ADVANCE_1 + '.' ;
			 	  + TT_BERRY_ADVANCE_2 + '.'  ;
			 	  + TT_BERRY_ADVANCE_3 + '.'  ;
			 	  + TT_TIME_PREMIUM    + '.'  ;
			 	  + TT_STD_DEDUCTION   + '.'  ;
			 	  + TT_FINAL_BERRY     + '.'  ;
			 	  + TT_ADV_CONTAINER_ONLY ) }
			case nRadio==3
				cRpt := REPORTS_ACCT_LEDGER_LOAN
				aTitle[1] := 'Transactions which may relate to loans'
			 	bForAcc := { ||  ( Account->type ==  TT_MISCELLANEOUS .or. ;
			 	    Account->type == TT_DEDUCT ) .and. Account->class <> D_CL_BC_BLUE_LEVY   }
			endcase

			aRpt := {}
			InitAccountRpt( aRpt, .f. )
			gRptInit( cRpt, aRpt)

			if lConfigure
				waitInfo({'You are Configuring Report Format '+cRpt, ;
				   aTitle[1] })

				gRptSelect( aRpt )
				if yesno({'Save this Production Report Format #1?'})
					gRptSave( aRpt )
				endif
			endif

			msgLine('Getting ready to print...')
			if nGrower==0
				bGrower := {|| .t. }
			else
				bGrower := {|| Account->number == nGrower }
				aadd( aTitle,'For grower = '+lStrim( nGrower ) )
			endif

			Account->(ordSetFocus( ACCOUNT_NUMBER_ORD ))
         Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
			Account->(dbSetRelation( 'Grower', ;
		      { || str( Account->number,FLD_GROWER) } ) )
			Account->(dbGoTop())

			bFor := { || Account->date >= dFrom .and. Account->date <= dTo }

			msgLine('Finding first record....')
			n := 1
			lOk := .f.
			do while !Account->(eof())
				showProg( str( n,6))
				if eval( bFor ) .and. eval( bGrower) .and. ;
				   eval( bForAcc) .and. eval( bForPaid )
					lOk := .t.
					exit
				endif
				Account->(dbSkip())
			enddo

			if !lOk
				WaitInfo({'We could not find any transactions', ;
				   'Try again....'})
				loop
			endif

			gRptInitHead()
			gRptGetSetHead( RPT_HEAD_TITLE, aTitle )
			gRptGetSetHead( RPT_HEAD_FOR_CONDITION, ;
                  { || eval( bFor ) .and. eval( bForAcc ) .and. ;
                       eval( bForPaid) .and. eval( bGrower ) })

			gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
			gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {||Account->number} )
			gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
				{ || nuQprnOut( 'Grower: '+lStrim(Account->number) + ' '+ ;
			     NameOf( LU_GROWER_NAME, Account->number) ) } )

			// For LandScape
			gRptAutoPageOrientation( aRpt, 0)
			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

			Account->( gRptPrinter( aRpt ))

			nuQprnOut()
			nuQprnOut('End of Report')

			if lLegend
				prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
			endif

			PRINT_OFF  RPT_COMPLETE_EJECT
   	endif
	enddo

	close databases
	kill window aWin
	RadioKill( aRadio )

	close databases
return( nil )



