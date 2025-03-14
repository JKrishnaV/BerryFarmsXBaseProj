// --------------------------------------------------------------------
//  Application: Berry Payment System
//  Description: For Setting Up Varieties
//               This allows for Long Process & Products and is
//               used for reporting.
//
//    File Name: VARIETY.PRG
//       Author: Bill Hepler
// Date created: June-02-2015
//     Last Rev: June-11-2015 added Report
// Copyright: (c) 2015 by Bill Hepler & Crafted Industrial Software Ltd.
// --------------------------------------------------------------


#include "window.ch"
#include "indexord.ch"
#include "valid.ch"
#include "field.ch"
#include "bsgstd.ch"
#include "common.ch"
#include "inkey.ch"
#include "BerryPay.ch"

#include 'rpt.ch'
#include 'berry_rpt.ch'
#include 'printer.ch'
#include 'sysvalue.ch'
#include "SumRptBld.ch"
#include 'errors.ch'

function Varieties(  )
	local cVariety, getList :={}, aW

	if !openfile({'PRODUCT','VARIETY'}, DB_SHARED )
		close databases
		return( nil )
	endif

	create window at 6,16,14,64 title 'Varieties' to aW
	display window aW
	set cursor on

	in window aW @ 4,2 winsay 'Use this screen to set the Varieties'
	in window aW @ 5,2 winsay 'used.  These can be defaulted from Products.'
	in window aW @ 6,2 winsay 'It allows for Long Products & Process.'
	in window aW @ 7,2 winsay 'F1 for more help on Varieties.'

	cVariety := space(FLD_VARIETY)
	do while .t.
		//                        'Description'
		in window aW @ 2,2 winsay 'Variety ID ' winget cVariety ;
			 picture "@!" ;
			lookup( LU_VARIETY, 'Enter Variety ID - [F5] to Browse')
		read

		do case
		case lastkey()==K_ESC
			exit
		case ValidTest(V_VARIETY,cVariety,VT_NO_MESSAGE)
			getScreen(.f.)
		case empty(cVariety)
			waitInfo({'Variety ID can not be blank'})
		otherwise
			if yesno({'Add Variety Type '+cVariety+' ?'})
				if Variety->(addRecord())
					Variety->variety := cVariety
					Variety->(dbCommit())
					getScreen( .t. )
				endif
			endif
		endcase
	enddo

	kill window aW
	close databases

return( nil )

static function getScreen( lRead )
	local nChoice
	local aWin

	if !Variety->(recLock())
		return( nil )
	endif

	create window at 5,14,13,67 ;
			title 'Edit Variety Type' to aWin

	display window aWin
	set cursor on

	do while .t.
		GetStuffed( lRead, aWin )
		lRead := .f.

		nChoice := thinChoice( {'View','Edit','Delete','X - eXit'})

		do case
		case nChoice==0 .or. nChoice==4
			exit
		case nChoice==1
			thinWait()
			loop
		case nChoice==2
			lRead := .t.
		case nChoice==3
			if YesNo({'Are you Sure you want to Delete This?'})
				Variety->(DeleteRecord())
				exit
			endif
		endcase
	enddo
	kill window aWin
	Variety->(dbUnlock())
return( nil )

static function getStuffed( lRead, aWin )
	local getList := {}

	do while .t.
      in window aWin @ 2,2 winsay 'Variety ID ' winget Variety->variety ;
			 picture "@!"
		getList := {}

		in window aWin @ 3,2 winsay "Description" winget Variety->Desc  ;
			get_message 'Enter a Description of this Variety...'

      in window aWin @ 6,2 winsay 'The Variety can come from the Scale'
      in window aWin @ 7,2 winsay 'or be defaulted.'

		if lRead
			read

         Variety->(dbCommit())
		else
			getList :={}
		endif
		exit
	enddo

return( nil )


function VarietyReport( )
	local getList :={}, aWin
	local dFrom, dTo
	local cSum, cTitle
	local aRpt, aTitle

	if !openMainStuff( DB_SHARED )
		close databases
		return( nil )
	endif

   cTitle := 'Variety Report'

	dFrom   := stod( str( sysValue(SYS_CURRENT_YEAR),4)+'0101')
	dTo     := date()

   myBsgScreen( cTitle )
   
   create window at 5,5,19,67 title cTitle to aWin
	display window aWin


	do while .t.
	  	in window aWin @ 2,2  winsay 'From' winget dFrom picture '@d' ;
   	 GET_MESSAGE ;
   	 'Enter the Beginning Transaction Cut Off Date (REMEMBER +/- keys)'

   	in window aWin @ 3,2  winsay ' to ' winget dTo picture '@d' ;
   	 GET_MESSAGE ;
   	 'Enter the Ending Transaction Cut Off Date   (Remember the +/- keys)'

		READ

		do case
		case lastkey()==K_ESC
   		exit
   	endcase

      if SelectPrn('VAR_RECD.TXT')
         aTitle := {TheClientName( ), cTitle, shMdy( dFrom)+' to '+shMdy( dTo ) }
			Daily->( dbSetFilter( { || !empty( 	Daily->NET ) }, ;
                                   '!empty( 	Daily->NET )'   ))

			Daily->(OrdSetFocus( DAILY_DATE_ORD ))
			Daily->(dbSeek( dtos( dFrom ), SOFTSEEK))
			if Daily->(eof()) .or. Daily->date > dTo
				waitInfo({'Nothing on these dates...'})
				Daily->(dbClearFilter())
				loop
			endif

			InitSumRep()
			cSum := GatherData(dFrom,dTo )
			Daily->(dbClearFilter())

			gRptInitHead()
         aTitle := { TheClientName( ), ;
           'Variety Summary Report, on '+shMDY(Date()), ;
					'From '+shMDY(dFrom)+' to '+shMDY(dFrom) }

			gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

			aRpt := {}
			SetSummaryCol( aRpt )

			gRptGetSetHead( RPT_HEAD_SUBTOTAL, .t. )
			gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| (cSum)->Variety} )
			gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
				 {|| nuQprnOut( iif( empty( (cSum)->variety),  ;
				     'Variety NOT known', ;
					  (cSum)->Variety+' '+NameOf(LU_VARIETY,(cSum)->variety) ) )} )

		  	PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

			(cSum)->(dbGoTop())
			(cSum)->(gRptPrinter( aRpt ))

         nuQprnOut()
         nuQprnOut( 'Totals include UNPOSTED transactions.' )
         nuQprnOut( )

			PRINT_OFF RPT_COMPLETE_EJECT
			(cSum)->(dbCloseArea())
			killUnique(cSum)
		endif
	enddo
	kill window aWin
	close databases

return( nil )



static function GatherData(dDate1,dDate2 )
	local cSum1
	local aStru
	local cFile
	local n := 0

	msgLine('Getting Set up...')

	aStru := {  { 'VARIETY',  'C', FLD_VARIETY, 0 }, ;
					{ 'PRODUCT',  'C', FLD_PRODUCT, 0 }, ;
					{ 'PROCESS',  'C', FLD_PROCESS, 0 }, ;
					{ 'GRADE1','N', 12,          0 }, ;
					{ 'GRADE2','N', 12,          0 }, ;
					{ 'GRADE3','N', 12,          0 }    }


	cFile := UniqueFile()
	cSum1 := UniqueDBF( aStru )

	msgLine('Working away on Daily...')
   Daily->(OrdSetFocus(DAILY_DATE_ORD))

	Daily->(dbSeek( dtos(dDate1), SOFTSEEK ) )
	dbSelectAr('Daily' )

	InitGeneralFor( { || .t. }, { || .t.}, { || .t. }, ;
		   { || .t. } )

   Daily->( OrdCondSet( 'GeneralFor()', ;
			        { || GeneralFor() }, ;
                    .f., ;
                  { || Daily->date<= dDate2  } ) )
   Daily->( OrdCreate( cFile, 'USETHIS',   ;
             'Daily->variety + Daily->product + Daily->process', ;
         { || Daily->variety + Daily->product + Daily->process } ) )

   if empty( Daily->(OrdBagName('USETHIS')) )
   	AppError(APP_ERR_TEMP_INDEXING1, {'Hmm-we have a problem!'})
   endif

   Daily->( OrdSetFocus('USETHIS') )

	Daily->(dbGoTop())

	InitSumRep()

	SetSumReps( SUMREP_FILE_TO_SEARCH, 'Daily')
	SetSumReps( SUMREP_SUM_FILE, cSum1 )

	SetSumReps( SUMREP_SEARCH_WHILE,   {|| !Daily->(eof()) } )
	SetSumReps( SUMREP_ADD_NEW_RECORD, {|| NewRec( cSum1 )} )
	SetSumReps( SUMREP_IS_SAME_RECORD, {|| SameNess( cSum1 )} )
	SetSumReps( SUMREP_ADD_TO_RECORD,  {|| AccumulateIt( cSum1, dDate1, dDate2 )} )
	SetSumReps( SUMREP_SHOW_PROG,      {|| str(n++,10)})

	MakeSumFile()

	Daily->(dbCloseArea())
	openFile({'Daily'}, DB_SHARED)

	msgLine('Combining files...')

return( cSum1 )


static function SameNess( cSum )
	local lReturn

	lReturn :=  (cSum)->process == Field->process .and.  ;
        (cSum)->product == Field->product .and. ;
		  (cSum)->variety == Field->variety ;

return( lReturn )


static Function NewRec( cSum )

	// the Make actually appends the record...
	(cSum)->variety := Field->variety
	(cSum)->product := Field->product
	(cSum)->process := Field->process

return( nil )

static function AccumulateIt( cSum )   // , dDate1, dDate2 )

	do case
	case Field->grade==1
		(cSum)->grade1 += Field->net
	case Field->grade==2
		(cSum)->grade2 += Field->net
	case Field->grade==3
		(cSum)->grade3 += Field->net
	endcase

return( nil )

static function SetSummaryCol( aRpt )

	aadd( aRpt, ;
		{ '', ;
		 { || '' }     ,  'C' ,   2  ,   000 , ;
			.t., .f. , ;
			'Pretty' } )

	aadd( aRpt, ;
		{ 'Prod', ;
		 { || Field->product }     ,  'C' , FLD_PRODUCT ,   000 , ;
			.t., .f. , ;
			'Process used' } )

		aadd( aRpt, ;
		{ 'Prod Name', ;
		 { || NameOf(LU_PRODUCT,Field->product ) }   ,  ;
		  'C' , FLD_PROCDESC ,   000 , ;
			.t., .f. , ;
			'Product Description' } )


	aadd( aRpt, ;
		{ 'Pr', ;
		 { || Field->process }     ,  'C' , FLD_PROCESS ,   000 , ;
			.t., .f. , ;
			'Process used' } )

	aadd( aRpt, ;
		{ 'Name', ;
		 { || NameOf(LU_PROCESS_TYPE,Field->process) }   ,  ;
		  'C' , FLD_PROCDESC ,   000 , ;
			.t., .f. , ;
			'Process Description' } )

	aadd( aRpt, ;
		{ {'Grade 1'} , ;
		 { || Field->grade1 }     ,  'N' ,    8  ,   000 , ;
			.t., .t. , ;
			'Grade 1 for Period' } )

	aadd( aRpt, ;
		{ {'Grade 2'} , ;
		 { || Field->grade2 }     ,  'N' ,    8  ,   000 , ;
			.t., .t. , ;
			'Grade 2 for Period' } )

	aadd( aRpt, ;
		{ {'P.T.D.','Grade 3'} , ;
		 { || Field->grade3 }     ,  'N' ,    8  ,   000 , ;
			.t., .t. , ;
			'Grade 3 for Period' } )

	aadd( aRpt, ;
		{ {  'Total'} , ;
		 { || Field->grade1 + Field->grade2 + Field->grade3 }  , ;
		   'N' ,    8  ,   000 , ;
			.t., .t. , ;
			'Total of All Grades for Period' } )

	aadd( aRpt, ;
		{ '', ;
		 { || '' }     ,  'C' ,   1  ,   000 , ;
			.t., .f. , ;
			'Pretty' } )



return( nil )





















