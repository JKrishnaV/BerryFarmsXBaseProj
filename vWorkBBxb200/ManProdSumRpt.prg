// ---------------------------------------------------------------------------
//   Application: Berry Pay System
//   Description: For Jack at his request
//                Shows production for a period vs year to date
//
//   Jun 2018 - housekeeping
//
//     File Name: ManProdSumRpt.prg
//        Author: Bill Hepler
//     Copyright: (c) 2015,2018 by Bill Hepler
// ---------------------------------------------------------------------------

#include "window.ch"
#include "printer.ch"
#include "BerryPay.ch"
#include "bsgstd.ch"
#include "inkey.ch"
#include "indexord.ch"
#include "field.ch"
#include "SumRptBld.ch"
#include "valid.ch"
#include "rpt.ch"
#include 'sysvalue.ch'
#include 'errors.ch'
#include 'berry_rpt.ch'

function MangmtProSumRpt()
	local dDate1, dDate2
	local getList := {}
	local aWin
	local cProduct
	local cProcess
	local cSum
	local aTitle
	local aRpt
	local nGrower := 0
	local cDepot
	local n

	if !openMainStuff(DB_SHARED)
		close databases
		return( nil )
	endif

	myBsgScreen( 'Management Summary of Production Report' )

	create window at 5,07,14,71 title 'Management Summary of Production' to aWin
	display window aWin

	dDate1 := FirstOfYear( date() )
	dDate2 := date()

	cProcess := space(FLD_PROCESS)
	cProduct := space(FLD_PRODUCT)
	cDepot   := space(FLD_DEPOT)

	do while .t.
		in window aWin @ 2,2 winsay 'From' winget dDate1 picture '@D' ;
			get_message 'Enter of starting date of first column'
		in window aWin @ 3,2 winsay ' to ' winget dDate2 picture '@D' ;
			get_message 'Enter of ending date of first column'

		in window aWin @ 4,2 winsay 'Product' winget cProduct picture '@!' ;
			when PutName( aWin,  4, 21, LU_PRODUCT, cProduct ) ;
			valid PutName( aWin, 4, 21, LU_PRODUCT, cProduct ) ;
			lookup( LU_PRODUCT, ;
		'Enter a Product to restrict the report to a single product, blank for all')

		in window aWin @ 5,2 winsay 'Process' winget cProcess picture '@!' ;
			when PutName(  aWin, 5, 21, LU_PROCESS_TYPE, cProcess ) ;
			valid PutName( aWin, 5, 21, LU_PROCESS_TYPE, cProcess ) ;
			lookup( LU_PROCESS_TYPE, ;
		'Enter a Process to restrict the report to a single process, blank for all')

		in window aWin @ 6,2 winsay 'Grower ' winget nGrower ;
			picture NumBlankPic(FLD_GROWER) ;
			when PutName( aWin, 6, 21, LU_GROWER, nGrower ) ;
			valid PutName( aWin,6, 21, LU_GROWER, nGrower ) ;
			lookup( LU_GROWER, ;
		'Enter a Single Grower to restrict to show only a single grower')

      in window aWin @7,02 winsay 'Depot  ' winget cDepot picture '@!' ;
         when PutName( aWin, 7, 21, LU_DEPOT, cDepot ) ;
         valid PutName( aWin, 7,21, LU_DEPOT, cDepot ) ;
         LookUp( LU_DEPOT, 'Blank for All Depots - F5 to Browse' )


		in window aWin @  9,2 winsay ;
			 'This report shows production for the above period'
		in window aWin @ 10,2 winsay ;
			 'and the year-to-date (both posted & unposted transactions)'

		read

		do case
		case lastkey()==K_ESC
			exit
		case year(dDate1)<>year(dDate2)
			waitInfo({'Year must be the same for both dates'})
			loop
		case dDate1 > dDate2
			waitInfo({'The First Date has to be Smaller!'})
			loop

		case SelectPrn('MANAGE.TXT')
			cSum := GatherData(dDate1,dDate2,cProduct, cProcess, nGrower, cDepot )

			gRptInitHead()
         aTitle := { TheClientName( ), ;
           'Management Production Summary Report, on '+shMDY(Date()), ;
					'From '+shMDY(dDate1)+' to '+shMDY(dDate2) }

			if !empty(cProduct)
				aadd(aTitle,'Product = '+cProduct)
			endif
			if !empty(cProcess)
				aadd(aTitle,'Process = '+cProcess)
			endif
			if nGrower > 0
				aadd(aTitle, alltrim(lStrim(nGrower)+' '+NameOf(LU_GROWER,nGrower)))
			endif
			if !empty( cDepot )
				n := len( aTitle)
				if len( aTitle[n]) < 40
					aTitle[n] += ' Depot='+cDepot
				else
					aadd( aTitle,'Depot='+cDepot)
				endif
			endif

			gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

			aRpt := {}
			SetJackCol( aRpt )

			gRptGetSetHead( RPT_HEAD_SUBTOTAL, .t. )
			gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| (cSum)->product} )
			gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
				 {|| nuQprnOut( (cSum)->product+' '+NameOf(LU_PRODUCT,(cSum)->product) )} )

		  	PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

			(cSum)->(dbGoTop())
			(cSum)->(gRptPrinter( aRpt ))

         nuQprnOut()
         nuQprnOut( 'Totals include UNPOSTED transactions.' )
         nuQprnOut( 'Year to Date Totals include receipts up to '+shMDY(dDate2) )
         nuQprnOut( )

			PRINT_OFF RPT_COMPLETE_EJECT

			(cSum)->(dbCloseArea())
			killUnique(cSum)

		endcase
	enddo
	kill window aWin
	close databases
return( nil )


static function GatherData(dDate1,dDate2, cProduct, cProcess, nGrower, cDepot )
	local cSum1
	local aStru
	local cFile
	local n := 0

	msgLine('Getting Set up...')

	aStru := {  { 'PRODUCT',  'C', FLD_PRODUCT, 0 }, ;
					{ 'PROCESS',  'C', FLD_PROCESS, 0 }, ;
					{ 'GRADE1_PD','N', 12,          0 }, ;
					{ 'GRADE2_PD','N', 12,          0 }, ;
					{ 'GRADE3_PD','N', 12,          0 }, ;
					{ 'GRADE1_YR','N', 12,          0 }, ;
					{ 'GRADE2_YR','N', 12,          0 }, ;
					{ 'GRADE3_YR','N', 12,          0 }    }


	cFile := UniqueFile()
	cSum1 := UniqueDBF( aStru )

	msgLine('Working away on Daily...')
   Daily->(OrdSetFocus(DAILY_DATE_ORD))

	// want the YTD !
	Daily->(dbSeek( substr(dtos(dDate1),1,4), SOFTSEEK ))
	dbSelectAr('Daily' )

	// To be Fixed - June 2010 - 2BFIXED - is FIXED
	// index on Daily->product + Daily->process   ;
	//	to (cFile) while Daily->date<= dDate2 ;
	//	for IncludeMe(cProduct,cProcess,nGrower)

	InitGeneralFor( { || .t. }, { || .t.}, { || .t. }, ;
		   { || IncludeMe(cProduct,cProcess,nGrower,cDepot) } )

   Daily->( OrdCondSet( 'GeneralFor()', ;
			        { || GeneralFor() }, ;
                    .f., ;
                  { || Daily->date<= dDate2  } ) )
   Daily->( OrdCreate( cFile, 'USETHIS',   ;
             'Daily->product + Daily->process', ;
         { || Daily->product + Daily->process } ) )

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
	SetSumReps( SUMREP_IS_SAME_RECORD, {||SameNess( cSum1 )} )
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
        (cSum)->product == Field->product

return( lReturn )


static Function NewRec( cSum )

	// the Make actually appends the record...
	(cSum)->product := Field->product
	(cSum)->process := Field->process

return( nil )

static function AccumulateIt( cSum, dDate1, dDate2 )

	do case
	case Field->grade==1
		(cSum)->grade1_yr += Field->net
	case Field->grade==2
		(cSum)->grade2_yr += Field->net
	case Field->grade==3
		(cSum)->grade3_yr += Field->net
	endcase

	if Field->date >= dDate1 .and. Field->date <= dDate2
		do case
		case Field->grade==1
			(cSum)->grade1_pd += Field->net
		case Field->grade==2
			(cSum)->grade2_pd += Field->net
		case Field->grade==3
			(cSum)->grade3_pd += Field->net
		endcase
	endif

return( nil )

static function SetJackCol( aRpt )

	aadd( aRpt, ;
		{ '', ;
		 { || '' }     ,  'C' ,   2  ,   000 , ;
			.t., .f. , ;
			'Pretty' } )

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
		{ {'P.T.D.','Grade 1'} , ;
		 { || Field->grade1_PD }     ,  'N' ,    8  ,   000 , ;
			.t., .t. , ;
			'Grade 1 for Period to Date (PTD)' } )

	aadd( aRpt, ;
		{ {'P.T.D.','Grade 2'} , ;
		 { || Field->grade2_PD }     ,  'N' ,    8  ,   000 , ;
			.t., .t. , ;
			'Grade 2 for Period to Date (PTD)' } )

	aadd( aRpt, ;
		{ {'P.T.D.','Grade 3'} , ;
		 { || Field->grade3_PD }     ,  'N' ,    8  ,   000 , ;
			.t., .t. , ;
			'Grade 3 for Period to Date (PTD)' } )

	aadd( aRpt, ;
		{ {'P.T.D.','Total'} , ;
		 { || Field->grade1_PD + Field->grade2_PD + Field->grade3_PD }  , ;
		   'N' ,    8  ,   000 , ;
			.t., .t. , ;
			'Total of All Grades for Period to Date (PTD)' } )

	aadd( aRpt, ;
		{ '', ;
		 { || '' }     ,  'C' ,   1  ,   000 , ;
			.t., .f. , ;
			'Pretty' } )

	aadd( aRpt, ;
		{ {'Y.T.D.','Grade 1'} , ;
		 { || Field->grade1_YR }     ,  'N' ,    8  ,   000 , ;
			.t., .t. , ;
			'Grade 1 for Year to Date (YTD)' } )

	aadd( aRpt, ;
		{ {'Y.T.D.','Grade 2'} , ;
		 { || Field->grade2_YR }     ,  'N' ,    8  ,   000 , ;
			.t., .t. , ;
			'Grade 2 for Year to Date (YTD)' } )

	aadd( aRpt, ;
		{ {'Y.T.D.','Grade 3'} , ;
		 { || Field->grade3_YR }     ,  'N' ,    8  ,   000 , ;
			.t., .t. , ;
			'Grade 3 for Year to Date (YTD)' } )

	aadd( aRpt, ;
		{ {'Y.T.D.','Total'} , ;
		 { || Field->grade1_YR + Field->grade2_YR + Field->grade3_YR }  , ;
		   'N' ,    8  ,   000 , ;
			.t., .t. , ;
			'Total of All Grades for Year to Date (YTD)' } )


return( nil )

