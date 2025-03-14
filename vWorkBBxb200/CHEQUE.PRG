// PROGRAM...: CHEQUE.PRG
// AUTHOR....: DUNCAN JEFFRIES / Rev BH
// DATE......: 5/9/90
// NOTES.....: THIS ROUTINE PRINTS THE CHEQUES
// June 3, 1994, Bill Hepler, re-written mostly
// June 1999 BH added for S.Alder Farms
// Aug 99 - fixed bug with Print out of Cheque Amount Rounding.
// Oct 99 - fixed bug with showing only 2 decimals when 3 are needed...
// Nov 2001 - up to 3 advances
//            corrected a bug about not printing descriptions
//            made it so you can print up to $ 9,876,543.21
//            lose the "," in some cases.
// July 2007 BH - New Cheque Format
// July 2009 BH - Another new cheque format for HP printers - laser cheques
// July 2014 BH - Support for GST.


#include 'printer.ch'
#include 'sysvalue.ch'
#include 'window.ch'
#include 'colors.ch'
#include 'inkey.ch'
#include 'bsgstd.ch'
#include 'BerryPay.ch'
#include 'price.ch'
#include 'valid.ch'
#include "indexord.ch"
#include "field.ch"
#include "errors.ch"
#include "account.ch"

function TestChequeFormat( )

   if !open4ChequeRun( DB_EXCLUSIVE )
      close databases
      return( nil )
   endif

   select Cheque
	copy structure to TempCheq

	use TempCheq exclusive new
   select TempCheq
	TempCheq->(addRecord())
	
   do while .t.
      if Yesno({'Print a Sample Check?', ;
         'You are using Format # '+str( sysValue( SYS_CHEQUE_FORMAT ),2) })

         if selectPrn('TESTCHQ.TXT')
            PRINT_ON  RPT_OVERWRITE
            PrinterCtrl( PRN_CTRL_10_CPI )

            ActualCheque( .f., date() )

            PrinterCtrl( PRN_CTRL_10_CPI )
            PRINT_OFF  RPT_COMPLETE_EJECT
         endif
      else
         exit
      endif
   enddo

   close databases

return( nil )

function ActualCheque( lReal, dDate )
   local aLines := {}
   local n

	do case
	case sysValue(SYS_CHEQUE_FORMAT)==1
      // bcBlueCheque( lReal, dDate)
      waitInfo({'We no longer support this format', ;
                'Call Crafted Industrial Software Ltd.' ,;
                'at 604-256-7485'})

	case sysValue(SYS_CHEQUE_FORMAT)==2
		SoAlderCheque( lReal, dDate)
		AdviceSection(lReal, dDate)

	case sysValue(SYS_CHEQUE_FORMAT)==3
		TripleCrownCheque( lReal, dDate)
		AdviceSection(lReal, dDate)

   case sysValue(SYS_CHEQUE_FORMAT)==4
      MiniHead( lReal,dDate)
		AdviceSection(lReal, dDate)
      NuFormFeed()

   case sysValue(SYS_CHEQUE_FORMAT)==5

      aLines := {}
      NiftyAdviceLines( lReal, dDate, aLines )

      if sysValue( SYS_CHEQUE_NIFTY_ADVICE1_STARTS ) > 0
         if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
            W32PrnTextArray( aLines, 0.3, ;
              sysValue( SYS_CHEQUE_NIFTY_ADVICE1_STARTS ), 11/72 )
         else
            hpAbsPrnPosition(  0.01 , ;
                sysValue( SYS_CHEQUE_NIFTY_ADVICE1_STARTS ) )
            for n := 1 to len( aLines )
               nuQQprnOut( aLines[n] )
               nuQprnOut()
            next
         endif
      endif

      if sysValue( SYS_CHEQUE_NIFTY_ADVICE2_STARTS ) > 0
         if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
            W32PrnTextArray( aLines, 0.3, ;
              sysValue( SYS_CHEQUE_NIFTY_ADVICE2_STARTS ), 11/72 )
         else
            hpAbsPrnPosition(  0.01 , ;
                sysValue( SYS_CHEQUE_NIFTY_ADVICE2_STARTS ) )
            for n := 1 to len( aLines )
               nuQQprnOut( aLines[n] )
               nuQprnOut()
            next
         endif
      endif

      ChqNiftyPrn( lReal,dDate)
      if lReal   // we only print ONE cheque for Alignment copies...
         nuFormFeed()   // and we eject after the print job...
      endif

	otherwise
		appError( APP_ERR_BAD_CHEQUE_FORMAT, ;
			{'Bad cheque format - check your system values!'} )
	endcase

return( nil )

static function TripleCrownCheque( lReal, dDate)
	local nLine, nAmt, cName
	local cI
	local n
   local aRay

   Grower->(OrdSetFocus( GROWER_NUMBER_ORD))
	Grower->(dbSeek( str(TempCheq->number,FLD_GROWER)) )

	if lReal
		nAmt := TempCheq->amount
		cName := padr(Grower->cheqName,FLD_NAME)
	else
		nAmt := 0
		cName := padr('* * * VOID * * *',FLD_NAME)
	endif
	msgLine(cName)

	nLine:= sysValue( SYS_CHEQUE_1ST_LINE )
	cI   := space(sysValue( SYS_CHEQUE_LEFT_INDENT ))

	setPrc(0,0)
	for n := 1 to nLine
      nuQprnOut()
	next
   nuQprnOut( cI + space(43)+'#'+ strZero(TempCheq->cheque, 6) + ;
      space(18)+shMDY(dDate)   )
   nuQprnOut()

   nuQprnOut()
   if nAmt > 999999
      nuQprnOut( cI+space(68)+ transform(nAmt, '9999999.99') )
   else
      nuQprnOut( cI+space(68)+ transform(nAmt, '999,999.99') )
   endif

   // ? cI + space(10)+DollarSayer(nAmt)
   if SysValue( SYS_CHEQUE_DOLLAR_FORMAT ) == 1
      nuQprnOut( cI+space(10)+DollarSayer( nAmt ) )
      nuQprnOut()
      nuQprnOut()
   else
      aRay := NumInWords( nAmt, 55 )
      do case
      case len( aRay ) > 3
         nuQprnOut( cI+space(10)+DollarSayer( nAmt ) )
         nuQprnOut()
         nuQprnOut()
      otherwise
         for n := 1 to 3
            if len( aRay ) >= n
               nuQprnOut( cI+space(10)+aRay[n] )
            else
               nuQprnOut()
            endif
         next
      endcase
   endif

   // ?
   // ?
	// PrnAtSay( nLine +2,6  , TempCheq->NUMBER  , '9999' )
   nuQprnOut( cI+space(10) + cName )
   nuQprnOut( cI+space(10) + Grower->STREET )
   nuQprnOut( cI+space(10) + Grower->CITY  )
   nuQprnOut( cI+space(10) + Grower->PCODE )

return( nil )

static function SoAlderCheque( lReal, dDate )
	local nLine, nAmt, cName
	local cI
	local n
   local aRay

   Grower->(OrdSetFocus( GROWER_NUMBER_ORD))
	Grower->(dbSeek( str(TempCheq->number,FLD_GROWER)) )

	if lReal
		nAmt := TempCheq->amount
		cName := padr(Grower->cheqName,FLD_NAME)
	else
		nAmt := 0
		cName := padr('* * * VOID * * *',FLD_NAME)
	endif
	msgLine(cName)

	nLine:= sysValue( SYS_CHEQUE_1ST_LINE )
	cI   := space(sysValue( SYS_CHEQUE_LEFT_INDENT ))

	setPrc(0,0)
	for n := 1 to nLine
      nuQprnOut()
	next

   nuQprnOut( cI+space(65)+ transform(TempCheq->cheque, '999999') )

   nuQprnOut()
   if SysValue( SYS_CHEQUE_DOLLAR_FORMAT ) == 1
      nuQprnOut( cI+space(10)+DollarSayer( nAmt ) )
      nuQprnOut()
      nuQprnOut()
   else
      aRay := NumInWords( nAmt, 55 )
      do case
      case len( aRay ) > 3
         nuQprnOut( cI+space(10)+DollarSayer( nAmt ) )
         nuQprnOut()
         nuQprnOut()
      otherwise
         for n := 1 to 3
            if len( aRay ) >= n
               nuQprnOut( cI+space(10)+aRay[n] )
            else
               nuQprnOut()
            endif
         next
      endcase
   endif

   if nAmt > 999999
      nuQprnOut( cI + space(50) + shMDY(dDate)+ ;
       '   $'+ transform( nAmt, '9999999.99') )
   else
      nuQprnOut( cI + space(50) + shMDY(dDate)+ ;
       '   $'+ transform( nAmt, '999,999.99') )
   endif

   nuQprnOut( )
   nuQprnOut( cI+space(10) + cName )
   nuQprnOut( cI+space(10) + Grower->STREET )
   nuQprnOut( cI+space(10) + Grower->CITY  )
   nuQprnOut( cI+space(10) + Grower->PCODE )

return( nil )

static function AdviceSection(lReal, dDate)
   local nLine, nAmt
	local aDbf
	local cI
	local lPrnNext

	if lReal
		nAmt := TempCheq->amount
	else
		nAmt := 0
	endif

	// Bottom section
	nLine := sysValue( SYS_CHEQUE_ADVICE_STARTS )
   // 2BFIXED - maybe Need to Fix this ! Noted May 6, 2010 - FIXED ?
   do while nuPrnRow() < nLine
      nuQprnOut()
	enddo

	cI   := space(sysValue( SYS_CHEQUE_LEFT_INDENT ))
   nuQprnOut( cI+ shMDY(dDate)+' - '+ ;
         padr('Grower: ' + lstrim( TempCheq->number),17) )

   if nAmt > 999999
      nuQQprnOut( padr('Amt $'+ alltrim(transform(nAmt, '9999999.99')),18 )+ ;
			'Cheque# '+ lStrim(TempCheq->cheque)+' '+ ;
          NameOf(LU_CURRENCY,TempCheq->currency) )
   else
      nuQQprnOut( padr('Amt $'+ alltrim(transform(nAmt, '999,999.99')),18 )+ ;
			'Cheque# '+ lStrim(TempCheq->cheque)+' '+ ;
          NameOf(LU_CURRENCY,TempCheq->currency) )
   endif

	// now seek out Account Info
	aDBF := Account->(saveDBF())

   Account->(OrdSetFocus(ACCOUNT_CHEQUE_ORD))
	Account->(dbSeek( TempCheq->series+str(TempCheq->cheque,FLD_CHEQUE), ;
		 HARDSEEK ))

	do while !Account->(eof()) .and. Account->series==TempCheq->series ;
			.and. Account->cheque==TempCheq->cheque

		if str(Account->dollars ,12,3) <> str(0,12,3)
         nuQprnOut( ' '+cI )

			// July 2014 - 2BFIXED
			if pRow() > sysValue( SYS_CHEQUE_FORM_LENGTH )-4
			
				if sysValue( SYS_CHEQUE_SUGGEST_LOOK_AT_STATEMENT )   // this is the default, changed Nov 2022 for Westberry
					nuQQprnOut( 'More transactions - see your statement' )
				endif
				
				exit
			endif

			lPrnNext := .t.
			do case
			case Account->type ==  TT_DEDUCT
            nuQQprnOut(  NameOf(LU_DEDUCTION_CLASS, Account->class) )
				if str(Account->u_price,10,3)<>str(0,10,3) .and. ;
						str(Account->lbs,12)<>str(0,12)
               nuQQprnOut( transform(Account->lbs,'99,999,999') + ;
                  sysValue(SYS_UNITS_OF_WEIGHT) )
               nuQQprnOut( UnitPrDec( Account->u_price ) )
				else
               nuQQprnOut( ' '+Account->desc )
					lPrnNext := .f.
				endif
         case Account->type ==  TT_BERRY_ADVANCE_1
				//                123456789_1 + 10 + 1 + 
            nuQQprnOut( padr('1st Adv to '+substr(shMDY(Account->date),1,6)+' '+ ;
				   NameOf(LU_SHORT_PRODUCT_NAME, Account->product)+ ;
               ' '+Account->process+GradeStr(Account->grade),41) )

            nuQQprnOut( transform(Account->lbs,'99,999,999') + ;
               sysValue(SYS_UNITS_OF_WEIGHT) )
            nuQQprnOut( UnitPrDec( Account->u_price ) )
				lPrnNext := .f.    // don't print comment anyway

         case Account->type ==  TT_BERRY_ADVANCE_2
            nuQQprnOut( padr('2nd Adv to '+substr(shMDY(Account->date),1,6)+' '+ ;
				   NameOf(LU_SHORT_PRODUCT_NAME, Account->product)+ ;
               ' '+Account->process+GradeStr(Account->grade),41) )

            nuQQprnOut( transform(Account->lbs,'99,999,999') + ;
               sysValue(SYS_UNITS_OF_WEIGHT) + UnitPrDec( Account->u_price ) )
				lPrnNext := .f.    // don't print comment anyway

         case Account->type ==  TT_BERRY_ADVANCE_3
            nuQQprnOut( padr('3rd Adv to '+substr(shMDY(Account->date),1,6)+' '+ ;
				   NameOf(LU_SHORT_PRODUCT_NAME, Account->product)+ ;
               ' '+Account->process+GradeStr(Account->grade),41) )

            nuQQprnOut( transform(Account->lbs,'99,999,999') + ;
               sysValue(SYS_UNITS_OF_WEIGHT) + UnitPrDec( Account->u_price ) )
				lPrnNext := .f.    // don't print comment anyway

         case Account->type ==  TT_TIME_PREMIUM
            nuQQprnOut( padr('Time Premium - ' + substr(shMDY(Account->date),1,6)+' '+;
				   NameOf(LU_SHORT_PRODUCT_NAME,Account->product)+ ;
               ' '+Account->process+GradeStr(Account->grade),41) )

            nuQQprnOut( transform(Account->lbs,'99,999,999') + ;
               sysValue(SYS_UNITS_OF_WEIGHT) + UnitPrDec( Account->u_price ))

         case Account->type ==  TT_STD_DEDUCTION
            nuQQprnOut( padr('Marketing Deduction ' + ;
               NameOf(LU_PRODUCT, Account->product), 41) )

            nuQQprnOut( transform(Account->lbs,'99,999,999') + ;
               sysValue(SYS_UNITS_OF_WEIGHT) + UnitPrDec( Account->u_price ))

			case Account->type ==  TT_SPECIAL_BERRY
            nuQQprnOut( padr('Special Payment to '+substr(shMDY(Account->date),1,6)+' '+ ;
				   NameOf(LU_SHORT_PRODUCT_NAME, Account->product)+ ;
               ' '+Account->process+GradeStr(Account->grade),41) )
            nuQQprnOut( transform(Account->lbs,'99,999,999') + ;
               sysValue(SYS_UNITS_OF_WEIGHT) + UnitPrDec( Account->u_price ))

			case Account->type ==  TT_FINAL_BERRY
            nuQQprnOut( padr('Final Paymnt less Advance, '+ ;
					 substr(shMDY(Account->date),1,6)+' '+ ;
				   NameOf(LU_SHORT_PRODUCT_NAME, Account->product)+ ;
               ' '+Account->process+GradeStr(Account->grade),41))
            nuQQprnOut( transform(Account->lbs,'99,999,999') + ;
               sysValue(SYS_UNITS_OF_WEIGHT) + UnitPrDec( Account->u_price ) )

			case Account->type ==  TT_SPECIAL_CONTAINER
            nuQQprnOut( 'Container Charge' )
			case Account->type ==  TT_EQUITY
            nuQQprnOut( 'Equity Payment' )
			case Account->type ==  TT_MISCELLANEOUS
            nuQQprnOut( 'Miscellaneous '+ Account->desc )
				lPrnNext := .f.
         case Account->type ==  TT_GST_TAX
            nuQQprnOut( padr('GST Tax', 41) )
            nuQQprnOut( space(10+2) + MakeBlank( UnitPrDec( Account->u_price ) ))
				
			otherwise
				lPrnNext := .f.
				if empty(Account->desc)
               nuQQprnOut( 'Other' )
				else
               nuQQprnOut( Account->desc )
				endif

				appError(APP_ERR_UNEXPECTED_AC_TYPE, ;
					Account->type )
			endcase

         // 2BFIXED - maybe needs to be Fixed ! - FIXED ?
         do while nuPrnColumn() < 66
            nuQQprnOut( ' ' )
			enddo
			if lReal
            if Account->dollars + Account->gst_est < -999999
               nuQQprnOut( transform(Account->dollars ,'999999999.99') )
            else
               nuQQprnOut( transform(Account->dollars ,'9,999,999.99') )
            endif
			else
            nuQQprnOut( transform( 999999.99   ,   '9,999,999.99') )
			endif

			// print line about why
         if lPrnNext .and. pRow() < sysValue( SYS_CHEQUE_FORM_LENGTH )-5
				if !empty(Account->desc)
               nuQprnOut( ' '+cI+' '+Account->desc )
				endif
			endif
		endif
		Account->(dbSkip())
	enddo

   // 2BFIXED - maybe needs to be FIXED - sb OK
   // do while pRow() < sysValue( SYS_CHEQUE_FORM_LENGTH )
   do while nuPrnRow() < sysValue( SYS_CHEQUE_FORM_LENGTH )
      nuQQprnOut( )
	enddo

	Account->( RestDbf(aDBF) )

return( nil )

static function NiftyAdviceLines(lReal, dDate, aLines )
   local nLine, nAmt
	local aDbf
	local cI
	local lPrnNext
   local nLen

	if lReal
		nAmt := TempCheq->amount
	else
		nAmt := 0
	endif

	// Bottom section
   nLine := sysValue( SYS_CHEQUE_NIFTY_ADVICE_NO_LINES )

	cI   := space(sysValue( SYS_CHEQUE_LEFT_INDENT ))

   if len( aLines) <> 0
      appError( APP_ERR_ADVICE1, ;
      { 'The aLines variable should be set to {}', ;
         'we are correcting.'})

      aLines := {''}
   else
      aadd( aLines,'')
   endif

   aLines[1] :=  cI + shMDY(dDate) + ' - '+  ;
     padr( 'Grower: ' + lstrim(TempCheq->number),17)

   if nAmt > 999999
      aLines[1] += padr(' Amt $'+ alltrim(transform(nAmt, '9999999.99')),18 )
   else
      aLines[1] += padr('Amt $' + alltrim(transform(nAmt, '999,999.99')),18 )
   endif
   aLines[1] +=  'Cheque# '+ lStrim(TempCheq->cheque)+' '+ ;
			 NameOf(LU_CURRENCY,TempCheq->currency)

	// now seek out Account Info
	aDBF := Account->(saveDBF())

   Account->(OrdSetFocus(ACCOUNT_CHEQUE_ORD))
	Account->(dbSeek( TempCheq->series+str(TempCheq->cheque,FLD_CHEQUE), ;
		 HARDSEEK ))

	do while !Account->(eof()) .and. Account->series==TempCheq->series ;
         .and. Account->cheque==TempCheq->cheque

		if Num2NotEqual0(Account->dollars)
         if len( aLines ) >= nLine-1
				if sysValue( SYS_CHEQUE_SUGGEST_LOOK_AT_STATEMENT )   // this is the default, changed Nov 2022 for Westberry 
					aadd( aLines, ' '+cI+ 'More transactions - see your statement...')
				endif
				exit
			endif

         aadd( aLines, ' '+cI )
         nLen := len( aLines )

			lPrnNext := .t.
			do case
			case Account->type ==  TT_DEDUCT
            aLines[nLen] += NameOf(LU_DEDUCTION_CLASS, Account->class)
				if str(Account->u_price,10,3)<>str(0,10,3) .and. ;
						str(Account->lbs,12)<>str(0,12)
               aLines[nLen] +=  transform(Account->lbs,'99,999,999') + ;
						sysValue(SYS_UNITS_OF_WEIGHT)
               aLines[nLen] +=  UnitPrDec( Account->u_price )
				else
               aLines[nLen] +=  ' '+Account->desc
					lPrnNext := .f.
				endif
         case Account->type ==  TT_BERRY_ADVANCE_1
            aLines[nLen] += padr('1st Adv to '+substr(shMDY(Account->date),1,6)+' '+ ;
				   NameOf(LU_SHORT_PRODUCT_NAME, Account->product)+ ;
				   ' '+Account->process+GradeStr(Account->grade),41)

            aLines[nLen] += transform(Account->lbs,'99,999,999') + ;
					sysValue(SYS_UNITS_OF_WEIGHT)
            aLines[nLen] += UnitPrDec( Account->u_price )
				lPrnNext := .f.    // don't print comment anyway

         case Account->type ==  TT_BERRY_ADVANCE_2
            aLines[nLen] +=  padr('2nd Adv to '+substr(shMDY(Account->date),1,6)+' '+ ;
				   NameOf(LU_SHORT_PRODUCT_NAME, Account->product)+ ;
				   ' '+Account->process+GradeStr(Account->grade),41)

            aLines[nLen] +=  transform(Account->lbs,'99,999,999') + ;
					sysValue(SYS_UNITS_OF_WEIGHT)
            aLines[nLen] += UnitPrDec( Account->u_price )
				lPrnNext := .f.    // don't print comment anyway

         case Account->type ==  TT_BERRY_ADVANCE_3
            aLines[nLen] +=  padr('3rd Adv to '+substr(shMDY(Account->date),1,6)+' '+ ;
				   NameOf(LU_SHORT_PRODUCT_NAME, Account->product)+ ;
				   ' '+Account->process+GradeStr(Account->grade),41)

            aLines[nLen] +=  transform(Account->lbs,'99,999,999') + ;
					sysValue(SYS_UNITS_OF_WEIGHT)
            aLines[nLen] +=  UnitPrDec( Account->u_price )
				lPrnNext := .f.    // don't print comment anyway

         case Account->type ==  TT_TIME_PREMIUM
            aLines[nLen] +=  padr('Time Premium - ' + substr(shMDY(Account->date),1,6)+' '+;
				   NameOf(LU_SHORT_PRODUCT_NAME,Account->product)+ ;
				   ' '+Account->process+GradeStr(Account->grade),41)

            aLines[nLen] +=  transform(Account->lbs,'99,999,999') + ;
					sysValue(SYS_UNITS_OF_WEIGHT)
            aLines[nLen] +=  UnitPrDec( Account->u_price )

         case Account->type ==  TT_STD_DEDUCTION
            aLines[nLen] +=  padr('Marketing Deduction ' + ;
				   NameOf(LU_PRODUCT, Account->product), 41)

            aLines[nLen] += transform(Account->lbs,'99,999,999') + ;
					sysValue(SYS_UNITS_OF_WEIGHT)
            aLines[nLen] +=  UnitPrDec( Account->u_price )

			case Account->type ==  TT_SPECIAL_BERRY
            aLines[nLen] += padr('Special Payment to '+substr(shMDY(Account->date),1,6)+' '+ ;
				   NameOf(LU_SHORT_PRODUCT_NAME, Account->product)+ ;
				   ' '+Account->process+GradeStr(Account->grade),41)
            aLines[nLen] += transform(Account->lbs,'99,999,999') + ;
					sysValue(SYS_UNITS_OF_WEIGHT)
            aLines[nLen] += UnitPrDec( Account->u_price )

			case Account->type ==  TT_FINAL_BERRY
            aLines[nLen] += padr('Final Paymnt less Advance, '+ ;
					 substr(shMDY(Account->date),1,6)+' '+ ;
				   NameOf(LU_SHORT_PRODUCT_NAME, Account->product)+ ;
				   ' '+Account->process+GradeStr(Account->grade),41)
            aLines[nLen] += transform(Account->lbs,'99,999,999') + ;
					sysValue(SYS_UNITS_OF_WEIGHT)
            aLines[nLen] += UnitPrDec( Account->u_price )

			case Account->type ==  TT_SPECIAL_CONTAINER
            aLines[nLen] +=  'Container Charge'
			case Account->type ==  TT_EQUITY
            aLines[nLen] +=  'Equity Payment'
			case Account->type ==  TT_MISCELLANEOUS
            aLines[nLen] +=  'Miscellaneous '+ Account->desc
				lPrnNext := .f.
			case Account->type ==  TT_GST_TAX
            aLines[nLen] += 'GST Tax '+alltrim(NameOf( LU_ALL_ACCOUNT_CLASSES, Account->class))				
			otherwise
				lPrnNext := .f.
				if empty(Account->desc)
               aLines[nLen] += 'Other'
				else
               aLines[nLen] +=  Account->desc
				endif

				appError(APP_ERR_UNEXPECTED_AC_TYPE, ;
					Account->type )
			endcase

         aLines[nLen] := padr(aLines[nLen],66)
			if lReal
            if Account->dollars < -999999
               aLines[nLen] += transform(Account->dollars,'999999999.99')
            else
               aLines[nLen] += transform(Account->dollars,'9,999,999.99')
            endif
			else
            aLines[nLen] += transform( 999999.99 , '9,999,999.99')
			endif

			// print line about why
         if lPrnNext .and. len( aLines) < nLine-1
				if !empty(Account->desc)
               aadd( aLines, ' '+cI+' '+Account->desc )
				endif
			endif
		endif
		Account->(dbSkip())
	enddo

   if !lReal .and. len( aLines ) < nLine-1

      do while len( aLines ) < nLine
         aadd( aLines, ' '+cI )
         nLen := len( aLines )

         aLines[nLen] += padr('Special Payment to '+ ;
            substr(shMDY(date()),1,6)+' '+ ;
            'Something...',41)
         aLines[nLen] += transform( 99999,'99,999,999') + ;
            sysValue(SYS_UNITS_OF_WEIGHT)
         aLines[nLen] += UnitPrDec( 1.23 )

         aLines[nLen] := padr(aLines[nLen],66)
         aLines[nLen] += transform( 999999.99 , '9,999,999.99')
      enddo
   endif

	Account->( RestDbf(aDBF) )

return( nil )

/* --------------------  we do not support this one
static function bcBlueCheque( lReal, dDate )
	local nLine, nAmt, cName

   Grower->(OrdSetFocus( GROWER_NUMBER_ORD))
	Grower->(dbSeek( str(TempCheq->number,FLD_GROWER)) )

	if lReal
		nAmt := TempCheq->amount
		cName := padr(Grower->cheqName,FLD_NAME)
	else
		nAmt := 0
		cName := padr('* * * VOID * * *',FLD_NAME)
	endif
	msgLine(cName)

	nLine:=3
	prnAtSay( 1,1, ' ')
//   PrinterCtrl( CHR(27)+'(8U'+CHR(27)+'(s0p10.00h12.0v0s0b3T'+chr(27)+'&l0o')
	PrnAtSay( nLine,70  , TempCheq->cheque  , '999999' )

	nLine +=2
	// IF PrinterInfo(PRN_IS_LASER)
//	PrinterCtrl( CHR(27)+'(1U'+CHR(27)+'(s1p14.4v0s3b4T'+chr(27)+'&l0o')

   if nAmt > 999999
      PrnAtSay( nLine,10  , INT( nAmt )  , '9999999' )
   else
      PrnAtSay( nLine,10  , INT( nAmt )  , '999,999' )
   endif

	PrnAtSay( nLine,18  , "DOLLARS and " )
	PrnAtSay( nLine,30  , ( nAmt - INT(nAmt))*100  , '99' )
	PrnAtSay( nLine,32  , "/100" _
	nLine += 2
	PrnAtSay( nLine,52  , shMDY(dDate) )
	PrnAtSay( nLine,67  , '$' )
   if nAmt > 999999
      PrnAtSay( nLine,68  , nAmt  , '9999999.99')
   else
      PrnAtSay( nLine,68  , nAmt  , '999,999.99')
   endif
	PrnAtSay( nLine+2,6  , TempCheq->NUMBER  , '9999')
	PrnAtSay( nLine+2,12  , cName )
	PrnAtSay( nLine+3,12  , Grower->STREET )
	PrnAtSay( nLine+4,12  , Grower->CITY )
	PrnAtSay( nLine+5,12  , Grower->PCODE )
	nLine := 22      // was 24

	PrnAtSay( nLine,  10  , TempCHeq->cheque  , '999999' )    // changed
	PrnAtSay( nLine+2,10  , dDate  , '@D' )
	PrnAtSay( nLine+4,10  , TempCheq->NUMBER  , '9999' )
	PrnAtSay( nLine+4,30  , cName )

   if nAmt > 999999
      PrnAtSay( nLine+6,10  , nAmt  , '9999999.99' )
   else
      PrnAtSay( nLine+6,10  , nAmt  , '999,999.99' )
   endif

	PrnAtSay( nLine+6,52  , 'Group: '+Grower->payGrp )

	if sysValue(SYS_CHEQUE_PART_THREE)
		nLine := 48
		PrnAtSay( nLine,52    , 'Date:    '+shMDY(dDate) )
      if nAmt > 999999
         PrnAtSay( nLine+1,52  , 'Amount $ '+ transform(nAmt, '9999999.99') )
      else
         PrnAtSay( nLine+1,52  , 'Amount $ '+ transform(nAmt, '999,999.99') )
      endif
		PrnAtSay( nLine+2,12  , 'Grower ID: ' + lstrim(Grower->number) )
		PrnAtSay( nLine+2,52  , 'Cheque No '+ transform(TempCheq->cheque, '999999') )
		PrnAtSay( nLine+3,12  , cName )

		PrnAtSay( nLine+3,52  , NameOf(LU_CURRENCY,TempCheq->currency) )

		PrnAtSay( nLine+4,12  , Grower->STREET )
		PrnAtSay( nLine+5,12  , Grower->CITY )
		PrnAtSay( nLine+5,52  , 'Group: '+Grower->payGrp )
		PrnAtSay( nLine+6,12  , Grower->PCODE )
	endif


return( nil )
---------------------------------------- */

static function DollarSayer( nAmt )
	// put in Aug 99 to fix embarrassing bug.

	local cAmtDollar, cAmtCents
	local cReturn

   if nAmt > 999999
      cAmtDollar := substr( transform( nAmt, '9999999.99' ), 1,7)
   else
      cAmtDollar := substr( transform( nAmt, '999,999.99' ), 1,7)
   endif

   cAmtCents  := substr( transform( nAmt, '9999999.99' ), 9,2)


	cReturn := '$'+alltrim(cAmtDollar)+' and '+cAmtCents+'/100'

return( cReturn )



static function MiniHead( lReal, dDate )
   local nAmt, cName
   local cI := '   '

   Grower->(OrdSetFocus( GROWER_NUMBER_ORD))
	Grower->(dbSeek( str(TempCheq->number,FLD_GROWER)) )

	if lReal
		nAmt := TempCheq->amount
		cName := padr(Grower->cheqName,FLD_NAME)
	else
		nAmt := 0
		cName := padr('* * * VOID * * *',FLD_NAME)
	endif
	msgLine(cName)

	setPrc(0,0)
   nuQprnOut( 'CHEQUE ADVICE INFORMATION for '+  ;
       TempCheq->series+str(TempCheq->cheque,8)  )
   nuQprnOut( )
   if nAmt > 999999
      nuQprnOut( cI + space(40) + shMDY(dDate)+ ;
       '   $'+ transform( nAmt, '9999999.99') )
   else
      nuQprnOut( cI + space(40) + shMDY(dDate)+ ;
       '   $'+ transform( nAmt, '999,999.99') )
   endif

   nuQprnOut()
   nuQprnOut( cI+space(10) + cName )
   nuQprnOut( cI+space(10) + Grower->STREET )
   nuQprnOut( cI+space(10) + Grower->CITY   )
   nuQprnOut( cI+space(10) + Grower->PCODE  )
   nuQprnOut( )

return( nil )




