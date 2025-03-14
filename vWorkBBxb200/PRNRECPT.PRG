// --------------------------------------------------------------------------
//   Application: Billing Information System
//   Description: Prints a Receipt
//                Assumes we are on Correct Record in Daily
//
//     File Name: PRNRECPT.PRG
//        Author: Bill Hepler
//  Date created: 07-24-99
//  Updated to Correct Eject problem
//  July 29, 2014 - Prints Printing Notes (not Non-Printing!)
//
//     Copyright: (c) 1999, 2012, 2014 by Bill Hepler & Crafted Industrial Software Ltd.
// --------------------------------------------------------------------------

#include "field.ch"
#include "valid.ch"
#include "BerryPay.ch"
#include "sysvalue.ch"
#include "printer.ch"
#include "browser.ch"
#include "bsgstd.ch"
#include 'common.ch'

function Prn1Receipt( lAllInfo )
	local cFile := 'RECEIPT.TXT'

	default lAllInfo to .f.
	if lAllInfo
		cFile := 'ALL_INFO.TXT'
	endif

	if SelectPrn( cFile )
		PRINT_ON  RPT_OVERWRITE

		ActualPrn( lAllInfo )

		PRINT_OFF RPT_COMPLETE_EJECT
	endif

return( SIG_CONTINUE )


static function ActualPrn(  lAllInfo )
	local lShowGT     := .f.
	local n
	local cInfo       := 'Office Copy'
   local cFrom_Field := ''

	if lAllInfo // 23456789012345678
		cInfo := 'SHOWS SPECIAL NOTES'
	endif

	PrinterCtrl( PRN_CTRL_10_CPI )

	nuQprnOut(  padr(TheClientName( ), 55) + cInfo )
	nuQprnOut(  padr(sysValue( SYS_ACTUAL_ADDRESS1   ), 55) + ;
		 'Grower Receipt' )
	nuQprnOut(  padr(sysValue( SYS_ACTUAL_ADDRESS2   ), 55) + ;
		 'Depot '+ Daily->depot )
	nuQprnOut(  padr(sysValue( SYS_ACTUAL_ADDRESS3   ), 55) + ;
       'Receipt '+ str(Daily->recpt,8)+ ' '+Daily->recptLtr )

	nuQprnOut( )
	nuQprnOut( )
	nuQprnOut(  padr('Grower: '+str(Daily->number,FLD_GROWER )+' ' + ;
		  NameOf(LU_GROWER_NAME, Daily->number),55) + ;
		  shMDY(Daily->date) )
	nuQprnOut(  space(55)+ Daily->time )
	nuQprnOut( )

	if empty(Daily->product)
		nuQprnOut( )
		nuQprnOut(  padr('Container Transaction only',55) )
		if !empty( Daily->variety)
			nuQprnOut(  padr('Variety: '+Daily->Variety+ ' '+NameOf( LU_VARIETY, Daily->Variety) ,60) )
		endif
		nuQprnOut( )
	else
		nuQprnOut(  padr('Product: '+Daily->product+ ' ' + ;
		  NameOf(LU_PRODUCT, Daily->product),45) + ;
		  iif( empty(Daily->variety),'', ;
		         Daily->variety+' '+NameOf( LU_VARIETY, Daily->Variety)  ) ;
		  )

		if str(Daily->gross,12,2) == str(0,12,2) .or. ;
				str(Daily->tare,12,2) == str(0,12,2) .or. ;
				str(Daily->gross - Daily->tare,12,2) <> str(Daily->net,12,2)
			lShowGT := .f.
		else
			lShowGT := .t.
		endif

		if lShowGT
			nuQQprnOut(  'Gross: ' + transform(Daily->gross,'9,999,999') + ;
				 ' ' + lower(sysValue(SYS_UNITS_OF_WEIGHT))  )
		endif

		nuQprnOut(  padr('Process: '+Daily->process+ ' ' + ;
		  NameOf(LU_PROCESS_TYPE, Daily->process),45) )

		if lShowGT
			nuQQprnOut(  'Tare:  '+transform(Daily->tare ,'9,999,999')+ ;
				' '+lower(sysValue(SYS_UNITS_OF_WEIGHT)) )
		endif

		if Num2NotEqual0( Daily->grade)
			nuQprnOut(  padr('Grade '+str(Daily->grade,2),45) )
		else
			nuQprnOut(  space( 45) )
		endif

      nuQQprnOut(     'Net:   '+transform(Daily->net  ,'9,999,999')+ ;
				' '+lower(sysValue(SYS_UNITS_OF_WEIGHT)) )

      if !(str( Daily->thePrice, 10,2)==str(0,10,2))
         nuQprnOut(  space(45) )
         nuQQprnOut(  'Price:   $'+str(Daily->thePrice,6,2) + ;
            '/'+lower(sysValue(SYS_UNITS_OF_WEIGHT)) )
      endif

      if !empty( Daily->FROM_FIELD ) .or. !empty( sysValue( SYS_IMPORT_FROM_FIELD_NAME ))
      	if !empty( sysValue( SYS_IMPORT_FROM_FIELD_NAME ))
         	cFrom_field := alltrim( sysValue( SYS_IMPORT_FROM_FIELD_NAME ))
         else
         	cFrom_Field := 'From_Field'
         endif

         nuQprnOut( cFrom_Field+': '+ Daily->FROM_FIELD )
      endif
	endif

	nuQprnOut( )
	nuQprnOut(  padr('Container Issues:',35)+padl('In',11)+padl('Out',11) )

	for n := 1 to MAX_TYPES_CONTAINERS
		if ContInUse( n ) .or.  ;
            str(Daily->(gsInContainer( n )),12) <> str(0,12) .or. ;
            str(Daily->(gsOutContainer(n)),12)  <> str(0,12)
			nuQprnOut(  ' '+padr( ContLName(n) ,34) )
         nuQQprnOut(  transform( Daily->(gsInContainer(n)), '999,999,999')  )
         nuQQprnOut(  transform( Daily->(gsOutContainer(n)), '999,999,999') )
		endif
	next

	nuQprnOut( )
	if Daily->day_uniq > 0
		nuQprnOut(  space(40)+'CPU ID#'+lstrim(Daily->day_uniq) )
	endif

	nuQprnOut( )

	if !empty(Daily->pr_note1)
		nuQprnOut(  'Note: ' + Daily->pr_note1 )
	endif
	if !empty(Daily->certified )
		nuQprnOut(  'Certified note: ' + Daily->certified )
	endif

	if lAllInfo
		if !(alltrim( Daily->product)==alltrim( Daily->LONG_PROD ) .and. ;
	     alltrim( Daily->process)==alltrim( Daily->LONG_PROC ) )

			nuQprnOut( 'Product/Process as imported=' + ;
		        Daily->Long_prod+' / '+Daily->Long_Proc )
		endif
		if !empty(Daily->np_note1)
			nuQprnOut(  'NON-PRINTING Note: ' + Daily->np_note1 )
		endif
		if !empty(Daily->cont_errs )
			nuQprnOut(  'Container errors on Import: ' + Daily->cont_errs )
		endif
		if !empty(Daily->edit_reas)
			nuQprnOut(  'EDITED AT SCALE: ' + Daily->edit_reas )
		endif
		if !empty( Daily->UNIQ_IMBAT)  .or. Daily->imported
			if ValidTest( V_IMPORT_SESSION, Daily->UNIQ_IMBAT, VT_NO_MESSAGE)
				nuQprnOut( 'Import Session: '+ var2char( Daily->UNIQ_IMBAT) + ' at '+ shMDY(ImpBat->QADD_DATE)+ ' '+ ImpBat->QADD_TIME + ;
				            '  Scale Imp Batch #' + ImpBat->depot + '-' + var2char( ImpBat->imp_bat ))
			else
				nuQprnOut( 'This Receipt was imported from the Scale Program')
			endif
		endif
      if Num2NotEqual0( Daily->uniq_imBat) .or. Num2NotEqual0( Daily->imp_bat)
      	nuQprnOut( 'Imported in Batch: '+Daily->depot+'-'+ var2char( Daily->imp_bat)+ ;
                    '   Import Session: '+var2char( Daily->uniq_imBat ) )
      endif
	endif

   if !num2Equal0(Daily->thePrice)
   	if Daily->fin_pr_id > 0
	   	nuQprnOut( 'Final Price: ' + '$'+alltrim(str(Daily->thePrice,10,2)  ) )
      else
	      nuQprnOut( 'Estimated Final Price: ' + '$'+alltrim(str(Daily->thePrice,10,2)  )  )
      endif
      do case
      case Daily->priceSrc == PRICE_SRC_KEY
      	nuQQprnOut( ' Keyed in')
		case Daily->priceSrc == PRICE_SRC_SCALE
	      nuQQprnOut( ' from Scale')
      endcase
   endif

   if Daily->post_bat1==0
		nuQprnOut(  'UnPosted Grower Receipt Printed from Office ' )
	else
		nuQprnOut(  'Posted Grower Receipt Printed from Office ' )
	endif
	if lAllInfo
		nuQQprnOut( cInfo)
	endif
	nuQprnOut( )

return( nil )

