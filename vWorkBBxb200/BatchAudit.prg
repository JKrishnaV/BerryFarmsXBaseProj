// PROGRAM...: BatchAudit.prg
// AUTHOR ...: Bill Hepler
// DATE .....: Sune 3, 2015
// Copyright:  (c) 2015 by Bill Hepler & Crafted Industrial Software Ltd.

#include 'common.ch'
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
#include 'sysvalue.ch'
#include 'errors.ch'

function BatchAudit(  )
	local getList :={}
	local aWin, aRpt, aTitle
	local nImpBatch := 0, nChoice := 0, n
	local cDepot := space( FLD_DEPOT )
	local bWhile, bFor, bTotalOn, bTotalTitle
	local cRpt
	local lConfigure := .f.
	local cUnique
	local aScrn

	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

	myBsgScreen( 'Batches of Tickets' )

	create window at 4,08,21,70 title 'Ticket Batches' to aWin
	display window aWin

	in window aWin @ 5,2 winsay 'The Summary of Batches is available as an option in'
	in window aWin @ 6,2 winsay 'this set of screens or in LISTS REPORTS Screen.'

	do while .t.
      ImpBat->(OrdSetFocus(0))
      ImpBat->(dbGoBottom())
      n := 5
      if !ImpBat->(eof()) .and. !ImpBat->(bof())
         in window aWin @ 9, 2 winsay 'Recent Batches Imported...'
         do while !ImpBat->(eof()) .and. !ImpBat->(bof()) .and. n > 0
            in window aWin @ 9+n, 3 winsay ImpBat->Depot+str(ImpBat->imp_bat,FLD_DOCUMENT)+ ;
              ' Imported '+shMdy(ImpBat->date)+'  '+ ;
              ' '+shMdy( ImpBat->low_date)+' '+shMdy( ImpBat->high_date )
            ImpBat->(dbSkip(-1))
            n--
         enddo
      endif
		PutName( aWin, 2, 15, LU_DEPOT, cDepot )

		in window aWin @ 2,2 winsay 'Depot' winget cDepot picture '@!' ;
		 valid PutName( aWin, 2, 15, LU_DEPOT, cDepot )   ;
		 lookup(LU_DEPOT,'F5=Browse - Enter Depot if you know it')

		in window aWin @ 3,2 winsay 'Import Batch' winget nImpBatch picture replicate('9',FLD_DOCUMENT) ;
		 lookup(LU_IMPORT_BATCH,'Enter the Import Batch Number / F5=Browse (enter Depot if known)', cDepot )

		in window aWin @ 4,2 winsay 'Configure' winget lConfigure picture 'Y' ;
		 get_message "Configure which columsn to print"

		read

      aTitle := { TheClientName( ) }

		do case
		case lastkey()==K_ESC
			exit
		case nImpBatch<0
			waitInfo({"Negative batch number - What The Heck?"})
			loop
		endcase

		nChoice := thinChoice({'Run Report','Summary Rpt','Edit','Cancel'})
		do case
		case nChoice == 2
			close databases
			aScrn := save_scr()

			AllImpBatList( )  //
			rest_scr( aScrn )

			close databases
			if !openMainStuff(DB_SHARED)
				exit
			endif
			loop

		case nChoice == 3 .or. nChoice == 0
			loop

      case nChoice == 4
			exit

		// nChoice is = to 1....

		case nImpBatch == 0
			if !Yesno({'A batch number of ZERO for Import Batches will be', ;
			           'receipts entered in the office.  Is this what you want to print?'})
				loop
			else
				aadd( aTitle, 'Tickets entered at the Office' )
			endif

		case empty( cDepot )
			if !yesno({'Entering a specific Depot makes this report run a little faster...', ;
			           'but leaving the depot blank makes the system show all depots', ;
						  'Do you wish to leave the DEPOT Blank?'})
				loop
			else

			endif
		endcase

      Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))
		Daily->(dbSetRelation( 'Grower', ;
		 { || str( Daily->number,FLD_GROWER) } ) )

		aTitle := {'Ticket Import Batch Listing'}
		bFor    := { || .t. }
		bWhile  := { || .t. }
		Daily->(OrdSetFocus( DAILY_IMPORT_DEPOT_BATCH_ORD ))
		Daily->(dbGoTop())
		bTotalOn    := { || Daily->depot + str(Daily->imp_bat, FLD_DOCUMENT) }

		do case
		case !empty(cDepot) .and. nImpBatch > 0
			if !Daily->(dbSeek( cDepot + str( nImpBatch, FLD_DOCUMENT)))
				WaitInfo({'Import Batch ' + lStrim( nImpBatch)+' is not found'})
				loop
			endif

			bWhile := { || Daily->depot==cDepot .and. Daily->imp_bat == nImpBatch }
			cRpt   :=  REPORTS_IMP_BAT_1_BATCH_1_DEPOT
			aadd( aTitle, 'Depot='+cDepot+alltrim(NameOf(LU_DEPOT,cDepot))+' Batch='+lStrim( nImpBatch ) )
			aadd( aTitle, alltrim( NameOf(LU_IMPORT_BATCH, nImpBatch, cDepot))  )
			bTotalOn    := nil
			bTotalTitle := nil

		case empty(cDepot) .and. nImpBatch > 0
			bFor   := { || Daily->imp_bat == nImpBatch }
			cRpt   :=  REPORTS_IMP_BAT_1_BATCH_ANY_DEPOT
			aadd( aTitle, 'Any Depot, Batch='+lStrim( nImpBatch ) )
			bTotalOn    := { || Daily->depot }
			bTotalTitle := { || nuQprnOut( 'Depot '+Daily->depot+ ' ' + ;
			  alltrim(NameOf(LU_IMPORT_BATCH, Daily->imp_bat, Daily->depot)) ) }

		case !empty(cDepot) .and. nImpBatch == 0
			bWhile := { || .t. }
			bFor   := { || Daily->depot == cDepot  }
			cRpt   :=  REPORTS_IMP_BAT_ALL_BATCH_1_DEPOT
			aadd( aTitle, 'Depot='+cDepot+' '+alltrim( NameOf(LU_DEPOT,cDepot))+'-All Receipts' )
			bTotalTitle := { || nuQprnOut( 'Import Batch '+lstrim(Daily->imp_bat)+' '+ ;
			                    NameOf( LU_IMPORT_BATCH, Daily->imp_bat, Daily->depot) ) }

		case empty(cDepot) .and. nImpBatch == 0
			Daily->(OrdSetFocus( DAILY_DATE_ORD ))
			Daily->(dbGoTop())
			bWhile := { || .t. }
			bFor   := { || Daily->imp_bat == 0  }
			cRpt   :=  REPORTS_IMP_BAT_INPUT_IN_OFFICE
			aadd( aTitle, 'Shows Tickets input at office (not imported)' )
			bTotalOn    := { || Daily->depot }
			bTotalTitle := { || nuQprnOut( 'Depot '+Daily->depot +' ' +alltrim(NameOf(LU_DEPOT,cDepot)) ) }

		otherwise
			WaitInfo({'The computer is confused - try again..'})
			loop
		endcase

		msgLine('Indexing....')
		cUnique := UniqueFile()

		msgLine('Skipping ahead...')
		do while !Daily->(eof()) .and. !eval( bFor )
			Daily->(dbSkip())
		enddo
		if Daily->(eof())
			WaitInfo({'Nothing found here!'})
			loop
		endif

		msgLine('Here we go ...')
		// dbSelectAr('Daily' )

      InitGeneralFor( bFor, { || .t. }, { || .t. }, { || .t. } )

      Daily->( OrdCondSet( 'GeneralFor()', ;
			        { || GeneralFor() }, ;
                    .f., bWhile  ) )
      // Daily->( OrdCreate( cUnique, 'USETHIS',   ;
      //       'Daily->depot + str( Daily->imp_bat, 8) + str( Daily->recpt, 8)', ;
      //   { || Daily->depot + str( Daily->imp_bat, 8) + str( Daily->recpt, 8)    } ) )

      // if empty( Daily->(OrdBagName('USETHIS')) )
      //    AppError(APP_ERR_TEMP_INDEXING1, {'Hmm-we have a problem!'})
      // endif

      // Daily->( OrdSetFocus('USETHIS') )

		// Daily->(dbGoTop())

		msgLine('Ready to report...')

		aRpt := {}
		rGrowerInfo( aRpt )
		rRcptQty( aRpt )
		rAdvPrInfo( aRpt )
		rOutConCols( aRpt, .f.  )
		rInConCols( aRpt, .f. )
		rRawConCols( aRpt )
		rFinPrInfo( aRpt )
      // aadd( aRpt, { 'St', ;
      //   { || iif(Daily->post_bat1==0 .and. Daily->fin_bat==0,"U" ,"P" ) },"C", 2, 000, .t., .f., ;
      //   'Status - P=Posted, U=Unposted Receipt' } )
      rDockage( aRpt, .f. )
      rDepotSite( aRpt )
		rRcptNotes( aRpt )
		rVarietyEtc( aRpt )
		rProGradeEtc( aRpt )   // March 2020

		gRptInit( cRpt, aRpt)

		if lConfigure
			gRptSelect( aRpt )
		endif

		aTitle[1] += ' for Rpt:'+cRpt
		aadd(aTitle, 'As of '+shMDY( date())+' at '+time() )

		gRptInitHead()
		gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

		gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
		gRptGetSetHead( RPT_HEAD_FOR_CONDITION, bFor )
		gRptGetSetHead( RPT_HEAD_WHILE_CONDITION, bWhile )

		if valtype( bTotalOn )=='B'
			gRptGetSetHead( RPT_HEAD_SUBTOTAL, .t. )
			gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, bTotalOn )
			gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, bTotalTitle )
		else
			gRptGetSetHead( RPT_HEAD_SUBTOTAL, .f. )
		endif

		if selectPrn( 'IMPBATCH.TXT')
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
		Daily->(dbCloseArea())

		KillUnique(cUnique,'.CDX')
		if !openFile({'Daily'},DB_SHARED)
			exit
		endif
	enddo

	kill window aWin
	close databases
RETURN( nil )


