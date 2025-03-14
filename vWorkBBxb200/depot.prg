//--------------------------------------------------------------------------
//   Application: Berry Payment System
//   Description: For Setting Up Payment Groups
//
//     File Name: Depot.prg
//        Author: Bill Hepler
//  Date created: 07-08-2013
//  Time created: 10:50 pm
//     Copyright: (c) 2013 by Bill Hepler
//--------------------------------------------------------------------------

#include "window.ch"
#include "indexord.ch"
#include "valid.ch"
#include "field.ch"
#include "bsgstd.ch"
#include "common.ch"
#include "inkey.ch"
#include "BerryPay.ch"

function MultiDepot()
	local lReturn := .f.

	EnsureOpen('Depot')
	if Depot->(LastRec()) >= 2
		lReturn := .t.
	endif

return( lReturn )

function DepotSetup(  )
	local cDepot, getList :={}, aW

	if !openfile({'DEPOT'}, DB_SHARED )
		close databases
		return( nil )
	endif

	create window at 6,16,13,64 title 'Depots' to aW
	display window aW
	set cursor on

	in window aW @ 4,2 winsay 'Use this screen to set up Receiving Depots'


	cDepot := space(FLD_DEPOT)
	do while .t.
		//                        'Description '
		in window aW @ 2,2 winsay 'Depot ID    ' winget cDepot ;
			 picture "@!" ;
			lookup( LU_DEPOT, 'Enter Depot ID - [F5] to Browse')
		read

		do case
		case lastkey()==K_ESC
			exit
		case ValidTest(V_DEPOT,cDepot,VT_NO_MESSAGE)
			getScreen(.f.)
		case empty(cDepot)
			waitInfo({'Depot ID can not be blank'})
		otherwise
			if yesno({'Add receiving Depot '+cDepot+' ?'})
				if Depot->(addRecord())
					Depot->Depot := cDepot
					Depot->(dbCommit())
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

	if !Depot->(recLock())
		return( nil )
	endif

	create window at 5,10,14,70 ;
			title 'Edit Receving Depot' to aWin

	display window aWin
	set cursor on

	do while .t.
		GetStuffed( lRead, aWin )
		lRead := .f.

		nChoice := thinChoice( {'View','Edit','Delete','X - eXit'})

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
				Depot->(DeleteRecord())
				exit
			endif
		endcase
	enddo
	kill window aWin
	Depot->(dbUnlock())
return( nil )

static function getStuffed( lRead, aWin )
	local getList := {}

	do while .t.
		in window aWin @ 2,2 winsay 'Depot ID    ' +' ' + Depot->depot

		in window aWin @ 3,2 winsay "Description " winget Depot->DepotName  ;
		  get_message 'Enter a Description of this Depot'

		if lRead
			read

			Depot->(dbCommit())
		else
			getList :={}
		endif
		exit
	enddo

return( nil )


























