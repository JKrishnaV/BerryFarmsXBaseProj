// --------------------------------------------------------------------------
//  Application: Berry Payment Program
//  Description: Actually Voids or Reissues a Cheque
//               assumes the files are in use exclusively, etc.
//               was moved to a separate file in June 95.
//
//  Revised July 99
//
//  Nov 2000    reWritten it makes it so VOIDs, just remove the PAID
//              stamps from the relevent files.....
//              ReIssue just puts a different cheque on it.
//  June 2011   Minor Revision
//  Sep 2011    Improve Audit trail, correct a ZapCheque issue
//  Apr 02,2021 Better Notes explaining what this does, and fix some stuff and test
//              more extensively.
//
//    File Name: VOIDREIS.PRG
//       Author: Bill Hepler
// Date created: 06-04-95
//    Copyright: (c) 1995,2011,2021 by Bill Hepler & Crafted Industrial Software Ltd.
// -------------------------------------------------------------------------


// The original Program had a PROBLEM, if we VOIDED a SPECIAL cheque...
// then, the computer generated -ve numbers in DAILY...this is quite
// appropriate for the WEEKLY cheques, which are usually voided because
// the wrong grower was entered (and these transactions will be set
// to another grower).

// We fix this here...
// if we VOID:
//    1.  for weekly payments - these PRODUCTION records are REVERSED OUT
//        (both the DAILY.DBF & ACCOUNT.DBF)
//    2.  for other payments - only the ACCOUNT.DBF records are REVERSED
// if we REISSUE:
//    1.  we first void the cheque as above
//    2.  we also COPY the original data...


#include "BerryPay.ch"
#include "bsgstd.ch"
#include "printer.ch"
#include "window.ch"
#include "sysvalue.ch"
#include "valid.ch"
#include "inkey.ch"
#include "colors.ch"
#include "price.ch"
#include "indexord.ch"
#include "field.ch"
#include "errors.ch"
#include 'account.ch'
#include "events.ch"

// we should be Passed the Date of Reissue or Void, and whether it is a
// reissue or void
// We are assumed to be on the correct Cheque....

///<para>This ONLY touches ACCOUNT.DBF
/// the price of Berry Advances & Final Account.dbf transactions is UNCHANGED
/// to ReIssue, last param=T -- void last Param=F
/// </para>
function VoidOrReissue( cSeries, nCheque, dDate, lReissue )
	local lReturn := .f.
   // local n
	local lActualReissue := .f.
	local cNewSer   := ''
	local nNewCheq  := 0

	if Cheque->series<>cSeries .or. Cheque->(eof()) .or. ;
			Cheque->cheque<>nCheque
		appError( APP_ERR_CHEQUE_LOCATE1, ;
			{'Restore Data', 'BAD-Not on correct Cheque!'})
	endif
	msgLine('Setting everything up...')

	showProg('Cheque')

	CopyOneRec('Cheque','VoidChq')
	voidChq->(EditByFlds())
	VoidChq->DATEVOID := date()

   Account->(OrdSetFocus( ACCOUNT_CHEQUE_ORD ))
	Account->(dbSeek( cSeries+str( nCheque,FLD_CHEQUE),HARDSEEK))

	// Copy the Original to the CANCEL cheque file.
	if lReissue
		if SetChqNo( dDate)
			nNewCheq := TempCheq->cheque
			cNewSer  := TempCheq->series

			VoidChq->note := 'Reissue as '+ TempCheq->(PrettyChequeNo())
			lActualReissue := .t.
		else
			VoidChq->note := 'Cancelled-not yet reissued'
		endif
	else
		VoidChq->note := 'Cheque Cancelled'
	endif

	if lActualReissue
		// update the related transactions with new cheque number
		do while Account->series== cSeries .and. ;
				Account->cheque== nCheque .and. ;
				.not. Account->(eof())

			// File is locked, so no problem...
			Account->cheque := nNewCheq
			Account->series := cNewSer

			Account->T_cheq := nNewCheq
			Account->T_ser  := cNewSer

			Account->(dbCommit())

			Account->(dbSeek( cSeries+str( nCheque,FLD_CHEQUE),HARDSEEK))
		enddo

		// if we REISSUE the Cheque, then TempCheq has the "real cheque" in it
		if PrintTheReissue( dDate )
			if Cheque->series<>cSeries .or. Cheque->(eof()) .or. ;
					Cheque->cheque<>nCheque
				appError( APP_ERR_CHEQUE_LOCATE2, ;
					{'Restore Data','BAD-Not on correct Cheque!'})
			endif
			Cheque->cheque  := nNewCheq
			Cheque->series  := cNewSer
			Account->T_cheq := nNewCheq
			Account->T_ser  := cNewSer

			Cheque->date   := dDate
			Cheque->(dbCommit())
		else
			if Cheque->series<>cSeries .or. Cheque->(eof()) .or. ;
					Cheque->cheque<>nCheque
				appError( APP_ERR_CHEQUE_LOCATE4, ;
					{'Restore Data','BAD-Not on correct Cheque!'})
			endif
			Cheque->(DeleteByFlds())
			Cheque->(dbDelete())          // we are in exclusive....
			Cheque->(dbCommit())

			lReturn := .f.
		endif
	else
		// update the related transactions with UNPAID (cheque == 0)

		do while Account->series== cSeries .and. ;
				Account->cheque== nCheque .and. ;
				.not. Account->(eof())

			// File is locked, so no problem...
			Account->cheque := 0
			Account->series := space(FLD_SERIES)
			Account->T_cheq := 0
			Account->T_ser  := space(FLD_SERIES)

			Account->(dbCommit())

			Account->(dbSeek( cSeries+str( nCheque,FLD_CHEQUE),HARDSEEK))
		enddo

		if Cheque->series<>cSeries .or. Cheque->(eof()) .or. ;
				Cheque->cheque<>nCheque
			appError( APP_ERR_CHEQUE_LOCATE4, ;
				{'Restore Data','BAD-Not on correct Cheque!'})
		endif
		Cheque->(deleteByFlds())
		Cheque->(dbDelete())          // we are in exclusive....
		Cheque->(dbCommit())

	endif

   if lReissue
      LogAnEvent( EVT_TYPE_CHEQUE_REISSUE , ;
                      {'Reissued Cheque ' + var2char( cSeries)+ var2char( nCheque), ;
                       'New Cheque is   ' + var2char( cNewSer)+ var2char( nNewCheq) })
	else
      LogAnEvent( EVT_TYPE_CHEQUE_VOID_LEAVE_AP , ;
                      {'Voided Cheque ' + var2char( cSeries)+ var2char( nCheque), ;
                       'But we LEFT the Accounts Payable entries' })

   endif

return( lReturn )

static function SetChqNo( dChqDate)
	local nRecNo
	local lReturn := .t.
	local aWin
	local nCheq, nStCh
	local cSeries, cStSer
	local getList := {}

	select Cheque
	nRecNo := Cheque->(recno())

	do case
	case Cheque->currency==CANADIAN_DOLLARS
		cStSer := cSeries := sysValue(SYS_CDN_CHEQUE_SERIES)
	case Cheque->currency==US_DOLLARS
		cStSer := cSeries := sysValue(SYS_US_CHEQUE_SERIES)
	otherwise
		waitHand({'Bad Currency Can NOT print!'})
		return( .f. )
	endcase

	copy to TempCheq while recno()==nRecNo

	use TempCheq exclusive new
	TempCheq->void := .f.

   Cheque->(OrdSetFocus(CHEQUE_CHEQUE_NO_ORD))
	if Cheque->(FindLast(cSeries))
		do while Cheque->cheque<0 .and. Cheque->series==cSeries .and. !Cheque->(bof())
			Cheque->(dbSkip(-1))
		enddo
	endif
	if Cheque->series == cSeries
		nStCh := nCheq := Cheque->cheque + 1
	else
		nCheq := 1
	endif
	Cheque->(dbGoTo(nRecNo))

	create window at 4,18,7,61 title 'Print this Cheque' to aWin
	display window aWin

	do while .t.
		in window aWin @ 2,2 winsay 'Enter the cheque series ' winget cSeries picture '!!'
		in window aWin @ 3,2 winsay 'Enter the starting cheque number' ;
		 winget nCheq PICTURE '999999' valid nCheq >= nStCh
		read
		if lastkey()==K_ESC
			lReturn := .f.
			exit
		endif
		if !(cSeries==cStSer .and. nCheq >= nStCh)
			waitHand({'This is not a valid Cheque Number.', ;
			 iif(cStSer==cSeries, ;
			  'Your cheque number must be at least '+lstrim(nStCh), ;
			  'You may only change the series in System Values') })
			loop
		endif

		TempCheq->date   := dChqDate
		TempCheq->series := cSeries
		TempCheq->cheque := nCheq
		TempCheq->void   := .f.

		lReturn := .t.
		exit
	enddo
	kill window aWin

return( lReturn )


static function PrintTheReissue(dChqDate)
	local lReturn := .f.

   if SysValue( SYS_ASK_TO_PRINT_ALIGNMENT_COPY_OF_CHEQUE)
      do while yesno({'Print Alignment Copy?'})
         if SelectPrn('ALIGN.TXT.')
            PRINT_ON  RPT_OVERWRITE
            PrinterCtrl( PRN_CTRL_10_CPI )
            ActualCheque( .f., dChqDate )
            PrinterCtrl( PRN_CTRL_10_CPI )
            PRINT_OFF  RPT_COMPLETE_EJECT
         endif
      enddo
   endif

	if yesno({'Next Step Prints the Actual Cheques.', ;
	  'Insert Cheque Forms', ;
		'Do you want to Print Cheques?'})

		if selectPrn('CHEQUE.TXT')

			PRINT_ON RPT_OVERWRITE
			PrinterCtrl( PRN_CTRL_10_CPI )
			ActualCheque( .t., dChqDate )
			PrinterCtrl( PRN_CTRL_10_CPI )
			PRINT_OFF RPT_COMPLETE_EJECT

			lReturn := .t.

			if selectPrn('POSTED.TXT')
				PRINT_ON RPT_OVERWRITE
            nuQprnOut('')
            nuQprnOut( shMDY(date()) )
            nuQprnOut( time() )
            nuQprnOut('')
            nuQprnOut('Cheque: '+cheque->series,Cheque->cheque)
            nuQprnOut(' to Grower '+lStrim(Cheque->number)+' '+Grower->cheqName)
            nuQprnOut(' was reissued.')
            nuQprnOut('The cheque was for $ '+lstrim(Cheque->amount,2) )
            nuQprnOut('Payment type '+NameOf(LU_CHEQUE_TYPE,Cheque->cheqType) )
            nuQprnOut('')
            nuQprnOut( 'The New Cheque Number is: '+TempCheq->series + str( TempCheq->cheque, 12) )
            nuQprnOut( '' )
				PRINT_OFF RPT_COMPLETE_EJECT
			endif
		endif
	endif

return( lReturn )


