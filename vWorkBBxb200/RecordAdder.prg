//////////////////////////////////////////////////////////////////////
///
/// <summary>
///     RecordAdder.prg
///     Adds records to various tables that have Unique IDs.
/// </summary>
///
///
/// <remarks>
///     April 6, 2020 - Set up.  Checking over.
/// </remarks>
///
///
/// <copyright>
///  (c) 2020 by Bill Hepler and Crafted Industrial Software Ltd.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "BerryPay.ch"
#include "BSGSTD.CH"
#include "common.ch"
#include "ERRORS.CH"
#include "events.ch"
#include "INDEXORD.CH"
#include "SIGNON.CH"
#include "Unique_Fields.ch"

#define    A_THE_UNIQUE_ID         1         // Actual FIELD NAME
#define    A_THE_UNIQUE_DBF        2         // The Main Data DBF it is in - Usually Truly unique there
#define    A_THE_UNIQUE_ORDER      3         // The Index ID in Main Data DBF
#define    A_THE_UNIQUE_2ND_DBF    4         // Optional: another DBF to look to check...
#define    A_THE_UNIQUE_2ND_ORD    5         //           the Order to use in this other DBF
#define    A_THE_UNIQUE_2ND_BLOCK  6         //           the Block in the other DBF...

static aTheUniqueIDs   := { ;
	{  UF_THE_DAY_UNIQ   ,  'Daily'       ,  DAILY_ID_ORD            ,  NIL, NIL, NIL }, ;
	{  UF_THE_DAYAUD_ID  ,  'Daily_Audit' ,  DAILYDAYAUD_SELF_ID_ORD ,  NIL, NIL, NIL }, ;
	{  UF_THE_UNIQ_IMBAT ,  'ImpBat'      ,  IMPBAT_UNIQUE_ID_ORD    , 'Daily', DAILY_DATE_ORD,       { || Daily->imp_bat } }, ;
	{  UF_THE_ACCT_UNIQ  ,  'Account'     ,  ACCOUNT_LINK_ORD        ,  NIL, NIL, NIL }, ;
	{  UF_THE_POST_BAT   ,  'PostBat'     ,  POSTBAT_BATCH_ORD       , 'Daily', DAILY_FINAL_DATE_ORD, ;
	                                                                    { || max( max( Daily->post_bat1, Daily->post_bat2), Daily->post_bat3)  } }, ;
	{  UF_THE_FIN_BAT    ,  'FinBat'      ,  FINBAT_BATCH_ORD        , 'Daily', DAILY_FINAL_DATE_ORD, ;
	                                                                    { || Daily->fin_bat } }, ;
	{  UF_THE_PRICE_ID   ,  'Price'       ,  PRICE_PRICE_ID_ORD      ,  NIL, NIL, NIL } , ;
	{  UF_THE_EVENT_ID   ,  'Events'      ,  EVENTS_ID_ORD           ,  NIL, NIL, NIL }             }



function Add2Void( cReason, cFile )

   local lReturn := .f.

   if VoidTck->(addRecord())
      lReturn := .t.

      VoidTck->date    := (cFile)->date
      VoidTck->depot   := (cFile)->depot
      VoidTck->recpt   := (cFile)->recpt
      VoidTck->number  := (cFile)->number  // grower
      VoidTck->product := (cFile)->product
      VoidTck->imp_bat := (cFile)->imp_bat

		do case
		case (cFile)->(fieldPos('EDIT_DATE')) >0
			VoidTck->qed_date := (cFile)->edit_date
		case (cFile)->(fieldPos('QED_DATE')) >0
			VoidTck->qed_date := (cFile)->QED_DATE
		endcase

		if (cFile)->(fieldPos('EDIT_BY')) >0
			VoidTck->qed_op   := (cFile)->edit_by
		endif
		if (cFile)->(fieldPos('EDIT_REAS')) >0
			VoidTck->edit_reas := (cFile)->edit_reas
		endif

      VoidTck->reason    := cReason

      VoidTck->(dbCommit())

		LogAnEvent( EVT_TYPE_VOID_SCALE_TICKET, ;
		            { 'Depot='+VoidTck->depot+' Recpt#='+var2char( VoidTck->recpt )+' VOIDED', ;
                    'Ticket Voided for Grower='+var2char(VoidTck->number), ;
                    'Ticket Date='+ var2char(VoidTck->date), ;
                    'Void Date  ='+ var2char(date())+' '+time()                } )
   endif

return( lReturn )

function DeleTicket()          // Apr 29, 2020 2BCHECKED
   local lReturn := .f.

	// Failsafe
	if Daily->post_bat1 > 0 .or. Daily->post_bat2 > 0 .or. Daily->post_bat3 > 0 .or. Daily->fin_bat > 0 .or. ;
	   Daily->adv_prid1 > 0 .or. Daily->adv_prid2 > 0 .or. Daily->adv_prid3 > 0 .or. Daily->fin_pr_id > 0

		WaitHand({'Hold on a minute - we will not delete a Receipt that we think has'                 , ;
		          'had payments applied to it!  Receipt: ' +Daily->depot+'-'+var2char( Daily->recpt)   , ;
					 'Post Batches (sb 0!): ' + var2char(Daily->post_bat1) +',' + var2char( Daily->post_bat2) + ',' + var2char( Daily->post_bat3) + ',' + var2char( Daily->fin_bat > 0 )   , ;
					 'Post Pricing IDs    : ' + var2char(Daily->adv_prid1) +',' + var2char( Daily->adv_prId2) + ',' + var2char( Daily->adv_prID3) + ',' + var2char( Daily->fin_pr_id > 0 ) , ;
					 'If there are problems with this - please contact Crafted IS - 604.256.7485' })
		return( lReturn )
	endif

   if yesno({'Are you sure you want to Delete this ticket?', ;
             '', ;
             'Looking at Ticket: '+Daily->depot+lstrim(Daily->recpt)+' '+Daily->recptLtr, ;
             ' Grower '+lstrim(Daily->number), ;
             ' Dated: '+shMDY(Daily->Date) })

      if Daily->(RecLock()) .and. nAddUniqueRec( UF_THE_DAYAUD_ID, UNIQ_FILE_WE_NEED_LOCKS ) > 0
			Daily->np_Note1 := 'DELETING! '+alltrim( Daily->np_Note1 )
			
			ReplOneRec( 'Daily', 'Daily_Audit')
			Daily_Audit->(dbCommit())

			if Add2Void('Voided at Office','DAILY')
				Daily->(DeleteByFlds())
            Daily->(dbDelete())
            Daily->(dbCommit())
            lReturn := .t.
         endif
      endif
      Daily->(dbUnlock())
		Daily_Audit->(dbUnlock())
   endif

return( lReturn )

///<summary>cWhichUniqueID is from Unique_Fields.ch - need to LOCK ?</summary>
function findLastUniqOnFile( cWhichUniqueID , lNeedLocks)                       // Apr 29, 2020 2BCHECKED
	local nReturn := -1
	local n, nID
	local bLockIt
	local aDBF
   local cError := ''
   local cTargetDBF, cTargetOrd, cOldOrd
   local nCounterFldNo, nTargetFldNo

	local aError := { 'Can not add new records!', ;
						  	'You should probably exit this program-AND', ;
						  	'Shut down this PC-then after Powering up', ;
						  	'shut down a second time. This may be an wssue w/ Windows', ;
						  	'not releasing File Handles.'   }

	default lNeedLocks to .t.


	n := WhichRow2Use( cWhichUniqueID )

	if n > 0
		// Target DBF & Order are known!
		cTargetDBF := aTheUniqueIDs[ n , A_THE_UNIQUE_DBF   ]
		cTargetOrd := aTheUniqueIDs[ n , A_THE_UNIQUE_ORDER ]

		if !ensureOpen( { aTheUniqueIDs[ n , A_THE_UNIQUE_DBF  ], 'CounterIDs' } )
			aError[ 1] := 'Can NOT open '+aTheUniqueIDs[ n , A_THE_UNIQUE_DBF  ]+' or CounterIDs'
			cError     :=  APP_ERR_COUNTER_UNIQUE_1
		else

			nCounterFldNo :=  CounterIDs->(fieldPos( cWhichUniqueID ))
			nTargetFldNo  :=  (cTargetDBF)->( fieldPos( cWhichUniqueID ))

			// Testing
			if nCounterFldNo <= 0 .or. nTargetFldNo <= 0
				aError :=   {'Technical Problem-probably going to crash!', ;
								 'cWhichUniqueID='+var2char( cWhichUniqueID), , ;
								 'Does NOT exist in CounterIDs.dbf or '+cTargetDBF }
			endif

			CounterIDS->(dbGoTop())
			if CounterIDs->(eof())
				CounterIDs->(addRecord())
			endif

			if CounterIDs->(eof())
				aError[ 1] := 'First Record not added to CounterIDs'
				cError     :=  APP_ERR_COUNTER_UNIQUE_2
			else
				// Do the main stuff here:
				//    1. Lock CounterIDs                           - check Value
				//    2. Look at LastRec in DBF with NO index      - check Value
				//    3. Look at LastRec in DBF with UNIQUE index  - check Value
				//    4. Add Record to Specified File
				//    5. Replace the specified UNIQUE ID with Value+1
				//    6. Exit routine
				if lNeedLocks
					bLockIt := { || CounterIDs->(recLock( .t. )) .and. (cTargetDBF)->(recLock( .t. )) }
				else
					bLockIt := { || .t. }
				endif

				if eval( bLockIt )                                     // CounterIDs->(recLock( .t. ))
					nID      := CounterIDs->( FieldGet( nCounterFldNo ) )        // Most recent ID from Counter

					aDBF     := (cTargetDBF)->( saveDBF( ))
					cOldOrd  := (cTargetDBF)->( ordSetFocus())
					(cTargetDBF)->( ordSetFocus( cTargetOrd ))
					(cTargetDBF)->( dbGoBottom())
					nID := max( nID, (cTargetDBF)->( FieldGet( nTargetFldNo )) )   //  Check Target DBF with Unique Index ON

					(cTargetDBF)->( ordSetFocus( 0 ))
					(cTargetDBF)->( dbGoBottom())
					nID := max( nID, (cTargetDBF)->( FieldGet( nTargetFldNo )) )   // Check Target DBF last physical record
					nID := max( nID, (cTargetDBF)->( recno() ))                    // Last Record !

					nReturn := nID                                       // this is the LAST ONE
					(cTargetDBF)->(restDBF( aDBF ))
					(cTargetDBF)->(ordSetFocus( cOldOrd ))              // in case it is necessary to be in the same Order, e.g. in a Browse

				else
					aError[ 1] := 'Can NOT lock CounterIDs.DBF or '+cTargetDBF
					cError     :=  APP_ERR_COUNTER_UNIQUE_3
				endif
			endif
		endif
	endif

   if !empty( cError )
   	aError[ 1 ] += (' for '+ cWhichUniqueID)
		appError( cError, aError )
   endif

return( nReturn)

///<summary>The 1st Parameter should be UF_THE_DAY_UNIQ etc... </summary>
function nAddUniqueRec( cWhichUniqueID, lNeedLocks )                       // Apr 29, 2020 2BCHECKED
	local nReturn := -1 //  error
	local aError := { 'Can not add new records!', ;
						   'You should probably exit this program-AND', ;
							'Shut down this PC-then after Powering up', ;
							'shut down a second time (This may be an wssue w/ Windows', ;
							'not releasing File Handles.'   }
	local cError    := ''
	local cTargetDBF
   local nCounterFldNo, nTargetFldNo
	local n
	local nID := 0

	default lNeedLocks to UNIQ_FILE_WE_NEED_LOCKS

	n := WhichRow2Use( cWhichUniqueID )

	if n > 0
		// Do the main stuff here:
		//    1. Lock CounterIDs                           - check Value
		//    2. Look at LastRec in DBF with NO index      - check Value - also get last recno()
		//    3. Look at LastRec in DBF with UNIQUE index  - check Value
		//    4. Add Record to Specified File
		//    5. Replace the specified UNIQUE ID with Value+1
		//    6. Exit routine

		nID := findLastUniqOnFile( cWhichUniqueID, lNeedLocks )

		if nID >= 0
			cTargetDBF := aTheUniqueIDs[ n , A_THE_UNIQUE_DBF ]

			nCounterFldNo :=  CounterIDs->(fieldPos( cWhichUniqueID ) )                 // this SHOULD NOT fail
			nTargetFldNo  :=  (cTargetDBF)->( fieldPos( cWhichUniqueID ))

			// Testing
			if nCounterFldNo <= 0 .or. nTargetFldNo <= 0
				cError     :=  APP_ERR_COUNTER_UNIQUE_4
				aError := {'Utterly UnExpected Technical Problem-probably going to crash !!', ;
							  'cWhichUniqueID='+var2char( cWhichUniqueID), ;
							  'Does NOT exist in CounterIDs.dbf or '+cTargetDBF}

			else
				if (cTargetDBF)->(addRecord())   // consider Lock Status
					nID++
					nReturn := nID

					if upper(cTargetDBF) ==  'DAILY_AUDIT'
						if (cTargetDBF)->(fieldPos('AUD_DATE')) > 0 .and. (cTargetDBF)->(fieldPos('AUD_TIME')) > 0
							(cTargetDBF)->aud_date := date()
							(cTargetDBF)->aud_time := time()
							(cTargetDBF)->aud_by   := soValue( SO_INIT )
						endif
					endif

					CounterIDs->(   fieldPut( nCounterFldNo, nID ) )     // writes the Dataout
					CounterIDs->(   dbCommit() )                 // force commit of data & unlcok so more other users can work

               if lNeedLocks
						CounterIDs->(   dbRunLock() )
               endif

					(cTargetDBF)->( fieldPut( nTargetFldNo, nID ) )     // writes the Dataout - we do NOT need to commit I think as the Counter Record has data
					(cTargetDBF)->( dbCommit())                         // BUT, we commit anyway, just to be sure...a little slower, but so what.
				else
					aError[ 1] := 'Can NOT add Record to '+cTargetDbf+'.DBF'
					cError     :=  APP_ERR_COUNTER_UNIQUE_5
				endif
			endif
		endif
	else
		aError[ 1] := 'Can NOT lock CounterIDs.DBF'
		cError     :=  APP_ERR_COUNTER_UNIQUE_6
	endif

	if !empty( cError )
		aError[1] += (' for '+var2char( cWhichUniqueID ))
		AppError( cError, aError )
	endif

return( nReturn )    // the ID is returned

static function WhichRow2Use( cWhichUniqueID )
	local n
	local nReturn := 0

	if !(valType( cWhichUniqueID ) == 'C')
		appError( APP_ERR_COUNTER_UNIQUE_7 , {'Unexpected Type for cWhichUniqueID - Type='+ valType( cWhichUniqueID), ;
		                                      'Value='+var2char( cWhichUniqueID), ;
														  'Probably going to Crash SOON - please note this' })
	endif

	for n := 1 to len( aTheUniqueIDs )
		if cWhichUniqueID == aTheUniqueIDs[ n , A_THE_UNIQUE_ID  ]
			nReturn := n
			exit
		endif
	next

   if nReturn == 0
		appError( APP_ERR_COUNTER_UNIQUE_8, ;
                 { 'Can NOT Find the Counter '+cWhichUniqueID  , ;
                   '*** This is almost certainly a BUG ***'    , ;
                   'Call Crafted Industrial at 604-256-7485'   , ;
                   'and give the Error Code-they will need to' , ;
                   'Look at Application Error Log ! '                } )
   endif

return( nReturn )

