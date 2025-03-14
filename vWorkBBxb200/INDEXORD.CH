//--------------------------------------------------------------------------
//     File Name: INDEXORD.CH
//   Description: Names of Indexes - do NOT make longer than 10 characters-limit of CDX DBE
//
//        Author: Bill Hepler
//  Date created: 05-09-99
//  Time created: 10:19:14 pm
//     Copyright: 1999, 2013 by Bill Hepler
//--------------------------------------------------------------------------

// ordinary transactions in Account are linked by Audit to Daily
// via the Acct_uniq & Day_uniq Fields.

#define    GROWER_NUMBER_ORD          'GRO_IDNO'
#define    GROWER_NAME_ORD            'GRO_NAME'
#define    GROWER_PAYGRP_NUMBER_ORD   'GRO_PG_ID'
#define    GROWER_PAYGRP_NAME_ORD     'GRO_PG_NM'
#define    GROWER_CHEQUE_NAME_ORD     'GRO_CHQNM'

#define    ACCOUNT_NUMBER_ORD       'ACC_IDNO'      // used for both DAILY & UNPOSTED
#define    ACCOUNT_DATE_ORD         'ACC_DATE'
#define    ACCOUNT_CHEQUE_ORD       'ACC_CHEQ'
#define    ACCOUNT_LINK_ORD         'ACC_LINK'


// #define    SUMMARY_NUMBER_ORD     'SUM_ID_ORD'

#define    SHARES_NUMBER_ORD       'SHA_IDNO'

//                                        123456789
#define    DAILY_GROWER_ORD              'DA_GRWNO'          // 2BFIXED -- all of these should be looked at
#define    DAILY_DEPOT_RECEIPT_ORD       'DA_RCPT'          
#define    DAILY_DATE_ORD                'DA_DATE'
#define    DAILY_ID_ORD                  'DA_RECID'
#define    DAILY_POST_DATE_ORD           'DA_PDATE'
#define    DAILY_ADV_POST_GROWER_ORD     'DA_ADVPG'     // April 2020
#define    DAILY_IMPORT_DEPOT_BATCH_ORD  'DA_IMPBAT'
#define    DAILY_FINAL_DATE_ORD          'DA_FINALD'    // 9 long do not do longer!
// #define    DAILY_DEPOT_TICKET_ORD        'DA_D_T_L'
#define    DAILY_IMPORT_UNIQ_BATCH_ORD   'DA_IMB_I'     // April 2020

// deleted the 5 th index in Oct 99

// Added in March 2020                          1234567890
#define    DAILYDAYAUD_DAILY_ID_ORD            'DAD_DAYID'
#define    DAILYDAYAUD_IMPORT_DEPOT_BATCH_ORD  'DAD_IMPBT'
#define    DAILYDAYAUD_DEPOT_TICKET_ORD        'DAD_D_T_L'
#define    DAILYDAYAUD_SELF_ID_ORD             'DAD_SELF'

#define    AUDIT_DAY_ACCT_ORD   'AUD_DAY'
#define    AUDIT_ACCT_DAY_ORD   'AUD_ACC'


// #define    DEDUCT_DATE_ORD      'DED_
// #define    DEDUCT_NUMBER_ORD    2

#define    CHEQUE_GROWER_ORD       'CHQ_GROW'
#define    CHEQUE_CHEQUE_NO_ORD    'CHQ_CHQ'
#define    CHEQUE_DATE_ORD         'CHQ_DATE'
#define    CHEQUE_GROWER_DATE_ORD  'CHQ_GRDT'   // 2BFIXED see MyDict
#define    CHEQUE_RECONCILE_ORD    'CHQ_REC'
#define    CHEQUE_DATE_GROWER_ORD  'CHQ_DTGR'

#define    VOIDCHQ_GROWER_ORD       'VC_GROW'
#define    VOIDCHQ_CHEQUE_NO_ORD    'VC_CHQ'
#define    VOIDCHQ_DATE_ORD         'VC_DATE'
#define    VOIDCHQ_DATE_VOID_ORD    'VC_DVOID'


#define    BANKREC_ACCOUNTING_DATE_ORD    'BANR_AD'

#define    CONTAIN_CONTAINER_ORD          'CON_CODE'

#define    PRODUCT_PRODUCT_ORD            'PROD_CODE'

#define    PROCESS_PROCESS_ORD            'PROC_CODE'

#define    PRICE_PRODUCT_ORD              'PRI_PROD'
#define    PRICE_DATE_ORD                 'PRI_DATE'
#define    PRICE_PRICE_ID_ORD             'PRI_IDORD'

#define    IMPBAT_BATCH_ORD               'IMP_BATCH'    // this is USELESS actually - comes from scale data!
#define    IMPBAT_DEPOT_BATCH_ORD         'IMP_DEP_B'    // this "SHOULD Be Unique", but can not be guaranteed to be (comes from Scale Data!
#define    IMPBAT_UNIQUE_ID_ORD           'IMP_UNIQ'     // this is assigned by this software WinBerryPay.

#define    POSTBAT_BATCH_ORD              'POST_BAT'

#define    FINBAT_BATCH_ORD               'FB_BAT'

#define    PAYGRP_PAYGRP_ORD              'PG_IDORD'

#define    VOIDTCK_DATE_RECEIPT_ORD       'VT_RCD'
#define    VOIDTCK_DEPOT_RECEIPT_ORD      'VT_DPRCP'

#define   CHQFMT_ID_ORD                   'CHQFMTID'

#define   RPTCFG_RPT_ID_ORD               'RCFG_RPT'

#define   DEPOT_DEPOT_ORD                 'DEPODEPO'

#define   TAX_TAXNAME_ORD                 'TAXNAME'  // 2014

#define   AUDACCT_MASTER_CHILD           'AA_M_CH'  // 2014
#define   AUDACCT_CHILD_MASTER           'AA_CH_M'  // 2014

#define   VARIETY_VARIETY_ORD            'VAR_VAR'  // 2015

#define EVENTS_DATE_ORD                  'EVT_DATE'  // 2020
#define EVENTS_TYPE_ORD                  'EVT_TYPE'  //
#define EVENTS_ID_ORD                    'EVT_ID'   

