// PROGRAM...: GLIST.PRG
// AUTHOR ...: DUNCAN JEFFRIES - QUANTUM RESEARCH
// DATE .....: 5/6/90
// NOTES ....: THIS ROUTINE PRODUCES THE GROWER REPORT
// BH May 26, 1994, revised to deal with shares
// June 95, revised, shares are too much trouble, never worked right
// June 99 - some changes - Bill Hepler
// June 2005 - widen phone number.
// July 2009 - Labels are 3 up or whatever, for LASER ONLY.
// Nov 2021  - Add in Address Lines as single columns, also print in Landscape
// Jan 2022  - Minor Mod to save report formats

#include 'BerryPay.ch'
#include 'bsgstd.ch'
#include 'printer.ch'
#include 'inkey.ch'
#include 'price.ch'
#include 'window.ch'
#include 'radio.ch'
#include "field.ch"
#include "sysvalue.ch"
#include "rpt.ch"
#include "valid.ch"
#include 'berry_rpt.ch'
#include 'common.ch'

#define  LAST_LINE_TO_PRINT       59

static dFrom,dTo, cStatus
static lPayGrp,cOrder
static cPayGrp

function growerList_1()
	local getList :={}, aWin,  aRptType, nRptType
	local aRpt
	local lNname
   local n1
   local nRow := 0, nCol := 0
   local aRay
   local oPS, oOldFont, oFont
   local lConfigure := .f., lLegend := .f.
   local cHeading := ''

	cPayGrp := space(FLD_PAYGRP)
	dFrom := dTo := date()
	lPayGrp := .t.
	cOrder := 'N'
	cStatus := space(9)

   if !openfile({'Grower','PayGrp', 'RptCfg'},DB_SHARED)
		close databases
		return( nil )
	endif

   if !GetToReport( REPORTS_GROWER_LABEL1, 'Grower Laser Label')
      close databases
      return( nil )
   endif
   // RptCfg is LOCKED!
   default RptCfg->TYPEFACE to 4
   default RptCfg->pitch to 10
   default RptCfg->symbol to '10U'
   default RptCfg->isfixed to .f.

   myBsgScreen( 'Grower List' )

   create window at 4,3,22,76 title 'Grower List' to aWin
	display window aWin

   create radiobox 6,46 using  { ;
	 'Address List     ', ;
	 'Grower Statistics', ;
	 'Mailing Labels   ' } frame title 'Report Type' to aRptType
   nRptType := 1

	lNname := .t.
	do while .t.
		RadioShow(aRptType,nRptType)

      in window aWin @ 2,2 winsay 'Show Normal Grower Name:     ' ;
		 winGet lNname PICTURE 'Y' GET_MESSAGE ;
		 'Y = Show Normal Grower Name,  N = Show Name as appears on Cheque'

      in window aWin @ 3,2 winsay 'Alpha or Numeric Order (A/N):' ;
		 winGet cOrder PICTURE '!' valid cOrder $ 'AN' GET_MESSAGE ;
		 'A = Alphabetical list of growers by Grower Name (not Cheque Name!)'
      in window aWin @ 4,2 winsay 'In PayGrp Order' ;
		 winGet lPayGrp PICTURE 'Y' GET_MESSAGE ;
		 'Growers who are being paid together can be put into the same Group'

      in window aWin @ 5,2 winsay 'Grower Status  ' winget cStatus ;
		 picture '@!' GET_MESSAGE ;
		 'Leave blank for all, or enter the status numbers you wish to print'

      in window aWin @ 6,2 winsay 'Specific PayGrp' winget cPayGrp ;
		  picture '@!' ;
			LookUp( LU_PAYGRP,  ;
         'Leave Blank for All Grower Payment Groups')
      read
      if lastkey()==K_ESC
         exit
      endif

		nRptType := RadioDo(aRptType,nRptType)

      do case
      case nRptType == 0
         loop
      case nRptType == 1
         in window aWin @ 8,2 winclear to 19,70
         in window aWin @ 8,2 winsay 'Configure Report? ' winget lConfigure ;
           picture 'Y' get_message 'Set columns to print'
			in window aWin @ 9,2 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
			 get_message "Say YES to Show Details of how Columns are Calculated"
			in window aWin @ 11,2 winsay 'If the Report is wider than '+ var2char(sysValue( SYS_GENERALLY_SWITCH_TO_LANDSCAPE))+' columns'
         in window aWin @ 12,2 winsay 'then the Report will be printed in LandScape'

         read

      case nRptType == 2
         in window aWin @ 8,2 winclear to 19,70
         in window aWin @ 8,2 winsay 'Configure Report? ' winget lConfigure ;
           picture 'Y' get_message 'Set columns to print'
			in window aWin @ 9,2 winsay 'Show Column Legend' winget lLegend picture 'Y' ;
			 get_message "Say YES to Show Details of how Columns are Calculated"
			in window aWin @ 11,2 winsay 'If the Report is wider than '+ var2char(sysValue( SYS_GENERALLY_SWITCH_TO_LANDSCAPE))+' columns'
         in window aWin @ 12,2 winsay 'then the Report will be printed in LandScape'

         read

      case nRptType == 3
         // Labels
         in window aWin @ 8,2 winclear to 19,70

         in window aWin @ 8,2 winsay 'Laser Label Setup'
         in window aWin @  9, 3 winsay 'From Left' ;
          winGet RptCfg->xTop picture '9.99' get_message ;
          'Inches from Left of Page'
         in window aWin @ 9,30 winsay 'From top' ;
          winGet RptCfg->yTop picture '9.99' get_message ;
          'Inches from Top of Page'

         in window aWin @ 10,3 winsay 'Columns of Labels' ;
          winGet RptCfg->cols picture '9' get_message ;
          'Columms of Labels (.e.g. 1-4)'
         in window aWin @ 10,30 winsay 'Rows' ;
          winGet RptCfg->rows picture '99' get_message ;
          'Rows of Labels (e.g. 10)'

         in window aWin @ 11, 3 winsay 'Label Width/Height' ;
          winGet RptCfg->width picture '9.999' get_message ;
          'Width of Label (e.g. 3 inches)'
         in window aWin @ 11,32 winGet RptCfg->height picture '9.999' ;
          get_message 'Height of Labels (e.g. 1 inch)'

         in window aWin @ 12,3 winGet RptCfg->w32Font ;
          lookup( LU_WIN_ANY_WIN_FONT, 'F5=Lookup - Enter Font for Windows Printer' )

         in window aWin @ 14,2 winsay 'For Labels compatible with Avery 5161-8161'
         in window aWin @ 15,2 winsay 'which 2 Up x 10 down (20 labels/page), try:'
         in window aWin @ 16,2 winsay 'Left = 0.5  Top= 0.75  Col=2  Rows=10'
         in window aWin @ 17,2 winsay 'Font =   12.Arial  (is readable)'

         read
      endcase

		do case
      case lastkey()==K_ESC
         exit
      case lastkey()==K_UP
		 	loop
		endcase

		cHeading := iif(empty(cStatus),'','Status = '+alltrim(cStatus)+' ')

		if SelectPrn('GROWER.TXT')
			do case
			 case nRptType==1
   	  		if SetGrow4Rpt(lPayGrp,cPayGrp,cOrder )
					aRpt := {}

               CfgGrowRpt( aRpt, lNname )

               gRptInit( REPORTS_GROWER_LABEL1, aRpt)
               if lConfigure
                  gRptSelect( aRpt )
               endif

					gRptInitHead()
               gRptGetSetHead( RPT_HEAD_TITLE, {'Grower List 1', cHeading})

					gRptGetSetHead( RPT_HEAD_FOR_CONDITION, ;
						{ || ListTheGoof() })

               gRptAutoPageOrientation( aRpt, 0)

   	  			PRINT_ON  RPT_OVERWRITE
					gRptPrintSize( aRpt )

					// Grower->(dbGotop())
					Grower->(gRptPrinter( aRpt ))

   	  			PRINT_OFF  RPT_COMPLETE_EJECT
					if lConfigure
						if yesno({'Save this Production Report Format #1?'})
							gRptSave( aRpt )
						endif
					endif
				endif

			 case nRptType == 2
            if !empty( cStatus)
               cHeading := 'Status: '+alltrim(cStatus)
            else
               cHeading := ''
            endif

	      	cHeading += ' in Dates '+shMDY(dFrom)+' - '+shMDY(dTo) + ;
				  iif(empty(cPayGrp),"",", for PayGrp "+cPayGrp)

				if SetGrow4Rpt(lPayGrp,cPayGrp,cOrder )
               aRpt := {}

               CfgGrowRpt( aRpt, lNname )

               gRptInit( REPORTS_GROWER_LIST2, aRpt)
               if lConfigure
                  gRptSelect( aRpt )
               endif

					gRptInitHead()
               gRptGetSetHead( RPT_HEAD_TITLE, {'Grower List 2', ;
                 cHeading })

					gRptGetSetHead( RPT_HEAD_FOR_CONDITION, ;
						{ || ListTheGoof() })

					gRptAutoPageOrientation( aRpt, 0)

   	  			PRINT_ON  RPT_OVERWRITE
					gRptPrintSize( aRpt )

					// Grower->(dbGotop())
					Grower->(gRptPrinter( aRpt ))

   	  			PRINT_OFF  RPT_COMPLETE_EJECT
					if lConfigure
						if yesno({'Save this Production Report Format #1?'})
							gRptSave( aRpt )
						endif
					endif

		      endif

			 case nRptType==3
   	  		if SetGrow4Rpt(lPayGrp,cPayGrp,cOrder )
   	  			PRINT_ON  RPT_OVERWRITE

               if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
                  if !empty( RptCfg->w32Font )
                     oPS := w32oPS()
                     oFont := xBpFont( ):new( oPS )
                     oFont:create( alltrim( RptCfg->w32Font ) )
                     oOldFont := GraSetFont( oPS, oFont )
                  else
                     PrinterCtrl(PRN_CTRL_12_CPI)
                  endif
               else
                  hpPortLtr()
                  HPtoDefaFont()

                  hpSetFontStuff( ;
                        RptCfg->TypeFace, ;
                        RptCfg->Symbol,   ;
                        RptCfg->isFixed,    ;
                        RptCfg->Darkness, ;
                        RptCfg->Pitch)
               endif
               nRow := 1
               nCol := 1

					do while !Grower->(eof())
						if ListTheGoof()
                     if nCol > RptCfg->cols
                        nRow++
                        nCol := 1
                     endif
                     if nRow > RptCfg->rows
                        nuFormFeed()
                        nRow := 1
                        nCol := 1
                     endif

                     // x, y
                     if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
                        if lNname
                           aRay := { alltrim( Grower->NAME  )  }
                        else
                           aRay := { alltrim( Grower->cheqNAME  )  }
                        endif

                        aadd( aRay,  alltrim(Grower->STREET) )

                        if !empty( Grower->street2)
                           aadd( aRay,  alltrim(Grower->STREET2) )
                        endif

                        aadd( aRay, alltrim(Grower->city) )
                        n1 := len( aRay)
                        if empty(Grower->prov)
                           if right( Grower->city,2 )<>'BC'
                              aRay[n1] +=' BC'
                           endif
                        else
                           aRay[n1] += ' '+alltrim( Grower->prov )
                        endif
                        aRay[n1] +=  '  '+ Grower->PCODE

                        W32PrnTextArray( aRay, ;
                          RptCfg->xTop + (nCol-1)*RptCfg->width , ;
                          RptCfg->yTop + (nRow-1)*RptCfg->height, ;
                           11/72 )
                     else
                        hpAbsPrnPosition(   ;
                          RptCfg->xTop + (nCol-1)*RptCfg->width , ;
                          RptCfg->yTop + (nRow-1)*RptCfg->height )

                        if lNname
                           nuQQprnOut( alltrim( Grower->NAME  )   )
                        else
                           nuQQprnOut( alltrim( Grower->cheqName ))
                        endif
                        nuQprnOut( )
                        n1 := 1/6
                        if !empty( Grower->street)
                           hpAbsPrnPosition(    ;
                              RptCfg->xTop + (nCol-1)*RptCfg->width , ;
                             RptCfg->yTop + (nRow-1)*RptCfg->height+ 1/6 )

                           nuQQprnOut(  alltrim(Grower->STREET) )
                           n1 += 1/6
                           nuQprnOut( )
                        endif
                        if !empty( Grower->street2)
                           hpAbsPrnPosition(    ;
                              RptCfg->xTop + (nCol-1)*RptCfg->width , ;
                             RptCfg->yTop + (nRow-1)*RptCfg->height+ n1 )

                           nuQQprnOut(  alltrim(Grower->STREET2) )
                           n1 += 1/6
                           nuQprnOut( )
                        endif

                        hpAbsPrnPosition(     ;
                          RptCfg->xTop + (nCol-1)*RptCfg->width , ;
                          RptCfg->yTop + (nRow-1)*RptCfg->height+ n1 )

                        nuQQprnOut( alltrim(Grower->city) )

                        if empty(Grower->prov)
                           nuQQprnOut( ' BC' )
                        else
                           nuQQprnOut( ' '+alltrim( Grower->prov ) )
                        endif
                        nuQQprnOut(  '  '+ Grower->PCODE )
                        nuQprnOut( )
                     endif
                     nCol++
                  endif
						Grower->(dbSkip())
					enddo
               if gsNuPrinterType()==NUPRINT_PRN_TYPE_W32FIXED
                  if !empty( RptCfg->w32Font )
                     GraSetFont( oPS, oOldFont )
                  else
                     PrinterCtrl(PRN_CTRL_10_CPI)
                  endif
               endif
   	  			PRINT_OFF  RPT_COMPLETE_EJECT
   	  		endif
   	  	endcase
   	endif
   enddo

   kill window aWin
   close databases

return( nil )


/* --------------------
static function PrintList( lConfigure, lNname )
         @nLine,  7 SAY str(Grower->STATUS,1) + ' '+Grower->Contract

			if lNname
	      	@nLine,12 SAY Grower->NAME
			else
	      	@nLine,12 SAY Grower->CheqNAME
			endif

      	@nLine, 44 SAY Grower->STREET
      	@nLine, 71 SAY Grower->CITY
      	@nLine, 94 SAY Grower->PCODE
      	@nLine,103 SAY Grower->PHONE
         @nLine,118 SAY Grower->ACRES PICTURE      cPic1

			if Grower->currency<>CANADIAN_DOLLARS
				@ nLine,0 say 'U$'
			endif
------------------------------------- */


static function ListTheGoof(  )
	local lReturn

	if empty(cStatus)
		lReturn := .t.
	else
		lReturn := str(Grower->status,1) $ alltrim(cStatus)
	endif

return( lReturn )

static function CfgGrowRpt( aRpt, lNname )

   aadd( aRpt,{ 'ID', {|| Grower->number}, 'N', 6, 0, .t., .f., ;
      'ID' })

   if lNname
      aadd( aRpt, ;
         { 'Name'    , { || Grower->name } ,  'C' , 030 ,  000 , ;
            .t., .f. , ;
            'Grower Name (not Cheque Name)' } )
   else
      aadd( aRpt, ;
         { 'Name'    , { || Grower->cheqname } ,  'C' , 030 ,  000 , ;
            .t., .f. , ;
            'Grower Name as appears on cheque' } )
   endif

   aadd( aRpt, ;
      { 'Address'    , ;
         { { || Grower->street } , ;
         { || alltrim(Grower->city)+' '+Grower->prov }, ;
         { || Grower->pcode } }, ;
         'M' , 030 ,  000 , ;
         .t., .f. , ;
         'Street Address in MultiLine' } )

   aadd( aRpt, ;
      { 'City'    , { || Grower->city } ,  'C' , 021 ,  000 , ;
         .f., .f. , ;
         'City' } )

   aadd( aRpt, ;
      { ''  , { || Grower->prov } ,  'C' , 02 ,  000 , ;
         .f., .f. , ;
         'Prov' } )
   aadd( aRpt, ;
      { 'Zip'  , { || Grower->pcode } ,  'C' , 09 ,  000 , ;
         .f., .f. , ;
         'Prov' } )
   aadd( aRpt, ;
      { 'Phones'   , ;
         { { || Grower->phone  } , ;
            { || Grower->phone2 } }, ;
            'M' , 14 ,  000 , ;
         .t., .f. , ;
         'Other Main Phone Numbers' } )

   aadd( aRpt, ;
      { 'Acres'   , { || Grower->acres } ,  'N' , 05 ,  000 , ;
         .f., .f. , ;
         'Acres in Production' } )

   aadd( aRpt, { 'Grp', {|| Grower->payGrp}, "C", 3, 0 , ;
         .t., .f., 'Grower Payment Group' })

   aadd( aRpt, ;
      { 'Hold?'   , { || iif(Grower->onHold,'HELD!',space(5) )} , ;
            'C' , 5 ,  000 , ;
         .f., .f. , ;
         'On Hold ?' } )

   aadd( aRpt, ;
      { 'LY Fresh'   , { || Grower->ly_fresh } ,  'N' , 08 ,  000 , ;
         .f., .f. , ;
         'Last Year Fresh Production - keyed in' } )
   aadd( aRpt, ;
      { 'LY Oth'   , { || Grower->ly_other } ,  'N' , 08 ,  000 , ;
         .f., .f. , ;
         'Last Year Other (non Fresh) Production - keyed in' } )

   aadd( aRpt, ;
      { 'Address'    ,  { || Grower->street } , ;
         'C' , 030 ,  000 , ;
         .f., .f. , ;
         'Street Address ONLY Single Line' } )
   aadd( aRpt, ;
      { 'Pr Lvl'    ,  { || Grower->status } , ;
         'N' , 006 ,  000 , ;
         .f., .f. , ;
         'Price Level' } )

   aadd( aRpt, ;
      { 'City/Prov'    , ;
         { || alltrim(Grower->city)+' '+Grower->prov }, ;
         'C' , 025 ,  000 , ;
         .f., .f. , ;
         'City + Prov' } )

   aadd( aRpt, ;
      { 'Added Name/Phones', ;
         { { || Grower->Alt_Name1 +'  '+ Grower->alt_phone1  } , ;
           { || Grower->Alt_Name2 +'  '+ Grower->alt_phone2  } , ;
			  { || padr(Grower->Notes,46)                       } , ;
			  { || padr(Grower->Note2,46)                       }    }, ;
            'M' , 46 ,  000 , ;
         .f., .f. , ;
         'Names & Alt Phone Numbers' } )

	aadd( aRpt, ;
		{ {'C','o','n'} , { || Grower->Contract } ,  'C' , 003 ,  000 , ;
         .f., .f. , ;
         'Does grower have a Contract?' } )

	aadd( aRpt, ;
		{ 'Cert' , { || Grower->Certified } ,  'C' , 008 ,  000 , ;
         .f., .f. , ;
         'Is grower Certified?' } )


return( nil )
