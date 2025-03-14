// Crop Statement for Year (Final )
// (c) 2014, Crafted Industrial Software Ltd. and Bill Hepler
// Bill Hepler
//
// CropYear Statement New Version
// Dec 2014
// March 2019 - fix form feed at end.

#include 'sysvalue.ch'
#include 'window.ch'
#include 'valid.ch'
#include 'inkey.ch'
#include 'account.ch'
#include 'printer.ch'
#include 'BerryPay.ch'
#include 'bsgstd.ch'
#include 'common.ch'
#include 'field.ch'
#include 'indexord.ch'
#include "errors.ch"

#define    A_PRODUCT     1
#define    A_PROCESS     2
#define    A_DATE_1      3
#define    A_DATE_2      4
#define    A_THE_PRICE   5
#define    A_COMPLETE    6

#define    A_WEIGHT      7
#define    A_DOCKAGE     8

#define    A_EMPTY_ARRAY   { '','', nil, nil, 0.00, .f.,  0, 0 }


#define   PH_ALL        1
#define   PH_TOP_ONLY   2


static cLogo
static nLogoTop, nLogoLeft, nLogoWidth
static nCoTop, nCoLeft

function CropStat_2014()                           // CropStat_new()
	local aW, getList :={}, cFile, nGrower
	local nYear
	local nCheque, cSeries
	local nPage
	local cI
	local dTo
	local aBott[2]
	local nChequeTot := 0.00
	local nOwed      := 0.00
	local nNoOStran  := 0
   local lSuppress  := .t.
   local bKey, bFor, bWhile
	local aPriceQtyDone := {}, aPriceQtyNotDone := {}
	local lConfigure := .f.
	local nChoice
   local nDocs
	local cGroStatFor     := GRO_STATEMENT_FOR_CROPYEAR
	local nStatementFmtID := CROPYEAR_STATEMENT_FORMAT_2_REV_2014

	myBsgscreen('Print Crop Year Statements 2014 Format-Rev 2018'  )

	cLogo      :=  sysValue( SYS_STATEMENT_LOGO                   )
	nLogoTop   :=  sysValue( SYS_STATEMENT_LOGO_TOP               )
	nLogoLeft  :=  sysValue( SYS_STATEMENT_LOGO_LEFT              )
	nLogoWidth :=  sysValue( SYS_STATEMENT_LOGO_WIDTH             )  // zero just do in natural size
	nCoTop     :=  sysValue( SYS_STATEMENT_YOUR_NAME_ADDRESS_TOP  )
	nCoLeft    :=  sysValue( SYS_STATEMENT_YOUR_NAME_ADDRESS_LEFT )

	dTo   := date()
	nYear := sysValue(SYS_CURRENT_YEAR)
	nGrower := 0
	aFill(aBott,space(FLD_STATEMENT_NOTES))
   aBott[1] := padr( sysValue( SYS_DEFAULT_FINAL_STATEMENT_LINE1 ),FLD_STATEMENT_NOTES )
   aBott[2] := padr( sysValue( SYS_DEFAULT_FINAL_STATEMENT_LINE2 ),FLD_STATEMENT_NOTES )

	if !openMainStuff( DB_SHARED )
		close databases
		return( nil )
	endif

   create window at 4,4,22,76 title 'Statement '+ var2char( nStatementFmtID )+'. ' + StatementDesc( cGroStatFor, nStatementFmtID ) to aW

	display window aW

   in window aW @ 2,43 winSay 'Statement does not include'
	in window aW @ 3,43 winSay 'UNPOSTED weekly receipts.'

	do while .t.
   	msgLine('Print '+StatementDesc( cGroStatFor, nStatementFmtID ) )

		in window aW @ 02,2 winSay 'Up to     ' winget dTo  picture '@D' ;
			GET_MESSAGE 'Statement will include Transactions up to this Date'

		in window aW @ 03,2 winsay 'Crop Year ' winget nYear picture '9999' ;
			GET_MESSAGE 'Statements will pertain to this crop year'

      in window aW @ 05,2 winsay 'Grower ID' winget nGrower picture ;
			numBlankPic(FLD_GROWER) ;
			LOOKUP( LU_GROWER, ;
			'Enter a specific Grower to Print a Statement for one Grower Only')

      in window aW @ 06,2 winsay 'Suppress 0 Value Lines' winget ;
         lSuppress picture 'Y' get_message ;
         'Should we show account entries (eg for 0 value advances)'

		in window aW @ 08,2 winsay 'Message on bottom of Statement'
      in window aW @ 09,3 winget aBott[1]
      in window aW @ 10,3 winget aBott[2]

		if lConfigure
			in window aW @12,2 winsay 'Your Logo' winget cLogo ;
				valid ValidTest( V_FILE_LOGO, cLogo, VT_BLANK_OK_MESSAGE) ;
				lookup( LU_FILE_LOGO, ;
				"F5=Lookup or Leave Blank for no Logo. (Enter Path+File ")

			in window aW @13, 3 winsay 'Top' winget nLogoTop picture '99.99' ;
           get_message 'Position in Inches from Top of printed page (0 if you do not wish to print)'
			in window aW @13,15 winsay 'Left' winget nLogoLeft picture '99.99' ;
           get_message 'Position in Inches from Left of printed page (0 if you do not wish to print)'
			in window aW @13,30 winsay 'Width' winget nLogoWidth picture '99.999' ;
           get_message 'Width of Logo in Inches (0 prints at Image Size)'

			in window aW @15, 2 winsay 'Location for Your Address if not on Logo'
			in window aW @16, 3 winsay 'Top' winget nCoTop picture '99.99' ;
           get_message 'Position in Inches from Top of printed page (0 if you do not wish to print)'
			in window aW @16,15 winsay 'Left' winget nCoLeft picture '99.99' ;
           get_message 'Position in Inches from Left of printed page (0 if you do not wish to print)'
		else
			in window aW @12,2 winsay 'Your Logo '+ cLogo
			in window aW @13, 3 winsay 'Top ' + str(nLogoTop,5,2)
			in window aW @13,15 winsay 'Left ' + str(nLogoLeft,5,2)
			in window aW @13,30 winsay 'Width ' + str(nLogoWidth,6,3)

			in window aW @15, 2 winsay 'Location for Your Address if not on Logo'
			in window aW @16, 3 winsay 'Top ' + str( nCoTop,5,2)
			in window aW @16,15 winsay 'Left ' + str( nLogoLeft,5,2)
		endif
		read

		if lastkey() == K_ESC
			exit
		endif

		nChoice := thinChoice({'Print','Configure','X-eXit'})
		do case
		case nChoice == 2
			lConfigure := .t.
			loop
		case nChoice == 3 .or. nChoice == 0
			exit
		endcase

		if selectPrn('STATE_2.TXT')
      	msgLine('Preparing Crop Year Statement to Print...')

			cFile := UniqueFile()
			if empty(cFile)
				waitHand({'Please REINDEX files and delete', ;
					'temporary files'})
				loop
			endif

			dbSelectArea('ACCOUNT')

			if !empty(nGrower)
            Account->(OrdSetFocus( ACCOUNT_NUMBER_ORD ))
				Account->(dbSeek( str(nGrower, FLD_GROWER), HARDSEEK ))

            bKey := { ||  AcctHeading() + Account->type + Account->class + ;
                          Account->product + Account->process + ;
                          str( Account->grade, FLD_GRADE ) +  ;
                          dtos( Account->date ) }
            bWhile :=  { || Account->number==nGrower }
            if lSuppress
               bFor := { || Account->year=nYear .and. ;
                         !(Account->dollars == 0.00 .and. ;
                         Account->u_price==0.000) .and. ;
                         Account->type <> TT_ADV_CONTAINER_ONLY .and. ;
                         Account->date <= dTo  }
            else
               bFor :=  { || Account->year=nYear .and. ;
                          Account->type <> TT_ADV_CONTAINER_ONLY .and. ;
                         Account->date <= dTo }
            endif

			else
            Account->(OrdSetFocus( ACCOUNT_DATE_ORD ))
				// make sure we get them ALL
				Account->(dbSeek( str(nYear-1,4), SOFTSEEK ))
            bKey := { || str(Account->number, FLD_GROWER)+ ;
                  AcctHeading() + Account->type + Account->class + ;
                  Account->product + Account->process + ;
                  str( Account->grade, FLD_GRADE ) +  ;
                  dtos( Account->date ) }

            bWhile := { || Account->date <= dTo }
            if lSuppress
               bFor :={ || Account->year==nYear .and. ;
                  !(Account->dollars == 0.00 .and. Account->u_price==0.000) ;
                  .and. ;
                  Account->type <> TT_ADV_CONTAINER_ONLY }
            else
               bFor := { || Account->year==nYear .and. ;
                  Account->type <> TT_ADV_CONTAINER_ONLY }
            endif

			endif
         SubsetBuilder ( cFile, 'Account', bKey, bFor, bWhile )

         Cheque->(OrdSetFocus( CHEQUE_CHEQUE_NO_ORD ))

			// Now we do the Transactions
			msgLine('Hang on...looking at Transactions to cross check...')

         // Account->(dbGoTop())
         (cFile)->(dbGoTop())

			cI := space(1)

			PRINT_ON  RPT_OVERWRITE

         // do while !Account->(eof())
         nDocs := 0
         do while !(cFile)->(eof())

				nGrower := Account->number
				if !ValidTest( V_GROWER, nGrower, VT_MESSAGE )
					Grower->(dbGoBottom())
					if !Grower->(eof())
						Grower->(dbSkip())             // we are at EOF()
					endif
				endif
				nChequeTot := 0.00
				nOwed      := 0.00
				nNoOStran  := 0

            // March 2019 - form feed fix
            if nDocs >= 1
            	nuFormFeed()
            endif
            nDocs++

				nPage   := 1
				PageHeader( PH_TOP_ONLY, nPage, dTo, nYear )

				// Now put the Other Info
				Daily->(dbSeek( str( nGrower, FLD_GROWER), HARDSEEK ))
				ShowProg( 'D'+str(nGrower,FLD_GROWER ) )

				aPriceQtyDone     := {}
				aPriceQtyNotDone  := {}

				do while !Daily->(eof()) .and. Daily->number == nGrower
					if !empty( Daily->product ) .and. ;
					     (num2NotEqual0(Daily->net) .or. num2NotEqual0( Daily->ori_net ))
						if Daily->fin_Bat > 0 .and. Daily->fin_pr_id > 0
							SetArray( aPriceQtyDone, .t. )
						else
							SetArray( aPriceQtyNotDone, .f. )
						endif
					endif
					Daily->(dbSkip())
				enddo

				do case
				case empty( aPriceQtyDone ) .and. empty( aPriceQtyNotDone)
					nuQprnOut( )
					nuQprnOut( cI + 'No berries received')
					nuQprnOut()

				case empty( aPriceQtyDone )
					nuQprnOut( )
					nuQprnOut( cI + 'Partial Payments Only - no final payouts made')
					nuQprnOut()

				otherwise
					if len( aPriceQtyDone ) > 40

						nPage := DeliveryTotals( aPriceQtyDone , cI, nPage, dTo, nYear )

					else
						if NearPageBottom( len( aPriceQtyDone)+ 9 )
							nuQprnOut('')
							nuQprnOut( cI + '   Continued....')
							nuFormFeed()
							nPage++
							PageHeader( PH_TOP_ONLY, nPage, dTo, nYear )
						endif

						nPage := DeliveryTotals( aPriceQtyDone , cI, nPage, dTo, nYear )

					endif

					if !empty( aPriceQtyNotDone )
							nuQprnOut('')
							nuQprnOut( cI + '   There are also berries that are not paid out in full....')
					endif
				endcase

				ShowProg( 'A '+str(nGrower,FLD_GROWER))

				PHskinny(  )
            do while !(cFile)->(eof()) .and. nGrower==Account->number
					cSeries := Account->series
					nCheque := Account->cheque

					if nCheque==0
                  nuQprnOut( cI + 'Outstanding Amounts:' )
					else
						if !Cheque->(dbSeek( ;
								cSeries + str(nCheque, FLD_CHEQUE ), HARDSEEK))

							appError(APP_ERR_STATE_CHQ_NOT_FND , ;
								{ 'Cheque Not Found '+cSeries + str(nCheque,10), ;
								'Grower '+str(nGrower,10) })
                     nuQprnOut( cI )
						else
                     nuQprnOut( cI+ str(nCheque,8) )
                     nuQQprnOut( ' ' )
                     nuQQprnOut( padr( shMDY( Cheque->date ),14) )
							if SysValue( SYS_ALLOW_US_DOLLARS ) .and. ;
									SysValue( SYS_ALLOW_CANADIAN_DOLLARS )
                        nuQQprnOut( padr( iif(Cheque->currency=='C', ;
									'Canadian Dollars', ;
                           'U.S. Dollars'), 90) )
							else
                        nuQQprnOut( space( 90 ) )
							endif

							if !Cheque->VOID
                        nuQQprnOut( transform( Cheque->amount, '$9,999,999.99' ) )
								nChequeTot += Cheque->amount
							else
								//  $9,999,999.99'
                        nuQQprnOut( ' *** VOID ***' )
							endif
						endif
					endif

               // do while !Account->(eof()) .and. nGrower==Account->number ;
               do while !(cFile)->(eof()) .and. nGrower==Account->number ;
							.and. Account->series==cSeries .and. ;
							Account->cheque==nCheque

                  if NearPageBottom( 14 )
                     nuFormFeed()
							nPage++
							PageHeader( PH_ALL, nPage, dTo, nYear )
							if nCheque==0
                        nuQprnOut( cI+'Outstanding amounts continued....' )
							else
                        nuQprnOut( ;
                          cI+'Cheque '+str(nCheque,8)+'  continued....' )
							endif
						endif

                  nuQprnOut( cI+space(8)+' ' )
						if nCheque==0
							nOwed      += (Account->dollars + Account->gst_est)
							nNoOStran  ++
						endif

						if PrnAccInfoNext() .and. !empty( Account->desc )
                     nuQprnOut( cI+space(8)+' '+space(15)+Account->desc )
						endif

                  (cFile)->(dbSkip())
					enddo
               nuQprnOut(  ' '  )       // blank line between cheques
				enddo

            if NearPageBottom( 14 )
               nuFormFeed()
					nPage++
					PageHeader( PH_ALL, nPage, dTo, nYear )
               nuQprnOut( cI+'Statement Summary to Follow:' )
				endif

            nuQprnOut( cI + padr('TOTAL AMOUNT OF CHEQUES WRITTEN:',113) )
            nuQQprnOut( transform( nChequeTot, '$9,999,999.99' ) )

				if nNoOStran > 0
               nuQprnOut( )
					do case
					case str(nOwed,12,2)==str(0,12,2)
                  nuQprnOut( cI+space(9)+'No net amount owed to grower.' )
					case nOwed > 0.00
                  nuQprnOut( cI+ padr( ;
							rTrim( TheClientName() )+ ;
                     ' owes to GROWER ', 113 ) )
                  nuQQprnOut( transform( nOwed, '$9,999,999.99' ) )
					otherwise
						// nOwed is Less
                  nuQprnOut( cI+ padr( 'Grower still owes '+ TheClientName(), 113 ) )
                  nuQQprnOut( transform( -nOwed, '$9,999,999.99' ) )
					endcase
               nuQprnOut( )
				endif

				nuQprnOut()
				PrinterCtrl( PRN_CTRL_10_CPI )
				if !empty(aBott[1]) .or. !empty(aBott[2])
               if NearPageBottom( 8 )
                  nuFormFeed()
						nPage++
						PageHeader( PH_ALL, nPage, dTo, nYear )
					endif
					nuQprnOut( )
               nuQprnOut( cI + '  Note:  '+ aBott[1] )
               nuQprnOut( cI + '         '+ aBott[2] )
					nuQprnOut( )
				endif

            nuQprnOut( cI + ;
             'Statement does not include unposted berry receipts' )

            // nuFormFeed()  - not needed March 2019
			enddo

			PRINT_OFF  RPT_COMPLETE_NO_EJECT

			Account->(dbCloseArea())
         KillUnique(cFile )
         cFile := ''

			if !openFile({'Account'}, DB_SHARED )
				exit
			endif
		endif

		if lConfigure
			if Yesno({'Save this configuration for Logo Position etc... ?'})
				PutSysValue( SYS_STATEMENT_LOGO                   , cLogo     )
				PutSysValue( SYS_STATEMENT_LOGO_TOP               , nLogoTop  )
				PutSysValue( SYS_STATEMENT_LOGO_LEFT              , nLogoLeft )
				PutSysValue( SYS_STATEMENT_LOGO_WIDTH             , nLogoWidth )
				PutSysValue( SYS_STATEMENT_YOUR_NAME_ADDRESS_TOP  , nCoTop    )
				PutSysValue( SYS_STATEMENT_YOUR_NAME_ADDRESS_LEFT , nCoLeft   )
			endif
		endif
	enddo
	kill window aW
	close databases
return( nil )


static function bhDiv( nX, nY )
	local nReturn
	if nY==0
		nReturn := 0
	else
		nReturn := nX /nY
	endif
return( nReturn )


static function PageHeader( nPHwhat, nPage, dTo, nYear )
	local cI := ' '
	local nLen
	local aRay

	default nPHwhat to PH_ALL

	nLen := 78-len(cI)-60


	PrinterCtrl( PRN_CTRL_10_CPI )
	if gsNuPrinterType( ) == NUPRINT_PRN_TYPE_W32FIXED .and. ;
	   (!empty( cLogo ) .or.  (nCoTop > 0 .and. nCoLeft > 0 ))

		nuQprnOut( )
		nuQprnOut( cI + padr('',60) + ;
			padl('Page'+str(nPage,3),nLen)         )

		nuQprnOut( cI + padr('',60) + ;
			padl('CROP YEAR '+str(nYear,4), nLen)  )

		nuQprnOut( cI + padr( '',60) + ;
			padl('SUMMARY STATEMENT', nLen)        )

		nuQprnOut( cI + padr('',60) + ;
			padl( "As of "+shMDY(dTo), nLen )        )

		nuQprnOut( )
		nuQprnOut( )
		nuQprnOut( cI + 'Grower: '+str(Grower->number, 5)+' '+Grower->name )
		nuQprnOut( cI+space(14) + Grower->STREET )
		if !empty( Grower->street2)
			nuQprnOut( cI+space(14) + Grower->STREET2 )
		endif
		nuQprnOut( cI+space(14) + alltrim(Grower->CITY)+', '+Grower->prov )
		nuQprnOut( cI+space(14) + Grower->PCODE )

		nuQprnOut( )

		// Print the Logo !
		// 		W32prnImage( Site->iLogo, InvCfg->logoX, InvCfg->logoY )
		// function W32PrnImage( xImage, nTopLeftXinch, nTopLeftYinch  )
		if nLogoLeft > 0 .and. nLogoTop > 0 .and. !empty( cLogo )
			W32prnImage( cLogo, nLogoLeft, nLogoTop, ;
			 iif( nLogoWidth >= 0.1, nLogoLeft + nLogoWidth,0)			)
		endif

		if nCoLeft > 0 .and. nCoTop > 0
			aRay := { allTrim( TheClientName() ) }
			if !empty( sysValue(SYS_ACTUAL_ADDRESS1) )
				aadd( aRay, alltrim( sysValue(SYS_ACTUAL_ADDRESS1) ))
			endif
			if !empty( sysValue(SYS_ACTUAL_ADDRESS2) )
				aadd( aRay, alltrim( sysValue(SYS_ACTUAL_ADDRESS2) ))
			endif
			if !empty( sysValue(SYS_ACTUAL_ADDRESS3) )
				aadd( aRay, alltrim( sysValue(SYS_ACTUAL_ADDRESS3) ))
			endif

			if len( alltrim(sysValue( SYS_ACTUAL_PHONE ))) >= 7
				aadd( aRay, '')
				aadd( aRay, alltrim( sysValue(SYS_ACTUAL_PHONE) ))
			endif

			W32PrnTextArray( aRay, nCoLeft, nCoTop , 1/6 )   // Oh, dear not consistent!

		endif

	else
		nuQprnOut( )
		nuQprnOut( cI + padr(TheClientName(),60) + ;
			padl('Page'+str(nPage,3),nLen)         )

		nuQprnOut( cI + padr(sysValue(SYS_ACTUAL_ADDRESS1),60) + ;
			padl('CROP YEAR '+str(nYear,4), nLen)  )

		nuQprnOut( cI + padr( sysValue(SYS_ACTUAL_ADDRESS2),60) + ;
			padl('SUMMARY STATEMENT', nLen)        )

		nuQprnOut( cI + padr(sysValue(SYS_ACTUAL_ADDRESS3),60) + ;
			padl( "As of "+shMDY(dTo), nLen )        )

		nuQprnOut( )
		nuQprnOut( )
		nuQprnOut( cI + 'Grower: '+str(Grower->number, 5)+' '+Grower->name )
		nuQprnOut( cI+space(14) + Grower->STREET )
		if !empty( Grower->street2)
			nuQprnOut( cI+space(14) + Grower->STREET2 )
		endif
		nuQprnOut( cI+space(14) + alltrim(Grower->CITY)+', '+Grower->prov )
		nuQprnOut( cI+space(14) + Grower->PCODE )

		nuQprnOut( )
	endif

	if nPHwhat ==  PH_ALL
		PHskinny( )
	endif

return( nil )


static function PHskinny(  )
	local cI := space( 1 )

	PrinterCtrl( PRN_CTRL_17_CPI )
   nuQprnOut( )
   nuQprnOut( cI+space(116)+padl('CHEQUE',10) )

   nuQprnOut( cI+padl('Cheque #',8)+' '       )
   nuQQprnOut( padr('Date',14)     )

   nuQQprnOut( padc('Notes',57)    )                 //  80
   nuQQprnOut( padr('LBS',10)      )                 //  90
   nuQQprnOut( padr('Rate',10)     )                 // 100
   nuQQprnOut( space(16)           )                 // 116
   nuQQprnOut( padl('AMOUNT',10)   )
   nuQprnOut( )

return( nil )



static function PrnAccInfoNext()
	local lPrnNext := .t.

	do case
	case Account->type ==  TT_DEDUCT
      nuQQprnOut( padr('Deduction '+NameOf(LU_DEDUCTION_CLASS, Account->class)+ ;
         ' as of '+shMDY(Account->date),55) )

   case Account->type ==  TT_BERRY_ADVANCE_1

		//                123456789_1  +  10 + 1 + 19 + 1 + 2 + 1   -- around 43 char at most..
      nuQQprnOut( padr('1st Adv to '+shMDY(Account->date)+' '+ ;
			NameOf(LU_PRODUCT, Account->product)+ ;
         ' '+Account->process+GradeStr(Account->grade),55) )

		lPrnNext := .f.                            // don't print comment anyway

   case Account->type ==  TT_BERRY_ADVANCE_2

      nuQQprnOut( padr('2nd Adv to '+shMDY(Account->date)+' '+ ;
			NameOf(LU_PRODUCT, Account->product)+ ;
         ' '+Account->process+GradeStr(Account->grade),55) )

		lPrnNext := .f.                            // don't print comment anyway

   case Account->type ==  TT_BERRY_ADVANCE_3

      nuQQprnOut( padr('3rd Adv to '+shMDY(Account->date)+' '+ ;
			NameOf(LU_PRODUCT, Account->product)+ ;
         ' '+Account->process+GradeStr(Account->grade),55)  )

		lPrnNext := .f.                            // don't print comment anyway

   case Account->type ==  TT_FINAL_BERRY

      nuQQprnOut( padr('Final Pay on '+ shMDY(Account->date)+' '+ ;
			NameOf(LU_PRODUCT, Account->product)+ ;
         ' '+Account->process+GradeStr(Account->grade),55)  )

		lPrnNext := .f.                            // don't print comment anyway

   case Account->type ==  TT_TIME_PREMIUM
      nuQQprnOut( padr('Time Premium to ' + shMDY(Account->date)+' '+ ;
			NameOf(LU_PRODUCT,Account->product)+ ;
         ' '+Account->process+GradeStr(Account->grade),55)   )


   case Account->type ==  TT_STD_DEDUCTION
      nuQQprnOut( padr('Marketing Deduction '+shMDY(Account->date)+' '+ ;
			NameOf(LU_PRODUCT, Account->product)+ ;
         ' '+Account->process+GradeStr(Account->grade),55)   )

		lPrnNext := .f.                            // don't print comment anyway

	case Account->type ==  TT_SPECIAL_BERRY
      nuQQprnOut( padr('Special Payment to '+shMDY(Account->date)+' '+ ;
			NameOf(LU_PRODUCT, Account->product)+ ;
         ' '+Account->process+GradeStr(Account->grade),55)    )

	case Account->type ==  TT_SPECIAL_CONTAINER
      nuQQprnOut( padr('Container Charge',55) )

	case Account->type ==  TT_EQUITY
      nuQQprnOut( padr('Equity Payment',55)   )

	case Account->type ==  TT_MISCELLANEOUS
		do case
		case !empty(Account->product)
         nuQQprnOut( padr('Miscellaneous '+ ;
				NameOf(LU_PRODUCT, Account->product)+ ;
            ' '+Account->process+GradeStr(Account->grade),55) )
		case Account->dollars + Account->gst_Est <= -.01
         nuQQprnOut( padr('Miscellaneous Deduction',55)       )
		case Account->dollars + Account->gst_Est >= 0.01
         nuQQprnOut( padr( ;
          'Owed to Grower - Misc. Entry on '+shMDY(Account->date),55) )
		otherwise
         nuQQprnOut( padr('Miscellaneous',55) )
		endcase

	otherwise
		if validTest( V_TRANSACTION_TYPE, Account->type, ;
				VT_MESSAGE )
         nuQQprnOut( padr( NameOf(LU_TRANSACTION_TYPE, Account->type)+' '+ ;
            shMDY(Account->date),55 ) )
		else

         nuQQprnOut( padr(Account->type+ ' '+shMDY(Account->date), 55) )

			// Corrected July 2014
			appError(APP_ERR_UNEXPECTED_AC_TYPE, ;
				Account->type+' on Grower '+str(Account->number,6) )
		endif
	endcase

	if str(Account->lbs,12) <> str(0,12) .and. ;
			str(Account->u_price,12,3) <> str(0,12,3)

      nuQQprnOut( ' for '+transform(Account->lbs,'999,999,999') + ;
         ' '+sysValue(SYS_UNITS_OF_WEIGHT)  )
      nuQQprnOut( ' @ '+rtrim( UnitPrDec(Account->u_price) ) )
	endif

   //Nov 2001 - widened so we can do One Million Dollar + transactions
   // and deal with NEGATIVES correctly.
   // do while pCol() < 98
   do while nuPrnColumn() < 98
      nuQQprnOut( ' ' )
	enddo

   nuQQprnOut( transform(Account->dollars ,'99,999,999.99') )

return( lPrnNext )

static function SetArray( aPriceQty, lComplete )
	local n, nRow := 0

	for n:=1 to len( aPriceQty )
		if lComplete
			if Daily->product == aPriceQty[n, A_PRODUCT ]    .and. ;
				Daily->process == aPriceQty[n, A_PROCESS ] .and. ;
				str(Daily->fin_price ,12,4) == str(aPriceQty[n, A_THE_PRICE],12,4)
				nRow := n
				exit
			endif
		else
			if Daily->product == aPriceQty[n, A_PRODUCT ]    .and. ;
				Daily->process == aPriceQty[n, A_PROCESS ] .and. ;
				str(Daily->adv_pr1 + Daily->adv_pr2 + Daily->adv_pr3,12,4) == str(aPriceQty[n, A_THE_PRICE],12,4)
				nRow := n
				exit
			endif
		endif
	next

	if num2Equal0( nRow )
		aadd( aPriceQty, A_EMPTY_ARRAY )
		nRow := len( aPriceQty)
		aPriceQty[ nRow, A_PRODUCT  ]     := Daily->product
		aPriceQty[ nRow, A_PROCESS  ]     := Daily->process
		if lComplete
			aPriceQty[ nRow, A_THE_PRICE ] := Daily->fin_price
		else
			aPriceQty[ nRow, A_THE_PRICE ] := Daily->adv_pr1 + Daily->adv_pr2 + Daily->adv_pr3
		endif
		aPriceQty[ nRow, A_DATE_1   ]     := Daily->date
		aPriceQty[ nRow, A_DATE_2   ]     := Daily->date
	endif
	if Daily->date < aPriceQty[ nRow, A_DATE_1   ]
		aPriceQty[ nRow, A_DATE_1   ]     := Daily->date
	endif
	if Daily->date > aPriceQty[ nRow, A_DATE_2   ]
		aPriceQty[ nRow, A_DATE_2   ]     := Daily->date
	endif
	aPriceQty[ nRow, A_WEIGHT ]          += Daily->net
	aPriceQty[ nRow, A_DOCKAGE ]         += (Daily->Ori_net - Daily->net)

return( nil )

static function WriteArray( nGrow, aPriceQty, cFile )
	local n

	for n:=1 to len( aPriceQty )
		(cFile)->(dbAppend())
		(cFile)->grower   := nGrow
		(cFile)->product  :=	aPriceQty[ n, A_PRODUCT   ]
		(cFile)->process  := aPriceQty[ n, A_PROCESS   ]
		(cFile)->price    := aPriceQty[ n, A_THE_PRICE ]
		(cFile)->date1    := aPriceQty[ n, A_DATE_1    ]
		(cFile)->date2    := aPriceQty[ n, A_DATE_2    ]
		(cFile)->net      := aPriceQty[ n, A_WEIGHT    ]
		(cFile)->docked   := aPriceQty[ n, A_DOCKAGE   ]
	next

return( nil )

// This assumes there is Something to Print
static function DeliveryTotals( aPriceQty , cI, nPage, dTo, nYear )
	local n
	local nReturn
	local nProdWt := 0, nTotWt := 0
	local nCnt    := 0
	local cRowHead
	local cP4Subs
	local cProduct, cProcess
	local nProducts := 0
	local bBlock

	nReturn := nPage

	aSort( aPriceQty, nil, nil , { |aX,aY| aX[A_PRODUCT] + aX[A_PROCESS] + dtos(aX[A_DATE_1]) < ;
	                                       aY[A_PRODUCT] + aY[A_PROCESS] + dtos(aY[A_DATE_1]) } )

	// if we have multiple products, we total on products
	//  otherwise we total on Process.
	cProduct := 'xq'

	for n := 1 to len( aPriceQty )
		if cProduct <> aPriceQty[n, A_PRODUCT ]
			nProducts++
			cProduct := aPriceQty[n, A_PRODUCT ]
		endif
	next

	// We subtotal on Product only or Product + Process

	if nProducts > 1
		bBlock := { | i | aPriceQty[ i, A_PRODUCT ] }
	else
		bBlock := { | i | aPriceQty[ i, A_PRODUCT ] + aPriceQty[ i, A_PROCESS ] }
	endif
	cP4Subs   := eval( bBlock, 1)    // This array must have data in it or we would not be here!


	cRowHead := cI +'  '+padr( 'Product / Process', FLD_PRODDESC + FLD_PROCDESC + 1) + ;
					            padc('-- Dates --', 6 + 1 + 3+1+2+1+2 ) + space( 2 ) + ;
									padl('Price',10+2) + padl('Weight',10) + padl('Total Wt',10)

	nuQprnOut('')
	PrinterCtrl( PRN_CTRL_12_CPI )
	nuQprnOut(cI + 'Overall Summary')
	nuQprnOut( cRowHead )
	cProduct := 'q\'
	cProcess := 'r\'
	for n := 1 to len( aPriceQty)
		if !(cP4Subs == eval( bBlock, n))
			// if nCnt > 1
				nuQQprnOut(  ' '+transform( nProdWt,'99,999,999') )
			// else
			//	nuQQprnOut(  '  '+ padc('*',10) )
			// endif
			cP4Subs  := eval( bBlock, n)
			nCnt     := 0
			nProdWt  := 0
		endif

		if NearPageBottom( len( aPriceQty)+5 )
			nuQprnOut('')
			nuQprnOut( cI + '   Continued....')
			nuFormFeed()
			nPage++
			PageHeader( PH_TOP_ONLY, nPage, dTo, nYear )
			nuQprnOut('')
			PrinterCtrl( PRN_CTRL_12_CPI )
			nuQprnOut(cI + 'Overall Summary Continued...')
			nuQprnOut( cRowHead )
			// We always want to print the Product and process at top of page
			cProduct := 'q\'
			cProcess := 'r\'
		endif

		// This is set up to make it easy to show or not the process & product
		// descriptions.
		do case
		case cProduct <> aPriceQty[n, A_PRODUCT]

			nuQprnOut( cI+'  '+NameOf( LU_PRODUCT, aPriceQty[n, A_PRODUCT])+' ' +  ;
			  NameOf( LU_PROCESS_TYPE, aPriceQty[n, A_PROCESS] )+ '  '+ ;
			  substr(shMdy( aPriceQty[n, A_DATE_1]),1,6) +'-'+shMdy( aPriceQty[n, A_DATE_2])+'  ' + ;
			  DollarStr( aPriceQty[n, A_THE_PRICE ],10) + ;
			  transform( aPriceQty[n, A_WEIGHT ],'99,999,999') )

		case cProcess <> aPriceQty[n, A_PROCESS]

			nuQprnOut( cI+'  '+ space( FLD_PRODDESC ) +'-' +  ;
			  NameOf( LU_PROCESS_TYPE, aPriceQty[n, A_PROCESS] )+ '  '+ ;
			  substr(shMdy( aPriceQty[n, A_DATE_1]),1,6) +'-'+shMdy( aPriceQty[n, A_DATE_2])+'  ' + ;
			  DollarStr( aPriceQty[n, A_THE_PRICE ],10) + ;
			  transform( aPriceQty[n, A_WEIGHT ],'99,999,999') )

		otherwise
			nuQprnOut( cI+'  '+ space( FLD_PRODDESC ) +'-' +  ;
			  NameOf( LU_PROCESS_TYPE, aPriceQty[n, A_PROCESS] )+ '  '+ ;
			  substr(shMdy( aPriceQty[n, A_DATE_1]),1,6) +'-'+shMdy( aPriceQty[n, A_DATE_2])+'  ' + ;
			  DollarStr( aPriceQty[n, A_THE_PRICE ],10) + ;
			  transform( aPriceQty[n, A_WEIGHT ],'99,999,999') )
		endcase

		cProduct := aPriceQty[ n, A_PRODUCT ]
		cProcess := aPriceQty[ n, A_PROCESS ]

		nCnt++
		nProdWt  += aPriceQty[n, A_WEIGHT ]
		nTotWt   += aPriceQty[n, A_WEIGHT ]
	next

	// if nCnt > 1
		nuQQprnOut(  ' '+transform( nProdWt,'99,999,999') )
	// else
	//	nuQQprnOut(  '  '+ padc('*',10) )
	// endif

	if str(nTotWt,12,2) <> str(nProdWt,12,2)
		nuQPrnOut( cI +'  '+padr( 'TOTAL:', FLD_PRODDESC + FLD_PROCDESC + 1) + ;
					            space(  6 ) +' '+ space( 3+1+2+1+2 )+ space( 2 ) + ;
									space(10+3) + space( 10) + transform( nTotWt,'99,999,999') )
	endif

	PrinterCtrl( PRN_CTRL_17_CPI )
	nReturn := nPage

return( nReturn )
