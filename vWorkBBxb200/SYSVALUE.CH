// SysValue.ch
// Substitute for Memvars
// September 92
//
// The Actual Array is unique to each application.	See BSGSTD.CH
// for the Structure of the Complete Array...
//
// Structure is:
//
// UniqID, Default Value, picture to Edit, valid for Edit

// File contains fields UNIQ_ID, VALUE, is NOT indexed...

// this is the Structure of the SysValue Array !
#define SYS_UNIQUE          1   // width MAX of 8
#define SYS_DEFAULT 			 2
#define SYS_PICTURE 			 3
#define SYS_VALID				 4
#define SYS_DESCRIPTION 	 5

#define SYS_CURRENT 			 6



// below is specific to your application !
/////////////////////////// 12345678 //////////////

#define  SYS_ALLOW_CANADIAN_DOLLARS '$_CANADA'
#define  SYS_ALLOW_US_DOLLARS       '$_US----'


#define  SYS_CURRENT_YEAR           'CURRYEAR'
#define  SYS_CURRENT_SEASON_START   'START_SE'
#define  SYS_CURRENT_SEASON_END     'END_SEAS'
#define  SYS_CURRENT_HOWMANY_YEARS  'HOW_MANY'

#define  SYS_CDN_CHEQUE_SERIES      'CHEQ_SER'
#define  SYS_US_CHEQUE_SERIES       'US_CHEQS'

#define  SYS_CHEQUE_PART_THREE             'CHEQ_3RD'
#define  SYS_DEFAULT_PREMIUM_MSG           'R_PRM_MS'
#define  SYS_DEFAULT_NO_STATEMENT_COPIES   'NO_STATE'


#define  SYS_DISK_CHECK_ON_FLOPPY          'DISKTEST'
#define  SYS_UNITS_OF_WEIGHT               'UNITSWGT'

#define  SYS_CHEQUE_FORMAT                 'CHEQFORM'
#define  SYS_CHEQUE_1ST_LINE               'FIRSTLIN'
#define  SYS_CHEQUE_LEFT_INDENT            'INDENTIT'
#define  SYS_CHEQUE_FORM_LENGTH            'FORM-LEN'
#define  SYS_CHEQUE_ADVICE_STARTS          'DADVICES'
#define  SYS_CHEQUE_DOLLAR_FORMAT          'CHEQFOR$'

#define  SYS_CHEQUE_NIFTY_ADVICE_NO_LINES  'CHQA_0LN'
#define  SYS_CHEQUE_NIFTY_ADVICE1_STARTS   'CHQA_AD1'
#define  SYS_CHEQUE_NIFTY_ADVICE2_STARTS   'CHQA_AD2'
#define  SYS_CHEQUE_NIFTY_DATE_FORMAT      'CHQA_DAF'
#define  SYS_CHEQUE_NIFTY_DATE_DISTANCE    'CHQA_DIS'
#define  SYS_CHEQUE_NIFTY_DOLLAR_FORMAT    'CHQA_MON'
#define  SYS_CHEQUE_NIFTY_AMT_IN_WORD_LEN  'CHQA_WLN'

#define  SYS_LABEL_LENGTH                  'LBL__LEN'
#define  SYS_LABEL_INDENT                  'LBL__IND'

#define  SYS_LABEL_2_CONTAINER_RPT         '2CONTRPT'


#define   SYS_ACTUAL_CLIENT_NAME           'CL-NAME-'
#define   SYS_ACTUAL_ADDRESS1              'CL-ADDR1'
#define   SYS_ACTUAL_ADDRESS2              'CL-ADDR2'
#define   SYS_ACTUAL_ADDRESS3              'CL-ADDR3'
#define   SYS_ACTUAL_PHONE                 'CL-PHONE'

#define   SYS_FORCE_CHQ_REC_2_BALANCE      'FORCEBAL'

#define   SYS_PRODUCTION_FORMAT_1          'PRDFORM1'
#define   SYS_PRODUCTION_FORMAT_2          'PRDFORM2'

#define   SYS_IMPORT_DIRECTORY             'IMPO_DIR'
#define   SYS_IMPORT_FORMAT                'IMPOFORM'
#define     SY_IMP_FMT_DOS             1
#define     SY_IMP_FMT_WIN_NO_PRICE    2
#define     SY_IMP_FMT_WIN_WITH_PRICE  3

#define   SYS_IMPORT_PREFIX                'IMPOPREF'

// added for WestBerry in 2007...
#define   SYS_SET_ADVANCES_BY_PROCESS_ONLY 'ADVBYPRO'

#define   SYS_IMPORT_ROUND_NET_METHOD      'ROUNDNET'

#define   SYS_PRODUCT_CATEGORY_1           'PRODCAT1'
#define   SYS_PRODUCT_CATEGORY_2           'PRODCAT2'
#define   SYS_PRODUCT_CATEGORY_3           'PRODCAT3'
#define   SYS_PRODUCT_CATEGORY_4           'PRODCAT4'
#define   SYS_PRODUCT_CATEGORY_5           'PRODCAT5'
#define   SYS_PRODUCT_CATEGORY_6           'PRODCAT6'

#define   SYS_PRODUCT_CATEGORY___          'PRODCAT'

#define   SYS_ARCHIVE_DATA_YEAR            'ARCHYEAR'

#define   SYS_DOCKAGE_ACTION               'DOCKAGE_'
#define       DOCKAGE_ACTION_WARN           'W'
#define       DOCKAGE_ACTION_CHANGE         'C'
#define       DOCKAGE_ACTION_NO_ACTION      'N'

#define   SYS_WEEK_STATEMENT_FORMAT        'STATEFMT'
#define         WEEK_STATE_FMT_ORIGINAL      'O'
#define         WEEK_STATE_FMT_KEYED_PRICE   'K'

#define   SYS_WEEK_STATEMENT_SUMMARY_FP   'STATEFM2'

#define SYS_OWN_DIRECTORY            'OWN_DIR_'

#define  SYS_ASK_TO_PRINT_ALIGNMENT_COPY_OF_CHEQUE  'ASK_ALIN'

// These 3 added in Aug 2012
#define  SYS_TRY_ROBOCOPY_FOR_QBU         'TRY_ROBO'
#define  SYS_FOLDER_TO_BACKUP_INTO        'BAK2HERE'
#define  SYS_FOLDER_BACKUP_BU1_2          'BAK2_1_2'

// July 2013
#define    SYS_GENERALLY_SWITCH_TO_LANDSCAPE       'SW_2LAND'
#define    SYS_DEFAULT_RPT_LINE_HEIGHT             'R_LINE_H'

#define    SYS_DEFAULT_ADV_STATEMENT_LINE1             'DF_STAL1'
#define    SYS_DEFAULT_ADV_STATEMENT_LINE2             'DF_STAL2'

#define    SYS_DEFAULT_FINAL_STATEMENT_LINE1           'DF_STFL1'
#define    SYS_DEFAULT_FINAL_STATEMENT_LINE2           'DF_STFL2'

// Dec 2014
#define    SYS_STATEMENT_LOGO                      'LOGOFILE'
#define    SYS_STATEMENT_LOGO_TOP                  'LOGO_S_T'
#define    SYS_STATEMENT_LOGO_LEFT                 'LOGO_S_L'
#define    SYS_STATEMENT_LOGO_WIDTH                'LOGO_S_W'  // Mar 2015

#define    SYS_STATEMENT_YOUR_NAME_ADDRESS_TOP     'YADD_S_T'
#define    SYS_STATEMENT_YOUR_NAME_ADDRESS_LEFT    'YADD_S_L'

// June 2, 2015
#define    SYS_DEFAULT_VARIETY                     'DF_VARIT'   // June 2015

// March 2019
#define   SYS_SHOW_PART_DATA_DIR                   'A_DATDIR'   // so shows near archive

// April 2019
#define   SYS_USE_PROCESS_GRADE_NAMES              'PRD_GR_N'

#define   SYS_WEEK_STATEMENT_DEFAULT_FORMAT        'DF_AWKDF'    // Default statement to print for Weekly...
#define   SYS_CROPYEAR_STATEMENT_DEFAULT_FORMAT    'DF_AYKDF'    // Default statement to print at Year End...

// March 2020
#define   SYS_IMPORT_FROM_FIELD_NAME               'FROM_FLD'    // The From Field name (which field)

// May 2021 - Westberry asks for
#define   SYS_QUICK_CHECK_FOR_ZERO_KEY             'ZERO_KEY'   // quick check for ZERO key.
#define    SQCFZ_NOT_AUTOMATIC           0    // Default, not using
#define    SQCFZ_AUTOMATIC_FRESH         1    // for WestBerry
#define    SQCFZ_AUTOMATIC_WHATEVER      2    // but if they wanted they could check whatever they are running

#define  SYS_CHEQUE_SUGGEST_LOOK_AT_STATEMENT      'CHQB_STA'   // Nov 2022-Jass-we normally suggest that a Grower
                                                               // look at his statement if there are more items
#define  SYS_QUIK_ED_GROW_CONTRACT_CERTIFY_FLD     'QU_ED_GC'																					// on the Cheque Stub, than fit...  The Default is Yes
																					// as that is what we used to do.  For some reason
																					// Jass & Westberry do not want to suggest that...
#define     SQEDG_QUIK_ED_GCC_FIELD_STD      0  // no quick edit, default
#define     SQEDG_QUIK_ED_GCC_CONTRACT       1  // quick mod of contract field Y/N
#define     SQEDG_QUIK_ED_GCC_CERTIFY        2  // Yes No


// #define  GRP_DIRECTORY                  'DIR-'
#define  GRP_FISCAL_YEAR                'FISC'
#define  GRP_MISC                       'MISC'
#define  GRP_PRICING                    'PRIC'
#define  GRP_CHEQUE                     'CHQ-'
#define  GRP_COMPANY                    'CO--'
#define  GRP_REPORTS                    'RPTS'
#define  GRP_IMPORT                     'IMPO'
#define  GRP_PRODUCT_CATEGORIES         'CATP'
#define  GRP_BACKUP                     'BACK'

