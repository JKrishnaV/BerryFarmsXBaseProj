// --------------------------------------------------------------------------
//  Application: BerryPayment Program
//  Description: Price Setting
//
//     Field Names changed to be more rational
//
//    File Name: PRICEFND.PRG
//       Author: Bill Hepler
//    Copyright: (c) 2018 by Bill Hepler & Crafted Industrial Software Ltd.
// --------------------------------------------------------------------------

// Nov  2001 can now pay advance 2 and 3
//           better checking on sum of Advances + Final


#include 'bsgstd.ch'
#include 'price.ch'
#include 'valid.ch'
#include "indexord.ch"
#Include "BerryPay.ch"
#include 'common.ch'
#include 'errors.ch'
#include 'sysvalue.ch'
#include 'field.ch'


function fValidPrice()
	local lReturn := .f.
	local cFile
	local cVar

	cFile := alias()

	if ValidTest(V_GROWER, Field->number, VT_NO_MESSAGE )

		do case
		case empty(Field->product) .and. empty(Field->process) .and. ;
					Field->grade==0 .and. Field->net==0 .and. !empty(Field->date)

			lReturn := .t.
		case !empty(Field->product) .and. !empty(Field->process) .and. ;
				Field->grade>0 .and. !empty(Field->date) .and. ;
				Field->grade <= MAX_NO_OF_GRADES

			if FindPrice( Field->Product, Field->Process, Field->Date )

            // the "2" ensures that data is there...
            cVar := varAdvance( cFile, 2 )

				if !empty(cVar)
					lReturn := .t.
				endif
			endif
		endcase
	endif

return( lReturn )

static function varAdvance( cFile, nAdvance )
   // changed in Nov 2001
	local cReturn := ''
	local cVar := ''
	local nPos

	// assumes that FIND PRICE worked!

	do case
	case Grower->currency == CANADIAN_DOLLARS
		cVar := 'C'
	case Grower->currency == US_DOLLARS
		cVar := 'U'
	endcase

   if nAdvance >= 1 .and. nAdvance <= MAX_NO_OF_ADVANCES
      if Grower->status > 0 .and. Grower->status <= MAX_NO_OF_PRICE_LEVELS
         cVar += 'L'+str(Grower->status,1)
      endif
      if (cFile)->grade > 0 .and. (cFile)->grade <= MAX_NO_OF_GRADES
         cVar += 'G'+str( (cFile)->grade,1)
      endif
      cVar += 'A'+str(nAdvance,1)

   else
      appError( APP_ERR_UNKNOWN_ADVANCE_TYPE3, { ;
        'The Advance Type is not determined.  This message', ;
        'may come up a LOT - contact Crafted Industrial Software Ltd.', ;
        'If the message comes up a lot you may need to do Alt-C', ;
        'and then restore back ups....'})
   endif

	nPos := Price->(FieldPos(cVar))

	// if grade is 0, no price

	if nPos > 0 .and. len(cVar) > 5
		cReturn := cVar
	endif

return( cReturn )

static function varFinal( cFile )
	local cReturn := ''
	local cVar    := ''
	local nPos

	// assumes that FIND PRICE worked!

	do case
	case Grower->currency == CANADIAN_DOLLARS
		cVar := 'C'
	case Grower->currency == US_DOLLARS
		cVar := 'U'
	endcase

	if Grower->status > 0 .and. Grower->status <= MAX_NO_OF_PRICE_LEVELS
      cVar += 'L'+str(Grower->status,1)
	endif

	if (cFile)->grade > 0 .and. (cFile)->grade <= MAX_NO_OF_GRADES
      cVar += 'G'+str( (cFile)->grade,1)
	endif
   cVar += 'FN'

	nPos := Price->(FieldPos(cVar))

	// if grade is 0, no price

	if nPos > 0 .and. len(cVar) > 5
		cReturn := cVar
	endif

// return( cVar )
return( cReturn )

static function VarPrem( cFile )
	local cReturn := ''
	local nPos

	// assumes that FIND PRICE worked!

	if Price->timePrem
		if (cFile)->time <= Price->time
			if Grower->status > 0 .and. Grower->status <= MAX_NO_OF_PRICE_LEVELS
				if (cFile)->grade > 0 .and. (cFile)->grade <= MAX_NO_OF_GRADES
					do case
					case Grower->currency == CANADIAN_DOLLARS
						cReturn := 'C'
					case Grower->currency == US_DOLLARS
						cReturn := 'U'
					endcase

					cReturn += 'PREMIUM'

					nPos := Price->(FieldPos(cReturn))

					// if grade is 0, no price
               //
					if nPos == 0 .or. len(cReturn) < 5
					 	cReturn := ""
					endif
				endif
			endif
		endif
	endif

return( cReturn )


function FindPrice( cProduct, cProcess, dDate )
	local lReturn := .f.

   Price->(OrdSetFocus( PRICE_PRODUCT_ORD ))
	Price->(dbSeek(cProduct+cProcess+dtos(dDate), SOFTSEEK ))

	if Price->product==cProduct .and. Price->process==cProcess .and. ;
			Price->from==dDate
		lReturn := .t.
	else
		// we are past it
		if !Price->(bof())
			Price->(dbSkip(-1))

			if Price->product==cProduct .and. Price->process==cProcess .and. ;
				dDate >= Price->from
				lReturn := .t.
			endif
		endif
	endif

	if lReturn
		if !empty(cProduct)
			lReturn := validTest(V_PRODUCT, cProduct, VT_NO_MESSAGE)
		endif
   else
      if sysValue( SYS_SET_ADVANCES_BY_PROCESS_ONLY )
         // we Look for PROCESS ONLY advance
         Price->(OrdSetFocus( PRICE_PRODUCT_ORD ))
         Price->(dbSeek(space( FLD_PRODUCT)+cProcess+dtos(dDate), SOFTSEEK ))
         if empty(Price->product) .and. Price->process==cProcess .and. ;
               Price->from==dDate
            lReturn := .t.
         else
            // we are past it
            if !Price->(bof())
               Price->(dbSkip(-1))

               if empty(Price->product) .and. Price->process==cProcess .and. ;
                  dDate >= Price->from
                  lReturn := .t.
               endif
            endif
         endif
      endif

      if !lReturn
         Price->(dbSeek(cProduct+cProcess+dtos(dDate), HARDSEEK ))
         if !Price->(eof())
            appError( APP_ERR_PRICING1, {'We expect to be at EOF for', ;
              'PriceFind() but are not', ;
              'Looking at:'+cProduct+','+cProcess+','+dtos( dDate) })
         endif
      endif
	endif

return( lReturn )

// now called Advance Price
/* in Nov 2001 there are now 3 Functions -
    - TotAdvPrice()             Total of All Advances
    - CurAdvPrice( nAdvance )   Current Advance Amount
    - RunAdvPrice( nAdvance )   Running total Advance up to nAdvance
*/



   // -- this is a Stub just for the Time Being
/* -
   function AdvancePrice()
      local nReturn

      nReturn := CurAdvPrice( 1 )  // just for Now

   return( nReturn )
*/


/* --- Not used any more
   function AdvancePrice(  )
      local nReturn := 0
      local cVar := ''
      local nPos
      local cFile

      cFile := alias()

      // assumes that FIND PRICE worked!
      cVar := varAdvance( cFile )
      if !empty(cVar)
         nPos := Price->(FieldPos(cVar))

         // if grade is 0, no price

         if nPos > 0 .and. len(cVar) > 5
            nReturn := Price->(FieldGet( nPos ))
         endif
      endif

   return( nReturn )
*/

function TotAdvPrice( )
   local nReturn := 0.00
   local nPrice

   /* ---- This was What we WERE doing -

          inconsistancy found in Sep 2007 !

      nReturn := CurAdvPrice( 1 )
      nReturn += CurAdvPrice( 2 )
      nReturn += CurAdvPrice( 3 )

   ----------------------------------------- */

   nReturn := CurAdvPrice( 1 )   // First Advance

   nPrice   := CurAdvPrice( 2 )   // 2nd Advance
   nReturn  := max( nPrice,nReturn)

   nPrice   := CurAdvPrice( 3 )   // 3rd Advance
   nReturn  := max( nPrice,nReturn)

return( nReturn )

///<summary>Projected Advance from Priceing Table considering other advances</summary>
function RunAdvPrice( nAdvance )
   local nReturn := 0.00
   local n

	for n := 1 to nAdvance
   	if Num3NotEqual0( CurAdvPrice( n ))
   		nReturn := max( CurAdvPrice( n ), nReturn )
   	endif
   next

return( nReturn )

///<summary>Advance Price # from Price Table</summary>
static function CurAdvPrice( nAdvance )
   local nReturn := 0.00
   local cVar := ''
   local nPos
   local cFile

   cFile := alias()

   // assumes that FIND PRICE worked!
   cVar := varAdvance( cFile, nAdvance )
   if !empty(cVar)
      nPos := Price->(FieldPos(cVar))

      // if grade is 0, no price

      if nPos > 0 .and. len(cVar) > 5
         nReturn := Price->(FieldGet( nPos ))
      endif
   endif

return( nReturn )


// this INCLUDES the KEYED in PRICE - June 2007
function FinalPrice(  )  // note this is final price, includes Advance !!!
	local nReturn := 0
	local cVar := ''
   local n, n1, n2
   local nPrice := 0.00
	local nPos
	local cFile

	cFile := alias()

   n  := 0
   n1 := FieldPos('FIN_PRICE')
   n2 := FieldPos('FIN_BAT')
   if n1 > 0 .and. n2 > 0
      // We have MADE a FINAL payment
      n := FieldGet( n2 )
      if n > 0
         nPrice  := FieldGet( n1 )
      endif
   endif

   if n > 0
      nReturn := nPrice
   else
      n := FieldPos('THEPRICE')
      if n > 0
         nPrice := FieldGet( n )
      endif

      if str( nPrice, 10,2 ) <> str( 0,10,2)
         nReturn := nPrice
      else
         // THis assumes that FIND PRICE worked!
         cVar := varFinal( cFile )
         if !empty(cVar)
            // FIRST IF WE HAVE AN ACTUAL PRICE  !!
            // December 7, 2007 we SHOULD grab data from The ACTUAL if it is
            // know
            nPos := Price->(FieldPos(cVar))

            // if grade is 0, no price

            if nPos > 0 .and. len(cVar) > 5
               nReturn := Price->(FieldGet( nPos ))
            endif
         endif
      endif
   endif
return( nReturn )


function AdvancePrem(  )
	local nReturn := 0
	local cVar := ''
	local nPos
	local cFile

	cFile := alias()

	// assumes that FIND PRICE worked!
	cVar := VarPrem( cFile )
	if !empty(cVar)
		nPos := Price->(FieldPos(cVar))

		// if grade is 0, no price

		if nPos > 0 .and. len(cVar) > 5
			nReturn := Price->(FieldGet( nPos ))
		endif
	endif

return( nReturn )


function PremAt( nGrower, cTime )
	local nReturn := 0
	local cVar := ''
	local nPos

	// assumes that FIND PRICE worked!

	if Price->timePremium
		if cTime <= Price->time
			if ValidTest(V_GROWER, nGrower, VT_NO_MESSAGE)
				if Grower->status > 0 .and. Grower->status <= MAX_NO_OF_PRICE_LEVELS

					do case
					case Grower->currency == CANADIAN_DOLLARS
						cVar := 'C'
					case Grower->currency == US_DOLLARS
						cVar := 'U'
					endcase

					cVar += 'PREMIUM'

					nPos := Price->(FieldPos(cVar))

					if nPos > 0 .and. len(cVar) > 5
						nReturn := Price->(FieldGet( nPos ))
					endif
				endif
			endif
		endif
	endif

return( nReturn )

/* ------------------ not used
   function FindAdvPr( nAdvance, cProduct, cProcess, dDate )
      local lReturn := .f.


   return( lReturn )
-------------------- */

function MrkDeduction( cProduct )
   local nReturn := 0.000

   if !empty( cProduct)
      if validTest( V_PRODUCT, cProduct, VT_NO_MESSAGE)
         nReturn := Product->deduct
      endif
   endif

return( nReturn )


function AdvPaid( nAdv )
   local nReturn := 0.00

   if (nAdv == 1 .or. nAdv == 0) .and. Field->post_bat1 > 0
      nReturn += round( Field->adv_pr1 * Field->net,2)
   endif

   if (nAdv == 2 .or. nAdv == 0) .and. Field->post_bat2 > 0
      nReturn += round( Field->adv_pr2 * Field->net,2)
   endif

   if (nAdv == 3 .or. nAdv == 0) .and. Field->post_bat3 > 0
      nReturn += round( Field->adv_pr3 * Field->net,2)
   endif

return( nReturn )

function NetPayable()
   local nReturn := 0.00
   local n

   if FindPrice( Field->Product, Field->Process, Field->Date )
      if Field->fin_bat > 0 .or. str(Field->net,10,2) == str(0,10,2)
         nReturn := 0.00
      else
         n := FinalPrice()  + MrkDeduction( Field->product)
         nReturn :=  Field->net * n  - AdvPaid( 0 )
      endif
   endif
return( nReturn )

///<summary>The actual advance paid out, 0 for all advances</summary>
function ThisActualAdvPrice( nAdv )
	local nReturn := 0.00

   if (nAdv == 1 .or. nAdv == 0) .and. ( Field->post_bat1 > 0 .or. field->post_bat2 > 0 .or. field->post_bat3 > 0 .or. Field->fin_bat > 0 )
      nReturn += Field->adv_pr1
   endif

   if (nAdv == 2 .or. nAdv == 0) .and. ( Field->post_bat2 > 0  .or. field->post_bat3 > 0 .or. Field->fin_bat > 0 )
      nReturn += Field->adv_pr2
   endif

   if (nAdv == 3 .or. nAdv == 0) .and. ( Field->post_bat3 > 0 .or. Field->fin_bat > 0 )
      nReturn += Field->adv_pr3
   endif

return( nReturn )
