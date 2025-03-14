// PROGRAM...: DAUDIT.PRG
// Original Author ...: DUNCAN JEFFRIES (revised B Hepler June 94)
// DATE .....: 7/10/90          revised again July 96
// NOTES ....: THIS ROUTINE PRODUCES A DAILY AUDIT REPORT
//    does not need to be DAILY, could be any range of dates.
//    This was compeletely re-written by Bill Hepler and uses
//    user definable columns.

// Revised June 17, 1994, Bill Hepler
// Quality Discount is Done for

// June 99 revised again
// Aug  99 revised again
// Sep  99 revised again to add both Posted & Unposted
// Oct  99 minor change to Report heading
// June 2000 - Revised because of UnPost.DBF eliminated
// Oct 2000 - bug fix
// Oct 2000 - add feature of product,process
// Jul 2001 - for PayGrp
// Jun 2010 - for Alaska, fix and generally make better.
// Jun 2011 - add Landscape extensions.
// Jul 2013 - Revised to deal better with Depots
// Oct 2013 - Final where advance not paid!
// Mar 2019 - Add Legend and columns and another Audit.
// Apr 2019 - Process Grade Names added
// Sep 2020 - Running Totals added to better match a Berry Receive
//            The Grower Container Balance Report in Avery Scale System is quirky
//            it Co-Mingles per Receipt Quanties and Running Totals.  Probably just
//            carelessness by someone.....

#include 'BerryPay.ch'
#include 'berry_rpt.ch'
#include 'bsgstd.ch'
#include 'combobox.ch'
#include 'common.ch'
#include 'errors.ch'
#include "field.ch"
#include "indexord.ch"
#include 'inkey.ch'
#include 'printer.ch'
#include 'rpt.ch'
#include 'sysvalue.ch'
#include 'valid.ch'
#include 'window.ch'

function dailyAudit( cAuditType  )   // lDaily )
	local getList :={}, dFrom,dTo, nGrower, aWin, nValue := 1
	local cDepot , cPayGrp
	local aTitle
   local cDW, cRpt:='', cRptForBoth := ''
	local cUnique
	local aRpt
	local lConfigure := .f., lLegend := .f.
	local aCombo
	local bWhile, bFor1, bFor2, bFor3
	local cProduct
	local cProcess
   local cTextFile

	cProcess := space(FLD_PROCESS)
	cProduct := space(FLD_PRODUCT)
	cPayGrp  := space(FLD_PAYGRP)
	cDepot   := space(FLD_DEPOT)

   do case
   case cAuditType == RP_DAILY_AUDIT
   // if lDaily
		dFrom       := dTo := date()
		cDW         := 'Daily'
      cRptForBoth := RP_BOTH_DAILY_AUDIT
		cTextFile   := 'D_AUDIT.TXT'

   case cAuditType == RP_WEEKLY_AUDIT
	// else
		dFrom       := date() -8
		dTo         := date() -1
		cDW         := 'Weekly'
      cRptForBoth := RP_BOTH_WEEKLY_AUDIT
		cTextFile   := 'W_AUDIT.TXT'

   case cAuditType == RP_ALTERNATE_1_AUDIT
		dFrom       := date() -8
		dTo         := date() -1
		cDW         := 'Special #1'
      cRptForBoth := RP_BOTH_ALTERNATE_1_AUDIT
		cTextFile   := 'A1_AUDIT.TXT'

   otherwise
   	WaitInfo({'Oh no - you should never see this', 'Call Crafted!'})
      return( nil )
	endcase

	nGrower := 0
	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

	myBsgScreen( cDW+' Audit Report' )
	msgLine( 'Audit Reporting..')

	create window at 4,08,21,70 title cDW+' Production Audit Report' to aWin
	display window aWin

	IN WINDOW aWin CREATE COMBOBOX AT 17,02 ;
           WINSAY 'Report on' USING { ;
		'UnPosted Receipts Only', ;
		'Posted (paid) Only    ', ;
		'Both Posted & Unposted' }   ;
	 MESSAGE ;
    'Posted transactions are (almost always) paid - and can not be edited' ;
	  TO aCombo

	ComboBoxShow( aCombo,  nValue )

	do while .t.
		msgLine('[Esc] to Exit')
		in window aWin @ 2,2  winSAY 'Select a date range for the report:'
		in window aWin @ 3,2 winsay 'From  ' winget dFrom picture '@d' ;
		 get_message 'Starting Date for Report,  +/- to adjust'
		in window aWin @ 4,2 winSAY 'To    ' winget dTo picture '@d' ;
		 get_message 'Ending Date for Report, +/- to adjust'

		in window aWin @ 6,2 winsay 'Grower' winget nGrower ;
		 PICTURE numBlankPic(FLD_GROWER) ;
		 valid PutName(aWin,6,20,LU_GROWER,nGrower) ;
		 LOOKUP(LU_GROWER, ;
		'Select a specific Grower or leave blank for all,   [F5] to Browse Growers')

		in window aWin @ 8,2 winsay 'Product' winget cProduct picture '@!' ;
			valid putName(aWin,8,20,LU_PRODUCT,cProduct) ;
			lookup( LU_PRODUCT, ;
		'Enter a Product to restrict the report to a single product, blank for all')

		in window aWin @ 9,2 winsay 'Process' winget cProcess picture '@!' ;
			valid putName(aWin,9,20,LU_PROCESS_TYPE,cProcess) ;
			lookup( LU_PROCESS_TYPE, ;
		'Enter a Process to restrict the report to a single process, blank for all')

		in window aWin @11,02 winsay 'Depot ' winget cDepot ;
         when PutName( aWin, 11, 15, LU_DEPOT, cDepot ) ;
         valid PutName( aWin,11, 15, LU_DEPOT, cDepot ) ;
         LookUp( LU_DEPOT, 'Blank for All Depots - F5 to Browse' )

		in window aWin @12,02 winsay 'PayGrp' winget cPayGrp ;
		  picture '@!' ;
			when PutName(aWin,12,30,LU_PAYGRP,cPayGrp) ;
			valid PutName(aWin,12,30,LU_PAYGRP,cPayGrp) ;
			LookUp( LU_PAYGRP,  ;
         'Leave Blank for All Grower Payment Groups')

		in window aWin @ 14,02 winsay 'Configure Report  ' winget lConfigure ;
		 picture 'Y'  GET_MESSAGE ;
		'You may select and order the columns to be printed'

		in window aWin @ 15,02 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

		read

		do case
		case lastkey()==K_ESC
			exit
		case nGrower <> 0 .and. !empty(cPayGrp)
			waitInfo({'Either set the grower or the Pay Group!'})
			loop
		endcase

		nValue := ComboBoxDo( aCombo,  nValue )

      aTitle := { TheClientName( ), ;
               cDW+' Audit Report' }

      Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))
		Daily->(dbSetRelation( 'Grower', ;
		 { || str( Daily->number,FLD_GROWER) } ) )

		do case
		case lastkey()==K_ESC .or. nValue == 0
         Daily->(dbClearRelation())
			loop
		case nValue == 1
			aadd(aTitle,'Unposted Transactions')
         // Oct 2013 - added Final Stuff here!
         bFor1  := { || Num2Equal0( Daily->Post_bat1) .and. ;
                        Num2Equal0( Daily->fin_bat) }
			if empty(nGrower)
            Daily->(OrdSetFocus(DAILY_POST_DATE_ORD))
				Daily->(dbSeek( str(0,FLD_DOCUMENT) + dtos(dFrom), SOFTSEEK))
            bWhile := { || Daily->date <= dTo .and. Daily->Post_bat1==0 .and. Daily->fin_bat==0}
			else
            Daily->(OrdSetFocus( DAILY_GROWER_ORD))
				Daily->(dbSeek( str(nGrower,FLD_GROWER)+dtos(dFrom), SOFTSEEK))
				bWhile := { || Daily->number == nGrower .and. Daily->date <= dTo  }
			endif

		case nValue == 2
			aadd( aTitle,'Posted Transactions Only')
         bFor1  := { || Daily->Post_bat1<>0 .or. Daily->Fin_Bat<>0 }
			if empty(nGrower)
            Daily->(OrdSetFocus(DAILY_DATE_ORD))
				Daily->(dbSeek( dtos(dFrom), SOFTSEEK))
				bWhile := { || Daily->date <= dTo }
			else
            Daily->(OrdSetFocus( DAILY_GROWER_ORD))
				Daily->(dbSeek( str(nGrower,FLD_GROWER)+dtos(dFrom), SOFTSEEK))
				bWhile := { || Daily->number == nGrower .and. Daily->date <= dTo  }
			endif
		case nValue == 3
			aadd( aTitle,'Posted & Unposted Transactions' )
			bFor1 := { || .t. }
			if empty(nGrower)
            Daily->(OrdSetFocus(DAILY_DATE_ORD))
				Daily->(dbSeek( dtos(dFrom), SOFTSEEK))
				bWhile := { || Daily->date <= dTo }
			else
            Daily->(OrdSetFocus( DAILY_GROWER_ORD))
				Daily->(dbSeek( str(nGrower,FLD_GROWER)+dtos(dFrom), SOFTSEEK))
				bWhile := { || Daily->number == nGrower .and. Daily->date <= dTo  }
			endif
		endcase

		if !empty( cPayGrp)
			bFor2 := { || GrInPayGrp(cPayGrp,'') }
		else
			bFor2 := { || .t. }
		endif

		// if !empty( cDepot)
      //   bFor3 := { || Daily->depot == cDepot }
		// else

		bFor3 := { || .t. }

		// endif

		msgLine('Indexing....')
		cUnique := UniqueFile()

		dbSelectAr('Daily' )

      InitGeneralFor( bFor1, bFor2, bFor3, ;
		   { || InclPrdPrcGrDepo( cProduct,cProcess,nGrower, cDepot ) } )

      Daily->( OrdCondSet( 'GeneralFor()', ;
			        { || GeneralFor() }, ;
                    .f., bWhile  ) )
      Daily->( OrdCreate( cUnique, 'USETHIS',   ;
             'str( Daily->number,      4    )+ dtos( Daily->date) + str( Daily->recpt,  6        )', ;
         { || str( Daily->number, FLD_NUMBER)+ dtos( Daily->date) + str( Daily->recpt, FLD_RECPT )} ) )

      if empty( Daily->(OrdBagName('USETHIS')) )
         AppError(APP_ERR_TEMP_INDEXING1, {'Hmm-we have a problem!'})
      endif

      Daily->( OrdSetFocus('USETHIS') )

		Daily->(dbGoTop())

		msgLine('Ready to report...')

		aRpt := {}
		rGrowerInfo( aRpt )
		rRcptQty( aRpt )
		rAdvPrInfo( aRpt )

		rOutConCols( aRpt, .f.  )
		rInConCols( aRpt, .f. )
		rRawConCols( aRpt )

		rFinPrInfo( aRpt )
      aadd( aRpt, { 'St', ;
         { || iif(Daily->post_bat1==0 .and. Daily->fin_bat==0,"U" ,"P" ) },"C", 2, 000, .t., .f., ;
         'Status - P=Posted, U=Unposted Receipt' } )

      rDockage( aRpt, .f. )
      rDepotSite( aRpt )
		rRcptNotes( aRpt )
		rVarietyEtc( aRpt )       // June 03, 2015
      rAdvancesPd( aRpt )       // March 2019
		rProGradeEtc( aRpt )      // April 2019

      if nValue == 3
			// this stuff for BOTH in September...
			cRpt := cRptForBoth
		else
         cRpt := cAuditType
		endif
      gRptInit( cRpt, aRpt)

		if lConfigure
			gRptSelect( aRpt )
		endif

      aadd(aTitle, 'From '+shMDY(dFrom)+' to '+shMDY(dTo) )
      if len( aTitle)>=2
         aTitle[2] := aTitle[2]+' '+cRpt
      endif
      MoreHead( aTitle, cProduct, cProcess, nGrower, cPayGrp, cDepot )

		gRptInitHead()
		gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

		gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| Daily->number } )
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
		 {|| nuQprnOut( str( Daily->number,FLD_NUMBER)+' '+Grower->name ) } )

		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL , .f.)

		if selectPrn( cTextFile )
			// For LandScape
			gRptAutoPageOrientation( aRpt, 0)

			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

			Daily->(gRptPrinter( aRpt ))

			if lLegend
				prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
			endif

			PRINT_OFF  RPT_COMPLETE_EJECT

			if lConfigure
				if yesno({'Save this Report Format?'})
					gRptSave( aRpt )
				endif
			endif
		endif

		Daily->(dbClearFilter())
		Daily->(dbClearRelation())
		Daily->(dbCloseArea())

		KillUnique(cUnique,'.CDX')
		if !openFile({'Daily'},DB_SHARED)
			exit
		endif
	enddo

	ComboBoxKill( aCombo )
	kill window aWin
	close databases
RETURN( nil )

function ProdAudit(  )
	local getList :={}, dFrom,dTo, nGrower, aWin
	local cDepot,aTitle
   local cUnique
	local aRpt
	local lConfigure := .f., lLegend := .f.
	local cProduct
	local cProcess
	local cPayGrp
   local bWhile, bFor1,bFor2,bFor3

	cProcess := space(FLD_PROCESS)
	cProduct := space(FLD_PRODUCT)
	cDepot   := space(FLD_DEPOT)
	cPayGrp  := space(FLD_PAYGRP)

	dFrom    := date() -7
	dTo      := date()
	nGrower  := 0

	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

	myBsgScreen( 'Unposted Product Audit Report' )
	msgLine('UnPosted Audit Reporting...')

	create window at 4,10,21,70 title 'Unposted Product Audit Report' to aWin
	display window aWin

	do while .t.
		msgLine('[Esc] to Exit')
		in window aWin @ 2,2  winSAY 'Select a date range for the report:'
		in window aWin @ 3,5 winsay 'From  ' winget dFrom picture '@d' ;
		 get_message 'Starting Date for Report,  +/- to adjust'
		in window aWin @ 4,5 winSAY 'To    ' winget dTo picture '@d' ;
		 get_message 'Ending Date for Report, +/- to adjust'

		in window aWin @ 6,5 winsay 'Grower' winget nGrower ;
		 PICTURE numBlankPic(FLD_GROWER) ;
		 valid PutName(aWin,6,25,LU_GROWER,nGrower) ;
		 LOOKUP(LU_GROWER, ;
		'Select a specific Grower or leave blank for all,   [F5] to Browse Growers')

		in window aWin @ 8,5 winsay 'Product' winget cProduct picture '@!' ;
			valid putName(aWin,8,25,LU_PRODUCT,cProduct) ;
			lookup( LU_PRODUCT, ;
		'Enter a Product to restrict the report to a single product, blank for all')

		in window aWin @ 9,5 winsay 'Process' winget cProcess picture '@!' ;
			valid putName(aWin,9,25,LU_PROCESS_TYPE,cProcess) ;
			lookup( LU_PROCESS_TYPE, ;
		'Enter a Process to restrict the report to a single process, blank for all')

		in window aWin @10,5 winsay 'Depot  ' winget cDepot ;
         when PutName( aWin, 10, 25, LU_DEPOT, cDepot ) ;
         valid PutName( aWin,10, 25, LU_DEPOT, cDepot ) ;
         LookUp( LU_DEPOT, 'Blank for All Depots - F5 to Browse' )

		in window aWin @11,5 winsay 'PayGrp ' winget cPayGrp ;
		  picture '@!' ;
			when PutName(aWin,11,30,LU_PAYGRP,cPayGrp) ;
			valid PutName(aWin,11,30,LU_PAYGRP,cPayGrp) ;
			LookUp( LU_PAYGRP,  ;
         'Leave Blank for All Grower Payment Groups')

		in window aWin @ 13, 5 winsay 'Configure Report  ' winget lConfigure ;
		 picture 'Y'  GET_MESSAGE ;
		'You may select and order the columns to be printed'

		in window aWin @ 14,05 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

		in window aWin @16,01 winsay 'Lists Unposted transactions by Product'

		READ

		if lastkey()==K_ESC
			exit
		endif

		cUnique := UniqueFile()
		select Daily
		msgLine('Indexing....')

      Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))
		Daily->(dbSetRelation( 'Grower', ;
		 { || str( Daily->number,FLD_GROWER) } ) )

		bFor1 := { || .t. }
		bFor2 := { || .t. }
		bFor3 := { || .t. }

		if !empty( cPayGrp)
         bFor1 := { || GrInPayGrp(cPayGrp,'') .and. Daily->Post_Bat1==0 .and. Daily->fin_bat==0 }
      else
         bFor1 := { || Daily->Post_Bat1==0 .and. Daily->fin_bat==0 }
		endif

		/* ----------------
			if !empty(cDepot)
				bFor2 := { || Daily->depot==cDepot }
			endif
		--------------- */

      bFor3 := { || !empty( Daily->product ) }


		if empty(nGrower)
      	Daily->(OrdSetFocus(DAILY_POST_DATE_ORD))
			Daily->(dbSeek( str(0,FLD_DOCUMENT) + dtos(dFrom), SOFTSEEK))
         bWhile := { || Daily->date <= dTo .and. Daily->Post_bat1==0 .and. Daily->fin_bat==0}
		else
      	Daily->(OrdSetFocus( DAILY_GROWER_ORD))
			Daily->(dbSeek( str(nGrower,FLD_GROWER)+dtos(dFrom), SOFTSEEK))
			bWhile := { || Daily->number == nGrower .and. Daily->date <= dTo  }
		endif

		// msgBox( 'After SEEK, before Index')
		// dbEdit2( .t. )

      InitGeneralFor( bFor1, bFor2, bFor3, ;
		   { || InclPrdPrcGrDepo( cProduct,cProcess,nGrower,cDepot ) } )

      Daily->( OrdCondSet( 'GeneralFor()', ;
			        { || GeneralFor() }, ;
                    .f.,  bWhile ) )

      Daily->( OrdCreate( cUnique, 'USETHIS',   ;
             'Daily->product + Daily->process + str( Daily->grade,     1    ) + dtos( Daily->date)', ;
         { || Daily->product + Daily->process + str( Daily->grade, FLD_GRADE) + dtos( Daily->date)  } ))

      if empty( Daily->(OrdBagName('USETHIS')) )
         AppError(APP_ERR_TEMP_INDEXING2, {'Hmm-we have a problem!'})
      endif
      Daily->( OrdSetFocus('USETHIS') )

		Daily->(dbGoTop())

		// msgBox( 'Afer Index')
		// dbEdit2( .t. )

		aRpt := {}
		rGrowerInfo( aRpt )
		rRcptQty( aRpt )
		rAdvPrInfo( aRpt )
		rFinPrInfo( aRpt )
		rDepotSite( aRpt )

      rProGradeEtc( aRpt )  // April 2019

		gRptInit( RP_PRODUCTION_AUDIT, aRpt)

		if lConfigure
			gRptSelect( aRpt )
		endif

      aTitle := {TheClientName( ), ;
        'From '+shMDY(dFrom)+' to '+shMDY(dTo)}
		MoreHead( aTitle, cProduct, cProcess, nGrower, cPayGrp, cDepot )

		aadd( aTitle, 'Unposted Product Product Audit' )

		gRptInitHead()
		gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

		gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {||Daily->product} )
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
		 {|| nuQprnOut( Daily->product+' '+NameOf(LU_PRODUCT, Daily->product )) } )

		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL , .t.)
		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_ON, {||Daily->process} )
		gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_TITLE, ;
		 {|| nuQprnOut( ' '+Daily->process+' '+NameOf(LU_PROCESS_TYPE, Daily->process )) } )

		if selectPrn('PRODAUD.TXT')

			// For LandScape
			gRptAutoPageOrientation( aRpt, 0)

			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

			Daily->(gRptPrinter( aRpt ))

			if lLegend
				prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
			endif

			PRINT_OFF  RPT_COMPLETE_EJECT

			if lConfigure
				if yesno({'Save this Report Format?'})
					gRptSave( aRpt )
				endif
			endif
		endif

		Daily->(dbClearFilter())
		Daily->(dbClearRelation())
		Daily->(dbCloseArea())

		KillUnique(cUnique,'.CDX')

      if !openFile({"Daily"}, DB_SHARED)
         exit
      endif
	enddo
	kill window aWin
	close databases
RETURN( nil )

function ContAudit(  )
	local getList :={}, dFrom,dTo, nGrower, aWin
   local cUnique
	local aRpt
	local lConfigure := .f.
	local aTitle
	local aCombo
	local nValue := 3
   local bWhile, bFor1, bFor2, bFor3
	local cDepot := ' '


	cDepot   := space(FLD_DEPOT)

	dFrom := date() -30
	dTo := date()

	nGrower := 0
	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

	myBsgScreen( 'Container Audit Report' )
   create window at 4,10,20,60 title 'Container Audit Report' to aWin
	display window aWin

   IN WINDOW aWin CREATE COMBOBOX AT 12,10 ;
           WINSAY 'Report on' USING { ;
		'UnPosted Receipts Only', ;
		'Posted (paid) Only    ', ;
		'Both Posted & Unposted' }   ;
	 MESSAGE ;
	 'Posted transactions are (almost always) paid - and can not be edit' ;
	  TO aCombo

	ComboBoxShow( aCombo,  nValue )

	do while .t.

		msgLine('[Esc] to Exit')
		in window aWin @ 2,2  winSAY 'Select a date range for the report:'
		in window aWin @ 3,10 winsay 'From  ' winget dFrom picture '@d' ;
		 get_message 'Starting Date for Report,  +/- to adjust'
		in window aWin @ 4,10 winSAY 'To    ' winget dTo picture '@d' ;
		 get_message 'Ending Date for Report, +/- to adjust'

		in window aWin @ 6,2 winSAY 'Depot ' winget cDepot picture '@!' ;
         when PutName( aWin, 6, 15, LU_DEPOT, cDepot ) ;
         valid PutName( aWin, 6,15, LU_DEPOT, cDepot ) ;
         LookUp( LU_DEPOT, 'Blank for All Depots - F5 to Browse' )

		in window aWin @ 8,2 winsay 'Grower' winget nGrower ;
		 PICTURE numBlankPic(FLD_GROWER) ;
		 LOOKUP(LU_GROWER, ;
		'Select a specific Grower or leave blank for all,   [F5] to Browse Growers')

		in window aWin @10,2 winsay 'Configure Report' winget lConfigure ;
		 picture 'Y'  GET_MESSAGE ;
		'You may select and order the columns to be printed'

      in window aWin @15,01 winsay 'Lists transactions by Grower'

		READ

		if lastkey()==K_ESC
			exit
		endif

		nValue := ComboBoxDo( aCombo,  nValue )

      aTitle := {'',''}
		do case
		case lastkey()==K_ESC .or. nValue == 0
			loop
		case nValue == 1
			if empty(nGrower)
            Daily->(OrdSetFocus(DAILY_POST_DATE_ORD))
				Daily->(dbSeek( str(0,FLD_DOCUMENT) + dtos(dFrom), SOFTSEEK))
            bWhile := { || Daily->date <= dTo .and. Daily->Post_bat1==0 .and. Daily->fin_bat==0}
            bFor1  := { || .t. }
			else
            Daily->(OrdSetFocus( DAILY_GROWER_ORD))
				Daily->(dbSeek( str(nGrower,FLD_GROWER)+dtos(dFrom), SOFTSEEK))
				bWhile := { || Daily->number == nGrower .and. Daily->date <= dTo  }
            bFor1  := { || Daily->Post_bat1==0 .and. Daily->fin_bat==0}
			endif
         aTitle[2] := 'UnPosted Receipts'
		case nValue == 2
			if empty(nGrower)
            Daily->(OrdSetFocus(DAILY_DATE_ORD))
				Daily->(dbSeek( dtos(dFrom), SOFTSEEK))
				bWhile := { || Daily->date <= dTo }
            bFor1  := { || Daily->Post_bat1<>0 }
			else
            Daily->(OrdSetFocus( DAILY_GROWER_ORD))
				Daily->(dbSeek( str(nGrower,FLD_GROWER)+dtos(dFrom), SOFTSEEK))
				bWhile := { || Daily->number == nGrower .and. Daily->date <= dTo  }
            bFor1  := { || Daily->Post_bat1<>0 }
			endif
         aTitle[2] := 'Posted Receipts'
		case nValue == 3
			if empty(nGrower)
            Daily->(OrdSetFocus(DAILY_DATE_ORD))
				Daily->(dbSeek( dtos(dFrom), SOFTSEEK))
				bWhile := { || Daily->date <= dTo }
            bFor1  := { || .t.  }
			else
            Daily->(OrdSetFocus( DAILY_GROWER_ORD))
				Daily->(dbSeek( str(nGrower,FLD_GROWER)+dtos(dFrom), SOFTSEEK))
				bWhile := { || Daily->number == nGrower .and. Daily->date <= dTo  }
            bFor1  := { || .t.  }
			endif
         aTitle[2] := 'Posted & UnPosted'
		endcase

      bFor2 := { || .t. }

      if !empty( cDepot )
      	// bFor2 := { || Daily->depot == cDepot }
         aadd(aTitle, 'Depot='+cDepot+' '+alltrim(NameOf( LU_DEPOT, cDepot )) )
      endif
      // if !empty( cDepot)
		//         bFor3 := { || Daily->depot == cDepot }
		// else

		bFor3 := { || .t. }

		// endif

		msgLine('Indexing....')
		cUnique := UniqueFile()

      InitGeneralFor( bFor1, bFor2, bFor3, ;
		   { || InclPrdPrcGrDepo( '','',nGrower,cDepot ) } )

      Daily->( OrdCondSet( 'GeneralFor()', ;
			        { || GeneralFor() }, ;
                    .f.,  bWhile  ) )
      Daily->( OrdCreate( cUnique, 'USETHIS',   ;
              'str( Daily->number,    4      )+ dtos( Daily->date) + str( Daily->recpt, 6         )' , ;
         { ||  str( Daily->number, FLD_NUMBER)+ dtos( Daily->date) + str( Daily->recpt, 6         )  } ) )

      if empty( Daily->(OrdBagName('USETHIS')) )
         AppError(APP_ERR_TEMP_INDEXING3, {'Hmm-we have a problem!'})
      endif

      Daily->( OrdSetFocus('USETHIS') )

		Daily->(dbSetRelation( 'Grower', ;
		 { || str( Daily->number,FLD_GROWER) } ) )

		Daily->(dbGoTop())

		aRpt := {}
		rGrowerInfo( aRpt )
		rRcptQty( aRpt )
		rAdvPrInfo( aRpt )
		rOutConCols( aRpt, .f.  )
		rInConCols( aRpt, .f. )
		rRawConCols( aRpt )
		rFinPrInfo( aRpt )
		rDepotSite( aRpt )

		if nValue == 3
			// this stuff for BOTH in September...
			aadd( aRpt, { 'St', ;
          { || iif(Daily->post_bat1==0 .and. Daily->fin_bat==0,"P" ,"U" ) },"C", 2, 000, .t., .f., ;
			 'Status - P=Posted, U=Unposted Receipt' } )

			gRptInit( RP_BOTH_CONTAINER_AUDIT, aRpt)
		else
			gRptInit( RP_CONTAINER_AUDIT, aRpt)
		endif

		if lConfigure
			gRptSelect( aRpt )
		endif


		gRptInitHead()
		gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

		gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {||Daily->number } )
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
		 {|| nuQprnOut( lStrim( Daily->number)+' '+NameOf(LU_GROWER, Daily->number )) } )

		if selectPrn('CONTAUD.TXT')
			// For LandScape
			gRptAutoPageOrientation( aRpt, 0)

			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

			Daily->(dbGoTop())
			Daily->(gRptPrinter( aRpt ))
			PRINT_OFF  RPT_COMPLETE_EJECT

			if lConfigure
				if yesno({'Save this Report Format?'})
					gRptSave( aRpt )
				endif
			endif
		endif

		Daily->(dbClearFilter())
		Daily->(dbClearRelation())
		Daily->(dbCloseArea())

		KillUnique(cUnique,'.CDX')
      if !openFile({"Daily"}, DB_SHARED)
         exit
      endif
	enddo

	ComboBoxKill( aCombo )
	kill window aWin
	close databases

RETURN( nil )

static function MoreHead( aTitle, cProduct, cProcess, nGrower, cPayGrp, cDepot)
	local cTemp
	local n
	local lAdd := .f.

	default cDepot to ''

	cTemp := ''
	if !empty(cProduct)
		cTemp :=  'Berry '+cProduct
	endif

	if !empty(cProcess)
		if empty(cTemp)
			cTemp :=  'Process '+cProcess
		else
			cTemp := cTemp+' '+'Process '+cProcess
		endif
	endif
	if !empty(cTemp)
		aadd( aTitle, cTemp)
	endif

	if !empty(cPayGrp)
		aadd(aTitle,'PayGrp='+cPayGrp+' '+alltrim(NameOf(LU_PAYGRP, cPayGrp)))
	endif

	if !empty(nGrower)
		aadd(aTitle, 'Grower '+lStrim(nGrower) )
	endif

	if !empty(cDepot)
		lAdd := .t.
		n := len( aTitle )
		if n > 0
			if len( aTitle[n]) < 40
				lAdd := .f.
				aTitle[n] += ' Depot='+cDepot
			endif
		endif
		if lAdd
			aadd(aTitle, 'Depot='+cDepot )
		endif
	endif

return( nil )

function OneCont(  )
   local getList :={}, dFrom,dTo, nGrower, aWin
	local cHeading
   local cUnique
	local aRpt
	// local lConfigure := .f.
	local cTitle
	local aCombo
	local nValue := 3
   local bWhile, bFor1, bFor2, bFor3
	local cDepot := ' '
   local nContainer := 0
   local lLegend     := .t., lDepot := .f.
   local lGCBcolumns := .t.

	cDepot   := space(FLD_DEPOT)

	dFrom := date() -30
	dTo := date()

	nGrower := 0
	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

   myBsgScreen( 'Single Container Audit Report' )

   create window at 4,06,21,72 title 'Single Container Report' to aWin
	display window aWin

   IN WINDOW aWin CREATE COMBOBOX AT 13,10 ;
           WINSAY 'Report on' USING { ;
		'UnPosted Receipts Only', ;
		'Posted (paid) Only    ', ;
		'Both Posted & Unposted' }   ;
	 MESSAGE ;
	 'Posted transactions are (almost always) paid - and can not be edited' ;
	  TO aCombo

	ComboBoxShow( aCombo,  nValue )

	do while .t.

		msgLine('[Esc] to Exit')
		in window aWin @  2, 2  winSAY 'Select a date range for the report:'
		in window aWin @  3,10 winsay 'From  ' winget dFrom picture '@d' ;
		 get_message 'Starting Date for Report,  +/- to adjust'
		in window aWin @  4,10 winSAY 'To    ' winget dTo picture '@d' ;
		 get_message 'Ending Date for Report, +/- to adjust'

      in window aWin @ 6, 2 winSAY 'Container Code' ;
       winget nContainer picture '@Z 99' ;
       valid ValidTest( V_CONTAINER, nContainer, VT_BROWSE) ;
       lookup( LU_CONTAINER, 'Enter Container Code - F5 to Browse')

		in window aWin @ 8, 2 winsay 'Grower ID     ' winget nGrower ;
		 PICTURE numBlankPic(FLD_GROWER) ;
		 valid PutName(aWin,8,25,LU_GROWER,nGrower) ;
		 LOOKUP(LU_GROWER, ;
		'Select a specific Grower or leave blank for all,   [F5] to Browse Growers')

		in window aWin @ 9, 2 winsay 'Sub Total on Depot' winget lDepot picture 'Y' ;
		  get_message "Say YES to sub-Total on the Depot"

		in window aWin @10, 2 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

		in window aWin @11, 2 winsay 'Show GCB Columns  ' winget lGCBColumns picture 'Y' ;
		  get_message "GBC Report shows Running total on IN and Receipt totals on OUT & Balance"

		in window aWin @15, 2 winsay 'The Grower Container Balance detail report in Avery Scale Software'
		in window aWin @16, 2 winsay 'is little odd.  Including the GCB columns makes it easier to match'
		in window aWin @17, 2 winsay 'up your data with the Scale Report.'


		READ

      do case
      case lastkey()==K_ESC
			exit
      case nContainer <= 0
         WaitInfo({'You must choose a container'})
         loop
      endcase

		nValue := ComboBoxDo( aCombo,  nValue )

		do case
		case lastkey()==K_ESC .or. nValue == 0
			loop
		case nValue == 1
         Daily->(OrdSetFocus(DAILY_POST_DATE_ORD))
         Daily->(dbSeek( str(0,FLD_DOCUMENT) + dtos(dFrom), SOFTSEEK))
         bWhile := { || Daily->date <= dTo .and. Daily->Post_bat1==0 }
         bFor1  := { || .t. }
         cTitle := 'UnPosted Receipts'

		case nValue == 2
         Daily->(OrdSetFocus(DAILY_DATE_ORD))
         Daily->(dbSeek( dtos(dFrom), SOFTSEEK))
         bWhile := { || Daily->date <= dTo }
         bFor1  := { || Daily->Post_bat1<>0 .or. Daily->fin_bat<>0}
         cTitle := 'Posted Receipts'
		case nValue == 3
         Daily->(OrdSetFocus(DAILY_DATE_ORD))
         Daily->(dbSeek( dtos(dFrom), SOFTSEEK))
         bWhile := { || Daily->date <= dTo }
         bFor1  := { || .t.  }
         cTitle := 'Posted & Unposted'
		endcase

		msgLine('Indexing....')
		cUnique := UniqueFile()

      bFor2 := { || .t. }


		// if !empty( cDepot)
      // bFor3 := { || Daily->depot == cDepot .and. ;
      //                (Daily->(gsInContainer( nContainer )) <> 0 .or. ;
      //                 Daily->(gsOutContainer( nContainer )) <> 0)  }
		// else
         bFor3 := { ||  (Daily->(gsInContainer( nContainer )) <> 0 .or. ;
            Daily->(gsOutContainer( nContainer )) <> 0)  }
		// endif

		msgLine('Indexing....')
		cUnique := UniqueFile()

		dbSelectAr('Daily' )

      InitGeneralFor( bFor1, bFor2, bFor3, ;
              { || InclPrdPrcGrDepo( '','',nGrower,cDepot ) } )


      Daily->( OrdCondSet( 'GeneralFor()', ;
			        { || GeneralFor() }, ;
                    .f.,  bWhile  ) )
      Daily->( OrdCreate( cUnique, 'USETHIS',   ;
             'str( Daily->number,      4    )+ dtos( Daily->date) + str( Daily->recpt,  6        )', ;
         { || str( Daily->number, FLD_NUMBER)+ dtos( Daily->date) + str( Daily->recpt, FLD_RECPT )} ) )

      if empty( Daily->(OrdBagName('USETHIS')) )
         AppError(APP_ERR_TEMP_INDEXING4, {'Hmm-we have a problem!'})
      endif

      Daily->( OrdSetFocus('USETHIS') )

		msgLine('Ready to report...')

		Daily->(dbSetRelation( 'Grower', ;
		 { || str( Daily->number,FLD_GROWER) } ) )

		Daily->(dbGoTop())

		aRpt := {}

      aadd( aRpt,{ ' ',{|| ' '}, 'C', 1, 0, .t., .f., 'a Nice Space'} )

      aadd( aRpt, {'Date', {|| shMDY(Field->date) }, "C", 6, 0 , ;
         .t., .f. , 'Date of Receipt'})

      aadd( aRpt, {'Rect #', {|| Field->depot+'-'+lstrim(Field->recpt) }, "C", FLD_RECPT+2, 0 , ;
         .t., .f. , 'Receipt # w/ Depot'})

      aadd( aRpt, { 'Prod', {|| Field->product},   'C',  4, 0 , .t., .f., ;
       'Product'})

      aadd( aRpt, { 'Proc', {|| Field->process},   'C',  4, 0 , .t., .f., ;
       'Proc'})

      aadd( aRpt, { 'Gr', {|| Field->grade},   'N',  2, 0 , .t., .f., ;
       'Grade'})

      aadd( aRpt, ;
		{ 'Gross'  	, { || Field->GROSS }      ,  'N' ,    006  ,   000 , ;
			.f., .f. , ;
			'Gross of Containers' } )

      aadd( aRpt, ;
		{ 'TARE'   	, { || Field->TARE }       ,  'N' ,    006  ,   000 , ;
			.f., .f. , ;
			'Tare of Containers' } )

      aadd( aRpt, { 'Net', {|| Field->net},   ',',  9, 0 , .t., .t., ;
       'Net Weight'})

      aadd( aRpt, { 'Con $',  ;
        {|| ValueAllContain( 'Daily' ) }, ',', 10, 2 , .t., .t., ;
         'Total Value of Containers Issued'})

      aadd( aRpt, { 'St', ;
          { || iif(Daily->post_bat1==0 .and. Daily->fin_bat==0,"P" ,"U" ) },"C", 2, 000, .t., .f., ;
			 'Status - P=Posted, U=Unposted Receipt' } )

      aadd( aRpt, { {'IN: '+ContSName( nContainer ),'Receipt'} , ;
          { || gsInContainer( nContainer ) }, "N", 7, 000, .t., .t., ;
          'Containers Received on this Receipt'} )

      aadd( aRpt, { { 'OUT: '+ContSName( nContainer ),'Receipt'}, ;
          { || gsOutContainer( nContainer ) }, "N", 7, 000, .t., .t., ;
          'Containers Shipped on this Receipt'})

      aadd( aRpt, { {'Out Bal','Receipt'}, ;
          { || -NetContRecvd( nContainer ) }, "N", 8, 000, .t., .t., ;
          'Containers Received - per Receipt'})

      // This is to Match the GCB Report
      if lGCBcolumns
      	aadd( aRpt, { {'G','C','B'}, ;
          { || ' ' }, "C", 1, 000, .t., .t., ;
          'Just to Notte these relate to GCB Report'})

         aadd( aRpt, { {'IN: '+ContSName( nContainer ),'Run Tot','GCB'} , ;
             { || gsInContainer( nContainer ) }, "R", 7, 000, .t., .t., ;
             'Running Total - Containers Received - to Match GCB Report'} )

         aadd( aRpt, { { 'OUT: '+ContSName( nContainer ),'Receipt','GCB'}, ;
             { || gsOutContainer( nContainer ) }, "N", 7, 000, .t., .t., ;
             'Containers Shipped on this Receipt - to Match GCB Report'})

         // The BALANCE Column on GCB report is wonky! It make NO Sense!
         aadd( aRpt, { {'Out Bal','Receipt','GCB'}, ;
             { || -NetContRecvd( nContainer ) }, "N", 8, 000, .t., .t., ;
             'Total of Containers Shipped- SubTotal to Match GCB Report'})
		else
	      aadd( aRpt, { {'IN: '+ContSName( nContainer ),'Run Tot'} , ;
   	       { || gsInContainer( nContainer ) }, "R", 7, 000, .t., .t., ;
      	    'Containers Received on this Receipt'} )

	      aadd( aRpt, { { 'OUT: '+ContSName( nContainer ),'Run Tot'}, ;
   	       { || gsOutContainer( nContainer ) }, "R", 7, 000, .t., .t., ;
      	    'Containers Shipped on this Receipt'})

	      aadd( aRpt, { {'Out Bal','Run Tot'}, ;
   	       { || -NetContRecvd( nContainer ) }, "R", 8, 000, .t., .t., ;
      	    'Containers Received - per Receipt'})
      endif
//      gRptInit( RP_BOTH_CONTAINER_AUDIT, aRpt)
//      if lConfigure
//         gRptSelect( aRpt )
//      endif

		cHeading := 'From '+shMDY(dFrom)+' to '+shMDY(dTo)
      cTitle   += ' Container: '+ ContSName( nContainer ) + iif( lGCBColumns,' to match GCB rpt','')

		gRptInitHead()
		gRptGetSetHead( RPT_HEAD_TITLE, ;
			{  cHeading, cTitle } )

		gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {||Daily->number } )
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
		 {|| nuQprnOut( lStrim( Daily->number)+' '+NameOf(LU_GROWER, Daily->number )) } )

      if lDepot
	      gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL , .t.)
			gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_ON, {|| Daily->depot } )
			gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL_TITLE, ;
			 {|| nuQprnOut( ' '+Daily->depot+' '+NameOf(LU_DEPOT, Daily->depot )) } )
      endif

      if selectPrn('CONT1AD.TXT')
			// For LandScape
			gRptAutoPageOrientation( aRpt, 0)

			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

			Daily->(dbGoTop())
			Daily->(gRptPrinter( aRpt ))

			if lLegend
				prnRptLegend( aRpt, {  cHeading, cTitle }, .t. ) // only show columns selected
			endif

			PRINT_OFF  RPT_COMPLETE_EJECT

         // if lConfigure
         //   if yesno({'Save this Report Format?'})
         //      gRptSave( aRpt )
         //   endif
         // endif
		endif

		Daily->(dbClearFilter())
		Daily->(dbClearRelation())
		Daily->(dbCloseArea())

		KillUnique(cUnique,'.CDX')
      if !openFile({"Daily"}, DB_SHARED)
         exit
      endif
	enddo

	ComboBoxKill( aCombo )
	kill window aWin
	close databases

RETURN( nil )

function DockAudit(  )
	local getList :={}, dFrom,dTo, nGrower, aWin
	local cDepot,aTitle
   local cUnique
	local aRpt
	local lConfigure := .f.
	local cProduct
	local cProcess
	// local cTemp
	// local cPayGrp
   local bFor1,bFor2,bFor3,bWhile

	cProcess := space(FLD_PROCESS)
	cProduct := space(FLD_PRODUCT)
	cDepot   := space(FLD_DEPOT)
	// cPayGrp  := space(FLD_PAYGRP)

	dFrom := date() -7
	dTo := date()

	nGrower := 0
	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

   myBsgScreen( 'Dockage Report' )

   create window at 4,10,20,70 title 'Lists Transactions that may have Dockage' to aWin
	display window aWin

	do while .t.
		msgLine('[Esc] to Exit')
		in window aWin @ 2, 2  winSAY 'Select a date range for the report:'
		in window aWin @ 3, 5 winsay 'From  ' winget dFrom picture '@d' ;
		 get_message 'Starting Date for Report,  +/- to adjust'
		in window aWin @ 4, 5 winSAY 'To    ' winget dTo picture '@d' ;
		 get_message 'Ending Date for Report, +/- to adjust'

		in window aWin @ 6, 5 winsay 'Grower' winget nGrower ;
		 PICTURE numBlankPic(FLD_GROWER) ;
		 valid PutName(aWin,6,25,LU_GROWER,nGrower) ;
		 LOOKUP(LU_GROWER, ;
		'Select a specific Grower or leave blank for all,   [F5] to Browse Growers')

		in window aWin @ 8, 5 winsay 'Product' winget cProduct picture '@!' ;
			valid putName(aWin,8,25,LU_PRODUCT,cProduct) ;
			lookup( LU_PRODUCT, ;
		'Enter a Product to restrict the report to a single product, blank for all')

		in window aWin @ 9, 5 winsay 'Process' winget cProcess picture '@!' ;
			valid putName(aWin,9,25,LU_PROCESS_TYPE,cProcess) ;
			lookup( LU_PROCESS_TYPE, ;
		'Enter a Process to restrict the report to a single process, blank for all')

		in window aWin @11,05 winsay 'Depot ' winget cDepot ;
         when PutName( aWin, 11, 25, LU_DEPOT, cDepot ) ;
         valid PutName( aWin,11, 25, LU_DEPOT, cDepot ) ;
         LookUp( LU_DEPOT, 'Blank for All Depots - F5 to Browse' )

		in window aWin @13,5 winsay 'Configure Report' winget lConfigure ;
		 picture 'Y'  GET_MESSAGE ;
		'You may select and order the columns to be printed'

      in window aWin @15,01 winsay 'Lists ALL transactions that may have DOCKAGE'

		READ

		if lastkey()==K_ESC
			exit
		endif

		cUnique := UniqueFile()
		select Daily
		msgLine('Indexing....')

      Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))
		Daily->(dbSetRelation( 'Grower', ;
		 { || str( Daily->number,FLD_GROWER) } ) )

      Daily->(OrdSetFocus( DAILY_DATE_ORD ))
      Daily->(dbSeek( dtos(dFrom), SOFTSEEK))

      // bFor1 := { || InclPrdPrcGrDepo( cProduct, cProcess, nGrower, cDepot ) }
      bFor1 := { || .t. }

      bFor2 := { ||  Daily->dock_pct > 0 .or. ;
                 (Daily->ori_net > 0 .and. ;
                 str(Daily->ori_net - Daily->net,8,1)<>str(0,8,1) ) }
      bFor3 := { || .t. }
      bWhile := { || Daily->date <= dTo }

      InitGeneralFor( bFor1, bFor2, bFor3, ;
		   { || InclPrdPrcGrDepo( cProduct,cProcess,nGrower,cDepot) } )

      msgLine('Indexing....')
		cUnique := UniqueFile()

      Daily->( OrdCondSet( 'GeneralFor()', ;
			        { || GeneralFor() }, ;
                    .f.,  bWhile  ) )
      Daily->( OrdCreate( cUnique, 'USETHIS',   ;
              'str( Daily->number,    4      )+ dtos( Daily->date) + str( Daily->recpt, 6         )' , ;
         { ||  str( Daily->number, FLD_NUMBER)+ dtos( Daily->date) + str( Daily->recpt, 6         ) } ) )

      if empty( Daily->(OrdBagName('USETHIS')) )
         AppError(APP_ERR_TEMP_INDEXING5, {'Hmm-we have a problem!'})
      endif

      Daily->( OrdSetFocus('USETHIS') )

		Daily->(dbSetRelation( 'Grower', ;
		 { || str( Daily->number,FLD_GROWER) } ) )

      Daily->(dbGoTop())

		aRpt := {}
		rRcptQty( aRpt )
		rAdvPrInfo( aRpt )
		rFinPrInfo( aRpt )
      rDockage( aRpt, .t. )
      rDepotSite( aRpt )
		rVarietyEtc( aRpt )

      rProGradeEtc( aRpt )   // April 2019

      gRptInit( RP_DOCKAGE, aRpt)

		if lConfigure
			gRptSelect( aRpt )
		endif

      aTitle := {TheClientName( ), ;
        'From '+shMDY(dFrom)+' to '+shMDY(dTo)}
      MoreHead( aTitle, cProduct, cProcess, nGrower, '',cDepot )

      aadd( aTitle, 'Dockage Related Report' )

		gRptInitHead()
		gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

		gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
      gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| Daily->number} )
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
       {|| nuQprnOut( lstrim( Daily->number)+' '+NameOf(LU_GROWER, Daily->number )) } )

      gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL , .f.)

      if selectPrn('DOCKAGE.TXT')
			// For LandScape
			gRptAutoPageOrientation( aRpt, 0)

			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )


			Daily->(dbGoTop())
			Daily->(gRptPrinter( aRpt ))
			PRINT_OFF  RPT_COMPLETE_EJECT

			if lConfigure
				if yesno({'Save this Report Format?'})
					gRptSave( aRpt )
				endif
			endif
		endif

		Daily->(dbClearFilter())
		Daily->(dbClearRelation())
		Daily->(dbCloseArea())

		KillUnique(cUnique,'.CDX')

      if !openFile({"Daily"}, DB_SHARED)
         exit
      endif
	enddo
	kill window aWin
	close databases
RETURN( nil )

