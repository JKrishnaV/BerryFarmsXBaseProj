// from Fish COOP 1993
// (c) 1988-2009, 2016 by Bill Hepler & Crafted Industrial Software Ltd.
//  really irrelevant now.

// 2BFIXED  - needs some protection on it

#include 'common.ch'
#include 'printer.ch'
#Include 'inkey.ch'
#include 'bsgstd.ch'
#include 'window.ch'
#include 'errors.ch'

static cEsc := ''
static nErrs := 0

static Function hpPc8()
	// @ pRow(),pCol() Say Chr(27) + "(10U"
	// Nov 98 force it to US Character set with Underlines
	@ pRow(),pCol() Say cEsc + Chr(27) + "(11U"
Return(NIL)

static Function hpPitch10()
    PrinterCtrl( cEsc + '\027' + "&k0S" )
Return( nil )

// Function hpSixLinesPer()
//    PrinterCtrl( cEsc + '\027' + "&l6D" )
// Return(NIL)

Function hpHalfLineFeed( ) // nR)
   PrinterCtrl(  cEsc + '\027' + "=" )
Return(NIL)

Function hpAbsPrnPosition(  nXinch , nYinch )
   local nDeciPoints  //  1/720 of Inch

   if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
      nErrs++
      if nErrs < 5
         appError( APP_ERR_HP_CALLED_1, ;
           {'Program is calling LINE PRINTER style commands', ;
            'when it should be calling Windows commands',  ;
            'We only call this routine 5x'})
      endif
   else
      nDeciPoints :=   nXinch * 720    // horizontal=2 decimal places
      PrinterCtrl(  cEsc + '\027' + "&a"+ lStrim(nDeciPoints) +"H" )

      nDeciPoints :=  nYinch * 720     // vertical=4 decimal places
      PrinterCtrl(  cEsc + '\027' + "&a"+ lStrim(nDeciPoints) +"V" )
   endif
return(nil)

Function hpRelVertAdvance(cInc)
   // local nRow,nCol

   PrinterCtrl(  cEsc + '\027' + "&a+"+ allTrim(cInc) +"V" )
return( nil )

Function hpPc8Io()
   PrinterCtrl( cEsc + '\027' + "(10U" )
Return(NIL)



function hpPortrait( )
   // this is first command, need extra ESC ??
   PrinterCtrl( '\027'+ '\027' + "&l0O" )

   if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
      nErrs++
      if nErrs < 5
         appError( APP_ERR_HP_CALLED_2, ;
           {'Program is calling LINE PRINTER style commands', ;
            'when it should be calling Windows commands',  ;
            'We only call this routine 5x'})
      endif
   endif
return( nil )

Function hpPortLtr()
   hpPortrait()
   hpLetterSize()
return( nil )

Function hpLetterSize()
   PrinterCtrl( cEsc + '\027' + "&l2A" )
Return( nil )


//Function SetLegalPaper()
Function hpLegalSize()
   PrinterCtrl( cEsc + '\027' + "&l3A" )
Return(NIL)

// Function Land_Scp()
function hpLandLetter()
   PrinterCtrl( cEsc + '\027' + "&l2A" )       // Letter
   PrinterCtrl( cEsc + '\027' + "&l1O" )       // landscape
Return(NIL)


Function SetManualFeed()
   PrinterCtrl( cEsc + '\027' + "&l2H" )
Return(NIL)



Function hpSetTopMargin(cLine)
   PrinterCtrl( cEsc + '\027' + "&l"+cLine+"E" )
Return(NIL)

Function hpMicroFeed(cInc)
   PrinterCtrl( cEsc + '\027' + "&a"+ cInc +"V" )
return(nil)


Function hpLine8
   PrinterCtrl( cEsc + '\027' + "&l8D" )
Return(.t.)


Procedure hpPitch12
   PrinterCtrl( cEsc + '\027' + chr(40) + chr(115) + "#12#" + chr(72) )
Return


Function hpNormBold
   PrinterCtrl( cEsc + '\027' + "(s3B" )
Return(.t.)



function HPtoDefaFont()
   hpPc8()                  // normal Symbol Set
   hpPitch10()              // 10 cpi
   PrinterCtrl( cEsc+ '\027(s0T' )  // back to Line Printer
   PrinterCtrl( cEsc+ '\027(s0P' )  // back to Fixed Form
   PrinterCtrl( cEsc +'\027(s0B' )  // back to normal font weight
return( nil )

function hpTestFontSets()
   // local nCol
   local aFont[3], aFixed[3], aDark[3], aSymbol[3], aPitch[3]
   local n
   local getList := {}
   local cTemp,cMsg
   // local nXinch,nYinch
   local aWin

   bsgScreen('Test HP Printer Fonts for Cheque Printing')
   create window at 4,02,22,75 title 'Test HP Laser' to aWin
	display window aWin

   aFill( aFont, 0)
   aFill( aPitch, 10)
   aFill( aFixed, .t.)
   aFill( aDark, 0)
   aFill( aSymbol,space(3))

   do while .t.
      in window aWin @ 1,02 winsay "Typeface (font):"
      for n := 1 to 3
         in window aWin @ 1,20+(n*10) winget aFont[n] picture '99999'
      next
      in window aWin @ 2,3 winsay ;
         '0=LinePrinter,2=Elite,3=Courier,4=Helvetica,8=Prestige,4099-Courier'
      in window aWin @ 3,3 winsay  ;
      '4101=CG Times,4148=Universal,16602-Arial'

      in window aWin @ 4,02 winsay "Pitch (in CPI):"
      for n := 1 to 3
         in window aWin @ 4,20+(n*10) winget aPitch[n] picture '99'
      next

      in window aWin @ 6,2 winsay 'Symbol Set:'
      for n := 1 to 3
         in window aWin @ 6,20+(n*10) winget aSymbol[n] picture '9!!'
      next
      in window aWin @  7,3 winsay '8U = HP Roman-8  10U = PC-8   0U = ASCII'
      in window aWin @  8,3 winsay '1U = US Legal    19U = Windows ANSI'

      in window aWin @ 10,2 winSay "Fixed Spacing:"
      for n := 1 to 3
         in window aWin @ 10,20+(n*10) winget aFixed[n] picture 'Y'
      next
      in window aWin @ 11,3 winsay ;
         'Y=Fixed Spacing, N=Proportionate Spacing -- must agree with font!'

      in window aWin @ 13,2 winsay 'Darkness:'
      for n := 1 to 3
         in window aWin @ 13,20+(n*10) winget aDark[n] picture '99'
      next
      in window aWin @ 14,3 winsay ;
        'Choose from -7=very thin to 0=Normal to 7=very dark'

      in window aWin @ 16,2 winsay ;
         'Some settings, such as Fixed Spacing, and Darkness may conflict with'
      in window aWin @ 17,2 winsay ;
         'TypeFace. This means that some combinations will not work as expected!'
      in window aWin @ 18,2 winsay ;
         'The availability of these type faces varies from printer to printer!'

      read
      if lastkey()==K_ESC
         exit
      endif

      for n := 1 to len( aSymbol)
         if !isAlpha( right( alltrim(aSymbol[n]),1))
            waitInfo({'Symbols must end with capital letter'})
         endif
      next

      If SelectPrn("TEST.TXT")
         PRINT_ON RPT_OVERWRITE

         hpPortLtr()
         HPtoDefaFont()

         nuQprnOut()
         nuQprnOut()
         nuQprnOut( shMdy(date())+padc('Test FONTS and Spacing',56)+time() )
         nuQPrnOut()

         for n := 1 to 3
            // What are we Printing...
            cTemp := ''
            cMsg  := ''

            do case
            case aFont[n]==0
               cTemp := 'LinePrinter'
            case aFont[n]==2
               cTemp := 'Elite'
            case aFont[n]==3
               cTemp := 'Courier'
            case aFont[n]==4
               cTemp := 'Helvetica'
            case aFont[n]==8
               cTemp := 'Prestige'
            case aFont[n]==4099
               cTemp := "Courier Scalable"
            case aFont[n]==4101
               cTemp := 'CG Times'
            case aFont[n]==4148
               cTemp := 'Universal'
            case aFont[n]==16602
               cTemp := 'Arial'
            otherwise
               cTemp := 'TypeFace ='
            endcase
            cTemp += ' ('
            cTemp += lStrim(aFont[n])
            cTemp += '), '

            do case
            case alltrim(aSymbol[n])=='8M'
               cTemp += 'HP Math-8'
               case alltrim(aSymbol[n])=='8U'
               cTemp += 'HP Roman-8'
            case alltrim(aSymbol[n])=='10U'
               cTemp += 'PC-8'
            case alltrim(aSymbol[n])=='8M'
               cTemp += 'HP Math-8'
            case alltrim(aSymbol[n])=='0U'
               cTemp += 'ASCII'
            case alltrim(aSymbol[n])=='0N'
               cTemp += 'ISO 8859-1 Latin 1'
            case alltrim(aSymbol[n])=='1U'
               cTemp += 'HP US Legal'
            case alltrim(aSymbol[n])=='19U'
               cTemp += 'Windows ANSI'
            otherwise
               cTemp += 'Symbol Set'
            endcase
            cTemp += ' ('
            cTemp += alltrim(aSymbol[n])
            cTemp += '), '

            if aFixed[n]
               cTemp += 'Fixed, Darkness='
            else
               cTemp += 'Proportionate, Darkness='
            endif

            cTemp += lStrim( aDark[n])

            cTemp += ' Pitch='+lstrim(aPitch[n])

            cMsg :=  ;
                hpSetFontStuff( ;
                   aFont[n], aSymbol[n], aFixed[n],aDark[n],aPitch[n] )

            // We do this twice, when we do it ONCE we don't seem
            // to actually get the Font Set...
            hpSetFontStuff( ;
                 aFont[n], aSymbol[n], aFixed[n], aDark[n], aPitch[n] )

            NiftyFont( cTemp,cMsg )
         next

         nuQprnOut()
         nuQprnOut( '-- Note positions are from PRINTABLE part of page --' )

         // hpAbsPrnPosition(  nXinch , nYinch )
         hpAbsPrnPosition(  1.5 , 0.25 )
         nuQQprnOut( 'X=1.5" Y=0.25"' )

         hpAbsPrnPosition(  5 , 9 )
         nuQQprnOut( 'X=5" Y=9"' )

         HPtoDefaFont()

         nuQprnOut()
         nuQprnOut( "End")
         PRINT_OFF  RPT_COMPLETE_EJECT

      Endif
   enddo

   kill window aWin

return( nil )



function hpSetFontStuff( nTypeFace,cSymbol,lFixed,nDarkness, nPitch)
   local cMsg    := ''
   local cReturn := ''

   cMsg  :=  cEsc+ '\027(s'+lStrim(nTypeFace)+'T'
   cReturn := cMsg+' '
   PrinterCtrl( cMsg )

   cMsg := cEsc+ '\027('+alltrim(cSymbol)
   PrinterCtrl( cMsg )
   cReturn += cMsg+' '

   if lFixed
      cMsg := cEsc+ '\027(s0P'   // to Fixed Form
   else
      cMsg := cEsc+ '\027(s1P'   // Proprotionate
   endif
   PrinterCtrl(cMsg)
   cReturn += cMsg+' '

   cMsg := cEsc +'\027(s'+lStrim(nDarkness)+'B'
   PrinterCtrl(cMsg)
   cReturn += cMsg+' '

   cMsg := cEsc +'\027(s'+lStrim(nPitch)+'H'
   PrinterCtrl(cMsg)
   cReturn += cMsg+' '

   // Sends it a Second Time, it does not always take the first time
   inkey()
   PrinterCtrl(cMsg)

return( cReturn )


static function NiftyFont(cDesc, cMsg)

   nuQprnOUt()
   nuQprnOUt( cDesc )
   nuQprnOUt( ' '+cMsg )
   nuQprnOUt()
   nuQprnOUt( '         1         2         3         4         5         6         7')
   nuQprnOUt( '1234567890123456789012345678901234567890123456789012345678901234567890')
   nuQprnOUt('')
   nuQprnOUt('abcdefghijklmnopqrstuvwxyz  '+ upper('abcdefghijklmnopqrstuvwxyz') )
   nuQprnOUt('!@#$%^&*()_+   {}[]  <>? ,./   |\             Dollar Sign: $')
   nuQprnOUt()

return( nil )

