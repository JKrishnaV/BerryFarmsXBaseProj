// Lookup.prg
// to Browse data.....
// (c) copyright 1993, 2011, 2015 by Bill Hepler
// Rev 2011 - minor changes here & there
// Minor change for Posted Status...
// June 2015 - browse import batch..
// July 2017 - File and Path fix which did not work before !
// Apr 2019 - Browse of Process Table Changed.
//            Printing more of the browese
// May 2023 - minor change to browse folders.

#include "ACCOUNT.CH"
#include "Appevent.ch"
#include 'arrays.ch'
#include "BerryPay.ch"
#include "browser.ch"
#include "bsgstd.ch"
#include "colors.ch"
#include "common.ch"
#include "errors.ch"
#include "field.ch"
#include "indexord.ch"
#include "inkey.ch"
#include "printer.ch"
#include "setcurs.ch"
#include "SIGNON.CH"
#include "SYSVALUE.CH"
#include "valid.ch"
#include "WINDOW.CH"
#include "Xbp.ch"

#pragma library("XppUi2")

#define PRINT_THE_BROWSE  tbKeyCfg(oTb,  { K_ALT_P, {||PrintTb(oTb)   } } )
#define FANCY_FINDER      tbKeyCfg(oTb,  { K_ALT_F, {||cisLtdFinder(oTb) } } )

// for Account->type & Account->class
// static aTransDesc    := A_TRANSACTION_TYPE_ARRAY
//    not needed as of July 2014 as we only add/edit some kinds of tansactions

static aDedClass     := A_DEDUCTION_CLASS_ARRAY
static aAllAcctClass := A_ALL_ACCOUNT_TYPE_CLASSES_ARRAY
static aTaxClass     := A_TAX_CLASSES_ARRAY
static aMayAdd       := A_MAY_ADD_TRANSACTION_TYPE_ARRAY
static aProdCat      := {}
static aProcClass    := PROCESS_CLASS_ARRAY

// Print Associated Field At Window Location  using NameOf()
function PutName(aWin,nRow,nCol, nSig,cVar)
	// almost always used in WHEN clause
	IN WINDOW aWin @ nRow,nCol WINSAY NameOf(nSig,cVar)
return( .t. )

function FancyGets( nSig,cMsg, get, getlist, xInfo)
   local aMsg, bLu ,bPlus, bMinus, bF3, bTs, bTc
	local lD := .f.

	if valtype(nSig)=='N'
		DEFAULT cMsg TO '[F5] to Browse Valid Entries'
      bLu := setkey( K_F5, {|| Browses( getlist,nSig,xInfo) })
	else
		bLu := setkey( K_F5, nil )
	endif
	if valType(cMsg)=='C'
		aMsg := msgLine(cMsg)
	endif
	if get:type=='D'
		lD     :=  .t.
		bPlus  := setKey( 43,  {|| DateNiceKey() } )
		bMinus := setKey( 45,  {|| DateNiceKey() } )
		bTc    := setKey( 84,  {|| DateNiceKey() } )
		bts    := setKey( 116, {|| DateNiceKey() } )
		bF3    := setKey( K_F3,{|| DateNiceKey() } )
	endif

	GetReader( get )

  	setkey( K_F5, bLu )

	if lD
		setKey( 43,bPlus)
		setKey( 45,bMinus)
		setKey( 84,bTC )
		setKey( 116, bTs )
		setKey( K_F3, bF3 )
	endif

	if valtype(aMsg)=='A'
		rest_scr(aMsg)
	endif

return( nil )

function DateNiceKey()
	local oGet
	local dDate

	oGet := getActive()
	if valType(oGet)=='O'
		do case
		case oGet:type=='D'
			dDate := oGet:VarGet()
			do case
			case empty(dDate)
				oGet:VarPut( date() )
			case lastkey()==K_F3
				oGet:VarPut( date() )
			case lastkey()==43  // plus
				oGet:VarPut( dDate+1 )
			case lastkey()==45  // Minus
				oGet:VarPut( dDate-1 )
			case upper( chr(lastkey())) == 'T'
				oGet:VarPut( date() )
			endcase
		endcase
	endif
return( nil )

function Browses( theGetList, nMessage, xInfo )
	local oGet, cToSeek, oTb, nToSeek, xVal, n,   aMsg
	local nRecNo, lGet := .t.
   local n1,n2
   local aUiPrn := UI_PRN_ARRAY
   local oFileDialog
   local c1, c2
	local lReturn := .f.

	// usually this is called from a READ, but in a few cases, not...
	oGet := getActive()
	if valType(oGet)=='U'
		lGet := .f.
		cToSeek     := ''
		nToSeek     := 0
	else
   	xVal := oGet:varGet()
		do case
		case valtype(xVal)=='C'
   		cToSeek     := upper( rtrim( xVal ) )
		case valType(xVal)=='D'
			cToSeek := dtos(xVal)
		case valType(xVal)=='N'
   		cToSeek := ''
   		nToSeek := xVal
   	endcase
   endif

	if Security('P')
		aMsg := msgLine( ;
'[Enter] -Select            [Alt P] -Print           [Alt F] -Finder')
	else
		aMsg := msgLine( ;
'[Enter] - Select            [Alt F] - the Finder')
	endif

	do case
	case nMessage == LU_PROCESS_TYPE
    	if !EnsureOpen({'Process'})
	    	return( nil )
	   endif
      Process->(OrdSetFocus(PROCESS_PROCESS_ORD))
		Process->(dbSeek( cToSeek ,SOFTSEEK))

      if sysValue( SYS_USE_PROCESS_GRADE_NAMES  )
	      oTb := tBrowCreate(7,4,16)
      else
	      oTb := tBrowCreate(7,20,16)
      endif

		tbColAdd( oTb, tbcolCreate('ID', ;
			 {|| Process->process }) )
		tbColAdd( oTb, tbcolCreate('Description',{|| Process->desc }) )
      tbColAdd( oTb, tbcolCreate('Class   ', ;
        {|| NameOf( LU_PROCESS_CLASS, Process->proc_class) }) )

      if sysValue( SYS_USE_PROCESS_GRADE_NAMES  )
			tbColAdd( oTb, tbcolCreate('Gr 1',  {|| Process->grade_n1 }) )
			tbColAdd( oTb, tbcolCreate('Gr 2',  {|| Process->grade_n2 }) )
			tbColAdd( oTb, tbcolCreate('Gr 3',  {|| Process->grade_n3 }) )
      endif

      PRINT_THE_BROWSE

		if Process->(eof())
			Process->(dbGoBottom())
		endif

		if Process->(theBrowse(oTb))
			oGet:varPut( Process->process )
			lReturn := .t.
		endif

	case nMessage == LU_PRODUCT
    	if !EnsureOpen({'Product'})
	    	return( nil )
	   endif
      Product->(OrdSetFocus(PRODUCT_PRODUCT_ORD))
		Product->(dbSeek( cToSeek ,SOFTSEEK))

		if Product->(eof())
			Product->(dbGoBottom())
		endif

		oTb := tBrowCreate(7,12,16,68)     // desc field here is short!
		tbColAdd( oTb, tbcolCreate('ID', ;
			 {|| Product->product }) )
		tbColAdd( oTb, tbcolCreate('Description',{|| Product->desc }) )
      tbColAdd( oTb, tbcolCreate('Deduction',  {|| Product->deduct }) )
      tbColAdd( oTb, tbcolCreate('Cat',  {|| Product->category }) )
		tbColAdd( oTb, tbcolCreate('Cat Desc',  {|| NameOf(LU_PRODUCT_CATEGORY,Product->category )}) )
		tbColAdd( oTb, tbcolCreate('GST',  {|| iif(Product->chg_gst,'GST','   ') }) )
		tbColAdd( oTb, tbcolCreate('Defa Variety',  {|| Product->variety }) )

		PRINT_THE_BROWSE

		if Product->(theBrowse(oTb))
			oGet:varPut( Product->product )
			lReturn := .t.
		endif

	case nMessage == LU_VARIETY

    	if !EnsureOpen({'Variety'})
	    	return( nil )
	   endif
      Variety->(OrdSetFocus(VARIETY_VARIETY_ORD))
		Variety->(dbSeek( cToSeek ,SOFTSEEK))

      oTb := tBrowCreate(7,20,16)
		tbColAdd( oTb, tbcolCreate('ID', ;
			 {|| Variety->variety }) )
		tbColAdd( oTb, tbcolCreate('Var Description',{|| Variety->desc }) )

      PRINT_THE_BROWSE

		if Variety->(eof())
			Variety->(dbGoBottom())
		endif

		if Variety->(theBrowse(oTb))
			oGet:varPut( Variety->variety )
			lReturn := .t.
		endif

	case nMessage == LU_DEPOT
    	if !EnsureOpen({'Depot'})
	    	return( nil )
	   endif
      Depot->(OrdSetFocus(DEPOT_DEPOT_ORD))
		Depot->(dbSeek( cToSeek ,SOFTSEEK))

		if Depot->(eof())
			Depot->(dbGoBottom())
		endif

		oTb := tBrowCreate(7,22,15,55) // desc fld is short
		tbColAdd( oTb, tbcolCreate('ID', ;
			 {|| Depot->depot }) )
		tbColAdd( oTb, tbcolCreate('Name/Desc',{|| Depot->depotname }) )

      PRINT_THE_BROWSE

		if Depot->(theBrowse(oTb))
			oGet:varPut( Depot->depot )
			lReturn := .t.
		endif

	case nMessage == LU_PAYGRP
    	if !EnsureOpen({'PayGrp'})
	    	return( nil )
	   endif
      PayGrp->(OrdSetFocus(PAYGRP_PAYGRP_ORD))
		PayGrp->(dbSeek( cToSeek ,SOFTSEEK))

		if PayGrp->(eof())
			PayGrp->(dbGoBottom())
		endif

		oTb := tBrowCreate(7,22,16,58)     // desc field here is short!
		tbColAdd( oTb, tbcolCreate('ID', ;
			 {|| PayGrp->PayGrp }) )
		tbColAdd( oTb, tbcolCreate('Description',{|| PayGrp->desc }) )
		tbColAdd( oTb, tbcolCreate('D-PrLvl',{|| PayGrp->def_prLvl} ) )

      PRINT_THE_BROWSE

		if PayGrp->(theBrowse(oTb))
			oGet:varPut( PayGrp->PayGrp   )
			lReturn := .t.
		endif

	case nMessage == LU_CONTAINER
    	if !EnsureOpen({'Contain'})
	    	return( nil )
	   endif
      Contain->(OrdSetFocus(CONTAIN_CONTAINER_ORD))
		Contain->(dbSeek( str(nToSeek,FLD_CONTAINER) ,SOFTSEEK))

		if Contain->(eof())
			Contain->(dbGoBottom())
		endif

		oTb := tBrowCreate(7,10,16,74)
		tbColAdd( oTb, tbcolCreate('Type', ;
			 {|| str(Contain->container,FLD_CONTAINER) }) )
		tbColAdd( oTb, tbcolCreate('Description',{|| Contain->desc }) )
		tbColAdd( oTb, tbColCreate('Value',{|| str(Contain->value,10,2)}))
		tbColAdd( oTb, tbColCreate('inUse?', ;
			 {|| iif(Contain->inUse,'  Y   ','--NO--' )}))
		tbColAdd( oTb, tbcolCreate('Short',{|| Contain->short }) )

      PRINT_THE_BROWSE

		if Contain->(theBrowse(oTb))
			oGet:varPut( Contain->container )
			lReturn := .t.
		endif

	case nMessage == LU_BANK_STATEMENT
    	if !EnsureOpen({'BankRec'})
	    	return( nil )
	   endif
      BankRec->(OrdSetFocus(GROWER_NUMBER_ORD))
		BankRec->(dbSeek(cToSeek,SOFTSEEK))
		if BankRec->(eof())
      	BankRec->(dbGoTOp())
      endif

		oTb := tBrowCreate(7,10,16,74)
		tbColAdd( oTb, tbcolCreate('Acct. Date',{|| shMDY(BankRec->acctDate) }) )
		tbColAdd( oTb, tbcolCreate('Date Done',{|| shMDY(BankRec->DateDone) }) )
		tbColAdd( oTb, tbColCreate('Desc',{|| BankRec->note}))
		tbColAdd( oTb, tbColCreate('Amount',{|| BankRec->amount}))

      PRINT_THE_BROWSE

		if BankRec->(theBrowse(oTb))
			oGet:varPut( BankRec->acctDate )
			lReturn := .t.
		endif


	 case nMessage == LU_MAY_ADD_TRANSACTION_TYPE
	 	nRecNo := ArraySeek( ARRAY:aMayAdd  VALUE:cToSeek )
	 	if nRecno<1
	 		nRecno := 1
	 	endif

		oTb := tBrowCreate(7,20,15)
		tbColAdd( oTb, tbcolCreate('Code',{|| aMayAdd[nRecNo,A_TT_COLUMN_CODE]}) )
		tbColAdd( oTb, tbcolCreate('Description',{|| aMayAdd[nRecNo, A_TT_COLUMN_DESC]}) )

		tbMainCfg( oTb, CB_GOTOP,	 {|| nRecno := 1})
		tbMainCfg( oTb, CB_GOBOTTOM, {|| nRecno := len(aMayAdd) })
		tbMainCfg( oTb, CB_WHILE, {|| nRecNo >=1 .or. nRecNo <= len(aMayAdd) })
		tbMainCfg( oTb, CB_SKIP, {| n | ArraySkipper( n, @nRecno, aMayAdd )})

      PRINT_THE_BROWSE

		if theBrowse(oTB)
         oGet:varPut(aMayAdd[nRecno,A_TT_COLUMN_CODE])
			lReturn := .t.
      endif

	 case nMessage == LU_DEDUCTION_CLASS
	 	nRecNo := ArraySeek( ARRAY:aDedClass  VALUE:cToSeek )
	 	if nRecno<1
	 		nRecno := 1
	 	endif

		oTb := tBrowCreate(7,20,15)
		tbColAdd( oTb, tbcolCreate('Code',{|| aDedClass[nRecNo, A_SINGLE_TYPE_CLASS_COLUMN_CODE ]}) )
		tbColAdd( oTb, tbcolCreate('Description',{|| aDedClass[nRecNo, A_SINGLE_TYPE_CLASS_COLUMN_DESC ]}) )

		tbMainCfg( oTb, CB_GOTOP,	 {|| nRecno := 1})
		tbMainCfg( oTb, CB_GOBOTTOM, {|| nRecno := len(aDedClass) })
		tbMainCfg( oTb, CB_WHILE, {|| nRecNo >=1 .or. nRecNo <= len(aDedClass) })
		tbMainCfg( oTb, CB_SKIP, {| n | ArraySkipper( n, @nRecno, aDedClass )})

      PRINT_THE_BROWSE

		if theBrowse(oTB)
         oGet:varPut(aDedClass[nRecno,A_SINGLE_TYPE_CLASS_COLUMN_CODE])
			lReturn := .t.
      endif

	case nMessage == LU_GST_TAX_CLASS
	 	nRecNo := ArraySeek( ARRAY:aTaxClass  VALUE:cToSeek )
	 	if nRecno<1
	 		nRecno := 1
	 	endif

		oTb := tBrowCreate(7,20,15)
		tbColAdd( oTb, tbcolCreate('Code',{|| aTaxClass[nRecNo, A_SINGLE_TYPE_CLASS_COLUMN_CODE ]}) )
		tbColAdd( oTb, tbcolCreate('Description',{|| aTaxClass[nRecNo, A_SINGLE_TYPE_CLASS_COLUMN_DESC ]}) )

		tbMainCfg( oTb, CB_GOTOP,	 {|| nRecno := 1})
		tbMainCfg( oTb, CB_GOBOTTOM, {|| nRecno := len(aTaxClass) })
		tbMainCfg( oTb, CB_WHILE, {|| nRecNo >=1 .or. nRecNo <= len(aTaxClass) })
		tbMainCfg( oTb, CB_SKIP, {| n | ArraySkipper( n, @nRecno, aTaxClass )})

      PRINT_THE_BROWSE

		if theBrowse(oTB)
			lReturn := .t.
			oGet:varPut(aTaxClass[nRecno,A_SINGLE_TYPE_CLASS_COLUMN_CODE])
      endif


	 case nMessage == LU_ALL_ACCOUNT_CLASSES
	 	nRecNo := ArraySeek( ARRAY:aAllAcctClass  VALUE:cToSeek )
	 	if nRecno<1
	 		nRecno := 1
	 	endif

		oTb := tBrowCreate(7,20,15)
		tbColAdd( oTb, tbcolCreate('Code',{|| aAllAcctClass[nRecNo,A_ALL_TYPE_CLASSES_COLUMN_CLASS_CODE ]}) )
		tbColAdd( oTb, tbcolCreate('Description',{|| aAllAcctClass[nRecNo, A_ALL_TYPE_CLASSES_COLUMN_DESC ]}) )

		tbMainCfg( oTb, CB_GOTOP,	 {|| nRecno := 1})
		tbMainCfg( oTb, CB_GOBOTTOM, {|| nRecno := len(aAllAcctClass) })
		tbMainCfg( oTb, CB_WHILE, {|| nRecNo >=1 .or. nRecNo <= len(aAllAcctClass) })
		tbMainCfg( oTb, CB_SKIP, {| n | ArraySkipper( n, @nRecno, aAllAcctClass )})

      PRINT_THE_BROWSE

		if theBrowse(oTB)
         oGet:varPut(aAllAcctClass[nRecno,A_ALL_TYPE_CLASSES_COLUMN_CLASS_CODE ])
			lReturn := .t.
      endif

	case nMessage == LU_CLASS_FOR_A_TYPE
		// Now there are ONLY 2 types with Classes, so we do this!
		do case
		case valType( xInfo ) <> 'C'
			appError( APP_ERR_ACCT_TYPE_CLASS_01 , ;
			  { 'The xInfo Variable is not defined!', ;
			    'We can not browse the Classes for this TYPE of Financial transaction', ;
				 'because the Type of Financial Transaction is not known' })
		case xInfo == TT_DEDUCT
			nRecNo := ArraySeek( ARRAY:aDedClass  VALUE:cToSeek )
			if nRecno<1
				nRecno := 1
			endif

			oTb := tBrowCreate(7,20,15)
			tbColAdd( oTb, tbcolCreate('Code',{|| aDedClass[nRecNo, A_SINGLE_TYPE_CLASS_COLUMN_CODE ]}) )
			tbColAdd( oTb, tbcolCreate('Description',{|| aDedClass[nRecNo, A_SINGLE_TYPE_CLASS_COLUMN_DESC ]}) )

			tbMainCfg( oTb, CB_GOTOP,	 {|| nRecno := 1})
			tbMainCfg( oTb, CB_GOBOTTOM, {|| nRecno := len(aDedClass) })
			tbMainCfg( oTb, CB_WHILE, {|| nRecNo >=1 .or. nRecNo <= len(aDedClass) })
			tbMainCfg( oTb, CB_SKIP, {| n | ArraySkipper( n, @nRecno, aDedClass )})

	      PRINT_THE_BROWSE

			if theBrowse(oTB)
				oGet:varPut(aDedClass[nRecno,A_SINGLE_TYPE_CLASS_COLUMN_CODE])
				lReturn := .t.
			endif

		case xInfo == TT_GST_TAX
			nRecNo := ArraySeek( ARRAY:aTaxClass  VALUE:cToSeek )
			if nRecno<1
				nRecno := 1
			endif

			oTb := tBrowCreate(7,20,15)
			tbColAdd( oTb, tbcolCreate('Code',{|| aTaxClass[nRecNo, A_SINGLE_TYPE_CLASS_COLUMN_CODE ]}) )
			tbColAdd( oTb, tbcolCreate('Description',{|| aTaxClass[nRecNo, A_SINGLE_TYPE_CLASS_COLUMN_DESC ]}) )

			tbMainCfg( oTb, CB_GOTOP,	 {|| nRecno := 1})
			tbMainCfg( oTb, CB_GOBOTTOM, {|| nRecno := len(aTaxClass) })
			tbMainCfg( oTb, CB_WHILE, {|| nRecNo >=1 .or. nRecNo <= len(aTaxClass) })
			tbMainCfg( oTb, CB_SKIP, {| n | ArraySkipper( n, @nRecno, aTaxClass )})

         PRINT_THE_BROWSE

			if theBrowse(oTB)
				oGet:varPut(aTaxClass[nRecno,A_SINGLE_TYPE_CLASS_COLUMN_CODE])
				lReturn := .t.
			endif

		case empty(xInfo)
			WaitHand({'The Type of Financial Transaction does not seem', ;
			          'to be defined, so we can not lookup the CLASS' })
		otherwise
			WaitHand({'Classes are not relevant for this type of' ,;
			          'financial transaction.', 'The type is='+xInfo, ;
						 NameOf( LU_TRANSACTION_TYPE, xInfo ) })
		endcase

	 case nMessage == LU_PRINTER
	 	if !EnsureOpen({'Printer'})
	 		return(nil)
	 	endif
	 	Printer->(dbGoTop())
	 	do while !Printer->(eof())
	 		if left(cToSeek,1)==left(Printer->unique,1)
	 			exit
	 		endif
	 		Printer->(dbSKip())
	 	enddo
	 	if Printer->(eof())
		 	Printer->(dbGoTop())
		endif
		oTb := tBrowCreate(7,25,15,50)
		tbColAdd( oTB, tbColCreate('Uniq ID',{||Printer->unique}) )
		tbColAdd( oTB, tbColCreate('Desc',{||Printer->desc}) )
		tbColAdd( oTB, tbColCreate('Port',{||Printer->port} ) )
		if Printer->(theBrowse(oTb)) .and. lGet
			oGet:varPut(Printer->Unique)
			lReturn := .t.
		endif

    case nMessage == LU_GROWER .or. nMessage == LU_GROWER_NAME ;
     .or. nMessage == LU_GROWER_CHEQUE_NAME

    	if !EnsureOpen({'Grower'})
	    	return( nil )
	   endif
	   do case
	   case nMessage == LU_GROWER
         Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
			cToSeek := str(nToSeek,FLD_GROWER)
		case nMessage == LU_GROWER_NAME
         Grower->(OrdSetFocus(GROWER_NAME_ORD))
		case nMessage == LU_GROWER_CHEQUE_NAME
         Grower->(OrdSetFocus(GROWER_CHEQUE_NAME_ORD))
		endcase

		Grower->(dbSeek(cToSeek,SOFTSEEK))
		if Grower->(eof())
      	Grower->(dbGoBottom())
      endif

		if GrowerBrowse() .and. lGet
		   do case
		   case nMessage == LU_GROWER
				oGet:varPut(grower->number)
				lReturn := .t.
			case nMessage == LU_GROWER_NAME
			 	PokeGetList( 'NGROWER', Grower->number, theGetList )
            PokeGetList( 'NGROW', Grower->number, theGetList )
            PokeGetList( 'CCHEQNAME', Grower->cheqname, theGetList )
            oGet:varPut(grower->name)
				lReturn := .t.
			case nMessage == LU_GROWER_CHEQUE_NAME
			 	PokeGetList( 'NGROWER', Grower->number, theGetList )
            PokeGetList( 'NGROW', Grower->number, theGetList )
            PokeGetList( 'CNAME', Grower->name, theGetList )
            oGet:varPut(grower->cheqname)
				lReturn := .t.
			endcase
		endif

    case nMessage == LU_IMPORT_BATCH                        //2BFIXED - April 2020

      if !EnsureOpen({'ImpBat'})
	 		return(nil)
	 	endif
		if valType(xInfo)=='C'
			ImpBat->(OrdSetFocus( IMPBAT_DEPOT_BATCH_ORD ))
			ImpBat->(dbSeek( xInfo + str( nToSeek, FLD_DOCUMENT ), SOFTSEEK))
		else
			ImpBat->(OrdSetFocus( IMPBAT_BATCH_ORD ))
			ImpBat->(dbSeek( str( nToSeek, FLD_DOCUMENT ), SOFTSEEK))
		endif
      if ImpBat->(eof())
         if !ImpBat->(bof())
            ImpBat->(dbSkip(-1))
         endif
      endif

		oTb := tBrowCreate(7,12,16,70)
      tbColAdd( oTB, tbColCreate('Depot',{|| ImpBat->depot}) )
      tbColAdd( oTB, tbColCreate('Batch No',{|| ImpBat->imp_bat}) )
      tbColAdd( oTB, tbColCreate('Imported',{|| shMDY(ImpBat->date) }) )

		tbColAdd( oTB, tbColCreate('Rcpt From',{|| shMDY(ImpBat->low_date) }) )
		tbColAdd( oTB, tbColCreate('Rcpt To',  {|| shMDY(ImpBat->high_date) }) )
      tbColAdd( oTB, tbColCreate('No Trans',{|| ImpBat->no_trans } ) )
		tbColAdd( oTB, tbColCreate('Lo Rcpt#',{|| ImpBat->low_recpt } ) )
		tbColAdd( oTB, tbColCreate('Ho Rcpt#',{|| ImpBat->hi_recpt} ) )

      PRINT_THE_BROWSE

      if ImpBat->(theBrowse(oTb))
         oGet:varPut(ImpBat->imp_bat)
			PokeGetList( 'CDEPOT', ImpBat->depot, theGetList )
			lReturn := .t.
		endif

   case nMessage == LU_PROCESS_CLASS

      n1 := row()
      n2 := col()

      n1 := min( n1, 17 )
      n1 := max( n1,  4 )

      n2 := min( n2, 65)
      n2 := max( n2,  5)


      n := aChooser( n1, n2, aProcClass, nToSeek, 'Process Classes' )
      if n >= 1
         oGet:varPut( n )
			lReturn := .t.
		endif

   case nMessage == LU_PRODUCT_CATEGORY
      ProdCatInit( aProdCat )

      n1 := row()
      n2 := col()

      n1 := min( n1, 17 )
      n1 := max( n1,  4 )

      n2 := min( n2, 65)
      n2 := max( n2,  5)

      n := aChooser( n1, n2, aProdCat, nToSeek, 'Prod-Categories' )
      if n >= 1
         oGet:varPut( n )
			lReturn := .t.
		endif


   case nMessage == LU_WIN_PRINTERS
      if uiChooseWin32Prn( aUiPrn )
         c1 := aUiPrn[ UI_PRN_PRINTER_NAME ]
         oGet:varPut( padr(c1, len(xVal) ) )
         lReturn := .t.
      endif
   case nMessage == LU_WIN_DEFA_FONT
      c1 := uiChoosePrnFont( xInfo )
      if !empty(c1)
         oGet:varPut( padr(c1, len(xVal) ) )
         lReturn := .t.
      endif
   case nMessage == LU_WIN_ANY_WIN_FONT
      if valType(xInfo)=='C'
         if empty( xInfo)
            if uiChooseWin32Prn( aUiPrn )
               xInfo := aUiPrn[ UI_PRN_PRINTER_NAME ]
            endif
         endif
      else
         xInfo := nil
         if uiChooseWin32Prn( aUiPrn )
            xInfo := aUiPrn[ UI_PRN_PRINTER_NAME ]
         endif
      endif

      if empty( xInfo )
         WaitInfo({'We need to select a Printer to choose a font...'})
      else
         c1 := uiChoosePrnFont( xInfo, .f.  )  // i.e. Any font, not just fixed
         if !empty(c1)
            oGet:varPut( padr(c1, len(xVal) ) )
            lReturn := .t.
         endif
      endif
   case nMessage == LU_WIN_DEFA_BIN
      if uiChooseWin32Prn( aUiPrn )
         n1 := aUiPrn[ UI_PRN_PRINTER_BIN ]
         oGet:varPut( n1 )
         lReturn := .t.
      endif
   case nMessage == LU_WIN_DEFA_FORM
      if uiChooseWin32Prn( aUiPrn )
         n1 := aUiPrn[ UI_PRN_PRINTER_FORM ]
         oGet:varPut( n1 )
         lReturn := .t.
      endif
   case nMessage == LU_FILE_LOGO
      oFileDialog := xbpFileDialog():new(  AppDeskTop() , SetAppWindow()  )

      oFileDialog := xbpFileDialog():new():create()
      oFileDialog:fileFilters := ;
        { {'Files for Logo','*.BMP;*.JPG;*.GIF;*.PNG'} }
      oFileDialog:title := 'Select File for Logo'
      oFileDialog:restoreDir := .t.
      c1 := alltrim(cToSeek)

      // may only open 1, may not create new files
      c2 := oFileDialog:open(  c1, .t., .f., .f. )
      // c2 := oFileDialog:open(  )  <- this Works
      if valType(c2)=='C'
         if !empty(c2)
            oGet:varPut( padr( alltrim(c2), FLD_FILE_AND_PATH ) )
            lReturn := .t.
         endif
      endif
      oFileDialog:destroy()


   case nMessage == LU_FILE_WATERMARK

      oFileDialog := xbpFileDialog():new(  AppDeskTop() , SetAppWindow()  )

      oFileDialog := xbpFileDialog():new():create()
      oFileDialog:fileFilters := ;
        { {'WaterMark Files','*.GIF;*.PNG'} }
      oFileDialog:title := 'Select File for WaterMark'
      oFileDialog:restoreDir := .t.
      c1 := alltrim(cToSeek)

      // may only open 1, may not create new files
      c2 := oFileDialog:open(  c1, .t., .f., .f. )
      // c2 := oFileDialog:open(  )  <- this Works
      if valType(c2)=='C'
         if !empty(c2)
            oGet:varPut( padr( alltrim(c2), len(cToSeek) ) )
            lReturn := .t.
         endif
      endif
      oFileDialog:destroy()

	case nMessage == LU_TAXES
		ensureOpen({'Tax'})

      Tax->(OrdSetFocus( TAX_TAXNAME_ORD ))
      Tax->(dbSeek( padr( cToSeek, FLD_TAXNAME ), SOFTSEEK))
      if Tax->(eof())
         if !Tax->(bof())
            Tax->(dbSkip(-1))
         endif
      endif

		oTb := tbrowCreate(10,15)
		tbColAdd( oTb, tbColCreate('Name',{||Tax->taxName}))
		//                          Mmm-DD-YY
		tbColAdd( oTb, tbColCreate('Cut Off D',{|| shMdy(Tax->eff_date)}))
		tbColAdd( oTb, tbColCreate('New Rate',{|| str(Tax->new_rate,7,3)+'%'}))
		tbColAdd( oTb, tbColCreate('Old Rate',{|| str(Tax->old_rate,7,3)+'%'}))

		// tbColAdd( oTb, tbColCreate('Gl Acct',{|| iif(Tax->glaTax==0,space(6), str(Tax->glaTax,6))}))
		// tbColAdd( oTb, tbColCreate('Gl Dept',{|| iif(Tax->gldTax==0,space(6), str(Tax->gldTax,6))}))
		// tbColAdd( oTb, tbColCreate('Gl Acct',{|| iif(Tax->new_gla==0,space(6), str(Tax->new_gla,6))}))
		// tbColAdd( oTb, tbColCreate('Gl Dept',{|| iif(Tax->new_gld==0,space(6), str(Tax->new_gld,6))}))

		Tax->(theBrowse(oTb))
		if .not. Tax->(eof()) .and. lastkey()==K_ENTER
			oGet:varPut(Tax->taxName)
			lReturn := .t.
		endif

	case nMessage == LU_FILE_DIRECTORY
		if alltrim(soValue(SO_INIT)) == 'BH' .or. ;
		   alltrim(soValue(SO_INIT))== CRAFTED_INDUSTRIAL_ADMIN_USER1 .or. ;
		   alltrim(soValue(SO_INIT))== CRAFTED_INDUSTRIAL_ADMIN_USER2 .or. ;
         alltrim(soValue(SO_INIT))== OLD_SCHOOL_ADMIN_USER

			c1 := oGet:varGet()
			c2 := DirectorySelector( alltrim(sysValue( SYS_IMPORT_DIRECTORY )), ;
											 'Select a Folder to Import Scale ticket from..' )

			if upper(c1) == upper( CurDirectory() ) .or. ;
				upper(c1) == upper( CurDirectory()+'\' )

				WaitInfo({'You can not import from your main Data directory!' , ;
							 CurDirectory(),'', ;
							 'Try that again!' })
			else
				if !empty( c2 )
					oGet:varPut( padr(c2, len( c1 )) )
					lReturn := .t.
				endif
			endif
		endif

	endcase
	rest_scr(aMsg)

return( lReturn )

function DailyBrowse( nGrower, nType )
	local oTb
	local lReturn, aMsg, lEdit
	local bWhile

	do case
	case nType == DAILY_POSTED_ONLY
		lEdit := .f.
		if nGrower == 0
         bWhile := {|| Daily->post_bat1 <> 0}
		else
         bWhile := {|| Daily->number==nGrower .and. Daily->post_bat1 <> 0}
		endif

	case nType == DAILY_UNPOSTED
		lEdit := .t.
		if nGrower == 0
         bWhile := {|| Num2Equal0( Daily->post_bat1) .and. ;
                       Num2Equal0( Daily->fin_bat ) }
		else
         bWhile := {|| Daily->number==nGrower .and. ;
                       Num2Equal0( Daily->post_bat1 ) .and. ;
                       Num2Equal0( Daily->fin_bat ) }
		endif

	case nType == DAILY_ANY_TRANS
		if nGrower == 0
			bWhile := nil
		else
			bWhile := {|| Daily->number==nGrower }
		endif

		lEdit := .t.
	otherwise
		appError(APP_ERR_BAD_FILE_CALL1, ;
		 {'Can NOT tell what kind of Browse!' } )
		return( .f. )
	endcase

	oTb := tBrowCreate(2,6,15,76)

	if lEdit
		aMsg := msgLine( ;
'Enter - Edit/View, [Alt P] -Print, [Alt F] -Finder,   Ins -Add New  Del-Delete')

		tbKeyCfg( oTb, {K_INS, {|| DailyAddRec( nGrower ) }})

		tbKeyCfg( oTb, ;
          {K_DEL, {|| DeleTicket(), SIG_EXIT } })
	else
		aMsg := msgline( ;
'Enter - Edit/View,     [Alt P] - Print,     [Alt F] - Finder')

	endif

	tbKeyCfg( oTb, {K_ENTER, {|| DailyEdit( DAILY_EDIT_ALLOW_NAVIGATE, nGrower) }})

	if nGrower == 0
		tbColAdd( oTB, tbColCreate('ID',{|| Daily->number}) )
		tbColAdd( oTB, tbColCreate('Name',{|| left( NameOf( LU_GROWER, Daily->number), FLD_NAME - 6) }) )
	endif

	tbMainCfg( oTb, CB_WHILE, bWhile )

	tbColAdd( oTB, tbColCreate('Dep',  'Daily->depot') )
	tbColAdd( oTB, tbColCreate('Recpt','Daily->recpt') )
   tbColAdd( oTB, tbColCreate('?',    'Daily->recptltr') )
	tbColAdd( oTB, tbColCreate('Date', 'Daily->date') )

	tbColAdd( oTB, tbColCreate('Berry', {|| Daily->product } ) )
	tbColAdd( oTB, tbColCreate('PrcTp', {|| Daily->process } ) )
   tbColAdd( oTB, tbColCreate('Gr',    {|| str( Daily->grade,2) } ) )

	tbColAdd( oTB, tbColCreate('Net',{|| str( Daily->net,8) } ) )

   tbColAdd( oTB, tbColCreate('Final Pr', ;
     {|| iif ( str(Daily->thePrice,12,3)==str(0,12,3), ;
           'AutoPrice',str( Daily->thePrice,9,2))  } ) )
        //  123456789

	tbColAdd( oTb, tbColCreate( ContSName(1), ;
		{ || str( NetContRecvd( 1 ), FLD_CONTAINER_SHORT) } ))

	tbColAdd( oTb, tbColCreate( ContSName(2), ;
		{ || str( NetContRecvd( 2 ), FLD_CONTAINER_SHORT) } ))

	tbColAdd( oTb, tbColCreate( ContSName(3), ;
		{ || str( NetContRecvd( 3 ), FLD_CONTAINER_SHORT) } ))

	tbColAdd( oTb, tbColCreate( ContSName(4), ;
		{ || str( NetContRecvd( 4 ), FLD_CONTAINER_SHORT) } ))

	tbColAdd( oTb, tbColCreate( ContSName(5), ;
		{ || str( NetContRecvd( 5 ), FLD_CONTAINER_SHORT) } ))

   if !empty( sysValue( SYS_IMPORT_FROM_FIELD_NAME ))
		tbColAdd( oTb, tbColCreate( sysValue( SYS_IMPORT_FROM_FIELD_NAME ) , ;
			{ || Daily->from_field } ))

   endif

   PRINT_THE_BROWSE
	FANCY_FINDER

	lReturn := Daily->(theBrowse(oTb))
	rest_scr(aMsg)

return( lReturn )

function DailyBrEdit( nGrower )
	local oTb, oCol
	local lReturn, aMsg
	local bWhile
   local n
   local lRead

   oTb   := tBrowCreate(2,3,15,77)
   n     := SetCursor( SC_NORMAL )
   lRead := ReadExit( .t. )

   if nGrower == Daily->number .and. nGrower > 0
      bWhile := {|| Daily->number==nGrower .and. !Daily->(eof()) }
      tbMainCfg( oTb, CB_WHILE, bWhile )
      aMsg := msgLine( 'Move to PRICE column to Edit -- '+ ;
         lStrim( nGrower)+' '+NameOf(LU_GROWER,nGrower) )
   else
      tbColAdd( oTB, tbColCreate('ID',{|| Daily->number}) )
      tbColAdd( oTB, tbColCreate('Name', ;
       {||padr(NameOf( LU_GROWER, Daily->number),16)}) )
      aMsg := msgLine( 'Move to PRICE column to Edit')
   endif

   tbKeyCfg( oTb, {K_F2, {|| DailyEdit( DAILY_EDIT_ALLOW_NAVIGATE, nGrower) }})

   tbColAdd( oTB, tbColCreate('Recpt','Daily->recpt') )
   tbColAdd( oTB, tbColCreate('?','Daily->recptltr') )
	tbColAdd( oTB, tbColCreate('Date', 'Daily->date') )

   tbColAdd( oTB, tbColCreate('Berry', ;
    {|| Daily->product + ' '+ Daily->process + str( Daily->grade,2) } ) )

	tbColAdd( oTB, tbColCreate('Net',{|| str( Daily->net,8) } ) )

   // oCol := tbColCreate( 'Price', {|| str(Daily->theprice,5,2)  } )
   oCol := tbColCreate( 'Price', {|| Daily->theprice  } )
   tbMainCfg( oTb, CB_ALLOW_EDIT, .t. )
   tbMainCfg( oTb, CB_NEED_LOCKS, .t. )
   // CC_WHEN

//   tbcolCfg(oCol, CC_GET_SET,  ;
//       {|x| iif(valtype(x)=='U', ;
//         str(Daily->thePrice,5,2), Daily->thePrice := val(x) ) })
   tbcolCfg(oCol, CC_GET_SET,  ;
		 {|x| iif(valtype(x)=='U', ;
         Daily->thePrice, Daily->thePrice := x ) })
   tbColCfg(oCol, CC_PICTURE, '99.99' )
   tbColCfg(oCol, CC_EDIT_MESSAGE, 'Edit the Price')
   // tbColCfg(oCol, CC_WHEN, { || str(Daily->fin_bat,10,2)==str(0,10,2) })

   tbColCfg(oCol, CC_VALID, ;
       {| x |  PriceVal0( x ) } )

   tbColCfg(oCol, CC_REPL_SUCCEEDS, NIL  )
   tbColCfg(oCol, CC_HOTKEY, NIL )

   tbColCfg(oCol, CC_HOTBLOCK, nil )
   // tbColCfg(oCol, CC_MOVEMENT, chr(K_DOWN ) )   //+chr(K_ENTER) )
   tbColAdd( oTb, oCol)

   tbColAdd( oTB, tbColCreate('Ed?', ;
    {|| iif( str(Daily->fin_bat,10,2)==str(0,10,2), '   ','No ') }))

   PRINT_THE_BROWSE
	FANCY_FINDER

	lReturn := Daily->(theBrowse(oTb))
	rest_scr(aMsg)
   setCursor( n )
   ReadExit( lRead )

return( lReturn )

static Function PriceVal0( x )
   local lReturn := .f.
   local n
   local lOk := .f.

   do case
   case valType( x )=='O'
      n := x:VarGet()
      lOk := .t.
   case valType( x)=='N'
      n := x
      lOk := .t.
   otherwise
      lOk := .f.
   endcase

   if lOk
      do case
      case Daily->fin_bat > 0
         WaitHand({'This has been PAID out, you may not edit!'})
      case n <= -0.001
         lReturn := Yesno({'You have set the Price to NEGATIVE'+str(n,10,2), ;
           'is this what you mean to do ?'})
      case n < 0.25                           // n < 0.60 changed in April 2020, May 2020
         lReturn := Yesno( ;
          {'You have set the Price to a small number'+str(n,10,2), ;
           'is this what you mean to do ?'})
      case n > 6.95                           // from 2.50 changed April 2020
         lReturn := Yesno( ;
          {'You have set the Price to a large number'+str(n,10,2), ;
           'is this what you mean to do ?'})
      otherwise
         lReturn := .t.
      endcase
   else
      waitHand({'Type is '+valType(x)})
      lReturn := .f.
   endif

return( lReturn )



function DeleteIt( aMsg )
	local nReturn := SIG_CONTINUE
	local aRay
	local n

	aRay := {'Delete this?'}

	do case
	case valType(aMsg)=='A'
		if len(aMsg) > 0
			aadd(aRay,'')
		endif
		for n := 1 to len(aMsg)
			aadd(aRay,aMsg[n])
		next
	case valType(aMsg)=='C'
		aadd( aRay, aMsg )
	endcase

	if yesno( aRay )

		if recLock()
		  	dbDelete()
			dbCommit()
			nReturn := SIG_EXIT
		endif
	endif

return( nReturn )

static function GrowerBrowse(  )
	local oTb, lReturn
	local aMsg

	oTb := tBrowCreate(7,12,15,68)
	tbColAdd( oTB, tbColCreate('ID',{||Grower->number}) )
	tbColAdd( oTB, tbColCreate('Name','Grower->name') )
	tbColAdd( oTB, tbColCreate('Phone','Grower->phone') )
	tbColAdd( oTB, tbColCreate('Street','Grower->street') )
	tbColAdd( oTB, tbColCreate('City','Grower->city') )
	tbColAdd( oTB, tbColCreate('Cheque Name','Grower->cheqname') )
	tbColAdd( oTb, tbColCreate('Grp','Grower->payGrp') )
	tbColAdd( oTb, tbColCreate('Curr.', ;
	  {|| NameOf(LU_CURRENCY,Grower->currency) } ) )

   tbColAdd( oTB, tbColCreate('Phone2','Grower->phone2') )

   tbColAdd( oTB, tbColCreate('Hold?',{ || iif(Grower->onHold,'HOLD',space(5) ) } ))

	tbKeyCfg( oTb, {K_F2, {|| ViewGrower( Grower->(recno()) ) }})

   PRINT_THE_BROWSE
	FANCY_FINDER

	aMsg := msgLine('Browsing Growers... [F2]=View, [Alt F]=Find, [Alt P]=Prn List')
	lReturn := grower->(theBrowse(oTb))
	rest_scr( aMsg )

return( lReturn )

function AccountGroBrowse( nGrower )
	local oTb, lReturn

	DEFAULT nGrower TO 0

	if num2Equal0( nGrower )
		WaitInfo({'The GROWER is set to ZERO - can NOT', ;
		          'figure out what to do'})
		return( .f. )
	endif

	// we assume we are RELATED to the CHEQUE file....

	if Account->number<>nGrower
		if Yesno({'There are NO Accounting Charges for ', ;
		 lStrim(nGrower)+' '+NameOf(LU_GROWER,nGrower), ;
		 'Do you wish to Add One?' })
		 	AddAccount( nGrower, .f. )
		else
			return( .f. )
		endif
	endif
	if Account->number<>nGrower
		return( .f. )
	endif

	oTb := tBrowCreate(7,03,15,77)

	tbMainCfg(oTb, CB_WHILE, {||Account->number==nGrower})
	tbMainCfg(oTb, CB_TITLE, 'Grower='+ lStrim(Account->number) )

	tbKeyCfg( oTb, { K_INS, {|| AddAccount( nGrower, .t. ) }})
	tbKeyCfg( oTB, { K_F1, ;
			 {|| WaitInfo({'[Alt P] = Print the Browse     ', ;
			               '[Alt F] = the Famous Finder    ', ;
								'[Enter] = Edit or View Current ', ;
								'[Del]   = Delete Current Record', ;
								'[Ins]   = Add a New Record     ' }), ;
								  SIG_CONTINUE } })

   msgLine(;
		 'Accounting Entries for '+NameOf(LU_GROWER,nGrower)+'  [Ins],[Enter],[Del],[F1]')

	tbKeyCfg( oTB, { K_DEL, {|| DeleIt() }})
   // tbKeyCfg( oTB, { K_ENTER, {|| AccountView( .f. ) }})
   // was that - Changed in Oct 2012
   tbKeyCfg( oTB, { K_ENTER, {|| AccountView( .t. , .f.) }})

	tbColAdd( oTB, tbColCreate('Date',  'Account->date') )
	tbColAdd( oTB, tbColCreate('Type of Trn', ;
	         { || NameOf( LU_SHORT_TRANSACTION_TYPE, Account->type) } ))

	tbColAdd( oTB, tbColCreate('Class','Account->class') )
	tbColAdd( oTB, tbColCreate('Prod. ', ;
		{|| Account->product+' '+Account->process+' '+ ;
		    iif(Account->grade==0,' ', str(Account->grade,1) ) }))

	tbColAdd( oTB, tbColCreate('Weight', ;
	 {||iif(empty(Account->lbs),space(FLD_LBS),str(Account->lbs,FLD_LBS) )} ) )
	tbColAdd( oTb, tbColCreate('Unit Pr.','Account->u_price') )
	tbColAdd( oTb, tbColCreate('Total Amt', { || str( Account->dollars ,12,2) } ))
	tbColAdd( oTb, tbColCreate('Notes','Account->desc') )
	tbColAdd( oTb, tbColCreate('Pd by Cheque', ;
	  {|| Account->series+str(Account->Cheque,FLD_CHEQUE+1)}) )

	tbColAdd( oTb, tbColCreate('Curr.', ;
	 {||NameOf(LU_CURRENCY,Account->Currency)} ) )

	tbColAdd( oTb, tbColCreate('Chq Amt/Info', ;
	  {|| ChequeInfo() }) )
	tbColAdd( oTB, tbColCreate('CropYr','Account->year') )
	tbColAdd( oTB, tbColCreate('Trn ID#',{ || str(Account->acct_uniq, FLD_DOCUMENT) } ) )

   // May 2019 - Show info about Advances
	tbColAdd( oTB, tbColCreate('Advance?', { || padr( iif(Account->ADV_NO  > 0, 'Adv'+Str(Account->ADV_NO,1)+' '+Str(Account->adv_bat, FLD_DOCUMENT),''), 14) }))
	tbColAdd( oTB, tbColCreate('Final?'  , { || padr( iif(Account->fin_bat > 0, 'Fin ' + str(Account->fin_bat, FLD_DOCUMENT),''), 12) }))

   PRINT_THE_BROWSE
	FANCY_FINDER

	lReturn := Account->(theBrowse(oTb))

return( lReturn )


function AccountChqBrowse( cSeries, nCheque )
	local oTb, lReturn := .f.
	local aMsg

	if !(Account->series==cSeries) .or. ;
	   Account->cheque<>nCheque .or. Account->(eof()) ;
	     .or. num2Equal0( Account->cheque )
		WaitHand({'Can not find any account entries for ' , ;
		    'Cheque: '+cSeries +' '+ lStrim( nCheque ) })
		return( lReturn )
	endif

	oTb := tBrowCreate(7,07,15,74)
	tbMainCfg(oTb, CB_TITLE, 'Paid on Cheque '+cSeries+' '+lStrim(nCheque) )

	tbMainCfg(oTb, CB_WHILE, ;
	  {|| Account->cheque == nCheque .and. Account->series == cSeries } )

	tbKeyCfg( oTB, { K_F1, ;
			 {|| WaitInfo({'[Alt P] = Print Browse ', ;
			               '[Alt F] = the Finder   ', ;
								'[Enter] = View Entry   ' }), SIG_CONTINUE } })

	// tbColAdd( oTB, tbColCreate('ID',{||Account->number}) )
	// tbColAdd( oTB, tbColCreate('Name',{||NameOf( LU_GROWER, Account->number)}) )

	aMsg := msgLine( ;
			'Viewing Accounting Entries,  [Enter]-View, [F1]-More Keys')

	tbKeyCfg( oTB, { K_ENTER, {|| AccountView( .f., .f. ) }})

	tbColAdd( oTB, tbColCreate('Crop Yr','Account->year') )
	tbColAdd( oTB, tbColCreate('Date','Account->date') )
	// tbColAdd( oTB, tbColCreate('Type','Account->type') )
	tbColAdd( oTB, tbColCreate('Type', ;
	         { || NameOf( LU_SHORT_TRANSACTION_TYPE, Account->type ) } ))

	tbColAdd( oTB, tbColCreate('Class','Account->class') )
	tbColAdd( oTB, tbColCreate('Prod.', ;
		{|| Account->product+' '+Account->process+' '+ ;
		    iif(Account->grade==0,' ', str(Account->grade,1) ) }))

	tbColAdd( oTB, tbColCreate('Weight', ;
	 {||iif(empty(Account->lbs),space(FLD_LBS),str(Account->lbs,FLD_LBS) )} ) )
	tbColAdd( oTb, tbColCreate('Unit Pr.','Account->u_price') )
	tbColAdd( oTb, tbColCreate('Ext. Price','Account->dollars') )
	tbColAdd( oTb, tbColCreate('GST Est','Account->gst_est') )
	tbColAdd( oTb, tbColCreate('Notes','Account->desc') )

	tbColAdd( oTb, tbColCreate('Curr.', ;
	 {||NameOf(LU_CURRENCY,Account->Currency)} ) )

	/*
	tbColAdd( oTb, tbColCreate('Pd by Cheque', ;
	  {|| Account->series+str(Account->Cheque,FLD_CHEQUE+1)}) )

		tbColAdd( oTb, tbColCreate('Chq Amt/Info', ;
		  {|| ChequeInfo() }) )
	*/

   PRINT_THE_BROWSE
	FANCY_FINDER

	lReturn := Account->(theBrowse(oTb))

	rest_scr( aMsg )

return( lReturn )

static Function DeleIt()
	local nReturn := SIG_REDRAW

	if AllowAccEd()
		if YesNo({'Delete this Transaction?', '', ;
				    ' Grower: '+lStrim(Account->Number), ;
					 ' Date:   '+shMDY(Account->date), ;
					 ' Type:   '+ Account->Type+' '+ NameOf( LU_SHORT_TRANSACTION_TYPE, Account->Type ) , ;
					 ' Class:  '+ Account->class, ;
					 ' $ Amt:  '+ DollarStr( Account->Dollars , 15) })

			if Account->(recLock())
				DeleteByFlds()
				Account->(dbDelete())
				Account->(dbCommit())

				nReturn := SIG_EXIT
				WaitExclam({'Deleted the rascal...'})
			endif
		endif
	else
		WaitInfo({'May not delete this transaction'})
	endif

return( nReturn )

static function ChequeInfo()
	local cReturn

	if Cheque->(eof()) .or. Cheque->number <> Account->number
		cReturn := space( 35 )
	else
		cReturn :=  DollarStr(Cheque->amount,13)+iif(Cheque->void,' VOID',space(5)) ;
		 + ' '+MedMDY(Cheque->date)
	endif
return( padc(cReturn,35) )

function CheqBrowse( bWhile, lShowGrower )
	local oTb, lReturn

	default bWhile to nil
	default lShowGrower to .t.

	if lShowGrower
		oTb := tBrowCreate(7, 4,15,77)
	else
		oTb := tBrowCreate(7, 8,14,73)
	endif

	if valType( bWhile ) == 'B'
		tbMainCfg( oTb, CB_WHILE, bWhile )
	endif

	tbColAdd( oTb, tbColCreate('Cheque #', ;
	 {||Cheque->SERIES + ' '+ strZero( Cheque->CHEQUE,FLD_CHEQUE) }))

	if lShowGrower
		tbColAdd( oTb, tbColCreate('GrowID',{|| str(Cheque->NUMBER, 6)  }))
		tbColAdd( oTb, tbColCreate('Grower',{|| padr(NameOf(LU_GROWER,Cheque->number),25) }))
	endif

	// tbColAdd( oTb, tbColCreate('',{||Cheque->CHEQTYPE  }))

	tbColAdd( oTb, tbColCreate('- Date -',{||MedMDY(Cheque->DATE )}))
	tbColAdd( oTb, tbColCreate('$ Amount',{||Cheque->AMOUNT }))
	tbColAdd( oTb, tbColCreate('Type',{|| NameOf(LU_CHEQUE_TYPE,Cheque->CHEQTYPE) }))
	tbColAdd( oTb, tbColCreate('Year',{||Cheque->YEAR }))
	tbColAdd( oTb, tbColCreate('Curr.',{|| NameOf(LU_CURRENCY,Cheque->Currency) }))
	tbColAdd( oTb, tbColCreate('Void',{||iif(Cheque->void,'VOID','    ') }))

   PRINT_THE_BROWSE
	FANCY_FINDER

	lReturn := Cheque->(theBrowse(oTb))
return( lReturn )


function SlowLu( cProc,nLine,cVar, theGetList, nLU )
   // slow look up on Customer
   local oGet, cToSeek, xVal
   local lSearch
   local bLookFor, abShow
   local cFile
   local cCallStack

   default nLu to 0
   default cProc to 'unKnown'
   default nLine to 0
   default cVar to ''

   cCallStack := alltrim( cProc) +' '+ lStrim(nLine)+' '+alltrim(cVar)

   lSearch := .f.

   oGet := getActive()
   // this step below is because in MENU TO this can be called and there
   // is no active get.....
   if valType(oGet)=='U'
      return( nil )
   endif

   xVal := oGet:varGet()
   if valtype(xVal)=='C'
      cToSeek := upper( alltrim( xVal ) )
      if empty( cToSeek )
         waitInfo({'Nothing to search for'})
         return( nil )
      endif
   else
      waitHand({'Weird Variable Type '+valType(xVal), cCallStack})
      return( nil )
   endif

   cToSeek := Stripper( cToSeek )

   do case
   case nLu == LU_SLOW_BROWSE_GROWER
      Grower->(OrdSetFocus(0))
      Grower->(dbGoTop())
      lSearch := .t.
      bLookFor := {|| cToSeek $ ;
            stripper( ;
            Grower->name   + Grower->cheqname + ;
            Grower->street + Grower->street2 + ;
            Grower->notes  + Grower->note2 + ;
            Grower->alt_name1  + Grower->alt_name2 + ;
            Grower->alt_phone1 + Grower->alt_phone2 + Grower->phone, ;
            Grower->city  ) }
      cFile    :=  'Grower'

      abShow := {  {|| str(Grower->number, FLD_GROWER) }, ;
                  {|| Grower->name }, ;
                  {|| Grower->city },  ;
                  {|| Grower->phone } , ;
                  {|| Grower->street } }
   endcase
   if lSearch
      theSlowBrow( theGetList, cFile, bLookFor, abShow )
   endif

return( nil )

static function theSlowBrow( theGetList, cFile, bSearchFor, abToShow )
   local aFound:={},aRecno:={}, aScrn, nResult := 0
   local n, nEvery, n1, n2, nLen
   local aGauge, aWin

   aScrn := msgLine('Checking for Near Hits  - [Esc] to halt search')

   n := 1
   setPos(maxRow(),maxCol()-1)

   create window at 6,10, 12, 70 title 'Searching through '+cFile to aWin
   display window aWin
   in window aWin @ 3,5 winsay 'Searching through file...'

   aGauge := gaugeNew( aWin )
   gaugeDisplay( aGauge )

   nEvery := round( (cFile)->(lastRec())/100, 0)
   nEvery := max( nEvery, 60 )

   n1 := 0
   GaugeUpdate( aGauge, (cFile)->(recno())/ (cFile)->(lastRec()) )

   do while !(cFile)->(eof()) .and. inkey()==0
      n1 ++
      if n1 > nEvery
         n1 := 0
         GaugeUpdate( aGauge, (cFile)->(recno())/(cFile)->(lastRec()) )
      endif

      if eval(bSearchFor)
         showProg( str(n++,7) )
         if valType(abToShow)=='B'
            aadd(aFound, eval( abToShow ) )
         else
            aadd( aFound, {} )
            nLen := len( aFound )
            for n2 := 1 to len( abToShow )
               aadd(aFound[nLen], eval(abToShow[n2] ) )
            next
         endif
         aadd(aRecno, (cFile)->(recno()) )
         if len(aFound) > 600
            waitInfo({'You have found over 600 of these!'})
            exit
         endif
      endif
      (cFile)->(dbSkip())
   enddo
   GaugeUpdate( aGauge, 1 )                   // ensure last box is 100 %
   KillGauge( aGauge )
   kill window aWin

   if len(aFound)==0
      waitInfo({'None Found - try again'})
   else
      //ARRAY BROWSE 8,1, aFound TITLE 'Near Hits' TO nResult

      nResult := NearHitBrow( aFound, aRecNo, cFile )

      if nResult <> 0
         do case
         case upper(cFile)=='GROWER'
            Grower->(dbGoto(aRecno[nResult]))
            pokeGetList('NGROW',   Grower->number,   theGetList)
         otherwise
            (cFile)->(dbGoto( aRecno[nResult] ))
         endcase
         DisplayGets(theGetList)                 // forces all get to be displayed !
      endif
   endif
   Rest_scr(aScrn)

return( nil )

static function NearHitBrow(  aTable, aRec, cFile )
   // browses a 1D or 2D table - revised big in December 95
   // basically like aChoice

   local oTb, oCol
   local nBott, n, nWide := 1, nRowArray := 1
   local aColor
   local nRow := 8, nCol := 1

   if len(aTable) == 0
      return( 0 )
   endif

   if valType(aTable[1])=='A'
      for n := 1 to len( aTable[1] )
         nWide +=  len(aTable[1,n])
         nWide ++  // Allow for Column spacing
      next
   else
      nWide := len(aTable[1])
   endif

   if nWide > maxCol()-6
      nWide := maxCol() -6
      nCol  := 2
   else
      nCol := int( (maxCol() - nWide - 2)/2 )
   endif

   nBott := min( nRow+len(aTable), maxRow()-3)
   oTb := tBrowCreate(nRow, nCol, nBott, nCol+nWide)
   tbMainCfg( oTb, CB_TITLE, 'Near Hits')

   if nRowArray <> 1
      oTb:rowPos := min( nRowArray, oTb:rowCount )
   endif

   if valType( aTable[1])  == 'A'
      // one would think we could do a Loop here, but the expression
      //    aTable[ nRowArray, <nX> ]
      // the expression <nX> must be a value that does not change!

      oCol :=  tbColCreate( NIL , {|| aTable[nRowArray,1]} )
      tbColCfg( oCol, CC_HEADING, NIL )
      oCol:width := len( aTable[1,1] )
      tbColAdd( oTb, oCol )

      if len(aTable[1]) >= 2
         oCol :=  tbColCreate( NIL , {||aTable[nRowArray,2]} )
         tbColCfg( oCol, CC_HEADING, NIL )
         oCol:width := len(aTable[1,2])
         tbColAdd( oTb, oCol )
      endif

      if len(aTable[1]) >= 3
         oCol :=  tbColCreate( NIL , {||aTable[nRowArray,3]} )
         tbColCfg( oCol, CC_HEADING, NIL )
         oCol:width := len(aTable[1,3])
         tbColAdd( oTb, oCol )
      endif

      if len(aTable[1]) >= 4
         oCol :=  tbColCreate( NIL , {||aTable[nRowArray,4]} )
         tbColCfg( oCol, CC_HEADING, NIL )
         oCol:width := len(aTable[1,4])
         tbColAdd( oTb, oCol )
      endif
      if len(aTable[1]) >= 5
         oCol :=  tbColCreate( NIL , {||aTable[nRowArray,5]} )
         tbColCfg( oCol, CC_HEADING, NIL )
         oCol:width := len(aTable[1,4])
         tbColAdd( oTb, oCol )
      endif
      if len(aTable[1]) >= 6
         oCol :=  tbColCreate( NIL , {||aTable[nRowArray,6]} )
         tbColCfg( oCol, CC_HEADING, NIL )
         oCol:width := len(aTable[1,4])
         tbColAdd( oTb, oCol )
      endif
      if len(aTable[1]) >= 7
         oCol :=  tbColCreate( NIL , {||aTable[nRowArray,7]} )
         tbColCfg( oCol, CC_HEADING, NIL )
         oCol:width := len(aTable[1,4])
         tbColAdd( oTb, oCol )
      endif

      // this line is really important.....to get display to look OK
      tbMainCfg( oTb, CB_SEP, { " ",""} )

      aColor := Char2Array( colorStr( COLOR_BROWSE ) )
      if len( aColor ) >= 4
         aColor[3] := aColor[4]
         tbMainCfg( oTb, CB_COLOR , Array2Char( aColor ) )
      endif
   else
      oCol :=  tbColCreate( NIL , {||aTable[nRowArray]} )
      tbColCfg( oCol, CC_HEADING, NIL )
      tbColAdd( oTb, oCol )

      // this line is really important.....to get display to look OK
      tbMainCfg( oTb, CB_SEP, SEP_NONE )
   endif

   tbMainCfg( oTb, CB_SKIP, {| n | ArraySkipper(n,  @nRowArray, aTable )} )
   tbMainCfg( oTb, CB_WHILE,    ;
      {|| nRowArray >= 1 .or. nRowArray <= len(aTable)} )


   do case
   case upper(cFile)=='GROWER'
      tbKeyCfg( oTb, { K_F2,  {|| ViewGrower( aRec[ nRowArray] ) } } )
      msgLine('[Enter] to Select, [F2] to View')
   otherwise
      msgLine('[Enter] to Select')
   endcase

   theBrowse( oTb )

return( nRowArray )


static function Stripper( cVar )
   local cReturn

   cReturn := alltrim( cVar)

   cReturn := strTran( cReturn, ' ','')

   cReturn := strTran( cReturn, '.','')
   cReturn := strTran( cReturn, '&','')
   cReturn := strTran( cReturn, ',','')

   cReturn := strTran( cReturn, '(','')
   cReturn := strTran( cReturn, ')','')
   cReturn := strTran( cReturn, '-','')

   cReturn := strTran( cReturn, "'",'')

   cReturn := strTran( cReturn, ';','')
   cReturn := strTran( cReturn, ":",'')

   cReturn := upper( cReturn )

return( cReturn )
