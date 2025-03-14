//--------------------------------------------------------------------------
//    File Name: FIELD.CH
//  Description: Data Field Size Constants.
//
//         **** Warning see RECEIPT.CH ********************************
//  June 2, 2015       We add more fields
//  Apr 12, 2019       Stuff from Process Grade Names
//
//       Author: Bill Hepler
// Date created: 05-08-99
// Copyright: 1999,2014,2015, 2019 by Bill Hepler & Crafted Industrial Software Ltd.
//--------------------------------------------------------------------------

// Noted in June 2015 - these next fields are used for the Import
//  interface - (DailyR.prg) do NOT change them lightly!!!

#define   FLD_PRODUCT          2
#define   FLD_PRODDESC        15
#define   FLD_SHORTDESC        4
#define   FLD_LONG_NU_PRODUCT  8

#define   FLD_GRADE              1    // See DailyR.prg for import

#define   FLD_PROCESS            2    // See DailyR.prg for import
#define   FLD_GRADE_POSITION     3    // See DailyR.prg for import !!
#define   FLD_PROCDESC          19
#define   FLD_LONG_NU_PROCESS    8
#define   FLD_PROCESS_GRADE_NAME 5

#define   FLD_VARIETY            8
#define   FLD_VARIETY_DESC      19


#define   FLD_CONTAINER        2
#define   FLD_CONTAINER_DESC  30
#define   FLD_CONTAINER_SHORT  6

// --------------------------------------------------------------------

#define    FLD_SERIES           2
#define    FLD_CHEQUE           6

#define    FLD_GROWER           4  // these 2 are the same
#define    FLD_NUMBER           4

#define    FLD_RECPT            6
#define    FLD_DEPOT            1
#define    FLD_DEPOT_NAME      12

#define    FLD_AD_LINK        8  // serves as a LINK from Account to Daily

#define    FLD_LBS            8
#define    FLD_U_PRICE_LEN    8
#define    FLD_U_PRICE        8,2

#define    FLD_DED_CLASS      8
#define    FLD_ACCT_TYPE      3

#define    FLD_NAME          30

#define    FLD_DOCUMENT       8


#define    FLD_STATUS         1

#define    FLD_PAYGRP         1

#define    FLD_DESC          30

#define    FLD_PRODUCT_CATEGORY     1   // Numeric, July 2008

#define    FLD_CHQ_FORMAT_ID        11

#define     FLD_RPT_ID               8

#define     FLD_TAXNAME              6  // Unique ID

#define     FLD_TICKET_NOTE      50

#define     FLD_FILE_AND_PATH    60

#define    FLD_ACCOUNT_TYPE       3   // see Account.ch

#define    FLD_STATEMENT_NOTES   55

#define    FLD_CONTAINER_QTY      5   // was 4, noted Aug 2019 - this Needs to be Widened!

#define   FLD_EVENT               16   // Dec 2019
#define   FLD_NOTE                55   // Dec 2019

#define  FLD_FROM_FIELD           10  //  Mar 2020
#define  FLD_IMP_FILE_NAME        50  //  Mar 2020 - includes path

#define  FLD_CONTAINER_ERRS       10  //  May 2020 - container errors if any on IMPORT for this ticket

#define  FLD_CERTIFIED            15  //  Set up May 2020 - this is the OLD length from 2010 or so.
