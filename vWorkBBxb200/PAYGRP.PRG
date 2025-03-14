* ÚÄ Program ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ?
* ? Application: Berry Payment System                                       ?
* ? Description: For Setting Up Payment Groups                              ?
* ?                                                                         ?
* ?   File Name: PayGrp.PRG                                                 ?
* ?      Author: Bill Hepler                                                ?
* ?Date created: 07-21-2001            Date updated:  Jul 2001              ?
* ?Time created: 10:55:00am            Time updated: þ10:55:00am            ?
* ?   Copyright: (c) 2001 by Bill Hepler & Crafted Industrial Software Ltd.         ?
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

#include "window.ch"
#include "indexord.ch"
#include "valid.ch"
#include "field.ch"
#include "bsgstd.ch"
#include "common.ch"
#include "inkey.ch"
#include "BerryPay.ch"

function PayGrp(  )
	local cPayGrp, getList :={}, aW

	if !openfile({'PAYGRP','GROWER'}, DB_SHARED )
		close databases
		return( nil )
	endif

	create window at 6,16,13,64 title 'Payment Groups' to aW
	display window aW
	set cursor on

	in window aW @ 4,2 winsay 'Use this screen to set Payment Groups'
	in window aW @ 5,2 winsay 'to pay sets of Growers at one time.'
	in window aW @ 6,2 winsay 'Usually this should correlate with the'
	in window aW @ 7,2 winsay 'Price Level of the Cusotmers.'


	cPayGrp := space(FLD_PAYGRP)
	do while .t.
		//                        'Description '
		in window aW @ 2,2 winsay 'Pay Group ID' winget cPayGrp ;
			 picture "@!" ;
			lookup( LU_PAYGRP, 'Enter Payment Group ID - [F5] to Browse')
		read

		do case
		case lastkey()==K_ESC
			exit
		case ValidTest(V_PAYGRP,cPayGrp,VT_NO_MESSAGE)
			getScreen(.f.)
		case empty(cPayGrp)
			waitInfo({'Payment Group ID can not be blank'})
		otherwise
			if yesno({'Add Payment Group '+cPayGrp+' ?'})
				if PayGrp->(addRecord())
					PayGrp->PayGrp := cPayGrp
					PayGrp->(dbCommit())
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

	if !PayGrp->(recLock())
		return( nil )
	endif

	create window at 5,10,14,70 ;
			title 'Edit Payment Group' to aWin

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
				PayGrp->(DeleteRecord())
				exit
			endif
		endcase
	enddo
	kill window aWin
	PayGrp->(dbUnlock())
return( nil )

static function getStuffed( lRead, aWin )
	local getList := {}
	local n
	local aRay := {}
	local aMsg

	aMsg := msgLine("Counting the growers here....")

   Grower->(OrdSetFocus( GROWER_PAYGRP_NUMBER_ORD ))
	Grower->(dbSeek( PayGrp->PayGrp, HARDSEEK))
	n := 0
	do while !Grower->(eof()) .and. Grower->payGrp==PayGrp->PayGrp
		aadd( aRay, Grower->name)
		Grower->(dbSkip())
	enddo

	in window aWin @ 6,2 winsay space(45)
	in window aWin @ 7,2 winsay space(45)
	in window aWin @ 8,2 winsay space(45)
	in window aWin @ 9,2 winsay space(45)

	rest_scr( aMsg )
	do case
	case len(aRay) == 0
		in window aWin @ 6,2 winsay 'No Growers are in this Group'
	case len(aRay) == 1
		in window aWin @ 6,2 winsay 'Only one Grower in this Group'
		in window aWin @ 7,2 winsay ' '+aRay[1]
	otherwise
		in window aWin @ 6,2 winsay 'There are '+lStrim(len(aRay))+ ;
			 ' growers in this group'
		for n := 1 to 3
			if len(aRay) < n
				exit
			endif
			in window aWin @ 6+n,3 winsay substr(aRay[n],1,20)
		next
		for n := 4 to 6
			if len(aRay) < n
				exit
			endif
			in window aWin @ 3+n,33 winsay substr(aRay[n],1,20)
		next
	endcase

	do while .t.
		in window aWin @ 2,2 winsay 'Pay Group ID' winget PayGrp->PayGrp ;
			 picture "@!"
		getList := {}

		in window aWin @ 3,2 winsay "Description " winget PayGrp->Desc  ;
		  get_message 'Enter a Description of this Payment Group'
		in window aWin @ 4,2 winsay "Default Price Level" ;
			winget PayGrp->def_prlvl  ;
			valid PayGrp->def_prlvl <= MAX_NO_OF_PRICE_LEVELS ;
		  get_message ;
		  'Expected Price Level for members of this Group'

		if lRead
			read

			PayGrp->(dbCommit())
		else
			getList :={}
		endif
		exit
	enddo

return( nil )


























