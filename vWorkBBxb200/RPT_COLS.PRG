//--------------------------------------------------------------------------
//  Berry Payment Application
//   Report columns for various User Defined Reports
//
//   April 2019 - Process Grade - started adding "Dummy Columns"
//
//    File Name: RPT_COLS.PRG
//       Author: Bill Hepler
// Date created: 05-06-99             Date updated: June 3, 2015
//    Copyright: (c) 1999, 2011, 2015, 2019 by Bill Hepler
//--------------------------------------------------------------------------

#include "BerryPay.ch"
#include "bsgstd.ch"
#include 'common.ch'
#include "field.ch"
#include "sysvalue.ch"
#include "valid.ch"

function rAdvPrInfo( aRpt )

	aadd( aRpt, {'Pr?', {|| iif( fValidPrice(),' ','N')}, ;
		 "C",  3, 0 , ;
		.f., .f. , 'Pricing Can be Calculated? (blank=Yes, NO=can not, error!'})

   aadd( aRpt, {'U Price', {|| iif( fValidPrice(),TotAdvPrice(),0)}, ;
		 "N",  8, 2 , ;
      .f., .f. , 'Total Advance Price per '+sysValue(SYS_UNITS_OF_WEIGHT)  })

   aadd( aRpt, {'Ext. Pr.', {|| iif( fValidPrice(),Field->net*TotAdvPrice(),0)}, ;
		 "N",  8, 2 , ;
      .f., .f. , 'Total Advance Extended Price Payable'  })

   aadd( aRpt, {'U Pr 1', {|| iif( fValidPrice(),RUnAdvPrice(1),0)}, ;
		 "N",  8, 2 , ;
      .f., .f. , {'1st Advance Price per '+sysValue(SYS_UNITS_OF_WEIGHT)+ ' from Pricing Tables', ;
                  'It is NOT necessarily the Actual Advance'  } })

   aadd( aRpt, {'U Pr 2', {|| iif( fValidPrice(),RunAdvPrice(2),0)}, ;
		 "N",  8, 2 , ;
      .f., .f. , {'2nd Advance Price per '+sysValue(SYS_UNITS_OF_WEIGHT) + ' from Pricing Tables', ;
                  'It is NOT necessarily the Actual Advance'  }        })

   aadd( aRpt, {'U Pr 3', {|| iif( fValidPrice(),RunAdvPrice(3),0)}, ;
		 "N",  8, 2 , ;
      .f., .f. , {'3rd Advance Price per '+sysValue(SYS_UNITS_OF_WEIGHT) + ' from Pricing Tables', ;
                  'It is NOT necessarily the Actual Advance'  }         })

   aadd( aRpt, {'Adv Paid', { || AdvPaid( 0 ) }, 'N', 8,2, .f., .t., ;
      'Actual advances paid against this receipt' })

   aadd( aRpt, {'1st Adv Due', ;
    { || iif( str(Field->post_bat1,10,0)==str(0,10,0) .and. fValidPrice() , ;
        RunAdvPrice(1)*Field->net, 0.00 ) }, 'N', 8,2, .f., .t., ;
      '1st Advance Payable, BUT NOT YET PAID' })

return( nil )


function rFinPrInfo( aRpt )

	aadd( aRpt, {'Fin U Pr', {|| iif( fValidPrice(), FinalPrice(),0)}, ;
		 "N",  8, 2 , ;
		.f., .f. , 'Final Price per '+sysValue(SYS_UNITS_OF_WEIGHT)  })

	aadd( aRpt, {'Fin Ext', {|| iif( fValidPrice(),Field->net*FinalPrice(),0)}, ;
		 "N",  8, 2 , ;
      .f., .t. , 'Final Extended Price to Pay'  })

   aadd( aRpt, {'Keyed Price', {|| field->thePrice }, ;
        'N',8,2, .f., .f., 'Pricing from scale or keyed in for this receipt'})

   aadd( aRpt, {'Fin w/ D', {|| iif( fValidPrice(), ;
            Field->net*(FinalPrice()+MrkDeduction( Field->product)) ,0)}, ;
		 "N",  8, 2 , ;
      .f., .t. , 'Final Extended Price to Pay LESS Std Marketing Levy'  })

/* --- Dec 2, 2007 Corrected
   aadd( aRpt, {'Net Payable', {|| iif( fValidPrice(), ;
       Field->net*(FinalPrice()+MrkDeduction( Field->product))-AdvPaid(0) ,0)}, ;
		 "N",  8, 2 , ;
      .f., .t. , 'Final Extended Price Payable (Total-Levy-Advances Paid)'  })
------------------- */

   aadd( aRpt, {'Net Payable', {|| NetPayable()}, ;
		 "N",  8, 2 , ;
      .f., .t. , 'Final Extended Price Payable (Total-Levy-Advances Paid)'  })

   aadd( aRpt, {'Ded Rate', { || MrkDeduction( field->product) }, ;
         'N',7,3, .f., .f., 'Std Marketing deduction (Levy) for Product' })

   aadd( aRpt, {'Ded Total',  ;
       { || round( MrkDeduction( field->product ) * Field->net,2) }, ;
         'N',8,2, .f., .f., ;
          'Extended Std Marketing deduction (Levy) for Product' })

   // Changed November 2011
   aadd( aRpt, {'Levy Due', ;
      { || iif( Field->post_bat1 > 0, ;
                 0.00,  ;
                 round(MrkDeduction( Field->Product )*Field->net,2)) }, ;
    'N', 8,2, .f., .t., ;
    'Std Marketing Levy due as of today, set in Product-see MrkDeduction()' })

return( nil )


function rGrowerInfo( aRpt )

	aadd( aRpt, ;
		{ ' ' 	, { || space(1) }     ,  'C' ,    001  ,   000 , ;
			.t., .f. , ;
			'Space to Look Nice' } )

	aadd( aRpt, {'St', {|| NameOf(LU_GROWER_STATUS,Field->Number)}, ;
		 "N",  1, 0 , ;
		.f., .f. , 'Grower Status'})

	aadd( aRpt,{ 'ID', {|| Field->number}, 'N', 4, 0, .f., .f., ;
	 'Grower ID' })

	aadd( aRpt, ;
		{ 'Name' 	, { || NameOf(LU_GROWER,Field->NUMBER) } ,  'C' , 030 ,  000 , ;
			.t., .f. , ;
			'Grower Name (not Cheque Name)' } )

	aadd( aRpt, ;
		{ 'Ch. Name' 	, { || NameOf(LU_GROWER_CHEQUE_NAME,Field->NUMBER) } , ;
		  'C' , 030 ,  000 , ;
			.t., .f. , ;
			'Grower Cheque Name' } )

	aadd( aRpt, { 'Grp', {|| Grower->payGrp}, "C", FLD_PAYGRP+2, 0 , ;
		.f., .f., 'Payment Group Grower Belongs to' })

return( nil )

function rRcptQty( aRpt )

	aadd( aRpt,{ ' ',{|| ' '}, 'C', 1, 0, .t., .f., 'a Nice Space'} )

	aadd( aRpt, {'Date', {|| shMDY(Field->date) }, "C", 12, 0 , ;
		.t., .f. , 'Date of Receipt'})

	aadd( aRpt, {'Rect #', {|| Field->recpt }, "N", FLD_RECPT, 0 , ;
		.t., .f. , 'Receipt #'})

	aadd( aRpt, { 'Prod', {|| Field->product},   'C',  4, 0 , .t., .f., ;
	 'Product ID'})

	// corrected July 23/99
	aadd( aRpt, { 'Prod Name', {|| NameOf(LU_PRODUCT,Field->product )},  ;
		  'C',  15, 0 , .f., .f., ;
	 'Product Name'})

	aadd( aRpt, { 'Pc', {|| Field->process},   'C',  2, 0 , .t., .f., ;
	 'Process Identifier'})

	aadd( aRpt, { 'Proc Name', {|| NameOf(LU_PROCESS_TYPE,Field->process)},  ;
		  'C',  15, 0 , .f., .f., ;
	 'Process Name'})

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

	aadd( aRpt, { 'Gr', {|| Field->grade},   'N',  2, 0 , .t., .f., ;
	 'Grade'})

	aadd( aRpt, { 'Grade 1', ;
		 {|| iif( Field->grade==1,Field->net,0) },   'N',  9, 0 , .f., .f., ;
	 'Net Weight of Grade #1'})

	aadd( aRpt, { 'Grade 2', ;
		 {|| iif( Field->grade==2,Field->net,0) },   'N',  9, 0 , .f., .f., ;
	 'Net Weight of Grade #2'})

	aadd( aRpt, { 'Grade 3', ;
		 {|| iif( Field->grade==3,Field->net,0) },   'N',  9, 0 , .f., .f., ;
	 'Net Weight of Grade #3'})


	aadd( aRpt, { 'Con $',  ;
	  {|| ValueAllContain( alias() ) }, ',', 10, 2 , .t., .t., ;
	   'Total Value of Containers Issued'})

return( aRpt )

function rOutConCols( aRpt, lShow )
	local n
	local cBlock
	local bBlock

	for n := 1 to MAX_TYPES_CONTAINERS

		cBlock := '{|| Field->OUT'+lstrim(n)+ '- Field->IN'+lStrim(n)+ ' }'
		bBlock := &cBlock

		aadd( aRpt, { 'OUT'+lStrim(n), ;
			bBlock,"N", 6, 000,  lShow , .t., ;
          alltrim(ContSname(n))+' - '+alltrim(ContLName( n )) + ;
           ', Net # Containers taken OUT ' + lStrim(n) } )

	next

return( nil )

function rInConCols( aRpt, lShow )
	local n
	local cBlock
	local bBlock

	for n := 1 to MAX_TYPES_CONTAINERS

		cBlock := '{|| Field->IN'+lstrim(n)+ '- Field->OUT'+lStrim(n)+ ' }'
		bBlock := &cBlock

		aadd( aRpt, { 'IN'+lStrim(n), ;
			bBlock,"N", 6, 000, lShow , .t., ;
         alltrim(ContSname(n))+ ' - '+ alltrim(ContLName( n )) + ;
         ', Net # Containers received IN ' + lStrim(n) } )

	next

return( nil )

function rRawConCols( aRpt )
	local n
	local cBlock
	local bBlock

	for n := 1 to MAX_TYPES_CONTAINERS

		cBlock := '{|| Field->IN'+lstrim(n)+ ' }'
		bBlock := &cBlock

		aadd( aRpt, { 'I-TP'+lStrim(n), ;
			bBlock,"N", 6, 000, .f., .f., ;
         alltrim(ContSname(n))+' - '+alltrim(ContLName( n )) +  ;
         ', Containers received IN ' + lStrim(n) } )

		cBlock := '{|| Field->OUT'+lstrim(n)+ ' }'
		bBlock := &cBlock

		aadd( aRpt, { 'O-TP'+lStrim(n), ;
			bBlock,"N", 6, 000, .f., .f., ;
         alltrim(ContSname(n))+' - '+alltrim(ContLName( n )) + ;
          ', Containers taken OUT ' + lStrim(n) } )

	next

return( nil )

function rDockage( aRpt, lShow )
   default lShow to .f.

   aadd( aRpt, { 'Dock%', ;
       {||  Field->dock_pct },   'N',  4, 0 , .f., .f., ;
    'Dockage percentage - (whole number - thus 5 = 5%)' })

   aadd( aRpt, { 'O Net', ;
       {||  Field->ori_net },   'N',  6, 0 , lShow, .t., ;
    'Original Net Weight (0 may mean original net not known' })

   aadd( aRpt, { 'Deduct', ;
     {|| iif( Field->ori_net > 0, Field->ori_net - Field->net, 0) }, ;
       'N',  6, 0 , lShow, .t., ;
    'Deduction from Original Net' })

   aadd( aRpt, { 'S', ;
      { || iif( Field->post_bat1==0,"U" ,"P" ) },"C", 1, 000, .f., .f., ;
       'Status - P=Posted, U=Unposted Receipt' } )

   aadd( aRpt, { 'Dck%', ;
       {||  str(Field->dock_pct,3)+'%' },   'C',  4, 0 , lShow, .f., ;
    'Dockage percentage, a string s.b. 4 wide to see __5%' })

return( nil )

function rPricAud( aRpt )

   aadd( aRpt,{ ' ',{|| ' '}, 'C', 1, 0, .t., .f., 'a Nice Space'} )

   aadd( aRpt, {'Date', {|| shMDY( Field->date) }, "C", 12, 0 , ;
      .t., .f. , 'Date of Receipt'})

   aadd( aRpt, {'Dp', {|| Field->depot }, "C", 2, 0 , ;
      .t., .f. , 'Depot'})

   aadd( aRpt, {'Rect #', {|| Field->recpt }, "N", FLD_RECPT, 0 , ;
      .t., .f. , 'Receipt #'})

   aadd( aRpt, { 'Prod', {|| Field->product},   'C',  4, 0 , .t., .f., ;
      'Product'})

   aadd( aRpt, { 'Pc', {|| Field->process},   'C',  2, 0 , .t., .f., ;
      'Process'})

   aadd( aRpt, { 'Gr', {|| Field->grade},   'N',  2, 0 , .t., .f., ;
      'Grade'})

   aadd( aRpt, { 'Net', {|| Field->net},   ',',  9, 0 , .t., .t., ;
      'Net Weight'})


   aadd( aRpt, {'Adv #1', {|| iif( fValidPrice(),RUnAdvPrice(1),0)}, ;
         "N",  8, 2 , ;
      .t., .f. , {'1st Advance Price per '+sysValue(SYS_UNITS_OF_WEIGHT)+' from Pricing Tables', ;
                  'it is NOT necessarily the actual price paid out'}  })

   aadd( aRpt, {'Adv #2', {|| iif( fValidPrice(),RunAdvPrice(2),0)}, ;
         "N",  8, 2 , ;
      .t., .f. , {'2nd Advance Price per '+sysValue(SYS_UNITS_OF_WEIGHT)+' from Pricing Tables', ;
                  'it is NOT necessarily the actual price paid out'}   })

   aadd( aRpt, {'Adv #3', {|| iif( fValidPrice(),RunAdvPrice(3),0)}, ;
         "N",  8, 2 , ;
      .t., .f. , {'3rd Advance Price per '+sysValue(SYS_UNITS_OF_WEIGHT)+' from Pricing Tables', ;
                  'it is NOT necessarily the actual price paid out'}            })

   aadd( aRpt, {'Adv Paid', { || AdvPaid( 0 ) }, 'N', 8,2, .t., .t., ;
      'Actual advances paid against this receipt' })

   aadd( aRpt, {'Payable',  { || NetPayable( ) }, 'N', 8,2, .t., .t., ;
      'Net Payable against this receipt' })

   aadd( aRpt, {'Final $', { || FinalPrice( 0 ) }, 'N', 8,2, .t., .f., ;
      'Final Price Due' })

   aadd( aRpt, {'Pr?', {|| iif( fValidPrice(),' ','N')}, ;
         "C",  3, 0 , ;
      .t., .f. , 'Pricing Can be Calculated? (blank=Yes, NO=can not, error!'})

   aadd( aRpt, { 'St', ;
         { || iif( Field->post_bat1==0,"U" ,"P" ) },"C", 2, 000, .t., .f., ;
         'Status - P=Posted, U=Unposted Receipt' } )

return( nil )

function rDepotSite( aRpt )

   aadd( aRpt, {'Dp', {|| Field->depot }, "C", FLD_DEPOT, 0 , ;
      .f., .f. , 'Deport Received at'})

   aadd( aRpt,{ 'D Desc',{|| NameOf( LU_DEPOT, Field->depot ) }, 'C', FLD_DEPOT_NAME, 0, .f., .f., 'Depot Name/Desc'} )


return( nil )

function rRcptNotes( aRpt )
   aadd( aRpt,{ '',{|| ''  }, 'C', 10, 0, .f., .f., 'Blank Space', 2} )

   aadd( aRpt, {'Printing Notes', {|| iif(empty( Field->np_note1),'','* ')+Field->pr_note1 }, "C", FLD_TICKET_NOTE, 0 , ;
      .f., .f. , 'Printing Note-shows on some reports sent to Grower-note * means NP notes', 2})

   aadd( aRpt,{ '',{|| ''  }, 'C', 10, 0, .f., .f., 'Another Blank Space', 2} )

   aadd( aRpt, {'NonPrinting Notes', {|| Field->np_note1 }, "C", FLD_TICKET_NOTE, 0 , ;
      .f., .f. , 'Non Printing Note', 2})

return( nil )

function rVarietyEtc( aRpt )
   aadd( aRpt, {'Variety', {|| Field->variety }, "C", FLD_VARIETY, 0 , ;
      .f., .f. , 'Actual Variety'})

   aadd( aRpt,{ 'Variety Desc',{|| NameOf( LU_VARIETY, Field->variety ) }, 'C', FLD_VARIETY_DESC, 0, .f., .f., 'Variety Description'} )

   aadd( aRpt, {'Category', {|| NameOf( LU_HAVE_PRODUCT_CATEGORY_DESC, Field->product )}, "C", 20, 0 , ;
      .f., .f. , 'Product Category'})

	aadd( aRpt, {'L. Prod', {|| Field->long_prod }, "C", FLD_LONG_NU_PRODUCT, 0 , ;
      .f., .f. , 'Long Product (based on Imported data!'})

	aadd( aRpt, {'L. Proc', {|| Field->long_proc }, "C", FLD_LONG_NU_PROCESS, 0 , ;
      .f., .f. , 'Long Process (based on Imported data!'})

	aadd( aRpt, {'Imp Bat', {|| Field->imp_bat }, "N", FLD_DOCUMENT, 0 , ;
      .f., .f. , 'Import Batch Number (0=Manually input in office)'})

return( nil )

function rAdvancesPd( aRpt )

	aadd( aRpt, { {'Actual','Adv 1','Paid out'}, {|| ThisActualAdvPrice( 1 ) }, "N", 10,3 , ;
      .f., .f. , {'The actual Rate of Advance #1 Paid Out (0.00 if NOT paid)'} })

	aadd( aRpt, {{ 'Actual','Adv 2','Paid out'}, {|| ThisActualAdvPrice( 2 ) }, "N", 10,3 , ;
      .f., .f. , {'The actual Rate of Advance #2 Paid Out (0.00 if NOT paid)'} })

	aadd( aRpt, { {'Actual','Adv 3','Paid out'}, {|| ThisActualAdvPrice( 3 ) }, "N", 10,3 , ;
      .f., .f. , {'The actual Rate of Advance #3 Paid Out (0.00 if NOT paid)'} })

	aadd( aRpt, { {'Is','Adv1','Pd ?'}, ;
               {|| iif( field->post_bat1 > 0 .or. field->post_bat2 > 0 .or. field->post_bat3 > 0 .or. Field->fin_bat > 0,'PD  ', 'No  ') }, ;
                "C", 4, 0 , ;
      .f., .f. , {'Is Advance #1 Paid Out - PD if that advance is Pd, or Final is DONE'} })

	aadd( aRpt, { {'Is','Adv2','Pd ?'},  ;
               {|| iif(  field->post_bat2 > 0 .or. Field->post_bat3 > 0 .or. Field->fin_bat > 0,'PD', 'No')+space(2)}, ;
                "C", 4,0 , ;
      .f., .f. , {'Is Advance #2 Paid Out - PD if that advance is Pd, or Final is DONE'} })

	aadd( aRpt, { {'Is','Adv3','Pd ?'}, ;
               {|| iif( Field->post_bat3 > 0 .or. Field->fin_bat > 0,'PD', 'No')+space(2)}, ;
                "C", 4,0 , ;
      .f., .f. , {'Is Advance #3 Paid Out - PD if that advance is Pd, or Final is DONE'} })

return( nil )

///<summary>Has Slots for Extra columns!</summary>
function rProGradeEtc( aRpt )

	aadd( aRpt, { {'Grade','Name'}, {|| NameOf( LU_PROCESS_GRADE, Field->process, Field->grade ) }, "C", FLD_PROCESS_GRADE_NAME,0 , ;
      .f., .f. , {'Name of Grade-see the Process Table!'} })

   // if we need to add columns to reports we will use these slots  - Updated Mar 2020
   //             this consumes 2 of the spare columns
   /* ----------------------------------
	aadd( aRpt, { 'FC', {|| '' }, "C",  1,0 , ;
      .f., .f. , {'For Future Use 1 - Character string-probably should not use this now', ;
                  'We may change the way this column is used in later releases'   } })
	aadd( aRpt, { 'FC', {|| '' }, "C",  1,0 , ;
      .f., .f. , {'For Future Use 2- Character string-probably should not use this now', ;
                  'We may change the way this column is used in later releases'   } })
   ---------------------------------------- */

   aadd( aRpt, {'From Fld', {|| Field->from_field }, "C", FLD_FROM_FIELD , 0 , ;
      .f., .f. , {'Growers Field ID called ' +  ;
		                  iif( !empty( sysValue( SYS_IMPORT_FROM_FIELD_NAME )), ;
		                       alltrim( sysValue( SYS_IMPORT_FROM_FIELD_NAME )),'-not used-'), ;
						'The HARVESTed from FIELD-optional info'} } )

   aadd( aRpt, {'Imp?', {|| iif(Field->imported,'IMP','MAN') }, "C", 3  , 0 , ;
      .f., .f. , 'Imported=IMP, Input Manually=MAN' } )

	// Still Held in Reserve
	aadd( aRpt, { 'FU3', {|| 0 }, "N",  1,0 , ;
      .f., .f. , {'For Future Use 3- Numeric-probably should not use this now', ;
                  'We may change the way this column is used in later releases'   } })
	aadd( aRpt, { 'FU4', {|| 0 }, "N",  1,0 , ;
      .f., .f. , {'For Future Use 4- Numeric-probably should not use this now', ;
                  'We may change the way this column is used in later releases'   } })

	// May 2020
	aadd( aRpt, { 'Con Errs', {|| Field->CONT_ERRS }, "C", FLD_CONTAINER_ERRS , 0, ;
      .f., .f. , {'Container Import Errors-Shows up to 4 or so Containers recorded', ;
                  'in the Import File that could NOT be put into Ticket!'   } })
	aadd( aRpt, { 'Certified', {|| Field->CERTIFIED }, "C", FLD_CERTIFIED , 0,  ;
      .f., .f. , {'Certified Field - from Scale', ''   } })
	

return( nil )


