// weekstat_1_old.prg
// weekly Statements (i.e. regular advance)
// June 16, 1994
// Totally re-written for Bill Hepler
//  July 4, 1994  changed again, because I change the audit trail...
//   either Prints for 1 grower or all, effective Charges of a certain date
//   looks at MOST WEEKLY recent cheque !

// June 95 - quality discount is NOT used any more, but its still here
//           for prior years.  Can be eliminated in future.

// July 96 - reWritten, new grades
// June 99 - reWritten, different stuff, quite a bit
//           simplified format a bit (from programmers point of view)


// June 99 - The process of producing this statement has been
//           evolutionary.  I would do it in a simpler way if I
//           had time now, but its in the state its in & seems
//           to work correctly.

// June 2000 - now re-written again
// Nov  2001 - re-written again to deal with MULTI-ADVANCE
//             and big dollars
// Aug  2007 - Minor Change to show letters for reverses etc.
// July 2009 - Change to fix problem, on advances there can be
//             Multiple Final Prices, we now check for this, and do
//             not show a final price if there are more than one
//             *** This is mainly an issue when Final Prices are keyed in ***
//             We also allow you not to print this.

// April 2019 Changes to Allow for New Process Naming -- NOT DONE (as Not Determined to be Necessary
//            See WeekStatOldRev()
// May 2020   Improve error message.

#include 'printer.ch'
#include 'sysvalue.ch'
#include 'inkey.ch'
#include 'BerryPay.ch'
#include 'bsgstd.ch'
#include 'window.ch'
#include 'valid.ch'
#include 'account.ch'
#include 'contain.ch'
#include 'price.ch'
#include "field.ch"
#include "indexord.ch"
#include 'errors.ch'


#define  BALANCE_START_COL       29       // actually start at 39
#define  BALANCE_INCREMENT_COL   10

// Advance & Final have Same Structure.

#define   A_AF_ID            1      // Unique 1

#define   A_AF_ADVANCE_NO    2      // Nov 2001 - Unique 5 / Sort 5



#define   A_AF_BERRY         3      //           Sort 1
#define   A_AF_PROCESS       4      //           Sort 2
#define   A_AF_GRADE         5      // Unique 2  Sort 3
#define   A_AF_FROM          6      //           Sort 4
#define   A_AF_TO            7
#define   A_AF_LBS           8
#define   A_AF_PAID          9
#define   A_AF_RECORDS      10      // does nothing actually
#define   A_AF_ADVANCE_RATE 11      // Unique 3
#define   A_AF_FINAL_RATE1  12      // Unique 4
#define   A_AF_FINAL_RATE2  13          // added July 2009
#define   A_AF_FINAL_MULTI  14          // added July 2009

// Relates to A_AF_ADVANCE_NO:
#define   AFA_UNKNOWN_PAYTYPE     0   //  not an Advance
#define   AFA_ADVANCE_1_PAYTYPE   1   //  1st Adv including Time Premium etc.
#define   AFA_ADVANCE_2_PAYTYPE   2   //  2nd Advance
#define   AFA_ADVANCE_3_PAYTYPE   3   //  3rd Advance
#define   AFA_FINAL_PAYTYPE       4   //  Final Payment
#define   AFA_SPECIAL_PAYMENT     5   //  Special Payment

#define A_AF_STRU {0, AFA_UNKNOWN_PAYTYPE, ;
        '','',0,date()+2000, date()-2000, 0, 0.00, 0,0.00,0.00,0.00, .f.}

// Premium
#define   A_PREM_STRU { '','', date()+2000, date()-2000, 0, 0.00, 0, 0.00 }
#define   A_PREM_BERRY     1        // Unique 1   Sort 1
#define   A_PREM_PROCESS   2        // Unique 2   Sort 2
#define   A_PREM_FROM      3        //            Sort 3
#define   A_PREM_TO        4
#define   A_PREM_LBS       5
#define   A_PREM_PAID      6
#define   A_PREM_RECORDS   7
#define   A_PREM_RATE      8        // Unique 3

// Deductions & Miscellaneous
//  just have the Record Number in Account....

static aBott[4], nLine, nPage, lPremMess, lAnyPrem
static dDate,nYear
static aContainer

// the Current Cheque (if any)
static cCurrency,dCheqDate

static aAdvance       // Array of Advance rates
static aPremium       // Array of Premium rates
static aMisc          // Any Account->recno() except Deductions, Weekly, Premium
static aDeduct        // Deductions (Account->recno())
static aDaily  := {}  // Daily->recno() reference by Advances & Premiums

static nOwed

static aBalance[ MAX_NO_OF_GRADES ]
static aCurrent[ MAX_NO_OF_GRADES ]

// Cross Check to Make Sure we are reasonable.
static nDaily4Week, nAcct4Daily, nAcct4Misc, nAcct4Cheque
   // Cheque->amount = nDaily4Week + nAcct4Misc
   // Cheque->amount = nAcct4Cheque
   // nAcct4Daily    = nDaily4Week

static nAdvance := 0  // what Advance Number is this Paying...should NOT be zero
static lShowFinal

function WeekStat_1_Old()                                       // was weekStat_Old()
	local aWin, getList :={},nGrower, n, nCopies
	local nChoice
	local cGroStatFor     := GRO_STATEMENT_FOR_WEEKLY
	local nStatementFmtID := WEEK_STATEMENT_FORMAT_1_OLD


	myBsgScreen('Print Old Weekly (Regular Advance) Statements')
   msgLine('Finding the date of last Advance run....')

   if ! open4ChequeRun( DB_SHARED )
		close databases
		return( nil )
	endif

   lShowFinal := sysValue( SYS_WEEK_STATEMENT_SUMMARY_FP )
	nCopies    := sysValue(SYS_DEFAULT_NO_STATEMENT_COPIES)
	nYear      := sysValue(SYS_CURRENT_YEAR)
	lPremMess  := .f.                                    // sysValue(SYS_DEFAULT_PREMIUM_MSG)
	nGrower    := 0

   aFill(aBott,space( FLD_STATEMENT_NOTES ))
   aBott[1] := padr( sysValue( SYS_DEFAULT_ADV_STATEMENT_LINE1 ),FLD_STATEMENT_NOTES)
   aBott[2] := padr( sysValue( SYS_DEFAULT_ADV_STATEMENT_LINE2 ),FLD_STATEMENT_NOTES)

   Cheque->(OrdSetFocus(CHEQUE_DATE_ORD))
	Cheque->(dbSetFilter( {|| Cheque->cheqType == CHEQUE_TYPE_WEEKLY }))
	Cheque->(dbGoBottom())
	dDate := Cheque->date                         // date of last cheque run
	Cheque->(dbClearFilter( ))

   create window at 4, 8,20,72 title 'Weekly Statement ' + var2char( nStatementFmtID )+'. ' + ;
                StatementDesc( cGroStatFor, nStatementFmtID ) to aWin

	display window aWin
	set cursor on
	in window aWin @ 02,45 winsay      'This may give'
	in window aWin @ 03,40 winsay 'misleading results'
	in window aWin @ 04,46 winsay       'on backdated'
	in window aWin @ 05,47 winsay        'statements.'

	in window aWin @ 07,41 winsay  'This statement is'
	in window aWin @ 08,47 winsay        'intended to'
	in window aWin @ 09,41 winsay  'accompany cheques'

	do while .t.
		msgLine('Statement for Advance Payments...')

      in window aWin @ 02,2 winSay 'For Cheques Issued on' ;
			winget dDate picture '@D' ;
			GET_MESSAGE ;
			'Date for Cheque (recent cheques only)'

      in window aWin @ 03,2 winsay 'For Grower: ' winget nGrower ;
			picture numBlankPic(FLD_GROWER) ;
			LOOKUP( LU_GROWER, ;
			'Enter a specific Grower to Print a Statement for one Grower Only')

      in window aWin @ 04,2 winsay 'Crop Year:  ' winget nYear picture '9999'
      in window aWin @ 05,2 winsay 'Copies of Statements' winget nCopies ;
			picture '9' valid nCopies >=1

      in window aWin @ 06,2 winsay 'Show Premium Message' winget lPremMess ;
			picture 'Y'  GET_MESSAGE ;
			'Print note on Time Premium on Statement?'

      in window aWin @ 07,2 winsay 'Show Final Prices   ' winget lShowFinal ;
			picture 'Y'  GET_MESSAGE ;
         'Show Final Prices (including Estimates) in Summary...?'

      In window aWin @ 10,02 winsay 'Message:'
		for n:=1 to len(aBott)
         in window aWin @ 10 + n,4 winget aBott[n] get_message ;
           'See General System Settings for Defaults'
		next

      in window aWin @ 10+len(aBott)+2,02 winsay ;
        'If you show Final Prices, be aware that these can be Estimates'
      in window aWin @ 10+len(aBott)+3,02 winsay ;
        'of the final price!'


		read

		if lastkey() == K_ESC
			exit
		endif

		Cheque->(dbClearFilter())

		if selectPrn('WEEKSTAT_1_O.TXT')
      	msgLine('Printer Selected for Statement Print .... Finding Data....')

			do case
			case !empty(nGrower)
				if !ValidTest(V_GROWER,nGrower,VT_MESSAGE)
					loop
				endif

				Cheque->(dbSetFilter( {|| Cheque->cheqType==CHEQUE_TYPE_WEEKLY } ))
            Cheque->(OrdSetFocus( CHEQUE_GROWER_DATE_ORD ))
				if Cheque->(dbSeek( ;
						 str(Grower->number,FLD_GROWER)+str(nYear,4)+dtos(Cheque->date), ;
						   HARDSEEK))
					PRINT_ON    RPT_OVERWRITE
					for n:=1 to nCopies
						theStatement( Cheque->series, Cheque->cheque)
					next
					PRINT_OFF   RPT_COMPLETE_NO_EJECT

				else
					if !Cheque->(FindLast( ;
							 str(Grower->number,FLD_GROWER) + str(nYear,4)))
						PRINT_ON    RPT_OVERWRITE
						for n:=1 to nCopies
							theStatement(space(FLD_SERIES),0)
						next
						PRINT_OFF   RPT_COMPLETE_NO_EJECT
					else
						nChoice := BsgChoice({ ;
							'The last weekly advance cheque for', ;
							'this grower was on '+shMDY(Cheque->date), ;
							'Cheque # '+Cheque->series+ lStrim(Cheque->cheque), ;
							'Do you wish to base the statement on', ;
							'this cheque or on any UnPaid Accounting Transactions?'}, ;
							{'This Chq','Unpaid','Cancel'})
						do case
						case nChoice==1
							PRINT_ON    RPT_OVERWRITE
							for n:=1 to nCopies
								theStatement( Cheque->series, Cheque->cheque)
							next
							PRINT_OFF   RPT_COMPLETE_NO_EJECT
						case nChoice==2
							PRINT_ON    RPT_OVERWRITE
							for n:=1 to nCopies
								theStatement( space(FLD_SERIES),0)
							next
							PRINT_OFF   RPT_COMPLETE_NO_EJECT
						endcase
					endif
				endif
				Cheque->(dbClearFilter())

			case !empty(dDate)
				Cheque->(dbSetFilter( {|| Cheque->cheqType==CHEQUE_TYPE_WEEKLY } ))
            Cheque->(OrdSetFocus(CHEQUE_DATE_ORD))
				if Cheque->(dbSeek( dtos(dDate),HARDSEEK) )
					select cheque
					// minor fix
					copy to tempCheq fields number,series,cheque ;
						for Cheque->year==nYear .and. ;
							Cheque->cheqType== ;
							 CHEQUE_TYPE_WEEKLY while Cheque->date==dDate
					use tempCheq exclusive new
					goto top
					if eof()
						waitInfo({'No Cheques for this Year on File for the day'})
						loop
					endif

					PRINT_ON    RPT_OVERWRITE
					do while !TempCheq->(eof())
						if ValidTest(V_GROWER,TempCheq->number,VT_MESSAGE)
							for n:=1 to nCopies
								theStateMent(TempCheq->series, TempCheq->cheque )
							next
						endif
						TempCheq->(dbSkip())
					enddo
					TempCheq->(dbCloseArea())
					PRINT_OFF   RPT_COMPLETE_NO_EJECT

				else
					waitInfo({'No Cheques on File for this day'})
				endif
			otherwise
				waitInfo( {'Fill in Cheque Run Date or Grower Date', ;
					 'You can look at the Cheque Register to Determine', ;
					 'a Cheque Date'})
			endcase
		endif
	enddo
return( nil )

static function theStatement( cSeries, nCheque )
	local n
	local nContainLn

   msgLine('Actual prep of statement for Chq# '+cSeries + var2char( nCheque)+'...' )

   nDaily4Week  := 0.00
   nAcct4Daily  := 0.00
   nAcct4Misc   := 0.00
   nAcct4Cheque := 0.00

	aFill( aBalance,0)
	aFill( aCurrent,0)

	nPage :=nLine := 1

	aContainer := ContArray()        //  Ok June 2000

	lAnyPrem := .f.
	FillArrays( cSeries, nCheque)   // June 2000 - Builds Various Arrays

   if nAdvance == 1
      PreviousWrk(cSeries, nCheque)  // June 2000 - Old Totals, incl. container
   endif

	StateHead()                     // J.2000 unchanged
	RecHead()                       // J.2000 unchanged

   if nAdvance == 1
      OldDailyShow()                  // J.2000 unchanged
   endif

	for n :=1 to len(aDaily)
		if nLine > 55
			nLine++
			PrnAtSay( nLine+2,1, 'Continued on next page...')
			nuFormFeed()
			StateHead()
			RecHead()
			nLine += 3
		ENDIF
		Daily->(dbGoTo(aDaily[n]) )

      DailyPrint(  )

		if empty(cSeries) .and. nCheque==0
			DailyUnPaidArrays()
		else
			DailyPaidArrays()
		endif
	next

	// determine how many lines
	nContainLn := 0
	for n := 1 to len(aContainer)
		if aContainer[n, A_CONT_IN] <> 0 .or. aContainer[n, A_CONT_OUT] <> 0 .or. ;
				aContainer[n, A_CONT_ISSUED] <> 0
			nContainLn ++
		endif
	next

   summaryB( nContainLn, cSeries, nCheque )

	nLine ++

	for n:=1 to len(aBott)
		if !empty(aBott[n])
			if nLine > 58
				PrnAtSay( nLine,1, 'Continued on next page...')
				nuFormFeed()
				StateHead()
				nLine += 3
			ENDIF
			prnAtSay( nLine ,1  ,  padc(aBott[n],75) )
			nLine ++
		endif
	next
	NuFormFeed()

RETURN( nil )

static function FillArrays( cSeries,nCheque )
   // also sets nAdvance
	msgLine('Cheque Info for '+lStrim(Grower->number))

   nAdvance := 0

	aAdvance := {}
	aPremium := {}
	aMisc    := {}
	aDeduct  := {}
	aDaily   := {}

   Audit->(OrdSetFocus( AUDIT_ACCT_DAY_ORD ))
   Daily->(OrdSetFocus( DAILY_ID_ORD ))

	nOwed := 0.00
	if empty(cSeries) .or. empty(nCheque)
		// no cheques for year
		cCurrency := Grower->currency
		dCheqDate := dDate

      Account->(OrdSetFocus( ACCOUNT_NUMBER_ORD ))
		Account->(dbSeek( str( Grower->number, FLD_NUMBER) + str(nYear,4),HARDSEEK))
		// Builds a list of Account Records which relate to this
		// Builds a list of Daily Records which relate to this
		do while Account->number==Grower->number .and. !Account->(eof()) .and. ;
				Account->year == nYear
			if empty(Account->series) .and. Account->cheque==0 .and. ;
					Account->date <= dCheqDate
				do case
            case Account->type== TT_BERRY_ADVANCE_1
               nAcct4Daily += Account->dollars
               nAdvance := max( nAdvance, 1)
					Acc2Daily( )
            case Account->type== TT_BERRY_ADVANCE_2
               nAcct4Daily += Account->dollars
               nAdvance := max( nAdvance, 2)

					Acc2Daily( )
            case Account->type== TT_BERRY_ADVANCE_3
               nAcct4Daily += Account->dollars
               nAdvance := max( nAdvance, 3)

					Acc2Daily( )
            case Account->type== TT_TIME_PREMIUM
               nAcct4Daily += Account->dollars
					Acc2Daily( )  // should be covered by the Above!
               nAdvance := max( nAdvance, 1)

            case Account->type== TT_STD_DEDUCTION
               // weekly deductions are shown in Summary Form Only
               // directly from the Account File
               nAcct4Misc  += Account->dollars
					// Acc2Daily()  -- No Reason to Care
					aadd(aDeduct, Account->(recno()))
               nAdvance := max( nAdvance, 1)

				case Account->type== TT_DEDUCT
               nAcct4Misc += Account->dollars
					aadd(aDeduct, Account->(recno()))

            case Account->type == TT_ADV_CONTAINER_ONLY
					Acc2Daily( )
					if str(Account->dollars ,12,2) <> str(0,12,2)
                  appError(APP_ERR_CONTAINER_AMT1, { ;
							'Container only transaction has charge', ;
							'Grower '+lStrim(Grower->number) })
						nAcct4Misc += Account->dollars
						aadd(aMisc, Account->(recno()))
					endif

               nAdvance := max( nAdvance, 1)  // could be any actually

				otherwise
               nAcct4Misc += Account->dollars
					if str(Account->dollars,12,2) <>str(0,12,2)
						aadd(aMisc, Account->(recno()))
					endif
				endcase
				nOwed += Account->dollars
            nAcct4Cheque += Account->dollars
			endif
			Account->(dbSkip())
		enddo
	else
		Cheque->(dbCLearFilter())
      Cheque->(OrdSetFocus( CHEQUE_CHEQUE_NO_ORD ))
		if !Cheque->(dbSeek( cSeries + str(nCheque, FLD_CHEQUE), HARDSEEK ))
			appError(APP_ERR_WEEK_STATE_CHEQUE_FIND, { ;
				'Can not find the Cheque for Grower '+lStrim(Grower->number), ;
				'Cheque Series/Number='+cSeries+str(nCheque,10) })
			return( .f. )
		endif

		// this is the Current Cheque
		cCurrency := Cheque->currency
		dCheqDate := Cheque->date

		// now we find all Associated Transactions
      Account->(OrdSetFocus( ACCOUNT_CHEQUE_ORD))
		Account->(dbSeek( cSeries+str(nCheque,FLD_CHEQUE)) )
		do while Account->series==cSeries .and. nCheque==Account->cheque ;
				.and. !Account->(eof())
			do case
         case Account->type== TT_BERRY_ADVANCE_1
            nAcct4Daily += Account->dollars
				Acc2Daily()
            nAdvance := max( nAdvance, 1)
         case Account->type== TT_BERRY_ADVANCE_2
            nAcct4Daily += Account->dollars
				Acc2Daily()
            nAdvance := max( nAdvance, 2)
         case Account->type== TT_BERRY_ADVANCE_3
            nAcct4Daily += Account->dollars
				Acc2Daily()
            nAdvance := max( nAdvance, 3)
         case Account->type== TT_TIME_PREMIUM
            nAcct4Daily += Account->dollars
				Acc2Daily()  // should be covered by the Above!
            nAdvance := max( nAdvance, 1)
         case Account->type== TT_STD_DEDUCTION
            // weekly deductions are shown in Summary Form Only
            // directly from the Account File
            nAcct4Misc  += Account->dollars
				// Acc2Daily()  - No reason to Care!
				aadd(aDeduct, Account->(recno()))
            nAdvance := max( nAdvance, 1)
			case Account->type== TT_DEDUCT
            nAcct4Misc += Account->dollars
				aadd(aDeduct, Account->(recno()))
         case Account->type == TT_ADV_CONTAINER_ONLY
				Acc2Daily( ) // we probably don't care, but it
				             // does not matter
				if str(Account->dollars ,12,2) <> str(0,12,2)
               appError(APP_ERR_CONTAINER_AMT2, { ;
						'Container only transaction has charge', ;
						'Grower '+lStrim(Grower->number) })
					nAcct4Misc += Account->dollars
					aadd(aMisc, Account->(recno()))
				endif
            nAdvance := max( nAdvance, 1)  // could be any actually
			otherwise
            nAcct4Misc += Account->dollars
				if str(Account->dollars,12,2) <>str(0,12,2)
					aadd(aMisc, Account->(recno()))
				endif
			endcase
			nOwed += Account->dollars
         nAcct4Cheque += Account->dollars
			Account->(dbSkip())
		enddo
	endif
   Cheque->(dbClearFilter())
return( nil )


static function PreviousWrk( cSeries, nCheque )
	local lFound
	local n
	local lConsider

   // DAILY.DBF record could relate to several
	// records in ACCOUNT.DBF.
	// so each DAILY.DBF record relates to can related to:
   //      ONE OR MORE ADVANCE (WEEKLY) CHEQUE(S)
	//      ONE FINAL CHEQUE
	//      MULTIPLE SPECIAL PAYMENT CHEQUES

   // This is ONLY relevant if we are looking a first advance !

   Daily->(OrdSetFocus(DAILY_GROWER_ORD))
	Daily->(dbSeek( str(Grower->number,FLD_GROWER)+str(nYear,4),HARDSEEK))

	do while Daily->number==Grower->number .and. year(Daily->date)==nYear ;
			.and. !Daily->(eof())

		// we are looking for Current Records to Print
		if empty(cSeries) .and. nCheque==0
         lConsider := (Daily->date <= dCheqDate .and. Daily->adv_prid1==0)
		else
         lConsider := (Daily->adv_prid1 > 0)
		endif

		if lConsider
			lFound := .f.
			for n := 1 to len(aDaily)
				if aDaily[n]==Daily->(recno())
					lFound := .t.
					exit
				endif
			next

         if lFound              // calculate the previous
            ContainerCount()
         else
            OldDailySum()
            for n := 1 to len(aContainer)
               aContainer[n,A_CONT_ISSUED]  += ;
                  ( Daily->(gsOutContainer(n)) - ;
                  Daily->(gsInContainer(n)) )
            next
         endif
		endif
		Daily->(dbSkip())
	enddo

return( nil )


static Function StateHead()

	PrinterCtrl( PRN_CTRL_10_CPI )

	nuQprnOut( space(18) +  padc( TheClientName( ) ,44)  )

   if nAdvance <> 0
      nuQprnOut( space( 18) +  padc("Statement of Harvest Season Advance #"+ ;
       lStrim(nAdvance),44) )
   else
      nuQprnOut( space(18) +  padc("Statement of Harvest Season Advance",44) )
   endif
   nuQQprnOut( space(2) +  padl(shMDY(dDATE),14) )
	nuQprnOut( space(18) +  padc('for Berry crop',44) )
   nuQprnOut( space(5)  + 'GROWER: '+ lStrim(Grower->NUMBER) )
	nuQprnOut( space(20) + padr( Grower->NAME,50) + ' PAGE: '+LTRIM(STR(nPage,2)) )
	nuQprnOut( space(20) +  Grower->STREET )
   if !empty( Grower->street2)
      nuQprnOut( space(20) +  Grower->STREET2 )
      nuQprnOut( space(20) +  alltrim(Grower->CITY)+' '+alltrim(Grower->prov)+ ;
          '  '+Grower->PCODE )
   else
      nuQprnOut( space( 20 )+ alltrim(Grower->CITY)+' '+Grower->prov )
      nuQprnOut( space( 20) +  Grower->PCODE )
   endif
	nLine := 11
	nPage ++
RETURN( nil )

static function RECHEAD()

   do case
   case sysvalue( SYS_WEEK_STATEMENT_FORMAT  ) == WEEK_STATE_FMT_ORIGINAL
      prnAtSay( nLine ,3  ,  ;
		'         Receipt           '+  ;
		'--------------- Lbs. of Berries -----------------' )

      prnAtSay( nLine +1,3  ,  ;
		'Date     Number            ' + ;
		'              Gr 1       # 2       # 3      Total' )

   case sysvalue( SYS_WEEK_STATEMENT_FORMAT  ) == WEEK_STATE_FMT_KEYED_PRICE
      prnAtSay( nLine ,3  ,  ;
      '         Receipt         '+  ;
      '                          Price/LB          Lbs. of' )

      prnAtSay( nLine +1,3  ,  ;
      'Date     Number          ' + ;
      'Product / Grade           (if set)          Berries' )

   endcase

	prnAtSay( nLine +2,0  ,  REPLICATE('=',79) )

	nLine+=3

RETURN( nil )

static function DailyPrint()
	local n
	local cName
   local cTmp

	prnAtSay( nLine , 1  ,  shMDY(Daily->DATE) )
	prnAtSay( nLine ,13  ,  Daily->RECPT  ,  replicate('9', FLD_RECPT ) )

   prnAtSay( nLine ,13+FLD_RECPT  ,  Daily->recptltr )

	do case
	case str(Daily->net,12,2) == str(0,12,2)
      prnAtSay( nLine , 22  ,  'Containers Only')    // indent 1 space

	case empty(Daily->product) .and. !empty(Daily->process)
      prnAtSay( nLine ,22  ,  'Product EMPTY - '+Daily->process )
		appError(APP_ERR_PRODUCT_PROCESS, ;
				{'Empty Product, Process='+Daily->process })
	otherwise
		cName := NameOf( LU_PRODUCT, Daily->product)

		if empty(cName)
         prnAtSay( nLine ,22  ,  Daily->product + ' Unknown Type '+Daily->process )
			appError(APP_ERR_WHAT_PRODUCT_IS_IT, ;
				{'Unknown Product '+Daily->product + 'on Receipt: '+Daily->depot+'-'+var2char( Daily->recpt)})
		else
         do case
         case sysvalue( SYS_WEEK_STATEMENT_FORMAT  ) == WEEK_STATE_FMT_ORIGINAL
            if str(Daily->prem_price,12,2) <> str(0,12,2)
               prnAtSay( nLine ,22  ,  padr( cName, 13)+'*'+Daily->process )
               lAnyPrem := .t.
            else
               prnAtSay( nLine ,22  ,  padr( cName, 13)+' '+Daily->process )
            endif
         case sysvalue( SYS_WEEK_STATEMENT_FORMAT  ) == WEEK_STATE_FMT_KEYED_PRICE
            if str(Daily->prem_price,12,2) <> str(0,12,2)
               prnAtSay( nLine ,22  ,  padr( cName, 13)+' '+'*'+ ;
                alltrim(NameOf( LU_PROCESS_TYPE, Daily->process ))+' #'+ ;
                 str( Daily->grade,FLD_GRADE) )
               lAnyPrem := .t.
            else
               prnAtSay( nLine ,22  ,  padr( cName, 13)+' '+' '+ ;
                alltrim(NameOf( LU_PROCESS_TYPE, Daily->process ))+' #'+ ;
                 str( Daily->grade,FLD_GRADE) )
            endif
         endcase
		endif

		do case
		case Daily->grade < 1 .or. Daily->grade > MAX_NO_OF_GRADES
			appError( APP_ERR_WEIRD_GRADE_POST , ;
				{'Problem with Posting of Price - ignored', ;
				'Daily Grade Rec '+str(Daily->grade,12,2), ;
				'Grower '+str(Daily->number, 10) })
			prnAtSay( nLine , 42  ,  'See Administrator, note '+APP_ERR_WEIRD_GRADE_POST )
		otherwise
         do case
         case sysvalue( SYS_WEEK_STATEMENT_FORMAT  ) == WEEK_STATE_FMT_ORIGINAL
            for n := 1 to len( aCurrent )
               if Daily->grade == n
                  aCurrent[n] += Daily->net
                  prnAtSay( nLine , BALANCE_START_COL + n* BALANCE_INCREMENT_COL ;
                     , Daily->net  ,  '9,999,999' )
               endif
            next
         case sysvalue( SYS_WEEK_STATEMENT_FORMAT  ) == WEEK_STATE_FMT_KEYED_PRICE
            for n := 1 to len( aCurrent )
               if Daily->grade == n
                  aCurrent[n] += Daily->net
               endif
            next
            do case
            case str( Daily->THEPRICE, 12, 2  )  == str( 0,12,2)
               prnAtSay( nLine , BALANCE_START_COL + 5 +  FLD_PROCDESC, ' ')
            case Daily->THEPRICE  > 0
               cTmp := alltrim(str( Daily->thePrice,7,2))
               prnAtSay( nLine , BALANCE_START_COL + 5 +  FLD_PROCDESC ,padl( '$'+cTmp,8))
            case Daily->THEPRICE  < 0
               cTmp := alltrim(str( -Daily->thePrice,7,2))
               prnAtSay( nLine , BALANCE_START_COL + 4 +  FLD_PROCDESC, padl( '-$'+cTmp,9))
            endcase
         endcase
			prnAtSay( nLine , 70  ,  Daily->net  ,  '9,999,999' )
		endcase
	endcase


	nLine ++

RETURN(nil)


// CALCUALTE PREVIOUS
static function OldDailySum()
	local n

	n := Daily->grade
	do case
	case n >= 1 .and. n <= len(aBalance)
		aBalance[n] += Daily->net
	case str(Daily->net,12,2) <> str(0,12,2)
		appError(APP_ERR_NO_GRADE, ;
			{'No grade but has weight'})
	endcase

RETURN(nil)

static function OldDailyShow()
	local n
	local nSum := 0

	prnAtSay( nLine ,1  ,  "Previous:" )

   do case
   case sysvalue( SYS_WEEK_STATEMENT_FORMAT  ) == WEEK_STATE_FMT_ORIGINAL
      for n := 1 to len( aBalance)
         prnAtSay( nLine , BALANCE_START_COL + n* BALANCE_INCREMENT_COL , ;
              aBalance[n]  ,   '9,999,999' )
         nSum += aBalance[n]
      next
   case sysvalue( SYS_WEEK_STATEMENT_FORMAT  ) == WEEK_STATE_FMT_KEYED_PRICE
      for n := 1 to len( aBalance)
         nSum += aBalance[n]
      next
   endcase

	prnAtSay( nLine ,70  ,  nSum  ,  '9,999,999'  )

	nLine += 2

RETURN(nil)

static function summaryB( nContainLn, cSeries, nCheque )
   local n
	local nTotal
	local cProduct, cProcess
	local lNewPage
   local lFinalUnkn   := .f.
   local lFinalMulti  := .f.

	if nLine >= 53
		prnAtSay( nLine ,0  ,  REPLICATE('=',79) )

		nuFormFeed()
		StateHead()
		RecHead()
		nLine += 2
	endif

	prnAtSay( nLine ,0  ,  REPLICATE('=',79) )
	nLine += 2

   if nAdvance == 1
      prnAtSay( nLine ,1  ,  'THIS PAY PERIOD:' )
   else
      prnAtSay( nLine ,1  ,  'ADVANCE # '+lStrim(nAdvance) )
   endif

	nTotal := 0
   do case
   case sysvalue( SYS_WEEK_STATEMENT_FORMAT  ) == WEEK_STATE_FMT_ORIGINAL
      for n := 1 to len(aCurrent)
         prnAtSay( nLine ,BALANCE_START_COL + n*BALANCE_INCREMENT_COL ;
             ,  aCurrent[ n ]   ,  '9,999,999' )
         nTotal += aCurrent[n]
      next
   case sysvalue( SYS_WEEK_STATEMENT_FORMAT  ) == WEEK_STATE_FMT_KEYED_PRICE
      for n := 1 to len(aCurrent)
         nTotal += aCurrent[n]
      next
   endcase

	prnAtSay( nLine ,70  ,  nTotal  ,  '9,999,999' )

   if nAdvance == 1
      // year to date is really weird if you are paying a second
      // or third advance

      nLine += 2
      prnAtSay( nLine ,1  ,  'YEAR TO DATE:' )

      nTotal := 0
      do case
      case sysvalue( SYS_WEEK_STATEMENT_FORMAT  ) == WEEK_STATE_FMT_ORIGINAL
         for n := 1 to len(aBalance)
            prnAtSay( nLine ,BALANCE_START_COL + n*BALANCE_INCREMENT_COL ;
                ,  aBalance[ n ] + aCurrent[ n ]   ,  '9,999,999' )
            nTotal += aBalance[n]
            nTotal += aCurrent[n]
         next
      case sysvalue( SYS_WEEK_STATEMENT_FORMAT  ) == WEEK_STATE_FMT_KEYED_PRICE
         for n := 1 to len(aBalance)
            nTotal += aBalance[n]
            nTotal += aCurrent[n]
         next
      endcase
      prnAtSay( nLine ,70  ,  nTotal  ,  '9,999,999' )
   endif

	nLine +=2

	if nLine >= 55
		nuFormFeed()
		StateHead()
		nLine += 2
	endif

	if lAnyPrem .or. lPremMess
		nLine ++
		prnAtSay( nLine ,24  ,  '* = Early shipment premium' )
		nLine += 2
	endif

	nLine += 2

	if nContainLn <> 0 // we don't need to print anything if ZERO....
		// Simplify this - Containers

      if nAdvance == 1
         ContInfo(  )
      endif
	endif

	// Payment Summary
	aSort( aAdvance, NIL, NIL, { |x,y| ;
		x[ A_AF_BERRY ]+ x[  A_AF_PROCESS ] + ;
    str( x[ A_AF_GRADE ], 1) + dtos( x[  A_AF_FROM ] ) + ;
    str( x[ A_AF_ADVANCE_NO], 3 )  ;
     < ;
		y[ A_AF_BERRY ]+ y[  A_AF_PROCESS ] + ;
    str( y[ A_AF_GRADE ], 1) + dtos( y[  A_AF_FROM ] ) + ;
    str( y[ A_AF_ADVANCE_NO], 3 )  ;
      } )

	cProduct := 'vv'
	cProcess := 'fd'
	lNewPage := .t.

	for n := 1 to len(aAdvance)
		if lNewPage
			nLine++

         prnAtSay( nLine , 01  ,  'Advance No '+lStrim(nAdvance)+' Summary:' )

         if lShowFinal
            prnAtSay( nLine , 40  ,  'Final' )
         endif
			prnAtSay( nLine , 48  ,  padl('Adv.',5)     )
			prnAtSay( nLine , 68  ,  padl('Actual',11) )

			nLine++

			prnAtSay( nLine , 24  ,  padc('- From -',14) )
         if lShowFinal
            prnAtSay( nLine , 40  ,  'Price' )
         endif

			prnAtSay( nLine , 48  ,  padl('Rate',5) )
			prnAtSay( nLine , 56  ,  padl('lbs',9) )
			prnAtSay( nLine , 68  ,  padl('Payment',11) )
         nLine++
		endif

		if cProduct <> aAdvance[ n,A_AF_BERRY ] .or. lNewPage
			prnAtSay( nLine ,3  ,  NameOf(LU_PRODUCT, aAdvance[n,A_AF_BERRY]) )
			nLine++
		endif
      if cProcess <> aAdvance[ n,A_AF_PROCESS ] .or. lNewPage .or. ;
         cProduct <> aAdvance[ n,A_AF_BERRY ]

			prnAtSay( nLine ,5  ,  padr(NameOf(LU_PROCESS_TYPE, ;
				 aAdvance[n,A_AF_PROCESS ]),15) )
		endif
		if aAdvance[n, A_AF_GRADE] <> 0
			prnAtSay( nLine ,21  ,  str(aAdvance[n, A_AF_GRADE],1) )
		endif
		prnAtSay( nLine , 24  ,  substr( shMDY( aAdvance[n, A_AF_FROM]),1,6)+'  '+ ;
		                substr( shMDY( aAdvance[n, A_AF_TO  ]),1,6) )

      // Changed July 2009
      /* --------------------
      if str( aAdvance[n, A_AF_FINAL_RATE],5,2)==str(0,5,2) .and. ;
              aAdvance[n, A_AF_ADVANCE_RATE] > 0
         prnAtSay( nLine , 40  ,  '  ???')
         lFinalUnkn := .t.
      else
         prnAtSay( nLine , 40  ,  transform( aAdvance[n, A_AF_FINAL_RATE],'99.99') )
      endif

      --------------------------- */

      if lShowFinal
         do case
         case aAdvance[n, A_AF_FINAL_MULTI ]
            prnAtSay( nLine , 40  ,  '  ???' )
            lFinalMulti := .t.
         case str( aAdvance[n, A_AF_FINAL_RATE1],12,3)==str(0,12,3) .and. ;
                 aAdvance[n, A_AF_ADVANCE_RATE] > 0
            prnAtSay( nLine , 40  ,  '  ???')
            lFinalUnkn := .t.
         otherwise
            prnAtSay( nLine , 40  ,  transform( aAdvance[n, A_AF_FINAL_RATE1],'99.99') )
         endcase
      endif

		prnAtSay( nLine , 48  ,  transform( aAdvance[n, A_AF_ADVANCE_RATE],'99.99') )

      // Nov 2001
      do case
      case aAdvance[n, A_AF_ADVANCE_NO] < nAdvance
         prnAtSay( nLine , 54  ,  str(aAdvance[n, A_AF_ADVANCE_NO],1) )
      case aAdvance[n, A_AF_ADVANCE_NO] > nAdvance
         prnAtSay( nLine , 54  ,  str(aAdvance[n, A_AF_ADVANCE_NO],1)+'*' )
      endcase

		prnAtSay( nLine , 56  ,  transform( aAdvance[n, A_AF_LBS],'9,999,999') )

		prnAtSay( nLine , 68  ,  transform( aAdvance[n, A_AF_PAID], '$999,999.99') )
		nLine++

		if nLine > 55
			lNewPage := .t.
			nuFormFeed()
			StateHead()
			nLine += 3
		else
			lNewPage := .f.
		endif
		cProduct := aAdvance[n, A_AF_BERRY]
		cProcess := aAdvance[n, A_AF_PROCESS]
	next

   do case
   case lFinalUnkn .and. lFinalMulti
      nLine ++
      prnAtSay( nLine ,24  ,  '???=multi rate or unknown Final Payment' )
		nLine += 2
   case lFinalUnkn
		nLine ++
      prnAtSay( nLine ,24  ,  '??? = Final Payment not known yet' )
		nLine += 2
   case lFinalMulti
      nLine ++
      prnAtSay( nLine ,24  ,  '??? = multiple Final Payment Rates' )
		nLine += 2
   endcase

	aSort( aPremium, NIL, NIL, { |x,y| ;
		x[ A_PREM_BERRY ]+x[  A_PREM_PROCESS ] + dtos( x[  A_PREM_FROM ] ) < ;
		y[ A_PREM_BERRY ]+y[  A_PREM_PROCESS ] + dtos( y[  A_PREM_FROM ] ) } )

	cProcess := 'sd'
	cProduct := 'as'
	lNewPage := .t.

	for n := 1 to len(aPremium)
		if lNewPage
			nLine++
			prnAtSay( nLine , 01  ,  'Premium Summary:' )

			prnAtSay( nLine , 24  ,  padc('- From -',14) )

			prnAtSay( nLine , 48  ,  padl('Rate',5) )
			prnAtSay( nLine , 56  ,  padl('lbs',9)  )
			prnAtSay( nLine , 68  ,  padl('Paid',11))
         nLine++
		endif

		if cProduct <> aPremium[ n,A_PREM_BERRY ] .or. lNewPage
			prnAtSay( nLine ,3  ,  NameOf(LU_PRODUCT, aPremium[n,A_PREM_BERRY]) )
			nLine++
		endif
      if cProcess <> aPremium[ n,A_PREM_PROCESS ] .or. lNewPage .or. ;
         cProduct <> aPremium[ n,A_PREM_BERRY ]
			prnAtSay( nLine ,5  ,  padr(NameOf(LU_PROCESS_TYPE, ;
				 aPremium[n,A_PREM_PROCESS ]),15) )
		endif

		prnAtSay( nLine , 24  ,  substr(shMDY( aPremium[n, A_PREM_FROM]),1,6)+'  '+ ;
		                substr(shMDY( aPremium[n, A_PREM_TO  ]),1,6) )

		prnAtSay( nLine , 48  ,  transform( aPremium[n, A_PREM_RATE],'99.99') )

      prnAtSay( nLine , 56  ,  transform( aPremium[n, A_PREM_LBS],'9,999,999'))

      prnAtSay( nLine , 68  ,  transform( aPremium[n, A_PREM_PAID], '$999,999.99'))
		nLine++

		cProduct := aPremium[n, A_PREM_BERRY]
		cProcess := aPremium[n, A_PREM_PROCESS]

		if nLine > 55
			lNewPage := .t.
			nuFormFeed()
			StateHead()
			nLine += 3
		else
			lNewPage := .f.
		endif
	next

	lNewPage := .t.
	for n := 1 to len(aMisc)
		if lNewPage
			nLine+=2
			prnAtSay( nLine ,1  ,  'Other Entries:' )
			prnAtSay( nLine , 48  ,  padl('Rate',5) )
			prnAtSay( nLine , 56  ,  padl('lbs',9) )
			prnAtSay( nLine , 68  ,  padl('Paid',11) )
			nLine++
		endif

		Account->(dbGoTo(aMisc[n]))

		prnAtSay( nLine ,3  ,  NameOf( LU_TRANSACTION_TYPE, Account->type) )

		prnAtSay( nLine ,37  ,  Account->product+' '+Account->process + ;
			iif(Account->grade==0,'' ,str(Account->grade,2) ) )

		if str(Account->u_price,12,3) <> str(0,12,3)
			prnAtSay( nLine , 47  ,  Account->u_price   ,   '99.999' )
		endif

		if str(Account->lbs,12,2)<>str(0,12,2)
         prnAtSay( nLine , 56  ,  Account->lbs  ,  '9,999,999' )
		endif

      if Account->dollars > 999999 .or. Account->dollars < -999999
         prnAtSay( nLine , 68  ,  Account->dollars  ,  '$9999999.99' )
      else
         prnAtSay( nLine , 68  ,  Account->dollars  ,  '$999,999.99' )
      endif

		if !empty( Account->desc )
			nLine++
			prnAtSay( nLine , 6  ,  Account->desc )
		endif
		nLine ++
		if nLine > 55
			lNewPage := .t.
			nuFormFeed()
			StateHead()
			nLine += 3
		else
			lNewPage := .f.
		endif
	next


	lNewPage := .t.
	for n := 1 to len(aDeduct)
		if lNewPage
			nLine+=2
			prnAtSay( nLine ,1  ,  'Deductions:' )
			prnAtSay( nLine , 48  ,  padl('Rate',5) )
			prnAtSay( nLine , 56  ,  padl('lbs',9) )
			prnAtSay( nLine , 68  ,  padl('Deducted',11) )
			nLine++
		endif

		Account->(dbGoTo(aDeduct[n]))

		if Account->type==TT_DEDUCT
			prnAtSay( nLine ,3  ,  NameOf( LU_DEDUCTION_CLASS, Account->class) )
		else
			prnAtSay( nLine ,3  ,  NameOf( LU_TRANSACTION_TYPE, Account->type ) )
		endif

		prnAtSay( nLine ,37  ,  Account->product+' '+Account->process + ;
			iif(Account->grade==0,'' ,str(Account->grade,2) ) )

		if str(Account->u_price,12,3) <> str(0,12,3)
         // prnAtSay( nLine , 47  ,  Account->u_price   ,   '99.999' )
         //  Revised July 2013
         prnAtSay( nLine , 46  ,  Account->u_price   ,   '99.9999' )
		endif

		if str(Account->lbs,12,2)<>str(0,12,2)
         prnAtSay( nLine , 56  ,  Account->lbs  ,  '9,999,999')
		endif

      if account->dollars > 999999 .or. Account->dollars < -999999
         prnAtSay( nLine , 68  ,  Account->dollars  ,  '$9999999.99' )
      else
         prnAtSay( nLine , 68  ,  Account->dollars  ,  '$999,999.99' )
      endif

		if !empty( Account->desc )
			nLine++
			prnAtSay( nLine , 6  ,  Account->desc )
		endif
		nLine ++
		if nLine > 55
			lNewPage := .t.
			nuFormFeed()
			StateHead()
			nLine += 3
		else
			lNewPage := .f.
		endif

	next

   //........... "$999,999.99"
   prnAtSay( nLine ,68  ,  "===========" )
	nLine ++

	IF !empty(cSeries) .and. !empty(nCheque)
      prnAtSay( nLine ,1   ,  'Cheque '+lStrim(nCheque)+' issued on ' + ;
			shMDY(dCheqDate)+', for' )

		do case
		case cCurrency==CANADIAN_DOLLARS
			prnAtSay( nLine , 61  ,  '')
		case cCurrency==US_DOLLARS
			prnAtSay( nLine , 61  ,  'US $')
		otherwise
			AppError(APP_ERR_UNKNOWN_CURRENCY , ;
			{'Unknown Currency Type '+cCurrency, ;
				'on Cheque '+str(nCheque,10) })
		endcase

      if Cheque->amount > 999999
         prnAtSay( nLine ,66  ,  transform(Cheque->amount, '$9,999,999.99') )
      else
         prnAtSay( nLine ,68  ,  transform(Cheque->amount,   '$999,999.99') )
      endif

      if str(Cheque->amount,12,2) <> str( nDaily4Week + nAcct4Misc, 12,2 )
         AppError(APP_ERR_ADD_UP1, ;
				{'Problem with '+lstrim(Grower->number), ;
				'Cheque Amount & Corresponding Items Disagree'})
			nLine ++
         prnAtSay( nLine , 1  ,  'Amount 1/2 =>' )
         prnAtSay( nLine ,18  ,  nDaily4week  ,  '$9,999,999.99' )
         prnAtSay( nLine ,33  ,  nAcct4Misc  ,   '$9,999,999.99')
      endif

      if str(Cheque->amount,12,2) <> str(nAcct4Cheque,12,2)
         AppError(APP_ERR_ADD_UP2, ;
				{'Problem with '+lstrim(Grower->number), ;
				'Cheque Amount & Corresponding Items Disagree'})
			nLine ++
         prnAtSay( nLine , 1  ,  'Acct Sum=>' )
         prnAtSay( nLine ,18  ,  nAcct4Cheque  ,  '$9,999,999.99' )
      endif

      if str(nAcct4Daily,12,2) <> str(nDaily4Week, 12,2 )
         AppError(APP_ERR_ADD_UP3, ;
				{'Problem with '+lstrim(Grower->number), ;
				'Cheque Amount & Corresponding Items Disagree'})
			nLine ++
         prnAtSay( nLine , 1  ,  'Daily 1/2 =>' )
         prnAtSay( nLine ,18  ,  nAcct4Daily  ,  '$9,999,999.99' )
         prnAtSay( nLine ,33  ,  nDaily4week  ,  '$9,999,999.99' )
      endif
		nLine++
   	prnAtSay( nLine ,68  ,  "===========")
	else
		prnAtSay( nLine , 1  ,  'BALANCE FORWARD')
      if nOwed > 999999 .or. nOwed < -999999
         prnAtSay( nLine , 65  ,  nOwed  ,  '$99,999,999.99')
      else
         prnAtSay( nLine , 68  ,  nOwed  ,  '$999,999.99' )
      endif
	endif
	nLine ++

	PrinterCtrl( PRN_CTRL_10_CPI )

RETURN( nil )

static function ContainerCount()
	local n
	for n := 1 to len(aContainer)
		aContainer[n,A_CONT_IN]  += Daily->(gsInContainer(n))
		aContainer[n,A_CONT_OUT] += Daily->(gsOutContainer(n))
	next
return( nil )

static function ContInfo( )
	local n, nValue
	local nCnt

	nCnt := 0
	for n := 1 to len(aContainer)
		if aContainer[n, A_CONT_IN ] <> 0 .or. ;
			aContainer[n, A_CONT_OUT ] <> 0 .or. ;
			aContainer[n, A_CONT_ISSUED] <> 0

			nCnt++
		endif
	next

	if nCnt + nLine > 54
		prnAtSay( nLine , 02  ,  'Continued on next page...')
		nuFormFeed()
		StateHead()
		nLine += 2
	endif

	prnAtSay( nLine , 02  ,   'Containers:')
	prnAtSay( nLine , 28  ,   '-This Period--')
	prnAtSay( nLine , 45  ,   '    YTD')
	nLine ++
	prnAtSay( nLine , 29  ,   " Rec'd")
	prnAtSay( nLine , 37  ,   'Issued')
	prnAtSay( nLine , 45  ,  '   Bal.')
	//              '999,999'
	nLine++

	for n := 1 to len(aContainer)
		if aContainer[n, A_CONT_IN ] <> 0 .or. ;
			aContainer[n, A_CONT_OUT ] <> 0 .or. ;
			aContainer[n, A_CONT_ISSUED] <> 0

			prnAtSay( nLine ,  2  ,  padr(aContainer[n,A_CONT_NAME],25) )
			prnAtSay( nLine , 29  ,  aContainer[n,A_CONT_IN]   ,  '99,999')
			prnAtSay( nLine , 37  ,  aContainer[n,A_CONT_OUT]  ,  '99,999')
			prnAtSay( nLine , 45  ,  aContainer[n,A_CONT_ISSUED] ;
				+ aContainer[n,A_CONT_OUT] ;
				- aContainer[n,A_CONT_IN]  ;
				 ,  '999,999')

			nLine++
		endif
	next

	nValue := 0.00
	for n := 1 to len( aContainer)
		nValue += (round( ;
			(aContainer[n,A_CONT_ISSUED]      ;
			+ aContainer[n,A_CONT_OUT] ;
			- aContainer[n,A_CONT_IN]   )  * aContainer[n,A_CONT_VALUE],2))
	next

	if str(nValue ,12,2 ) <> str(0,12,2) .and. nValue > 0
		nLine++
		prnAtSay( nLine , 2  ,  'TOTAL VALUE OF OUTSTANDING CONTAINERS:')
		prnAtSay( nLine ,41  ,  nValue  ,  '$999,999.99')
	endif
	nLine++

return( NIL )



static function AccBerry()
	local cReturn

	cReturn :=  Account->product +' '+Account->process+' '+ ;
					iif(Account->grade==0, ' ' ,Str(account->grade,1) )

return( cReturn )


// June 2000

static Function Acc2Daily(  )
	local n
	local lAdded

	Audit->(dbSeek( str(Account->acct_uniq,FLD_DOCUMENT), HARDSEEK ))
	do while Account->acct_uniq == Audit->acct_uniq .and. ;
				!Audit->(eof())

		if !Daily->(dbSeek( str(Audit->day_uniq, FLD_DOCUMENT),HARDSEEK))
			appError(APP_ERR_AUDIT_TRAIL_PROBLEM1, { ;
				'Can not find the Daily for Grower '+lStrim(Grower->number), ;
				'Account ID='+str(Account->acct_uniq,10), ;
				'Acct Type ='+Account->type, ;
				'Daily ID  ='+str(Daily->day_uniq,10) })
		else
			lAdded := .f.
			for n := 1 to len(aDaily)
				if aDaily[n]==Daily->(recno())
					lAdded := .t.
					exit
				endif
			next
			if !lAdded
				aadd(aDaily, Daily->(recno()) )
			endif
		endif
		Audit->(dbSkip())
	enddo
return( nil )

static function DailyPaidArrays()

   // Nov 2001
   // what Advance are we concerned with
   //    look at Each Entry in Audit for this Entry in Daily
   //      find the Account record associated.
   //      if that Account Record references the Cheque
   //      go through & see how much we paid....etc.

   Account->(OrdSetFocus( ACCOUNT_LINK_ORD ))
   Audit->(OrdSetFocus( AUDIT_DAY_ACCT_ORD ))
   Audit->(dbSeek( str(Daily->day_uniq, FLD_DOCUMENT ), HARDSEEK))

   do while !Audit->(eof()) .and. Audit->day_uniq==Daily->day_uniq
      if Account->(dbSeek( str(Audit->acct_uniq, FLD_DOCUMENT), HARDSEEK))
         if Account->cheque==Cheque->cheque .and. ;
             Account->series==Cheque->series
            PdArrayThing()
         endif
      else
         AppError( APP_ERR_CAN_NOT_FIND_ACCOUNT_REC1, { ;
           'Account Rec Not Found for '+lStrim(Audit->acct_uniq), ;
           'Daily Unique is '+lStrim(Daily->day_uniq), ;
			  'Receipt # is '+Daily->depot+var2char( Daily->recpt), ;
           'Grower is '+lStrim(Daily->number), ;
           'Daily Record No: '+lStrim(Daily->(recno())) })
      endif
      Audit->(dbSkip())
   enddo

return( nil )

static Function PdArrayThing()
   local n
	local lFound

   // Nov 2001
   local nID
   local nPrice
   local nAdv
   local nFinal       // July 2009

   do case
   case Account->type == TT_BERRY_ADVANCE_1
      nID    := Daily->adv_prid1
      nPrice := Daily->adv_pr1
      nAdv   := AFA_ADVANCE_1_PAYTYPE
   case Account->type == TT_BERRY_ADVANCE_2
      nID    := Daily->adv_prid2
      nPrice := Daily->adv_pr2
      nAdv   := AFA_ADVANCE_2_PAYTYPE
   case Account->type == TT_BERRY_ADVANCE_3
      nID    := Daily->adv_prid3
      nPrice := Daily->adv_pr3
      nAdv   := AFA_ADVANCE_3_PAYTYPE
   otherwise
      nID    :=  0
      nPrice :=  0.00
      nAdv   :=  AFA_UNKNOWN_PAYTYPE
   endcase

   // if Daily->adv_prid1 > 0

   if nID > 0
      Price->(OrdSetFocus( PRICE_PRICE_ID_ORD ))
      if !Price->(dbSeek( str( nID, FLD_DOCUMENT ), HARDSEEK ))
         AppError( APP_ERR_NO_PRICE_WITH_ID , ;
          {'Can not find Price ID '+lStrim( nID ), ;
           'This is pretty odd-maybe you deleted a price', ;
           'that you should not have', ;
           'Final Price on Statement may be wonky' })

         FindPrice( daily->Product, daily->Process, daily->Date )
      endif

		lFound := .f.
		for n := 1 to len(aAdvance)
         if nID == aAdvance[n, A_AF_ID] .and. ;
            str( nPrice,12,2) == ;
				   str(aAdvance[n, A_AF_ADVANCE_RATE],12,2) .and. ;
				Daily->product == aAdvance[ n, A_AF_BERRY ] .and. ;
				Daily->process == aAdvance[ n, A_AF_PROCESS ] .and. ;
            Daily->grade == aAdvance[ n, A_AF_GRADE ] .and. ;
            nAdv == aAdvance[ n, A_AF_ADVANCE_NO ]

					lFound := .t.
					exit
			endif
		next
		if !lFound
			aadd( aAdvance, A_AF_STRU )
			n := len(aAdvance)
         aAdvance[n, A_AF_ID]            := nID
         aAdvance[n, A_AF_ADVANCE_RATE]  := nPrice
         aAdvance[ n, A_AF_ADVANCE_NO ]  := nAdv

         // this should have been done regardless of whether it was
         //   a new Record.  Prior to July 27,2009 it was here..
         // aAdvance[n, A_AF_FINAL_RATE1]    := ;

			aAdvance[ n, A_AF_BERRY ]       := Daily->product
			aAdvance[ n, A_AF_PROCESS ]     := Daily->process
			aAdvance[ n, A_AF_GRADE ]       := Daily->grade
			aAdvance[ n, A_AF_FROM  ]       := Daily->date
			aAdvance[ n, A_AF_TO    ]       := Daily->date
		endif

      nFinal := max(Daily->(FinalPrice()),Daily->fin_price)
      // we check are there more than one Final Prices possible
      //  July 2009 we move to here
      if str(nFinal,12,3) <> str( 0,12,3)
         if str( aAdvance[n, A_AF_FINAL_RATE2],12,3) == str( 0,12,3)
            aAdvance[n, A_AF_FINAL_RATE2] := nFinal
         endif
         aAdvance[n, A_AF_FINAL_RATE1]    := nFinal

         // this checks are there Multiple Rates
         if !(str( aAdvance[n, A_AF_FINAL_RATE1],12,3) == ;
               str( aAdvance[n, A_AF_FINAL_RATE2],12,3) )
            aAdvance[n, A_AF_FINAL_MULTI] := .t.
         endif
      endif

		aAdvance[ n, A_AF_FROM     ] := min(Daily->date,aAdvance[n,A_AF_FROM])
		aAdvance[ n, A_AF_TO       ] := max(Daily->date,aAdvance[n,A_AF_TO])
		aAdvance[ n, A_AF_LBS      ] += Daily->net
      aAdvance[ n, A_AF_PAID     ] += round(Daily->net* nPrice,2)
		aAdvance[ n, A_AF_RECORDS  ] ++

      if str(Daily->prem_price,12,2) <> str(0,12,2) .and. ;
           nAdv == AFA_ADVANCE_1_PAYTYPE

			lFound := .f.
			for n := 1 to len(aPremium)
				if str(Daily->prem_price,12,2) == ;
					   str(aPremium[n, A_PREM_RATE],12,2) .and. ;
					Daily->product == aPremium[ n, A_PREM_BERRY ] .and. ;
					Daily->process == aPremium[ n, A_PREM_PROCESS ]

						lFound := .t.
						exit
				endif
			next

			if !lFound
				aadd( aPremium, A_PREM_STRU )
				n := len(aPremium)
            aPremium[ n, A_PREM_RATE]     := Daily->prem_price
            aPremium[ n, A_PREM_BERRY ]   := Daily->product
            aPremium[ n, A_PREM_PROCESS ] := Daily->process
            aPremium[ n, A_PREM_FROM  ]   := Daily->date
            aPremium[ n, A_PREM_TO    ]   := Daily->date
			endif
			aPremium[ n, A_PREM_FROM     ] := min(Daily->date,aPremium[n,A_PREM_FROM])
			aPremium[ n, A_PREM_TO       ] := max(Daily->date,aPremium[n,A_PREM_TO])
			aPremium[ n, A_PREM_LBS      ] += Daily->net
			aPremium[ n, A_PREM_PAID     ] += round(Daily->net*Daily->prem_price,2)
			aPremium[ n, A_PREM_RECORDS  ] ++

         nDaily4Week += round(Daily->net * Daily->prem_price,2)
		endif

      nDaily4Week += round(Daily->net * nPrice,2)

	endif
return( nil )

static function DailyUnPaidArrays()
	local n
	local lFound
	local nAdvanceRate
	local nFinal
	local nPremium

	if FindPrice( Daily->Product, Daily->Process, Daily->Date )
      nAdvanceRate := Daily->( TotAdvPrice())  // AdvancePrice(  )
      nFinal       := max(Daily->(FinalPrice()),Daily->fin_price)
      nPremium     := Daily->(AdvancePrem(  ))

		lFound := .f.
		for n := 1 to len(aAdvance)
			// Weird found bug in Aug 2013
			if str(nAdvanceRate,12,2) == str(aAdvance[n, A_AF_ADVANCE_RATE],12,2) .and. ;
				Daily->product == aAdvance[ n, A_AF_BERRY ] .and. ;
				Daily->process == aAdvance[ n, A_AF_PROCESS ] .and. ;
				Daily->grade == aAdvance[ n, A_AF_GRADE ]

					lFound := .t.
					exit
			endif
		next
		if !lFound
			aadd( aAdvance, A_AF_STRU )
			n := len(aAdvance)
			aAdvance[n, A_AF_ID]            := 0
			aAdvance[n, A_AF_ADVANCE_RATE]  := nAdvanceRate

			aAdvance[ n, A_AF_BERRY ]       := Daily->product
			aAdvance[ n, A_AF_PROCESS ]     := Daily->process
			aAdvance[ n, A_AF_GRADE ]       := Daily->grade
			aAdvance[ n, A_AF_FROM  ]       := Daily->date
			aAdvance[ n, A_AF_TO    ]       := Daily->date
		endif

      if str(nFinal,12,3) <> str( 0,12,3)
         if str( aAdvance[n, A_AF_FINAL_RATE2],12,3) == str( 0,12,3)
            aAdvance[n, A_AF_FINAL_RATE2] := nFinal
         endif

         aAdvance[n, A_AF_FINAL_RATE1] := nFinal
         // this checks are there Multiple Rates
         if !(str( aAdvance[n, A_AF_FINAL_RATE1],12,3) == ;
               str( aAdvance[n, A_AF_FINAL_RATE2],12,3) )
            aAdvance[n, A_AF_FINAL_MULTI] := .t.
         endif
      endif

		aAdvance[ n, A_AF_FROM     ] := min(Daily->date,aAdvance[n,A_AF_FROM])
		aAdvance[ n, A_AF_TO       ] := max(Daily->date,aAdvance[n,A_AF_TO])
		aAdvance[ n, A_AF_LBS      ] += Daily->net
		aAdvance[ n, A_AF_PAID     ] += round(Daily->net*nAdvanceRate,2)
		aAdvance[ n, A_AF_RECORDS  ] ++

		if str( nPremium,12,2) <> str(0,12,2)
			lFound := .f.
			for n := 1 to len(aPremium)
				if str( nPremium,12,2) == ;
					   str(aPremium[n, A_PREM_RATE],12,2) .and. ;
					Daily->product == aPremium[ n, A_PREM_BERRY ] .and. ;
					Daily->process == aPremium[ n, A_PREM_PROCESS ]

						lFound := .t.
						exit
				endif
			next

			if !lFound
				aadd( aPremium, A_PREM_STRU )
				n := len(aPremium)
				aPremium[ n, A_PREM_RATE]      := nPremium
				aPremium[ n, A_PREM_BERRY ]    := Daily->product
				aPremium[ n, A_PREM_PROCESS ]  := Daily->process
				aPremium[ n, A_PREM_FROM  ]    := Daily->date
				aPremium[ n, A_PREM_TO    ]    := Daily->date
			endif
			aPremium[ n, A_PREM_FROM     ] := min(Daily->date,aPremium[n,A_PREM_FROM])
			aPremium[ n, A_PREM_TO       ] := max(Daily->date,aPremium[n,A_PREM_TO])
			aPremium[ n, A_PREM_LBS      ] += Daily->net
			aPremium[ n, A_PREM_PAID     ] += round(Daily->net*nPremium,2)
			aPremium[ n, A_PREM_RECORDS  ] ++
		endif
	endif
return( nil )

