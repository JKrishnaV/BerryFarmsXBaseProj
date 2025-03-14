// ---------------------------------------------------------------------------
//  Application: Berry Payment System
//  Description: Purges old data
//    File Name: PURGE.PRG
//       Author: Bill Hepler
// Date created: 07/02/02
// Revision
//      May 13, 2020   -  Get rid of new files as needed.
//
//  Copyright: (c) 2002, 2019, 2020 by Bill Hepler
// ----------------------------------------------------------------------------

#include "BSGSTD.CH"
#include "directry.ch"
#include "events.ch"
#include "inkey.ch"
#include "WINDOW.CH"

function PurgeData()
   local getList := {}
   local lGrower  := .f.
   local lProduct := .f.
   local lReport  := .f.
   local aDir
   local aWin
   local n
   local aFail

   myBsgScreen( 'Purge Data for Year End' )
   close databases

   create window at 6,10,16,72 title 'Purge Data for Year Beginning' to aWin
   display window aWin

   if !yesno({'Do you wish to Purge Old Data ??', ;
         '** You should backup before doing this! **', ;
         'This purges all data in the selected files...', ;
         '', ;
         '(you may choose what files to purge)'})
      return( nil )
   endif

   do while .t.
      in window aWin @ 2,2 winsay 'Delete Growers' winget ;
       lGrower picture 'Y' get_message ;
       'Delete the entire Grower List'

      in window aWin @ 3,2 winsay 'Delete Product Info' winget ;
       lProduct picture 'Y' get_message ;
       'Delete all Products, Processes'

      in window aWin @ 4,2 winsay 'Delete Report Formats' winget ;
       lReport picture 'Y' get_message ;
       'Delete all the saved report formats'

      in window aWin @ 6,2 winsay 'This function will delete ALL prices'
      in window aWin @ 7,2 winsay 'receipts, adjustments, cheques and batches.'

      in window aWin @ 9,2 winsay '[Esc] to exit without Deleting...'

      read

      aFail := {}
      if lastkey() <> K_ESC
         if yesno({'Ready to Delete this stuff?'})

            msgLine('Deleting main stuff...')

				close databases

            begin sequence
               EraseMe(aFail,'ACCOUNT.DBF')
               EraseMe(aFail,'AUDIT.DBF')
               EraseMe(aFail,'BANKREC.DBF')
               EraseMe(aFail,'CHEQUE.DBF')
					EraseMe(aFail,'COUNTERIDS.DBF')    // April 2020
               EraseMe(aFail,'DAILY.DBF')
					EraseMe(aFail,'DAILY_AUDIT.DBF')   // added in Mar 2020
               EraseMe(aFail,'EVENTS.DBF')        // April 2020
               EraseMe(aFail,'FINBAT.DBF')
               EraseMe(aFail,'IMPBAT.DBF')
               EraseMe(aFail,'POSTBAT.DBF')
               EraseMe(aFail,'PRICE.DBF')
               EraseMe(aFail,'VOIDCHQ.DBF')
               EraseMe(aFail,'VOIDTCK.DBF')
            end sequence

            if lGrower
               msgLine('Deleting Grower and Pay Groups')

               begin sequence
                  EraseMe(aFail,'GROWER.DBF')
                  EraseMe(aFail,'PAYGRP.DBF')
                  if file('SHARES.DBF')
                     EraseMe(aFail,'SHARES.DBF')
                  endif
               end sequence
            endif

            if lProduct
               msgLine('Deleting Products and Processes')

               begin sequence
                  EraseMe(aFail,'PROCESS.DBF')
                  EraseMe(aFail,'PRODUCT.DBF')
						EraseMe(aFail,'VARIETY.DBF')
               end sequence
            endif

            if lReport
               aDir := Directory('RPT*.DBF')
               msgLine('Deleting Reports...')
               for n := 1 to len( aDir)
                  begin sequence
                     EraseMe(aFail, aDir[n,F_NAME] )
                  end sequence
               next
            endif

            if len(aFail) <> 0
               WaitInfo({'Next screen shows files that were not erased'})

               WaitHand( aFail )
            endif

            msgLine('Now Setting up New Files..')
            ConvertData()

            if OpenFile({'Events'}, DB_EXCLUSIVE )
            	LogAnEvent( EVT_TYPE_PURGE, 'Purge '+iif( lGrower,'Grower ','' ) + ;
                                           iif(lProduct,'Product','')+iif(lReport,' Reports',''))
            endif
				close databases

            waitInfo({'Files purged !', 'You MUST EXIT the program NOW!', ;
             'You may need to go into the System Settings to ensure', ;
             'that your YEAR and CHEQUE numbers are correct!'})

         endif
      endif
      exit
   enddo
   close databases
   kill window aWin
return( nil )


static function EraseMe( aFail, cFile )
   local lFileErr := .f.
   local lSucceed := .f.
   local cCDX

   showProg( cFile )
   begin sequence

   	if file( cFile )
         if fErase(cFile)==0
            lSucceed := .t.
         else
            aadd(aFail,cFile)
         endif
         lFileErr:= .t.
		else
      	aadd( aFail,'Can find '+cFile)
      endif

      cCDX := strTran( cFile,'.DBF','.CDX')

      if file( cCDX )
	      fErase( cCDX )
      endif

   end sequence

   if !lFileErr
      aadd(aFail,cFile)
   endif

   if !lSucceed
      WaitInfo({'Failed to delete '+cFile, ;
       'You must delete this file by hand.' })
   endif

return( lSucceed )






