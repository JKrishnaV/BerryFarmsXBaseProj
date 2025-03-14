// June 17, 1994
// Bill Hepler
//    May 99 - revised the blinking thing
//    June 2010
//    Sep 23 2011 - add stuff for Deleting
//    April 2020 - cleaned up BH
// (c) 1994, 2011, 2020 by Bill Hepler


#include 'bsgstd.ch'
#include 'colors.ch'
#include 'version.ch'
#include 'common.ch'
#include "myver.ch"
#include 'setcurs.ch'
#include 'BerryPay.ch'
#include 'signon.ch'
#include 'errors.ch'


static bFor1, bFor2, bFor3, bFor4

function ReasonablePostDate( d , lShowMsg, cInfo )
	local lReturn := .t.
	local aRay := {'Hmm Not sure about this.'}

	default lShowMsg to .f.
	default cInfo to ''

   if !empty( cInfo )
   	aRay := { cInfo }
   endif

	do case
	case empty( d )
		aadd( aRay,'The date entered is Empty!')
		lReturn := .f.
	case d < date() - 367
		aadd( aRay,'The date entered is '+medMdy( d )+'--Too Early!')
      aadd( aRay,'You should be afer ' + medMdy( date() - 366)    )
		lReturn := .f.
	case d > date() + 150
		aadd( aRay,'The date entered is '+medMdy( d )+'--Too far ahead!')
      aadd( aRay,'You should be BEFORE '+medMdy( date() + 150 ) )
		lReturn := .f.
	endcase

	if lShowMsg .and. !(lReturn )
		WaitInfo( aRay )
	endif

return( lReturn )


function PrnAtSay( nRow, nCol, xVal, xPicture )
   local c

   if nuPrnRow() > nRow
      nuFormFeed()
   endif

   do while nuPrnRow() < nRow .and. nuPrnRow() < 171
   	// the 171 is just to keep it from going forever...
      nuQprnOut()
   enddo

   do while nuPrnColumn() < nCol .and. nuPrnColumn() < 179
   	// the 179 is just to keep it from going forever...
      nuQQprnOut(' ')
   enddo

   do case
   case valType(xPicture)=='C'
      c := transform( xVal, xPicture )
      nuQQprnOut( c )
   case valType(xVal)=='C'
      nuQQprnOut( xVal )
   case valType(xVal)=='D'
      nuQQprnOut( dtoc( xVal ))
   case valType( xVal)=='N'
      nuQQprnOut( xVal )
   otherwise
      nuQQprnOut( Var2Char( xval ))
   endcase

return( nil )



function InitGeneralFor( bF1, bF2, bF3, bF4 )
	default bF1 to { || .t. }
	default bF2 to { || .t. }
	default bF3 to { || .t. }
	default bF4 to { || .t. }

	bFor1 := bF1
	bFor2 := bF2
	bFor3 := bF3
	bFor4 := bF4

	if valType( bFor1 ) <> 'B'
		appError( APP_ERR_GENERAL_FOR_1, {'Wrong Type Set to InitGeneralFor()', ;
		       'Type='+valType( bFor1 ) })
		bFor1 := { || .t. }
	endif
	if valType( bFor2 ) <> 'B'
		appError( APP_ERR_GENERAL_FOR_2, {'Wrong Type Set to InitGeneralFor()', ;
		       'Type='+valType( bFor2 ) })
		bFor2 := { || .t. }
	endif
	if valType( bFor3 ) <> 'B'
		appError( APP_ERR_GENERAL_FOR_3, {'Wrong Type Set to InitGeneralFor()', ;
		       'Type='+valType( bFor3 ) })
		bFor3 := { || .t. }
	endif
	if valType( bFor4 ) <> 'B'
		appError( APP_ERR_GENERAL_FOR_4, {'Wrong Type Set to InitGeneralFor()', ;
		       'Type='+valType( bFor4 ) })
		bFor4 := { || .t. }
	endif

return( nil )

function GeneralFor()
	local lReturn := .f.

	if eval( bFor1 )
		if eval( bFor2 )
			if eval( bFor3 )
				if eval( bFor4 )
					lReturn := .t.
				endif
			endif
		endif
	endif

return( lReturn )

function NiceMenu( nBar, cTitle, nRow, nCol, aMenu, cMess )
   // emulates menu to
   // returns the selected 0 for ESC
   // the first menu item determines width !

   // row,column,title,array with choices.
   // nBar is the returned value
   // sample call:
   //
   // kk := bsgmenu(kk, 'Main Menu', 3,3, { ;
   //        {'1. Do something nice','Message'}, ;
   //        {'2. Do something neat','sdfdasf'}, ;
   //        {'3. Who cares anyway ','fdasdjfj '}, ;
   //        {'Q. Quit             ','Leave the Program' } )

   // This program takes a variable number of menu items as parameters.
   // These menu items are counted and put into an array, and we then
   // display the menu....
   // the @kk is to ensure that when you return to the PROMPTs you are still
   // on the same menu item....
   //
   // this program DOES NOT address saving screens and so on.

   local nItems,nWidth,nLength,lQuit,  n, aMsg
   local promptList := {}

	nItems := len(aMenu)        // how many are there ?

   // is there a Q. Quit ??
	if valtype(aMenu[nItems])=='A'
   	lQuit := (' QUIT' $ upper(aMenu[nItems,1]) ) .or. ;
   	 'QUIT'==upper(substr(aMenu[nItems,1],1,4))
		nWidth := max( len(cTitle), len(aMenu[1,1]) ) + 7
   else
   	lQuit := (' QUIT' $ upper(aMenu[nItems]) ) .or. ;
       'QUIT'==upper(substr(aMenu[nItems],1,4))
		nWidth := max( len(cTitle), len(aMenu[1]) ) + 7
   endif

	store nItems+3 + iif(lQuit,1,0) to nLength

	DEFAULT cMess to '[Esc] to Exit'
	if len(cMess)==0
		cMess := '[Esc] to Exit'
	endif
	aMsg := msgLine( cMess )

	bsgSetColor(COLOR_MENU)

	@ nRow,nCol clear to  nRow + nLength,nCol+nWidth

	@ nRow,nCol +1 to  nRow + nLength,nCol+nWidth -1 double

	@ nRow,nCol + 4 say alltrim(cTitle)

	bsgSetColor(COLOR_OMENU)
	@ nRow+1,nCol +2 clear to  nRow + nLength -1,nCol+nWidth -2

	shadow( nRow, nCol, nRow + nLength, nCol+nWidth )

	for n = 1 to nItems
		if valtype(aMenu[n])=='A'
			if lQuit .and. n=nItems
				//	this is QUIT
				@ nRow+2 + n, nCol+4 prompt aMenu[n,1] message padr(aMenu[n,2],80)
			else
				@ nRow+1 + n, nCol+4 prompt aMenu[n,1] message padr(aMenu[n,2],80)
			endif
		else
			if lQuit .and. n=nItems
				//	this is QUIT
				@ nRow+2 + n, nCol+4 prompt aMenu[n]
			else
				@ nRow+1 + n, nCol+4 prompt aMenu[n]
			endif
		endif
	next

	menu to nBar

	bsgSetColor(COLOR_OMENU)
	@ nRow,nCol,  nRow + nLength,nCol+nWidth box space(8)

	@ nRow,nCol +1 to  nRow + nLength,nCol+nWidth -1

	@ nRow,nCol + 4 say alltrim(cTitle)

	bsgSetColor(COLOR_MAIN)
   rest_scr(aMsg)

return(nBar)


function EditByFlds()
   // June 2003
   // should be called as follows:
   //     if Customer->(RecLock())
   //         Customer->custName := cCustName
   //         Customer->(EditByFlds())
   //         ... etc ...
   //
   // see Convdata -  static function AddDateFlds( aStru )

   if FieldPos('QED_OP') > 0 .and. FieldPos('QED_DATE') > 0 .and. ;
	  FieldPos('QED_TIME') > 0

      if alltrim(SOValue(SO_INIT)) <> alltrim(Field->qadd_op) .or. date() <> Field->qadd_Date .or. ;
		   val( left(Field->qadd_time,2)) - val( left(time(),2)) >= 1

         // this protects against showing it as edited, if it has just been added....
			// BUT if added more than an hour ago (the time stuff) or edited by a different user
			// etc, then we make note of the edit.

         Field->Qed_date  := date()
         Field->Qed_time  := time()
         Field->Qed_op    := SOValue(SO_INIT)
      endif
   else
      appError( APP_ERR_INPUTBY_MISSING2,  { ;
               'The Table '+ Alias()+ ' does NOT have EDIT BY/ADD BY fields', ;
               'defined.  Not serious - but call Bill on this'})
   endif
return( nil )

function DeleteByFlds()
   // Sep 2011
   // should be called as follows:
   //     if Customer->(RecLock())
   //         Customer->(DeleteByFlds()
   //         Customer->(dbDelete())
   //         ... etc ...
   //
   // see Convdata -  static function AddDateFlds( aStru )

   if FieldPos('QDEL_OP') > 0 .and. FieldPos('QDEL_DATE') > 0
      Field->Qdel_date  := date()
      Field->Qdel_time  := time()
      Field->Qdel_op    := SOValue(SO_INIT)
   else
      appError( APP_ERR_INPUTBY_MISSING3,  { ;
               'The Table '+ Alias()+ ' does NOT have Delete BY fields', ;
               'defined.'})
   endif
return( nil )

