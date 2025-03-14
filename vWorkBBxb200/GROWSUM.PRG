// PROGRAM...: GROWSUM.PRG
//               was called ProdRep.prg before 2007
// AUTHOR ...: Total ReWrite by B Hepler
// DATE .....: June 20, 1994
//             July 2, 1996
//             Jun 1999 - redone again.
//             June 2007 redone again, get rid of Report Form
//             July 2013 stuff for Depots

#include 'bsgstd.ch'
#include 'printer.ch'
#include 'BerryPay.ch'
#include 'window.ch'
#include 'sysvalue.ch'
#include 'inkey.ch'
#include "field.ch"
#include "indexord.ch"
#include "valid.ch"
#include 'rpt.ch'
#include 'berry_rpt.ch'

static dDate
static cPayGrp, cOrder
static cFile  := 'notSetYet'
static nStatus

function GrowerSum( cRpt )
	local getList :={}, aWin
   local cProduct
   local lPayGrp
   local aRpt
   local aTitle
   local cTitle := ''
   local cDepot := space(FLD_DEPOT)
   local n


	if !openMainStuff( DB_SHARED )
		close databases
		return( nil )
	endif

	cProduct := space(FLD_PRODUCT)
	nStatus  := 0
	dDate    := date()
	lPayGrp  := .t.
	cPayGrp  := space(FLD_PAYGRP)
	cOrder   := 'N'

   do case
   case cRpt == REP_3_YEAR
      cTitle := '3 Year Average Production Report'
   case cRpt == REP_PROCESS_CLASS
      cTitle := 'Process Class Summary Report'
   endcase

   myBsgScreen( cTitle )
	
   create window at 5,5,19,67 title 'Grower Summary-'+cTitle to aWin
	display window aWin

   in window aWin @ 12,2 winsay cTitle

	do while .t.

		msgLine('This is a Fairly slow report')

   	in window aWin @ 2,2  winsay 'Product' winget cProduct picture '@!' ;
         valid empty( cProduct ) .or. ValidTest(V_PRODUCT, cProduct, VT_BROWSE) ;
			lookup(LU_PRODUCT, ;
          'Enter Product to Look at (or Leave Blank for ALL products)' )

   	in window aWin @ 3,2  winsay 'Up to  ' winget dDate picture '@d' ;
			get_message 'Include transactions up to this date'

 		in window aWin @ 5,2  winsay 'Grower Status' winget nStatus ;
		 picture '9'  GET_MESSAGE ;
		 '1 = Status 1, 2 = Status 2, 0 for All growers'

		in window aWin @ 6,2 winsay 'Alphabetic or Numeric Order (A/N):' ;
		 winGet cOrder PICTURE '!' valid cOrder $ 'AN' GET_MESSAGE ;
		 'A = Alphabetical list of growers by Grower Name (not Cheque Name!)'

		in window aWin @ 7,2 winsay 'In PayGrp Order' ;
		 winGet lPayGrp PICTURE 'Y'

		in window aWin @ 8,2 winsay 'One PayGrp Only' winget cPayGrp ;
		  picture '@!' ;
			when PutName(aWin,08,25,LU_PAYGRP,cPayGrp) ;
			valid PutName(aWin,08,25,LU_PAYGRP,cPayGrp) ;
			LookUp( LU_PAYGRP,  ;
         'Leave Blank for All Grower Payment Groups')

      in window aWin @10,02 winsay 'Depot         ' winget cDepot picture '@!' ;
         when PutName( aWin, 10, 25, LU_DEPOT, cDepot ) ;
         valid PutName( aWin, 10, 25, LU_DEPOT, cDepot ) ;
         LookUp( LU_DEPOT, 'Blank for All Depots - F5 to Browse' )
		READ

		do case
		case lastkey()==K_ESC
   		exit
      case !empty( cProduct )
         if !validTest(V_PRODUCT, cProduct, VT_MESSAGE)
            loop
         endif
   	endcase

      if SelectPrn('GROWSUM.TXT')
         aTitle := {TheClientName( ), cTitle }

			if nStatus <>0
            aadd( aTitle, 'Status = '+lstrim(nStatus) )
      	endif

         aadd( aTitle,"Production to "+shMDY(dDate) )

         if !empty(cDepot)
	         n := len( aTitle )
	         aTitle[n] += ' Depot='+cDepot
	      endif

         if !empty(cPayGrp)
            aadd(aTitle,'Pay Group = '+cPayGrp)
         endif

         if !empty( cProduct )
            aadd( aTitle, ;
              'For '+alltrim(cProduct)+' '+NameOf(LU_PRODUCT, cProduct) )
         endif

			if SetGrow4Rpt(lPayGrp,cPayGrp,cOrder )
				if GatherInfo( cProduct , cDepot)

					PRINT_ON  RPT_OVERWRITE
					dbSelectAr( cFile )
					goto top

               gRptInitHead()

               gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

               if lPayGrp
                  gRptGetSetHead( RPT_HEAD_SUBTOTAL, .t. )
                  gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| (cFile)->payGrp } )
                  gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
                      {|| nuQprnOut( 'PayGroup: '+(cFile)->PayGrp +' '+ ;
                                NameOf(LU_PAYGRP, (cFile)->PayGrp) ) } )
               else
                  gRptGetSetHead( RPT_HEAD_SUBTOTAL, .f. )
               endif


               aRpt := {}
               theRptCols( aRpt, cRpt, cDepot )

					gRptPrintSize( aRpt )

               // gRptSelect( aRpt )

               (cFile)->(dbGoTop())
               (cFile)->(gRptPrinter( aRpt ))
					PrinterCtrl( PRN_CTRL_10_CPI )
					(cFile)->(dbCloseArea( ))

					if cRpt == REP_3_YEAR .and. !empty( cDepot )
						nuQprnOut()
						nuQprnOut('Past year results and Averages include ALL depots!')
						nuQprnOut()
					endif

					KillUnique(cFile,'.DBF')

					PRINT_OFF  RPT_COMPLETE_EJECT
				endif
			endif
		endif
	enddo
	kill window aWin
	close databases
return( nil )


static function GatherInfo( cProduct, cDepot )
   local nYear, nProd2, nProd1, nProd0
   local nClass1,nClass2,nClass3,nClass4
   local lOk := .f.

	msgLine('Getting Ready...')

	cFile := UniqueDBF( { ;
	{ 'NUMBER', 'N', FLD_NUMBER, 0}, ;
   { 'NAME',   'C', FLD_NAME,   0}, ;
   { 'PAYGRP', 'C', FLD_PAYGRP, 0}, ;
   { 'STATUS', 'N',  1, 0}, ;
	{ 'YEAR0',  'N', 10, 0}, ;
	{ 'YEAR1',  'N', 10, 0}, ;
	{ 'YEAR2',  'N', 10, 0}, ;
	{ 'YEARS',  'N',  5, 0}, ;
   { 'AVG'  ,  'N', 10, 0}, ;
   { 'CLASS1', 'N', 10, 0}, ;
   { 'CLASS2', 'N', 10, 0}, ;
   { 'CLASS3', 'N', 10, 0}, ;
   { 'CLASS4', 'N', 10, 0} } )

	if empty( cFile)
		return( .f. )
	endif

   Daily->(OrdSetFocus(DAILY_GROWER_ORD))
   if !empty( cDepot )
   	Daily->(dbSetFilter( { || Daily->depot == cDepot .and. Daily->date <= dDate } , ;
   	    'Daily->depot == cDepot .and. Daily->date <= dDate' ))
   else
   	Daily->(dbSetFilter( { || Daily->date <= dDate } , ;
   	    'Daily->date <= dDate' ))
   endif

   nYear := year(dDate)

	do while !Grower->(eof())
		showProg( str( Grower->number,FLD_GROWER ) )
		nProd2 := nProd1 :=  nProd0 := 0
      nClass1 := nClass2 := nClass3 := nClass4 := 0

      select Daily
      if empty(nStatus) .or. Grower->status == nStatus
         dbseek( str(Grower->number,FLD_NUMBER) + str(nYear,4), SOFTSEEK )
         do while Daily->number==Grower->number .and. ;
                  year(Daily->date)==nYear .and. !Daily->(eof())

            lOk := .f.
            if empty( cProduct)
               nProd0  += Daily->net
               lOk := .t.
            else
               if Daily->product==cProduct
                  nProd0 += Daily->net
                  lOk := .t.
               endif
            endif

            if lOk
               if validTest(V_PROCESS_TYPE, Daily->process, VT_NO_MESSAGE)
                  do case
                  case Process->proc_class == PROCESS_CLASS_FRESH
                     nClass1 += Daily->net
                  case Process->proc_class == PROCESS_CLASS_PROCESSED
                     nClass2 += Daily->net
                  case Process->proc_class == PROCESS_CLASS_JUICE
                     nClass3 += Daily->net
                  otherwise
                     nClass4 += Daily->net
                  endcase
               else
                  nClass4 += Daily->net
               endif
            endif

            Daily->(dbSkip())
         enddo

         if !empty( cProduct )

            dbseek( str(Grower->number,FLD_NUMBER) + str(nYear - 1,4), SOFTSEEK )
            sum Daily->net to nProd1 ;
               while Daily->number==Grower->number .and. ;
                   year(Daily->date)==nYear-1 ;
                  for Daily->product==cProduct

            dbseek( str(Grower->number,FLD_NUMBER) + str(nYear - 2,4), SOFTSEEK )
            sum Daily->net to nProd2 ;
               while Daily->number==Grower->number .and. ;
                   year(Daily->date)== nYear-2 ;
             for Daily->date <= dDate .and. Daily->product==cProduct
         else

            dbseek( str(Grower->number,FLD_NUMBER) + str(nYear + 1,4), SOFTSEEK )
            sum Daily->net to nProd1 ;
               while Daily->number==Grower->number .and. ;
                   year(Daily->date)==nYear-1

            dbseek( str(Grower->number,FLD_NUMBER) + str(nYear + 2,4), SOFTSEEK )
            sum Daily->net to nProd2 ;
               while Daily->number==Grower->number .and. ;
                   year(Daily->date)== nYear-2
         endif

         (cFile)->(dbAppend())
         (cFile)->number := Grower->number
         (cFile)->name   := Grower->name
         (cFile)->status := Grower->status
         (cFile)->payGrp := Grower->payGrp
         (cFile)->year0  := nProd0
         if empty( cProduct ) .and. Num2Equal0( nProd1 )
         	(cFile)->year1  := Grower->ly_fresh + Grower->ly_other
         else
         	(cFile)->year1  := nProd1
        	endif

         (cFile)->year2  := nProd2

         (cFile)->years  := iif(nProd0 > 0,1,0)+ iif( (cFile)->year1 > 0,1,0) +iif( (cFile)->year2 > 0,1,0)
         (cFile)->class1 := nClass1
         (cFile)->class2 := nClass2
         (cFile)->class3 := nClass3
         (cFile)->class4 := nClass4

   		if (cFile)->years > 0
   			(cFile)->avg := (nProd0 + (cFile)->year1 + (cFile)->year2)/(cFile)->Years
   		else
   			(cFile)->(dbDelete())
   		endif
   	endif
		Grower->(dbSkip())
	enddo
	Daily->(dbClearFilter())

RETURN( .t. )

static function theRptCols( aRpt, cRpt, cDepot )
   aadd( aRpt,{ 'ID', {|| Field->number}, 'N', 4, 0, .t., .f., ;
		 'Grower ID' })
   aadd( aRpt, {'Lvl', {||Field->status},'N', 3, 0, .t., .f., ;
       'Usual Grower Price Level'})
   aadd( aRpt, {'Name', {||Field->name},'C',30,0,.t., .f., ;
       'Grower Name (not Cheque Name)'})

   do case
   case cRpt == REP_3_YEAR
      aadd( aRpt, { str(Year(dDate),4), {||Field->year0},'N',8,0,.t., .t., ;
          'Production in '+str(year(dDate),4) })

      if empty( cDepot )
	      aadd( aRpt, { str(Year(dDate)-1,4), {||Field->year1},'N',8,0,.t., .t., ;
          'Production in '+str(year(dDate)-1,4)} )
   	   aadd( aRpt, { str(Year(dDate)-2,4), {||Field->year2},'N',8,0,.t., .t., ;
          'Production in '+str(year(dDate)-2,4) })
	   	aadd( aRpt, { 'Avg', {||Field->avg},'N',8,0,.t., .t., ;
          'Yearly Production Average' } )
      else
	      aadd( aRpt, { {'All Depot',str(Year(dDate)-1,4)}, {||Field->year1},'N',8,0,.t., .t., ;
          'All Production in '+str(year(dDate)-1,4)} )
   	   aadd( aRpt, { {'All Depot',str(Year(dDate)-2,4)}, {||Field->year2},'N',8,0,.t., .t., ;
          'All Production in '+str(year(dDate)-2,4) })

	   	aadd( aRpt, { '--Avg--', {|| padc('n/a', 8)},'C',8,0,.t., .f., ;
          'Space' } )
      endif

   case cRpt == REP_PROCESS_CLASS
      aadd( aRpt, { 'Fresh', {||Field->class1},'N',8,0,.t., .t., ;
          'Fresh Production for this year' })
      aadd( aRpt, { 'Process', {||Field->class2},'N',8,0,.t., .t., ;
          'Process Production for this year' } )
      aadd( aRpt, { 'Juice', {||Field->class3},'N',8,0,.t., .t., ;
          'Juice Produced this year' })
      aadd( aRpt, { 'Other', {||Field->class4},'N',8,0,.t., .t., ;
          'Other production for this year' } )
   endcase

return( nil )

