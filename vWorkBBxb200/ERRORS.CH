
// ---------------------------------------------------------------------------
//   File Name: ERRORS.CH
//  Description: These are Errors that we need to code to tell us if
//               they come up.
//
//       Author: Bill Hepler
// Date created: 01-08-98
// Time created: 05:05:58pm
//    Copyright: 1998, 2011, 2014 by Bill Hepler
// ---------------------------------------------------------------------------

#define   APP_ERR_WRONG_DBF_FILE1        '00011'
#define   APP_ERR_WRONG_DBF_FILE2        '00012'

#define   APP_ERR_WRONG_DBF_FILE3        '00013'

#define   APP_ERR_BAD_FILE_CALL1         '00021'
#define   APP_ERR_BAD_FILE_CALL2         '00022'

#define   APP_ERR_DAY_UNIQ_4             '00034'
#define   APP_ERR_DAY_UNIQ_5             '00035'
#define   APP_ERR_DAY_UNIQ_6             '00036'
#define   APP_ERR_DAY_UNIQ_7             '00037'


#define   APP_ERR_WEIRD_GRADE_POST       '00039'

#define   APP_ERR_WHAT_PRODUCT_IS_IT     '00040'
#define   APP_ERR_PRODUCT_PROCESS        '00041'
#define   APP_ERR_WHAT_PRODUCT_IS_IT_2   '00042'

#define   APP_ERR_UNKNOWN_CURRENCY       '00045'


#define   APP_ERR_ADD_UP1                '00051'
#define   APP_ERR_ADD_UP2                '00052'
#define   APP_ERR_ADD_UP3                '00053'

#define   APP_ERR_NO_GRADE               '00060'

#define   APP_ERR_NO_CURRENCY            '00070'
#define   APP_ERR_EMPTY_CURRENCY1        '00071'
#define   APP_ERR_EMPTY_CURRENCY2        '00072'


#define   APP_ERR_DEDUCTION_CLASS         '00081'
#define   APP_ERR_DEDUCTION_TYPE          '00082'

#define   APP_ERR_BAD_CHEQUE_FORMAT       '00090'

#define   APP_ERR_UNEXPECTED_AC_TYPE      '00100'

#define   APP_ERR_UNEXPECTED_VALTYPE      '00110'

#define   APP_ERR_CONTAINER_ID            '00120'
#define   APP_ERR_CONTAINER_DUPLICATE1    '00121'
#define   APP_ERR_CONTAINER_DUPLICATE2    '00122'

#define   APP_ERR_GROWER_NO_WRONG         '00130'
#define   APP_ERR_GROWER_NOT_FOUND        '00131'

#define   APP_ERR_REPORT_CALC1             '00141'
#define   APP_ERR_REPORT_CALC2             '00142'
#define   APP_ERR_REPORT_CALC3             '00143'
#define   APP_ERR_REPORT_CALC4             '00144'

#define   APP_ERR_ARRAY_GOOF               '00150'

#define   APP_ERR_STATE_CHQ_NOT_FND        '00160'
#define   APP_ERR_STATE_SUB_TOTAL          '00161'   // April 2019

#define   APP_ERR_DAILY_ID_DURING_IMPORT         '00170'
#define   APP_ERR_BATCH_NO_DURING_IMPORT         '00171'
#define   APP_ERR_BATCH_NO_DURING_POST           '00172'
#define   APP_ERR_BATCH_ASSIGN_DURING_IMPORT     '00173'
#define   APP_ERR_BATCH_ASSIGN_IN_IMPORT         '00174'
#define   APP_ERR_BATCH_ALREADY_ON_FILE5         '00175'
#define   APP_ERR_BATCH_ALREADY_ON_FILE6         '00176'
#define   APP_ERR_BATCH_MULTIPLE_NO              '00177'   // older one
#define   APP_ERR_BATCH_MORE_MULTIPLES           '00178'   // April 2020 added
#define   APP_ERR_BATCH_FILE_NAME_ISSUE          '00179'   // April 2020 added


#define   APP_ERR_TRYING_TO_POST_TWICE1          '00181'
#define   APP_ERR_TRYING_TO_POST_TWICE2          '00182'
#define   APP_ERR_TRYING_TO_POST_TWICE3          '00183'
#define   APP_ERR_TRYING_TO_POST_TWICE4          '00184'

#define   APP_ERR_REMOVING_UPDATE1                '00201'
#define   APP_ERR_REMOVING_UPDATE2                '00202'

#define   APP_ERR_NEGATIVE_YEAR_END_PRICE         '00210'

#define   APP_ERR_NOT_BALANCING                   '00220'

#define   APP_ERR_POSTING_BATCH_EXPECTED          '00230'

#define   APP_ERR_WEEK_STATE_CHEQUE_FIND          '00240'
#define   APP_ERR_WEEK_STATE_CHEQUE_FIND2         '00242'


#define   APP_ERR_AUDIT_TRAIL_PROBLEM1            '00251'
#define   APP_ERR_AUDIT_TRAIL_PROBLEM2            '00252'

#define   APP_ERR_CONTAINER_AMT1           '00261'
#define   APP_ERR_CONTAINER_AMT2           '00262'

#define   APP_ERR_NO_PRICE_WITH_ID                '00270'

#define   APP_ERR_CHEQUE_LOCATE1                  '00271'
#define   APP_ERR_CHEQUE_LOCATE2                  '00272'
#define   APP_ERR_CHEQUE_LOCATE3                  '00273'
#define   APP_ERR_CHEQUE_LOCATE4                  '00274'
#define   APP_ERR_CHEQUE_LOCATE5                  '00275'
#define   APP_ERR_CHEQUE_LOCATE6                  '00276'
#define   APP_ERR_CHEQUE_LOCATE7                  '00277'

#define   APP_ERR_GROWER_NOT_FOUND_HERE1          '00281'
#define   APP_ERR_GROWER_NOT_FOUND_HERE2          '00282'

#define   APP_ERR_UNKNOWN_ADVANCE_TYPE1           '00291'
#define   APP_ERR_UNKNOWN_ADVANCE_TYPE2           '00292'
#define   APP_ERR_UNKNOWN_ADVANCE_TYPE3           '00293'
#define   APP_ERR_UNKNOWN_ADVANCE_TYPE4           '00294'
#define   APP_ERR_UNKNOWN_ADVANCE_TYPE5           '00295'
#define   APP_ERR_UNKNOWN_ADVANCE_TYPE6           '00296'
#define   APP_ERR_UNKNOWN_ADVANCE_TYPE7           '00297'
#define   APP_ERR_UNKNOWN_ADVANCE_TYPE8           '00298'

#define   APP_ERR_UNKNOWN_INDEXING_TYPE           '00300'

#define   APP_ERR_CAN_NOT_FIND_ACCOUNT_REC        '00310'
#define   APP_ERR_CAN_NOT_FIND_ACCOUNT_REC1       '00311'
#define   APP_ERR_CAN_NOT_FIND_ACCOUNT_REC2       '00312'
#define   APP_ERR_CAN_NOT_FIND_ACCOUNT_REC3       '00313'
#define   APP_ERR_CAN_NOT_FIND_ACCOUNT_REC4       '00314'


#define   APP_ERR_PROBABLY_EDITED_PRICE_REC1    '00321'

#define   APP_ERR_GROWER_STATUS1                '00331'

#define   APP_ERR_GROWER_HOLD1                  '00341'

#define   APP_ERR_FIELD_WIDTH1                  '00351'

#define   APP_ERR_PRICING1                      '00361'
#define   APP_ERR_PRICING2                      '00362'
#define   APP_ERR_PRICING3                      '00363'
#define   APP_ERR_PRICING4                      '00364'
#define   APP_ERR_PRICING5                      '00365'

#define   APP_ERR_ADVICE1                       '00371'

#define   APP_ERR_IMPORTED_PRICE_TOO_HIGH       '00381'
#define   APP_ERR_IMPORTED_PRICE_NEGATIVE       '00382'

#define   APP_ERR_IMPORTED_DOCKAGE_TOO_HIGH       '00391'
#define   APP_ERR_IMPORTED_DOCKAGE_NEGATIVE       '00392'

#define   APP_ERR_GENERAL_FOR_1                  '00401'
#define   APP_ERR_GENERAL_FOR_2                  '00402'
#define   APP_ERR_GENERAL_FOR_3                  '00403'
#define   APP_ERR_GENERAL_FOR_4                  '00404'

#define   APP_ERR_TEMP_INDEXING1                 '00501'
#define   APP_ERR_TEMP_INDEXING2                 '00502'
#define   APP_ERR_TEMP_INDEXING3                 '00503'
#define   APP_ERR_TEMP_INDEXING4                 '00504'
#define   APP_ERR_TEMP_INDEXING5                 '00505'
#define   APP_ERR_TEMP_INDEXING6                 '00506'
#define   APP_ERR_TEMP_INDEXING7                 '00507'
#define   APP_ERR_TEMP_INDEXING8                 '00508'
#define   APP_ERR_TEMP_INDEXING9                 '00509'
#define   APP_ERR_TEMP_INDEXING10                '00510'
#define   APP_ERR_TEMP_INDEXING11                '00511'
#define   APP_ERR_TEMP_INDEXING12                '00512'
#define   APP_ERR_TEMP_INDEXING13                '00513'

#define   APP_ERR_HP_CALLED_1                    '00601'
#define   APP_ERR_HP_CALLED_2                    '00602'

#define   APP_ERR_INPUTBY_MISSING1               '00701'
#define   APP_ERR_INPUTBY_MISSING2               '00702'
#define   APP_ERR_INPUTBY_MISSING3               '00703'

#define   APP_ERR_BLANK_CFILE1                   '00711'

#define   APP_ERR_WEIRD_DATA_1                   '00721'

#define   APP_ERR_ZAP_CHQ_1                      '00731'
#define   APP_ERR_ZAP_CHQ_2                      '00732'
#define   APP_ERR_ZAP_CHQ_3                      '00733'
#define   APP_ERR_ZAP_CHQ_4                      '00734'
#define   APP_ERR_ZAP_CHQ_5                      '00735'
#define   APP_ERR_ZAP_CHQ_6                      '00736'
#define   APP_ERR_ZAP_CHQ_7                      '00737'

#define   APP_ERR_TAX_STUFF1                     '00741'
#define   APP_ERR_TAX_STUFF2                     '00742'
#define   APP_ERR_TAX_STUFF3                     '00743'
#define   APP_ERR_TAX_STUFF4                     '00744'

#define   APP_ERR_POSTING_CATASTROPHE_1          '00751'
#define   APP_ERR_POSTING_CATASTROPHE_2          '00752'
#define   APP_ERR_POSTING_CATASTROPHE_3          '00753'

#define   APP_ERR_MULTIPLE_GST_RATES_4GROWER     '00761'  // Not an error, just unusual

#define   APP_ERR_TEMP_POSTING_FILES_01          '00771'

#define   APP_ERR_ACCT_UNIQ_1                    '00781'  // July 2014
#define   APP_ERR_ACCT_UNIQ_2                    '00782'
#define   APP_ERR_ACCT_UNIQ_3                    '00783'
#define   APP_ERR_ACCT_UNIQ_4                    '00784'
#define   APP_ERR_ACCT_UNIQ_5                    '00785'
#define   APP_ERR_ACCT_UNIQ_6                    '00786'


#define   APP_ERR_ACCT_TYPE_CLASS_01             '00791'  // July 2014

#define   APP_ERR_CROSS_CHECK_01                 '00801'  // March 2019

#define   APP_ERR_LOG_PROBLEM_EVENT              '00850'
#define   APP_ERR_CAN_NOT_OPEN_EVENT_LOG1        '00851'
#define   APP_ERR_EMPTY_EVENT_LOG_TYPE           '00852'

#define   APP_ERR_COUNTER_UNIQUE_1               '00861' // April 2020
#define   APP_ERR_COUNTER_UNIQUE_2               '00862'
#define   APP_ERR_COUNTER_UNIQUE_3               '00863'
#define   APP_ERR_COUNTER_UNIQUE_4               '00864'
#define   APP_ERR_COUNTER_UNIQUE_5               '00865'
#define   APP_ERR_COUNTER_UNIQUE_6               '00866'
#define   APP_ERR_COUNTER_UNIQUE_7               '00867'
#define   APP_ERR_COUNTER_UNIQUE_8               '00868'


#define   APP_ERR_ACCT_UNIQ_TYPE_1               '00871'


#define   APP_ERR_GLITCHY_IMPORT_0               '00880' // May 2020
#define   APP_ERR_GLITCHY_IMPORT_1               '00881'
#define   APP_ERR_GLITCHY_IMPORT_2               '00882'
#define   APP_ERR_GLITCHY_IMPORT_3               '00883'
#define   APP_ERR_GLITCHY_IMPORT_4               '00884'
#define   APP_ERR_GLITCHY_IMPORT_5               '00885'
#define   APP_ERR_GLITCHY_IMPORT_6               '00886'
#define   APP_ERR_GLITCHY_IMPORT_7               '00887'
#define   APP_ERR_GLITCHY_IMPORT_8               '00888'
#define   APP_ERR_GLITCHY_IMPORT_9               '00889' // May 2020

#define   APP_ERR_GLITCHY_IMPORT_10              '00890' // May 2020
#define   APP_ERR_GLITCHY_IMPORT_11              '00891'
#define   APP_ERR_GLITCHY_IMPORT_12              '00892'
#define   APP_ERR_GLITCHY_IMPORT_13              '00893'
// #define   APP_ERR_GLITCHY_IMPORT_14              '00894'
// #define   APP_ERR_GLITCHY_IMPORT_15              '00895'
// #define   APP_ERR_GLITCHY_IMPORT_16              '00896'
// #define   APP_ERR_GLITCHY_IMPORT_17              '00897'
// #define   APP_ERR_GLITCHY_IMPORT_18              '00898'
// #define   APP_ERR_GLITCHY_IMPORT_19              '00899'

#define   APP_ERR_GLITCHY_IMP_CONTAINER_1        '00901' // May 2020
#define   APP_ERR_GLITCHY_IMP_CONTAINER_2        '00902' // May 2020
#define   APP_ERR_GLITCHY_IMP_CONTAINER_3        '00903' // May 2020

#define   APP_ERR_GLITCHY_IMPORT_DATE_1          '00911' // May 2020

#define   APP_ERR_BLANK_DEPOT_1                  '00921' // July 2020



