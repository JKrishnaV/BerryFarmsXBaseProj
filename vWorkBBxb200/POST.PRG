// Post.prg
// June 1999 - Revised to Show Berry Type
// June 2000 - Because we now have only Daily & to Show more info
//             about the cheque run....
// June 2011 - Improve Report a little.
// July 2014 - Put in some work for GST.
//             Note this File Assumes the existence of:
//                 TEMPAUD, TEMPACCT, TEMPA_A set up in
//                 Misc.prg -- MakeTempPostDBFs()
//                 Also some work with Acct_Uniq !
// May 2020    Fix Some stuff to do with Selecting a Printer

#include 'account.ch'
#include 'BerryPay.ch'
#include 'bsgstd.ch'
#include "common.ch"
#include 'printer.ch'
#include 'indexord.ch'
#include 'field.ch'
#include "berry_rpt.ch"
#include 'rpt.ch'
#include "valid.ch"
#include 'errors.ch'
#include 'tax.ch'
#include 'sysvalue.ch'

#define   A_GST_ARRAY           { 0, 0.00, 0, 0.00, ctod(''), 0.00000, '' }
#define   A_ELE_GROWER               1
#define   A_ELE_GST_AMT              2
#define   A_ELE_ACCOUNT_UNIQ_ID      3
#define   A_ELE_NON_GST_AMOUNT       4
#define   A_ELE_DATE                 5
#define   A_ELE_GST_RATE             6   // this should be ZERO or a fixed rate for all records in batch!
#define   A_ELE_DESC                 7   // We only write this when it is unusual

static lBadError := .f.

///<summary>Note cPostType and nPostBatch are optional</summary>
function Post2Account( nNextAcctUniq, aHeading, lPost, cPostType, nPostBatch )
	// assumes Printer is ON !
	// Posts transactions to Account from a File...
	local lReturn := .f.
	local aRpt := {}
	local aHead := {'Posting Journal'}
	local n, n1
   local cKey, cRate
	local lGst
	local nGST, nRate, nGST_total,nNonGST_total
	local dDate4Grow

	// local aRay
	local aGST4_1Grower, aGSTtoWrite
	local nGrower
	local nAcctUniq

   default cPostType  to ''
   default nPostBatch to 0

	nAcctUniq := nNextAcctUniq
	// Note that nAcctUniq is supposed to be the NEXT one

	msgLine('Checking for next account number...')
	if select('TempAud')==0 .or. select('TempAcct')==0 .or. select('TempA_A')==0
		appError( APP_ERR_TEMP_POSTING_FILES_01, ;
 		{'Temporary Posting Files are not set up as expected!', ;
		 'Check TempAud, TempAcct, TempA_A', ;
		 'We may crash - PLEASE NOTE this!'})
	else
		nAcctUniq := max( nAcctUniq, NextAcctUniq() )
		//
		TempAcct->(dbGoTop())
		n := 1
		do while !TempAcct->(eof())
			showProg( n++ )
			nAcctUniq := max( nAcctUniq, TempAcct->acct_uniq+1 )
			TempAcct->(dbSkip())
		enddo
	endif
	lBadError := .f.

	// We Re-Do the Tax Calculation HERE!
	msgLine('Hey we are calculating the GST now...')

	lGst := .t.
	nRate := TaxFinder( TAXNAME_IS_GST, TAX_VALUE_RATE,  date()-365 )
	if num5Equal0( nRate )
		nRate := TaxFinder( TAXNAME_IS_GST, TAX_VALUE_RATE,  date() )
		if num5Equal0( nRate )
			nRate := TaxFinder( TAXNAME_IS_GST, TAX_VALUE_RATE,  date()-15 )
			if num5Equal0( nRate )
				lGst := .f.
			endif
		endif
	endif

	if lGST
		// 2 BE Fixed!

		Account->(ordSetFocus( ACCOUNT_LINK_ORD ))
		Account->(dbGoBottom())

		EnsureOpen({'Grower','Product'})
		// waitInfo({'Tax Calc!!'})
		TempAcct->(dbGoTop())
		aGst4_1Grower  := {}
		aGstToWrite    := {}

		// These do not really need to be initialized, since if
		// nothing is writtne to aGST4_1Grower, these will not
		// be referenced.
		nGrower          := 0
		nGST_total       := 0.00000
		nNonGST_total    := 0.00
		dDate4Grow       := date() - 3650

		do while !TempAcct->(eof())
			nGrower          := TempAcct->number
			aGST4_1Grower    := {}
			nGST_total       := 0.00000
			nNonGST_total    := 0.00
			dDate4Grow       := date() - 3700   // 10 years ago

			do while nGrower == TempAcct->number .and. !TempAcct->(eof())
				lGST       := .f.
				if TempAcct->TYPE == TT_STD_DEDUCTION
					if ValidTest( V_GROWER, TempAcct->number, VT_MESSAGE )
						if ValidTest( V_PRODUCT, TempAcct->product, VT_MESSAGE )
							lGst := Product->chg_gst .and. Grower->chg_gst
							if lGst
								// Note that this rate should be the SAME all the time!
								nRate := TaxFinder( TAXNAME_IS_GST, TAX_VALUE_RATE, TempAcct->date  )
								nGST  :=  round( TempAcct->dollars * nRate,5)
								if num5NotEqual0( nGST )
									TempAcct->chg_gst    := .t.
									TempAcct->gst_rate   := nRate
									TempAcct->gst_est    := nGST   // estimate ONLY  !!!
									// TempAcct->nonGst_est := TempAcct->dollars

									nGST_total     +=  nGST
									nNonGST_total  += TempAcct->dollars
									//                            Grower        GST $     Link to this               NonGST $
									aadd( aGST4_1Grower,  A_GST_ARRAY )
									n := len( aGST4_1Grower )
									aGST4_1Grower[n, A_ELE_GROWER               ] := TempAcct->number
									aGST4_1Grower[n, A_ELE_GST_AMT              ] := nGst
									aGST4_1Grower[n, A_ELE_ACCOUNT_UNIQ_ID      ] := TempAcct->ACCT_UNIQ
									aGST4_1Grower[n, A_ELE_NON_GST_AMOUNT       ] := TempAcct->dollars
									aGST4_1Grower[n, A_ELE_DATE                 ] := TempAcct->date
									aGST4_1Grower[n, A_ELE_GST_RATE             ] := nRate
									dDate4Grow := max( dDate4Grow, TempAcct->date )
								endif
							endif
						endif
					endif
				endif
				TempAcct->(dbSkip())
			enddo

			n := 0
			if len( aGST4_1Grower ) > 0 .and. num2NotEqual0( round( nGST_total,2) ) // then we have some results
				nGrower           := aGST4_1Grower[ 1, A_ELE_GROWER ]

				// 2BFIXED - Now we check about GST rates....
            //    we sort on Rate & date
				ASort( aGST4_1Grower,,,  {|aX,aY| ;
				      str(aX[ A_ELE_GST_RATE],10,5) + dtos(aX[ A_ELE_DATE ]) >  ;
						str(aY[ A_ELE_GST_RATE],10,5) + dtos(aY[ A_ELE_DATE ]) } )

				cRate         := str( aGST4_1Grower[1, A_ELE_GST_RATE ], 10, 5 )
				dDate4Grow    := aGST4_1Grower[1, A_ELE_DATE ]
				nGST_total    := 0.00000
				nNonGst_Total := 0.00

				for n1 := 1 to len( aGST4_1Grower )
					if cRate <> str( aGST4_1Grower[n1, A_ELE_GST_RATE ], 10, 5 )

						appError( APP_ERR_MULTIPLE_GST_RATES_4GROWER, { ;
						    'Unusual NOT an ERROR - but there are multiple', ;
							 'GST Rates within this Payment Processing Run for' , ;
							 'grower#='+lStrim(nGrower), ;
							 'You may see a number of these messages'})

						aadd( aGSTtoWrite,  A_GST_ARRAY )
						n := len( aGSTtoWrite )
						aGSTtoWrite[n, A_ELE_GROWER               ] := nGrower
						aGSTtoWrite[n, A_ELE_GST_AMT              ] := round( nGST_Total,2)
						aGSTtoWrite[n, A_ELE_ACCOUNT_UNIQ_ID      ] := nAcctUniq
						aGSTtoWrite[n, A_ELE_NON_GST_AMOUNT       ] := nNonGst_Total
						aGSTtoWrite[n, A_ELE_DATE                 ] := dDate4Grow
						aGSTtoWrite[n, A_ELE_GST_RATE             ] := aGST4_1Grower[ n1, A_ELE_GST_RATE ]
						aGSTtoWRite[n, A_ELE_DESC                 ] := "Multiple GST rates in this run"

						// reset variables...
						cRate         := str( aGST4_1Grower[n1, A_ELE_GST_RATE ], 10, 5 )
						dDate4Grow    := aGST4_1Grower[n1, A_ELE_DATE ]
						nGST_total    := 0.00000
						nNonGst_Total := 0.00
					else
						dDate4Grow    := aGST4_1Grower[n1, A_ELE_DATE ]
						nGST_total    += aGST4_1Grower[n1, A_ELE_GST_AMT      ]
						nNonGst_Total += aGST4_1Grower[n1, A_ELE_NON_GST_AMOUNT ]
					endif

					// write out audit
					TempA_A->(addRecord())
					TempA_A->Acct_uniq  := nAcctUniq
					TempA_A->Acct_child := aGST4_1Grower[n1, A_ELE_ACCOUNT_UNIQ_ID ]
				next

				n1 := len( aGST4_1Grower )
				aadd( aGSTtoWrite,  A_GST_ARRAY )
				n := len( aGSTtoWrite )
				aGSTtoWrite[n, A_ELE_GROWER               ] := nGrower
				aGSTtoWrite[n, A_ELE_GST_AMT              ] := round( nGST_total,2)
				aGSTtoWrite[n, A_ELE_ACCOUNT_UNIQ_ID      ] := nAcctUniq
				aGSTtoWrite[n, A_ELE_NON_GST_AMOUNT       ] := nNonGst_Total
				aGSTtoWrite[n, A_ELE_DATE                 ] := dDate4Grow
				aGSTtoWrite[n, A_ELE_GST_RATE             ] := aGST4_1Grower[ n1, A_ELE_GST_RATE ]
				nAcctUniq++
				// This is the normal case no need to update the Desc
			endif
		enddo

		// Now we write out the GST records - or other weird bonus records....
		for n :=1 to len( aGSTtoWrite )
			TempAcct->(AddRecord())
			TempAcct->number     := aGSTtoWrite[ n, A_ELE_GROWER ]
			TempAcct->date       := aGSTtoWrite[ n, A_ELE_DATE ]
			TempAcct->year       := sysValue(SYS_CURRENT_YEAR)
			TempAcct->type       := TT_GST_TAX
			TempAcct->class      := TAX_TYPE_CL_AUTO_STD_DEDUCTION
			TempAcct->currency   := Grower->currency // has to be Looked Up
			TempAcct->acct_uniq  := aGSTtoWrite[n, A_ELE_ACCOUNT_UNIQ_ID ]
			TempAcct->dollars    := round( aGSTtoWrite[n, A_ELE_GST_AMT ], 2) // it should ALREADY be Rounded.
			TempAcct->nonGst_est := aGSTtoWrite[n, A_ELE_NON_GST_AMOUNT ] // it should ALREADY be Rounded.
			TempAcct->gst_rate   := aGSTtoWrite[n, A_ELE_GST_RATE ]

			TempAcct->desc       := aGSTtoWRite[n, A_ELE_DESC ]

         if !empty(  cPostType )
         	do case
            case cPostType == C_ACCOUNT_POST_TYPE_WEEKLY_1
            	TempAcct->adv_bat := nPostBatch
               TempAcct->adv_no  := 1

            case cPostType == C_ACCOUNT_POST_TYPE_WEEKLY_2
            	TempAcct->adv_bat := nPostBatch
               TempAcct->adv_no  := 2

            case cPostType == C_ACCOUNT_POST_TYPE_WEEKLY_3
            	TempAcct->adv_bat := nPostBatch
               TempAcct->adv_no  := 3

            case cPostType == C_ACCOUNT_POST_TYPE_FINAL
		         TempAcct->fin_bat := nPostBatch
            endcase
         endif

		next
	endif

	if valType(aHeading)=='A'
		for n := 1 to len(aHeading)
			aadd(aHead, aHeading[n] )
		next
	else
		aadd(aHead,aHeading)
	endif

   Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
	Grower->(dbGoTop())
	dbSelectAR( 'TempAcct' )
	// index on Currency

   cKey :=  'TempAcct->currency + str(TempAcct->number,4)+ TempAcct->type'

   TempAcct->( OrdCreate( 'TempAcct', 'USETHIS', cKey,   ;
      { || TempAcct->currency + str( TempAcct->number, FLD_GROWER) + ;
               TempAcct->type } ))

	set relation to str(Field->number,FLD_GROWER) into Grower

	BuildTheRpt( aRpt )
	// gRptInit(RP_ACCOUNT_POSTING, aRpt)
	gRptInitHead()
	gRptGetSetHead( RPT_HEAD_TITLE, aHead )

	gRptGetSetHead( RPT_HEAD_SUBTOTAL, .t. )
	gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| TempAcct->number } )
	gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
	 {|| nuQprnOut( 'Grower: '+str( TempAcct->number, FLD_GROWER)+' '+ ;
	            NameOf(LU_GROWER, TempAcct->number)       ) } )

	do while .t.
		TempAcct->(dbGoTop())

      if SelectPrn( 'POST2A_'+cPostType + var2char( nPostBatch ) )
			// For LandScape

         PRINT_ON  RPT_OVERWRITE

         gRptPrintSize( aRpt )

         TempAcct->(gRptPrinter( aRpt ))

         PrinterCtrl( PRN_CTRL_10_CPI )

         PRINT_OFF RPT_COMPLETE_EJECT
      endif

	   if !yesno({'Do you need to RePrint this Report?'})
	   	exit
	   endif
	enddo
	set relation to

	if lPost
		if yesno({'Post these transactions?', ;
			 'Yes - posts them to the financial file', ;
			 '      where they can be paid.', ;
			 'No  - resets them (your Grower', ;
			 '      receipts are NOT deleted).'})

			msgLine('Posting transactions')

			// Re-write in 2014 -
			showProg('Audit')
			TempAud->(ordSetFocus( 0 ))
			TempAud->(dbGoTop())
			do while !TempAud->(eof())
				if !CopyOneRec( 'TempAud', 'AUDIT')
					appError( APP_ERR_POSTING_CATASTROPHE_1, ;
					  {'Catastrophic ERROR in Posting - Please Restore Data', ;
					   'Affects the AUDIT.DBF table!', ;
					   'and call Crafted Industrial Software Ltd. 604-256-7485' })
					lBadError := .t.
					exit
				endif
				TempAud->(dbSkip())
			enddo

			showProg('Account')
			TempAcct->(ordSetFocus( 0 ))
			TempAcct->(dbGoTop())
			do while !TempAcct->(eof())
				if !CopyOneRec( 'TempAcct', 'ACCOUNT')
					appError( APP_ERR_POSTING_CATASTROPHE_2, ;
					  {'Catastrophic ERROR in Posting - Please Restore Data', ;
					   'Affects the ACCOUNT.DBF table - REALLY, really BAD!', ;
					   'and call Crafted Industrial Software Ltd. 604-256-7485' })
					lBadError := .t.
					exit
				endif
				TempAcct->(dbSkip())
			enddo

			TempA_A->(ordSetFocus( 0 ))
			TempA_A->(dbGoTop())
			do while !TempA_A->(eof())
				if !CopyOneRec( 'TempA_A', 'AUDACCT')
					appError( APP_ERR_POSTING_CATASTROPHE_3, ;
					  {'Catastrophic ERROR in Posting - Please Restore Data', ;
					   'Affects the AUDACCT.DBF table - REALLY, really BAD!', ;
					   'and call Crafted Industrial Software Ltd. 604-256-7485' })
					lBadError := .t.
					exit
				endif
				TempA_A->(dbSkip())
			enddo

			if lBadError
				lReturn := .f.
				WaitInfo({'This is a REALLY bad problem - COULD NOT update data correctly!!!', ;
				           'See error APP_ERR_POSTING_CATASTROPHE! '})
			else
				msgLine('Posting is complete')
				CloseTempPostDBFs( )
				lReturn := .t.
				waitInfo({'Posting Completed - You may now generate Cheques'})
			endif
		endif
	endif

return( lReturn )


static function BuildTheRpt( aRpt )

	aadd( aRpt, { '', { || ' ' }, ;
		'C', 1, 0 , .t. , .f. , 'Space' })

	// 123-56-8901
	aadd( aRpt, { 'Date', { || shMDY(Field->DATE) }, ;
		'C', 11, 0 , .t. , .f. , 'Date posted' })

	aadd( aRpt, {'Type', { || Field->TYPE }, ;
		'C',   003   ,  000, .t. , .f. , 'Type of Trans' })

	aadd( aRpt, {'Class', { || Field->class }, ;
		'C',   008 ,    000, .t. , .f., 'Class (usually of deduction)'})

   aadd( aRpt, {'Description', { || AcctEntryFancyDesc() }, ;
      'M',  FLD_DESC+1, 000, .t., .f.,  ;
		 'Multi-Line Description of Transaction' })

	aadd( aRpt, {'Prod', { || Field->product+' '+Field->process } ,;
		'C',  005,     000, .t. ,.f., 'Product/Process if Relevent' })

	aadd( aRpt, {' ', { || iif( Field->grade==0,' ',str(Field->grade,1) ) } , ;
		'C',  001,     000, .t. ,.f., 'Grade'} )

   // note that total would not make sense...
   aadd( aRpt, {'Wgt', { || Field->lbs }, ;
      'N',   008,     000, .t. , .f., 'Lbs of product for transaction'})

   aadd( aRpt, { {'Total','LBS'},;
      { || iif( Field->type==TT_BERRY_ADVANCE_1 .or. ;
                Field->type==TT_BERRY_ADVANCE_2 .or. ;
                Field->type==TT_BERRY_ADVANCE_3 .or. ;
                Field->type==TT_FINAL_BERRY , ;
                     Field->lbs,0 ) }, ;
      'N',   008,     000, .t. , .t., 'Total Lbs of product'})


	aadd( aRpt, {'Price', { || Field->u_price } ,;
		'N',  008,     003, .t. ,.f., 'Unit price - if Relevent'} )

	aadd( aRpt, {'GST', { || iif( Field->type==TT_GST_TAX, Field->dollars, 0.00) } ,;
		'N',  010,     002, .t. ,.f., 'GST Amount'} )

	aadd( aRpt, {'Deductions', ;
	  { || iif( (Field->type==TT_STD_DEDUCTION .or. Field->type==TT_DEDUCT) .or. ;
	           ( Field->type==TT_GST_TAX .and. Field->dollars <= -0.001), ;
		     Field->dollars , 0.00 ) } ,;
		'N',  010,     002, .t. ,.t., 'Payments - Deductions'} )

	aadd( aRpt, {'Payments', ;
	  { || iif( (Field->type==TT_STD_DEDUCTION .or. Field->type==TT_DEDUCT) .or. ;
	           ( Field->type==TT_GST_TAX .and. Field->dollars <= -0.001), ;
		 0.00, Field->dollars ) } ,;
		'N',  010,     002, .t. ,.t., 'Payments - Deductions excluded'} )

	// aadd( aRpt, {'Total', { || Field->dollars+Field->gst_est } ,;
	//   Changed to the Above Briefly

	aadd( aRpt, {'Total', { || Field->dollars } ,;
		'N',  010,     002, .t. ,.t., 'Total Value (including GST)'} )

	aadd( aRpt, {' ', { || Field->currency } ,;
		'C',  01,     000, .t. ,.f., 'Currency'} )

return( nil )


function AcctEntryFancyDesc( )
	local aReturn := {  }
	local cTmp

	cTmp := NameOf(  LU_TRANSACTION_TYPE,  Field->type )
	if !empty( cTmp )
		aadd( aReturn, alltrim(cTmp) )
	endif
	if !empty( Field->class )
		cTmp := NameOf(  LU_ALL_ACCOUNT_CLASSES,  Field->class )
		if !empty( cTmp )
			aadd( aReturn, alltrim(cTmp) )
		endif
	endif

	if !empty( Field->desc)
		aadd(aReturn, Field->desc)
	endif
	if Field->type==TT_GST_TAX
		aadd( aReturn,'Est NonGST Amt= '+DollarStr( Field->nongst_est,12))
		if num5NotEqual0(Field->gst_rate)
			aadd( aReturn,'GST Rate= '+lstrim( Field->gst_rate*100,3)+'%')
		endif
	else
		if num2NotEqual0( Field->gst_est) .or. Field->chg_gst
			aadd( aReturn,'Est GST = '+DollarStr( Field->gst_est,12))
		endif
	endif

	if len( aReturn ) == 0
		aadd( aReturn,'')
	endif

return( aReturn )
