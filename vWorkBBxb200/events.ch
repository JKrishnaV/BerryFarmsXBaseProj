// Events.ch
// Aug 31, 2014
// written by Bill Hepler - taken from Waste Management in 2019
// added to Dec 2014 & Dec 2019

// (c) 2014, 2019 by Crafted Industrial Software Ltd.

//                                             1234567890123456
#define  EVT_TYPE_VOID_SCALE_TICKET           'Void ScaleTicket'             // Found
#define  EVT_TYPE_REVERSE_TICKET              'Reverse a Ticket'             // Found

#define  EVT_TYPE_START_ADVANCE_DETERMINE     'Start AdvanceDet'             // Found
#define  EVT_TYPE_ADVANCE_CHECKED_4_ERRS      'Adv Chkd 4 Errs '             // Found
#define  EVT_TYPE_ADVANCE_INDEXED             'Adv Indexed     '             // Found
#define  EVT_TYPE_ADVANCE_ACTUAL_DETERMINE    'Adv Actual DetMn'             // Found
#define  EVT_TYPE_ADVANCE_DETERMINE_FAILS     'Adv DetMn FAILS '             // Found
#define  EVT_TYPE_ADVANCE_DID_NOT_POST        'Adv did NOT Post'             // Found

#define  EVT_TYPE_CHEQUES_TRY_TO_GENERATE     'Cheque Try2Start'             // Found
#define  EVT_TYPE_CHEQUE_GENERATE_FAILS       'Cheque Gen FAILS'             // Found
#define  EVT_TYPE_CHEQUE_VOUCHER_ONLY         'Cheque Voucher  '             // Found
#define  EVT_TYPE_CHEQUES_NOT_PRINTED_1       'Cheques NOT prn1'             // Found
#define  EVT_TYPE_CHEQUES_NOT_PRINTED_2       'Cheques NOT prn2'             // Found
#define  EVT_TYPE_CHEQUES_PRINTED             'Cheques Printed '             // Found

#define  EVT_TYPE_START_FINAL_DETERMINE       'Start Final Det'              // found
#define  EVT_TYPE_FINAL_CHECKED_4_ERRS        'Fin Chkd 4 Errs '             // found
#define  EVT_TYPE_FINAL_INDEXED               'Fin Indexed     '             // found
#define  EVT_TYPE_FINAL_ACTUAL_DETERMINE      'Fin Actual DetMn'             // found
#define  EVT_TYPE_FINAL_DETERMINE_FAILS       'Fin DetMn FAILS '             // found
#define  EVT_TYPE_FINAL_DID_NOT_POST          'Fin did NOT Post'             // found

#define  EVT_TYPE_GO_INTO_PAY_FIX             'PayFix ENTER !!!'             // found
#define  EVT_TYPE_PAY_FIX_PROCESS_IT          'PayFix PROCESS !'             // found


#define  EVT_TYPE_IMPORT_DATA_STEP1           'Import Sca Tick1'             // found
#define  EVT_TYPE_IMPORT_DATA_STEP2           'Import Sca Tick2'             // found
#define  EVT_TYPE_IMPORT_DATA_STOP1           'Import Stopped 1'             // found
#define  EVT_TYPE_IMPORT_DATA_STOP2           'Import Stopped 2'             // found
#define  EVT_TYPE_IMPORT_DATA_STOP3           'Import Stopped 3'             // found
#define  EVT_TYPE_IMPORT_DATA_STOP4           'Import Stopped 4'             // found
#define  EVT_TYPE_IMPORT_DATA_TICKETS         'Imported Tickets'             // found

#define  EVT_TYPE_IMPORT_ABORT_1              'Import Aborted 1'             // found
#define  EVT_TYPE_IMPORT_ABORT_2              'Import Aborted 2'             // found
#define  EVT_TYPE_IMPORT_NO_DATA              'Import NO DATA! '             // found 3 cases
#define  EVT_TYPE_IMPORT_MULTI_BRANCH         'Import MultBrnch'             // found
#define  EVT_TYPE_IMPORT_BATCH_WEIRD          'Import Bat Weird'             // found

#define  EVT_TYPE_PURGE                       'Purge Most Data '             // found

#define EVT_TYPE_CHEQUE_LOAN_ISSUED           'Loan to Grower  '
#define EVT_TYPE_CHEQUE_REISSUE               'Reissue a Cheque'
#define EVT_TYPE_CHEQUE_VOID_LEAVE_AP         'VoidCheq LeaveAP'
#define EVT_TYPE_CHEQUE_VOID_REMOVE_AP        'VoidCheq and AP '
#define EVT_TYPE_CHEQUE_VOID_REMOVE_AP_OH_NO  'VoidCheq AP-Err?'            // We may have a problem here!
#define EVT_TYPE_CHEQUE_DUBIOUS_TRY           'MaybeBAD to Void'            // probably should not void this

