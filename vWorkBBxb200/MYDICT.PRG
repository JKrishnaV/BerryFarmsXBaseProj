//--------------------------------------------------------------------------
//  Application: Berry Payment
//  Description: Dictionary of Tables
//
//    File Name: MYDICT.PRG
//       Author: Bill Hepler
// Date created: 09-30-95
// Updated:      Dec 15, 2015
//               May 19, 2020 - revisions to audit trail, change some indexes.
//
//    Copyright: (c) 1995, 2012, 2014, 2015, 2020 by Bill Hepler
//--------------------------------------------------------------------------

#include "indexord.ch'

function InitMyData()
	local aDBFs

	aDBFs := {}

   // NOT in Purge!
   aadd( aDBFs, { 'BsgColor','Color Settings',     '', {}}  )
   aadd( aDBFs, { 'Users',   'Users of the System','', {}}  )

   // in Purge
	aadd( aDBFs, { 'Price','Price Settings', '', { ;
      {PRICE_PRODUCT_ORD,   'Product Order Pricing', ;
		'Price->product+Price->process+dtos(Price->from)'} , ;
      {PRICE_DATE_ORD,      'Date Order Pricing',  ;
		 'dtos(Price->from)+Price->product+Price->process'}, ;
      {PRICE_PRICE_ID_ORD, 'Price ID','str(Price->PriceID,8)'} }} )

   // NOT in Purge!
	aadd( aDBFs, { 'Contain','Container Types', '', { ;
       {CONTAIN_CONTAINER_ORD, 'Container No', 'str(Contain->container,2)'}  }}  )

   // index added in May 96 - NOT in Purge
	aadd( aDBFs, { 'SysValue', 'System Settings',   '', { ;
       {'SYSVAL1','Group + ID','SysValue->group+Sysvalue->uniq_id'} }} )

   // NOT in Purge!
	aadd( aDBFs, { 'Printer', 'Available Printers', '', {}} )
	// aadd( aDBFs, { 'Users','Authorized Users',      '', {}} )

   //FLD_GROWER in Purge
	aadd( aDBFs, {'GROWER','Growers','',  { ;
      {GROWER_NUMBER_ORD         , 'Grower Number', 'str(Grower->number,4)'}, ;
      {GROWER_NAME_ORD           , 'Grower Name', 'upper(Grower->name)'}, ;
      {GROWER_PAYGRP_NUMBER_ORD  , 'Group and Number','Grower->paygrp + str(Grower->number,4)'}, ;
      {GROWER_PAYGRP_NAME_ORD    , 'PayGrp and Name','Grower->paygrp+upper(substr(Grower->name,1,20))'}, ;
      {GROWER_CHEQUE_NAME_ORD    , 'Name as it appears on Cheque','upper(Grower->cheqName)'  }}} )

	// FLD_CHEQUE = 6
	// FLD_AD_LINK = 8
   // in Purge
	aadd( aDBFS, {'Account','Accounting Transactions','', { ;
      { ACCOUNT_NUMBER_ORD ,'Grower Number + year','str(Account->number,4)+str(Account->year,4)+dtos(Account->date)'}, ;
      { ACCOUNT_DATE_ORD   ,'Date','dtos(Account->date)'}, ;
      { ACCOUNT_CHEQUE_ORD ,'Cheque Number', ;
		  'Account->series+str(Account->cheque,6)+' + ;
		  'iif(Account->dollars + Account->gst_est>=0.00,"A","Z")+Account->type' }, ;
      { ACCOUNT_LINK_ORD   ,'ID Field','str(Account->acct_Uniq,8)'  } }} )

	/*
		aadd( aDBFs, {'Shares', 'Shares Owned','', { ;
			{'Share1','Grower Number','str(Shares->number,4)'  }}} )
	*/

	// FLD_RECPT = 6
	// These are posted...

	// Note on July 99 - do NOT think that Index 5 is ever used...

   // in purge - APRIL 2BFIXED
	//
	aadd( aDBFs, {'Daily','Daily Receipts (Record of Shipments)','', { ;
      { DAILY_GROWER_ORD      ,        'Grower Number'  ,          'str(Daily->number,4)+dtos(Daily->date)+Daily->depot+str(Daily->recpt,6)'}, ;
      { DAILY_DEPOT_RECEIPT_ORD     ,  'Receipt Number' ,          'Daily->depot+str(Daily->recpt,6)+Daily->RECPTLTR'}, ;
      { DAILY_DATE_ORD        ,        'Date'           ,          'dtos(Daily->date)+Daily->depot+str(Daily->recpt,6)+Daily->recptLtr'}, ;
      { DAILY_ID_ORD          ,        'ID'             ,          'str(Daily->day_uniq,8)' }, ;
      { DAILY_POST_DATE_ORD   ,        'Post by Date'   ,          'str(Daily->post_bat1,8)+dtos(Daily->date)'}, ;
      { DAILY_ADV_POST_GROWER_ORD ,    'Adv Post by Grower' ,      'str(Daily->LAST_ADVPB,8) + str(Daily->number,4)'}, ;
      { DAILY_IMPORT_DEPOT_BATCH_ORD,  'Depot Import Batch',       'Daily->depot+str(Daily->imp_bat,8)+dtos(Daily->date)'}, ;
      { DAILY_FINAL_DATE_ORD  ,        'Final by Date'  ,          'str(Daily->fin_bat,8)+dtos(Daily->date)'}, ;
		{ DAILY_IMPORT_UNIQ_BATCH_ORD,   'Unique Import Batch + ID', 'str(Daily->uniq_imbat,8)+str(Daily->day_uniq,8)'} ;
		 }} )

	// Added in Mar 2020 to be sure we can check imports
	aadd( aDBFs, {'Daily_Audit','Audit of Daily Receipts','', { ;
      { DAILYDAYAUD_DAILY_ID_ORD    ,       'Daily ID Reference',       'str(Daily_Audit->day_uniq,8)+str(Daily_Audit->dayaud_ID,8)' }, ;
      { DAILYDAYAUD_IMPORT_DEPOT_BATCH_ORD, 'Import Batch ID + Ticket', 'str(Daily_Audit->uniq_imbat,8)+Daily_Audit->depot+str(Daily_Audit->recpt,6)+Daily_Audit->RECPTLTR'}, ;
		{ DAILYDAYAUD_DEPOT_TICKET_ORD,       'Depot + Scale Ticket',     'Daily_Audit->depot+str(Daily_Audit->recpt,6)+Daily_Audit->RECPTLTR'},  ;
		{ DAILYDAYAUD_SELF_ID_ORD,            'Daily Audit (self) ID',    'str(Daily_Audit->dayaud_ID,8)'} ;
		 }} )


   // in purge
	aadd( aDBFs, {'ImpBat','Imported Batch Header','', { ;
      { IMPBAT_UNIQUE_ID_ORD,   'Unique ID of Import Session', 'str(ImpBat->UNIQ_IMBAT,8)' }, ;
      { IMPBAT_BATCH_ORD,       'Import Batch Number+Depot'  , 'str(ImpBat->imp_bat,8)+ImpBat->depot'}, ;   /* not too useful */
      { IMPBAT_DEPOT_BATCH_ORD, 'Import Depot+Batch Number'  , 'ImpBat->depot+str(ImpBat->imp_bat,8)'} ;
		 }} )

   // in purge
	aadd( aDBFs, {'PostBat','Post (Advance Payment) Batch Header','', { ;
      { POSTBAT_BATCH_ORD, 'Posting Batch Number'  , 'str(PostBat->post_bat,8)'} ;
		 }} )

   // in purge
	aadd( aDBFs, {'FinBat','Post (Final Payment) Batch Header','', { ;
      { FINBAT_BATCH_ORD, 'Posting Batch Number'  , 'str(FinBat->fin_bat,8)'} ;
		 }} )

   // in purge
	aadd( aDBFs, { 'Audit','Audit Domain','', { ;
      { AUDIT_DAY_ACCT_ORD,'Day+Acc ID','str(Audit->day_uniq,8)+str(Audit->acct_uniq,8)'}, ;
      { AUDIT_ACCT_DAY_ORD,'Acc+Day ID','str(Audit->acct_uniq,8)+str(Audit->day_uniq,8)' }}})

   // in purge
   aadd( aDBFs, {'BankRec','Bank Reconciliation','', { ;
      { BANKREC_ACCOUNTING_DATE_ORD,'Date','dtos(BankRec->acctDate)' }}} )

	// index 2 here is UNIQUE
   // in purge
	aadd( aDBFs, {'Cheque','Actual Cheques','', { ;
      {CHEQUE_GROWER_ORD     ,'Grower + Cheque', ;
                                      'str(Cheque->number,4)+str(Cheque->year,4)+series+str(Cheque->Cheque,6)'}, ;
      {CHEQUE_CHEQUE_NO_ORD  ,'Cheque number (unique)', ;
                                     'Cheque->series+str(Cheque->Cheque,6)'}, ;
      {CHEQUE_DATE_ORD       ,'Date of Cheque', ;
                                     'dtos(Cheque->date)+Cheque->series+str(Cheque->Cheque,6)'}, ;
      {CHEQUE_GROWER_DATE_ORD,'Grower and Cheque', ;
                                     'str(Cheque->number,4)+str(Cheque->year,4)+dtos(Cheque->date)'}, ;
      {CHEQUE_RECONCILE_ORD  ,'Date Cleared', ;
               'dtos(Cheque->dateClear)+Cheque->series+str(Cheque->cheque,6)' }, ;
      {CHEQUE_DATE_GROWER_ORD,'Date + Grower Ord', ;
               'dtos(Cheque->date)+str(Cheque->number,4)+Cheque->series+str(Cheque->cheque,6)' }  }} )

   // in purge
	aadd( aDBFs, {'VoidChq','Cancelled Cheques','', { ;
      {VOIDCHQ_GROWER_ORD   ,'Grower + Cheque', ;
                                     'str(VoidChq->number,4)+VoidChq->series+str(VoidChq->Cheque,6)'}, ;
      {VOIDCHQ_CHEQUE_NO_ORD,'Cheque number (unique)', ;
                                     'VoidChq->series+str(VoidChq->Cheque,6)'}, ;
      {VOIDCHQ_DATE_ORD     ,'Date of Cheque', ;
                                     'dtos(VoidChq->date)+VoidChq->series+str(VoidChq->Cheque,6)'}, ;
      {VOIDCHQ_DATE_VOID_ORD,'Date Void', ;
                'dtos(VoidChq->datevoid)+VoidChq->series+str(VoidChq->cheque,6)' }}} )

	// New for May 99
   //FLD_PRODUCT - in purge
	aadd( aDBFs, {'Product','Products','',  { ;
      {PRODUCT_PRODUCT_ORD, 'Product Order', 'Product->product'} }} )

   // in purge
	aadd( aDBFs, {'Process','Processes','',  { ;
      {PROCESS_PROCESS_ORD, 'Process Type Order', 'Process->process'} }} )

   // Added in July 2001 - in purge
	aadd( aDBFs, { 'PayGrp', 'Payment Groups',   '', { ;
       {PAYGRP_PAYGRP_ORD,'PayGrp ID','PayGrp->PayGrp'} }} )

   // Added in June 2005 - Void Tickets
   aadd( aDBFs, { 'VoidTck', 'Voided Tickets',   '', { ;
       {VOIDTCK_DATE_RECEIPT_ORD,'Voided by Ticket Date','dtos(VoidTck->date)+str(VoidTck->recpt,6)'}, ;
		 {VOIDTCK_DEPOT_RECEIPT_ORD,'Voided by Depot and Receipt','VoidTck->depot+str(VoidTck->recpt,6)'} }} )
		 
   // Added in July 2009 - Cheque Format
   aadd( aDBFs, { 'ChqFmt', 'Cheque Format Details',   '', { ;
       { CHQFMT_ID_ORD ,'Cheque Format ID','ChqFmt->id+str(ChqFmt->(recno(),6))'} }} )

   // RptCfg
   aadd( aDBFs, {'RptCfg','Report Configuration Headers', '', { ;
        { RPTCFG_RPT_ID_ORD, 'Rpt ID Order', 'RptCfg->Rpt_ID'} }} )

	// Depot - NOT in Purge
   aadd( aDBFs, {'Depot','Depot Locations','', { ;
      { DEPOT_DEPOT_ORD,'Depot','Depot->depot' }}} )

	// Tax - not in Purge
   aadd( aDBFs, {'Tax','Tax Names','', { ;
      { TAX_TAXNAME_ORD,'Tax','upper(Tax->taxname)' }}} )

	aadd( aDBFs, {'AudAcct','Link among Account entries (esp GST)','', { ;
	   {  AUDACCT_MASTER_CHILD , 'Master to Child','str(AudAcct->acct_uniq,8)+str(AudAcct->ACCT_CHILD,8)'}, ;
		{  AUDACCT_CHILD_MASTER , 'Child to Master','str(AudAcct->acct_child,8)+str(AudAcct->ACCT_UNIQ,8)'} } } )

   //FLD_VAREITY   - in purge
	aadd( aDBFs, {'Variety','Varities of the Fruit','',  { ;
      {VARIETY_VARIETY_ORD, 'Variety Order', 'Variety->variety'} }} )

	// Dec 2019
   aadd( aDBFs, {'Events','Event Logs shows critical actions','', { ;
       { EVENTS_ID_ORD   , 'Event Unique ID Ord', 'str(Events->event_ID,8)' } , ;
       { EVENTS_TYPE_ORD , 'Event Type'         , 'Events->evt_type+ str( Events->event_ID,8)' }, ;
       { EVENTS_DATE_ORD , 'Event Dates Ord'    , 'dtos(Events->qadd_date) + Events->qadd_time'}    }} )

   aadd( aDBFs, { 'CounterIDs','Counters for Unique Identifiers',     '', {}}  )


return( aDBFs )
