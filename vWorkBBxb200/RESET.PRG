* 旼 Program 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
* �  Application: Billing Information System                                 �
* �  Description: Resets PRICE for Keyed in Prices                           �
* �    File Name: ReSetE.PRG                                                 �
* �       Author: Bill Hepler                                                �
* � Date created: 12-03-2007                                                 �
* �    Copyright: (c) 2007 by Bill Hepler & Crafted Industrial Software Ltd.         �
* 읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸

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


function ReSetTickPrice()
	local getList := {}
   local cProcess
   local aWin

   cProcess := space( FLD_PROCESS )

	if !openfile({'Grower', 'Product','Process', ;
			'Account','Cheque','BankRec','Audit','Daily','VoidChq'}, ;
	  DB_EXCLUSIVE)
		close databases
		return( nil )
	endif

   myBsgScreen( 'ReSet Manually Entered Prices' )

   create window at 6,16,19,63 title 'ReSet Manually Entered Prices' to aWin
	display window aWin
	set cursor on

	do while .t.
      msgLine('[Esc] to Exit')

      in window aWin @ 5,2  winsay 'This screen allows you to Reset Keyed in Prices'
      in window aWin @ 6,2  winsay 'on UnSettled Receipts.'

      in window aWin @ 2,2  winsay 'Process' winget cProcess  ;
       picture '@!' ;
       LOOKUP( LU_PROCESS_TYPE, 'Enter a Process or leave blank for any')
		read

		do case
		case lastkey()==K_ESC
			exit
      endcase

      if yesno({'Ready to Run this ?'})
         if selectPrn('PRCHNGE.TXT')
            PRINT_ON RPT_OVERWRITE
            nuQprnOut(  'Price Changes...' )
            nuQprnOut( )
            Daily->(OrdSetFocus( DAILY_DATE_ORD ))
            Daily->(dbGoTop())
            do while !Daily->(eof())
               if (!empty(cProcess) .and. Daily->process==cProcess) .or. ;
                          empty(cProcess)

                  if str(Daily->FIN_PRICE ,10,2) == str(0,10,2) .and. ;
                     str( Daily->FIN_PR_ID,10,2) == str(0,10,2) .and. ;
                     str( Daily->FIN_BAT, 10,2 ) == str(0,10,2) .and. ;
                     str( Daily->ThePrice,10,2) <> str(0,10,2)

				         if NearPageBottom( 6 )
            				nuFormFeed()
				            nuQprnOut( 'Price changes continued..' )
				            nuQprnOut( )
         				endif

                     nuQprnOut( 'Grower:' + Str(Daily->number,10)+ ;
                       '  Recpt:'+ str(Daily->recpt,10)+' changed '+ ;
                       '  Prd: '+Daily->product+ '  '+ ;
                       '  Prc: '+Daily->process )

                     Daily->ThePrice := 0.00
                  endif
               endif
               Daily->(dbSkip())
            enddo
            PRINT_OFF RPT_COMPLETE_EJECT
         endif
      endif
   enddo
	kill window aWin
	close databases
return( nil )


