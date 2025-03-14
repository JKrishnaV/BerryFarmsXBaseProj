// --------------------------------------------------------------------------
//   Application: Berry Pay
//   Description: Continuity Summary
//     File Name: RecptSum.PRG
//        Author: Bill Hepler
//  Date created: 07/03/02              Time created: 09:19:49 pm
//  Rev:   July 16, 2013 - Look at Depot + Recpt No
//
//     Copyright: (c) 2002, 2013 by Bill Hepler
// --------------------------------------------------------------------------

#include "window.ch"
#include "printer.ch"
#include "BerryPay.ch"
#include "bsgstd.ch"
#include "inkey.ch"
#include "indexord.ch"
#include "field.ch"
#include "SumRptBld.ch"
#include "valid.ch"


// consider multi depots

function RecptSum()
   local dDate1, dDate2
	local getList := {}
	local aWin
   local cFile,cDepot
   local nPage
   local nRecpt
   local nImportBat
   local dDate
   local aNote
   local lNotePrev
   local n

	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

   myBsgScreen( 'Ticket Continuity Summary' )

   create window at 5,06,15,73 title 'Ticket Continuity Summary' to aWin
	display window aWin

	dDate1 := FirstOfYear( date() )
	dDate2 := date()

   in window aWin @ 6,2 winsay ;
     'This report tests for Continuity of Receipt Numbers'
   in window aWin @ 7,2 winsay ;
     'It notes apparant duplicates, out of date order'
   in window aWin @ 8,2 winsay ;
     'and out of Import Order transactions.'

   do while .t.
		in window aWin @ 2,2 winsay 'From' winget dDate1 picture '@D' ;
         get_message 'Enter of starting date to check'
		in window aWin @ 3,2 winsay ' to ' winget dDate2 picture '@D' ;
         get_message 'Enter of ending date to check'

      read

      if lastkey()==K_ESC
         exit
      endif

      if selectPrn('CONTSUM.TXT')
         cFile := UniqueFile()

         msgLine('Working away on Daily...')
         Daily->(OrdSetFocus(DAILY_DATE_ORD))

         // want the YTD !
         Daily->(dbSeek( dtos(dDate1), SOFTSEEK ))
         dbSelectAr('Daily' )

         // index on str( Daily->recpt,FLD_RECPT) ;
         //      to (cFile) while Daily->date<= dDate2

         index on Daily->depot + str( Daily->recpt,FLD_RECPT) ;
               to (cFile) while Daily->date<= dDate2

         Daily->(dbGoTop())
         msgLine('Computing...')

         nPage:=1

         PRINT_ON  RPT_OVERWRITE
         PrinterCtrl( PRN_CTRL_10_CPI )

         Heading( nPage, dDate1, dDate2)

         dDate       := Daily->date
         nImportBat  := Daily->imp_bat
         nRecpt      := Daily->recpt
         cDepot      := Daily->depot

         nuQprnOut( )
         nuQprnOut( '***** Depot='+cDepot)
         nuQprnOut( 'First Receipt: '+ ShowCurrRecpt() )
         if !Daily->(eof())
            Daily->(dbSkip())
         endif

         do while !Daily->(eof())
            aNote := {}
            lNotePrev := .f.

            do case
            case Daily->depot <> cDepot
               if NearPageBottom( 10 )
                  nuQprnOut('....Continued on Next Page...')
                  nPage++
                  Heading( nPage, dDate1, dDate2 )
               endif

               nuQprnOut('Last ticket for depot=' + ;
                 cDepot+'-'+StrZero(Daily->recpt,FLD_RECPT)+' '+ ;
                 shMdy( dDate) )
               nuQprnOut('')
               nuQprnOut('***** Depot='+Daily->Depot)

               aadd(aNote,'First ticket for Depot='+Daily->Depot+'-'+ ;
                  strZero(Daily->recpt,FLD_RECPT))

            case Daily->recpt > nRecpt+1
               aadd(aNote,'Gap in receipts - may be missing receipts')
               lNotePrev := .t.
            case Daily->recpt == nRecpt
               aadd(aNote,'Duplicate Recpt#')
            endcase

            if dDate > Daily->date .and. cDepot==Daily->depot
               aadd(aNote,'Receipt is from earlier day')
               lNotePrev := .t.
            endif

            if nImportBat > Daily->imp_bat .and. cDepot<>Daily->depot
               if Daily->imp_bat==0
                  aadd(aNote,'Manually input ticket')
               else
                  aadd(aNote,'Imported before previous receipt')
                  lNotePrev := .t.
               endif
            endif

            if len(aNote) > 0
               if NearPageBottom( 7+len(aNote) )
                  nPage++
                  Heading( nPage, dDate1, dDate2 )
               endif

               if lNotePrev
                  nuQprnOut( 'From Rcpt# '+str(nRecpt,FLD_RECPT)+ ;
                     ' '+shMDY(dDate)+' to '+str(Daily->Recpt,FLD_RECPT)+ ;
                     ' '+shMdy(Daily->date) )
               else
                  nuQprnOut( '')
               endif

               nuQprnOut( ShowCurrRecpt() )

               for n:=1 to len(aNote)
                  nuQprnOut( '  '+aNote[n] )
               next
            endif

            dDate       := Daily->date
            nImportBat  := Daily->imp_bat
            nRecpt      := Daily->recpt
            cDepot      := Daily->depot

            Daily->(dbSkip())
         enddo

         nuQprnOut( 'Last Receipt was: '+ cDepot+ ;
           str(nRecpt,FLD_RECPT)+' '+shMDY(dDate)+ ;
            iif(nImportBat==0, ;
               ' manually input', ;
               ' Imp Bat# '+lStrim(nImportBat) ) )

         if NearPageBottom( 10 )
            nPage++
            Heading( nPage, dDate1, dDate2 )
         endif
         nuQprnOut()
         nuQprnOut( 'Notes: ')
         nuQprnOut( ' The system expects Receipts to increment one at a time')
         nuQprnOut( ' and that dates of successive receipts will either be the')
         nuQprnOut( ' same as the previous or from a later day.  Further, we' )
         nuQprnOut( ' expect that receipts from the scale will be imported into')
         nuQprnOut( ' this system in order.' )
         nuQprnOut( )
         nuQprnOut( 'End.' )
         nuQprnOut( )
         PRINT_OFF RPT_COMPLETE_EJECT

         Daily->(dbCloseArea())
         KillUnique(cFile)
         openFile({'Daily'}, DB_SHARED)
         exit
      endif
   enddo

   kill window aWin
	close databases
return( nil )

static function ShowCurrRecpt( )
   local cReturn

   cReturn := 'Depot/Rcpt# '+ ;
     Daily->depot+'-'+strZero(Daily->recpt,FLD_RECPT)+' '+ ;
     shMDY(Daily->date)+ ;
     iif(Daily->imp_Bat==0, ;
      ' manually input', ;
       ' Imp Bat# '+lStrim(Daily->imp_bat) )

return( cReturn )

static function Heading( nPage, dDate1, dDate2 )

   if nPage > 1
      nuFormFeed()
   endif
   nuQPrnOut( padr(shMDY(date()),20) + ;
     padc('Receipt Continuity Report',50)+'Page'+str(nPage,3) )
   nuQprnOut( padr(time(),20)+ padc( shMDY(dDate1)+' to '+shMDY(dDate2),50) )
   nuQprnOut()
   nuQprnOut()

return( nil )
