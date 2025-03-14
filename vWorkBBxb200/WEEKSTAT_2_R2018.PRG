// WeekStat_2_R2018         was: wkst2012.prg
// weekly Statements (i.e. regular advance)
// for 2012 - new format
// June 2012, revised minor in July 2013 for Depot & Text
// Aug 7, 2013 - very annoying bug with estimated final price!
// July 16, 2014 - GST related.   Also fixed a couple of spacing
//         related issues.  Also fixed a piece of redundant code

// Form - for the 2012 format we:
//     1.  Build Array of relevent transactions from ACCOUNT.DBF for 1 grower
//         Relates to a cheque ordinarily. (or an Unpaid Transaction).
//            a2012Account := { Sort Ord string,
//                              Account->(Recno()),
//                              { from Daily }  }
//     2.  For each element in the array of ACCOUNT.DBF we find
//         all tickets (in DAILY.DBF) and create a sub-array in a2012Account
//         This consists of {  Sort Ord string, Daily->(recno()) }
//                   (meaning and analogous structure).
//
//     3.  For unpaid, we can add a BLANK element to
//         to Account and then associate UnPaid Tickets...
//         At the risk of being inefficient we can also tally up
//         the containers directly from Data I guess.

//    We go through the a2012Account and print headings.
//    then any associated details are shown from the Sub Array

//    Then we print the outstanding container count.

//    One thing that can be a bit confusing is if you pay out more than
//    one advance (e.g. advance 1 and 2) on the same cheque, and there
//    is a receipt with both advance 1 & 2 on the same cheque, that
//    receipt will show Advance 1 & 2 in the "PAID OUT" column.  The
//    receipt will also show up twice (once under the Advance 1 pay out
//    and the 2nd time under the Advance 2 pay out).

//   (c) Copyright 2012,2013, 2014, 2018,2019 by Bill Hepler


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

#define  WIDTH_FLD_1_EMPTY          2
#define  WIDTH_FLD_2_DATE          13
#define  WIDTH_FLD_3_RECPT         13
#define  WIDTH_FLD_4_U_PRICE       10
#define  WIDTH_FLD_5_NET           14
#define     FLD_5_NET_PICTURE  '99,999,999,999'
//                              123456789_1234

#define  WIDTH_FLD_6_EXT_PRICE     15
#define  WIDTH_FLD_7_FINAL_U_PRICE 10

// Advance & Final have Same Structure.

#define   A_AF_ID            1      // Unique 1
#define   A_AF_ADVANCE_NO    2      // Nov 2001 - Unique 5 / Sort 5


#define A_ACCOUNT_RECNO        1
#define A_ACCOUNT_SORTORD      2
#define A_ACCOUNT_DAILY_ARRAY  3

#define A_DAILY_RECNO        1
#define A_DAILY_SORTORD        2

#define A_ADDED_2012_ACCOUNT    { Account->(recno()),  ;
   NameOf( LU_TRANSACT_TYPE_SORT_CODE , Account->Type) + dtos(Account->date) + Account->product + Account->process + str( Account->grade, 1) + str(Account->u_price,10,2), {}  }

#define A_ADDED_2012_DAILY     { Daily->(recno()),  ;
    Daily->depot+str(Daily->recpt,FLD_RECPT)+Daily->recPtLtr }

  //    The Daily->product etc SHOULD be redundant

// Need this:



#define A_ADDED_OLD_DAILY      { Daily->(recno()), '',0 }

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



#define   MAGIC_WIDTH_TO_LINEUP     1   // needed this, tired of looking for why, July 2014


// Deductions & Miscellaneous
//  just have the Record Number in Account....

static aBott[4],nPage, lAnyPrem
static dDate,nYear
static aContainer

// the Current Cheque (if any)
static dCheqDate

static aAccount := {}

static aAdvance
static aPremium  // Array of Premium rates
static aMisc     // Any Account->recno() except Deductions, Weekly, Premium
static aDeduct   // Deductions (Account->recno())

static nUnPaid  := 0,  nNewerPaid := 0, nPrevPaid  := 0
static nSameDay := 0,  nUnDeduct := 0

static aBalance[ MAX_NO_OF_GRADES ]
static aCurrent[ MAX_NO_OF_GRADES ]

static aGSTclasses4Grower := {}

// Cross Check to Make Sure we are reasonable.
static nDaily4Week, nAcct4Daily                                // , nAcct4Cheque
   // Cheque->amount = nDaily4Week
   // Cheque->amount = nAcct4Cheque
   // nAcct4Daily    = nDaily4Week

static nAdvance   := 0  // what Advance Number is this Paying...
// static lShowFinal := .f.

static dLastDaily
static nTotalGSTAmt := 0.00

function WeekStat_2_R2018( )
	local aWin, getList :={},nGrower, n, nCopies
	local nChoice
	local cTitle
	local lPrinted := .f.
	local aDBF1, aDBF2
	local cMsg1, cMsg2
	local cGroStatFor     := GRO_STATEMENT_FOR_WEEKLY
	local nStatementFmtID := WEEK_STATEMENT_FORMAT_2_REV_2018

	cTitle := 'Print '+var2char( nStatementFmtID )+'. '+'2012 type Format Weekly (Regular Advance) Statements'
	myBSGscreen( cTitle )
   msgLine('Finding the date of last Advance run....')

	if ! open4ChequeRun( DB_SHARED )
		close databases
		return( nil )
	endif

   // lShowFinal := sysValue( SYS_WEEK_STATEMENT_SUMMARY_FP )
	nCopies    := sysValue(SYS_DEFAULT_NO_STATEMENT_COPIES)
	nYear      := sysValue(SYS_CURRENT_YEAR)

	nGrower := 0
   aFill(aBott,space(FLD_STATEMENT_NOTES))

   aBott[1] := padr( sysValue( SYS_DEFAULT_ADV_STATEMENT_LINE1 ),FLD_STATEMENT_NOTES )
   aBott[2] := padr( sysValue( SYS_DEFAULT_ADV_STATEMENT_LINE2 ),FLD_STATEMENT_NOTES )

   Cheque->(OrdSetFocus(CHEQUE_DATE_ORD))
	Cheque->(dbSetFilter( {|| Cheque->cheqType == CHEQUE_TYPE_WEEKLY }))
	Cheque->(dbGoBottom())
	dDate := Cheque->date                         // date of last cheque run
	Cheque->(dbClearFilter( ))

   create window at 4, 8,20,72 title ;
	   'Statement '+ var2char( nStatementFmtID )+'. ' + StatementDesc( cGroStatFor, nStatementFmtID ) to aWin

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
			GET_MESSAGE 'We back date (if necessary) to this date'

      in window aWin @ 03,2 winsay 'For Grower: ' winget nGrower ;
			picture numBlankPic(FLD_GROWER) ;
			LOOKUP( LU_GROWER, ;
			'Enter a specific Grower to Print a Statement for one Grower Only')

      in window aWin @ 04,2 winsay 'Crop Year:  ' winget nYear picture '9999'
      in window aWin @ 05,2 winsay 'Copies of Statements' winget nCopies ;
			picture '9' valid nCopies >=1

      in window aWin @ 10,02 winsay 'Message:'
		for n:=1 to len(aBott)
         in window aWin @ 10 + n,5  winget aBott[n] GET_MESSAGE ;
          'Note first two lines are Set in General System Settings!'
		next

		read

		if lastkey() == K_ESC
			exit
		endif

		Cheque->(dbClearFilter())

		if selectPrn('WEEKSTAT_2_2018.TXT')
      	msgLine('Printer Selected for Statement Print .... Finding Data....')

			lPrinted := .f.

			do case
			case !empty(nGrower)
				if !ValidTest(V_GROWER,nGrower,VT_MESSAGE)
					loop
				endif

				Cheque->(dbSetFilter( {|| Cheque->cheqType==CHEQUE_TYPE_WEEKLY } ))
            Cheque->(OrdSetFocus( CHEQUE_GROWER_DATE_ORD ))

				if Cheque->(dbSeek( ;
						 str(Grower->number,FLD_GROWER)+str(nYear,4)+dtos(dDate), ;
						   HARDSEEK))

					PRINT_ON    RPT_OVERWRITE
					for n:=1 to nCopies
						if lPrinted
							nuFormFeed()
						endif
						the2012Statement( Cheque->series, Cheque->cheque )
						lPrinted := .t.
					next
					PRINT_OFF   RPT_COMPLETE_NO_EJECT

				else
					if !Cheque->(FindLast( ;
							 str(Grower->number,FLD_GROWER) + str(nYear,4)))
						PRINT_ON    RPT_OVERWRITE
						for n:=1 to nCopies
							if lPrinted
								nuFormFeed()
							endif
							the2012Statement(  space(FLD_SERIES), 0 )
							lPrinted := .t.
						next
						PRINT_OFF   RPT_COMPLETE_NO_EJECT
					else
						aDBF1 := Cheque->(saveDBF())
						cMsg1 := 'Cheque #: '+Cheque->series+' '+lStrim(Cheque->cheque)+'  '+shMdy(Cheque->date)
						aDBF2 := {}
						cMsg2 := ''
						Cheque->(dbClearFilter( ))
            		Cheque->(OrdSetFocus( CHEQUE_GROWER_DATE_ORD ))
						if Cheque->(dbSeek( ;
						 str(Grower->number,FLD_GROWER)+str(nYear,4)+dtos(dDate), ;
						   HARDSEEK))
						 	aDBF2 := Cheque->(saveDBF())
						 	cMsg1 := '1 - '+cMsg1
						 	cMsg2 := '2 - Cheque #: '+Cheque->series+' '+lStrim(Cheque->cheque)+'  '+shMdy(Cheque->date)
						else
							Cheque->(FindLast( ;
							 str(Grower->number,FLD_GROWER) + str(nYear,4)))
						 	if Cheque->number == Grower->number
						 		aDBF2 := Cheque->(saveDBF())
							 	cMsg1 := '1 - '+cMsg1
							 	cMsg2 := '2 - Cheque #: '+Cheque->series+' '+lStrim(Cheque->cheque)+'  '+shMdy(Cheque->date)
						 	endif
						endif

						Cheque->(restDBF( aDBF1 ))

						if empty( aDBF2 )
							nChoice := BsgChoice({ ;
								'The last weekly advance cheque for', ;
								'this grower was on '+medMDY(Cheque->date), ;
								'Cheque # '+Cheque->series+ lStrim(Cheque->cheque), ;
								'Do you wish to base the statement on', ;
								'this cheque or on any UnPaid Accounting Transactions?'}, ;
								{'This Chq','Unpaid','Cancel'})
							if nChoice >= 2
								nChoice++
							endif
						else
							nChoice := BsgChoice({ ;
								'The last weekly advance cheque for', ;
								'this grower was on '+medMDY(Cheque->date), ;
								cMsg1, ;
								'There is another cheque on the date requested that is not', ;
								'a regular Advance cheque', ;
								cMsg2,'', ;
								'Do you wish to base the statement on', ;
								'the 1st Cheque, the 2nd cheque or on unPaid Accounting Transactions?'}, ;
								{'1st Chq','2nd Chq', 'Unpaid','Cancel'})

						endif
						do case
						case nChoice==1
							PRINT_ON    RPT_OVERWRITE
							for n:=1 to nCopies
								if lPrinted
									nuFormFeed()
								endif
								the2012Statement( Cheque->series, Cheque->cheque)
								lPrinted := .t.
							next
							PRINT_OFF   RPT_COMPLETE_NO_EJECT
						case nChoice==2
							Cheque->(restDBF( aDBF2 ))

							PRINT_ON    RPT_OVERWRITE
							for n:=1 to nCopies
								if lPrinted
									nuFormFeed()
								endif
								the2012Statement( Cheque->series, Cheque->cheque)
								lPrinted := .t.
							next
							PRINT_OFF   RPT_COMPLETE_NO_EJECT

						case nChoice==3
							PRINT_ON    RPT_OVERWRITE
							for n:=1 to nCopies
								if lPrinted
									nuFormFeed()
								endif
								the2012Statement( space(FLD_SERIES),0)
								lPrinted := .t.
							next
							PRINT_OFF   RPT_COMPLETE_EJECT
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
								if lPrinted
									nuFormFeed()
								endif
								the2012Statement( TempCheq->series, TempCheq->cheque, .f. )
								lPrinted := .t.
							next
						endif
						TempCheq->(dbSkip())
					enddo
					TempCheq->(dbCloseArea())
					PRINT_OFF   RPT_COMPLETE_EJECT

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



static function AcctTypeDescStr( )
	local cReturn := ''

	do case
	// case Account->type== TT_STD_DEDUCTION
	//	cReturn := alltrim( NameOf( LU_TRANSACTION_TYPE, Account->type )) + ;
	//	  ' for '+ Account->product+'/'+Account->process+'/'+ ;
	//		  str(Account->grade, FLD_GRADE)

	case (Account->type $  TT_BERRY_ADVANCE_1 + 'z'+ TT_BERRY_ADVANCE_2+'z'+TT_BERRY_ADVANCE_3 ) ;
	             .or. ;
	      Account->type == TT_FINAL_BERRY
	   cReturn := alltrim( NameOf( LU_TRANSACTION_TYPE, Account->type )) + ;
	     ' for '+ alltrim(NameOf( LU_PRODUCT, Account->product ))+ ;
	       ' '+alltrim(NameOf(LU_PROCESS_TYPE, Account->process))+' #'+lStrim(Account->grade)
	otherwise
		cReturn := alltrim(NameOf( LU_TRANSACTION_TYPE, Account->type ) )
		if !empty( Account->product ) .or. !empty( Account->process) .or. Account->grade > 0
			cReturn += ' for'
			if !empty(Account->product )
				cReturn +=' '
				cReturn += alltrim(NameOf( LU_PRODUCT, Account->product ))
			endif
			if !empty(Account->process )
				cReturn += ' '
				cReturn += alltrim(NameOf( LU_PROCESS_TYPE, Account->process ))
			endif
			if Account->grade > 0
				cReturn += ' #'
				cReturn += lStrim(Account->grade)
			endif
		endif
	endcase
return( cReturn )


static function the2012Statement( cSeries, nCheque  )
   local n, n1, n2
	local nContainLn
	local nSubTotDollar
	local nSubTotWgt
	local lPrinted := .f.
   local lTmp := .f.
	local c
	local aAdvanceLbs[ MAX_NO_OF_ADVANCES ]
	local aAdvanceAmt[ MAX_NO_OF_ADVANCES ]
	local nAdvanceNo := 0
	local nFinalLbs  := 0
	local nFinalAmt  := 0.00
	local nOtherAmt  := 0.00  // do NOT care about Pounds for This
	local nDeductAmt := 0.00
   local nDeductStd := 0.00
   local nDeductWt  := 0
   local cDeductPr  := replicate('z', WIDTH_FLD_4_U_PRICE  )
	local nCol, nTmp

	local aMsg := {}

   msgLine('Actual prep of statement for Chq# '+cSeries + var2char( nCheque)+'...' )

	aFill( aAdvanceLbs,   0 )
	aFill( aAdvanceAmt, 0.00 )
	aGSTclasses4Grower := {}

   nDaily4Week  := 0.00
   StopCompilerWarning( nDaily4Week )
   nAcct4Daily  := 0.00
   StopCompilerWarning( nAcct4Daily ) // 2BFIXED.. May 2018

   //    nAcct4Cheque := 0.00

	nSubTotDollar := 0.00
	nSubTotWgt    := 0

	aFill( aBalance,0)
	aFill( aCurrent,0)

	nTotalGSTAmt := 0.00

	nPage := 1

	aContainer := ContArray()        //  Ok June 2000

	lAnyPrem := .f.
   StopCompilerWarning( lAnyPrem )

	// Fills main arrays of Account Records and
	// also date of most recent Daily Transaction
	FillArrays2012( cSeries, nCheque)

	// uses date of Most recent Daily Transaction
	// to determine how many containers are out.
	ContainersEtc( )                    //

	StateHead()                     //
	ReceiptHead()                       //

	// Sorts by Account Record (then by Receipt)
	aSort( aAccount, NIL, NIL, { |x,y| ;
		x[A_ACCOUNT_SORTORD]  <   y[A_ACCOUNT_SORTORD]  } )

	for n :=1 to len( aAccount )
		nAdvanceNo := 0
		aSort( aAccount[ n,A_ACCOUNT_DAILY_ARRAY ] , NIL, NIL, { |x,y| ;
			x[A_DAILY_SORTORD]  <   y[A_DAILY_SORTORD]  } )

		Account->(dbGoTo( aAccount[ n, A_ACCOUNT_RECNO ] ))

		if Account->type <> TT_GST_TAX
			// We do NOT print anything about GST in this Section...

			do case
			case Account->type ==  TT_ADV_CONTAINER_ONLY
				if len( aAccount ) == n .and. !lPrinted
					// this should never come up actually
					nuQprnOut( ' '+alltrim( AcctTypeDescStr( )) + ' as of '+shMdy( Account->date) )
				endif
			case Account->type == TT_STD_DEDUCTION .or. ;
					 Account->type == TT_TIME_PREMIUM
				nuQprnOut(  AcctTypeDescStr( ) )
				lPrinted := .t.

			otherwise
				nuQprnOut( alltrim( AcctTypeDescStr( ) )+ ;
				  ' as of '+shMdy( Account->date) )
				lPrinted := .t.
				do case
				case Account->type == TT_BERRY_ADVANCE_1
					nAdvanceNo := 1
				case Account->type == TT_BERRY_ADVANCE_2
					nAdvanceNo := 2
				case Account->type == TT_BERRY_ADVANCE_3
					nAdvanceNo := 3
				endcase
			endcase

			if !empty( Account->class )
				nuQprnOut( ' ',space(2)+ NameOf( LU_DEDUCTION_CLASS, Account->class) )
			endif
			if !empty( Account->desc )
				nuQprnOut( ' ',space(4), Account->desc )
			endif

			do case
			case Account->type ==  TT_ADV_CONTAINER_ONLY
				ShowProg( str(n,6) )

			case Account->type == TT_STD_DEDUCTION .or. ;
					 Account->type == TT_TIME_PREMIUM

				nDeductStd += Account->dollars
				nDeductWt  += Account->lbs

				nuQprnOut( space( WIDTH_FLD_1_EMPTY ) )

				nuQQprnOut( padc( shMDY(Account->date ), WIDTH_FLD_2_DATE  ))
				nuQQprnOut( space( WIDTH_FLD_3_RECPT ) )

				// c := '$' + str( Account->u_price , 8,5)
				c :=  alltrim(str( Account->u_price , 9,5))

				for n1 := 1 to 3
					if right(c,1)=='0'
						n2 := len( c )
						c  := left( c, n2-1)
					else
						exit
					endif
				next

				do case
				case len(c) <= WIDTH_FLD_4_U_PRICE -3
					c := '$ '+c
				case len(c) == WIDTH_FLD_4_U_PRICE -2
					c := '$'+c
				endcase

				do case
				case left(cDeductPr,1)=='z'
					cDeductPr := c
				case !(cDeductPr == c)
					cDeductPr := space( WIDTH_FLD_4_U_PRICE )
				endcase

				nuQQprnOut( padl( c , WIDTH_FLD_4_U_PRICE ) )

				nuQQprnOut(  transform(  Account->lbs,  FLD_5_NET_PICTURE  ) )
				nuQQprnOut( DollarStr( Account->dollars, WIDTH_FLD_6_EXT_PRICE ) )
				nuQQprnOut( ' *')

			case Account->type == TT_DEDUCT .or. Account->type == TT_MISCELLANEOUS

				if Account->type == TT_DEDUCT
					nDeductAmt += Account->dollars
				else
					nOtherAmt += Account->dollars
				endif
				// nuQQprnOut( space(  WIDTH_FLD_4_U_PRICE ) )
				// nuQQprnOut(  space( WIDTH_FLD_5_NET  ) )
				// if MAGIC_WIDTH_TO_LINEUP >= 1
				// 	nuQQprnOut(  space(MAGIC_WIDTH_TO_LINEUP ) )
				// endif

				nCol := nuPrnColumn()
				// target is:
				//    WIDTH_FLD_1_EMPTY   +  WIDTH_FLD_2_DATE  +  WIDTH_FLD_3_RECPT  +
				//   WIDTH_FLD_4_U_PRICE  +  WIDTH_FLD_5_NET   +
				nTmp := WIDTH_FLD_1_EMPTY   +  WIDTH_FLD_2_DATE  +  WIDTH_FLD_3_RECPT  + ;
				      WIDTH_FLD_4_U_PRICE  +  WIDTH_FLD_5_NET
				if Num2NotEqual0( nTmp -nCol ) .and. nTmp-nCol >= 1
					nuQQprnOut( space( nTmp - nCol ))
				endif

				nuQQprnOut( DollarStr( Account->dollars, WIDTH_FLD_6_EXT_PRICE ) )
				// nuQQprnOut( ' *')
				nSubTotDollar += Account->dollars  // Added in July 2014

			otherwise

				// Look to see about what transactions are tagged in Daily
				for n1 := 1 to len( aAccount[n, A_ACCOUNT_DAILY_ARRAY ] )
					Daily->(dbGoTo( aAccount[n, A_ACCOUNT_DAILY_ARRAY, n1, A_DAILY_RECNO ] ))

					Daily2012Print( Account->type )

					if NearPageBottom( 7 )
						nuQprnOut()
						nuQprnOut( ' Continued on next page...')
						nuFormFeed()
						StateHead(  )
						ReceiptHead(  )
					ENDIF

					nSubTotDollar += round( Daily->net * Account->u_price, 2 )
					nSubTotWgt    += Daily->net
				next

				do case
				case nAdvanceNo > 0
					aAdvanceAmt[ nAdvanceNo ] += Account->dollars
					aAdvanceLbs[ nAdvanceNo ] += Account->lbs
				case Account->type == TT_FINAL_BERRY
					nFinalAmt += Account->dollars
					nFinalLbs += Account->lbs
				case Account->type == TT_DEDUCT .or. Account->type == TT_STD_DEDUCTION
					nDeductAmt += Account->dollars
				otherwise
					nOtherAmt += Account->dollars
				endcase

				if len( aAccount[n, A_ACCOUNT_DAILY_ARRAY ] ) > 1
					// we only print if we need to !
					nuQprnOut(  space( WIDTH_FLD_1_EMPTY ))
					nuQQprnOut( padr( '* SubTotal:', WIDTH_FLD_2_DATE  ))
					nuQQprnOut( space( WIDTH_FLD_3_RECPT ))
					nuQQprnOut( space( WIDTH_FLD_4_U_PRICE ))

					nuQQprnOut( transform( nSubTotWgt,  FLD_5_NET_PICTURE ) )
					nuQQprnOut( DollarStr( nSubTotDollar, WIDTH_FLD_6_EXT_PRICE) )
					nuQQprnOut( ' *')
				endif

				nSubTotDollar := 0.00
				nSubTotWgt    := 0
			endcase

			nuQprnOut()

			/*	 -- don't think this is needed
			if empty(cSeries) .and. nCheque==0
				DailyUnPaidArrays()
			else
				DailyPaidArrays()
			endif
			*/
		endif
	next

	if n >= 1
		if Account->type <>  TT_ADV_CONTAINER_ONLY .and. ;
		   Account->type <> TT_STD_DEDUCTION .and. ;
			Account->type <> TT_TIME_PREMIUM

			if NearPageBottom( 9 )
				nuFormFeed()
				StateHead()
			endif

			nuQprnOut(  space( WIDTH_FLD_1_EMPTY ))
			nuQQprnOut( padr( '* SubTotal:', WIDTH_FLD_2_DATE  ))
			nuQQprnOut( space( WIDTH_FLD_3_RECPT ))
			nuQQprnOut( space( WIDTH_FLD_4_U_PRICE ))

			if num2Equal0( nSubTotWgt)
				nuQQprnOut( space( WIDTH_FLD_5_NET ) )
			else
				nuQQprnOut( transform( nSubTotWgt,  FLD_5_NET_PICTURE ) )
			endif
			nuQQprnOut( DollarStr( nSubTotDollar, WIDTH_FLD_6_EXT_PRICE))
			nuQQprnOut( ' *')
		endif
	endif

	nuQprnOut()
	if NearPageBottom( 7 )
		nuFormFeed()
		StateHead()
	endif

	nuQprnOut(' Summary Totals')
	for n := 1 to len( aAdvanceLbs )
		if num2NotEqual0(aAdvanceLbs[n]) .or. num2NotEqual0(aAdvanceAmt[n])
			if NearPageBottom( 6 )
				nuFormFeed()
				StateHead()
			endif

			nuQprnOut(  space( WIDTH_FLD_1_EMPTY ))
			nuQQprnOut( padr( 'Advance #'+str(n,1), WIDTH_FLD_2_DATE  ))
			nuQQprnOut( space( WIDTH_FLD_3_RECPT ))
			nuQQprnOut( space( WIDTH_FLD_4_U_PRICE ))

			nuQQprnOut( transform( aAdvanceLbs[ n ],  FLD_5_NET_PICTURE ) )

			nuQQprnOut( DollarStr( aAdvanceAmt[n], WIDTH_FLD_6_EXT_PRICE) )
			nuQQprnOut( ' **')
		endif
	next

	if num2NotEqual0( nFinalLbs) .or. num2NotEqual0( nFinalAmt)
		if NearPageBottom( 6 )
			nuFormFeed()
			StateHead()
		endif

		nuQprnOut(  space( WIDTH_FLD_1_EMPTY ))
		nuQQprnOut( padr( 'Final Pays', WIDTH_FLD_2_DATE  ))
		nuQQprnOut( space( WIDTH_FLD_3_RECPT ))
		nuQQprnOut( space( WIDTH_FLD_4_U_PRICE ))

		nuQQprnOut( transform( nFinalLbs,  FLD_5_NET_PICTURE ) )

		nuQQprnOut( DollarStr( nFinalAmt, WIDTH_FLD_6_EXT_PRICE) )
		nuQQprnOut( ' **')
	endif

   if num2NotEqual0( nDeductStd)
		if NearPageBottom( 5 )
			nuFormFeed()
			StateHead()
		endif

		nuQprnOut(  space( WIDTH_FLD_1_EMPTY ))
      nuQQprnOut( padr( 'Reg Marketing Deduction', ;
       WIDTH_FLD_2_DATE +WIDTH_FLD_3_RECPT-1  ))
      nuQQprnOut( space( 1 ))

      if empty(cDeductPr) .or. left(cDeductPr,1)=='z'
         nuQQprnOut( space( WIDTH_FLD_4_U_PRICE ))
      else
         nuQQprnOut( padl( alltrim(cDeductPr),WIDTH_FLD_4_U_PRICE ))
      endif

      // nuQQprnOut( space( WIDTH_FLD_5_NET ) )
      if left(str( nDeductWt,WIDTH_FLD_5_NET),1)=='*'
         nuQQprnOut( space( WIDTH_FLD_5_NET ) )
      else
         // nuQQprnOut( transform( nSubTotWgt,  FLD_5_NET_PICTURE ) )
			// corrected July 18, 2014
			if Num2Equal0( nDeductWt)
				nuQQprnOut( WIDTH_FLD_5_NET)
			else
				nuQQprnOut( transform( nDeductWt,  FLD_5_NET_PICTURE ) )
			endif
      endif

      nuQQprnOut( DollarStr( nDeductStd, WIDTH_FLD_6_EXT_PRICE) )
		nuQQprnOut( ' **')
	endif

	if num2NotEqual0( nOtherAmt)
		if NearPageBottom( 5 )
			nuFormFeed()
			StateHead()
		endif

		nuQprnOut(  space( WIDTH_FLD_1_EMPTY ))
		nuQQprnOut( padr( 'Other', WIDTH_FLD_2_DATE  ))
		nuQQprnOut( space( WIDTH_FLD_3_RECPT ))
		nuQQprnOut( space( WIDTH_FLD_4_U_PRICE ))

		nuQQprnOut( space( WIDTH_FLD_5_NET ) )

		nuQQprnOut( DollarStr( nOtherAmt, WIDTH_FLD_6_EXT_PRICE) )
		nuQQprnOut( ' **')
	endif

	if num2NotEqual0( nDeductAmt)
		if NearPageBottom( 5 )
			nuFormFeed()
			StateHead()
		endif

		nuQprnOut(  space( WIDTH_FLD_1_EMPTY ))
		nuQQprnOut( padr( 'Deductions', WIDTH_FLD_2_DATE  ))
		nuQQprnOut( space( WIDTH_FLD_3_RECPT ))
		nuQQprnOut( space( WIDTH_FLD_4_U_PRICE ))

		nuQQprnOut( space( WIDTH_FLD_5_NET ) )

		nuQQprnOut( DollarStr( nDeductAmt, WIDTH_FLD_6_EXT_PRICE) )
		nuQQprnOut( ' **')
	endif

	if num2NotEqual0( nTotalGSTamt )
		if NearPageBottom( 5 )
			nuFormFeed()
			StateHead()
		endif

		nuQprnOut(  space( WIDTH_FLD_1_EMPTY ))
		if len( aGSTclasses4Grower  )== 1
			nuQQprnOut( padr('GST Tax '+NameOf( LU_ALL_ACCOUNT_CLASSES , aGSTclasses4Grower[1]), ;
			  WIDTH_FLD_2_DATE + WIDTH_FLD_3_RECPT + WIDTH_FLD_4_U_PRICE +  WIDTH_FLD_5_NET ) )
		else
			nuQQprnOut( padr( 'GST Tax', WIDTH_FLD_2_DATE  ))
			nuQQprnOut( space( WIDTH_FLD_3_RECPT ))
			nuQQprnOut( space( WIDTH_FLD_4_U_PRICE ))
			nuQQprnOut( space( WIDTH_FLD_5_NET ) )
		endif

		nuQQprnOut( DollarStr( nTotalGSTamt, WIDTH_FLD_6_EXT_PRICE) )
		nuQQprnOut( ' **')
	endif


	/* -----------------------
	nuQprnOut(  space( WIDTH_FLD_1_EMPTY ))
	nuQQprnOut( padr( '** TOTAL:', WIDTH_FLD_2_DATE  ))
	nuQQprnOut( space( WIDTH_FLD_3_RECPT ))
	nuQQprnOut( space( WIDTH_FLD_4_U_PRICE ))

	if num2Equal0( nTotWgt )
		nuQQprnOut( space( WIDTH_FLD_5_NET ))
	else
		nuQQprnOut( transform( nTotWgt,  FLD_5_NET_PICTURE ) )
	endif

	nuQQprnOut( DollarStr( nTotDollar, WIDTH_FLD_6_EXT_PRICE) +' **')
	--------------- */

	if NearPageBottom( 5 )
		nuFormFeed()
		StateHead()
	endif

	nuQprnOut()

   if Cheque->amount > 0.00 .and. Cheque->cheque == nCheque .and. nCheque > 0
		nuQprnOut(  space( WIDTH_FLD_1_EMPTY ))
		nuQQprnOut( padr( 'Cheque: '+ cSeries,WIDTH_FLD_2_DATE    ))
		nuQQprnOut( padr( lStrim( nCheque ), WIDTH_FLD_3_RECPT ))
		nuQQprnOut( space( WIDTH_FLD_4_U_PRICE ))
		nuQQprnOut( space( WIDTH_FLD_5_NET ))

	   nuQQprnOut( DollarStr( Cheque->amount, WIDTH_FLD_6_EXT_PRICE) )
	   nuQQprnOut( ' ***' )
	   nuQprnOut()
   endif


	// determine how many lines
	nContainLn := 0
	for n := 1 to len(aContainer)
		if aContainer[n, A_CONT_IN] <> 0 .or. aContainer[n, A_CONT_OUT] <> 0 .or. ;
				aContainer[n, A_CONT_ISSUED] <> 0
			nContainLn ++
		endif
	next

	// Do not think this is needed
	//      summaryB( nContainLn, cSeries, nCheque )

	if nContainLn <> 0 // we don't need to print anything if ZERO....
		// Simplify this - Containers

      if nAdvance == 1
         ContInfoPrint(  )
      endif
	endif

   lTmp := .f.
	for n:=1 to len(aBott)
		if !empty(aBott[n])
			if NearPageBottom( 7 )
				nuQprnOut( )
				nuQprnOut( 'Continued on next page...')
				nuFormFeed()
				StateHead()
            nuQprnOut( '  ' )
         endif
         if !lTmp
            nuQprnOut( '  ' )
         endif
         lTmp := .t.
			nuQprnOut( padc('  '+aBott[n],82) )
		endif
	next

	aMsg := {}
	if nUnPaid > 0
		aadd( aMsg, 'There are additional items charged to this account, but not yet paid out')
	endif
	if nUnDeduct > 0
		aadd( aMsg, 'There are additional items that will be deducted from this account later')
	endif
	if nNewerPaid > 0
		aadd( aMsg, 'There are transactions paid out after this date that are not included in the Paid Out column')
	endif
	if nPrevPaid > 0
		aadd( aMsg, 'The Paid Out column includes items paid out previously')
	endif
	if nSameDay > 0
		aadd( aMsg, 'More than one cheque was issued on the same day.')
	endif

	if !NearPageBottom( 4 + len( aMsg ) )
		if len( aMsg ) >= 1
			PrinterCtrl( PRN_CTRL_17_CPI )
			nuQprnOut()
			for n := 1 to len( aMsg )
				nuQprnOut( space( 10 )+aMsg[n] )
			next
		endif

		//    The PAID OUT column shows items which have been actually paid out (by cheque) on or before '+shMdy( date )+'.')
		// it DOES include items that have only been "vouchered" to the account.
		nuQprnOut()
		PrinterCtrl( PRN_CTRL_12_CPI )
		nuQprnOut(' Statement End')
	endif

RETURN( nil )


static function FillArrays2012( cSeries,nCheque )
   // also sets nAdvance
   local aDBF
   local lFound

	msgLine('Cheque Info for '+lStrim(Grower->number))

	dLastDaily := ctod('01/01/1980')
	nUnPaid := nNewerPaid := nPrevPaid := nUnDeduct :=  nSameDay := 0

   nAdvance := 0

	aAdvance := {}
	aPremium := {}
	aMisc    := {}
	aDeduct  := {}
	aAccount := {}

   Audit->(OrdSetFocus( AUDIT_ACCT_DAY_ORD ))
   Daily->(OrdSetFocus( DAILY_ID_ORD ))

	// this section not done yet !

	if empty(cSeries) .or. empty(nCheque)
		// no cheques for year
		dCheqDate := dDate

      Account->(OrdSetFocus( ACCOUNT_NUMBER_ORD ))
		Account->(dbSeek( str( Grower->number, FLD_NUMBER) + str(nYear,4),HARDSEEK))
		// Builds a list of Account Records which relate to this
		// Builds a list of Daily Records which relate to this
		do while Account->number==Grower->number .and. !Account->(eof()) .and. ;
				Account->year == nYear
			if empty(Account->series) .and. Account->cheque==0 .and. ;
			   Account->date <= dCheqDate
				AccumuFromAccount()
			endif
			Account->(dbSkip())
		enddo
	else
		// July 25, 2012
		Cheque->(dbCLearFilter())
      Cheque->(OrdSetFocus( CHEQUE_CHEQUE_NO_ORD ))
		if !Cheque->(dbSeek( cSeries + str(nCheque, FLD_CHEQUE), HARDSEEK ))
			appError(APP_ERR_WEEK_STATE_CHEQUE_FIND, { ;
				'Can not find the Cheque for Grower '+lStrim(Grower->number), ;
				'Cheque Series/Number='+cSeries+str(nCheque,10), ;
				'First attempt to find a cheque' })
			return( .f. )
		endif

		// this is the Current Cheque
		dCheqDate := Cheque->date

		// now we find all Associated Transactions
      Account->(OrdSetFocus( ACCOUNT_CHEQUE_ORD))
		Account->(dbSeek( cSeries+str(nCheque,FLD_CHEQUE)) )
		do while Account->series==cSeries .and. nCheque==Account->cheque ;
				.and. !Account->(eof())
			AccumuFromAccount()
			Account->(dbSkip())
		enddo
		Account->(OrdSetFocus( ACCOUNT_NUMBER_ORD))
		Account->(dbSeek( str( Grower->number, FLD_GROWER), HARDSEEK))
		do while Account->number==Grower->number .and. !Account->(eof())
			do case
			case empty( Account->series ) .and. num2Equal0( Account->cheque)
				if Account->dollars > 0.00
					nUnPaid ++
				else
					nUnDeduct ++
				endif
			case Account->date > dDate .and. Account->series <> cSeries .and. ;
			     Account->cheque <> nCheque
			   nNewerPaid ++
			case Account->series==Cheque->series .and. Account->cheque==Cheque->cheque
				showProg('Chk..')
			otherwise
				// figure it out
				showProg('Hmm..')
				aDBF := Cheque->(saveDBF())

				if Cheque->Series == Account->series .and. ;
				   Cheque->cheque == Account->cheque
				   lFound := .t.
				else
			      Cheque->(OrdSetFocus( CHEQUE_CHEQUE_NO_ORD ))
					lFound := Cheque->(dbSeek( Account->Series + str(Account->Cheque, FLD_CHEQUE), HARDSEEK ))
				endif

				if lFound
					do case
					case Cheque->date > dDate
						nNewerPaid++
					case Cheque->date < dDate
						nPrevPaid++
					case Cheque->series == cSeries .and. Cheque->cheque < nCheque
						// same date, but was paid on earlier cheque
						nPrevPaid ++
					otherwise
						// Can not tell really, but they should be included on this statement
						nSameDay ++
					endcase
				else
					appError(APP_ERR_WEEK_STATE_CHEQUE_FIND2, { ;
					'Can not find the Cheque for Grower '+lStrim(Grower->number), ;
					'Cheque Series/Number='+Account->Series+str(Account->Cheque,10), ;
					'Cross check of payments test' })
				endif
				Cheque->(restDbf( aDBF ))
			endcase

			Account->(dbSkip())
		enddo
	endif
   Cheque->(dbClearFilter())

return( nil )

static function AccumuFromAccount()
	local lFound
	local n

	do case
	case Account->type== TT_BERRY_ADVANCE_1
		nAcct4Daily += Account->dollars
		nAdvance := max( nAdvance, 1)
	case Account->type== TT_BERRY_ADVANCE_2
		nAcct4Daily += Account->dollars
		nAdvance := max( nAdvance, 2)
	case Account->type== TT_BERRY_ADVANCE_3
		nAcct4Daily += Account->dollars
		nAdvance := max( nAdvance, 3)
	case Account->type== TT_TIME_PREMIUM
		nAcct4Daily += Account->dollars
		nAdvance := max( nAdvance, 1)
	case Account->type== TT_STD_DEDUCTION
		// weekly deductions are shown in Summary Form Only
		// directly from the Account File
		aadd(aDeduct, Account->(recno()))
		nAdvance := max( nAdvance, 1)
	case Account->type== TT_DEDUCT
		aadd(aDeduct, Account->(recno()))
	case Account->type == TT_ADV_CONTAINER_ONLY
		if str(Account->dollars ,12,2) <> str(0,12,2)
			appError(APP_ERR_CONTAINER_AMT1, { ;
				'Container only transaction has charge', ;
				'Grower '+lStrim(Grower->number) })
			aadd(aMisc, Account->(recno()))
		endif
		nAdvance := max( nAdvance, 1)  // could be any actually
	case Account->type == TT_GST_TAX
		nTotalGSTAmt += Account->dollars
		lFound := .f.
		for n := 1 to len( aGSTclasses4Grower )
			if aGSTclasses4Grower[n]==Account->class
				lFound := .t.
			endif
		next
		if !lFound
			aadd(aGSTclasses4Grower, Account->class )
		endif
	otherwise
		if str(Account->dollars,12,2) <>str(0,12,2)
			aadd(aMisc, Account->(recno()))
		endif
	endcase
	// nAcct4Cheque += Account->dollars

	// We don't print GST Details on this report.
	if Account->type <> TT_GST_TAX
		aadd( aAccount, A_ADDED_2012_ACCOUNT )
		// This step finds any Transactions associated
		//  with this entry in Account - these may or may not
		//  actually print, but at least we have them!
		Acc2Daily2012(  )
	endif

return( nil )

static function ContainersEtc( )

   Daily->(OrdSetFocus(DAILY_GROWER_ORD))
	Daily->(dbSeek( str(Grower->number,FLD_GROWER)+str(nYear,4),HARDSEEK))

	do while Daily->number==Grower->number .and. year(Daily->date)==nYear ;
			.and. !Daily->(eof())

		if Daily->date <= dLastDaily
      	ContainerCount()
		endif

		Daily->(dbSkip())
	enddo

return( nil )


static Function StateHead()
	local aRay := {}
	local n

	PrinterCtrl( PRN_CTRL_12_CPI )
	nuQprnOut( 'As of '+padr( shMdy(dDate),12)+  padc( TheClientName( ) ,62)  + ;
	 padl('Page '+lStrim( nPage),7) )

   if nAdvance <> 0
      nuQprnOut( space(18)+ padc("Statement of Harvest Season Advance #"+ ;
       lStrim(nAdvance)+ " for Berry Crop",62) )
   else
      nuQprnOut( space(18) +padc("Statement of Harvest Season Advance for Berry Crop",62) )
   endif

	nuQprnOut()
	if nPage<>1  // Only Print full address on Page 1
		nuQprnOut( space( 6 )+ padr(alltrim(Grower->Name),50)+ '   Grower# '+lStrim(Grower->number)  )
	else
		aRay := { padr(alltrim(Grower->Name),50)+ '   Grower# '+lStrim(Grower->number)  }

		if !empty( Grower->street )
			aadd( aRay, Grower->street )
		endif

		if !empty( Grower->city )
			aadd( aRay, alltrim(Grower->city) + ' '+ Grower->prov + '  '+ Grower->pcode )
		endif

		nuQprnOut('')
		for n := 1 to len( aRay )
			nuQprnOut( space( 6 )+ aRay[ n ])
		next
	endif

   nuQprnOut('')
   nuQprnOut('')

	nPage ++
RETURN( nil )

static function ReceiptHead()

	nuQprnOut(  space( WIDTH_FLD_1_EMPTY ))
	nuQQprnout( space( WIDTH_FLD_2_DATE ))
	nuQQprnout( padl('Receipt ', WIDTH_FLD_3_RECPT ))
	nuQQprnOut( padl('Price/LB', WIDTH_FLD_4_U_PRICE ))
	nuQQprnOut( padl('Weight of', WIDTH_FLD_5_NET ))
	nuQQprnOut( padl('Extended', WIDTH_FLD_6_EXT_PRICE ))
	nuQQprnOut( padl('Final', WIDTH_FLD_7_FINAL_U_PRICE ))
	nuQQprnOut( padl('Paid', WIDTH_FLD_7_FINAL_U_PRICE ))

	nuQprnOut(  space( WIDTH_FLD_1_EMPTY ))
	nuQQprnout( padc( 'Date', WIDTH_FLD_2_DATE ))
	nuQQprnout( padl('Number ', WIDTH_FLD_3_RECPT ))
	nuQQprnOut( padl('Paid ', WIDTH_FLD_4_U_PRICE ))
	nuQQprnOut( padl('Berries ', WIDTH_FLD_5_NET ))
	nuQQprnOut( padl('Price ', WIDTH_FLD_6_EXT_PRICE ))
	nuQQprnOut( padl('Unit Rate', WIDTH_FLD_7_FINAL_U_PRICE ))
	nuQQprnOut( padl('Out', WIDTH_FLD_7_FINAL_U_PRICE ))

	nuQprnOut(  REPLICATE('=',78 + WIDTH_FLD_7_FINAL_U_PRICE ) )
	nuQprnOut(  )

RETURN( nil )


static function Daily2012Print( cAccountType )
	//	local n
   local nPrice
   local lPrn := .f.
   local aDBF1, aDBF2, aDBF3, aDBF4
   local nDayUniq, nAcctUniq
   local nPosted, nPaid, nPaidBefore

	nuQprnOut( space( WIDTH_FLD_1_EMPTY ))
	nuQQprnOut( padc( shMDY(Daily->DATE), WIDTH_FLD_2_DATE ) )

	if MultiDepot()
		nuQQprnOut( padl( Daily->Depot + '-'+lStrim(  Daily->RECPT ) + alltrim(Daily->recptltr), WIDTH_FLD_3_RECPT )  )
	else
		nuQQprnOut( padl( str( Daily->RECPT,FLD_RECPT ) + padc(Daily->recptltr, 3), WIDTH_FLD_3_RECPT )  )
	endif

	do case
	case str(Daily->net,12,2) == str(0,12,2)
      nuQQprnOut(  '  Containers Only')

	case empty(Daily->product) .and. !empty(Daily->process)
      nuQQprnOut(  '  Product EMPTY - '+Daily->process )
		appError(APP_ERR_PRODUCT_PROCESS, ;
				{'Empty Product, Process='+Daily->process })
	otherwise
		nuQQprnOut(  padl( '$ '+lStrim( Account->u_price, 2),WIDTH_FLD_4_U_PRICE )  )
		nuQQprnOut(  transform(Daily->net  ,  FLD_5_NET_PICTURE  )    )
		nuQQprnOut(  dollarStr( round(Daily->net * Account->u_price  ,2 ), WIDTH_FLD_6_EXT_PRICE )  )

		if cAccountType $ TT_BERRY_ADVANCE_1 +'~'+ TT_BERRY_ADVANCE_2 + '~'+ ;
		                  TT_BERRY_ADVANCE_3 +'~'+ TT_FINAL_BERRY

         if Daily->(fValidPrice( ) )  // Aug 2013 Fixed!
            nPrice :=  Daily->(finalPrice())
            if num3NotEqual0( nPrice )
               nuQQprnOut(  dollarStr( nPrice , WIDTH_FLD_7_FINAL_U_PRICE)  )
               lPrn := .t.
            endif
         endif
		endif

		if !lPrn
			nuQQprnOut(  space( WIDTH_FLD_7_FINAL_U_PRICE )  )
		endif
		// Now go figure out about Total Paid for Receipt

		aDBF1 := Account->(SaveDBF())
		aDBF2 := Daily->(SaveDBF())
		aDBF3 := Audit->(SaveDBF())
		aDBF4 := Cheque->(SaveDBF())

		// Steps
		//    Go through Audit for this Daily record
		//    For each Audit is there an Account transaction ?
		//    For the Account Transaction is there a Cheque ?

		nPosted       := 0.00
		nPaid         := 0.00
		nPaidBefore   := 0.00

		nDayUniq := Daily->DAY_UNIQ

		Account->( OrdSetFocus( ACCOUNT_LINK_ORD     ))
		Audit->(   OrdSetFocus( AUDIT_DAY_ACCT_ORD   ))
		Cheque->(  OrdSetFocus( CHEQUE_CHEQUE_NO_ORD ))

		Audit->(dbSeek( str( nDayUniq, FLD_AD_LINK ), HARDSEEK ))
		do while Audit->DAY_UNIQ == nDayUniq .and. !Audit->(eof())
			nAcctUniq := Audit->acct_uniq
			Account->(dbSeek( str( nAcctUniq, FLD_AD_LINK ), HARDSEEK ))
			if Account->type <> TT_STD_DEDUCTION
				// We ignore the Standard Deductions
				do while Account->ACCT_UNIQ == nAcctUniq .and. !Account->(eof())
					nPosted += Account->U_PRICE

					if !empty( Account->series ) .and. Account->cheque > 0
						if Cheque->(dbSeek( Account->series + str( Account->cheque, FLD_CHEQUE ), HARDSEEK ))
							nPaid += Account->u_price
							if Cheque->date <= dDate
								nPaidBefore += Account->u_price
							endif
						endif
					endif
					Account->(dbSkip())
				enddo
			endif
			Audit->(dbSkip())
		enddo

		if num3NotEqual0( nPaidBefore )
			nuQQprnOut(  dollarStr( nPaidBefore , WIDTH_FLD_7_FINAL_U_PRICE)  )
		endif

		// July 29, 2014
		//    We can Print the PRINTING Notes if there are any
		if !empty(Daily->pr_note1)
			nuQprnOut( space(  WIDTH_FLD_1_EMPTY  +  WIDTH_FLD_2_DATE  +  WIDTH_FLD_3_RECPT-4 ) + ;
			           Daily->pr_note1 )
		endif

		Account->(RestDBF( aDBF1 ))
		Daily->(  RestDBF( aDBF2 ))
		Audit->(  RestDBF( aDBF3 ))
		Cheque->( RestDBF( aDBF4 ))

		// BH likes having these variables for debugging
		//  but at this point they are not used, just do not want to get
		//  alerts from the Compiler about unused variables.
		if nPosted == nPaid
			nPosted := nPaid
		endif
	endcase

RETURN(nil)


static function ContainerCount()
	local n
	for n := 1 to len(aContainer)
		aContainer[n,A_CONT_IN]  += Daily->(gsInContainer(n))
		aContainer[n,A_CONT_OUT] += Daily->(gsOutContainer(n))
	next
return( nil )

static function ContInfoPrint( )
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

	if NearPageBottom( nCnt + 9 )
		nuQprnOut( )
		nuQprnOut(  '    Continued on next page...')
		nuFormFeed()
		StateHead()
	endif

	nuQprnOut( padr(' Containers YTD:',26))
	nuQQprnOut(padl('Issued',13) )
	nuQQprnOut(padl('Received',13) )
	nuQQprnOut(padl('Issued',13) )
	nuQQprnOut(padl('Balance',13) )
	nValue := 0.00

	for n := 1 to len(aContainer)
		if aContainer[n, A_CONT_IN ] <> 0 .or. ;
			aContainer[n, A_CONT_OUT ] <> 0 .or. ;
			aContainer[n, A_CONT_ISSUED] <> 0

			nuQprnOut(  '  '+padr(aContainer[n,A_CONT_NAME],24) )
			//                                                      123456789_123
			nuQQprnOut( transform(  aContainer[n,A_CONT_ISSUED] ,  '9,999,999,999'))
			nuQQprnOut( transform(  aContainer[n,A_CONT_IN]     ,  '9,999,999,999'))
			nuQQprnOut( transform( aContainer[n,A_CONT_OUT]     ,  '9,999,999,999'))

			nuQQprnOut( transform( aContainer[n,A_CONT_ISSUED] ;
				+ aContainer[n,A_CONT_OUT] ;
				- aContainer[n,A_CONT_IN]  ,  '9,999,999,999'))

			nValue += (round( ;
				(aContainer[n,A_CONT_ISSUED]      ;
				+ aContainer[n,A_CONT_OUT] ;
				- aContainer[n,A_CONT_IN]   )  * aContainer[n,A_CONT_VALUE],2))
		endif
	next


	if !num2Equal0(nValue) .and. nValue > 0.00
		nuQprnOut( '  TOTAL VALUE OF OUTSTANDING CONTAINERS: '+ ;
		   transform( nValue  ,  '$999,999.99') )
	endif

return( NIL )



static function AccBerry()
	local cReturn

	cReturn :=  Account->product +' '+Account->process+' '+ ;
					iif(Account->grade==0, ' ' ,Str(account->grade,1) )

return( cReturn )


static function acc2Daily()
return( nil )

static Function Acc2Daily2012(  )
	local n

	n := len( aAccount )

	// to Be fixed   2BFIXED - July 16, 2014
	//   this little cludge tries to fix it
	do case
	case Account->type == TT_GST_TAX    // no records for this...
		return( nil )
	case Account->type == TT_STD_DEDUCTION   // too many for this...
		return( nil )
	otherwise
		if n > 0  // I guess
			Audit->(dbSeek( str(Account->acct_uniq,FLD_DOCUMENT), HARDSEEK ))
			do while Account->acct_uniq == Audit->acct_uniq .and. ;
						!Audit->(eof())

				if !Daily->(dbSeek( str(Audit->day_uniq, FLD_DOCUMENT),HARDSEEK))
					appError(APP_ERR_AUDIT_TRAIL_PROBLEM2, { ;
						'Can not find the Daily for Grower '+lStrim(Grower->number), ;
						'Account ID='+str(Account->acct_uniq,10), ;
						'Daily ID  ='+str(Daily->day_uniq,10) })
				else
					aadd( aAccount[ n, A_ACCOUNT_DAILY_ARRAY ],  A_ADDED_2012_DAILY  )
					dLastDaily := max( Daily->date, dLastDaily )
				endif
				Audit->(dbSkip())
			enddo
		endif
	endcase
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
         AppError( APP_ERR_CAN_NOT_FIND_ACCOUNT_REC3, { ;
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

      // Changed Aug 2013
      if Daily->(fValidPrice( ) )
         nFinal := max(Daily->(FinalPrice()),Daily->fin_price)
      else
         nFinal := Daily->fin_price
      endif

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
	local nAdvance
	local nFinal
	local nPremium

	if FindPrice( Daily->Product, Daily->Process, Daily->Date )
      if Daily->(fValidPrice( ) )
         nAdvance := Daily->( TotAdvPrice())  // AdvancePrice(  )
         nFinal   := max(Daily->(FinalPrice()),Daily->fin_price)
         nPremium := Daily->(AdvancePrem(  ))
      else
         nAdvance := Daily->( TotAdvPrice())  // AdvancePrice(  )
         nFinal   := Daily->fin_price
         nPremium := 0.00
      endif

		lFound := .f.
		for n := 1 to len(aAdvance)
			if nAdvance == str(aAdvance[n, A_AF_ADVANCE_RATE],12,2) .and. ;
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
			aAdvance[n, A_AF_ADVANCE_RATE]  := nAdvance

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
		aAdvance[ n, A_AF_PAID     ] += round(Daily->net*nAdvance,2)
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
