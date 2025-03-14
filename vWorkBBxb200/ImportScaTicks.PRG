/// ImortScaTicks.prg
///
/// (c) Copyright 2020 by Bill Hepler
///  This reads in Data Produced by various Scale Programs into the Payment
///  program.
///
/// Jun 02,2015   - Importing Wider Processes THESE go to VARIETIES.
///                 Similarly we can import wider Products
///                 We default what goes into Varieties!
/// Jul 27,2017   - Improve notes on Dockage
/// Aug 09,2019   - Overflow issues with Container Qty resolved
/// Mar 10,2020   - Small improvement to what files are being imported..
///                 inxluding ability to take in the GROWERS FIELD ID, FROM_FIELD
///                 use Search for   FROM_FIELD
///                 Added the Daily_Audit so that I can check on what is being imported !
///                 The data in Daily_Audit is Not EDITED only written here.  It is purged.
///                 The Import Batch No should be set as UNIQUE - there was some ambiguity
///                 in earlier versions of the program as to whether it was Unique or
///                 whether DEPOT + IMP_BAT was unique.
/// Apr 2020        To Improve Audit, we re-write some stuff, then TEST the heck out of it.
///                 ImpBat->imp_bat   is a Unique Identifier in the ImpBat table
///                    see   UF_THE_UNIQ_IMBAT   Field->UNIQ_IMBAT
///                    This field is also present in Daily to link back..
///                 In addition, I re-factored the piece of code that determines what columns are
///                 present to make it shorter and also easier to understand.  In general, we will
///                 correctly import based on the FILE contents, and warn if the data in the file
///                 and the software configuration do not match up.  Improve checking over of data also!
/// The file from the scale is valid ONLY if one of these conditions is met
///  Edit Reason, nCont1                       found  the "base case from 2000"
///  Edit Reason, nCont1, Harvest Field Fname  found  the "change requested by Westberry for 2020 season" - harvest field info
///  Edit Reason, Certified nCont1             found  a change for South Alder in 2013 or so
///  Edit Reason, Certified, Harvest & nCont1  found  hypothetical at this point
/// We search for Specific Field Names in the First Row of the Import File.

#include "BerryPay.ch"
#include "berry_rpt.ch"
#include "browser.ch"
#include "bsgstd.ch"
#include "dbstruct.ch"
#include "directry.ch"
#include "errors.ch"
#include "events.ch"
#include "field.ch"
#include "fileio.ch"
#include "indexord.ch"
#include "inkey.ch"
#include "printer.ch"
#include "rpt.ch"
#include "sysvalue.ch"
#include "Unique_Fields.ch"
#include "valid.ch"
#include "window.ch"


// The configuration of the HARVest FRom FieLD in BerryPay will be:
//   No HARVEST_FROM_FIELD
//   Spelling of Harvest From DOES NOT MATCH scale file
//   Spelling of Harvest From DOES match
// But in ANY case, the configuration of Berry Pay does NOT matter, what matters is what is in the file

// Similary, there is may be a PRICE field included in the Scale File
//    SYS_IMPORT_FORMAT, which is EITHER with or without price.
//    this IS important - so if the scale file disagrees, then
//    we may stop import!

#define  E_PRICE     '$'
#define  E_GROWER    '#'
#define  E_GRADE     'G'
#define  E_BERRY     'B'
#define  E_PROCESS   'P'
#define  E_EMPTY     'E'
#define  E_RECEIPT   'R'
#define  E_TIME      'T'   // July 2003 - include Date now in 2020
#define  E_VOID      'V'   // June 2005
#define  E_WEIGHT    'W'
#define  E_DOCKAGE   'D'
#define  E_CONTAINER 'C'  // May 2020
#define  E_GARBAGE   'X'

#define  NT_KEY_1  '$-Price  #-Grower  G-Grade  B-BerryTp  P-Process  E-Empty'
#define  NT_KEY_2  'X-Garbage T-Time  V-Void  W-Weight   D-Dockage noted   C-Container'
#define  NT_KEY_3  'Time & Empty Errors may indicate garbaged ticket data-check these carefully'


static  dScaleFromDate := NIL, dScaleToDate := NIL
static  nScaleBatch    := 0
static  cScaleDepot    := ''
static  nImportErrors  := 0

function ImportScaTicks( )

	if !ArchiveCheckOK()
		return( nil )
	endif

	if !(openfile({'Daily' ,'Daily_Audit','ImpBat' ,'VoidTck','CounterIDs'},DB_EXCLUSIVE) .and. ;
		  openfile({'Grower','Process'    ,'Product','Price'  ,'Contain',   'PayGrp', 'RptCfg', 'Tax', 'Variety'},DB_SHARED))
		close databases
	endif

	myBsgScreen( 'Load Receipts from Disk' )
	msgLine('Look at loading receipts from Disk')

	InitScaleBatchStatics()

	LoadFrScale( )

	close databases

return( nil )


static function LoadFrScale(  )
	local getlist :={}
	local aTxtFiles, aFiles
	local n , lError, lReturn := .f., aWin
	local cDir,cAskDir,cFile,cDirFile := '', cDirBU
	local lConfigure := .f.
	local aRpt
	local lImpBefore
	local aMsg, aHead
	local nPos
	local aStru
	local cProduct, cProcess
	local nGrade
	local nErr
	local lErase
	local aContain[ MAX_TYPES_CONTAINERS, 2 ]
	local aGaps := {}
	local aNotes
	local cPrefix, cExt, c

	cAskDir := padr(sysValue( SYS_IMPORT_DIRECTORY ),60)
	do case
	case sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_DOS
		// DOS version
		cPrefix := ''
		cExt    := 'TXT'
		aNotes  := {'We no longer support this format!', ;
						'Your settings within this program may be incorrect', ;
						'' }
		waitHand({'You are set to IMPORT from a very old version of SCALE', ;
					 'This is NO LONGER SUPPORTED', ;
					 'We will EXIT !!!' })

		return( nil )

	case sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_WIN_NO_PRICE
		// PacWeigh Berry
		cPrefix := sysValue( SYS_IMPORT_PREFIX )
		cExt    := 'CSV'
		aNotes  := {'We are set up to import from the Windows Version of the', ;
						'Pacific-Avery Scale program.  The files will look like this:', ;
						'    '+cPrefix+'0000123.CSV', ;
						'where 0000123 is the BATCH NUMBER being Imported', ;
						'The SYSTEM will NOT import prices set at the SCALE!'}

	case sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_WIN_WITH_PRICE
		// PacWeigh Berry
		cPrefix := sysValue( SYS_IMPORT_PREFIX )
		cExt    := 'CSV'
		aNotes  := {'We are set up to import from the Windows Version of the', ;
						'Pacific/Avery program.  The files will look like this:', ;
						'    '+cPrefix+'0000123.CSV', ;
						'where 0000123 is the BATCH NUMBER being Imported' , ;
					  'The SYSTEM imports PRICES set at the Scale !'}
	endcase


	aadd( aNotes,'')
	aadd( aNotes,'*** Ensure you are the ONLY person in BerryPay !!! ***')

	do case
	case sysValue(SYS_DOCKAGE_ACTION) ==  DOCKAGE_ACTION_WARN
		aadd( aNotes,'We WARN ONLY if we see transactions with Dockage!')
	case sysValue(SYS_DOCKAGE_ACTION) ==  DOCKAGE_ACTION_CHANGE
		aadd( aNotes,'We CHANGE THE NET if we see transactions with Dockage!')
	case sysValue(SYS_DOCKAGE_ACTION) ==  DOCKAGE_ACTION_NO_ACTION
		aadd( aNotes,'We IGNORE Dockage and keep Net on tickets with Dockage!')
	otherwise
		aadd( aNotes,'Hmm - not sure what happens if we see DOCKAGE !')
	endcase

	create window at 4,3,22,76 title 'Input Berry Receipts From Disk' to aWin
	display window aWin
	msgLine('Read data from disk...')

	DO WHILE .T.
		CloseTempFiles()  // Just in Case

		lError := .t.

		in window aWin @ 3,2 winclear to 18,70
		for n := 1 to len(aNotes)
			in window aWin @4+n,4 winsay aNotes[n]
		next

		in window aWin @4,2 winsay ;
		 'Import proceeds by first viewing data to be imported.'

		in window aWin @2,2 winsay ;
			'File location for this batch of receipts:'
		in window aWin @3,5 winget cAskDir picture '@!' ;
			LookUp( LU_FILE_DIRECTORY, 'This defaults from your System Settings')
			
		read

		if lastkey()==K_ESC
			exit
		endif

		cDir := alltrim(cAskDir )

		do case
		case empty(cDir)
			waitInfo({'You must enter in a Directory!'})
			loop
		case substr(cDir,1,1)=='B' .or. substr(cDir,1,1)=='A'
			waitInfo({ 'Insert the required floppy disk'})

			if sysValue( SYS_DISK_CHECK_ON_FLOPPY )
				if !DiskReady( substr( cDir,1,1))
					waitInfo({'Drive is NOT ready' } )
					loop
				endif

				if !DiskReadyW( substr( cDir,1,1))
					waitInfo({'There is a Write Protect on Disk - Please Remove' } )
					loop
				endif

			endif
		case len(alltrim(cDir))==3
			waitInfo({'Ensure that Disk Drive is available - so for example', ;
						 'if you are using a FlashRAM, please insert the FlashRAM', ;
						 'module.'})

		otherwise
			waitInfo({'Ensure that the drive is ready to read from'})
		endcase

		msgLine('Getting ready to read from drive '+alltrim(cDir))
		inkey(1)

		lError := .t.
		aTxtFiles := {}
		aFiles := {}

		begin sequence
			msgLine('Looking for files in '+alltrim(cDir ) )
			aTxtFiles := directory( cDir+cPrefix+'*.'+cExt)

			if len(aTxtFiles)==0
				// Win 2000 issue, seemingly-does NOT always read from Floppy drives for some reason....
				msgLine('Next Pass at Reading...')

				aTxtFiles := directory( '*.DBF')
				aTxtFiles := {}

				memory(-1)
				inkey(1)

				aTxtFiles := directory( cDir+cPrefix+'*.'+cExt)
				if len(aTxtFiles)==0
					memory(-1)
					inkey(1)
					aTxtFiles := directory( cDir+cPrefix+'*.'+cExt)
				endif
			endif

			lError := .f.

			if sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_DOS
				waitInfo({'This should NEVER come up- DOS import Format'})

			else
				for n := 1 to len(aTxtFiles)
					aadd( aFiles, { aTxtFiles[ n, F_NAME], ;
								aTxtFiles[ n, F_SIZE], ;
								aTxtFiles[ n, F_DATE], ;
								aTxtFiles[ n, F_TIME] } )
				next
			endif

		end sequence

		if lError
			waitHand({'Problem Reading this Disk !'})
			loop
		endif

		cFile := ''
		if len(aFiles)== 0
			waitInfo({'No suitable files in this directory', ;
				 cDir })
			loop
		else
			cFile := SelectAfile( aFiles )
			if empty(cFile)
				loop
			endif
		endif

		cDirFile := cDir+cFile

		in window aWin @16,2 winclear to 18,70
		in window aWin @18,2 winsay 'File to import: '+cDirFile

		lConfigure := .f.

		in window aWin @16,2 winsay ;
			'Set columns to display for Report?' ;
			winget lConfigure  picture 'Y' ;
			get_message 'Set columns to Display on Import Report'
		READ

		if lastkey()==K_ESC .or. lastkey()==K_UP
			loop
		endif

		aRpt :=  {}
		rGrowerInfo( aRpt )
		rRcptQty( aRpt )
		rOutConCols( aRpt, .t.  )
		rInConCols( aRpt, .f.  )
		rRawConCols( aRpt )
		rFinPrInfo( aRpt )
		rDockage( aRpt, .f. )
		rDepotSite( aRpt )
		rVarietyEtc( aRpt )     // June 2015
		rProGradeEtc( aRpt )    // April 2020

		gRptInit(RP_IMPORT_DATA_BY_GROWER, aRpt)

		if lConfigure
			gRptSelect( aRpt )
			if yesno({'Save this Format?'})
				gRptSave( aRpt )
			endif
		endif

		LogAnEvent( EVT_TYPE_IMPORT_DATA_STEP1, ;
		            {'Step 1 Import: ' + cDirFile } )

		if !ImportData( cDirFile )                              // Sets nScaleBatch, cScaleDepot, dScaleFromDate,dScaleToDate
	      LogAnEvent( EVT_TYPE_IMPORT_DATA_STOP1, ;
		            {'Stop Import of ' + cDirFile, ;
						'Depot is likely='+cScaleDepot }  )
			loop
		endif

		// has this batch been imported before ???
		lImpBefore := .f.
		if HasThisBeenImpBefore(  )
			lImpBefore := .t.
		endif

		aGaps := {}
		GapAnalyze( aGaps, cDirFile )

		aChooser( 5, 5, aGaps, NIL, 'Note Receipt Gaps in '+cFile)

		aMsg := {}
		if lImpBefore
			aadd( aMsg,'At least some data may already be on file')
		else
			aadd( aMsg,'Data does NOT appear to have been imported before')
		endif
		aadd(aMsg, '')
		aadd( aMsg, ;
			'Start Import by viewing these '+ ;
			lStrim( toPost->(lastRec()))+' records?')

		if !yesno( aMsg )
			LogAnEvent( EVT_TYPE_IMPORT_DATA_STOP2, ;
			 {'Stop Import of ' + cDirFile, ;
			  'Gaps have been analysed.', ;
			  'Depot is likely='+cScaleDepot }  )
			loop
		endif

		CheckForErrors()  // BB Sept 9/99 reports errors in import data

		WaitInfo({'This next report shows data that you MAY import', ;
					 'from the Scale.', cDirFile, ;
					 'Depot is probably='+cScaleDepot })

		if !selectPrn('SCALE.TXT','Select a Printer to show data available to import')
			LogAnEvent( EVT_TYPE_IMPORT_DATA_STOP3, ;
			 {'Stop Import of ' + cDirFile, ;
			  'Did NOT print data...', ;
			  'Depot is likely='+cScaleDepot }  )

		else

			aStru :=	 { ;
				{ 'PRODUCT', 'C', FLD_PRODUCT, 0 }, ;
				{ 'GRADE',   'N', FLD_GRADE,   0 }, ;
				{ 'PROCESS', 'C', FLD_PROCESS, 0 }, ;
				{ 'NET',     'N', 10, 0 } , ;
				{ 'LOADS',   'N',  6, 0 }  }

			dbCreate( 'SUM1', aStru )
			use Sum1 exclusive new

			select toPost
			INDEX ON toPost->Product+str( toPost->Grade, FLD_GRADE) + ;
				toPost->process TO toPost                                                 // FOR !toPost->isVoid
			toPost->(dbGoTop())

			cProduct := replicate('~', FLD_PRODUCT)
			nGrade   := -99
			cProcess := replicate('~', FLD_PROCESS)

			for n := 1 to len( aContain )
				aContain[n,1] := 0
				aContain[n,2] := 0
			next

			do while !toPost->(eof())

				if !empty(toPost->product) .or. str(toPost->net,12,2)<>str(0,12,2)
					if toPost->product<>cProduct .or. ;
							toPost->grade<>nGrade .or. ;
							toPost->process<>cProcess

						cProduct := toPost->product
						nGrade   := toPost->grade
						cProcess := toPost->process

						Sum1->(dbAppend())
						Sum1->Product := toPost->product
						Sum1->Grade   := toPost->grade
						Sum1->Process := toPost->process
					endif

					Sum1->net += toPost->net
					Sum1->Loads++
				endif

				// In and Out...(containers!)
				for n := 1 to MAX_TYPES_CONTAINERS
					nPos := toPost->(fieldPos('IN'+lstrim(n) ))
					aContain[n,1] += toPost->(fieldGet(nPos))

					nPos := toPost->(fieldPos('OUT'+lstrim(n) ))
					aContain[n,2] += toPost->(fieldGet(nPos))
				next

				toPost->(dbSkip())
			enddo

			select toPost
			ToPost->(ordListClear())

			INDEX ON str(toPost->number,FLD_GROWER) + ;
				toPost->Product+str( toPost->Grade, FLD_GRADE) + ;
				toPost->process TO toPost

			toPost->(dbGoTop())
			gRptInitHead()

			aHead := {'Scale Receipts for '+ cDirFile, ;
						 'Depot='+cScaleDepot +' Batch='+var2char(nScaleBatch)}

			do case
			case sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_DOS
				gRptGetSetHead( RPT_HEAD_TITLE, aHead )
			case sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_WIN_NO_PRICE
				gRptGetSetHead( RPT_HEAD_TITLE, aHead )
			case sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_WIN_WITH_PRICE
				aHead[2]+= ' w/ PRICES'
				gRptGetSetHead( RPT_HEAD_TITLE, aHead )
			endcase

			gRptGetSetHead( RPT_HEAD_SUBTOTAL, .t. )
			gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| ToPost->number } )
			gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
				 {|| nuQprnOut( 'Grower: '+str( ToPost->number, FLD_GROWER)+' '+ ;
				           NameOf(LU_GROWER, ToPost->number)       ) } )

			gRptGetSetHead( RPT_HEAD_FOR_CONDITION, {|| !toPost->isVoid } )

			nErr := 0
			gRptGetSetHead( RPT_HEAD_ON_RECORD, ;
				{ || iif( empty(AnyProblems(  )), NIL , nErr++) })

			gRptGetSetHead( RPT_HEAD_ON_RECORD_AFTER_LINE, ;
				{ || nuQprnOut( AnyProblems(  )) })

			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt, 8 )

			do while !toPost->(eof())
				if toPost->isVoid
					toPost->(dbSkip())
				else
					exit
				endif
			enddo

			toPost->(gRptPrinter( aRpt ))
			PrinterCtrl( PRN_CTRL_10_CPI )

			do case
			case nErr == 1
				if nearPageBottom( 6 )
					nuFormFeed()
					nuQprnOut()
					nuQprnOut()
				endif
				nuQprnOut( 'One Error Reported' )
				nuQprnOut( '  Key= '+NT_KEY_1   )
				nuQprnOut( '       '+NT_KEY_2   )
				nuQprnOut( '  '+NT_KEY_3        )

			case nErr > 1
				if NearPageBottom( 6 )
					nuFormFeed()
					nuQprnOut(  )
					nuQprnOut(  )
				endif
				nuQprnOut( lStrim(nErr)+' Errors found' )
				nuQprnOut( '  Key= '+NT_KEY_1           )
				nuQprnOut( '       '+NT_KEY_2           )
				nuQprnOut( '  '+NT_KEY_3                )
			endcase

			nuQprnOut( )
			nuQprnOut( 'Gap analysis' )
			for n := 1 to len(aGaps)
				if nearPageBottom( len(aGaps)+6 )
					nuFormFeed()
					nuQprnOut( )
					nuQprnOut( shMDY(date())+ space(10)+'Import Report continued' )
					nuQprnOut( time() )
					nuQprnOut( )
				endif
				nuQprnOut( aGaps[n] )
			next
			nuQprnOut( )

			PrinterCtrl( PRN_CTRL_10_CPI )
			nuFormFeed()

			aRpt := {}
			SetUpSumRpt( aRpt )
			gRptInitHead()

			aHead := {'Product Summary for Import', ;
                   'Depot:'+alltrim(cScaleDepot) +' Batch='+var2char(nScaleBatch), ;
                   'File=' + cDirFile, ;
						 'From '+shMDY( dScaleFromDate) + ' to '+shMDY( dScaleToDate)  }

			gRptGetSetHead( RPT_HEAD_TITLE, aHead )

			gRptGetSetHead( RPT_HEAD_SUBTOTAL, .t. )
			gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| Sum1->product } )
			gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
				 {|| nuQprnOut( Sum1->product + ' '+ ;
				           NameOf(LU_PRODUCT, Sum1->product)       ) } )

			Sum1->(dbGoTop())
			Sum1->(gRptPrinter( aRpt ))

			nuFormFeed()
			nuQprnOut( )
			nuQprnOut( )
			nuQprnOut( padr(shMDY(date()),30) + padc('Container Receipts/Shipments',40) )
			nuQprnOut( space(30)          + padc('for Batch '+cScaleDepot +'-'+ lStrim(nScaleBatch),40) )
			nuQprnOut( )
			nuQprnOut( )
			nuQprnOut( space(50)+padl('Net',11)+padl('Net',11) )
			nuQprnOut( padr('Container',30)+padl('Received',10)+padl('Shipped',10)+ ;
				padl('Received',11)+padl('Shipped',11) )
			nuQprnOut( )
			for n := 1 to len(aContain)
				if str( aContain[n,1],12,1) <> str(0,12,1) .or. ;
				   str( aContain[n,2],12,1) <> str(0,12,1)

					nuQprnOut( ' '+padr(ContLName( n ),25)+ ;
						  str(aContain[n,1],10) + ;
						  str(aContain[n,2],10) + ;
						  str(aContain[n,1] - aContain[n,2],11)+ ;
						  str(aContain[n,2] - aContain[n,1],11)  )

				endif
			next
			nuQprnOut( )
			nuQprnOut( 'Excludes VOIDED tickets...' )
			nuQprnOut( )
			nuQprnOut( 'End.' )
			nuQprnOut( )

			PRINT_OFF  RPT_COMPLETE_EJECT

			// toPost->(dbCloseArea())
			Sum1->(dbCloseArea())

			do case
			case nErr == 1
				aMsg := {'There is one record with a problem with', ;
					'data problems (including void)'}
				aadd( aMsg,'You can correct this later' )
				aadd( aMsg,'')
			case nErr > 1
				aMsg := {'There are '+lStrim(nErr)+' records with problems with', ;
					'data problems (including voids)'}
				aadd( aMsg,'You can correct these later' )
				aadd( aMsg,'')
			otherwise
				aMsg := {}
			endcase

			aadd( aMsg, 'Do you want to update the master files with this batch of receipts ?')
			aadd( aMsg, '  We think the Depot/Batch # is '+ cScaleDepot + var2char( nScaleBatch) )
			aadd( aMsg, '-Please note the batch #-')
			aadd( aMsg, ' '+cDirFile )

			inkey()
			if !yesno( aMsg )
				LogAnEvent( EVT_TYPE_IMPORT_DATA_STOP4, ;
				{'Stop Import of ' + cDirFile, ;
				'Gaps have been analysed.', ;
				'Depot is likely='+cScaleDepot }  )

			else
				ThePost( cDirFile )
				lErase := .f.
				cDirBU := ''

				BEGIN SEQUENCE
					if !file(cDirFile)
						waitInfo({'Weird - we can not find the file:',' '+ cDirFile})
					else
						c := upper( cDirFile )
						cDirBU := strTran( c, '.'+upper(cExt) , '.BU' )
						if file( cDirBU )
							if fErase(cDirFile)<>0
								WaitInfo({'Can NOT erase a BACKUP '+cDirBU })
						  endif
						endif
						if fRename( cDirFile, cDirBU )==0
							lErase := .t.
						endif
					endif
				END SEQUENCE

				if lErase
					WaitInfo({'We Renamed the import file from Scale Computer', ;
						'to ensure that it will not accidentally be imported.', ;
						'It is called '+cDirBU, ;
						'This is good.'})
				else
					WaitInfo({'Could not erase the file from Scale Computer', ;
						'Dir/File='+cDirFile, ;
						'Be sure you do not import it again!'})
				endif
			endif
		endif
	enddo

	kill window aWin
return( lReturn )

static Function thePost( cDirFile )
	local nCount
	local nID, nLowID, nHighID
	local nUnique_ImpBatch := 0
	local nLowRcpt,nHighRcpt
	local d1,d2
	local nDeleted := 0
	local nRecNo   := 0    // First Voided Record

	msgLine('Now Finding the IDs...')

	// Now we start the Import
	nUnique_ImpBatch := nAddUniqueRec( UF_THE_UNIQ_IMBAT, .f. )    // should NOT need locks - therefore FALSE...

	MsgLine('Updating the IDs...' )

	LogAnEvent( EVT_TYPE_IMPORT_DATA_STEP2, ;
		            {'Step 2 Unique Import Batch=' + var2char( nUnique_ImpBatch), ;
						 'Depot Batch # is Depot='+var2char( cScaleDepot)+'  Batch#='+var2char( nScaleBatch),      ;
						  var2char( cDirFile) } )

	ToPost->(dbSetOrder( 0 ))
	ToPost->(dbGoTop())

	nCount       := 0
	nLowRcpt     := 0
	nHighRcpt    := 0
	d1           := date()+1000
	d2           := date()-2000
	nLowID       := 999999999
	nHighID      := 0

	do while !ToPost->(eof())
		nCount++

		ToPost->uniq_imbat  := nUnique_ImpBatch

		if ToPost->isVoid
			ToPost->pr_Note1 := 'Voided at Scale NOT imported'
			nAddUniqueRec( UF_THE_DAYAUD_ID, UNIQ_FILE_DO_NOT_NEED_LOCKS  )   // Table is Locked
			ReplOneRec('ToPost', 'Daily_Audit')     // Note that this RECORD in Daily_Audit.DBF will have a 0 for the ->day_uniq !

			Add2Void( 'Voided at Scale','ToPost' )
			if nRecNo == 0
				// First Record...
				nRecNo := VoidTck->(recno())
			endif

			ToPost->(dbDelete())
			ToPost->(dbCommit())
			nDeleted++
		else

			nAddUniqueRec( UF_THE_DAY_UNIQ , UNIQ_FILE_DO_NOT_NEED_LOCKS  )                    // Table is Locked
			ReplOneRec('ToPost', 'Daily', { UF_THE_DAY_UNIQ }  )                               // Daily->DAY_UNIQ has the Unique key in it,

			nAddUniqueRec( UF_THE_DAYAUD_ID, UNIQ_FILE_DO_NOT_NEED_LOCKS  )                    // Table is Locked
			ReplOneRec('Daily', 'Daily_Audit')
			Daily_Audit->np_note1 :=  IMPORTED_FROM_SCALE_PC  + shMdy(date())+' '+time()        // This to make CLear this record was imported

			nID := Daily->day_uniq                                   // Unique Identifier of the Daily->   transaction
			showProg( str(nID++,8))
			if nLowID > nID
				nLowID := nID
			endif
			if nID > nHighID
				nHighID := nID
			endif
		endif

		// So these calculations include VOIDS
		if nLowRcpt <= 0
			nLowRcpt := ToPost->recpt
		else
			nLowRcpt := min(ToPost->recpt,nLowRcpt)
		endif

		nHighRcpt   := max( ToPost->recpt, nHighRcpt )

		d1 := min( ToPost->date, d1 )
		d2 := max( ToPost->date, d2 )

		ToPost->(dbSkip())
	enddo

	ToPost->(dbCloseArea())

	ImpBat->depot     := cScaleDepot        // July 2013 - logic changed in May 2020 !  Same Intent though!
	ImpBat->imp_bat   := nScaleBatch   //  but this is changed a bit in 2020
	                                   //  the DEPOT + IMP_BAT should be UNIQUE in this file, but they can NOT
												  //  be guaranteed to be unique, as this information is drawn from the import file.
	ImpBat->DATE         := date()
	ImpBat->DATA_DATE    := d1         // who cares, was the actual date

	ImpBat->LOW_DATE    := d1          // new IMPORT
	ImpBat->HIGH_DATE   := d2

	dScaleFromDate      := d1
	dScaleToDate        := d2

	ImpBat->NO_TRANS   := nCount
	ImpBat->LOW_ID     := nLowID
	ImpBat->HIGH_ID    := nHighID
	ImpBat->LOW_RECPT  := nLowRcpt
	ImpBat->HI_RECPT   := nHighRcpt

	ImpBat->voids      := nDeleted
	ImpBat->imp_file   := right( alltrim( cDirFile), FLD_IMP_FILE_NAME )

	ImpBat->(dbCommit())

	Daily->(dbCommit())
	Daily->(dbCloseArea())
	OpenFile({'Daily'},DB_EXCLUSIVE)

	LogAnEvent( EVT_TYPE_IMPORT_DATA_TICKETS, { ;
		            'Imp. Batch from Depot:' + var2Char( cScaleDepot ) + Var2char( nScaleBatch)+' UniqBat#='+ var2char( nUnique_ImpBatch ) ,  ;
						'File: '+alltrim(cDirFile),                                             ;
						'Dates from: '  + shMDY( d1) + ' to ' + shMDY( d2 ),                    ;
						'# tickets = '  + var2Char( nCount),                                    ;
						'Recpt ID fr: ' + var2Char( nLowID) + ' - ' + var2Char( nHighID ),      ;
						'Receipt# fr: ' + var2char( nLowRcpt ) +' - ' + var2char( nHighRcpt),   ;
						'Deleted Tks= ' + var2char( nDeleted )             }   )

	if nDeleted > 0
		if yesno({'We DELETED ' +lStrim( nDeleted)+' void ticket(s)!', ;
			'Would you like to List these?', ;
			'You can Print this report later from the:', ;
			' Reports Menu', ;
			'  Transaction Detail', ;
			'   Voided Tickets'})

			if selectPrn('IMPVOID.TXT')
				VoidTck->(OrdSetFocus( 0 ))
				if nRecNo > 0
					VoidTck->(dbGoTo(nRecNo))

					PRINT_ON  RPT_OVERWRITE

					VoidPrnter( { || !VoidTck->(eof()) } , ;
					  {'Voided tickets imported on '+shMDY(date()) } )

					PRINT_OFF  RPT_COMPLETE_EJECT
				else
					waitHand({'Bizarre printing problem...'})
				endif
			endif
		endif
	endif

return( nil )

static function ImportData( cDirFile )
	local lReturn := .f.

	InitScaleBatchStatics()

	do case
	case sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_DOS
		WaitInfo({'We no longer support Import From DOS version'})
	case sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_WIN_NO_PRICE
		// lReturn := ImpFrWinFmt1( cDirFile )
		lReturn := ImpFrWinFmt2020( cDirFile )
	case sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_WIN_WITH_PRICE
		// lReturn := ImpFrWinFmt1( cDirFile )
		lReturn := ImpFrWinFmt2020( cDirFile )
	endcase
return( lReturn )


// for Win Version of Scale ------------------------ the OLD ONE - is in copies of source in Feb 2020 and back!
// this can be USED for any Windows Format - modified in Mar 2020
static function ImpFrWinFmt2020( cDirFile )
	local lReturn := .f.
	local nNet := 0.0
	local n, nNoDockage := 0, nHasDockage := 0
	local nAdjNet  := 0.0
	local nPrice   := 0.00
	local nDockPct := 0   // 15% = 15
	// local cTmp1, cTmp2
	local nCnt, nRecords
	local cStr
	local nContainer
	local nIn, nOut
	local cContainer
	local aRay
	local cData,cLine
	local nStart,nEnd
	local c_Cont1,    c_EditReason, c_Certified, c_PriceInFile                    // May 2020 - part of refactoring
	local nCertified, nEditReason,  nB4container, nCont1, nPriceInFile
	local lCertified      := .f.  // July 2013
	local lFrom_Field     := .f.  // Mar 2020
	local lPriceInFile    := .f.  // changed code for this in 2020 - now look file.
	local cFrom_FieldName := ''
	local aImpBatches        := {}    // should just contain one record
	local nFileNameImpBat    := -1     // deduced from Name of the File
	local cTmp               := ''
	local lPeriod            := .f.
	local lFound             := .t.

	msgLine( 'Can we import...' )

	if !file(cDirFile)
		waitHand({'We can not find '+cDirFile})
		return( lReturn )
	endif

	MakeScaleNew()

	msgLine('If this fails - means the EXPORT file is Bad!')

	for n := len( cDirFile) to 1 step -1
		do case
		case lPeriod .and. substr( cDirFile, n, 1)=='.'
			exit

		case substr( cDirFile, n, 1)=='.' .and. !lPeriod
			lPeriod := .t.

		case lPeriod
			do case
			case len( cTmp ) >= 8
				exit
			case isDigit( substr( cDirFile, n, 1))
				cTmp := substr( cDirFile, n, 1) + cTmp
			case len( cTmp ) >= 3
				// imp[lied NOT a digit, so good bye....
				//  we do NOT want to grab a batch no like this 8X123.CSV as 8123, it should be 123...
				//  of course this is NOT perfect..
				exit
			case n < len( cDirFile ) -3 .and. empty( cTmp )
				showProg( n )
			otherwise
				exit
			endcase
		endcase
	next

	// We should get a batch Nummber
	if len( cTmp ) >= 1
		nFileNameImpBat := val( cTmp )
		aadd( aImpBatches, val( cTmp ) )
	else
		appError( APP_ERR_GLITCHY_IMPORT_0, { ;
		  'This is ODD - we expect a Batch Number in the file name', ;
		  'but we were not able to deduce one!', ;
		  'this is NOT an Error, but it should not happen normally!', ;
		  'File='+cDirFile })
	endif

	cData := ''

	begin sequence
		nNoDockage  := 0
		nHasDockage := 0

		// This statement has PROBLEMS in Alaska 190, so we do something else...
		/* --------------------
			select TempGunk
			APPEND FROM (cDirFile) SDF
		---------------------------- */

		cData := MemoRead( cDirFile )
	end sequence

	if len( cData ) <= 100
		appError( APP_ERR_GLITCHY_IMPORT_1, ;
		  {'There is NOT enough Data in this to be a valid import file', ;
		   'File='+cDirFile, ;
		   'Length of Data file='+var2char( len( cData )), ;
			'The following line shows data in the file', ;
			' '+ substr( cData, 1,70) } )

		LogAnEvent( EVT_TYPE_IMPORT_NO_DATA, ;
				 {'No data to Import ! - File Size='+var2char( cData)+'  Header:', ;
				  substr(cData,1                ,  min( FLD_NOTE, len( cData) )), ;
				  substr(cData,FLD_NOTE + 1     ,  min( 2*FLD_NOTE, len( cData) )), ;
				  substr(cData,2 * FLD_NOTE + 1 ,  min( 3*FLD_NOTE, len( cData) )), ;
				  'App Error Code='+APP_ERR_GLITCHY_IMPORT_1				  })

		return( lReturn )
	endif


	// --------- This is re-written in Spring 2020 -----------------------------------------
	//  We have 4 cases in the import files:
	//    1.  "EDIT REASON","CONT1"                                the "base case from 2000"
	//    2.  "EDIT REASON","some field","CONT1"                   the "change requested by Westberry for 2020 season" - harvest field info
	//    3.  "EDIT REASON","CERTIFIED","CONT1"                    a change for South Alder in 2013 or so
	//    4.  "EDIT REASON","CERTIFIED","some field","CONT1"       if we have Certified and Harvest field Info
	//
	//  In any of these cases, we have the configuration of THIS program - do we have the Harvested From Field data field
	//  correctly identified?
	//    i.e. SysValue( FROM_FIELD ) is either Blank, filled in as expected, or filled in NOT as Expected.
	//    We WARN if this is NOT CORRECT.
	// We MUST find "EDIT_REASON" and "CONT1"! in the first 1,000 characters of cData
	//  ED REAS_CONT1                   1   //    the "base case from 2000"
	//  ED_REAS_HARV_FR_FLD_CONT1       2   //    the "change requested by Westberry for 2020 season" - harvest field info
	//  ED REAS_CERT_CONT1              3   //    a change for South Alder in 2013 or so
	//  ED_REAS_CERT_HARV_FR_FLD_CONT1  4   //    if we have Certified and Harvest field Info-hypothetical at this point

	c_EditReason  := '","EDIT REASON","'
	c_Certified   := '","EDIT REASON","CERTIFIED","'
	c_Cont1       := '","CONT1","'
	c_PriceInFile := '","GROWERID","PRICE","'

	nCont1           := at( c_Cont1,       substr( cData,1,1000) )         // these both MUST be present
	nEditReason      := at( c_EditReason,  substr( cData,1,1000) )        // or the file is NOT a valid format to Import
	nPriceInFile     := at( c_PriceInFile, substr( cData,1,1000) )        // this is Optional

   if at( c_EditReason + c_Cont1, substr( cData,1,1000) ) > 0 .or. ;
	   at( c_Certified  + c_Cont1, substr( cData,1,1000) ) > 0

		appError(APP_ERR_GLITCHY_IMPORT_2 ,  ;
			 {"We seem to have a BLANK Field Name after EDIT REASON", ;
			  c_EditReason + c_Cont1 + "=" + var2char(at( c_EditReason + c_Cont1 , substr( cData,1,1000) )), ;
			  c_Certified  + c_Cont1 + "=" + var2char(at( c_Certified  + c_Cont1 , substr( cData,1,1000) )), ;
			  "File="+cDirFile, ;
			  "You should correct this.  We can NOT IMPORT the data!" })

		LogAnEvent( EVT_TYPE_IMPORT_NO_DATA, ;
				 {'Bad Field Header in Import File', ;
				  'Blank Field NAME', ;
				  'App Error Code='+APP_ERR_GLITCHY_IMPORT_2 })

		return( lReturn )
   endif

	if nPriceInFile > 0 .and. sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_WIN_WITH_PRICE
		if sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_WIN_WITH_PRICE
			msgLine('Importing price...normal')
		else
			appError(APP_ERR_GLITCHY_IMPORT_3 ,  ;
			 {"We are NOT set to import price in cisBerry, but it is present in Scale File Data!", ;
			  "nPriceInFile="+var2char( nPriceInFile), ;
			  "see: "+ substr( cData, nPriceInFile, len( c_PriceInFile) + 10), ;
			  "File="+cDirFile, ;
			  "You should correct this.  We will IMPORT the price!" })
		endif
	else
		if sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_WIN_NO_PRICE
			msgLine('Price is NOT in scale file...normal')
		else
			appError(APP_ERR_GLITCHY_IMPORT_4 ,  ;
			 {"We ARE set to import price in cisBerry, but it is NOT present in Scale File Data!", ;
           "The Import Format =" + var2char( sysValue( SYS_IMPORT_FORMAT ) )                  , ;
			  "nPriceInFile="+var2char( nPriceInFile ), ;
			  "File="+cDirFile                        , ;
			  "You should correct this.  Something is screwy!" })
		endif
	endif

   if nPriceInFile > 0
		lPriceInFile := .t.
   else
   	lPriceInFile := .f.
   endif

	if num2Equal0( nCont1 ) .or. num2Equal0( nEditReason )
		appError(APP_ERR_GLITCHY_IMPORT_5 ,  ;
				 {"Did NOT find EDIT REASON and/or CONT1 field heading", ;
				  "nCont1="+var2char( nCont1)+ "  nEditReason="+var2char( nEditReason), ;
				  "should find: "+c_EditReason+" & "+c_Cont1, ;
				  " "+ substr(cData, 1,70), ;
				  " "+ substr(cData,71,70), ;
				  "File="+cDirFile, ;
				  "This is NOT a proper import file! - We will NOT IMPORT IT!" })

		WaitInfo( {'Error Code=' + APP_ERR_GLITCHY_IMPORT_5, ;
					  'We will NOT import this file.' })

		LogAnEvent( EVT_TYPE_IMPORT_NO_DATA, ;
				 {'No Edit Reason or CONT1 in Import File', ;
				  'App Error Code='+APP_ERR_GLITCHY_IMPORT_5 })

		return( lReturn )

	endif

	nCertified       := at( c_Certified,substr( cData,1,1000) )
	nB4Container     := nEditReason + len( c_EditReason )

	// July 2013 - is there a "CERTIFIED" field in there
	// If  CERTIFIED is there, the next field will be either NCONT1 or the Harvest From Field ID
	if nCertified > 0
		nB4container     := nCertified + len( c_Certified )
		if nCertified > 800
			waitInfo({"Found CERTIFIED pretty FAR along!", ;
						 "We found it at position="+var2char( nCertified) })
		endif
		lCertified      := .t.
	endif

	// Suppose we have something like this:
	//         the position of nCont1 | = 189 i.e. the start of ","CONT1
	//                               | this = 188
	//  ","EDIT REASON","CERTIFIED","F","CONT1"   ","EDIT REASON","F","CONT1"  ","EDIT REASON","F","CONT1"   ","EDIT REASON","CONT1"
	//    nEditReason   == 159                      nEditReason   == 159         nEditReason   == 159          nEditReason   == 159  - SAME
	//    nCertified    == 159
	//    nCont1        == 189                      nCont1        ==             nCont1        ==              nCont1        == 173
	//    nB4Container  == 188                      nB4Container  ==             nB4Container  ==              nB4Container  == 176

	cFrom_FieldName := ''
	if nCont1 > nB4Container              // because nCont1 starts a the last quote of previous field-the "-" is 3 characters
		for n := nB4Container to nCont1
			if !( substr( cData, n, 1)=='"' .or. substr( cData, n, 1)== "'" .or. substr( cData, n,1)==',' )
				cFrom_FieldName += substr( cData, n, 1)
			endif
		next
	endif

	lFrom_Field     := .f.                                                           // Mar 2020

	do case
	case empty( cFrom_FieldName ) .and. empty( sysValue( SYS_IMPORT_FROM_FIELD_NAME ))
		msgLine('No From Harvest Field data recorded...normal')

	case empty( cFrom_FieldName ) .and. !empty( sysValue( SYS_IMPORT_FROM_FIELD_NAME ))
		msgLine('Importing but no data is in file for ' + sysValue( SYS_IMPORT_FROM_FIELD_NAME ) )

		nImportErrors++
		appError(APP_ERR_GLITCHY_IMPORT_6 ,  ;
			 {"There is no FROM FIELD in this DATA - but you are configured to"   , ;
			  "expect this data.  We will allow you to import the data, but you"     , ;
			  "should correct the configuration of cisBerryPay."                     , ;
			  "File="+cDirFile, ;
			  "Configured to expect From Field in the import file: "+ sysValue( SYS_IMPORT_FROM_FIELD_NAME )   })

	case !empty( cFrom_FieldName ) .and. empty( sysValue( SYS_IMPORT_FROM_FIELD_NAME ))

		nImportErrors++
		appError(APP_ERR_GLITCHY_IMPORT_7 ,  ;
			 {"There is a FROM FIELD in this DATA - but you are NOT configured to"   , ;
			  "expect this data.  We will allow you to import the data, but you"     , ;
			  "should correct the configuration of cisBerryPay."                     , ;
			  "File="+cDirFile, ;
			  "We found this Harvest From Field in the import file: "+cFrom_FieldName    })

		lFrom_Field := .t.

	case !empty( cFrom_FieldName ) .and.   !empty( sysValue( SYS_IMPORT_FROM_FIELD_NAME ) )
		lFrom_Field := .t.

		if upper( alltrim( cFrom_FieldName)) == upper( alltrim( sysValue( SYS_IMPORT_FROM_FIELD_NAME )))
			msgLine('The From Harvest Field data is as Expected...normal' )
		else
			// We did NOT find the FROM FIELD which we expected to find
			nImportErrors++
			appError( APP_ERR_GLITCHY_IMPORT_8 ,  ;
				 {"The SCALE Program and cisBerryPay Program are NOT configured to", ;
				  "match one another.  You should correct this!", ;
				  " cFrom_Field from Scale File="+cFrom_FieldName, ;
				  " the cisConfiguration is set="+sysValue( SYS_IMPORT_FROM_FIELD_NAME  ), ;
					"File="+cDirFile, ;
				  "Please correct your System Settings!"})

			WaitInfo({"The import will still work but you should correct", ;
						 "this problem.  See ERROR CODE=" + APP_ERR_GLITCHY_IMPORT_8 })
		endif

	otherwise
		nImportErrors++
		appError( APP_ERR_GLITCHY_IMPORT_9 ,  ;
				 {"We are NOT sure why this error message has come up",  ;
				  "Please contact Crafted Industrial Software ASAP",     ;
				  "We suggest you DO NOT IMPORT this file",              ;
				  "File="+cDirFile, ;
				  "nCont1="+var2char( nCont1 ) + "  cFrom_FieldName=" + var2char( cFrom_FieldName), ;
				  "SysValue( FLD NAME )=" + sysValue( SYS_IMPORT_FROM_FIELD_NAME ) })

		if Yesno({"Do wish to ABORT this Import?"})

			LogAnEvent( EVT_TYPE_IMPORT_ABORT_1, ;
				 {'We aborted an IMPORT ! - File Size='+var2char( cData)+'  Header:', ;
				  substr(cData,1                ,  min( FLD_NOTE, len( cData) )), ;
				  substr(cData,FLD_NOTE + 1     ,  min( 2*FLD_NOTE, len( cData) )), ;
				  substr(cData,2 * FLD_NOTE + 1 ,  min( 3*FLD_NOTE, len( cData) )), ;
				  'AppError Code=' + APP_ERR_GLITCHY_IMPORT_9 })

			return( lReturn )
		endif
	endcase

	//  ----  According to Alaska this is slow etc
	// nLines := mlCount( cData, 600, 1, .f. )
	// for n := 1 to nLines
	//    cLine := MemoLine(  cData, 600, n, 1, .f. )
	//    TempGunk->(dbAppend())
	//    TempGunk->(FieldPut( 1, cLine ))
	// next
	// TempGunk->(dbCommit())
	//
	// this is better
	// -------------------------------------
	// nStart := At( CR_LF, cData )
	// DO WHILE nStart > 0
	//    cLine := SubStr( cData, 1, nStart-1 )
	//    TempGunk->(dbAppend())
	//    TempGunk->(FieldPut( 1, cLine ))
	//   cData := SubStr( cData, nStart+2 )
	//   nStart := At( CR_LF, cData )
	// enddo
	// -----------------------------------------
	// Still Better

	nStart := 1

	nEnd := At( CR_LF, cData, nStart )
	DO WHILE nEnd > 0
		TempGunk->(dbAppend())
		TempGunk->(FieldPut( 1, SubStr( cData, nStart, nEnd-nStart ) ))
		nStart := nEnd + 2
		nEnd := At( CR_LF, cData, nStart )
	ENDDO

	IF nStart < Len( cData )
		cLine := SubStr( cData, nStart, len( cData )-nStart )
		cLine := strTran( cLine, chr(10), '')
		cLine := strTran( cLine, chr(13), '')
		TempGunk->(dbAppend())
		TempGunk->(FieldPut( 1, cLine ) )
	endif

	nRecords := 0
	TempGunk->(dbGoTop())
	do while !TempGunk->(eof())
		// We skip Blank lines and the Heading Line
		if upper(substr( TempGunk->textInfo,2,6))<>'SITEID' .and. len( alltrim( TempGunk->textInfo )) > 3
			nRecords++

			ToPost->(AddRecord())
			// Site (depot)       .
			// Ticket             .
			// Void               .
			// Batch              .
			// Prod               .
			// Grade              .
			// DateIn             .
			// TimeIn             .
			// Grower ID          .
			// price -  We MIGHT import this/field is OPTIONAL !!.
			// Dockage PCT        .
			// NET weight         .
			// Add Date           .
			// Add by             .
			// Ed Date            .
			// Edit By            .
			// Ed Reason          .
			// Certified          . - we MIGHT import this field is OPTIONAL
			// Potentially we have the FROM_FIELD - after Certified - which is optional.
         // then the ---
			//   Containers  ID,In,Out

			nCnt := 1
			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			ToPost->depot := cStr

			if !empty( ToPost->depot)
				do case
				case empty( cScaleDepot )
					cScaleDepot := ToPost->Depot
				case !(ToPost->depot == cScaleDepot )
					nImportErrors++
					if nImportErrors < 8
						appError( APP_ERR_GLITCHY_IMPORT_10 , ;
						  {'Problem with SITE ID (depot) =' + cStr, ;
							'We expected to see:' + cScaleDepot, ;
							'Import Ticket Row is '+var2char( nRecords), ;
							'This is a TECHNICAL PROBLEM WITH the IMPORT DATA FILE!'})
					endif
				endcase
			else
				nImportErrors++
				if nImportErrors < 8
					appError( APP_ERR_GLITCHY_IMPORT_11, ;
					  {'Problem with SITE ID (depot) =' + cStr,           ;
						'It is EMPTY as far at the program is concerned',  ;
						'Import Ticket Row is '+var2char( nRecords),       ;
						'This is a TECHNICAL PROBLEM WITH the IMPORT DATA FILE!'})
				endif
			endif

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			if str( val( cStr ), FLD_RECPT ) == replicate( '*',FLD_RECPT)
				ToPost->recpt := val( ;
				  right( str( val( cStr ), 12 ), FLD_RECPT) )

				nImportErrors++
				appError(APP_ERR_FIELD_WIDTH1 , ;
				  {'This ticket number is too wide '+cStr , ;
					'we chopped it up though for now!', ;
					'Row is '+var2char( nRecords) })
			else
				ToPost->recpt := val( cStr )
			endif

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			if !empty(cStr)
				if substr(cStr,1,1) == 'Y' .or. substr(cStr,1,1) == 'T' ;
					.or. substr(cStr,1,1)='V'
					ToPost->isVoid := .t.
				endif
			endif

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			ToPost->imp_bat := val(cStr)                         // Import Batch, supposedly Field->depot + str( Field->imp_bat )
																				  // are a Unique Batch No.
			// Logic changed a little here in April 2020
			if len( aImpBatches )==0
				aadd( aImpBatches, ToPost->imp_bat )

				if !( str( ToPost->imp_Bat, 8) == str( nFileNameImpBat, 8 ))
					nImportErrors++
					appError( APP_ERR_BATCH_FILE_NAME_ISSUE  , ;
					  {'Batch Number does NOT agree with File Name!', ;
						'File Name is: ' + cDirFile, ;
						'Expected BatchNo is: ' + var2char( nFileNameImpBat ), ;
						'Batch Number from Import Data is: ' + var2char( ToPost->imp_Bat ), ;
						'Previously noted batch#: '+lStrim(nScaleBatch) })
				endif

			else
				lFound := .f.
				for n := 1 to len( aImpBatches )
					if aImpBatches[ n ] ==  ToPost->imp_bat
						lFound := .t.
						exit
					endif
				next

				if !lFound
					aadd( aImpBatches, ToPost->imp_bat )

					LogAnEvent( EVT_TYPE_IMPORT_MULTI_BRANCH ,  { ;
					  'Seem to have Multiple Branches in Batch',  ;
					  cDirFile,                                   ;
					  var2char( aImpBatches)                    }  )

					nImportErrors++
					if nImportErrors < 8
						appError( APP_ERR_BATCH_MORE_MULTIPLES  , ;
						  {'Multiple Batches here',                                       ;
							'Previously noted batch# '+lStrim(nScaleBatch),                  ;
							'Current Batch is        '+lStrim(ToPost->imp_bat),            ;
							'Expected Batch# from FileName: '+ var2char( nFileNameImpBat), ;
							'File Name is: ' + cDirFile,                                   ;
							'All Batches so far: '+var2char( aImpBatches)  })
					endif
				endif
			endif


			do case
			case nScaleBatch == 0
				nScaleBatch := ToPost->imp_bat
			case !(nScaleBatch == ToPost->imp_bat)
				nImportErrors++
				if nImportErrors < 8
					appError( APP_ERR_BATCH_MULTIPLE_NO  , ;
					  {'Multiple Batches here', ;
						'Previously noted batch# '+lStrim(nScaleBatch), ;
						'Current Batch is        '+lStrim(ToPost->imp_bat) })
				endif

				nScaleBatch := ToPost->imp_bat
			endcase

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			ToPost->long_prod := cStr    // Audit of what was Imported.
			ToPost->product   := cStr   // This effectively Truncates!

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			ToPost->long_proc := cStr
			ToPost->process   := substr(cStr,1,2)  // FLD_PROCESS

			ToPost->variety   := VarietyDefaulter( ToPost->long_prod, ToPost->long_proc )
			do case
			case len(alltrim(cStr)) >= 3            // FLD_GRADE_POSITION
				// June 2015 this was changed from:
				//      case len(alltrim(cStr))==3
				// to the >=

				if isDigit( substr( allTrim(cStr),3,1))
					ToPost->grade := val( substr(alltrim(cStr),3,1) )
				else
					if ValidTest(V_PROCESS_TYPE, ToPost->process,VT_NO_MESSAGE)
						if Process->def_grade > 0
							ToPost->grade := Process->def_grade
						else
							ToPost->grade := 1
						endif
					else
						ToPost->grade := 1
					endif
				endif
			case len(alltrim(cStr))==2
				ToPost->grade := 1
			case len(alltrim(cStr))==0
				ToPost->grade := 0
			endcase

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )   // MM-DD-YYYY
			cStr := strTran( cStr, '-','/' )
			ToPost->date    := ctod( cStr )

			if ToPost->date < sysValue( SYS_CURRENT_SEASON_START )     .or. ;
            ToPost->date > sysValue( SYS_CURRENT_SEASON_END )       .or. ;
			   !(year( ToPost->date ) == sysValue( SYS_CURRENT_YEAR )) .or. ;
				ToPost->date > date()

				nImportErrors++

				if nImportErrors < 10
					appError( APP_ERR_GLITCHY_IMPORT_12, ;
					{'Bad Date on Receipt: '+ToPost->depot+'-'+var2char( ToPost->recpt), ;
					 'Date on Receipt: ' + var2char( ToPost->date), ;
					 'Start of Season Set as:  ' + var2char(sysValue( SYS_CURRENT_SEASON_START )),  ;
					 'End of Season is Set as: ' + var2char(sysValue( SYS_CURRENT_SEASON_END   )),  ;
					 'Crop Year is (sysValue): ' + var2char(sysValue( SYS_CURRENT_YEAR )) })
				endif
			endif

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			ToPost->time     := cStr

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			ToPost->number   := val( cStr )

			// price
			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			ToPost->PriceSrc := PRICE_SRC_FILE

			// I change this in May 2020 - if the price is in the file, we should import it & mainly
			// we should get the correct data imported.
			//
			// Old Code:
			//       if sysValue(SYS_IMPORT_FORMAT)==SY_IMP_FMT_WIN_WITH_PRICE
			//

			if lPriceInFile
				nPrice := val(cStr)
				do case
				case nPrice >= MAXIMUM_PRICE
					nPrice := 0.00
					appError( APP_ERR_IMPORTED_PRICE_TOO_HIGH , ;
					  {'Price in Receipt '+ ToPost->depot+ str( ToPost->recpt,10)+ ' is TOO HIGH', ;
						'It is over '+str( MAXIMUM_PRICE, 10,2)+ ' so we SET TO ZERO!'})
				case nPrice <= -0.01
					nPrice := 0.00
					appError( APP_ERR_IMPORTED_PRICE_NEGATIVE , ;
					  {'Price in Receipt '+ ToPost->depot+str( ToPost->recpt,10)+ ' is NEGATIVE', ;
						'It is LESS than ZERO so we SET TO ZERO!'})
				endcase

				ToPost->thePrice := nPrice
				if str(ToPost->thePrice,10,2)<>str(0,10,2)
					ToPost->PriceSrc := PRICE_SRC_SCALE
				endif
			endif

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )

			// This was changed on Aug 7, 2008
			//   ToPost->dock_pct := val(cStr)
			nDockPct := val(cStr)

			do case
			case nDockPct >= 99
				nImportErrors++
				nDockPct := 0
				appError( APP_ERR_IMPORTED_DOCKAGE_TOO_HIGH , ;
					{'Dockage in Receipt '+ ToPost->depot+str( ToPost->recpt,10)+ ' is TOO HIGH', ;
					'It is over 98% so we SET TO ZERO!'})
			case nDockPct <= -0.01
				nImportErrors++
				nDockPct := 0
				appError( APP_ERR_IMPORTED_PRICE_NEGATIVE , ;
					{'Dockage in Receipt '+ ToPost->Depot+ str( ToPost->recpt,10)+ ' is NEGATIVE', ;
					'It is LESS than ZERO so we SET TO ZERO!'})
			endcase

			ToPost->dock_pct := nDockPct

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			nNet := val( cStr )
			do case
			case right( cStr,2 )=='.5' .or. right(cStr,3)=='.05'
				nNet := round( nNet + 0.45,0)  // always round these up
			case right( cStr,2 )=='.0' .or. right(cStr,3)=='.00' .or. ;
				  at( '.',cStr)==0
				ShowProg( cStr )
				// no need to round at all!

			case sysValue( SYS_IMPORT_ROUND_NET_METHOD )=='U'
				nNet += 0.48   // to make sure it goes up
				nNet := round( nNet,0)
			otherwise
				nNet := round( nNet,0)
			endcase

			// We deal with DOCKAGE !!
			ToPost->ori_net := nNet
			nAdjNet         := nNet

			do case
			case str( nDockPct, 6) == str(0,6)
				nNoDockage++
			case sysValue( SYS_DOCKAGE_ACTION )== DOCKAGE_ACTION_WARN
				nHasDockage++
				aRay := {'Dockage taken on Depot/Receipt: '+ ;
						  ToPost->depot+' '+ lstrim(ToPost->recpt), ;
				 'Grower ID: '    +lstrim( ToPost->number) }
				aadd( aRay,  'Net weight is: '+str(nNet,6) )
				aadd( aRay,  'Dockage is: '   +lStrim(nDockPct)+'%' )
				aadd( aRay,   'PLEASE ADJUST THIS RECEIPT - receipt NOT adjusted!')
				waitinfo( aRay )

			case sysValue( SYS_DOCKAGE_ACTION )== DOCKAGE_ACTION_CHANGE
				nHasDockage++
				do case
				case nDockPct >= 100
					nAdjNet  := 0
				case nDockPct <= 0
					nAdjNet  := nNet
				otherwise
					nAdjNet  := nNet * ( (100-nDockPct) /100 )
				endcase

				aRay := {'Dockage taken on Depot/Receipt: '+ ;
					 ToPost->depot+' '+lstrim(ToPost->recpt), ;
				 'Grower ID: '+lstrim( ToPost->number)}
				aadd( aRay, 'Net weight Taken as: '+str(nAdjNet,6) )
				aadd( aRay, 'Original Net was:    '+str(nNet,6) )
				aadd( aRay, 'Dockage is: '+lstrim(nDockPct)+'%' )

				waitInfo( aRay )

			case sysValue( SYS_DOCKAGE_ACTION )== DOCKAGE_ACTION_NO_ACTION
				nHasDockage++
			otherwise
				// really the same as above...
				nHasDockage++
			endcase

			ToPost->net := nAdjNet

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			// MM-DD-YYYY
			cStr := strTran( cStr, '-','/' )
			ToPost->add_date := ctod( cStr )                               // Date added NOT used for computation

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			ToPost->add_by := cStr

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )                  // MM-DD-YYYY
			cStr := strTran( cStr, '-','/' )
			ToPost->edit_date := ctod( cStr )                                // Edited date NOT used for computation

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			ToPost->edit_by := cStr

			cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
			ToPost->edit_reas := cStr

			// July 2013 - have we added the "CERTIFIED" field!
			if lCertified
				cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
				ToPost->certified := cStr
			endif

			// ---------------- This Section for "from_Field" data - noted in July 2019 !!
			if lFrom_Field
				cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
				ToPost->FROM_FIELD := cStr
			endif

			ToPost->imported   := .t.   // we are reading them from a File, so they are IMOPRTED ! - April 2020

			// from now On we are looking at Containers...
			// there can be up to 20 container types..

			for n:=1 to 20
				cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
				// this is the Container Name (or Pallet)
				cContainer := alltrim(upper(cStr))

				cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
				nIn  := val(cStr)

				cStr := GrabNextFld( @nCnt, TempGunk->textInfo )
				nOut  := val(cStr)

				if !empty( cContainer )
					nContainer := ContNumb( cContainer )
					if nContainer == 0
						nImportErrors++
						if empty( ToPost->CONT_ERRS)
							ToPost->Cont_errs := cContainer
						else
							ToPost->Cont_errs  := alltrim( ToPost->Cont_errs )+','+alltrim(cContainer)
						endif

						AppError(APP_ERR_GLITCHY_IMP_CONTAINER_1, {'We can NOT post this properly!', ;
									'There is a Container Type which is not', ;
									'set up the same between the two systems.', ;
									'',;
									'Ticket (in ToPost) ='+ ToPost->depot + ' ' + var2char(ToPost->recpt), ;
										' Container type='+cContainer+' is the problem.'})
					else

						if ContainerWidthChk( nIn )
							ToPost->(gsInContainer(  nContainer, nIn ))
						else
							if empty( ToPost->CONT_ERRS)
								ToPost->Cont_errs := 'inWdth'
							else
								ToPost->Cont_errs  := alltrim( ToPost->Cont_errs )+',inWdth'
							endif
							nImportErrors++
							AppError(APP_ERR_GLITCHY_IMP_CONTAINER_2,{'YOU MUST FIX TICKET ' +ToPost->depot+' '+var2char( ToPost->recpt ), ;
										 'Container value for '+cContainer, ;
										 '  Incoming Qty = '+var2char( nIn ), ;
										 'Is TOO Large to Fit in Field !' })
						endif

						if ContainerWidthChk( nOut )
							ToPost->(gsOutContainer( nContainer, nOut ))
						else
							if empty( ToPost->CONT_ERRS)
								ToPost->Cont_errs := 'outWd'
							else
								ToPost->Cont_errs  := alltrim( ToPost->Cont_errs )+',outWd'
							endif
							nImportErrors++
							AppError(APP_ERR_GLITCHY_IMP_CONTAINER_3,;
										{'YOU MUST FIX TICKET '+ToPost->depot+' '+var2char( ToPost->recpt ), ;
										 'Container value for '+cContainer, ;
										 '  OutGoing Qty = '+var2char( nIn ), ;
										 'Is TOO Large to Fit in Field !' })
						endif
					endif
				endif

				if nCnt >= len( TempGunk->textInfo )
					exit
				endif
			next

			if str(toPost->net,12,2)==str(0,12,2) .and. ;
				empty(toPost->process)
				// Container transactions only
				toPost->product := ''
				toPost->process := ''
				toPost->grade   := 0
			endif
			ToPost->(dbCommit())

		endif

		TempGunk->(dbSkip())
	enddo

	if toPost->(lastRec()) >= 1
		lReturn := .t.

		if nHasDockage >= 1
			waitInfo({'Dockage was noted on '+lStrim(nHasDockage)+' tickets', ;
						 'We did NOT have dockage on ' + lstrim( nNoDockage)+ ' tickets'})
		endif
		if nImportErrors >= 1
			WaitExclam({'You will note we found '+lStrim( nImportErrors )+' possible errors', ;
							'Look over the data carefully and consider what to do about any', ;
							'errors that you see.'})
		endif


	else

		waitInfo({'No data in file to import'})

		LogAnEvent( EVT_TYPE_IMPORT_ABORT_2, ;
				 {'We aborted an IMPORT ! - File Size='+var2char( cData)+'  Header:', ;
				  substr(cData,1                ,  min( FLD_NOTE, len( cData) )), ;
				  substr(cData,FLD_NOTE + 1     ,  min( 2*FLD_NOTE, len( cData) )), ;
				  substr(cData,2 * FLD_NOTE + 1 ,  min( 3*FLD_NOTE, len( cData) ))  })

	endif

RETURN( lReturn )

static function GapAnalyze( aGaps, cDirFile )
	local nLast := -1
	local nLow  := 9999999
	local nHigh := -1
	local n := 0
	local cDepot      := ''
	local nDepotBatch := -1
	local nDupes      :=  0
	local cTmp

	aSize( aGaps, 0 )
	msgLine("Testing in Daily.DBF"  + ;
		" ...are there any Gaps in Receipts?")

	toPost->(dbGoTop())
	select toPost
	INDEX ON toPost->depot + str(toPost->recpt,FLD_RECPT) TO AnyGaps
	toPost->(dbGoTop())

	Daily->(OrdSetFocus(DAILY_DEPOT_RECEIPT_ORD))

	// Check the Scale Records.....
	do while !toPost->(eof())
		n++
		if n > 1
			do case
			case toPost->recpt == nLast
				aadd(aGaps,'Duplicate Ticket in TOPOST '+lStrim(toPost->recpt))
			case toPost->recpt > nLast+1
				aadd(aGaps,'Missing Tickets in TOPOST '+lStrim(nLast+1)+ ;
					  ' '+lStrim(toPost->recpt-1) )
			endcase

			if !( toPost->depot == cDepot ) .or. !( toPost->imp_bat == nDepotBatch )
				aadd( aGaps,'Multiple DEPOTs or BATCHES found: '+cDepot+'-'+var2char( nDepotBatch)+ ;
								'  and  '+ toPost->depot+'-'+var2char( toPost->imp_bat )+' Recpt#='+ var2char( toPost->recpt) )

				appError( APP_ERR_GLITCHY_IMPORT_13, {'Multiple DEPOTs or BATCHes in this batch'                  ,  ;
																 'See: ' + cDepot        + '-' + var2char( nDepotBatch)      ,    ;
																 'and: ' + toPost->depot + '-' + var2char( toPost->imp_bat ) ,    ;
																 'File: '+cDirFile,                                               ;
																 '*** THIS IS SERIOUSLY WEIRD !!! ***'   } )
				nImportErrors++
				LogAnEvent( EVT_TYPE_IMPORT_BATCH_WEIRD, ;
		            {'Import: ' + cDirFile, ;
						 'Weird problem with Batch or Depot', ;
						 'See: ' + cDepot        + '-' + var2char( nDepotBatch)      ,    ;
						 'and: ' + toPost->depot + '-' + var2char( toPost->imp_bat ) 				} )

			endif
		endif

		cDepot      := ToPost->depot
		nDepotBatch := ToPost->imp_bat

		if nDupes <= 2
			if Daily->(dbSeek( toPost->depot + str( toPost->recpt, FLD_RECPT ), HARDSEEK ))
				aadd( aGaps, '*** Receipt '+ Daily->depot + str( Daily->recpt, FLD_RECPT )+' is ALREADY ON FILE !')
				if Daily->imp_Bat == toPost->imp_bat
					aadd( aGaps, 'for the Same Import Batch - you should NOT import this batch')
				else
					aadd( aGaps, 'The receipt was imported in Batch ' + var2char( Daily->Imp_bat) )
				endif
				nDupes++
			endif
		endif

		nLast := toPost->recpt
		if nLow > toPost->recpt .and. toPost->recpt > 0
			nLow := toPost->recpt
		endif
		if nHigh < toPost->recpt
			nHigh := toPost->recpt
		endif

		toPost->(dbSkip())
	enddo

	if n == 0
		aadd( aGaps, 'Hey - nothing here to POST!')
	else
		if Daily->(dbSeek( cDepot + str( nLast, FLD_RECPT ), HARDSEEK ))
			aadd( aGaps, '*** Last Receipt '+ Daily->depot + str( Daily->recpt, FLD_RECPT )+' is ALREADY ON FILE !')
			if nDupes >= 1 .and. Daily->imp_bat == nDepotBatch
				aadd( aGaps, '*** This batch seems to have been posted before!  Do NOT Import again ***')
			endif
			nDupes++
		endif

		aadd( aGaps, 'We are trying to import receipts for depot '+cDepot+' from '+var2char( nLow)+ '-' + var2char( nHigh ) )

		do case
		case n==nDupes .or. nDupes==3
			aadd( aGaps, 'You should probably NOT import these tickets !' )

		case nDupes == 0 .and. Daily->(dbSeek( cDepot + str( nLow - 1, FLD_RECPT ), HARDSEEK ))
			aadd(aGaps, 'Last ticket imported for this depot was '+Daily->depot+'-'+var2char( Daily->recpt) )
			aadd(aGaps, 'This is expected - you should probably import these tickets' )

		otherwise
			// First we check on Tickets
			Daily->(OrdSetFocus(DAILY_DEPOT_RECEIPT_ORD))
			if !Daily->(dbSeek( cDepot , HARDSEEK))
				aadd(aGaps,'No receipts have been processed yet for this depot: '+ cDepot )
			else
				cTmp := ''
				do while !Daily->(eof()) .and.  Daily->depot==cDepot
					do case
					case Daily->depot == cDepot .and. Daily->recpt < nLow
						cTmp := 'Last ticket on file below this batch is: '+Daily->depot +'-'+var2Char( daily->recpt )
					case Daily->depot  == cDepot .and. Daily->recpt > nHigh
						if !empty( cTmp )
							aadd( aGaps, cTmp )
							cTmp := ''
						endif
						cTmp := 'First ticket on file above this batch is: '+Daily->depot +'-'+var2Char( daily->recpt )
						exit
					endcase
					Daily->(dbSkip( ))
				enddo
				if !empty( cTmp )
					aadd( aGaps, cTmp )
				endif
			endif
		endcase

		// May 2020 - quick Check of Batch
		if !empty( cDepot ) .and. nDepotBatch > 0
			ImpBat->( ordSetFocus( IMPBAT_DEPOT_BATCH_ORD ))
			if ImpBat->( dbSeek( cDepot  + str( nDepotBatch, FLD_DOCUMENT ), HARDSEEK ) )
				aadd( aGaps, 'Batch '+cDepot+'-'+var2char( nDepotBatch)+' WAS been imported before !!!')
				nImportErrors++
			else
				if nDupes > 0
					aadd( aGaps, 'Hmm, no record of this batch being imported...ODD !')
				else
					aadd( aGaps, 'Batch '+cDepot+'-'+var2char( nDepotBatch)+' does not seem to have been imported before')
				endif
			endif
		endif
	endif

	for n := 1 to len(aGaps)
		aGaps[n] := padr(aGaps[n],65)   // widened a little in May 2020
	next

return( nil )


///<summary>Has this data in ToPost.dbf been imported before? </summary>
static function HasThisBeenImpBefore(  )
	local lReturn := .f.
	local lCheck  := .t.
	local nCount  := 0

	msgLine("Testing in Daily.DBF...was this data imported before?")

	toPost->(dbGoTop())
	Daily->(OrdSetFocus(DAILY_DEPOT_RECEIPT_ORD))

	// Check the Scale Records.....
	do while !toPost->(eof()) .and. lCheck

		Daily->(dbSeek( ToPost->depot + str( toPost->recpt, FLD_RECPT) ,HARDSEEK))

		do while Daily->depot==ToPost->depot .and. Daily->recpt==toPost->recpt .and. !Daily->(eof())

			if Daily->depot  == toPost->depot     .and. ;
				Daily->number == toPost->number    .and. ;
				Daily->depot  == toPost->depot     .and. lCheck

				lReturn := .t.
				nCount++

				if !Yesno({"There appears to be duplicates of this data in the Ticket File", ;
						"This is example #"+var2char( nCount ), ;
						"Receipt in Import File--", ;
						" Grower: "+ lStrim( toPost->number)   + "   Depot/Receipt: "+ ToPost->depot + var2char( toPost->recpt )                            , ;
						" Receipt Date: "+ shMDY( ToPost->date)+ "  Product: "+ToPost->product+" "+ToPost->process + " Net Weight: "+var2char( ToPost->net) , ;
						"Receipt on File--"  , ;
						" Grower: "+ lStrim( Daily->number)    + "   Depot/Receipt: "+ Daily->depot  + var2char( Daily->recpt ) + Daily->RECPTLTR           , ;
						" Receipt Date: "+ shMDY( ToPost->date)+ "  Product: "+ToPost->product+" "+ToPost->process + " Net Weight: "+var2char( ToPost->net) , ;
						" "+iif(empty( Daily->imp_bat), "seems to input in office!"," Import Batch:"+var2char( Daily->imp_bat))                              , ;
						"", ;
						"Do you wish to keep checking data?"})

					lCheck := .f.
					exit
				endif
			endif
			Daily->(dbSkip())
		enddo

		toPost->(dbSkip())
	enddo

return( lReturn )


static function MakeScaleNew()
	local aStru1 := {}

	// just be sure they are closed
	if select('TOPOST') > 0
		toPost->(dbCloseArea())
	endif

	if select('TEMPGUNK') > 0
		TempGunk->(dbCloseArea())
	endif

	aStru1 := ReceiptStru( RECEIPT_STRU_FOR_DAILY )
	AED_Fields_nonStd( aStru1 )

	dbCreate('toPost', aStru1 )      // to Post - same Stru as DAILY.DBF

	dbCreate('TempGunk',{ {'TEXTINFO','C',1024,0 }  } )    // from Text File

	use toPost exclusive new
	use TempGunk exclusive new

return( nil )

function AnyProblems(  )             // May 2020 change to return variable length string
	// check toPost Record
	local cReturn := ''

	do case
	case empty( toPost->number )
		cReturn += E_GROWER
	case !ValidTest( V_GROWER, toPost->number, VT_NO_MESSAGE )
		cReturn += E_GROWER
	endcase

	// Depot is getting Garbage in it
	if HasJunk( toPost->depot ) .or.  HasJunk(toPost->product) .or. ;
		HasJunk( toPost->process )
		cReturn += E_GARBAGE
	endif

	// Changed in May 2020 to check for Date as well as Time!
	if ToPost->date < sysValue( SYS_CURRENT_SEASON_START ) .or. ToPost->date > sysValue( SYS_CURRENT_SEASON_END ) ;
			       .or. !(year( ToPost->date ) == sysValue( SYS_CURRENT_YEAR )) .or. ;
					 ToPost->date > date()
		cReturn += E_TIME
	else
		// July 2003
		if substr( toPost->time,1,2 )<'00' .or.  substr(toPost->time,1,2)>'24' ;
			.or. ;
			substr( toPost->time,4,2 )<'00' .or.  substr(toPost->time,4,2)>'60'

			cReturn += E_TIME
		endif
	endif

	if toPost->grade==0 .and. empty(toPost->product) .and. ;
			empty(toPost->process)

		if !( ToPost->( AnyContainers( ) ) )
			cReturn += E_EMPTY
		endif

	else
		if str(toPost->thePrice,12,2)==str(0,12,2)
			if !( FindPrice( toPost->Product, toPost->Process, toPost->date))  // dDate )
				cReturn += E_PRICE
			endif
		endif

		if toPost->grade <= 0 .or. toPost->grade > MAX_NO_OF_GRADES
			cReturn += E_GRADE
		endif

		if !ValidTest( V_PRODUCT, toPost->Product, VT_NO_MESSAGE )
			cReturn += E_BERRY
		endif

		if !ValidTest( V_PROCESS_TYPE, toPost->process, VT_NO_MESSAGE )
			cReturn += E_PROCESS
		endif
	endif

	if empty( toPost->recpt )
		cReturn += E_EMPTY
	endif

	if toPost->isVoid
		cReturn += E_VOID
	endif

	if toPost->net <= -0.01
		cReturn += E_WEIGHT
	endif

	if sysValue( SYS_DOCKAGE_ACTION ) <> DOCKAGE_ACTION_NO_ACTION
		if str(toPost->dock_pct,6,0) <> str(0,6,0)
			cReturn += E_DOCKAGE
		endif
	endif

	if !empty( toPost->cont_errs)
		cReturn +=  E_CONTAINER                 // May 2020
	endif

return( cReturn )



static function SelectAfile( aFiles )

	local oTb, oCol
	local nRow
	local cReturn := ''
	local aMsg

	nRow := 1

	oTb := tBrowCreate(7,10)

	tbMainCfg( oTb, CB_TITLE, 'Select File to Import')

	tbMainCfg( oTb, CB_SKIP, {| n,bW | ArraySkipper( n, @nRow, aFiles )})
	tbMainCfg( oTb, CB_NEED_LOCKS, .f. )

	tbMainCfg( oTb, CB_GOTOP,	  {|| nRow := 1})
	tbMainCfg( oTb, CB_GOBOTTOM, {|| nRow := len(aFiles) })
	tbMainCfg( oTb, CB_WHILE,    {|| nRow >=1 .or. nRow <= len(aFiles) })

	tbMainCfg( oTb, CB_ALLOW_EDIT, .f.)

	if sysValue( SYS_IMPORT_FORMAT ) == SY_IMP_FMT_DOS
		oCol := tbcolCreate('Date', ;
			{|| shMDY( aFiles[nRow, 1 ]) } )
		tbColAdd(oTb, oCol)

		oCol := tbcolCreate('------ File Name ------', ;
			{|| padc( aFiles[nRow,2 ], 20) })
		tbColAdd(oTb, oCol)

		oCol := tbcolCreate('Size', ;
			{|| transform(aFiles[nRow,3 ],'9,999,999') })
		tbColAdd(oTb, oCol)

		oCol := tbcolCreate('Created On', ;
			{|| aFiles[nRow,4 ] })
		tbColAdd(oTb, oCol)
	else
		oCol := tbcolCreate('------ File Name ------', ;
			{|| padc( aFiles[nRow,1 ], 23) })
		tbColAdd(oTb, oCol)

		oCol := tbcolCreate('Size', ;
			{|| transform(aFiles[nRow,2 ],'9,999,999') })
		tbColAdd(oTb, oCol)

		oCol := tbcolCreate('Created On', ;
			{|| aFiles[nRow,3 ] })
		tbColAdd(oTb, oCol)

		oCol := tbcolCreate('- at -', ;
			{|| aFiles[nRow,4 ] })
		tbColAdd(oTb, oCol)
	endif

	aMsg := msgLine( '[Enter] to Select file to import')

	if theBrowse(oTB)
		cReturn := aFiles[nRow,1]
	endif

	rest_scr(aMsg)

return( cReturn )


static function SetUpSumRpt( aRpt )


	/* in subtotal
		aadd( aRpt, ;
			{ 'Prod' 	, { || Field->Product }     ,  'C' ,    005  ,   000 , ;
				.t., .f. , ;
				'Product' } )
	*/

	aadd( aRpt, ;
		{ '    ' 	, { || space(13) }     ,  'C' ,    013  ,   000 , ;
			.t., .f. , ;
			'Good  Looks' } )

	aadd( aRpt, ;
		{ 'Proc' 	, { || Field->process }     ,  'C' ,    005  ,   000 , ;
			.t., .f. , ;
			'Process' } )

	aadd( aRpt, ;
		{ 'Desc' 	, { || NameOf(LU_PROCESS_TYPE,Field->process) }  , ;
		   'C' ,    015  ,   000 , ;
			.t., .f. , ;
			'Process Name' } )

	aadd( aRpt, ;
		{ 'Grade' 	, { || Field->grade }     ,  'N' ,    005  ,   000 , ;
			.t., .f. , ;
			'Grade' } )

	aadd( aRpt, ;
		{ 'Receipts' 	, { || Field->loads }     ,  'N' ,    008  ,   000 , ;
			.t., .t. , ;
			'Receipts' } )

	aadd( aRpt, ;
		{ 'Net Weight' 	, { || Field->net }     ,  'N' ,    012  ,   000 , ;
			.t., .t. , ;
			'Total Wgt' } )

return( nil )

static function CheckForErrors()
	local nErr := 0,aMsg := {}, aMsg2, aMsg3
	local nDupes, nBlankRec,nBlankGrow, nDateTime
	local nRecpt
	local n
	local cErr


	aMsg2 := MsgLine('Checking Imported data for Errors')

	toPost->(dbGoTop())
	// July 18, 2000
	nDupes     := 0
	nBlankRec  := 0
	nBlankGrow := 0
	nDateTime  := 0
	nRecpt     := -9987    // should never occur
	nErr       := 0

	dbSelectArea('ToPost')
	index on str(ToPost->recpt,FLD_RECPT + 2 ) to TOPOSTX
	toPost->(dbGoTop())

	do while !toPost->(eof())
		if ToPost->recpt==0
			nBlankRec++
			if nBlankRec < 3
				WaitInfo({'Blank Receipt Number Shown on Import' , ;
							 '*** Serious problem ***', ;
							 'Record '+ str(ToPost->(recno()),10) } )
			endif
		endif
		if ToPost->number==0
			nBlankGrow++
			if nBlankGrow < 3
				WaitInfo({'Blank Grower Number Shown on Import' , ;
							 '*** Serious problem ***', ;
							 'Recpt #:'+var2char( ToPost->recpt),   ;
							 'Record '+ str(ToPost->(recno()),10) } )
			endif
		endif

		if ToPost->recpt==nRecpt
			if nDupes < 3
				WaitInfo({'Duplicate Receipt Number Shown on Import' , ;
							 'Receipt No is: '+str(ToPost->recPt,10), ;
							 '*** Serious problem ***', ;
							 'Record '+ str(ToPost->(recno()),10) } )
			endif
			nDupes++
		endif

		// added July 2003
		if ToPost->date < sysValue( SYS_CURRENT_SEASON_START ) .or. ToPost->date > sysValue( SYS_CURRENT_SEASON_END ) ;
			       .or. !(year( ToPost->date ) == sysValue( SYS_CURRENT_YEAR ))

				nDateTime++
				if nDateTime < 4
					WaitInfo({'Problem with DATE on Import' , ;
						 'Receipt No is:  '+var2char(ToPost->recPt,10), ;
						 'Date on Receipt='+var2char(ToPost->date), ;
						 'Check this Receipt very carefully', ;
						 'This MAY just be a problem with your SYSVALUE configuration', ;
						 'Record '+ str(ToPost->(recno()),10) } )
				endif
		else
			if empty(ToPost->time) .or. !(isDigit(ToPost->time)) .or. ;
				( ToPost->time < '00:00' .or. ToPost->time > '24:00')

				nDateTime++
				if nDateTime < 3
					WaitInfo({'Problem with TIME on Import' , ;
						 'Receipt No is: '+str(ToPost->recPt,10), ;
						 'Check this Receipt very carefully', ;
						 '*** Serious problem ***', ;
						 'Record '+ str(ToPost->(recno()),10) } )
				endif
			endif
		endif

		cErr := AnyProblems(  )
		if !empty( cErr )
			if nErr < 3
				WaitInfo({'Problem Code: '+cErr , ;
						 'Depot is :  '+ToPost->depot, ;
						 'Receipt No: '+str(ToPost->recPt,10), ;
						 'Grower No : '+str(ToPost->number,10), ;
						 'Record      '+ str(ToPost->(recno()),10) } )
			endif
			nErr++
		endif
		toPost->(dbSkip())
	end do
	rest_scr(aMsg2)

	do case
	case nErr == 1
		aadd( aMsg , 'There is one record with a problem with ')
		aadd( aMsg , 'Grower#,Product,Grade,Process or Void')
		aadd( aMsg , 'You can correct this later ' )
	case nErr > 1
		aadd( aMsg, 'There are '+lStrim(nErr)+' records with problems with ' )
		aadd( aMsg, 'Grower#,Product,Grade,Process or Void' )
		aadd( aMsg, 'You can correct these later ' )
	endcase

	do case
	case nBlankRec == 1
		aadd( aMsg , 'There is one record with a blank Receipt #')
		aadd( aMsg , 'This may indicate an entirely blank')
		aadd( aMsg , 'receipt ---' )
	case nBlankRec > 1
		aadd( aMsg, 'There are '+lStrim(nBlankRec)+' records with blank Receipt#' )
		aadd( aMsg , 'This may indicate an entirely blank')
		aadd( aMsg , 'receipt ---' )
	endcase

	do case
	case nBlankGrow == 1
		aadd( aMsg , 'There is one record with a blank Grower!')
		aadd( aMsg , 'This may indicate an entirely blank')
		aadd( aMsg , 'receipt ---' )
	case nBlankGrow > 1
		aadd( aMsg, 'There are '+lStrim(nBlankGrow)+' records with Blank Growers' )
		aadd( aMsg , 'This may indicate an entirely blank')
		aadd( aMsg , 'receipt ---' )
	endcase

	do case
	case nDupes == 1
		aadd( aMsg , 'There is one duplicate receipt #')
	case nDupes > 1
		aadd( aMsg, 'There are '+lStrim(nDupes)+' duplicate Receipt Numbers' )
	endcase

	do case
	case nDateTime == 1
		aadd( aMsg , 'There is one Receipt with a Date/Time problem')
	case nDupes > 1
		aadd( aMsg, 'There are '+lStrim(nDateTime)+' date/Time problems with Receipts' )
	endcase

	if len(aMsg) > 0
		aMsg3 := {}
		for n :=1 to len( aMsg )
			aadd( aMsg3, aMsg[n] )
		next
		aadd( aMsg3, '')
		aadd( aMsg3,'Do you wish to print the error list?')
		if YesNo(aMsg3)
			ReportErrors( aMsg )
		endif
	endif
	select toPost
	toPost->(ordListClear())

return(nil)

static function ReportErrors( aMsg )
	local aRpt := {},nErr := 0, n

	rImportErr(aRpt)  // Set columns

	WaitInfo({'This next report shows Scale Errors!'})

	if selectPrn('SCALERR.TXT','Select Printer for the ScaleError Report')

		select toPost
		toPost->(dbGoTop())

		gRptInitHead()

		gRptGetSetHead( RPT_HEAD_TITLE, ;
				{ 'Scale Receipts in Receipt# Order',  ;
				  'Errors for batch ' + cScaleDepot+lStrim(nScaleBatch) } )

		gRptGetSetHead( RPT_HEAD_ON_RECORD, ;
			{ || iif( empty(AnyProblems(  )), NIL , nErr++) })

		PRINT_ON  RPT_OVERWRITE

		gRptPrintSize( aRpt, 10 )      // 2 )

		toPost->(gRptPrinter( aRpt ))

		if NearPageBottom( len( aMsg )+6)
			nuFormFeed()
			nuQprnOut( )
			nuQprnOut( )
		endif
		nuQprnOut( )
		for n := 1 to len( aMsg )
			nuQprnOut( ' '+aMsg[n] )
		next
		nuQprnOut(                   )
		nuQprnOut( ' Key= '+NT_KEY_1 )
		nuQprnOut( '      '+NT_KEY_2 )
		nuQprnOut( '   '+NT_KEY_3    )

		PrinterCtrl( PRN_CTRL_10_CPI )

		PRINT_OFF  RPT_COMPLETE_EJECT

	endif
return(nil)


static function rImportErr(aRpt)

	aadd( aRpt, {'D', {|| Field->depot }, "C", 1, 0 , ;
		.t., .f. , 'Depot'})

	aadd( aRpt, {'Rect #', {|| Field->recpt }, "N", FLD_RECPT, 0 , ;
		.t., .f. , 'Receipt #'})

	aadd( aRpt, {'Date', {|| shMDY(Field->date) }, "C", 12, 0 , ;
		.t., .f. , 'Date of Receipt'})

	aadd( aRpt, { 'Prod', {|| Field->product},   'C',  4, 0 , .t., .f., ;
	 'Product'})

	aadd( aRpt, ;
		{ 'Grower Name'   , { || NameOf(LU_GROWER,Field->NUMBER) } ,  'C' , 022 ,  000 , ;
			.t., .f. , ;
			'Grower Name (not Cheque Name)' } )

	aadd( aRpt, { 'Pc', {|| Field->process},   'C',  2, 0 , .t., .f., ;
	 'Process'})

	aadd( aRpt, { 'Gr', {|| Field->grade},   'N',  2, 0 , .t., .f., ;
	 'Grade'})

	aadd( aRpt, { 'Net', {|| Field->net},   ',',  9, 0 , .t., .f., ;
	 'Net Weight'})

	aadd( aRpt, { 'Errors', {|| AnyProblems()},   'C',  10, 0 , .t., .f., ;
	 'Error Code'})

/*
	aadd( aRpt,{ 'ID', {|| Field->number}, 'N', 4, 0, .f., .f., ;
	 'Grower ID' })

*/
return(nil)

static function HasJunk( c )
	local n
	local lReturn := .f.

	for n := 1 to len( c )
		if asc( substr( c, n, 1 ) ) < 32 .or. ;
			(asc( substr( c, n, 1 ) ) > 32 .and. asc( substr( c, n, 1 ) ) < 47) ;
			  .or. ;
			(asc( substr( c, n, 1 ) ) > 58 .and. asc( substr( c, n, 1 ) ) < 64) ;
			  .or. ;
			(asc( substr( c, n, 1 ) ) > 91 .and. asc( substr( c, n, 1 ) ) < 97) ;
				.or. ;
			 asc( substr( c, n, 1 ) ) > 122

			 lReturn := .t.
		endif
	next


return( lReturn )


static function GrabNextFld( nCnt, cTextInfo )
	// nCnt is Passed by REFERNCE
	local n
	local cReturn := ''

	n := nCnt

	do while n <= len(cTextInfo)
		do case
		case substr( cTextInfo,n,1)=='"'    // Quote
			// skip this....
		case substr( cTextInfo,n,1)==','    // Comma
			n++                    // we must advance counter !
			exit
		otherwise
			cReturn += substr(cTextInfo,n,1)
		endcase
		n++
	enddo

	nCnt := n

return( cReturn )


static function VarietyDefaulter( cLongProduct, cLongProcess )
	// We use Process to default the Variety, then Product
	//   then the Default from Product
	//   then the System Default for Variety, if both
	//   the product & process are known.

	local cReturn := space( FLD_VARIETY )

	do case
	case len(alltrim(cLongProcess)) > FLD_PROCESS + 1
		// the Plus 1 is because the GRADE is at the end of the
		// Process
		cReturn := padr( alltrim( ;
		           substr(       ;
					  alltrim(cLongProcess),FLD_PROCESS + 2, FLD_LONG_NU_PROCESS)), ;
					  FLD_VARIETY )
	case len(alltrim(cLongProduct)) > FLD_PRODUCT
		cReturn := padr( alltrim( ;
		            substr( alltrim(cLongProduct),FLD_PRODUCT + 1, FLD_LONG_NU_PRODUCT) ), ;
					   FLD_VARIETY )
	endcase

	if empty( cReturn ) .and. !empty( cLongProduct ) .and. ;
		!empty( cLongProcess)

		if alltrim( cLongProduct)==padr(cLongProduct, FLD_PRODUCT)
			if ValidTest(LU_PRODUCT, padr(cLongProduct, FLD_PRODUCT) ,  VT_NO_MESSAGE)
				cReturn := Product->variety
			endif
		endif

		if !empty( cReturn)
			cReturn := sysValue( SYS_DEFAULT_VARIETY )
		endif
	endif
return( cReturn )

static function ContainerWidthChk( nQty )
	local lReturn := .t.
	local cQty

	cQty := var2char( nQty )

	if len( cQty ) > FLD_CONTAINER_QTY
		WaitInfo({'Wait a SEC - a Qty of Containers is to BIG!', ;
					 'Value = '+cQty })
		lReturn := .f.
	endif

 return( lReturn )

 static function InitScaleBatchStatics()

	 // this is our best guess for now
	dScaleFromDate   :=  DATE()-1   // often from Yesterday
	dScaleToDate     :=  DATE()-1

	cScaleDepot      := ''          // supposedly ONE Depot PER batch
	nScaleBatch      := 0           // and One Batch per Batch

	nImportErrors    := 0

 return( nil )

static function CloseTempFiles()
	if select('TempGunk') > 0
		TempGunk->(dbCloseArea( ))
	endif
	if select('ToPost') > 0
		ToPost->(dbCloseArea( ))
	endif
	if select('Sum1') > 0
		Sum1->(dbCloseArea())
	endif

return( nil )
