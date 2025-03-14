//---------------------------------------------------------------------------
//  Application: Berry Payment System
//  Description: The Actual Cheque Reconcilliation
//   File Name: CHEQREC.PRG
//      Author: Bill Hepler
// Date created: 05-20-95              Date updated: þ05-20-95
// Time created: 07:54:15am            Time updated: þ07:54:15am
// Copyright: (c) 1995 by Bill Hepler
// Copyright: (c) 2017 by Crafted Industrial Software Ltd.
//--------------------------------------------------------------------------

	// Database File: D:\BLUEBERR\CHEQUE.DBF
	//   Last Update: 05/20/95
	//     # Records: 830
	//      # Fields: 10  Bytes/Record: 46
	// Field  FieldName  Type  Width  Decimals
	//   1    SERIES      C    002     000
	//   2    CHEQUE      N    006     000
	//   3    NUMBER      N    004     000
	//   4    DATE        D    008     000
	//   5    AMOUNT      N    010     002
	//   6    YEAR        N    004     000
	//   7    CHEQTYPE    C    001     000
	//   8    VOID        L    001     000
	//   9    DATECLEAR   D    008     000
	//  10    ISCLEARED   L    001     000
	//  11    CURRENCY    C    001     000   // July 96

#include "browser.ch"
#include "window.ch"
#include "BerryPay.ch"
#include "bsgstd.ch"
#include "inkey.ch"
#include "valid.ch"
#include "colors.ch"
#include "printer.ch"
#include "field.ch"
#include "indexord.ch"
#include "sysvalue.ch"
#include 'rpt.ch'

static oTb  := nil  // get rid of warning
static aWin := nil  //   ditto
static aRec
static nCheques := 0 , nAmount := 0.00
static nOpenBal, nCloseBal, nUnRecCheq, nUnRecDepo
static cOpenBal, cCloseBal, cUnRecCheq, cUnRecDepo
static dStatement

function CheqReconcile()
	local getList := {}
	local nChoice

	if !openfile({'Cheque','Grower','BankRec'},DB_EXCLUSIVE)
		 close databases
		 return( nil )
	endif

	nAmount := -9090909.88
	dStatement := date()

	myBsgScreen('Cheque Reconcilliation')

	create window at 4,3,16,65 title 'Reconcile' to aRec
	display window aRec
	set cursor on

	cOpenBal := cCloseBal := cUnRecCheq := cUnRecDepo := Space(30)
	nOpenBal := nCloseBal := nUnRecCheq := nUnRecDepo := 0.00

	if ! yesno({ ;
		'To reconcile the cheque register, you should have your', ;
		'bank statement in front of you.  On the next screen you', ;
		'will be shown a data entry form.  You will be asked to enter:', ;
		'  the opening balance on your bank statement', ;
		'  the deposits not recorded in this computer system', ;
		'  the outlays of cash not recorded in this system', ;
		'  and the closing balance from your bank statement.', ;
		'Then you will be shown the uncleared cheques and you should', ;
		'mark the cheques cleared on this bank statement.  The computer', ;
		'will sum the amount.  When you are done you can print reports', ;
		'on the cleared & uncleared cheques.   The last step then is to', ;
		'accept this reconciliation as correct.', ;
		'   - Remember to BACK UP your data BEFORE running this procedure!', ;
		'Do you want to reconcile your bank statement ?' })
			close databases
			return( nil )
	endif


	do while .t.
      BankRec->(OrdSetFocus(BANKREC_ACCOUNTING_DATE_ORD))
		BankRec->(dbGoBottom())
		if !BankRec->(eof())
			in window aRec @ 13,2 winsay 'Last Bank Rec was done '+ ;
				shMDY(BankRec->DateDone)+ ',  for '+shMDY(BankRec->AcctDate)+' Statement'
		endif

		in window aRec @10,2 winsay ;
			 'Input details from this months bank statement and the'
		in window aRec @11,2 winsay ;
			'computer will then show you the list of cheques to clear.'

		msgLine('Input details from this months bank statement')
		in window aRec @ 1,2 winsay 'Date of Bank Statement'
		in window aRec @ 1,50 winget dStatement picture '@d' when theDifference()

		in window aRec @ 2,2 winsay 'Opening Balance' winget cOpenBal
		in window aRec @ 2,50 winget nOpenBal picture '99,999,999.99' ;
			valid theDifference()

		in window aRec @ 3,2 winsay '+ Deposits     ' winget cUnRecDepo
		in window aRec @ 3,50 winget nUnRecDepo picture '99,999,999.99' ;
			valid theDifference()

		in window aRec @ 4,2 winsay '- Service etc. ' winget cUnRecCheq ;
			get_message ;
 'Input a description of Service Charges and other withdrawals from the account'
	  	in window aRec @ 4,50 winget nUnRecCheq picture '99,999,999.99' ;
			valid theDifference()

		in window aRec @ 5,2 winsay '- cleared from the Cheque Register'

		if str(nAmount,12,2) == str(-9090909.88,12,2)
			in window aRec @ 5,50 winsay  " to be calc'd"
		else
			in window aRec @ 5,50 winsay nAmount picture '99,999,999.99'
		endif

		in window aRec @ 6,50 winsay  '-------------'

		in window aRec @ 7,2 winsay 'Closing Balance' winget cCloseBal
		in window aRec @ 7,50 winget nCloseBal picture '99,999,999.99'   ;
			valid theDifference()

		read

		if lastkey() == K_ESC
			exit
		else
         BankRec->(OrdSetFocus(BANKREC_ACCOUNTING_DATE_ORD))
			if BankRec->(dbSeek( dtos(dStatement), HARDSEEK ))
				waitHand({'You have done a Bank Reconciliation as of this date!'})
				loop
			endif
		endif

		ChequesCleared()
		MarkCheques()

		theDifference()

		if str(nCloseBal,12,2)==str(CalcCloseBal(),12,2)
			nChoice := thinChoice({'Edit','Continue','X - eXit'})
			if nChoice == 2
				if RecPostIt( .t. )    // this marks Cheques as cleared !
					exit
				endif
			endif
		else
			if sysValue(SYS_FORCE_CHQ_REC_2_BALANCE)
				nChoice := bsgChoice({'You have not balanced.  You must balance', ;
					'in order to procede to the next step.', ;
					'You may either Edit the data entered or Exit'}, ;
					{'Edit','X - eXit'})
			else
				nChoice := bsgChoice({'You have not balanced.  However, you may', ;
					'procede to the next step. You may:', ;
					' Edit the data entered' , ;
					' Continue and mark cheques as cleared', ;
					' X - eXit' }, ;
					{'Edit','Continue','X - eXit'})

				if nChoice == 2
					if RecPostIt( .f. )    // this marks Cheques as cleared !
						exit
					endif
				endif

			endif
		endif
		if nChoice == 1
			loop
		endif
		exit
	enddo

	close databases

return( nil )

static function ToggleIt()
	if Cheque->isCleared
		Cheque->isCleared := .f.
		nAmount  -= Cheque->amount
		nCheques --
	else
		Cheque->isCleared := .t.
		nAmount  += Cheque->amount
		nCheques ++
	endif

	WinChat()
	oTb:refreshCurrent()
	oTb:stabilize()
	keyboard chr(K_DOWN)

return( SIG_CONTINUE  )

static function WinChat()

	in window aWin @ 2,14 winsay nCheques picture       '99,999'
	in window aWin @ 3, 8 winsay nAmount  picture '9,999,999.99'
	in window aWin @ 4, 8 winsay ;
		 CalcCloseBal() - nCloseBal picture '9,999,999.99'

//	in window aRec @ 4,50 winsay nAmount picture '99,999,999.99'

return( nil )

static function ChequesCleared()
	local aMsg

   Cheque->(OrdSetFocus(CHEQUE_RECONCILE_ORD))
	Cheque->(dbGoTop())
	aMsg := msgLine('Hang On...we are checking for cleared cheques')

	nCheques := 0
	nAmount  := 0.00
	do while !Cheque->(eof()) .and. empty(Cheque->dateClear)
		showProg( cheque->cheque )
		if Cheque->isCleared
			nCheques ++
			nAmount  += Cheque->amount
		endif
		Cheque->(dbSkip())
	enddo
	Cheque->(dbGoTop())
	rest_scr( aMsg  )

return( nil )

static function MarkCheques()

	create window at 2,40,6,60 title 'Cleared' to aWin
	winGetSet(aWin, WIN_COLOR, ColorStr(COLOR_ALT_WIN) )
	winGetSet(aWin, WIN_BORDER_COLOR, ColorStr( COLOR_MAIN_ALT_WINDOW_BORDER) )
	display window aWin

	in window aWin @ 2,2 winsay '# Cheques '
	in window aWin @ 3,2 winsay 'Amt $'
	in window aWin @ 4,2 winsay 'Out by'
	WinChat()

	// made wider
	oTb := tBrowCreate(10,2,20,77)
	tbColAdd( oTb, tbColCreate('Cheque#',{|| Cheque->Cheque }))
//	tbColAdd( oTb, tbColCreate('Ser',{|| Cheque->series }))
	tbColAdd( oTb, tbColCreate('Cur',{|| Cheque->currency }))
	tbColAdd( oTb, tbColCreate('Date',{|| shMDY(Cheque->date) }))
	tbColAdd( oTb, tbColCreate('Void',{|| iif(Cheque->Void,'VOID','   ') }))
//	tbColAdd( oTb, tbColCreate('Tp',{|| Cheque->cheqType }))
//	tbColAdd( oTb, tbColCreate('Grower',{|| Cheque->number }))
	tbColAdd( oTb, tbColCreate('Name', ;
		{|| NameOf(LU_GROWER, Cheque->number ) }))

//	tbColAdd( oTb, tbColCreate('Cleared On', ;
//		{|| iif( empty(Cheque->dateClear),space(12), ;
//		 padc( shMDY(Cheque->dateClear) ) ) }))

	tbColAdd( oTb, tbColCreate('Amount',{|| Cheque->Amount }))
	tbColAdd( oTb, tbColCreate('Clear', ;
		 {|| iif(Cheque->isCleared, chr(251),' ') }))

	tbMainCfg( oTb, CB_TITLE, 'Cheque Register' )
	tbMainCfg( oTb, CB_WHILE, {|| empty(Cheque->dateclear) })
	tbMainCfg( oTb, CB_GOBOTTOM, {|| bottomFinder() } )
	tbMainCfg( oTb, CB_GOTOP, {|| Cheque->(dbGoTop()),SIG_FORCE_REDRAW } )

	tbKeyCfg(oTb, { K_ENTER, {|| ToggleIt() }} )
	tbKeyCfg(oTb, { K_SPACE, {|| ToggleIt() }} )

   Cheque->(OrdSetFocus(CHEQUE_RECONCILE_ORD))
	msgLine('to Mark/unMark Cheques as cleared press [Space] or [Enter]')
	Cheque->(theBrowse( oTb ))

	kill window aWin

Return( nil )

static function bottomFinder()
	Cheque->(findLast(space(8)))
return( SIG_FORCE_REDRAW )

static function CalcCloseBal()
	local nReturn
	nReturn := round( nOpenBal + nUnRecDepo - nUnRecCheq - nAmount, 2)
return( nReturn )


static function RecPostIt( lBalanced )
	local lReturn := .f.
	local aW
	local lCleared   := .t.
	local lUnCleared := .f.
   local nChoice
	local getList := {}
   local aRpt

	create window at 8,12,18,60 title 'Complete Reconciliation' to aW
	display window aW
	set cursor on

	do while .t.
		msgLine('Print reconciliation report & clear the cheques')
		in window aW @ 2,2 winsay 'List Cleared Cheques  ' winget lCleared ;
			 picture 'Y'
		in window aW @ 3,2 winsay 'List Uncleared Cheques' winget lUncleared ;
			picture 'Y'

		if lBalanced
			in window aW @ 5,2 winsay 'At this point your reconciliation is in balance.'
		else
			in window aW @ 5,2 winsay 'At this point cheques are marked as cleared.'
		endif
		in window aW @ 6,2 winsay 'You should print out the reconciliation report,'
		in window aW @ 7,2 winsay 'and then mark these transactions as having been'
		in window aW @ 8,2 winsay 'cleared on the Statement Date, '+shMDY(dStatement)

		read
		if lastkey() <> K_ESC
			if selectPrn('CHEQREC.TXT')
				PRINT_ON RPT_OVERWRITE
				
				PrinterCtrl( PRN_CTRL_12_CPI )
				
            nuQprnOut()
            nuQprnOut( ' '+'Cheque Reconciliation Report for '+shMDY(dStatement) )
            nuQprnOut( ' '+shMDY(date())  )
            nuQprnOut( ' '+time()  )
            nuQprnOut()
            nuQprnOut()
				if lBalanced
               nuQprnOut( ' Opening Balance:    '+cOpenBal  +transform(nOpenBal,  '99,999,999.99') )
               nuQprnOut( '  + Deposits etc.    '+cUnRecDepo+transform(nUnRecDepo,'99,999,999.99') )
               nuQprnOut( '  - Bank Charges etc '+cUnRecDepo+transform(nUnRecCheq,'99,999,999.99') )
				endif
            nuQprnOut( '  - Cheques Cleared  '+space(30) +transform(nAmount,   '99,999,999.99') )

				if lBalanced
               nuQprnOut( '                     '+space(30) + '-------------' )
               nuQprnOut( ' Closing Balance     '+cCloseBal + transform(nCloseBal,'99,999,999.99') )
               nuQprnOut( )
               nuQprnOut( ' In Balance' )
               nuQprnOut( )
				endif

				if lCleared
               Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
					select Cheque
					set relation to str(Cheque->number,FLD_GROWER) into Grower
               OrdSetFocus(CHEQUE_RECONCILE_ORD)
					goto top

               //
               aRpt := {}
               Cheque->(bhRegiSetup( aRpt, .f. ))

               gRptInitHead()
               gRptGetSetHead( RPT_HEAD_TITLE, ;
                { 'Cleared Cheques for '+shMDY(dStatement) } )
               gRptGetSetHead( RPT_HEAD_WHILE_CONDITION, ;
                 {|| empty( Cheque->dateClear ) } )

					gRptPrintSize( aRpt )
               nuFormFeed()

               VoidChq->(gRptPrinter( aRpt ))
               PrinterCtrl( PRN_CTRL_10_CPI )

               nuFormFeed()

					set relation to
				endif

				if lUnCleared
					select Cheque
               OrdSetFocus(CHEQUE_RECONCILE_ORD)
					goto top

               aRpt := {}
               Cheque->(bhRegiSetup( aRpt, .f. ))

               gRptInitHead()
               gRptGetSetHead( RPT_HEAD_TITLE, ;
                { 'Uncleared Cheques for '+shMDY(dStatement) } )

               gRptGetSetHead( RPT_HEAD_FOR_CONDITION, ;
                 {|| !(Cheque->isCleared ) } )

               gRptGetSetHead( RPT_HEAD_WHILE_CONDITION, ;
                 {|| empty( Cheque->dateClear ) } )

					gRptPrintSize( aRpt )
               nuFormFeed()
               VoidChq->(gRptPrinter( aRpt ))
				endif

            PRINT_OFF  RPT_COMPLETE_EJECT

				nChoice := bsgChoice({ ;
					'If the reports have printed correctly, you may now', ;
					'complete the reconciliation of these cheques.  This', ;
					'procedure marks the cheques with the date of the bank', ;
					'statement and clears them.'}, ;
					{'Continue','Reprint', 'X-eXit'})

            do case
				case nChoice == 1
               cheque->(ordSetFocus( CHEQUE_RECONCILE_ORD ))
               Cheque->(dbGoTop())

               do while !Cheque->(eof()) .and. !empty(Cheque->dateClear)
						showProg( str(Cheque->cheque,FLD_CHEQUE) )
						if Cheque->isCleared
							Cheque->dateClear := dStatement
                     Cheque->(dbCommit())
                     Cheque->(dbGoTop())
                     loop
						endif
                  Cheque->(dbSKip())
               enddo

					// in exclusive !
					BankRec->(addRecord())
					BankRec->acctDate := dStatement
					BankRec->dateDone := date()

					if lBalanced
						BankRec->Note     := iif( empty(cCloseBal), cOpenBal, cCloseBal)
						BankRec->amount   := nAmount
					else
						BankRec->Note     := 'Not a full balance.'
						BankRec->amount   := nAmount
					endif

					waitInfo({'Procedure Completed!'})
					lReturn := .t.
				case nChoice == 2
					loop
				endcase
			endif
		endif
		exit
	enddo
	kill window aW

return( lReturn )


static function theDifference()
	do case
	case str(nAmount,12,2) == str(-9090909.88,12,2)
		in window aRec @ 8,43 winsay space(20)
	case str(nCloseBal,12,2)==str(CalcCloseBal(),12,2)
		in window aRec @ 8,43 winsay space(7)+padc('OK',13)
	otherwise
		in window aRec @ 8,43 winsay ;
			'Out by '+transform( CalcCloseBal() - nCloseBal ,'99,999,999.99')
	endcase
return( .t. )
