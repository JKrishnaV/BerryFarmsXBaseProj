// BerryPay.ch
// Rev May 2020

#define    IMPORTED_FROM_SCALE_PC      'Imported from Scale PC '

#define    READ_IT    .t.
#define    NO_READ    .f.

#define    RECEIPT_STRU_FOR_IMPORT   1
#define    RECEIPT_STRU_FOR_DAILY    2
#define    RECEIPT_STRU_FOR_SUMMARY  3

#define    MAX_TYPES_CONTAINERS     20
#define    MAX_NO_OF_GRADES          3

// was changed to 3 in July 2001 from 2 previously
#define    MAX_NO_OF_PRICE_LEVELS    3    // dont change it if possible

#define    MAX_NO_OF_ADVANCES        3    // dont change it if possible !!


#define   CHEQUE_TYPE_WEEKLY     'W'
#define   CHEQUE_TYPE_SPECIAL    'S'
#define   CHEQUE_TYPE_EQUITY     'E'
#define   CHEQUE_TYPE_LOAN       'A'   // formerly called CHEQUE_TYPE_ADVANCE
#define   CHEQUE_TYPE_FINAL      'F'

// changed abbreviations in 2021 to be shorter and more descriptive esp "Weekly Advance"
#define   CHEQUE_NAME_ARRAY    { ;
 { CHEQUE_TYPE_WEEKLY,  'WkAdv' } , ;
 { CHEQUE_TYPE_SPECIAL, 'Spec.'} , ;
 { CHEQUE_TYPE_EQUITY,  'Equit'} , ;
 { CHEQUE_TYPE_LOAN,    'Loan '} , ;
 { CHEQUE_TYPE_FINAL  , 'Final'}   }

#define   DAILY_POSTED_ONLY   0
#define   DAILY_UNPOSTED      1
#define   DAILY_ANY_TRANS     2

#define   PRICE_SRC_FR_FILE    0 // these are the SAME !
#define   PRICE_SRC_FILE       1
#define   PRICE_SRC_SCALE      2
#define   PRICE_SRC_KEY        3


#define    PROCESS_CLASS_ARRAY  { 'Fresh  ', ;
                                  'Process', ;
                                  'Juice  ', ;
                                  'Other  ' }

#define   MAX_NO_PROC_CLASSES     4

#define  PROCESS_CLASS_FRESH      1
#define  PROCESS_CLASS_PROCESSED  2
#define  PROCESS_CLASS_JUICE      3
#define  PROCESS_CLASS_OTHER      4   // grab bag

#define   MAX_NO_PRODUCT_CATEGORIES      6

//                                         12345678901
#define    CHQ_FORMAT_ID_OUR_NAME         'OUR_NAME___'
#define    CHQ_FORMAT_ID_OUR_ADDRESS      'OUR_ADDR___'

#define    CHQ_FORMAT_ID_GROWER_NAME      'GROW_NAME__'
#define    CHQ_FORMAT_ID_GROWER_ADDRESS   'GROW_ADDR__'
#define    CHQ_FORMAT_WORD_TO_ORDER_OF    'WORD_TO_ORD'


#define    CHQ_FORMAT_ID_AMOUNT_AS_NUM    'AMT_AS_NUM_'
#define    CHQ_FORMAT_ID_AMOUNT_AS_TEXT   'AMT_AS_TEXT'
#define    CHQ_FORMAT_WORD_PAY            'WORD_PAY___'

#define    CHQ_FORMAT_DATE                'CHEQUE_DATE'
#define    CHQ_FORMAT_WORD_DATE           'WORD_DATE__'
#define    CHQ_FORMAT_YMD                 'DATE_YMD___'

// #define    CHQ_FORMAT_CHEQUE_NUMBER    'CHEQUE_NO__'


#define    MAXIMUM_PRICE                  99.98

#define   MINIMUM_LIB_VERSION   8.920   // Jan 8, 2020

#define ADD_EDIT_WHO_DID_ARRAY  { '',ctod(''),space(8),0}
#define AE_WHO_DID_PERSON   1
#define AE_WHO_DID_DATE     2
#define AE_WHO_DID_TIME     3
#define AE_WHO_DID_RECNO    4


// This is used for EFT cheques which are a different series of Cheque#s
#define   EFT_CHEQUE_SERIES        'EF'

#define    OLD_STATEMENT     'OLD'
#define    NEW_STATEMENT     'NEW'


// Do not change this lightly - this relates to Structure of Daily.dbf etc...
//  also see Valid.prg
#define   MIN_GRADE_NO    1   // 2019 - this is not the way this should have been done!
#define   MAX_GRADE_NO    3   //        but its the way the system works.

// See SysValue() routines and definitions....See also MENUS.PRG  !!!!
#define  WEEK_STATEMENT_FORMAT_1_OLD           1   // Oldest from 1990s
#define  WEEK_STATEMENT_FORMAT_1_REV_2019      2   // Old Format Revised in 2019 -     allows for more desc of Grades
#define  WEEK_STATEMENT_FORMAT_2_REV_2018      3   // Revised in 2012, 2014 (to allow better for GST)
#define  WEEK_STATEMENT_FORMAT_2_REV_2019      4   // Revised in 2012, 2014, & then in 2019 - allows for more desc of Grades


#define  CROPYEAR_STATEMENT_FORMAT_1_OLD              1   // Old Version from 1999
#define  CROPYEAR_STATEMENT_FORMAT_2_REV_2014         2   // New Version from 2014
#define  CROPYEAR_STATEMENT_FORMAT_2_SHORT_REV_2019   3   // New Version (2014) - added features in 2019, summary & More Desc of Grades
                                                          // shortened at WestBerry's request
#define  CROPYEAR_STATEMENT_FORMAT_2_LONG_REV_2019    4   // New Version (2014) - added features in 2019, summary & More Desc of Grades
                                                          // Longer form (like original) with extra summary at end.


// Grower Statement Arrays:
#define GRO_STATEMENT_COL_ID          1
#define GRO_STATEMENT_COL_EXE_BLOCK   2
#define GRO_STATEMENT_COL_DESC        3

#define GRO_STATEMENT_FOR_WEEKLY      'A'
#define GRO_STATEMENT_FOR_CROPYEAR    'B'

#define GROW_STATEMENT_WEEKLY_GENERAL_DESC   'Regular Advance (Weekly) Payment Statement'
#define GROW_STATEMENT_CROPYEAR_GENERAL_DESC 'Year End or Final (Crop Year) Statement'

#define GROWER_STATEMENT_WEEKLY_ARRAY   { ;
   { WEEK_STATEMENT_FORMAT_1_OLD            , { || WeekStat_1_Old()   } , 'Old format from 1990s'              }, ;
   { WEEK_STATEMENT_FORMAT_1_REV_2019       , { || WeekStat_1_R2019() } , 'Old format Updated in 2019'         }, ;
   { WEEK_STATEMENT_FORMAT_2_REV_2018       , { || WeekStat_2_R2018() } , 'New format from 2012, w/GST revised 2018' }, ;
   { WEEK_STATEMENT_FORMAT_2_REV_2019       , { || WeekStat_2_R2019() } , 'New format from 2012, w/GST revised 2019' } }

#define GROWER_STATEMENT_CROPYEAR_ARRAY { ;
   { CROPYEAR_STATEMENT_FORMAT_1_OLD              , { || CropStat_Old(      )  } , 'Old format from 1999'                       }, ;
   { CROPYEAR_STATEMENT_FORMAT_2_REV_2014         , { ||	CropStat_2014(     )  } , 'New format fr 2014, w/ GST rev 2018'        }, ;
   { CROPYEAR_STATEMENT_FORMAT_2_SHORT_REV_2019   , { || CropStat_2019( .f. )  } , 'New short format fr 2014, w/ GST rev 2019'  }, ;
   { CROPYEAR_STATEMENT_FORMAT_2_LONG_REV_2019    , { || CropStat_2019( .t. )  } , 'New long format fr 2014, w/ GST rev 2019'   }   }

#define DAILY_EDIT_IN_READ_MODE      1001   // e.g. when you are adding a manual transaction
#define DAILY_EDIT_ALLOW_NAVIGATE    1002   //      when you are browsing the Scale Tickets
#define DAILY_EDIT_VIEW_ONLY         1003   //      when you are browsing from ACCOUNT & should only
                                            //      be looking at the scale ticket, not editing...



