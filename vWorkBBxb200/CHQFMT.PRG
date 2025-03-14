// PROGRAM ...: ChqFmt.prg
// AUTHOR ....: Bill Hepler
// DATE ......: July 2009
// NOTES .....: Deals with Printing Cheques
//              June 2010 - to deal with Windows Printing

#Include 'bsgstd.ch'
#include 'common.ch'
#include 'inkey.ch'
#include 'window.ch'
#include 'BerryPay.ch'
#include 'browser.ch'
#include 'valid.ch'
#include "indexord.ch"
#include "field.ch"
#include 'sysvalue.ch'
#include 'printer.ch'

static oPS
static oFont := nil // to get rid of warnings
static oOldFont

function ChqNiftyPrn( lReal, dDate )
   local lReturn := .f.
   local aAddress := {}
   local aAmt := {}
   local cTemp
   local nXinch, nYinch, nAmt
   local n
   local aGrower := {}
   local aMsg
   local cName

   Grower->(OrdSetFocus( GROWER_NUMBER_ORD))
	Grower->(dbSeek( str(TempCheq->number,FLD_GROWER)) )

   if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
      oPS := w32oPS()
      oOldFont := graSetFont( oPS )
   endif

   if lReal
		nAmt := TempCheq->amount
      cName   := padr(Grower->cheqName,FLD_NAME)
      aGrower := {}
      if !empty( Grower->street )
         aadd( aGrower, alltrim(Grower->street))
      endif

      if !empty( Grower->street2 )
         aadd( aGrower, alltrim(Grower->street2))
      endif

      if !empty( Grower->city )
         aadd( aGrower, alltrim(Grower->city)+' '+  ;
                        alltrim(Grower->prov)+'  '+alltrim(Grower->pcode) )
      endif
	else
      nAmt    := 123456.78
      cName   := padr('VOID CHEQUE - grower Name here',FLD_NAME)
      aGrower := { 'Suite 321', ;
                   '123 VOID Ave South', ;
                   'Void Cheque, BC   V6Z 1K2'}
	endif

   aMsg := msgLine(cName+'  for '+str(nAmt,10,2  ) )

   if cfPrinter( CHQ_FORMAT_ID_OUR_NAME     )
      nXinch := ChqFmt->xInch
      nYinch := ChqFmt->yInch
      if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
         W32PrnTextArray( ;
          { alltrim( TheClientName( ) ) }, ;
            nXinch, nYinch, 1/6 )
      else
         hpAbsPrnPosition( nXinch , nYinch )
         nuQQprnOut( alltrim( TheClientName( ) ) )
      endif
   endif

   if cfPrinter( CHQ_FORMAT_ID_OUR_ADDRESS  )
      nXinch := ChqFmt->xInch
      nYinch := ChqFmt->yInch
      aAddress := {}
      cTemp := sysValue( SYS_ACTUAL_ADDRESS1 )
      if !empty( cTemp )
         aadd( aAddress, cTemp )
      endif
      cTemp := sysValue( SYS_ACTUAL_ADDRESS2 )
      if !empty( cTemp )
         aadd( aAddress, cTemp )
      endif
      cTemp := sysValue( SYS_ACTUAL_ADDRESS3 )
      if !empty( cTemp )
         aadd( aAddress, cTemp )
      endif
      cTemp := sysValue( SYS_ACTUAL_PHONE )
      if !empty( cTemp )
         aadd( aAddress, cTemp )
      endif

      if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
         W32PrnTextArray( aAddress, nXinch, nYinch, 1/6 )
      else
         for n:=1 to len( aAddress )
            hpAbsPrnPosition( nXinch , nYinch )
            nuQQprnOut( aAddress[n] )
            nYinch += 1/6
         next
      endif
   endif

   if cfPrinter( CHQ_FORMAT_ID_GROWER_NAME     )
      nXinch := ChqFmt->xInch
      nYinch := ChqFmt->yInch
      if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
         W32PrnTextArray( { cName }, nXinch, nYinch, 1/6 )
      else
         hpAbsPrnPosition( nXinch , nYinch )
         nuQQprnOut( cName )
      endif
   endif

   if cfPrinter( CHQ_FORMAT_ID_GROWER_ADDRESS  )
      nXinch := ChqFmt->xInch
      nYinch := ChqFmt->yInch

      if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
         W32PrnTextArray( aGrower, nXinch, nYinch, 1/6 )
      else
         for n:=1 to len( aGrower )
            hpAbsPrnPosition( nXinch , nYinch )
            nuQQprnOut( aGrower[n] )
            nYinch += 1/6
         next
      endif
   endif

   if cfPrinter( CHQ_FORMAT_WORD_TO_ORDER_OF )
      nXinch := ChqFmt->xInch
      nYinch := ChqFmt->yInch
      if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
         W32PrnTextArray( {'TO THE','ORDER','OF'} , nXinch, nYinch, 1/6 )
      else
         hpAbsPrnPosition( nXinch , nYinch )
         nuQQprnOut( 'TO THE' )
         nYinch += 1/6
         hpAbsPrnPosition( nXinch , nYinch )
         nuQQprnOut( 'ORDER' )
         nYinch += 1/6
         hpAbsPrnPosition( nXinch , nYinch )
         nuQQprnOut( 'OF')
      endif
   endif

   if cfPrinter( CHQ_FORMAT_ID_AMOUNT_AS_NUM  )
      nXinch := ChqFmt->xInch
      nYinch := ChqFmt->yInch
      do case
      case sysValue(SYS_CHEQUE_NIFTY_DOLLAR_FORMAT)==1
         cTemp := '$ '+ alltrim(transform(nAmt, '999,999.99'))
      case sysValue(SYS_CHEQUE_NIFTY_DOLLAR_FORMAT)==2
         cTemp := alltrim(transform(nAmt, '999,999.99'))
      case sysValue(SYS_CHEQUE_NIFTY_DOLLAR_FORMAT)==3
         cTemp := alltrim(transform(nAmt, '999999.99'))
      endcase

      if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
         W32PrnTextArray( {cTemp} , nXinch, nYinch, 1/6 )
      else
         hpAbsPrnPosition( nXinch , nYinch )
         nuQQprnOut( cTemp )
      endif
   endif

   if cfPrinter( CHQ_FORMAT_ID_AMOUNT_AS_TEXT )
      // aAmt   := NumInWords( nAmt, 65 )
      aAmt   := NumInWords( nAmt, sysValue( SYS_CHEQUE_NIFTY_AMT_IN_WORD_LEN))

      nXinch := ChqFmt->xInch
      nYinch := ChqFmt->yInch
      if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
         W32PrnTextArray( aAmt, nXinch, nYinch, 1/6 )
      else
         for n:=1 to len( aAmt )
            hpAbsPrnPosition( nXinch , nYinch )
            nuQQprnOut( aAmt[n] )
            nYinch += 1/6
         next
      endif
   endif

   if cfPrinter( CHQ_FORMAT_DATE  )
      nXinch := ChqFmt->xInch
      nYinch := ChqFmt->yInch
      do case
      case sysValue( SYS_CHEQUE_NIFTY_DATE_FORMAT ) == 1
         // YYYYmmDD
         cTemp := dtos( dDate )
      case sysValue( SYS_CHEQUE_NIFTY_DATE_FORMAT ) == 2
         // DDmmYYYY
         cTemp := substr( dtos(dDate), 7,2) + ;
                  substr( dtos(dDate), 5,2) + ;
                  substr( dtos(dDate), 1,4)
      case sysValue( SYS_CHEQUE_NIFTY_DATE_FORMAT ) == 3
         // MMddYYYY
         cTemp := substr( dtos(dDate), 5,2) + ;
                  substr( dtos(dDate), 7,2) + ;
                  substr( dtos(dDate), 1,4)
      otherwise
         cTemp := dtos( dDate)
      endcase

      if len( cTemp ) <> 8
         cTemp := padr( cTemp, 8)
      endif
      for n := 1 to 8
         if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
            W32PrnTextArray( {substr(cTemp,n,1)}, nXinch, nYinch, 1/6 )
         else
            hpAbsPrnPosition( nXinch , nYinch )
            nuQQprnOut( substr(cTemp,n,1) )
         endif
         nXinch +=  sysValue( SYS_CHEQUE_NIFTY_DATE_DISTANCE )
           // 7/24    // less than 2/6
      next
   endif

   if cfPrinter( CHQ_FORMAT_WORD_DATE  )
      nXinch := ChqFmt->xInch
      nYinch := ChqFmt->yInch

      if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
         W32PrnTextArray( {'DATE'}, nXinch, nYinch, 1/6 )
      else
         hpAbsPrnPosition( nXinch , nYinch )
         nuQQprnOut( 'DATE')
      endif
   endif

   if cfPrinter( CHQ_FORMAT_YMD               )
      nXinch := ChqFmt->xInch
      nYinch := ChqFmt->yInch
      do case
      case sysValue( SYS_CHEQUE_NIFTY_DATE_FORMAT ) == 1
         cTemp := 'YYYYMMDD'
      case sysValue( SYS_CHEQUE_NIFTY_DATE_FORMAT ) == 2
         cTemp := 'DDMMYYYY'
      case sysValue( SYS_CHEQUE_NIFTY_DATE_FORMAT ) == 3
         cTemp := 'MMDDYYYY'
      otherwise
         cTemp := 'YYYYMMDD'
      endcase

      for n := 1 to 8
         if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
            W32PrnTextArray( {substr(cTemp,n,1)}, nXinch, nYinch, 1/6 )
         else
            hpAbsPrnPosition( nXinch , nYinch )
            nuQQprnOut( substr(cTemp,n,1) )
         endif
         nXinch += sysValue( SYS_CHEQUE_NIFTY_DATE_DISTANCE )
         // nXinch += 7/24
      next
   endif
   rest_scr( aMsg )

   if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
      graSetFont( oPS, oOldFont )
      if valType( oFont ) == 'O'
         oFont:destroy()
         oFont := NIL
      endif
   endif

return( lReturn )

static function cfPrinter( cID )
   local lReturn := .f.
   local  nTypeFace, cSymbol,lFixed,nDarkness, nPitch

   if validTest(  V_CHEQUE_FORMAT_ID, cID, VT_NO_MESSAGE )
      if ChqFmt->PRINTTHIS
         if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
            if !empty( ChqFmt->w32Font )
               oFont := xBpFont( ):new( oPS )
               oFont:create( alltrim( ChqFmt->w32Font ))
               GraSetFont( oPS, oFont )
               lReturn := .t.
               // not needed, we are going to Specify anyway
               // W32PrnText( '', ChqFmt->xInch, ChqFmt->yInch )
            endif
         else
            nTypeFace :=  ChqFmt->TYPEFACE
            cSymbol   :=  alltrim( ChqFmt->Symbol )
            lFixed    :=  ChqFmt->isFixed
            nDarkness :=  ChqFmt->darkness
            nPitch    :=  ChqFmt->pitch   // CPI
            if !empty( cSymbol   ) .and. nPitch > 3 .and. ChqFmt->yInch > 0 ;
                    .and. ChqFmt->xInch >= 0
               hpSetFontStuff( nTypeFace, cSymbol,lFixed,nDarkness, nPitch)
               // x, y
               hpAbsPrnPosition( ChqFmt->xInch , ChqFmt->yInch )
               lReturn := .t.
            endif
         endif
      endif
   endif

return( lReturn )

function ChqFmtEdit( lOpen )
   local  getlist :={}, aWin
   local  nChoice := 1
   local oTb
   local cPrn
   local aUiPrn := UI_PRN_ARRAY

   default lOpen to .t.

   if lOpen
      if !openFile({'CHQFMT'},DB_EXCLUSIVE)
         close databases
         return( nil )
      endif
   endif

   if select('CHQFMT') == 0
     WaitHand({'Can not open CHQFMT'})
     return( nil )
   endif

   WaitInfo({'You need to select a printer that', ;
             'you expect to print cheques to in order', ;
             'for the Formatter to determine what Fonts', ;
             'are available'})

   if uiChooseWin32Prn( aUiPrn )
      cPrn := aUiPrn[ UI_PRN_PRINTER_NAME ]
      if empty( cPrn )
         close databases
         return( nil )
      endif
   else
      close databases
      return( nil )
   endif


   cfInputter()

   oTb := tBrowCreate(7,2,16)
   tbColAdd( oTb, tbcolCreate('ID', ;
         {|| ChqFmt->ID }) )
   tbColAdd( oTb, tbcolCreate('Prn?', ;
        { || iif( ChqFmt->printThis, ' Yes ',' -N- ') }))
   tbColAdd( oTb, tbcolCreate('Notes', ;
        { ||  substr(ChqFmt->note,1,20)  }))

   tbColAdd( oTb, tbcolCreate('Fr Right', ;
      {|| iif( ChqFmt->xInch>0, str(ChqFmt->xInch, 9,4),padc('n/a',9) )}) )
   tbColAdd( oTb, tbcolCreate('From Top', ;
      {|| iif( ChqFmt->yInch>0, str(ChqFmt->yInch, 9,4),padc('n/a',9) )}) )

   myBsgScreen('Edit Cheque Format (Nifty Cheque)')

   create window at 4,02,22,75 title 'Cheque Info Formatter' to aWin
	display window aWin

   ChqFmt->(dbGoTop())
   ChqFmt->(theBrowse(oTb))
   if lastkey()==K_ENTER
      nChoice := 1

      DO WHILE .t.
         in window aWin @ 1,02 winsay 'ID: ' + ChqFmt->id
         do case
         case ChqFmt->id == CHQ_FORMAT_WORD_PAY
            in window aWin @ 2,02 winsay  ;
             padr('Prints the word PAY - s.b. in front of '  ;
               + CHQ_FORMAT_ID_AMOUNT_AS_TEXT+')',60)
         case ChqFmt->id == CHQ_FORMAT_WORD_TO_ORDER_OF
            in window aWin @ 2,02 winsay  ;
             padr('Prints TO THE ORDER OF in 3 lines',60)
         case ChqFmt->id == CHQ_FORMAT_WORD_DATE
            in window aWin @ 2,02 winsay  ;
             padr('Prints the word DATE - s.b. in front of '  ;
               + CHQ_FORMAT_YMD+')',60)
         otherwise
            in window aWin @ 2,02 winsay space( 60)
         endcase

         in window aWin @ 3,2 winsay 'Note (to Self)' winget ChqFmt->note ;
           get_message 'Note to your self on this field'

         in window aWin @ 4,2 winsay 'Print this Data?' winget ChqFmt->printThis ;
           picture 'Y' get_message 'Print this Data on the Cheque?'

			in window aWin @ 5,2 winsay 'Select Font:' winget ChqFmt->w32Font ;
          lookup(LU_WIN_ANY_WIN_FONT, 'Font for this item', cPrn )

//      in window aW @6,03 winsay 'Font   ' ;
//         winget aStation[STN_WIN32_TICKET_FONT] ;
//         LOOKUP(LU_WIN_DEFA_FONT, ;
//         'Default Font for Ticket (if using)', ;
//           aStation[STN_WIN32_TICKET_PRINTER] )


			// hold over from DOS - not needed
			in window aWin @ 7,01 winsay ;
			 'Info below applies ONLY when treating printer as Line Printer'

         in window aWin @ 8,02 winsay "Typeface (font):" winget ChqFmt->TYPEFACE ;
           get_message 'Enter the TypeFace'
         in window aWin @ 9,03 winsay ;
            '0=LinePrinter,2=Elite,3=Courier,4=Helvetica,8=Prestige,4099-Courier'
         in window aWin @10,03 winsay  ;
            '4101=CG Times,4148=Universal,16602-Arial -- use 4 for CHEQUE $ amt'

         in window aWin @ 11,02 winsay "Pitch (in CPI):" winget ChqFmt->pitch ;
           get_message 'Enter the Pitch - 8,10 or 12 are usually best'
         in window aWin @ 12,2 winsay 'Symbol Set:' winget ChqFmt->symbol ;
           get_message 'Usually 10U, the PC-8 set is best'
         in window aWin @ 13,3 winsay '8U = HP Roman-8  10U = PC-8   0U = ASCII'
         in window aWin @ 14,3 winsay '1U = US Legal    19U = Windows ANSI'

         in window aWin @ 15,2 winSay "Fixed Spacing:" winget ChqFmt->isfixed ;
            picture 'Y' get_message 'Must match TypeFace!'
         in window aWin @ 16,3 winsay ;
            'Y=Fixed Spacing, N=Proportionate Spacing -- must agree with font!'

         in window aWin @ 17,2 winsay 'Darkness:' winget ChqFmt->darkness ;
          picture '99' ;
           get_message '-7 is light, 0 normal, 7 very dark'

         in window aWin @ 18,2 winsay 'Print Location from Right, Top'
         in window aWin @ 18,33 winget ChqFmt->xInch picture '99.9999' ;
           get_message 'Print at X inches from Left of PRINTABLE PAGE'

         in window aWin @ 18,43 winget ChqFmt->yInch picture '99.9999' ;
           get_message 'Print at Y inches from Top of PRINTABLE PAGE'


         if nChoice == 1
            read
            if lastkey() == K_ESC
               nChoice := 0
            endif
         else
            thinWait('Viewing')
         endif

         if nChoice <> 0
            nChoice := thinChoice({'Edit','View','Back','Forward','X-eXit'})
         endif

         do case
         case nChoice == 0 .or. nChoice == 5
            oTb:Invalidate()
            ChqFmt->(theBrowse(oTb))
            if lastkey() == K_ESC
               exit
            else
               nChoice := 1
            endif
         case nChoice == 3
            if ChqFmt->(bof())
               waitInfo({'At start of List!'})
            else
               ChqFmt->(dbSkip( - 1))
            endif
            nChoice := 2
         case nChoice == 4
            if ChqFmt->(eof())
               waitInfo({'At end of List!'})
            else
               ChqFmt->(dbSkip( 1 ))
               if ChqFmt->(eof())
                  waitInfo({'At end of List!'})
                  ChqFmt->( dbSkip( -1 ) )
               endif
            endif
            nChoice := 2
         endcase
      enddo
   endif

   kill Window aWin

   if !lOpen
      close databases
   endif

RETURN(nil)


static function cfInputter( ) // cID  )

   TheAdder( CHQ_FORMAT_ID_OUR_NAME     )
   TheAdder( CHQ_FORMAT_ID_OUR_ADDRESS  )

   TheAdder( CHQ_FORMAT_ID_GROWER_NAME     )
   TheAdder( CHQ_FORMAT_ID_GROWER_ADDRESS  )
   TheAdder( CHQ_FORMAT_WORD_TO_ORDER_OF  )

   TheAdder( CHQ_FORMAT_ID_AMOUNT_AS_NUM  )
   TheAdder( CHQ_FORMAT_ID_AMOUNT_AS_TEXT )
   TheAdder( CHQ_FORMAT_WORD_PAY          )

   TheAdder( CHQ_FORMAT_DATE              )
   TheAdder( CHQ_FORMAT_WORD_DATE         )
   TheAdder( CHQ_FORMAT_YMD               )


return( nil )

static function TheAdder( cID )
   local lReturn := .f.

   if validTest( V_CHEQUE_FORMAT_ID, cID, VT_NO_MESSAGE )
      lReturn := .t.
   else
		ChqFmt->(addRecord())
      ChqFmt->id       := cID
      ChqFmt->SYMBOL   := '10U'
      ChqFmt->pitch    := 10
      ChqFmt->typeFace := 3
      ChqFmt->isFixed  := .t.

      ChqFmt->(dbCommit())
      lReturn := .t.
   endif

return( lReturn )

/*--------------------
      in window aW @5,03 winsay 'Printer' ;
            winget aStation[STN_WIN32_TICKET_PRINTER] ;
            valid ValidTest(V_WIN_PRINTERS, ;
               aStation[STN_WIN32_CASH_TICKET_PRINTER], VT_BLANK_OK_MESSAGE) ;
            LOOKUP(LU_WIN_PRINTERS, ;
               'Windows Printer Name to print tickets (blank if not using)')

      in window aW @6,03 winsay 'Font   ' ;
         winget aStation[STN_WIN32_TICKET_FONT] ;
         LOOKUP(LU_WIN_DEFA_FONT, ;
           'Default Font for Ticket (if using)', ;
           aStation[STN_WIN32_TICKET_PRINTER] )
-------------- */
