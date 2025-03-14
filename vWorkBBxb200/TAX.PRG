//	TAX.PRG
//	Bill Hepler/Roy Hedberg
//	Originally written on 6/24/88
// Rev June 2010 for HST
//	Add/Edit a TAX Record (no DELETE as this could cause problems)
//  Feb 13, 2023 - Minor Cleanup


#include 'inkey.ch'
#include 'bsgstd.ch'
#include 'valid.ch'
#include 'window.ch'
#include 'errors.ch'
#include 'tax.ch'
#include 'field.ch'

static aTax

function InitTaxes()
	// builds the Tax Table
	local aMsg

	if !file('Tax.dbf') .or. !file('tax.cdx')
		waitInfo({'You must create TAX indexes...'})
		return( .f. )
	endif
	if .not. OpenFile({'Tax'},DB_SHARED)
		return( .f. )
	endif
	aMsg := msgLine('Initializing Taxes')

	Tax->(dbSetFilter({|| !Tax->(deleted()) }) )
	Tax->(dbGoTop())

	aTax := {}
	do while .not. Tax->(eof())
		// We REALLY constrain this !
		// July 2014

		if alltrim(Tax->taxname) == 'GST'
			SetTaxEtc( )
		else
			AppError( APP_ERR_TAX_STUFF1, {'We have a WEIRD Tax Type, so we are IGNORING IT!', ;
			'Tax Type = '+Tax->taxname, 'RecNo:'+lstrim(Tax->(recno())), ;
			'You may wish to get Crafted Industrial Software to Delete this!'})
		endif

		Tax->(dbSkip())
	enddo

	if len( aTax ) < 1
		Tax->(addRecord())
		Tax->taxName := 'GST'
		SetTaxEtc()
		WaitInfo({'We are setting up the GST rate for the first time!', ;
		          'Please go set rates etc','It is set for a Rate of ZERO'})
	endif

	Tax->(dbCloseArea())
	rest_scr( aMsg )

return( .t. )

function ValidTaxArea( cTaxName, nMessage )
	local lReturn

	if ascan( aTax,{|x| alltrim( x[1] ) == alltrim( cTaxName) } ) > 0
		lReturn := .t.
	else
		lReturn := .f.
		if nMessage == VT_MESSAGE
			waitHand({'This tax area is not on file!'})
		endif
	endif
return( lReturn )

function TaxFinder( cTaxName, nWhatInfo, dDate )
	// this returns tax rate, gl codes or whatever depending on what you have asked for.
	local nElement := 0, n
	local xReturn

	if valType( dDate ) <>'D'
		appError( APP_ERR_TAX_STUFF2 , {'No DATE set THIS IS BAD ! Using Today !'})
		dDate := date()
	endif

	if nWhatInfo < TAX_VALUE_MIN .or. nWhatInfo > TAX_VALUE_MAX
		appError( APP_ERR_TAX_STUFF3 , {'Not asking correct thing from TAX ROUTINE !', ;
		                               'We are going to CRASH and BURN', ;
		                               'Asking for '+Var2Char( nWhatInfo) })
		xReturn := NIL
		return( xReturn )
	endif


	// this is how we have to search a 2D array......

	nElement := ascan( aTax,{|x| upper(alltrim( x[1] )) == upper(alltrim( cTaxName)) } )

	if nElement == 0
		appError( APP_ERR_TAX_STUFF4, { 'Can NOT find this TaxName '+cTaxName, ;
		   'Returning Blank', ;
		   'This call should not come up - we should be protected by ValidTest() call' })
		do case
		// case nWhatInfo == TAX_VALUE_ISHST
		//	xReturn := .f.
		case nWhatInfo == TAX_VALUE_RATE
			xReturn := 0.000
		endcase
	else
		if dDate <= aTax[ nElement, TAX_EFFECTIVE_DATE ]
			n := 0  // i.e. the OLD STUFF applies
		else
			n := 1
		endif

		do case

		case nWhatInfo == TAX_VALUE_RATE
			// Rate is stored as a PerCentage in database so 5=5%=0.05
			//   to 3 decimal places - e.g. 5.125%
			xReturn := round(aTax[ nElement, TAX_OLD_RATE + n ],5)   // Note it is already divided by 100

		endcase
	endif
return( xReturn )

function AddEditTaxes( )
	local getlist:={}, cTaxName
	local aW
	local lNew := .f.

	if !OpenFile({'Tax'},DB_SHARED)
	   return (.f.)
	endif
	cTaxName := padr('GST', FLD_TAXNAME)

   create window at 4,10,22,70 title 'Tax Records' to aW
	display window aW
	set cursor on

	in window aW @13,2 winsay 'When tax rates change, you must be very careful to'
	in window aW @14,2 winsay 'process the transactions that are at earlier rate'
	in window aW @15,2 winsay 'in separate batches than transactions where the later'
	in window aW @16,2 winsay 'rate will apply.  Be sure to contact Crafted if needed!'

	DO WHILE .t.
		in window aW @ 01,01 winclear to 11,59
		in window aW @ 01,40 winsay 'Records on File:' + STR(Tax->(LastRec()),5)

		msgLine( 'Enter a Region, or Press [F5] for list')

		in window aW @ 02,02 winsay 'Tax Name' winget cTaxName ;
		  lookup(LU_TAXES, 'F5=Lookup the Tax-should be at least ONE!')
		read

		if empty(cTaxName) .OR. lastkey()==K_ESC
			exit
		endif

		if Tax->(dbSeek( upper(cTaxName), HARDSEEK ))
			if .not. Tax->(RecLock())
				loop
			endif
			lNew := .f.
		else
			lNew := .t.
			if yesno({'Add this Tax Record?'})
				if Tax->(AddRecord())
					Tax->taxName  := cTaxName
					tax->eff_date := date()-1
				endif
			else
				loop
			endif
		endif

		msgLine('Enter tax information')

		in window aW @05,02 winsay 'Date NEW rate is effective' ;
		  winget Tax->eff_date PICTURE '@D' valid !empty( Tax->eff_date) ;
		  get_message 'This allows you to run normally with a rate change'

      in window aW @ 6,02 winsay 'Old Tax Rate ( % ) ' ;
		  winget Tax->old_rate PICTURE '99.999' ;
		  get_message 'Old rate as a Percentage (e.g. 5=5%) BEFORE the Effective Date'

      in window aW @ 6,32 winsay 'New Rate ( % )' ;
		  winget Tax->new_rate PICTURE '99.999' ;
		  get_message 'New rate as a Percentage ON and AFTER the Effective Date'

		READ
		if lastkey() <> K_ESC
			if !lNew .and. UpDated()
				Tax->(EditByFlds())
			endif
		endif

      Tax->(RecUnLock())
	ENDDO
	kill window aW
	CLOSE DATABASES

   InitTaxes()  // rebuilds tax table

RETURN ( NIL )

static function SetTaxEtc( )
	local n

	aadd(aTax,{} )

	n := len(aTax)
	aSize( aTax[n], TAX_ARRAY_SIZE )

	aTax[n,TAX_TAXNAME]      := alltrim( Tax->TaxName)

	aTax[n,TAX_OLD_RATE]     := round(Tax->old_rate / 100, 4)
	aTax[n,TAX_NEW_RATE]     := round(Tax->new_rate / 100, 4)


	aTax[n,TAX_EFFECTIVE_DATE] := Tax->eff_date

return( nil )
