// ---------------------------------------------------------------------------
//  Application: Berry Payment System
//  Description:
//      Aug 2011 - add stuff for SandBox
//      July 24, 2014 - GST related changes
//      Sep 10, 2019 - minor improvement to formatting etc.
//      May 20, 2020 - add CounterIDs to open statement
//
//    File Name: MISC.PRG
//       Author: Bill Hepler
// Date created: 05-23-99
// Time created: 04:19:42pm
// Copyright (c) 1999, 2011, 2014, 2020 by Bill Hepler & Crafted Industrial Software Ltd.
//----------------------------------------------------------------------------

#include "COLORS.CH"   // bsgStd one
#include "common.ch"
#include "errors.ch"
#include 'valid.ch'
#include "bsgstd.ch"
#include 'sysvalue.ch'
#include 'indexord.ch'
#include 'account.ch'
#include 'field.ch'
#include "events.ch"

static lHoldUI := .t.

static cDataDirInfo := ''
static nDataYear    := 0

function TheClientName( )
   local cReturn

   if 'SANDBOX' $ upper( CurDirectory())
      cReturn := 'SANDBOX '+alltrim( substr( SysValue( SYS_ACTUAL_CLIENT_NAME),1,15 ))
   else
      cReturn := alltrim(SysValue( SYS_ACTUAL_CLIENT_NAME ))
   endif
return( cReturn )


function openMainStuff( lShared )
	local lReturn

	lReturn := openfile( ;
		{ 'Account', 'AudAcct',    'Audit',                           ;
		  'Cheque',  'ChqFmt',     'Contain', 'CounterIDs',           ;
		  'Daily',   'Daily_Audit','Depot',   'Events',               ;
		  'FinBat',  'Grower',     'ImpBat',                          ;
		  'PayGrp',  'PostBat',    'Price',   'Process',  'Product',  ;
		  'Variety', 'VoidTck'                                          },  lShared )

return( lReturn )

function open4ChequeRun( lShared )
	local lReturn

	lReturn := openMainStuff( lShared )

return( lReturn )

function InclPrdPrcGrDepo( cProduct, cProcess, nGrower, cDepot )
	local lReturn := .t.

	default nGrower to 0

	if !empty(cProcess)
		if Field->process <> cProcess
			lReturn := .f.
		endif
	endif

	if !empty(cProduct)
		if Field->product <> cProduct
			lReturn := .f.
		endif
	endif

	if nGrower > 0
		if Field->Number <> nGrower
			lReturn := .f.
		endif
	endif

	if !empty( cDepot )
		if !(Field->depot==cDepot)
			lReturn := .f.
		endif
	endif

return( lReturn )

function IncludeMe( cProduct, cProcess, nGrower, cDepot )
	local lReturn := .f.

	default nGrower to 0
	default cDepot to ''

	if str(Field->net,12,1) <> str(0,12,1)
		lReturn := InclPrdPrcGrDepo( cProduct, cProcess, nGrower, cDepot )
	endif
return( lReturn )

function GradeStr( n )
	local cReturn := space(2)

	if n > 0
		cReturn := str(n,2)
	endif

return( cReturn )

function LongProGradeStr( cProcess, nGrade )
	local cReturn := ''
   local nLen   := FLD_PROCESS + 2 + FLD_PROCESS_GRADE_NAME
   local cGrade := ''

	do case
	case empty( cProcess )
		cReturn := space( nLen )
	case nGrade <= 0
		cReturn := padr( cProcess, nLen)
	otherwise
		if sysValue( SYS_USE_PROCESS_GRADE_NAMES )
			cGrade := NameOf( LU_PROCESS_GRADE, cProcess, nGrade )
			cReturn := padr( cProcess + str(nGrade,1)+' ' + alltrim( cGrade), nLen )
		else
		  cReturn := padr( cProcess + ' ' + str( nGrade, 1), nLen)
		endif
	endcase

return( cReturn )

function UnitPrDec( nPrice, nDigits )
	local cReturn

	DEFAULT nDigits to 9

	if right(str(nPrice,12,3),1)=='0'
		cReturn := str(nPrice, nDigits,2)
	else
		cReturn := str(nPrice, nDigits ,3)
	endif

return( cReturn )

function forPP( cProduct, cProcess )
	local lReturn := .F.

	do case
	case empty(cProduct) .and. empty(cProcess)
		lReturn := .t.
	case !empty(cProduct) .and. !empty(cProcess)
		if Daily->product==cProduct .and. Daily->process==cProcess
			lReturn := .t.
		endif
	case !empty(cProduct)
		if Daily->product==cProduct
			lReturn := .t.
		endif
	case !empty(cProcess)
		if Daily->process==cProcess
			lReturn := .t.
		endif
	endcase

return( lReturn )

function GrInPayGrp(cIncPayGrp,cExcPayGrp)
	local lReturn := .F.
	local aDBF

	if empty(cIncPayGrp) .and. empty(cExcPayGrp)
		lReturn := .t.
	else
		if Grower->number==Daily->number
			do case
			case Grower->payGrp==cIncPayGrp .and. !empty(cIncPayGrp)
				lReturn := .t.
			case Grower->payGrp<>cExcPayGrp .and. !empty(cExcPayGrp)
				lReturn := .t.
			endcase
		else
         appError( APP_ERR_GROWER_NOT_FOUND_HERE1, ;
				{'Could Not Find Grower '+lStrim(Daily->number), ;
				 'was checking Pay Groups: '+cIncPayGrp+','+cExcPayGrp, ;
				 'Error may not be critical...' })

			aDBF := Grower->( SaveDBF( ))
			if ValidTest( V_GROWER, Daily->number, VT_NO_MESSAGE)
				do case
				case Grower->payGrp==cIncPayGrp .and. !empty(cIncPayGrp)
					lReturn := .t.
				case Grower->payGrp<>cExcPayGrp .and. !empty(cExcPayGrp)
					lReturn := .t.
				endcase
			endif
			Grower->(restDBF( aDBF ))
		endif
	endif

return( lReturn )

function VariousHead( aHead, dLastDate, cProduct, cProcess, ;
		 nIncGrower, cIncPayGrp, nExcGrower, cExcPayGrp )

	aadd( aHead, 'Includes transactions up to '+shMDY(dLastDate) )
	if !empty(cProduct)
		aadd(aHead,'Product = '+cProduct)
	endif
	if !empty(cProcess)
		aadd(aHead,'Process = '+cProcess)
	endif
	if nIncGrower<>0
		aadd(aHead,'Grower = '+lStrim(nIncGrower) )
	endif
	if nExcGrower<>0
		aadd(aHead,'Exclude Grower '+lStrim(nExcGrower) )
	endif
	if !empty(cIncPayGrp)
		aadd(aHead,'Pay Group = '+cIncPayGrp)
	endif
	if !empty(cExcPayGrp)
		aadd(aHead,'Exclude Pay Group = '+cExcPayGrp)
	endif

return( nil )

function SetHoldUI( lSet )
   // see notes ON EXCLonHOLD() below
   local lReturn

   lReturn := lHoldUI

   lHoldUI := lSet

return( lReturn )

function ExclOnHold(  )
   // Excludes transactions where grower is ON-HOLD
   // used for Building Indexes mainly
   // for indexes use like:
   //     SetHoldUI( .t. )
   //     set relation to Grower
   //     select Daily
   //     index on whatever for ExclOnHold() to whatever
   //     SetHoldUI( .f. )
   //     ...
   // For non Indexed, if you set relation, sb as above,
   //  if no relation set, then SETholdUI( .f. )...


   local lReturn := .t.
   local aDBF

   if Grower->number<>Daily->number

      if lHoldUI
         appError( APP_ERR_GROWER_NOT_FOUND_HERE2 , ;
         {'Could Not Find Grower '+lStrim(Daily->number), ;
            'was checking On HOLDS', ;
            'Error may not be critical...' })
      endif

      aDBF := Grower->( SaveDBF( ))
      if !ValidTest( V_GROWER, Daily->number, VT_NO_MESSAGE)
         lReturn := .f.
      endif
      Grower->(restDBF( aDBF ))
   endif
   if Grower->onHold
      lReturn := .f.
   endif
return( lReturn )


function ValidDirThing( c )
   local lReturn := .f.

   if len( c ) >= 3
      if isAlpha( substr( c,1,1)) .and. substr(c,2,2)==':\' .and. ;
         right( alltrim(c), 1) == '\'
         lReturn := .t.
      endif
   endif

   if !lReturn
      waitHand({'A valid directory must be like this:', ;
                '   A:\', ;
                '   C:\IMPORT\', ;
                '   G:\DATADIR\IMPORT\', ;
                'The first letter is the DRIVE LETTER, followed', ;
                'by a COLON and a BACK SLASH.  The last character must', ;
                'be a BACKSLASH.', ;
                'This program does not support UNC names'})
   endif

return( lReturn )


function DollarStr(nDollars, nWidth)
	local cReturn

	if valType(nWidth) == 'N'
		cReturn := padl('$ '+alltrim(transform( nDollars,'9,999,999,999.99')),nWidth)
	else
		cReturn := '$ '+alltrim(transform( nDollars,'9,999,999,999.99'))
	endif

return( cReturn )

function MakeTempPostDBFs( )
	// These are PUBLIC names of Temporary Posting Files....

	select Account
	copy structure to TempAcct
	use TempAcct exclusive new

	select Audit
	copy structure to TempAud
	use TempAud exclusive new

	select AudAcct
	copy structure to TempA_A
	use TempA_A exclusive new

return( nil )

function CloseTempPostDBFs( )
	// These are PUBLIC names of Temporary Posting Files....
   if select('TempAcct')<>0
		TempAcct->(dbCloseArea())
	endif
	if select('TempAud')<>0
	  	TempAud->(dbCloseArea())
	endif
	if select('TempA_A')<>0
		TempA_A->(dbCloseArea())
	endif

	if file('_TMPACCT.DBF') .and. file('TEMPACCT.DBF')
		fErase( '_TMPACCT.DBF' )
	endif
	if file('_TMPAUD.DBF') .and. file('TEMPAUD.DBF')
		fErase( '_TMPAUD.DBF' )
	endif
	if file('_TEMPA_A.DBF') .and. file('TEMPA_A.DBF')
		fErase( '_TMPA_A.DBF' )
	endif

	if file('TEMPACCT.DBF')
		fRename( 'TEMPACCT.DBF', '_TMPACCT.DBF' )
	endif
	if file('TEMPAUD.DBF')
		fRename( 'TEMPAUD.DBF', '_TMPAUD.DBF' )
	endif
	if file('TEMPA_A.DBF')
		fRename( 'TEMPA_A.DBF', '_TMPA_A.DBF' )
	endif

	if file('TEMPACCT.CDX')
		fErase( 'TEMPACCT.CDX')
	endif
	if file('TEMPAUD.CDX')
		fErase( 'TEMPAUD.CDX' )
	endif
	if file('TEMPA_A.CDX')
		fErase( 'TEMPA_A.CDX' )
	endif

return( nil )

function NextAcctUniq( )
	local nReturn := 0

	Account->(ordSetFocus( 0 ))  // Record Order
	Account->(dbGoBottom())
	if !Account->(eof())
		nReturn := max( Account->acct_uniq, nReturn )

		Account->(ordSetFocus( ACCOUNT_NUMBER_ORD ))
		Account->(dbGoBottom())
		// can suppress for now...
		do case
		case Num2Equal0( Account->acct_uniq )
			if Account->QADD_DATE > ctod('07/07/2014')
				appError( APP_ERR_ACCT_UNIQ_5, ;
				  {'The last transaction in the Accounting Entries has', ;
					'an ID of Zero.  ', ;
					'This might need to be corrected.', ;
					'Record Number='+lStrim(Account->(recno())), ;
					'Grower is='+lStrim(Account->number) })
			endif
		case Account->acct_uniq > nReturn
			appError( APP_ERR_ACCT_UNIQ_1, ;
			  {'We are correcting an unexpected error with assigning', ;
				'a unique identifier to ACCOUNT.DBF entries.  This is', ;
				'odd and should be reported, but the system is correcting', ;
				'the problem. See ACCOUNT.DBF', ;
				'This could indicate an Indexing problem', ;
				'Account is reporting='+lStrim(Account->acct_uniq), ;
				'Our initial thought was='+lStrim(nReturn)})
		endcase
	endif
	nReturn := max( Account->acct_uniq, nReturn )

	Audit->(ordSetFocus( AUDIT_ACCT_DAY_ORD ))
	Audit->(dbGoBottom())
	if Audit->acct_uniq > nReturn
		appError( APP_ERR_ACCT_UNIQ_2, ;
		  {'We are correcting an unexpected error with assigning', ;
		   'a unique identifier to ACCOUNT.DBF entries.  This is', ;
			'odd and should be reported, but the system is correcting', ;
			'the problem. See AUDIT.DBF', ;
			'Our initial thought was='+lStrim(nReturn)})
	endif
	nReturn := max( Audit->acct_uniq, nReturn )

	AudAcct->(ordSetFocus( AUDACCT_MASTER_CHILD ))
	AudAcct->(dbGoBottom())
	if Audit->acct_uniq > nReturn
		appError( APP_ERR_ACCT_UNIQ_3, ;
		  {'We are correcting an unexpected error with assigning', ;
		   'a unique identifier to ACCOUNT.DBF entries.  This is', ;
			'odd and should be reported, but the system is correcting', ;
			'the problem. See AudAcct.DBF->acct_uniq', ;
			'Our initial thought was='+lStrim(nReturn)})
	endif
	nReturn := max( AudAcct->acct_uniq, nReturn )

	AudAcct->(ordSetFocus( AUDACCT_CHILD_MASTER ))
	AudAcct->(dbGoBottom())
	if AudAcct->acct_child > nReturn
		appError( APP_ERR_ACCT_UNIQ_4, ;
		  {'We are correcting an unexpected error with assigning', ;
		   'a unique identifier to ACCOUNT.DBF entries.  This is', ;
			'odd and should be reported, but the system is correcting', ;
			'the problem.  See AudAcct.DBF->acct_child', ;
			'Our initial thought was='+lStrim(nReturn)})
	endif
	nReturn := max( AudAcct->acct_child, nReturn )

	nReturn++
return( nReturn )

function AccountRelations( aAcctRelStru )  // passed by reference its an array
	local aDBFacct, aDBFdaily, aDBFaudit, aDBFaudAcct, aDBFCheque
	local nAcctUniq := -1

	aDBFacct     := Account->(saveDBF())
	aDBFdaily    := Daily->(saveDBF())
	aDBFaudit    := Audit->(saveDBF())
	aDBFaudAcct  := AudAcct->(saveDBF())
	aDBFcheque   := Cheque->(saveDBF())

	aAcctRelStru[  REL_2_IS_ERROR           ]  :=   .f.
	aAcctRelStru[  REL_2_ERROR_CONDITION    ]  :=   ''

	nAcctUniq                                  := Account->acct_uniq
	aAcctRelStru[  REL_2_ACCT_UNIQ          ]  :=   nAcctUniq

	do case
	case Account->(eof())
		aAcctRelStru[  REL_2_IS_ERROR           ] := .t.
		aAcctRelStru[  REL_2_ERROR_CONDITION    ] := 'Not on ACCOUNT TRN!'
	case num2Equal0( nAcctUniq )
		aAcctRelStru[  REL_2_IS_ERROR           ] := .t.
		aAcctRelStru[  REL_2_ERROR_CONDITION    ] := 'ACCT ID# = 0'
	endcase

	Audit->(ordSetFocus( AUDIT_ACCT_DAY_ORD ))
	if Audit->(dbSeek( str( nAcctUniq, FLD_DOCUMENT ), HARDSEEK))
		aAcctRelStru[  REL_2_ACCOUNT_TRN_DAILY  ]   :=  .t.
	endif

	AudAcct->(ordSetFocus(  AUDACCT_MASTER_CHILD ))
	if AudAcct->(dbSeek( str( nAcctUniq, FLD_DOCUMENT ), HARDSEEK))
		aAcctRelStru[  REL_2_OTHER_ACCOUNTS     ]        := .t.
		aAcctRelStru[  REL_2_OTHER_ACCOUNTS_AS_MASTER]   := .t.
	endif

	AudAcct->(ordSetFocus(  AUDACCT_CHILD_MASTER ))
	if AudAcct->(dbSeek( str( nAcctUniq, FLD_DOCUMENT ), HARDSEEK))
		aAcctRelStru[  REL_2_OTHER_ACCOUNTS     ]        := .t.
		aAcctRelStru[  REL_2_OTHER_ACCOUNTS_AS_CHILD]    := .t.
	endif

	do case
	case !aAcctRelStru[  REL_2_OTHER_ACCOUNTS     ]  .and. ;
	     !aAcctRelStru[  REL_2_ACCOUNT_TRN_DAILY  ]

	  aAcctRelStru[  REL_2_STANDALONE         ]  := .t.

	case aAcctRelStru[  REL_2_OTHER_ACCOUNTS_AS_MASTER] .and. ;
	     aAcctRelStru[  REL_2_OTHER_ACCOUNTS_AS_CHILD ]

		aAcctRelStru[  REL_2_IS_ERROR           ] := .t.
		aAcctRelStru[  REL_2_ERROR_CONDITION    ] += 'Very Complex !'

	case aAcctRelStru[  REL_2_OTHER_ACCOUNTS_AS_MASTER] .and. ;
	     !aAcctRelStru[  REL_2_OTHER_ACCOUNTS_AS_CHILD ]

	  aAcctRelStru[  REL_2_ACCOUNT_MASTER     ]  := .t.

	endcase

	if !empty( Account->series) .or. !empty( Account->cheque)
		Cheque->(OrdSetFocus( CHEQUE_CHEQUE_NO_ORD))
		if Cheque->(dbSeek( Account->series + str( Account->cheque, FLD_CHEQUE),HARDSEEK))
			aAcctRelStru[  REL_2_CHEQUE_FULL_ID     ] :=  Account->series + ' '+lStrim( Account->cheque)
			aAcctRelStru[  REL_2_CHEQUE_INFO        ] :=  padr( shMDY(Cheque->date) + '  '+ ;
     			iif(Cheque->void,'VOID',alltrim( DollarStr(Cheque->amount,12) )), 24)
		else
			aAcctRelStru[  REL_2_IS_ERROR           ] := .t.
			aAcctRelStru[  REL_2_ERROR_CONDITION    ] += ' Chq NOT found'
			aAcctRelStru[  REL_2_CHEQUE_FULL_ID     ] :=  Account->series + ' '+lStrim( Account->cheque)
			aAcctRelStru[  REL_2_CHEQUE_INFO        ] :=  padr( 'Cheque NOT found!', 24)
		endif
	endif

	Account->(restDBF(aDBFacct ))
	Daily->(  restDBF(aDBFdaily))
	Audit->(  restDBF(aDBFaudit))
	AudAcct->(restDBF(aDBFaudAcct))
	Cheque->( restDBF(aDBFcheque))

return( nil )

function ArchiveCheckOK()
	local lReturn := .t.

   if !empty( sysValue( SYS_ARCHIVE_DATA_YEAR )) .or. ( nDataYear > 2000 .and. nDataYear < 2155 )
   	if !YesNo({'The data year is set to '+ sysValue( SYS_ARCHIVE_DATA_YEAR ), ;
                 iif( nDataYear > 2000,'Data Directory Year is '+ lStrim( nDataYear ), ''), ;
                'This often means this is an ARCHIVE', ;
                '','Do you wish to Continue?'})
         lReturn := .f.
         return( lReturn )
      endif

      if val( sysValue( SYS_ARCHIVE_DATA_YEAR ) ) > 2000 .and. ;
         year( date() ) > val( sysValue( SYS_ARCHIVE_DATA_YEAR )) + 1

         if !Yesno({'Are you sure you want to Continue?', ;
                   'We think we are running data from '+ sysValue( SYS_ARCHIVE_DATA_YEAR ) })
            lReturn := .f.
         endif
		endif
   endif

return( lReturn )

static function DataDirShower( )
   local cDir, cPart, c, cNum
   local n

	// the calculation is ONLY done ONCE - as we DO NOT change the Data Dir
   // while the program is running

   if empty( cDataDirInfo )
   	cDir   := CurDirectory()
      if right(cDir,1)=='\'
         cDir := left( cDir, len(cDir)-1)
      endif

      cPart  := ''
      cNum   := ''
      for n := len( cDir ) to 1 step -1
         c     := substr( cDir,n,1)
         if c == '\'
            exit
         endif
         cPart := c + cPart
         if isDigit( c )
            cNum := c + cPart
         endif
      next

      // Important Step
      cDataDirInfo := cPart
      nDataYear := val(cNum)
      if nDataYear < 2000 .or. nDataYear > 2100
         nDataYear := 0
      endif
      // ------------------
   endif

   if sysValue( SYS_SHOW_PART_DATA_DIR ) .and. !empty( cDataDirInfo )
     	bsgSetColor(COLOR_HEAD1)
      @ 01,maxCol() - (len( cDataDirInfo )+1) say cDataDirInfo
      bsgSetColor(COLOR_MAIN)
  endif

return( nil )

function myBsgScreen( cHead )
	bsgScreen( cHead )
   DataDirShower()

return( nil )
