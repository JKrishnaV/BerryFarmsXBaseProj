//////////////////////////////////////////////////////////////////////
///
/// <summary>
///   RepairData_1offs.prg
///   This is for repairs to data that too complex to do reliably with
///   dbu32.exe or other utilities.  They are usually only run ONCE!
/// </summary>
///
///
/// <remarks>
///
/// </remarks>
///
///
/// <copyright>
///  (c) 2022 Crafted Industrial Software Ltd. All Rights Reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////

#include "BSGSTD.CH"
#include "FIELD.CH"
#include "INDEXORD.CH"
#include "inkey.ch"
#include "SYSVALUE.CH"
#include "VALID.CH"
#include "WINDOW.CH"

/// This is to repair a grawers ledger.  Jass was running a cheque
/// and a power failure happened.  She just kept on - she did not
/// check over her work.  She did NOT get in touch with me right away
/// and so the relevent backup was overwritten.
///
function WestBerry121( )
	local aW
   local getList   := {}
   local nGrower   := 121
	local nCheque   := 23530
   local cSeries   := '1A'
   local nPostBat2 := 31
   local nPrice2   := 0.20
   local nPriceID  := 3
   local aRay      := {}
   local nCount    := 0
   local nTmp

	if !xxPassWord('Bills wife','RUTH')
   	return( nil )
   endif

   if !yesno({'Are you sure you want to do this? ', ;
              'this is to fix problems with Grower 121', ;
              'caused by the Power Failure!'})
   	return( nil )
	endif

	if !xxPassWord('Bills Dog','BROWNIE')
   	return( nil )
   endif

	if !xxPassWord('Are you authorzied to do this','YES')
   	return( nil )
   endif

   if !openFile({'Grower','Daily','Account','Cheque','Audit'},DB_EXCLUSIVE )
   	close databases
      return( nil )
   endif

	create window at 2,04,20,76 title 'Emergency Fix for WestBerry - re Jan 2022' to aW
	display window aW

	set cursor on

   do while .t.
		in window aW @ 2, 2 winsay 'Grower' winget nGrower picture NumBlankPic( FLD_GROWER ) ;
       LOOKUP( LU_GROWER, ;
		 'Enter the Grower ID here')

		in window aW @ 3,2  winsay 'Cheque' winget cSeries ;
		 picture '@!' ;
		 get_message "Enter the Cheque Series - currently it is " + ;
		 sysValue(SYS_CDN_CHEQUE_SERIES)+', '+sysValue(SYS_US_CHEQUE_SERIES)
		in window aW @ 3,10+FLD_SERIES winget nCheque picture ;
		 numBlankPic(FLD_CHEQUE)

		in window aW @ 4,2 winsay 'Post Bat2' winget nPostBat2 picture '9999'
      in window aW @ 5,2 winsay 'Price2   ' winget nPrice2   picture '9.99'
      in window aW @ 6,2 winsay 'Price ID ' winget nPriceID  picture '999'

		read

      if lastkey() == K_ESC
      	exit
      endif

      Cheque->(OrdSetFocus(CHEQUE_CHEQUE_NO_ORD))
		if !Cheque->(dbSeek(cSeries + str(nCheque, FLD_CHEQUE),HARDSEEK))
      	WaitInfo({"Can NOT find this cheque - this will not work"})
         loop
      endif

      Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
      if !Grower->(dbSeek( str(nGrower,FLD_GROWER), HARDSEEK))
      	WaitInfo({'Can NOT find this Grower - this will not work'})
         loop
      endif

      if !(nGrower==Cheque->number)
      	WaitInfo({'Grower and Cheque do NOT agree!'})
			loop
      endif

      Daily->(OrdSetFocus(  DAILY_GROWER_ORD ))
      if !Daily->(dbSeek( str(nGrower,FLD_GROWER), HARDSEEK))
      	WaitInfo({'No transactions for this grower!'})
         loop
      endif

		if Yesno({'Run the FIX ?'})

      	nTmp      := len( shMDY( date()) )

	      aRay      := { padl('Unique',FLD_DOCUMENT) + ' ' + ;
                        'Dp'                        + ' ' + ;
                        padl('Recpt', FLD_RECPT)    + ' ' + ;
                        padc('Date', nTmp)          + ' ' + ;
                        padr('Pd', FLD_PRODUCT)     + ' ' + ;
                        padr('Ps', FLD_PROCESS)     + ' ' + ;
                        padr('G',  FLD_GRADE)       + ' ' + ;
                        padl('Net Wt', 8)           + ' ' + ;
                        padl('Adv1 Pr',10)      + ;
                        padl('Adv2 Pr',10)      + ;
                        padl('Adv3 Pr',10)      + ;
                        padl('Final',10)        + ;
                        padl('Keyed Pr',10)                 }

         nCount    := 0

         Account->(OrdSetFocus( ACCOUNT_CHEQUE_ORD )) // not sure this is important

         Audit->( OrdSetFocus( AUDIT_DAY_ACCT_ORD ))   // important-we SHOULD not find an Entry for ADVANCE 2 here


         do while !Daily->(eof()) .and. Daily->number == nGrower

            if Daily->post_bat2          == nPostBat2          .and. ;
               str(Daily->adv_pr2,10,2)  == str( nPrice2,10,2) .and. ;
               str(Daily->adv_prid2,3 )  == str( nPriceID , 3)

               aadd( aRay, str( Daily->day_uniq, FLD_DOCUMENT)+' ' + ;
                           Daily->depot + ' '+ ;
                           str( Daily->recpt, FLD_RECPT)+' '+ ;
                           shMdy( Daily->date)+ ' '+ ;
                           Daily->product + ' ' + ;
                           Daily->process + ' ' + ;
                           str( Daily->grade,1)+' ' + ;
                           str( Daily->net,8)+ ' '+ ;
                           str( Daily->adv_pr1, 10,2)  + ;
									str( Daily->adv_pr2, 10,2)  + ;
									str( Daily->adv_pr3, 10,2)  + ;
                           str( Daily->fin_price,10,2) + ;
                           str( Daily->theprice,10,2) )

					Daily->adv_pr2 := 0
               nCount++

            endif

         	Daily->(dbSkip())
         enddo

         WaitInfo({'We FIXED '+var2char( nCount )+' Receipt Records', ;
                   'Please see the next screen for details'})

         WinArrayVu( aRay,'Updated' )

         exit
      endif
   enddo
   kill window aW
   close databases

return( nil )

function WestBerry122( )
	local aW
   local getList   := {}
   local nGrower   := 333
   local dAccFrom   := date()-20
   local dAccTo     := date()
   local dDailyFrom := date()-20
   local dDailyTo   := date()
   local nAuditDel  := 0
   local nAcctDel   := 0
   local aRay       := {}
   local aAccount   := {}
   local nTmp       := 0
   local nCount     := 0

   if !yesNo({'This Fixer is intended to Back out entries to the  ACCOUNT.DBF'       , ;
              'table for a particular Grower for a date range.  We are NOT sure'     , ;
              'why the orginal problem occurs but it seems to have something to', ;
				  'do with Loans being made and then normal payments being processed'  , ;
              'are for less money than the loans (which should work actually).' ,'', ;
              'This cleans up Advances which have not been fully paid out!'   , ;
              '   ***   '                                               , ;
              'Continue?' })
      return( nil )
   endif

	if !xxPassWord('Bills wife','RUTH')
   	return( nil )
   endif

   if !yesno({'Are you sure you want to do this? ','', ;
	           'This routine is intended to REMOVE all traces of advances', ;
				  'which have not been paid out!  It should NOT be used to', ;
				  'reverse cheques!' })
   	return( nil )
	endif

	if !xxPassWord('Bills Dog','BROWNIE')
   	return( nil )
   endif

	if !xxPassWord('Are you authorzied to do this','YES')
   	return( nil )
   endif

   if !openFile({'Grower','Daily','Account','Cheque','Audit'},DB_EXCLUSIVE )
   	close databases
      return( nil )
   endif

	create window at 2,04,20,76 title 'Emergency Fixer-Nov 2022-clean up AP' to aW
	display window aW

	in window aW @ 10,2 winsay 'Be VERY attentive to the date you enter here!'

	set cursor on

   do while .t.
		in window aW @ 2, 2 winsay 'Grower' winget nGrower picture NumBlankPic( FLD_GROWER ) ;
       LOOKUP( LU_GROWER, ;
		 'Enter the Grower ID here')

		in window aW @ 4,2 winsay 'Delete DAILY from: ' winget dDailyFrom picture '@D' ;
        get_message 'Earliest date for DAILY Receipts to remove ADVANCES'

		in window aW @ 5,2 winsay 'Delete DAILY until:' winget dDailyTo picture '@D' ;
        get_message "Latest date for DAILY Receipts to remove ADVANCES"

		in window aW @ 7,2 winsay 'Delete Accounts from: ' winget dAccFrom picture '@D' ;
        get_message "Earliest date to remove from ACCOUNTS"

		in window aW @ 8,2 winsay 'Delete Accounts until:' winget dAccTo picture '@D' ;
        get_message "Delete ACCOUNTS this date or earlier back to FROM date"

		read

      if lastkey() == K_ESC
      	exit
      endif

		Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
      if !Grower->(dbSeek( str(nGrower,FLD_GROWER), HARDSEEK))
      	WaitInfo({'Can NOT find this Grower - this will not work'})
         loop
      endif

      Daily->(OrdSetFocus(  DAILY_GROWER_ORD ))
      if !Daily->(dbSeek( str(nGrower,FLD_GROWER), HARDSEEK))
      	WaitInfo({'No transactions for this grower!'})
         loop
      endif

		aRay     := {}
   	aAccount := {}

		if Yesno({'Run the FIX ?'})

      	nTmp      := len( shMDY( date()) )

	      aRay      := { padl('Unique',FLD_DOCUMENT) + ' ' + ;
                        'Dp'                        + ' ' + ;
                        padl('Recpt', FLD_RECPT)    + ' ' + ;
                        padc('Date', nTmp)          + ' ' + ;
                        padr('Pd', FLD_PRODUCT)     + ' ' + ;
                        padr('Ps', FLD_PROCESS)     + ' ' + ;
                        padr('G',  FLD_GRADE)       + ' ' + ;
                        padl('Net Wt', 8)           + ' ' + ;
                        padl('Adv1 Pr',10)          + ;
                        padl('Adv2 Pr',10)          + ;
                        padl('Adv3 Pr',10)          + ;
                        padl('Final',10)            + ;
                        padl('Keyed Pr',10)         + ;
                        ' Deleted'            }

      	aAccount := { padl('AcctUniq',FLD_DOCUMENT)           + ' ' + ;
                       padc('Date',nTmp)                       + ' ' + ;
                       padL('Cheque', FLD_SERIES + FLD_CHEQUE) + ' ' + ;
                       'Prod'                                  + ' ' + ;
                       'Pr/G'                                  + ' ' + ;
                       padl('Wgt', 10)                         + ' ' + ;
         				  padl('Un Price',10)                     + ' ' + ;
                       padl('Total $', 10)                     + ' ' + ;
                       ' Advance'   }

         nCount    := 0
			nAuditDel := 0

         Account->(OrdSetFocus( ACCOUNT_LINK_ORD ))
         Audit->(  OrdSetFocus( AUDIT_DAY_ACCT_ORD ))   // important-we SHOULD not find an Entry for ADVANCE 2 here
			Cheque->( OrdSetFocus( CHEQUE_CHEQUE_NO_ORD ))

         do while !Daily->(eof()) .and. Daily->number == nGrower

         	if Daily->date >= dDailyFrom .and. Daily->date <= dDailyTo   .and.  Daily->fin_bat == 0
					msgLine('Reciept: '+Daily->depot + str( Daily->recpt, 10) )


					If YesNo({'Should we Reverse all Advances for this transaction?', ;
						'Unique ID:      '+  str( Daily->day_uniq, FLD_DOCUMENT), ;
						'Ticket #:       '+  Daily->depot + ' '+ str( Daily->recpt, FLD_RECPT), ;
						'Date:           '+  shMdy( Daily->date), ;
						'Prod/Proc/Gr:   '+  Daily->product + ' ' + Daily->process + ' ' +  str( Daily->grade,1), ;
						'Net Wt:         '+  str( Daily->net,8), ;
						'Adv #1 / Post:  '+  '$'+str( Daily->adv_pr1, 10,2)  + str( Daily->post_bat1, 12), ;
						'Adv #2 / Post:  '+  '$'+str( Daily->adv_pr2, 10,2)  + str( Daily->post_bat2, 12), ;
						'Adv #3 / Post:  '+  '$'+str( Daily->adv_pr3, 10,2)  + str( Daily->post_bat3, 12), ;
						'Final/Keyed:    '+  '$'+str( Daily->fin_price,10,2) + ' $'+ str( Daily->theprice,10,2), ;
						'Last Adv Batch: '+  var2char( Daily->last_advPb), ;
						'--> We will blank out the Advance Information!' })

						aadd( aRay, str( Daily->day_uniq, FLD_DOCUMENT)+' ' + ;
										Daily->depot + ' '+ ;
										str( Daily->recpt, FLD_RECPT)+' '+ ;
										shMdy( Daily->date)+ ' '+ ;
										Daily->product + ' ' + ;
										Daily->process + ' ' + ;
										str( Daily->grade,1)+' ' + ;
										str( Daily->net,8)+ ' '+ ;
										str( Daily->adv_pr1, 10,2)  + ;
										str( Daily->adv_pr2, 10,2)  + ;
										str( Daily->adv_pr3, 10,2)  + ;
										str( Daily->fin_price,10,2) + ;
										str( Daily->theprice,10,2)  + ;
										str( nAuditDel, 4 ) + str( nAcctDel, 3) )

						Daily->post_bat1 := 0
						Daily->post_bat2 := 0
						Daily->post_bat3 := 0

						Daily->adv_pr1   := 0
						Daily->adv_pr2   := 0
						Daily->adv_pr3   := 0

						Daily->adv_prId1 := 0
						Daily->adv_prId2 := 0
						Daily->adv_prId3 := 0

						Daily->LAST_ADVPB := 0

						nAuditDel  := 0
                  nAcctDel   := 0

						if Audit->( dbSeek( str( Daily->DAY_UNIQ, FLD_AD_LINK ), HARDSEEK ))

							// ------------------------ Delete all Audit Records attached to this Daily.dbf Record
							//                          and delete the associated ACCOUNT.DBF records
							do while Audit->Day_Uniq == Daily->DAY_UNIQ .and. !Audit->(eof())
                     	// we have not incremented nAuditDel yet..
								showProg( str( Daily->day_uniq, 8 )+ str(nAuditDel, 2) )

								if Account->( dbSeek( str( Audit->acct_uniq, FLD_AD_LINK ), HARDSEEK ))

									do while Account->acct_uniq == Audit->acct_uniq .and. !Account->(eof())

										if Account->date >= dAccFrom .and. Account->date <= dAccTo
											// nAccountID := Account->acct_uniq

											if !empty( Account->series) .or. !empty( Account->cheque)
												if Cheque->(dbSeek( Account->series + str( Account->cheque,FLD_CHEQUE ), HARDSEEK))
													WaitInfo({ ;
														'We have paid this on Cheque: ' + var2char( Account->series) + var2char( Account->cheque), ;
														' Date=   ' + shMDY( Cheque->date), ;
														' Amount= $' + str( Cheque->amount,12,2), ;
														iif( Cheque->void, 'Voided',' Cheque is recorded as issued'), ;
														'YOU SHOULD GET BILL TO MANUALLY DELETE THIS CHEQUE - or Restore backups etc'      })

												else
													WaitInfo({ ;
														 'We have paid this on Cheque: ' + var2char( Account->series) + var2char( Account->cheque), ;
														 'but WE CAN NOT FIND THE cheque!'     })
												endif
											endif

											waitInfo({'We are removing this Payable entry:', ;
												 'ID:           ' + str( Account->Acct_Uniq,FLD_DOCUMENT ), ;
												 'Date:         ' + shMdy( Account->Date    )             , ;
												 'Prod/Proc/Gr: ' + Account->product +' '+ Account->process + ' '+ str( Account->grade,1), ;
												 'Weight:       ' + str( Account->lbs, 10),  ;
												 'Unit Price:   $'+ str( Account->u_price, 10,3 ), ;
												 'Amount:       $'+ str( Account->dollars, 10,2 ), ;
												 'Advance Info: ' + str( Account->adv_no,1)+ ' Batch:'+ str( Account->ADV_BAT, 10), ;
												 'Cheque-if PD: ' + Account->series + var2char( Account->cheque) })

											aadd( aAccount, { ;
											  str( Account->Acct_Uniq,FLD_DOCUMENT )  + ' ' + ;
											  Account->series + str( Account->cheque, FLD_CHEQUE), ;
											  shMdy( Account->Date    )              + ' ' + ;
											  padr( Account->product, 4)                + ' ' + ;
											  padr( Account->process + ' '+ str( Account->grade,1),4)   + ' ' + ;
											  str( Account->lbs, 10)                + ' ' + ;
											  str( Account->u_price, 10,3 )         + ' ' + ;
											  str( Account->dollars, 10,2 )         + ' ' + ;
											  str( Account->adv_no,1)+ ' '+ str( Account->ADV_BAT, 10-2) } )

											Account->(DeleteRecord())
                                 nAcctDel++
										endif
										Account->(dbSkip())
									enddo
								endif
								Audit->( DeleteRecord())
								nAuditDel++
								Audit->(dbSkip())
							enddo
						endif

						nCount++
					endif
            endif

         	Daily->(dbSkip())
         enddo

         WaitInfo({'We FIXED '+var2char( nCount )+' Receipt Records', ;
			          'We Deleted '+var2char( nAuditDel)+ ' Audit Records to clean up!', ;
                   'Please see the next screens for details'})

         WinArrayVu( aRay,'Updated Daily-Screen 1/2' )
         WinArrayVu( aAccount, 'Deleted Account Records-Screeb 2/2')

         exit
      endif
   enddo
   kill window aW
   close databases

return( nil )

