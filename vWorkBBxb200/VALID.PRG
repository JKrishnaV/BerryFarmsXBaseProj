// valid.prg
//   Changes in July 2014 to deal with GST.
//              June 2015 to add Varieties
//  (c) 1994, 2011, 2014, 2015 Bill Hepler
// Bill Hepler

#include 'bsgstd.ch'
#include 'common.ch'
#include 'valid.ch'
#include 'BerryPay.ch'
#include 'account.ch'
#include 'price.ch'
#include "field.ch"
#include "indexord.ch"
#include 'sysvalue.ch'

static aTransDesc    := A_TRANSACTION_TYPE_ARRAY
static aDedClass     := A_DEDUCTION_CLASS_ARRAY
static aAllAcctClass := A_ALL_ACCOUNT_TYPE_CLASSES_ARRAY
// static aTaxClass     := A_TAX_CLASSES_ARRAY
static aMayAdd       := A_MAY_ADD_TRANSACTION_TYPE_ARRAY

static aChequeType   := CHEQUE_NAME_ARRAY
static aProcClass    := PROCESS_CLASS_ARRAY
static aProdCat      := {}

function ValidTest( nTest, xVal,  nShowType , xInfo )
	local lValid := .t., lFound := .f.
	local lTest1 := .t.
	local aMsg := {}
   local n
	local nLookup
	local nShowMsg
	local nValue

	DEFAULT nShowType TO VT_MESSAGE
	DEFAULT xInfo TO ''

   if nShowType >= VT_BLANKS_OK
      nShowMsg := nShowType - VT_BLANKS_OK
      if empty( xVal )
         return( .t. )
      endif
   else
      nShowMsg := nShowType
   endif

	nLookUp := 1000+nTest

   ProdCatInit( aProdCat )

	do while .t.
		do case
	   case nTest == V_PROCESS_TYPE
			aMsg := { 'Process Type '+xVal+' is not on file'  }
			if Process->process==xVal .and. !Process->(deleted()) .and. ;
					!Process->(eof())
				lValid := .t.
			else
				lValid := NormalValid( 'Process', PROCESS_PROCESS_ORD, xVal )
			endif

	   case nTest == V_PROCESS_GRADE
			aMsg := { 'Process Type '+xVal+' is not on file'  }
			if Process->process==xVal .and. !Process->(deleted()) .and. ;
					!Process->(eof())
				lValid := .t.
			else
				lValid := NormalValid( 'Process', PROCESS_PROCESS_ORD, xVal )
			endif
         if valType( xInfo ) == 'N'
         	if xInfo < MIN_GRADE_NO .or. xInfo > MAX_GRADE_NO
	         	aadd( aMsg, 'Invalid Grade No specified ='+var2char( xInfo ) )
   	         lValid := .f.
            endif
         else
         	aadd( aMsg, 'Invalid Grade No specified ='+var2char( xInfo ) )
            lValid := .f.
         endif

	   case nTest == V_VARIETY
			ensureOpen( {'Variety'})
			aMsg := { 'Variety type '+xVal+' is not on file'  }
			if Variety->variety==xVal .and. !Variety->(deleted()) .and. ;
					!Variety->(eof())
				lValid := .t.
			else
				lValid := NormalValid( 'Variety', VARIETY_VARIETY_ORD, xVal )
			endif

      case nTest == V_CHEQUE_FORMAT_ID
         aMsg := { 'Cheque Fmt '+xVal+' is not on file'  }

         // shouldn't be necessary, but ran into weird circumstance where it
         // was
         if EnsureOpen( 'ChqFmt' )
	         if ChqFmt->id == xVal .and. !ChqFmt->(deleted()) .and. ;
	               !ChqFmt->(eof())
					lValid := .t.
				else
	            lValid := NormalValid( 'ChqFmt', CHQFMT_ID_ORD, xVal )
				endif
			endif

	   case nTest == V_CONTAINER
         if !EnsureOpen({'Contain'})
            return( .f. )
         endif

			aMsg := { 'Container Type '+str(xVal,3)+' is not allowed'  }

			if Contain->container==xVal .and. !Contain->(deleted()) .and. ;
					!Contain->(eof())
				lValid := .t.
			else
				lValid := NormalValid( ;
					'Contain',CONTAIN_CONTAINER_ORD, str(xVal,FLD_CONTAINER) )
			endif

	   case nTest == V_PRODUCT
			aMsg := { 'Product ID '+xVal+' is not on File'  }
			if Product->product==xVal .and. !Product->(deleted()) .and. ;
					!Product->(eof())
				lValid := .t.
			else
				lValid := NormalValid( 	'Product',PRODUCT_PRODUCT_ORD, xVal )
			endif

		 case nTest == V_CURRENCY
			aMsg := { 'Valid Currencies are:' , ;
			  'C = Canadian Dollars', ;
			  'U = US Dollars' }
			lValid := iif( xVal==US_DOLLARS .or. xVal==CANADIAN_DOLLARS, .t., .f. )

		 case nTest == V_BANK_STATEMENT
			aMsg := { 'Bank Statement Date not on file '+shMDY(xVal)}
			lValid := NormalValid('BankRec',BANKREC_ACCOUNTING_DATE_ORD, ;
				dtos(xVal))

		 case nTest == V_CHEQUE_TYPE
		 	aMsg := { 'Invalid Cheque type '+xVal}
         lValid :=  !empty(NameOf(LU_CHEQUE_TYPE, xVal))
			nLookUp := 0

		 case nTest == V_PRINTER
		 	aMsg := {'Printer '+xVal+' has not been set up'}
		 	if !ensureOpen({'Printer'})
		 		return(.f.)
		 	endif
		 	Printer->(dbGoTop())
			lValid := .f.
			do while !Printer->(eof())
				if xVal==Printer->unique
		 			lValid := .t.
		 			exit
		 		endif
		 		Printer->(dbSkip())
		 	enddo

		 case nTest == V_GROWER
		 	aMsg := {'Grower '+lstrim(xVal)+' is not on file'}
			if Grower->number==xVal .and. !Grower->(eof()) .and. ;
					 !Grower->(deleted())
				lValid := .t.
			else
		 		lValid := NormalValid('Grower',GROWER_NUMBER_ORD, ;
			 	 str(xVal,FLD_GROWER))
			endif

		 case nTest == V_TRANSACTION_TYPE
		 	aMsg := { 'Transaction Type '+xVal +' is not on file'}
		 	lValid := .f.
		 	for n := 1 to len(aTransDesc)
		 		if aTransDesc[n, A_TT_COLUMN_CODE]==xVal
		 			lValid := .t.
		 			exit
		 		endif
			next

			nLookup := 0

		 case nTest == V_MAY_ADD_TRANSACTION_TYPE
         aMsg := { 'Transaction Type '+xVal +' is allowed to added...'}
		 	lValid := .f.
		 	for n := 1 to len(aMayAdd)
		 		if aMayAdd[n,A_TT_COLUMN_CODE]==xVal
		 			lValid := .t.
		 			exit
		 		endif
			next

		 case nTest == V_DEDUCTION_CLASS
		 	aMsg := { 'Deduction Class '+xVal +' is not on file'}
		 	lValid := .f.
		 	for n := 1 to len(aDedClass)
		 		if aDedClass[n, A_SINGLE_TYPE_CLASS_COLUMN_CODE]==xVal
		 			lValid := .t.
		 			exit
		 		endif
			next

		 case nTest == V_ALL_ACCOUNT_CLASSES
		 	aMsg := { 'Account Class '+xVal +' is not allowed'}
		 	lValid := .f.
		 	for n := 1 to len(aAllAcctClass)
		 		if aAllAcctClass[n,A_SINGLE_TYPE_CLASS_COLUMN_CODE]==xVal
		 			lValid := .t.
		 			exit
		 		endif
			next
		case nTest == V_CLASS_FOR_A_TYPE
			lFound := .f.
			lValid := .f.
			if valType(xInfo)=='C'
				aMsg := { 'Account Class '+xVal +' is not allowed for Type='+xInfo}
				for n := 1 to len(aAllAcctClass)
					if aAllAcctClass[n,A_ALL_TYPE_CLASSES_COLUMN_TYPE_CODE ]==xInfo
						lFound := .t.   // we found the type
						if aAllAcctClass[n,A_ALL_TYPE_CLASSES_COLUMN_CLASS_CODE ]==xVal
							lValid := .t.
							exit
						endif
					endif
				next
				if !lFound
					// then there are no classes for this Account->type
					do case
					case empty( xInfo) .and. empty( xVal)
						lValid := .t.    // just to let us past...
					case empty(xVal)
						lValid := .t.
					endcase
				endif
			else
				aMsg := {'We can NOT look up a CLASS because we do not know the type'}
			endif

	   case nTest == V_PAYGRP
			aMsg := { 'PayGrp ID '+xVal+' is not on File'  }
			if PayGrp->PayGrp==xVal .and. !PayGrp->(deleted()) .and. ;
					!PayGrp->(eof())
				lValid := .t.
			else
				lValid := NormalValid( 	'PayGrp', PAYGRP_PAYGRP_ORD, xVal )
			endif

      case nTest == V_IMPORT_BATCH
         aMsg := { 'Import Batch '+lstrim(xVal)+' is not on File'  }

			lTest1 := .t.
			if valType( xInfo) == 'C'
				if !empty( xInfo )
					lTest1 := .f.
				endif
			endif

			if lTest1
				// No Depot ID
				if ImpBat->imp_bat==xVal .and. !ImpBat->(deleted()) .and. ;
						!ImpBat->(eof())
					lValid := .t.
				else
					lValid := NormalValid(  'ImpBat',IMPBAT_BATCH_ORD, ;
						str(xVal, FLD_DOCUMENT) )
				endif
			else
				// Has Depot ID
				if ImpBat->imp_bat==xVal .and. !ImpBat->(deleted()) .and. ;
				   ImpBat->depot==xInfo .and.  !ImpBat->(eof())
					lValid := .t.
				else
					lValid := NormalValid(  'ImpBat',IMPBAT_DEPOT_BATCH_ORD, ;
						xInfo + str(xVal, FLD_DOCUMENT) )
				endif

			endif
      case nTest == V_PROCESS_CLASS
         aMsg := {'The class of Process is not defined' }
         if xVal >= 1 .and. xVal <= len( aProcClass )
            lValid := .t.
         endif

      case nTest == V_PRODUCT_CATEGORY
         aMsg := {'The Product Category is not defined' }
         if xVal >= 0 .and. xVal <= len( aProdCat )
            // implicit NOT categorized
            lValid := .t.
         endif

      case nTest == V_DEPOT
			aMsg := { 'Depot ID '+xVal+' is not on File'  }
			if Depot->depot==xVal .and. !Depot->(deleted()) .and. ;
					!Depot->(eof())
				lValid := .t.
			else
				lValid := NormalValid( 	'Depot',PRODUCT_PRODUCT_ORD, xVal )
			endif

		case nTest == V_IMPORT_SESSION
			if empty( xVal )
				aMsg := { 'Import Session 0 implies NO import batch' }
				lValid := .t.
			else
				aMsg := { 'Import Session '+ var2char( xVal ) + ' is not on file' }
				nValue := NIL
				if valType( xVal ) == "N"
					nValue := xVal
				else
					nValue := val( var2char( xVal ) )
				endif
				lValid := NormalValid( 	'ImpBat', IMPBAT_UNIQUE_ID_ORD, str( nValue, FLD_DOCUMENT) )
			endif

      endcase

		exit
	enddo

	if empty(xVal)
		aadd(aMsg,'- Because the ID code is EMPTY  ! -')
	endif

	if !lValid
		do case
		case nShowMsg==VT_MESSAGE
			waitHand( aMsg )
		case nShowMsg==VT_BROWSE .and. nLookup > 0
			browses( {}, nLookup, xInfo)
		endcase
	endif

return( lValid )


function NameOf( nTest, xCode, xInfo )
   local cReturn :=''
	local n1,  n

	default xInfo to ''

   ProdCatInit( aProdCat )

	do case
	 case nTest == LU_CURRENCY
		do case
		case xCode==CANADIAN_DOLLARS
			cReturn := 'CAD$'
		case xCode==US_DOLLARS
			cReturn := 'USD$'
		otherwise
			cReturn := '    '
		endcase

	 case nTest == LU_CHEQUE_TYPE
		cReturn := space(len(aChequeType[1,2]))

		for n:= 1 to len(aChequeType)
			if xCode==aChequeType[n,1]
				cReturn := aChequeType[n,2]
			endif
		next

    case nTest == LU_PROCESS_CLASS
      cReturn := space(len(aProcClass[1]))

      if xCode >= 1 .and. xCode <= len(aProcClass)
         cReturn := aProcClass[xCode]
      else
         cReturn := aProcClass[ PROCESS_CLASS_OTHER ]
      endif

    case nTest == LU_PRODUCT_CATEGORY
      cReturn := padr('Other',len( aProdCat[1] ) )
      if xCode >= 1 .and. xCode <= len(aProdCat)
         cReturn := aProdCat[xCode]
      endif

	case nTest ==   LU_HAVE_PRODUCT_CATEGORY_DESC
		cReturn := padr(' ',len( aProdCat[1] ) )
		if !empty( xCode )
			if ValidTest( V_PRODUCT, xCode, VT_NO_MESSAGE )
				n1 := Product->category
				if n1 >= 1 .and. n1 <= len(aProdCat)
					cReturn := aProdCat[ n1 ]
				endif
			endif
		endif

   // should really use V_TRANSACTION_TYPE, since MAY_ADD is a subset !
   case nTest == LU_MAY_ADD_TRANSACTION_TYPE
  		cReturn := space( len(aMayAdd[1,A_TT_COLUMN_DESC]) )
	 	for n := 1 to len(aMayAdd)
	 		if aMayAdd[n,A_TT_COLUMN_CODE]==xCode
	 			cReturn := aMayAdd[n,A_TT_COLUMN_DESC]
	 			exit
	 		endif
		next

   case nTest == LU_TRANSACTION_TYPE
  		cReturn := space( len(aTransDesc[1,A_TT_COLUMN_DESC]) )
	 	for n := 1 to len(aTransDesc)
	 		if aTransDesc[n, A_TT_COLUMN_CODE ]==xCode
	 			cReturn := aTransDesc[n, A_TT_COLUMN_DESC]
	 			exit
	 		endif
		next

   case nTest == LU_TRANSACT_TYPE_SORT_CODE
  		cReturn := space( len(aTransDesc[1,A_TT_COLUMN_SORT_BY]) )
	 	for n := 1 to len(aTransDesc)
	 		if aTransDesc[n, A_TT_COLUMN_CODE ]==xCode
	 			cReturn := aTransDesc[n, A_TT_COLUMN_SORT_BY]
	 			exit
	 		endif
		next

   case nTest == LU_SHORT_TRANSACTION_TYPE
  		cReturn := space( len(aTransDesc[1,A_TT_COLUMN_SHORT_DESC]) )
	 	for n := 1 to len(aTransDesc)
	 		if aTransDesc[n,A_TT_COLUMN_CODE]==xCode
	 			cReturn := aTransDesc[n,A_TT_COLUMN_SHORT_DESC]
	 			exit
	 		endif
		next

   case nTest == LU_DEDUCTION_CLASS
  		cReturn := space( len(aDedClass[1,A_SINGLE_TYPE_CLASS_COLUMN_DESC ]) )
	 	for n := 1 to len(aDedClass)
	 		if aDedClass[n, A_SINGLE_TYPE_CLASS_COLUMN_CODE ]==xCode
	 			cReturn := aDedClass[n, A_SINGLE_TYPE_CLASS_COLUMN_DESC ]
	 			exit
	 		endif
		next

    case nTest == LU_ALL_ACCOUNT_CLASSES
  		cReturn := space( len(aAllAcctClass[1, A_ALL_TYPE_CLASSES_COLUMN_DESC  ]) )
	 	for n := 1 to len(aAllAcctClass)
	 		if aAllAcctClass[n,A_ALL_TYPE_CLASSES_COLUMN_CLASS_CODE ]==xCode
	 			cReturn := aAllAcctClass[n,A_ALL_TYPE_CLASSES_COLUMN_DESC  ]
	 			exit
	 		endif
		next

	case nTest == LU_CLASS_FOR_A_TYPE
  		cReturn := space( len(aAllAcctClass[1, A_ALL_TYPE_CLASSES_COLUMN_DESC  ]) )

		if valType(xInfo)=='C'
			for n := 1 to len(aAllAcctClass)
				if aAllAcctClass[n,A_ALL_TYPE_CLASSES_COLUMN_CLASS_CODE ]==xCode ;
				            .and. ;
					aAllAcctClass[n,A_ALL_TYPE_CLASSES_COLUMN_TYPE_CODE ]==xInfo

					cReturn := aAllAcctClass[n,A_ALL_TYPE_CLASSES_COLUMN_DESC  ]
					exit
				endif
			next
		endif

	case nTest == LU_GROWER_STATUS
      if ValidTest(V_GROWER, xCode, VT_NO_MESSAGE)
      	cReturn := Grower->status
      else
      	cReturn := 0                  // Numeric !
      endif

	case nTest == LU_GROWER .or. nTest == LU_GROWER_NAME
      if ValidTest(V_GROWER, xCode, VT_NO_MESSAGE)
      	cReturn := Grower->name
      else
      	cReturn := space(len(Grower->name))
      endif

	case nTest == LU_GROWER_CHEQUE_NAME
      if ValidTest(V_GROWER, xCode, VT_NO_MESSAGE)
      	cReturn := Grower->cheqname
      else
      	cReturn := space(len(Grower->cheqname))
      endif

	case nTest == LU_PROCESS_TYPE
      if ValidTest(V_PROCESS_TYPE, xCode, VT_NO_MESSAGE)
      	cReturn := Process->desc
      else
      	cReturn := space(len(Process->desc ))
      endif

	case nTest == LU_PROCESS_GRADE
		cReturn := space( FLD_PROCESS_GRADE_NAME )

      if ValidTest(V_PROCESS_TYPE, xCode, VT_NO_MESSAGE)
         if valType( xInfo ) == 'N'
         	if xInfo >= MIN_GRADE_NO .and. xInfo <= MAX_GRADE_NO
					do case
               case xInfo == 1
               	cReturn := Process->grade_n1
               case xInfo == 2
               	cReturn := Process->grade_n2
               case xInfo == 3
               	cReturn := Process->grade_n3
               endcase
            endif
         endif
      endif

	case nTest == LU_VARIETY
      if ValidTest(V_VARIETY, xCode, VT_NO_MESSAGE)
      	cReturn := Variety->desc
      else
      	cReturn := space(len(Variety->desc ))
      endif

	case nTest == LU_PRODUCT
      if ValidTest(V_PRODUCT, xCode, VT_NO_MESSAGE)
      	cReturn := Product->desc
      else
      	cReturn := space(len(Product->desc ))
      endif

	case nTest == LU_SHORT_PRODUCT_NAME
      if ValidTest(V_PRODUCT, xCode, VT_NO_MESSAGE)
      	cReturn := Product->ShortDesc
			if empty(Product->ShortDesc)
				cReturn := substr(Product->desc,1,FLD_SHORTDESC)
			endif
      else
      	cReturn := space( FLD_SHORTDESC )
      endif

	case nTest == LU_PAYGRP
      if ValidTest(V_PAYGRP, xCode, VT_NO_MESSAGE)
      	cReturn := PayGrp->Desc
      else
      	cReturn := space(len(PayGrp->desc ))
      endif

	case nTest == LU_DEPOT
      if ValidTest(V_DEPOT, xCode, VT_NO_MESSAGE)
      	cReturn := Depot->depotname
      else
      	cReturn := space(FLD_DEPOT_NAME)
      endif
   case nTest == LU_IMPORT_BATCH
		do case
		case empty( xCode )
			cReturn := 'Input in the office'
		case ValidTest(V_IMPORT_BATCH, xCode, VT_NO_MESSAGE, xInfo )
			cReturn := 'ImpBat='+iif(empty( ImpBat->depot),'Depot Unknown',ImpBat->depot)+ '-'+lStrim( ImpBat->IMP_BAT) + ' '
			do case
			case empty( xCode )
				cReturn += ' Input in Office'
			case ImpBat->LOW_DATE == ImpBat->HIGH_DATE
				cReturn += ' From: '+shMdy( ImpBat->LOW_DATE )
			otherwise
				cReturn += ' Fr: '+shMdy( ImpBat->LOW_DATE ) +' - '+shMdy( ImpBat->HIGH_DATE )
			endcase
		otherwise
			cReturn := 'Import info not found' + ;
			     iif( valType(xInfo)=='C',xInfo, Var2Char( xInfo)) + ' '+ ;
				  iif( valType(xCode)=='N',lStrim(xCode), Var2Char( xCode))
		endcase
		cReturn := padr( cReturn,35)
	endcase

return( cReturn )

static function NormalValid(cFile,nOrder,xVal)
	local lValid := .f.

	// we DO NOT allow Empty xVal !
	if valType(xVal)=='C'
		if alltrim(xVal)=='0'   // we pass data as strings usually....
			return( lValid)
		endif
	endif

	if ! empty(xVal)
		if ensureOpen( { cFile })
         (cFile)->(OrdSetFocus(nOrder))
			lValid := (cFile)->(dbSeek( xVal, HARDSEEK))
		endif
	endif

return( lValid )

function ProdCatInit( aRay )
   local n

   if len( aRay)==0       // aProdCat
      for n := 1 to  MAX_NO_PRODUCT_CATEGORIES
         aadd( aRay, ;
           sysValue( SYS_PRODUCT_CATEGORY___ + str( n,1) ) )
      next
   endif
return( nil )


function MayChgGSTonType( cType )
	local lReturn := .f.
	local n

	for n := 1 to len( aTransDesc )
		if aTransDesc[ n, A_TT_COLUMN_CODE ] == cType
			if aTransDesc[ n, A_TT_COLUMN_GST_TAXABLE ]
				lReturn := .t.
				exit
			endif
		endif
	next

return( lReturn )


