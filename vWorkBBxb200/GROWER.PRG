* PROGRAM ...: GROWER.PRG
* AUTHOR ....: Originally written by DUNCAN JEFFRIES - QUANTUM RESEARCH
* DATE ......: 5/6/90
* NOTES .....: THIS ROUTINE COLLECTS THE DATA FOR EACH GROWER
*  re-written BH Crafted Industrial Software Ltd.
// May 99 Touched up a bit. - eliminated shares
// Aug 9 minor touch up
// July 2001
// July 2002 - add OnHold
// June 2010 - more stuff.
// Sep 2012 - add View Cheques
// Jul 2014 - GST
// May 2024 - Quick Edit of Grower Contract Field
//            see SysValue also

#Include 'bsgstd.ch'
#include 'inkey.ch'
#include 'window.ch'
#include 'BerryPay.ch'
#include 'browser.ch'
#include 'colors.ch'
#include 'valid.ch'
#include 'price.ch'
#include "indexord.ch"
#include "field.ch"
#include "sysvalue.ch"

static aGwin, aBott

function Grower()
	local nGrow := 0, getlist :={}, aWin, cName, cCheqName
   local bF6

	cName := cCheqName := space(30)

	if !openMainStuff( DB_SHARED )
		close databases
		return( nil )
	endif

	myBsgScreen('Input/Change/View Grower Information')

	create window at 6,09,12,71 title 'Grower Information' to aWin
	display window aWin

	in window aWin @ 6,02 winsay ;
		 'You may look up the grower by ID, Name, or Cheque Name'


	DO WHILE .T.
      Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
		Grower->(dbGoBottom())
		in window aWin @1,37 winsay 'Highest ID on File: '+ ;
		 str(Grower->number,FLD_GROWER)

      bF6 := setKey(K_F6,{|p,l,v| SlowLu(p,l,v,GetList, ;
                       LU_SLOW_BROWSE_GROWER)})

   	in window aWin @2,02 winsay 'Grower Number: ' winget nGrow ;
   	 picture NumBlankPic(FLD_GROWER) ;
   	 LOOKUP( LU_GROWER, '[F5] to Browse in Numeric Order')
   	in window aWin @3,02 winsay 'Grower Name:   ' winget cName ;
       LOOKUP( LU_GROWER_NAME, ;
        '[F5] to Browse in Grower Name Order / [F6] Slow Freeform Lookup')
   	in window aWin @4,02 winsay 'Cheque Name:   ' winget cCheqName ;
   	 LOOKUP( LU_GROWER_CHEQUE_NAME, '[F5] to Browse in Cheque Name Order')
		read
      setKey( K_F6, bF6 )

	   IF nGrow==0 .or. lastkey()==K_ESC
	   	exit
	   endif

      Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
	   if !Grower->(dbSeek( str(nGrow,FLD_GROWER),HARDSEEK))
	   	if yesNo({'Add Grower '+lstrim(nGrow)+'?'})
	   		if Grower->(AddRecord())
					Grower->number   := nGrow
					Grower->currency := CANADIAN_DOLLARS
					Grower->status   := 1
					Grower->chg_gst  := .t.   // July 2014
					Grower->(dbCommit())
				endif
			else
				loop
			endif
		endif

      create window at 2,04,21,73 Title 'Grower' to aGwin
		display window aGwin

		msgline('')
		aBott := save_scr(23,0,maxRow(),maxCol())

		Newin( NO_READ )
      inTheGrower( {|x| newin(x )} )
      kill window aGwin

	ENDDO
	kill window aWin
	close databases
return( nil )

Function ViewGrower( nRecNo )
   local nRec

   nRec := Grower->(recNO())

   Grower->(dbGoTo( nRecNo ))

   create window at 2,04,21,73 Title 'Grower' to aGwin
   display window aGwin

   msgline('')
   aBott := save_scr(24,0,maxRow(),maxCol())

   Newin( NO_READ )
   thinWait('Viewing Grower...')

   // inTheGrower( {|x| newin(x )} )

   kill window aGwin

   Grower->(dbGoTo( nRec ))

return( SIG_CONTINUE )


static function NEWIN( lRead )
	local GetList :={}

   // ShareView( Grower->Number, SHO_SHOW_ONLY )

	rest_Scr(aBott)

	if !Grower->(recLock())
		return( nil )
	endif

	PayGrpInfo(  )
	in window aGwin @  1,02 winsay  "Grower Number: "+lSTRim(Grower->NUMBER)

   in window aGwin @  2,02 winSAY 'Price Level' winget Grower->STATUS ;
	 valid Grower->status > 0 .and. Grower->status <= MAX_NO_OF_PRICE_LEVELS ;
	 GET_MESSAGE 'Enter usual Price Level (can be overridden) 1-4'

   in window aGwin @  2,25 winsay 'Currency' winget Grower->currency ;
	 picture '@!' ;
	 valid ValidTest(V_CURRENCY,Grower->currency,VT_MESSAGE) ;
	 get_message 'Use Canadian or US as the currency'

   // 2002 - July
   in window aGwin @  2,60 winsay 'On Hold' winget Grower->onHold ;
    picture 'Y' ;
    get_message 'If a grower is on hold we will not generate cheques for him!'

	// new in 2001 - We try & make it easier to pay a group....
   in window aGwin  @03,02 WINSAY 'Pay Group  ' winget ;
		 Grower->payGrp PICTURE '@!' ;
		 when PayGrpInfo()      ;
		 valid ValidTest( V_PAYGRP,  Grower->payGrp, VT_BROWSE ) ;
			 .and. PayGrpInfo() ;
	 LOOKUP( LU_PAYGRP, ;
	 '[F5]-A Payment Group is designed to be Paid at one Time')

   in window aGwin @  4,02 winSAY 'Cheque Name' winget ;
	 Grower->CHEQNAME PICTURE '@!' ;
	 GET_MESSAGE 'This is the Name that Prints on Cheques'

	in window aGwin  @ 6,02 WINSAY 'Grower Name' winget Grower->NAME ;
	 PICTURE '@!' GET_MESSAGE 'Name for alphabetic Sorts'
   in window aGwin  @ 7,02 WINSAY 'Address    ' WINGET Grower->STREET
   in window aGwin  @ 8,02 WINSAY '           ' WINGET Grower->STREET2

   in window aGwin  @ 9,02 winsay 'City       ' winGET Grower->CITY ;
    get_message 'Put Province or State in next field!'

   in window aGwin  @ 9,40 winget Grower->prov picture '@!' ;
	 get_message 'Enter the Province or State'

   in window aGwin  @10,02 winsay 'Postal     ' winGET Grower->PCODE ;
	 PICTURE '!9!!9!99999' ;
	 get_message 'Postal Code'
   in window aGwin  @11,02 winSAY 'Phone #s   ' winget Grower->PHONE ;
     get_message 'Main phone'
   in window aGwin  @11,30 winget Grower->PHONE2 get_message ;
    'Enter an alternate phone number'
   in window aGwin  @12,02 winsay 'Contract   ' winget Grower->contract picture '@!' ;
	 GET_MESSAGE 'Contract with this grower?'

   in window aGwin  @12,30 winsay 'Cont. Lim' winget Grower->contlim ;
		get_message 'Enter Container Value Credit Limit if used'
   in window aGwin @ 13,02 winsay "Certified  " winget Grower->certified ;
    picture '@!' GET_MESSAGE ;
     'Certification Status - remember to set price correctly'

	in window aGwin  @ 5,52 winsay 'Acres   ' winget Grower->ACRES ;
     get_message 'Acres in Production'
   in window aGwin  @ 6,52 winsay 'LY Fresh' winget Grower->LY_FRESH ;
     get_message 'Last Years Fresh production (keyed in!)'
   in window aGwin  @ 7,52 winsay 'LY Other' winget Grower->LY_OTHER ;
     get_message 'Last Years Other (non-Fresh) production (keyed in!)'

	in window aGwin  @ 9,52 winsay 'Ch. GST ' winget Grower->CHG_GST picture 'Y' ;
     get_message 'Charge GST (for Marketing Deduction & other services)'


   in window aGwin @ 14,02 winsay 'Notes:'
   in window aGwin @ 15,05  winget Grower->notes
   in window aGwin @ 16,05  winget Grower->note2
   in window aGwin @ 17,02  winsay 'Other' winget Grower->alt_name1
   in window aGwin @ 17,50  winsay 'Ph' winget Grower->alt_phone1
   in window aGwin @ 18,02  winsay 'Names' winget Grower->alt_name2
   in window aGwin @ 18,50  winsay 'Ph' winget Grower->alt_phone2

	if lRead==READ_IT
		read
		do case
		case empty( Grower->payGrp )
			waitHand({'The Payment Group field should be filled in!'})
		case !ValidTest( V_PAYGRP, Grower->payGrp, VT_MESSAGE )
			waitHand({'The Payment Group should be corrected!'})
		endcase
      if updated()
         Grower->( EditByFlds() )
      endif
	else
		getList :={}
	endif

RETURN(nil)


static function inTheGrower( bEdit )
   // B Hepler

	local nMenu := 1, nRec,  cColor, n
	local nDaily

	cColor := setColor()
	nRec := Grower->(recno())

	do while .t.
      setColor(cColor)
      Grower->(dbGoTo(nRec))   // ensure grower is always positioned
		eval(bEdit, NO_READ)

		// May 2024
		do case
		case SysValue( SYS_QUIK_ED_GROW_CONTRACT_CERTIFY_FLD ) == SQEDG_QUIK_ED_GCC_CERTIFY
			nMenu := ThinChoice( ;
			{'Ed','P<','N>','Ac','Chq','Daily','UnPo','Del','Tcy','X-bye'})

		case SysValue( SYS_QUIK_ED_GROW_CONTRACT_CERTIFY_FLD ) == SQEDG_QUIK_ED_GCC_CONTRACT
			nMenu := ThinChoice( ;
			{'Ed','P<','N>','Ac','Chq','Daily','UnPo','Del','Tcn','X-bye'})

		otherwise
			// the default
			// on the Cheque Stub, than fit...  The Default is Yes
			nMenu := ThinChoice( ;
         {'Edit','Prev','Next','Acct','Chq','Daily','UnPost','Del','X-eXit'})
		endcase

		select Grower
		do case
		case nMenu == 1
		 	eval(bEdit, READ_IT)
      case nMenu == 2
       	if !bof()
            SKIP-1
         endif
         IF BOF()
           	waitInfo({'At Top of File'})
           	if !eof()
           		dbGoTop()
           	endif
         else
				nRec := Grower->(recno())
         endif
      case nMenu == 3
        	Grower->(dbSkip())
         if Grower->(EOF())
         	waitInfo({"At Last Record"})
         	dbGoBottom()
         else
				nRec := Grower->(recno())
         endif

		// case nMenu == 4
		//	ShareView( Grower->number, SHO_LEAVE_ON_EXIT )

		case nMenu == 4
         Cheque->(OrdSetFocus( CHEQUE_CHEQUE_NO_ORD))
			Account->(dbSetRelation(  'Cheque', ;
			 {|| Account->series + str(Account->cheque,FLD_CHEQUE) } ))

         Account->(OrdSetFocus(ACCOUNT_NUMBER_ORD))
		 	if Account->(dbSeek( str(Grower->number,FLD_NUMBER),HARDSEEK))
		 		AccountGroBrowse( Grower->number )
		 	else
		 		if yesno({'No Accounting Transactions on File.', ;
		 		 'Do you wish to add one ?'})
		 		 	AddAccount( Grower->number, .f.)
		 		endif
		 	endif
			Account->(dbClearRel())

		case nMenu == 5
		 	// View Cheques
		 	Cheque->(OrdSetFocus( CHEQUE_GROWER_DATE_ORD ))
		 	if Cheque->(dbSeek( str( Grower->number, FLD_GROWER), HARDSEEK))
		 		do while .t.
		 			if CheqBrowse( { || Grower->number == Cheque->number .and. !Cheque->(eof()) }, .f. )
		 				Account->(OrdSetFocus(ACCOUNT_CHEQUE_ORD))
		 				if Account->(dbSeek( Cheque->series + str( Cheque->cheque, FLD_CHEQUE ), HARDSEEK ))
		 					AccountChqBrowse( Cheque->Series, Cheque->Cheque )
		 				else
		 					WaitInfo({'Can not find any account entries for this cheque', ;
		 					       })
		 				endif
		 			else
		 				exit
		 			endif
		 		enddo
		 	else
		 		WaitInfo({'No cheques issued to this grower yet'})
		 	endif

      case nMenu == 6
         Daily->(OrdSetFocus( DAILY_GROWER_ORD ))
			if Daily->(FindLast( str( Grower->number,FLD_GROWER) ))
				for n :=1 to 6
					nDaily := Daily->(recno())
					Daily->(dbSkip(-1))
					if Grower->number<>Daily->number .or. Daily->(bof())
						Daily->(dbGoTo(nDaily))
					endif
				next
				Daily->(DailyBrowse( Grower->number, DAILY_ANY_TRANS ))
			else
				waitInfo({'No posted Production on file'})
			endif

      case nMenu == 7
         Daily->(OrdSetFocus( DAILY_ADV_POST_GROWER_ORD ))
			if Daily->(dbSeek( str(0,FLD_DOCUMENT) + str(Grower->number,FLD_GROWER) , HARDSEEK))
				DailyBrowse( Grower->number, DAILY_UNPOSTED )
			else
				if yesno({'No unposted Production on file','Add a transaction?'})
					DailyAddRec(Grower->number)
				endif
			endif

      case nMenu == 8
         if yesno({'Attempt to DELETE the Grower?'})
            Daily->(OrdSetFocus( DAILY_GROWER_ORD ))
            if Daily->(dbSeek( str(Grower->number,FLD_GROWER) , HARDSEEK))
               WaitInfo({'Can NOT delete - there are Tickets'} )
            else
               Account->(OrdSetFocus(ACCOUNT_NUMBER_ORD))
               if Account->(dbSeek( str(Grower->number,FLD_NUMBER),HARDSEEK))
                  WaitInfo({'Can NOT delete - there are Account Transactions'} )
               else
                  if yesno({'Are you sure you want to delete him?'})
                     if Grower->(RecLock())
                        Grower->(dbDelete())
                        Grower->(dbCommit())
                        WaitInfo({'That Grower is toasted !'})
                        exit
                     endif
                  endif
               endif
            endif
         endif

		case nMenu == 9
			do case
			case sysValue(SYS_QUIK_ED_GROW_CONTRACT_CERTIFY_FLD) == SQEDG_QUIK_ED_GCC_CONTRACT
				// Contract is 1 Character
				do case
				case empty( Grower->contract )
					Grower->contract := "Y"
				case Grower->contract == "N"
					Grower->contract := "Y"
				case Grower->contract == "Y"
					Grower->contract := "N"
				otherwise
					WaitInfo({'Not sure what to do with Contract', ;
                         'The QUICK CHANGE will only deal with', ;
                         'Y or N or Blank'})
				endcase

			case sysValue(SYS_QUIK_ED_GROW_CONTRACT_CERTIFY_FLD) == SQEDG_QUIK_ED_GCC_CERTIFY
				// Certfied is multi letter  upper case
				do case
				case empty( Grower->certified )
					Grower->certified := "YES"
				case upper(alltrim(Grower->certified)) == "NO" .or. ;
				     upper(alltrim(Grower->certified)) == "N"
					Grower->certified := "YES"
				case upper(alltrim(Grower->certified)) == "YES" .or. ;
				     upper(alltrim(Grower->certified)) == "Y"
					Grower->certified := "NO"
				otherwise
					WaitInfo({'Not sure what to do with Certification Status', ;
                         'The Quick Changer only does YES or NO or Blank!'})
				endcase
			otherwise
				exit
			endcase
      otherwise
       	exit
      endcase
   enddo
   rest_scr(aBott)
return( nil )

static Function PayGrpInfo(  )

	validTest(V_PAYGRP, Grower->payGrp, VT_NO_MESSAGE)

	if !empty(Grower->payGrp) .and. Grower->payGrp==PayGrp->PayGrp
		if Grower->status == PayGrp->def_prlvl .or. PayGrp->def_prLvl==0
         in window aGWin @ 2,38 winsay '                   '
		else
         in window aGwin @ 2,38 winsay 'Expect Price Lvl=' + ;
				lStrim(PayGrp->def_prLvl)
		endif
      in window aGwin @ 3,38 winsay PayGrp->desc
	else
      in window aGWin @ 2,38 winsay '                   '
      in window aGWin @ 3,38 winsay space(FLD_NAME)
	endif
return( .t. )

function CountOnHold( aOnHold )
   local n, aMsg

   aMsg := msgLine('Counting ON-HOLDS....')

   aSize( aOnHold, 0)

   Grower->(dbGoTop())
   n := 0
   do while !Grower->(eof())
      n++
      ShowProg( str(n,6))
      if Grower->onHold
         aadd( aOnHold, Grower->name )
      endif
      Grower->(dbSkip())
   enddo

   rest_Scr( aMsg )

return( len(aOnHold) )


