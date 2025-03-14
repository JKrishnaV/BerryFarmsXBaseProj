// PROGRAM ...: Ed_Recpt.PRG
// AUTHOR ....: Bill Hepler re-wrote in 1994
// DATE ......: 6/24/90
// NOTES .....: THIS ROUTINE INPUTS/EDITS THE DAILY LOAD RECEIPTS.

// May 11, 1994
// Almost totally revised By BH to allow Edit...
// June 99 revised again - shows pricing
// Sep  99 revised a little to show audit trail for POSTED Transactions
// June 2000 - Now have ONLY daily.dbf, no unposted.
// June 2007 - Revised a bit for Manual Price
// Aug  2008 - Revised a bit for Dockage
// Oct 21, 2011 - Widened a couple things.
// Jul 29, 2014 - Printing and Non-Printing Notes
// Jun 06, 2015 - Minor changes to do with VARIETY Changes
// Sep 18, 2019 - We now show meaningful error messages when there is a Half Posting
//                of batch - that is they started the posting process but did not back out
//                in the normal way (this is probably a bug).  THe message is not really
//                possible for a user to interpret - they need to call me.
// Apr 20, 2020 - Some changes to indexes etc, & assigning
// Jan 20, 2022 - bug in field name fixed.

#include "account.ch"
#include "BerryPay.ch"
#include "browser.ch"
#include "bsgstd.ch"
#include "common.ch"
#include "errors.ch"
#include "events.ch"
#include "field.ch"
#include "indexord.ch"
#include "inkey.ch"
#include "miscpay.ch"
#include "sysvalue.ch"
#include "Unique_Fields.ch"
#include "valid.ch"
#include "window.ch"

#define  THE_CHQ_ARRAY   { '', ctod(''), 0.00, .t. }
#define  A_COL_CHEQUE_NO  1
#define  A_COL_DATE       2
#define  A_COL_AMOUNT     3
#define  A_COL_VOID       4

#define  A_ROW_WEEKLY     1
#define  A_ROW_YEARLY     2
// Specials are in other Rows

#define    MAY_EDIT_FULLY            1
#define    MAY_EDIT_PRICE            2
#define    MAY_EDIT_PRICE_AND_PROD   3
#define    MAY_NOT_EDIT              4


static dTheDate
static cTheTime
static cProcess,cProduct
static nGrade, nNet, nGrower
static nThePrice
static cFlashPriceErr    := ''

// Normally this has Daily->UF_THE_DAY_UNIQ in it!
#define    AUDIT_THE_NEXT_SAVE    -1
static nLastDailyIDSaved := AUDIT_THE_NEXT_SAVE    // this refers to a FULL save, I don't want to clutter the audit trail with little saves.


function QedDailyPrice()
	local getList :={}, nGrow := 0
	local nChoice
	local aW

	if !openMainStuff(DB_SHARED)
		close databases
	endif

	myBsgScreen( 'Edit Berry Receipts by Grower' )

	create window at 8,13,12,62 title 'Quick Edit Receipt Price' to aW
	display window aW
	set cursor on
	in window aW @ 4, 2 winsay 'Allows you to quickly Edit Prices'
	nGrower  := 0

	do while .t.
		in window aW @2,02 winsay 'Grower Number: ' winget nGrow ;
		 picture NumBlankPic(FLD_GROWER) ;
		 LOOKUP( LU_GROWER, '[F5] to Browse in Numeric Order')
		read

		do case
		case lastkey() == K_ESC
			exit
		otherwise

			nChoice := bsgChoice({'You may FILTER OUT transactions which', ;
								'have been Paid Out - or you can include paid', ;
								'out transctions in the browse.  In any case,', ;
								'you may not edit Tickets that have had a final', ;
								'payment issued against them.'}, ;
								{'EditableOnly','All','Cancel'})

			do case
			case nChoice == 1
				Daily->(dbSetFilter( { || str(Daily->fin_bat,10,2)==str(0,10,2) .and. str( Daily->net,10,2)<>str( 0, 10,2) }, ;
				 'str(Daily->fin_bat,10,2)==str(0,10,2) .and. str( Daily->net,10,2)<>str( 0, 10,2)' ))
			case nChoice == 2
				Daily->(dbSetFilter( { || str( Daily->net,10,2)<>str( 0, 10,2) }, ;
				 'str( Daily->net,10,2)<>str( 0, 10,2)' ))
			otherwise
				loop
			endcase

			Daily->(OrdSetFocus( DAILY_GROWER_ORD ))
			Daily->(dbSeek( str( nGrow, FLD_GROWER ), SOFTSEEK))
			if Daily->(eof())
				if Daily->(bof())
					waitHand({'Nothing on file'})
					loop
				else
					Daily->(dbSkip(-1))
				endif
			endif
			DailyBrEdit( 0 )
		endcase
	enddo
	kill window aW

	close databases

return( nil )

function ReceiptByNo( )
	// this I invented to Manually Edit Reciepts
	local getList :={}
	local nReceipt
	local cDepot
	local aW

	if !openMainStuff(DB_SHARED)
		close databases
	endif

	Depot->(dbGoTop())
	cDepot := Depot->depot
	myBsgScreen( 'Berry Receipts ordered by Receipt #' )

	create window at 8,13,13,72 title 'Add/Edit by Receipt #' to aW
	display window aW
	set cursor on
	in window aW @ 5, 2 winsay 'Allows you to check receipts in numeric order'
	nReceipt := 0

	do while .t.
		in window aW @ 2, 2 winsay 'Depot/Site' winget cDepot picture '@!' ;
		  when PutName(  aW,2, 17, LU_DEPOT, cDepot ) ;
		  valid PutName( aW,2, 17, LU_DEPOT, cDepot ) ;
		 LOOKUP( LU_DEPOT, '[F5] to Browse depots on file')

		in window aW @ 3, 2 winsay 'Receipt No' winget nReceipt ;
		 picture numBlankPic(FLD_RECPT) ;
		 get_message 'Enter Receipt # to look for'
		read

		PutName( aW, 2, 17, LU_DEPOT, cDepot )

		do case
		case lastkey() == K_ESC
			exit
		otherwise
			Daily->(OrdSetFocus( DAILY_DEPOT_RECEIPT_ORD))
			Daily->(dbSeek( cDepot + str( nReceipt, FLD_RECPT ), SOFTSEEK))
			if Daily->(eof())
				if Daily->(bof())
					waitHand({'Nothing on file like this'})
		        	DailyAddRec( 0 )
				else
					Daily->(dbSkip(-1))
				endif
			endif
			Daily->(DailyBrowse( 0, DAILY_ANY_TRANS ))
		endcase
	enddo
	kill window aW

	close databases

return( nil )


function EditReceipt(  )
	// this I invented to Manually Edit Reciepts
	local nChoice, n

	if !openMainStuff(DB_SHARED)
		close databases
	endif

	myBsgScreen( 'Input/Change/View Berry Receipts' )

	do while .t.
		nChoice := bsgChoice({'You may view unposted receipts', ;
		 '(which can be edited)', ;
		 'or all receipts - (posted ones can not be edited).'}, ;
		 {'Unposted','All','Cancel'})

		do case
		 case nChoice==3 .or. nChoice==0
		 	exit
		 case nChoice==1
			Daily->(OrdSetFocus( DAILY_ADV_POST_GROWER_ORD ))
			Daily->(dbGoTop())
			do case
			case Daily->(eof()) .or. (Daily->post_bat1 <> 0 .and. Daily->Last_AdvPB <> 0)
				if YesNo({'No Unposted Data on file', ;
						'Do you wish to add a record?'})
					DailyAddRec( 0 )
					Daily->(dbGoTop())
					if Daily->(eof()) .or. Daily->post_bat1 <> 0
						waithand({'No Unposted Data is on file'})
						loop
					endif
				else
					waithand({'No Unposted Data is on file'})
					loop
				endif
			endcase
			Daily->(DailyBrowse( 0, DAILY_UNPOSTED ))

		case nChoice==2
			Daily->(OrdSetFocus( DAILY_DATE_ORD ))
			Daily->(dbGoBottom())
			if Daily->(eof())
				if YesNo({'No Data on file', ;
						'Do you wish to add a record?'})
					DailyAddRec( 0 )
					Daily->(dbGoTop())
				endif
			endif
			if Daily->(eof())
				waithand({'No Data is on file'})
				loop
			else
				n := 0
				do while !Daily->(bof()) .and. n < 6
					n++
					Daily->(dbSkip(-1))
				enddo
			endif
			Daily->(DailyBrowse( 0, DAILY_ANY_TRANS ))
		endcase
	enddo

	close databases

return( nil )

function DailyAddRec( nWho )
	static dDate := NIL
	local getList :={},aW, nReceipt := 0
	local  cName
	local aDBF
	local nGrower
	local cHead
	local cDepot

	DEFAULT dDate TO date()-1

	nGrower := nWho
	cName   := space(FLD_NAME)

	aDBF  := Daily->(saveDBF())

	Depot->(dbGoTop())
	cDepot := Depot->depot

	if nWho == 0
		cHead := 'Add Record'
	else
		cHead := 'Add Record for Grower '+str(nWho,4)
	endif

	create window at 8,13,14,62 title cHead to aW
	display window aW
	set cursor on

	do while .t.
		in window aW @ 2, 5 winsay 'Date       ' winget dDate ;
		 picture '@D' valid ValidCropDate(dDate,VT_MESSAGE) ;
		 get_message 'Enter Date,  +/- keys will change date'

		in window aW @ 3, 5 winsay 'Depot/Site ' winget cDepot picture '@!' ;
		 LOOKUP( LU_DEPOT, '[F5] to Browse depots on file')

		in window aW @ 4, 5 winsay 'Receipt No ' winget nReceipt ;
		 picture numBlankPic(FLD_RECPT)

		if nWho==0
	      in window aW @ 5, 5 winsay 'Grower Number' winget nGrower ;
		    picture numBlankPic(FLD_NUMBER) ;
			 LOOKUP( LU_GROWER, '[F5] to Look up Grower by Grower ID')

			in window aW @ 6, 5 winsay 'Grower Name  ' winget cName   ;
		    picture '@!' ;
			 LOOKUP( LU_GROWER_NAME, '[F5] to Look up Grower by Grower Name')
		endif

		read

		if lastkey()==K_ESC
			exit
		else
			if empty(dDate)
				waitHand({"You must fill in the Date"})
				loop
			endif
			if empty(nReceipt)
				waitHand({"You must fill in the Receipt No."})
				loop
			endif
			if !validTest(V_GROWER, nGrower, VT_MESSAGE)
				loop
			endif

			Daily->(OrdSetFocus( DAILY_DEPOT_RECEIPT_ORD ))
			if Daily->(dbSeek( cDepot +str(nReceipt,FLD_RECPT) ,HARDSEEK ))
				if !yesno({'We already have a receipt for this depot', ;
					 'with the same receipt number,' , ;
					 'It is for Grower '+lSTrim(Daily->number), ;
					 '  Date: '+shMDY( Daily->date )+'  ' + ;
					    iif( empty(Daily->product), 'Container only!',  ;
					           alltrim( NameOf(LU_SHORT_PRODUCT_NAME, Daily->product)+ ' '+Daily->process+GradeStr( Daily->grade) ) + ;
					           str( Daily->net, 8) ), ;
	      		 '', ;
				 	'Do you wish to Add this Receipt anyway?'})
					loop
				endif
			endif

			if Daily->(fileLock()) .and. CounterIDs->(fileLock()) .and. Daily_Audit->(fileLock())

				nAddUniqueRec( UF_THE_DAY_UNIQ , UNIQ_FILE_DO_NOT_NEED_LOCKS  )

				Daily->number := nGrower
	         Daily->date   := dDate
	         Daily->recpt  := nReceipt
				Daily->depot  := cDepot
				Daily->time   := time()

				Daily->np_note1 := "MANUALLY ADDED RECEIPT"
				Daily->(dbCommit())

				nAddUniqueRec( UF_THE_DAYAUD_ID, UNIQ_FILE_DO_NOT_NEED_LOCKS  )
				ReplOneRec('Daily', 'Daily_Audit' )
				nLastDailyIDSaved := AUDIT_THE_NEXT_SAVE    // we will audit the Next Save

				Daily->np_note1 := ""
				Daily->(dbCommit())
				Daily->(dbUnlock())
			else
				loop
			endif

			DailyEdit( DAILY_EDIT_IN_READ_MODE, nWho )
			nReceipt ++

		endif
	enddo

	Daily->(restDBF( aDBF ))

	kill window aW

return( SIG_REDRAW )

///<summary>See DAILY_EDIT_ etc defines for what action(s) are allowed</summary>
Function DailyEdit( nAction, nWho , lJustAdded )
	local getList := {},  nEditStat := 0, nRec
	local aContainer[ MAX_TYPES_CONTAINERS, 2]
	local n, nChoice
	local aMsg
	local nEdit := MAY_NOT_EDIT
	local cMsg
	local aWin
	local cRecptLtr
	local nRecpt
	local lRefresh := .f.                // do we need to REFRESH?
	local aOrigData := {}, aNewData := {}
	local cDepot,c
	local aRay
	local nReturn := SIG_REDRAW
	local lChanged := .f.
	local lFirstPass := .t.

	default lJustAdded to .f.   // because normally we are editing an "established ticket"

	do case
	case nAction == DAILY_EDIT_VIEW_ONLY
		nEdit := MAY_NOT_EDIT
		cMsg  := 'Viewing Only'
	case Daily->post_bat1 == 0 .and. Daily->fin_bat == 0
		nEdit := MAY_EDIT_FULLY
		if lJustAdded
			cMsg  := 'May Edit'
		else
			cMsg := 'Should Edit'
		endif
	case Daily->fin_Bat > 0
		nEdit := MAY_NOT_EDIT
		cMsg  := 'Paid Out-May NOT edit'
	otherwise
		// if we are just changing the PRODUCT and we priced the Advance
		// based on Process, we can change the PRODUCT...
		nEdit := MAY_EDIT_PRICE
		cMsg  := 'May Edit Final Price'
		if Daily->adv_prid1 > 0 .and. Daily->adv_prid2 == 0 .and. ;
			!empty( Daily->product)
			Price->(OrdSetFocus(PRICE_PRICE_ID_ORD))
			if Price->(dbSeek( str(Daily->adv_prid1, FLD_DOCUMENT ), HARDSEEK ))
				if empty( Price->product )
					nEdit := MAY_EDIT_PRICE_AND_PROD
					cMsg  := 'May Ed F.Price & Prod'
				endif
			endif
		endif
	endcase

	if nAction == DAILY_EDIT_IN_READ_MODE .and. nEdit <> MAY_NOT_EDIT
		nEditStat := 1
	else
		nEditStat := 0
	endif

	create window at 1,2,22,78 title 'Daily Receipt Edit/View' to aWin
	display window aWin
	set cursor on

	aMsg := msgLine('Working with a Grower Receipt/Shipment Record')

	aOrigData := {}
	LoadUpData( aOrigData )

	do while .t.
		lChanged := .f.

		do case
	   case nAction == DAILY_EDIT_VIEW_ONLY
			nEdit := MAY_NOT_EDIT
			cMsg  := 'Viewing Only'
		case Daily->post_bat1 == 0 .and. Daily->fin_bat == 0
			nEdit := MAY_EDIT_FULLY
			if !lFirstPass .or. !lJustAdded
				cMsg  := 'May Edit'
			endif
		case Daily->fin_Bat > 0
			nEdit := MAY_NOT_EDIT
			cMsg  := 'Paid Out-May NOT edit'
		otherwise
			nEdit := MAY_EDIT_PRICE
			cMsg  := 'May Edit Final Price'
			// if we are just changing the PRODUCT and we priced the Advance
			// based on Process, we can change the PRODUCT...
			nEdit := MAY_EDIT_PRICE
			cMsg  := 'May Edit Final Price'
			if Daily->adv_prid1 > 0 .and. Daily->adv_prid2 == 0 .and. ;
				 !empty( Daily->product)
				Price->(OrdSetFocus(PRICE_PRICE_ID_ORD ))
				if Price->(dbSeek( str(Daily->adv_prid1, FLD_DOCUMENT ), HARDSEEK ))
					if empty( Price->product )
						nEdit := MAY_EDIT_PRICE_AND_PROD
						cMsg  := 'May Ed F.Price & Prod'
					endif
				endif
			endif
		endcase

		in window aWin @ 1,33 winsay padr('->'+cMsg,25)

		if empty( Daily->edited )
			in window aWin @ 22,35 winsay space(15)
		else
			in window aWin @ 22,35 winsay 'Ed: '+ shMDY( Daily->edited )
		endif

		// if lRefresh
		if nEdit <> MAY_NOT_EDIT .and. nEditStat==1
			if !Daily->(recLock())
				exit
			endif
		endif

		aOrigData := {}
		LoadUpData( aOrigData )

		nRecpt    := Daily->recpt
		cRecptLtr := Daily->recptltr
		dTheDate  := Daily->date
		cTheTime  := Daily->time
		nGrower   := Daily->number
		cProcess  := Daily->process
		cProduct  := Daily->product
		nGrade    := Daily->grade
		nNet      := Daily->net
		cDepot    := Daily->depot

		nThePrice := Daily->thePrice

		for n := 1 to len(aContainer)
			aContainer[n, 1] := Daily->(gsInContainer(n))
			aContainer[n, 2] := Daily->(gsOutContainer(n))
		next

		PutName( aWin, 1, 17, LU_DEPOT, cDepot )
		PutName( aWin, 3, 3, LU_GROWER, nGrower)
		PutName( aWin, 8, 3, LU_PRODUCT, cProduct)
		PutName( aWin,10, 3, LU_PROCESS_TYPE, cProcess)

		// endif

		FlashPrice( aWin )

		// lRefresh := .f.

		in window aWin  @ 1, 2 winsay    'Depot:    ' winget cDepot ;
			picture '@!' when PutName( aWin, 1, 17, LU_DEPOT, cDepot ) ;
			valid PutName( aWin, 1, 17, LU_DEPOT, cDepot ) ;
			LookUp( LU_DEPOT, ;
			'F5 to Browse - The Depot it was processed at - now set as '+cDepot )

		if nWho==0
		 	in window aWin  @ 2, 2 winsay 'Grower #: ' winget nGrower ;
		 	 PICTURE  NumBlankPic( FLD_GROWER  ) ;
	    	 when PutName(aWin, 3, 3 , LU_GROWER, nGrower) ;
	    	 valid ValidTest(V_GROWER, nGrower, VT_MESSAGE) ;
		   	 .and. PutName( aWin, 3, 3, LU_GROWER,nGrower) ;
				  .and. FlashPrice(  aWin ) ;
	        LOOKUP(LU_GROWER,'Enter Grower Number, F5 to Browse')
		else
			in window aWin  @ 2, 2 winSAY 'Grower #: '+' '+ ;
				str(nGrower, FLD_GROWER)
			PutName( aWin, 3, 3, LU_GROWER,nGrower)
		endif

		in window aWin  @ 4, 2 winsay    'Receipt #:' winget nRecpt ;
		 picture NumBlankPic( FLD_RECPT ) ;
			 get_message 'Receipt # for this transaction'
		in window aWin @ 4, 2 + 10+ 1+FLD_RECPT+1 winget cRecptLtr ;
			 picture '!' ;
			 get_message 'Put in a Letter if you need to for Reverses'

		in window aWin  @ 5, 2 winSay    'Date:     ' ;
			 winget dTheDATE picture '@d' ;
		 valid ValidCropDate( dTheDate,VT_MESSAGE) ;
		  .and. FlashPrice( aWin ) ;
		 get_message 'Enter Date as MM/DD/YYYY'

		in window aWin  @ 6, 2 winSay    'Time:     ' ;
			 winget cTheTime picture '99:99' ;
		 valid cTheTime <='24:00' .and. cTheTime >= '00:00'

		do case
		case !empty( Daily->np_note1) .or.  !empty( Daily->EDIT_REAS) .or. !empty( Daily->pr_note1)
			in window aWin  @ 5, 25 winSay    '  See  '
			in window aWin  @ 6, 25 winSay    ' Notes '
		otherwise
			in window aWin  @ 5, 25 winSay    '   no  '
			in window aWin  @ 6, 25 winSay    ' notes '
		endcase

		in window aWin  @ 7, 2 winsay    'Product:  ' winget cProduct ;
			picture '@!' when ;
			  PutName(aWin,8, 3, LU_PRODUCT, cProduct) ;
			 valid iif( empty( cProduct), .t. , ;
			  validTest(V_PRODUCT, cProduct, VT_BROWSE )) ;
			  .and. FlashPrice(  aWin ) ;
			  .and.  PutName(aWin,8, 3, LU_PRODUCT, cProduct) ;
			lookup(LU_PRODUCT, ;
			'Enter product or leave blank for Container only transaction')

		in window aWin  @ 9, 2 winsay    'Process:  ' winget cProcess ;
			picture '@!' when ;
			  PutName(aWin,10,3, LU_PROCESS_TYPE, cProcess) ;
			 valid iif( empty(cProcess), .t. , ;
			  validTest(V_PROCESS_TYPE, cProcess, VT_BROWSE )) ;
			  .and. FlashPrice(  aWin ) ;
			  .and.  PutName(aWin,10,3,LU_PROCESS_TYPE, cProcess) ;
			lookup(LU_PROCESS_TYPE, ;
			'Enter process type or leave blank for Container only transaction')

		in window aWin  @ 11, 2 winsay    'Grade:    ' winget nGrade   ;
			picture '9' ;
			 valid nGrade <= MAX_NO_OF_GRADES ;
			 .and. FlashPrice(  aWin ) ;
			get_message ;
			'Enter grades or leave blank for Container only transaction'

		in window aWin  @ 12, 2 winsay    'Net Wgt:  ' winget nNet   ;
			picture  NumBlankPic(FLD_LBS) ;
			valid FlashPrice(  aWin ) ;
			get_message ;
			'Leave blank for Container only Transactions'+ ;
			  iif(Daily->ori_net>0,', Original Net='+lStrim(Daily->ori_net), '')

		if (str(Daily->ori_net,10,1)<>str(nNet,10,1) .and. ;
			 Daily->ori_net > 0 ) .or. ;
			 Daily->dock_pct > 0

			 in window aWin @ 12,2+10+FLD_LBS+2 winsay 'Special'
		else
			 in window aWin @ 12,2+10+FLD_LBS+2 winsay '       '
		endif

		in window aWin @13,2 winsay 'Scale Price' winget nThePrice picture '999.99';
		 get_message 'Price from Scale or Manual Override'

		in window aWin @ 1,35+FLD_CONTAINER_DESC winsay padl('In',5)
		in window aWin @ 1,42+FLD_CONTAINER_DESC winsay padl('Out',5)

		for n := 1 to len(aContainer)

			if str(aContainer[n,1],12,2)<>str(0,12,2) .or. ;
			   str(aContainer[n,2],12,2)<>str(0,12,2) .or. ;
				ContInUse( n )

				in window aWin @ 1+n,35 winsay ContLName( n )
				in window aWin @ 1+n,35+FLD_CONTAINER_DESC winget ;
					aContainer[n,1] picture '99999'

				in window aWin @ 1+n,35+7+FLD_CONTAINER_DESC winget ;
					aContainer[n,2] picture '99999'
			else
				if n < 15
					in window aWin @ 1+n,35 winsay 'Cont. Type is not in use'
				endif
			endif
		next

		if num2Equal0(Daily->imp_bat)
			in window aWin @ 22, 46 winsay  padc('Input here',12)
		else
			in window aWin @ 22, 46 winsay  'Imp# '+ ;
				 padr(lStrim( Daily->imp_bat),7)
		endif

		in window aWin @ 22, 60 winsay  'Uniq ID: '+ ;
				 str( Daily->day_uniq,FLD_DOCUMENT)

		if nEditStat==1
			do case
			case nEdit == MAY_NOT_EDIT
				getList := {}
				thinWait('Viewing Transaction')
				lRefresh := .f.
			case nEdit == MAY_EDIT_PRICE .or. nEdit == MAY_EDIT_PRICE_AND_PROD
				getList := {}

				if nEdit == MAY_EDIT_PRICE
					thinWait('You may edit the Scale Price but NO other data')
				else
					WaitInfo({'You may edit the Scale Price, and the Product.', ;
								 'You may also edit the product - however, you', ;
								 'it may be better to REVERSE this transaction', ;
								 'and add a new transaction.'})
				endif

				if lastkey()<>K_ESC
					set cursor on

					cProduct := Daily->product
					if nEdit == MAY_EDIT_PRICE_AND_PROD
						in window aWin  @ 7, 2 winsay    'Product:  ' winget cProduct ;
						picture '@!' when ;
						  PutName(aWin,8, 3, LU_PRODUCT, cProduct) ;
						 valid validTest(V_PRODUCT, cProduct, VT_BROWSE ) ;
						  .and. FlashPrice(  aWin ) ;
						  .and.  PutName(aWin,8, 3, LU_PRODUCT, cProduct) ;
						lookup(LU_PRODUCT, ;
						'You may change product for this Transaction')
					endif

					in window aWin @13,2 winsay 'Scale Price' winget nThePrice picture '999.99';
					 get_message 'You may SET the Final Price Manually..'

					if lRefresh
						getList := {}
						thinWait('Viewing transaction...')
						lRefresh := .f.
					else
						read
						lRefresh := .t.
					endif

					if lastkey() <> K_ESC
						// Price Updater
						if cProduct <> Daily->product .and. ;
							  nEdit == MAY_EDIT_PRICE_AND_PROD
							Daily->product := cProduct
							lChanged := .t.
						endif
						if !(str(Daily->theprice,10,2)==str(nThePrice,10,2))
							Daily->thePrice := nThePrice
							Daily->PriceSrc := PRICE_SRC_KEY
							lChanged := .t.
						endif
						if lChanged
							Daily->edited := date()
							Daily->(EditByFlds())

							// This is so we don't bother saving every little change to Daily out to the audit.
							if !(Daily->Day_Uniq == nLastDailyIDSaved )
								if nAddUniqueRec( UF_THE_DAYAUD_ID, UNIQ_FILE_WE_NEED_LOCKS )  > 0  // Table is NOT locked
									ReplOneRec('Daily', 'Daily_Audit')           //
									nLastDailyIDSaved := Daily->DAY_UNIQ
								endif
							endif

							lChanged := .f.
						endif
					endif
				endif

				Daily->(dbCommit())
				Daily->(dbRunLock())

				nEditStat := 0
				if lRefresh
					lFirstPass := .f.
					loop
				endif

			otherwise
				msgLine('Unposted Transaction')

				if lRefresh
					getList := {}
					lRefresh := .f.
				 else
					read
					lRefresh := .t.
				endif

				if lastkey()==K_ESC
					exit
				endif

				aNewData := {}
				LoadUpData( aNewData )
				if DataChanged( aOrigData, aNewData )
					Daily->edited := date()
					Daily->(EditByFlds())

					// This is so we don't bother saving every little change to Daily out to the audit.
					if !(Daily->Day_Uniq == nLastDailyIDSaved )
						if nAddUniqueRec( UF_THE_DAYAUD_ID, UNIQ_FILE_WE_NEED_LOCKS )  // Table is NOT locked
							ReplOneRec('Daily', 'Daily_Audit')           //
							nLastDailyIDSaved := Daily->DAY_UNIQ
						endif
					endif
				endif

		     	if !validCropDate( dTheDate,VT_MESSAGE)
					lRefresh   := .f.
					lFirstPass := .f.
					loop
		     	endif

				do case
				case !empty(cProduct) .and. !empty(cProcess) .and. !nGrade==0
					if !ValidTest(V_PRODUCT, cProduct, VT_MESSAGE)
						lRefresh := .f.
						loop
					endif
					if !ValidTest(V_PROCESS_TYPE, cProcess, VT_MESSAGE)
						lRefresh := .f.
						loop
					endif
				case empty(cProduct) .and. empty(cProcess) .and. nGrade==0
					// Looks OK
					nEditStat := 0

				otherwise
					waitInfo({'Not consistant Product/Process/Grade'})
					lRefresh := .f.
					loop
				endcase

				for n := 1 to len(aContainer)
					Daily->(gsInContainer(n, aContainer[n,1] ))

					Daily->(gsOutContainer(n, aContainer[n,2] ))
				next

				Daily->number   := nGrower
				Daily->recptLtr := cRecptLtr
				Daily->recpt    := nRecpt
				Daily->date     := dTheDate
				Daily->time     := cTheTime
				Daily->number   := nGrower
				Daily->process  := cProcess
				Daily->product  := cProduct
				Daily->grade    := nGrade
				Daily->net      := nNet
				Daily->depot    := cDepot

				// Price Updater
				if !(str(Daily->theprice,10,2)==str(nThePrice,10,2))
					Daily->thePrice := nThePrice
					Daily->PriceSrc := PRICE_SRC_KEY
				endif

				aNewData := {}
				LoadUpData( aNewData )
				if DataChanged( aOrigData, aNewData )
					Daily->edited := date()
					Daily->(EditByFlds())
					if !(Daily->Day_Uniq == nLastDailyIDSaved )
						if nAddUniqueRec( UF_THE_DAYAUD_ID, UNIQ_FILE_WE_NEED_LOCKS )  > 0
							ReplOneRec('Daily', 'Daily_Audit')           //
							nLastDailyIDSaved := Daily->DAY_UNIQ
						endif
					endif
				endif

				Daily->(dbCommit())
				Daily->(dbRunLock())
				lFirstPass := .f.

				nEditStat := 0
				if lRefresh
					loop
				endif
			endcase
		endif

		nRec := Daily->(recno())

		lRefresh := .f.
		aRay := {'View'}
		do case
		case nAction == DAILY_EDIT_VIEW_ONLY
			aRay :=  ;
				{'View','RcptPrn','Info','X-eXit'}
		case nEdit == MAY_NOT_EDIT
			aRay :=  ;
				{'View','Finance','Next','Prev','RcptPrn','Spec/Info','X-eXit'}
		case nEdit == MAY_EDIT_PRICE .or. nEdit == MAY_EDIT_PRICE_AND_PROD
			aRay :=  ;
				{'Edit','Finance','Next','Prev','RcptPrn','Spec/Info','X-eXit'}
		case nEdit == MAY_EDIT_FULLY
			aRay :=  ;
				{'Edit','Delete',   'Next','Prev','RcptPrn','Info','X-eXit'}
		endcase

		nEditStat := VeryThinChoice( aRay )
		if nEditStat >= 1 .and. nEditStat <= len( aRay )
			c := substr( aRay[nEditStat], 1,1 )
		else
			c := ''
		endif

		do case
		case c == 'D'   // Delete
			if DeleTicket()
				exit
			endif
			nLastDailyIDSaved := AUDIT_THE_NEXT_SAVE    // basically if you try to delete, even you dont we want to know about any changes you make
		case c == 'F'
			ShowFinances()

		case c == 'I'
			ShowEditTheInfo( .t. )

		case c == 'N'   // nEditStat==3
		 	Daily->(dbSkip())
			lFirstPass := .f.
		 	if Daily->(eof()) .or. (nWho<>0 .and. Daily->number<>nWho)
		 		waitHand({'On last available record in this sort order'})
		 		Daily->(dbGoTo(nRec))
		 	endif

		case c == 'P'   // nEditStat==4
		 	Daily->(dbSkip(-1))
		 	if Daily->(bof())  .or. (nWho<>0 .and. Daily->number<>nWho)
		 		waitHand({'On first available Record in this sort order'})
		 		Daily->(dbGoTo(nRec))
		 	endif
			lFirstPass := .f.

		case c == 'R'    // nEditStat==5
			nChoice := bsgChoice( ;
			          {'You may print either a normal receipt or ALL INFO', ;
			           ' The ALL INFO receipt includes Non-Printing notes', ;
						  ' such as the Reason a ticket was edited at the scale', ;
						  ' and the NON-PRINTING Notes.'}, ;
						  {'Normal Receipt','ALL INFO','Cancel'} )

			do case
			case nChoice == 1
				Prn1Receipt( .f. )
			case nChoice == 2
				if Yesno({'Do you wish to print this form of theReceipt?', ;
				     '','This form shows ALL info including various', ;
					  'NON Printing Notes.'})
					  	Prn1Receipt( .t. )
				endif
			endcase
		case c == 'S'   // nEditStat==6
			if SpecialMenu()
				WaitInfo({'We have added transactions - you may need to edit!'})
				nReturn := SIG_EXIT
				exit
			endif
		case nEditStat==0 .or. nEditStat==7 .or. c=='X' .or. empty(c)
			exit
		endcase
		lFirstPass := .f.
	enddo

	rest_scr(aMsg)

	kill window aWin
return( nReturn )


static function FlashPrice( aWin )
	local aRay
	local n
	local lAdvance, lFinal
	local lPrice := .t.
	local lFound
	local cAdvChq := ' '
	local cFinChq := ' '
	local cChq
	local nRate := 0.00

	cFlashPriceErr := ''

	in window aWin @14, 2 winclear to 22,30

	if !(Daily->process==cProcess .and. Daily->product==cProduct .and. ;
			Daily->grade==nGrade .and. Daily->net==nNet)
		in window aWin @ 22,2 winsay 'Price may change on Save'
	endif

	if Daily->post_bat1==0 .and. Daily->post_bat2==0 .and. Daily->post_bat3==0
		lAdvance := .f.
	else
		lAdvance := .t.
	endif
	if Daily->fin_bat==0
		lFinal   := .f.
	else
		lFinal   := .t.
	endif

	if empty(cProduct) .and. empty(cProcess)
		in window aWin @14, 2 winsay 'Container Only'
		if lAdvance
			in window aWin @15, 2 winsay ' Posted as Advance'
		endif
		if lFinal
			in window aWin @16, 2 winsay ' Posted as Final'
		endif
		return( .t. )
	endif

	aRay := {}
	aRay := PostPaidArray( NIL )   // we grab this REGARDLESS

	if !lFinal .or. !lAdvance
		lPrice := FindPrice( cProduct, cProcess, dTheDate )
	endif

	if lAdvance
		in window aWin @ 14,02 winsay '1st Adv Rate: $'+ ;
			Transform( Daily->Adv_Pr1, '99.99' ) +'/'+ ;
				lower(sysValue(SYS_UNITS_OF_WEIGHT))

		lFound := .f.
		for n := 1 to len(aRay)
			if aRay[n,PAS_ACC_CHEQUE_FOUND] .and. ;
					aRay[n, PAS_ACC_TYPE]==TT_BERRY_ADVANCE_1

				lFound := .t.
				cAdvChq := aRay[n,PAS_ACC_SERIES] + ;
					str( aRay[n,PAS_ACC_CHEQUE_NO], FLD_CHEQUE)
				in window aWin @15,03 winsay 'Chq: '+aRay[n,PAS_ACC_SERIES]+ ;
					  '-'+padr(lstrim( aRay[n,PAS_ACC_CHEQUE_NO]),9) + ;
				     shMDY( aRay[n,PAS_ACC_CHEQUE_DATE] )
				in window aWin @16,03 winsay 'Amt: '+transform( ;
							 aRay[n,PAS_ACC_CHEQUE_AMT],'$9999999.99')
				exit
			endif
		next
		if !lFound
			if len( aRay ) == 0
				in window aWin @15,03 winsay 'POSTED but no Acct Rec-ERR'
			   cFlashPriceErr := 'Advance POSTED but no Account Rec-ERROR'
			else
	         in window aWin @15,03 winsay '-- No Cheque Yet --'
			endif
		endif
	else
		if lPrice
			in window aWin @14, 2 winsay ;
				'Price ID# ='+lStrim(Price->PriceID)+ ;
			   ' - '+shMDY(Price->from)
			in window aWin @15, 2 winsay 'Est. Advance= ' + ;
				transform( ;
				Daily->(TotAdvPrice()),'$99.99')+'/'+ ;
				lower(sysValue(SYS_UNITS_OF_WEIGHT))
			if str(Daily->(AdvancePrem(  )),12,3) <> str(0,12,3)
				in window aWin @16, 2 winsay 'Premium:' +transform( ;
					Daily->(AdvancePrem()),'$ 99.99')+'/'+ ;
					lower(sysValue(SYS_UNITS_OF_WEIGHT))
			endif
		else
			in window aWin @14, 2 winsay ;
				'No Advance Price Found'
		endif
	endif

	if lFinal
		in window aWin @ 17,02 winsay 'Final Rate:   $'+ ;
			Transform( Daily->Fin_Price, '99.99' ) +'/'+ ;
				lower(sysValue(SYS_UNITS_OF_WEIGHT))

		lFound := .f.

		nRate := 0.00
		for n := 1 to len(aRay)
			if aRay[n,PAS_ACC_CHEQUE_FOUND] .and. aRay[n,PAS_ACC_TYPE]==TT_FINAL_BERRY
				lFound := .t.
				cFinChq := aRay[n,PAS_ACC_SERIES] + ;
					str( aRay[n,PAS_ACC_CHEQUE_NO], FLD_CHEQUE)

				in window aWin @18,03 winsay 'Chq: '+aRay[n,PAS_ACC_SERIES]+ ;
					  '-'+padr(lstrim( aRay[n,PAS_ACC_CHEQUE_NO]),9) + ;
				     shMDY( aRay[n,PAS_ACC_CHEQUE_DATE] )
				in window aWin @19,03 winsay 'Amt: '+transform( ;
							 aRay[n,PAS_ACC_CHEQUE_AMT],'$9999999.99')
				nRate += aRay[ n, PAS_ACC_UNIT_PRICE ]
			else
				// Not a final pay
				if aRay[n,PAS_ACC_TYPE] == TT_BERRY_ADVANCE_1 .or. ;
					aRay[n,PAS_ACC_TYPE] == TT_BERRY_ADVANCE_2 .or. ;
					aRay[n,PAS_ACC_TYPE] == TT_BERRY_ADVANCE_3
					nRate += aRay[ n, PAS_ACC_UNIT_PRICE ]            // CrossChekc
				endif
			endif
		next

		do case
		case nRate + 0.01 < Daily->Fin_Price .and. lFound
			// WE PAID a FINAL PRICE & it is LESS than FINAL total
			//  This DOES NOT check out all possible errors!
	      in window aWin @ 17,02 + 15 + 5 + 1 + 2+1  winsay '<Err?>'
		case !lFound
			if len( aRay ) == 0
				in window aWin @15,03 winsay 'POSTED but no Acct Rec-ERR'
			   cFlashPriceErr := 'Final POSTED but no Account Rec-  !!!'
			else
	         in window aWin @18,03 winsay '-- No Cheque Yet --'
			endif
		endcase
	else
		if lPrice
			if lAdvance
				// if advance was paid we need to show the Price Estimate
				// info....
				if Daily->(fValidPrice())
					in window aWin @17, 2 winsay ;
					 'Price ID# ='+lStrim(Price->PriceID)+ ;
					 ' - '+shMDY(Price->from)
					in window aWin @18, 2 winsay 'Est. Final  = ' + ;
						transform( ;
						Daily->(FinalPrice()),'$99.99')+'/'+ ;
						lower(sysValue(SYS_UNITS_OF_WEIGHT))
					in window aWin @19, 3 winsay ' Final includes Adv'
				else
					in window aWin @17, 2 winsay ;
					 'Can not find currently'
					in window aWin @18, 2 winsay ;
					 'valid price'

					AppError( APP_ERR_PROBABLY_EDITED_PRICE_REC1, ;
					  {'Probably a new price record was set up or', ;
						'deleted or something like that...'})
				endif
			endif
		else
			in window aWin @17, 2 winsay ;
				'No Final Price Found'
		endif
	endif

	if len( aRay ) == 0
		if lAdvance .or. lFinal
			in window aWin @ 20,02 winsay 'ERROR-Incomplete Posting!'
			if !empty( cFlashPriceErr)
				cFlashPriceErr := 'ERROR-Incomplete Posting!'
			endif
		endif
	else
		for n := 1 to len(aRay)
			if aRay[n,PAS_ACC_CHEQUE_FOUND]
				cChq := aRay[n,PAS_ACC_SERIES] + ;
						str( aRay[n,PAS_ACC_CHEQUE_NO], FLD_CHEQUE)
				if !(cChq==cFinChq .or. cChq==cAdvChq)
					in window aWin @ 20,02 winsay 'More Payments '+cChq
					exit
				endif
			endif
		next
	endif

return( .t. )


static function LoadUpData( aRay )
	local n:= 1
	local x

	do while .t.
		// In May 2020, we ignore changes to the EDIT FIELDS

		if !( Daily->(FieldName( n )) == 'QED_DATE' .or. ;
		      Daily->(FieldName( n )) == 'QED_TIME' .or. ;
				Daily->(FieldName( n )) == 'QED_OP')

			x := Daily->(FieldGet( n ))

			if valType(x)=='U'
				exit
			else
				aadd( aRay, x )
			endif
		endif
		n++
	enddo

return( nil )

static function DataChanged( aRay1, aRay2 )
	local lReturn := .f.
	local n

	if len(aRay1) <> len(aRay2)
		appError( APP_ERR_ARRAY_GOOF , ;
		 {'Len: '+str(len(aRay1),10)+str(len(aRay2),10)} )
	endif

	for n := 1 to len( aRay1 )
		if !(aRay1[n] == aRay2[n])
			lReturn := .t.
			exit
		endif
	next

return( lReturn )

static Function ShowFinances()
	local aRay, aErr
	local aW
	local n, n1
	local lPrice := .f.
	local cTmp

	if Daily->imp_bat==0
		cTmp := 'Keyed in'
	else
		cTmp := 'Imp# '+lStrim( Daily->imp_bat )
	endif

	aRay := PostPaidArray( ) // date()+7 ) - Sep 2019 - I do NOT think the date should be passed in!
	aErr := {}

	create window at 1,03,21,76 title 'Financial Info for Receipt # '+ ;
	 lStrim(Daily->recpt) + '  '+cTmp to aW
	display window aW
	set cursor on
	in window aW @ 2, 2 winsay Grower->number
	in window aW @ 2,10 winsay Grower->name
	in window aW @ 2,60 winsay 'UniqueID: '+lstrim(Daily->day_uniq)
	in window aW @ 3,60 winsay 'Record #: '+lstrim(Daily->(recno()))

	if Daily->imp_bat==0
		in window aW @ 3,10 winsay 'May have been manually keyed in'
	else
		in window aW @ 3,10 winsay 'Imported in batch '+lStrim(Daily->imp_bat)
	endif

	in window aW @ 5,10 winsay '1st Advance'
	in window aW @ 5,30 winsay '2nd'
	in window aW @ 5,45 winsay '3rd'
	in window aW @ 5,65 winsay 'Final'

	in window aW @ 6,02 winsay 'Price'
	in window aW @ 7,02 winsay 'ID:'
	in window aW @ 8,02 winsay 'Batch'

	if Daily->(fValidPrice())
		lPrice := .t.
	endif

	// Jan 24, 2022 Now - if there is Posting Batch Number and a Price, then
	//  there should be an entry in the Account Table (which is summarized in
	//  aRay - the list of related A/P entries.
	//  If there is no entry in aRay, that seems to indicate an error.

	cTmp := ''
	if !empty( Daily->product) .and. Daily->post_Bat1 >= 1 .and. num3NotEqual0( Daily->adv_pr1 )
		// we have presumably posted this transaction - is there an entry in the Array that relates to this?
		cTmp := ' Err'
		for n:= 1 to len( aRay )
			if aRay[ n,  PAS_ACC_TYPE       ] == TT_BERRY_ADVANCE_1
				cTmp := ''
			endif
		next
	endif
   if !empty( cTmp )
   	aadd( aErr, 'Adv 1 - expect payment record, but none found' )
   endif

	do case
	case Daily->adv_prid1 == 0 .and. Daily->post_bat1<>0 .and. ;
		  Daily->net==0 .and. empty(Daily->product)
		in window aW @ 6,12 winsay str(Daily->adv_pr1,FLD_DOCUMENT,2)
		in window aW @ 7,12 winsay cTmp   // normally NOTHING
		in window aW @ 8,12 winsay str(Daily->post_bat1,FLD_DOCUMENT)
	case Daily->adv_prid1 <> 0
		in window aW @ 6,12 winsay str(Daily->adv_pr1,FLD_DOCUMENT,2)
		in window aW @ 7,12 winsay str(Daily->adv_prid1,FLD_DOCUMENT)+cTmp

		if Daily->adv_pr1    >= 0.01          .and. num2Equal0( Daily->post_bat1 ) .and.    ;
			 Daily->fin_price > Daily->adv_pr1 .and. Daily->fin_bat >= 1
			 // Data problem
			in window aW @ 8,12 winsay padc('Problem!',8)
		else
			in window aW @ 8,12 winsay str(Daily->post_bat1,FLD_DOCUMENT)
		endif
	case lPrice
		in window aW @ 6,12 winsay str( RunAdvPrice( 1 ),FLD_DOCUMENT,2)
		in window aW @ 7,12 winsay str(Price->priceID,FLD_DOCUMENT)+cTmp
		if Num2Equal0(Daily->post_bat1)
			in window aW @ 8,12 winsay padl('Not yet',FLD_DOCUMENT)
		else
			in window aW @ 8,12 winsay 'Pd: '+lStrim( Daily->post_bat1)
		endif
	case !Num2Equal0(Daily->post_bat1) .and. Daily->adv_prid == 0 .and. ;
			 num3NotEqual0(Daily->net )
		// Aug 2011 this indicates an Error I think
		in window aW @ 6,12 winsay str( RunAdvPrice( 1 ),FLD_DOCUMENT,2)
		in window aW @ 7,12 winsay 'ERROR '+cTmp
		in window aW @ 8,12 winsay APP_ERR_WEIRD_DATA_1
	otherwise
		in window aW @ 6,12 winsay padl('No Price',FLD_DOCUMENT)
		in window aW @ 7,12 winsay padl('found',FLD_DOCUMENT) + cTmp
	endcase

	cTmp := ''
	if !empty( Daily->product) .and. Daily->post_Bat2 >= 1 .and. num3NotEqual0( Daily->adv_pr2 )
		// we have presumably posted this transaction - is there an entry in the Array that relates to this?
		cTmp := ' Err'
		for n:= 1 to len( aRay )
			if aRay[ n,  PAS_ACC_TYPE       ] == TT_BERRY_ADVANCE_2
				cTmp := ''
			endif
		next
	endif
   if !empty( cTmp )
   	aadd( aErr, 'Adv 2 - expect payment record, but none found' )
   endif

	do case
	case Daily->adv_prid2 == 0 .and. Daily->post_bat2<>0 .and. ;
		  Daily->net==0 .and. empty(Daily->product)
		in window aW @ 6,25 winsay str(Daily->adv_pr3,FLD_DOCUMENT,2)
		in window aW @ 7,12 winsay cTmp   // normally NOTHING
		in window aW @ 8,25 winsay str(Daily->post_bat3,FLD_DOCUMENT)
	case Daily->adv_prid2 <> 0
		in window aW @ 6,25 winsay str(Daily->adv_pr2,FLD_DOCUMENT,2)
		in window aW @ 7,25 winsay str(Daily->adv_prid2,FLD_DOCUMENT)+ cTmp
		in window aW @ 8,25 winsay str(Daily->post_bat2,FLD_DOCUMENT)
	case lPrice
		in window aW @ 6,25 winsay str( RunAdvPrice( 2 ),FLD_DOCUMENT,2)
		in window aW @ 7,25 winsay str(Price->priceID,FLD_DOCUMENT)+ cTmp
		in window aW @ 8,25 winsay padl('Not yet',FLD_DOCUMENT)
	otherwise
		in window aW @ 6,25 winsay padl('No Price',FLD_DOCUMENT)
		in window aW @ 7,25 winsay padl('found',FLD_DOCUMENT)+cTmp
	endcase

	cTmp := ''
	if !empty( Daily->product) .and. Daily->post_Bat3 >= 1 .and. num3NotEqual0( Daily->adv_pr3 )
		// we have presumably posted this transaction - is there an entry in the Array that relates to this?
		cTmp := ' Err'
		for n:= 1 to len( aRay )
			if aRay[ n,  PAS_ACC_TYPE       ] == TT_BERRY_ADVANCE_3
				cTmp := ''
			endif
		next
	endif
   if !empty( cTmp )
   	aadd( aErr, 'Adv 3 - expect payment record, but none found' )
   endif

	do case
	case Daily->adv_prid3 == 0 .and. Daily->post_bat3<>0 .and. ;
		  Daily->net==0 .and. empty(Daily->product)
		in window aW @ 6,40 winsay str(Daily->adv_pr3,FLD_DOCUMENT, 2)
		in window aW @ 7,40 winsay padl(cTmp, FLD_DOCUMENT)
		in window aW @ 8,40 winsay str(Daily->post_bat3,FLD_DOCUMENT)
	case Daily->adv_prid3 <> 0
		in window aW @ 6,40 winsay str(Daily->adv_pr3,FLD_DOCUMENT, 2)
		in window aW @ 7,40 winsay str(Daily->adv_prid3,FLD_DOCUMENT)+cTmp
		in window aW @ 8,40 winsay str(Daily->post_bat3,FLD_DOCUMENT)
	case lPrice
		in window aW @ 6,40 winsay str( RUnAdvPrice( 3 ),FLD_DOCUMENT,2)
		in window aW @ 7,40 winsay str(Price->priceID,FLD_DOCUMENT) + cTmp
		in window aW @ 8,40 winsay padl('Not yet',FLD_DOCUMENT)
	otherwise
		in window aW @ 6,40 winsay padl('No Price',FLD_DOCUMENT)
		in window aW @ 7,40 winsay padl('found',FLD_DOCUMENT) + cTmp
	endcase

	cTmp := ''
	if !empty( Daily->product) .and. Daily->fin_Bat >= 1 .and. num3NotEqual0( Daily->fin_price ) .and. ;
      (Daily->fin_price - Daily->adv_pr1 - Daily->adv_pr2 - Daily->adv_pr3) > 0.00

		// we have presumably posted this transaction - is there an entry in the Array that relates to this?
		cTmp := ' Err'
		for n:= 1 to len( aRay )
			if aRay[ n,  PAS_ACC_TYPE       ] == TT_FINAL_BERRY
				cTmp := ''
			endif
		next
	endif
   if !empty( cTmp )
   	aadd( aErr, 'Final Pay - expect payment record, but none found' )
   endif

	do case
	case Daily->fin_pr_id <> 0
		in window aW @ 6,62 winsay str(Daily->fin_price,FLD_DOCUMENT,2)
		in window aW @ 7,62 winsay str(Daily->fin_pr_id,FLD_DOCUMENT) + cTmp
		in window aW @ 8,62 winsay str(Daily->fin_bat,FLD_DOCUMENT)
	case lPrice
		in window aW @ 6,62 winsay str( FinalPrice( 3 ),FLD_DOCUMENT,2)
		in window aW @ 7,62 winsay str(Price->priceID,FLD_DOCUMENT)  + cTmp
		in window aW @ 8,62 winsay padl('Not yet',FLD_DOCUMENT)
	otherwise
		in window aW @ 6,62 winsay padl('No Price',FLD_DOCUMENT)
		in window aW @ 7,62 winsay padl('found',FLD_DOCUMENT) + cTmp
	endcase

	if len( aRay ) == 0
		in window aW @ 5, 10 winsay 'No Payments or Accounting Records'
		in window aW @ 6, 10 winsay 'are associated with this receipt.'
	else
		// unlikely to be more than 7 lines:
		for n := 1 to len( aRay )
			in window aW @ (2*n)+8, 2 winsay '>'+;
			  NameOf(LU_SHORT_TRANSACTION_TYPE, aRay[n,  PAS_ACC_TYPE ])

			in window aW @ (2*n)+8,16 winsay  aRay[n,  PAS_ACC_CLASS ]

			in window aW @ (2*n)+8,26 winsay  shMDY( aRay[n,  PAS_ACC_DATE  ] )

			if aRay[ n, PAS_ACC_CHEQUE_FOUND]
				in window aW @ (2*n)+8,40 winsay  'Chq: ' + ;
				 aRay[n , PAS_ACC_SERIES   ] +'-'+ ;
				 lStrim(aRay[n , PAS_ACC_CHEQUE_NO  ])

				in window aW @ (2*n)+8,55 winsay  'Issued: '+ ;
				 shMDY(aRay[n , PAS_ACC_CHEQUE_DATE ])

				if str(aRay[n ,PAS_ACC_UNIT_PRICE],11,2) <> str(0,11,2)
					in window aW @ (2*n)+9,30 winsay 'Price: '+ ;
					 str( aRay[n ,PAS_ACC_UNIT_PRICE],9,3)+'/lb'
				endif

				in window aW @ (2*n)+9,56 winsay  'Tot $'+ ;
					transform(aRay[n , PAS_ACC_CHEQUE_AMT ],'9,999,999.99')
			else
				in window aW @ (2*n)+8,40 winsay  'Not Paid Out Yet'
			endif
		next

      n1 := n  // the next row
      for n := 1 to len( aErr )
			in window aW @ (2*n1)+8,16 winsay  aErr[n ]
         n1++
         if n1 > 5
         	exit
         endif
      next
	endif

	if !empty( cFlashPriceErr )
		PostErrMsg( )
	endif
	thinWait('')

	kill window aW

return( nil )

static function ShowEditTheInfo( lAllowEdit )
	local aW
	local getList := {}
	local bF1

	default lAllowEdit to .t.

	create window at 2,3,23,75 title 'Info on Receipt #' + ;
						  Daily->depot +'-'+ lStrim(Daily->recpt) + alltrim( Daily->RECPTLTR)  to aW

	WinGetSet( aW, WIN_HAS_SHADOW, .f. )    // too Big for Shadow now, May 2020
	display window aW
	set cursor on
	in window aW @ 1,40 winsay cFlashPriceErr

	in window aW @ 2,  2 winsay   ' Date Added: '+shMDY(Daily->ADD_DATE)
	in window aW @ 3,  2 winsay   '   Added by: '+ Daily->add_by

	in window aW @ 2, 38 winsay   ' Import/Add: '+shMDY(Daily->QADD_DATE)
	in window aW @ 3, 38 winsay   '         by: '+ Daily->QADD_OP
	in window aW @ 4, 38 winsay   '         at: '+ Daily->QADD_TIME

	if num2NotEqual0( Daily->UNIQ_IMBAT )
		if ValidTest( V_IMPORT_SESSION , Daily->UNIQ_IMBAT, VT_NO_MESSAGE )
			in window aW @ 2, 65 winsay  padc('Import' , FLD_DOCUMENT)
			in window aW @ 3, 65 winsay  padc('session', FLD_DOCUMENT)
			in window aW @ 4, 65 winsay  padc(  var2char(Daily->UNIQ_IMBAT), FLD_DOCUMENT)
		endif
	endif

	if year( Daily->edit_date) < 1900 .and. empty(Daily->edit_by) ;
			.and. empty(Daily->edit_reas)
		in window aW @ 5, 2 winsay 'Probably not edited after it'
		in window aW @ 6, 2 winsay 'was input at the Scale...'
	else
		in window aW @ 5, 2 winsay 'Scale Edit:  ' + shMDY(Daily->edit_date)
		in window aW @ 6, 2 winsay '         by: ' + Daily->edit_by
		in window aW @ 7, 2 winsay 'Reason: '+left( Daily->edit_reas,20)
	endif

	if empty( Daily->Qed_date) .and. empty( Daily->Qed_op )
	   in window aW @ 5,38 winsay 'Probably not edited'
	   in window aW @ 6,38 winsay 'by office staff.'
	else
	   in window aW @ 5,38 winsay 'Office Edit: '+shMDY(Daily->Qed_date)
	   in window aW @ 6,38 winsay 'was done by: '+ Daily->Qed_op
	   in window aW @ 7,38 winsay '         at: '+Daily->Qed_time
	endif

	in window aW @ 9, 2 winsay 'Dock Pct: '+str( Daily->dock_pct, 4)+'%'

	do case
	case Num2Equal0(Daily->ori_net) .and. Num2Equal0( Daily->net )
		if empty( Daily->product )
			in window aW @ 9,38 winsay 'Container only ticket'
		else
	   	in window aW @ 9,38 winsay 'No product received'
		endif

	case str(Daily->ori_net,8,1)<>str(0,8,1)
		if str(Daily->ori_net,8,1)==str(Daily->net,8,1)
		   in window aW @ 9,38 winsay 'Original net: '+ str( Daily->ori_net,7)+' (unchanged)'
		else
	      in window aW @ 9,38 winsay 'Original net: '+ str( Daily->ori_net,7)+'  Changed!  '
		endif

	case Daily->dock_pct > 0 .or. Num2NotEqual0(Daily->net)
		in window aW @ 9,38 winsay 'Original Net Not Known'
	endcase

	if Daily->isVoid
		in window aW @ 10, 2 winsay '*** Voided Ticket ***'
	else
		in window aW @ 10, 2 winsay 'Normal ticket        '
	endif

	if Daily->imp_bat==0
		in window aW @ 10,38 winsay 'Created in Office   '
	else
		in window aW @ 10,38 winsay 'Import Batch: '+ Daily->Depot+'-'+lStrim(Daily->imp_bat)
	endif

	if Num2Equal0(Daily->post_bat1 )
		in window aW @ 11, 5 winsay 'No 1st Adv'
	else
		in window aW @ 11, 5 winsay '1st Adv '+lStrim(Daily->post_bat1)
	endif

	if Num2Equal0(Daily->post_bat2 )
		in window aW @ 11, 20 winsay 'No 2nd Adv'
	else
		in window aW @ 11, 20 winsay '2nd Adv '+lStrim(Daily->post_bat2)
	endif

	if Num2Equal0(Daily->post_bat3 )
		in window aW @ 11, 35 winsay 'No 3rd Adv'
	else
		in window aW @ 11, 35 winsay '3rd Adv '+lStrim(Daily->post_bat3)
	endif

	if Num2Equal0(Daily->fin_bat )
		in window aW @ 11, 50 winsay 'No Final'
	else
		in window aW @ 11, 50 winsay 'Final '+lStrim(Daily->fin_bat)
	endif

	if !Num2Equal0(Daily->adv_prid1 )
		in window aW @ 12, 5 winsay 'ID: '+lStrim(Daily->adv_prid1)
	endif

	if !Num2Equal0(Daily->adv_prid2 )
		in window aW @ 12, 20 winsay 'ID: '+lStrim(Daily->adv_prid2)
	endif

	if !Num2Equal0(Daily->adv_prid3 )
		in window aW @ 12, 35 winsay 'ID: '+lStrim(Daily->adv_prid3)
	endif

	if !Num2Equal0(Daily->fin_pr_id )
		in window aW @ 12, 50 winsay 'ID: '+lStrim(Daily->fin_pr_id)
	endif

	if !Num3Equal0(Daily->adv_pr1 )
		in window aW @ 13, 5 winsay '$ '+Str(Daily->adv_pr1,7,2)
	endif

	if !Num3Equal0(Daily->adv_pr2 )
		in window aW @ 13, 20 winsay '$ '+Str(Daily->adv_pr1,7,2)
	endif

	if !Num3Equal0(Daily->adv_prid3 )
		in window aW @ 13, 35 winsay '$ '+Str(Daily->adv_pr3,7,2)
	endif

	if !Num3Equal0(Daily->fin_price )
		in window aW @ 13, 50 winsay '$: '+Str(Daily->fin_price,8,2)
	endif

	if Daily->imp_bat > 0
		if alltrim( Daily->product)==alltrim( Daily->LONG_PROD ) .and. ;
	      alltrim( Daily->process)==alltrim( Daily->LONG_PROC )

			in window aW @ 15, 02 winsay 'Product/Process on file same as import'
		else
	      if empty( Daily->Long_prod ) .and. empty( Daily->Long_Proc )
				in window aW @ 15, 02 winsay 'No Product/Process in Import!'
			else
				in window aW @ 15, 02 winsay 'Product/Process as imported=' + ;
		               Daily->Long_prod+' / '+Daily->Long_Proc
	      endif
		endif
	else
		in window aW @ 15, 02 winsay 'Ticket probably input by office!'
	endif

	bF1 := setkey( K_F1,  ;
	 {|| ReceiptVarietyHelp( sysValue(SYS_DEFAULT_VARIETY) )  })

	if !empty( cFlashPriceErr )
	   PostErrMsg( )
	endif

	if empty(Daily->cont_errs)
		in window aW @ 21,02 winsay space( 40 )
	else
		in window aW @ 21,02 winsay "Container Import Errs: "+Daily->cont_errs
	endif

	if Daily->(recLock())
		PutName(aW,20,30,LU_VARIETY,Daily->variety)

		in window aW @ 17, 02 winsay 'Certified:' winget Daily->certified ;
		  get_message 'Certification info (can be from Receipt)'

		if empty( Sysvalue( SYS_IMPORT_FROM_FIELD_NAME )) .and. empty( Daily->from_field )
			in window aW @ 17,38 Winsay 'From Grower Field data not in use'
		else
			in window aW @ 17,38 Winsay Sysvalue( SYS_IMPORT_FROM_FIELD_NAME ) winget Daily->from_field ;
			 get_message 'Enter the Grower Field Name that this load came from'
		endif

		in window aW @ 18,02 Winsay 'N.P. Note:' winGet Daily->np_note1 ;
		get_message 'Non-Printing Note'

		in window aW @ 19,02 Winsay 'Prn Note: ' winGet Daily->pr_note1 ;
		get_message 'This note Prints on New Format Statement !'

		in window aW @ 20,02 winsay 'Variety:  ' winget Daily->variety ;
		 valid PutName(aW,20,30,LU_VARIETY,Daily->variety) ;
		 Lookup( LU_VARIETY, 'F5=Browse, Enter variety for reporting or leave blank, F1=Help')

		if lAllowEdit
			read
			if updated()
				Daily->(EditByFlds())                            // we do NOT really care about these edits, so we do NOT audit them

				if !(Daily->Day_Uniq == nLastDailyIDSaved )
					if nAddUniqueRec( UF_THE_DAYAUD_ID, UNIQ_FILE_WE_NEED_LOCKS )  > 0  // Table is NOT locked
						ReplOneRec('Daily', 'Daily_Audit')           //
						nLastDailyIDSaved := Daily->DAY_UNIQ
					endif
				endif
			endif
		else
			clear gets
			thinwait('Viewing Info ')
		endif

		Daily->(dbRunLock())
		Daily->(dbCommit())
	else
		if empty( Sysvalue( SYS_IMPORT_FROM_FIELD_NAME )) .and. empty( Daily->from_field )
			in window aW @ 17,02 Winsay 'From Grower Field data not in use'
		else
			in window aW @ 17,02 Winsay Sysvalue( SYS_IMPORT_FROM_FIELD_NAME ) + ' '+ Daily->from_field
		endif

		in window aW @ 18,02 Winsay 'N.P. Note: '+ Daily->np_note1
		in window aW @ 19,02 Winsay 'Prn Note:  '+ Daily->pr_note1
		in window aW @ 20,02 winsay 'Variety:   ' + Daily->variety + ;
		 ' '+NameOf( LU_VARIETY, Daily->variety )
		thinWait('Viewing Info...')
	endif

	kill window aW
	setKey( K_F1, bF1 )
return( nil )


static function SpecialMenu()
	local nChoice
	local lReturn := .f.    // if TRUE, then added record

	if Daily->post_bat1 > 0 .or. Daily->fin_bat > 0 .or. ;
		Daily->post_bat2 > 0

		nChoice := bsgChoice({'You may select the following:','', ;
									 'C - reverse & copy this transaction', ;
									 '    you should then EDIT the copy!', ;
									 'R - Reverse this entry, but do not', ;
									 '    make an additional copy', ;
									 'I - show Info about this transation', ;
									 '    Allows you to Edit PRINTING & NON-PRINTING', ;
									 '    notes on this transaction.', ;
									 'X - eXit this screen'}, ;
						 {'Copy & Rev','Reverse only','Info','X-eXit'})
		do case
		case nChoice == 1
			if Yesno({'Do you want to create a REVERSING transaction', ;
						 'and a correcting transaction.  The system will', ;
						 'allow you to edit the correcting transaction.', ;
						 'This creates two transactions which the', ;
						 'system can process on the next payment run.'})
				MakeReverse('R')
				MakeReverse('A')
				lReturn := .t.
			endif

		case nChoice == 2
			if Yesno({'Do you want to create a REVERSING transaction?', ;
						 'This creates a negative transaction which the', ;
						 'system can process on the next payment run.  If', ;
						 'you need to make a correcting entry - you must', ;
						 'make it later.'} )
				MakeReverse('R')
				lReturn := .t.
			endif

		case nChoice == 3
			ShowEditTheInfo( .t. )  // allow Edit
		endcase
	else
		ShowEditTheInfo( .t. )
	endif

return( lReturn )


static function MakeReverse( cLetter )
	local  lReturn := .f.
	local  aRay := {}
	local  n, n1
	local  c

	n1 := Daily->(fCount())

	for n := 1 to n1
		aadd( aRay, Daily->(FieldGet( n ))  )
	next

	Daily->(dbUnlock())

	if Daily->(fileLock()) .and. CounterID->(fileLock()) .and. Daily_Audit->(fileLock())

		nLastDailyIDSaved := AUDIT_THE_NEXT_SAVE                            // we are doing reverses, want to audit this thoroughly
		nAddUniqueRec( UF_THE_DAY_UNIQ, UNIQ_FILE_DO_NOT_NEED_LOCKS )

		Daily->recptltr  := cLetter
		Daily->add_date  := date()

		if cLetter=='R'
			Daily->edit_reas := 'Reverse!'
		endif
		Daily->(dbCommit())

		for n := 1 to len( aRay )
			c := Daily->(FieldName( n ))

			do case
			case c =='NET' .or. c=='GROSS' .or. c=='TARE'
				Daily->(fieldPut(n, -aRay[n]) )
			case substr(c,1,2)=='IN' .and. substr(c,3,1)>='1' .and. ;
				  substr(c,3,1)<='9'
				// Reverse INs
				Daily->(fieldPut( n, -aRay[n] ))
			case substr(c,1,3)=='OUT' .and. substr(c,4,1)>='1' .and. ;
				  substr(c,4,1)<='9'
				// Reverse OUTs
				Daily->(fieldPut( n, -aRay[n] ))
			case c=='DATE'   .or. c=='THEPRICE' .or. c=='PRICESRC' .or. ;
				c=='DOCK_PCT' .or. c=='DEPOT'    .or. c=='PRODUCT' .or. ;
				c=='NUMBER'   .or. c=='GRADE'    .or. c=='PROCESS' .or. ;
				c=='RECPT'    .or. c=='TIME'

				Daily->(fieldPut( n, aRay[n]))
			endcase
		next

		Daily->(dbCommit())

		nAddUniqueRec( UF_THE_DAYAUD_ID, UNIQ_FILE_DO_NOT_NEED_LOCKS )
		ReplOneRec('Daily', 'Daily_Audit')           //
		Daily->(dbRunLock())
		nLastDailyIDSaved := Daily->DAY_UNIQ

		if cLetter=='R'
			LogAnEvent( EVT_TYPE_REVERSE_TICKET , { ;
			 'Create Reversing Entry for ' + Daily->depot + '-'+ var2char( Daily->recpt)+cLetter, ;
			 'Daily Reciept Unique ID='+ var2char( Daily->DAY_UNIQ ) })

			WaitInfo({'We have reversed the transaction '+Daily->depot+'-'+lStrim( Daily->recpt)+cLetter })
		else
			LogAnEvent( EVT_TYPE_REVERSE_TICKET , { ;
			 'Create Correcting Entry for Reverse ' + Daily->depot + '-'+ var2char( Daily->recpt)+cLetter, ;
			 'Daily Reciept Unique ID='+ var2char( Daily->DAY_UNIQ ) })

			WaitInfo({'We have created a NEW transaction to FIX', ;
				'Remember to FIX this transaction !!', ;
				'It is Receipt '+Daily->depot+'-'+lStrim( Daily->recpt)+cLetter })
		endif
	endif

return( lReturn )


///<summary>ONLY called if there seems to be an Error</summary>
static function PostErrMsg( )
	local aMsg
	local aRay
	local n
	local lFound := .f.

	aRay := {}
	aRay := PostPaidArray( NIL )   // we grab this REGARDLESS

	aMsg := {'Potential Error with Posting Found', ;
				'It seems like a payment posting may not have been fully processed!', ;
				'*** this is potentially VERY serious ***', ;
					 cFlashPriceErr,'' }

	aadd( aMsg, '*** You may need to phone support to interpret these ***')

	aadd( aMsg, 'Advance 1 status from Receipt:' )
	aadd( aMsg, ' Price = $'+ str( Daily->adv_pr1,   7,2 )+',  Batch='+str( Daily->post_bat1,7)+', PriceID='+str( Daily->adv_prID1,7) )

	lFound := .f.
	for n := 1 to len( aRay )
		if aRay[n,  PAS_ACC_TYPE       ] == TT_BERRY_ADVANCE_1
			lFound := .t.
			exit
		endif
	next

	do case
	case lFound
		aadd( aMsg, ' Account Record Found - this is expected')
	case !empty( Daily->post_bat1 )
		aadd( aMsg, ' PROBLEM - Posting Batch filled in but no Account Record found')
		aadd( aMsg, ' *** this may mean the Grower will be UNDER PAID ***' )
	endcase

	aadd( aMsg, 'Advance 2 status from Receipt:' )
	aadd( aMsg, ' Price = $'+ str( Daily->adv_pr2,   7,2 )+',  Batch='+str( Daily->post_bat2,7)+', PriceID='+str( Daily->adv_prID2,7) )

	lFound := .f.
	for n := 1 to len( aRay )
		if aRay[n,  PAS_ACC_TYPE       ] == TT_BERRY_ADVANCE_2
			lFound := .t.
			exit
		endif
	next

	do case
	case lFound
		aadd( aMsg, ' Account Record Found - this is expected')
	case !empty( Daily->post_bat2 )
		aadd( aMsg, ' PROBLEM - Posting Batch filled in but no Account Record found')
		aadd( aMsg, ' *** this may mean the Grower will be UNDER PAID ***' )
	endcase

	aadd( aMsg, 'Advance 3 status from Receipt:' )
	aadd( aMsg, ' Price = $'+ str( Daily->adv_pr3,   7,2 )+',  Batch='+str( Daily->post_bat3,7)+', PriceID='+str( Daily->adv_prID3,7) )

	lFound := .f.
	for n := 1 to len( aRay )
		if aRay[n,  PAS_ACC_TYPE       ] == TT_BERRY_ADVANCE_3
			lFound := .t.
			exit
		endif
	next

	do case
	case lFound
		aadd( aMsg, ' Account Record Found - this is expected')
	case !empty( Daily->post_bat3 )
		aadd( aMsg, ' PROBLEM - Posting Batch filled in but no Account Record found')
		aadd( aMsg, ' *** this may mean the Grower will be UNDER PAID ***' )
	endcase

	aadd( aMsg, 'Final Price status from Receipt:' )
	aadd( aMsg, ' Price = $'+ str( Daily->fin_price, 7,2 )+',  Batch='+str( Daily->fin_bat  ,7)+', PriceID='+str( Daily->fin_pr_ID,7) )
	lFound := .f.
	for n := 1 to len( aRay )
		if aRay[n,  PAS_ACC_TYPE       ] == TT_FINAL_BERRY
			lFound := .t.
			exit
		endif
	next

	do case
	case lFound
		aadd( aMsg, ' Account Record Found - this is expected')
	case !empty( Daily->fin_bat )
		aadd( aMsg, ' PROBLEM - Posting Batch filled in but no Account Record found')
		aadd( aMsg, ' *** this may mean the Grower will be UNDER PAID ***'  )
	endcase

	waitInfo( aMsg )

return( nil )
