//---------------------------------------------------------------------------
//   Application: Berry Payment System
//   Description: Converts Data from Older Version to New Version (automaticallY)
//     File Name: CONVDATA.PRG
//
//      Jun 2007 - Change some field names etc.
//      Jun 2010 - Add the Edit Delete Fields, still not implemented fully
//      Jul 2011 - Stuff to do with Old Grower Balances
//      Jul 2014 - GST related stuff, to Grower
// May/June 2015 - The VARIETY Field...
//      Dec 2019 - Minor additions
//      Mar 2020 - New Fields in Daily and other changes
//      Apr 2020 - AED_Fields_Nnn_Standard used... essentially change name of function.
//
//        Author: Bill Hepler
//  Date created: 05-20-95
//  Time created: 07:20:10am
//     Copyright: (c) 1995, 2011, 2014, 2015, 2019, 2020 by Bill Hepler
// ---------------------------------------------------------------------------

#include "account.ch"
#include "BerryPay.ch"
#include "bsgstd.ch"
#include "common.ch"
#include "dbstruct.ch"
#include "field.ch"
#include "SIGNON.CH"
#include "Unique_Fields.ch"

function ConvertData()

	BuildAccount()            // Summary of Posted Transactions
	BuildAudAcct()            // Tax Records that relate to Account Records....
	BuildAudit()              // Daily & Account
	BuildBankRec()
	BuildCheque()
	BuildChqFmt()
	BuildContainer()
	BuildCounterIDs()          // Apr 2020
	BuildDepot( )
	BuildEvents( )              // Dec 2019
	BuildFinBat()
	BuildGrower()
	BuildImpBat()
	BuildPayGrp()
	BuildPostBat()
	BuildPrice()
	BuildProcess()
	BuildProduct()
	BuildReceipts()
	BuildRptCfg(  )
	BuildTax( )
	BuildVariety()              // June 2015
	BuildVoid()

return( nil )

static function BuildChqFmt()
   local aStru

	// Changed in 2014 - got rid of ADD_DATE etc
	// aStru := { ;
   //      {'ID',      'C', FLD_CHQ_FORMAT_ID,0}, ;
   //      {'TYPEFACE',  'N',5,0}, ;
   //      {'SYMBOL',    'C',3,0}, ;
   //      {'ISFIXED',   'L',1,0}, ;
   //      {'DARKNESS',  'N',2,0}, ;
   //      {'PITCH',     'N',2,0}, ;
   //      {'XINCH',     'N',7,4}, ;
   //      {'YINCH',     'N',7,4}, ;
   //      {'NOTE',      'C',30,0}, ;
   //      {'PRINTTHIS', 'L',1, 0}, ;
   //      {'ADD_DATE',  'D', 8 , 000 }, ;
   //      {'ADD_BY',    'C', 8 , 000 }, ;
   //      {'EDIT_DATE', 'D', 8 , 000 }, ;
   //      {'EDIT_BY'  , 'C', 8 , 000 }, ;
   //      {'EDIT_REAS', 'C', 20 , 000 }, ;
   //      {'W32FONT',   'C', 45 , 000 } }

	aStru := { ;
         {'ID',      'C', FLD_CHQ_FORMAT_ID,0}, ;
         {'TYPEFACE',  'N',5,0}, ;
         {'SYMBOL',    'C',3,0}, ;
         {'ISFIXED',   'L',1,0}, ;
         {'DARKNESS',  'N',2,0}, ;
         {'PITCH',     'N',2,0}, ;
         {'XINCH',     'N',7,4}, ;
         {'YINCH',     'N',7,4}, ;
         {'NOTE',      'C',30,0}, ;
         {'PRINTTHIS', 'L',1, 0}, ;
         {'EDIT_REAS', 'C', 20 , 000 }, ;
         {'W32FONT',   'C', 45 , 000 } }

   AED_Fields_nonStd( aStru )   // June 2010
   AssertStructure( 'ChqFmt', aStru, .t. )


return( nil )

static function BuildVoid()
	local aStru

	aStru := { ;
         {'DATE',      'D',8,0}, ;
         {'DEPOT',     'C',FLD_DEPOT,0}, ;
         {'RECPT',     'N',FLD_RECPT,0}, ;
         {'NUMBER',    'N',004,0}, ;
         {'PRODUCT',   'C',FLD_PRODUCT,0}, ;
         {'REASON',    'C',20,0}, ;
         {'IMP_BAT',   'N',FLD_DOCUMENT,0}, ;
         {'EDIT_REAS', 'C', 20 , 000 } }

   AED_Fields_nonStd( aStru )   // June 2010

	aadd( aStru, { 'UNIQ_IMBAT', 'N', FLD_DOCUMENT, 0 })     // April 2020

   AssertStructure( 'VoidTck', aStru, .t. )

return( nil )


static function BuildReceipts()
	local aStru

	aStru := ReceiptStru( RECEIPT_STRU_FOR_DAILY )

   AED_Fields_nonStd( aStru )   // June 2010 - because we use special names for these fields...
	AssertStructure( 'Daily', aStru, .t. )

	aadd( aStru, { 'DAYAUD_ID',  'N',   FLD_DOCUMENT, 0 })    // Audit Field

	aadd( aStru, { 'AUD_DATE',  'D',   8 , 0 })                // Audit Field - see Record Adder  nAddUniqueRec( )
	aadd( aStru, { 'AUD_TIME',  'C',   8 , 0 })                // Audit Field
	aadd( aStru, { 'AUD_BY',    'C',   USER_FLD_WIDTH, 0 })    // Audit Field

   AssertStructure( 'Daily_Audit', aStru, .t. )   // March 2020 - the data as imported from Scale - AUDIT file !
return( nil )

static function BuildBankRec()
	local aStru

	aStru := { ;
			{'ACCTDATE','D',8,0}, ;
			{'DATEDONE','D',8,0}, ;
			{'NOTE','C',30,0}, ;
			{'AMOUNT',  'N',12,2}  }

   AED_Fields_nonStd( aStru )   // June 2010
	AssertStructure( 'BankRec', aStru, .t. )

return( nil )

static function BuildCheque()

	local aStru := {}

	aadd( aStru, {'SERIES',      'C'  ,  FLD_SERIES  ,   000 })
	aadd( aStru, {'CHEQUE',      'N'  ,  FLD_CHEQUE  ,   000 })
	aadd( aStru, {'NUMBER',      'N'  ,  004  ,   000 })
	aadd( aStru, {'DATE',        'D'  ,  008  ,   000 })
	aadd( aStru, {'AMOUNT',      'N'  ,  010  ,   002 })
	aadd( aStru, {'YEAR',        'N'  ,  004  ,   000 })             // This is the GROWING SEASON year of the transaction
	                                                                 // This field has turned out to be redundant & slighlty troublesome
																						  // as Packing Houses tend to keep each year separate-noted in 2020
																						  // The separate years thing has been in place for at least 10 years!
	aadd( aStru, {'CHEQTYPE',    'C'  ,  001  ,   000 })
	aadd( aStru, {'VOID',        'L'  ,  001  ,   000 })
	aadd( aStru, {'DATECLEAR',   'D'  ,  008  ,   000 })
	aadd( aStru, {'ISCLEARED',   'L'  ,  001  ,   000 })
	aadd( aStru, {'CURRENCY',    'C'  ,  001  ,   000 })

   AED_Fields_nonStd( aStru )   // June 2010
	AssertStructure( 'Cheque', aStru, .t. )

	aadd( aStru, {'DATEVOID',   'D'  ,  008  ,   000 })
	aadd( aStru, {'NOTE',       'C'  ,  030  ,   000 })

	AssertStructure( 'VoidChq', aStru, .t. )

return( nil )

static function BuildGrower()

	local aStru := {}

	aadd( aStru, {'NUMBER',      'N'  ,  004  ,   000 })
	aadd( aStru, {'STATUS',      'N'  ,  FLD_STATUS  ,   000 })
	aadd( aStru, {'CHEQNAME',    'C'  ,  030  ,   000 })
	aadd( aStru, {'NAME',        'C'  ,  030  ,   000 })
   aadd( aStru, {'STREET',      'C'  ,  030  ,   000 })
   aadd( aStru, {'CITY',        'C'  ,  025  ,   000 })
	aadd( aStru, {'PROV',        'C'  ,  002  ,   000 })
   aadd( aStru, {'PCODE',       'C'  ,  010  ,   000 })
   aadd( aStru, {'PHONE',       'C'  ,  013  ,   000 })   // wider June 2005

	// Depot of grower is MOSTLY not used.
	aadd( aStru, {'DEPOT',       'C'  ,  FLD_DEPOT ,   000 })

	aadd( aStru, {'ACRES',       'N'  ,  006  ,   002 })
	aadd( aStru, {'NOTES',       'C'  ,  060  ,   000 })
	aadd( aStru, {'CONTRACT',    'C'  ,  001  ,   000 })
	aadd( aStru, {'CURRENCY',    'C'  ,  001  ,   000 })

	// Container credit Limit
	aadd( aStru, {'CONTLIM',    'N'  ,  008  ,   000 })

   aadd( aStru, {'PAYGRP',    'C'  ,  FLD_PAYGRP ,   000 })

   aadd( aStru, {'ONHOLD',    'L'  ,  1 ,   000 })   // July 2002

   aadd( aStru, {'PHONE2',    'C'  ,  013  ,   000 })   // added June 2005

   aadd( aStru, {'STREET2',      'C'  ,  030  ,   000 })  // added June,2006

   // June 2010
   aadd( aStru, {'ALT_NAME1',        'C'  ,  030  ,   000 })
   aadd( aStru, {'ALT_PHONE1',       'C'  ,  013  ,   000 })
   aadd( aStru, {'ALT_NAME2',        'C'  ,  030  ,   000 })
   aadd( aStru, {'ALT_PHONE2',       'C'  ,  013  ,   000 })
   aadd( aStru, {'NOTE2',            'C'  ,  060  ,   000 })

   // Never used

   // aadd( aStru, {'LY_PROD',       'N'  ,  008  ,   000 })
   aadd( aStru, {'LY_FRESH',       'N'  ,  008  ,   000 })
   aadd( aStru, {'LY_OTHER',       'N'  ,  008  ,   000 })

   AED_Fields_nonStd( aStru )   // June 2010
   aadd( aStru, {'CERTIFIED',       'C'  ,  FLD_CERTIFIED  ,   000 })    // the field Def width was put in 2020, but SAME as existing
   aadd( aStru, {'FAX',             'C'  ,  013  ,   000 })
	aadd( aStru, {'CHG_GST',         'L'  ,  001, 000 })

	AssertStructure( 'Grower', aStru, .t. )

return( nil )


static function BuildProduct()
	local aStru := {}

	aadd( aStru, {'PRODUCT',     'C'  , FLD_PRODUCT  ,   000 })
	aadd( aStru, {'DESC',        'C'  , FLD_PRODDESC ,   000 })
	aadd( aStru, {'SHORTDESC',   'C'  , FLD_SHORTDESC ,   000 })

	// for Marketing deduction
   aadd( aStru, {'DEDUCT',      'N'  ,  9,6 } )     // June 99
   aadd( aStru, {'CATEGORY',    'N'  ,  FLD_PRODUCT_CATEGORY, 0})     // July 2008
	aadd( aStru, {'CHG_GST',     'L'  ,  1, 0})

   AED_Fields_nonStd( aStru )   // June 2010
	aadd( aStru, {'VARIETY',     'C'  ,  FLD_VARIETY, 0})    // June 2015

	AssertStructure( 'Product', aStru, .t. )

return( nil )

static function BuildVariety()
	local aStru := {}

	aadd( aStru, {'VARIETY',     'C'  , FLD_VARIETY  ,   000 })
	aadd( aStru, {'DESC',        'C'  , FLD_VARIETY_DESC ,   000 })
	AED_Fields_nonStd( aStru )

	AssertStructure( 'Variety', aStru, .t. )

return( nil )

static function BuildProcess()

	local aStru := {}

	aadd( aStru, {'PROCESS',     'C'  , FLD_PROCESS  ,   000 })
	aadd( aStru, {'DESC',        'C'  , FLD_PROCDESC ,   000 })
   aadd( aStru, {'DEF_GRADE',   'N'  , 1, 0})
   aadd( aStru, {'PROC_CLASS',  'N'  , 1, 0})

   AED_Fields_nonStd( aStru )   // June 2010

   // Used by WestBerry Farms - April 2019
   aadd( aStru, {'GRADE_N1',    'C'  , FLD_PROCESS_GRADE_NAME, 0 })   // Name if Using for Grade 1 of a given process
   aadd( aStru, {'GRADE_N2',    'C'  , FLD_PROCESS_GRADE_NAME, 0 })
   aadd( aStru, {'GRADE_N3',    'C'  , FLD_PROCESS_GRADE_NAME, 0 })

	AssertStructure( 'Process', aStru, .t. )

return( nil )

static function BuildContainer()
	local aStru := {}


	aadd( aStru, { 'CONTAINER', 'N', FLD_CONTAINER, 0 } )
	aadd( aStru, { 'DESC',      'C', FLD_CONTAINER_DESC, 0 })
	aadd( aStru, { 'SHORT',     'C', FLD_CONTAINER_SHORT, 0 })
	aadd( aStru, { 'TARE',      'N', 3, 0 })
	aadd( aStru, { 'VALUE',     'N', 7, 2 })
	aadd( aStru, { 'INUSE',     'L', 1, 0 })

   AED_Fields_nonStd( aStru )   // June 2010
	AssertStructure( 'Contain', aStru, .t. )

return( nil )

static function BuildPrice()

	local aStru := {}
   local n1, n2, n3

	aadd( aStru, {'PRODUCT',     'C'  , FLD_PRODUCT  ,   000 })
	aadd( aStru, {'PROCESS',     'C'  , FLD_PROCESS  ,   000 })
	aadd( aStru, {'FROM',        'D'  , 8            ,   000 })

	aadd( aStru, {'TIME',        'C'  , 5            ,   000 })
	aadd( aStru, {'TIMEPREM',    'L'  , 1            ,   000 })

	aadd( aStru, {'CPREMIUM',    'N'  , 5            ,   002 })
	aadd( aStru, {'UPREMIUM',    'N'  , 5            ,   002 })

	// US & Canadian Dollars
	for n1 := 1 to MAX_NO_OF_GRADES
		for n2 := 1 to MAX_NO_OF_PRICE_LEVELS
         // OLD Level Pricing-1st Advance
         // aadd( aStru, {'UL'+str(n2,1)+'GRADE'+str(n1,1),  'N'  , 8  ,  2 })
         // aadd( aStru, {'CL'+str(n2,1)+'GRADE'+str(n1,1),  'N'  , 8  ,  2 })

			// 2nd Advance
         // aadd( aStru, {'U2A'+str(n2,1)+'GR'+str(n1,1),  'N'  , 8  ,  2 })
         // aadd( aStru, {'C2A'+str(n2,1)+'GR'+str(n1,1),  'N'  , 8  ,  2 })

			// 3rd Advance
         // aadd( aStru, {'U3A'+str(n2,1)+'GR'+str(n1,1),  'N'  , 8  ,  2 })
         // aadd( aStru, {'C3A'+str(n2,1)+'GR'+str(n1,1),  'N'  , 8  ,  2 })

			// Final Price
         // aadd( aStru, {'UFIN'+str(n2,1)+'GR'+str(n1,1),  'N'  , 8  ,  2 })
         // aadd( aStru, {'CFIN'+str(n2,1)+'GR'+str(n1,1),  'N'  , 8  ,  2 })

         // NEW:
         //   Price->CL1G1A1 - Canadian$ Level1, Grade1, Advance 1
         //   Price->CL1G1FN - Canadian$ Level1, Grade1, Final Price
         // there are 3 GRADES, 3 LEVELS, and 3 Advances MAX

         for n3 := 1 to MAX_NO_OF_ADVANCES
            aadd( aStru,{'C'+'L'+str(n2,1)+'G'+str(n1,1)+'A'+str(n3,1),'N',8,2 })
            aadd( aStru,{'U'+'L'+str(n2,1)+'G'+str(n1,1)+'A'+str(n3,1),'N',8,2 })
         next

         // Final Payment
         aadd( aStru, {'C'+'L'+str(n2,1)+'G'+str(n1,1)+'FN','N',8,2 } )
         aadd( aStru, {'U'+'L'+str(n2,1)+'G'+str(n1,1)+'FN','N',8,2 } )


		next
	next

	aadd( aStru, {'PRICEID' ,     'N'  , FLD_DOCUMENT ,   000 })

	// Final & Advance Price used ?
   aadd( aStru, {'ADV1_USED',     'L'  , 1 ,   000 })  // CHANGED to ADV1
	aadd( aStru, {'ADV2_USED',     'L'  , 1 ,   000 })
	aadd( aStru, {'ADV3_USED',     'L'  , 1 ,   000 })
	aadd( aStru, {'FIN_USED',      'L'  , 1 ,   000 })


   AED_Fields_nonStd( aStru )   // June 2010

	aadd( aStru, { UF_THE_PRICE_ID,      'N'  , FLD_DOCUMENT ,   000 })

	AssertStructure( 'Price', aStru, .t. )

return( nil )

static function BuildAccount()

	local aStru := {}

	aadd( aStru , {'NUMBER',      'N' ,   004  ,   000 })
	aadd( aStru , {'DATE',        'D' ,   008  ,   000 })
	aadd( aStru , {'TYPE',        'C' ,   FLD_ACCOUNT_TYPE  ,   000 })
	aadd( aStru , {'CLASS',       'C' ,   008  ,   000 })
	aadd( aStru , {'PRODUCT',     'C' ,  FLD_PRODUCT, 000 })
	aadd( aStru , {'PROCESS',     'C' ,  FLD_PROCESS, 000 })
	aadd( aStru , {'GRADE',       'N' ,  FLD_GRADE  , 000 })
	aadd( aStru , {'LBS',         'N' ,   008  ,   000 })
   // aadd( aStru , {'U_PRICE',     'N' ,   008  ,   003 })
   aadd( aStru , {'U_PRICE',     'N' ,   010  ,   005 })
	aadd( aStru , {'DOLLARS',     'N' ,   012  ,   002 })
   aadd( aStru , {'DESC',        'C' ,  FLD_DESC ,   000 })
	aadd( aStru , {'SERIES',      'C' ,  FLD_SERIES ,   000 })
	aadd( aStru , {'CHEQUE',      'N' ,   006  ,   000 })
	aadd( aStru , {'T_SER',       'C' ,  FLD_SERIES ,   000 })
	aadd( aStru , {'T_CHEQ',      'N' ,   006  ,   000 })
	aadd( aStru , {'YEAR',        'N' ,   004  ,   000 })                                 // See notes under Cheque above !!

	// Noted in July 2014 - this field is used as LINK only, not actually
	// as a unique Identifier.  "Sometime" this should be corrected.
	// See ShowProof() in ACCT_REG.PRG for an understanding of what
	// is actually involved here.  NOT fixing this for now (July 2014).
	aadd( aStru , {'ACCT_UNIQ',   'N' ,   FLD_DOCUMENT  ,   000 })
	aadd( aStru , {'CURRENCY',    'C' ,   001  ,   000 })

   AED_Fields_nonStd( aStru )   // June 2010

	// July 2014, still thinking, do I need to add an explicit
	//            field for recording rounding...  this a Scratch Field
	//            NOT needed:
	// aadd( aStru , {'GST_AMT',     'N' ,  11  ,   002 })  // Estimate ONLY for GSTable records...
	//     The Field GST_AMT should be eliminated....!
	//     Replaced with GST_EST to make its purpose more clear...July 23, 2014
	aadd( aStru , {'GST_EST',     'N' ,  11  ,   002 })  // Estimate ONLY for GSTable records...

	aadd( aStru , {'CHG_GST',     'L' ,   1  ,   0 })    // Jan 2019 - caught minor error in specifcation.
	aadd( aStru , {'GST_RATE',    'N' ,   9  ,   005 })
	// Was called this - changed 'NONGST_AMT',  'N' ,  12  ,   002
	aadd( aStru , {'NONGST_EST',  'N' ,  12  ,   002 })  // this is ONLY relevent for GST Records....
	                                                     // Estimate Any Way

	// Transactions will NOT necessarily have one of these, but they will for weekly and Finals AFTER
   //  Sep 2019
	aadd( aStru, {'ADV_NO',    'N' ,  1 ,   0 })  // Added 2019 - better audit Trail
	aadd( aStru, {'ADV_BAT',   'N' ,  FLD_DOCUMENT  ,   0 })  // Added 2019 - better audit Trail
	aadd( aStru, {'FIN_BAT',   'N' ,  FLD_DOCUMENT  ,   0 })  // Added 2019 - better audit Trail

	AssertStructure( 'Account', aStru, .t. )

return( nil )

static function BuildAudit()
	local aStru := {}

	aadd( aStru, {'DAY_UNIQ' ,   'N' ,   FLD_DOCUMENT  ,   000 })
	aadd( aStru, {'ACCT_UNIQ',   'N' ,   FLD_DOCUMENT  ,   000 })

   AED_Fields_nonStd( aStru )   // June 2010


	// aadd( aStru, {'ACCT_LINK',  'N' ,   FLD_DOCUMENT   ,  000 })
	// July 2014 added this but it Should be Eliminated.  See AUDACCT.DBF
	//  for records that Link Accounts to each other for Taxes and
	//  perhaps other information such as loans.  Was for GST but I
	//  decided setting up another table was better.
	// This table just Links Daily & Account Records...

	AssertStructure( 'Audit', aStru, .t. )

return( nil )

static function BuildAudAcct()
	local aStru := {}

	aadd( aStru, {'ACCT_UNIQ',   'N' ,   FLD_DOCUMENT  ,   000 })
	aadd( aStru, {'ACCT_CHILD',  'N' ,   FLD_DOCUMENT  ,   000 })
	//             1234567890

   AED_Fields_nonStd( aStru )

	// this is for GST, and shows the Relationship between
	//   different Account Records (for example a GST record in
	//   account may relate to other records in Account....

	// aadd( aStru, {'ACCT_LINK',  'N' ,   FLD_DOCUMENT   ,  000 })
	// July 2014 added this but it Should be Eliminated.  See AUDACCT.DBF
	//  for records that Link Accounts to each other for Taxes and
	//  perhaps other information such as loans.

	// So if we have something like this:
	//   Account Uniq IDs 1,2,3 (which are Berry Council Marketing deductions)
	//   relates to Account Uniq ID 4 which is the GST Tax on this....
   //	  We get:
	//           ACCT_UNIQ   LINK_TO
	//              4         1
	//              4         2
	//              4         3

	AssertStructure( 'AudAcct', aStru, .t. )

return( nil )


static function BuildImpBat()
	local aStru := {}

	aadd( aStru, {'IMP_BAT' ,    'N' ,   FLD_DOCUMENT  ,   000 })    // This is the BATCH NUMBER from Scale Export!
	                                                                 // Supposedly a batch of tickets with the  same DEPOT + IMP_BAT
																						  // will be imported in one fell swoop.  This is NOT the same
																						  // as the ->UNIQ_IMBAT.  See notes below.
	aadd( aStru, {'DATE',        'D' ,   008 ,   000 })
	aadd( aStru, {'DATA_DATE',   'D' ,   008 ,   000 })              // Do NOT Use normally
	aadd( aStru, {'NO_TRANS',    'N' ,   FLD_DOCUMENT ,   000 })
	aadd( aStru, {'LOW_ID',      'N' ,   FLD_DOCUMENT ,   000 })
	aadd( aStru, {'HIGH_ID',     'N' ,   FLD_DOCUMENT ,   000 })

   aadd( aStru, {'LOW_RECPT',   'N' ,   FLD_DOCUMENT ,   000 })
   aadd( aStru, {'HI_RECPT',    'N' ,   FLD_DOCUMENT ,   000 })

   aadd( aStru, {'LOW_DATE',    'D' ,   8 ,   000 })                // These are Important
   aadd( aStru, {'HIGH_DATE',   'D' ,  8 ,   000 })                 //

   aadd( aStru, {'VOIDS',       'N' ,  8 ,   000 })

   AED_Fields_nonStd( aStru )   // June 2010

   aadd( aStru, {'DEPOT',       'C',  1,                  0 })   // July 2013
	aadd( aStru, {'IMP_FILE',    'C', FLD_IMP_FILE_NAME ,  0 })   // Mar 2020
	aadd( aStru, {'UNIQ_IMBAT',  'N', FLD_DOCUMENT      ,  0 })   // Apr 2020 - this is the UNIQUE Identifier, assigned in Office.
	                                                              //  it is a UNIQUE identifier for records in this table.

   aadd( aStru, {'RECEIPTS',       'N' ,  8 ,   000 })           // May 2020 Valid Receipts that were posted.


   AssertStructure( 'ImpBat', aStru, .t. )

return( nil )

static function BuildPostBat()
	local aStru := {}

	aadd( aStru, {'POST_BAT' ,  'N' ,   FLD_DOCUMENT  ,   000 })
	aadd( aStru, {'DATE',       'D' ,   008 ,   000 })
	aadd( aStru, {'CUTOFF',     'D' ,   008 ,   000 })
   AED_Fields_nonStd( aStru )   // June 2010

	aadd( aStru, {'POST_TYPE',  'C' ,   005 ,   000 })    // May 2020

	AssertStructure( 'PostBat', aStru, .t. )

return( nil )

static function BuildFinBat()
	local aStru := {}

	aadd( aStru, {'FIN_BAT' ,  'N' ,   FLD_DOCUMENT  ,   000 })
	aadd( aStru, {'DATE',       'D' ,   008 ,   000 })
	aadd( aStru, {'CUTOFF',     'D' ,   008 ,   000 })
   AED_Fields_nonStd( aStru )   // June 2010

	AssertStructure( 'FinBat', aStru, .t. )

return( nil )

static function BuildPayGrp()
	local aStru := {}

	aadd( aStru, {'PAYGRP'   ,'C' ,   FLD_PAYGRP ,   000 })
	aadd( aStru, {'DESC',     'C' ,   FLD_NAME ,   000 })
	aadd( aStru, {'DEF_PRLVL','N',    FLD_STATUS, 000 } )
   AED_Fields_nonStd( aStru )   // June 2010

	AssertStructure( 'PayGrp', aStru, .t. )

return( nil )

static function BuildRptCfg(  )
   local aStru

   aStru := { ;
      {'RPT_ID',    'C',  FLD_RPT_ID ,   000 }, ;
      {'DESC',      'C',  030 ,   000 }, ;
      {'TITLE1',    'C',  030 ,   000 }, ;
      {'SORT1',     'N',  003 ,   000 }, ;
      {'SORT2',     'N',  003 ,   000 }, ;
      {'SORT3',     'N',  003 ,   000 }, ;
      {'SORT4',     'N',  003 ,   000 }, ;
      {'XTOP',      'N',  007 ,   004 }, ;
      {'YTOP',      'N',  007 ,   004 }, ;
      {'COLS',      'N',  002 ,   000 }, ;
      {'ROWS',      'N',  003 ,   000 }, ;
      {'HEIGHT',    'N',  008 ,   004 }, ;
      {'WIDTH' ,    'N',  008 ,   004 }, ;
      {'TYPEFACE',  'N',    5,      0}, ;
      {'SYMBOL',    'C',    3,      0}, ;
      {'ISFIXED',   'L',    1,      0}, ;
      {'DARKNESS',  'N',    2,      0}, ;
      {'PITCH',     'N',    2,      0} }

   AED_Fields_nonStd( aStru )   // June 2010

   aadd( aStru, {'W32FONT',      'C',   30, 0 })

	assertStructure('RptCfg', aStru, .t.  )

return( nil )

function AED_Fields_nonStd( aStru )
   //             1234567890
   aadd( aStru, {'QADD_DATE' ,   'D',    8, 0 })
   aadd( aStru, {'QADD_TIME' ,   'C',    8, 0 })
   aadd( aStru, {'QADD_OP'   ,   'C',    USER_FLD_WIDTH, 0 })
   aadd( aStru, {'QED_DATE'  ,   'D',   8, 0 })
   aadd( aStru, {'QED_TIME'  ,   'C',   8, 0 })
   aadd( aStru, {'QED_OP'    ,   'C',   USER_FLD_WIDTH, 0 })
   aadd( aStru, {'QDEL_DATE' ,   'D',    8, 0 })
   aadd( aStru, {'QDEL_TIME' ,   'C',    8, 0 })
   aadd( aStru, {'QDEL_OP'   ,   'C',    USER_FLD_WIDTH, 0 })

return( nil )


static function BuildDepot( )
   local aStru

   aStru := { ;
      {'DEPOT',      'C',  FLD_DEPOT,         000 }, ;
      {'DEPOTNAME',  'C',  FLD_DEPOT_NAME ,   000 } }

   AED_Fields_nonStd( aStru )   // July 2013

	assertStructure('Depot', aStru, .t.  )


return( nil )

static function BuildTax()
	local aStru

   aStru := { }
	aadd( aStru,  {'TAXNAME',   'C',  FLD_TAXNAME,  0 } )
   aadd( aStru, { 'EFF_DATE',  'D', 08, 0 } )          // Old rate is Before

   aadd( aStru, { 'OLD_RATE',  'N', 06, 3 } )  // Allow for 1.125 or other dumb stuff!
   aadd( aStru, { 'NEW_RATE',  'N', 06, 3 } )
   aadd( aStru, { 'NEW_ISHST', 'L', 01, 0 } )  // Is this an HST.. ?
   aadd( aStru, { 'OLD_ISHST', 'L', 01, 0 } )

   AED_Fields_nonStd( aStru )

   assertStructure( 'TAX', aStru, .t. )

return( nil )

static function BuildEvents( )
   local aStru := {}

   // Notes on things like VOID tickets
	// Set a date to Above current, create invoice batch
	// Void invoice batch

	aadd( aStru, {'EVT_TYPE',     'C',   FLD_EVENT,     000} )
	aadd( aStru, {'NOTE1',        'C',   FLD_NOTE,      000} )
	aadd( aStru, {'NOTE2',        'C',   FLD_NOTE,      000} )
	aadd( aStru, {'NOTE3',        'C',   FLD_NOTE,      000} )
	aadd( aStru, {'NOTE4',        'C',   FLD_NOTE,      000} )
	aadd( aStru, {'NOTE5',        'C',   FLD_NOTE,      000} )
	aadd( aStru, {'NOTE6',        'C',   FLD_NOTE,      000} )
	aadd( aStru, {'NOTE7',        'C',   FLD_NOTE,      000} )
	aadd( aStru, {'NOTE8',        'C',   FLD_NOTE,      000} )
	aadd( aStru, {'COMP_NAME',    'C',    35,     000} )
	aadd( aStru, {'WIN_USER',     'C',    16,     000} )
	aadd( aStru, {'SESSIONID',    'C',    16,     000} )
	aadd( aStru, {'PRG',          'C',    16,     000} )           // Widened

   AED_Fields_nonStd( aStru )  // lib

	aadd( aStru, {'EVENT_ID',     'N',   FLD_DOCUMENT,     000} )

   AssertStructure( 'Events', aStru, .t. )   //lib

return( nil )

static function BuildCounterIDs()
   local aStru

	aStru := { ;
         { UF_THE_DAY_UNIQ,    'N', FLD_DOCUMENT,  0},  ;           /* Daily */
         { UF_THE_DAYAUD_ID,   'N', FLD_DOCUMENT,  0},  ;           /* Daily Audit File */
         { UF_THE_UNIQ_IMBAT,  'N', FLD_DOCUMENT,  0},  ;           /* Import File */
         { UF_THE_ACCT_UNIQ,   'N', FLD_DOCUMENT,  0},  ;           /* This is NOT unique PER record ! */
         { UF_THE_POST_BAT,    'N', FLD_DOCUMENT,  0},  ;           /* Post Advance Payment Batches */
         { UF_THE_FIN_BAT,     'N', FLD_DOCUMENT,  0},  ;           /* Final Batches */
         { UF_THE_EVENT_ID,    'N', FLD_DOCUMENT,  0},  ;           /* Event */
			{ UF_THE_PRICE_ID,    'N', FLD_DOCUMENT,  0}        }      /* Price ID records */

   AED_Fields_nonStd( aStru )   // June 2010

   AssertStructure( 'CounterIDs', aStru, .t. )             // NO INDEXES on this puppy

return( nil )


