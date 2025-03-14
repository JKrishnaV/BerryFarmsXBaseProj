// CheqRun.prg
// June 16, 1994
// Does the Actual Cheque Run....
// Modified in May 95 to allow for Advance Cheque for Known Amount....
// See also VoidReis.PRG for related CODE on Cheque Numbers.
// Aug 2011 - Changes for EFT cheques
// July 2014 - minor change for GST

#include 'inkey.ch'
#include 'common.ch'
#include 'window.ch'
#include 'bsgstd.ch'
#include 'printer.ch'
#include 'BerryPay.ch'
#include 'valid.ch'
#include 'sysvalue.ch'
#include 'account.ch'
#include 'price.ch'
#include "indexord.ch"
#include "field.ch"
#include "errors.ch"
#include 'rpt.ch'
#include 'events.ch'

// not in Special Pay
static cSeries,nCheq,dChqDate,dLastDate
static cStSer, nStChq

static nStartEFTchq

// in SpPay  - can be passed by another program.....
static nGrower,nYr

// in SpPay, used to select Growers to send to...
static cOrder,lPayGrp,cPayGrp

static cCheqType

function cheques( cCurrency, cChqTp, nY,nG, cO,lD, cD, dL ,nRecID )
	local aWin, getList :={}

	close databases
	if !open4ChequeRun( DB_EXCLUSIVE )
		close databases
		return( nil )
	endif

   inkey() // to just clear keyboard if Jass is impatient
   inkey() // 2nd one

	nYr     := iif( valtype(nY)=='N', nY, sysvalue(SYS_CURRENT_YEAR) )
	nGrower := iif( valType(nG)=='N', nG, 0)
	cOrder  := iif( valType(cO)=='C', cO, 'N')
	lPayGrp  := iif( valType(lD)=='L', lD, .f.)
	cPayGrp  := iif( valType(cD)=='C', cD, space( FLD_PAYGRP ) )
	dLastDate := iif(valType(dL)=='D', dL, date()-30)
	cCheqType := cChqTp

	dChqDate := date()
	do case
	case cCurrency == CANADIAN_DOLLARS
		cStSer := cSeries := sysValue(SYS_CDN_CHEQUE_SERIES)
	case cCurrency == US_DOLLARS
		cStSer := cSeries := sysValue(SYS_US_CHEQUE_SERIES)
	otherwise
		appError(APP_ERR_NO_CURRENCY, {'Very Bad - Currency not passed'})
		close databases
		return( nil )
	endcase

   Cheque->(OrdSetFocus(CHEQUE_CHEQUE_NO_ORD))
	if Cheque->(FindLast(cSeries))
		do while Cheque->cheque<0 .and. Cheque->series==cSeries .and. !Cheque->(bof())
			Cheque->(dbSkip(-1))
		enddo
	endif
	if Cheque->series == cSeries
      nStChq := nCheq := Cheque->cheque + 1
	else
      nStChq := nCheq := 1
	endif

   if Cheque->(FindLast( EFT_CHEQUE_SERIES ))
      do while Cheque->cheque<0 .and. Cheque->series==EFT_CHEQUE_SERIES .and. !Cheque->(bof())
			Cheque->(dbSkip(-1))
		enddo
	endif
   if Cheque->series == EFT_CHEQUE_SERIES
      nStartEFTchq := Cheque->cheque + 1
	else
      nStartEFTchq := 1
	endif

	msgLine('Do not forget the alignment cheque')

   create window at 4,5,22,72 ;
	  title 'Print '+NameOf(LU_CURRENCY,cCurrency)+' Cheques' to aWin
	display window aWin
	set cursor on

	do while .t.
		in window aWin @12,5 winsay  'This process takes place in 4 steps -'
		in window aWin @13,5 winsay  ' 1. Generate the Cheques'
		in window aWin @14,5 winsay  ' 2. Print a Pre-Check Register'
		in window aWin @15,5 winsay  ' 3. Print the Cheques'
		in window aWin @16,5 winsay  ' 4. Print the Cheque Register'

      in window aWin @18,2 winsay 'Use '+EFT_CHEQUE_SERIES+ ;
       ' for EFT cheques - they have their own numbers'

      in window aWin @ 2,2 winsay 'Enter the cheque series ' ;
        winget cSeries picture '@!'
		in window aWin @ 3,2 winsay 'Enter the starting cheque number' ;
       winget nCheq picture numZeroPic(FLD_CHEQUE -1) ;
       get_message 'EFT cheques will have their own numbers'

		// July 95 -- because we void cheques, we do not allow the number
		//            to be more than 5 digits !

		in window aWin @ 4,2  winsay 'Cheque Date:' winget dChqDate picture '@d' ;
		 GET_MESSAGE 'The accounting date of Generated Cheques'
		in window aWin @ 5,2  winsay 'Include to: ' winget dLastDate ;
		 GET_MESSAGE 'Include deductions and other adjustments up to this date'

      if cCheqType <> CHEQUE_TYPE_LOAN
			in window aWin @ 6,2 winsay 'Alphabetic or Numeric Order (A/N):' ;
			 winGet cOrder PICTURE '!' valid cOrder $ 'AN' ;
			  GET_MESSAGE ;
		 'A = Alphabetical list of growers by Grower Name (not Cheque Name!)'

			in window aWin @ 7,2 winsay 'In Pay Group Order ?  ' ;
			 winGet lPayGrp PICTURE 'Y' ;

			in window aWin @ 8,2 winsay 'Specific PayGrp Only  ' winget cPayGrp ;
			 when PutName(aWin,8,30,LU_PAYGRP,cPayGrp) ;
			 valid PutName(aWin,8,30,LU_PAYGRP,cPayGrp) ;
			  picture '@!' lookup( LU_PAYGRP,  'Leave Blank for All Groups' )
		endif

		in window aWin @ 9,2 winsay 'For Crop Year         ' winget nYr  ;
		 picture '9999' GET_MESSAGE ;
		 'The Crop Year to Which these Payments and Deductions Belong'

		in window aWin @10,2 winsay 'Specific Grower Only  ' winget nGrower ;
		 picture NumBlankPic( FLD_GROWER ) ;
       when cCheqType<>CHEQUE_TYPE_LOAN ;
		 LOOKUP( LU_GROWER, ;
		'Enter a Grower ID here, if you wish to generate a cheque for 1 grower ONLY')

		read
      do case
      case lastkey()==K_ESC
			exit
      case cSeries == EFT_CHEQUE_SERIES .and. nCheq < nStartEFTchq
         waitHand({'This is too low a number for EFT Cheques.  These', ;
                   'must start at '+lstrim( nStartEFTchq)+ ' or higher'})
         loop
      case cSeries == cStSer  .and. nCheq < nStChq
         waitHand({'This is not a valid starting place for', ;
             'the Cheque Numbers for series '+cStSer, ;
             'Your cheque number must be at least '+lstrim(nStChq) })
         loop
      case cSeries <> cStSer .and. cSeries <> EFT_CHEQUE_SERIES
         waitHand({'You must use either '+EFT_CHEQUE_SERIES+ ' or ' +cStSer, ;
           'as the series for this type of Cheque', ;
           'You can change the Main Series in the General System Settings'})
      otherwise
         if cSeries== EFT_CHEQUE_SERIES
            waitHand({'You are Running EFT cheques!'})
			endif
      endcase

      if !yesno({'Prepare and print cheques?', ;
         'The steps:', ;
         ' 1. We prepare cheques in the computer.',;
         ' 2. We allow you to print a PRE-CHEQUE register',;
         ' 3. Print any actual cheques.', ;
         ' 4. Print the Cheque posting Register' })
         loop
      endif

		LogAnEvent( EVT_TYPE_CHEQUES_TRY_TO_GENERATE , ;
		             {'Cheques Dated '+ shMdy( dChqDate) , ;
                    'Incl. to ' + shMdy( dLastDate )   , ;
                    'Grower(0=All): '+ var2char( nGrower)  } )

		if !GenCheques( cCurrency, nRecID )
			LogAnEvent( EVT_TYPE_CHEQUE_GENERATE_FAILS , ;
		               {'Cheques Dated '+ shMdy( dChqDate) , ;
                      'Incl. to ' + shMdy( dLastDate )   , ;
                      'Grower(0=All): '+ var2char( nGrower)  } )
			loop
		endif

      PrnRegi(cCurrency,'Pre-Check Register','PREREG.TXT')

      if sysValue(SYS_CHEQUE_FORMAT) == 4
         WaitHand({'In the next screen you will print the', ;
                   'VOUCHER forms.  Please be sure you select', ;
                   'a Printer for this!'})
			LogAnEvent( EVT_TYPE_CHEQUE_VOUCHER_ONLY , ;
		                { 'Cheques Dated '+ shMdy( dChqDate), ;
                        'Incl. to ' + shMdy( dLastDate )  , ;
                        'Grower(0=All): '+ var2char( nGrower)  } )
      else
         // meaning we print actual CHEQUES...

         if SysValue( SYS_ASK_TO_PRINT_ALIGNMENT_COPY_OF_CHEQUE)
            do while yesno({'Print Alignment Copy?'})
               if SelectPrn('ALIGN.TXT.')
               	msgLine('Printing Alignment...')
                  PRINT_ON  RPT_OVERWRITE
                  PrinterCtrl( PRN_CTRL_10_CPI )
                  ActualCheque( .f., dChqDate )

                  PrinterCtrl( PRN_CTRL_10_CPI )
                  PRINT_OFF  RPT_COMPLETE_EJECT
               endif
            enddo
         endif


         if !yesno({'Next Step Prints the Actual Cheques.', ;
           'Insert Cheque Forms.', ;
           '*** Normally you should print the cheques ****', ;
            'Do you want to Print Cheques?'})

				LogAnEvent( EVT_TYPE_CHEQUES_NOT_PRINTED_1 , { ;
		                   'Cheques Dated '+ shMdy( dChqDate) , ;
                         'Incl. to ' + shMdy( dLastDate ) , ;
                         'Grower(0=All): '+ var2char( nGrower) } )

            loop
         endif
      endif

		if !selectPrn('CHEQUE.TXT')
			LogAnEvent( EVT_TYPE_CHEQUES_NOT_PRINTED_2 , { ;
		                'Cheques Dated '+ shMdy( dChqDate) , ;
                      'Incl. to ' + shMdy( dLastDate ) , ;
                      'Grower(0=All): '+ var2char( nGrower) } )

			loop
		endif
      msgLine('Getting ready to print cheques..')

		// Moved this up here so that cheques could have proper INFO
		select Account
		set order to 0   // FOR SPEED and NO INDEX BUGS !
		replace all Account->series with Account->t_ser, ;
		 Account->Cheque with Account->t_cheq for ;
		 empty(Account->cheque) .and. empty(account->series) ;
		 .and. !empty(Account->t_cheq)

		Account->(dbCloseArea())

		OpenFile({'Account'},DB_EXCLUSIVE)

		// this is UNLIKELY TO fail...

		LogAnEvent( EVT_TYPE_CHEQUES_PRINTED , { ;
	                'Cheques Dated '+ shMdy( dChqDate) , ;
                   'Incl. to ' + shMdy( dLastDate )   , ;
                   'Grower(0=All): '+ var2char( nGrower) }  )

		PRINT_ON RPT_OVERWRITE

		PrinterCtrl( PRN_CTRL_10_CPI )

		tempcheq->(dbGoTop())
		DO WHILE .NOT. TempCheq->(EOF())
			// PrinterCtrl( CHR(27)+CHR(67)+CHR(21))  // laser Printer

			// Just Prints Them....
         ActualCheque( .t., dChqDate )

			TempCheq->(dbSkip())
		ENDDO

		PRINT_OFF RPT_COMPLETE_EJECT

		do while .t.
         PrnRegi(cCurrency,'Posted Cheque Register','CHEQREG.TXT')
			select TempCheq
			use

			select Cheque
			append from TempCheq
			exit
		enddo
		exit
	enddo
	kill window aWin
	close databases

return( nil )

static function GenCheques( cCurrency, nRecID )
	local nChAmt, nRec

	msgLine('Getting Ready')
   if select('TempCheq')>0
      TempCheq->(dbCloseArea())
      sleep( 10 )
	endif

	if file('_TmpCheq.DBF') .and. file('TempCheq.DBF')
      fErase('_TmpCheq.DBF')
   endif
	if file('TempCheq.dbf')
	   fRename('TempCheq.DBF','_TmpCheq.DBF')
	endif

	select Cheque
	copy structure to TempCheq
	use TempCheq exclusive new

	select Account

   if cCheqType == CHEQUE_TYPE_LOAN
      if ValidTest(V_GROWER,nGrower,VT_MESSAGE)
         if Grower->onHold
            waitInfo({'Grower is on hold - we are trying not to pay him!'})
            return( .f. )
         endif
      else
			return( .f.)
		endif

      Account->( OrdSetFocus( ACCOUNT_NUMBER_ORD ))
		replace  Account->t_ser with '',Account->t_cheq with 0 ;
		 for (empty(Account->series) .or. empty(Account->cheque)) ;
		 .and. (!empty(Account->t_ser) .and. !empty(Account->t_cheq) ) ;
		 .and. Account->currency==cCurrency ;
		 while Account->number == nGrower

		nChAmt := 0.00

		Account->(dbGoTo( nRecID) )
		if Account->dollars > 0
			nChAmt += Account->dollars
			Account->t_ser   := cSeries
			Account->t_cheq  := nCheq

			// create a cheque.
			AddCheqAmt( cCurrency, nChAmt )
		endif
	else
		set order to 0
		replace all Account->t_ser with '',Account->t_cheq with 0 ;
		 for (empty(Account->series) .or. empty(Account->cheque)) ;
		  .and. Account->currency==cCurrency ;
		 .and. (!empty(Account->t_ser) .and. !empty(Account->t_cheq) )

		if cCheqType==CHEQUE_TYPE_EQUITY
			set filter to Account->type==TT_EQUITY
		else
			set filter to Account->type<>TT_EQUITY
		endif

		if empty(nGrower)
			if !SetGrow4Rpt(lPayGrp,cPayGrp,cOrder )
				return( .f. )
			endif
         Account->(OrdSetFocus(ACCOUNT_NUMBER_ORD))
		else
			if !ValidTest(V_GROWER,nGrower,VT_MESSAGE)
				return( .f.)
			endif
         Account->(OrdSetFocus(ACCOUNT_NUMBER_ORD))
			Account->(dbSeek( str(nGrower,FLD_GROWER), HARDSEEK))
		endif

		msgLine('Generating Cheques')

		do while !Grower->(eof())
			showProg(str(grower->number,FLD_NUMBER))

			nChAmt := 0.00

         if !Grower->onHold
            Account->(dbSeek( str(Grower->number,FLD_GROWER)+str(nYr,4), SOFTSEEK))
            nRec := 0
            do while Grower->number==Account->number .and. Account->year==nYr .and. ;
             Account->date <= dLastDate .and. !Account->(eof())

               if empty(account->series) .and. empty(account->cheque)
                  // June 99 - currency problems
                  if Empty(Account->currency)
                     if Grower->currency == cCurrency
                        appError(APP_ERR_EMPTY_CURRENCY1, ;
                           {'Currency Field is Empty in ACCOUNT.DBF', ;
                            'Grower '+str(Grower->number,10), ;
                            'We are correcting - however please note', ;
                            'this error.'})
                        Account->currency := cCurrency
                     else
                        appError(APP_ERR_EMPTY_CURRENCY2, ;
                           {'Currency Field is Empty in ACCOUNT.DBF', ;
                            'Grower '+str(Grower->number,10), ;
                            'Please check it and correct later!' })
                     endif
                  endif

                  if Account->currency==cCurrency
                     if nRec == 0
                        // 1st Record
                        nRec := Account->(recno())
                     endif
                     nChAmt += Account->dollars
                     Account->t_ser   := cSeries
                     Account->t_cheq  := nCheq
                  endif
               endif
               Account->(dbSkip())
            enddo

            // the other case is nChAmt==0.00 .and. nRec==0
            do case
             case nChAmt <= 0.00 .and. nRec > 0
               // negative amount, we reverse it back out !
               Account->(dbGoTo(nRec))
               do while !Account->(eof()) .and. Grower->number==Account->number ;
                 .and. Account->date <= dLastDate .and. Account->year==nYr
                  if empty(account->series) .and. empty(account->cheque)
                      nChAmt -= Account->dollars
                      Account->t_ser   := ''
                      Account->t_cheq  := 0
                  endif
                  Account->(dbSkip())
               enddo
             case nChAmt > 0.00
               // create a cheque.
               AddCheqAmt( cCurrency, nChAmt )
            endcase
         endif

         if !empty(nGrower)
            exit              // just one grower
			endif
			Grower->(dbSkip())
		enddo
	endif
   Account->(dbClearFilter())
return( .t. )

static function prnRegi( cCurrency,cHeading, cPrnInfo )
	local nRec, nOrd
   local aRpt

	nRec := Grower->(recno())
	nOrd := Grower->(IndexOrd())
   do while .t.
      waitHand({'Insert Correct Paper for Printing',  cHeading, ;
       'Next you will select the Printer' })

      if selectPrn( cPrnInfo )
         PRINT_ON  RPT_OVERWRITE

         Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))
         select TempCheq
         set relation to str(TempCheq->number,FLD_NUMBER) into Grower
         goto top

         // 2BFIXED - done I think
         // report form bh_regi heading ;
         // NameOf(LU_CURRENCY,cCurrency)+' '+cHeading+' for '+shMDY(dChqDate) ;
         //  to Print

         aRpt := {}
         TempCheq->(bhRegiSetup( aRpt, .f. ))

         gRptInitHead()
         gRptGetSetHead( RPT_HEAD_TITLE, ;
            { NameOf(LU_CURRENCY,cCurrency)+' '+cHeading+' for '+shMDY(dChqDate)  } )

			gRptPrintSize( aRpt )

         TempCheq->(gRptPrinter( aRpt ))

         PrinterCtrl( PRN_CTRL_10_CPI )

         select TempCheq
         set relation to
         PRINT_OFF RPT_COMPLETE_EJECT
      endif

		if !yesno({'Print Register Again?'})
			exit
		endif
	enddo
	if nRec>0
		Grower->(dbGoto(nRec))
	endif
   Grower->(OrdSetFocus(nOrd))
return( nil )

static Function AddCheqAmt( cCurrency, nAmt )

	TempCheq->(addRecord())
	TempCheq->date      := dChqDate
	TempCheq->currency  := cCurrency
	TempCheq->year      := nYr
	TempCheq->number    := Grower->number
	TempCheq->cheque    := nCheq
	TempCheq->series    := cSeries
	TempCheq->amount    := nAmt
	TempCheq->cheqType  := cCheqType

	nCheq++
return( nil )

