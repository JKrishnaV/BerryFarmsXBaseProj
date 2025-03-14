// -----------------------------------------------------------------------------
//   Application: cisBerry Payment System
//     File Name: MYSYS.PRG
//        Author: Bill Hepler
//  June 2, 2015 - added stuff for Variety
//  Jul 27, 2017 - XBase 200 stuff fixed
//  Apr 19, 2019 - Some settings added for Statement Printing etc.
//  May 20, 2021 - Settings for a Report out Weekly and Final
//  May 14, 2024 - For Quick Edit of Grower Contract

//  Copyright: (c) 1996, etc 2014, 2015, 2017, 2019, 2021, 2024  by Bill Hepler
// -----------------------------------------------------------------------------

#include 'BerryPay.ch'
#include 'bsgstd.ch'
#include 'field.ch'
#include 'sysvalue.ch'

function InitMySysValue()
	local aSys

	aSys := {}

	// Pricing
   aadd( aSys, { SYS_IMPORT_ROUND_NET_METHOD, GRP_PRICING, ;
      'U', '!', {|x| x == 'U' .or. x == 'S'  }, ;
      'Round on Import U=Up  S=Std up on .5 or more' })

	aadd( aSys, { SYS_ALLOW_CANADIAN_DOLLARS, GRP_PRICING, ;
		.t., 'Y', {|| .t.  }, ;
		'Allow Canadian $ pricing' })

	aadd( aSys, { SYS_ALLOW_US_DOLLARS , GRP_PRICING, ;
		.f., 'Y', {|| .t.  }, ;
		'Allow US $ pricing' })

	aadd( aSys, { SYS_UNITS_OF_WEIGHT , GRP_PRICING, ;
		'lb', 'XX', {|x| x== 'lb' .or. x=='kg' }, ;
		'Units of Weight: lb or kg' })

   // this is new for WestBerry...
   aadd( aSys, { SYS_SET_ADVANCES_BY_PROCESS_ONLY, GRP_PRICING, ;
       .f., 'Y', {|| .t. }, ;
       'Advance prices MAY be set ONLY by process'})

   // Aug 2008
   aadd( aSys, { SYS_DOCKAGE_ACTION, GRP_PRICING, ;
      'W', '!', {|x| x == DOCKAGE_ACTION_WARN .or.;
        x == DOCKAGE_ACTION_NO_ACTION .or. x == DOCKAGE_ACTION_CHANGE  }, ;
      'Dockage Action - Change,Warn,No action' })

	// May 2021
   aadd( aSys, { SYS_QUICK_CHECK_FOR_ZERO_KEY , GRP_PRICING, ;
      SQCFZ_NOT_AUTOMATIC, '9', {|x| x == SQCFZ_NOT_AUTOMATIC .or.;
        x == SQCFZ_AUTOMATIC_FRESH .or. x == SQCFZ_AUTOMATIC_WHATEVER  }, ;
      'ZERO Price Receipt Chk 0=No,1=Fresh,2=from User IF' })

	aadd( aSys, { SYS_CURRENT_YEAR,  GRP_FISCAL_YEAR, ;
    2007 ,   '9999', {|x| x> 1980  },   ;
    'Current production year you are working in'   })

	aadd( aSys,  { SYS_CURRENT_SEASON_START, GRP_FISCAL_YEAR,  ;
      ctod('05/30/2007'), '@D', {|| .t. }, ;
	  'The Start of the Current Season'  })

	aadd( aSys, { SYS_CURRENT_SEASON_END, GRP_FISCAL_YEAR, ;
    ctod('10/31/2007'), '@D', {|| .t. }, ;
	  'The End of the Current Season'  }   )

	// this added May 2020 to deal with odd problem.  Usually we should just have ONE crop year in
	// a dataset.  Originally system was designed for 1, but customers have for past 10 or 15 years
	// just put one Crop year in one data set.  Often because of changes to Growers, Products and
	// containers.

	aadd( aSys, { SYS_CURRENT_HOWMANY_YEARS, GRP_FISCAL_YEAR, ;
		1, '9', { || .t. }, ;
		'How many Crop Years in Data-usually 1!'}  )

	aadd( aSys, { SYS_CDN_CHEQUE_SERIES, GRP_FISCAL_YEAR, ;
    '94', '!!', {|x| substr(x,1,1)<>'U' .and. x <> EFT_CHEQUE_SERIES }, ;
  'Canadian Cheques Series (ensure CheqNo unique)' } )

	aadd( aSys, { SYS_US_CHEQUE_SERIES, GRP_FISCAL_YEAR, ;
    'US', '!!', {|x| substr(x,1,1)=='U' .and. x <> EFT_CHEQUE_SERIES }, ;
  'U.S. Cheques Series (ensure CheqNo unique)' } )

	// Misc.

	//   this one is because we can have up to 20 container types
	aadd( aSys, { SYS_LABEL_2_CONTAINER_RPT , GRP_MISC, ;
		.t., 'Y', { || .t. }, ;
		'Have 2 Container Reports usually?' })

	aadd( aSys, { SYS_DISK_CHECK_ON_FLOPPY , GRP_MISC, ;
		.t., 'Y', { || .t. }, ;
		'Check Write Status of Floppy Drives' })

	aadd( aSys, { SYS_CHEQUE_PART_THREE, GRP_MISC, ;
	.t., 'Y', {||.t.}, ;
  'Print a 3rd Part on Cheque for your records'} )

	aadd( aSys, { SYS_DEFAULT_PREMIUM_MSG, GRP_MISC, ;
	.f., 'Y', {||.t.}, ;
  'Default for Show Premium Msg on Wkly Statemnt'} )

	aadd( aSys, { SYS_DEFAULT_NO_STATEMENT_COPIES, GRP_MISC, ;
	2, '9', {|x| x>=1}, ;
  'Default for No. Copies of Statements to PRN'} )

	aadd( aSys, { SYS_LABEL_LENGTH, GRP_MISC, ;
		8, '99', { |x| x>=4 }, ;
		'Length in lines for LABEL'})

	aadd( aSys, { SYS_LABEL_INDENT, GRP_MISC, ;
		2, '99', { |x| x>=0 }, ;
		'Left Indent for LABEL'})

	aadd( aSys, { SYS_TRY_ROBOCOPY_FOR_QBU, GRP_BACKUP, ;
		.t., 'Y', { || .t. }, ;
		'Try to use RoboCopy for Quick BU (N=xCopy)'})

	aadd( aSys, { SYS_FOLDER_TO_BACKUP_INTO  , GRP_BACKUP, ;
	   'C:\MYBACKUP\                      ', ;
      '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!', ;
       {|x| ValidDirThing(x) }, ;
		'Target (default) Backup Folder Quick BU'})

	aadd( aSys, { SYS_FOLDER_BACKUP_BU1_2, GRP_BACKUP, ;
		.t., 'Y', { || .t. }, ;
		'Try to backup to C:\BU1 and C:\BU2'})


   aadd( aSys, { SYS_ASK_TO_PRINT_ALIGNMENT_COPY_OF_CHEQUE , GRP_CHEQUE, ;
      .f.,'Y', {|x| .t. }, ;
      'Always ask to print an alignment copy of Chq?' })

   // CHeques - these values set june 99, rev July 2007
   //              Revised July 2009

	aadd( aSys, { SYS_CHEQUE_FORMAT    , GRP_CHEQUE, ;
      2,'9', {|x| x >=1 .and.  x<=5 }, ;
      'ChqFmt 1=bcBlu 2=SoAld 3=TrpCrow 4=None 5=UDF' })

   // Cheques - Dollars as Numbers or in Writing
   aadd( aSys, { SYS_CHEQUE_DOLLAR_FORMAT    , GRP_CHEQUE, ;
      1,'9', {|x| x==1 .or. x==2  }, ;
      'ChqFmt<=4, $ Format 1=Numbers 2=Words' })

	aadd( aSys, { SYS_CHEQUE_1ST_LINE  , GRP_CHEQUE, ;
		3, '9', { || .t. }, ;
      'ChqFmt<=4, 1st Line of check (top indent)' })

	aadd( aSys, { SYS_CHEQUE_LEFT_INDENT , GRP_CHEQUE, ;
		0, '9', { || .t. }, ;
      'ChqFmt<=4,Left margin indent'})

	aadd( aSys, { SYS_CHEQUE_FORM_LENGTH, GRP_CHEQUE, ;
      42,'99', {|x| x>9 .and. x<99  }, ;
      'ChqFmt<=4,Len of chq incl statement' })

	aadd( aSys, { SYS_CHEQUE_ADVICE_STARTS, GRP_CHEQUE, ;
      24,'99', {|x| x>9 .and. x<99  }, ;
      'ChFmt<=4,Line to start printing chq advice' })

   aadd( aSys, { SYS_CHEQUE_NIFTY_ADVICE_NO_LINES, GRP_CHEQUE, ;
      24,'99', {|x| x>9 .and. x<99  }, ;
      'ChFmt 5, Max# Lines Printed in Advice Section' })

   aadd( aSys, { SYS_CHEQUE_NIFTY_ADVICE1_STARTS, GRP_CHEQUE, ;
      4,'99.99', {|x| x>=0 }, ;
      'ChFmt 5, Inches fr top where Advice#1 Prints' })
   aadd( aSys, { SYS_CHEQUE_NIFTY_ADVICE2_STARTS, GRP_CHEQUE, ;
      8,'99.99', {|x| x>=0 }, ;
      'ChFmt 5, Inches fr top where Advice#2 Prints' })

   aadd( aSys, { SYS_CHEQUE_NIFTY_DATE_FORMAT, GRP_CHEQUE, ;
      1,'9', {|x| x>=1 .and. x<=3 }, ;
      'ChFmt 5, DateFmt 1=YYYYMMDD 2=DDMMYYYY 3=MMDDYYYY' })
   aadd( aSys, { SYS_CHEQUE_NIFTY_DATE_DISTANCE, GRP_CHEQUE, ;
      0.2917,'9.9999', {|x| x>=0 }, ;
      'ChFmt 5, Date Character Distance 0.1667=1/6 inch' })
   aadd( aSys, { SYS_CHEQUE_NIFTY_DOLLAR_FORMAT, GRP_CHEQUE, ;
      1,'9', {|x| x>=1 .and. x<=3 }, ;
      'ChFmt 5, $amt:1=$ 1,234.56  2=1,234.56 3=1234.56' })

   aadd( aSys, { SYS_CHEQUE_NIFTY_AMT_IN_WORD_LEN, GRP_CHEQUE, ;
      65,'99', {|x| x>=45 .and. x<=99 }, ;
      'ChFmt 5, Width of Cheque Amt in Words' })


	// July 26/99 ?
	aadd( aSys, { SYS_FORCE_CHQ_REC_2_BALANCE, GRP_CHEQUE, ;
		.f., 'Y', { || .t. }, ;
		'Force the Cheque Reconciliation to Balance?'})

	// Nov 2022
	aadd( aSys, { SYS_CHEQUE_SUGGEST_LOOK_AT_STATEMENT, GRP_CHEQUE, ;
		.t., 'Y', { || .t. }, ;
		'If Chq pays more than fits on Stub-Look to State'})

	aadd( aSys, { SYS_ACTUAL_CLIENT_NAME, GRP_COMPANY, ;
		'South Alder Farms Ltd.          ', ;
		'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', ;
		 {|| .t.   }, ;
		'Your Co. Name' })

	aadd( aSys, { SYS_ACTUAL_ADDRESS1   , GRP_COMPANY, ;
		'2052 - 272nd Street             ', ;
		'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', ;
		 {|| .t.   }, ;
		'Your Address Line 1' })

	aadd( aSys, { SYS_ACTUAL_ADDRESS2   , GRP_COMPANY, ;
		'Aldergrove, BC                  ', ;
		'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', ;
		 {|| .t.   }, ;
		'Your Address Line 2' })

	aadd( aSys, { SYS_ACTUAL_ADDRESS3   , GRP_COMPANY, ;
		'V4W 2R1                         ', ;
		'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', ;
		 {|| .t.   }, ;
		'Your Address Line 3' })
   aadd( aSys, { SYS_ACTUAL_PHONE   , GRP_COMPANY, ;
      'Tel:                            ', ;
		'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', ;
		 {|| .t.   }, ;
      'Your Telephone Number to Print on Documents' })

	// Group Reports
	aadd( aSys, { SYS_PRODUCTION_FORMAT_1 , GRP_REPORTS, ;
		'Production Report Format No 1   ', ;
		'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', ;
		 {|| .t. }, ;
		'Production Report Format #1 Title' })

	aadd( aSys, { SYS_PRODUCTION_FORMAT_2 , GRP_REPORTS, ;
		'Production Report Format No 2   ', ;
		'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', ;
		 {|| .t. }, ;
		'Production Report Format #2 Title' })

	// these 2 added April 2019
   aadd( aSys, { SYS_WEEK_STATEMENT_DEFAULT_FORMAT , GRP_REPORTS, ;
      WEEK_STATEMENT_FORMAT_2_REV_2019, ;
      '9', ;
       {| x | WeekStatInfo( x ) }, ;
      'Default Format for Weekly Statemnt, Choose from 4' })

   aadd( aSys, { SYS_CROPYEAR_STATEMENT_DEFAULT_FORMAT , GRP_REPORTS, ;
      CROPYEAR_STATEMENT_FORMAT_2_REV_2014, ;
      '9', ;
       {| x | CropYearInfo( x ) }, ;
      'Default Crop Year-Yr End Statemnt, Choose from 3' })

	// older
   aadd( aSys, { SYS_WEEK_STATEMENT_FORMAT , GRP_REPORTS, ;
      WEEK_STATE_FMT_ORIGINAL, ;
      '!', ;
       {| x | x==WEEK_STATE_FMT_ORIGINAL .or. x== WEEK_STATE_FMT_KEYED_PRICE }, ;
      'Weekly Statemnt Fmt: O=Original,K=Keyed Price' })
   aadd( aSys, { SYS_WEEK_STATEMENT_SUMMARY_FP, GRP_REPORTS, ;
      .t., ;
      'Y', ;
       {| | .t. }, ;
      'Defa:Show Summary of Final Price on WklyStatment' })

   // July 2013
   // 'GST at 5% is included in BC Blueberry Levy       ', ;
   //           1         2         3         4         5
   //  123456789 123456789 123456789 123456789 123456789 123456789

   aadd( aSys, { SYS_DEFAULT_ADV_STATEMENT_LINE1 , GRP_REPORTS, ;
      space( FLD_STATEMENT_NOTES), ;
      replicate('X',FLD_STATEMENT_NOTES), ;
		 {|| .t. }, ;
      'Default Line 1 for Advance Statements' })

   aadd( aSys, { SYS_DEFAULT_ADV_STATEMENT_LINE2 , GRP_REPORTS, ;
      space( FLD_STATEMENT_NOTES), ;
      replicate('X',FLD_STATEMENT_NOTES), ;
		 {|| .t. }, ;
      'Default Line 2 for Advance Statements' })

   aadd( aSys, { SYS_DEFAULT_FINAL_STATEMENT_LINE1 , GRP_REPORTS, ;
      space( FLD_STATEMENT_NOTES), ;
      replicate('X',FLD_STATEMENT_NOTES), ;
		 {|| .t. }, ;
      'Default Line 1 for Crop Year (Final) Statements' })

   aadd( aSys, { SYS_DEFAULT_FINAL_STATEMENT_LINE2 , GRP_REPORTS, ;
      space( FLD_STATEMENT_NOTES), ;
      replicate('X',FLD_STATEMENT_NOTES), ;
		 {|| .t. }, ;
      'Default Line 2 for Crop Year (Final) Statements' })

	// Dec 2014
   aadd( aSys, { SYS_STATEMENT_LOGO , GRP_REPORTS, ;
       space(FLD_FILE_AND_PATH), ;
       replicate('X', FLD_FILE_AND_PATH), ;
		 {|| .t. }, ;
      'Folder+File Name for your Company logo, if using' })

	aadd( aSys, { SYS_STATEMENT_LOGO_TOP , GRP_REPORTS, ;
      0.00, ;
      '99.99', ;
		 {|| .t. }, ;
      'Top of Logo Position on Statements in Inches' })

	aadd( aSys, { SYS_STATEMENT_LOGO_LEFT , GRP_REPORTS, ;
      0.00, ;
      '99.99', ;
		 {|| .t. }, ;
      'Left Position of Logo on Statements in Inches' })

	aadd( aSys, { SYS_STATEMENT_LOGO_WIDTH , GRP_REPORTS, ;
      0.00, ;
      '99.999', ;
		 {|| .t. }, ;
      'Width of Logo on Statements in Inches' })

	aadd( aSys, { SYS_STATEMENT_YOUR_NAME_ADDRESS_TOP , GRP_REPORTS, ;
      0.00, ;
      '99.99', ;
		 {|| .t. }, ;
      'Top of Your Name & Address on Statements in Inches' })
	aadd( aSys, { SYS_STATEMENT_YOUR_NAME_ADDRESS_LEFT , GRP_REPORTS, ;
      0.00, ;
      '99.99', ;
		 {|| .t. }, ;
      'Left Pos of your Name & Addr on Statements Inches' })


   aadd( aSys, { SYS_IMPORT_DIRECTORY , GRP_IMPORT, ;
      'A:\                                     ', ;
      'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', ;
       {|x| ValidDirThing(x) }, ;
      'Usual Import Directory, e.g. G:\IMPDIR\' })

   aadd( aSys, { SYS_IMPORT_FORMAT , GRP_IMPORT, ;
      1, ;
      '9', ;
       {|x| ImpoFormat(x) }, ;
      'Import Type 1=DOS, 2=Win NO PRICE, 3=w/ Price' })

   aadd( aSys, { SYS_IMPORT_FROM_FIELD_NAME , GRP_IMPORT, ;
      space(10), ;
      'XXXXXXXXXX', ;
       {|x| FromFieldName(x) }, ;
      'The Name of FROM_FIELD data in Import File' })

   aadd( aSys, { SYS_IMPORT_PREFIX , GRP_IMPORT, ;
      'S', ;
      '!', ;
       {|x| !empty(x) }, ;
      'Import Prefix for Import Style 2 or 3' })

   aadd( aSys, { SYS_DEFAULT_VARIETY , GRP_IMPORT, ;
      space( FLD_VARIETY ), ;
      replicate('!',FLD_VARIETY), ;
       {| x | ReceiptVarietyHelp( x ) }, ;
      'Basic Default for VARIETY-set when tcket imported' })


   aadd( aSys, { SYS_PRODUCT_CATEGORY_1 , GRP_PRODUCT_CATEGORIES, ;
      'Blueberry ', ;
      'XXXXXXXXXX', ;
       {|x| !empty(x) }, ;
      'Product Category #1 for Columnar Reports' })

   aadd( aSys, { SYS_PRODUCT_CATEGORY_2 , GRP_PRODUCT_CATEGORIES, ;
      'Raspberry ', ;
      'XXXXXXXXXX', ;
       {|x| !empty(x) }, ;
      'Product Category #2 for Columnar Reports' })

   aadd( aSys, { SYS_PRODUCT_CATEGORY_3 , GRP_PRODUCT_CATEGORIES, ;
      'Blackberry', ;
      'XXXXXXXXXX', ;
       {|x| !empty(x) }, ;
      'Product Category #3 for Columnar Reports' })

   aadd( aSys, { SYS_PRODUCT_CATEGORY_4 , GRP_PRODUCT_CATEGORIES, ;
      'Strawberry', ;
      'XXXXXXXXXX', ;
       {|x| !empty(x) }, ;
      'Product Category #4 for Columnar Reports' })

   aadd( aSys, { SYS_PRODUCT_CATEGORY_5 , GRP_PRODUCT_CATEGORIES, ;
      'Gooseberry', ;
      'XXXXXXXXXX', ;
       {|x| !empty(x) }, ;
      'Product Category #5 for Columnar Reports' })

   aadd( aSys, { SYS_PRODUCT_CATEGORY_6 , GRP_PRODUCT_CATEGORIES, ;
      'Other     ', ;
      'XXXXXXXXXX', ;
       {|x| !empty(x) }, ;
      'Product Category #6 for Columnar Reports' })

   aadd( aSys, { SYS_USE_PROCESS_GRADE_NAMES  , GRP_PRODUCT_CATEGORIES, ;
      .f. , ;
      'Y', ;
       {|x|  .t. }, ;
      'Use Product Grade Names (3 short names/process)' })


   aadd( aSys, { SYS_ARCHIVE_DATA_YEAR , GRP_MISC, ;
      '    ', 'XXXX', { || .t. }, ;
      'Leave BLANK for current year, fill for archive' })

   aadd( aSys, { SYS_SHOW_PART_DATA_DIR  , GRP_MISC, ;
      .t., 'Y', { || .t. }, ;
      'Show last part of Data Directory on Menu' })

   aadd( aSys, { SYS_OWN_DIRECTORY, GRP_MISC, ;
      padr('C:\STATION', FLD_STD_DIRECTORY_WIDTH),   ;
      '@! A:\' +replicate('X', FLD_STD_DIRECTORY_WIDTH-3), ;
      {|x| right(alltrim(x),1)=='\'}, ;
      'Path for EACH Stations private files'} )


   aadd( aSys, ;
      { SYS_GENERALLY_SWITCH_TO_LANDSCAPE, GRP_MISC, ;
		  105, '999', { | x |  Sw2Land( x )  }, ;
		  'Switch many reports to Landscape if > this width' } )

   aadd( aSys, { SYS_DEFAULT_RPT_LINE_HEIGHT, GRP_MISC, ;
      0.0, ;
      '9.9', ;
       { | x | LineHeightNote( x ) }, ;
      'Default Line Height for Rpts(in LPI), 0.0=default' })

   // For Jass in May 2024
   aadd( aSys, { SYS_QUIK_ED_GROW_CONTRACT_CERTIFY_FLD , GRP_MISC, ;
      SQEDG_QUIK_ED_GCC_FIELD_STD, ;
      '9', ;
       { || .t. }, ;
      'QuikEd of Grow Fld 0=n/a, 1=Contract, 2=Certify' })

return( aSys )

function sysGroups()
	local aRay := {}

   aadd(aRay,{ GRP_BACKUP,       'Backups   '})   // Aug 2012
	aadd(aRay,{ GRP_CHEQUE   ,    'Cheques   '})
	aadd(aRay,{ GRP_FISCAL_YEAR,  'Fiscal Pd '})
	aadd(aRay,{ GRP_MISC,         'Misc.     '})
	aadd(aRay,{ GRP_PRICING,      'Pricing   '})
	aadd(aRay,{ GRP_COMPANY,      'Company   '})
	aadd(aRay,{ GRP_REPORTS,      'Reports   '})

   aadd(aRay,{ GRP_IMPORT,       'Import    '})
   aadd(aRay,{ GRP_PRODUCT_CATEGORIES, ;
                                 'Categories'})

return( aRay )

static function ImpoFormat(x)
   local lReturn := .t.
   local aRay

   aRay := { 'You may choose different formats to import in', ;
             ' 1 = used by older Pacific DOS scale program', ;
             ' 2 = used by the PacWeigh Berry Program.  If using', ;
             '     the PacWeigh Berry Program, set STATION SETTINGS', ;
             '     EXPORT, as follows:', ;
             '     -Container Count 6 or more', ;
             '     -Export File Format = 2 South Alder', ;
             '     -FileName Extension = CSV', ;
             '     -FileName Prefix to ONE LETTER (set the', ;
             '      filename prefix here to the same)', ;
             '     -Include VOIDS to YES', ;
             ' 3 = PacWeigh Berry Include Prices!' }

   if x==1 .or. x==2 .or. x==3
      waitInfo( aRay )
   else
      aadd( aRay,'')
      aadd( aRay,'-- PLEASE CHOOSE 1,2 or 3 !!!  --')
      waitHand(aRay)

      lReturn := .f.
   endif

return( lReturn )

static function FromFieldName(x)
   local lReturn := .t.
   local cVar
   local aRay

   cVar := alltrim( var2char( x ))

   if ',' $ cVar .or. '|' $ cVar .or. '$' $ cVar .or. '"' $ cVar .or. "'" $ cVar
      cVar += '  ** InValid Name-No Commas, Quotes etc **'
      lReturn := .f.
   endif

   aRay := { 'Leave this blank if you are not importing the FROM_FIELD', ;
             'information from the Scale Program.  If you', ;
             'plan to import this information your Scale Program ', ;
             'must be set up to record it and export it!  Then you', ;
             'must enter the Name of Field in the Export file.', ;
             'This name is NOT case sensitive.  Usual names would be', ;
             '   FIELD ID   or  FROM_FIELD', ;
             ' '+iif( empty( cVar ),'No field selected','Name='+ cVar), ;
             'This data can be reported on or viewed on the ticket.' }

   waitInfo( aRay )

return( lReturn )

static function Sw2Land( nVal )
	local lReturn := .t.

	if valType( nVal ) == 'N'
		lReturn := .f.
		if nVal == 0 .or. (nVal >= 90 .and. nVal <= 999 )
			lReturn := .t.
		endif
	endif

	WinArrayVu( {  ;
	  'As of March 2011, you may set to make many of the reports which print', ;
	  'in this system print in Landscape Mode (wide paper!) if the report is', ;
	  'wide instead of printing in very small print.  This setting only applies', ;
	  'to printers which are using Windows drivers.','', ;
	  'We suggest you set this value to somewhere between 100 and 120 characters', ;
	  'wide.  Just so you know what the system does automatically:', ;
	  '  10 Characters/inch - default printing width.', ;
	  '  12 Characters/inch - prints at this width if the reports are between', ;
	  '                       80 - 96 characters wide.  Most people find this', ;
	  '                       fairly easy to read.', ;
	  'The default value for this is 103.','',  ;
	  'If you set the Value to 0 or 999 it will be ignored'})

return( lReturn )


static function LineHeightNote( x )
	local lReturn := .t.
	local aRay := {}

	aadd( aRay, 'You may set the Default Line Height for Reports to a range')
	aadd( aRay, 'from 3 Lines Per Inch to 12 Lines Per Inch.  If you leave')
	aadd( aRay, 'the value at 0.0 the report itself will cleverly figure out' )
	aadd( aRay, 'what height to make the lines of the body of the report.' )
	aadd( aRay, 'The default of 0.0 will ensure that line heights are set' )
	aadd( aRay, 'to the smallest height possible.  This puts the most lines')
	aadd( aRay, 'on a single page.')
	aadd( aRay, '')
	aadd( aRay, 'In any case, the Heading Lines will print at single space.')
	aadd( aRay, 'Most people find 6 Lines / Inch pretty readable.')

	if x < 3 .or. x > 12
		aadd( aRay,'')
		aadd( aRay,'You must set this value to between 3 to 12')
		lReturn := .f.
	endif

	WaitInfo( aRay )

return( lReturn )

function ReceiptVarietyHelp( x )
	local aRay := { ;
	  'As of June 2015, you may set a VARIETY of Berry which can be used for reporting...', ;
	  'The VARIETY is set by the System when Weigh Slips are imported and you may key', ;
	  'in the VARIETY when you edit a Ticket as well.','', ;
	  'The way we set VARIETY (on import of tickets) is:', ;
	  ' If PROCESS imported has extra characters these are used to set VARIETY', ;
	  '  otherwise:', ;
	  '   if PRODUCT imported has extra characters we use those to set VARIETY.', ;
	  '    otherwise:', ;
	  '     if variety is still blank, we use the Default VARIETY attached to the PRODUCT.', ;
	  '--->if all that is still blank, we use the Basic Default VARIETY in System Settings.', ;
	  '' }

	if valType( x) == 'C'
		if !empty( x )
			aadd( aRay, ' Variety default='+x )
		endif
	endif

	WinArrayVu( aRay, 'Info on VARIETIES' )

return( .t. )

static function WeekStatInfo( x )      // April 2019
	local lReturn  := .f.
	local aRay

	aRay :=       { 'The Advance Statements (also called Weekly Statements) will accompany the' ,                 ;
	                'the cheques you issue for the regular advance payments.  There are several',                 ;
						 'formats available - you can run any of these and see how they work for you.',                ;
						 'You must then select one of these formats as Your Standard format.  You may',                ;
						 'change the standard format at any time and you may run the non-standard',                    ;
						 'formats as well if you wish.',                                                               ;
						 '',                                                                                           ;
						 'The choices are:',                                                                           ;
						 ' 1 - Old Weekly statement dating from the early 1990s',                                      ;
						 '    '+StatementDesc( GRO_STATEMENT_FOR_WEEKLY, WEEK_STATEMENT_FORMAT_1_OLD ),                ;
						 ' 2 - Old format revised to include more information about Grades',                           ;
						 '     This revsion was done in 2019',                                                         ;
						 '    '+StatementDesc( GRO_STATEMENT_FOR_WEEKLY, WEEK_STATEMENT_FORMAT_1_REV_2019 ),           ;
						 ' 3 - The 2014 Revised format statement.  Last revised in 2018.' ,                            ;
						 '    '+StatementDesc( GRO_STATEMENT_FOR_WEEKLY, WEEK_STATEMENT_FORMAT_2_REV_2018 ),           ;
						 ' 4 - The 2014 Revised format statement.  Last revised in 2019 to show ' ,                    ;
						 '     additional info about grades and a summary of payment amounts',                         ;
						 '    '+StatementDesc( GRO_STATEMENT_FOR_WEEKLY, WEEK_STATEMENT_FORMAT_2_REV_2018 ),           ;
						 '',                                                                                           ;
						 'You have chosen '+var2char( x )  }

	if valType( x) == 'N'
		if x >= WEEK_STATEMENT_FORMAT_1_OLD       .and. ;
			x <= WEEK_STATEMENT_FORMAT_2_REV_2019

			lReturn := .t.
		else
			aadd( aRay,'This is INVALID choice' )
		endif
	else
		aadd( aRay,'This is INVALID choice - not numeric !' )
	endif

	WinArrayVu( aRay, 'Advance (Weekly) Statements' )

return( lReturn )


static function CropYearInfo( x )               // April 2019
	local lReturn  := .f.
	local aRay

	aRay :=       { 'The Year End Statements (also called Crop Year Statements) are usually sent'          , ;
	                'out after the Crop has been fully paid out, or at times to show the growers'          , ;
						 'a full account of what cheques they have been issued.'                                , ;
						 'You must then select one of these formats as Your Standard format.  You may'          , ;
						 'change the standard format at any time and you may run the non-standard'              , ;
						 'formats as well if you wish.'                                                         , ;
						 '',                                                                                      ;
						 'The choices are:',                                                                      ;
						 ' 1 - Old Crop Year statement dating from the late 1990s',                               ;
						 '    '+StatementDesc( GRO_STATEMENT_FOR_CROPYEAR, CROPYEAR_STATEMENT_FORMAT_1_OLD ),     ;
						 ' 2 - 2014 Crop Yearformat as last revised in 2018',                                     ;
						 '    '+StatementDesc( GRO_STATEMENT_FOR_CROPYEAR,CROPYEAR_STATEMENT_FORMAT_2_REV_2014),  ;
						 ' 3 - The 2014 Revised Short format statement with 2019 enhancements.  This was',        ;
						 '     also revised in 2019 to show additional information about Grades and an',          ;
						 '     additional overall summary at the end of the report.  It does NOT include',        ;
						 '     the summary at the top of the report !' ,                                          ;
						 '    '+StatementDesc( GRO_STATEMENT_FOR_CROPYEAR, ;
                                                              CROPYEAR_STATEMENT_FORMAT_2_SHORT_REV_2019 ), ;
						 ' 4 - The 2014 Revised Short format statement with 2019 enhancements.  This was',        ;
						 '     also revised in 2019 to show additional information about Grades and an',          ;
						 '     additional overall summary at the end of the report.  It DOES include the',        ;
						 '     summary at the top of the report !' ,                                              ;
						 '    '+StatementDesc( GRO_STATEMENT_FOR_CROPYEAR, ;
                                                               CROPYEAR_STATEMENT_FORMAT_2_LONG_REV_2019 ), ;
						 'You have chosen '+var2char( x )  }



	if valType( x) == 'N'
		if x >= CROPYEAR_STATEMENT_FORMAT_1_OLD       .and. ;
			x <= CROPYEAR_STATEMENT_FORMAT_2_LONG_REV_2019

			lReturn := .t.
		else
			aadd( aRay,'This is INVALID choice' )
		endif
	else
			aadd( aRay,'This is INVALID choice - not numeric !' )
	endif

	WinArrayVu( aRay , 'Crop Year (final) Statement Format')

return( lReturn )

