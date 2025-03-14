// Acct_reg.prg
// June 27, 1994
// Bill Hepler
// (c) 1994, 2011, 2014 by Bill Hepler
//          June 1999 - I put the explanation of what this does
//                      THis report does NOT look at unposted results
//          June 2000 - Revised for regular final payments
//          Aug  2007 - Revised to show more totals to make it clearer
//                      for cases where the Grower is NOT issued a
//                      cheque because of the Advance Owed.
//          Jun 2010  - Fix for Alaska Printing
//          Sep 2011  - A few minor page break problems fixed

//          July 2014  - GST related stuff needs fix and Audit needed.
//          Aug  2022  - Minor, but not full improvement to alignment, sort of bug in Print to HP Printers

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
#include 'price.ch'
#include "field.ch"
#include "indexord.ch"
#include "errors.ch"

#define  A_ACCOUNT_LENGTH   15
#define  A_ADV_1       1     // regular advance 1
#define  A_ADV_2       2     // regular advance 2
#define  A_ADV_3       3     // regular advance 3
#define  A_YEARLY      4     // yearly (final) special payments
#define  A_OTHER       5     // miscellaneous
#define  A_DEDUCT      6     // deductions
#define  A_UNP_WEEKLY  7     // expected due from unposted
#define  A_UNP_YEARLY  8     // expected due from unposted
#define  A_PAID        9     // Paid according to 1-6
#define  A_CHEQUES    10     // Cheques found, should match A_PAID !
#define  A_OWED       11     // Owed to Grower (posted)
#define  A_EQUITY1    12     // Equity Due Year x and earlier
#define  A_EQUITY2    13     // Equity Due All other years
#define  A_MARKET_DED 14     // Marketing Deduction
#define  A_GST_TAXES  15     // GST added July 2014

#define  DOLLAR_PIC   '99,999,999.99'
static aInfo := { ;
 'Regular 1st Advances (includes STD weekly deductions)', ;
 'Regular 2nd Advances  . . . . . . . . . . . . . . . .', ;
 'Regular 3rd Advances  . . . . . . . . . . . . . . . .', ;
 'Final Payouts . . . . . . . . . . . . . . . . . . . .', ;
 'PreSeason Advances-loans & Miscellaneous Payouts  . .', ;
 'Deductions & Offsets for PreSeason Advances . . . . .', ;
 'Unposted Advance Payments . . . . . . . . . . . . . .', ;
 'Unposted Final Payment  . . . . . . . . . . . . . . .', ;
 'Transaction shown as Paid (=Cheques)  . . . . . . . .', ;
 'Total of Cheques  . . . . . . . . . . . . . . . . . .', ;
 'Posted transaction Owed to Grower . . . . . . . . . .', ;
 'Equity 1  . . . . . . . . . . . . . . . . . . . . . .', ;
 'Equity 2  . . . . . . . . . . . . . . . . . . . . . .', ;
 'Standard Marketing Deduction (a STD weekly deduction)', ;
 'GST Taxes . . . . . . . . . . . . . . . . . . . . . .' }
//          2         3         4         4         5
//123456789 123456789 123456789 123456789 123456789 123456789

static dTo, nGrower,  nYear, nEqYear
static nLine := 0
static nPage
static bYear, bGrower, bEqYear
static nRadio

static aGrower[A_ACCOUNT_LENGTH],  aTotal[A_ACCOUNT_LENGTH]

function AcctRegister()
	local aWin, getList :={}, aRadio, n
	local lCancel := .f.
	local nCnt

	if !openMainStuff( DB_SHARED)
		close databases
		return( nil )
	endif

	dTo     := date()
	nEqYear := sysValue( SYS_CURRENT_YEAR) -5
	nYear   := sysValue( SYS_CURRENT_YEAR )
	nGrower := 0

	create radiobox 08,12 using { ;
	 'Summary - 1 Line / Grower', ;
	 'Detailed Grower Ledger   ', ;
	 'Show Full Audit Trail    '} title 'Type of Report' frame to aRadio
	nRadio := 1

	myBsgScreen( 'Grower Account Registers' )

	create window at 6,10,19,60 title 'Grower Ledgers' to aWin
	display window aWin
	set cursor on

	in window aWin @ 13,2 winsay 'This ledger includes ONLY posted transactions'
	in window aWin @ 14,2 winsay 'It does not include UNPAID berry receipts.'

	do while .t.
		msgLine('[Esc] to Exit')
		nRadio := RadioDo(aRadio,nRadio)
		if lastkey()==K_ESC
			exit
      endif

   	in window aWin @ 8,2  winsay 'Crop Year' winget nYear picture '@Z 9999' ;
   	 valid true( {|| nEqYear := iif(nEqYear<>0,nEqYear, ;
   	  iif(nYear<>0,nYear-5,sysValue(SYS_CURRENT_YEAR)-5) ) }) .and. ;
   	   true(DisplayGets(getList) ) ;
   	 GET_MESSAGE ;
   	 'Enter the Crop Year ONLY if you want the the Ledger for a single crop year'
   	in window aWin @ 9,2  winsay 'Effective' winget dTo picture '@d' ;
   	 GET_MESSAGE ;
   	 'Enter the Transaction Cut Off Date'
		in window aWin @10,2  winsay 'Specific Grower Only' winget nGrower ;
		 picture NumBlankPic( FLD_GROWER ) ;
       LOOKUP( LU_GROWER, ;
'Enter a Grower ID here, if you wish to print a ledger for 1 grower ONLY')

      in window aWin @11,2  winsay 'Equity Due from Year' winGet nEqYear ;
       picture '@Z 9999' GET_MESSAGE ;
       'Enter the year of Equity that is Due'
		READ

		do case
		 case lastkey()==K_ESC
		 	exit
		 case (empty(nEqYear) .and. !empty(nYear)) .or. (empty(nYear) .and. !empty(nEqYear))
			waitHand({'Equity year and Regular Year conflict'})
			loop
		endcase

		if selectPrn('LEDGER.TXT')
			lCancel := .f.
			aFill(aTotal,0.00)
			nPage := 1
			// nLine := 67 --- we do not need this June 2010

         Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
			if nGrower==0
				Grower->(dbGoTop())
				bGrower := {||.t.}
			else
				if !Grower->(dbSeek( str(nGrower,FLD_GROWER), HARDSEEK))
					waitInfo({'Grower is Not on file'})
					loop
				endif
				bGrower := {|| Grower->number == nGrower }
			endif
			if nYear==0
				bYear := { | nY | .t. }        // always true
			else
				bYear := {| nY | nY == nYear }
			endif
			if nEqYear==0
				bEqYear := { | nY | .t. }
			else
				bEqYear := { | nY | nY == nEqYear }
			endif

			PRINT_ON  RPT_OVERWRITE
			PrinterCtrl(PRN_CTRL_17_CPI)
			RepHead()

			nCnt := 0
			do while eval(bGrower) .and. !Grower->(eof())
				nCnt++
				msgLine(lstrim(Grower->number)+' '+grower->name)
				aFill(aGrower,0.00)                // we store grower results here
				do case
				 case nRadio==1
				 	SummaryPrinter()
				 case nRadio==2
				 	if nCnt > 1
				 		nPage++
				 		nuFormFeed()
				 		RepHead()
				 	endif
				 	DetailPrinter()
				 case nRadio==3
				 	if nCnt > 1
				 		nPage++
				 		nuFormFeed()
				 		RepHead()
				 	endif
				 	DetailPrinter()
				endcase

				for n:=1 to len(aGrower)              // accumulate totals
					aTotal[n] += aGrower[n]
				next
				Grower->(dbSkip())
				if inkey() == K_ESC
					if yesno({'Cancel this report run?'})
						lCancel := .t.
						nuQprnOut('')
						nuQprnOut('Report Printing Cancelled.....')
						exit
					endif
				endif
			enddo
			nLine ++

			do case
			case lCancel
				nuQQprnOut('..')
			case nRadio == 1
	      	PrnAtSay( nLine,  1  ,  'TOTALS' )
            PrnAtSay( nLine, 36  ,  aTotal[A_ADV_1] + ;
             aTotal[A_ADV_2] + aTotal[A_ADV_3] + ;
             aTotal[A_UNP_WEEKLY] , DOLLAR_PIC )
   	   	PrnAtSay( nLine, 50  ,  aTotal[A_YEARLY]+aTotal[A_UNP_YEARLY] , DOLLAR_PIC )
      		PrnAtSay( nLine, 64  ,  aTotal[A_DEDUCT]+aTotal[A_OTHER] , DOLLAR_PIC )
      		PrnAtSay( nLine, 88  ,  aTotal[A_EQUITY1]+aTotal[A_EQUITY2] , DOLLAR_PIC )
      		PrnAtSay( nLine,102  ,  aTotal[A_PAID] , DOLLAR_PIC )
      		PrnAtSay( nLine,116  ,  OutStanding(aTotal) , DOLLAR_PIC )
      	 case nGrower==0
     			// nLine := 67
     			nPage++
            nuFormFeed()
            RepHead()
      		PrnAtSay( nLine,1  ,  'TOTALS')
      		PrnAtSay( nLine,116  ,  OutStanding(aTotal) , DOLLAR_PIC )
      	endcase

			PRINT_OFF  RPT_COMPLETE_EJECT
   	endif
	enddo
	kill window aWin
	close databases
return( nil )

static function SummaryPrinter()
	TimeForHead()

	CalcPosted()
	CalcUnPosted()

	CheckCheques()
	PrnAtSay( nLine,1  ,  str(Grower->number,FLD_GROWER))
	PrnAtSay( nLine,6  ,  Grower->name)
   PrnAtSay( nLine, 36  ,  aGrower[A_ADV_1] + aGrower[A_ADV_2] + aGrower[A_ADV_3] ;
    + aGrower[A_UNP_WEEKLY] , DOLLAR_PIC )
	PrnAtSay( nLine, 50  ,  aGrower[A_YEARLY]+aGrower[A_UNP_YEARLY] , DOLLAR_PIC )
	PrnAtSay( nLine, 64  ,  aGrower[A_DEDUCT]+aGrower[A_OTHER] , DOLLAR_PIC )
	PrnAtSay( nLine, 88  ,  aGrower[A_EQUITY1]+aGrower[A_EQUITY2] , DOLLAR_PIC )
	PrnAtSay( nLine,102  ,  aGrower[A_PAID] , DOLLAR_PIC )
	PrnAtSay( nLine,116  ,  OutStanding(aGrower) , DOLLAR_PIC )
	nLine ++
	if str(aGrower[A_PAID],12,2) <> str(aGrower[A_CHEQUES],12,2)
		PrnAtSay( nLine,24  ,  'Actual Cheque do NOT balance Amount Paid !  Run Detailed Ledger')
		nLine ++
   else

	endif
return( nil )

static function DetailPrinter()
	local n

	// We should be at the Top of the Page when we come into this...
	// TimeForHead()
	// RepHead()

   if CalcPosted()
      PrnAtSay( nLine,   1  ,  padr('Totals for Posted Items',41) )
      PrnAtSay( nLine, 88  ,  aGrower[A_OWED] ;
			 , DOLLAR_PIC )
      PrnAtSay( nLine,116  ,  aGrower[A_OWED]- aGrower[A_PAID] , DOLLAR_PIC )
      nLine ++
   endif

	if CalcUnPosted() <> 0         // 123456789_123456789_123456789_123456789_
		PrnAtSay( nLine,   1  ,  padr('Payment Due to Grower for Unposted Items',41))
		PrnAtSay( nLine, 88  ,  aGrower[A_UNP_WEEKLY]+aGrower[A_UNP_YEARLY] ;
			 , DOLLAR_PIC )
		PrnAtSay( nLine,116  ,  aGrower[A_UNP_WEEKLY]+ ;
			 aGrower[A_UNP_YEARLY] , DOLLAR_PIC )
	endif
	nLine ++
	PrnAtSay( nLine,1  ,        padr('TOTALS',41))
   PrnAtSay( nLine,88  ,  aGrower[ A_ADV_1 ] + ;
      aGrower[ A_ADV_2 ] + ;
      aGrower[ A_ADV_3 ] + ;
      aGrower[ A_YEARLY ] + ;
		aGrower[ A_OTHER ] + aGrower[ A_DEDUCT ] + ;
	   aGrower[ A_UNP_WEEKLY ]+ aGrower[A_UNP_YEARLY] + ;
	   aGrower[ A_EQUITY1] + aGrower[A_EQUITY2] ;
	 , DOLLAR_PIC )

	PrnAtSay( nLine,102  ,  aGrower[A_PAID] , DOLLAR_PIC )
	PrnAtSay( nLine,116  ,  OutStanding(aGrower) , DOLLAR_PIC )
   nLine ++
   nLine ++
   TimeForHead( 2 )
	PrnAtSay( nLine,2  ,  'Cheques issued to Grower:')
	nLine ++
	CheckCheques()

   nLine++
   do case
   case str(aGrower[A_CHEQUES],12,2)==str(aGrower[A_OWED],12,2)
      PrnAtSay( nLine,24  ,  'All posted items have been paid out')
   case aGrower[A_OWED] > aGrower[A_CHEQUES] +0.01
      PrnAtSay( nLine,2  ,  ;
         'Next cheque to grower may include the outstanding amounts')
   case aGrower[A_OWED] + 0.01 < aGrower[A_CHEQUES]
      if aGrower[ A_UNP_WEEKLY ] + aGrower[ A_UNP_YEARLY ] > ;
            aGrower[ A_CHEQUES ] - aGrower[ A_OWED ]
         PrnAtSay( nLine,2  ,  ;
            'Grower has been advanced more money than posted transactions, '+ ;
            'but unposted payments (e.g. finals) are greater than advances')
      else
         PrnAtSay( nLine,2  ,   ;
            'Grower has been advanced more money than posted transactions, '+ ;
            'and now owes us more than the known value of berries recieved')
         nLine ++
         PrnAtSay( nLine,2  ,  ;
            'This situation often arises for pre-season advances (loans!).')
      endif
   endcase
   nLine++

   if nRadio==3 .or. nRadio==2  // added the 2 in Aug 2007
      nLine ++
      TimeForHead( 4 )  // put it all on the same page
		for n := 1 to len(aGrower)
			TimeForHead()
			PrnAtSay( nLine, 10  ,  aInfo[n])
         PrnAtSay( nLine, 65  ,  aGrower[n] , DOLLAR_PIC )
			nLine ++
		next
		nLine ++
   endif

   PrnAtSay( nLine,01  ,  'End of Report for this Grower')
   nuQprnOut(' ' )

return( nil )

static function CalcUnposted()
	// June 2000 - this includes Advances & Final Payments....
	local nPrice , nReturn

	nPrice := nReturn := 0.00

   Daily->(OrdSetFocus(DAILY_GROWER_ORD))
	if Daily->(dbSeek( str(Grower->number,FLD_GROWER), HARDSEEK ))
		showProg(str(Grower->number,FLD_GROWER)+' Unpost')

		// skip til we find one that applies
		do while Daily->number==Grower->number .and. !Daily->(eof())

			if Daily->date <= dTo .and. eval( bYear, year(Daily->date)) ;
               .and. (Daily->post_bat1==0 .or. Daily->fin_bat==0)

				if Daily->(fValidPrice( ) )
					nPrice := 0.00
					do case
               case Daily->post_bat1==0 .and. Daily->fin_bat==0
                  nPrice := Daily->(TotAdvPrice()) + ;
						              Daily->(AdvancePrem())

						aGrower[A_UNP_WEEKLY] += round(nPrice*Daily->net,2)
						nReturn += round(nPrice * Daily->net,2)

                  if Daily->(FinalPrice()) > Daily->(TotAdvPrice())
			       		nPrice := Daily->(FinalPrice()) - ;
                               Daily->(TotAdvPrice())

							aGrower[A_UNP_YEARLY] += round(nPrice*Daily->net,2)
							nReturn += round(nPrice * Daily->net,2)
						endif

					case Daily->fin_bat==0
                  nPrice := Daily->(FinalPrice()) - Daily->adv_pr1 ;
                     - Daily->adv_pr2 - Daily->adv_pr3

						if nPrice > 0
							aGrower[A_UNP_YEARLY] += round(nPrice*Daily->net,2)
							nReturn += round(nPrice * Daily->net,2)
						endif

               case Daily->post_bat1==0
                  nPrice := 0.00
                  // this will happen if we do NOT issue
                  //    an Advance and just do a FINAL payment

                  /* ------------------
						appError( APP_ERR_POSTING_BATCH_EXPECTED, ;
                     { 'We have a FIN_BAT, but not POST_BAT1', ;
							  ' for Daily Recpt:'+lStrim(Daily->recpt), ;
							  ' Grower:'+lStrim(Daily->number), ;
							  'Press Alt-C if this message comes up a lot'})
                  */
					endcase
				endif
			endif
			Daily->(dbSkip())
		enddo
	endif

return( nReturn )

static function CheckCheques( )
   local  nCheques := 0

   Cheque->(OrdSetFocus(CHEQUE_GROWER_ORD))
	if Cheque->(dbSeek( str(Grower->number,FLD_GROWER), HARDSEEK ))
		showProg('Cheques')
	endif

   do while Cheque->number==Grower->number .and. !Cheque->(eof())
   	if ( eval( bYear, Cheque->year) .or. ;
   	 (eval( bEqYear, Cheque->year) .and. Cheque->cheqType==CHEQUE_TYPE_EQUITY )) ;
   	   .and. Cheque->date <= dTo

	   	aGrower[A_CHEQUES] += Cheque->amount
   		nCheques ++
   		if nRadio <> 1
				Prn1Cheq()
			endif
      endif
	   Cheque->(dbSkip())
   enddo
   if nRadio <> 1 .and. nCheques > 0
   	PrnAtSay( nLine,01  ,  'Total of '+lStrim(nCheques)+' cheques shown:')
		PrnAtSay( nLine,102  ,  aGrower[A_CHEQUES] , '99,999,999.99')
		nLine ++
	endif
return( nil )

static function Prn1Cheq()
	TimeForHead()
	PrnAtSay( nLine,10  ,  shMDY(Cheque->date))
	PrnAtSay( nLine,22  ,  Cheque->(PrettyChequeNo()))
	PrnAtSay( nLine,34  ,  NameOf(LU_CHEQUE_TYPE,Cheque->Cheqtype))
	PrnAtSay( nLine,50  ,  str(Cheque->year,4))
	PrnAtSay( nLine,60   ,  Cheque->amount , '99,999,999.99')
	PrnAtSay( nLine,75  ,  iif(Cheque->void,'VOID', NameOf(LU_CURRENCY,Cheque->currency) ))
	nLine ++
return( nil )

static function CalcPosted()
   local lReturn := .f., cCheque, nAmt

   Cheque->(OrdSetFocus(CHEQUE_CHEQUE_NO_ORD))
   Account->(OrdSetFocus(ACCOUNT_NUMBER_ORD))
	Account->(dbSetRelation('Cheque',{|| Account->series + str(Account->cheque,FLD_CHEQUE)}))

	if Account->(dbSeek( str(Grower->number,FLD_GROWER),HARDSEEK))
		showProg('Daily..')
	endif
	do while Account->number==Grower->number .and. !Account->(eof())
		if (eval(bYear, Account->year)  .or.  ;
		 (Account->type==TT_EQUITY .and. eval(bEqYear,Account->year)) ) ;
		 .and. Account->date <= dTo
		 	TimeForHead()
		 	do case
		 	case (Account->type ==TT_DEDUCT .and. Account->class== D_CL_COOP_CLEAN) ;
           .or. Account->type==TT_BERRY_ADVANCE_1  ;
           .or. Account->type==TT_TIME_PREMIUM ;
           .or. Account->type==TT_STD_DEDUCTION

            aGrower[A_ADV_1] += Account->dollars

            if Account->type == TT_STD_DEDUCTION
               aGrower[A_MARKET_DED] += Account->dollars
            endif

         case Account->type==TT_BERRY_ADVANCE_2

            aGrower[A_ADV_2] += Account->dollars

         case Account->type==TT_BERRY_ADVANCE_3

            aGrower[A_ADV_3] += Account->dollars

			case Account->type==TT_FINAL_BERRY
		 		//case Account->type==TT_SPECIAL_BERRY .or. ;
			 	//		 Account->type==TT_SPECIAL_CONTAINER

		 	 	aGrower[A_YEARLY] += Account->dollars

		 	 case Account->type ==TT_EQUITY .and. Account->year==nEqYear
		 	 	aGrower[A_EQUITY1] += Account->dollars
          case Account->type ==TT_EQUITY
          	aGrower[A_EQUITY2] += Account->dollars
			 case Account->type == TT_GST_TAX
			 	aGrower[A_GST_TAXES] += Account->dollars
		 	 case Account->dollars > 0
		 	 	aGrower[A_OTHER] += Account->dollars
		 	 otherwise
		 	 	aGrower[A_DEDUCT] += Account->dollars
		 	endcase
		 	nAmt := Account->dollars
         if str(nAmt,12,2) <> str(0,12,2)
            lReturn := .t.
         endif

         aGrower[A_OWED] += Account->dollars

			if nRadio <> 1  // We need the Details
				PrnAtSay( nLine, 1  ,  shMDY(Account->date))
				if !empty(Account->acct_uniq)
					PrnAtSay( nLine,16  ,  str(Account->acct_uniq,FLD_AD_LINK))
				endif

				// Sep 99 - made a little easier to read
				do case
				case Account->type==TT_DEDUCT
					PrnAtSay( nLine,32  ,  'Deduction')
					PrnAtSay( nLine,43  ,  NameOf(LU_DEDUCTION_CLASS,Account->class))
            case Account->type==TT_BERRY_ADVANCE_1 .or. ;
                 Account->type==TT_BERRY_ADVANCE_2 .or. ;
                 Account->type==TT_BERRY_ADVANCE_3
					// more info Sep 99
					PrnAtSay( nLine,32  ,  NameOf(LU_SHORT_TRANSACTION_TYPE,Account->type) ;
					 + ' '+Account->product+'/'+Account->process )
				case Account->type== TT_FINAL_BERRY
					// more info Sep 99
					PrnAtSay( nLine,32  ,  NameOf(LU_SHORT_TRANSACTION_TYPE,Account->type) ;
					 + ' '+Account->product+'/'+Account->process )
				otherwise
					PrnAtSay( nLine,32  ,  NameOf(LU_TRANSACTION_TYPE,Account->type) )
				endcase

				if Num2NotEqual0(Account->lbs) .and. Num3NotEqual0( Account->u_price)
					PrnAtSay( nLine,70  ,  transform(Account->lbs,'9,999,999') )
					//                                             123456789
					// note that we display to 3 digits....Nov 15/94
					PrnAtSay( nLine,80  ,  padl('$'+alltrim(str(Account->u_price,8,3)),7) )
				endif
				PrnAtSay( nLine, 88  ,  Account->dollars , DOLLAR_PIC )
			endif
			cCheque := ''
			do case
			 case !empty(Account->cheque) .and. Cheque->(eof())
			 	cCheque := 'ERROR'
			 	nLine ++
			 case !empty(Account->cheque) .and. Cheque->date <= dTo
				aGrower[A_PAID] += Account->dollars
				cCheque := Account->(PrettyChequeNo())
				nAmt  := 0
			endcase
			if nRadio <> 1
            PrnAtSay( nLine,106  ,  cCheque )
            PrnAtSay( nLine,116  ,  nAmt , DOLLAR_PIC )
            nLine ++
			endif

			if !empty(Account->desc) .and. nRadio <> 1
				PrnAtSay( nLine,32  ,  Account->desc )
				nLine ++
			endif

			if nRadio == 3
				ShowProof()
			endif
		endif
		Account->(dbSkip())
	enddo
   Account->(dbClearRelation())

return( lReturn)

static function ShowProof()
	local nWho
	local aAcctRecs := {}
	local aDBF
	local lMasterIsGST := .f.
	local dDate
	local lAudAcctPrn := .f.

	nWho  := Account->number
	dDate := Account->date

	if Account->type == TT_GST_TAX
		lMasterIsGST := .t.
	endif

	if !empty(Account->acct_uniq)   // Older version data....
		if Account->type $ ACCT_ASSOC_RECS_DAILY_TYPES
			Audit->(OrdSetFocus(AUDIT_ACCT_DAY_ORD))
			Daily->(OrdSetFocus(DAILY_ID_ORD))
			Audit->(dbSetRelation('Daily',{||str(Audit->day_uniq,FLD_AD_LINK)}) )

			if Audit->(dbSeek( str(Account->acct_uniq,FLD_AD_LINK),HARDSEEK))
				do while Audit->acct_uniq==Account->acct_uniq .and. !Audit->(eof())
					TimeForHead()
					do case
					case Daily->(eof())
						PrnAtSay( nLine,10  ,  'No Daily Record on File' )
						nLine ++
					case Daily->number <> nWho
						showProg('Dupes..')
					otherwise
						PrnAtSay( nLine,10  ,  shMDY(Daily->date) )
						PrnAtSay( nLine,26  ,  str(Daily->recpt,FLD_RECPT) )
						// Nov 2001 added
						PrnAtSay( nLine,26+FLD_RECPT  ,  Daily->recptltr )

						// Modified Sep 99
						PrnAtSay( nLine,36  ,  'Berry: '+ Daily->product        )
						PrnAtSay( nLine,48  ,  'Proc: ' + Daily->process        )
						PrnAtSay( nLine,59  ,  'Gr: ' + str(Daily->grade,1)     )
						PrnAtSay( nLine,72  ,  'Net:   '+ str(Daily->net,7)     )
						//	PrnAtSay( nLine,108  ,  iif(!empty(+Daily->premium),'Prem','') )
						nLine ++
					endcase
					Audit->(dbSkip())
				enddo
			else
				PrnAtSay( nLine,10  ,  'Daily Transactions expected, but not found' )
				nLine ++
			endif
		endif
		// This IS not a case statement on purpose.
		//    We COULD allow for Account records to be used ALSO

		if Account->type $ ACCT_ASSOC_RECS_OTHER_ACCT_RECS
			AudAcct->(OrdSetFocus( AUDACCT_MASTER_CHILD ))
			// we are finding the Children
			if AudAcct->(dbSeek( str(Account->acct_uniq,FLD_AD_LINK),HARDSEEK))
				aAcctRecs := {}
				do while AudAcct->acct_uniq==Account->acct_uniq .and. !AudAcct->(eof())
					aadd( aAcctRecs, AudAcct->acct_child )
					AudAcct->(dbSkip())
				enddo
				if len( aAcctRecs ) > 0
					aDBF := Account->(saveDBF())
					PrnAtSay( nLine, 8 , 'Shows linked Transactions (children):')
					nLine++
					Account->(ordSetFocus( ACCOUNT_LINK_ORD ))

					RelatedAcctRecs( aAcctRecs, lMasterIsGst, dDate )

					Account->(restDBF( aDBF ))
					lAudAcctPrn := .t.
				endif
			endif
			AudAcct->(OrdSetFocus( AUDACCT_CHILD_MASTER ))

			if AudAcct->(dbSeek( str(Account->acct_uniq,FLD_AD_LINK),HARDSEEK))
				aAcctRecs := {}
				// we are finding the Masters (probably should only be 1...
				do while Account->acct_uniq==AudAcct->acct_child .and. !AudAcct->(eof())
					aadd( aAcctRecs, AudAcct->acct_uniq)
					AudAcct->(dbSkip())
				enddo
				// This is the same as Above except as notes
				if len( aAcctRecs ) > 0
					aDBF := Account->(saveDBF())
					PrnAtSay( nLine, 8 , 'Shows linked Transactions (m):')
					nLine++
					Account->(ordSetFocus( ACCOUNT_LINK_ORD ))

					RelatedAcctRecs( aAcctRecs, lMasterIsGst, dDate )

					Account->(restDBF( aDBF ))
					lAudAcctPrn := .t.
				endif
			endif
			if lAudAcctPrn
				nLine++     // ease of reading
			endif
		endif
	endif
return( nil )


static function TimeForHead( nSub)
	DEFAULT nSub TO 0

   if NearPageBottom( 7 + nSub )
   	nPage++
      nuFormFeed()
      RepHead()
   endif

return( nil )

static function RepHead()
	local cHeading

	PrinterCtrl(PRN_CTRL_17_CPI)
	if nRadio==1
		cHeading := iif(nYear<>0,'Crop Year '+str(nYear,4),'')+ ;
		 '   ' + iif(nEqYear<>0,'Equity Year '+str(nYear,4),'') + ;
		 '  Up to '+shMDY(dTo)

		PrnAtSay(  1,0  ,  ;
		 padr(shMDY(date()),15)+padc( 'Grower Ledger',100)+ ;
		 padl('Page'+str(nPage),15)                )
		PrnAtSay(  2,0  ,  padc(cHeading,130)      )

		PrnAtSay(  4, 37  ,  '----   Due to Grower  -----' )
		PrnAtSay(  4, 68  ,  'Deductions'         )
      PrnAtSay(  4,116  ,  padl('NET',14)       )
      PrnAtSay(  5,  2  ,  'Grower'        )
      PrnAtSay(  5, 36  ,  padl('Advance',13) )
      PrnAtSay(  5, 50  ,  padl('Yearly',13)  )
      PrnAtSay(  5, 64  ,  padl('and Other',13) )
      PrnAtSay(  5, 88  ,  padl('Equity',13)    )
      PrnAtSay(  5,102  ,  padl('Paid',13)      )
      PrnAtSay(  5,116  ,  padl('OUTSTANDING',13))
      nLine := 7
   else
   	PrnAtSay(   1,5  ,  TheClientName( ) )
	   PrnAtSay(   1,90  ,  "Account Ledger" )
   	PrnAtSay(   1,122  ,  "Page"+str(nPage,4) )

		PrnAtSay(   2,5  ,  sysValue(SYS_ACTUAL_ADDRESS1) )
		if nYear <> 0
			PrnAtSay(   2,90  ,  'CROP YEAR '+str(nYear,4) )
		else
			PrnAtSay(   2,90  ,  'ALL CROP YEARS' )
		endif
		PrnAtSay(   3,5  ,  sysValue(SYS_ACTUAL_ADDRESS2) )
		PrnAtSay(   4,5  ,  sysValue(SYS_ACTUAL_ADDRESS3) )

	   PrnAtSay(   4,90  ,  "As of "+shMDY(dTo) )

      PrnAtSay(   7,10  ,  Grower->name )
      PrnAtSay(   7,90  ,  'Grower No: '+lStrim(Grower->number) )
      PrnAtSay(   8,10  ,  Grower->street )
      if !empty( Grower->street2)
         PrnAtSay(   9,10  ,  Grower->street2 )
         PrnAtSay(  10,10  ,  alltrim(Grower->city)+' '+alltrim( Grower->prov)+ ;
          '  '+alltrim( Grower->pcode ) )
      else
         PrnAtSay(   9,10  ,  alltrim(Grower->city)+' '+Grower->prov )
         PrnAtSay(  10,10  ,  Grower->pcode )
      endif

      PrnAtSay(  12,16  ,  'Link to' )
      PrnAtSay(  12,84  ,  'Unit' )
      PrnAtSay(  12,88  ,  padl('Owed to',13) )
      PrnAtSay(  12,106  ,  'Cheque #' )
      PrnAtSay(  13,16  ,  "Daily Recpt" )
      PrnAtSay(  13,75  ,  'Lbs' )
      PrnAtSay(  13,83  ,  'Price' )
      PrnAtSay(  13,88  ,  padl('Grower',13) )
      PrnAtSay(  13,106  ,  '(if paid)' )
      PrnAtSay(  13,116  ,  padl('OUTSTANDING',13) )
      nLine := 15
   endif

return( nil )

static Function OutStanding( aRay )
	//either grower or Total !
   local nReturn
   nReturn :=  aRay[A_ADV_1] + aRay[A_ADV_2] +  aRay[A_ADV_3] + ;
        aRay[A_YEARLY] + aRay[A_OTHER] + aRay[A_DEDUCT] + ;
        aRay[A_EQUITY1] + aRay[A_EQUITY2] ;
           - aRay[A_PAID] + ;
        aRay[A_UNP_WEEKLY] + aRay[A_UNP_YEARLY]

return( nReturn )


static Function RelatedAcctRecs( aAcctRecs, lMasterIsGst, dDate )
	local n

	for n := 1 to len( aAcctRecs )
		TimeForHead()
		if Account->(dbSeek( str( aAcctRecs[ n], FLD_DOCUMENT )))
			if Account->date <> dDate
				// this will not usually print....usually the date will be the SAME!
				PrnAtSay( nLine,10  ,  shMDY( Account->date) )
			endif
			PrnAtSay( nLine,24  , str( Account->acct_uniq,FLD_DOCUMENT) )
			PrnAtSay( nLine,36  , Account->type +'  '+Account->product )
			PrnAtSay( nLine,48  , padr(NameOf( LU_SHORT_TRANSACTION_TYPE, Account->type ),22) )

			PrnAtSay( nLine,72  ,  DollarStr( Account->dollars, 14)  )
			do case
			case lMasterIsGst
				PrnAtSay( nLine,88  ,  DollarStr( Account->gst_est, 12)  + '=est GST' )
			case Account->type == TT_GST_TAX
				PrnAtSay( nLine,88  ,  DollarStr( Account->nongst_est, 12)  + '=est nonGST' )
			endcase

			if !empty( Account->desc )
				nLine ++
				PrnAtSay( nLine,36  , Account->desc )
			endif
		else
			PrnAtSay( nLine,10 , 'Can NOT find ACCOUNT transaction#='+lStrim( Account->Acct_uniq ))
		endif

		nLine++
	next
return( nil )
