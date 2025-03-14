// Cheq_reg.prg
// June 27, 1994
// Bill Hepler
// (c) 1994,  Crafted Industrial Software Ltd. and Bill Hepler
//   Feb 1995 - we now allow a Cheque Register Sorted by Grower.
//   Oct 1999 - minor improvements
//   Jun 2007 - get rid of Report Form
//   Jun 2010 - Alaska
//   Jul 2014 - GST Related
//   Aug 2022 - Show Dates better

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
#include 'rpt.ch'


static dTo, dFrom, dStatement, dDate
static nGrower, lProof, cSeries, nCheque
static cHeading
static nLine,nPage
static lByGrower
static nRadio
static aWin

static lVoidsOnly := .f.


function ChequeRegister()
	local nTmpGrow
	local aRadio
   local aRpt

	if !openfile({'Grower','Account','Cheque','BankRec','VoidChq','AudAcct'}, ;
	  DB_SHARED)
		close databases
		return( nil )
	endif

	BankRec->(dbGoBottom())
	dStatement := BankRec->acctDate

	lVoidsOnly := .f.
	dFrom   := sysValue( SYS_CURRENT_SEASON_START )
	dTo     := sysValue( SYS_CURRENT_SEASON_END )
	dDate   := date()
	lProof  := .f.
	nGrower := 0
	cSeries := space(FLD_SERIES)
	nCheque := 0
	lByGrower := .f.
	nRadio  := 1

	create radiobox 6,24 using  { ;
		'Listing of Cheques by Date', ;
		'Batches of Cleared Cheques', ;
		'Uncleared Cheques         ', ;
		'Void/Cancelled Cheques    '   } ;
		 frame title 'Type of Register' to aRadio

	myBsgScreen( 'Cheque Registers' )

	create window at 4,07,20,72 title 'Cheque Registers' to aWin
	display window aWin
	set cursor on

	do while .t.
		msgLine('[Esc] to Exit')

		RadioShow(aRadio,nRadio)
		GetTheStuff( .f. )

		msgLine('Select the Type of Register to Print')
		nRadio := RadioDo(aRadio, nRadio)
		if nRadio > 0
			GetTheStuff( .t. )
			if lastkey()==K_ESC .or. lastkey()==K_UP .or. lastkey()==K_PGUP
				loop
			endif
		else
			exit   // we hit ESC
		endif

		if selectPrn('REGI.TXT')
         Cheque->(dbClearFilter())   // make sure its Cleared

         Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
			Cheque->(dbSetRelation( 'Grower',{|| str(Cheque->number,FLD_NUMBER)}, ;
			 'str(Cheque->number,FLD_NUMBER)'))
			do case
			case nRadio == 4
            Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
				Cheque->(dbClearRelation())

				VoidChq->(dbSetRelation( 'Grower', ;
					{|| str(VoidChq->number,FLD_NUMBER)}, ;
				 'str(VoidChq->number,'+lstrim(FLD_NUMBER)+')' ))

            VoidChq->(OrdSetFocus( VOIDCHQ_DATE_ORD))
				VoidChq->(dbSeek( dtos( dFrom ), SOFTSEEK))

				cHeading := shMDY(dFrom)+' - '+shMDY(dTo) + ' Void Cheques'

            dbSelectAR('VoidChq')
            aRpt := {}
            bhRegiSetup( aRpt, .t. )

            gRptInitHead()
            gRptGetSetHead( RPT_HEAD_TITLE, { cHeading } )
            gRptGetSetHead( RPT_HEAD_WHILE_CONDITION, ;
              {|| dTo >= VoidChq->date } )

				PRINT_ON RPT_OVERWRITE

				gRptPrintSize( aRpt )

            VoidChq->(gRptPrinter( aRpt ))
				PrinterCtrl( PRN_CTRL_10_CPI )

            PRINT_OFF  RPT_COMPLETE_EJECT

			case nRadio == 3
				dbSelectAR('Cheque')
            Cheque->(OrdSetFocus(CHEQUE_RECONCILE_ORD))
				Cheque->(dbGoTop())

            aRpt := {}
            bhRegiSetup( aRpt, .f. )

            cHeading := 'Uncleared Cheques on or before '+ shMDY(dDate)
            gRptInitHead()
            gRptGetSetHead( RPT_HEAD_TITLE, { cHeading } )
            gRptGetSetHead( RPT_HEAD_FOR_CONDITION, {|| !Cheque->isCleared } )

            // SEEMS REDUNDANT !
            // gRptGetSetHead( RPT_HEAD_WHILE_CONDITION, ;
            // {|| empty(Cheque->dateClear) } )


				PRINT_ON RPT_OVERWRITE
				gRptPrintSize( aRpt )

            Cheque->(gRptPrinter( aRpt ))

            PRINT_OFF  RPT_COMPLETE_EJECT

			case nRadio == 2
            Cheque->(OrdSetFocus(CHEQUE_RECONCILE_ORD))
				if Cheque->(dbSeek(dtos(dStatement),HARDSEEK))
					cHeading := 'Bank Reconciliation for '+shMDY(dStatement)

               select Cheque
               aRpt := {}
               bhRegiSetup( aRpt, .f. )

               gRptInitHead()
               gRptGetSetHead( RPT_HEAD_TITLE, { cHeading } )
               gRptGetSetHead( RPT_HEAD_WHILE_CONDITION, ;
                {|| Cheque->dateClear == dStatement } )

               PRINT_ON RPT_OVERWRITE
					gRptPrintSize( aRpt )

               Cheque->(gRptPrinter( aRpt ))

               PRINT_OFF  RPT_COMPLETE_EJECT
				else
					waitInfo({'No bank rec done for this date'})
				endif

         case !empty(nCheque)
				cHeading := 'Cheque # '+cSeries+'-'+strZero(nCheque,FLD_CHEQUE)
            Cheque->(OrdSetFocus(CHEQUE_CHEQUE_NO_ORD))
				if Cheque->(dbSeek(cSeries + str(nCheque, FLD_CHEQUE),HARDSEEK))
					PRINT_ON RPT_OVERWRITE
					if lProof
               	// Apr 2021 - fix this line
						ProofPrinter( ;
						  {|| Cheque->series <= cSeries .and. Cheque->cheque == nCheque }, ;
						  {|| .t. } )
					else
						select Cheque
                  aRpt := {}
                  bhRegiSetup( aRpt, .f. )

                  gRptInitHead()
                  gRptGetSetHead( RPT_HEAD_TITLE, { cHeading } )
                  gRptGetSetHead( RPT_HEAD_WHILE_CONDITION, ;
                   {|| Cheque->series == cSeries } )

						gRptPrintSize( aRpt )
                  Cheque->(gRptPrinter( aRpt ))
               endif
					PRINT_OFF  RPT_COMPLETE_EJECT

				else
					waitInfo({'Cheque is not on file'})
				endif

         case !empty(nGrower)
				cHeading := lstrim(nGrower)+', '+alltrim(NameOf(LU_GROWER,nGrower))+ ;
				 ' '+shMDY(dFrom)+'-'+shMDY(dTo)
            Cheque->(OrdSetFocus(CHEQUE_GROWER_ORD))
				if Cheque->(dbSeek( str(nGrower,FLD_GROWER), HARDSEEK))
					PRINT_ON RPT_OVERWRITE
					if lProof
						ProofPrinter( {||Cheque->number== nGrower }, ;
						 {|| dTo >= Cheque->date .and. dFrom <= Cheque->date })
					else
						select Cheque

                  aRpt := {}
                  bhRegiSetup( aRpt, .f. )

                  gRptInitHead()
                  gRptGetSetHead( RPT_HEAD_TITLE, { cHeading } )
                  gRptGetSetHead( RPT_HEAD_WHILE_CONDITION, ;
                   {|| Cheque->number == nGrower } )
                  gRptGetSetHead( RPT_HEAD_FOR_CONDITION, ;
                   {|| dTo >= Cheque->date .and. dFrom <= Cheque->date } )

						gRptPrintSize( aRpt )
                  Cheque->(gRptPrinter( aRpt ))
               endif
					PRINT_OFF  RPT_COMPLETE_EJECT
				else
					waitInfo({'No Cheques on File for this Grower'})
				endif
         otherwise
            cHeading := shMDY(dFrom)+' - '+shMDY(dTo)

            if lVoidsOnly
               cHeading += ' Void Cheques'
            endif

				if lByGrower .and. Cheque->date <= dTo
	            Cheque->(OrdSetFocus(CHEQUE_DATE_GROWER_ORD))
				else
	            Cheque->(OrdSetFocus(CHEQUE_DATE_ORD))
				endif
				Cheque->(dbSeek( dtos(dFrom), SOFTSEEK ))

					//	dbSelectAR("Cheque")
					//	index on str(Cheque->number,FLD_GROWER) + dtos(Cheque->date) to ;
					//	 TmpCheq while Cheque->date <= dTo
					//	goto top


				if Cheque->date <= dTo
					PRINT_ON RPT_OVERWRITE
					do case
					case lProof
						if lByGrower
							do while !Cheque->(eof()) .and. Cheque->date <= dTo
								nTmpGrow := Cheque->number
								ProofPrinter({||Cheque->number <= nTmpGrow}, {|| .t. })
							enddo
						else
							ProofPrinter({||Cheque->date <= dTo}, {|| .t. })
						endif

					case lByGrower
                  Account->(OrdSetFocus( ACCOUNT_NUMBER_ORD ))
						Cheque->(dbSetRelation( 'Grower', ;
						 {|| str(Cheque->number,FLD_NUMBER)}, ;
						 'str(Cheque->number,FLD_NUMBER)'))
                  Cheque->(dbSetFilter( ;
                   {|| dTo >= Cheque->date .and. dFrom <= Cheque->date } ))
                  Cheque->(dbGoTop())

                  aRpt := {}
                  if lVoidsOnly
                     bhRegiSetup( aRpt, .t. )
                  else
                     bhRegiSetup( aRpt, .f. )
                  endif

                  gRptInitHead()
                  gRptGetSetHead( RPT_HEAD_TITLE, { cHeading } )

                  if lVoidsOnly
                     gRptGetSetHead( RPT_HEAD_FOR_CONDITION, ;
                      {|| Cheque->void  })
                  endif

						gRptPrintSize( aRpt )
                  Cheque->(gRptPrinter( aRpt ))
                  Cheque->(dbClearFilter())

					otherwise
						select Cheque
                  aRpt := {}
                  if lVoidsOnly
                     bhRegiSetup( aRpt, .t. )
                  else
                     bhRegiSetup( aRpt, .f. )
                  endif
                  Cheque->(dbSetFilter( ;
                   {|| dTo >= Cheque->date .and. dFrom <= Cheque->date } ))
                  Cheque->(dbGoTop())

                  gRptInitHead()
                  gRptGetSetHead( RPT_HEAD_TITLE, { cHeading } )

                  if lVoidsOnly
                     gRptGetSetHead( RPT_HEAD_FOR_CONDITION, {|| Cheque->void } )
                  endif

						gRptPrintSize( aRpt )

                  Cheque->(gRptPrinter( aRpt ))
                  Cheque->(dbClearFilter())
               endcase
					PRINT_OFF  RPT_COMPLETE_EJECT
				else
					waitInfo({'No Cheques on File for these Dates'})
				endif
			endcase

		endif
		lVoidsOnly := .f.
	enddo
	kill window aWin
	close databases
return( nil )

static function ProofPrinter( bWhile, bFor )
	local nCheqTot, nCheques, lOk := .t.
	local nNonVoidTot, nNonVoidCheques

 	PrinterCtrl(PRN_CTRL_17_CPI)
	nCheqTot := nNonVoidTot := 0.00
	nCheques := nNonVoidCheques := 0
	nPage := 1
	RepHead()
	do while eval(bWhile) .and. !Cheque->(eof())
		if eval(bFor)
			nCheqTot += Cheque->amount
			nCheques ++
			if !Cheque->void
				nNonVoidTot     += Cheque->amount
				nNonVoidCheques ++
			endif
			CheqPrinter()
			if !Detail1Cheq()    // Print Details and see if there are errors.
				lOk := .f.
			endif
		endif
		Cheque->(dbSkip())
	enddo
	nLine +=2
	PrnAtSay( nLine,01, 'TOTAL' )
	PrnAtSay( nLine,20, lStrim(nNonVoidCheques)+' printed' )
	PrnAtSay( nLine,117,nNonVoidTot, '99,999,999.99')
	nLine ++
	if nCheques - nNonVoidCheques > 0
		PrnAtSay( nLine,01,' including voids')
		PrnAtSay( nLine,20, lStrim(nCheques)+' printed')
		PrnAtSay( nLine,117, nCheqTot, '99,999,999.99')
	endif

	PrinterCtrl(PRN_CTRL_10_CPI)

return( lOk )


static function CheqPrinter()
	TimeForHead(-2)

	PrnAtSay( nLine, 00 ,   Cheque->(PrettyChequeNo())              )
	PrnAtSay( nLine, 12 ,   shMDY(Cheque->date)                     )
	PrnAtSay( nLine, 24 ,   str(Cheque->number,FLD_GROWER)          )
	PrnAtSay( nLine, 30 ,   Grower->cheqName                        )
	PrnAtSay( nLine, 72 ,   NameOf(LU_CHEQUE_TYPE,Cheque->Cheqtype) )
	PrnAtSay( nLine, 82 ,   str(Cheque->year,4)                     )
	PrnAtSay( nLine, 92 ,   iif(Cheque->void,'VOID','')             )
	PrnAtSay( nLine,117 ,   Cheque->amount , '99,999,999.99'        )
	nLine ++
return( nil )

static function Detail1Cheq()
	local lOk := .t.
	local nAmt := 0.00

   Account->(OrdSetFocus(ACCOUNT_CHEQUE_ORD))
	if Account->(dbSeek( Cheque->series+str(Cheque->cheque,FLD_CHEQUE),HARDSEEK))
		do while Account->series==Cheque->series .and. ;
		 Account->cheque==Cheque->cheque .and. !Account->(eof())
			TimeForHead()
			nAmt += Account->dollars
			PrnAtSay( nLine,12 , shMDY(Account->date) )
			if !empty(Account->acct_uniq)
				PrnAtSay(nLine,26, str(Account->acct_uniq,FLD_AD_LINK) )
			endif

			// this is OK for June 99 re TT_WEEKLY
			do case
			case Account->type==TT_DEDUCT
				PrnAtSay( nLine,38, 'Deduction')
				PrnAtSay( nLine,49, NameOf(LU_DEDUCTION_CLASS,Account->class))
			case Account->type==TT_GST_TAX
				PrnAtSay( nLine,38, 'GST Tax')
				PrnAtSay( nLine,49, NameOf(LU_ALL_ACCOUNT_CLASSES,Account->class))
			case empty( Account->process )
				PrnAtSay( nLine,38 , Account->product )
				PrnAtSay( nLine,49 , NameOf(LU_TRANSACTION_TYPE,Account->type) )
			otherwise
				PrnAtSay( nLine,38 , Account->product+'/'+Account->process+'/'+ ;
				  str(Account->grade, FLD_GRADE) )
				PrnAtSay( nLine,49 , NameOf(LU_TRANSACTION_TYPE,Account->type) )
			endcase

			if Account->lbs<>0 .and. Account->u_price<>0.000
				PrnAtSay( nLine,84 , transform(Account->lbs,'9,999,999') )
				PrnAtSay( nLine,94 , '$'+str(Account->u_price,7,3) )
			endif
         if Account->dollars < -999999
            PrnAtSay( nLine,106 , Transform(Account->dollars,'999999999.99') )
         else
            PrnAtSay( nLine,106 , Transform(Account->dollars,'9,999,999.99') )
         endif
			nLine ++
			if !empty(Account->desc)
				PrnAtSay( nLine,46 , Account->desc )
				nLine ++
			endif
			if Account->year<>Cheque->year
				PrnAtSay( nLine,26 , '*** Error, Crop Year is: '+str(Account->year,4) )
				nLine ++
				lOk := .f.
			endif
			Account->(dbSkip())
		enddo
	else
		if Cheque->amount<>0
			PrnAtSay( nLine,16 , '*** ERROR ! ***')
		endif
		PrnAtSay( nLine,36 , 'No Transactions Found !' )
		nLine ++
	endif
	if str(nAmt,12,2) <> str(Cheque->amount,12,2)
		PrnAtSay( nLine,16 , 'Serious ERROR - Cheque and Line Amounts do NOT match' )
		PrnAtSay( nLine,98 , transform(nAmt,'9,999,999.99') )
		nLine ++
		lOk := .f.
	endif
	nLine ++

return( lOk )

static function TimeForHead( nSub)
	DEFAULT nSub TO 0
	if nLine > 56 - nSub
		RepHead()
	endif
return( nil )

static function RepHead()
	PrnAtSay( 1,0 , ;
	 padr(shMDY(date()),15)+padc( 'Cheque Register - Detailed Form',100)+ ;
	 padl('Page'+str(nPage),15) )
	PrnAtSay( 2,0 , padc(cHeading,130) )

	PrnAtSay( 4,01 , 'Cheque #')
	PrnAtSay( 4,15 , 'Date')
	PrnAtSay( 4,24 , 'Grower' )
	PrnAtSay( 4,72 , 'Type' )
	PrnAtSay( 4,82 , 'Year' )
	PrnAtSay( 4,117 , '       AMOUNT' )

	PrnAtSay( 5,0 , replicate('-',130) )
	PrnAtSay( 6,26 , ' Link to' )
	PrnAtSay( 6,88 , '    Unit' )

	PrnAtSay( 7,15 , 'Date' )
	PrnAtSay( 7,26 , padl("Daily",FLD_AD_LINK) )
	PrnAtSay( 7,47 , 'Description' )

	PrnAtSay( 7,84 , '     Lbs' )
	PrnAtSay( 7,94 , '   Price')

	PrnAtSay( 7,106 , '      Amount' )
	PrnAtSay( 8,0 , replicate('-',130) )

	nPage ++
	nLine := 10
return( nil )

static function GetTheStuff( lRead )
	local getList := {}


	if nRadio == 3 .or. !lRead
		in window aWin @12,40 winsay 'Up to the date' winget dDate ;
			picture '@d' get_message ;
			'Show all cheques issued on or before the date.'
	endif
	if nRadio == 2 .or. !lRead
		in window aWin @12,40 winsay 'Statement Date' winget dStatement ;
			picture '@d' ;
			lookup( LU_BANK_STATEMENT, ;
			'Enter the Statement Date - [F5] for List of Reconcile Dates' )
	endif

	if nRadio == 4
		in window aWin @10,2  winsay 'From:' winget dFrom picture '@d' ;
		 get_message 'Based on Date of Cheque'
		in window aWin @11,2  winsay '  To:' winget dTo picture '@d' ;
		 get_message 'Remember the + - and T keys for date fields'
	endif

	if nRadio == 1 .or. !lRead
		in window aWin @10,2  winsay 'From:' winget dFrom picture '@d' ;
		 get_message 'Based on Date of Cheque'
		in window aWin @11,2  winsay '  To:' winget dTo picture '@d' ;
		 get_message 'Remember the + - and T keys for date fields'

		in window aWin @12,2  winsay 'Specific Grower Only' winget nGrower ;
		 picture NumBlankPic( FLD_GROWER ) ;
		 LOOKUP( LU_GROWER, ;
'Enter a Grower ID here, if you wish to list the register for 1 grower ONLY')

		in window aWin @13,2  winsay 'Specific Cheque Only' winget cSeries ;
		 picture '@!'
		in window aWin @13,24+FLD_SERIES winget nCheque picture ;
		 numBlankPic(FLD_CHEQUE)
		in window aWin @14,2  winsay 'Show Payment Details  ' winget lProof ;
		 picture 'Y'  GET_MESSAGE ;
		 'This shows all the associated charges with this cheque'
		in window aWin @15,2 winsay  'Show Void Cheques Only' winget lVoidsOnly ;
		 picture 'Y' when ;
		  !empty(dFrom) .and. !empty(dTo) .and. empty(nGrower) .and. empty(nCheque) ;
		  .and. empty(cSeries)  .and. !lProof ;
		  GET_MESSAGE ;
		 'This will show ONLY Voided Cheques ONLY from Cheque File!'
		in window aWin @16,2 winsay 'Sort Cheques by Grower' winget lByGrower ;
		 picture 'Y'  GET_MESSAGE ;
		 'Say YES if you want a report suitable to send to the Growers'
	endif

	if lRead
		read
	else
		getList := {}
	endif

return( nil )


function bhRegiSetup( aRpt, lVoidOnly )

   default lVoidOnly to .f.

   aadd( aRpt, { '', {|| Field->series}, 'C', 2, 0, .t., .f., ;
     'Cheque Series ID' })

   aadd( aRpt, { 'Cheque#', {|| Field->cheque}, 'N', 7, 0, .t., .f., ;
     'Cheque Number (Cheq # + Series are unique)' })

   aadd( aRpt, { '', {|| Field->cheqtype}, 'C', 2, 0, .t., .f., ;
     'Cheque Type, A=Advance, F=Final, W=Weekly Advance, etc' })

   aadd( aRpt,{ 'ID', {|| Field->number}, 'N', 5, 0, .t., .f., ;
		 'Grower ID' })

	aadd( aRpt, ;
		{ 'Name' 	, { || NameOf(LU_GROWER,Field->NUMBER) } ,  'C' , 030 ,  000 , ;
               .f., .f. , ;
					'Grower Name (not cheque name)' } )

	aadd( aRpt, ;
      { 'Name' , { || NameOf(LU_GROWER_CHEQUE_NAME,Field->NUMBER) }, ;
            'C' , 030 ,  000 , ;
				.t., .f. , ;
				'Grower Cheque Name' } )

	//   aadd( aRpt, ;
   //   {'Date', {|| shMDY( FIELD->DATE )},'C',6,0, .t.,.f., ;
   //      'Date as MMM dd,YY - you may shorten to 6 wide or have as 9 wide'})
   // Aug 2022 - show full date
   aadd( aRpt, ;
      {'Date', {|| shMDY( FIELD->DATE )},'C',9,0, .t.,.f., ;
         'Date as MMM dd,YY - you may shorten to 6 wide or have as 9 wide'})

   if lVoidOnly
      aadd( aRpt, ;
      {'Amount', {|| Field->amount },'N',11,2, .t.,.t., ;
         'Amount of Cheque - including VOIDS!'} )
   else
      aadd( aRpt, ;
      {'Amount', {|| iif( Field->void,0,Field->amount) },'N',11,2, .t.,.t., ;
         'Amount of Cheque - VOIDS are shown as 0!'})

      aadd( aRpt, ;
      {'', {|| iif(Field->void,'VOID','   ') },'C',4,0, .t.,.f., ;
         'Void Status'})
   endif


return( nil )
