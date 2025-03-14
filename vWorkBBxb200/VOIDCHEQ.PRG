// VoidCheq.prg
// Bill Hepler
// 07-15-94 11:25am
//   changes to correct an "added" bug in SpPay.prg where I inadvertantly
//   deleted some stuff..

// Rewritten in Nov 2000 to VOID the cheques in a reasonable way....
// July 2011 - fixed unreported problem with report.
// May 2021  - revise some

#include "common.ch"
#include 'window.ch'
#include 'bsgstd.ch'
#include 'printer.ch'
#include 'BerryPay.ch'
#include 'inkey.ch'
#include 'sysvalue.ch'
#include 'valid.ch'
#include 'account.ch'
#include "field.ch"
#include "indexord.ch"
#include 'errors.ch'
#include "events.ch"


#define A_TT_TYPE_PAY       1
#define A_TT_COUNT          2
#define A_TT_EARLIEST_DATE  3
#define A_TT_LATEST_DATE    4


static  dVoidAt    := NIL      // Set to nil to avoid compiler warnings
static  aDiagPayTypes  := {}, aDiagNote := {}
static  nDiagFirst     := 0
static  nDiagSecond    := 0
static  nDiagThird     := 0
static  nDiagFinal     := 0
static  lDiagMix       := .f.


function VoidChequeLeaveAP()
	local aWin, getList :={}, cChequeID, nAmt
	local nGrower
	local cSeries, nCheque
	local dFrom

   InitDiagStatics()

	if !openfile({ ;
			'VoidChq','Grower','Account','Cheque','Audit','Daily','BankRec'}, ;
	  DB_EXCLUSIVE)
		close databases
		return( nil )
	endif


	dFrom   := date()
	nGrower := 0
	cSeries := space(FLD_SERIES)
	nCheque := 0

	myBsgScreen( 'Void (cancel) Cheque, Leave AP Vouchers & Receipts' )

	create window at 6,10,16,69 title 'Select Cheque to Void' to aWin
	display window aWin

	waitInfo({'This screen allows you to void cheques.  We are simply voiding',       ;
	 'the cheque, but we leave all VOUCHER information and Receipt information',      ;
    'as it is.  Thus the grower outstanding balance will grow larger.',              ;
    'In some computer systems this is called CANCELLING A CHEQUE.',                  ;
    'You may re-run this cheque at a later time and include other transactions.','', ;
    'Do NOT use this option if you need to pay out at a different rate!','',         ;
	 'You may wish to run the Grower Ledger with FULL audit trail',                   ;
	 'before AND after you do this.  Remember to BACKUP!'})

	set cursor on

	in window aWin @ 6,2 winsay 'This option leaves the A/P Voucher Records and any'
   in window aWin @ 7,2 winsay 'references in the Scale Reciepts to this payment.'
   in window aWin @ 8,2 winsay 'Use this option if you just want to delay payment'
   in window aWin @ 9,2 winsay 'but you are NOT changing prices.'

	do while .t.
		msgLine('Enter parameter to Start Search for Cheque from')

		in window aWin @ 2,2  winsay 'Specific Cheque Only' winget cSeries ;
		 picture '@!'
		in window aWin @ 2,24+FLD_SERIES winget nCheque picture ;
		 numBlankPic(FLD_CHEQUE)

		in window aWin @ 3,2  winsay 'Grower:' winget nGrower ;
		 picture NumBlankPic( FLD_GROWER ) ;
		 LOOKUP( LU_GROWER, ;
'Enter a Grower ID here, if you wish to list the register for 1 grower ONLY')
		in window aWin @ 4,2  winsay 'From:' winget dFrom picture '@d' ;
       get_message "You can leave Chq# and Grower blank and key in a date.."
		READ

		do case
		case lastkey()==K_ESC
			exit
		case !empty(cSeries) .or. !empty(nCheque)
         Cheque->(OrdSetFocus(CHEQUE_CHEQUE_NO_ORD))
			Cheque->(dbSeek(cSeries+str(nCheque,FLD_CHEQUE),SOFTSEEK))
		case !empty(nGrower)
         Cheque->(OrdSetFocus(CHEQUE_GROWER_ORD))
			Cheque->(dbSeek( str(nGrower,FLD_GROWER),SOFTSEEK))
		otherwise
      	Cheque->(OrdSetFocus(CHEQUE_DATE_ORD))
			Cheque->(dbSeek( dtos( dFrom ),SOFTSEEK) )
		endcase

		if Cheque->(eof())
			Cheque->(dbGoTop())
		endif

		msgLine('[Enter] to Select a Cheque to Void')
		if CheqBrowse( nil, .t. )
			// we hit enter !
			if empty(Cheque->dateClear)
				nAmt := Cheque->amount
				cChequeId := Cheque->(PrettyChequeNo())
				nGrower   := Cheque->number

            InitDiagStatics()
            if Void_DoWeChkOver()
					VoidOrReissue( Cheque->series, Cheque->cheque, dVoidAt, .f. )
					if selectPrn("VOID.TXT")
						PRINT_ON RPT_OVERWRITE
						nuQprnOut( )
						nuQprnOut( shMDY(date()) )
						nuQprnOut( "Record of Voided Cheque:" )
						nuQprnOut( "Cheque # " + cChequeID )
						nuQprnOut( "Grower #" + str( nGrower, 6 )+' '+ NameOf(LU_GROWER, nGrower ) )
						nuQprnOut( "Amount  $"+str(nAmt,12,2))
						nuQprnOut( )
						nuQprnOut( "Date of Void is "+shMDY(dVoidAt) )
						nuQprnOut( )
						nuQprnOut( "Please check the grower ledger to inspect the effect of" )
						nuQprnOut( "this cheque on your statistics.  This has NOT changed" )
                  nuQprnOut( "any of the Voucher records and does NOT allow you to" )
                  nuQprnOut( "recalculate previously vouchered transactions!")
						nuQprnOut( )
						nuQprnOut( "Keep this Record" )

						PRINT_OFF RPT_COMPLETE_EJECT
					endif
				endif
			else
				waitInfo({'Can NOT void this Cheque'})
			endif
		endif
	enddo
	kill window aWin
	close databases
return( nil )

static function Void_DoWeChkOver()
	local aWin
	local lVoidIt := .f., lReturn := .f.
	local getList :={}
   local nAdvance := 0, nFinal := 0, nStdDeduct := 0
   local nValue := 0.00

	dVoidAt := date()

	// Does this Cheque Have any Weekly or Final?

	Account->( OrdSetFocus( ACCOUNT_CHEQUE_ORD ))
	Account->( dbSeek( Cheque->series + str( Cheque->cheque, FLD_CHEQUE )))
	do while Cheque->series == Account->series .and.  Cheque->cheque == Account->cheque .and. !Account->(eof())
		do case
      case Account->type == TT_BERRY_ADVANCE_1 .or. ;
			  Account->type == TT_BERRY_ADVANCE_2 .or. ;
			  Account->type == TT_BERRY_ADVANCE_3

			nAdvance++
         nValue += Account->DOLLARS

		case Account->type == TT_FINAL_BERRY
      	nFinal++
			nValue += Account->DOLLARS
      case Account->type == TT_STD_DEDUCTION
			nStdDeduct++
         nValue += Account->DOLLARS
      endcase
      Account->(dbSkip())
   enddo


   if nAdvance > 0 .or. nFinal > 0 .or. nStdDeduct > 0 .or. num2NotEqual0( nValue )

		WaitInfo({'This cheque seems to Refence Tickets.' ,                ;
                'It is OK for you to void the cheque - but you',         ;
                'will not be able to re-price these tickets','',         ;
                'The usual reason to do this is because you are',        ;
                'delaying payment to this grower.', '',                  ;
                ' # of Advance Vouchers='+var2char( nAdvance),           ;
                ' # of Final Vouchers  ='+var2char( nFinal ),            ;
                ' # of Coop deductions ='+var2char( nStdDeduct),         ;
                ' Total value of the above = $'+var2char( nValue )            })

	endif

	create window at 5,08,17,70 title 'Void this Cheque' to aWin
	display window aWin
	set cursor on

	msgLine('Do you want to void this cheque?')

	in window aWin @ 2,2 winsay 'Cheque is to Grower '+lstrim(Cheque->number)
	in window aWin @ 3,2 winsay NameOf(LU_GROWER,Cheque->number)
	in window aWin @ 4,2 winsay 'Cheque Number '+ Cheque->(PrettyChequeNo())+ ;
	  ' on '+shMDY(Cheque->date)
	in window aWin @ 5,2 winsay 'Amount '+ ;
	 transform(Cheque->amount, '9,999,999.99') ;
	 +' '+NameOf(LU_CURRENCY,Cheque->currency)
	in window aWin @ 7,2 winsay 'Void this Cheque?' winget lVoidIt picture 'Y'
	in window aWin @ 8,2 winsay 'Date Voided      ' winget dVoidAt ;
	 picture '@D' get_message ;
	 'Accounting Date for Void Cheque entry'

	if Cheque->void
		in window aWin @ 9,2 winsay 'Note this is an already VOIDED cheque'
	endif

	read


	if lastkey() <> K_ESC .and. !empty(dVoidAt) .and. lVoidIt
      if nAdvance > 0 .or. nFinal > 0 .or. nStdDeduct > 0 .or. num2NotEqual0( nValue )

	      if Yesno({'Are you sure you want to VOID this Cheque?', ;
                'This particular type of void leaves the tickets vouchered!' })
				lReturn := .t.
      	endif
      endif
	endif

	kill window aWin

Return( lReturn )


function VoidChequeDeleteAP()
	local aWin, getList :={}, cChequeID, nAmt
	local nGrower
	local cSeries, nCheque
	local dFrom

	if !openfile({ 'Product','Process', ;
			'VoidChq','Grower','Account','Cheque','Audit','Daily','BankRec'}, ;
	  DB_EXCLUSIVE)
		close databases
		return( nil )
	endif

	waitInfo({"This screen allows you to void cheques and deletes", ;
	 "the associated AP Vouchers.  It also resets the related tickets", ;
    "so that you can recalculate the rates of pay.", "", ;
    "You should ONLY do this to the MOST RECENT cheque for a grower!"})

	dFrom   := date()
	nGrower := 0
	cSeries := space(FLD_SERIES)
	nCheque := 0

	myBsgScreen( 'Void Cheque, associated Vouchers, reset Receipts' )
	create window at 6,10,17,68 title 'Select Cheque to Void' to aWin
	display window aWin
	in window aWin @ 6,2 winsay 'This option removes the A/P Voucher Records and'
   in window aWin @ 7,2 winsay 'any references in the Scale Tickets to this payment.'
   in window aWin @ 8,2 winsay 'Use this option if you need to re-price advances or'
   in window aWin @ 9,2 winsay 'or final pay rates on tickets.'

	set cursor on

	do while .t.
		msgLine('Enter parameter to Start Search for Cheque from')

		in window aWin @ 2,2  winsay 'Specific Cheque Only' winget cSeries ;
		 picture '@!'
		in window aWin @ 2,24+FLD_SERIES winget nCheque picture ;
		 numBlankPic(FLD_CHEQUE)

		in window aWin @ 3,2  winsay 'Grower:' winget nGrower ;
		 picture NumBlankPic( FLD_GROWER ) ;
		 LOOKUP( LU_GROWER, ;
'Enter a Grower ID here, if you wish to list the register for 1 grower ONLY')

		in window aWin @ 4,2  winsay 'From:' winget dFrom picture '@d' ;
       get_Message 'You can fill this in and leave the cheque or grower blank'

		READ

		do case
		 case lastkey()==K_ESC
			exit
		 case !empty(cSeries) .or. !empty(nCheque)
         Cheque->(OrdSetFocus(CHEQUE_CHEQUE_NO_ORD))
			Cheque->(dbSeek(cSeries+str(nCheque,FLD_CHEQUE),SOFTSEEK))
		 case !empty(nGrower)
         Cheque->(OrdSetFocus(CHEQUE_GROWER_ORD))
			Cheque->(dbSeek( str(nGrower,FLD_GROWER),SOFTSEEK))
		 otherwise
         Cheque->(OrdSetFocus(CHEQUE_DATE_ORD))
			Cheque->(dbSeek( dtos( dFrom ), SOFTSEEK ) )
		endcase
		if Cheque->(eof())
			Cheque->(dbGoTop())
		endif
		msgLine('[Enter] to Select a Cheque to Delete Traces')
		if CheqBrowse( nil, .t. )
			// we hit enter !
			if empty(Cheque->dateClear)
				nAmt      := Cheque->amount
				cChequeId := Cheque->(PrettyChequeNo())
				nGrower   := Cheque->number

				if Void_IsItNewestChq()    // also check if Advance1 & Advance2 for same ticket on this...will work but will trigger warnings
					VoidCheq_Unvoucher( Cheque->series, Cheque->cheque )
					if selectPrn("ZAPCHQ.TXT")
						PRINT_ON RPT_OVERWRITE
						nuQprnOut()
						nuQprnOut( shMDY(date()) )
						nuQprnOut( "Record of Voided Cheque:" )
						nuQprnOut( "Cheque # " +cChequeID )
						nuQprnOut( "Grower #"+ str(nGrower,10)+ '  '+ NameOf(LU_GROWER,nGrower) )
						nuQprnOut( "Amount  $" + str(nAmt,12,2) )
						nuQprnOut( )
						nuQprnOut( "Date Voided is "+shMDY(date()) )
                  nuQprnOut( "This has removed associated Voucher Records and reset any associated")
                  nuQprnOut( "Scale Receipts.")
						nuQprnOut( )
						nuQprnOut( "Please check the grower ledger to inspect the effect of" )
						nuQprnOut( "this cheque on your statistics." )
						nuQprnOut( )
						nuQprnOut( "Keep this Record" )

						PRINT_OFF RPT_COMPLETE_EJECT
					endif
				endif
			else
				waitInfo({'Can NOT void this Cheque-it has been cleared!', ;
                      'Cheque:' + Cheque->(PrettyChequeNo()), ;
                      'Cleared on: '+ shMdy( Cheque->dateClear ) })
			endif
		endif
	enddo
	kill window aWin
	close databases
return( nil )

/// <para>Also Sets the Diagnostic Variables</para>
static function Void_IsItNewestChq()
	local aWin
	local lVoidIt := .f., lReturn := .f.
	local getList :={}
	local aDBF
	local nRec
	local nGrower
	local nMoreRecent := 0
   local cMsg := ''
   local n
   local aTemp

   msgLine('Doing some serious thinking here...please hang on...')

   InitDiagStatics()

   // if we find ANY of these kinds of payments, we MAY need to check out whether
   // we are cancelled out EARLIER payments After we have paid out Later payments
   // We can have an Advance1 and Advance2 paid out on SAME ticket and same cheque
   // and that is actually OK....BUT we are still warning
   //
   // In MY view (BH) the users of this system should NOT be voiding cheques and
   // then recalculating them - that indicates that their business processes are
   // sloppy.  Of course, we need to allow for errors...
   //

	aDBF      := Cheque->(saveDBF())

	// Is this the LAST cheque for this guy?
	nRec    := Cheque->(recno())
	nGrower := Cheque->number  // the Grower Number

	Cheque->( OrdSetFocus( CHEQUE_GROWER_ORD ))
	Cheque->( dbSeek( str( nGrower, FLD_GROWER )))
	do while Cheque->number == nGrower .and. !Cheque->(eof())
		if Cheque->(recno()) > nRec
      	cMsg += 'Chq#'+Cheque->series+var2char( Cheque->cheque )+'  '
			nMoreRecent++
         aDiagNote := {'We seem to have a MORE recent Cheque for this Grower', ;
                       'See '+cMsg,  'you probably should not void this cheque'  }
			WaitInfo( aDiagNote )
		endif
		Cheque->(dbSkip())
	enddo

	Cheque->(restDBF( aDBF ))

   // now we check DO we have different advances that might be for same ticket...
   //  we do not fully check this...
	showProg('Acct')
   aDBF := Account->(saveDBF())

   Account->( OrdSetFocus( ACCOUNT_CHEQUE_ORD ))
   Account->( dbSeek( Cheque->series + str( Cheque->cheque, FLD_CHEQUE )))

   do while Cheque->series == Account->series .and. ;
            Cheque->cheque == Account->cheque .and.  !Account->(eof())

      for n := 1 to len( aDiagPayTypes )
      	// we do not worry about Payment Types that DO NOT relate to Tickets (e.g. Loans and miscellaneous deductions)
         //
      	if Account->type == aDiagPayTypes[ n, A_TT_TYPE_PAY ]
				aDiagPayTypes[ n, A_TT_COUNT ] ++
            if Account->date < aDiagPayTypes[ n, A_TT_EARLIEST_DATE ]
					aDiagPayTypes[ n,A_TT_EARLIEST_DATE ] := Account->date
            endif
            if Account->date > aDiagPayTypes[ n, A_TT_LATEST_DATE ]
					aDiagPayTypes[ n,A_TT_LATEST_DATE ] := Account->date
            endif
            do case
            case n == 6
            	nDiagFinal ++
            case n == 5
            	nDiagThird ++
            case n == 4
            	nDiagSecond ++
            otherwise
            	nDiagFirst ++
            endcase
         endif
      next
      Account->(dbSkip())
   enddo
	Account->(restDBF( aDBF ))

   lDiagMix := .f.

   if ( nDiagFinal  > 0 .and. ( nDiagThird > 0  .or. nDiagSecond > 0 .or. nDiagFirst > 0 ) )  .or. ;
      ( nDiagThird  > 0 .and. ( nDiagSecond > 0 .or. nDiagFirst > 0      )                 )  .or. ;
      ( nDiagSecond > 0 .and. ( nDiagFirst > 0 )                                  )

      // we have a mix of transaction types on this cheque - this is NOT necessarily
      // a problem, but it could be
      lDiagMix := .t.

   endif


	dVoidAt := date()

	create window at 5,08,19,70 title 'Void this Cheque' to aWin
	display window aWin
	set cursor on

	msgLine('Do you want to ZAP this cheque?')

	in window aWin @ 2,2 winsay 'Cheque is to Grower '+lstrim(Cheque->number)
	in window aWin @ 3,2 winsay NameOf(LU_GROWER,Cheque->number)
	in window aWin @ 4,2 winsay 'Cheque Number '+ Cheque->(PrettyChequeNo())+ ;
	  ' on '+shMDY(Cheque->date)
	in window aWin @ 5,2 winsay 'Amount '+ ;
	 transform(Cheque->amount, '9,999,999.99') ;
	 +' '+NameOf(LU_CURRENCY,Cheque->currency)
	in window aWin @ 7,2 winsay 'Void this Cheque?' winget lVoidIt picture 'Y' ;
    get_message "Do you want VOID this Cheque & reset associated vouchers & tickets?"

	in window aWin @ 8,2 winsay 'This will remove any associated AP Voucher records and'
   in window aWin @ 9,2 winsay 'reset associated tickets to unPaid by this cheque'

	if Cheque->void
		in window aWin @ 10,2 winsay 'Note this is a VOID cheque'
	endif

	if nMoreRecent > 0
		in window aWin @ 11,2 winsay 'There are MORE RECENT cheques for this Grower!'
      in window aWin @ 12,3 winsay cMsg
	endif
	read

	if lastkey() <> K_ESC .and. lVoidIt
		if nMoreRecent > 0
			lReturn :=  .f.
			if Yesno({'There seem to be more recent cheques for this grower!', ;
			          'This procedure will almost certainly cause you problems!', ;
			          'PLEASE call Crafted Industrial Software Ltd. before you', ;
			          'try this! There are '+var2char( nMoreRecent)+' NEWER cheques for this Grower!', ;
                   'see '+cMsg,'', ;
                   'Are you SURE you want to Void this Cheque ????' })

				lReturn := .t.

            aTemp :=  { 'We may void Cheque '+Cheque->(PrettyChequeNo()) + ' BUT -', ;
                'We are logging this situation!  It may cause you some real', ;
				    'problems - but still might work out. See Notes below-'}

            for n :=1 to len( aDiagPayTypes )
            	aadd( aTemp, '  '+ var2char( aDiagPayTypes[ n ] ) )
            next

				appError( APP_ERR_ZAP_CHQ_7, aTemp )

			  	LogAnEvent( EVT_TYPE_CHEQUE_DUBIOUS_TRY , ;
		           { 'We may void Cheque '+Cheque->(PrettyChequeNo()) + ' BUT -', ;
                   'There are '+var2char( nMoreRecent)+' NEWER cheques for this Grower!', ;
                   'Mix Status = '+var2char( lDiagMix ), ;
					    'Probably a BAD IDEA -see '+cMsg } )

			endif
      else
      	lReturn := .t.
		endif
	endif

	kill window aWin

return( lReturn )

///<para>This removes both the ACCOUNT.DBF record AND resets the
/// associated DAILY.DBF berry receipt pricing information.  It allows you
/// to REprice the Advance or Final Payment
/// </para>
static function voidCheq_UnVoucher( cSeries, nCheque )
	local lReturn := .f.
   local nAccount := 0, nAudit := 0, nDaily := 0
   local lPossibleErr := .f.
   local aAccountRecs := {}
   local aDBF
   local n

	if Cheque->series<>cSeries .or. Cheque->(eof()) .or. ;
			Cheque->cheque<>nCheque
		appError( APP_ERR_CHEQUE_LOCATE5, ;
			{'Restore Data', 'BAD-Not on correct Cheque!'})
	endif
	msgLine('Setting everything up...')

	showProg('Cheque')


	showProg('Acct')
   // this is very important for MINIMIZING ERROR REPORTS  !!!
   //   We must REMOVE Final Payments First, then 3rd advances, then 2nd Advances,
   //   then 1st Advance type transactions (actual 1st advance etc)
   // Note that the 3rd element in the aAccountRecs is REDUNDANT, I am only including
   // it for debugging
   Account->(OrdSetFocus( ACCOUNT_CHEQUE_ORD ))
   aDBF := Account->( saveDBF())
	Account->(dbSeek( cSeries+str( nCheque,FLD_CHEQUE),HARDSEEK))
	do while Account->series== cSeries .and. ;
				Account->cheque== nCheque .and. ;
				.not. Account->(eof())
      do case
      case Account->type == TT_FINAL_BERRY
      	aadd( aAccountRecs, { 0, Account->(recno()), Account->type } )    // Reset these FIRST
      case Account->type == TT_BERRY_ADVANCE_3
			aadd( aAccountRecs, { 1, Account->(recno()), Account->type } )   // Reset these SECOND
      case Account->type == TT_BERRY_ADVANCE_2
			aadd( aAccountRecs, { 2, Account->(recno()), Account->type } )   // Reset these THIRD
      case Account->type == TT_BERRY_ADVANCE_1
			aadd( aAccountRecs, { 3, Account->(recno()), Account->type } )   // Reset these FOURTH
		otherwise
	      aadd( aAccountRecs, { 4, Account->(recno()), Account->type } )   // Reset these LAST (likely NOT at all)
      endcase
   	Account->(dbSkip())
   enddo
   Account->( restDBF( aDBF ))

	CopyOneRec('Cheque','VoidChq')
	VoidChq->(EditByFlds())
	VoidChq->DATEVOID := date()
	VoidChq->note := 'Cheque Zapped!'

   aSort( aAccountRecs, NIL, NIL, { | aX,aY | aX[1] < aY[1] } )
	// Copy the Original to the CANCEL cheque file.
	// delete the related transactions with new cheque number

   // We used to do this:
	//		do while Account->series== cSeries .and. ;
	//				Account->cheque== nCheque .and. ;
	//			.not. Account->(eof())

   for n := 1 to len( aAccountRecs )
		Account->(dbGoTo( aAccountRecs[ n, 2 ] )) // the Record Number

		// search for Audit, then fix any Scale Receipt Records which are marked inappropriately
      Audit->(OrdSetFocus(AUDIT_ACCT_DAY_ORD))
		Audit->(dbSeek( str(Account->acct_uniq,FLD_DOCUMENT)))
		do while Audit->acct_uniq==Account->acct_uniq .and. !Audit->(eof())
			// now find the Daily Records
         Daily->(OrdSetFocus(DAILY_ID_ORD))
			Daily->(dbSeek( str(Audit->day_uniq, FLD_DOCUMENT) ))
			do while Audit->day_uniq==Daily->day_uniq .and. !Daily->(eof())

         	// These are the ONLY kinds of transactions that mark the Daily DBF records
            // (that is the Scale Receipt records)...

				do case
				case Account->type == TT_BERRY_ADVANCE_1 .or. ;
				     Account->type == TT_TIME_PREMIUM .or. ;
				     Account->type == TT_STD_DEDUCTION

					if Daily->adv_prid2 > 0 .or. Daily->post_bat2 > 0 .or.  ;
					   Daily->adv_prid3 > 0 .or. Daily->post_bat3 > 0 .or.  ;
                  Daily->fin_pr_id > 0 .or. Daily->fin_bat > 0

					   AppError( APP_ERR_ZAP_CHQ_1, {'Might be BAD-First Advance will be ZAPPED.', ;
					     'But LATER advances and or final are marked as paid...!', ;
					     'This may be a problem!', 'Grower No: '+lStrim(Daily->number),           ;
					     'Cheque=' + Account->series + lStrim( Account->cheque),                  ;
					     'Looking at Ticket # ' + Daily->depot + lstrim( Daily->recpt),           ;
						  'Advance 2 data (ID/Batch/Price): '+var2char(Daily->adv_prid2) + ' ' + var2char( Daily->post_bat2) + ' $'+var2char( Daily->adv_pr2), ;
						  'Advance 3 data (ID/Batch/Price): '+var2char(Daily->adv_prid3) + ' ' + var2char( Daily->post_bat3) + ' $'+var2char( Daily->adv_pr3), ;
						  'Final pay data (ID/Batch/Price): '+var2char(Daily->fin_pr_id) + ' ' + var2char( Daily->fin_bat)   + ' $'+var2char( Daily->fin_price), ;
					     'CHECK the GROWER LEDGER with FULL audit Trail!'                 })

                  lPossibleErr := .t.

            	endif

					Daily->adv_prid1  := 0
					Daily->post_bat1  := 0
					Daily->adv_pr1    := 0.00
					Daily->prem_price := 0.00

				case Account->type == TT_BERRY_ADVANCE_2
					if Daily->adv_prid3 > 0 .or. Daily->post_bat3 > 0  .or. ;
                  Daily->fin_pr_id > 0 .or. Daily->fin_bat > 0

					   AppError( APP_ERR_ZAP_CHQ_2, {'Might be Bad-Second Advance will be ZAPPED.', ;
					     'But 3rd advance or final shows as paid...', ;
					     'This may be a problem!', 'Grower No: '+lStrim(Daily->number),           ;
					     'Cheque=' + Account->series + lStrim( Account->cheque),                  ;
					     'Looking at Ticket # ' + Daily->depot + lstrim( Daily->recpt),           ;
						  'Advance 3 data (ID/Batch/Price): '+var2char(Daily->adv_prid3)+ ' ' + var2char( Daily->post_bat3) + ' $'+var2char( Daily->adv_pr3), ;
						  'Final pay data (ID/Batch/Price): '+var2char(Daily->fin_pr_id)+ ' ' + var2char( Daily->fin_bat) + ' $'+var2char( Daily->fin_price), ;
					     'CHECK the GROWER LEDGER with FULL audit Trail!'                 })

                  lPossibleErr := .t.

					endif
					Daily->adv_prid2  := 0
					Daily->post_bat2  := 0
					Daily->adv_pr2    := 0.00

				case Account->type == TT_BERRY_ADVANCE_3
					if Daily->fin_pr_id > 0 .or. Daily->fin_bat > 0
					   AppError( APP_ERR_ZAP_CHQ_3, {'Might be Bad-Third Advance will be ZAPPED.', ;
					     'But final shows as paid...', ;
					     'This may be a problem!', 'Grower No: '+lStrim(Daily->number),           ;
					     'Cheque=' + Account->series + lStrim( Account->cheque),                  ;
					     'Looking at Ticket # ' + Daily->depot + lstrim( Daily->recpt),           ;
						  'Final pay data (ID/Batch/Price): '+var2char(Daily->fin_pr_id)+ ' ' + var2char( Daily->fin_bat) + ' $'+var2char( Daily->fin_price), ;
					     'CHECK the GROWER LEDGER with FULL audit Trail!'                 })

                  lPossibleErr := .t.

					endif
					Daily->adv_prid3 := 0
					Daily->post_bat3 := 0
					Daily->adv_pr3   := 0.00

            case Account->type == TT_FINAL_BERRY
					Daily->fin_pr_id := 0
					Daily->fin_bat   := 0
					Daily->fin_price := 0
				endcase
            nDaily++
				Daily->(dbCommit())
				Daily->(dbSkip())
			enddo

         nAudit++
			Audit->(dbDelete())
			Audit->(dbSkip())
		enddo
      nAccount++
		Account->(dbDelete())
		Account->(dbCommit())

      // we are NOW using a FOR loop to locate the record
		// Account->(dbSkip())
   	//enddo

   next


	if Cheque->series<>cSeries .or. Cheque->(eof()) .or. ;
		Cheque->cheque<>nCheque
		appError( APP_ERR_CHEQUE_LOCATE6, ;
			{'Restore Data','BAD-Not on correct Cheque!'})
	endif
	Cheque->(dbDelete())
	Cheque->(dbCommit())

   if lPossibleErr
	  	LogAnEvent( EVT_TYPE_CHEQUE_VOID_REMOVE_AP_OH_NO, ;
			           { 'Cheque '+var2char( cSeries ) + var2char( nCheque)+' was voided.', ;
      	             'This process REMOVED the AP records - MAY BE ERRORS!', ;
						    'DailyReset='+var2char(nDaily) +' Deleted-Acct=' + var2char( nAccount ) + ' -Aud=' + var2char( nAudit ), ;
                      'Mixed Acct Tp='+var2char( lDiagMix) } )


   else
	  	LogAnEvent( EVT_TYPE_CHEQUE_VOID_REMOVE_AP, ;
			           { 'Cheque '+var2char( cSeries ) + var2char( nCheque)+' was voided.', ;
      	             'This process REMOVED the AP records!', ;
						    'DailyReset='+var2char(nDaily) +' Deleted-Acct=' + var2char( nAccount ) + ' -Aud=' + var2char( nAudit ), ;
                      'Mixed Acct Tp='+var2char( lDiagMix) } )
	endif

return( lReturn )

static function InitDiagStatics()
	aDiagPayTypes := {  { TT_TIME_PREMIUM    , 0,  ctod('12/12/2525'), ctod('') } , ;
                       { TT_STD_DEDUCTION   , 0,  ctod('12/12/2525'), ctod('') } , ;
                       { TT_BERRY_ADVANCE_1 , 0,  ctod('12/12/2525'), ctod('') } , ;
                       { TT_BERRY_ADVANCE_2 , 0,  ctod('12/12/2525'), ctod('') } , ;
                       { TT_BERRY_ADVANCE_3 , 0,  ctod('12/12/2525'), ctod('') } , ;
                       { TT_FINAL_BERRY     , 0,  ctod('12/12/2525'), ctod('') }     }

   aDiagNote      := {}
	nDiagFirst     := 0
	nDiagSecond    := 0
	nDiagThird     := 0
	nDiagFinal     := 0
	lDiagMix       := .f.
return( nil )

