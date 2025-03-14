//////////////////////////////////////////////////////////////////////
///
/// <summary>
///   Views audit trail of changes to Receipts.  Note that NOT all
///   changes to Receipts are shown here.  Its mainly edits, and
///   also sometimes "a moment in time"
///
///   Since 2020 - all import are written in here (including tickets voided
///   at the scale that were received in Download fromt the Scale.
///   Most Manual Edits of the tickets are also captured.  As of May 2020
///   we are NOT capturing the changes which happen to Receipts when payments
///   are made.  However, we do permit a general - "grab the state of all receipts"
///   to be made.  This was for programming simplicity etc.
///
/// </summary>
///
///
/// <remarks>
/// </remarks>
///
///
/// <copyright>
///  (c) 2020 by Bill Hepler & Crafted Industrial Software Ltd.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "BSGSTD.CH"
#include "common.ch"
#include "FIELD.CH"
#include "INDEXORD.CH"
#include "inkey.ch"
#include "std.ch"
#include "SYSVALUE.CH"
#include "Unique_Fields.ch"
#include "VALID.CH"
#include "WINDOW.CH"

static dAuditDate    := NIL
static cAuditTime    := ''

function vuRecptAudit()
	local aW
   local cDepot     := space( FLD_DEPOT )
   local nReceipt   := 0
   local cLetter    := space( 1 )
   local getList    := {}
   local lAdd2Audit := .f.
   local nTimes     := 0

   if sysValue( SYS_CURRENT_YEAR ) < 2020
   	WaitInfo({"This feature is MEANINGLESS for Crop Years before 2020 !"})
      return( nil )
   endif

   if !YesNo({"This screen requires technical expertise to interpret.", ;
             "It is intended to help Crafted Industrial to locate problems.", ;
             "It shows the Original State of Receipts, and some of the", ;
             "changes that were made to tickets.", ;
             "","Are you sure you want to use this screen?"})
      return( nil )
   endif

  	if !openMainStuff(DB_SHARED)
		close databases
   endif

	initAuditStatics()

	if Daily->(lastRec()) == 0
   	WaitInfo({'No Ticket Audit Records have been written yet', ;
                'This set of features is ONLY available for the', ;
                'Crop Year of 2020 and later !!','', ;
                'We will exit this screen as there is nothing to see.'})
   	close databases
   	return( nil )
   endif

	myBsgScreen( 'View the Audit Trail of Berry Receipt Edits' )
	Depot->(dbGoTop())
	cDepot := Depot->depot

	create window at 7,9,18,74 title 'View the Receipt Audit Trail' to aW
	display window aW
   set cursor on

	in window aW @ 5, 2 winsay 'Enter the Receipt Number you would like to check'

   do while .t.
		in window aW @ 2, 2 winsay 'Depot/Site' winget cDepot picture '@!' ;
		  when PutName(  aW, 2, 17, LU_DEPOT, cDepot ) ;
		  valid PutName( aW, 2, 17, LU_DEPOT, cDepot ) ;
		 LOOKUP( LU_DEPOT, '[F5] to Browse depots on file')

		in window aW @ 3, 2 winsay 'Receipt No' winget nReceipt ;
		 picture numBlankPic(FLD_RECPT) ;
		 get_message 'Enter Receipt # to look for'

		in window aW @ 4, 2 winsay 'Recpt Letter' winget cLetter ;
		 get_message 'Enter Receipt Letter if applicable (usually leave this blank)'

		in window aW @ 6, 2 winsay 'Update Audit Table' winget lAdd2Audit picture 'Y' ;
		 get_message 'Sometimes this makes it easier to check over the audit trail'
		in window aW @ 7, 3 winsay 'This will add a record that shows the current data'
		in window aW @ 8, 3 winsay 'in each receipt. This does not hurt anything to do'
		in window aW @ 9, 3 winsay 'but does make the audit trail file bigger'
		read

      if lastkey() == K_ESC
			exit
      endif

      if lAdd2Audit
      	if nTimes >= 1
         	if !Yesno({'You have added to the audit trail recently-', ;
                      'are you REALLY SURE you want to do this again?'})
               loop
            endif
         endif
			if CreateAud4AllRecpts(  )
         	nTimes ++
         endif
      	lAdd2Audit := .f.
      endif


     	Daily_Audit->(ordSetFocus( DAILYDAYAUD_DEPOT_TICKET_ORD ))

      do case
      case !empty( nReceipt)
         Daily_Audit->(dbSeek( cDepot + str( nReceipt, FLD_RECPT ) + cLetter, SOFTSEEK ))
      case !empty( cDepot )
         Daily_Audit->(dbSeek( cDepot, SOFTSEEK ))
      otherwise
		   Daily_Audit->(dbGoTop())
      endcase

      if Daily_Audit->(eof())
      	if !Daily_Audit->(bof())
         	Daily_Audit->( dbSkip( -1 ))
         endif
      endif

      if Daily_Audit->(eof())
      	WaitHand({'Hm...we are confused - going to top of Audit File'})
         Daily->(dbGoTop())
		endif

      if Daily_Audit->(eof())
      	WaitInfo({'Maybe indexes are corrupted - we can not do this...'})
         exit
      endif

      // DO NOT allow EDIT - table is already open.
		Daily_Audit->(dbEdit2( .f., 'Daily_Audit', .t. ))

   enddo

   close databases
   kill window aW

return( nil )


function CreateAud4AllRecpts(  )
	local aMsg := {}
   local lReturn := .f.
   local n

   initAuditStatics()

   if !ensureOpen({'Daily','Daily_Audit','CounterIDS'})
   	return( lReturn )
   endif

	if !empty( dAuditDate )
   	aMsg := {'You updated the Audit Trail on '+shMdy( dAuditDate )+' '+ cAuditTime, ;
               'You probably do NOT need to do this again!','' }
	endif


   aadd( aMsg,'Do you wish to ADD Audit Records to the Receipts Audit File?')
   aadd( aMsg,' this may take a few minutes...' )

   if yesno( aMsg )
   	if  Daily->(fileLock( .t.)) .and. Daily_Audit->(fileLock( .t. )) .and. CounterIDs->(fileLock( .t. ))

         Daily->( ordSetFocus( 0 ))
         Daily->( dbGoTop())
         MsgLine('Adding new Audit Records...')
         n := 0
         do while !Daily->(eof())
            n++
            showProg( n )

            nAddUniqueRec( UF_THE_DAYAUD_ID, UNIQ_FILE_DO_NOT_NEED_LOCKS  )
            ReplOneRec('Daily', 'Daily_Audit' )
            Daily_Audit->np_note1 := 'Aud:'+shMdy( date())+'_'+substr(Time(),5)+' '+Daily_Audit->np_note1

            Daily->(dbSkip())
         enddo

         dAuditDate   := date()
         cAuditTime   := time()
			lReturn      := .t.

         WaitInfo({'Added to Audit Fille at '+shMdy( dAuditDate)+' '+ cAuditTime, ;
                   'We added '+var2char( n) + ' records' })

      endif
   endif
	Daily->(dbUnlock())
   Daily_Audit->( dbUnLock())
   CounterIDS->( dbUnlock())

return( lReturn )

static function initAuditStatics()

	if valType( dAuditDate ) <> 'D'
   	dAuditDate := ctod('')
   endif

   if valType( cAuditTime ) <> 'C'
   	cAuditTime := ''
   endif

return( nil )
