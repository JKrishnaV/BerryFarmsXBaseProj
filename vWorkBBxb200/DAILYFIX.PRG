// Fixer / mostly just for BH
//       Author: Bill Hepler
// Date created: July 2005
// Updated:      July 25, 2012
//               July 14, 2014 - Messages are nicer, more reports
//               March 4, 2015 - Diagnose Date issues.
//               Sep 10, 2019  - Diagnostic looks at Daily Unique as well...
//               May 27, 2020  - More Strict Tests and fix up a FIXER
//               Aug 01, 2021  - A bit more on missing tickets
//               Nov 03, 2022  - A new Diagnostic test added 122...

//    Copyright: (c) 2005, 2012, 2014, 2015, 2019, 2020, 2021, 2022 by Bill Hepler

//--------------------------------------------------------------------------


#include "ACCOUNT.CH"
#include "BerryPay.ch"
#include "bsgstd.ch"
#include "common.ch"
#include "dbstruct.ch"
#include "field.ch"
#include "indexord.ch"
#include "inkey.ch"
#include "printer.ch"
#include "Unique_Fields.ch"
#include "VALID.CH"
#include "window.ch"

#define  A_DATE_FLD_NUMBER   1
#define  A_DATE_FLD_NAME     2

#define  DIAG_RPT_GENERAL   1
#define  DIAG_RPT_DATE      2

#define  A_RAY_ADV_ROW_1ST_ADVANCE   1
#define  A_RAY_ADV_ROW_MARKET_DED    2
#define  A_RAY_ADV_ROW_2ND_ADVANCE   3
#define  A_RAY_ADV_ROW_3RD_ADVANCE   4
#define  A_RAY_ADV_ROW_FINAL         5
#define  A_RAY_ADV_ROW_BONUS         6
#define  A_RAY_ADV_ROW_OTHER         7 // time based premiums and errors



#define  A_RAY_ADV_COL_COUNTS     1   // 1st Row, - should be 1 or ZERO !
#define  A_RAY_ADV_COL_LBS        2   // 2nd Row, last Weight
#define  A_RAY_ADV_COL_PRICE      3   // 3rd Row, last price
#define  A_RAY_ADV_COL_TOT_PRICE  4   // 4th Row, last total price
#define  A_RAY_ADV_COL_BATCH      5   // 5th Row - (last) Advance Batch or Final Batch (final not implemented yet Nov 2022)
#define  A_RAY_ADV_COL_ACCOUNT_ID 6   // 6th Row, last Account->acct_uniq


function DailyFixerUniq(  )
	local nCount, nID
	local cPass  := space( 10 )
	local aWin
	local getList := {}

	if !Yesno({'Are you sure you want to RUN this program?', ;
			'It is intended for Data from BEFORE 2020 !', ;
			'It updates the UNIQUE ID field in Daily Receipts.', ;
			'to fix problems caused by import bugs in July 2005.', ;
			'You will be prompted for a PassWord !', '', ;
			'Run this?'})
		return( nil )
	endif

   if !yesno({'This is ODD - we do not expect you to run this routine.','', ;
             'Are you SURE you want to do this?'})
      return( nil )
   endif

	if !openFile({'Daily','CounterIDs'}, DB_EXCLUSIVE )
		close databases
		return( nil )
	endif

	create window at 6,08,17,73 title 'Set Unique IDs Receipt File' to aWin
	display window aWin
	set cursor on

	do while .t.
		in window aWin @  2,2 winsay 'Enter Password to Proceed' ;
			winget cPass picture '@!' get_message 'Hint: BH Mom initials before marriage'

		in window aWin @ 4,2 winsay 'This assigns a UNIQUE ID to any Receipts that are BLANK'
		in window aWin @ 5,2 winsay 'It will NOT change tickets with Unique IDs'
		read

		do case
		case lastkey()==K_ESC
			exit
		case upper(alltrim(cPass))<>'OAK'
			waitInfo({'Password is wrong'})
			loop
		endcase

		if yesno({'Fix them up by Assigning Unique IDs?'})

			nCount := 0

			nID := findLastUniqOnFile( UF_THE_DAY_UNIQ , .f.)                       // Apr 29, 2020 2BCHECKED

			msgLine('Working away, starting at '+var2char( nID ))

			Daily->(OrdSetFocus( 0 ))
			Daily->(dbGoTop())

			do while !Daily->(eof())
				if Daily->(recno()) % 500 == 0
					ShowProg( str(Daily->recpt,8) )
				endif

				if empty( Daily->DAY_UNIQ )
					nCount++
					nID++
					Daily->day_uniq       := nID
					CounterIDs->day_uniq  := nID
				endif

				Daily->(dbSkip())
			enddo

			WaitInfo({'We fixed up '+var2char( nCount )+' records'})
		endif

		exit
	enddo

	close databases
	kill window aWin

return( nil )

function DailyFixerOld( )
	local getList := {}
	local cPass := space(10)
	local aWin
	local cPath := space(40)
	local cFilePath
	local lProceed := .f.
	local nRecpt
	local nRecno
	local n
	local lChanged
	local cNote

	if !Yesno({'Are you sure you want to RUN this program?', ;
			'It updates your current Ticket Transactions with', ;
			'data from another table.  This is intended mainly', ;
			'to fix problems caused by import bugs in July 2005.', ;
			'You will be prompted for a PassWord !', '', ;
			'Run this?'})
		return( nil )
	endif

	create window at 6,08,17,73 title 'Fix up Ticket File' to aWin
	display window aWin
	set cursor on

	do while .t.
		in window aWin @  2,2 winsay 'Enter Password to Proceed' ;
			winget cPass picture '@!' get_message 'Hint: BH Mom initials before marriage'

		in window aWin @  4,2 winsay 'Path for Correct File...'
		in window aWin @  5,5 winget cPath get_message ;
			'Enter the directory where correct data is stored with \ at end...'

		read

		do case
		case lastkey()==K_ESC
			exit
		case upper(alltrim(cPass))<>'OAK'
			waitInfo({'Password is wrong'})
			loop
		case empty(cPath)
			waitInfo({'Path must be filled in!'})
			loop
		case right( alltrim(cPath),1) <> '\'
			waitInfo({'Path must end with \'})
			loop
		endcase


		lProceed := .f.
		begin sequence

			cFilePath := alltrim(cPath)+'DAILY.DBF'
			if file(cFilePath)
				lProceed := .t.
			endif

		end sequence

		if !lProceed
			WaitInfo({'Something is wrong here...maybe path is wrong.'})
			loop
		endif

		if selectPrn('FIXIT.TXT')
			close databases
			use DAILY exclusive
			if neterr()
				waitInfo({'Can not open DAILY...'})
				loop
			endif

			use (cFilePath) ALIAS NewGuy exclusive new
			if neterr()
				waitInfo({'Can not open '+cFilePath})
				loop
			endif

			msgLine('Working building indexes...')

			select DAILY
			index on str(Daily->recpt,8) to D1

			select NewGuy
			index on str(NewGuy->recpt,8) to N1

			PRINT_ON  RPT_OVERWRITE

			PrinterCtrl( PRN_CTRL_10_CPI )

			nuQprnOut( 'FIXUP....'  )
			nuQprnOut( shMDY(date())+' '+ time() )
			nuQprnOut()
			msgLine('Working...')

			Daily->(OrdSetFocus(1))
			NewGuy->(OrdSetFocus(1))

			Daily->(dbGoTop())
			nRecpt := -1
			do while !Daily->(eof())
				if NearPageBottom( 10 )
					nuFormFeed()
					nuQprnOut( 'FIXUP continued...' )
					nuQprnOut( )
				endif

				ShowProg( str(Daily->recpt,8) )
				do case
				case Daily->recpt <= 0
					nuQprnOut( 'Reciept Skipped...recno='+lstrim(Daily->(recno())))
				case daily->recpt == nRecpt
					nuQprnOut('Duplicate ticket in DAILY.DBF '+lstrim(nRecpt))
					nuQprnOut(' recno()= '+lstrim(Daily->(recno())) )
				otherwise
					if NewGuy->( dbSeek( str(Daily->recpt,8), HARDSEEK))
						nRecno := NewGuy->(recno())
						NewGuy->(dbSkip())
						cNote := ''
						if !NewGuy->(eof()) .and. NewGuy->recpt==Daily->recpt
							nuQprnOut( 'Duplicate ticket in NEWGUY.DBF '+lstrim(nRecpt))
							nuQprnOut( ' Daily recno() ='+lstrim( Daily->(recno())) )
							nuQprnOut( ' NewGuy recno()='+lstrim(NewGuy->(recno())) )
						else
							NewGuy->(dbGoto( nRecno ))
							lChanged := .f.
							for n := 1 to MAX_TYPES_CONTAINERS
								if NewGuy->(gsInContainer( n)) <> Daily->(gsInContainer(n))
									lChanged := .t.
									Daily->(gsInContainer(n, NewGuy->(gsInContainer(n) ) ))
									cNote += Daily->(ContSName( n ))+' in '
								endif
							next

							for n := 1 to MAX_TYPES_CONTAINERS
								if NewGuy->(gsOutContainer( n)) <> Daily->(gsOutContainer(n))
									lChanged := .t.
									Daily->(gsOutContainer(n, NewGuy->(gsOutContainer(n) ) ))
									cNote += Daily->(ContSName( n ))+' out '
								endif
							next
							if lChanged
								nuQprnOut( str(Daily->recpt,10)+ ;
								' Changed Containers '+cNote )
							else
								nuQprnOut( str(Daily->recpt,10)+ ;
								' Containers are the same' )
							endif

							if Daily->net <> NewGuy->net
								if Daily->POST_BAT1 == 0  .and. ;
									Daily->POST_BAT2 == 0  .and. ;
									Daily->POST_BAT3 == 0  .and. ;
									Daily->FIN_BAT   == 0  .and. ;
									Daily->ADV_PR2   == 0  .and. ;
									Daily->ADV_PR3   == 0

									nuQprnOut('  Quantity changed '+ ;
									 lstrim(Daily->recpt)+ str(Daily->net,10)+ ;
									 ' to '+ str( NewGuy->net ,10)  )
									Daily->net := NewGuy->net
								else
									nuQprnOut( ' ** Quantity different ' + ;
										lStrim(Daily->recpt) + str(Daily->net,10)+ ;
										' to '+ str( NewGuy->net,10) )
								endif
							endif
						endif
					else
						nuQprnOut( 'No Ticket Found in NewGuy '+lstrim(Daily->recpt))
					endif
				endcase
				nRecpt := Daily->recpt
				Daily->(dbSkip())
			enddo
			PRINT_OFF  RPT_COMPLETE_EJECT
		endif

		exit
	enddo
	close databases
	kill window aWin

return( nil )


function UnPostIt( )
	local getList := {}
	local cPass := space(10)
	local aWin
	local lProceed := .f.


	if !Yesno({'Are you sure you want to RUN this program?', ;
			'It UNPOSTS transactions!', ;
			'You will be prompted for a PassWord !', '', ;
			'Run this?'})
		return( nil )
	endif

	if !openfile({'Daily', 'Account','PostBat','FinBat', ;
	              'Audit', 'Cheque','VoidChq','Price'}, DB_EXCLUSIVE)
		close databases
		return( nil )
	endif

	create window at 6,08,17,73 title 'Unpost Daily File' to aWin
	display window aWin
	set cursor on

	do while .t.
		in window aWin @  2,2 winsay 'Enter Password to Proceed' ;
			winget cPass picture '@!' ;
			get_message 'Hint: BH Mom initials before marriage'

		in window aWin @  3,2 winsay 'Proceed' winget lProceed ;
			picture 'Y' get_message 'Unpost everything????'
		read

		do case
		case lastkey()==K_ESC
			exit
		case upper(alltrim(cPass))<>'OAK'
			waitInfo({'Password is wrong'})
			loop
		case !lProceed
			exit
		otherwise
			if !yesno({'Unpost everything ?'})
				exit
			endif
		endcase


		if selectPrn('UNPOST.TXT')
			PRINT_ON  RPT_OVERWRITE

			nuQprnOut( 'UNPOST....'  )
			nuQprnOut( shMDY(date())+' '+ time() )
			nuQprnOut()
			msgLine('Working...')

			Daily->(OrdSetFocus( 0 ))

			nuQprnOut('Getting DAILY...')
			Daily->(dbGoTop())
			do while ! Daily->(eof())
				replace ;
				  Daily->adv_pr1 with 0, ;
				  Daily->adv_prid1 with 0, ;
				  Daily->post_bat1 with 0, ;
				  Daily->adv_pr2 with 0, ;
				  Daily->adv_prid2 with 0, ;
				  Daily->post_bat2 with 0, ;
				  Daily->adv_pr3 with 0, ;
				  Daily->adv_prid3 with 0, ;
				  Daily->post_bat3 with 0, ;
				  Daily->fin_price with 0, ;
				  Daily->fin_pr_id with 0, ;
				  Daily->fin_bat with 0, ;
				  Daily->prem_price with 0

				Daily->(dbSKip())
			enddo

			Daily->(dbCommit())

			msgLine('Now the Prices...')
			nuQprnOut('Getting PRICE...')
			Price->(OrdSetFocus( 0 ))
			Price->(dbGoTop())
			do while ! Price->(eof())
				replace Price->ADV1_USED with .f., ;
				        Price->ADV2_USED with .f., ;
				        Price->ADV3_USED with .f., ;
				        Price->FIN_USED with .f.

				Price->(dbSKip())
			enddo

			msgLine('Zapping...')

			fileZappa('Account')
			fileZappa('PostBat')
			fileZappa('FinBat')
			fileZappa('Audit')
			fileZappa('AudAcct')
			fileZappa('Cheque')
			fileZappa('VoidChq')

			nuQprnOut( 'Wow we zapped them - so we are done' )

			PRINT_OFF  RPT_COMPLETE_EJECT
		endif

		exit
	enddo
	close databases
	kill window aWin

return( nil )


static function Filezappa( cFile )
	showProg( cFile )

	nuQprnOut( 'Zapping '+cFile )
	if select( cFile )==0
		OpenFile({cFile},DB_EXCLUSIVE)
	endif

	dbSelectAR( cFile )
	zap
	use

return( nil )


Function DiagnoseRpt()
	local nPage
	local cDepot,nReceipt,cLetter
	local nAcctUniq, nDailyUniq, nAcctChild
	local nDailyErr := 0, nAcctUniqErr := 0, nAcctDailyErr := 0, nAcctChildErr := 0
	local lErr := .f.
	local lNote := .f.
	local nCnt, nTicks
	local cTmp,c
	local aTick

	if !OpenFile({'Account','AudAcct','Audit',   'Cheque', 'Daily',  ;
	              'FinBat', 'Grower', 'PostBat', 'VoidTck'          }, DB_SHARED )
		close databases
		return( nil )
	endif

	if yesno({'Run Diagnostic Report?', ;
         'We check for Odd Events such as running a 2nd Advance on', ;
         'Ticket when you have not yet run a first advance.  The system', ;
         'allows this, but we advise against doing that.','', ;
	      'We also Look for missing and duplicate entries in:', ;
			' -Daily (the Scale tickets)', ;
			' -Accounts (financial summary records)', ;
			' -Audit files (relates Daily and Accounts)' })

		if selectPrn('DIAGNOSE.TXT')
			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( {}, 112 )   // July 31, 2021
			nPage := 1

			DiagRptHeader( DIAG_RPT_GENERAL , nPage )
			nPage++
			msgLine('Checking Receipts...Test 1/2..')

			PostBat->(ordSetFocus( POSTBAT_BATCH_ORD   ))             // this is FIXED I think April 29, 2020
			FinBat->( ordSetFocus( FINBAT_BATCH_ORD       ))
			Daily->(  ordSetFocus( DAILY_DEPOT_RECEIPT_ORD ))

			Daily->(dbGoTop())
			nuQprnOut('Testing Daily Receipts - (scale tickets) - Receipt #...')

			cDepot   := Daily->depot
			cLetter  := Daily->RECPTLTR
			nReceipt := Daily->RECPT-1   // we start at "previous"

			nCnt := 0
			do while !Daily->(eof())
				lErr  := .f.
				lNote := .f.
				nCnt++
				if nCnt % 10 == 0
					showProg( nCnt )
				endif

				do case
				case empty( Daily->recpt)
					lErr := .t.
					nuQprnOut( ' ERR-UnNumbered Recpt: '+ ;
					    Daily->depot+' '+str(Daily->recpt,FLD_RECPT)+Daily->recptLtr )

				case cDepot == Daily->depot .and. ;
				     cLetter == Daily->recptLtr .and. ;
					  nReceipt == Daily->recpt
					lErr := .t.
					nuQprnOut( ' ERR-Duplicate Scale Ticket Record: '+ ;
					    Daily->depot+' '+str(Daily->recpt,FLD_RECPT)+Daily->recptLtr )

				case cDepot == Daily->depot .and. Daily->recpt > nReceipt + 1
					lNote  := .t.
					c      := ''
					cTmp   := ''
					aTick  := {}
					nTicks := Daily->recpt - nReceipt -1
					if nTicks > 1
						cTmp := var2char( nTicks)+' Receipts Missing ! '
					endif
					VoidTck->(ordSetFocus( VOIDTCK_DEPOT_RECEIPT_ORD ))
					VoidTck->(dbSeek( cDepot + str( nReceipt+1, FLD_RECPT ), SOFTSEEK))
					do while !VoidTck->(eof()) .and. VoidTck->depot==cDepot .and. VoidTck->recpt <= Daily->recpt
						if empty( c )
							c := 'Voided in office: ' +var2char( VoidTck->recpt )+' '
						else
							aadd( aTick, VoidTck->recpt )
						endif
						VoidTck->(dbSkip())
					enddo

					do case
					case len( aTick ) == 1
						c += ( '-'+var2char( aTick[1]))
					case len( aTick ) > 1
						c += ('+ ' + var2char( len( aTick )) + ' more')
					endcase

					nuQprnOut( ' Jump in Scale Ticket from: ' + ;
					   Daily->depot+' '+str( nReceipt,FLD_RECPT)+Daily->recptLtr +' to '+ ;
						str(Daily->recpt,FLD_RECPT) +' '+ cTmp + c )

				case cDepot <> Daily->depot
					lNote := .t.
					nuQprnOut( ' NB: Last Ticket for Depot=' + cDepot + ' is: ' + ;
					   cDepot+' '+str( nReceipt,FLD_RECPT)+ cLetter )
					nuQprnOut( '' )
					nuQprnOut( '     First Ticket in New Series: '+ ;
					    Daily->depot+' '+str(Daily->recpt,FLD_RECPT)+Daily->recptLtr )
				endcase

				if Daily->post_bat1 >= 1 .or. Daily->post_Bat2 >= 1 .or. ;
				   Daily->post_bat3 >= 1 .or. Daily->fin_Bat   >= 1

					// We check does this batch exist
					if Daily->post_bat1 >= 1
						if !PostBat->(dbSeek( str(Daily->post_bat1, FLD_DOCUMENT ), HARDSEEK ))
							lErr := .t.
							nuQprnOut( ' ERR- *** Ghost Posting of Payment 1 to Scale Ticket Record: '+ ;
							             Daily->depot+' '+str(Daily->recpt,FLD_RECPT)+Daily->recptLtr )
						endif
					endif
					if Daily->post_bat2 >= 1
						if !PostBat->(dbSeek( str(Daily->post_bat2, FLD_DOCUMENT ), HARDSEEK ))
							lErr := .t.
							nuQprnOut( ' ERR- *** Ghost Posting of Payment 2 to Scale Ticket Record: '+ ;
							             Daily->depot+' '+str(Daily->recpt,FLD_RECPT)+Daily->recptLtr )
						endif
					endif
					if Daily->post_bat3 >= 1
						if !PostBat->(dbSeek( str(Daily->post_bat3, FLD_DOCUMENT ), HARDSEEK ))
							lErr := .t.
							nuQprnOut( ' ERR- *** Ghost Posting of Payment 3 to Scale Ticket Record: '+ ;
							             Daily->depot+' '+str(Daily->recpt,FLD_RECPT)+Daily->recptLtr )
						endif
					endif
					if Daily->fin_bat >= 1
						if !FinBat->(dbSeek( str(Daily->fin_bat, FLD_DOCUMENT ), HARDSEEK ))
							lErr := .t.
							nuQprnOut( ' ERR- *** Ghost Posting of Final Pay to Scale Ticket Record: '+ ;
							             Daily->depot+' '+str(Daily->recpt,FLD_RECPT)+Daily->recptLtr )
						endif
					endif
				endif

				if lErr .or. lNote
					if lErr
						nDailyErr++
					endif
					if NearPageBottom( 9 )
						nuFormFeed()
						DiagRptHeader( DIAG_RPT_GENERAL , nPage )
						nPage++
					endif
				endif

				cDepot   := Daily->depot
				cLetter  := Daily->RECPTLTR
				nReceipt := Daily->RECPT

				Daily->(dbSkip())
			enddo
			if nDailyErr > 0
				nuQprnOut('* '+lStrim(nDailyErr)+' Error(s)')
			else
				nuQprnOut('* no errors found in Daily')
			endif
			nuQprnOut()

			msgLine('Checking Receipts...Test 2/2..')

			Daily->(ordSetFocus( DAILY_ID_ORD ))
			Daily->(dbGoTop())
			nuQprnOut('Testing Daily Receipts (scale tickets) - Unique ID...')

			nDailyUniq := -1

			nCnt      := 0
			nDailyErr := 0

			do while !Daily->(eof())
				lErr  := .f.
				lNote := .f.
				nCnt++
				if nCnt % 10 == 0
					showProg( nCnt )
				endif

				do case
				case empty( Daily->day_uniq)
					lErr := .t.
					nuQprnOut( ' ERR-UnAssigned ID: '+ ;
					    Daily->depot+' '+str(Daily->recpt,FLD_RECPT)+Daily->recptLtr )

				case Daily->day_uniq == nDailyUniq

					lErr := .t.
					nuQprnOut( ' ERR-Duplicate Scale Ticket ID: '+ ;
					    Daily->depot+' '+str(Daily->recpt,FLD_RECPT)+Daily->recptLtr+'  ID='+var2char( nDailyUniq)  )

				endcase

				if lErr .or. lNote
					if lErr
						nDailyErr++
					endif
					if NearPageBottom( 9 )
						nuFormFeed()
						DiagRptHeader( DIAG_RPT_GENERAL , nPage )
						nPage++
					endif
				endif

				nDailyUniq   := Daily->day_uniq

				Daily->(dbSkip())
			enddo
			if nDailyErr > 0
				nuQprnOut('* '+lStrim(nDailyErr)+' Error(s)')
			else
				nuQprnOut('* no errors found in Unique IDs of Daily')
			endif
			nuQprnOut()

			msgLine('Testing Accounting Transactions...')
			nuQprnOut('Testing Accounting Transactions....')
			Account->(ordSetFocus( ACCOUNT_LINK_ORD ))
			Account->(dbGoTop())
			nAcctUniq := Account->acct_uniq-1
			nCnt := 0

			do while !Account->(eof())
				lErr  := .f.
				lNote := .f.
				nCnt++
				if nCnt % 10 == 0
					showProg( nCnt )
				endif

				do case
				case num2Equal0( Account->acct_uniq)
					lErr := .t.
					nuQprnOut( ' Account ID of ZERO (manully added - not too serious, RecNo=' + ;
					    +lstrim(Account->(recno()) )+'  Grow#'+lStrim( Account->number) )

				case nAcctUniq == Account->acct_uniq
					lErr := .t.
					nuQprnOut( ' ERR-Duplicate Account IDS: '+ ;
					    +str(Account->acct_uniq,FLD_DOCUMENT) +'  Grow#'+lStrim( Account->number) )

				case Account->acct_uniq > nAcctUniq + 1
					lNote := .t.
					nuQprnOut( ' NB: Jump in Account IDs from: ' + ;
					    +str( nAcctUniq, FLD_DOCUMENT) +' to '+ ;
						 +str(Account->acct_uniq,FLD_DOCUMENT)+'  Grow#'+lStrim( Account->number)  )
				endcase

            // Added--some additional notes added Nov 2022
				//  Hmm, well what happens sometimes is that when we are Doing a Secord advance, but no
				//   first advance has been done yet, the ADV# could be 2, but there will be 2 records created
				//   at that time, a FIRST and a SECOND.  This indicates sloppy practice - they are doing a second advance without
				//   doing a first advance!
            if ( Account->type == TT_BERRY_ADVANCE_1 .and. Account->adv_no <> NN_ADVANCE_1) ;
                                           .or. ;
            	( Account->type == TT_BERRY_ADVANCE_2 .and. Account->adv_no <> NN_ADVANCE_2) ;
                                           .or. ;
            	( Account->type == TT_BERRY_ADVANCE_3 .and. Account->adv_no <> NN_ADVANCE_3)
            	lErr := .t.
					do case
					case Account->adv_no == NN_ADVANCE_3
						nuQprnOut( 'G#:'+var2char( Account->number)+' '+var2char( Account->acct_uniq)+' 3rd advance run before 1st or 2nd! -Type='+Account->type + ' #=' + var2char( Account->Adv_no))
					case Account->adv_no == NN_ADVANCE_2 .and. Account->type == TT_BERRY_ADVANCE_1
						nuQprnOut( 'G#:'+var2char( Account->number)+' '+var2char( Account->acct_uniq)+' Looks like 2nd advance run before 1st! -Type='+Account->type + ' #=' + var2char( Account->Adv_no))
					otherwise
						nuQprnOut( 'G#:'+var2char( Account->number)+' '+var2char( Account->acct_uniq)+' Adv Type & No out of Sync-Type='+Account->type + ' #=' + var2char( Account->Adv_no))
					endcase
            endif

            if ( Account->type == TT_BERRY_ADVANCE_1   .or. ;
            	  Account->type == TT_BERRY_ADVANCE_2   .or. ;
            	  Account->type == TT_BERRY_ADVANCE_3  )      .and. Num2Equal0( Account->adv_bat)
            	lErr := .t.
               nuQprnOut( 'G#:'+var2char( Account->number)+' '+var2char( Account->acct_uniq)+' Adv Type w/ NO Advance Batch! '+Account->type + 'Adv#' + var2char( Account->Adv_no))
            endif

				if lErr .or. lNote
					if lErr
						nAcctUniqErr++
					endif
					if NearPageBottom( 9 )
						nuFormFeed()
						DiagRptHeader( DIAG_RPT_GENERAL, nPage )
						nPage++
					endif
				endif
				nAcctUniq := Account->acct_uniq
				Account->(dbSkip())
			enddo
			if nAcctUniqErr > 0
				nuQprnOut('* '+lStrim(nAcctUniqErr)+' Error(s) or Noticeable events')
			else
				nuQprnOut('* no errors found in Account')
			endif
			nuQprnOut()

			msgLine('Testing Accounting-Accounting Audit (GST etc)...')
			nuQprnOut('Testing Accounting-Accounting Audit (GST etc)....')
			AudAcct->(ordSetFocus( AUDACCT_MASTER_CHILD ))
			AudAcct->(dbGoTop())
			nAcctUniq  := -1
			nAcctChild := -1
			nCnt := 0

			do while !AudAcct->(eof())
				lErr  := .f.
				lNote := .f.
				nCnt++
				if nCnt % 10 == 0
					showProg( nCnt )
				endif

				do case
				case num2Equal0( AudAcct->acct_uniq) .or. num2Equal0( AudAcct->acct_child)
					lErr := .t.
					nuQprnOut( ' We have a Zero Value in Link Field, RecNo=' + ;
					    +lstrim(AudAcct->(recno()) ) + 'A='+lStrim(AudAcct->acct_uniq)+' Ch='+lStrim(AudAcct->acct_child) )

				case nAcctUniq == AudAcct->acct_uniq  .and. ;
				     nAcctChild == Audit->day_uniq
					lErr := .t.
					nuQprnOut( ' ERR-Duplicate  IDS: , RecNo=' + ;
					    +lstrim(AudAcct->(recno()) ) + 'A=+'+lStrim(AudAcct->acct_uniq)+' Ch='+lStrim(AudAcct->acct_child) )
				endcase

				if lErr .or. lNote
					if lErr
						nAcctChildErr++
					endif
					if NearPageBottom( 9 )
						nuFormFeed()
						DiagRptHeader( DIAG_RPT_GENERAL , nPage )
						nPage++
					endif
				endif
				nAcctUniq  := AudAcct->acct_uniq
				nAcctChild := AudAcct->acct_child

				AudAcct->(dbSkip())
			enddo
			if nAcctChildErr > 0
				nuQprnOut('* '+lStrim(nAcctChildErr)+' Error(s)')
			else
				nuQprnOut('* no errors found in Link within Account records')
			endif
			nuQprnOut()

			msgLine('Testing Accounting-Daily Audit...')
			nuQprnOut('Testing Accounting-Daily Audit....')
			Audit->(ordSetFocus( AUDIT_DAY_ACCT_ORD ))
			Audit->(dbGoTop())
			nAcctUniq  := -1
			nDailyUniq := -1
			nCnt := 0

			do while !Audit->(eof())
				lErr  := .f.
				lNote := .f.
				nCnt++
				if nCnt % 10 == 0
					showProg( nCnt )
				endif

				do case
				case num2Equal0( Audit->acct_uniq) .or. num2Equal0( Audit->day_uniq)
					lErr := .t.
					nuQprnOut( ' We have a Zero Value in Link Field, RecNo=' + ;
					    +lstrim(Audit->(recno()) ) + 'A='+lStrim(Audit->acct_uniq)+' D='+lStrim(Audit->day_uniq) )

				case nAcctUniq == Audit->acct_uniq  .and. ;
				     nDailyUniq == Audit->day_uniq
					lErr := .t.
					nuQprnOut( ' ERR-Duplicate  IDS: , RecNo=' + ;
					    +lstrim(Audit->(recno()) ) + 'A=+'+lStrim(Audit->acct_uniq)+' D='+lStrim(Audit->day_uniq) )
				endcase

				if lErr .or. lNote
					if lErr
						nAcctDailyErr++
					endif
					if NearPageBottom( 9 )
						nuFormFeed()
						DiagRptHeader( DIAG_RPT_GENERAL , nPage )
						nPage++
					endif
				endif
				nAcctUniq  := Audit->acct_uniq
				nDailyUniq := Audit->day_uniq

				Audit->(dbSkip())
			enddo
			if nAcctDailyErr > 0
				nuQprnOut('* '+lStrim(nAcctDailyErr)+' Error(s)')
			else
				nuQprnOut('* no errors found in Link between Account & Daily')
			endif
			nuQprnOut()

			msgLine(  'Testing for Errors with Final Pay & Advances...')

			nuQprnOut('Testing for Errors with Final Pay & Advances...')

			Audit->(ordSetFocus( AUDIT_DAY_ACCT_ORD ))
			Audit->(dbGoTop())
			nAcctUniq  := -1
			nDailyUniq := -1
			nCnt := 0

			// Nov 2019, WestBerry
			Daily->( ordSetFocus( DAILY_GROWER_ORD ))
			Daily->(dbClearFilter())
			Daily->(dbGoTop())
			//                  1         2         3         4          5        6         7         8         9
			//         123456789_123456789_123456789_123456789_123456789_123456789_123456789_123456789_123456789_123456789_123456789_123456789_
			nuQprnOut(' Grower#   Receipt #   Date   Product   --- Pay Rate Info   ---         Net Weight')
			do while !Daily->(eof())
				if Num3NotEqual0( Daily->adv_pr1 ) .and. Num2Equal0( Daily->post_bat1 )
					nuQprnOut( padr( str( Daily->Number, FLD_GROWER),                                    9) + ;
								  padr( Daily->depot + str( Daily->Recpt, FLD_RECPT) + Daily->RecptLtr, 11) + ;
								  padr( shMDY( Daily->date),                                            10) +  ;
								  padr( Daily->Product+' '+Daily->process+ str( Daily->grade,2),        10) + ;
								  'Adv1: '+str( Daily->adv_pr1, 7, 2)+ ;
									 '  Final: '+str( Daily->fin_Price, 7, 2) +' '+   ;
								  str( Daily->net, 10)  )

					if NearPageBottom( 9 )
						nuFormFeed()
						DiagRptHeader( DIAG_RPT_GENERAL , nPage )
			         nuQprnOut(' Grower#   Receipt #   Date   Product   --- Pay Rate Info   ---         Net Weight')
						nPage++
					endif
				endif

				if Num3NotEqual0( Daily->adv_pr2 ) .and. Num2Equal0( Daily->post_bat2 )
					nuQprnOut( padr( str( Daily->Number, FLD_GROWER),                                    9) + ;
								  padr( Daily->depot + str( Daily->Recpt, FLD_RECPT) + Daily->RecptLtr, 11) + ;
								  padr( shMDY( Daily->date),                                            10) +  ;
								  padr( Daily->Product+' '+Daily->process+ str( Daily->grade,2),        10) + ;
								  'Adv2: '+str( Daily->adv_pr2, 7, 2)+ ;
									 '  Final: '+str( Daily->fin_Price, 7, 2) +' '+   ;
								  str( Daily->net, 10)  )

					if NearPageBottom( 9 )
						nuFormFeed()
						DiagRptHeader( DIAG_RPT_GENERAL , nPage )
						nPage++
					endif
				endif
				if Num3NotEqual0( Daily->adv_pr3 ) .and. Num2Equal0( Daily->post_bat3 )
					nuQprnOut( padr( str( Daily->Number, FLD_GROWER),                                    9) + ;
								  padr( Daily->depot + str( Daily->Recpt, FLD_RECPT) + Daily->RecptLtr, 11) + ;
								  padr( shMDY( Daily->date),                                            10) +  ;
								  padr( Daily->Product+' '+Daily->process+ str( Daily->grade,2),        10) + ;
								  'Adv3: '+str( Daily->adv_pr3, 7, 2)+ ;
									 '  Final: '+str( Daily->fin_Price, 7, 2) +' '+   ;
								  str( Daily->net, 10)  )

					if NearPageBottom( 9 )
						nuFormFeed()
						DiagRptHeader( DIAG_RPT_GENERAL , nPage )
						nPage++
					endif
				endif

				Daily->(dbSkip())
			enddo

			nuQprnOut('Report Complete.')
			PRINT_OFF RPT_COMPLETE_EJECT
		endif
	endif
	close databases

return( nil )

static function diagRptHeader( nReportType, nPage )
	do case
	case nReportType == DIAG_RPT_GENERAL
		nuQprnOut(shMdy(date())+padc('Diagnostic Report',76)+'Page '+lStrim(nPage) )

	case nReportType == DIAG_RPT_DATE
		nuQprnOut(shMdy(date())+padc('Possible Date Errors',60)+'Page '+lStrim(nPage) )
	endcase

	nuQprnOut( time())
	nuQprnOut( )

return( nil )


Function DateErrorRpt()
	local nPage
	local nErrs := 0
	local nCnt  := 0
	local aFld2Chk := {}
	local cNote

	if !OpenFile({'Daily','Account','Cheque','PostBat','FinBat'}, DB_SHARED )
		close databases
		return( nil )
	endif

	if yesno({'Run Date Diagnostic Report?', ;
	      'This looks for forward dated and empty dates:', ;
			'-Daily (the Scale tickets)', ;
			'-Accounts (financial summary records)', ;
			'-Audit files (relates Daily and Accounts)', ;
			'-Cheque files (cheque summaries)' 			})

		if selectPrn('DATE_ERR.TXT')
			PRINT_ON  RPT_OVERWRITE
			nPage := 1

			DiagRptHeader( DIAG_RPT_DATE,  nPage )
			nPage++
			Daily->(ordSetFocus( DAILY_DEPOT_RECEIPT_ORD ))    // Fixed I think, BH Apr 15, 2020
			Daily->(dbGoTop())
			nuQprnOut('Testing Daily Receipts (scale tickets)...')

			msgLine('Checking Receipts...')
			nCnt     := 0
			nErrs    := 0
			aFld2Chk := {}
			SetArrayDateFlds( aFld2Chk, 'DAILY' )

			nuQprnOut('Potential Errors in Daily Show Below:')

			do while !Daily->(eof())
				nCnt++
				if nCnt % 100 == 0
					showProg( nCnt )
				endif

				cNote := cDateErrs( aFld2Chk, 'DAILY')
				if !empty( cNote )
					nuQprnOut( ' ')
					nuQQprnOut( ' RecNo=' + str( Daily->(recno()),10) )
					nuQQprnOut( cNote )
					nuQQprnOut( 'Grower='+ str(Daily->number,FLD_GROWER ) )
					nuQQprnOut(  Daily->depot )
					nuQQprnOut(  Daily->RECPT )
					nErrs++

					if NearPageBottom( 9 )
						nuFormFeed()
						DiagRptHeader( DIAG_RPT_DATE, nPage )
						nPage++
					endif
				endif

				Daily->(dbSkip())
			enddo
			if nErrs > 0
				nuQprnOut('* '+lStrim(nErrs)+' Error(s)')
			else
				nuQprnOut('* no errors found in Daily')
			endif
			nuQprnOut()

			nuQprnOut()
			msgLine('Testing Accounting Transactions...')
			nuQprnOut('Potential Errors in the Account file follow below')
			Account->(ordSetFocus( ACCOUNT_LINK_ORD ))
			Account->(dbGoTop())
			nCnt      := 0
			nErrs     := 0
			aFld2Chk  := {}
			SetArrayDateFlds( aFld2Chk, 'ACCOUNT' )

			do while !Account->(eof())
				nCnt++
				if nCnt % 100 == 0
					showProg( nCnt )
				endif
				cNote := cDateErrs( aFld2Chk, 'ACCOUNT')
				if !empty( cNote )
					nuQprnOut( ' ')
					nuQQprnOut( 'RecNo=' + str( Account->(recno()),10)+' ' )
					nuQQprnOut( cNote )
					nuQQprnOut( ' Grower='+ str(Account->number,FLD_GROWER ) )
					nuQQprnOut( ' ID='+str(Account->acct_uniq,FLD_DOCUMENT) )

					nErrs++

					if NearPageBottom( 9 )
						nuFormFeed()
						DiagRptHeader( DIAG_RPT_DATE, nPage )
						nPage++
					endif
				endif
				Account->(dbSkip())
			enddo
			if nErrs > 0
				nuQprnOut('* '+lStrim(nErrs)+' Error(s)')
			else
				nuQprnOut('* no errors found in Account')
			endif

			msgLine('Testing Cheques...')
			nuQprnOut()
			nuQprnOut('Looking for Date errors in Cheques')
			Cheque->(ordSetFocus( 0 ))
			Cheque->(dbGoTop())
			nCnt     := 0
			nErrs    := 0
			aFld2Chk := {}
			SetArrayDateFlds( aFld2Chk, 'CHEQUE' )

			do while !Cheque->(eof())
				nCnt++
				if nCnt % 100 == 0
					showProg( nCnt )
				endif
				cNote := cDateErrs( aFld2Chk, 'CHEQUE')
				if !empty( cNote )
					nuQprnOut( ' ')
					nuQQprnOut( 'RecNo=' + str( Cheque->(recno()),10)+' ' )
					nuQQprnOut( cNote )
					nuQQprnOut( ' Grower='+ str( Cheque->number,FLD_GROWER ) )
					nuQQprnOut( ' Chq#='+ Cheque->series + str( Cheque->cheque, FLD_CHEQUE ) )

					nErrs++

					if NearPageBottom( 9 )
						nuFormFeed()
						DiagRptHeader( DIAG_RPT_DATE, nPage )
						nPage++
					endif
				endif
				Cheque->(dbSkip())
			enddo
			if nErrs > 0
				nuQprnOut('* '+lStrim(nErrs)+' Error(s)')
			else
				nuQprnOut('* no errors found in Cheque')
			endif

			nuQprnOut()

			PostBat->(ordSetFocus( 0 ))
			PostBat->(dbGoTop())
			nuQprnOut('Testing Post Batch Header...')

			msgLine('Checking Advance Postings Batch Header...')
			nCnt     := 0
			nErrs    := 0
			aFld2Chk := {}
			SetArrayDateFlds( aFld2Chk, 'POSTBAT' )

			nuQprnOut('Potential Errors in Advance Postings Batch Below:')

			do while !PostBat->(eof())
				nCnt++
				if nCnt % 100 == 0
					showProg( nCnt )
				endif

				cNote := cDateErrs( aFld2Chk, 'POSTBAT')
				if !empty( cNote )
					nuQprnOut( ' ')
					nuQQprnOut( 'RecNo=' + str( PostBat->(recno()),10)+ ' ' )
					nuQQprnOut( cNote )
					nuQQprnOut( ' Adv Batch='+ str( PostBat->Post_Bat,FLD_DOCUMENT ) )
					nErrs++

					if NearPageBottom( 9 )
						nuFormFeed()
						DiagRptHeader( DIAG_RPT_DATE, nPage )
						nPage++
					endif
				endif

				PostBat->(dbSkip())
			enddo
			if nErrs > 0
				nuQprnOut('* '+lStrim(nErrs)+' Error(s)')
			else
				nuQprnOut('* no errors found in PostBat')
			endif
			nuQprnOut()


			FinBat->(ordSetFocus( 0 ))
			FinBat->(dbGoTop())
			nuQprnOut('Testing Final Payment Batch Header...')

			msgLine('Checking Final Postings Batch Header...')
			nCnt     := 0
			nErrs    := 0
			aFld2Chk := {}
			SetArrayDateFlds( aFld2Chk, 'FINBAT' )

			nuQprnOut('Potential Errors in Final Payout Postings Batch Below:')

			do while !FinBat->(eof())
				nCnt++
				if nCnt % 100 == 0
					showProg( nCnt )
				endif

				cNote := cDateErrs( aFld2Chk, 'FINBAT')
				if !empty( cNote )
					nuQprnOut( ' ')
					nuQQprnOut( 'RecNo=' + str( FinBat->(recno()),10)+ ' ' )
					nuQQprnOut( cNote )
					nuQQprnOut( ' Adv Batch='+ str( FinBat->Fin_Bat,FLD_DOCUMENT ) )
					nErrs++

					if NearPageBottom( 9 )
						nuFormFeed()
						DiagRptHeader( DIAG_RPT_DATE, nPage )
						nPage++
					endif
				endif

				FinBat->(dbSkip())
			enddo
			if nErrs > 0
				nuQprnOut('* '+lStrim(nErrs)+' Error(s)')
			else
				nuQprnOut('* no errors found in FinBat')
			endif
			nuQprnOut()

			nuQprnOut('Report Complete.')
			PRINT_OFF RPT_COMPLETE_EJECT
		endif
	endif
	close databases

return( nil )

static Function SetArrayDateFlds( aRay, cFile )
	local n
	local aFlds
	local c

	if len( aRay ) <> 0
		WaitInfo({'What the heck! Bad aRay'})
		return( nil )
	endif

	aFlds := (cFile)->(dbStruct())
	for n := 1 to len( aFlds )
		if aFlds[n, DBS_TYPE ] == 'D'
			c := aFlds[n, DBS_NAME ]
			if !('ADD_DATE' $ c .or. ;
			     'EDIT_DATE' $ c .or. ;
				  'DEL_DATE' $ c .or. ;
				  'EDITED'  $  c .or. ;
				  'ED_DATE' $ c  .or. ;
				  'DATECLEAR' $ c	  )

				//  We are not worried about dates that records
				//   were added to files etc.
				//  A_DATE_FLD_NUMBER   1
				//  A_DATE_FLD_NAME     2
				aadd( aRay, { n, aFlds[n, DBS_NAME] } )  // which field is
			endif
		endif
	next

return( nil )

static Function cDateErrs( aRay, cFile )
	local n
	local cReturn := ''
	local dDate

	for n := 1 to len( aRay )
		dDate := (cFile)->(FieldGet( aRay[n,A_DATE_FLD_NUMBER ] ))
		do case
		case empty( dDate )
			cReturn += 'Empty Date in '+aRay[n,A_DATE_FLD_NAME ]+' '
		case dDate < date()-(365*5)
			cReturn += 'Old Date in '+aRay[n,A_DATE_FLD_NAME ]+' '+mdy( dDate)+' '
		case dDate > date()
			cReturn += 'Forward Date in '+aRay[n,A_DATE_FLD_NAME ]+' '+mdy( dDate)+' '
		endcase
	next

return( cReturn )

// Diagnoses Linkage errors between Daily out to Account
Function DiagLinkageRpt()
	// local cDepot,nReceipt,cLetter
	// local nAcctUniq, nDailyUniq, nAcctChild
	// local nDailyErr := 0, nAcctUniqErr := 0, nAcctDailyErr := 0, nAcctChildErr := 0
	// local lErr := .f.
	// local lNote := .f.
	// local nCnt, nTicks
	// local cTmp,c
	// local aTick
	local aErrors   := {}
	// local n
   local nDailyUniq
	// local aRecs
   local aRayAdv    := {}
	local aW
	local getList    := {}
   local nGrower    := 0
   local nWhich
   local cTicket    := ''
   local lError     := .f.
   local cErrNote   := ''
   local lShowAll   := .f.
   local nToShow    := 15
   local nShows     := 0

	if !OpenFile({'Account','AudAcct','Audit',   'Cheque', 'Daily',  ;
	              'FinBat', 'Grower', 'PostBat'         }, DB_SHARED )
		close databases
		return( nil )
	endif

	create window at 8,05,17,75 title 'Diagnostic Report on Payables' to aW
	display window aW

	set cursor on


   /*
	in window aW @ 4,2 winsay 'This assigns a UNIQUE ID to any Receipts that are BLANK'

	in window aW 04,02 winsay 'Leave Grower Number blank to look at ALL receipts.'
	in window aW 05,02 winsay 'Enter a Grower number to look only at receipts for'
	in window aW 06,02 winsay 'a single grower.'
   */

	do while .t.
   	in window aW @2,02 winsay 'Single Grower Only?: ' winget nGrower ;
   	 picture NumBlankPic(FLD_GROWER) ;
   	 LOOKUP( LU_GROWER, '[F5] to Browse in Numeric Order')


   	in window aW @3,02 winsay 'Show details for each entry, even if no error?:' winget lShowAll ;
   	 picture 'Y' ;
       get_message 'Y=shows each item, even if there are no errors (mostly for Bill)'

   	in window aW @4,02 winsay 'Max Number of details to show' winget nToShow picture '999999' ;
       get_message 'Usually you will not want to show too many items on screen'

		read

      do case
      case lastkey() == K_ESC
			exit
      case empty(nGrower) .and. lShowAll
      	if !yesno({'Are you sure you want to show all entries - this can be painful?'})
         	loop
         endif
		endcase

		if yesno({'Run Linkage Diagnostic Report?', ;
				'This looks at links between Daily.DBF scale tickets', ;
				'and the Account Records.', ;
				' Looks at Audit files (relates Daily and Accounts)', ;
				' Looks for associated Accounts (financial summary records)' })

			if !empty( nGrower )
				Daily->( dbSetFilter( { || Daily->number == nGrower }, 'Daily->number == nGrower'))
			else
				Daily->( dbClearFilter())
			endif

			if yesno({'Ready to RIP?'})
				// PRINT_ON  RPT_OVERWRITE
				// gRptPrintSize( {}, 112 )   // July 31, 2021
				msgLine('Checking Receipts...Test 1/2..')

				PostBat->(ordSetFocus( POSTBAT_BATCH_ORD   ))             // this is FIXED I think April 29, 2020
				FinBat->( ordSetFocus( FINBAT_BATCH_ORD       ))
				Daily->(  ordSetFocus( DAILY_DEPOT_RECEIPT_ORD ))
				Audit->(  ordSetFocus( AUDIT_DAY_ACCT_ORD  ))
				Account->(ordSetFocus( ACCOUNT_LINK_ORD ))

            nShows := 0

				Daily->(dbGoTop())
				do while !Daily->(eof())
					nDailyUniq := Daily->day_uniq
               cTicket    := Daily->depot + str(Daily->recpt,FLD_RECPT) + Daily->RECPTLTR
					lError   := .f.
					cErrNote := ''

               msgLine( 'Grower/Recpt ' + var2char( Daily->number) +'  '+ cTicket )


						//             1     2     3      4      5       6      7
						//            Adv1  Levy  Adv2   Adv3   Final  Special Other/Premiums etc

					aRayAdv := { {  0,   0,    0,     0,     0,      0 ,    0}, ;      /*  A_RAY_ADV_ROW_1ST_ADVANCE  */
									 {  0,   0,    0,     0,     0,      0 ,    0}, ;      /*  A_RAY_ADV_ROW_MARKET_DED   */
									 {  0,   0,    0,     0,     0,      0 ,    0}, ;      /*  A_RAY_ADV_ROW_2ND_ADVANCE  */
									 {  0,   0,    0,     0,     0,      0 ,    0}, ;      /*  A_RAY_ADV_ROW_3RD_ADVANCE  */
									 {  0,   0,    0,     0,     0,      0 ,    0}, ;      /*  A_RAY_ADV_ROW_FINAL        */
									 {  0,   0,    0,     0,     0,      0 ,    0}, ;      /*  A_RAY_ADV_ROW_BONUS        */
									 {  0,   0,    0,     0,     0,      0 ,    0}    }    /*  A_RAY_ADV_ROW_OTHER        */


					// we must find a link
					if !( Audit->(dbSeek( str( nDailyUniq, FLD_AD_LINK ), HARDSEEK )))

						// if the Batch Numbers are all ZERO, it is just fine...nothing has been done
						if num2NotEqual0( Daily->post_bat1 ) .or. ;
							num2NotEqual0( Daily->post_bat2 ) .or. ;
							num2NotEqual0( Daily->post_bat3 ) .or. ;
							num2NotEqual0( Daily->fin_bat )

							cErrNote +=  'Can NOT find Audit Record!'
							lError   := .t.

							if !empty(cErrNote) .or. lError
								if nShows  < nToShow
									nShows++
									DailyVsAccountErr( cErrNote, cTicket, aRayAdv )
								endif
								aadd( aErrors, ' Grower: '+str( Daily->number, FLD_GROWER)+ '  Recpt:' + cTicket + '  '+ padr( cErrNote, 70 ))
							endif
						endif
					else
						ShowProg( Audit->day_uniq )

						do while Audit->day_uniq == nDailyUniq .and. !Audit->(eof())

							if Account->(dbSeek( str( Audit->acct_uniq, FLD_AD_LINK ), HARDSEEK ))

								nWhich := 0
								do while Account->acct_uniq == Audit->acct_uniq .and. !Account->(eof())
									do case
									case Account->type == TT_BERRY_ADVANCE_1
										nWhich := A_RAY_ADV_ROW_1ST_ADVANCE
									case Account->Type == TT_STD_DEDUCTION
										nWhich := A_RAY_ADV_ROW_MARKET_DED
									case Account->type == TT_BERRY_ADVANCE_2
										nWhich := A_RAY_ADV_ROW_2ND_ADVANCE
									case Account->type == TT_BERRY_ADVANCE_3
										nWhich := A_RAY_ADV_ROW_3RD_ADVANCE
									case Account->type == TT_FINAL_BERRY
										nWhich := A_RAY_ADV_ROW_FINAL
									case Account->type == TT_SPECIAL_BERRY
										nWhich := A_RAY_ADV_ROW_BONUS
									otherwise
										nWhich := A_RAY_ADV_ROW_OTHER
									endcase

									aRayAdv[ nWhich, A_RAY_ADV_COL_COUNTS      ]++
									aRayAdv[ nWhich, A_RAY_ADV_COL_LBS         ] := Account->lbs
									aRayAdv[ nWhich, A_RAY_ADV_COL_PRICE       ] := Account->u_price
									// aRayAdv[ nWhich, A_RAY_ADV_COL_BATCH       ] := Account->adv_bat
									aRayAdv[ nWhich, A_RAY_ADV_COL_ACCOUNT_ID  ] := Account->acct_uniq
									aRayAdv[ nWhich, A_RAY_ADV_COL_TOT_PRICE   ] := Account->dollars

									do case
									case nWhich == A_RAY_ADV_ROW_1ST_ADVANCE .or. nWhich ==  A_RAY_ADV_ROW_MARKET_DED .or. ;
										  nWhich == A_RAY_ADV_ROW_2ND_ADVANCE .or. nWhich ==  A_RAY_ADV_ROW_3RD_ADVANCE

										aRayAdv[ nWhich, A_RAY_ADV_COL_BATCH       ] := Account->adv_bat
									case nWhich ==  A_RAY_ADV_ROW_FINAL
										aRayAdv[ nWhich, A_RAY_ADV_COL_BATCH       ] := Account->fin_bat

									endcase

									Account->(dbSkip())
								enddo

							endif

							// aadd( aRay, { Audit->acct_uniq, '', 0 , '', 0 })
							Audit->(dbSkip())
						enddo


						// final Issued.  Advances are NOT necessarily issued.
						// But the Final actual payout (sum of ACCOUNT Advances + ACCOUNT Final SB=  Daily->fin_price

						if ErrInFinal( aRayAdv )
							cErrNote += 'Final Calc? '
							lError   := .t.
						endif

						// Advance 3 issued, so other advances should be present.
						if aRayAdv[ A_RAY_ADV_ROW_3RD_ADVANCE, A_RAY_ADV_COL_COUNTS   ] > 0
							if aRayAdv[ A_RAY_ADV_ROW_2ND_ADVANCE, A_RAY_ADV_COL_COUNTS ] == 0 .or. ;
								aRayAdv[ A_RAY_ADV_ROW_1ST_ADVANCE, A_RAY_ADV_COL_COUNTS ] == 0
								cErrNote += 'Issue with 3 Advances '
								lError   := .t.
							endif
						endif

						if aRayAdv[ A_RAY_ADV_ROW_2ND_ADVANCE, A_RAY_ADV_COL_COUNTS ] > 0
							if aRayAdv[ A_RAY_ADV_ROW_1ST_ADVANCE, A_RAY_ADV_COL_COUNTS ] == 0
								cErrNote +=  'Issue with 2 Advances '
								lError   := .t.
							endif
						endif

						if num2Equal0( aRayAdv[ A_RAY_ADV_ROW_1ST_ADVANCE, A_RAY_ADV_COL_COUNTS  ])  .and. ;
											Daily->post_bat1 > 0 .and. Daily->adv_pr1 > 0
							cErrNote +=  'problem w/ 1st Advance '
							lError   := .t.
						endif

						if num2Equal0( aRayAdv[ A_RAY_ADV_ROW_2ND_ADVANCE, A_RAY_ADV_COL_COUNTS  ]) .and. ;
											Daily->post_bat2 > 0 .and. Daily->adv_pr2 > 0
							cErrNote +=  'problem w/ 2nd Advance '
							lError   := .t.
						endif

						if num2Equal0( aRayAdv[ A_RAY_ADV_ROW_3RD_ADVANCE, A_RAY_ADV_COL_COUNTS  ]) .and. ;
											Daily->post_bat3 > 0 .and. Daily->adv_pr3 > 0
							cErrNote +=  'problem w/ 3rd Advance '
							lError   := .t.
						endif

						if num2Equal0( aRayAdv[ A_RAY_ADV_ROW_FINAL, A_RAY_ADV_COL_COUNTS  ]) .and. ;
											Daily->fin_bat > 0 .and. Daily->fin_price > 0
							cErrNote +=  'problem w/ Final Pay '
							lError   := .t.
						endif

						if aRayAdv[ A_RAY_ADV_ROW_FINAL,       A_RAY_ADV_COL_COUNTS ] > 1 .or.   ;
							aRayAdv[ A_RAY_ADV_ROW_3RD_ADVANCE, A_RAY_ADV_COL_COUNTS ] > 1 .or. ;
							aRayAdv[ A_RAY_ADV_ROW_2ND_ADVANCE, A_RAY_ADV_COL_COUNTS ] > 1 .or. ;
							aRayAdv[ A_RAY_ADV_ROW_1ST_ADVANCE, A_RAY_ADV_COL_COUNTS ] > 1
								cErrNote += 'Too many Pays '
								lError   := .t.
						endif

						if !empty(cErrNote) .or. lError
							if nShows  < nToShow
								nShows++
								DailyVsAccountErr( cErrNote, cTicket, aRayAdv )
							endif
							aadd( aErrors, ' Grower: '+str( Daily->number, FLD_GROWER)+ '  Recpt:' + cTicket + '  '+ padr( cErrNote, 70 ))
						else
							if lShowAll
								if nShows  < nToShow
									nShows++
									DailyVsAccountErr( 'No Error Noted', cTicket, aRayAdv )
								endif
							endif
						endif
					endif

					Daily->(dbSkip())
				enddo

            if len( aErrors ) > 0
   	         WinArrayVu( aErrors, 'Potential Errors')
            else
					WaitInfo({'No problems found  !!'})
            endif
			endif
		endif
	enddo

	close databases
	kill window aW

return( nil )

static function DailyVsAccountErr( cNote, cTicket, aRayAdv )
	local aRay
	local nWhich
	local n

	//                  10        20        30        40        50        60
	//         123456789_123456789_123456789_123456789_123456789_123456789_
	//               1234567            12345678             123456
	//                       $123456789          $1234567890        123456789
	//         Adv#  PostBat    U Price   Weight    TotPrice  Count   PrID/ID
	aRay := { 'Grower No='+var2char( Daily->number ), ;
             'Potential Error with record with Ticket#: '+cTicket , cNote,  ;
	          'Info about Daily Record & Account follows:', '', ;
             'Adv#  PostBat    U Price   Weight    TotPrice  Count      ID' }

	nWhich := A_RAY_ADV_ROW_1ST_ADVANCE // advance 1

	aadd( aRay,  ;
             'D  1 ' + ;
						   str( Daily->post_bat1,7) + ' '+ ;
									padl( '$'+alltrim( str( Daily->adv_pr1,9,2)),9) + ' ' +;
												   str( Daily->net,8)+' '+ ;
																padl('$'+ alltrim( str( Daily->adv_pr1 * Daily->net,10,2)),10) + ' ' + ;
															               space(6)+ ' '+ ;
                                                               str( Daily->adv_prID1,9)  )
	aadd( aRay,  ;
 				 ' Acc '+ ;
						   str( aRayAdv[ nWhich, A_RAY_ADV_COL_BATCH ],7) + ' '+ ;
									padl( '$'+ alltrim( str( aRayAdv[ nWhich, A_RAY_ADV_COL_PRICE ],9,2)),9) + ' ' + ;
												   str( aRayAdv[ nWhich, A_RAY_ADV_COL_LBS ],8)+' '+ ;
																padl('$'+ alltrim( str( aRayAdv[ nWHich, A_RAY_ADV_COL_TOT_PRICE ] ,10,2)),10) + ' ' + ;
																            str( aRayAdv[ nWHich, A_RAY_ADV_COL_COUNTS],6) + ' ' + ;
                                                                   str( aRayAdv[ nWhich, A_RAY_ADV_COL_ACCOUNT_ID],9)  )

	if !( aRayAdv[ nWhich, A_RAY_ADV_COL_BATCH ] == Daily->post_bat1) .or. ;
		!( aRayAdv[ nWhich, A_RAY_ADV_COL_PRICE ] == Daily->adv_pr1   )

		n := len( aRay )
		aRay[ n ] +=  '  Err?'
	endif

	nWhich := A_RAY_ADV_ROW_2ND_ADVANCE // advance 2

	aadd( aRay,  ;
             'D  2 ' + ;
						   str( Daily->post_bat2,7) + ' '+ ;
									padl( '$'+alltrim( str( Daily->adv_pr2,9,2)),9) + ' ' +;
												   str( Daily->net,8)+' '+ ;
																padl('$'+ alltrim( str( Daily->adv_pr2 * Daily->net,10,2)),10) + ' ' + ;
															               space(6)+ ' '+ ;
                                                               str( Daily->adv_prID2,9)  )

	aadd( aRay,  ;
 				 ' Acc '+ ;
						   str( aRayAdv[ nWhich, A_RAY_ADV_COL_BATCH ],7) + ' '+ ;
									padl( '$'+ alltrim( str( aRayAdv[ nWhich, A_RAY_ADV_COL_PRICE ],9,2)),9) + ' ' + ;
												   str( aRayAdv[ nWhich, A_RAY_ADV_COL_LBS ],8)+' '+ ;
																padl('$'+ alltrim( str( aRayAdv[ nWHich, A_RAY_ADV_COL_TOT_PRICE ] ,10,2)),10) + ' ' + ;
																            str( aRayAdv[ nWHich, A_RAY_ADV_COL_COUNTS],6) + ' ' + ;
                                                                   str( aRayAdv[ nWhich, A_RAY_ADV_COL_ACCOUNT_ID],9)  )

	if !( aRayAdv[ nWhich, A_RAY_ADV_COL_BATCH ] == Daily->post_bat2) .or. ;
		!( aRayAdv[ nWhich, A_RAY_ADV_COL_PRICE ] == Daily->adv_pr2   )

		n := len( aRay )
		aRay[ n ] +=  '  Err?'
	endif


	nWhich := A_RAY_ADV_ROW_3RD_ADVANCE  // Advance 3
	aadd( aRay,  ;
             'D  3 ' + ;
						   str( Daily->post_bat3,7) + ' '+ ;
									padl( '$'+alltrim( str( Daily->adv_pr3,9,2)),9) + ' ' +;
												   str( Daily->net,8)+' '+ ;
																padl('$'+ alltrim( str( Daily->adv_pr3 * Daily->net,10,2)),10) + ' ' + ;
															               space(6)+ ' '+ ;
                                                               str( Daily->adv_prID3,9)  )

	aadd( aRay,  ;
 				 ' Acc '+ ;
						   str( aRayAdv[ nWhich, A_RAY_ADV_COL_BATCH ],7) + ' '+ ;
									padl( '$'+ alltrim( str( aRayAdv[ nWhich, A_RAY_ADV_COL_PRICE ],9,2)),9) + ' ' + ;
												   str( aRayAdv[ nWhich, A_RAY_ADV_COL_LBS ],8)+' '+ ;
																padl('$'+ alltrim( str( aRayAdv[ nWHich, A_RAY_ADV_COL_TOT_PRICE ] ,10,2)),10) + ' ' + ;
																            str( aRayAdv[ nWHich, A_RAY_ADV_COL_COUNTS],6) + ' ' + ;
                                                                   str( aRayAdv[ nWhich, A_RAY_ADV_COL_ACCOUNT_ID],9)  )


	nWhich := A_RAY_ADV_ROW_FINAL  // Final

	aadd( aRay,  ;
             'Final' + ;
						   str( Daily->fin_bat,7) + ' '+ ;
									padl( '$'+alltrim( str( Daily->fin_price,9,2)),9) + ' ' +;
												   str( Daily->net,8)+' '+ ;
																padl('$'+ alltrim( str( Daily->fin_price * Daily->net,10,2)),10) + ' ' + ;
															               space(6)+ ' '+ ;
                                                               str( Daily->fin_pr_id,9)  )

	aadd( aRay,  ;
 				 ' Acc '+ ;
						   str( aRayAdv[ nWhich, A_RAY_ADV_COL_BATCH ],7) + ' '+ ;
									padl( '$'+ alltrim( str( aRayAdv[ nWhich, A_RAY_ADV_COL_PRICE ],9,2)),9) + ' ' + ;
												   str( aRayAdv[ nWhich, A_RAY_ADV_COL_LBS ],8)+' '+ ;
																padl('$'+ alltrim( str( aRayAdv[ nWHich, A_RAY_ADV_COL_TOT_PRICE ] ,10,2)),10) + ' ' + ;
																            str( aRayAdv[ nWhich, A_RAY_ADV_COL_COUNTS],6) + ' ' +  ;
                                                               str( aRayAdv[ nWhich, A_RAY_ADV_COL_ACCOUNT_ID],9)  );

   if ErrInFinal(  aRayAdv )
		n := len( aRay )
		aRay[ n ] +=  '  Err?'
	endif

   if aRayAdv[ A_RAY_ADV_ROW_MARKET_DED, A_RAY_ADV_COL_COUNTS  ] >= 1
		aadd(aRay, 'We also have ' + var2char( aRayAdv[ A_RAY_ADV_ROW_MARKET_DED, A_RAY_ADV_COL_COUNTS ]) + ;
		                  ' Standard Marketing Deduction(s)')
	endif


   if aRayAdv[ A_RAY_ADV_ROW_BONUS, A_RAY_ADV_COL_COUNTS ] >= 1
		aadd(aRay, 'We also have ' + var2char( aRayAdv[ A_RAY_ADV_ROW_BONUS, A_RAY_ADV_COL_COUNTS ]) + ;
		                       ' Bonus Payout(s)')
	endif

   if aRayAdv[ A_RAY_ADV_ROW_OTHER, A_RAY_ADV_COL_COUNTS ] >= 1
		aadd(aRay, 'We also have ' + var2char( aRayAdv[ A_RAY_ADV_ROW_OTHER, A_RAY_ADV_COL_COUNTS ]) + ;
		                                ' Other Payout(s)-Check them!')
	endif

   aadd(aRay, '')
   aadd(aRay, 'D1,D2,D3 & Final are Payments taken from the Daily receipt table (DAILY.DBF).' )
   aadd(aRay, 'Acc      are actual payments from the Accounts Payable table (ACCOUNT.DBF)' )
	aadd(aRay, 'These should agree for Advances, as should the Unit Price. But the Weight and' )
	aadd(aRay, 'total amounts will not necessarily agree as the Account Records are aggregates of Daily')
	aadd(aRay, 'Receipts.  The IDs will not agree.  The Count of Advances should be either 1 or 0!  A count')
	aadd(aRay, 'of 1 indicates an actual payout.  If the Daily (D) line shows a PostBat & Price, but the')
	aadd(aRay, 'dashed line shows a PostBat of 0 and no price, this means System is CONFUSED about whether')
	aadd(aRay, 'an advance has been paid out - AND the Grower will likely be SHORT PAID !!!')


	WaitHand( aRay )

return( nil )

///</remarks>
/// Final Issued.  Advances are NOT necessarily issued.
/// But the Final actual payout (sum of ACCOUNT Advances + ACCOUNT Final SB=  Daily->fin_price
/// </remarks>
static function ErrInFinal(  aRayAdv )
	local lReturn := .f.
   local nPrice1, nPrice2

   // there is a BUG here! Old data (pre Nov 2022 and etc) will always have a ZERO in Daily->fin_bat
   //
   if Daily->fin_bat > 0 .and. aRayAdv[ A_RAY_ADV_ROW_FINAL, A_RAY_ADV_COL_BATCH ] > 0
		if !( aRayAdv[ A_RAY_ADV_ROW_FINAL, A_RAY_ADV_COL_BATCH ] == Daily->fin_bat)
   		lReturn := .t.
      endif
   endif

	nPrice1 := aRayAdv[ A_RAY_ADV_ROW_FINAL      , A_RAY_ADV_COL_PRICE ]  +        ;
              aRayAdv[ A_RAY_ADV_ROW_3RD_ADVANCE, A_RAY_ADV_COL_PRICE ]  +        ;
				  aRayAdv[ A_RAY_ADV_ROW_2ND_ADVANCE, A_RAY_ADV_COL_PRICE ]  +        ;
				  aRayAdv[ A_RAY_ADV_ROW_1ST_ADVANCE, A_RAY_ADV_COL_PRICE ]

   nPrice2 := Daily->Fin_Price

	if aRayAdv[ A_RAY_ADV_ROW_FINAL, A_RAY_ADV_COL_COUNTS ] > 0 .or. Daily->fin_bat > 0

   	if !( str( nPrice1, 10,3 ) == str( nPrice2,10,3))
			lReturn := .t.
      endif
   endif

return( lReturn )

