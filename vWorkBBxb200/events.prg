// Events.prg
// Aug 2014, 2019
// written by Bill Hepler
//    Adds Entries to the Event Log
//    Moved from Waste Management related to Berry

// (c) 2014, 2019 by Crafted Industrial Software Ltd.


#include 'bsgstd.ch'
#include 'common.ch'
#include 'errors.ch'
#include 'field.ch'
#include 'indexord.ch'
#include 'inkey.ch'
#include 'printer.ch'
#include 'rpt.ch'
#include 'unique_fields.ch'
#include 'window.ch'

// do not actually refernce Events.ch !

function LogAnEvent( cEventType, aNote )
	local n
	local nFldNo
	local c

	default cEventType to ''
	default aNote to {}

	if !ensureOpen( {'Events','CounterIDs'} )
		appError( APP_ERR_CAN_NOT_OPEN_EVENT_LOG1, {'Can NOT open Events.dbf the Events Log!', ;
		   'This is not very good'})
		return( nil )
	endif

	if empty( cEventType)
		appError( APP_ERR_EMPTY_EVENT_LOG_TYPE, { 'No Data in Event Log Type'})
	endif

	// if Events->(addRecord())
	if nAddUniqueRec( UF_THE_EVENT_ID, UNIQ_FILE_WE_NEED_LOCKS  ) > 0
		Events->EVT_TYPE  := cEventType
		// Events->NOTE      := cNote
		Events->COMP_NAME := GetEnv('COMPUTERNAME')
		Events->WIN_USER  := GetEnv('USERNAME')
		Events->SESSIONID := GetEnv('SESSIONNAME')    // Especially by Terminal Server
		Events->prg       := AppName( .f. )           // put in by Scale or who ever (EXE NAME)

		if valtype( aNote )=='A'
			for n := 1 to min( len( aNote ), 8 )
				c                            := 'NOTE'+str( n, 1)
				nFldNo                       := Events->(fieldPos( c ))
				Events->(fieldPut( nFldNo, aNote[ n ] ))
			next
		else
			Events->Note1 := var2char( aNote )
		endif

		Events->(dbCommit())
		Events->(dbUnLock())
	endif

return( nil )

function TheEventsList()
	local getlist := {}
	local dDate1, dDate2
	local aW
	local nChoice

	dDate1 := date() - 10
	dDate2 := date()

	if !openfile({'Events'},DB_SHARED)
		return( nil )
	endif

	create window at 7,14,13,65 title 'Audit Report of Events' to aW
	display window aW
	set cursor on

	in window aW @ 2,21 winsay 'Show events like imports,'
	in window aW @ 3,21 winsay 'cheque runs, voids and'
	in window aW @ 4,21 winsay 'similar events.'

	do while .t.
		in window aW @ 2,2 winsay 'From' winget dDate1 picture "@D" ;
			valid !empty(dDate1) ;
			get_message 'Starting Date of Audit Report (remember + - on NumPad)'

		in window aW @ 3,2 winsay ' to ' winget dDate2 picture "@D" ;
			valid !empty(dDate2) ;
			get_message 'Ending Date of Audit Report (+ - on NumPad adjust date)'
		read

		do case
		case lastkey() == K_ESC
			exit
		case dDate2 < dDate2
			loop
		otherwise
			nChoice := thinChoice({'Print','Browse','Cancel'})
			if nChoice == 3 .or. nChoice == 0
				loop
			endif

			Events->( ordSetFocus( EVENTS_DATE_ORD))
			Events->(dbSeek(dtos(dDate1),SOFTSEEK))
			if Events->(eof()) .or. Events->qadd_date > dDate2
            if !yesno({'We can not find any significant accounting events in this date range.', ;
						'Do you wish to proceed anyway?'})
					loop
				endif
			endif

			do case
			case nChoice == 1

				if selectPrn('ACC_EVENTS.TXT')

					PRINT_ON RPT_OVERWRITE

					prnAccEventsRpt( dDate1,dDate2 )

					PRINT_OFF RPT_COMPLETE_EJECT
				endif
			case nChoice == 2
				if Events->(eof())
					if Events->(bof())
						WaitInfo({'At start of File'})
						loop
					else
						Events->(dbSkip(-1))
					endif
				endif
				dbEdit2(.f., 'Events')
			endcase

		endcase
	enddo
	kill window aW
	close databases
return( nil)


function PrnAccEventsRpt(  dFrom, dTo  )
   local aScrn
	local aRpt := {}

   aScrn := msgLine('Looking at Event Log..')
	SetRptDef( aRpt )

	Events->( ordSetFocus( EVENTS_DATE_ORD))
	Events->(dbSeek(dtos(dFrom),SOFTSEEK))

	gRptInitHead()
	gRptGetSetHead( RPT_HEAD_PRINT_GRAND_TOTAL, .f. )
	gRptGetSetHead( RPT_HEAD_WHILE_CONDITION, ;
	  { || Events->qadd_Date <= dTo .and. !Events->(eof()) })

	gRptGetSetHead( RPT_HEAD_TITLE, { 'Event Log from '+ShMDY(dFrom)+' to '+ShMDY(dTo) } )

	gRptPrintSize( aRpt,0)

	Events->(gRptPrinter( aRpt ))

	nuQprnOut('')
	nuQprnOut('End of Report')
	rest_scr( aScrn )

return( nil )

static function SetRptDef( aRpt )

   aadd( aRpt, ;
         { 'Date'    ,{|| shMdy( Events->qadd_date )  },"C", 012, 000, .t., .f., ;
	  		'Date'} )

	aadd( aRpt, ;
         { 'Time'    ,{|| Events->qadd_time   },"C", 8, 000, .t., .f., ;
	  		'Time'} )

	aadd( aRpt, ;
      { 'Oper'    ,{|| Events->qadd_op  },"C", 010, 000, .t., .f., ;
  		'Craft Weigh Operator logged on'} )

	aadd( aRpt, ;
      { 'PRG'    ,{|| Events->prg  },"C", 016, 000, .t., .f., ;
  		'Usually cisBerryPay.exe...'} )

	aadd( aRpt, ;
      { 'Evt Type',  { || Events->evt_type }, ;
			  'C', FLD_EVENT, 000, .t., .f., 'Event Description'})

	aadd( aRpt, ;
      { 'Notes-First 4',  {   ;
             { || Events->note1 }, ;
				 { || Events->note2 }, ;
				 { || Events->note3 }, ;
				 { || Events->note4 } }, ;
			  'M', FLD_NOTE, 000, .t., .f., 'First 4 Details'})

   aadd( aRpt, ;
         { ''    ,{|| ''   },"C", 021, 000, .t., .f., ;
	  		'Indent for Band 2', 2 } )

   aadd( aRpt, ;
         { 'WinUser'    ,{|| Events->win_user   },"C", 027, 000, .f., .f., ;
	  		'Windows User ID (logged in as)', 2 } )

   aadd( aRpt, ;
         { 'Computer'    ,{|| Events->comp_name   },"C", 020, 000, .f., .f., ;
	  		'Computer Name', 2 } )

   aadd( aRpt, ;
         { 'Session ID'    ,{|| Events->sessionID   },"C", 020, 000, .f., .f., ;
	  		'Session ID', 2 } )

	aadd( aRpt, ;
      { 'Notes-Last 4',  {   ;
             { || Events->note1 }, ;
				 { || Events->note2 }, ;
				 { || Events->note3 }, ;
				 { || Events->note4 } }, ;
			  'M', FLD_NOTE, 000, .f., .f., 'Last 4 Details'})


return( aRpt )



