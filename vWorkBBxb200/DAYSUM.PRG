// PROGRAM...: DaySum.prg
//             based on GrowSum.prg
//   Bill Hepler, July 7, 2008
//   Revised, minor changes July 2009
//            more minor changes Sep 2009, look at Money Stuff
//   Mar 08, 2019 - Added Legends.

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

#define SHOW_GROWER    1
#define SHOW_DATE      2

static dFrom,dTo
static cPayGrp
static cFile1 := 'notSetYet1', cFile2 := 'notSetYet2' , cFile3 := 'notSetYet3'
static cProduct, nProdCat, cProcess, nStatus, cDepot

function byDaySum(  )
   local getList :={}, aWin
   local aRpt
   local aTitle
   local lSummary   := .t.
   local lDDetail   := .t.
   local lConfigure := .f., lLegend := .f.
   local lPrinted   := .f.
   local lAp, lQty
   local c,cRpt
   local n

   if !openMainStuff( DB_SHARED )
      close databases
      return( nil )
   endif

   cProduct := space(FLD_PRODUCT)
   nProdCat := 0
   dFrom    := ctod('01/01/'+str(year(date()),4) )
   dTo      := date()
   cPayGrp  := space(FLD_PAYGRP)
   cProcess := space(FLD_PROCESS )
   nStatus  := 0
   lQty     := .t.
   lAp      := .f.
   cDepot   := space(FLD_DEPOT)

   myBsgScreen( 'by Day Summaries' )

   create window at 4,4,22,70 title 'Summary by Day' to aWin
   display window aWin

   in window aWin @ 2,42 winsay 'This report gives'
   in window aWin @ 3,42 winsay 'totals for each day.'

   do while .t.
      msgLine('This is a Fairly slow report')
      in window aWin @ 2,02  winsay 'From' winget dFrom picture '@d' ;
         get_message 'Include transactions from this date'
      in window aWin @ 2,20  winsay 'to' winget dTo picture '@d' ;
         get_message 'Include transactions to this date'

      in window aWin @ 4, 2  winsay 'Product' winget cProduct picture '@!' ;
         valid putName(aWin,4,25,LU_PRODUCT,cProduct) .and.  ;
         (empty( cProduct ) .or. ValidTest(V_PRODUCT, cProduct, VT_BROWSE)) ;
         lookup(LU_PRODUCT, ;
         'Enter Product to Look at (or Leave Blank for ALL products)' )

      in window aWin @ 5, 2  winsay 'Process Type    ' winget cProcess ;
         picture '@!' ;
         valid putName(aWin,5,25,LU_PROCESS_TYPE,cProduct) .and.  ;
			(empty( cProcess ) .or. ValidTest(V_PROCESS_TYPE, cProcess, VT_BROWSE)) ;
         lookup(LU_PROCESS_TYPE, ;
         'Enter Process to Look at (or Leave Blank for ALL processes)' )

      in window aWin @ 6, 2  winsay 'Product Category' winget nProdCat ;
         picture '@Z 9' ;
         valid nProdCat==0 .or. ValidTest(V_PRODUCT_CATEGORY, nProdCat, VT_BROWSE) ;
         lookup(LU_PRODUCT_CATEGORY, ;
         'Enter Product Category to Look at (or Leave Blank for ALL categories)' )

      in window aWin @ 8,02 winsay 'Depot      ' winget cDepot picture '@!' ;
         when PutName( aWin, 8, 25, LU_DEPOT, cDepot ) ;
         valid PutName( aWin, 8,25, LU_DEPOT, cDepot ) ;
         LookUp( LU_DEPOT, 'Blank for All Depots - F5 to Browse' )

      in window aWin @ 9, 2 winsay 'Price Level' winget nStatus ;
         picture '9'  get_message ;
         'Enter a specific Grower Price Level or Leave at 0 for all'

      in window aWin @10, 2 winsay 'Pay Group  ' winget cPayGrp ;
         picture '@!' ;
         when PutName(aWin,10,25,LU_PAYGRP,cPayGrp) ;
         valid PutName(aWin,10,25,LU_PAYGRP,cPayGrp) ;
         LookUp( LU_PAYGRP,  ;
         'Leave Blank for All Grower Payment Groups')

      in window aWin @ 12, 2 winsay 'Print Daily Summary' winget lSummary ;
         picture 'Y' get_message 'Shows 1 Line per Day'
      in window aWin @ 13, 2 winsay ' by Day + Grower   ' winget lDDetail ;
         picture 'Y' get_message 'Grand Sort by Day - sub total for each grower'

      in window aWin @ 14, 2 winsay 'Show A/P data      ' winget lAp ;
        picture 'Y' get_message 'Show A/P data (and less production info)'

      in window aWin @ 15, 2 winsay 'Quantity Data      ' winget lQty ;
        picture 'Y' get_message 'Show Amount Received data (without A/P data)'

      in window aWin @ 17, 2 winsay 'Configure Columns ' winget lConfigure ;
        picture 'Y' get_message 'Select, Order and Configure the Report Columns'

		in window aWin @ 18, 2 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

      read

      do case
      case lastkey()==K_ESC
         exit
      case !empty( cProduct )
         if !validTest(V_PRODUCT, cProduct, VT_MESSAGE)
            loop
         endif
      endcase

      if !lQty .and. !lAp
         waitInfo({'You need to look at either the AP or Qty Report'})
         loop
      endif

      if SelectPrn('DAYSUM1.TXT')
         aTitle := {TheClientName( ), '' }

         if !empty(cPayGrp)
            aadd( aTitle, 'PayGroup = '+cPayGrp+' '+NameOf(LU_PAYGRP,cPayGrp) )
         endif
         if nStatus <> 0
            aadd( aTitle, 'Grower Price Level = '+str(nStatus,3) )
         endif

         aadd( aTitle,"From "+shMDY(dFrom)+' to '+shMDY(dTo) )
         if !empty(cDepot)
	         n := len( aTitle)
	         aTitle[n] += '  Depot='+cDepot
	      endif

         if !empty( cProduct )
            aadd( aTitle, ;
               'For '+alltrim(cProduct)+' '+NameOf(LU_PRODUCT, cProduct) )
         endif
         if !empty( nProdCat )
            aadd( aTitle, ;
               'For Category '+NameOf(LU_PRODUCT_CATEGORY, nProdCat) )
         endif
         if !empty( cProcess )
            aadd( aTitle, ;
               'For Process '+cProcess+' '+NameOf(LU_PROCESS_TYPE, cProcess) )
         endif

         msgLine('Selecting and Sorting Data...')

         if !GatherInfo(  )
            exit
         endif

         dbSelectAr( cFile1 )
         goto top

         PRINT_ON  RPT_OVERWRITE

         if lSummary
            for n := 1 to 2
               if (n == 1 .and. lQty) .or. ;
                  (n == 2 .and. lAp )

                  aRpt := {}
                  if n == 1
                     cRpt := RP_BYDAYSUM
                     theRptCols( aRpt, SHOW_DATE, .f. )
                     c := ' '
                  else
                     // n == 2
                     cRpt := RP_BYDAY_AP
                     theRptCols( aRpt, SHOW_DATE, .t. )
                     c := ' A/P '
                  endif

                  gRptInit( cRpt, aRpt)

                  gRptInitHead()
                  gRptGetSetHead( RPT_HEAD_TITLE, aTitle )
                  aTitle[2] := 'Overall'+c+'Summary by Day'
                  gRptGetSetHead( RPT_HEAD_SUBTOTAL, .f. )

						// 2BFIXED colors in Summary - March 2019 - no Idea why this is worky

                  if lConfigure
                     gRptSelect( aRpt,  NIL, 'W+/B,N/R' )
                     if yesno({'Save this Format for'+c+'Day Summary?'})
                        gRptSave( aRpt )
                     endif
                  endif

						gRptPrintSize( aRpt )

                  (cFile1)->(dbGoTop())
                  (cFile1)->(gRptPrinter( aRpt ))

						if lLegend
							prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
						endif

                  lPrinted := .t.
               endif
            next
         endif

         if lDDetail
				if lPrinted
					nuFormFeed()
				endif

            aRpt := {}
            for n := 1 to 2
               if (n == 1 .and. lQty) .or. ;
                  (n == 2 .and. lAp )

                  aRpt := {}
                  if n == 1
                     cRpt := RP_BYDAY_DAY_GROWER
                     theRptCols( aRpt, SHOW_GROWER, .f. )
                     c := ' '
                  else
                     // n == 2
                     cRpt := RP_BYDAY_AP_DAY_GROWER
                     theRptCols( aRpt, SHOW_GROWER, .t. )
                     c := ' A/P '
                  endif

                  gRptInit( cRpt, aRpt)

                  gRptInitHead()
                  gRptGetSetHead( RPT_HEAD_TITLE, aTitle )
                  aTitle[2] := 'By Day '+c+'Summary Showing Each Grower'

                  gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| (cFile2)->date } )
                  gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
                     {|| nuQprnOut( shMDY( (cFile2)->date ) ) } )
                  gRptGetSetHead( RPT_HEAD_SUBTOTAL, .t. )

                  if lConfigure
                     gRptSelect( aRpt, NIL, 'R/W,GR+/B' )
                     if yesno({'Save this Format for'+c+'Day/Grower Summary?'})
                        gRptSave( aRpt )
                     endif
                  endif

						gRptPrintSize( aRpt )

                  (cFile2)->(dbGoTop())
                  (cFile2)->(gRptPrinter( aRpt ))

						if lLegend
							prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
						endif

               endif
            next
         endif

			PRINT_OFF  RPT_COMPLETE_EJECT

         (cFile1)->(dbCloseArea( ))
         (cFile2)->(dbCloseArea( ))

         Daily->(dbCloseArea())

         KillUnique(cFile1,'.DBF')
         KillUnique(cFile2,'.DBF')
         KillUnique(cFile3,'.CDX')

         if !OpenFile({'Daily'},DB_SHARED)
            exit
         endif
      endif
   enddo
   kill window aWin
   close databases
return( nil )

static function GatherInfo(  )
   local nGrower
   local lOk := .f.
   local aStru
   local dDate

   msgLine('Getting Ready...')

   aStru := { ;
      { 'NUMBER', 'N', FLD_NUMBER, 0}, ;
      { 'NAME',   'C', FLD_NAME,   0}, ;
      { 'DATE',   'D', 8,   0}, ;
      { 'PAYGRP', 'C', FLD_PAYGRP, 0}, ;
      { 'STATUS', 'N',  1, 0}, ;
      { 'TOTRECD','N', 10, 0}, ;
      { 'CLASS1', 'N', 10, 0}, ;
      { 'CLASS2', 'N', 10, 0}, ;
      { 'CLASS3', 'N', 10, 0}, ;
      { 'CLASS4', 'N', 10, 0}, ;
      { 'CAT0',   'N', 10, 0}, ;
      { 'CAT1',   'N', 10, 0}, ;
      { 'CAT2',   'N', 10, 0}, ;
      { 'CAT3',   'N', 10, 0}, ;
      { 'CAT4',   'N', 10, 0}, ;
      { 'CAT5',   'N', 10, 0}, ;
      { 'CAT6',   'N', 10, 0}, ;
      { 'TOTVALUE',  'N', 12, 2}, ;
      { 'TOPAY',     'N', 12, 2}, ;
      { 'UNDETRECD', 'N', 10, 0}    }

   cFile1 := UniqueDBF(  aStru )
   cFile2 := UniqueDBF(  aStru )
   cFile3 := UniqueFile()

   if empty( cFile1) .or. empty( cFile2 )
      return( .f. )
   endif

   msgLine('Thinking like a little fiend...')

   // Daily->( dbSetFilter( { || !empty( Daily->product )}, '!empty( Daily->product )' ))

	InitGeneralFor( { || .t. }, { || .t. }, { || .t. }, ;
		   { || InclPrdPrcGrDepo( cProduct,cProcess, 0, cDepot ) } )

   Daily->(dbSetFilter( { || GeneralFor() } ))

   Daily->(OrdSetFocus(DAILY_DATE_ORD))
   Daily->(dbSeek( dtos(dFrom), SOFTSEEK ))

   do while !Daily->(eof()) .and. Daily->date <= dTo
      dDate := Daily->date
      showProg( dtoc( dDate) )

      (cFile1)->(dbAppend())
      (cFile1)->date := dDate
      do while Daily->date == dDate .and. !Daily->(eof())
         nGrower := Daily->number

         ValidTest( V_GROWER, nGrower, VT_NO_MESSAGE )

         if ( nStatus <> 0 .and. Grower->status <> nStatus) .or. ;
               (!empty(cPayGrp) .and. Grower->paygrp <> cPayGrp)

            do while Daily->number==nGrower .and. ;
                  Daily->date == dDate .and. !Daily->(eof())
               Daily->(dbSkip())
            enddo
         else
            (cFile2)->(dbAppend())
            (cFile2)->date   := dDate
            (cFile2)->number := nGrower
            (cFile2)->name   := Grower->name
            (cFile2)->status := Grower->status
            (cFile2)->payGrp := Grower->payGrp

            do while Daily->number==nGrower .and. ;
                  Daily->date == dDate .and. !Daily->(eof())

               ValidTest( V_PRODUCT, Daily->product, VT_NO_MESSAGE )

               lOk := .f.
               if Daily->product==cProduct .or. empty( cProduct )
                  if Product->category == nProdCat .or. nProdCat==0
                     if Daily->process==cProcess .or. empty( cProcess )
                        lOk := .t.
                     endif
                  endif
               endif

               if lOk
                  (cFile1)->TotRecd += Daily->net
                  (cFile2)->TotRecd += Daily->net
                  //    { 'TOTVALUE',  'N', 12, 2},       Total value
                  //    { 'TOPAY',   'N', 12, 2},         To Pay (currently)
                  //    { 'UNDETRECD', 'N,  10, 0}        UnDetermined AMT

                  // Sep 2009
                  if str( Daily->( FinalPrice() ),10,3 ) == str( 0, 10, 3)
                     (cFile1)->unDetRecd += Daily->net
                     (cFile2)->unDetRecd += Daily->net
                  else
                     (cFile1)->totValue += round( Daily->( FinalPrice() ) * Daily->net, 2)
                     (cFile1)->toPay    += round( Daily->( NetPayable()),  2)
                     (cFile2)->totValue += round( Daily->( FinalPrice() ) * Daily->net, 2)
                     (cFile2)->toPay    += round( Daily->( NetPayable()) , 2)
                  endif


                  if validTest(V_PROCESS_TYPE, Daily->process, VT_NO_MESSAGE)
                     do case
                     case Process->proc_class == PROCESS_CLASS_FRESH
                        (cFile1)->Class1 += Daily->net
                        (cFile2)->Class1 += Daily->net
                     case Process->proc_class == PROCESS_CLASS_PROCESSED
                        (cFile1)->Class2 += Daily->net
                        (cFile2)->Class2 += Daily->net
                     case Process->proc_class == PROCESS_CLASS_JUICE
                        (cFile1)->Class3 += Daily->net
                        (cFile2)->Class3 += Daily->net
                     otherwise
                        (cFile1)->Class4 += Daily->net
                        (cFile2)->Class4 += Daily->net
                     endcase
                  else
                     (cFile1)->Class4 += Daily->net
                     (cFile2)->Class4 += Daily->net
                  endif

                  do case
                  case Product->category == 1
                     (cFile1)->Cat1 += Daily->net
                     (cFile2)->Cat1 += Daily->net
                  case Product->category == 2
                     (cFile1)->Cat2 += Daily->net
                     (cFile2)->Cat2 += Daily->net
                  case Product->category == 3
                     (cFile1)->Cat3 += Daily->net
                     (cFile2)->Cat3 += Daily->net
                  case Product->category == 4
                     (cFile1)->Cat4 += Daily->net
                     (cFile2)->Cat4 += Daily->net
                  case Product->category == 5
                     (cFile1)->Cat5 += Daily->net
                     (cFile2)->Cat5 += Daily->net
                  case Product->category == 6
                     (cFile1)->Cat6 += Daily->net
                     (cFile2)->Cat6 += Daily->net
                  otherwise
                     (cFile1)->Cat0 += Daily->net
                     (cFile2)->Cat0 += Daily->net
                  endcase
               endif

               Daily->(dbSkip())
            enddo
         endif
      enddo
   enddo
	Daily->(dbClearFilter())

RETURN( .t. )

static function theRptCols( aRpt, nType, lAP )

   do case
   case nType == SHOW_GROWER
      aadd( aRpt, { '', {|| ' '}, 'C',1,0, .t., .f. , ;
         'Blank space for Looks' })
      aadd( aRpt,{ 'ID', {|| Field->number}, 'N', 4, 0, .t., .f., ;
         'Grower ID' })
      aadd( aRpt, {'Lvl', {||Field->status}, 'N', 3, 0, .t., .f., ;
         'Usual Grower Price Level'})
      aadd( aRpt, {'Name', {||Field->name},'C',30,0,.t., .f., ;
         'Grower Name (not Cheque Name)'})

   case nType == SHOW_DATE
      aadd( aRpt, { '', {|| ' '}, 'C',1,0, .t., .f. , ;
         'Blank space for Looks' })
      aadd( aRpt,{ 'Date', {|| shMDY( Field->date) }, 'C', 12, 0, .t., .f., ;
         'Date as MMM dd YYYY' })
   endcase

   aadd( aRpt, { 'Total', {||Field->totrecd},'N',9,0,.t., .t., ;
      'Total Received' } )

   aadd( aRpt, { 'Fresh', {||Field->class1},'N',8,0,.t., .t., ;
      'Fresh Production for this year, Process Class = ' + NameOf( LU_PROCESS_CLASS, PROCESS_CLASS_FRESH) })
   aadd( aRpt, { 'Process', {||Field->class2},'N',8,0,.t., .t., ;
      'Process Production for this year, Process Class = ' + ;
		                  NameOf(LU_PROCESS_CLASS, PROCESS_CLASS_PROCESSED )} )
   aadd( aRpt, { 'Juice', {||Field->class3},'N',8,0,.t., .t., ;
      'Juice Produced this year, Proces Class = ' + NameOf(LU_PROCESS_CLASS, PROCESS_CLASS_JUICE )   })
   aadd( aRpt, { 'Other', {||Field->class4},'N',8,0,.t., .t., ;
      'Other production for this year, Process Class = ' + NameOf(LU_PROCESS_CLASS, PROCESS_CLASS_OTHER) } )

   aadd( aRpt, { '', {|| ' '}, 'C',1,0, .f., .f. , ;
      'Blank space for Looks' })

   if lAP
      //    { 'TOTVALUE',  'N', 12, 2},       Total value
      //    { 'TOPAY',   'N', 12, 2},         To Pay (currently)
      //    { 'UNDETRECD', 'N,  10, 0}        UnDetermined AMT

      aadd( aRpt, { 'Tot Value', {||Field->TotValue},'N',12,2,.t., .t., ;
         'Total Known Value of receipts' })
      aadd( aRpt, { 'to Pay', {||Field->ToPay},'N',12,2,.t., .t., ;
         'Total Known Value of receipts' })
      aadd( aRpt, { 'Unknown Wt', {||Field->unDetRecD},'N',11,0,.t., .t., ;
         'Weight of Receipts where Final Price is unknown' })

   else
      aadd( aRpt, { sysValue( SYS_PRODUCT_CATEGORY_1), {||Field->cat1},'N',8,0,.t., .t., ;
         'Product Category 1 '+sysValue( SYS_PRODUCT_CATEGORY_1 )+ ' receipts' })
      aadd( aRpt, { sysValue( SYS_PRODUCT_CATEGORY_2), {||Field->cat2},'N',8,0,.t., .t., ;
         'Product Category 2 '+sysValue( SYS_PRODUCT_CATEGORY_2 )+ ' receipts' })
      aadd( aRpt, { sysValue( SYS_PRODUCT_CATEGORY_3), {||Field->cat3},'N',8,0,.t., .t., ;
         'Product Category 3 '+sysValue( SYS_PRODUCT_CATEGORY_3 )+ ' receipts' })
      aadd( aRpt, { sysValue( SYS_PRODUCT_CATEGORY_4), {||Field->cat4},'N',8,0,.t., .t., ;
         'Product Category 4 '+sysValue( SYS_PRODUCT_CATEGORY_4 )+ ' receipts' })
      aadd( aRpt, { sysValue( SYS_PRODUCT_CATEGORY_5), {||Field->cat5},'N',8,0,.t., .t., ;
         'Product Category 5 '+sysValue( SYS_PRODUCT_CATEGORY_5 )+ ' receipts' })
      aadd( aRpt, { sysValue( SYS_PRODUCT_CATEGORY_6), {||Field->cat6},'N',8,0,.t., .t., ;
         'Product Category 6 '+sysValue( SYS_PRODUCT_CATEGORY_6 )+ ' receipts' })
      aadd( aRpt, { 'Non Cat', {||Field->cat0},'N',8,0,.t., .t., ;
         'Non Categorized Product Receipts' })

   endif
return( nil )

