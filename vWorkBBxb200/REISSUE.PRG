//---------------------------------------------------------------------------
//  Application: BerryPayment System
//  Description: Reissue a Cheque (it Voids Old One and creates a New One
//
//  File Name: REISSUE.PRG
//     Author: Bill Hepler
// Date created: 05-30-95              Date updated: 05-30-95
// Time created: 04:46:53pm            Time updated: 04:46:53pm
// Copyright: (c) 1995, 2021 by Bill Hepler & Crafted Industrial Software Ltd.
// --------------------------------------------------------------------------


#include 'common.ch'
#include 'window.ch'
#include 'bsgstd.ch'
#include 'printer.ch'
#include 'BerryPay.ch'
#include 'inkey.ch'
#include 'sysvalue.ch'
#include 'valid.ch'
#include 'account.ch'
#include "radio.ch"
#include "field.ch"
#include "indexord.ch"


static dReissue := NIL   // get rid of compiler warning

function ReissueCheque()
	local getList := {}
	local nGrower, cSeries, nCheque
	local aWin

	if !openfile({'Grower', 'Product','Process', ;
			'Account','Cheque','BankRec','Audit','Daily','VoidChq'}, ;
	  DB_EXCLUSIVE)
		close databases
		return( nil )
	endif

	nGrower := 0
	cSeries := space(FLD_SERIES)
	nCheque := 0

	myBsgScreen( 'Reissue Cheques' )

	create window at 5,7,21,74 title 'Select a Cheque to Reissue' to aWin
	display window aWin
	set cursor on

	do while .t.
		msgLine('[Esc] to Exit - Enter a Cheque to Reissue')

		in window aWin @ 5,2  winsay 'This screen allows you to REISSUE a cheque. This option'
      in window aWin @ 6,2  winsay 'is intended to be used if you need to re-issue a cheque'
		in window aWin @ 7,2  winsay 'that was lost or damaged, or the grower name has changed.'

		in window aWin @ 9,2  winsay 'When you select a cheque to reissue the computer resets'
      in window aWin @10,2  winsay 'the accounting records relating to the old cheque to'
		in window aWin @11,2  winsay 'relate to the new cheque.  It also makes an entry in the'
      in window aWin @12,2  winsay 'void/cancel file.'

		in window aWin @14,2  winsay 'Enter either a grower # or the cheque number and the'
		in window aWin @15,2  winsay 'computer will show a list of cheques you can Re-Issue.'

		in window aWin @ 2,2  winsay 'Grower' winget nGrower ;
		 picture NumBlankPic( FLD_GROWER ) ;
		 LOOKUP( LU_GROWER, 'Enter a Grower ID here, if you wish to browse by Grower')
		in window aWin @ 3,2  winsay 'Cheque' winget cSeries ;
		 picture '@!' ;
		 get_message "Enter the Cheque Series - currently it is " + ;
		 sysValue(SYS_CDN_CHEQUE_SERIES)+', '+sysValue(SYS_US_CHEQUE_SERIES)
		in window aWin @ 3,10+FLD_SERIES winget nCheque picture ;
		 numBlankPic(FLD_CHEQUE)

		read

		do case
		case lastkey()==K_ESC
			exit
		case !empty(nGrower)
         Cheque->(OrdSetFocus(CHEQUE_GROWER_ORD))
			Cheque->(dbSeek( str(nGrower,FLD_GROWER), SOFTSEEK))
		case !empty(nCheque) .or. !empty(cSeries)
         Cheque->(OrdSetFocus(CHEQUE_CHEQUE_NO_ORD))
			Cheque->(dbSeek(cSeries + str(nCheque, FLD_CHEQUE),SOFTSEEK))
		otherwise
			waitExclam({'Hey - enter some data!'})
			loop
		endcase

		if CheqBrowse( nil, .t. )
			// we hit enter

			if Cheque->amount >0 .and. empty(Cheque->dateClear)
				if Cheque->void
					if !yesno({'This cheque has been marked as void.', ;
							 'However, you can reIssue it', ;
							 'Do you wish to reIssue this cheque?'})
						loop
               else
               	if !yesNo({'Are you sure you want to do this?', ;
                             'you should call Bill before you do this.'})
                  	loop
                  endif
					endif
				endif

				if DoWeReissue()
					VoidOrReissue( Cheque->series, Cheque->cheque, dReissue, .t. )
				endif
			else
				waitHand({'Cheque can not be Reissued!', ;
                      'It has either been cleared or is a negative amount', ;
                      'or some other issue.'    })
				loop
			endif
		endif
	enddo
	kill window aWin
	close databases
return( nil )

static function DoWeReissue()
	local aWin
	local lReissue := .f., lReturn := .f.
	local getList :={}

	dReissue := date()

	create window at 5,14,17,66 title 'Reissue this Cheque' to aWin
	display window aWin
	set cursor on

	in window aWin @ 10,2 winsay ;
		'Reissuing a cheque will automatically void the OLD'
	in window aWin @ 11,2 winsay ;
		'cheque and reissue a New Cheque for the amount.'

	msgLine('Do you want to Reissue this cheque?')

	in window aWin @ 2, 2 winsay 'Cheque Number: '+ Cheque->(PrettyChequeNo())+ ;
	  ', issued on '+shMDY(Cheque->date)

	in window aWin @ 3, 2 winsay 'To Grower: '+lstrim(Cheque->number) + ;
		', '+ NameOf(LU_GROWER,Cheque->number)
	in window aWin @ 4, 2 winsay ;
		  alltrim( NameOf(LU_CHEQUE_TYPE,Cheque->cheqtype)) + ;
		  ' Payment'
	in window aWin @ 5, 2 winsay 'Amount: ' + ;
		transform(Cheque->amount, '9,999,999.99')

	in window aWin @ 7,2 winsay 'Reissue Cheque?  ' winget lReissue picture 'Y'
	in window aWin @ 8,2 winsay 'Date to Reissue  ' winget dReissue ;
	 picture '@D' get_message ;
	 'Accounting Date for Reissued Cheque entry'
	read

	if lastkey() <> K_ESC .and. !empty(dReissue) .and. lReissue
		lReturn := .t.
	endif

	kill window aWin

return( lReturn )


