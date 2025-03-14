// PROGRAM...: SPPAY.PRG
//  DATE......: 8/27/90
//  NOTES.....: THIS ROUTINE CALCUALTES THE SPECIAL PAYMENT
// June 3, 1994
// re-written entirely by Bill Hepler
// June 99  reWrite a bit for new structure...
// Oct  99  Deduction not working, fixed....
// Nov 2001 allow for status 3.
// Nov 8, 2001 - allow for Comment to be posted fully to Account File
// July 4, 2002 - OnHolds allowed for
// July 2014  - changed to make it in line with other things I am doing
//              and also to cope better with GST.

#include 'common.ch'
#include 'window.ch'
#include 'bsgstd.ch'
#include 'printer.ch'
#include 'BerryPay.ch'
#include 'inkey.ch'
#include 'sysvalue.ch'
#include 'colors.ch'
#include 'account.ch'
#include 'valid.ch'
#include 'price.ch'
#include 'field.ch'
#include 'indexord.ch'
#include 'errors.ch'

static nYr, dTranDate

static dTo, dFrom
static cPayGrp, aHead, lPayGrp, cOrder

/*
	static nM1Pro1,nM2Pro1,nNonPro1, nM1Pro2,nM2Pro2,nNonPro2, ;
		 nM1FreshA,nM1FreshB, nM2FreshA,nM2FreshB, nNonFreshA, nNonFreshB, ;
		 nM1Ju, nM2Ju, nNonJu, nM1Clean1,nM1Clean2, nM2Clean1,nM2Clean2, ;
		 nNonClean1,nNonClean2
*/

static nGrower, cClass, nDeductPrice
static nPrice1, nPrice2, nPrice3
static cProduct,cProcess
static nGrade

static nAcctAud
// must exit after Cheques(), as it Closes the Data bases

function SpPay()
	local  getList :={}, nChoice, aAltWin
	local cCurrency
   local aWin
   local cDesc
   local aOnHold := {}

	if !open4ChequeRun( DB_EXCLUSIVE )
		close databases
		return( nil )
	endif

	cCurrency := CANADIAN_DOLLARS
	cClass := space(FLD_DED_CLASS)
	nDeductPrice := 0
	nYr := sysValue(SYS_CURRENT_YEAR)
	dTranDate := date() -30
	dFrom   := sysValue( SYS_CURRENT_SEASON_START )
	dTo     := sysValue( SYS_CURRENT_SEASON_END )
	lPayGrp := .t.
	cPayGrp := space(FLD_PAYGRP)
	cOrder := 'N'

	cProcess := space(FLD_PROCESS)
	cProduct := space(FLD_PRODUCT)
	nGrade   := 0
   cDesc    := space( FLD_DESC )

	nGrower := 0
   nPrice1 := nPrice2 := nPrice3 := 0.00

	myBsgScreen( 'Generate Special Payments' )
	msgLine('Set up and Run SPECIAL PAYMENTS !')

   create window at 2,5,22,72 title 'Special Payments' to aWin
	display window aWin

   waitInfo({'This option is NOT to be used to make regular FINAL', ;
             'PAYMENTS - that is done with the FINAL CROP PAYMENTS', ;
             'menu option.' , ;
             'This screen is used for special pricing deals that', ;
             'can not be accomodated through the regular pricing', ;
             'system.' })

	do while .t.
      CountOnHold( aOnHold )
      do case
      case len(aOnHold)==0
         in window aWin @19,40 winsay 'No Growers on Hold '
      case len(aOnHold)==1
         in window aWin @19,40 winsay '1 Grower on Hold   '
      otherwise
         in window aWin @19,40 winsay lStrim(len(aOnHold))+ ;
          ' Growers on Hold '
      endcase

   	in window aWin @ 2,2  winsay 'Season From:' winget dFrom picture '@d' ;
			get_message 'Start Payments/Deductions based on Receipts for this date'
   	in window aWin @ 2,30 winsay 'to:' winget dTo picture '@d' ;
			get_message 'Include Receipts up to this date'

		in window aWin @ 4,2  winsay 'Trans. Date:' winget dTranDate ;
		 GET_MESSAGE 'Set Payment Generated in this session to this Date'

   	in window aWin @ 6,2  winsay 'Product:' winget cProduct picture '@!' ;
			lookup(LU_PRODUCT,'Enter a berry type to pay on, or blank for ALL')
   	in window aWin @ 7,2  winsay 'Process:' winget cProcess picture '@!' ;
			lookup(LU_PROCESS_TYPE,'Enter a process type to pay on, or blank for ALL')
		in window aWin @ 8,2  winsay 'Grade:  ' winget nGrade picture '@Z 9' ;
			get_message 'Enter a Grade to pay on, or 0 for any grade'

		in window aWin @10,2  winsay 'Deduction:  ' winget cClass picture '@!' ;
		 valid validTest(V_DEDUCTION_CLASS,cClass,VT_NO_MESSAGE) .or. empty(cClass) ;
       LOOKUP( LU_DEDUCTION_CLASS , ;
       'Leave blank or enter the type of deduction to be applied to All lbs shipped')

		in window aWin @10,26 winget nDeductPrice picture '9.999' when ;
		 nDeductPrice<>0 .or. !empty(cClass) ;
		 valid nDeductPrice > 0  GET_MESSAGE ;
		  'Enter amount per pound to deduct from grower (as a positive number)'

      in window aWin @11,2  winsay 'Note:' winget cDesc get_message ;
       'This note will print on cheque stubs, & some reports'

     	in window aWin @12,2  winsay 'Price #1:' winget nPrice1 ;
          picture '99.999' valid nPrice1 <= 1 ;
          GET_MESSAGE 'Extra Payment for Status #1 Growers for Berries received'

      in window aWin @12,26 winsay '#2:' winget nPrice2 picture '99.999' ;
			 valid nPrice2 <= 1 ;
          GET_MESSAGE 'Extra Payment for Status #2 Growers for Berries Received'

      in window aWin @12,42 winsay '#3:' winget nPrice3 picture '99.999' ;
          valid nPrice3 <= 1 ;
          GET_MESSAGE 'Extra Payment for Status #3 Growers for Berries Received'

		in window aWin @14,2  winsay 'Currency:   ' winget cCurrency picture '@!' ;
		 valid validTest(V_CURRENCY,cCurrency,VT_MESSAGE) ;
       Get_Message 'Enter Canadian or US currency'

		in window aWin @16,2 winsay 'Alphabetic or Numeric Order (A/N):' ;
		 winGet cOrder PICTURE '!' valid cOrder $ 'AN' GET_MESSAGE ;
		 'A = Alphabetical list of growers by Grower Name (not Cheque Name!)'

		in window aWin @17,2 winsay 'In PayGrp Order?' ;
		 winGet lPayGrp PICTURE 'Y'

		in window aWin @18,2 winsay 'Specific PayGroup Only' winget cPayGrp ;
			when PutName(aWin,18,30,LU_PAYGRP,cPayGrp) ;
			valid PutName(aWin,18,30,LU_PAYGRP,cPayGrp) ;
			LookUp( LU_PAYGRP,  ;
         'Leave Blank to use All Payment Groups')

		in window aWin @19,2 winsay 'For Crop Year         ' winget nYr  ;
		 picture '9999' valid validAcctYear(nYr, VT_MESSAGE ) ;
		 GET_MESSAGE ;
		'The Crop Year to Which these Payments and Deductions Belong'

		in window aWin @20,2 winsay 'Specific Grower Only  ' winget nGrower ;
		 picture NumBlankPic( FLD_GROWER ) ;
       LOOKUP( LU_GROWER, ;
'Enter a Grower ID here, if you wish to generate a payment for 1 grower ONLY')

		READ

		do case
		case lastkey()==K_ESC
   		exit
		case dTo > dTranDate
			waitHand({'Transaction date can not be less', ;
			          'than the TO date!' })
			loop

   	 case year(dFrom)>year(dTo)
   		waitHand({'Season Dates are reversed!'})
   		loop
   	 case !validAcctYear(nYr,VT_MESSAGE)
   	 	loop
   	 case nYr<>year(dTo)
   	 	if !yesNo({'The Crop Year and Dates are Not the same.', ;
			 'Is this OK ?'})
	   	 	loop
			endif
   	endcase

		do while .t.
			nChoice := BsgChoice({ ;
			 'Normally, you will first generate the', ;
   	    'amounts to pay.  These will print out.', ;
	       'Then you will tell the computer to print', ;
   	    'out Cheques. You can generate the amounts', ;
   	    'to pay, and then hold back on paying until later !'}, ;
          {'Generate','Cheques','OnHolds','Cancel'})

   	   do case
          case nChoice == 0 .or. nChoice == 4
   	    	exit
	       case nChoice == 1
            if nGrower<> 0 .or. !empty(cPayGrp)
	       		if !yesno({'You have selected to create charges', ;
	       		 'for only some of the growers.  The system does', ;
	       		 'NOT prevent you from creating charges to these', ;
	       		 'Growers a second time.  Are you sure this what', ;
	       		 'you want to do ?'})
	       		 	loop
               endif
            endif

            create window at 07,10,17,60 title 'Reason for Special Payments' ;
               color colorStr(COLOR_ALT_WIN) to aAltWin
            // WinGetSet(aAltWin,WIN_BORDER_COLOR, ;
            //   COLOR_MAIN_ALT_WINDOW_BORDER)
            display window aAltWin
            in window aAltWin @ 4,5 winsay ;
               'Input the reason for special payments'
            in window aAltWin @ 5,5 winsay ;
               'Note that the system does NOT'
            in window aAltWin @ 6,5 winsay ;
               'prevent you from creating charges to these'
            in window aAltWin @ 7,5 winsay ;
               'Growers a second time.  In order to'
            in window aAltWin @ 8,5 winsay ;
               'do this you may want to enter a comment.'

            do while .t.
               in window aAltWin @ 2,5 winsay 'Reason:' winget cDesc ;
                  get_message ;
                  'Confirm this description - it will print on certain documents'
               read
               do case
               case lastkey()==K_ESC
                  exit
               case empty(cDesc)
                  if yesno({'You have no commment.', ;
                     'Do you want to enter a comment?'})
                     loop
                  endif
               endcase
               exit
            enddo
            kill window aAltWin

            if lastkey()==K_ESC
               loop
            endif

	       	if yesno({'Generate Payments ?', ;
	       	 'This procedure will produce a report of new', ;
	       	 'charges.  You should keep this for your', ;
   	    	 'audit trail.'})
		      	if selectPrn('NEWCH.TXT')
		       		if empty(nGrower)
							if SetGrow4Rpt(lPayGrp,cPayGrp,cOrder )
                        if Generate( cCurrency, cDesc )
				      	 		Cheques( cCurrency,CHEQUE_TYPE_SPECIAL, nYr, nGrower, cOrder, lPayGrp, cPayGrp, dTranDate)
				      	 		exit
				      	 	endif
			   	   	endif
			   	   else
                     Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
			   	   	if Grower->(dbSeek( str(nGrower,FLD_GROWER), HARDSEEK))
                        if Grower->onHold
                           waitHand({'This Grower is on HOLD!'})
                           loop
                        endif
                        if Generate( cCurrency, cDesc )
				      	 		Cheques( cCurrency, CHEQUE_TYPE_SPECIAL, nYr, nGrower, cOrder, lPayGrp, cPayGrp, dTranDate)
				      	 		exit
			   	   		endif
			   	   	endif
			   	   endif
		      	endif
		      endif
	       case nChoice == 2
     	 		Cheques(cCurrency,CHEQUE_TYPE_SPECIAL, nYr, nGrower, cOrder, lPayGrp, cPayGrp, dTranDate)
   	    	exit
         case nChoice == 3
            if len( aOnHold ) == 0
               waitInfo({'No one is on-hold at present'})
            else
               aChooser( 5, 20, aOnHold, NIL, 'On Holds')
            endif
	      endcase
	   enddo
	   exit
	enddo
	kill window aWin
	close databases
return( nil )


static function Generate( cCurrency, cDesc )
   local nMember, lReturn
	local nPayPrice, nQtyP, nQtyD
	local bBerry, bProcess, bGrade
	local aFound[ 8 ], lIncrement, n
	local nIncrement := 0

	if empty(cProduct)
		bBerry      := { || .t.  }
	else
		bBerry      := { || Daily->product==cProduct }
	endif

	if empty(cProcess)
		bProcess    := { || .t.  }
	else
		bProcess    := { || Daily->process==cProcess }
	endif

	if nGrade == 0
		bGrade      := { || .t.  }
	else
		bGrade      := { || Daily->grade  ==nGrade   }
	endif

	MakeTempPostDBFs()

	Select Account
   Account->(OrdSetFocus( ACCOUNT_LINK_ORD ))
   Account->(dbGoBottom())

	nAcctAud := Account->acct_uniq +1

	msgLine('Generating Charges')
   Daily->(OrdSetFocus(DAILY_GROWER_ORD))
	aHead := {'Special from '+shMDY(dFrom)+' - '+shMDY(dTo) + ;
	 iif(empty(cPayGrp),"",", PayGrp="+cPayGrp) }

	do while !Grower->(eof())
		showProg(Str(Grower->number,FLD_GROWER))

      nQtyP := nQtyD := 0

      afill(aFound, .f. )

		nMember :=  MemberStatus( Grower->number )

		if Grower->currency <> cCurrency
			if nGrower <> 0
				exit
			else
				Grower->(dbSkip())
				loop
			endif
		endif

      // iif(nMember==1, nPrice1, nPrice2)
      //    replaced on Nov 2001

      do case
      case nMember==1
         nPayPrice := nPrice1
      case nMember==2
         nPayPrice := nPrice2
      case nMember==3
         nPayPrice := nPrice3
      otherwise
         nPayPrice := 0.000
         AppError( APP_ERR_GROWER_STATUS1, ;
           { 'Grower '+lstrim(Grower->number)+' has an invalid', ;
             'status of <'+str(nMember,10,2)+'>, this grower', ;
             'will not be given a special payment' })
      endcase

		if str(nPayPrice,12,3) <> str(0,12,3) .or. ;
			str(nDeductPrice,12,3) <> str(0,12,3)

			nQtyP := nQtyD := 0
			Daily->(dbSeek( str(Grower->number,FLD_GROWER)+dtos(dFrom),SOFTSEEK))
			do while Daily->number==Grower->number .and. Daily->date<=dTo ;
					.and. !Daily->(eof())

				if str(Daily->net,12,2)<>str(0,12,2) .and. ;
						eval(bBerry) .and. eval(bProcess) ;
                  .and. eval(bGrade) .and. !Grower->onHold

					if str(nPayPrice,13,3) <> str( 0, 13, 3)
						nQtyP  += Daily->net
						TempAud->(addRecord())
						TempAud->day_uniq  := Daily->day_uniq
						TempAud->acct_uniq := nAcctAud + 1
						aFound[1] := .t.
					endif

					if !empty(cClass) .and. str(nDeductPrice,13,3) <> str( 0, 13, 3)
						nQtyD  += Daily->net
						TempAud->(addRecord())
						TempAud->day_uniq  := Daily->day_uniq
						TempAud->acct_uniq := nAcctAud + 8
						aFound[8] := .t.
					endif

				endif
				Daily->(dbSkip())
			enddo
		endif

		nIncrement := 0
		lIncrement := .f.
		for n:=1 to len(aFound)
			if aFound[n]
				nIncrement := n
            lIncrement := .t.
				// TempAcct->(dbAppend())
				TempAcct->(AddRecord())

				TempAcct->number    := Grower->number
				TempAcct->currency  := cCurrency
				TempAcct->date      := dTranDate
				tempAcct->year      := nYr
            tempAcct->desc      := cDesc
				TempAcct->acct_uniq := nAcctAud + n
				TempAcct->product   := cProduct
				TempAcct->process   := cProcess
				TempAcct->grade     := nGrade

				do case
				case n==1
					TempAcct->type    := TT_SPECIAL_BERRY
					TempAcct->u_price := nPayPrice
	      		TempAcct->lbs     := nQtyP

      		 case n==8
      			TempAcct->type    := TT_DEDUCT
      			TempAcct->u_price := -nDeductPrice
					TempAcct->class   := cClass
	      		TempAcct->lbs     := nQtyD

				endcase

      		tempAcct->dollars := round(TempAcct->u_price * TempAcct->lbs,2)
			endif
		next

		// so we can do JUST 1 GROWER !
		if nGrower <> 0
			exit
		endif

		if lIncrement
			nAcctAud += nIncrement
			nAcctAud ++
		endif

		Grower->(dbSkip())
	enddo

	lReturn := Post2Account( nAcctAud, aHead, .t. )    // this returns a logical

return( lReturn )


