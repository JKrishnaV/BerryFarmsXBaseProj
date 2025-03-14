// PROGRAM...: EQUITY.PRG
// AUTHOR....: DUNCAN JEFFRIES - QUANTUM RESEARCH
// DATE......: 8/27/90
// NOTES.....: THIS ROUTINE CALCUALTES AND PRINTS THE EQUITY PAYMENT
//    Total re-write by Bill Hepler
//    Pays Equity Data in file. Converted by Bill Hepler.

//    As of June 99 - turned OFF

#Include 'window.ch'
#Include 'sysvalue.ch'
#Include 'bsgstd.ch'
#Include 'valid.ch'
#Include 'inkey.ch'
#Include 'BerryPay.ch'
#Include 'printer.ch'
#Include 'account.ch'
#include 'price.ch'
#include "field.ch"
#Include "indexord.ch"

#define A_EQUITY_STRU  { 0, 0.00, "  ",0,' ' }

#define  A_EQUITY_YEAR     1
#define  A_EQUITY_AMOUNT   2
#define  A_EQUITY_SERIES      3
#define  A_EQUITY_CHEQUE      4
#define  A_EQUITY_CURRENCY    5


static nYear, aEquity

function equity()
   local aWin, nGrower :=0, dDate, getlist :={}

	if !openfile({'Grower', 'Account','Cheque'},DB_EXCLUSIVE)
		close databases
		return( nil )
	endif

	dDate := date()
	myBsgScreen("Equity Payments")
	nYear := sysvalue(SYS_CURRENT_YEAR) - 6

   create window at 6,10,16,55 title 'Equity Payments' to aWin
   display window aWin
   set cursor on

   do while .t.
   	msgLine('[Esc] to Exit')
   	in window aWin @ 2,5 winsay  'Crop Year to be Paid ' ;
   	 winGet nYear picture '9999'
		in window aWin @ 3,5 winsay  'Specific Grower Only ' ;
		 winget nGrower ;
		 picture NumBlankPic( FLD_GROWER ) ;
       LOOKUP( LU_GROWER, ;
'Enter a Grower ID here, if you wish to generate a payment for 1 grower ONLY')
		in window aWin @ 5,5 winsay 'The steps to making an Equity Payment:'
		in window aWin @ 6,5 winsay '  1.  Pre-Cheque Register  '
		in window aWin @ 7,5 winsay '  2.  Print Cheques        '
		in window aWin @ 8,5 winsay '  3.  Print Statements     '

		read
		if lastkey()==K_ESC
			exit
		endif

		// that should do it !
		if yesno({'Ready to Generate Cheques?'})
			Cheques( CANADIAN_DOLLARS, CHEQUE_TYPE_EQUITY , nYear, nGrower, ;
			 'N', .f., '', dDate)

			Cheques( US_DOLLARS, CHEQUE_TYPE_EQUITY , nYear, nGrower, ;
			 'N', .f., '', dDate)

		endif

	enddo
	kill window aWin
return( nil )


function equityState()
   local aWin, nGrower :=0, nCopies, n,  getList :={}

	if !openfile({'Grower', 'Account','Cheque'},DB_EXCLUSIVE)
		close databases
		return( nil )
	endif


	myBsgScreen("Equity Statements")
   
	nYear := sysvalue(SYS_CURRENT_YEAR) - 6
	nCopies := sysValue(SYS_DEFAULT_NO_STATEMENT_COPIES)

   create window at 6,10,12,50 title 'Equity Statements' to aWin
   display window aWin
   set cursor on
   do while .t.
   	in window aWin @ 2,5 winsay  'Regarding Crop Year ' ;
   	 winGet nYear picture '9999'
   	in window aWin @ 3,5 winsay  'Copies to Print     ' ;
   	 winget nCopies picture '9' valid nCopies >=1
		in window aWin @ 4,5 winsay  'Specific Grower Only' ;
		 winget nGrower ;
		 picture NumBlankPic( FLD_GROWER ) ;
       LOOKUP( LU_GROWER, ;
'Enter a Grower ID here, if you wish to generate a payment for 1 grower ONLY')
		read
		if lastkey()==K_ESC
			exit
		endif
		if selectPrn("EQUITY.TXT")

			PRINT_ON   RPT_OVERWRITE

			if nGrower <> 0
			 	if ValidTest( V_GROWER, nGrower, VT_MESSAGE)
			 		for n :=1 to nCopies
				 		EqStatement( .t. )
				 	next
		 		endif
			else
            Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
			 	Grower->(dbGoTop())
		 		do while !Grower->(eof())
			 		for n := 1 to nCopies
				 		EqStatement( .f. )
				 	next
		 			Grower->(dbSkip())
			 	enddo
			endif

			PRINT_OFF  RPT_COMPLETE_NO_EJECT

      endif
	enddo
	kill window aWin
return( nil )


static function eqStatement( lForce )
	// is there any Equity Record for that year ?
	local n, nEquity, nNet, nLine
   // local nCheque

   aEquity :={}

	msgLine(lstrim(Grower->number)+' '+Grower->name)
   Account->(OrdSetFocus( ACCOUNT_NUMBER_ORD))
	Account->(dbSeek( str(Grower->number,FLD_GROWER)+str(nYear,4), SOFTSEEK ))
	do while !Account->(eof()) .and. Account->number == Grower->number
		if Account->type==TT_EQUITY
			aadd(aEquity, A_EQUITY_STRU)
			n := len(aEquity)
			aEquity[n, A_EQUITY_YEAR]     := Account->year
			aEquity[n, A_EQUITY_AMOUNT]   := Account->dollars
			aEquity[n, A_EQUITY_SERIES]   := Account->series
			aEquity[n, A_EQUITY_CHEQUE]   := Account->cheque
			aEquity[n, A_EQUITY_CURRENCY] := Account->currency
		endif
		Account->(dbSkip())
	enddo

	do case
	 case lForce .and. len(aEquity)==0
	 	waitInfo({'No equity records on file for', ;
	 	 lstrim(Grower->number)+' '+Grower->name })
	 	return( nil )
	 case len(aEquity)==0
	 	return( nil )
	endcase

	// we know there is data...

	PrnAtSay(   1,5 , TheClientName( ) )
   PrnAtSay(   1,50 , "Equity Payemnt Statement for" )
	PrnAtSay(   2,5 , sysValue( SYS_ACTUAL_ADDRESS1) )
	PrnAtSay(   2,50 , 'Crop Year '+str(nYear,4) )
	PrnAtSay(   3,5 , sysValue( SYS_ACTUAL_ADDRESS2))
	PrnAtSay(   4,5 , sysValue( SYS_ACTUAL_ADDRESS3))
   PrnAtSay(   4,50 , "As of "+shMDY(date()))

   PrnAtSay(   7,07 , 'Grower No: '+lStrim(Grower->number))
   PrnAtSay(   9,07 , Grower->name)

	PrnAtSay(  10,07 , Grower->street )
   if !empty( Grower->street2)
      PrnAtSay(  11,07 , Grower->street2)
      PrnAtSay(  12,07 , alltrim(Grower->city)+' '+alltrim(Grower->prov)+'  '+ ;
        Grower->pcode )
   else
      PrnAtSay(  11,07 , alltrim(Grower->city)+' '+Grower->prov )
      PrnAtSay(  12,07 , Grower->pcode )
   endif

	PrnAtSay( 16, 5 , 'CROP     --- PAYMENT INFORMATION ---          EQUITY        EQUITY' )
	PrnAtSay( 17, 5 , 'YEAR     -- CHEQUE # --  --  DATE --          AMOUNT       BALANCE' )
	PrnAtSay( 18, 5 , '------------------------------------------------------------------' )
	//          1994      94-0000234      MMM_DD-YYYY    999,999.99    999,999.99'

	// nCheque := 0.00
   nNet    := 0.00
   nEquity := 0.00
	nLine := 18
	for n := 1 to len(aEquity)
		nLine += 2
		nEquity += aEquity[n,A_EQUITY_AMOUNT]
   	PrnAtSay( nLine, 5 , aEquity[n,A_EQUITY_YEAR] , '9999')

      if empty(aEquity[n,A_EQUITY_CHEQUE])
      	nNet += aEquity[n,A_EQUITY_AMOUNT]
      else
      	// nCheque += aEquity[n,A_EQUITY_AMOUNT]
         Cheque->(OrdSetFocus(CHEQUE_CHEQUE_NO_ORD))
      	if !Cheque->(dbSeek( aEquity[n,A_EQUITY_SERIES] + ;
      	 str(aEquity[n,A_EQUITY_CHEQUE],FLD_CHEQUE), HARDSEEK))
      		waitInfo({'Problem with Cheque Data for', ;
      		 lstrim(Grower->number)+' '+Grower->name, ;
      		 'Reindex files - if persists call Crafted Industrial Software Ltd.'})
      	else
            PrnAtSay(  nLine,14 , Cheque->series+'-'+strZero(Cheque->cheque,FLD_CHEQUE) )
            PrnAtSay(  nLine,30 , shMDY(Cheque->date) )
         endif
      endif

      PrnAtSay(  nLine,47 , aEquity[n,A_EQUITY_AMOUNT] , '999,999.99' )
      PrnAtSay(  nLine,61 , nNet , '999,999.99' )
		PrnAtSay(  nLine,72 , NameOf(LU_CURRENCY, aEquity[n,A_EQUITY_AMOUNT]) )

   next

	nLine += 2
	PrnAtSay(  nLine, 5 , '------------------------------------------------------------------' )
	nLine += 2
	PrnAtSay(  nLine, 5 , 'TOTAL     ==>' )
	PrnAtSay(  nLine,47 ,  nEquity , '999,999.99' )
	PrnAtSay(  nLine,61 ,  nNet , '999,999.99' )
	nLine += 2
	PrnAtSay(  nLine, 5 , '------------------------------------------------------------------' )

	nuFormFeed()

return( nil )
