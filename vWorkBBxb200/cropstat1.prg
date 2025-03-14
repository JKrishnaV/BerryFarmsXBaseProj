// CropStat1.prg - OLD Version
// (c) 1994, 2014 Crafted Industrial Software Ltd. and Bill Hepler
// Bill Hepler
//
// CropYear Statement
// this is produced AFTER the weekly harvest "advances" have been paid
// Oct  99 - Total ReWrite to Show Grower statement as per Grower Ledger
// Jun  2000 - Minor Change...
// Aug 2010 - INDEX ON is whacked I am fixing this.
// Sep 2012 - Minor Fix to get alignment a little nicer
// Dec 2014 - Now obsolete. see Cropstat2.prg

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

function CropStat_Old()
	local aWin, getList :={}, cFile, nGrower
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
	local cGroStatFor     := GRO_STATEMENT_FOR_CROPYEAR
	local nStatementFmtID := CROPYEAR_STATEMENT_FORMAT_1_OLD

	if !(yesno({'As of 2014, we now have a new version of the Crop Statement', ;
	          'The new version has additional information available and', ;
				 'allows you to place your company logo on the statement.', ;
				 'This version is included mainly for you to reproduce an old', ;
				 'statement exactly as the grower would have seen it.', '', ;
				 'Do you wish to continue?'}))
		return( nil )
	endif

	myBsgscreen('Print Old Version of Crop Year Statements' )

	dTo   := date()
	nYear := sysValue(SYS_CURRENT_YEAR)
	nGrower := 0
	aFill(aBott,space( FLD_STATEMENT_NOTES))
   aBott[1] := padr( sysValue( SYS_DEFAULT_FINAL_STATEMENT_LINE1 ),FLD_STATEMENT_NOTES )
   aBott[2] := padr( sysValue( SYS_DEFAULT_FINAL_STATEMENT_LINE2 ),FLD_STATEMENT_NOTES )

	if !openMainStuff( DB_SHARED )
		close databases
		return( nil )
	endif

   create window at 6,5,18,73 title 'Statement '+ var2char( nStatementFmtID )+'. ' + StatementDesc( cGroStatFor, nStatementFmtID ) to aWin
	display window aWin

   in window aWin @ 12,2 winSay ;
		'Statement does not include UNPOSTED weekly receipts'

	do while .t.
   	msgLine('Print '+StatementDesc( cGroStatFor, nStatementFmtID ) )

		in window aWin @ 02,5 winSay 'Up to     ' winget dTo  picture '@D' ;
			GET_MESSAGE 'Statement will include Transactions up to this Date'

		in window aWin @ 03,5 winsay 'Crop Year ' winget nYear picture '9999' ;
			GET_MESSAGE 'Statements will pertain to this crop year'

      in window aWin @ 05,5 winsay 'Grower ID' winget nGrower picture ;
			numBlankPic(FLD_GROWER) ;
			LOOKUP( LU_GROWER, ;
			'Enter a specific Grower to Print a Statement for one Grower Only')

      in window aWin @ 06,5 winsay 'Suppress 0 Value Lines' winget ;
         lSuppress picture 'Y' get_message ;
         'Should we show account entries (eg for 0 value advances)'

      in window aWin @ 08,5 winsay 'Message on bottom of Statement'
      in window aWin @ 09,6 winget aBott[1]
      in window aWin @ 10,6 winget aBott[2]

		read
		if lastkey() == K_ESC
			exit
		endif

		if selectPrn('STATE_1.TXT')
      	msgLine('Preparing Crop Year Statement to Print...')

			cFile := UniqueFile()
			if empty(cFile)
				waitHand({'Please REINDEX files and delete', ;
					'temporary files'})
				loop
			endif

			dbSelectArea('ACCOUNT')

			// 2BFIXED  2 BE FIXED JUNE 2010

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

            /* -----------
            if lSuppress
               index on ;
                  AcctHeading() + Account->type + Account->class + ;
                  Account->product + Account->process + ;
                  str( Account->grade, FLD_GRADE ) +  ;
                  dtos( Account->date ) ;
                  to (cFile) for Account->year=nYear .and. ;
                  !(Account->dollars == 0.00 .and. Account->u_price==0.000) ;
                  .and. ;
                  Account->type <> TT_ADV_CONTAINER_ONLY .and. ;
                  Account->date <= dTo while Account->number==nGrower
            else
               index on ;
                  AcctHeading() + Account->type + Account->class + ;
                  Account->product + Account->process + ;
                  str( Account->grade, FLD_GRADE ) +  ;
                  dtos( Account->date ) ;
                  to (cFile) for Account->year=nYear .and. ;
                  Account->type <> TT_ADV_CONTAINER_ONLY .and. ;
                  Account->date <= dTo while Account->number==nGrower
            endif
            ----------------- */
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

            /* ---------------
            if lSuppress
               index on str(Account->number, FLD_GROWER)+ ;
                  AcctHeading() + Account->type + Account->class + ;
                  Account->product + Account->process + ;
                  str( Account->grade, FLD_GRADE ) +  ;
                  dtos( Account->date ) ;
                  to (cFile) for Account->year==nYear .and. ;
                  !(Account->dollars == 0.00 .and. Account->u_price==0.000) ;
                  .and. ;
                  Account->type <> TT_ADV_CONTAINER_ONLY while Account->date ;
                  <= dTo
            else
               index on str(Account->number, FLD_GROWER)+ ;
                  AcctHeading() + Account->type + Account->class + ;
                  Account->product + Account->process + ;
                  str( Account->grade, FLD_GRADE ) +  ;
                  dtos( Account->date ) ;
                  to (cFile) for Account->year==nYear .and. ;
                  Account->type <> TT_ADV_CONTAINER_ONLY while Account->date ;
                  <= dTo
            endif
            ----------------------------- */

			endif
         SubsetBuilder ( cFile, 'Account', bKey, bFor, bWhile )

         Cheque->(OrdSetFocus( CHEQUE_CHEQUE_NO_ORD ))

         // Account->(dbGoTop())
         (cFile)->(dbGoTop())

			cI := space(1)

			PRINT_ON  RPT_OVERWRITE

         // do while !Account->(eof())
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

            // setPrc( 0, 0 )
				nPage   := 1
				PageHeader( nPage, dTo, nYear )

            // while !Account->(eof()) .and. nGrower==Account->number
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

                  // if nuPrnRow() > 55
                  if NearPageBottom( 14 )
                     nuFormFeed()
							nPage++
							PageHeader( nPage, dTo, nYear )
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

                  //Account->(dbSkip())
                  (cFile)->(dbSkip())
					enddo
               nuQprnOut(  ' '  )       // blank line between cheques
				enddo

            // if nuPrnRow() > 55
            if NearPageBottom( 14 )
               nuFormFeed()
					nPage++
					PageHeader( nPage, dTo, nYear )
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

				if !empty(aBott[1]) .or. !empty(aBott[2])
               if NearPageBottom( 10 )
                  nuFormFeed()
						nPage++
						PageHeader( nPage, dTo, nYear )
					endif

               nuQprnOut( cI + '  Note:  '+ aBott[1] )
               nuQprnOut( cI + '         '+ aBott[2] )
				endif

            nuQprnOut( )
            nuQprnOut( cI + ;
             'Statement does not include unposted berry receipts' )

            nuFormFeed()
			enddo

			PRINT_OFF  RPT_COMPLETE_NO_EJECT

			Account->(dbCloseArea())
         KillUnique(cFile )
         cFile := ''

			if !openFile({'Account'}, DB_SHARED )
				exit
			endif
		endif
	enddo
	kill window aWin
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


function AcctHeading( )
	local cReturn := 'Z'

	if Account->cheque == 0
		cReturn := 'Z'+space(FLD_SERIES)+space(FLD_CHEQUE)
	else
		cReturn := 'A'+Account->series + str( Account->cheque, FLD_CHEQUE)
	endif

return( cReturn )

static function PageHeader( nPage, dTo, nYear )
	local cI := ' '
	local nLen

	nLen := 78-len(cI)-60

	PrinterCtrl( PRN_CTRL_10_CPI )
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

