// PROGRAM...: Grower Lists 2 - similar to GLIST.PRG
// July 2002 - Bill Hepler
// Mar 2019 - Add Legend
// Nov 2021 - Landscape & some options for address formatting

#include 'berry_rpt.ch'
#include 'bsgstd.ch'
#include 'printer.ch'
#include 'inkey.ch'
#include 'indexord.ch'
#include 'window.ch'
#include "rpt.ch"
#include "valid.ch"
#include "sysvalue.ch"

function growerLists_2( lOnHold )
   local getList :={}, aWin
	local aRpt
   local cTitle
   local lConfigure := .f., lLegend := .f.
   local cRpt
   local cFile
   local lByName := .t.

	if !openfile({'Grower','PayGrp'},DB_SHARED)
		close databases
		return( nil )
	endif

   if lOnHold
      cTitle := 'Growers On Hold'
      cRpt   := RP_GROWER_ON_HOLD
      cFile  := 'ONHOLD.TXT'
   else
      cTitle := 'Growers by PayGroup'
      cRpt   := RP_GROWER_BY_PAYGROUP
      cFile  := 'PAYGRP.TXT'
   endif

   myBsgScreen( 'Report on '+cTitle )

   create window at 6,10,15,70 title 'List '+cTitle to aWin
	display window aWin

	do while .t.

      in window aWin @ 2,2 winsay 'Sort by Name' ;
       winGet lByName PICTURE 'Y' GET_MESSAGE ;
       'Y = List Growers by Name, N = List by Number'

      in window aWin @ 3,2 winsay 'Configure Report Columns' ;
       winGet lConfigure PICTURE 'Y' GET_MESSAGE ;
       'Y = Set & arrange Columns for this Report, N = Just run report'

		in window aWin @ 4,2 winsay 'Show Column Legend      ' winget lLegend picture 'Y' ;
		  get_message "Say YES to Show Details of how Columns are Calculated"

		in window aWin @ 6,2 winsay 'If the Report is wider than '+ var2char(sysValue( SYS_GENERALLY_SWITCH_TO_LANDSCAPE))+' columns'
      in window aWin @ 7,2 winsay 'then the Report will be printed in LandScape'

		read

      if lastkey()==K_ESC
			exit
      endif

      if SelectPrn( cFile )

         aRpt := {}
         setRptArray( aRpt, lOnHold )

         gRptInit( cRpt, aRpt)

         if lConfigure
            gRptSelect( aRpt )
         endif

         gRptInitHead( )
         gRptGetSetHead( RPT_HEAD_TITLE, {cTitle})

         if lOnHold
            gRptGetSetHead( RPT_HEAD_FOR_CONDITION, ;
                  { || Grower->onHold })
            gRptGetSetHead( RPT_HEAD_SUBTOTAL , .f.)
            gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, NIL )
            if lByName
               Grower->(OrdSetFocus( GROWER_NAME_ORD ))
            else
               Grower->(OrdSetFocus( GROWER_NUMBER_ORD ))
            endif
         else
            gRptGetSetHead( RPT_HEAD_FOR_CONDITION, NIL )
            gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)
            gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| Grower->payGrp } )
            gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
             {|| nuQprnOut( Grower->PayGrp+' '+NameOf(LU_PAYGRP, Grower->payGrp))})

            if lByName
               Grower->(OrdSetFocus( GROWER_PAYGRP_NAME_ORD ))
            else
               Grower->(OrdSetFocus( GROWER_PAYGRP_NUMBER_ORD ))
            endif
         endif

			gRptAutoPageOrientation( aRpt, 0)
         PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

         Grower->(dbGotop())
         Grower->(gRptPrinter( aRpt ))

			if lLegend
				prnRptLegend( aRpt, {'Grower Report Legend', cTitle }, .t. ) // only show columns selected
			endif

         PRINT_OFF  RPT_COMPLETE_EJECT

         if lConfigure
            if yesno({'Save Report Format?' })
               gRptSave( aRpt )
            endif
         endif
   	endif
   enddo
   kill window aWin
   close databases

return( nil )

static function setRptArray( aRpt, lOnHold )

   aadd( aRpt,{ '', {|| ' '}, 'C', 1, 0, !lOnHold, .f., ;
      'Space For Looks' })

   aadd( aRpt,{ 'ID', {|| Grower->number}, 'N', 6, 0, .t., .f., ;
      'Grower ID' })

   aadd( aRpt, ;
         { 'Name'    , { || Grower->name } ,  'C' , 030 ,  000 , ;
            .t., .f. , ;
            'Grower Name (not Cheque Name)' } )
   aadd( aRpt, ;
         { 'Name'    , { || Grower->cheqname } ,  'C' , 030 ,  000 , ;
            .f., .f. , ;
            'Grower Name as appears on cheque' } )

   aadd( aRpt, ;
      { 'Address 1' , { || Grower->street } ,  'C' , 025 ,  000 , ;
         .f., .f. , ;
         'Street Address (1st line)' } )

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
      { 'Phone'   , { || Grower->phone } ,  'C' , 13 ,  000 , ;
         .t., .f. , ;
         'Phone' } )

   aadd( aRpt, ;
      { 'Acres'   , { || Grower->acres } ,  'N' , 05 ,  000 , ;
         .f., .f. , ;
         'Acres in Production' } )

   aadd( aRpt, { 'Grp', {|| Grower->payGrp}, "C", 3, 0 , ;
        lOnHold, .f., 'Grower Payment Group' })

   aadd( aRpt, { 'Hold', {|| iif(Grower->onHold,'HOLD','   ')}, "C", 4, 0 , ;
        !lOnHold, .f., 'Is Grower on hold...' })

   aadd( aRpt, ;
      { 'Phone2'   , { || Grower->phone2 } ,  'C' , 13 ,  000 , ;
         .f., .f. , ;
         'Alternate Phone' } )

   aadd( aRpt, ;
      { 'PrLvl'   , { || Grower->Status } ,  'N' , 5 ,  000 , ;
         .t., .f. , ;
         'Grower Price Level' } )

   aadd( aRpt, ;
      { 'LY Fresh'   , { || Grower->ly_Fresh } ,  'N' , 08 ,  000 , ;
         .f., .f. , ;
         'Last Years Fresh Production - keyed in' } )
   aadd( aRpt, ;
      { 'LY Other'   , { || Grower->ly_other } ,  'N' , 08 ,  000 , ;
         .f., .f. , ;
         'Last Years Other (nonFresh) Production - keyed in' } )

   aadd( aRpt, ;
      { 'Address'    , ;
         { { || Grower->street } , ;
         { || alltrim(Grower->city)+' '+Grower->prov }, ;
         { || Grower->pcode } }, ;
         'M' , 030 ,  000 , ;
         .f., .f. , ;
         'Street Address in MultiLine' } )

   aadd( aRpt, ;
      { 'Address 2' , { || Grower->street2 } ,  'C' , 025 ,  000 , ;
         .f., .f. , ;
         'Street Address (2nd line)' } )

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
      { 'Phones'   , ;
         { { || Grower->phone  } , ;
           { || Grower->phone2 } }, ;
            'M' , 14 ,  000 , ;
         .f., .f. , ;
         'Other Main Phone Numbers' } )

	aadd( aRpt, ;
		{ {'C','o','n'} , { || Grower->Contract } ,  'C' , 003 ,  000 , ;
         .f., .f. , ;
         'Does grower have a Contract?' } )

	aadd( aRpt, ;
		{ 'Cert' , { || Grower->Certified } ,  'C' , 008 ,  000 , ;
         .f., .f. , ;
         'Is grower Certified?' } )
	
return( nil )


