// --------------------------------------------------------------------
//  Application: Berry Payment System
//  Description: For Setting Up Processes   (IQF, FRESH ETC)
//               Must correspond to the SCALE System.
//
//   June 2007 some REVISIONS
//   Apr  2019 Proecess Grade names added.
//
//    File Name: PROCESS.PRG
//       Author: Bill Hepler
// Date created: 12-11-94
// Copyright: (c) 1994, 2014, 2019 by Bill Hepler & Crafted Industrial Software Ltd.
// --------------------------------------------------------------

#include "BerryPay.ch"
#include "bsgstd.ch"
#include "common.ch"
#include "field.ch"
#include "indexord.ch"
#include "inkey.ch"
#include "sysvalue.ch"
#include "valid.ch"
#include "window.ch"

function Process(  )
	local cProcess, getList :={}, aW

	if !openfile({'PROCESS'}, DB_SHARED )
		close databases
		return( nil )
	endif

	create window at 6,15,16,64 title 'Processes' to aW
	display window aW
	set cursor on

	in window aW @ 4,2 winsay 'Use this screen to set the Process types'
	in window aW @ 5,2 winsay 'used.  This can be used to determine pricing.'
	in window aW @ 6,2 winsay 'This must correlate with the scale system.'

   if sysValue( SYS_USE_PROCESS_GRADE_NAMES  )
		in window aW @ 8,2 winsay 'You may name each Grade# for all process types'
   else
		in window aW @ 8,2 winsay 'You are set NOT to use Names for Grades!'
      in window aW @ 9,2 winsay 'This feature is controlled in the System'
      in window aW @10,2 winsay 'Settings Menu.'
   endif


	cProcess := space(FLD_PROCESS)
	do while .t.
		//                        'Description'
		in window aW @ 2,2 winsay 'Process ID ' winget cProcess ;
			 picture "@!" ;
			lookup( LU_PROCESS_TYPE, 'Enter Process ID - [F5] to Browse')
		read

		do case
		case lastkey()==K_ESC
			exit
		case ValidTest(V_PROCESS_TYPE,cProcess,VT_NO_MESSAGE)
			getScreen(.f.)
		case empty(cProcess)
			waitInfo({'Process ID can not be blank'})
		otherwise
			// Aug 18-98
			if yesno({'Add Process Type '+cProcess+' ?'})
				if Process->(addRecord())
					Process->process := cProcess
					Process->(dbCommit())
					getScreen( .t. )
				endif
			endif
		endcase
	enddo

	kill window aW
	close databases

return( nil )

static function getScreen( lRead )
	local nChoice
	local aWin

	if !Process->(recLock())
		return( nil )
	endif

	create window at 5,14,16,67 ;
			title 'Edit Process Type' to aWin

	display window aWin
	set cursor on

	do while .t.
		GetStuffed( lRead, aWin )
		lRead := .f.

		nChoice := VeryThinChoice( {'View','Edit','Delete','X - eXit'})

		do case
		case nChoice==0 .or. nChoice==4
			exit
		case nChoice==1
			thinWait()
			loop
		case nChoice==2
			lRead := .t.
		case nChoice==3
			if YesNo({'Are you Sure you want to Delete This?'})
				Process->(DeleteRecord())
				exit
			endif
		endcase
	enddo
	kill window aWin
	Process->(dbUnlock())
return( nil )

static function getStuffed( lRead, aWin )
	local getList := {}

	do while .t.
      PutName(aWin,4,20,LU_PROCESS_CLASS,Process->proc_class)

      in window aWin @  2,2 winsay 'Process ID ' winget Process->process ;
			 picture "@!"
		getList := {}

		in window aWin @  3,2 winsay "Description" winget Process->Desc  ;
			get_message 'Enter a Description of this Process Type'

      in window aWin @  4,2 winsay 'Process Class' winget process->proc_class ;
         picture '9' valid ;
          validTest( V_PROCESS_CLASS, Process->proc_class, VT_BROWSE) .and. ;
           PutName(aWin,4,20,LU_PROCESS_CLASS,Process->proc_class)  ;
         lookup( LU_PROCESS_CLASS, ;
         'Enter the Process Class for this process - used for Reporting')

      in window aWin @  5,2 winsay 'Default Grade' winget process->def_grade ;
         picture '9' valid Process->def_grade <= MAX_NO_OF_GRADES ;
         get_message 'Enter the default grade for this process or leave as 0'

      in window aWin @  6,2 winsay 'Grade can be used for pricing & reporting'
      in window aWin @  7,2 winsay 'Fill this in if GRADE# is NOT assigned at Scale'

      if sysValue( SYS_USE_PROCESS_GRADE_NAMES  )
			in window aWin @  9,2 winsay "Grade 1 Name" winget Process->GRADE_N1  ;
				get_message 'Description of this Grade if using - can show on some reports'
			in window aWin @ 10,2 winsay "Grade 2 Name" winget Process->GRADE_N2  ;
				get_message 'Description of this Grade if using - can show on some reports'
			in window aWin @ 11,2 winsay "Grade 3 Name" winget Process->GRADE_N3  ;
				get_message 'Description of this Grade if using - can show on some reports'
      else
			in window aWin @ 10,2 winsay "Names for specific grades not configured"
      endif

		if lRead
			read

         if !validTest( V_PROCESS_CLASS, Process->proc_class, VT_MESSAGE )
            Process->proc_class := PROCESS_CLASS_OTHER
         endif

         Process->(dbCommit())
		else
			getList :={}
		endif
		exit
	enddo

return( nil )


