// PROGRAM...: ACC_RPT.PRG
// AUTHOR ...: Bill Hepler
// DATE .....: July 12, 2011 - not actually used
//             Revised very substantially July 10, 2014 to serve as a GST register
//             July 16, 2014 before GST is actually implemented I changed this.
//             March 08,2019 Legend Stuff
// NOTES ....: This is intended as a GST register

// (c) Copyright 2014, 2019 Bill Hepler & Crafted Industrial Software

#include 'inkey.ch'
#include 'BerryPay.ch'
#include 'window.ch'
#include 'printer.ch'
#include 'bsgstd.ch'
#include 'valid.ch'
#include 'rpt.ch'
#include "field.ch"
#include "indexord.ch"
#include 'combobox.ch'
#include 'sysvalue.ch'
#include 'errors.ch'
#include 'berry_rpt.ch'
#include 'account.ch'

#define   GST_STATUS_NOT_RELATED_TRANSACTIONS     1
#define   GST_STATUS_GST_RELATED_TRANSACTIONS     2
#define   GST_STATUS_ANY_TRANSACTIONS             3

function acc_rpt(  )
	local getList :={}, dFrom,dTo, nGrower, aWin
   local aTitle
   local cRpt := REPORTS_ACCOUNT_ONLY_GST  // default
	local aRpt
	local lConfigure := .f., lLegend := .f.
	local aCombo1, aCombo2
	local bWhile, bFor1, bFor2, bFor3
	local nGSTstatus := GST_STATUS_GST_RELATED_TRANSACTIONS ,  nValue     := 3, n := 0

   dFrom  := date()-30
   dTo    := date()

	nGrower := 0
	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

   myBsgScreen( 'GST Tax Register' )
	msgLine('GST Tax Register Reports')
   
   create window at 4,08,21,70 title 'GST Tax Register ' to aWin
	display window aWin

	IN WINDOW aWin CREATE COMBOBOX AT 11,02 ;
           WINSAY 'Tax Related' USING { ;
		'No GST Tax on Transaction  ', ;
		'Only Transactions with GST ', ;
		'Do not select on GST Status' }   ;
	 MESSAGE ;
    'Select the GST status of transctions to print' ;
	  TO aCombo1

	IN WINDOW aWin CREATE COMBOBOX AT 14,02 ;
           WINSAY 'Report on' USING { ;
		'UnPosted Receipts Only', ;
		'Posted (paid) Only    ', ;
		'Both Posted & Unposted' }   ;
	 MESSAGE ;
    'Posted transactions are (almost always) paid - and can not be edited' ;
	  TO aCombo2

	ComboBoxShow( aCombo1,  nGSTstatus )
	ComboBoxShow( aCombo2,  nValue )

	do while .t.
		msgLine('[Esc] to Exit')
		in window aWin @ 2,2  winsay 'Select a date range for the report:'
		in window aWin @ 3,2 winsay 'From  ' winget dFrom picture '@d' ;
		 get_message 'Starting Date for Report,  +/- to adjust'
		in window aWin @ 4,2 winSAY 'To    ' winget dTo picture '@d' ;
		 get_message 'Ending Date for Report, +/- to adjust'

		in window aWin @ 6,2 winsay 'Grower' winget nGrower ;
		 PICTURE numBlankPic(FLD_GROWER) ;
		 valid PutName(aWin,6,20,LU_GROWER,nGrower) ;
		 LOOKUP(LU_GROWER, ;
		'Select a specific Grower or leave blank for all,   [F5] to Browse Growers')

		in window aWin @ 8,02 winsay 'Configure Report  ' winget lConfigure ;
		 picture 'Y'  GET_MESSAGE ;
		'You may select and order the columns to be printed'

		in window aWin @ 9,02 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

		read

		do case
		case lastkey()==K_ESC
			exit
		endcase

      aTitle := { TheClientName( ), ;
               cRpt+' GST Ledger from '+shMdy(dFrom)+' to '+shMdy(dTo) }

		n := ComboBoxDo( aCombo1,  nGSTstatus )
		do case
		case n == 0 .or. lastkey() == K_ESC
			loop
		case n == 1
			bFor3 := { || Num2Equal0( Account->Gst_est ) .and. ;
             			!Account->chg_gst, Account->type <> TT_GST_TAX }
			aadd( aTitle,'Transactions with NO GST charged')
			cRpt := REPORTS_ACCOUNT_NO_GST
		case n == 2
			bFor3 := { || Num2NotEqual0( Account->Gst_Est ) .or. Account->chg_gst .or. ;
			              Account->type == TT_GST_TAX }
			aadd( aTitle,'Only transactions related to GST charges')
			cRpt  := REPORTS_ACCOUNT_ONLY_GST
		otherwise
			bFor3 := { || .t. }
			aadd( aTitle,'Does not select transaction based on GST')
			cRpt := REPORTS_ACCOUNT_ANY_TRANS_GST
		endcase
		nGSTstatus := n   // this ignores the return value of 0
		in window aWin @ 16, 02 winsay 'Report format selected is: '+cRpt

		n    := ComboBoxDo( aCombo2,  nValue )
		do case
		case n == 0 .or. lastkey() == K_ESC
			loop
		case n == 1
			aadd(aTitle,'Unposted Transactions')
			bFor2  :=  { || Num2Equal0( Account->cheque ) }
		case n == 2
			aadd( aTitle,'Posted Transactions Only')
			bFor2  := { || Num2NotEqual0( Account->cheque ) }
		case n == 3
			aadd( aTitle,'Posted & Unposted Transactions' )
			bFor2 := { || .t. }
		endcase
		nValue := n

		aRpt := {}
		SetTheRpt( aRpt )
      gRptInit( cRpt, aRpt)

		if lConfigure
			gRptSelect( aRpt )
		endif

      Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))
      Account->(dbSetRelation( 'Grower', ;
       { || str( Account->number,FLD_GROWER) } ) )
      Account->(OrdSetFocus(ACCOUNT_NUMBER_ORD))
      bFor1 := { || Account->date >= dFrom .and. Account->date <= dTo }

		msgLine('Positioning....')

      if empty(nGrower)
         Account->(dbGoTop( ))
         bWhile := { || .t. }
			aadd( aTitle, 'All Growers')
      else
         Account->(dbSeek( str(nGrower,FLD_GROWER)+dtos(dFrom), SOFTSEEK))
         bWhile := { || Account->number == nGrower }
			aadd( aTitle, 'Grower: '+lStrim(nGrower)+' '+alltrim(NameOf( LU_GROWER, nGrower )))
      endif

		do while !Account->(eof()) .and. Account->(eval(bWhile)) ;
		     .and. !( Account->( eval( bFor1)) .and. ;
		              Account->( eval( bFor2)) .and. ;
						  Account->( eval( bFor3)) )

			Account->(dbSkip())
		enddo

		if Account->(eof()) .or. !Account->( eval( bWhile )) ;
		     .or. !Account->( eval( bFor1))  ;
		     .or. !Account->( eval( bFor2))  ;
			  .or. !Account->( eval( bFor3))

			WaitInfo({'Having trouble finding relevant transactions!', ;
			          iif( Account->(eof()),'At end of ACCOUNTs list','Recno()='+lstrim(Account->(recno()))+' Trn#='+lStrim(Account->acct_uniq)), ;
						 'While Condition:'+iif( eval( bWhile),'OK','Not found-'+lStrim(Account->number) ), ;
			          'Dates:'+iif( eval(bFor1),'OK','Not found-'+shMdy( Account->date) ),  ;
						 'Posting Status:'+iif( eval(bFor2),'OK','Not Found CHQ-'+Account->series+lStrim(Account->Cheque)), ;
						 'GST Charged:'+iif( eval(bFor3),'OK','Not found-GST='+str( Account->Gst_Est,10,2)), ;
						 '            '+'  '+iif( Account->chg_gst,'No GST charged','')+' '+iif(Account->type == TT_GST_TAX,'GST Tax Charge!','Type='+Account->type)  })
		endif

		msgLine('Ready to report...')
		gRptInitHead()
		gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

		gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| Account->number } )
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
		 {|| nuQprnOut( str( Account->number,FLD_NUMBER)+' '+Grower->name ) } )

		gRptGetSEtHead( RPT_HEAD_FOR_CONDITION, { || eval(bFor1) .and. eval(bFor2) .and. eval(bFor3) })
		gRptGetSetHead( RPT_HEAD_WHILE_CONDITION, bWhile )

		if selectPrn( 'ACCOUNT.TXT')
			// For LandScape
			gRptAutoPageOrientation( aRpt, 0)

			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

			Account->(gRptPrinter( aRpt ))
			if lLegend
				prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
			endif

			PRINT_OFF  RPT_COMPLETE_EJECT

			if lConfigure
				if yesno({'Save this Report Format for '+cRpt+' ?'})
					gRptSave( aRpt )
				endif
				lConfigure := .f.
			endif
		endif

		Account->(dbClearFilter())
		Account->(dbClearRelation())
	enddo

	ComboBoxKill( aCombo1 )
	kill window aWin
	close databases
RETURN( nil )


static function SetTheRpt( aRpt )  // , nGSTstatus )
	// this report is defined for 2014 Season only

   aadd( aRpt,{ ' ',{|| ' '}, 'C', 1, 0, .t., .f., 'a Nice Space'} )

	// 2014 Experiment with Bands
	aadd( aRpt, ;
	{ ' '  	, { || '' }      ,  'C' ,    15  ,   000 , ;
		.t., .f. , ;
		'Space for Looks-by default, originally set as band 2', 2 } )

	aadd( aRpt,{ 'Trn #',{|| Account->acct_uniq} , "N", 8, 0 , ;
      .t., .f. , 'Transaction #'})

   aadd( aRpt, {'Date', {|| shMDY(Account->date) }, "C", 6, 0 , ;
      .t., .f. , 'Date of Receipt'})

   aadd( aRpt, {'Type', {|| Account->type }, "C", 4, 0 , ;
      .t., .f. , 'Type of transaction'})
   aadd( aRpt, { 'Class', {|| Account->class},   'C',  9, 0 , .t., .f., ;
    'Class of the Transaction'})

   aadd( aRpt, ;
	{ 'Description' , { || AcctEntryFancyDesc( ) }       ,  'M' ,   FLD_DESC,   000 , ;
		.T., .F. , ;
		'Full MultiLine Description of Transaction' } )

   aadd( aRpt, { 'Cheque', {|| iif( Num2Equal0(Account->cheque), ;
                space(9),  Account->series+ strZero( Account->cheque,6))  },   'C',  9, 0 , .t., .t., ;
    'Cheque Number Including Series...'})

   aadd( aRpt, { 'Curr',  ;
     {|| Account->currency  }, 'C', 4, 0 , .f., .f., ;
      'Currency'})

	// Added July 2014
	aadd( aRpt, ;
	{ {'Est','$ Non-Gst','Est Base'}  	, { || Account->NONGST_est }      ,  'N' ,    012  ,   002 , ;
		.t., .t. , ;
		'Est. of NonGST Base Amt - sb Correct for Wkly Marketing Ded' } )

	aadd( aRpt, ;
	{ '$ Est GST'  	, { || Account->Gst_est }      ,  'N' ,    012  ,   002 , ;
		.t., .t. , ;
    'GST ESTIMATED amount PER GST taxable Transaction-Deductions are NEGATIVE' } )

	// changed to include GST July 2014
   aadd( aRpt, ;
	{ {'Actual','$ NonGST'}	, { || iif( Account->type==TT_GST_TAX, 0.00, Account->dollars) }      ,  'N' ,    012  ,   002 , ;
		.t., .t. , ;
		'Actual Non GST Amounts (based on Transaction Type)' } )

   aadd( aRpt, ;
	{ {'Actual','$ GST'}	, { || iif( Account->type==TT_GST_TAX, Account->dollars, 0.00 )}      ,  'N' ,    012  ,   002 , ;
		.t., .t. , ;
		'Actual Reportable GST Amounts (based on Transaction Type)' } )

   aadd( aRpt, ;
	{ '$ Total'  	, { || Account->dollars }      ,  'N' ,    012  ,   002 , ;
		.t., .t. , ;
		'Actual Total Amount Including GST' } )

	// Experiment with Bands
	aadd( aRpt, ;
	{ 'Desc'   	, { || Account->desc }       ,  'C' ,   FLD_DESC,   000 , ;
		.T., .F. , ;
		'Description input when transaction set up', 2 } )

	aadd( aRpt, ;
	{ ' '  	, { || '' }      ,  'C' ,    1  ,   000 , ;
		.f., .f. , ;
		'Another Space for Looks' } )

   aadd( aRpt, ;
	{ 'GST Rate'  	, { || iif( num5NotEqual0(Account->gst_rate), str(Account->gst_rate*100,5,2)+'%', '' )}      ,  'C' ,    006  ,   000 , ;
		.f., .f. , ;
		'GST Tax Rate (if relevant)' } )

return( nil )

