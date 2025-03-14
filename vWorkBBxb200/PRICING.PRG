// pricing.prg
// June 12, 1994
// Sets Prices for various Dates
//        totally revised May 99
// -------------- Note that the Final Price Includes the advance
//                price paid out !! -----------------------------------

// July 2001 added MORE prices...
// Nov  2001 can now pay advance 2 and 3
//           better checking on sum of Advances + Final
// June 2007 - Fixed up FIELD NAMES to be more systematic.
// Aug 3, 2012 - bug for US prices
// April 2020 - tidy up
// May 2020 - uniques etc.

#Include "BerryPay.ch"
#include "browser.ch"
#include "bsgstd.ch"
#include "common.ch"
#include "errors.ch"
#include "field.ch"
#include "indexord.ch"
#include "inkey.ch"
#include "openfile.ch"
#include "price.ch"
#include "printer.ch"
#include "set.ch"
#include "sysvalue.ch"
#include "Unique_Fields.ch"
#include "valid.ch"
#include "window.ch"

function Pricing()
   local oTb

   waitInfo({'All products must have price record before they can be posted.', ;
             'You do not need to set prices until you are ready to pay them', ;
             '', ;
             'Prices for Subsequent advances must be larger than previous', ;
             'advances - meaning prices shown are CUMULATIVE.  For example,', ;
             ' 1st Advance = 0.40 cents', ;
             ' 2nd Advance = 0.65 cents - (actual advance = 25 cents)', ;
             ' 3rd Advance = 1.00 dollar - (this advance = 35 cents)', ;
             ' Final Price = 1.28  (last payout will be 28 cents'})

	if !openfile({'Price','Product','Process','CounterIDs'} ,DB_SHARED)
		close databases
		return( nil )
	endif

	msgLine( ;
	'Editing Prices - [INS] = add, [DEL] = delete,  [F4] = Change Sort Order')

	Price->(dbGoTop())
	if Price->(eof())

		PriceAdd()

	endif

	oTb := tBrowCreate(7,3,18,76)

	tbMainCfg( oTb, CB_ALLOW_EDIT, .f.)
	tbMainCfg( oTb, CB_NEED_LOCKS, .f.)
	tbMainCfg( oTb, CB_TITLE, 'Set Pricing')

	tbKeyCfg( oTb, { K_DEL, {|| Price->(DeleteIt()) } } )

	tbKeyCfg( oTb, { K_INS, {|| PriceAdd() } } )

	tbKeyCfg( oTb, { K_ENTER, {|| PriceEdit() } } )
	tbKeyCfg( oTb, { K_F2,    {|| PriceEdit() } } )
	tbKeyCfg( oTb, { K_F4,    {|| IndOrd() } } )

	tbColAdd( oTb, tbcolCreate('ID',{ || str(Price->PriceID,FLD_DOCUMENT) } ))

	tbColAdd( oTb, tbcolCreate('From',{ || shMDY(Price->from) } ))
	tbColAdd( oTb, tbcolCreate('Berry',{ || Price->product } ))
	tbColAdd( oTb, tbcolCreate('Pro',{ || Price->process } ))

	tbColAdd( oTb, tbcolCreate('Prem.',{ || Price->time } ))

	if sysValue(SYS_ALLOW_CANADIAN_DOLLARS)
		tbColAdd( oTb, tbcolCreate('C-Prm',{ || str(Price->cPremium,5,2) } ))
	endif

	if sysValue(SYS_ALLOW_US_DOLLARS)
		tbColAdd( oTb, tbcolCreate('U-Prm',{ || str(Price->uPremium,5,2) } ))
	endif

	// Grades
	if sysValue(SYS_ALLOW_CANADIAN_DOLLARS)
      tbColAdd( oTb, tbcolCreate('CAD1 Gr1',{ || Price->cL1G1A1 } ))
      tbColAdd( oTb, tbcolCreate('CAD1 Gr2',{ || Price->cL1G2A1 } ))
      tbColAdd( oTb, tbcolCreate('CAD1 Gr3',{ || Price->cL1G3A1 } ))

      tbColAdd( oTb, tbcolCreate('CAD2 Gr1',{ || Price->cL2G1A1 } ))
      tbColAdd( oTb, tbcolCreate('CAD2 Gr2',{ || Price->cL2G2A1 } ))
      tbColAdd( oTb, tbcolCreate('CAD2 Gr3',{ || Price->cL2G3A1 } ))

      tbColAdd( oTb, tbcolCreate('Cfi1 Gr1',{ || Price->cL1G1FN } ))
      tbColAdd( oTb, tbcolCreate('Cfi1 Gr2',{ || Price->cL1G2FN } ))
      tbColAdd( oTb, tbcolCreate('Cfi1 Gr3',{ || Price->cL1G3FN } ))

      tbColAdd( oTb, tbcolCreate('Cfi2 Gr1',{ || Price->cL2G1FN } ))
      tbColAdd( oTb, tbcolCreate('Cfi2 Gr2',{ || Price->cL2G2FN } ))
      tbColAdd( oTb, tbcolCreate('Cfi2 Gr3',{ || Price->cL2G3FN } ))

	endif

	if sysValue(SYS_ALLOW_US_DOLLARS)
      tbColAdd( oTb, tbcolCreate('uAD1 Gr1',{ || Price->uL1G1A1 } ))
      tbColAdd( oTb, tbcolCreate('uAD1 Gr2',{ || Price->uL1G2A1 } ))
      // tbColAdd( oTb, tbcolCreate('uAD1 Gr3',{ || Price->uLlG3A1 } ))
		tbColAdd( oTb, tbcolCreate('uAD1 Gr3',{ || Price->uL1G3A1 } ))

      tbColAdd( oTb, tbcolCreate('uAD2 Gr1',{ || Price->uL2G1A1 } ))
      tbColAdd( oTb, tbcolCreate('uAD2 Gr2',{ || Price->uL2G2A1 } ))
      tbColAdd( oTb, tbcolCreate('uAD2 Gr3',{ || Price->uL2G3A1 } ))

      tbColAdd( oTb, tbcolCreate('Ufi1 Gr1',{ || Price->uL1G1FN } ))
      tbColAdd( oTb, tbcolCreate('Ufi1 Gr2',{ || Price->uL1G2FN } ))
      // tbColAdd( oTb, tbcolCreate('Ufi1 Gr3',{ || Price->uLlG3FN } ))
      tbColAdd( oTb, tbcolCreate('Ufi1 Gr3',{ || Price->uL1G3FN } ))

      tbColAdd( oTb, tbcolCreate('Ufi2 Gr1',{ || Price->uL2G1FN } ))
      tbColAdd( oTb, tbcolCreate('Ufi2 Gr2',{ || Price->uL2G2FN } ))
      tbColAdd( oTb, tbcolCreate('Ufi2 Gr3',{ || Price->uL2G3FN } ))
   endif

	Price->(dbGoTop())
   if Price->(eof())
      if yesno({'No pricing on file - add new?'})
         PriceAdd()
      endif
   endif

   if Price->(eof())
      waitInfo({'No Prices on File - Bye!'})
   else
      Price->(theBrowse( oTb ))
   endif

return( nil )


static function IndOrd(  )
	// Change Index Order
	local nOldOrd, nOrd, aScrn
	local aRay, aOrd
	local n

	aOrd := {}
	aRay := FileArray('Price')
	aSize( aOrd, len( aRay[ OPEN_INDEX_INFO] ) + 1 )

	for n :=1 to len( aRay[ OPEN_INDEX_INFO] )
		// seems to be a bug here, that makes it so I must do this...
		aOrd[ n ] :=  padr( aRay[ OPEN_INDEX_INFO, n, OI_DESCRIPTION ], 40)
	next
	aOrd[ len(aOrd) ] := padr( 'Physical File Order',40)

   nOldOrd := Price->(IndexOrd())

	nOldOrd := iif(nOldOrd == 0, len(aOrd), nOldOrd)

	aScrn := save_scr(5,10,maxRow(),maxCol())
	nOrd := bsgMenu(nOldOrd, 'Select Order', 8,18, aOrd)
   rest_scr(aScrn)

	do case
	 case lastkey()==K_ESC
		nOrd := nOldOrd
	 case nOrd == len(aOrd)
	 	nOrd := 0
	endcase

   Price->(OrdSetFocus(nOrd))

return( SIG_FORCE_REDRAW )

static function PriceAdd()
	local getList := {}
	local aW
	local cProduct,cProcess,dFrom
	local nPriceID

   create window at 5,16,15,64 title 'Set Price' to aW
	display window aW
	set cursor on

	in window aW @ 6,2 winsay 'Use this screen to set up new Prices'

   if sysValue( SYS_SET_ADVANCES_BY_PROCESS_ONLY )
      in window aW @ 8,2 winsay 'You may set up prices for a Process ONLY'
      in window aW @ 9,2 winsay 'This can be helpful for quickly setting'
      in window aW @10,2 winsay 'advance prices. This capability is controlled'
      in window aW @11,2 winsay 'by a System Value.'
   else
      in window aW @ 8,2 winsay 'You may set up prices for a Product+Process'
      in window aW @ 9,2 winsay 'combination ONLY.  This capability is'
      in window aW @10,2 winsay 'controlled by a System Value.'
   endif

	cProduct := space(FLD_PRODUCT)
	cProcess := space(FLD_PROCESS)
	dFrom    := date()

	do while .t.
      if sysValue( SYS_SET_ADVANCES_BY_PROCESS_ONLY )
         in window aW @ 2,2 winsay 'Product ID ' winget cProduct ;
             picture "@!" valid ;
             (empty( cProduct) .or. validTest(V_PRODUCT,cProduct,VT_BROWSE)) ;
             .and. ;
             PutName(aW,2,20, LU_PRODUCT, cProduct)  ;
            lookup( LU_PRODUCT, 'Enter Product ID - [F5] to Browse')
      else
         in window aW @ 2,2 winsay 'Product ID ' winget cProduct ;
             picture "@!" valid ;
            validTest(V_PRODUCT,cProduct,VT_BROWSE) .and. ;
             PutName(aW,2,20, LU_PRODUCT, cProduct)  ;
            lookup( LU_PRODUCT, 'Enter Product ID - [F5] to Browse')
      endif

		in window aW @ 3,2 winsay 'Process ID ' winget cProcess ;
			 picture "@!"  valid ;
			validTest(V_PROCESS_TYPE,cProcess,VT_BROWSE) .and. ;
			 PutName(aW,3,20, LU_PROCESS_TYPE, cProcess)   ;
			lookup( LU_PROCESS_TYPE, 'Enter Process Type - [F5] to Browse')

		in window aW @ 4,2 winsay 'Dated after' winget dFrom ;
			picture '@D' ;
			valid !empty(dFrom) ;
			get_message 'Goods received ON or AFTER this date are set to this price'
		read

		do case
		case lastkey()==K_ESC
			exit
      case empty(cProduct) .and. ;
			  ValidTest(V_PROCESS_TYPE,cProcess,VT_MESSAGE) .and. ;
           !empty(dFrom) .and. sysValue( SYS_SET_ADVANCES_BY_PROCESS_ONLY )

         Price->(OrdSetFocus(PRICE_PRODUCT_ORD))
         if Price->(dbSeek( space(FLD_PRODUCT)+cProcess+dtos(dFrom)))
				PriceEdit()
			else
				if Yesno({ 'Nothing found for this date', ;
                       'Set up new price for process '+cProcess+'?'} )

					if Price->(fileLock())
                  Price->(OrdSetFocus( PRICE_PRICE_ID_ORD ))
						Price->(dbGoBottom())
						nPriceID := Price->PriceID +1
						if nPriceID <= 0
							nPriceID := 1
						endif
						Price->(addRecord())

						Price->PriceID := nPriceID  // June 2000

						Price->product := cProduct
						Price->process := cProcess
						Price->from    := dFrom
						Price->(dbCommit())
						Price->(dbUnlock())

						PriceEdit()
					endif
				endif
			endif

      case ValidTest(V_PRODUCT,cProduct,VT_MESSAGE) .and. ;
			  ValidTest(V_PROCESS_TYPE,cProcess,VT_MESSAGE) .and. ;
			  !empty(dFrom)

         Price->(OrdSetFocus(PRICE_PRODUCT_ORD))
			if Price->(dbSeek( cProduct+cProcess+dtos(dFrom)))
				PriceEdit()
			else
				if Yesno({ 'Nothing found for this date', ;
						     'Set up new price?'} )

					if Price->(fileLock()) .and. CounterIDs->(fileLock())
						nAddUniqueRec( UF_THE_PRICE_ID , UNIQ_FILE_DO_NOT_NEED_LOCKS )

						Price->product := cProduct
						Price->process := cProcess
						Price->from    := dFrom
						Price->(dbCommit())
						Price->(dbUnlock())

						PriceEdit()
					endif

				endif
			endif

      otherwise
			loop
		endcase
	enddo

	kill window aW

return( SIG_FORCE_REDRAW )


static function PriceEdit()
	local getList := {}
	local lRead := .t.
	local aW
	local lAdvance,lAdvance2, lAdvance3, lFinal
	local lFirst := .t.
	local bF1
	local aRay := {}
   local nGrade, nLevel
   local lError

	if !Price->(recLock())
		return( SIG_FORCE_REDRAW )
	endif

   lAdvance  := Price->adv1_used
	lAdvance2 := Price->adv2_used
	lAdvance3 := Price->adv3_used
	lFinal    := Price->fin_used

	create window at 2,03,22,77 ;
		 title 'Set Price for ID# '+lStrim(Price->PriceID) to aW
	display window aW

	if lAdvance
		aadd( aRay,'1st Advance Payment made using these prices')
	endif
	if lAdvance2
		aadd( aRay,'2nd Advance Payment made using these prices')
	endif
	if lAdvance3
		aadd( aRay,'3rd Advance Payment made using these prices')
	endif
	if lFinal
		aadd( aRay,'Final Payment made using these prices')
	endif

	if len(aRay) >=1
      waitInfo(aRay)
      if yesno({'In spite of this you may allow editing of advance', ;
                'rates.  Do this only if you REALLY need to, as', ;
                'it can cause real confusion.','', ;
                'Do you want to be able to Edit Previously Paid', ;
                'Advance Rates??' } )
         if yesno({'Are you sure you want to edit these', ;
           'Previously paid rates?'})
            lAdvance  := .f.
            lAdvance2 := .f.
            lAdvance3 := .f.
         endif
      endif
	endif

	in window aW @ 5,50 winsay ;
		 'Final Prices s.b. EQUAL'
	in window aW @ 6,50 winsay ;
		 'TO or MORE than Advances'
	in window aW @ 7,50 winsay ;
		 '--- [ F1 ] More Info ---'
	set cursor on

	bF1 := setKey( K_F1, { || PriceHelp() } )

	do while .t.
		PutName(aW,2,30, LU_PRODUCT, Price->Product)
		PutName(aW,3,30, LU_PROCESS_TYPE, Price->Process)

		in window aW @ 2,2 winsay 'Product ID  '+' '+ Price->product
		in window aW @ 3,2 winsay 'Process Type'+' '+ Price->process
		in window aW @ 4,2 winsay 'Date on/aft '+' '+ shMDY(price->from)

		// This is EXTRA Money...Not included in the Advance & Final
		in window aW @ 6,2 winsay 'Pay Time Based Premium' ;
			 winget price->timeprem picture 'Y' ;
			 get_message ;
           'Add Premium Bonus on 1st Advance Payment' + ;
			  'for deliveries on or before a time'

		in window aW @ 7,2 winsay 'Up to' winget price->time ;
			 picture '99:99' ;
			 when Price->timeprem ;
			 valid !empty(Price->time) ;
			 get_message ;
			  'Growers recieve a time based bonus for berries received on/before this'

		if sysValue(SYS_ALLOW_CANADIAN_DOLLARS)
			in window aW @ 6,30 winsay 'Can $' winget price->cPremium ;
				 picture '99.99' ;
				 when Price->timeprem ;
				 valid !empty(Price->time) ;
				 get_message ;
			  'This is EXTRA money above the regular Advance + Final Payment'
		endif

		if sysValue(SYS_ALLOW_US_DOLLARS)
			in window aW @ 7,30 winsay 'U.S.$' winget price->uPremium ;
				 picture '99.99' ;
				 when Price->timeprem ;
				 valid !empty(Price->time) ;
				 get_message ;
			  'This is EXTRA money above the regular Advance + Final Payment'
		endif


		if sysValue(SYS_ALLOW_CANADIAN_DOLLARS)
			in window aW @09,2  winsay 'Canadian Price Advances -> Final'

         in window aW @10,3  winsay 'Gr 1' winget price->cL1G1A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
			  'Advance Price/LB for Level 1, Grade 1'

         in window aW @10,15  winget price->cL1g1A2 ;
             picture '99.99' when !lAdvance2 get_message ;
			  '2nd Advance Price/LB for Level 1, Grade 1'

         in window aW @10,22 winget price->cL1g1A3 ;
             picture '99.99' when !lAdvance3 get_message ;
			  '3rd Advance Price/LB for Level 1, Grade 1'

         in window aW @10,29 winget price->cL1g1Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 1, 1, .t. ) ;
              get_message ;
			  'Total Final Price/LB for Level 1, Grade 1 (including all Advances)'

         in window aW @11,3  winsay 'Gr 2' winget price->cL1G2A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 1, Grade 2'

         in window aW @11,15  winget price->cL1g2A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 1, Grade 2'

         in window aW @11,22 winget price->cL1g2A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 1, Grade 2'

         in window aW @11,29 winget price->cL1g2Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 1, 2, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 1, Grade 2 (including all Advances)'

         in window aW @12,3  winsay 'Gr 3' winget price->cL1G3A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 1, Grade 3'

         in window aW @12,15  winget price->cL1g3A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 1, Grade 3'

         in window aW @12,22 winget price->cL1g3A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 1, Grade 3'

         in window aW @12,29 winget price->cL1g3Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 1, 3, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 1, Grade 3 (including all Advances)'

			in window aW @13,2  winsay 'Level 2-'
         // 14
         in window aW @14,3  winsay 'Gr 1' winget price->cL2G1A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 2, Grade 1'

         in window aW @14,15  winget price->cL2g1A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 2, Grade 1'

         in window aW @14,22 winget price->cL2g1A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 2, Grade 1'

         in window aW @14,29 winget price->cL2g1Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 2, 1, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 2, Grade 1 (including all Advances)'

         in window aW @15,3  winsay 'Gr 2' winget price->cL2G2A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 2, Grade 2'

         in window aW @15,15  winget price->cL2g2A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 2, Grade 2'

         in window aW @15,22 winget price->cL2g2A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 2, Grade 2'

         in window aW @15,29 winget price->cL2g2Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 2, 2, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 2, Grade 2 (including all Advances)'

         in window aW @16,3  winsay 'Gr 3' winget price->cL2G3A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 2, Grade 3'

         in window aW @16,15  winget price->cL2g3A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 2, Grade 3'

         in window aW @16,22 winget price->cL2g3A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 2, Grade 3'

         in window aW @16,29 winget price->cL2g3Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 2, 3, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 2, Grade 3 (including all Advances)'

         in window aW @17,2  winsay 'Level 3-'
         in window aW @18,3  winsay 'Gr 1' winget price->cL3G1A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 3, Grade 1'

         in window aW @18,15  winget price->cL3g1A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 3, Grade 1'

         in window aW @18,22 winget price->cL3g1A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 3, Grade 1'

         in window aW @18,29 winget price->cL3g1Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 3, 1, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 3, Grade 1 (including all Advances)'

         in window aW @19,3  winsay 'Gr 2' winget price->cL3G2A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 3, Grade 2'

         in window aW @19,15  winget price->cL3g2A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 3, Grade 2'

         in window aW @19,22 winget price->cL3g2A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 3, Grade 2'

         in window aW @19,29 winget price->cL3g2Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 3, 2, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 3, Grade 2 (including all Advances)'

         in window aW @20,3  winsay 'Gr 3' winget price->cL3G3A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 3, Grade 3'

         in window aW @20,15  winget price->cL3g3A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 3, Grade 3'

         in window aW @20,22 winget price->cL3g3A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 3, Grade 3'

         in window aW @20,29 winget price->cL3g3Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 3, 3, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 3, Grade 3 (including all Advances)'
      endif

		if sysValue(SYS_ALLOW_US_DOLLARS)
			in window aW @09,38  winsay 'US Prices Advances to -> Final'

         in window aW @10,43  winsay 'Gr 1' winget price->uL1G1A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
			  'Advance Price/LB for Level 1, Grade 1'

         in window aW @10,55  winget price->uL1g1A2 ;
             picture '99.99' when !lAdvance2 get_message ;
			  '2nd Advance Price/LB for Level 1, Grade 1'

         in window aW @10,62 winget price->uL1g1A3 ;
             picture '99.99' when !lAdvance3 get_message ;
			  '3rd Advance Price/LB for Level 1, Grade 1'

         in window aW @10,69 winget price->uL1g1Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 1, 1, .t. ) ;
              get_message ;
			  'Total Final Price/LB for Level 1, Grade 1 (including all Advances)'

         in window aW @11,43  winsay 'Gr 2' winget price->uL1G2A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 1, Grade 2'

         in window aW @11,55  winget price->uL1g2A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 1, Grade 2'

         in window aW @11,62 winget price->uL1g2A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 1, Grade 2'

         in window aW @11,69 winget price->uL1g2Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 1, 2, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 1, Grade 2 (including all Advances)'

         in window aW @12,43  winsay 'Gr 3' winget price->uL1G3A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 1, Grade 3'

         in window aW @12,55  winget price->uL1g3A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 1, Grade 3'

         in window aW @12,62 winget price->uL1g3A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 1, Grade 3'

         in window aW @12,69 winget price->uL1g3Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 1, 3, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 1, Grade 3 (including all Advances)'

			in window aW @13,42  winsay 'Level 2-'
         // 14
         in window aW @14,43  winsay 'Gr 1' winget price->uL2G1A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 2, Grade 1'

         in window aW @14,55  winget price->uL2g1A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 2, Grade 1'

         in window aW @14,62 winget price->uL2g1A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 2, Grade 1'

         in window aW @14,69 winget price->uL2g1Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 2, 1, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 2, Grade 1 (including all Advances)'

         in window aW @15,43  winsay 'Gr 2' winget price->uL2G2A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 2, Grade 2'

         in window aW @15,55  winget price->uL2g2A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 2, Grade 2'

         in window aW @15,62 winget price->uL2g2A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 2, Grade 2'

         in window aW @15,69 winget price->uL2g2Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 2, 2, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 2, Grade 2 (including all Advances)'

         in window aW @16,43  winsay 'Gr 3' winget price->uL2G3A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 2, Grade 3'

         in window aW @16,55  winget price->uL2g3A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 2, Grade 3'

         in window aW @16,62 winget price->uL2g3A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 2, Grade 3'

         in window aW @16,69 winget price->uL2g3Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 2, 3, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 2, Grade 3 (including all Advances)'

         in window aW @17,42  winsay 'Level 3-'
         in window aW @18,43  winsay 'Gr 1' winget price->uL3G1A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 3, Grade 1'

         in window aW @18,55  winget price->uL3g1A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 3, Grade 1'

         in window aW @18,62 winget price->uL3g1A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 3, Grade 1'

         in window aW @18,69 winget price->uL3g1Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 3, 1, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 3, Grade 1 (including all Advances)'

         in window aW @19,43  winsay 'Gr 2' winget price->uL3G2A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 3, Grade 2'

         in window aW @19,55  winget price->uL3g2A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 3, Grade 2'

         in window aW @19,62 winget price->uL3g2A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 3, Grade 2'

         in window aW @19,69 winget price->uL3g2Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 3, 2, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 3, Grade 2 (including all Advances)'

         in window aW @20,43  winsay 'Gr 3' winget price->uL3G3A1 ;
             picture '99.99' when !lAdvance ;
              get_message ;
           'Advance Price/LB for Level 3, Grade 3'

         in window aW @20,55  winget price->uL3g3A2 ;
             picture '99.99' when !lAdvance2 get_message ;
           '2nd Advance Price/LB for Level 3, Grade 3'

         in window aW @20,62 winget price->uL3g3A3 ;
             picture '99.99' when !lAdvance3 get_message ;
           '3rd Advance Price/LB for Level 3, Grade 3'

         in window aW @20,69 winget price->uL3g3Fn ;
             picture '99.99' ;
             valid PriceTotOk( 'C', 3, 3, .t. ) ;
              get_message ;
           'Total Final Price/LB for Level 3, Grade 3 (including all Advances)'

		endif

		if lRead
			if lFinal .and. lFirst
				getList := {}
				if yesno({'You have have made at least some final payments with', ;
					'this ID are you SURE you want to Edit?'} )
					lFirst := .f.
					loop
				else
					thinWait('Viewing')
				endif
				exit
			endif

			read
			if updated()
				Price->(editByFlds())
			endif
			Price->(dbCommit())

         lError := .f.

			if sysValue(SYS_ALLOW_CANADIAN_DOLLARS)
            for nLevel := 1 to MAX_NO_OF_PRICE_LEVELS
               for nGrade := 1 to MAX_NO_OF_GRADES
                  if !PriceTotOk( 'C', nLevel, nGrade, .f. )
                     lError := .t.
                  endif
               next
            next
         endif

			if sysValue(SYS_ALLOW_US_DOLLARS)
            for nLevel := 1 to MAX_NO_OF_PRICE_LEVELS
               for nGrade := 1 to MAX_NO_OF_GRADES
                  if !PriceTotOk( 'U', nLevel, nGrade, .f. )
                     lError := .t.
                  endif
               next
            next
			endif
         if lError
            if Yesno({'You seem to have Final Prices that are less than', ;
             'the sum of advance prices - you may set the final to 0', ;
             'meaning they are not yet known - or make the final pay', ;
             'larger than the sum of advances!', '', ;
             'Do you wish to correct these problems?' })
               loop
            endif
         endif
		else
			getList :={}
			thinWait('Viewing')
		endif
		lFirst := .f.
		exit
	enddo

	setKey(K_F1, bF1)

	Price->(dbRunLock())

	kill window aW

return( SIG_FORCE_REDRAW )

static function PriceHelp()
   waitInfo({'Each grower is given a price level (from 1 to 3)', ;
		'which determines which set of prices he will be paid.',   ;
		'The payments are made up of up to 3 advances, and a', ;
		'final payment.  The final total shown on the Price Screen', ;
		'is the Sum of all advances + any extra needed to make up' ,;
		'the FINAL TOTAL price.'  })

return( nil )

function PricePrint( )
	local nOrder
	local cProd
	local lTopOfPage := .t.
   local n1,n2,n3, nPos
   local cVar

	if !openfile({'Price','Product','Process'} ,DB_SHARED)
		close databases
		return( nil )
	endif

	nOrder := BsgChoice({'Select Order to Print Pricing by:', ;
		'','Product - Sorted by Product/Process', ;
		   'Date    - Sorted by Date', ;
			'ID      - Sorted by ID (input order)'}, ;
			{'Product','Date','ID Order','Cancel'})

	if nOrder>=1 .and. nOrder<=3
		if selectPrn('Price')
			PRINT_ON  RPT_OVERWRITE

			do case
			case nOrder == 1
            Price->(OrdSetFocus(PRICE_PRODUCT_ORD))
			case nOrder == 2
            Price->(OrdSetFocus(PRICE_DATE_ORD ))
			case nOrder == 3
            Price->(OrdSetFocus(PRICE_PRICE_ID_ORD ))
			endcase

			Price->(dbGoTop())

			cProd := '^^'
			PrinterCtrl( PRN_CTRL_17_CPI )

			do while !Price->(eof())

            if NearPageBottom()
					lTopOfPage := .t.
               nuFormFeed()
				endif

				if lTopOfPage
               nuQprnOut( 'Berry Payment Pricing' )
               nuQprnOut( shMDY(date()) )
               nuQprnOut( time() )
               nuQprnOut( )

               nuQprnOut(  )
               nuQprnOut( space(14)+'--------Level #1--------'+space(8)+ ;
									'--------Level #2--------'+space(8)+ ;
                           '--------Level #3--------' )
               nuQprnOut( space(14)+'Grade 1      2      3   '+space(8)+ ;
                           'Grade 1      2      3   '+space(8)+ ;
                           'Grade 1      2      3   '  )
               nuQprnOut( )
				endif

				if cProd <> Price->product .or. lTopOfPage
               nuQprnOut( )
               nuQprnOut( Price->product+' '+NameOf(LU_PRODUCT, Price->product) )
					cProd := Price->product
				endif

				lTopOfPage := .f.

            nuQprnOut( '  '+Price->process+' '+NameOf(LU_PROCESS_TYPE, Price->process)+ ;
               ' ID#'+lStrim(Price->priceID) )

				do case
            case Price->adv1_used .and. Price->fin_used
               nuQQprnOut( ' Final & Advances Pd ' )
            case Price->adv1_used
               nuQQprnOut( ' Advances Pd '         )
				case Price->fin_used
               nuQQprnOut( ' Final Pd '           )
				otherwise
               nuQQprnOut( ' Not paid against '   )
				endcase

				if SysValue( SYS_ALLOW_CANADIAN_DOLLARS )
               nuQQprnOut( '   '+'CAD$ ' )
               nuQQprnOut( padr('Fr '+shMDY(Price->from),16) )
					if Price->timePrem
                  nuQQprnOut( 'Before '+Price->Time+ '   '+str(Price->cpremium,5,2) )
					endif

               for n1 := 1 to MAX_NO_OF_ADVANCES
                  nuQprnOut(  space(4)+padr('Adv. '+str(n1,1),8) )
                  for n2 := 1 to MAX_NO_OF_PRICE_LEVELS
                     for n3 := 1 to MAX_NO_OF_GRADES
                        cVar := 'CL'+str(n2,1)+'G'+str(n3,1)+'A'+str(n1,1)
                        nPos := Price->(FieldPos( cVar ))
                        if nPos <> 0
                           nuQQprnOut( str( Price->(FieldGet( nPos )),8,2) )
                        else
                           appError(APP_ERR_PRICING2, {'Advance problem'})
                        endif
                     next
                     nuQQprnOut( space( 8 ) )
                  next
               next

               nuQprnOut(  space(4)+padr('Total',8) )
               for n2 := 1 to MAX_NO_OF_PRICE_LEVELS
                  for n3 := 1 to MAX_NO_OF_GRADES
                     cVar := 'CL'+str(n2,1)+'G'+str(n3,1)+'FN'
                     nPos := Price->(FieldPos( cVar ))
                     if nPos <> 0
                        nuQQprnOut( str( Price->(FieldGet( nPos )),8,2) )
                     else
                        appError(APP_ERR_PRICING2, {'Final problem'})
                     endif
                  next
                  nuQQprnOut( space( 8 ) )
               next
				endif

				if	SysValue( SYS_ALLOW_US_DOLLARS)
					if SysValue( SYS_ALLOW_CANADIAN_DOLLARS )
                  nuQprnOut( '   '+'USD $ Prices ' )
					else
                  nuQprnOut( '  '+Price->process+' '+NameOf(LU_PROCESS_TYPE, Price->process) )
                  nuQQprnOut( space(2)+'USD$ ' )
					endif
               nuQQprnOut( padr('Fr '+shMDY(Price->from),16) )

					if Price->timePrem
                  nuQQprnOut( 'Before '+Price->Time+ '   '+str(Price->upremium,5,2) )
					endif

               for n1 := 1 to MAX_NO_OF_ADVANCES
                  nuQprnOut(  space(4)+padr('Adv. '+str(n1,1),8) )
                  for n2 := 1 to MAX_NO_OF_PRICE_LEVELS
                     for n3 := 1 to MAX_NO_OF_GRADES
                        cVar := 'UL'+str(n2,1)+'G'+str(n3,1)+'A'+str(n1,1)
                        nPos := Price->(FieldPos( cVar ))
                        if nPos <> 0
                           nuQQprnOut( str( Price->(FieldGet( nPos )),8,2) )
                        else
                           appError(APP_ERR_PRICING2, {'Advance problem'})
                        endif
                     next
                     nuQQprnOut( space( 8 ) )
                  next
               next

               nuQprnOut(  space(4)+padr('Total',8) )
               for n2 := 1 to MAX_NO_OF_PRICE_LEVELS
                  for n3 := 1 to MAX_NO_OF_GRADES
                     cVar := 'UL'+str(n2,1)+'G'+str(n3,1)+'FN'
                     nPos := Price->(FieldPos( cVar ))
                     if nPos <> 0
                        nuQQprnOut( str( Price->(FieldGet( nPos )),8,2) )
                     else
                        appError(APP_ERR_PRICING2, {'Final problem'})
                     endif
                  next
                  nuQQprnOut( space( 8 ) )
               next
				endif

				Price->(dbSkip())

			enddo

			PrinterCtrl( PRN_CTRL_10_CPI )
			PriExplain()

			PRINT_OFF RPT_COMPLETE_EJECT

		endif
	endif

	close databases

return( nil )

static function PriExplain()

   if NearPageBottom( 10 )
      nuFormFeed()
      nuQprnOut( )
      nuQprnOut( 'Berry Payment Pricing' )
      nuQprnOut( shMDY(date())             )
      nuQprnOut( )
	endif
   nuQprnOut( )
   nuQprnOut( 'Explanation:' )
   nuQprnOut( ' This report shows whether any payments have been made using each of' )
   nuQprnOut( ' the pricing records shown.  Two types of payment can be made using'  )
   nuQprnOut( ' these records: Advances & Final Payments.  It is possible to make a' )
   nuQprnOut( ' Final Payment without making an Advance.  This could come up if you' )
   nuQprnOut( ' had a season advance of 50 cents, then later added the final payment')
   nuQprnOut( ' records that gave a final price from July 14-28 $1.05, but all other')
   nuQprnOut( ' dates a final price of $1.00/lb.' )
   nuQprnOut( 'End.' )
   nuQprnOut( )

return( nil )

static function PriceTotOk( cCur, nLevel, nGrade, lMsgOnly )
   local cAdv1, cAdv2, cAdv3, cFinal
   local lReturn := .t.
   local nTot   := 0.00
   local nTotal := 0.00
   local nPos

   default lMsgOnly to .t.

   /*
   cAdv1  := cCur+'L'+str(nLevel,1) + 'GRADE' + str(nGrade,1)
   cAdv2  := cCur+'2A'+str(nLevel,1) + 'GR' + str(nGrade,1)
   cAdv3  := cCur+'3A'+str(nLevel,1) + 'GR' + str(nGrade,1)
   cFinal := cCur+'FIN'+str(nLevel,1)+ 'GR' + str(nGrade,1)
   */
   cAdv1  := cCur+'L'+str(nLevel,1)+'G'+str(nGrade,1)+'A1'
   cAdv2  := cCur+'L'+str(nLevel,1)+'G'+str(nGrade,1)+'A2'
   cAdv3  := cCur+'L'+str(nLevel,1)+'G'+str(nGrade,1)+'A3'
   cFinal := cCur+'L'+str(nLevel,1)+'G'+str(nGrade,1)+'FN'

   /* ---------------- prior to SEPT 2007 -----
   nPos := Price->(fieldPos( cAdv1 ))
   nTot := Price->(fieldGet( nPos ))
   nPos := Price->(fieldPos( cAdv2 ))
   nTot += Price->(fieldGet( nPos ))
   nPos := Price->(fieldPos( cAdv3 ))
   nTot += Price->(fieldGet( nPos ))
   -------------------------------------- */

   nPos := Price->(fieldPos( cAdv1 ))
   nTot := Price->(fieldGet( nPos ))
   nPos := Price->(fieldPos( cAdv2 ))
   nTot := max( Price->(fieldGet( nPos )),nTot)
   nPos := Price->(fieldPos( cAdv3 ))
   nTot := max( Price->(fieldGet( nPos )),nTot)

   nPos := Price->(fieldPos( cFinal ))
   nTotal := Price->(fieldGet( nPos ))

   if nTot > nTotal .and. str( nTotal,12,2) <> str(0,12,2)
      WaitHand({'Final $'+cCur+' Price for Grade '+str(nGrade,1) + ;
       'Level '+str(nLevel,1)+' is not correct '})
      lReturn := .f.
   endif

   if lMsgOnly
      lReturn := .t.
   endif

return( lReturn )

