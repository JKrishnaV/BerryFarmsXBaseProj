// Valid.ch
// February 24, 1994
//  April 2019




// Validity Checks - see Valid.prg
#define VT_NO_MESSAGE	 1
#define VT_MESSAGE	    2
#define VT_BROWSE        3

#define VT_BLANKS_OK    10  // if GREATER Blank is OK

#define VT_BLANK_OK_NO_MESSAGE    11
#define VT_BLANK_OK_MESSAGE       12
#define VT_BLANK_OK_BROWSE        13


// do not change these numbers without checking REPORT FORMS !
#define   V_GROWER                    1
#define   V_PRINTER                   2
#define   V_GROWER_NAME               3    // used only to LU cheque Name
#define   V_GROWER_CHEQUE_NAME        4
#define   V_TRANSACTION_TYPE          5
#define   V_MAY_ADD_TRANSACTION_TYPE  6
#define   V_DEDUCTION_CLASS           7
// see also       V_ALL_ACCOUNT_CLASSES      47
// see also       V_CLASS_FOR_A_TYPE         57, needs XINFO!

#define   V_CHEQUE_TYPE               8
#define   V_BANK_STATEMENT            9   // means it IS already on file

#define   V_CURRENCY                 10

#define   V_CONTAINER                11
#define   V_PROCESS_TYPE             12
#define   V_PROCESS_GRADE            71  // Name of Grade_N1 etc
#define   V_PRODUCT                  13

#define   V_PRICE_LEVEL              15
#define   V_PAYGRP                   16
#define   V_IMPORT_BATCH             17

#define   V_PROCESS_CLASS            18   // General Class of Process !
#define   V_PRODUCT_CATEGORY         19   // General Class of Products !

#define   V_CHEQUE_FORMAT_ID         20

#define   V_DEPOT                    30  // July 2013
#define   V_GST_TAX_CLASS            41  //  not needed yet
#define   V_TAXES                    42

#define   V_ALL_ACCOUNT_CLASSES      47
#define   V_CLASS_FOR_A_TYPE         57

#define   V_VARIETY                  70   // June 2015
//                                   71    see above

#define   V_IMPORT_SESSION           73   // May 2020


#define V_PRINTERS               300
#define V_WIN_PRINTERS           310
#define V_WIN_DEFA_FONT          320  // generally not used, LU is tho!

#define  V_FILE_LOGO              871
#define  V_FILE_WATERMARK         872
#define  V_FILE_DIRECTORY         873


#define    LU_GROWER                     1001

#define    LU_SLOW_BROWSE_GROWER         2001

#define    LU_PRINTER                    1002
#define    LU_GROWER_NAME                1003
#define    LU_GROWER_CHEQUE_NAME         1004
#define    LU_TRANSACTION_TYPE           1005
#define    LU_MAY_ADD_TRANSACTION_TYPE   1006  // these can be input by user.
#define    LU_DEDUCTION_CLASS            1007
#define    LU_CHEQUE_TYPE                1008
#define    LU_BANK_STATEMENT             1009

//   #define    LU_GROWER_DEPOT               1100
#define    LU_GROWER_STATUS              1101

#define    LU_SHORT_TRANSACTION_TYPE     1105
#define    LU_TRANSACT_TYPE_SORT_CODE    1106 // July 2012


#define   LU_CURRENCY                    1010
#define   LU_CONTAINER                   1011
#define   LU_PROCESS_TYPE                1012
#define   LU_PROCESS_GRADE               1071    // April 2019
#define   LU_PRODUCT                     1013
#define   LU_SHORT_PRODUCT_NAME          1014

#define   LU_PRICE_LEVEL                 1015

#define   LU_PAYGRP                      1016
#define   LU_IMPORT_BATCH                1017
#define   LU_PROCESS_CLASS               1018

#define   LU_PRODUCT_CATEGORY             1019
#define   LU_HAVE_PRODUCT_FIND_CATEGORY   1119     //
#define   LU_HAVE_PRODUCT_CATEGORY_DESC   1219     //

#define   LU_DEPOT                       1030

#define   LU_GST_TAX_CLASS               1041
#define   LU_TAXES                       1042
#define   LU_ALL_ACCOUNT_CLASSES         1047
#define   LU_CLASS_FOR_A_TYPE            1057
#define   LU_VARIETY                     1070   // June 2015
//                                         71    noted from above...

#define LU_PRINTERS                1300
#define LU_WIN_PRINTERS            1310
#define LU_WIN_DEFA_FONT           1320

#define LU_WIN_ANY_WIN_FONT         1350

#define LU_WIN_DEFA_BIN            1330
#define LU_WIN_DEFA_FORM           1340


#define  LU_FILE_LOGO             1871
#define  LU_FILE_WATERMARK        1872
#define  LU_FILE_DIRECTORY        1873


