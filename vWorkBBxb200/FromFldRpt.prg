// PROGRAM...: FromFldRpt.prg
//             Prints out tickets for a given Harvested From Field
//             for WestBerry
// AUTHOR ...: Bill Hepler May 26, 2020
// Written:    May 26, 2020
//     rev:
// (c) 2020 by Bill Hepler & Crafted Industrial Software Ltd.

#include 'inkey.ch'
#include 'BerryPay.ch'
#include 'window.ch'
#include 'printer.ch'
#include 'bsgstd.ch'
#include 'valid.ch'
#include 'rpt.ch'
#include 'berry_rpt.ch'
#include "field.ch"
#include "indexord.ch"
#include 'combobox.ch'
#include 'sysvalue.ch'

function FromFldRpt( cRpt )
	local getList :={}, dFrom,dTo, nGrower, aWin
	local aTitle
	local aRpt
	local lConfigure := .f.
	local lLegend := .f.
	local cFromField := space( FLD_FROM_FIELD  )
	local bForDate, bForGrow, bForFromField
	local cDW

	if empty( sysValue( SYS_IMPORT_FROM_FIELD_NAME ) )
		if YesNo({'You do NOT seem to be using the From Harvest Field data', ;
		          'This report probably will not be useful.','', ;
					 'Do you wish to Exit this report?' })
			return( nil )
		endif
	endif

	dFrom := sysValue( SYS_CURRENT_SEASON_START )
	dTo   := date()
	cDW   := 'From Harvest Field Report '+cRpt

	nGrower := 0
	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

	myBsgScreen( cDW )

	create window at 4,08,20,70 title cDW to aWin
	display window aWin

	do while .t.
		lLegend := .f.                 // this report often goes to Growers !

      in window aWin @ 8,10 winsay 'We will do a partial match on the'
		in window aWin @ 9,10 winsay 'harvest field.'

		msgLine('[Esc] to Exit')
		in window aWin @ 2,2 winsay 'From  ' winget dFrom picture '@d' ;
		 get_message 'Starting Date for Report,  +/- to adjust'
		in window aWin @ 3,2 winSAY 'To    ' winget dTo picture '@d' ;
		 get_message 'Ending Date for Report, +/- to adjust'

		in window aWin @ 5,2 winsay 'Grower' winget nGrower ;
		 PICTURE numBlankPic(FLD_GROWER) ;
		 valid PutName(aWin,5,20,LU_GROWER,nGrower) .and. ;
		 (empty( nGrower) .or. validTest(V_GROWER, nGrower, VT_BROWSE)) ;
		 LOOKUP(LU_GROWER, ;
		'Select a specific Grower,   [F5] to Browse Growers')

		in window aWin @ 7,2 winsay 'Harvest Field '+ alltrim( sysValue( SYS_IMPORT_FROM_FIELD_NAME )) ;
		 winget cFromField get_message ;
		'Input a Harvest Field to match or leave blank for all'

		in window aWin @12,02 winsay 'Configure Report' winget lConfigure ;
		 picture 'Y'  GET_MESSAGE ;
		'You may select and order the columns to be printed'

		in window aWin @ 13,02 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

		read

		do case
		case lastkey()==K_ESC
			exit
		case nGrower == 0 .and. empty( cFromField )
			waitInfo({'You must run this for ONE grower or a Harvest Field'})
			loop
		case lLegend
			if !Yesno({'You have selected to Show the Legend',                         ;
						  'This is a valid option - but is usually used when you',        ;
						  'are experimenting with a report format - we do not reccomend', ;
						  'sending reports to customer with the Legend showing', '',      ;
						  'Do you wish to continue?'} )
				loop
			endif
		endcase

		aTitle := { TheClientName( )+' '+cRpt }
		bForGrow       :=  { || .t. }
		bForFromField  :=  { || .t. }
		bForDate       :=  { ||  Daily->date >= dFrom .and. Daily->date <= dTo }

		if !empty( nGrower )
			aadd( aTitle, 'Grower='+lStrim(nGrower) +' '+ alltrim(NameOf( LU_GROWER, nGrower)) )
			bForGrow  := { || Daily->number == nGrower }
		endif
		if !empty( cFromField )
			aadd( aTitle, cDW+'Harvest Field '+ alltrim(sysValue( SYS_IMPORT_FROM_FIELD_NAME )) + '=' + cFromField )
			bForFromField := { || upper(alltrim( cFromField )) $ upper( Daily->from_Field ) }
		endif
		aadd(aTitle, 'From '+shMDY(dFrom)+' to '+shMDY(dTo) )

		msgLine('Selecting records to print....hang on....')

		Daily->(dbClearFilter())
		Daily->(dbClearRelation())
		inkey( 1 )

		Daily->(OrdSetFocus( DAILY_GROWER_ORD))

		Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))
		Daily->(dbSetRelation( 'Grower', ;
		 { || str( Daily->number,FLD_GROWER) } ) )

		Daily->( DbSetFilter( { || LookAtMe( bForDate, bForGrow, bForFromField ) } ) )

		Daily->(OrdSetFocus( DAILY_GROWER_ORD))
		Daily->(dbGoTop())

		if Daily->(eof())
			waitInfo({'Can not find information which matches!'})
			Daily->(dbClearFilter())
			Daily->(dbClearRelation())
			loop
		endif
		showProg('Aha...')

		aRpt := {}

		rRcptQty( aRpt )
		rAdvPrInfo( aRpt )
		rFinPrInfo( aRpt )

		rOutConCols( aRpt, .f.  )
		rInConCols( aRpt, .f. )
		rRawConCols( aRpt )

		rDepotSite( aRpt )
		rRcptNotes( aRpt )   // July 29 2014
		rVarietyEtc( aRpt )  // June 2015
		rProGradeEtc( aRpt ) // April 2019

		gRptInit( cRpt, aRpt)

		if lConfigure
			gRptSelect( aRpt )
		endif

		gRptInitHead()
		gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

		gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| Daily->number } )
		gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
		 {|| nuQprnOut( str( Daily->number,FLD_NUMBER)+' '+Grower->name ) } )   // remember have relation on!

		if selectPrn(cRpt+'.TXT')

			// For LandScape
			gRptAutoPageOrientation( aRpt, 0)

			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

			Daily->(gRptPrinter( aRpt ))

			PRINT_OFF  RPT_COMPLETE_EJECT

			if lConfigure
				if yesno({'Save this Report Format?'})
					gRptSave( aRpt )
				endif
			endif
		endif

		Daily->(dbClearFilter())
		Daily->(dbClearRelation())
	enddo

	kill window aWin
	close databases
RETURN( nil )

static Function LookAtMe( bForDate, bForGrow, bForFromField )
	local lReturn := .f.

	if eval( bForDate)
		if eval( bForGrow )
			if eval( bForFromField )
				lReturn := .t.
         endif
      endif
	endif

return( lReturn )
