// Weekly.prg
// June 13, 1994
// Bill Hepler
//   calculates the Weekly Payment....
//   1.  Creates index of suitable records in DAILY file
//   2.  Allows you to view these
//   3.  Creates Posting Records into Temporary File
//        & Marks Daily Records with Batch
//   4.  Prints the Transactions to be Posted
//        (remember there may be other transactions to pay which will not print)
//   5.  If you select POST it
//           We copy append temporary posting file into posting file
//           Creates Batch record summary in IMP_BAT.DBF
//           Prints Cheques
//	          Prints "Advice" or statement to go with Cheque
//       else
//           sets Daily->Imp_Batch & associates back to ZERO
//           kills temporary posting file
//---------------------------------------------------------------
//       The advice includes PLASTIC TOTES, WOOD TOTES, and LUGS

// 1999 we revise it because our product file is now rational
//      we now put the actual product & process & grade into
//      the ACCOUNT file.
//   We also do automatic marketing deductions....

// June 2000 - Posting Procedure changes no UNPOST...
// Oct  2000 - Can restrict to ONE product / process...
// Nov  2001 - Pays First, 2nd or 3rd Advance
// July 2002 - On-Holds dealt with
// July 2014 - Changes for GST only really effect
// Apr  2019 - Changes for Grades included, a couple inkey() put in due to WestBerry Printer
//             problems.
// Dec 2019 -------------- See Weekly.prg -----------------------------------------------------------------------
//          ---   This is a SPECIAL FIX for a specific bug                                                    ---
//          ---   DO NOT USE THIS ROUTINELY !!!!                                                              ---
//          ---     Westberry - they seem to have run an advance, backed out part way through & the program   ---
//          ---       did NOT completely "unmark" the tickets - specifically, the system left these fields    ---
//          ---       marked:      Daily->adv_pr1   >  0    the PRICE (that should have been paid)            ---
//          ---                    Daily->adv_prID1 >  0    the Record in PRICE.DBF refered to                ---
//          ---                    Daily->post_bat1 == 0    Daily Advance 1 WAS NOT poasted                   ---
//          ---                    Daily->fin_price > 0     Final Price was Set                               ---
//          ---                    Daily->fin_bat   > 0     Final Price was Posted                            ---
//          ---                    Daily->fin_pr_id > 0     Final Price ID is set                             ---
//          ---       It will turn out that the Final Record in ACCOUNT will be set at Fin_Price - Adv_Pr1    ---
//          ---       as though the Advance Price WAS paid (even though it was NOT paid)                      ---                                                                                        ---
//          -----------------------------------------------------------------------------------------------------
// Apr 2020 - I updated

#include "ACCOUNT.CH"
#include "BerryPay.ch"
#include "bsgstd.ch"
#include "common.ch"
#include "errors.ch"
#include "field.ch"
#include "indexord.ch"
#include "forstuff.ch"
#include "inkey.ch"
#include "price.ch"
#include "printer.ch"
#include "sysvalue.ch"
#include "tax.ch"
#include "Unique_Fields.ch"
#include "valid.ch"
#include "window.ch"
#include "events.ch"

static  dChqDate
static lPayGrp, cOrder
static nYear

static nAcct_uniq := 0
static nNoRec, nReplaced

static aAccountRec
#define   AA_STRU   { space(3),space(8),'','',0, 0.000, 0, 0.00, 0, date(), 0.0000 }
//                      1        2      3  4  5   6     7   8    9   10      11
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
#define   AA_GST_AMT    11

function Weekly_SpecFix( nAdvance )
   local getList :={}, nChoice
	local dLastDate
   local aWin
	local nIncGrower, nExcGrower
	local cIncPayGrp, cExcPayGrp
	local nPostBatch
	local cProduct
	local cProcess
	local aHead
   local cAdvance
   local aOnHold
   local lCont := .f.

	if !Yesno({'This is the SPECIAL FIXER - only use after speaking with Crafted IS!', ;
	    		 '','Are you sure you want to do this ?'})
		return( nil )
	endif

	if xxPassWord( 'BH Mom maiden inits', 'OAK', .F. )
      if xxPassWord( 'Bills Dog?',"BROWNIE", .f. )
      	if YesNo({'You know - this is a SPECIAL procedure that Bill Hepler' , ;
                   'created to deal with a SPECIAL situation -- do NOT use'  , ;
                   'this procedure unless you REALLY know what you are'      , ;
                   'doing.  Do you know what you are doing ????'                   })
	         lCont := .t.
         endif
      endif
   endif

	if !lCont
		return( nil )
	endif

   do case
   case nAdvance == 1
      cAdvance := 'First'
   case nAdvance == 2
      cAdvance := 'Second'
   case nAdvance == 3
      cAdvance := 'Third'
   otherwise
      AppError( APP_ERR_UNKNOWN_ADVANCE_TYPE1 , ;
        {'Unknown Advance Type '+str(nAdvance,5) })
      return( nil )
   endcase

   if !ArchiveCheckOK()
   	return( nil )
   endif

   do case
   case nAdvance==1
      lCont := yesno( ;
       {'This deals with FIRST advances against PAID receipts!', '', ;
        'Do you wish to continue?'})

	case nAdvance==2  // not invoked
   	lCont := yesno( ;
       {'This has NEVER BEEN tested', ;
        'Do you wish to continue?'})
   case nAdvance==3 // not invoked
   	lCont := yesno( ;
       {'This has NEVER EVER BEEN tested', ;
        'Do you wish to continue?'})
   endcase

   if !lCont
   	return( nil )
   endif
   nNoRec    := 0
   nReplaced := 0

	cProduct := space(FLD_PRODUCT)
	cProcess := space(FLD_PROCESS)

	nYear := sysValue(SYS_CURRENT_YEAR)
	dChqDate  := date()
	dLastDate := date() -30

	lPayGrp := .t.
	cIncPayGrp := space(FLD_PAYGRP)
	cExcPayGrp := space(FLD_PAYGRP)

	cOrder := 'N'

	nIncGrower := 0
	nExcGrower := 0

   myBsgScreen( 'Generate '+cAdvance +' Special Advance Pay' )

   create window at 4,5,21,72 title cAdvance +' Regular Corrective Advance' to aWin
	display window aWin

	in window aWin @ 2,5  winsay 'BackUp Before running this!'

	in window aWin @ 4,5  winsay 'This process allows you to create cheques for'
	in window aWin @ 5,5  winsay 'all or some portion of the growers.'

   in window aWin @ 7,2  winsay 'The PAYMENT GROUP is what allows you the most'
   in window aWin @ 8,2  winsay 'flexibility to include/exclude growers from a'
   in window aWin @ 9,2  winsay 'cheque run.  Growers ON-HOLD will not be paid.'

	in window aWin @11,2 winsay 'The procedure to Generate Cheques:'
	in window aWin @12,5 winsay '1. Determine Payment Due for Production'
	in window aWin @13,5 winsay '2. Determine Total Payments to be Made on this run'
	in window aWin @14,5 winsay '3. Produce Cheques (includes deductions)'
	in window aWin @15,5 winsay '4. Print Statements to accompany cheques'

	in window aWin @17,2 winsay 'This produces cheques to pay Advances!'

	ThinWait()
   if 'SANDBOX' $ upper( CurDirectory())
   	WaitInfo({'Sand Box run - we do not backup!'})
   else
      if Yesno({'Do you wish to BACK UP ?  We encourage you to do this', ;
             'since these procedures will likely permanently change your', ;
             'data files!','', ;
             'We suggest backing up to a Flash Drive'} )
         // QuikBackUp( sysValue( SYS_OWN_DIRECTORY ),, .f. )
         QuikBackUp( sysValue( SYS_OWN_DIRECTORY ),  ;
                     sysValue( SYS_FOLDER_TO_BACKUP_INTO ), ;
                     sysValue( SYS_FOLDER_BACKUP_BU1_2 ) , ;
            'Defaults for this are in your System Settings.', ;
                     sysValue( SYS_TRY_ROBOCOPY_FOR_QBU ) )

         //  thisStation( STN_BACKUP_FOLDER ), ;
         //  thisStation( STN_BACKUP_TO_C_BU ) , ;
         //  'Defaults for this are in your Station Settings.'       )
      endif
   endif

	msgLine('Getting ready to roll...')

	inkey( 1 )
	if !( open4ChequeRun(DB_EXCLUSIVE) )
		close databases
		return( nil )
	endif

	LogAnEvent( EVT_TYPE_GO_INTO_PAY_FIX, ;
		            { 'PayFixer '+var2char( nAdvance ) + ' - Warning' } )

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

   	in window aWin @ 2,2  winsay 'Cheque Date: ' winget dChqDate picture '@d' ;
		 valid ReasonablePostDate( dChqDate, .t., 'Cheque Date' ) ;
       GET_MESSAGE 'The accounting date of Generated Transactions and Cheques'
		in window aWin @ 3,2  winsay 'Include to:  ' winget dLastDate ;
		 valid ReasonablePostDate( dLastDate, .t., 'Include to Date' ) ;
		 GET_MESSAGE 'Include deductions and other adjustments up to this date'

		in window aWin @ 4,2 winsay  'For Crop Year' winget nYear  ;
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
        when PutName(aWin, 12 ,30,LU_PRODUCT, cProduct ) ;
        valid PutName(aWin,12, 30,LU_PRODUCT, cProduct ) ;
       LOOKUP( LU_PRODUCT, ;
'You may restrict this run to apply only to a single product')

		in window aWin @13,2 winsay '       Process' winget cProcess ;
		 picture '@!' ;
        when PutName(aWin, 13 ,30,LU_PROCESS_TYPE, cProcess ) ;
        valid PutName(aWin,13, 30,LU_PROCESS_TYPE, cProcess ) ;
       LOOKUP( LU_PROCESS_TYPE, ;
'You may restrict this run to apply only to a single process')

		read
   	if lastkey()==K_ESC
   		exit
   	endif

		if !( ReasonablePostDate( dChqDate, .t., 'Cheque Date' ) .and. ;
		      ReasonablePostDate( dLastDate, .t., 'Posting Date' ))
			WaitInfo({'Dates are looking wonky' })
		endif

      if GoofyParam( nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp )
			loop
		endif

      nChoice := ThinChoice( ;
      {'Determine','Cheques','Statements','OnHolds','X - eXit'})

		// because daily Might have the temporary index DAYTEMP open....
      msgLine('Cleaning up....')
		Daily->(dbCloseArea())
      sleep( 10 )
      if file('DAYTEMP.CDX')
         fErase('DAYTEMP.CDX')
      endif
		if !openFile({'Daily'}, DB_EXCLUSIVE)
			exit
		endif

   	do case
      case nChoice == 0 .or. nchoice == 5
   		exit
   	case nChoice == 1
			LogAnEvent( EVT_TYPE_PAY_FIX_PROCESS_IT, ;
		            {'PayFixer '+var2char( nAdvance ) + ' - Processing',  ;
						 'Date:'+shMdy(dLastDate)+' Prod/Proc='+cProduct+cProcess} )

         if Check4Err( dLastDate, cProduct, cProcess, ;
                nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp, nAdvance )

				// this means a VALID price is found for relevent
				// Unposted Transactions...
				nPostBatch := findLastUniqOnFile( UF_THE_POST_BAT , .f. )  + 1         // no need to Lock, in Exclusive More

            if IndexDayTemp( dLastDate, cProduct, cProcess, ;
                   nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp, nAdvance )

               aHead := { cAdvance +' Advance Payment Batch '+lStrim(nPostBatch) }

					VariousHead( aHead, dLastDate, cProduct, cProcess, ;
		 				nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp )

               if Determine( dLastDate, nPostBatch, aHead, nAdvance )

						if sysValue(SYS_ALLOW_CANADIAN_DOLLARS)
   			 			Cheques(CANADIAN_DOLLARS, CHEQUE_TYPE_WEEKLY, ;
							nYear, nIncGrower, cOrder, lPayGrp, cIncPayGrp, dLastDate)
						endif

						if sysValue(SYS_ALLOW_US_DOLLARS)
							Cheques(US_DOLLARS, CHEQUE_TYPE_WEEKLY, ;
							 nYear, nIncGrower, cOrder, lPayGrp, cIncPayGrp, dLastDate)
						endif

	   		 		exit
					endif
	   	 	endif
			endif

   	case nChoice == 2
			if sysValue(SYS_ALLOW_CANADIAN_DOLLARS)
				Cheques(CANADIAN_DOLLARS,CHEQUE_TYPE_WEEKLY, ;
					 nYear, nIncGrower, cOrder, lPayGrp, cIncPayGrp, dLastDate)
			endif

			if sysValue(SYS_ALLOW_US_DOLLARS)
				Cheques(US_DOLLARS ,     CHEQUE_TYPE_WEEKLY, ;
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
	enddo
	close databases
   sleep( 10 )
   msgLine('Cleaning up....')
   if file('DAYTEMP.CDX')
      fErase('DAYTEMP.CDX')
   endif
	kill window aWin
return( nil )

static function IndexDayTemp( dLastDate, cProduct, cProcess, ;
       nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp, nAdvance )

	local lReturn := .f.
	local bFor1,bFor2,bFor3,bFor4

   StopCompilerWarning( nExcGrower )
   StopCompilerWarning( nIncGrower )
   StopCompilerWarning( dLastDate  )
   StopCompilerWarning( cIncPayGrp )
   StopCompilerWarning( cExcPayGrp )

   nNoRec := 0

	msgLine('Building temporary index....')

   Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))
	dbSelectAR('Daily')
	Daily->(dbSetRelat( 'Grower', { || str( Daily->number, FLD_GROWER)}, ;
		'str( Daily->number,'+ lStrim( FLD_GROWER)+')' ))

	do case
   case nAdvance == 1
      SetForClause(  FOR_TYPE_ADVANCE_1 )
   case nAdvance == 2
      SetForClause(  FOR_TYPE_ADVANCE_2 )
   case nAdvance == 3
      SetForClause(  FOR_TYPE_ADVANCE_3 )
   otherwise
      appError( APP_ERR_UNKNOWN_ADVANCE_TYPE4, { ;
         'Advance Number not known'})
   endcase

   SetHoldUI( .T. )

   bFor1 := { || Daily->adv_pr1 > 0 .and. Daily->adv_prID1 > 0 .and. Daily->post_bat1 == 0 .and. Daily->fin_bat > 0 } // Changed
   bFor2 := { || .t. } //  { || GrInPayGrp(cIncPayGrp,cExcPayGrp) }
   bFor3 := { || forPP( cProduct, cProcess ) }
   bFor4 := { || .t. } // { || ExclOnHold( ) }

   // if nIncGrower > 0
   //   bFor1 := { || Daily->adv_pr1 > 0 .and. Daily->adv_prID1 > 0 .and. Daily->post_bat1 == 0 .and. Daily->fin_bat == 0  .and. Daily->number == nIncGrower }
   // endif

   if file('DAYTEMP.CDX')
      fErase('DAYTEMP.CDX')
   endif
   InitGeneralFor( bFor1, bFor2, bFor3, bFor4 )

   /* --------------------- this is the Original ----------------------------------------------
   Daily->( OrdCondSet( 'GeneralFor()', ;
              { || GeneralFor() }, ;
                 .f., ;
               { || Daily->fin_bat==0 .and. Daily->date <= dLastDate } ) )
   Daily->( OrdCreate( 'DAYTEMP', 'USETHIS',   ;
          'str( Daily->number,      4    )+ dtos( Daily->date) + str( Daily->recpt,  6        )', ;
      { || str( Daily->number, FLD_NUMBER)+ dtos( Daily->date) + str( Daily->recpt, FLD_RECPT )} ) )
   -------------------------------------- */

   // This is the CHANGE to CORRECT


   /*
   Daily->( OrdCondSet( 'GeneralFor()', ;
              { || GeneralFor() }, ;
                 .f., ;
               { || Daily->fin_bat > 0 .and. Daily->date <= dLastDate } ) )
   */

   Daily->( dbGoTop())   // MayBe this is NEEDED ...

   Daily->( OrdCreate( 'DAYTEMP', 'USETHIS',   ;
          'str( Daily->number,      4    )+ dtos( Daily->date) + str( Daily->recpt,  6        )', ;
      { || str( Daily->number, FLD_NUMBER)+ dtos( Daily->date) + str( Daily->recpt, FLD_RECPT )} ) )

   if empty( Daily->(OrdBagName('USETHIS')) )
      AppError(APP_ERR_TEMP_INDEXING6, {'Hmm-we have a problem!'})
   endif

   Daily->( OrdSetFocus('USETHIS') )

   Daily->(dbGoTop())

   SetHoldUI( .f. )

   SetForClause( FOR_TYPE_ALWAYS_TRUE )

   Daily->( dbSetFilter( { || GeneralFor() }, 'GeneralFor()' ) )
   Daily->(dbGoTop())
   if Daily->(eof())
      WaitHand({"We found NOTHING"})
   else
      lReturn := .t.
      msgLine('Counting up stuff....')
      do while !Daily->(eof())
         nNoRec++
         Daily->(dbSkip())           // we know how many tickets..
      enddo
      WaitHand({'We found '+var2char( nNoRec )+' records'})
      Daily->(dbClearRel())
      Daily->(dbGoTop())
   endif

   // DailyBrowse( nGrower, nType )
   DailyBrowse( 0, DAILY_ANY_TRANS )

   // 2BFIXED    TO BE FIXED MAYBE
   // OpenMoreIndexes( 'Daily' )

   Daily->(dbClearRel())
return( lReturn )


static function Determine( dLastDate, nPostBatch, aHead, nAdvance )

	local lReturn := .f.
   local n
   local cPostType

	// 'Batch '+lStrim(nPostBatch)+ 	' Weekly Advances to '+shMDY(dLastDate) }

   do case
   case nAdvance == 1
   	cPostType := C_ACCOUNT_POST_TYPE_WEEKLY_1
   case nAdvance == 2
   	cPostType := C_ACCOUNT_POST_TYPE_WEEKLY_2
   case nAdvance == 3
   	cPostType := C_ACCOUNT_POST_TYPE_WEEKLY_3
   otherwise
      AppError( APP_ERR_UNKNOWN_ADVANCE_TYPE7, { ;
        'Bad Advance type in DETERMINE()' })
      return( .f. )

   endcase


	// if SelectPrn('WEEK.TXT')
	if SelectPrn('WEEK_'+cPostTYpe )
		msgLine('Hang on...we are preparing for this ordeal')

		nAcct_Uniq := NextAcctUniq( )

		MakeTempPostDBFs()

		Daily->(dbGoTop())
		do while !Daily->(eof())  // remember we are in the Temporary Order

         if Grower->number <> Daily->number
            Grower->(OrdSetFocus( GROWER_NUMBER_ORD))
            Grower->(dbSeek( str( Daily->number, FLD_GROWER),HARDSEEK ))
         endif

         if Grower->onHold
            appError( APP_ERR_GROWER_HOLD1 , ;
             {'We are trying to pay a Grower ON HOLD', ;
              'This should not happen - we should have excluded them', ;
              'previously '+lStrim(Grower->number) })

            do while !Daily->(eof()) .and. Grower->number==Daily->number
               Daily->(dbSkip())
            enddo

         else

            OneGrower( dLastDate, nPostBatch, nAdvance )
         endif

      enddo

	   if Post2Account( nAcct_Uniq, aHead, .t. )
			PostBat->(addRecord())
			PostBat->POST_BAT  := nPostBatch
			PostBat->date      := date()
			PostBat->CutOff    := dLastDate
			PostBat->Post_Type := 'Sp'+var2char( nAdvance )
			
			PostBat->(dbCommit())
			lReturn := .t.

         WaitExclam({'We have posted the Payment Vouchers', ;
            'Data that may be of interest to Crafted Industrial:', ;
            ' nReplaced = '+str(nReplaced,10), ;
            ' nNoRec    = '+str(nNoRec,10) })
		else
			lReturn := .f.   // redundant, but just to be CLEAR
         n := 0
			msgLine('Unmarking the Daily File....')
			Daily->(dbGoTop())
			do while !Daily->(eof())
            do case
            case nAdvance == 1 .and. Daily->post_bat1==nPostBatch
               Daily->post_bat1  := 0
               Daily->adv_pr1    := 0
               Daily->prem_price := 0
               Daily->ADV_PRID1  := 0
               n++
            case nAdvance == 2 .and. Daily->post_bat2==nPostBatch
               Daily->post_bat2  := 0
               Daily->adv_pr2    := 0
               Daily->ADV_PRID2  := 0
               n++
            case nAdvance == 3 .and. Daily->post_bat3==nPostBatch
               Daily->post_bat3  := 0
               Daily->adv_pr3    := 0
               Daily->ADV_PRID3  := 0
               n++
            endcase

				Daily->(dbSkip())
			enddo
         do case
         case n > nReplaced
            AppError( APP_ERR_REMOVING_UPDATE1, ;
                  {'We set more records to UNPAID', ;
                   'than we paid. This is a problem !', ;
                   'Call Crafted Industrial Software Ltd.!', ;
                   'n         = '+str(n,10), ;
                   'nReplaced = '+str(nReplaced,10), ;
                   'nNoRec    = '+str(nNoRec,10) })
         case n==nReplaced
            WaitInfo({'We are PROBABLY set back to unpaid correctly'})
         endcase

			WaitExclam({'One problem you may have is that', ;
				'the system has now MARKED some of your', ;
				'Price Table Advances as being USED.  If this', ;
				'is a problem call Crafted Industrial Software Ltd. or', ;
            'restore your Back Ups !!!','', ;
            'Data that may be of interest to Crafted IS Ltd:', ;
            ' n         = '+str(n,10), ;
            ' nReplaced = '+str(nReplaced,10), ;
            ' nNoRec    = '+str(nNoRec,10) })
		endif

		CloseTempPostDBFs()
	endif

   inkey()
   inkey()

return( lReturn )

static Function OneGrower( dLastDate, nPostBatch, nAdvance )
	// assume Grower.DBF is in correct position
   local n

	msgLine('Calculating for '+lstrim(Grower->number)+' '+Grower->name)

   if nAdvance < 1 .or. nAdvance > 3
      appError( APP_ERR_UNKNOWN_ADVANCE_TYPE8, ;
         {'Unknown Advance Type - BAD Thing', ;
         'CALL Crafted Industrial Software Ltd. A.S.A.P.  !!!'})
   endif

	aAccountRec :={}

	do while Daily->number==Grower->number .and. !Daily->(eof())
      BuildFrDaily( nPostBatch, nAdvance )
      Daily->(dbSkip())
	enddo

	for n := 1 to len(aAccountRec)
		TempAcct->(addRecord())
		TempAcct->date := dLastDate
		TempAcct->year := nYear
		TempAcct->number := Grower->number

		TempAcct->currency := Grower->currency

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
		TempAcct->gst_est   := aAccountRec[n, AA_GST_AMT]

      // Should Have nPostBatch and Adv Number in Here - noted Sep 2019
      TempAcct->adv_bat   := nPostBatch
      TempAcct->adv_no    := nAdvance

	next

return( nil )

static function BuildFrDaily( nPostBatch, nAdvance )
	local nPrice, cType, nLbs,  cClass, nExtended, nGST
   local lFirstPaid
   local lReplace
	local lGst

	cClass := space(8)
   lReplace := .f.

   do case
   case nAdvance==1 .and. Daily->post_bat1 <> 0
		appError( APP_ERR_TRYING_TO_POST_TWICE1, ;
         {'We are trying to POST an Advance #1', ;
			 'to a Daily record that has already', ;
			 'been posted to! We are preventing this', ;
			 'CALL Crafted Industrial Software Ltd. A.S.A.P.  !!!'})
   case nAdvance==2 .and. Daily->post_bat2 <> 0
      appError( APP_ERR_TRYING_TO_POST_TWICE2, ;
         {'We are trying to POST an Advance #2', ;
			 'to a Daily record that has already', ;
			 'been posted to! We are preventing this', ;
			 'CALL Crafted Industrial Software Ltd. A.S.A.P.  !!!'})
   case nAdvance==3 .and. Daily->post_bat3 <> 0
      appError( APP_ERR_TRYING_TO_POST_TWICE3, ;
         {'We are trying to POST an Advance #3', ;
			 'to a Daily record that has already', ;
			 'been posted to! We are preventing this', ;
			 'CALL Crafted Industrial Software Ltd. A.S.A.P.  !!!'})
   otherwise
      if nAdvance < 1 .or. nAdvance > 3
         appError( APP_ERR_UNKNOWN_ADVANCE_TYPE6, ;
            {'Unknown Advance Type - BAD', ;
             'Advance Number is '+Var2Char( nAdvance ), ;
             'CALL Crafted Industrial Software Ltd. A.S.A.P.  !!!'})
      endif
   endcase

	// if Daily->(FindPrice( Daily->product, Daily->process, Daily->date))   Original is correct
	if Daily->adv_pr1 > 0 .and. Daily->post_bat1==0 .and. Daily->fin_bat > 0
      // Nov 2001 - we pay as many advances as we need to...
      lFirstPaid := .t.  // have PAID 1st Advance

      nLbs  := Daily->net
      // if nAdvance >= 1 .and. Daily->adv_prid1 == 0 .and. Daily->post_bat1==0
      if nAdvance >= 1 .and. Daily->adv_pr1 > 0.00 .and. Daily->post_bat1==0
         lFirstPaid := .f.  // we had not previously paid 1st Advance

         nPrice := Daily->adv_pr1                       // Daily->(RunAdvPrice( 1 ))
         cType  := TT_BERRY_ADVANCE_1
         nExtended := nLbs * nPrice

         // this line added in June 2000, so that the Advance is
         // known for SURE !
         // Daily->adv_pr1   := nPrice
         Daily->post_bat1    := nPostBatch
			Daily->LAST_ADVPB   := nPostBatch
         // Daily->adv_prid1 := Price->PriceID
         lReplace := .t.

         Add2ARec(cType, cClass, Daily->product, Daily->process, Daily->grade, ;
			 nPrice, nLbs,nExtended)

         // June 2000 - do not care about this in this context
         // if !Price->ADV1_USED
         //    Price->adv1_used := .t.
         // endif
      endif

		// Ignore all this
      /* -------------------------------------

      if nAdvance >= 2 .and. Daily->adv_prid2 == 0 .and. Daily->post_bat2==0


         // nPrice := Daily->(RunAdvPrice( 2 ))
         // The statement above is what you would expect, but if
         // the price for advance 1 was not set correctly, the
         // total advance for no 2 will correct that
         // this applies to all lines below

         nPrice := Daily->(RunAdvPrice( 2 )) - Daily->adv_pr1

         cType  := TT_BERRY_ADVANCE_2
         nExtended := nLbs * nPrice

         Daily->adv_pr2    := nPrice
         Daily->post_bat2  := nPostBatch
			Daily->LAST_ADVPB := nPostBatch
         Daily->adv_prid2  := Price->PriceID
         lReplace := .t.

         Add2ARec(cType, cClass, Daily->product, Daily->process, Daily->grade, ;
			 nPrice, nLbs,nExtended)

         if !Price->ADV2_USED
            Price->adv2_used := .t.
         endif
      endif

      if nAdvance >= 3 .and. Daily->adv_prid3 == 0 .and. Daily->post_bat3==0
         // nPrice := Daily->(RunAdvPrice( 3 ))
         nPrice := Daily->(RunAdvPrice( 3 )) - ;
             Daily->adv_pr1 - Daily->adv_pr2

         cType  := TT_BERRY_ADVANCE_3
         nExtended := nLbs * nPrice

         Daily->adv_pr3    := nPrice
         Daily->post_bat3  := nPostBatch
			Daily->LAST_ADVPB := nPostBatch
         Daily->adv_prid3  := Price->PriceID
         lReplace := .t.

         Add2ARec(cType, cClass, Daily->product, Daily->process, Daily->grade, ;
			 nPrice, nLbs,nExtended)

         if !Price->ADV3_USED
            Price->adv3_used := .t.
         endif
      endif
      ---------------------------------------- */

      if !empty(Daily->product) .and. !lFirstPaid .and. lReplace
         // if we have not PREVIOUSLY paid the first Weekly Advance
         // then we deduct the Marketting Deduction & add in the
         // time based premium.

         nPrice := MrkDeduction( Daily->product )
         if str( nPrice,12,3) <> str(0,12,3)
            // nPrice := Product->deduct
            cType  := TT_STD_DEDUCTION    // Marketing Deduction
				nExtended := nLbs * nPrice
				nGST      := 0.0000
				lGST      := .f.
				if Grower->chg_gst
					lGST := .t.
				endif

				if lGST .and. validTest(V_PRODUCT, Daily->product, VT_MESSAGE )
					if Product->chg_gst
						nGST := nExtended * TaxFinder( TAXNAME_IS_GST, TAX_VALUE_RATE, dChqDate  )  // 2BFIXED
					else
						lGST := .f.
					endif
				endif

				// We do NOT care about the Process or Grade for this!
				Add2ARec(cType, cClass, Daily->product,'',0, ;
					 nPrice, nLbs,nExtended, nGst)
			endif

         /* ---------------- they are not using
			nPrice := Daily->(AdvancePrem(  ))

			if str(nPrice,12,3)<>str(0,12,3)
            cType  := TT_TIME_PREMIUM      // Premium for Being Early
				nExtended := nLbs * nPrice
				Daily->prem_price := nPrice

            lReplace := .t.

				// We do NOT care about the Grade for this!
				Add2ARec(cType, cClass, Daily->product, Daily->process, 0, ;
					 nPrice, nLbs,nExtended)
			endif
         -------------------------- */
		endif
	endif

	// July 31, 96 - to deal with problem with CONTAINER Receipts showing
	//               in current file

	if Daily->(AnyContainers( )) .and. ;
	   empty(Daily->product) .and. empty(Daily->process) .and. ;
	   empty(Daily->grade)

			nPrice := 0.00
         cType := TT_ADV_CONTAINER_ONLY
			nLbs  := 0
			nExtended := 0
			Add2ARec(cType, cClass, '','',0, nPrice, nLbs,nExtended)

         if nAdvance >= 1 .and. Daily->post_bat1==0
            Daily->post_bat1  := nPostBatch
				Daily->LAST_ADVPB := nPostBatch
            lReplace := .t.
         endif
         if nAdvance >= 2 .and. Daily->post_bat2==0
            Daily->post_bat2  := nPostBatch
				Daily->LAST_ADVPB := nPostBatch
            lReplace := .t.
         endif
         if nAdvance >= 3 .and. Daily->post_bat3==0
            Daily->post_bat3  := nPostBatch
				Daily->LAST_ADVPB := nPostBatch
            lReplace := .t.
         endif

	endif

   if lReplace
      nReplaced++
   endif

return( nil )

static function Add2ARec(cType, cClass, cProduct, cProcess, nGrade, ;
		   nPrice, nLbs,nExtended, nGst)
	local n, nRow

	default nGst to 0.0000

	nRow := 0
	for n:=1 to len(aAccountRec)
		if aAccountRec[n,AA_TYPE]==cType .and. aAccountRec[n,AA_CLASS]==cClass ;
				.and. aAccountRec[n,AA_PRODUCT] == cProduct ;
				.and. aAccountRec[n,AA_PROCESS] == cProcess ;
				.and. aAccountRec[n,AA_GRADE  ] == nGrade

			if nPrice==aAccountRec[n,AA_PRICE]
				aAccountRec[n,AA_WEIGHT]   += nLbs
				aAccountRec[n,AA_EXTENDED] += nExtended
				aAccountRec[n,AA_GST_AMT]  += nGst
				nRow := n
				exit
			endif
		endif
	next

	if nRow == 0
		aadd(aAccountRec, AA_STRU )
		nRow := len(aAccountRec)
		aAccountRec[nRow, AA_TYPE]      := cType
		aAccountRec[nRow, AA_CLASS]     := cClass
		aAccountRec[n,    AA_PRODUCT]   := cProduct
		aAccountRec[n,    AA_PROCESS]   := cProcess
		aAccountRec[n,    AA_GRADE  ]   := nGrade
		aAccountRec[nRow, AA_PRICE]     := nPrice
		aAccountRec[nRow, AA_WEIGHT]    := nLbs
		aAccountRec[nRow, AA_EXTENDED]  := nExtended
		aAccountRec[nRow, AA_ACCT_UNIQ] := nAcct_Uniq
		aAccountRec[nRow, AA_GST_AMT]   := nGST
		nAcct_Uniq ++
	endif

	// Oct 99
	if nRow > 0
		if aAccountRec[nRow, AA_EARLY_DATE ] > Daily->date .or. ;
			empty( aAccountRec[ nRow, AA_EARLY_DATE ] )

			aAccountRec[nRow, AA_EARLY_DATE ] := Daily->date
		endif
	endif

   // TempAud->(dbAppend())
	TempAud->(addRecord())
   TempAud->day_uniq  := Daily->day_uniq
   TempAud->acct_uniq := aAccountRec[nRow,AA_ACCT_UNIQ]

return( nil )



