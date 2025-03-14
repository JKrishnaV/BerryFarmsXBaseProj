// Grow_AP.PRG
//  based somewhat on Acct_reg.prg
// Aug 21, 2007
// Bill Hepler
// June 2011 - LandScape  & more stuff to do with the Advance Amounts
//   Nov 29, 2011 - there are a whack of problems - needs re-write.
//   Mar 08, 2019 - Added LEGEND - this may be very helpful for this report


#include 'common.ch'
#include 'window.ch'
#include 'bsgstd.ch'
#include 'printer.ch'
#include 'BerryPay.ch'
#include 'inkey.ch'
#include 'sysvalue.ch'
#include 'valid.ch'
#include 'account.ch'
#include 'radio.ch'
#include 'price.ch'
#include "field.ch"
#include "indexord.ch"
#include "errors.ch"
#include 'berry_rpt.ch'
#include 'rpt.ch'

#define  Z_FRESH_PAID    1    // Fresh Paid
#define  Z_NF_PAID       2    // NonFresh Paid
#define  Z_FRESH_OWED    3    // Fresh Owed
#define  Z_NF_OWED       4    // NonFresh Owed
#define  Z_TOTAL_PAID    5
#define  Z_TOTAL_OWED    6


#define  A_PAY_INFO_LENGTH             22

#define  A_PROCLASS_1_WGT               1        // Fresh Wt
#define  A_PROCLASS_OTHER_WGT           2        // NF Wt

#define  A_PROCLASS_1_TOTAL_ADVANCE_DUE       3
#define  A_PROCLASS_1_FINAL_DUE               4    // Total Fresh Value
#define  A_PROCLASS_OTHER_TOTAL_ADVANCE_DUE   5
#define  A_PROCLASS_OTHER_FINAL_DUE           6    // Total Not Fresh Value


#define  A_PROCLASS_1_TOTAL_ADV_CHEQ            7      // All Cheque Against
#define  A_PROCLASS_OTHER_TOTAL_ADV_CHEQ        8
#define  A_PROCLASS_1_FINAL_CHEQ                9      // Cheque Against FINAL
#define  A_PROCLASS_OTHER_FINAL_CHEQ           10
//   We distinguish the PURPOSE of CHEQUES here, which is
//   a little different than estimated totals due...


/*
	#define  A_MARKET_DEDUCTION_DUE             11        // computed
	#define  A_MARKET_DEDUCTION_CHEQ            12        // Cheque against
*/

	#define  A_MARKET_DEDUCTION_PROCLASS_FRESH_DUE    11        // computed
	#define  A_MARKET_DEDUCTION_PROCLASS_OTHER_DUE    12        // computed
	#define  A_MARKET_DEDUCTION_CHEQ                  13        // Cheque against


#define  A_OTHER_DUE                        14        // Count DIRECTLY
#define  A_OTHER_CHEQ                       15
#define  A_TOTAL_CHEQUES_ISSUED             16        // Count Directly


// added in 2011
#define A_PROCLASS_1_1ST_ADVANCE_DUE        17       // Fresh Advance 1 Due
#define A_PROCLASS_OTHER_1ST_ADVANCE_DUE    18       // Process & Juice Etc Advance 1 Due

#define A_PROCLASS_1_2ND_ADVANCE_DUE        19       // Fresh Advance 2 Due
#define A_PROCLASS_OTHER_2ND_ADVANCE_DUE    20       // Process & Juice Etc Advance 2 Due

#define A_PROCLASS_1_3RD_ADVANCE_DUE        21       // Fresh Advance 2 Due
#define A_PROCLASS_OTHER_3RD_ADVANCE_DUE    22       // Process & Juice Etc Advance 2 Due


// so ignoring market deductions
//   +    A_PC__FINAL_DUE estimates what they are owed.
//   -    A_PC__CHEQ      tells what they have been paid.
//  (-)   A_PRESEASON_ADVANCE_NET  tells what the net is for Advance
//  (-)   A_OTHER_UNPAID           any other unpaid.
//   =    Net Owed to Grower


#define  DOLLAR_PIC   '99,999,999.99'
static aInfo := { ;
   'Fresh Weight                        ', ;    /*  1 */
   'NonFresh Weight                     ', ;    /*  2 */
   'Total Fresh Advance (inc. Paid)     ', ;    /*  3 */
   'Fresh Final Total Value             ', ;    /*  4 */
   'Total Process Advance (inc. Paid)   ', ;    /*  5 */
   'Process Final Total Value           ', ;    /*  6 */
   'Fresh Advance Actually Paid         ', ;    /*  7 */
   'Process Advance Actually Paid       ', ;    /*  8 */
   'Final Fresh Actually Paid           ', ;    /*  9 */
   'Final NonFresh Actually Paid        ', ;    /* 10 */
   'Marketing Levy Due for Fresh        ', ;    /* 11 */
   'Marketing Levy Due for Process      ', ;    /* 12 */
   'Levy Deductions Actually Paid out   ', ;    /* 13 */
   'X-Other transactions not yet paid   ', ;    /* 14 */
   'Y-All other transactions paid out   ', ;    /* 15 */
   'Total Cheques Issued (includes Levy)', ;    /* 16 */
   'Fresh 1st Advance actually Due now  ', ;    /* 17 */
   ' Other 1st Advance actually Due now ', ;    /* 18 */
   'Fresh 2nd Advance actually Due now  ', ;    /* 19 */
   ' Other 2nd Advance actually Due now ', ;    /* 20 */
   'Fresh 3rd Advance actually Due now  ', ;    /* 21 */
   ' Other 3rd Advance actually Due now '  }    /* 22 */

static aFresh := {}
static dTo, nGrower,  nYear
static bYear, bGrower

static aGrower[A_PAY_INFO_LENGTH],  aTotal[A_PAY_INFO_LENGTH]

function Grow_Ap( cRptFormat )
   local aWin, getList :={}, n
   local aRpt := {}
   local lConfigure := .f., lLegend := .f.
   //local cRptFormat := RP_GROW_AP01, cFile
   local cFile
   local lDBG := .f.

   if !openMainStuff( DB_SHARED)
      close databases
      return( nil )
   endif

   SetFreshProcesses()
   dTo     := date()
   nYear   := sysValue( SYS_CURRENT_YEAR )
   nGrower := 0


   myBsgScreen( 'Grower Accounts Payables '+cRptFormat )

   create window at 6,10,19,60 title 'Grower A/P '+cRptFormat to aWin
   display window aWin
   set cursor on

   in window aWin @ 13,2 winsay 'This ledger includes UNPOSTED transactions'
   in window aWin @ 14,2 winsay 'and estimates of payments due.'

   do while .t.
      msgLine('[Esc] to Exit')

      in window aWin @ 2,2  winsay 'Crop Year' winget nYear picture '@Z 9999' ;
         GET_MESSAGE ;
         'Enter the Crop Year ONLY if you want the the Ledger for a single crop year'

      in window aWin @ 3,2  winsay 'Effective' winget dTo picture '@d' ;
         GET_MESSAGE ;
         'Enter the Transaction Cut Off Date'

      in window aWin @ 4,2  winsay 'Specific Grower Only' winget nGrower ;
         picture NumBlankPic( FLD_GROWER ) ;
         LOOKUP( LU_GROWER, ;
         'Enter a Grower ID here, if you wish to print a ledger for 1 grower ONLY')

      in window aWin @ 6, 2 winsay 'Configure Report  ' winget lConfigure ;
         picture 'Y' ;
         get_message 'Configure the Report Columns'

		in window aWin @ 7,02 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

      in window aWin @ 9,2 winsay 'Leave DeBug File' winget lDBG ;
          picture 'Y' ;
          get_message 'Leaves a UNIQxxxx file-for Crafted Industrial Software Ltd. mainly'

      READ

      do case
      case lastkey()==K_ESC
         exit
      endcase

      aRpt := {}
      CfgRpt( aRpt )
      gRptInit( cRptFormat, aRpt)

      if lConfigure
         gRptSelect( aRpt )
      endif

      if selectPrn('GROW_AP.TXT')
         aFill(aTotal,0.00)
         Grower->(OrdSetFocus(GROWER_NUMBER_ORD))
         if nGrower==0
            Grower->(dbGoTop())
            bGrower := {||.t.}
         else
            if !Grower->(dbSeek( str(nGrower,FLD_GROWER), HARDSEEK))
               waitInfo({'Grower is Not on file'})
               loop
            endif
            bGrower := {|| Grower->number == nGrower }
         endif
         if nYear==0
            bYear := { | nY | .t. }              // always true
         else
            bYear := {| nY | nY == nYear }
         endif

         cFile := UniqueDBF( { {'NUMBER',  'N', FLD_GROWER , 0 }, ;
                               {'PC1WT',   'N', 10,0}, ;
                               {'PCXWT',   'N', 10,0}, ;
                               {'PC1ADUE', 'N', 12,2}, ;
                               {'PC1ACHQ', 'N', 12,2}, ;
                               {'PCXADUE', 'N', 12,2}, ;
                               {'PCXACHQ', 'N', 12,2}, ;
                               {'PC1FDUE', 'N', 12,2}, ;
                               {'PC1FCHQ', 'N', 12,2}, ;
                               {'PCXFDUE', 'N', 12,2}, ;
                               {'PCXFCHQ', 'N', 12,2}, ;
                               {'MARKCHQ' , 'N', 12,2}, ;
                               {'MARK1DUE', 'N', 12,2}, ;
                               {'MARKXDUE', 'N', 12,2}, ;
                               {'OTHCHQ',   'N', 12,2}, ;
                               {'OTHDUE',   'N', 12,2}, ;
                               {'CHEQUES',  'N', 12,2}, ;
										 {'PC1A1DUE', 'N', 12,2}, ;
										 {'PCXA1DUE', 'N', 12,2}, ;
										 {'PC1A2DUE' ,'N', 12,2}, ;
										 {'PCXA2DUE', 'N', 12,2}, ;
										 {'PC1A3DUE' ,'N', 12,2}, ;
										 {'PCXA3DUE', 'N', 12,2}    } )
         if empty(cFile)
            waitInfo({"Can not make temp file!" })
            loop
         endif

         do while eval(bGrower) .and. !Grower->(eof())
            msgLine(lstrim(Grower->number)+' '+grower->name)
            aFill(aGrower,0.00)                  // we store grower results here

            RunDaily()
            CalcPosted()
            CheckCheques()

            (cFile)->(dbAppend())
            (cFile)->NUMBER  := Grower->number
            (cFile)->PC1WT     := aGrower[ A_PROCLASS_1_WGT ]
            (cFile)->PCXWT     := aGrower[ A_PROCLASS_OTHER_WGT ]
            (cFile)->PC1ADUE   := aGrower[ A_PROCLASS_1_TOTAL_ADVANCE_DUE ]
            (cFile)->PC1FDUE   := aGrower[ A_PROCLASS_1_FINAL_DUE ]
            (cFile)->PCXADUE   := aGrower[ A_PROCLASS_OTHER_TOTAL_ADVANCE_DUE ]
            (cFile)->PCXFDUE   := aGrower[ A_PROCLASS_OTHER_FINAL_DUE ]
            (cFile)->PC1ACHQ   := aGrower[ A_PROCLASS_1_TOTAL_ADV_CHEQ ]
            (cFile)->PCXACHQ   := aGrower[ A_PROCLASS_OTHER_TOTAL_ADV_CHEQ ]
            (cFile)->PC1FCHQ   := aGrower[ A_PROCLASS_1_FINAL_CHEQ ]
            (cFile)->PCXFCHQ   := aGrower[ A_PROCLASS_OTHER_FINAL_CHEQ ]

            // (cFile)->MARKDUE   := aGrower[ A_MARKET_DEDUCTION_DUE ]

            (cFile)->MARK1DUE  := aGrower[ A_MARKET_DEDUCTION_PROCLASS_FRESH_DUE ]
            (cFile)->MARKXDUE  := aGrower[ A_MARKET_DEDUCTION_PROCLASS_OTHER_DUE ]

            (cFile)->MARKCHQ   := aGrower[ A_MARKET_DEDUCTION_CHEQ ]
            (cFile)->OTHDUE    := aGrower[ A_OTHER_DUE ]
            (cFile)->OTHCHQ    := aGrower[ A_OTHER_CHEQ ]
            (cFile)->CHEQUES   := aGrower[ A_TOTAL_CHEQUES_ISSUED ]

            (cFile)->PC1A1DUE  := aGrower[ A_PROCLASS_1_1ST_ADVANCE_DUE ]
				(cFile)->PCXA1DUE  := aGrower[ A_PROCLASS_OTHER_1ST_ADVANCE_DUE ]
            (cFile)->PC1A2DUE  := aGrower[ A_PROCLASS_1_2ND_ADVANCE_DUE ]
				(cFile)->PCXA2DUE  := aGrower[ A_PROCLASS_OTHER_2ND_ADVANCE_DUE ]
            (cFile)->PC1A3DUE  := aGrower[ A_PROCLASS_1_3RD_ADVANCE_DUE ]
				(cFile)->PCXA3DUE  := aGrower[ A_PROCLASS_OTHER_3RD_ADVANCE_DUE ]

            for n:=1 to len(aGrower)             // accumulate totals
               aTotal[n] += aGrower[n]
            next
            Grower->(dbSkip())
         enddo

			// For LandScape
			gRptAutoPageOrientation( aRpt, 0)

         PRINT_ON  RPT_OVERWRITE

         gRptPrintSize( aRpt )

         gRptInitHead()
         gRptGetSetHead( RPT_HEAD_TITLE, { ;
               TheClientName( ), ;
                'Format '+ cRptFormat, ;
                'Grower A/P '+shMDY(dTo) })

         (cFile)->(dbGoTop())

         (cFile)->( gRptPrinter( aRpt ))

         PrinterCtrl(PRN_CTRL_10_CPI)

         if NearPageBottom( 33 )
            nuFormFeed()
            nuQprnOut( 'Summary of Results' )
            nuQprnOut( )
         endif
         nuQprnOut( )
         nuQprnOut( 'Summary' )
         nuQprnOut( )
         for n := 1 to len( aInfo )
            nuQprnOut( space(5)    )
            nuQQprnOut( aInfo[ n ] )
            if n <= 2
               nuQQprnOut( '  '+transform( aTotal[n], '9,999,999,999')+ ;
                   ' '+sysValue(SYS_UNITS_OF_WEIGHT)  )
            else
               nuQQprnOut( ' $'+transform( aTotal[n], '99,999,999.99') )
            endif
         next
         nuQprnOut( )
         nuQprnOut( '  Grand Totals:' )
         nuQprnOut( space(5)+padr('Total Shipped', len( aInfo[1]) ) + space(2)+ ;
            transform( ;
             aTotal[ A_PROCLASS_1_WGT ] + ;
             aTotal[ A_PROCLASS_OTHER_WGT ] , '9,999,999,999')+ ;
              ' '+sysValue( SYS_UNITS_OF_WEIGHT ) )

         nuQprnOut( space(5)+padr('Total Value of Crop',len( aInfo[1]))+ ' $' + ;
             transform( aTotal[  A_PROCLASS_1_FINAL_DUE ] + ;
                        aTotal[  A_PROCLASS_OTHER_FINAL_DUE ], ;
                        '99,999,999.99') )

         nuQprnOut( space(5)+padr( ;
           'Unpaid Adv, ignores PreSeason Adv',len( aInfo[1]))+ ;
             ' $' + ;
             transform( aTotal[  A_PROCLASS_1_TOTAL_ADVANCE_DUE ] + ;
                        aTotal[  A_PROCLASS_OTHER_TOTAL_ADVANCE_DUE ] - ;
                        aTotal[  A_PROCLASS_1_TOTAL_ADV_CHEQ ] - ;
                        aTotal[  A_PROCLASS_OTHER_TOTAL_ADV_CHEQ ], ;
                        '99,999,999.99')  )

         nuQprnOut( ' The difference between X & Y above usually will be the amount' )
         nuQprnOut( '  of PreSeason (Loans) which have been repaid.' )

         nuQprnOut( 'Fresh & Other Numbered Advances take into account what has been paid out' )
			nuQprnOut( 'to date, but ignores loans, bonuses, deductions and crop levies.' )

         nuQprnOut( 'End' )

			if lLegend
				prnRptLegend( aRpt,{ 'Legend for Format '+ cRptFormat}, .t. ) // only show columns selected
			endif

         PRINT_OFF  RPT_COMPLETE_EJECT

         if lConfigure
				if yesno({'Save this Report Format?'})
					gRptSave( aRpt )
				endif
			endif

         (cFile)->(dbCloseArea())
         if !lDBG
            KillUnique( cFile )
         endif

      endif
   enddo
   kill window aWin
   close databases
return( nil )


static function RunDaily()
   // June 2000 - this includes Advances & Final Payments....
   local nTotAdvance, nPrice, nDeductPrice,nPremium
   local nAdvance1, nAdvance2, nAdvance3


   Daily->(OrdSetFocus(DAILY_GROWER_ORD))
   if Daily->(dbSeek( str(Grower->number,FLD_GROWER), HARDSEEK ))
      showProg(str(Grower->number,FLD_GROWER)+' Unpost')

      // skip til we find one that applies
      do while Daily->number==Grower->number .and. !Daily->(eof())
         nPrice := nTotAdvance := nDeductPrice := 0.00
         nAdvance1 := 0.00
         nAdvance2 := 0.00
         nAdvance3 := 0.00
         nPremium  := 0.00

         if Daily->date <= dTo .and. eval( bYear, year(Daily->date)) .and. ;
            str( Daily->net,12,2) <> str(0,12,2)
            // we DONT care about net weights of 0 - they are
            // container records


            nDeductPrice := MrkDeduction( Daily->product )
            if Daily->(fValidPrice( ) )
               nTotAdvance := Daily->(TotAdvPrice())
               nPremium := Daily->(AdvancePrem())
               nPrice   := Daily->(FinalPrice()) + Daily->(AdvancePrem())

					do case
					case Daily->FIN_BAT > 0
						nAdvance1 := 0.00
						nAdvance2 := 0.00
						nAdvance3 := 0.00

					case Daily->post_bat3 > 0
						nAdvance1 := 0.00
						nAdvance2 := 0.00
						nAdvance3 := 0.00

					case Daily->post_bat2 > 0
						nAdvance1 := 0.00
						nAdvance2 := 0.00
						nAdvance3 := Daily->(RunAdvPrice(3)) - Daily->adv_pr1 - Daily->adv_pr2

					case Daily->post_bat1 > 0
						nAdvance1 := 0.00
						nAdvance2 := Daily->(RunAdvPrice(2)) - Daily->adv_pr1
						nAdvance3 := Daily->(RunAdvPrice(3)) - max( Daily->(RunAdvPrice(2)), Daily->adv_pr1 )

					otherwise
						nAdvance1 := Daily->(RunAdvPrice(1))
						nAdvance2 := Daily->(RunAdvPrice(2)) - Daily->(RunAdvPrice(1))
						nAdvance3 := Daily->(RunAdvPrice(3)) - Daily->(RunAdvPrice(2))
					endcase

            else
               if Daily->FIN_BAT > 0
                  nPrice := Daily->Fin_Price
               else
                  nPrice := Daily->thePrice
               endif
            endif

            if aScan( aFresh, Daily->process ) >= 1
               aGrower[ A_PROCLASS_1_WGT ]          += Daily->net
               aGrower[ A_PROCLASS_1_TOTAL_ADVANCE_DUE ]  += Daily->net * nTotAdvance
               aGrower[ A_PROCLASS_1_FINAL_DUE   ]  += Daily->net * ;
                                    (nPrice + nPremium )
					aGrower[ A_PROCLASS_1_1ST_ADVANCE_DUE ]  += Daily->net * nAdvance1
					aGrower[ A_PROCLASS_1_2ND_ADVANCE_DUE ]  += Daily->net * nAdvance2
					aGrower[ A_PROCLASS_1_3RD_ADVANCE_DUE ]  += Daily->net * nAdvance3
					aGrower[ A_MARKET_DEDUCTION_PROCLASS_FRESH_DUE ] += round(nDeductPrice*Daily->net,2)
            else
               aGrower[ A_PROCLASS_OTHER_WGT ] += Daily->net
               aGrower[ A_PROCLASS_OTHER_TOTAL_ADVANCE_DUE ]  +=  ;
                   Daily->net * nTotAdvance
               aGrower[ A_PROCLASS_OTHER_FINAL_DUE   ]  += ;
                   Daily->net * (nPrice + nPremium )

					aGrower[ A_PROCLASS_OTHER_1ST_ADVANCE_DUE ]  += Daily->net * nAdvance1
					aGrower[ A_PROCLASS_OTHER_2ND_ADVANCE_DUE ]  += Daily->net * nAdvance2
					aGrower[ A_PROCLASS_OTHER_3RD_ADVANCE_DUE ]  += Daily->net * nAdvance3
					aGrower[ A_MARKET_DEDUCTION_PROCLASS_OTHER_DUE ] += round(nDeductPrice*Daily->net,2)
            endif

         endif
         Daily->(dbSkip())
      enddo
   endif

return( nil )

static function CheckCheques( )

   Cheque->(OrdSetFocus(CHEQUE_GROWER_ORD))
   if Cheque->(dbSeek( str(Grower->number,FLD_GROWER), HARDSEEK ))
      showProg('Cheques')
   endif

   do while Cheque->number==Grower->number .and. !Cheque->(eof())
      if  eval( bYear, Cheque->year) .and. Cheque->date <= dTo
         aGrower[A_TOTAL_CHEQUES_ISSUED] += Cheque->amount
      endif
      Cheque->(dbSkip())
   enddo
return( nil )


static function CalcPosted()

   Cheque->(OrdSetFocus(CHEQUE_CHEQUE_NO_ORD))
   Account->(OrdSetFocus(ACCOUNT_NUMBER_ORD))

   if Account->(dbSeek( str(Grower->number,FLD_GROWER),HARDSEEK))
      showProg('From Account..')
   endif
   do while Account->number==Grower->number .and. !Account->(eof())
      if (eval(bYear, Account->year)) .and. Account->date <= dTo

         if isChequeOK( Account->series, Account->cheque)
            do case
            case Account->type==TT_BERRY_ADVANCE_1 .or. ;
                 Account->type==TT_BERRY_ADVANCE_2 .or. ;
                 Account->type==TT_BERRY_ADVANCE_3

               if aScan( aFresh, Account->process)>0
                  aGrower[ A_PROCLASS_1_TOTAL_ADV_CHEQ ]+= (Account->dollars )
               else
                  aGrower[ A_PROCLASS_OTHER_TOTAL_ADV_CHEQ ]+= (Account->dollars )
               endif

            case Account->type==TT_FINAL_BERRY .or. ;
                 Account->type==TT_TIME_PREMIUM

               if aScan( aFresh, Account->process)>0
                  aGrower[ A_PROCLASS_1_FINAL_CHEQ ]+= ( Account->dollars )
               else
                  aGrower[ A_PROCLASS_OTHER_FINAL_CHEQ ]+= ( Account->dollars  )
               endif

            case Account->type ==TT_STD_DEDUCTION
               aGrower[ A_MARKET_DEDUCTION_CHEQ ]+= ( Account->dollars  )
            otherwise
               aGrower[ A_OTHER_CHEQ ] += (Account->dollars )
            endcase
         else
            aGrower[ A_OTHER_DUE ] += (Account->dollars )
         endif
      endif
      Account->(dbSkip())
   enddo

return( nil )


static function SetFreshProcesses()
   aSize(aFresh,0)

   Process->(dbGoTop())
   do while !Process->(eof())
      if Process->proc_class==1
         aadd( aFresh, Process->process )
      endif
      Process->(dbSkip())
   enddo

return( nil )

static function IsChequeOK( cSeries, nCheque )
   local lReturn := .f.

   if !empty( cSeries ) .and. str( nCheque, 12,2) <> str(0,12,2)
      Cheque->(OrdSetFocus(CHEQUE_CHEQUE_NO_ORD))
      if Cheque->(dbSeek( cSeries+str( nCheque,FLD_CHEQUE)))
         if Cheque->date <= dTo
            lReturn := .t.
         endif
      endif
   endif
return( lReturn )

static function CfgRpt( aRpt )
   aadd( aRpt, { 'Grower', {|| Field->NUMBER  }, 'N', 4,0, .t., .f., ;
     'Grower ID'})
   aadd( aRpt, { 'Grower Name', {|| NameOf(LU_GROWER_NAME, Field->NUMBER ) }, ;
          'C', 25,0, .t., .f., ;
     'Grower Name'})

   aadd( aRpt, {'Fresh Wt', {|| Field->PC1WT   }, 'N', 10, 0, .t., .t., ;
      'Fresh Weight'})

   aadd( aRpt, {'Proc Wt', {|| Field->PCXWT   }, 'N', 10, 0, .t., .t., ;
      'NonFresh Weight'})

   aadd( aRpt, {'Total Wt', {|| Field->PCXWT + Field->PC1WT }, 'N', 10, 0, .t., .t., ;
      'Total Weight Shipped'})

   aadd( aRpt, {'F Adv Due', {|| Field->PC1ADUE }, 'N', 10, 2, .f., .t., ;
      'Fresh Advances Due (including paid receipts)'})

   aadd( aRpt, {'F Value', {|| Field->PC1FDUE }, 'N', 10, 2, .t., .t., ;
      'Fresh Total Value (Amount Due including Paid Receipts)'})

   aadd( aRpt, {'Fr Paid', {|| FancyDue( Z_FRESH_PAID ) }, 'N', 10, 2, .t., .t., ;
      'Fresh Paid INCLUDING PRE-SEASON ADVANCES (loans)'})

   aadd( aRpt, {'Fr Owed', {|| FancyDue( Z_FRESH_OWED ) }, 'N', 10, 2, .t., .t., ;
      'Fresh Owed Paid INCLUDING PRE-SEASON ADVANCES (loans)'})

   aadd( aRpt, {'NF AdvDue', {|| Field->PCXADUE }, 'N', 10, 2, .f., .t., ;
      'NonFresh Advance Value (includes Paid Receipts)'})

   aadd( aRpt, {'NF Value', {|| Field->PCXFDUE }, 'N', 10, 2, .t., .t., ;
      'NonFresh Total Due (include Paid Receipts)'})
   aadd( aRpt, {'NF Paid', {|| FancyDue( Z_NF_PAID ) }, 'N', 10, 2, .t., .t., ;
      'NonFresh Paid INCLUDING PRE-SEASON ADVANCES (loans)'})
   aadd( aRpt, {'NF Owed', {|| FancyDue( Z_NF_OWED ) }, 'N', 10, 2, .t., .t., ;
      'NonFresh Owed INCLUDING PRE-SEASON ADVANCES (loans)'})

   aadd( aRpt, {'F Adv Pd', {|| Field->PC1ACHQ }, 'N', 10, 2, .f., .t., ;
      'Fresh Advances Actually Paid'})

   aadd( aRpt, {'NF Adv Pd', {|| Field->PCXACHQ }, 'N', 10, 2, .f., .t., ;
      'NonFresh Advances Actually Paid'})

   aadd( aRpt, {'F Paid', {|| Field->PC1FCHQ }, 'N', 10, 2, .f., .t., ;
      'Fresh Total Paid'})

   aadd( aRpt, {'NF Paid', {|| Field->PCXFCHQ }, 'N', 10, 2, .f., .t., ;
      'NonFresh Total Paid'})

   aadd( aRpt, {'Mark Due', {|| Field->MARK1DUE + Field->MARKXDUE }, 'N', 10, 2, .f., .t., ;
      'Total Marketing Deduction Due (includes Fresh & Process)'})

   aadd( aRpt, {'Mark Pd', {|| Field->MARKCHQ }, 'N', 10, 2, .f., .t., ;
      'Marketing Deductions Paid  (includes Fresh & Process)'})

   aadd( aRpt, {'Oth Due', {|| Field->OTHDUE  }, 'N', 10, 2, .f., .t., ;
      'All Other Due'})
   aadd( aRpt, {'Oth Paid', {|| Field->OTHCHQ  }, 'N', 10, 2, .f., .t., ;
      'All Other Actually Paid Out'})
   aadd( aRpt, {'Tot Chqs', {|| Field->CHEQUES  }, 'N', 10, 2, .f., .t., ;
      'Total Cheques issued within date range'})

   aadd( aRpt, {'TOT Paid', {|| FancyDue( Z_TOTAL_PAID ) }, 'N', 10, 2, .f., .t., ;
      'Total $ Paid out INCLUDING PRE-SEASON ADVANCES (loans)'})
   aadd( aRpt, {'NET Owed', {|| FancyDue( Z_TOTAL_OWED ) }, 'N', 10, 2, .f., .t., ;
      'Net Total $ Owed INCLUDING PRE-SEASON ADVANCES (loans)'})

	// June 2011
   aadd( aRpt, {'Fr 1st Ad', {|| Field->PC1A1DUE }, 'N', 10, 2, .f., .t., ;
      'Fresh 1st Advance due - NOT including Deductions ! Ignores loans!'})
   aadd( aRpt, {'Fr 2nd Ad', {|| Field->PC1A2DUE }, 'N', 10, 2, .f., .t., ;
      'Fresh 2nd Advance due - this is projected for the RUN.  Ignores loans !'})
   aadd( aRpt, {'Fr 3rd Ad', {|| Field->PC1A3DUE }, 'N', 10, 2, .f., .t., ;
      'Fresh 3rd Advance due - this is projected for the RUN.  Ignores loans !'})

   aadd( aRpt, {'Oth 1st Ad', {|| Field->PCXA1DUE }, 'N', 10, 2, .f., .t., ;
      'NonFresh 1st Advance due - NOT including Deductions ! Ignores loans!'})
   aadd( aRpt, {'Oth 2nd Ad', {|| Field->PCXA2DUE }, 'N', 10, 2, .f., .t., ;
      'NonFresh 2nd Advance due - this is projected for the RUN.  Ignores loans!'})
   aadd( aRpt, {'Oth 3rd Ad', {|| Field->PCXA3DUE }, 'N', 10, 2, .f., .t., ;
      'NonFresh 3rd Advance due - this is projected for the RUN.  Ignores loans!'})

   aadd( aRpt, {'F.Mark Due', {|| Field->MARK1DUE }, 'N', 10, 2, .f., .t., ;
      'Marketing Deduction Due for Fresh only'})
   aadd( aRpt, {'P.Mark Due', {|| Field->MARKXDUE }, 'N', 10, 2, .f., .t., ;
      'Marketing Deduction Due for Other (Process)'})

return( nil )

static Function FancyDue( nWhat )
   local nReturn  := 0.00
   local nDue
   local nChq
   local aRay[6]

   aFill( aRay, 0.00)

   nDue   :=  Field->OthDue
   nChq   :=  Field->othChq

   aRay[ Z_FRESH_PAID ] := Field->pc1Achq + Field->pc1Fchq     // Fresh Paid
   aRay[ Z_NF_PAID    ] := Field->pcxAchq + Field->pcxFchq     // NonFresh Paid

   aRay[ Z_FRESH_OWED ] := Field->pc1Fdue - aRay[ Z_FRESH_PAID]
   aRay[ Z_NF_OWED    ] := Field->pcxFdue - aRay[ Z_NF_PAID ]

   // Now how much is actually Due, we first deduct from FRESH!

   do case
   case str(nDue , 12, 2 ) == str(0,12,2)  .and. ;
        str(nChq,  12, 2 ) == str(0,12,2)
      // do Nothing

   case nDue <  0.00 .and. nChq < aRay[ Z_FRESH_OWED ]
      // then we deduct advances due etc from the Fresh
      aRay[ Z_FRESH_OWED ] -= nChq
      aRay[ Z_FRESH_PAID ] += nChq
   otherwise
      // reduce Fresh OWED to ZERO, and then reduce the NON-FRESH owed
      nChq -= aRay[ Z_FRESH_OWED]
      aRay[ Z_FRESH_OWED] := 0.00
      aRay[ Z_NF_PAID ] += nChq
      aRay[ Z_NF_OWED ] -= nChq
   endcase

	/*
	   aRay[ Z_TOTAL_OWED ] := aRay[ Z_FRESH_OWED]+aRay[ Z_NF_OWED]
   	aRay[ Z_TOTAL_PAID ] := aRay[ Z_FRESH_PAID]+aRay[ Z_NF_PAID]
   */

	aRay[ Z_TOTAL_PAID ] :=  Field->PC1Fchq + Field->PC1ACHQ +  ;
	                         Field->PCXFchq + Field->PCXACHQ + ;
	                         Field->MARKchq + ;
	                         Field->OTHchq

   aRay[ Z_TOTAL_OWED ] := Field->PC1Fdue   + ;
	                        Field->PCXFdue   + ;
	                        Field->MARK1due  + ;
	                        Field->MARKXdue  + ;
	                        Field->OTHDUE   - ;
									(Field->PC1Fchq + Field->PC1ACHQ +  ;
	                         Field->PCXFchq + Field->PCXACHQ + ;
	                         Field->MARKchq )

   nReturn := aRay[ nWhat ]
return( nReturn )



