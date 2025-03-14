// PostSum.PRG
// Sep 99
// Bill Hepler
// (c) 1999,  Crafted Industrial Software Ltd. and Bill Hepler
//    various reports on Posted Transactions in the ACCOUNT.DBF
//    table.
// 2010 - Fixed for Alaska
// 2011 - Minor Rev for Account Reporting.
// 2014 - some changes for GST


#include 'common.ch'
#include 'window.ch'
#include 'bsgstd.ch'
#include 'printer.ch'
#include 'BerryPay.ch'
#include 'berry_rpt.ch'
#include 'inkey.ch'
#include 'sysvalue.ch'
#include 'valid.ch'
#include 'account.ch'
#include 'radio.ch'
#include 'price.ch'
#include "field.ch"
#include "indexord.ch"
#include "SumRptBld.ch"
#include "rpt.ch"
#include "errors.ch"


function PostSummary()
	local aWin, getList :={}
	local aRadio, nRadio
	local nYear
	local dFrom, dTo
	local cNtx,cSumFile
	local nCnt
	local lConfigure := .f., lLegend := .f.
	local aTitle
	local nWide := 60
	local aRpt
	local bYear

	if !openMainStuff( DB_SHARED)
		close databases
		return( nil )
	endif

	dFrom   := sysValue( SYS_CURRENT_SEASON_START )
	dTo     := date()
	nYear   := sysValue( SYS_CURRENT_YEAR )

	create radiobox 06,12 using { ;
	 'Grower Summary (by Product)    ', ;
	 'Product Summary Only           ', ;
	 'Outstanding Posted Transactions', ;
	 'NonBerry Transactions          '} title 'Type of Report' frame to aRadio
	nRadio := 1

	myBsgScreen( 'Posted Transaction Reports' )
   
	create window at 4,10,21,60 title 'Posted Transactions' to aWin
	display window aWin
	set cursor on

	in window aWin @ 17,2 winsay 'This ledger includes ONLY posted transactions'
	in window aWin @ 18,2 winsay 'It does not include UNPAID berry receipts.'

	do while .t.
		msgLine('[Esc] to Exit')
		nRadio := RadioDo(aRadio,nRadio)
		if lastkey()==K_ESC
			exit
      endif

   	in window aWin @  9,2  winsay 'Crop Year' winget nYear picture '@Z 9999' ;
   	 GET_MESSAGE ;
   	 'Enter the Crop Year ONLY if you want the the Ledger for a single crop year'

   	in window aWin @ 10,2  winsay 'From' winget dFrom picture '@d' ;
   	 GET_MESSAGE ;
   	 'Enter the From Date (remember your little +/- keys)'

   	in window aWin @ 11,2  winsay ' To ' winget dTo   picture '@d' ;
   	 GET_MESSAGE ;
   	 'Enter the To Date (remember your little +/- keys)'

   	in window aWin @ 13,2 winsay 'Configure Columns ' winget lConfigure ;
			picture 'Y' ;
   	 GET_MESSAGE ;
   	 'You may choose and arrange the columns to print'

		in window aWin @ 14,2 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

		READ

		if lastkey()==K_ESC
			exit
		endif
		cNtx := uniqueFile()
		if empty(cNtx)
			waitHand({'Please Reindex and Erase Temporary Files'})
			exit
		endif

		if selectPrn('POSTED_T.TXT')
         aTitle := { TheClientName( ), ;
           '', 'From '+shMDY(dFrom)+ ' to '+shMDY(dTo) }

			if nYear==0
				bYear := { || .t. }        // always true
			else
				bYear := {|| Account->year == nYear }
				aadd( aTitle, 'Crop Year ='+str(nYear,5))
			endif

			aRpt := {}
			InitSumRpt( aRpt )

			if nRadio  == 1 .or. nRadio  == 2

				msgLine('Index the Accounting Data....')

				cSumFile := CreateSumFile()
				nCnt := 0
				InitSumRep()

				SetSumReps( SUMREP_FILE_TO_SEARCH, 'Account')
				SetSumReps( SUMREP_SUM_FILE, cSumFile )
				SetSumReps( SUMREP_SEARCH_WHILE, {|| !Account->(eof()) } )
				SetSumReps( SUMREP_ADD_NEW_RECORD, ;
					{|| NewRec(cSumFile,  .T. ) } )


				SetSumReps( SUMREP_ADD_TO_RECORD,{|| AccumulateIt( cSumFile )} )
				SetSumReps( SUMREP_SHOW_PROG,{|| str(nCnt++,10)})

            Account->(OrdSetFocus( ACCOUNT_DATE_ORD ))   // for Speed
				Account->(dbSeek( dtos( dFrom ), SOFTSEEK ))

				do case
				case nRadio  == 1
					// Summary on Grower
					gRptInit( RP_ACCOUNTING_SUM_1, aRpt)
					gRptInitHead()
               aTitle[2] := 'Grower Accounting Summary'

					dbSelectArea('ACCOUNT')

               /* ---------------- FIXED June 2010
					index on str(Account->number, FLD_GROWER)+ ;
								Account->product + Account->process + ;
								str( Account->grade, FLD_GRADE ) ;
								to (cNtx) for AccountNotEmpty() .and.  ;
								eval(bYear) while Account->date <= dTo
               ------------------------ */
               InitGeneralFor( {|| AccountNotEmpty()}, ;
                                   bYear, {||.t.},{||.t.} )

               Account->( OrdCondSet( 'GeneralFor()', ;
                          { || GeneralFor() }, ;
                             .f., ;
                           { || Account->date <= dTo } ) )
               Account->( OrdCreate( cNtx, 'USETHIS',   ;
               'str(Account->number, 4            ) + Account->product + Account->process + str( Account->grade, 1 )' , ;
               { || str(Account->number, FLD_GROWER)+ ;
                    Account->product + Account->process + ;
                    str( Account->grade, FLD_GRADE) } ) )

               if empty( Account->(OrdBagName('USETHIS')) )
                  AppError(APP_ERR_TEMP_INDEXING10, {'Hmm-we have a problem!'})
               endif

               Account->( OrdSetFocus('USETHIS') )

					Account->(dbGoTop())

					SetSumReps( SUMREP_ADD_NEW_RECORD, ;
						{|| NewRec(cSumFile, .t. ) } )
					SetSumReps( SUMREP_IS_SAME_RECORD, ;
						{||SameProdStuff(cSumFile) .and. SameGrowStuff(cSumFile) } )

					gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
					gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {||(cSumFile)->number} )
					gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
						{ || nuQprnOut( ' '+;
							lStrim((cSumFile)->number) + ' '+ ;
							NameOf( LU_GROWER_NAME, (cSumFile)->number) ) } )

					gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL , .t.)

					gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_ON, {||(cSumFile)->product} )
					gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_TITLE, ;
						{ || nuQprnOut( ' Berry: '+;
							(cSumFile)->product + ' '+ ;
							NameOf( LU_PRODUCT, (cSumFile)->product) ) } )

					gRptGetSetHead( RPT_HEAD_3SUBTOTAL , .t.)

					gRptGetSetHead( RPT_HEAD_3SUBTOTAL_ON, {||(cSumFile)->process} )
					gRptGetSetHead( RPT_HEAD_3SUBTOTAL_TITLE, ;
						{ || nuQprnOut( '  Process: '+ ;
							(cSumFile)->process + ' '+ ;
							NameOf( LU_PROCESS_TYPE, (cSumFile)->process) ) } )

					gRptGetSetHead( RPT_HEAD_SUBTOTAL_END, ;
						{ || LevelDiv( '-', nWide ) })

					SetSumReps( SUMREP_IS_SAME_RECORD, ;
					 {||SameProdStuff(cSumFile) .and. SameGrowStuff(cSumFile) } )

				case nRadio  == 2
					gRptInit( RP_ACCOUNTING_SUM_2, aRpt)
					gRptInitHead()
               aTitle[2] := 'Product Accounting Summary'

					dbSelectArea('ACCOUNT')

               /* ------------------------------
					index on Account->product + Account->process + ;
								str( Account->grade, FLD_GRADE ) ;
								to (cNtx) for AccountNotEmpty() .and. ;
								eval(bYear) while Account->date <= dTo
               ----------------------- */

               InitGeneralFor( {|| AccountNotEmpty()}, ;
                                   bYear, {||.t.},{||.t.} )

               Account->( OrdCondSet( 'GeneralFor()', ;
                          { || GeneralFor() }, ;
                             .f., ;
                           { || Account->date <= dTo } ) )
               Account->( OrdCreate( cNtx, 'USETHIS',   ;
               'Account->product + Account->process + str( Account->grade, 1 )' , ;
               { || Account->product + Account->process + ;
                    str( Account->grade, FLD_GRADE) } ) )

               if empty( Account->(OrdBagName('USETHIS')) )
                  AppError(APP_ERR_TEMP_INDEXING11, {'Hmm-we have a problem!'})
               endif

               Account->( OrdSetFocus('USETHIS') )

					Account->(dbGoTop())

					gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)

					gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {||(cSumFile)->product} )
					gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
						{ || nuQprnOut( (cSumFile)->product + ' '+ ;
							NameOf( LU_PRODUCT, (cSumFile)->product) ) } )

					gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL , .t.)

					gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_ON, {||(cSumFile)->process} )
					gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_TITLE, ;
						{ || nuQprnOut( ' Process: '+ ;
							(cSumFile)->process + ' '+ ;
							NameOf( LU_PROCESS_TYPE, (cSumFile)->process) ) } )

					gRptGetSetHead( RPT_HEAD_3SUBTOTAL , .f.)
					gRptGetSetHead( RPT_HEAD_SUBTOTAL_END, NIL )

					SetSumReps( SUMREP_IS_SAME_RECORD, ;
						{|| SameProdStuff(cSumFile)  } )

				endcase

				msgLine('Making the Summary...' )

				MakeSumFile()

				(cSumFile)->(dbGoTop())

				Account->(dbCloseArea())
				openfile({'Account'}, DB_SHARED)  // unlikely to fail

				if lConfigure
					gRptSelect( aRpt )
				endif

				gRptGetSetHead( RPT_HEAD_TITLE, aTitle )
				nWide := gRptWidth( aRpt)

				if nWide >= sysValue(SYS_GENERALLY_SWITCH_TO_LANDSCAPE)
	            gRptAutoPageOrientation( aRpt, 0)
      	   endif


				PRINT_ON  RPT_OVERWRITE

            gRptPrintSize( aRpt )

				(cSumFile)->(gRptPrinter( aRpt ))

				if lLegend
					prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
				endif

				PRINT_OFF  RPT_COMPLETE_EJECT

				(cSumFile)->(dbCloseArea())

				KillUnique(cSumFile )

				if lConfigure
					if yesno({'Save this Production Report Format?'})
						gRptSave( aRpt )
					endif
				endif

			else

				msgLine('Index the Accounting Data....')

            Account->(OrdSetFocus( ACCOUNT_DATE_ORD ))   // for Speed
				Account->(dbSeek( dtos( dFrom ), SOFTSEEK ))

				dbSelectArea('ACCOUNT')

				do case
				case nRadio == 3

               aTitle[2] := 'Outstanding Posted Transactions'

               /* --------------------------------------
					index on str(Account->number, FLD_GROWER)+ ;
						Account->product + Account->process + ;
							str( Account->grade, FLD_GRADE ) ;
							to (cNtx) for AccountNotEmpty()  ;
							.and. Account->cheque== 0 .and. ;
							eval(bYear) while Account->date <= dTo
               ------------------------------------ */
               InitGeneralFor( {|| AccountNotEmpty()}, ;
                                   bYear, ;
                                   {|| Account->cheque==0},{||.t.} )

               Account->( OrdCondSet( 'GeneralFor()', ;
                          { || GeneralFor() }, ;
                             .f., ;
                           { || Account->date <= dTo } ) )
               Account->( OrdCreate( cNtx, 'USETHIS',   ;
               'str(Account->number, 4            ) + Account->product + Account->process + str( Account->grade, 1 )' , ;
               { || str(Account->number, FLD_GROWER)+ ;
                    Account->product + Account->process + ;
                    str( Account->grade, FLD_GRADE) } ) )

               if empty( Account->(OrdBagName('USETHIS')) )
                  AppError(APP_ERR_TEMP_INDEXING12, {'Hmm-we have a problem!'})
               endif

               Account->( OrdSetFocus('USETHIS') )

               aRpt := {}
					InitAccountRpt( aRpt, .f.  )   // in Grower Order
					gRptInit( RP_OUTSTANDING_ACC_DETAIL, aRpt)
					gRptInitHead()
               aTitle[2] := 'Outstanding Posted Transactions'

				case nRadio == 4
	 				//'NonBerry Transactions

               /* ------------------------------------------------
					index on str(Account->number, FLD_GROWER) + ;
						dtos(Account->date) ;
						 	to (cNtx) for AccountNotEmpty()   ;
							.and. ;
						 (empty(Account->product) .or. Account->type==TT_DEDUCT ;
								 .or. Account->type==TT_SPECIAL_CONTAINER .or. ;
								 Account->type==TT_EQUITY .or. ;
								 Account->type==TT_MISCELLANEOUS) ;
							.and. ;
						  eval(bYear) while Account->date <= dTo
               ------------------------------ */
               InitGeneralFor( {|| AccountNotEmpty()}, ;
                                   bYear, ;
                  {|| (empty(Account->product) .or. Account->type==TT_DEDUCT ;
                      .or. Account->type==TT_SPECIAL_CONTAINER .or. ;
                       Account->type==TT_EQUITY .or. ;
                       Account->type==TT_MISCELLANEOUS) }, ;
                                    {||.t.} )

               Account->( OrdCondSet( 'GeneralFor()', ;
                          { || GeneralFor() }, ;
                             .f., ;
                           { || Account->date <= dTo } ) )

               Account->( OrdCreate( cNtx, 'USETHIS',   ;
               'str(Account->number, 4            ) + Dtos(Account->date)' , ;
               { || str(Account->number, FLD_GROWER)+ Dtos(Account->date) } ))

               if empty( Account->(OrdBagName('USETHIS')) )
                  AppError(APP_ERR_TEMP_INDEXING13, {'Hmm-we have a problem!'})
               endif

               Account->( OrdSetFocus('USETHIS') )

					aRpt := {}
					InitAccountRpt( aRpt, .f. )     // in Grower order
					gRptInit( RP_NON_BERRY_DETAIL, aRpt)
					gRptInitHead()
               aTitle[2] := 'Non Berry Posted Transactions'

				endcase

				gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
				gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {||Account->number} )
				gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
					{ || nuQprnOut( ' '+;
						lStrim( Account->number) + ' '+ ;
						NameOf( LU_GROWER_NAME, Account->number) ) } )

				Account->(dbGoTop())

				if lConfigure
					gRptSelect( aRpt )
				endif

				gRptGetSetHead( RPT_HEAD_TITLE, aTitle )
				nWide := gRptWidth( aRpt)

				if nWide >= sysValue(SYS_GENERALLY_SWITCH_TO_LANDSCAPE)
	            gRptAutoPageOrientation( aRpt, 0)
      	   endif

				PRINT_ON  RPT_OVERWRITE

				gRptPrintSize( aRpt )
				Account->(gRptPrinter( aRpt ))

	         PrinterCtrl(PRN_CTRL_10_CPI)

            nuQprnOut()
            nuQprnOut('  Negative numbers are DEDUCTIONS - meaning the Grower owes' )
            nuQprnOut('  you money for these items.' )
            nuQprnOut()

				PRINT_OFF  RPT_COMPLETE_EJECT

				if lConfigure
					if yesno({'Save this Production Report Format?'})
						gRptSave( aRpt )
					endif
				endif

				Account->(dbCloseArea())
				openfile({'Account'}, DB_SHARED)  // unlikely to fail

			endif
		endif
		killUnique(cNtx, '.CDX' )
	enddo
	kill window aWin
	close databases
return( nil )


function InitAccountRpt( aRpt, lShowGrower )

	default lShowGrower to .f.

	aadd( aRpt,{ ' ',{|| ' '}, 'C', 3, 0, .t., .f., 'Nice Space'} )

	// Posted
	aadd( aRpt, { 'Type', ;
		 {|| NameOf(LU_SHORT_TRANSACTION_TYPE, Account->type) }, ;
		  'C',  15 , 0 , .t., .f., ;
		'Type of Transaction'})

	aadd( aRpt, { 'Class', ;
		 {|| Account->class }, ;
		  'C',  10 , 0 , .t., .f., ;
		'Type of Deduction or Tax if relevent'})

	aadd( aRpt, { 'Berry', ;
		 {|| Account->product+' '+Account->process+ ;
		     iif(Account->grade==0,' ',str(Account->grade,FLD_GRADE)) }, ;
		  'C',  8 , 0 , .t., .f., ;
		'The Product Type (or Blank)'})

	aadd( aRpt, { 'Date', ;
		 {|| shMDY(Account->date) }, ;
		  'C',  12 , 0 , .t., .f., ;
		'The Accounting Date of Transaction'})

	aadd( aRpt, { 'Note', ;
		 {|| Account->desc }, ;
		  'C',  30 , 0 , .t., .f., ;
		'Notes (if any)'})

	aadd( aRpt, { 'Amount', ;
		 {|| Account->dollars }, ;
		  ',',  12 , 2 , .t., .t., ;
		'The Amount Due !'})

	aadd( aRpt, { 'Cheque', ;
		 {|| iif(Account->cheque==0, ;
		     padc('UNPAID', FLD_CHEQUE + FLD_SERIES), ;
		     Account->series + str(Account->cheque, FLD_CHEQUE) ) }, ;
		  'C',  12 , 0 , .t., .f., ;
		'Cheque Number or Unpaid'})

	aadd( aRpt, { 'Grower', ;
		 {|| Account->Number }, ;
		  'N',  7 , 0 , .f., .f., ;
		  'Grower Number'})

	aadd( aRpt, { 'Grower Name', ;
		 {|| NameOf( LU_GROWER_NAME,Account->Number) }, ;
		  'C',  30 , 0 , .f., .f., ;
		  'Grower Name'})

	aadd( aRpt, { 'Amt', ;
		 {|| Account->dollars }, ;
		  ',',  12 , 2 , .f., .t., ;
		'The Amount Due...'})

	aadd( aRpt, { 'GST Est', ;
		 {|| Account->gst_est }, ;
		  ',',  12 , 2 , .f., .t., ;
		'The Amount of GST Due'})

	aadd( aRpt, ;
	{ ' '  	, { || '' }      ,  'C' ,    1  ,   000 , ;
		.f., .f. , ;
		'Space for Looks' } )

	aadd( aRpt, ;
	{ ' '  	, { || '' }      ,  'C' ,    1  ,   000 , ;
		.f., .f. , ;
		'Another Space for Looks' } )

		aadd( aRpt, ;
	{ 'Description' , { || AcctEntryFancyDesc( ) }       ,  'M' ,   FLD_DESC,   000 , ;
		.f., .F. , ;
		'Full MultiLine Description of Transaction' } )

	aadd( aRpt, { 'Trans#', ;
		 {|| Account->acct_uniq }, ;
		  'N',  FLD_DOCUMENT , 0 , .f., .f., ;
		'The Unique ID of this transction (for Audit)'})

return( nil )


static function InitSumRpt( aRpt )

	aadd( aRpt,{ ' ',{|| ' '}, 'C', 6, 0, .t., .f., 'Nice Space'} )

	// Posted
	aadd( aRpt, { 'Grade', ;
		 {|| iif(Field->grade==0,'','Grade'+str(Field->grade,2)) }, ;
		'C',  8 , 0 , .t., .f., ;
		'Grade For this - Blank if grade is not relevent'})

	aadd( aRpt, { {'Weekly','Receipts'}, {|| Field->wklbs }, ;
		',',  12 , 0 , .t., .t., ;
		'LBS received weekly - (posted)'})

	// 1,345,789.12
	aadd( aRpt, { {'Regular','Advance'}, {|| Field->weekly }, ;
		',',  13, 2 , .T., .t., ;
		'Regular Advance $ weekly - including unpaid reverses etc.'})

	aadd( aRpt, { {'Spec','Pay'}, {|| Field->special }, ;
		',', 13, 2, .T., .t., ;
		'Special $ Payments - including unpaid reverses etc.'})

	aadd( aRpt, { {'Other','Amounts'}, {|| Field->other }, ;
		',', 13, 2 , .t., .t., ;
		'Other $ amounts - Deductions, advances etc - includes unpaid'})

	aadd( aRpt, { {'Out','Standing'}, {|| Field->unpaid }, ;
		',',  13, 2 , .t., .t., ;
		'Amounts $ Still Due To or From Grower (Cheque not yet issued)'})

	//
	aadd( aRpt, { {'Final','Amounts'}, {|| Field->final }, ;
		',',  13, 2 , .T., .t., ;
		'Final Actual $ Payment Made - (advance NOT included in this)'})

	aadd( aRpt, { {'Total','Final'}, {|| Field->final + Field->weekly }, ;
		',',  13, 2 , .T., .t., ;
		'Final + Advance $ Payment'})

	aadd( aRpt, { {'Total','Regular'},  ;
		{|| Field->premium + Field->final + Field->weekly }, ;
		',',  13, 2 , .T., .t., ;
		'Final + Advance + Premium $ Payment'})

	aadd( aRpt, { {'Prem','LBS'}, {|| Field->PremLbs }, ;
		',',  12 , 0 , .t., .t., ;
		'LBS Premium has been Paid On - (posted)'})

	aadd( aRpt, { {'Fin','LBS'}, {|| Field->FinLbs }, ;
		',',  12 , 0 , .t., .t., ;
		'LBS Final had been Paid On - (posted)'})

   aadd( aRpt, { {'Regular','Advance'}, {|| Field->premium + Field->weekly }, ;
		',',  13, 2 , .T., .t., ;
      'Regular Advance $ weekly - including Premiums'})

return( nil )

static function SameProdStuff( cSumFile )
	local lReturn

	lReturn :=  (cSumFile)->product== Account->product .and. ;
	  (cSumFile)->process == Account->process .and. ;
	  (cSumFile)->grade == Account->grade

return( lReturn )

static function SameGrowStuff( cSumFile )
	local lReturn

	lReturn :=  (cSumFile)->number == Account->number

return( lReturn )


static Function NewRec( cSumFile, lGrower )

	// the Make actually appends the record...
	(cSumFile)->product := Account->product
	(cSumFile)->process := Account->process
	(cSumFile)->grade   := Account->grade

	if lGrower
		(cSumFile)->number   := Account->number
	endif

return( nil )

static function AccumulateIt( cSumFile )

	do case
   case Account->type == TT_BERRY_ADVANCE_1 .or. ;
        Account->type == TT_BERRY_ADVANCE_2 .or. ;
        Account->type == TT_BERRY_ADVANCE_3 .or. ;
        Account->type == TT_STD_DEDUCTION

      if Account->type == TT_BERRY_ADVANCE_1 .or. ;
        Account->type == TT_BERRY_ADVANCE_2 .or. ;
        Account->type == TT_BERRY_ADVANCE_3
			(cSumFile)->wkLbs += Account->lbs
		endif

		(cSumFile)->weekly += Account->dollars

   case Account->type == TT_TIME_PREMIUM
		(cSumFile)->premium += Account->dollars
		(cSumFile)->PremLbs += Account->lbs

	case Account->type == TT_FINAL_BERRY
		(cSumFile)->final   += Account->dollars
		(cSumFile)->FinLbs  += Account->lbs

	case Account->type == TT_SPECIAL_BERRY
		(cSumFile)->special += Account->dollars
      // (cSumFile)->specLbs += Account->lbs
      (cSumFile)->spLbs += Account->lbs

	otherwise
		(cSumFile)->other  += Account->dollars
	endcase

	if empty(Account->cheque)
		(cSumFile)->unPaid += Account->dollars
	endif

return( nil )

static function CreateSumFile()
	local cFileName
	local aStru := {}

	aStru := { ;
		{ 'NUMBER',    'N', FLD_NUMBER, 0 } , ;
		{ 'PRODUCT',   'C', FLD_PRODUCT, 0 } , ;
		{ 'PROCESS',   'C', FLD_PROCESS, 0 } , ;
		{ 'GRADE',     'N', FLD_GRADE, 0 } , ;
		{ 'WEEKLY',    'N', 12, 2 } , ;
		{ 'FINAL',     'N', 12, 2 } , ;
		{ 'PREMIUM',   'N', 12, 2 } , ;
      { 'PREMLBS',   'N', 12, 0 } , ;
		{ 'SPECIAL',   'N', 12, 2 } , ;
		{ 'OTHER',     'N', 12, 2 } , ;
		{ 'UNPAID',    'N', 12, 0 } , ;
		{ 'WKLBS',     'N', 12, 0 } , ;
		{ 'SPLBS',     'N', 12, 0 } , ;
		{ 'FINLBS',    'N', 12, 0 }    }

	cFileName := uniqueDBF(aStru )

return( cFileName )

static function LevelDiv( cLevelDiv, nWide )
	if !empty(cLevelDiv)
      nuQprnOut( replicate(cLevelDiv,nWide) )
      nuQprnOut( )
	endif
return( nil )

function AccountNotEmpty()
	local lReturn := .f.

	// because if there is NO LBS and NO dollars we don't care!
	if str(Account->lbs,13,1) <> str(0,13,1)
		lReturn := .t.
	endif

	if str(Account->dollars,13,2) <> str(0,13,2)
		lReturn := .t.
	endif
return( lReturn )
