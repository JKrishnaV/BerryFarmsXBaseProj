// PROGRAM...: PRODYTD.PRG
// DATE .....: 7/01/96
// NOTES ....: THIS ROUTINE PRODUCES A YEAR-TO-DATE PRODUCTION REPORT

// May 99 - because we now have multiple products in the SAME
//          database, we change this quite a bit
// Jul 99 - revised to fix bugs etc.(not seen yet by client
//          thankfully).
// Sep 99 - note that this includes POSTED & UNPOSTED
//        - Subs for Product & Process
// Jun 2000  - Eliminates Unposted Stuff
// Nov 2001  - Revised to account for Multiple Advances
//             There are up to 3 advances, so what should happen is
//             described in NotesOnIt()
// Jun 2010 For Alaska changed a little
// Jul 2013 put in Stuff for Depot
// Oct 2013 - fix bug with UnPosted, also allow page breaks for Grower

#include 'bsgstd.ch'
#include 'printer.ch'
#include 'BerryPay.ch'
#include 'window.ch'
#include 'sysvalue.ch'
#include 'inkey.ch'
#include 'berry_rpt.ch'
#include 'rpt.ch'
#include 'valid.ch'
#include "indexord.ch"
#include "field.ch"
#include "errors.ch"
#include "miscpay.ch"
#include "account.ch"
#include "combobox.ch"

#define SPECIAL_PAY_DED_TEXT  ;
 'Special Payments & Deductions made for this year'

static nErrs := 0

function ProdYtd()
	local getList :={},aWin
	local nStatus
	local lConfigure := .f., lLegend := .t., lPayGrp
   local lGrower, lSummary, lPageBreak
	local aCombo
	local cProduct, cProcess
	local aRpt
	local dTo,dFrom
	local aTitle
	local nMember := 0
	local cByGrower
	local n
	local nGrower := 0
	local nValue
   local nChoice
   local lNotes := .t.
   local cDepot
   local lPrinted := .f.

	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

   lGrower    := .t.
   lSummary   := .t.
   lPageBreak := .f.


	cProduct := space(FLD_PRODUCT)
	cDepot   := space(FLD_DEPOT)

	dFrom   := sysValue( SYS_CURRENT_SEASON_START )
	dTo     := sysValue( SYS_CURRENT_SEASON_END )
	nStatus := 0
	lPayGrp  := .f.
	cProcess := space(FLD_PROCESS)

	myBsgScreen( 'Production Report' )

   create window at 3,5,22,65 title 'Production Report' to aWin
	display window aWin

   IN WINDOW aWin CREATE COMBOBOX AT 18,02 ;
           WINSAY 'Report Formats' USING { ;
		padr(SysValue( SYS_PRODUCTION_FORMAT_1 ),30), ;
		padr(SysValue( SYS_PRODUCTION_FORMAT_2 ),30), ;
		padr('Print both Report Formats',30) } ;
	 MESSAGE ;
	 'You can pre-define 2 different report formats for this report' ;
	  TO aCombo

	nValue := 1
	ComboBoxShow( aCombo,  nValue )

	in window aWin @20,2 winsay ;
	'This report includes both posted & unposted transactions'

	do while .t.
      nErrs := 0
      lConfigure := .f.

		in window aWin @  2,2  winsay 'From:' winget dFrom picture '@d' ;
			get_message 'Starting Date /  Use +- to adjust date easily'
		in window aWin @  2,25  winsay 'to:' winget dTo picture '@d' ;
			get_message 'End Date /  Use +- to adjust date easily'

		in window aWin @  4,02  winsay 'Price Level' winget nStatus ;
			picture '9' valid nMember <= MAX_NO_OF_PRICE_LEVELS ;
			GET_MESSAGE ;
			'0 = All,  1 = Price Level 1,   2 = Price Level 2'

		in window aWin @  5,02 winsay 'Group by Pay Grp?' ;
			winGet lPayGrp PICTURE 'Y' ;
			get_message 'Based on Grower Payment Group!'

		in window aWin @  7,02 winsay 'One Product Only   ' winget cProduct ;
			picture '@!' ;
			when PutName( aWin, 7, 28, LU_PRODUCT, cProduct ) ;
			valid PutName( aWin, 7, 28, LU_PRODUCT, cProduct ) ;
			lookup(LU_PRODUCT,'[F5] to browse, Leave blank for All')

		in window aWin @  8,02 winsay 'One Process Only   ' winget cProcess ;
			picture '@!' ;
			when PutName( aWin, 8, 28, LU_PROCESS_TYPE, cProcess ) ;
			valid PutName( aWin, 8, 28, LU_PROCESS_TYPE, cProcess ) ;
			lookup(LU_PROCESS_TYPE,'[F5] to browse, Leave blank for All')

		in window aWin @  9,02 winsay 'One Grower Only    ' winget nGrower ;
			picture NumBlankPic(FLD_GROWER) ;
			when PutName( aWin, 9, 28, LU_GROWER, nGrower ) ;
			valid PutName( aWin, 9, 28, LU_GROWER, nGrower ) ;
			lookup(LU_GROWER,'[F5] to browse, Leave blank for All')

      in window aWin @ 10,02 winsay 'Depot              ' winget cDepot picture '@!' ;
         when PutName( aWin, 10, 28, LU_DEPOT, cDepot ) ;
         valid PutName( aWin, 10,28, LU_DEPOT, cDepot ) ;
         LookUp( LU_DEPOT, 'Blank for All Depots - F5 to Browse' )

		in window aWin @ 12,02 winsay 'Show Grower Summary ' winget lGrower ;
			picture 'Y' get_message ;
			 'Shows Production Summary for each Grower'

		in window aWin @ 12,32 winsay 'Show Product Summary' winget lSummary ;
			picture 'Y' get_message  ;
			'Show Summary by Product & Process -' + ;
			 ' similar to Management Summary of Production'

      in window aWin @ 13,02 winsay 'Page Break on Grower' winget lPageBreak ;
			picture 'Y' get_message ;
          'Page Break on Growers (only applies to Grower summary-NOT PayGroup)'

      in window aWin @ 15,02 winsay 'Print Explanation    ' winget lNotes ;
         picture 'Y' get_message ;
          'Print an explanation of information available on this Report'

      in window aWin @ 16,02 winsay 'Configure Rpt Columns' winget lConfigure ;
			picture 'Y' get_message 'Select and order columns to print on report?'

		in window aWin @ 17,02 winsay 'Show Column Legend   ' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

		READ

		do case
		case lastkey()==K_ESC
			exit
		case year(dFrom) <> year(dTo)
			WaitExclam({'One year at time!'})
			loop
		case !lSummary .and. !lGrower
			waitInfo({'Hey - nothing selected to print'})
			loop
		case nStatus <> 0 .and. nGrower <> 0
			waitInfo({'You have selected a STATUS and a Grower', ;
				'Status will be IGNORED'})
			nStatus := 0
		case lastkey() <> K_PGDN
			nValue := ComboBoxDo( aCombo,  nValue )
			if lastkey()==K_ESC .or. nValue == 0
				nValue := 1
				loop
			endif
		endcase

      nChoice := thinChoice({'Run Report','Display Info','X-eXit'})

      do case
      case nChoice==2
         NotesOnIt( .t. )
      case nChoice==0 .or. nChoice==3
         exit
      endcase

		if !SelectPrn('PRODYTD.TXT')
			loop
		endif

		do case
		case nGrower > 0
         aTitle := { TheClientName( ), ;
          '', alltrim(lStrim(nGrower)+' '+NameOf(LU_GROWER,nGrower))}
		case nStatus == 0
         aTitle := { TheClientName( ), ;
            '','All Growers'}
		otherwise
         aTitle := { TheClientName( ), ;
             '','Status = '+str(nStatus,1)}
		endcase

		aadd(aTitle, 'From '+shMDY(dFrom)+' - '+shMDY(dTo))

		if !empty( cDepot )
			n := len( aTitle)
			aTitle[n] += ' Depot='+cDepot
		endif

		if !empty(cProduct)
			aadd( aTitle , "Berry Type="+cProduct)
		endif
		if !empty(cProcess)
			aadd( aTitle , "Process Type="+cProcess)
		endif

		cByGrower := PrepByGrow( nStatus, dFrom,dTo, cProduct, cProcess,nGrower, cDepot )

		if empty( cByGrower )
			waitHand({'Reindex files - be sure to ERASE', ;
				'the Temporary files'})
			loop
		endif

      if nValue == 1 .or. nValue == 3
			aRpt := {}
			theSumCol( aRpt )
			gRptInit( RP_PRODUCTION_GROWER_YTD1, aRpt)
			if lConfigure
				waitInfo({'You are Configuring Report Format #1', ;
					 SysValue( SYS_PRODUCTION_FORMAT_1 )} )
				gRptSelect( aRpt )
				if yesno({'Save this Production Report Format #1?'})
					gRptSave( aRpt )
				endif
			endif
      endif
      if nValue == 2 .or. nValue == 3
			aRpt := {}
			theSumCol( aRpt )
			gRptInit( RP_PRODUCTION_GROWER_YTD2, aRpt)
			if lConfigure
				waitInfo({'You are Configuring Report Format #2', ;
					 SysValue( SYS_PRODUCTION_FORMAT_2 )} )
				gRptSelect( aRpt )
				if yesno({'Save this Production Report Format #2?'})
					gRptSave( aRpt )
				endif
			endif
      endif

		PRINT_ON  RPT_OVERWRITE

      lPrinted := .f.

		if nValue == 1 .or. nValue == 3
			aRpt := {}
			theSumCol( aRpt )
			gRptInit( RP_PRODUCTION_GROWER_YTD1, aRpt)

         aTitle[2] := allTrim(sysValue( SYS_PRODUCTION_FORMAT_1 ))

			if lGrower

            SetRptUp( cByGrower, aTitle ,lPayGrp, lPageBreak )

				(cByGrower)->(dbGoTop())

            // PRINT_ON   RPT_ADD_TO_FILE

				gRptPrintSize( aRpt )

				(cByGrower)->(gRptPrinter( aRpt ))

				if lLegend
					prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
				endif

            lPrinted := .t.
			endif

			if lSummary
				// pretty Tricky - we use the same columns !
            if lPrinted
            	nuFormFeed()
            endif

            aTitle[2] := 'Summary '+alltrim(sysValue( SYS_PRODUCTION_FORMAT_1 ))
				DoTheSumm( aRpt, cByGrower, aTitle ,lPayGrp )
				if lLegend
					prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
				endif
            lPrinted := .t.
			endif
		endif

		if nValue == 2 .or. nValue == 3
			aRpt := {}
			theSumCol( aRpt )
			gRptInit( RP_PRODUCTION_GROWER_YTD2, aRpt)

         aTitle[2] := allTrim(sysValue( SYS_PRODUCTION_FORMAT_2 ))

			if lGrower
            SetRptUp( cByGrower, aTitle ,lPayGrp, lPageBreak )

				(cByGrower)->(dbGoTop())

            if lPrinted
            	nuFormFeed()
            endif

				gRptPrintSize( aRpt )

				(cByGrower)->(gRptPrinter( aRpt ))

				if lLegend
					prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
				endif

            lPrinted := .t.

			endif

			if lSummary
				// pretty Tricky - we use the same columns !
            aTitle[2] := 'Summary '+alltrim(sysValue( SYS_PRODUCTION_FORMAT_2 ))

            if lPrinted
            	nuFormFeed()
            endif

				DoTheSumm( aRpt, cByGrower, aTitle ,lPayGrp )
				if lLegend
					prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
				endif
            lPrinted := .t.
			endif
		endif

      nuQprnOut(  ' ')
      if lNotes
         PrinterCtrl( PRN_CTRL_12_CPI )
         // if pRow() > 40
         if NearPageBottom( 25 )
            NuFormFeed()

            nuQprnOut( shMDY(date()) )
            nuQprnOut( time()   )
            nuQprnOut( space(20)+padc('Production Report Notes',40) )
            for n := 2 to len( aTitle)
               nuQprnOut( space(20)+padc(aTitle[n],40) )
            next
         endif
         nuQprnOut( ' ' )
         nuQprnOut( ' ' )
         NotesOnIt( .f. )
      endif

      PRINT_OFF  RPT_COMPLETE_EJECT

		KillUnique( cByGrower, '.CDX')
		KillUnique( cByGrower, '.DBF')
	enddo

	kill window aWin
	close databases
return( nil )

static function SumByProd( cFile, lPayGrp )
	field product, process, payGrp
	field  TOT_LY,  UNP_LY
	field  PGRADE1, PGRADE2, PGRADE3, PGRADE00
	field  UGRADE1, UGRADE2, UGRADE3, UGRADE00
	field  PAD_AMT, PPS_AMT, UAD_AMT
   field  PPR_AMT,          UPR_AMT
   field  PFI_AMT,          UFI_AMT

	local cReturn
	local cTemp
	local c

	// this takes the Product of prepByGrow()
	// it summarizes the File by Product + Process

	msgLine( 'Building Summary...')
	cReturn  := UniqueFile( )
	cTemp    := UniqueFile( )

	if !empty(cReturn)
		(cFile)->(dbGoTop())

		dbSelectArea( cFile )

      //      2BFIXED - June 2010 - is FIXED
      if lPayGrp
      	c := cFile + '->payGrp+ '+cFile+ '->Product + ' + ;
      	     cFile + '->process'
			(cFile)->( OrdCreate( cTemp, 'USETHIS', c, ;
			      	  { || (cFile)->payGrp+ (cFile)->Product + (cFile)->process } ))

			total on (cFile)->payGrp + (cFile)->product + (cFile)->process  ;
			  fields  TOT_LY,UNP_LY, ;
				 PGRADE1, PGRADE2, PGRADE3, PGRADE00, ;
				 UGRADE1, UGRADE2, UGRADE3, UGRADE00, ;
				 PAD_AMT, PSP_AMT, UAD_AMT, ;
				 PFI_AMT, UFI_AMT, PPR_AMT, UPR_AMT to (cReturn)

     	else
     		c := cFile+ '->Product + ' + ;
      	     cFile + '->process'
			(cFile)->( OrdCreate( cTemp, 'USETHIS', c, ;
			      	  { || (cFile)->Product + (cFile)->process } ))

			total on (cFile)->product + (cFile)->process  ;
			  fields  TOT_LY,UNP_LY, ;
				 PGRADE1, PGRADE2, PGRADE3, PGRADE00, ;
				 UGRADE1, UGRADE2, UGRADE3, UGRADE00, ;
				 PAD_AMT, PSP_AMT, UAD_AMT, ;
				 PFI_AMT, UFI_AMT, PPR_AMT, UPR_AMT to (cReturn)

     	endif


      /* -----------------  TO BE FIXED - 2BFIXED - June 2010 - is Fixed
      if lPayGrp
			index on (cFile)->payGrp+ (cFile)->Product + (cFile)->process to (cTemp)

			total on (cFile)->payGrp + (cFile)->product + (cFile)->process  ;
			  fields  TOT_LY,UNP_LY, ;
				 PGRADE1, PGRADE2, PGRADE3, PGRADE00, ;
				 UGRADE1, UGRADE2, UGRADE3, UGRADE00, ;
				 PAD_AMT, PSP_AMT, UAD_AMT, ;
				 PFI_AMT, UFI_AMT, PPR_AMT, UPR_AMT to (cReturn)

		else
			index on (cFile)->Product + (cFile)->process to (cTemp)

			total on (cFile)->product + (cFile)->process  ;
			  fields  TOT_LY,UNP_LY, ;
				 PGRADE1, PGRADE2, PGRADE3, PGRADE00, ;
				 UGRADE1, UGRADE2, UGRADE3, UGRADE00, ;
				 PAD_AMT, PSP_AMT, UAD_AMT, ;
				 PFI_AMT, UFI_AMT, PPR_AMT, UPR_AMT to (cReturn)
		endif
      ----------------------------- */
      (cFile)->(dbClearInd())

		use (cReturn) exclusive new
	endif

	killUnique( cTemp, '.CDX' )

return( cReturn )


static function PrepByGrow( nStatus, dFrom, dTo, cProduct, cProcess, nGrower, cDepot )
	field number, process, product
	local nLastYear
	local aStru
	local cReturn
	local nCount := 0
	local cDaily
	local aPaid
	local aErr := {}
   local nPrice, nFinPrice, n
   local nExtPr, nDiskPrice
   local bFor1,bFor2

   if valType(nStatus)<>'N' .or. valType(dFrom)<>'D' .or. valType(dTo)<>'D' .or. ;
      valType(cProduct)<>'C' .or. valType(cProcess)<>'C'
      waitInfo({'Problem with Parameters in PrepByGrow( )'})
   endif


	aStru   :=   {}
	aadd( aStru, { 'NUMBER', 'N', FLD_GROWER, 0 } )

	aadd( aStru, { 'PAYGRP',   'C', FLD_PAYGRP,  0  } )  // drawn from Grower
	aadd( aStru, { 'STATUS',  'N', FLD_STATUS, 0  } )  //  from Grower

	aadd( aStru, { 'PROCESS', 'C', FLD_PROCESS, 0 } )
	aadd( aStru, { 'PRODUCT', 'C', FLD_PRODUCT, 0 } )

	aadd( aStru, { 'TOT_LY', 'N', 11, 0 } )
	aadd( aStru, { 'UNP_LY', 'N', 11, 0 } )

	aadd( aStru, { 'PGRADE1',  'N', 11, 0 })
	aadd( aStru, { 'PGRADE2',  'N', 11, 0 })
	aadd( aStru, { 'PGRADE3',  'N', 11, 0 })
	aadd( aStru, { 'PGRADE00', 'N', 11, 0 })

	aadd( aStru, { 'PAD_AMT', 'N', 13, 2 })   // Posted (this year advance)
   aadd( aStru, { 'PSP_AMT', 'N', 13, 2 })   // Posted Special Payments & Deds
	aadd( aStru, { 'PPR_AMT', 'N', 13, 2 })   // Posted Time Premiums
	aadd( aStru, { 'PFI_AMT', 'N', 13, 2 })   // Posted Final Payments
	// so Total Final = PAD_AMT + PFI_AMT
   //    Total Paid  = PAD_AMT + PSP_AMT + PPR_AMT

	aadd( aStru, { 'UAD_AMT', 'N', 13, 2 })   // Unposted Estimated Advances
	aadd( aStru, { 'UFI_AMT', 'N', 13, 2 })   // Unposted Estimated Final
	aadd( aStru, { 'UPR_AMT', 'N', 13, 2 })   // Unposted Premium
	// so Total Final = UAD_AMT + UFI_AMT

	aadd( aStru, { 'UGRADE1',  'N', 11, 0 })
	aadd( aStru, { 'UGRADE2',  'N', 11, 0 })
	aadd( aStru, { 'UGRADE3',  'N', 11, 0 })
	aadd( aStru, { 'UGRADE00', 'N', 11, 0 })

	cReturn := UniqueDBF( aStru )
	cDaily  := UniqueFile( )

	if empty(cReturn) .or. empty(cDaily)
		return( cReturn )
	endif

	dbSelectAR( cReturn )
	index on str(number,FLD_GROWER) + product + process to (cReturn )

   Daily->(OrdSetFocus( 0 ))
   if empty( cDepot )
   	Daily->(dbClearFilter())
   else
		Daily->(dbSetFilter( { || Daily->depot == cDepot } , 'Daily->depot == cDepot' ))
   endif
	Daily->(dbGoTop())

	nLastYear := year(dFrom)-1

	// Build Indexes on Daily
	msgLine('Indexing Posted hang on...')

	// 2BFIXED - June 2010 - is fixed - is Fixed
	//	index on str( Daily->number, FLD_GROWER) + ;
	//			Daily->product + Daily->process to (cDaily) ;
	//			for (year(Daily->date) == nLastYear .or. ;
	//				 (Daily->date >= dFrom .and. Daily->date <= dTo)) ;
	//				 .and. IncludeMe(cProduct,cProcess,nGrower)


	dbSelectAr('Daily' )
	bFor1 := { || (year(Daily->date) == nLastYear .or. ;
					 (Daily->date >= dFrom .and. Daily->date <= dTo))  }

	bFor2 := { || IncludeMe(cProduct,cProcess,nGrower,cDepot ) }

	InitGeneralFor( bFor1, bFor2, { || .t. }, { || .t. }  )

   Daily->( OrdCondSet( 'GeneralFor()', ;
			        { || GeneralFor() }, ;
                    .f., ;
                  { || !Daily->(Eof()) } ) )

   Daily->( OrdCreate( cDaily, 'USETHIS',   ;
             'str( Daily->number,      4    )+ Daily->product + Daily->process', ;
         { || str( Daily->number, FLD_NUMBER)+ Daily->product + Daily->process } ) )

	if empty( Daily->(OrdBagName('USETHIS')) )
   	AppError(APP_ERR_TEMP_INDEXING7, {'Hmm-we have a problem!'})
   endif

   Daily->( OrdSetFocus('USETHIS') )

	Daily->(dbGoTop())

	msgLine('Ready to report...')

	/*
		index on str( Daily->number, FLD_GROWER) + ;
				Daily->product + Daily->process to (cDaily) ;
				for (year(Daily->date) == nLastYear .or. ;
					 (Daily->date >= dFrom .and. Daily->date <= dTo)) ;
					 .and. IncludeMe(cProduct,cProcess,nGrower)
	*/

	goto top

	dbSelectAr( cReturn )

	msgLine('Building Summary from Daily File....')
	do while  !Daily->(eof())
		ShowProg(nCount++)
		// look in Daily (Posted)

		do case
		case !AlignGrower( cReturn, nStatus )
			aadd(aErr,  'Grower: '+lstrim(Daily->number)+ ', Recpt: '+ ;
				lStrim(Daily->recpt)+',  Grower is Not on File' )


      // case Num2Equal0( Daily->post_bat1 )
      // Fixed Oct 2013
      case Num2Equal0( Daily->post_bat1 ) .and. ;
           Num2Equal0( Daily->post_bat2 ) .and. ;
           Num2Equal0( Daily->post_bat3 ) .and. ;
           Num2Equal0( Daily->fin_bat )

         // has not been Posted
			do case
			case year(Daily->date)==nLastYear
				(cReturn)->unp_ly += Daily->net
				if len(aErr) < 100
					aadd(aErr,  str(Daily->number,10)+ ;
						' last Years Transaction not Posted' )
				endif

				if FindPrice( Daily->Product, Daily->Process, Daily->date )

               nPrice := Daily->(TotAdvPrice( ))
					(cReturn)->UAD_AMT += nPrice*Daily->net

					nPrice := Daily->(FinalPrice()) - nPrice
					if nPrice > 0.00
						(cReturn)->UFI_AMT += nPrice*Daily->net
					endif

					nPrice := Daily->(AdvancePrem( ))
					(cReturn)->UPR_AMT += nPrice*Daily->net
				else
					if len(aErr) < 100
						aadd(aErr, 'Grower '+lstrim(Daily->number,10)+ ;
							' UnPosted Last Yr receipt-No Price!' )
					endif
				endif

			case Daily->date >= dFrom .and. Daily->date <= dTo
				do case
				case Daily->grade==1
					(cReturn)->ugrade1  += Daily->net
				case Daily->grade==2
					(cReturn)->ugrade2  += Daily->net
				case Daily->grade==3
					(cReturn)->ugrade3  += Daily->net
				otherwise
					(cReturn)->ugrade00 += Daily->net
					if len(aErr) < 100
						aadd(aErr, ;
							'Grower (unpost):'+  ;
								str(Daily->number,10)+' weight no Grade!' )
					endif
				endcase

				if FindPrice( Daily->Product, Daily->Process, Daily->date )
               nPrice := Daily->(TotAdvPrice( ))
					(cReturn)->UAD_AMT += nPrice*Daily->net

					nPrice := Daily->(FinalPrice()) - nPrice
					if nPrice > 0.00
						(cReturn)->UFI_AMT += nPrice*Daily->net
					endif

					nPrice := Daily->(AdvancePrem( ))
					(cReturn)->UPR_AMT += nPrice*Daily->net
				else
					if len(aErr) < 100
                  aadd(aErr, 'Grower#'+str(Daily->number,8)+ ;
                     ' UnPosted receipt-No Price!  Recpt#'+ ;
                      str(Daily->recpt,10)+ ' '+ShMdy( Daily->date ) )
					endif
				endif

			otherwise
				appError( APP_ERR_REPORT_CALC3, ;
					{ 'Oh no - if this keeps coming up', ;
					   'Press ALT-C to break'})
			endcase

		otherwise
			// Posted
			do case
			case year(Daily->date)==nLastYear
				(cReturn)->tot_ly += Daily->net

			case Daily->date >= dFrom .and. Daily->date <= dTo
            nFinPrice := 0.00    // Actual or estimated amount of
                                 // final payment.  That is the
                                 // Final Price - any advances...
				do case
				case Daily->grade==1
					(cReturn)->pgrade1  += Daily->net
				case Daily->grade==2
					(cReturn)->pgrade2  += Daily->net
				case Daily->grade==3
					(cReturn)->pgrade3  += Daily->net
				otherwise
					(cReturn)->pgrade00 += Daily->net
					if len(aErr) < 100
						aadd(aErr, 'Grower (Post):' + ;
								str(Daily->number,10)+' weight no Grade!' )
					endif
				endcase

            nPrice := Daily->adv_pr1 + Daily->adv_pr2 + Daily->adv_pr3

            (cReturn)->PAD_AMT += round( nPrice * Daily->net,2)

            do case
            case Daily->fin_pr_id <> 0
               //case abs(Daily->fin_price) > abs( nPrice )
               // allows now (Nov 5, 2001) for Negative prices
               //    this has been Paid Out...

               nFinPrice := Daily->fin_price - nPrice
               (cReturn)->PFI_AMT += round( ;
                ( nFinPrice )*Daily->net,2)
            case FindPrice( Daily->Product, Daily->Process, Daily->date )
               nFinPrice := Daily->(FinalPrice( )) - nPrice
               if nFinPrice > 0.00
                  (cReturn)->UFI_AMT += round( nFinPrice*Daily->net,2)
               endif
            endcase

            // (cReturn)->UPR_AMT += round(Daily->prem_price*Daily->net,2)
            // Corrected July 18 - 2000 not noticed by So. Alder

            (cReturn)->PPR_AMT += round(Daily->prem_price*Daily->net,2)

				// we want ALL payments made...
            aPaid := PostPaidArray( date()+5 )      // dTo
            nExtPr  := 0.00

				for n := 1 to len(aPaid)
               if aPaid[ n, PAS_ACC_TYPE ] == TT_BERRY_ADVANCE_1 .or. ;
                  aPaid[ n, PAS_ACC_TYPE ] == TT_BERRY_ADVANCE_2 .or. ;
                  aPaid[ n, PAS_ACC_TYPE ] == TT_BERRY_ADVANCE_3 .or. ;
                  aPaid[ n, PAS_ACC_TYPE ] == TT_TIME_PREMIUM .or. ;
                  aPaid[ n, PAS_ACC_TYPE ] == TT_FINAL_BERRY

                  nExtPr += aPaid[n, PAS_ACC_UNIT_PRICE ]*Daily->net
					else
						(cReturn)->psp_amt += ;
							(aPaid[n, PAS_ACC_UNIT_PRICE ]*Daily->net)
					endif
				next

            // if Daily->fin_price > 0.00
            if Daily->fin_pr_id <> 0
               nDiskPrice := round( Daily->fin_price * Daily->net,2) + ;
                 round(Daily->prem_price*Daily->net,2)
            else
               nDiskPrice := round( ;
                 (Daily->adv_pr1 + Daily->adv_pr2 + ;
                   Daily->adv_pr3) * Daily->net,2) + ;
                 round(Daily->prem_price*Daily->net,2)
            endif

            if str(nExtPr,12,2) <> str(nDiskPrice,12,2) .and. nErrs < 20
               nErrs++
               appError( APP_ERR_NOT_BALANCING, { ;
                'Daily Receipt is Not Balancing', ;
                'Receipt:   '+lStrim(Daily->recpt) + Daily->recptltr, ;
                'Unique ID: '+lStrim(Daily->day_uniq), ;
                'Grower:    '+lStrim(Daily->number), ;
                'nExtPr Price='+str(nExtPr,12,2), ;
                'Disk Price='+str(nDiskPrice,12,2), ;
                'Advances:  '+str(Daily->adv_pr1,12,2)+ ;
                              str(Daily->adv_pr2,12,2)+ ;
                              str(Daily->adv_pr3,12,2), ;
                'Final:     '+str(Daily->fin_price,12,2)+ ;
                   ' ID: '+str(Daily->fin_pr_id,12), ;
                'Possible Forward Dated Transaction Error!'})
				endif
			otherwise
				appError( APP_ERR_REPORT_CALC4, { ;
					'Oh no - if this keeps coming up', ;
					'Press ALT-C to break'})
			endcase

		endcase

		Daily->(dbSkip())
	ENDDO

	if len(aErr) > 0
		waitInfo({'Some potential errors found', ;
		  'Errors found = '+str(len(aErr),5) })

		if len(aErr) > 9
			aSize( aErr, 8 )
			aadd( aErr, '' )
			aadd( aErr,'Please write these errors down!' )
		else
			aadd( aErr, '')
			aadd( aErr, 'Please write these errors down!')
		endif
		WaitInfo( aErr )
	endif

	Daily->(dbCloseArea())

	KillUnique(cDaily,'.CDX')

	openfile({'DAILY'}, DB_SHARED )

RETURN( cReturn )

static function AlignGrower( cTempFile, nStatus )
	local nGrower
	local cProduct
	local cProcess
	local lFound
	local lReturn

	if valType(nStatus)<>'N'
		appError( APP_ERR_REPORT_CALC2, { ;
		  'Oh no - if this keeps coming up', ;
		  'Press ALT-C to break'})
	endif

	nGrower  := Daily->number
	cProduct := Daily->product
	cProcess := Daily->process

	ValidTest( V_GROWER, nGrower, VT_NO_MESSAGE)

	lReturn := .t.

	if nStatus <> 0
		if nStatus  <> Grower->status
			lReturn := .f.
		endif
	endif

	if lReturn

		if	nGrower  == (cTempFile)->number  .and. ;
		   cProduct == (cTempFile)->product .and. ;
			cProcess == (cTempFile)->process .and. !(cTempFile)->(eof())
			lFound := .t.
		else
			lFound :=  (cTempFile)->(dbSeek( ;
			  str(nGrower,FLD_GROWER)+cProduct +cProcess, HARDSEEK ))

		endif

		if !lFound
			(cTempFile)->(dbAppend())
			(cTempFile)->number   := nGrower
			(cTempFile)->product  := cProduct
			(cTempFile)->process  := cProcess

			(cTempFile)->payGrp   := Grower->payGrp    // will be blank if
			(cTempFile)->status   := Grower->status   // the grower is not on file

		endif
	endif

return( lReturn )

static function theSumCol( aRpt )

	aadd( aRpt,{ ' ',{|| ' '}, 'C', 3, 0, .t., .f., 'Nice Space'} )

	aadd( aRpt, { 'Pr', {|| Field->process }, ;
		'C',  2, 0 , .t., .f., ;
		'Process'})

	aadd( aRpt, { 'ProcessName', ;
		 {|| NameOf(LU_PROCESS_TYPE, Field->process) }, ;
		'C',  15, 0 , .t., .f., 'Process Name'} )

	// Posted
	aadd( aRpt, { {'Posted','Grade 1'}, {|| Field->pgrade1 }, ;
		'N',  9, 0 , .f., .t., ;
		'Grade 1 - Posted Receipts in LBS'})
	aadd( aRpt, { {'Posted','Grade 2'}, {|| Field->pgrade2 }, ;
		'N',  9, 0 , .f., .t., ;
		'Grade 2 - Posted Receipts in LBS'})
	aadd( aRpt, { {'Posted','Grade 3'}, {|| Field->pgrade3 }, ;
		'N',  9, 0 , .f., .t., ;
		'Grade 3 - Posted Receipts in LBS'})
	aadd( aRpt, { {'Posted','Non-Grade'}, {|| Field->ugrade00 }, ;
		'N',  9, 0 , .f., .t., ;
		'Unknown Grade - Posted Receipts in LBS'})

	aadd( aRpt, { {'All','Posted'}, ;
	 {|| Field->pgrade1 + Field->pgrade2 + Field->pgrade3 }, ;
		',',  9, 0 , .t., .t., ;
		'Posted Receipts - Grades 1,2,3 in LBS'})

	// UnPosted
	aadd( aRpt, { {'UnPosted','Grade 1'}, {|| Field->ugrade1 }, ;
		'N',  9, 0 , .f., .t., ;
		'Grade 1 - UnPosted Receipts in LBS'})
	aadd( aRpt, { {'UnPosted','Grade 2'}, {|| Field->ugrade2 }, ;
		'N',  9, 0 , .f., .t., ;
		'Grade 2 - UnPosted Receipts in LBS'})
	aadd( aRpt, { {'UnPosted','Grade 3'}, {|| Field->ugrade3 }, ;
		'N',  9, 0 , .f., .t., ;
		'Grade 3 - UnPosted Receipts in LBS'})

	aadd( aRpt, { {'UnPosted','Non-Grade'}, {|| Field->ugrade00 }, ;
		'N',  9, 0 , .f., .t., ;
		'Unknown Grade - UnPosted Receipts in LBS'})

	aadd( aRpt, { {'All','UnPosted'}, ;
	 {|| Field->ugrade1 + Field->ugrade2 + Field->ugrade3 }, ;
		',',  9, 0 , .t., .t., ;
		'Posted Receipts - Grades 1,2,3 in LBS'})

	// Posted + Unposted
	aadd( aRpt, { {'Total','Grade 1'}, {|| Field->ugrade1 + Field->pgrade1 }, ;
		'N',  9, 0 , .f., .t., ;
		'Grade 1 - UnPosted + Posted Receipts in LBS'})

	aadd( aRpt, { {'Total','Grade 2'}, {|| Field->ugrade2 + Field->pgrade2 }, ;
		'N',  9, 0 , .f., .t., ;
		'Grade 2 - UnPosted + Posted Receipts in LBS'})

	aadd( aRpt, { {'Total','Grade 3'}, {|| Field->ugrade3 + Field->pgrade3 }, ;
		'N',  9, 0 , .f., .t., ;
		'Grade 3 - UnPosted + Posted Receipts in LBS'})

	aadd( aRpt, { {'Total','Receipt'}, ;
	 {|| Field->ugrade1 + Field->ugrade2 + Field->ugrade3 + ;
	     Field->pgrade1 + Field->pgrade2 + Field->pgrade3 }, ;
		',', 11, 0 , .t., .t., ;
		'All Posted & Unposted Receipts - Grades 1,2,3 in LBS'})

	aadd( aRpt, { 'Tot LY',{|| Field->TOT_LY }, 'N', 10, 0 , .f., .t., ;
		'Total Posted Production for Last Year'})

	aadd( aRpt, { 'Unp LY',{|| Field->UNP_LY }, 'N', 10, 0 , .f., .t., ;
		'Last Years UnPosted Production - Likely indicates an error'})

	//  Paid Amounts
	aadd( aRpt, { 'Paid Adv',{|| Field->PAD_AMT }, 'N', 12, 2 , .f., .t., ;
      'Paid advances for this year, includes 2nd & 3rd Advances'})
	aadd( aRpt, { 'Paid Pre',{|| Field->PPR_AMT }, 'N', 12, 2 , .f., .t., ;
		'Paid Time Premiums for this year'})
	aadd( aRpt, { 'Paid Sp',{|| Field->PSP_AMT }, 'N', 12, 2 , .f., .t., ;
      SPECIAL_PAY_DED_TEXT })
	aadd( aRpt, { 'Paid Fin',{|| Field->PFI_AMT }, 'N', 12, 2 , .f., .t., ;
		'Actual Final Payments for this year'})

   aadd( aRpt, { 'Adv Run', ;
      {|| Field->PPR_AMT + Field->PAD_AMT }, ;
	 'N', 12, 2 , .t., .t., ;
   'All actual advances & time premiums on this years product'})

   aadd( aRpt, { 'Paid YTD', ;
		{|| Field->PSP_AMT + Field->PAD_AMT + Field->PFI_AMT + FIELD->PPR_AMT}, ;
	 'N', 12, 2 , .t., .t., ;
   'All actual payments for this years product (including Specials & Deds)'})

   aadd( aRpt, { 'Paid Reg',{|| Field->PAD_AMT + Field->PFI_AMT }, 'N', 12, 2 , .f., .t., ;
    'Paid advances + final payments for this year (excludes premiums & special)'})

   aadd( aRpt, { 'Pd AFP', ;
    {|| Field->PAD_AMT + Field->PPR_AMT + Field->PFI_AMT }, ;
     'N', 12, 2 , .f., .t., ;
    'Paid advances + final payments + premium for this year (excludes special)'})

	// Unpaid Amounts
   aadd( aRpt, { 'Est Adv',{|| Field->UAD_AMT }, 'N', 12, 2 , .t., .t., ;
		'Estimated unpaid Advances remaining'})
	aadd( aRpt, { 'Est Fin',{|| Field->UFI_AMT }, 'N', 12, 2 , .f., .t., ;
		'Estimated unpaid Unposted Final Payments for this year'})
	aadd( aRpt, { 'Est Prem',{|| Field->UPR_AMT }, 'N', 12, 2 , .f., .t., ;
		'Estimated unpaid Premiums for this year'})

   aadd( aRpt, { 'EstARun', ;
      {|| Field->UPR_AMT + Field->UAD_AMT }, ;
	 'N', 12, 2 , .t., .t., ;
   'All unpaid (estimated) advances & time premiums on this years product'})

   aadd( aRpt, { 'Est YTD', ;
      {||  Field->UAD_AMT + Field->UFI_AMT + FIELD->UPR_AMT}, ;
	 'N', 12, 2 , .t., .t., ;
   'All unpaid (estimated) advances, final & premiums for this years product'})

   aadd( aRpt, { 'Est Reg',{|| Field->UAD_AMT + Field->UFI_AMT }, 'N', 12, 2 , .f., .t., ;
    'UnPaid (est) advances+final for this year (excludes premiums & special'})

	// Total Amounts
	aadd( aRpt, { 'Tot Adv',{|| Field->UAD_AMT+ Field->PAD_AMT }, ;
		 'N', 12, 2 , .f., .t., ;
		'Total Paid & estimated advances for this year'})

	aadd( aRpt, { 'Tot Pre',{|| Field->PPR_AMT + Field->UPR_AMT }, ;
		 'N', 12, 2 , .f., .t., ;
		'Total Paid & estimated Time Premiums for this year'})

	aadd( aRpt, { 'Tot Fin',{|| Field->UFI_AMT + Field->PFI_AMT }, ;
		'N', 12, 2 , .f., .t., ;
		'Total Paid & Estimated Final Payments for this year'})

	aadd( aRpt, { 'Total YTD', ;
	  {|| Field->PAD_AMT + Field->PFI_AMT + FIELD->PPR_AMT + Field->PSP_AMT + ;
	      Field->UAD_AMT + Field->UFI_AMT + FIELD->UPR_AMT}, ;
	 'N', 12, 2 , .t., .t., ;
    'Total actual & estimated payments for this years product (inc Special)'})

	aadd( aRpt, { 'Tot Reg', ;
		{|| Field->PAD_AMT + Field->PFI_AMT + ;
		    Field->UAD_AMT + Field->UFI_AMT }, ;
		 'N', 12, 2 , .f., .t., ;
    'Total Advances + final payments for this year (excl premiums & special'})

   aadd( aRpt, { 'Tot AFP', ;
      {|| Field->PAD_AMT + Field->PFI_AMT + Field->PPR_AMT + ;
          Field->UAD_AMT + Field->UFI_AMT + Field->UPR_AMT }, ;
		 'N', 12, 2 , .f., .t., ;
    'Total Advances, Premiums, Final payments for this year (excl special'})


return( aRpt )


static Function SetRptUp( cByGrower, aTitle ,lPayGrp, lPageBreak )

	gRptInitHead()

	gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

	if lPayGrp
		dbSelectAR( cByGrower )
      (cByGrower)->(OrdListClear())
		dbGoTop()
		index on Field->payGrp + str( Field->number, FLD_GROWER) ;
						 to (cByGrower)
		dbGoTop()

		gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {||(cByGrower)->payGrp} )
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
			{ || nuQprnOut('PayGrp: '+(cByGrower)->payGrp + ' ' + ;
		        NameOf( LU_PAYGRP, (cByGrower)->payGrp)	)  } )


		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL , .t.)

		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_ON, {||(cByGrower)->number} )
		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_TITLE, ;
			{ || nuQprnOut( ' '+;
			lStrim((cByGrower)->number) + ' '+ ;
			NameOf( LU_GROWER_NAME, (cByGrower)->number) ) } )

		gRptGetSetHead( RPT_HEAD_3SUBTOTAL , .t.)

		gRptGetSetHead( RPT_HEAD_3SUBTOTAL_ON, {||(cByGrower)->product} )
		gRptGetSetHead( RPT_HEAD_3SUBTOTAL_TITLE, ;
				{ || nuQprnOut( '  '+ ;
					(cByGrower)->product + ' '+ ;
					NameOf( LU_PRODUCT, (cByGrower)->product) ) } )

	else
		gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL , .f.)

      if lPageBreak
         gRptGetSetHead( RPT_HEAD_EJECT_ON_SUBTOTAL , .t.)
      endif

		gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {||(cByGrower)->number} )
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
		{ || nuQprnOut( ;
			lStrim((cByGrower)->number) + ' '+ ;
			NameOf( LU_GROWER_NAME, (cByGrower)->number) ) } )

		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL , .t.)

		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_ON, {||(cByGrower)->product} )
		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_TITLE, ;
			{ || nuQprnOut( ' '+ ;
				(cByGrower)->product + ' '+ ;
				NameOf( LU_PRODUCT, (cByGrower)->product) ) } )

		gRptGetSetHead( RPT_HEAD_3SUBTOTAL , .f.)
	endif
return( nil )


static Function DoTheSumm( aRpt, cByGrower, aTitle ,lPayGrp )
	// Tricky uses the Same Columns as the Other Report!
	local cSummary

	cSummary := SumByProd( cByGrower, lPayGrp )

	gRptInitHead()

	gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

	if lPayGrp

		/*
          noted in May 2010 - is this relevant ??
          2BFIXED

			dbSelectAR( cSummary )
			set index to
			dbGoTop()
			index on Field->payGrp + str( Field->number, FLD_GROWER) ;
						 to (cByGrower)
		dbGoTop()
		*/

		(cSummary)->( OrdListClear() )
		dbSelectAR( cSummary )
		index on Field->payGrp + str( Field->number, FLD_GROWER) ;
						 to (cByGrower)

		gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {||(cSummary)->payGrp} )
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
		  { || nuQprnOut('PayGrp: '+(cSummary)->payGrp+' '+;
		    NameOf(LU_PAYGRP, (cSummary)->payGrp)  ) } )

		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL , .t.)
		gRptGetSetHead( RPT_HEAD_3SUBTOTAL , .f.)

		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_ON, {||(cSummary)->product} )
		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_TITLE, ;
				{ || nuQprnOut( '  '+ ;
				(cSummary)->product + ' '+ ;
				NameOf( LU_PRODUCT, (cSummary)->product) ) } )

	else
		gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL , .f.)
		gRptGetSetHead( RPT_HEAD_3SUBTOTAL , .f.)

		gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {||(cSummary)->product} )
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
			{ || nuQprnOut( ;
			(cSummary)->product + ' '+ ;
			NameOf( LU_PRODUCT, (cSummary)->product) ) } )
	endif

	(cSummary)->(dbGoTop())

	gRptPrintSize( aRpt )

	(cSummary)->(gRptPrinter( aRpt ))

	(cSummary)->(dbCloseArea())
	KillUnique( cSummary, '.DBF')

return( nil )

static function NotesOnIt( lScreen )
   local aRay
   local n
   aRay := {}

   aadd( aRay,'This report summarizes receipts and their payment status')
   aadd( aRay,'A receipt has essentially 3 states it can be in:')
   aadd( aRay,' 1. Unposted - no payments have been posted against the')
   aadd( aRay,'      receipt at all.  The receipt can be edited or voided')
   aadd( aRay,' 2. Advances Paid, Final not paid - one or more advances has')
   aadd( aRay,'      been posted against the receipt.  The receipt may NOT')
   aadd( aRay,'      be edited.  A final payment has not been made & the')
   aadd( aRay,'      final amount may not even be known.  The final payment')
   aadd( aRay,'      amount is still an UNPOSTED estimate.  Any time based')
   aadd( aRay,'      premiums have been made.')
   aadd( aRay,' 3. Final Payment Made - all advances have been made & the')
   aadd( aRay,'      final payment has been made.')
   aadd( aRay,'Special payments can be made against any posted transaction')
   aadd( aRay,'before or after the Final Payment is made.')

   aadd( aRay, '')
   aadd( aRay, 'The report does not include financial adjustments.')
   aadd( aRay, 'It does include deductions & special payments that relate')
   aadd( aRay, 'directly to receipts.  These are show in the column:')
   aadd( aRay, ' '+SPECIAL_PAY_DED_TEXT )
   aadd( aRay, '')
   aadd( aRay, 'Receipts are only included if they are dated within')
   aadd( aRay, 'the date range given. However, these receipts may have')
   aadd( aRay, 'been paid for outside the period given, or may be waiting')
   aadd( aRay, 'for actual payment in the ACCOUNT file to be paid on the')
   aadd( aRay, 'next run.  These receipts will be shown as PAID on this')
   aadd( aRay, 'report, even if a cheque has not actually been issued.')

   if lScreen
      WinArrayVu( aRay, 'Payment Status info' )
   else
      nuFormFeed()
      for n:=1 to len( aRay )
         nuQprnOut( aRay[ n ] )
      next
      nuQprnOut()
   endif


return( nil )



