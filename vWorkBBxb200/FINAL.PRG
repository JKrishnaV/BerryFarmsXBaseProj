// Final.prg
// June 17, 2000
// Oct 2000 - can restrict to ONE product (& process)
// Bill Hepler
//   calculates the Final Payment....
//   1.  Looks in DAILY file & Sets up appropriate records in TempAcct
//   2.  Posts from TempAcct to ACCOUNT
//   3.  Prints Cheques
//	  4.  Prints "Advice" or statement to go with Cheque
//       The advice includes PLASTIC TOTES, WOOD TOTES, and LUGS

//   Based on Weekly.prg
// Nov 2001 - minor corrections
// July 2002 - On-Holds dealt with
// Aug 2010 - Get Rid of Freaking Index ON....
// Mar 2015 - Better Date Checking
// Dec 2019 - Event Logging
// Apr 2020 - Minor changes for unique ID...
// Oct 2021 - Jass found a bug around line 560 - rounding problem
// Nov 2022 - I found a bug here, I was NOT putting the Final Payment batch number in !
//            I correct it but existing data has problems.

#include 'common.ch'
#include 'window.ch'
#include 'bsgstd.ch'
#include 'printer.ch'
#include 'BerryPay.ch'
#include 'inkey.ch'
#include 'sysvalue.ch'
#include 'price.ch'
#include 'account.ch'
#include 'valid.ch'
#include "errors.ch"
#include "indexord.ch"
#include "field.ch"
#include "events.ch"
#include "Unique_Fields.ch"

static nYear
static nAcct_uniq
static aAccountRec
static cFile        := ''

#define   AA_STRU   { space(3),space(8),'','',0, 0.000, 0, 0.00, 0, date() }
//                      1        2      3  4  5   6     7   8    9   10
#define   AA_TYPE        1
#define   AA_CLASS       2
#define   AA_PRODUCT     3
#define   AA_PROCESS     4
#define   AA_GRADE       5
#define   AA_PRICE       6
#define   AA_WEIGHT      7
#define   AA_EXTENDED    8
#define   AA_ACCT_UNIQ   9
#define   AA_EARLY_DATE 10

function FinalPay()
   local getList :={}
   local nChoice
	local dLastDate
	local nPostBatch
   local aWin
	local cProduct
	local cProcess
	local aHead

	local dChqDate
	local cIncPayGrp, cExcPayGrp, lPayGrp, cOrder
	local nIncGrower, nExcGrower
   local aOnHold := {}
   local lCont := .f.

	cProduct := space(FLD_PRODUCT)
	cProcess := space(FLD_PROCESS)

   if !ArchiveCheckOK()
   	return( nil )
   endif

	if !( open4ChequeRun( DB_EXCLUSIVE) )
		close databases
		return( nil )
	endif

	nYear := sysValue(SYS_CURRENT_YEAR)
	dChqDate  := date()
	dLastDate := date() -30

	lPayGrp := .t.
	cIncPayGrp := space(FLD_PAYGRP)
	cExcPayGrp := space(FLD_PAYGRP)

	cOrder := 'N'

	nIncGrower := nExcGrower := 0

	myBsgScreen( 'Generate Regular Final Payment' )

	create window at 3,4,21,68 title 'Regular Final Price Payment' to aWin
	display window aWin

	in window aWin @ 2,5  winsay 'BackUp Before running this!'

	in window aWin @ 5,5  winsay 'This process allows you to create'
	in window aWin @ 6,5  winsay 'cheques for all or some portion of the'
	in window aWin @ 7,5  winsay 'the growers.'

   in window aWin @ 7,2  winsay 'The PAYMENT GROUP is what allows you the most flexibility to'
   in window aWin @ 8,2  winsay 'include/exclude growers from a cheque run.  Growers'
   in window aWin @ 9,2  winsay 'ON-HOLD will not be paid.  ' + ;
             iif( sysValue( SYS_QUICK_CHECK_FOR_ZERO_KEY ) <> SQCFZ_NOT_AUTOMATIC,' Zero Check is ON!','        ')

	in window aWin @ 12,2 winsay 'The procedure to Generate Cheques:'
	in window aWin @ 13,5 winsay '1. Determine Payment Due for Production'
	in window aWin @ 14,5 winsay '2. Produce Cheques (includes deductions)'
	in window aWin @ 15,5 winsay '3. Print Statements to accompany cheques'

	in window aWin @17,2 winsay ;
			'This makes final payments - ignores unposted transactions'

	ThinWait()

	in window aWin @ 2,2 winclear to 15,65

   aOnHold := {}
	do while .t.
      CountOnHold( aOnHold )
      do case
      case len(aOnHold)==0
         in window aWin @15,2 winsay 'No Growers are on Hold'
      case len(aOnHold)==1
         in window aWin @15,2 winsay '1 Grower on Hold: '+aOnHold[1]
      case len(aOnHold)==2
         in window aWin @15,2 winsay '2 Growers on Hold: '+aOnHold[1]
         in window aWin @16,2 winsay '                   '+aOnHold[2]
      otherwise
         in window aWin @15,2 winsay lStrim(len(aOnHold))+ ;
          ' Growers on Hold, including '+substr(aOnHold[1],1,20)
         in window aWin @16,2 winsay substr(aOnHold[2],1,20)+' '+ ;
                                     substr(aOnHold[3],1,20)+' ...'
      endcase

   	in window aWin @ 2,2  winsay 'Cheque Date:' winget dChqDate picture '@d' ;
		 valid ReasonablePostDate( dChqDate, .t., 'Cheque Date' ) ;
       GET_MESSAGE 'The accounting date of Generated Transactions and Cheques'
		in window aWin @ 3,2  winsay 'Include to: ' winget dLastDate ;
		 valid ReasonablePostDate( dLastDate, .t., 'Include to Date' ) ;
		 GET_MESSAGE 'Include deductions and other adjustments up to this date'
		in window aWin @ 4,2 winsay 'For Crop Year' winget nYear  ;
		 picture '9999' GET_MESSAGE ;
		'The Crop Year to Which these Payments and Deductions Belong'

		in window aWin @ 6,2 winsay 'Pay this PayGrp Only' winget cIncPayGrp ;
		  picture '@!' ;
			when PutName(aWin, 6 ,30,LU_PAYGRP,cIncPayGrp) ;
			valid PutName(aWin, 6,30,LU_PAYGRP,cIncPayGrp) ;
			LookUp( LU_PAYGRP,  ;
         'Leave Blank for All Grower Payment Groups')

		in window aWin @ 7,2 winsay 'Pay this Grower Only' winget nIncGrower ;
		 picture NumBlankPic( FLD_GROWER ) ;
			when PutName(aWin, 7 ,30,LU_GROWER_NAME, nIncGrower) ;
			valid PutName(aWin, 7,30,LU_GROWER_NAME, nIncGrower) ;
       LOOKUP( LU_GROWER, ;
'Enter a Grower ID here, if you wish to generate a payment for 1 grower ONLY')

		in window aWin @ 9,2 winsay 'Exclude this PayGrp' winget cExcPayGrp ;
		  picture '@!' ;
			when PutName(aWin, 9 ,30,LU_PAYGRP,cExcPayGrp) ;
			valid PutName(aWin, 9,30,LU_PAYGRP,cExcPayGrp) ;
			LookUp( LU_PAYGRP,  ;
         'Leave Blank for All Grower Payment Groups')

		in window aWin @10,2 winsay 'Exclude this Grower' winget nExcGrower ;
		 picture NumBlankPic( FLD_GROWER ) ;
			when PutName(aWin,10 ,30,LU_GROWER_NAME, nExcGrower) ;
			valid PutName(aWin,10,30,LU_GROWER_NAME, nExcGrower) ;
       LOOKUP( LU_GROWER, ;
'Enter a Grower ID here, if you wish to generate a payment for 1 grower ONLY')

		in window aWin @12,2 winsay 'Single Product' winget cProduct ;
		 picture '@!' ;
       LOOKUP( LU_PRODUCT, ;
'You may restrict this run to apply only to a single product')

		in window aWin @13,2 winsay '       Process' winget cProcess ;
		 picture '@!' ;
       LOOKUP( LU_PROCESS_TYPE, ;
'You may restrict this run to apply only to a single process')

		READ
   	if lastkey()==K_ESC
   		exit
   	endif
		if !( ReasonablePostDate( dChqDate, .t., 'Cheque Date' ) .and. ;
		      ReasonablePostDate( dLastDate, .t., 'Posting Date' ))
			WaitInfo({'Dates are looking wonky' })
		endif

      nChoice := ThinChoice( ;
      {'Determine','Cheques','Statements','OnHolds','X-eXit'})

   	do case
      case nChoice == 0 .or. nChoice == 5
   	 	exit
      case nChoice == 1
      	lCont := .t.
      	do case
			case sysValue( SYS_QUICK_CHECK_FOR_ZERO_KEY ) == SQCFZ_AUTOMATIC_WHATEVER
				lCont := QuikNoKeyPrice( CHEQUE_TYPE_FINAL  , 0, stod(str( nYear,4)+'0101'  ), dLastDate, cProduct, cProcess, nIncGrower, '' )
			case sysValue( SYS_QUICK_CHECK_FOR_ZERO_KEY ) == SQCFZ_AUTOMATIC_FRESH .and. (cProcess == 'FR' .or. empty(cProcess) )
				lCont := QuikNoKeyPrice( CHEQUE_TYPE_FINAL , 0, stod(str( nYear,4)+'0101'  ), dLastDate, cProduct, 'FR',     nIncGrower, '' )
			endcase

			if !lCont
				if !YesNo({'We have found some ZERO PRICED Receipts', ;
				           'Do you wish to CONTINUE to Make Payments ANYWAY ?'})
					loop
				endif
			endif

      	LogAnEvent( EVT_TYPE_START_FINAL_DETERMINE, ;
		            {'Final Attempt Determination - PayGrp ' + cIncPayGrp, ;
						 'Chq Date='+shMDY( dChqDate )} )

         if Check4Err( dLastDate, cProduct, cProcess, ;
               nIncGrower,cIncPayGrp, nExcGrower, cExcPayGrp, 0 )

				nPostBatch := findLastUniqOnFile( UF_THE_FIN_BAT , .f. )  + 1      // no lock needed as using Exclusively - noted APR 2020

	      	LogAnEvent( EVT_TYPE_FINAL_CHECKED_4_ERRS , ;
		            {'Final Payment-No errors so far-Batch='+var2char( nPostBatch) }  )

				// this MAY include records that have been posted....
            if IndexFinalTemp( dLastDate, cProduct, cProcess, ;
						 nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp )

					// this excludes previously posted data....

					aHead := { 'Final Payments Batch '+lStrim(nPostBatch) }
					VariousHead( aHead, dLastDate, cProduct, cProcess, ;
		 				nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp )

		      	LogAnEvent( EVT_TYPE_FINAL_INDEXED , ;
		            {'Final Payment - Indexed files'} )

               inkey()   // in case Jass is Impatiant

		   	 	if Determine( dLastDate, nPostBatch, aHead )

			      	LogAnEvent( EVT_TYPE_FINAL_ACTUAL_DETERMINE , ;
		             {'Final Payment - Actual Determination of Amts Owed' , 'Batch='+var2char( nPostBatch) } )

						if sysValue(SYS_ALLOW_CANADIAN_DOLLARS)
                     Cheques(CANADIAN_DOLLARS, CHEQUE_TYPE_FINAL , ;
								nYear, nIncGrower, cOrder, lPayGrp, cIncPayGrp, dLastDate)
						endif

						if sysValue(SYS_ALLOW_US_DOLLARS)
                     Cheques(US_DOLLARS, CHEQUE_TYPE_FINAL , ;
								 nYear, nIncGrower, cOrder, lPayGrp, cIncPayGrp, dLastDate)
						endif
					else
			      	LogAnEvent( EVT_TYPE_FINAL_DETERMINE_FAILS , ;
		             { 'Final Pay Actual Determination of Amts Owed' , ;
						   'Batch was going to be '+var2char( nPostBatch ), ;
						   shMDY( dLastDate) + 'Prod/Proc='+ cProduct + cProcess } )

					endif

               if select('Daily') > 0
                  Daily->(dbCloseArea())
               endif
               openFile({'Daily'}, DB_EXCLUSIVE )
	   	 		exit
	   	 	endif
			endif

   	 case nChoice == 2
			if sysValue(SYS_ALLOW_CANADIAN_DOLLARS)
            Cheques(CANADIAN_DOLLARS,CHEQUE_TYPE_FINAL , ;
					 nYear, nIncGrower, cOrder, lPayGrp, cIncPayGrp, dLastDate)
			endif

			if sysValue(SYS_ALLOW_US_DOLLARS)
            Cheques(US_DOLLARS ,     CHEQUE_TYPE_FINAL , ;
					 nYear, nIncGrower, cOrder, lPayGrp, cIncPayGrp, dLastDate)
			endif

   	 	exit
   	 case nChoice == 3
   	 	close databases

         StatementDo( GRO_STATEMENT_FOR_WEEKLY, SysValue( SYS_WEEK_STATEMENT_DEFAULT_FORMAT ) )

   	 	exit
      case nChoice == 4
         if len( aOnHold ) == 0
            waitInfo({'No one is on-hold at present'})
         else
            aChooser( 5, 20, aOnHold, NIL, 'On Holds')
         endif
   	endcase
      if !empty( cFile)
         KillUnique( cFile )
         cFile := ''
      endif
	enddo
	close databases

   if !empty( cFile)
      KillUnique( cFile )
      cFile := ''
   endif

	kill window aWin
return( nil )

static function IndexFinalTemp(dLastDate, cProduct, cProcess, ;
		nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp )
	local lReturn := .f.
   local bKey, bFor, bWhile

   StopCompilerWarning( nExcGrower )
	StopCompilerWarning( cExcPayGrp )

	msgLine('Building temporary index....')
   if !empty( cFile)
      KillUnique( cFile )
      cFile := ''
   endif

   cFile := UniqueFile()
   if empty(cFile )
      WaitHand({'Can NOT get a temp file...'})
      return( lReturn )
   endif

   Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))

   // dbSelectAR('Daily')
	Daily->(dbSetRelat( 'Grower', { || str( Daily->number, FLD_GROWER)}, ;
		'str( Daily->number,'+ lStrim( FLD_GROWER)+')' ))

   SetHoldUI( .t. )

   bKey   :=  { || str(Daily->number,FLD_NUMBER) + dtos(Daily->date) + ;
                           str(Daily->recpt,FLD_RECPT) }

   bFor   := { || GrInPayGrp(cIncPayGrp,cExcPayGrp) .and. ;
                  forPP( cProduct, cProcess ) .and. ExclOnHold()}

	if nIncGrower==0
      Daily->(OrdSetFocus( DAILY_FINAL_DATE_ORD))
		if Daily->(dbSeek( str(0, FLD_DOCUMENT ), HARDSEEK))
         /*----
			index on str(Daily->number,FLD_NUMBER) + dtos(Daily->date) + ;
				str(Daily->recpt,FLD_RECPT) to DAYTEMP ;
             for GrInPayGrp(cIncPayGrp,cExcPayGrp) .and. ;
              forPP( cProduct, cProcess ) .and. ExclOnHold(  ) ;
				while Daily->fin_bat==0 .and. ;
				Daily->date <= dLastDate
         -------- */

         bWhile := { || Daily->fin_bat==0 .and. Daily->date <= dLastDate}
         lReturn := .t.
      endif
	else
      // fixed in Oct 2000
      Daily->(OrdSetFocus( DAILY_GROWER_ORD))
      if Daily->(dbSeek( str(nIncGrower, FLD_GROWER ), HARDSEEK))
         /* ------------------------
			index on str(Daily->number,FLD_NUMBER) + dtos(Daily->date) + ;
				str(Daily->recpt,FLD_RECPT) to DAYTEMP ;
				 for GrInPayGrp(cIncPayGrp,cExcPayGrp) ;
               .and. forPP( cProduct, cProcess ) .and. ExclOnHold(  ) ;
            while Daily->number==nIncGrower .and. ;
				Daily->date <= dLastDate
         --------------------------- */

         bWhile := { || Daily->number==nIncGrower .and. Daily->date <= dLastDate}
         lReturn := .t.
      endif
	endif

   if lReturn
      SubsetBuilder ( cFile, 'Daily', bKey, bFor, bWhile )

      (cFile)->(dbGoTop())
      if (cFile)->(eof())
         lReturn := .f.
      endif
   endif

   SetHoldUI( .f. )

return( lReturn )

static function Determine( dLastDate, nPostBatch, aHead )
	local lReturn := .f.

   // May 2020 - this SelectPrn Here was NOT correct.

	// if SelectPrn('FINAL.TXT'  )
   if YesNo({'Are you ready to Determine what the final payments will be ?'           ,'', ;
             'It is best to only do this step if you expect to actually'              ,    ;
             'actually post the transactions.  After you post the transactions'       ,    ;
             'transactions you can pay them out, or leave them as payables.'          ,    ;
             'The system does take into account any loans or other money that'        ,    ;
             'Growers owe you as long as the information is recorded in this'         ,    ;
             'system !   This is a FINAL PAYMENT posting!'                                    })


		msgLine('Hang on...we are preparing for this ordeal')

		nAcct_Uniq := NextAcctUniq( )
		MakeTempPostDBFs()

      // Daily->(dbGoTop())
      (cFile)->(dbGoTop())
      //do while !Daily->(eof())  // remember we are in the Temporary Order
      do while !(cFile)->(eof())  // remember we are in the Temporary Order
         Grower->(OrdSetFocus( GROWER_NUMBER_ORD))
			Grower->(dbSeek( str( Daily->number, FLD_GROWER),HARDSEEK ))

      	OneGrower( dLastDate, nPostBatch )

      enddo

      // we Now get Daily UnTied to (cFile)
      if empty( cFile)
         AppError(APP_ERR_BLANK_CFILE1 , {'UnExpected CFILE blank!'})
      else
         if select( cFile ) > 0
            (cFile)->(dbCloseArea())
         endif
         Daily->(dbClearRelation())
         Daily->(dbGoTop())
      endif

      if Post2Account( nAcct_uniq, aHead, .t., C_ACCOUNT_POST_TYPE_FINAL , nPostBatch )
	   	// we have to update the Daily Files....
			lReturn := .t.

			FinBat->(addRecord())                        // files are being used EXCLUSIVELY, so this is OK - noted APRIL 2020
			FinBat->FIN_BAT  := nPostBatch
			FinBat->date     := date()
			FinBat->CutOff   := dLastDate

			FinBat->(dbCommit())
		else
			lReturn := .f.   // redundant, but just to be CLEAR
			msgLine('Unmarking the Daily File....')
			Daily->(dbCloseArea())
			OpenFile({'Daily'}, DB_EXCLUSIVE )
         Daily->(OrdSetFocus( DAILY_GROWER_ORD ))
			Daily->(dbGoTop())
			do while !Daily->(eof())
				ShowProg( str(Daily->number,8) )
				if Daily->fin_bat==nPostBatch
					Daily->fin_bat   := 0
					Daily->fin_price := 0
					Daily->fin_PR_ID := 0
				endif
				Daily->(dbSkip())
			enddo

			LogAnEvent( EVT_TYPE_FINAL_DID_NOT_POST, {       ;
             'We did NOT post a Final Payment',           ;
             'nAcct_uniq = '+ var2char( nAcct_uniq ),     ;
             'Estimated Batch # =' + var2char(nPostBatch)  })

			WaitExclam({'One problem you may have is that', ;
				'the system has now MARKED some of your', ;
				'Price Table Advances as being USED', ;
				'If this is a problem call Crafted Industrial or', ;
				'restore your Back Ups !!!'} )
		endif


      CloseTempPostDBFs()   // probably not needed here
	endif

return( lReturn )

static Function OneGrower( dLastDate, nPostBatch )
	// assume Grower.DBF is in correct position
   local n
   local nGrower := 0
   local cCurrency := CANADIAN_DOLLARS

	msgLine('Calculating for '+lstrim(Grower->number)+' '+Grower->name)

	aAccountRec :={}

   //do while Daily->number==Grower->number .and. !Daily->(eof())
   nGrower := Daily->number

   do while Daily->number==nGrower .and. !(cFile)->(eof())
      BuildFrDaily( nPostBatch )
      //Daily->(dbSkip())
      (cFile)->(dbSkip())
	enddo

	for n := 1 to len(aAccountRec)
		TempAcct->(addRecord())

      TempAcct->date := dLastDate
      TempAcct->year := nYear
      if Grower->number <> nGrower
         if !ValidTest( V_GROWER, nGrower )
            AppError( APP_ERR_GROWER_NOT_FOUND , ;
              {'Can not find Grower:'+lStrim( nGrower) })
         endif
      endif
      if Grower->number == nGrower
         cCurrency := Grower->currency
      endif
      TempAcct->number   := nGrower
      TempAcct->currency := cCurrency

		if valType(aAccountRec[n, AA_TYPE])<>'C' .or. ;
			valType( aAccountRec[n, AA_CLASS]) <> 'C' .or. ;
			valType( aAccountRec[n, AA_PRODUCT    ] ) <> 'C' .or. ;
			valType( aAccountRec[n, AA_PROCESS    ] ) <> 'C' .or. ;
			valType( aAccountRec[n, AA_GRADE      ] ) <> 'N'

			appError( APP_ERR_UNEXPECTED_VALTYPE, ;
				{'Will crash soon', ;
				'AA_TYPE - '+ valType(aAccountRec[n, AA_TYPE]), ;
				'AA_CLASS- '+ valType( aAccountRec[n, AA_CLASS]), ;
				'AA_PRODUCT'+ valType( aAccountRec[n, AA_PRODUCT ]), ;
				'AA_PROCESS'+ valType( aAccountRec[n, AA_PROCESS ]), ;
				'AA_GRADE  '+ valType( aAccountRec[n, AA_GRADE   ]) })
		endif

      TempAcct->type      := aAccountRec[n, AA_TYPE]
      TempAcct->Class     := aAccountRec[n, AA_CLASS]
      TempAcct->product   := aAccountRec[n, AA_PRODUCT    ]
      TempAcct->process   := aAccountRec[n, AA_PROCESS    ]
      TempAcct->grade     := aAccountRec[n, AA_GRADE      ]

      TempAcct->u_price   := aAccountRec[n, AA_PRICE]
      TempAcct->lbs       := aAccountRec[n, AA_WEIGHT]

		// June 99 - round this at last moment...
      TempAcct->dollars   := round(aAccountRec[n, AA_EXTENDED],2)

      TempAcct->acct_uniq := aAccountRec[n, AA_ACCT_UNIQ]

      // Nov 2022 - I realize that I need to add this line.
      TempAcct->adv_bat   := nPostBatch
	next

return( nil )

static function BuildFrDaily( nPostBatch )
	local nPrice, cType, nLbs,  cClass, nExtended
	local nFinal

	cClass := space(8)
	if Daily->fin_bat == 0

		if Daily->(FindPrice( Daily->product, Daily->process, Daily->date))

			nFinal := Daily->( FinalPrice(  ))
         nPrice := nFinal - Daily->adv_pr1 -Daily->adv_pr2 - Daily->adv_pr3

			if round(nPrice,3) <= round(-0.001,3)     // Oct 2021 weird glitch noted by Jass & confirmed by BH
				AppError( APP_ERR_NEGATIVE_YEAR_END_PRICE, ;
					{ 'Negative Year End Price', ;
					  'Price = '+str(nPrice,12,2), ;
					  'We will pay it but we think you should know about it.', ;
					  'for Grower '+str(Daily->number,FLD_GROWER)+ ;
					  '  Berry: '+daily->product+' '+daily->process+lStrim(Daily->grade) })
			endif

	      Daily->fin_price  := nFinal         // the Price in PRICE.DBF
			Daily->fin_bat    := nPostBatch
         Daily->fin_pr_id  := Price->PriceID  // corrected Nov 2001

			cType := TT_FINAL_BERRY
			nLbs  := Daily->net
			nExtended := nLbs * nPrice

			Add2ARec(cType, cClass, Daily->product, Daily->process, Daily->grade, ;
				 nPrice, nLbs,nExtended)

			if !Price->(eof())
				if !Price->FIN_USED               // Oct 2021-not sure this is correct.  We could be using a keyed final price.
					Price->fin_used := .t.
				endif
			endif

		endif

		if Daily->(AnyContainers( )) .and. ;
		   empty(Daily->product) .and. empty(Daily->process) .and. ;
		   empty(Daily->grade) .and. Daily->fin_bat == 0

				Daily->fin_bat  := nPostBatch
		endif
	endif

return( nil )

static function Add2ARec(cType, cClass, cProduct, cProcess, nGrade, ;
		   nPrice, nLbs,nExtended)

	local n, nRow

	nRow := 0
	for n:=1 to len(aAccountRec)
		if aAccountRec[n,AA_TYPE]==cType .and. aAccountRec[n,AA_CLASS]==cClass ;
				.and. aAccountRec[n,AA_PRODUCT] == cProduct ;
				.and. aAccountRec[n,AA_PROCESS] == cProcess ;
				.and. aAccountRec[n,AA_GRADE  ] == nGrade

			if nPrice==aAccountRec[n,AA_PRICE]
				aAccountRec[n,AA_WEIGHT]   += nLbs
				aAccountRec[n,AA_EXTENDED] += nExtended
				nRow := n
				exit
			endif
		endif
	next

	if nRow == 0
		aadd(aAccountRec, AA_STRU )
		nRow := len(aAccountRec)
		aAccountRec[nRow, AA_TYPE]    := cType
		aAccountRec[nRow, AA_CLASS]   := cClass
		aAccountRec[n,AA_PRODUCT]     := cProduct
		aAccountRec[n,AA_PROCESS]     := cProcess
		aAccountRec[n,AA_GRADE  ]     := nGrade
		aAccountRec[nRow, AA_PRICE]   := nPrice
		aAccountRec[nRow, AA_WEIGHT]  := nLbs
		aAccountRec[nRow, AA_EXTENDED]  := nExtended
		aAccountRec[nRow, AA_ACCT_UNIQ] := nAcct_Uniq
		nAcct_Uniq ++
	endif

	// Oct 99
	if nRow > 0
		if aAccountRec[nRow, AA_EARLY_DATE ] > Daily->date .or. ;
			empty( aAccountRec[ nRow, AA_EARLY_DATE ] )

			aAccountRec[nRow, AA_EARLY_DATE ] := Daily->date
		endif
	endif

	TempAud->(addRecord())
   TempAud->day_uniq  := Daily->day_uniq
   TempAud->acct_uniq := aAccountRec[nRow,AA_ACCT_UNIQ]

return( nil )

/* ------------- 2BFIXED  april 2020 ------------------------
	nReturn := findLastUniqOnFile( UF_THE_FIN_BAT , .f. )  // no lock needed as using Exclusively - noted APR 2020
	nReturn++
------------------------------------- */


