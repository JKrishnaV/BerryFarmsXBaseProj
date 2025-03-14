// PROGRAM...: PriceAud.prg
// AUTHOR ...: Bill Hepler - Oct 2009
//  (c) 2009, 2013, 2021 by Bill Hepler
//   based on dAudit.prg
//   July 2013 - Depot stuff
//   May 2021 - added stuff to show the Keyed Price

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

function PriceAudit()
   local getList :={}, dFrom,dTo, nGrower, aWin
	local aTitle
	local aRpt
	local lConfigure := .f., lLegend := .f.
   local bFor
	local cProduct
	local cProcess
	local cDepot
   local cRpt := RP_PRICE_AUDIT
   local lError := .t.
   local n

	cProcess := space(FLD_PROCESS)
	cProduct := space(FLD_PRODUCT)
	cDepot   := space(FLD_DEPOT)

   dFrom := date() -31
   dTo   := date()

	nGrower := 0
	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

   myBsgScreen( 'Price Audit Report '+cRpt )
   create window at 4,08,21,70 title 'Price Audit' to aWin
	display window aWin

	do while .t.
		msgLine('[Esc] to Exit')
      in window aWin @ 2,2  winSAY 'Select a date range for the report:'
      in window aWin @ 3,02 winsay 'From  ' winget dFrom picture '@d' ;
		 get_message 'Starting Date for Report,  +/- to adjust'
      in window aWin @ 4,02 winSAY 'To    ' winget dTo picture '@d' ;
		 get_message 'Ending Date for Report, +/- to adjust'

      in window aWin @ 6,02 winsay 'Grower' winget nGrower ;
		 PICTURE numBlankPic(FLD_GROWER) ;
       valid PutName(aWin,6,20,LU_GROWER,nGrower)  ;
		 LOOKUP(LU_GROWER, ;
      'Input a Grower to look at one grower only,   [F5] to Browse Growers')

      in window aWin @ 8,02 winsay 'Product' winget cProduct picture '@!' ;
         valid putName(aWin,8,20,LU_PRODUCT,cProduct) ;
			lookup( LU_PRODUCT, ;
		'Enter a Product to restrict the report to a single product, blank for all')

      in window aWin @ 9,02 winsay 'Process' winget cProcess picture '@!' ;
         valid putName(aWin,9,20,LU_PROCESS_TYPE,cProcess) ;
			lookup( LU_PROCESS_TYPE, ;
		'Enter a Process to restrict the report to a single process, blank for all')

      in window aWin @10,02 winsay 'Depot  ' winget cDepot picture '@!' ;
         when PutName( aWin, 10, 20, LU_DEPOT, cDepot ) ;
         valid PutName( aWin, 10, 20, LU_DEPOT, cDepot ) ;
         LookUp( LU_DEPOT, 'Blank for All Depots - F5 to Browse' )

      in window aWin @12,02 winsay 'Include only Notable Receipts' winget lError ;
        picture 'Y' GET_MESSAGE  ;
        'Only show Transactions of note- e.g. Errors or Missing Prices'

      in window aWin @14,02 winsay 'Configure Report  ' winget lConfigure ;
		 picture 'Y'  GET_MESSAGE ;
		'You may select and order the columns to be printed'

		in window aWin @17,02 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

		read

		do case
		case lastkey()==K_ESC
			exit
		endcase

      aTitle := { TheClientName( )  }
      aadd(aTitle, cRpt+' Price Audit from '+shMDY(dFrom)+' to '+shMDY(dTo) )
      if !empty( cDepot )
      	n := len( aTitle )
			aTitle[n] += ' Depot='+cDepot
		endif
      MoreHead( aTitle, cProduct, cProcess, nGrower )

      if lError
         bFor   := { || !empty( Daily->product) .and. ;
                      Daily->date >= dFrom  .and. ;
                      Daily->date <= dTo .and. ;
                      InclPrdPrcGrDepo( cProduct, cProcess, nGrower, cDepot )  ;
                      .and. thePriceBad() }
      	aadd( aTitle, 'Shows only Receipts with Pricing Errors' )
      else
         bFor   := { || !empty( Daily->product) .and. ;
                      Daily->date >= dFrom  .and. ;
                      Daily->date <= dTo .and. ;
                      InclPrdPrcGrDepo( cProduct, cProcess, nGrower, cDepot )  }
      endif

      Daily->(OrdSetFocus( DAILY_GROWER_ORD))


      Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))
		Daily->(dbSetRelation( 'Grower', ;
		 { || str( Daily->number,FLD_GROWER) } ) )

		Daily->(dbGoTop())

		aRpt := {}

      rPricAud( aRpt )
      rDepotSite( aRpt )
		rVarietyEtc( aRpt )

      rAdvancesPd( aRpt )   // March 2019

      rFinPrInfo( aRpt )    // May 2021  - includes keyed price.

      gRptInit( cRpt, aRpt)

		if lConfigure
			gRptSelect( aRpt )
		endif

		gRptInitHead()
		gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

      gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
      gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| Daily->number } )
      gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
       {|| nuQprnOut( str( Daily->number,FLD_NUMBER)+' '+Grower->name ) } )

      gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL , .f.)

      gRptGetSetHead( RPT_HEAD_FOR_CONDITION , bFor )

      if selectPrn(cRpt+'.TXT')

         msgLine('Finding the Starting point...')

         Daily->(dbGoTop())
         do while  !Daily->(eof())
            showProg( str( Daily->number,FLD_GROWER)+' '+shMDY( Daily->date) )
            if Daily->( eval( bFor ))
               exit
            endif
            Daily->(dbSkip())
         enddo

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
	enddo

	kill window aWin
	close databases
RETURN( nil )

static function MoreHead( aTitle, cProduct, cProcess, nGrower)
	local cTemp

	cTemp := ''
	if !empty(cProduct)
      cTemp :=  'Berry='+alltrim( cProduct )
	endif

	if !empty(cProcess)
      cTemp :=  ' Process='+alltrim( cProcess)
	endif

   if nGrower > 0
      cTemp += ' Grower='+lStrim( nGrower)
   endif

   if !empty(cTemp)
      aadd( aTitle, alltrim(cTemp) )
	endif

return( nil )

static function thePriceBad()
   local lReturn := .t.

   if Daily->(fValidPrice())
      if str(Daily->( FinalPrice() ),12,3) <> str( 0, 12,3 )
         lReturn := .f.
      endif
   endif

return( lReturn )

function CheckKeyPrice()
   local getList :={}, dFrom,dTo, nGrower, aWin
	local aTitle
	local aRpt
	local lConfigure := .f., lLegend := .f.
   local bFor
	local cProduct
	local cProcess
	local cDepot
   local cRpt := RP_KEYED_PRICE_QUICK
   local lError := .t.
   local n

	cProcess := space(FLD_PROCESS)
	cProduct := space(FLD_PRODUCT)
	cDepot   := space(FLD_DEPOT)

   dFrom := date() -31
   dTo   := date()

	nGrower := 0
	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

   myBsgScreen( 'Quick Check Keyed Price Report '+cRpt )
   create window at 4,08,21,70 title 'Keyed Price Audit' to aWin
	display window aWin

	do while .t.
		msgLine('[Esc] to Exit')
      in window aWin @ 2,2  winSAY 'Select a date range for the report:'
      in window aWin @ 3,02 winsay 'From  ' winget dFrom picture '@d' ;
		 get_message 'Starting Date for Report,  +/- to adjust'
      in window aWin @ 4,02 winSAY 'To    ' winget dTo picture '@d' ;
		 get_message 'Ending Date for Report, +/- to adjust'

      in window aWin @ 6,02 winsay 'Grower' winget nGrower ;
		 PICTURE numBlankPic(FLD_GROWER) ;
       valid PutName(aWin,6,20,LU_GROWER,nGrower)  ;
		 LOOKUP(LU_GROWER, ;
      'Input a Grower to look at one grower only,   [F5] to Browse Growers')

      in window aWin @ 8,02 winsay 'Product' winget cProduct picture '@!' ;
         valid putName(aWin,8,20,LU_PRODUCT,cProduct) ;
			lookup( LU_PRODUCT, ;
		'Enter a Product to restrict the report to a single product, blank for all')

      in window aWin @ 9,02 winsay 'Process' winget cProcess picture '@!' ;
         valid putName(aWin,9,20,LU_PROCESS_TYPE,cProcess) ;
			lookup( LU_PROCESS_TYPE, ;
		'Enter a Process to restrict the report to a single process, blank for all')

      in window aWin @10,02 winsay 'Depot  ' winget cDepot picture '@!' ;
         when PutName( aWin, 10, 20, LU_DEPOT, cDepot ) ;
         valid PutName( aWin, 10, 20, LU_DEPOT, cDepot ) ;
         LookUp( LU_DEPOT, 'Blank for All Depots - F5 to Browse' )

      in window aWin @12,02 winsay 'Include only Notable Receipts' winget lError ;
        picture 'Y' GET_MESSAGE  ;
        'Only show Transactions of note- e.g. Errors or No Keyed price'

      in window aWin @14,02 winsay 'Configure Report  ' winget lConfigure ;
		 picture 'Y'  GET_MESSAGE ;
		'You may select and order the columns to be printed'

		in window aWin @17,02 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

		read

		do case
		case lastkey()==K_ESC
			exit
		endcase

      aTitle := { TheClientName( )  }
      aadd(aTitle, cRpt+' Quick Keyed Prices from '+shMDY(dFrom)+' to '+shMDY(dTo) )
      if !empty( cDepot )
      	n := len( aTitle )
			aTitle[n] += ' Depot='+cDepot
		endif
      MoreHead( aTitle, cProduct, cProcess, nGrower )

      if lError
         bFor   := { || !empty( Daily->product) .and. ;
                      Daily->date >= dFrom  .and. ;
                      Daily->date <= dTo .and. ;
                      InclPrdPrcGrDepo( cProduct, cProcess, nGrower, cDepot )  ;
                      .and. num3Equal0( Daily->thePrice ) }
      	aadd( aTitle, 'Shows only Receipts MISSING Keyed in Prices' )

      else
         bFor   := { || !empty( Daily->product) .and. ;
                      Daily->date >= dFrom  .and. ;
                      Daily->date <= dTo .and. ;
                      InclPrdPrcGrDepo( cProduct, cProcess, nGrower, cDepot )  }
      endif

      Daily->(OrdSetFocus( DAILY_GROWER_ORD))

      Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))
		Daily->(dbSetRelation( 'Grower', ;
		 { || str( Daily->number,FLD_GROWER) } ) )

		Daily->(dbGoTop())

		aRpt := {}

      rPricAud( aRpt )
      rDepotSite( aRpt )
		rVarietyEtc( aRpt )
      rAdvancesPd( aRpt )

      rFinPrInfo( aRpt )    // May 2021  - includes keyed price.

      gRptInit( cRpt, aRpt)

		if lConfigure
			gRptSelect( aRpt )
		endif

		gRptInitHead()
		gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

      gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
      gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| Daily->number } )
      gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
       {|| nuQprnOut( str( Daily->number,FLD_NUMBER)+' '+Grower->name ) } )

      gRptGetSetHead( RPT_HEAD_SUBSUBTOTAL , .f.)

      gRptGetSetHead( RPT_HEAD_FOR_CONDITION , bFor )

      if selectPrn(cRpt+'.TXT')

         msgLine('Finding the Starting point...')

         Daily->(dbGoTop())
         do while  !Daily->(eof())
            showProg( str( Daily->number,FLD_GROWER)+' '+shMDY( Daily->date) )
            if Daily->( eval( bFor ))
               exit
            endif
            Daily->(dbSkip())
         enddo

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
	enddo

	kill window aWin
	close databases
RETURN( nil )

// The Quick and Dirty Version

function QuikNoKeyPrice( cPayType, nAdvance, dFrom, dTo, cProduct, cProcess, nGrower, cDepot )
	local aTitle
   local n
   local bFor
   local aDBF
   local aRay := {}
	local lReturn := .t.

   aTitle := { TheClientName( )  }
   aadd(aTitle, RP_KEYED_PRICE_QUICK+' Quick Keyed Prices from '+shMDY(dFrom)+' to '+shMDY(dTo) )

   if !empty( cDepot )
     	n := len( aTitle )
		aTitle[n] += ' Depot='+cDepot
	endif
   MoreHead( aTitle, cProduct, cProcess, nGrower )

	bFor   := { || !empty( Daily->product) .and. ;
                  Daily->date >= dFrom  .and. ;
                  Daily->date <= dTo .and. ;
                  InclPrdPrcGrDepo( cProduct, cProcess, nGrower, cDepot )  ;
                      .and. num3Equal0( Daily->thePrice ) }

   aadd( aTitle, 'Shows only Receipts MISSING Keyed in Prices' )

   aDBF := Daily->(saveDBF())

   Daily->(dbGoTop())
   n := 0
   do while  !Daily->(eof())
		n++
      if n % 100 == 0
      	showProg( str( n, 8))
      endif

		if ForPayType( cPayType, nAdvance )   // if it is already paid out we do NOT care!
			if Daily->( eval( bFor ))
				if len( aRay ) == 0
					aadd( aRay,  {'Grow #',                       ;
									  padr( 'Grower Name', 30),       ;
									 'Depot',                         ;
									 padl('Receipt', FLD_RECPT+1),    ;
									 padr('Date',12),                 ;
									 'Prod',                          ;
									 'Proc',                          ;
									 'Gr',                            ;
									 padl('Weight',10),               ;
                            padl('Price',7)          }  )

				endif

				aadd( aRay, { str( Daily->number, 6),                        ;
								  padr( NameOf( LU_GROWER, Daily->Number ), 30), ;
								  padr( Daily->depot,5),                         ;
								  str( Daily->recPt, FLD_RECPT+1),               ;
								  padr( shMdy( Daily->date), 12),                ;
								  padr(Daily->product,4),                        ;
								  padr(Daily->process,4),                        ;
								  str(Daily->grade,2),                           ;
								  str(Daily->net,10 ),                           ;
                          str(Daily->thePrice,7,2)    } )
			endif
      endif
      Daily->(dbSkip())
   enddo

   Daily->(restDBF( aDBF ))

	if len( aRay ) >= 1
		WinArrayVu( aRay,'Receipts with NO keyed Price', .t.)
		lReturn := .f.
	endif

return( lReturn )


static function ForPayType( cPayType, nAdvNo )
	local lReturn := .t.

	if empty( Daily->product)
   	lReturn := .f.
   else
      do case
      case cPayType == CHEQUE_TYPE_WEEKLY
         do case
         case Daily->fin_bat >= 1
            lReturn := .f.
         case nAdvNo == 1
            if num2NotEqual0( Daily->post_bat1 ) .or. ;
               num2NotEqual0( Daily->post_bat2 ) .or. ;
               num2NotEqual0( Daily->post_bat3 )
               lReturn := .f.
            endif
         case nAdvNo == 2
            if num2NotEqual0( Daily->post_bat2 ) .or. ;
               num2NotEqual0( Daily->post_bat3 )
               lReturn := .f.
            endif
         case nAdvNo == 3
            if num2NotEqual0( Daily->post_bat3 )
               lReturn := .f.
            endif
         endcase

      case cPayType == CHEQUE_TYPE_FINAL
         if num2NotEqual0( Daily->fin_bat )
            lReturn := .f.
         endif
      endcase
	endif

return( lReturn )
