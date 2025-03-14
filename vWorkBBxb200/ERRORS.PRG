* ÚÄ Program ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
* ³  Application: Billing Information System                                 ³
* ³  Description: Logs Errors that we expect the User to Write Down          ³
* ³               This was added when I added cartage in Jan 98.             ³
* ³               It is mostly for non-critical errors, that indicate        ³
* ³               logical problems with the data or the program itself.      ³
* ³                                                                          ³
* ³   Starting on March 8, 1998 -                                            ³
* ³   It is also used to note unusual things the user may have done.         ³
* ³   So at least some of these are not program errors or problems at all.   ³
* ³                                                                          ³
* ³         From Waste Management System.                                    ³
* ³                                                                          ³
* ³    File Name: ERRORS.PRG                                                 ³
* ³       Author: Bill Hepler                                                ³
* ³ Date created: 01-08-98              Date updated: ş01-08-98              ³
* ³ Time created: 05:08:11pm            Time updated: ş05:08:11pm            ³
* ³    Copyright: (c) 1998 by Bill Hepler & Crafted Industrial Software Ltd.³
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

#include 'errors.ch'
#include 'bsgstd.ch'
#include 'common.ch'
#include 'sysvalue.ch'
#include 'signon.ch'

#include 'fileio.ch'

function BrowseErrFile( cFile, cMessage )
	if !file( cFile )
		WaitInfo({'File '+cFile+' is not present', ;
		 'this likely means no errors have been', ;
		 'logged since the file was cleared.' })
	else
		WaitInfo({'Browsing the Log File '+cFile, ;
		  cMessage })

		TextBrowser( cFile, .t.)

		if yesno({'Clear file '+cFile+'?', ;
			'This will delete the File', ;
			'You should only do this when', ;
			'instructed to by your systems administrator'})

			if yesno({'Clear file '+cFile+' ?'})
				ferase( cFile )
			endif
		endif
	endif

return( nil )

function AppError( cErr, aMsg )
	local aError, aShow
	local n
	local nHandle
	local nKey

	if valType(cErr) <> 'C'
		cErr := 'UNKNOWN CODE'
	endif

	nKey := lastkey()

	aError := {'This program has encountered an UnUsual Event', ;
		'please note the Event Code that follows',       ;
		'and report it to your systems administrator','', ;
		'EventCode: '+cErr,'' }

	do case
	case valType( aMsg ) == 'A'
		for n := 1 to len( aMsg )
			aadd( aError, aMsg[n] )
		next
		aadd(aError,'')
	case valType( aMsg ) == 'C'
		aadd(aError, aMsg )
		aadd(aError,'')
	endcase

	aadd( aError, ;
		'Called by: '+procname(1)+iif(procLine(1)==0,'',str(procLine(1),6)) )

	n := 2
	do while !empty( procname(n) ) .and. n <11
		aadd( aError, ;
		 '     from: '+procname(n)+iif(procLine(n)==0,'',str(procLine(n),6) ) )
		n++
	enddo

   if len(aError) > 15
		aShow := {}
      for n := 1 to 14
			aadd(aShow,aError[n])
		next
		aadd(aShow,'      and more...')
		WaitHand( aShow )
	else
		WaitHand( aError )
	endif

	if file('ERR_APP.ERR')
		nHandle := fOpen('ERR_APP.ERR', FO_READWRITE )
	else
		nHandle := fCreate('ERR_APP.ERR',  FC_NORMAL )
		if nHandle >= 0
			fSeek( nHandle, 0, FS_END )
		endif
	endif

	if nHandle > 0
		fSeek(  nHandle, 0,FS_END)
		fWrite( nHandle, replicate('-',70) + chr(13) + chr(10)  )

		fSeek(  nHandle, 0,FS_END)
		fWrite( nHandle, shMDY(date()) + '   '+ time() + chr(13) + chr( 10) )
		fSeek(  nHandle, 0,FS_END)
		fWrite( nHandle, 'LastKey = '+ str( nKey, 5) + chr(13) + chr( 10) )
		fSeek(  nHandle, 0,FS_END)
		fWrite( nHandle, 'Logged on as '+ soValue(SO_INIT)+ ;
			 ' '+soValue(SO_FULLNAME) + chr(13) + chr( 10) )

		fSeek(  nHandle, 0,FS_END)
		fWrite( nHandle, ' '+chr(13)+ chr(10)  )

		fSeek(  nHandle, 0,FS_END)
		fWrite( nHandle, ' ' + chr(13) + chr( 10) )

		for n := 1 to len( aError )
			fSeek(  nHandle, 0,FS_END)
			fWrite( nHandle, aError[n] + chr(13) + chr( 10) )
		next

		if empty(alias())
			fSeek(  nHandle, 0,FS_END)
			fWrite( nHandle, 'No DBF Open.' + chr(13) + chr( 10) )
		else
			fSeek(  nHandle, 0,FS_END)
			fWrite( nHandle, 'Current DBF: '+alias() + chr(13) + chr( 10) )

			if eof()
				fSeek(  nHandle, 0,FS_END)
				fWrite( nHandle, 'At EOF()'+ chr(13) + chr( 10) )
			else
				fSeek(  nHandle, 0,FS_END)
				fWrite( nHandle, 'Field 1: '+FieldName(1)+' '+ ;
					Var2Char(FieldGet(1)) + chr(13) + chr( 10) )
				fSeek(  nHandle, 0,FS_END)
				fWrite( nHandle, 'Field 2: '+FieldName(2)+' '+ ;
					Var2Char(FieldGet(2)) + chr(13) + chr( 10) )
				fSeek(  nHandle, 0,FS_END)
				fWrite( nHandle, 'Field 3: '+FieldName(3)+' '+ ;
					Var2Char(FieldGet(3)) + chr(13) + chr( 10) )
				fSeek(  nHandle, 0,FS_END)
				fWrite( nHandle, 'Recno= '+str(recno(),10) + chr(13) + chr( 10) )
				fSeek(  nHandle, 0,FS_END)
				fWrite( nHandle, ' ' + chr(13) + chr( 10) )
			endif
		endif

		for n := 1 to 100
			if !empty(alias(n))
				fSeek(  nHandle, 0,FS_END)
				fWrite( nHandle, str(n,3)+' DBF: '+alias(n) + chr(13) + chr( 10) )
				fSeek(  nHandle, 0,FS_END)
				fWrite( nHandle, ' Recno= '+ ;
					str( (alias(n))->(recno()),10) + chr(13) + chr( 10) )
				if (alias(n))->(eof())
					fSeek(  nHandle, 0,FS_END)
					fWrite( nHandle, ' At EOF()'+ chr(13) + chr( 10) )
				endif
			endif
		next

		// put this in to help ensure that if an unusual event came up
		// on a Daily we can figure out what it is
		if select('Daily') > 0
			if Daily->(eof())
				fSeek(  nHandle, 0,FS_END)
				fWrite( nHandle, 'Daily is at EOF()' + chr(13) + chr( 10) )
			else
				fSeek(  nHandle, 0,FS_END)
				fWrite( nHandle, 'Daily.DBF Grower: '+str(Daily->number,10) + ;
               ', Date: '+shMDY(Daily->date) + ;
                chr(13) + chr( 10) )
            fSeek(  nHandle, 0,FS_END)

            fWrite( nHandle, ' Rcpt: '+str(Daily->recpt,10) + ;
					', Day Uniq: '+str(Daily->day_uniq,10) + ;
					', Recno(): '+str(Daily->(recno()),10)+ ;
				 chr(13) + chr( 10) )
				fSeek(  nHandle, 0,FS_END)

				if Daily->(deleted())
					fWrite( nHandle, 'DELETED'+ chr(13) + chr( 10) )
				endif

			endif
			fSeek(  nHandle, 0,FS_END)
			fWrite( nHandle, 'Index Key '+Daily->(indexKey()) + chr(13) + chr( 10) )
		endif

		if select('Grower') > 0
			if Grower->(eof())
				fSeek(  nHandle, 0,FS_END)
				fWrite( nHandle, 'Grower is at EOF()' + chr(13) + chr( 10) )
			else
				fSeek(  nHandle, 0,FS_END)
				fWrite( nHandle, 'Grower DBF - Grower: '+str(Grower->number,10) + ;
					', PayGrp: '+Grower->payGrp + ;
					', Status: '+str(Grower->status,3) + ;
					', Recno(): '+str(Grower->(recno()),10)+ ;
				 chr(13) + chr( 10) )
				fSeek(  nHandle, 0,FS_END)

				if Grower->(deleted())
					fWrite( nHandle, 'DELETED'+ chr(13) + chr( 10) )
				endif
			endif
			fSeek(  nHandle, 0,FS_END)
			fWrite( nHandle, 'Index Key '+Grower->(indexKey()) + chr(13) + chr( 10) )
		endif

      if select('Account') > 0
         if Account->(eof())
				fSeek(  nHandle, 0,FS_END)
            fWrite( nHandle, 'Account is at EOF()' + chr(13) + chr( 10) )
			else
				fSeek(  nHandle, 0,FS_END)
            fWrite( nHandle, 'Account DBF - Grower: '+str(Account->number,10) + ;
               ', Type:   '+Account->type + ;
               chr(13) + chr( 10) )
               fSeek(  nHandle, 0,FS_END)

            fWrite( nHandle, ' Date:   '+shMDY(Account->date) + ;
               ', Amount: '+str(Account->dollars,12,2) + ;
               ', Recno(): '+str(Account->(recno()),10)+ ;
				 chr(13) + chr( 10) )
				fSeek(  nHandle, 0,FS_END)

            if Account->(deleted())
					fWrite( nHandle, 'DELETED'+ chr(13) + chr( 10) )
				endif
			endif
			fSeek(  nHandle, 0,FS_END)
         fWrite( nHandle, 'Index Key '+Account->(indexKey()) + chr(13) + chr( 10) )
		endif

		fSeek(  nHandle, 0,FS_END)
		fWrite( nHandle, replicate('=',70) + chr(13) + chr( 10) )
		fSeek(  nHandle, 0,FS_END)
		fWrite( nHandle, ' ' + chr(13) + chr( 10) )

		fClose( nHandle )
	endif

return( nil )

