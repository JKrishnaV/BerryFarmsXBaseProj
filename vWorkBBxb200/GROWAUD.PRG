// PROGRAM...: GrowAUD.PRG
// AUTHOR ...: Bill Hepler July 2007
//   based on dAudit.prg
// Revised June 2011 - Landscape etc..
// Revised July 2011 - Fixed the Filtering
// April 2019 - Add Grade Name


#include 'inkey.ch'
#include 'BerryPay.ch'
#include 'window.ch'
#include 'printer.ch'
#include 'bsgstd.ch'
#include 'valid.ch'
#include 'rpt.ch'
#include 'berry_rpt.ch'
#include "field.ch"
#include "indexord.ch"
#include 'combobox.ch'
#include 'sysvalue.ch'

function GrowRecRpt( cRpt )
	local getList :={}, dFrom,dTo, nGrower, aWin, nValue := 1
	local cDepot
	local aTitle
	local cDW
	local aRpt
	local lConfigure := .f.
	local aCombo
	local bFor
	local cProduct
	local cProcess
   local aBot[2]
   local n
   local lLegend := .f.

   aFill( aBot, space( 40 ) )

	cProcess := space(FLD_PROCESS)
	cProduct := space(FLD_PRODUCT)
   cDepot   := space(FLD_DEPOT)

   dFrom := date() -8
   dTo   := date() -1
   cDW   := 'Grower Report '+cRpt

	nGrower := 0
	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

	myBsgScreen( cDW+' Audit Report' )

   create window at 4,08,22,70 title cDW to aWin
	display window aWin

   IN WINDOW aWin CREATE COMBOBOX AT 17,02 ;
           WINSAY 'Report on' USING { ;
		'UnPosted Receipts Only', ;
		'Posted (paid) Only    ', ;
		'Both Posted & Unposted' }   ;
	 MESSAGE ;
	 'Posted transactions are (almost always) paid - and can not be edit' ;
	  TO aCombo

	ComboBoxShow( aCombo,  nValue )

	do while .t.
   	lLegend := .f.                 // this report often goes to Growers !

		msgLine('[Esc] to Exit')
      in window aWin @ 1,2  winSAY 'Select a date range for the report:'
      in window aWin @ 2,2 winsay 'From  ' winget dFrom picture '@d' ;
		 get_message 'Starting Date for Report,  +/- to adjust'
      in window aWin @ 3,2 winSAY 'To    ' winget dTo picture '@d' ;
		 get_message 'Ending Date for Report, +/- to adjust'

      in window aWin @ 5,2 winsay 'Grower' winget nGrower ;
		 PICTURE numBlankPic(FLD_GROWER) ;
       valid PutName(aWin,5,20,LU_GROWER,nGrower) .and. ;
       validTest(V_GROWER, nGrower, VT_BROWSE)     ;
		 LOOKUP(LU_GROWER, ;
      'Select a specific Grower,   [F5] to Browse Growers')

      in window aWin @ 7,2 winsay 'Product' winget cProduct picture '@!' ;
         valid putName(aWin,7,20,LU_PRODUCT,cProduct) ;
			lookup( LU_PRODUCT, ;
		'Enter a Product to restrict the report to a single product, blank for all')

      in window aWin @ 8,2 winsay 'Process' winget cProcess picture '@!' ;
         valid putName(aWin,8,20,LU_PROCESS_TYPE,cProcess) ;
			lookup( LU_PROCESS_TYPE, ;
		'Enter a Process to restrict the report to a single process, blank for all')

      in window aWin @10,02 winsay 'Depot ' winget cDepot picture '@!' ;
         when PutName( aWin, 10, 11, LU_DEPOT, cDepot ) ;
         valid PutName( aWin, 10, 11, LU_DEPOT, cDepot ) ;
         LookUp( LU_DEPOT, 'Blank for All Depots - F5 to Browse' )

      in window aWin @12,02 winsay 'Msg 1' winget aBot[1] ;
         GET_MESSAGE  'Enter a message to Print on this report'
      in window aWin @13,02 winsay 'Msg 2' winget aBot[2] ;
         GET_MESSAGE  'You may enter 2 lines to print on this report'

      in window aWin @15,02 winsay 'Configure Report' winget lConfigure ;
		 picture 'Y'  GET_MESSAGE ;
		'You may select and order the columns to be printed'

		in window aWin @ 16,02 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

		read

		do case
		case lastkey()==K_ESC
			exit
      case nGrower == 0
         waitInfo({'You must run this for ONE grower!'})
			loop
      case lLegend
      	if !Yesno({'You have selected to Show the Legend',                         ;
                    'This is a valid option - but is usually used when you',        ;
                    'are experimenting with a report format - we do not reccomend', ;
                    'sending reports to customer with the Legend showing', '',      ;
                    'Do you wish to continue?'} )
            loop
         endif
		endcase

		nValue := ComboBoxDo( aCombo,  nValue )

      aTitle := { TheClientName( ), ;
                  cDW+' Grower='+lStrim(nGrower), ;
                  alltrim(NameOf( LU_GROWER, nGrower)) }

		do case
		case lastkey()==K_ESC .or. nValue == 0
			loop
		case nValue == 1
			aadd(aTitle,'Unposted Transactions')

         bFor   := { || Daily->Post_bat1==0 .and. Daily->fin_bat==0 .and. ;
             GrowAudPP( cProduct, cProcess, cDepot )}

		case nValue == 2
			aadd( aTitle,'Posted Transactions Only')
         bFor   := { || (Daily->Post_bat1<>0 .or. Daily->fin_bat<>0) .and. ;
                           GrowAudPP( cProduct, cProcess, cDepot ) }

      case nValue == 3
			aadd( aTitle,'Posted & Unposted Transactions' )

         bFor   := { || GrowAudPP( cProduct, cProcess, cDepot )  }

      endcase

      msgLine('Selecting records to print....')
      Daily->(dbClearFilter())
      Daily->(dbClearRelation())
      inkey( 1 )

      Daily->(OrdSetFocus( DAILY_GROWER_ORD))
      Daily->(dbSeek( str(nGrower,FLD_GROWER)+dtos(dFrom), SOFTSEEK))

      Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))
		Daily->(dbSetRelation( 'Grower', ;
		 { || str( Daily->number,FLD_GROWER) } ) )

		aadd(aTitle, 'From '+shMDY(dFrom)+' to '+shMDY(dTo) )

		n := len( aTitle )
		if !empty( cDepot )
			aadd( aTitle, ' Depot='+cDepot )
      endif
      Daily->( DbSetFilter( bFor ))

      Daily->(OrdSetFocus( DAILY_GROWER_ORD))
      Daily->(dbSeek( str(nGrower,FLD_GROWER)+dtos(dFrom), SOFTSEEK))

      if Daily->number <> nGrower .or. Daily->date > dTo .or. Daily->(eof())
      	waitInfo({'Can not find information which matches!'})
      	loop
      endif

		aRpt := {}

      rRcptQty( aRpt )
		rAdvPrInfo( aRpt )
      rFinPrInfo( aRpt )

      rOutConCols( aRpt, .f.  )
		rInConCols( aRpt, .f. )
		rRawConCols( aRpt )

      aadd( aRpt, { 'St', ;
          { || iif(Daily->post_bat1==0,"U" ,"P" ) },"C", 2, 000, .t., .f., ;
			 'Status - P=Posted, U=Unposted Receipt' } )

		rDepotSite( aRpt )
		rRcptNotes( aRpt )   // July 29 2014
		rVarietyEtc( aRpt )  // June 2015
      rProGradeEtc( aRpt ) // April 2019

      gRptInit( cRpt, aRpt)

		if lConfigure
			gRptSelect( aRpt )
		endif

      MoreHead( aTitle, cProduct, cProcess )

		gRptInitHead()
		gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

		gRptGetSetHead( RPT_HEAD_WHILE_CONDITION, ;
			 { || Daily->number == nGrower .and. Daily->date <= dTo } )

      if selectPrn(cRpt+'.TXT')

			// For LandScape
			gRptAutoPageOrientation( aRpt, 0)

			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

			Daily->(gRptPrinter( aRpt ))

         if NearPageBottom( 10 )
            nuFormFeed()
            for n := 1 to len( aTitle)
               nuQPrnOut( padc( aTitle[n], 70 ) )
            next
            nuQprnOut()
            nuQprnOut()
         endif
         nuQprnOut()
         for n := 1 to len( aBot )
            if !empty(aBot[n])
               nuQprnOut( '    '+aBot[n] )
            endif
         next
         nuQprnOut()
         PRINT_OFF  RPT_COMPLETE_EJECT

			if lConfigure
				if yesno({'Save this Report Format?'})
					gRptSave( aRpt )
				endif
			endif
		endif

		Daily->(dbClearFilter())
      Daily->(dbClearRelation())
	enddo

	ComboBoxKill( aCombo )
	kill window aWin
	close databases
RETURN( nil )

static function MoreHead( aTitle, cProduct, cProcess)
	local cTemp

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

return( nil )

function GrowAudPP( cProduct, cProcess, cDepot )
   local lReturn := .t.

   if !empty( cProduct )
      if !(cProduct==Daily->product)
         lReturn := .f.
      endif
   endif

   if !empty( cProcess )
      if !(cProcess==Daily->process)
         lReturn := .f.
      endif
   endif

   if !empty( cDepot )
      if !(cDepot==Daily->depot)
         lReturn := .f.
      endif
   endif

return( lReturn )
