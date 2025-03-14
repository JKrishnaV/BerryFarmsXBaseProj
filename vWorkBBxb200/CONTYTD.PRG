// -----------------------------------------------------------------------------
//  Application: Berry Pay Application
//  Description: Container information
//               Shows containers in/out for various periods
//     June 99   reWritten
//     July 99   on 19th corrected minor problem
//     July 2005 Minor revisions
//     July 2020 Hash Totals Added - a fair amount revision needed here
//               this is to test for a bug in Berry Receive, where it does
//               not send across all container transactions.
//     May 2021  Put in stuff for doing a SINGLE depot, which I think we need
//               because last year (2020), Avery/Pacific found a bug in the
//               export of containers, so we need a really strong audit trail
//               for each depot.
//
//    File Name: CONTYTD.PRG
//       Author: Bill Hepler
// Date created: 07-01-96              Date updated: 07-01-96
// Time created: 08:17:42pm            Time updated: 08:17:42pm
// Copyright: (c) 1996, 2020, 2021 by Bill Hepler & Crafted Industrial Software Ltd.
// --------------------------------------------------------------------------------

#include "berry_rpt.ch"
#include "common.ch"
#include "printer.ch"
#include "BerryPay.ch"
#include "bsgstd.ch"
#include "ERRORS.CH"
#include "inkey.ch"
#include "indexord.ch"
#include "field.ch"
#include "SumRptBld.ch"
#include "valid.ch"
#include "rpt.ch"
#include "sysvalue.ch"
#include "window.ch"

#define   A_D__THE_DEPOT_ID   1     // the Depot ID
#define   A_D__FILE_NAME      2     // file name for Temporary info
#define   A_D__RECORDS        3     // Number of Records
#define   A_D__DEPOT_ROW      { '','',0 }

#define   THE_MESSAGE_ROW    2
#define   HASH_MESSAGE       'Hash Totals Container Report'


function ContainSum()
	local dDate1, dDate2
	local getList := {}
	local aWin
	// local n
	local cSum
   local n
   local aDepot := {}
	local aTitle
	local aRpt
	local lConfigure := .f., lLegend := .f.
   local lRpt1,lRpt2,lHash
   local lPrint
   local cDepot

	if !openfile({'Grower','Daily','Depot'},DB_SHARED)
		close databases
		return( nil )
	endif

	lHash   := .t.
   lRpt1   := .t.
   lRpt2   := sysValue(SYS_LABEL_2_CONTAINER_RPT)
   cDepot  := space(FLD_DEPOT)

	myBsgScreen( 'Container Summary Report' )

	create window at 5,05,22,76 title 'Container Summary' to aWin
	display window aWin

	in window aWin @ 12,2 winsay ;
		 'This report shows calculates container movement for the period.'
   in window aWin @ 14,2 winsay ;
       'The Hash Total Report is intended so you can quickly see if the'
   in window aWin @ 15,2 winsay ;
       'container use from Scale PC(s) agrees with container use recorded'
   in window aWin @ 16,2 winsay ;
       'in BerryPay - check Grand Totals on Grower Container Balance !'

	dDate1 := FirstOfYear(date())
	dDate2 := date()

	do while .t.
		in window aWin @ 2, 2 winsay 'From' winget dDate1 picture '@D' ;
			get_message 'Enter starting date for tickets to consider'
		in window aWin @ 2, 20 winsay 'to ' winget dDate2 picture '@D' ;
			get_message 'Enter ending date for tickets to consider'

		in window aWin @ 4, 2 winsay 'Run Hash Total Report' winget lHash picture 'Y' ;
			get_message 'This report is intended for a Quick Comparison to Scale Report!'
		in window aWin @ 5, 2 winsay 'Run Detail Report # 1' winget lRpt1 picture 'Y' ;
			get_message 'This container Summary Report format #1'
		in window aWin @ 6, 2 winsay 'Run Detail Report # 2' winget lRpt2 picture 'Y' ;
			get_message 'This container Summary Report format #2'

		in window aWin @ 8, 2 winsay 'Configure Report Columns' winget lConfigure picture 'Y' ;
			get_message 'Select, arrange and format columns for this report'
		in window aWin @ 9, 2 winsay 'Show Column Legend      ' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

		in window aWin @10,2 winsay 'Depot ' winget cDepot picture '@!' ;
         when PutName(  aWin, 10, 15, LU_DEPOT, cDepot ) ;
         valid PutName( aWin, 10,15, LU_DEPOT, cDepot ) ;
         LookUp( LU_DEPOT, 'Blank for All Depots - F5 to Browse' )

		read

		do case
		case lastkey()==K_ESC
			exit

		case dDate1 > dDate2
			waitInfo({'The First Date has to be Smaller!'})
			loop

      case !( lHash .or. lRpt1 .or. lRpt2 )
      	WaitInfo({'You have not selected any reports to print!'})
         loop

		case SelectPrn('CONTAIN.TXT')

			gRptInitHead()
         aTitle := { TheClientName( ), ;
                     'Container Summary Report', ;
							'Includes unposted receipts', ;
					'From '+shMDY(dDate1)+' to '+shMDY(dDate2) }

         if !empty( cDepot )
         	aTitle[4] += (' Depot='+cDepot )
         endif


			if lConfigure
         	if lHash
					aRpt := {}
					setUpRpts( 3, aRpt, aTitle, .t. )
            endif

         	if lRpt1
					aRpt := {}
					setUpRpts( 1, aRpt, aTitle, .t. )
            endif

         	if lRpt2
					aRpt := {}
					setUpRpts( 1, aRpt, aTitle, .t. )
            endif
			endif

         if !empty( cDepot )
				cSum := Build1sum(dDate1,dDate2,cDepot )
         else
				cSum := Build1sum(dDate1,dDate2,'' )
         endif

         aDepot := {}

         if lHash
         	msgLine( 'Step 2 for the Hash Totals...')

            if !empty( cDepot )
            	aadd( aDepot, A_D__DEPOT_ROW )
               aDepot[ 1, A_D__THE_DEPOT_ID ] := cDepot
            else
               Depot->(dbGoTop())
               do while !Depot->(eof())
                  if !empty( Depot->depot )
                     aadd( aDepot, A_D__DEPOT_ROW )
                     n := len( aDepot )
                     aDepot[ n, A_D__THE_DEPOT_ID ] := Depot->depot
                  endif
                  Depot->(dbSkip())
               enddo
				endif

            if len( aDepot ) >= 1
            	for n := 1 to len( aDepot )
						aDepot[ n, A_D__FILE_NAME ] := Build1sum(dDate1, dDate2, aDepot[ n, A_D__THE_DEPOT_ID ] )
                  aDepot[ n, A_D__RECORDS   ] := (aDepot[ n, A_D__FILE_NAME ])->(LastRec())
               next
            else
            	WaitInfo({'No depots on file - better check this out'})
               loop
            endif
         endif

         // Do not bother unless requested
         // gRptSetWhen2LandScape( sysValue( SYS_GENERALLY_SWITCH_TO_LANDSCAPE)  )

		  	PRINT_ON  RPT_OVERWRITE

         lPrint := .f.

         if lHash
				// this will normally be PER Depot
				aRpt := {}
				setUpRpts( 3, aRpt, aTitle, .f. )
				gRptPrintSize( aRpt )

            for n := 1 to len( aDepot )
              	if aDepot[ n, A_D__RECORDS ] >= 1
                  if n > 1
                  	nuFormFeed()
                  endif

                  aTitle[ THE_MESSAGE_ROW ] := ;
                                  HASH_MESSAGE + ' - Depot: '+ aDepot[ n, A_D__THE_DEPOT_ID ]

                  gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

                  dbUseArea( .t., NIL, aDepot[ n, A_D__FILE_NAME ], NIL , .F. )
                  ( aDepot[ n, A_D__FILE_NAME ] )->(dbGoTop())
                  ( aDepot[ n, A_D__FILE_NAME ] )->(gRptPrinter( aRpt ))
               endif
            next

				if lLegend
            	prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
				endif
				lPrint := .t.
         endif

			if lRpt1
				// if we have lots of containers we need 2 reports
            if lPrint
					nuFormFeed()
            endif

				aRpt := {}
				setUpRpts( 1, aRpt, aTitle, .f. )

				gRptPrintSize( aRpt )

				(cSum)->(dbGoTop())
				(cSum)->(gRptPrinter( aRpt ))

				if lLegend
					prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
				endif
			endif

			if lRpt2
				// if we have lots of containers we need 2 reports
            if lPrint
					nuFormFeed()
            endif

				aRpt := {}
				setUpRpts( 2, aRpt, aTitle, .f. )

				gRptPrintSize( aRpt )

				(cSum)->(dbGoTop())
				(cSum)->(gRptPrinter( aRpt ))

				if lLegend
					prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
				endif
			endif

			PRINT_OFF RPT_COMPLETE_EJECT

			(cSum)->(dbCloseArea())
			killUnique(cSum)

         for n :=1 to len( aDepot )
         	if !empty( ( aDepot[ n, A_D__FILE_NAME ] ) )
					killUnique( aDepot[ n, A_D__FILE_NAME ] )
				endif
         next
		endcase
	enddo

	kill window aWin
	close databases
return( nil )

/// <summary>Depot is BLANK for all!
/// </summary>
static function Build1Sum(dDate1, dDate2, cDepot )
	field in1,in2,in3,in4,in5,in6,in7,in8,in9, ;
		     out1,out2,out3,out4,out5,out6,out7,out8,out9
	field in11,in12,in13,in14,in15,in16,in17,in18,in19, ;
		     out11,out12,out13,out14,out15,out16,out17,out18,out19
	field in10,in20,out10,out20

	local cTempDBF
	local aStru
	local nGrower, n, nQty, nQtyIn, nQtyOut
	local bInTemp,  bInData
	local bOutTemp, bOutData
	local nCount

   default cDepot to ''      // i.e.  ALL Depots

	aStru := ReceiptStru( RECEIPT_STRU_FOR_SUMMARY )

	cTempDBF   := uniqueDBF( aStru )

	msgLine('Stage 1....')
   Daily->(OrdSetFocus( DAILY_GROWER_ORD ))  /// do NOT use this... DAILY_DATE_ORD ))
   if empty( cDepot )
   	// ALL Depots...
      Daily->( dbSetFilter(   ;
         { || Daily->date >= dDate1 .and. Daily->date <= dDate2 }, ;
             'Daily->date >= dDate1 .and. Daily->date <= dDate2'     ))
   else
   	// Just one depot
      Daily->( dbSetFilter(   ;
         { || Daily->date >= dDate1 .and. Daily->date <= dDate2 .and. Daily->depot==cDepot }, ;
             'Daily->date >= dDate1 .and. Daily->date <= dDate2 .and. Daily->depot==cDepot'     ))
   endif

	nCount := 0
	Daily->(dbGoTop())
	do while !Daily->(eof())
		nGrower := Daily->number
		showProg( str(nCount++,6) )
		(cTempDBF)->(dbAppend())
		(cTempDBF)->number := nGrower

		do while !Daily->(eof()) .and. Daily->number==nGrower
			for n := 1 to MAX_TYPES_CONTAINERS

				bInTemp  := (cTempDBF)->(FieldBlock('IN'+lStrim(n)))
				bInData  :=    Daily->(FieldBlock('IN'+lStrim(n)))

				bOutTemp := (cTempDBF)->(FieldBlock('OUT'+lStrim(n)))
				bOutData :=      Daily->(FieldBlock('OUT'+lStrim(n)))

            nQtyIn   := Daily->(eval(bInData))
            nQtyOut  := Daily->(eval(bOutData))

				nQty     := (cTempDBF)->(eval(bInTemp))
				nQty     += Daily->(eval(bInData))


				// Adds data back in
				(cTempDBF)->(eval(bInTemp, nQty))


				nQty     := (cTempDBF)->(eval(bOutTemp))
				nQty     += Daily->(eval(bOutData))

				// Adds data back in
				(cTempDBF)->(eval(bOutTemp, nQty))

   			(cTempDBF)->HASH_IN  +=   nQtyIn                          // Added in 2020 for doing quick check of Containers
            (cTempDBF)->HASH_OUT +=   nQtyOut                         // These are HASH TOTALS
            (cTempDBF)->HASH_BAL += ( nQtyOut - nQtyIn )              // Balance

			next
         if empty( Daily->depot )
				appError( APP_ERR_BLANK_DEPOT_1, ;
              {'Blank Depot on a Daily Receipt - this should not occur!', ;
               '*** You should correct this ! ***',    ;
               'Grower # = '+var2char( Daily->number), ;
               'Receipt# = '+var2char( Daily->recpt ), ;
               'Record # = '+var2char( Daily->(recno()) )  })
         endif
			Daily->(dbSkip())
		enddo
	enddo

	Daily->( dbClearFilter())

return( cTempDBF )



static function SameNess( cSum )
	local lReturn

	lReturn := (cSum)->number == Field->number

return( lReturn )

static Function NewRec( cSum )

	// the Make actually appends the record...
	(cSum)->number := Field->number

return( nil )

static function AccumulateIt( cSum, dDate1 )
	local n
	local nIn,nOut

	do case
	case Field->date >= dDate1
		(cSum)->PTD_NET += Field->net

		for n := 1 to MAX_TYPES_CONTAINERS
         nIn  := gsInContainer( n )
         nOut := gsOutContainer( n )

			(cSum)->( gsContainer('IN', n, nIn )  )
			(cSum)->( gsContainer('OUT', n, nOut ))
		next

	case year(field->date) == year(dDate1)
		(cSum)->YTD_NET += Field->net

		for n := 1 to MAX_TYPES_CONTAINERS
         nIn  := gsInContainer( n )
         nOut := gsOutContainer( n )

			(cSum)->( gsContainer('YTD', n, nIn - nOut )  )
		next

	case year(field->date) == year(dDate1)-1
		(cSum)->LYR_NET += Field->net

		for n := 1 to MAX_TYPES_CONTAINERS
         nIn  := gsInContainer( n )
         nOut := gsOutContainer( n )

			(cSum)->( gsContainer('LYR', n, nIn - nOut )  )
		next

	endcase

return( nil )

//static function setUpRpts( nFirst2nd, aRpt, aTitle, lConfigure)
static function setUpRpts( nRpt, aRpt, aTitle, lConfigure)
	local cFile
	local cMsg
   local lDefaShowCol := .f.
   local n

	do case
   case nRpt == 1
		cFile        := RP_CONTAINER_1_YTD
		cMsg         := '1st Container Report'
	case nRpt == 2
		cFile        := RP_CONTAINER_2_YTD
		cMsg         := '2nd Container Report'
   case nRpt == 3
   	lDefaShowCol := .t.
		cFile        := RP_CONTAINER_3_HASH
		cMsg         := HASH_MESSAGE
	endcase

   aTitle[ THE_MESSAGE_ROW ] := cMsg

	aadd( aRpt,{ 'ID', {|| Field->number}, 'N', 6, 0,  lDefaShowCol, .f., ;
		 'Grower ID' })

	aadd( aRpt, ;
		{ 'Name' 	, { || NameOf(LU_GROWER,Field->NUMBER) } ,  'C' , 030 ,  000 , ;
					.t., .f. , ;
					'Grower Name (not cheque name)' } )

	aadd( aRpt, ;
		{ 'Name' , { || NameOf(LU_GROWER_CHEQUE_NAME,Field->NUMBER) };
			  ,  'C' , 030 ,  000 , ;
				.f., .f. , ;
				'Grower Cheque Name' } )

	rOutConCols( aRpt, .f.  )
	rInConCols(  aRpt, .f. )
	rRawConCols( aRpt )

	aadd( aRpt, ;
		{ 'TotVal', { || ValueAllContain() }, ;
			'N', 10,2, .f. , .t. , ;
			'Value of Containers (in this report), held by grower'})

   // New July 2020
	aadd( aRpt, ;
		{ 'In Hash', { || Field->hash_in }, ;
			'N', 10,0, lDefaShowCol , .t. , ;
			'Incoming Containers Hash Total'})

	aadd( aRpt, ;
		{ 'OutHash', { || Field->hash_Out }, ;
			'N', 10,0, lDefaShowCol , .t. , ;
			'OutGoing Containers Hash Total'})

	aadd( aRpt, ;
		{ 'TOTAL HASH', { || Field->hash_bal }, ;
			'N', 10,0, lDefaShowCol , .t. , ;
			'Balance - Main OutGoing Containers Hash Total'})

	if nRpt == 3
   	// we ONLY print the hash totals unless we go to some
      // trouble of configuring the report
   	for n := 4 to len( aRpt)-4
      	aRpt[ n, RPT_G_PRINT ] := .f.
      next
   endif

	gRptInit( cFile, aRpt)

	gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

	if lConfigure
		waitInfo({'Configuring '+cMsg, ;
                'Report File Name = ' + cFile })

		gRptSelect( aRpt )

		if yesno({'Save & Run this Format for '+ cFile + ' ?', ;
      	       '', cMsg })
			gRptSave( aRpt )
      else
      	WaitInfo({'This report will revert to its OLD format', ;
                   'File='+cFile, ;
                   cMsg })
		endif
	endif

return( nil )

