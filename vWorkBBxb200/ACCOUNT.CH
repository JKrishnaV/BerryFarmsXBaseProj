// Account.ch
// as of 1995 QUALITY is no longer used
// June 2000 - we add "Final Price"
//          this is the Supposedly Final Price which is composed of the
//           Final Price - Advance
//           Price->cL1Grade1 is the Advance Price = 0.55/lb
//           Price->cFin1Gr1 is the Final Price    = 0.98/lb
//              the actual Final Payment is        = 0.43/lb
//              the difference between the 2................

//  The "Special Payments" are really Bonus Payments........
//  something outside the normal price agreements.
//  They were previously used for the additional payments, but
//  they are confusing...actually these are not used much!

//  July 2002 change stuff to deal with multiple advances
//
//  July 2012 - we comment better to help understand statement
//              e.g. WkSt2012.prg better
//  July 2014 - stuff for GST:  My original plans were to just
//              add new "Types" to the array here to allow for
//              GST etc. I changed my mind & added new fields
//              to Account.dbf, but I think that is wrong!
//              (as of July 16, 2014).  What I am doing is
//              back essentially to my original idea, which is
//              to add "Account" records.  I do add fields to
//              to ACCOUNT.DBF though to show that the record is
//              taxable, and estimate the GST on this...
//              Taxes will be additional columns in Account Records
//              Automatic taxes are added in POST.PRG.  Manual
//              Taxes can be added too.
//              GST Tax is Simply a TYPE.


// In Principal there are "Types" and "Classes", where
//    Classes are a "child" of Types.   However,
//    not all Types have classes.
// Note that  "CLASS" IDs should be Unique !

// Container Only Transactions:
//   On statements we usually ignore this as they should NOT have a Value!
#define    TT_ADV_CONTAINER_ONLY 'W_C'

#define    TT_DEDUCT             'DED'    // General Deductions (might be manual etc)

// Advance payments (normal)
#define  TT_BERRY_ADVANCE_1    'W_F'
#define  TT_BERRY_ADVANCE_2    'W_G'
#define  TT_BERRY_ADVANCE_3    'W_H'

// GST can be automatically applied to the STD_DEDUCTION ...
#define  TT_GST_TAX            'ZTG'   // Tax GST - we "generally" want this at the end


#define  NN_ADVANCE_1    1
#define  NN_ADVANCE_2    2
#define  NN_ADVANCE_3    3


// Time Based Premium issued once only - generally on 1st Advance
#define  TT_TIME_PREMIUM       'W_P'
//  This is only done once - generally on 1st Advance..
//   the Blueberry Council deduction
//   July 2014 - I added code for GST charges (especially to
//               this particular kind of transaction).
#define  TT_STD_DEDUCTION      'WDD'

#define  TT_FINAL_BERRY        'F_B'

#define  TT_SPECIAL_BERRY       'Y_F'
#define  TT_SPECIAL_CONTAINER   'Y_C'
#define  TT_EQUITY              'EQY'
#define  TT_MISCELLANEOUS       'MIS'

// these are for Classes for Deductions...
#define  D_CL_FERTILIZER        'FERT    '
#define  D_CL_CHEMICAL          'CHEMICAL'
#define  D_CL_BC_RASP_LEVY      'BCRASPLV'
#define  D_CL_CROP_INS          'CROP_INS'
#define  D_CL_COOP_CLEAN        'CO_CLEAN'
#define  D_CL_INTEREST          'INTEREST'
#define  D_CL_BC_FARM_INC_INS   'BCFARMII'
#define  D_CL_QUALITY_DEDUCTION 'QUAL_DED'  // Not Used any More
#define  D_CL_BC_BLUE_LEVY      'BCBLUELV'
#define  D_CL_FLAT_DRUM_PALLET  'FL_DR_PA'
#define  D_CL_MISCELLANEOUS     'MISC    '

//            #define  D_CL_MISCELLANEOUS     'MISC    '
#define  TAX_TYPE_CL_AUTO_STD_DEDUCTION       'TAX WDD '
#define  TAX_TYPE_CL_STAND_ALONE_ADJUSTMENT   'TAX ADJ '
#define  TAX_TYPE_CL_RELATES_TO_ANOTHER       'TAX REL '


// used for reports etc.
#define TT_FULL_DESC_LENGTH    30   // keep the biggest!
#define TT_SHORT_DESC_LENGTH   10
#define TT_DEDUCT_DESC_LENGTH  25


#define   A_MAY_ADD_TRANSACTION_TYPE_ARRAY  { ;
 {TT_DEDUCT,            "Deductions                   ",0.00}, ;
 {TT_EQUITY,            "Equity                       ",0.00}, ;
 {TT_MISCELLANEOUS,     "Miscellaneous Entry          ",0.00}, ;
 {TT_GST_TAX,           "GST Tax                      ",0.00} }

#define  A_TT_COLUMN_CODE        1
#define  A_TT_COLUMN_DESC        2
#define  A_TT_COLUMN_DOLLAR      3
#define  A_TT_COLUMN_SORT_BY     4
#define  A_TT_COLUMN_GST_TAXABLE 5    // GST itself is not GSTable!
#define  A_TT_COLUMN_SHORT_DESC  6

//
#define   A_TT_TRANSACTION_TYPE_DESC_LEN   29
//   "Deductions                   "
//    123456789_123456789_123456789


#define   A_TRANSACTION_TYPE_ARRAY  { ;
 {TT_DEDUCT,            "Deductions                   ",0.00,'07', .t. , "Deductions" }, ;
 {TT_BERRY_ADVANCE_1,   "1st Advance for Berries      ",0.00,'02', .f. , "Adv1 Berry" }, ;
 {TT_BERRY_ADVANCE_2,   "2nd Advance for Berries      ",0.00,'03', .f. , "Adv2 Berry" }, ;
 {TT_BERRY_ADVANCE_3,   "3rd Advance for Berries      ",0.00,'04', .f. , "Adv3 Berry" }, ;
 {TT_TIME_PREMIUM,      "Reg. Adv. Early Time Premium ",0.00,'05', .f. , "Time Prem " }, ;
 {TT_STD_DEDUCTION,     "Reg Adv Marketing Deduction  ",0.00,'06', .t. , "Market Ded" }, ;
 {TT_FINAL_BERRY,       "Final Payment less Advance   ",0.00,'10', .f. , "Fin. Berry" }, ;
 {TT_SPECIAL_BERRY,     "Special Payment for Berries  ",0.00,'11', .f. , "Spec Berry" }, ;
 {TT_EQUITY,            "Equity                       ",0.00,'12', .f. , "Equity    " }, ;
 {TT_SPECIAL_CONTAINER, "Special Pay re: Containers   ",0.00,'13', .f. , "Sp Contain" }, ;
 {TT_MISCELLANEOUS,     "Miscellaneous Entry          ",0.00,'01', .t. , "Misc.Entry" }, ;
 {TT_ADV_CONTAINER_ONLY, ;
                        "Container Only Transaction   ",0.00,'14', .f. , "Cont Only" }, ;
 {TT_GST_TAX,           "GST Tax                      ",0.00,'15', .f. , "GST Tax  " } }


//
// Classes:   Some "Transaction TYPES" have Classes:

// for All Classes:
#define  A_ALL_TYPE_CLASSES_COLUMN_TYPE_CODE        1
#define  A_ALL_TYPE_CLASSES_COLUMN_CLASS_CODE       2
#define  A_ALL_TYPE_CLASSES_COLUMN_DESC             3
#define  A_ALL_TYPE_CLASSES_COLUMN_DOLLAR           4

// for Classes for ONE type
#define  A_SINGLE_TYPE_CLASS_COLUMN_CODE        1
#define  A_SINGLE_TYPE_CLASS_COLUMN_DESC        2
#define  A_SINGLE_TYPE_CLASS_COLUMN_DOLLAR      3


// These are for MANUAL DEDUCTIONS !!!
#define  A_DEDUCTION_CLASS_ARRAY { ;
 {D_CL_FERTILIZER ,                       'Fertilizer              ',0.00}, ;
 {D_CL_CHEMICAL,                          'Chemicals               ',0.00}, ;
 {D_CL_BC_RASP_LEVY,                      'BC Raspberry Counc. Levy',0.00}, ;
 {D_CL_CROP_INS,                          'Crop Insurance          ',0.00}, ;
 {D_CL_COOP_CLEAN,                        'Cleaning/Picking Charges',0.00}, ;
 {D_CL_INTEREST,                          'Interest                ',0.00}, ;
 {D_CL_BC_FARM_INC_INS,                   'BC Farm Income Insurance',0.00}, ;
 {D_CL_QUALITY_DEDUCTION,                 'Quality Deduction       ',0.00}, ;
 {D_CL_BC_BLUE_LEVY,                      'BC Blueberry Counc. Levy',0.00}, ;
 {D_CL_FLAT_DRUM_PALLET,                  'Flats, Drums, Pallets   ',0.00}, ;
 {D_CL_MISCELLANEOUS,                     'Miscellaneous Deduction ',0.00} }

// These are for Taxes
#define  A_TAX_CLASSES_ARRAY  { ;
 {  TAX_TYPE_CL_AUTO_STD_DEDUCTION     ,  'For Marketing Deduction ',0.00}, ;
 {  TAX_TYPE_CL_STAND_ALONE_ADJUSTMENT ,  'Manual Tax Entry        ',0.00}, ;
 {  TAX_TYPE_CL_RELATES_TO_ANOTHER     ,  'Relates to another entry',0.00}  }

#define  A_ALL_ACCOUNT_TYPE_CLASSES_ARRAY { ;
 { TT_DEDUCT,   D_CL_FERTILIZER                      , 'Fertilizer              ' , 0.00}, ;
 { TT_DEDUCT,   D_CL_CHEMICAL                        , 'Chemicals               ' , 0.00}, ;
 { TT_DEDUCT,   D_CL_BC_RASP_LEVY                    , 'BC Raspberry Counc. Levy' , 0.00}, ;
 { TT_DEDUCT,   D_CL_CROP_INS                        , 'Crop Insurance          ' , 0.00}, ;
 { TT_DEDUCT,   D_CL_COOP_CLEAN                      , 'Cleaning/Picking Charges' , 0.00}, ;
 { TT_DEDUCT,   D_CL_INTEREST                        , 'Interest                ' , 0.00}, ;
 { TT_DEDUCT,   D_CL_BC_FARM_INC_INS                 , 'BC Farm Income Insurance' , 0.00}, ;
 { TT_DEDUCT,   D_CL_QUALITY_DEDUCTION               , 'Quality Deduction       ' , 0.00}, ;
 { TT_DEDUCT,   D_CL_BC_BLUE_LEVY                    , 'BC Blueberry Counc. Levy' , 0.00}, ;
 { TT_DEDUCT,   D_CL_FLAT_DRUM_PALLET                , 'Flats, Drums, Pallets   ' , 0.00}, ;
 { TT_DEDUCT,   D_CL_MISCELLANEOUS                   , 'Miscellaneous Deduction ' , 0.00}, ;
 { TT_GST_TAX,  TAX_TYPE_CL_AUTO_STD_DEDUCTION       , 'For Marketing Deduction ' , 0.00}, ;
 { TT_GST_TAX,  TAX_TYPE_CL_STAND_ALONE_ADJUSTMENT   , 'Manual Tax Entry        ' , 0.00}, ;
 { TT_GST_TAX,  TAX_TYPE_CL_RELATES_TO_ANOTHER       , 'Relates to a Deduction  ' , 0.00}  }


 // Finding Related Transactions, see Misc

 #define   REL_2_ACCOUNT_TRN_DAILY         1     // Relate to Daily DBF (in AUDIT.DBF)
 #define   REL_2_OTHER_ACCOUNTS            2     // Relate to other Account.dbf records (in AudAcct.DBF)
 #define   REL_2_OTHER_ACCOUNTS_AS_MASTER  3     //   If above is T - is it a MASTER e.g. GST
 #define   REL_2_OTHER_ACCOUNTS_AS_CHILD   4     //   If above is T - is it a CHILD e.g.
 #define   REL_2_STANDALONE                5     // SB True if 1 & 2 are F....
 // at this point  1-4 interrale
 //   all False is NOT initialized or a problem
 //   all True is an Error
 //   3 & 4 True is an error (for now anyway)

 #define   REL_2_ACCOUNT_MASTER            6
 #define   REL_2_CHEQUE_FULL_ID            7
 #define   REL_2_CHEQUE_INFO               8

 #define   REL_2_ACCT_UNIQ                 9     // Stored for Cross Checking.
 #define   REL_2_IS_ERROR                 10
 #define   REL_2_ERROR_CONDITION          11

 #define   ARRAY_REL_2_ACCOUNT   { .f., .f., .f., .f., .f.,   0, space( 10 ), space(25), 0 , .t., 'Not initialized' }
 //                                 1    2    3    4    5     6         7         8      9   10,     11

// Will there be other records associated with an Account Transaction:

#define   ACCT_ASSOC_RECS_DAILY_TYPES  TT_BERRY_ADVANCE_1+'x'+ ;
                                                TT_BERRY_ADVANCE_2 + 'x'+ TT_BERRY_ADVANCE_3 + 'x' + ;
																TT_TIME_PREMIUM + 'x' + TT_STD_DEDUCTION + 'x' + ;
																TT_FINAL_BERRY + 'x' + TT_SPECIAL_BERRY + 'x'

#define   ACCT_ASSOC_RECS_OTHER_ACCT_RECS   TT_DEDUCT+'x'+TT_GST_TAX +'x' + ;
                                                  TT_STD_DEDUCTION +'x'+ TT_MISCELLANEOUS + 'x'




#define  C_ACCOUNT_POST_TYPE_WEEKLY_1  'W1'
#define  C_ACCOUNT_POST_TYPE_WEEKLY_2  'W2'
#define  C_ACCOUNT_POST_TYPE_WEEKLY_3  'W3'
#define  C_ACCOUNT_POST_TYPE_FINAL     'F '

