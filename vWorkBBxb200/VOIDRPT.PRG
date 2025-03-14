// ---------------------------------------------------------------------------
//  Application: Berry Payment System
//  Description: Does the Void Report
//
//     File Name: VOIDRPT
//        Author: Bill Hepler
//  Date created: 06/22/05              Date updated: July 2014
//
//  Copyright: (c) 2005,2011, 2014 by Bill Hepler & Crafted Industrial Software Ltd.
//-------------------------------------------------------------------------

#include 'common.ch'
#include 'window.ch'
#include 'bsgstd.ch'
#include 'printer.ch'
#include 'BerryPay.ch'
#include 'inkey.ch'
#include 'sysvalue.ch'
#include 'account.ch'
#include "rpt.ch"
#include "field.ch"
#include "indexord.ch"


function VoidRpt()
   local aWin
   local dFrom,dTo
   local getList := {}

   if !openfile({'Grower','VoidTck','Product','Process','ImpBat','Daily'}, ;
	  DB_SHARED)
		close databases
		return( nil )
	endif

	dFrom   := min( sysValue( SYS_CURRENT_SEASON_START ), date() )
	dTo     := max( sysValue( SYS_CURRENT_SEASON_END )  , date() )

   myBsgScreen( 'Void Ticket Listing' )

   create window at 5,07,18,72 title 'List Voided Tickets' to aWin
	display window aWin
	set cursor on

	do while .t.
		msgLine('[Esc] to Exit')

      in window aWin @ 2,2  winsay 'From:' winget dFrom picture '@d' ;
       get_message 'Based on earlier of Date of Ticket or Date of Void'
      in window aWin @ 3,2  winsay '  To:' winget dTo picture '@d' ;
		 get_message 'Remember the + - and T keys for date fields'
      read

      if lastkey()==K_ESC
         exit
      endif

      VoidTck->(OrdSetFocus( 0 ))
      VoidTck->(dbGoTop())
      if VoidTck->(eof())
         waitInfo({'No here!'})
         loop
      endif

      if selectPrn('VOIDRPT.TXT')
         PRINT_ON RPT_OVERWRITE

         VoidPrnter(                                                                   ;
			   {|| (VoidTck->qAdd_Date >= dFrom .or. VoidTck->date >= dFrom) .and.       ;
			       (VoidTck->qAdd_Date <= dTo   .or. VoidTck->date <= dTo  )          }, ;
           {'Voided Ticket Listing', 'From '+shMDY(dFrom)+' to '+shMDY(dTo) })

         PRINT_OFF  RPT_COMPLETE_EJECT

		endif
	enddo

	kill window aWin
	close databases
return( nil )

function VoidPrnter( bWhile, aTitle )
   local aRpt := {}

   aadd( aRpt,{ 'Dep', {|| VoidTck->depot}, 'C', max(3,FLD_DEPOT), 0, .t., .f., ;
       'Depot' })

	aadd( aRpt, ;
      { 'Recpt'    , { || VoidTck->recPt } ,  'N' , FLD_RECPT ,  000 , ;
        .t., .f. , ;
        'Receipt #' } )

   aadd( aRpt, ;
      { 'Tick Date'    , { || shMDY(VoidTck->date) } ,  'C' , 11 ,  000 , ;
        .t., .f. , ;
        'Date of the  Ticket' } )

   aadd( aRpt, ;
      { 'Grower'    , { || VoidTck->number } ,  'N' , 6 ,  000 , ;
        .t., .f. , ;
        'Grower #' } )

   aadd( aRpt, ;
      { 'Prod'    , { || VoidTck->product } ,  'C' , FLD_PRODUCT ,  000 , ;
        .t., .f. , ;
        'Product' } )

   aadd( aRpt, ;
      { 'VoidDate'    , { || shMDY(VoidTck->qadd_date) } ,  'C' , 11 ,  000 , ;
        .t., .f. , ;
        'Date Ticket was Voided' } )

   aadd( aRpt, ;
      { 'By'    , { || VoidTck->qadd_op } ,  'C' , 6 ,  000 , ;
        .t., .f. , ;
        'Who Voided' } )

   aadd( aRpt, ;
      { 'Comments'    , { || alltrim(VoidTck->reason)+'/'+alltrim(VoidTck->edit_reas) } ,  'C' , 30 ,  000 , ;
        .t., .f. , ;
        'Where Voided & Why Edited at Scale (if applicable)' } )

   aadd( aRpt, ;
      { 'ImpBatch'    , { || VoidTck->imp_bat } ,  'N' , FLD_DOCUMENT ,  000 , ;
        .t., .f. , ;
        'Import Batch Number' } )

   gRptInitHead()
   gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

   gRptGetSetHead( RPT_HEAD_FOR_CONDITION, bWhile  )

   gRptPrintSize( aRpt )

   VoidTck->(gRptPrinter( aRpt ))

   nuQprnOut()
   nuQprnOut('End of Report.')

return( nil )

