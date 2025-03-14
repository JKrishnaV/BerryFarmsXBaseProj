// -------------------------------------------------------------------------
//   Application: Berry Payment System
//   Description: Lists Product, Grades, etc
//     File Name: OLIST.PRG
//     Author: Bill Hepler
//      July 2014 - tidy up
//      June 2015 - Varieties ADDED
//      May 2020  - updated for changes to Import Batch - removed that
//
// Date created: 07/20/09
// Time created: 01:11:21pm
// Copyright: (c) 2009, 2014, 2015, 2019, 2020 by Bill Hepler & Crafted Industrial Software Ltd.
// --------------------------------------------------------------------------

#include "BerryPay.ch"
#include "bsgstd.ch"
#include "field.ch"
#include "indexord.ch"
#include "inkey.ch"
#include "price.ch"
#include "printer.ch"
#include "radio.ch"
#include "rpt.ch"
#include "sysvalue.ch"
#include "valid.ch"
#include "window.ch"

function ProductList()
	local aWin
	local aRpt

	if !openfile({'Product','Process','Contain'},DB_SHARED)
		close databases
		return( nil )
	endif

	myBsgScreen( 'Grower List' )

	create window at 7,10,13,65 title 'Product List' to aWin
	display window aWin

	do while .t.
		in window aWin @ 2,2 winsay 'Prints the List of Products'
		thinWait('Next you may select the Printer to use...')

		if SelectPrn('PRODUCT.TXT')
			aRpt := {}

			aadd( aRpt,{ 'ID', {|| Product->product}, 'C', 4, 0, .t., .f., ;
					'Product' })
			aadd( aRpt,{ 'Desc', {|| Product->desc}, 'C', FLD_PRODDESC+1, 0, .t., .f., ;
					'Product Full Description' })
			aadd( aRpt,{ 'Sh.Desc', {|| Product->shortdesc}, 'C', FLD_SHORTDESC+1, 0, .t., .f., ;
					'Short Description' })
			aadd( aRpt,{ 'Deduct', {|| Product->deduct}, 'N', 10, 6, .t., .f., ;
					'Deduction (if any)' })
			aadd( aRpt,{ 'Cat', {|| Product->category}, 'C', FLD_PRODUCT_CATEGORY+2, 0, .t., .f., ;
					'Category Code' })
			aadd( aRpt,{ 'Cat Desc', ;
				{|| NameOf(LU_PRODUCT_CATEGORY,Product->category)}, ;
				 'C', 20, 0, .t., .f. , ;
					'Category Code' })

			aadd( aRpt,{ {'Default','Variety'}, {|| Product->variety}, 'C', FLD_VARIETY, 0, .t., .f., ;
					'DEFAULT Variety' })
			aadd( aRpt,{ 'Variety Desc', ;
				{|| NameOf(LU_VARIETY,Product->variety)}, ;
				 'C', 20, 0, .t., .f. , ;
					'Variety Description' })

			gRptInitHead()
			gRptGetSetHead( RPT_HEAD_TITLE, {'Product List'})

			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

			Product->(dbGotop())
			Product->(gRptPrinter( aRpt ))

			PRINT_OFF  RPT_COMPLETE_EJECT
		endif
		exit

	enddo
	kill window aWin
	close databases

return( nil )

function ProcessList()
	local aWin
	local aRpt

	if !openfile({'Product','Process','Contain'},DB_SHARED)
		close databases
		return( nil )
	endif

	myBsgScreen( 'Grower List' )

	create window at 7,10,13,65 title 'Process List' to aWin
	display window aWin

	do while .t.
		in window aWin @ 2,2 winsay 'Prints the List of Processes'
		thinWait('Next you may select the Printer to use...')

		if SelectPrn('PROCESS.TXT')
			aRpt := {}

			aadd( aRpt,{ 'ID', {|| Process->process}, 'C', 4, 0, .t., .f., ;
					'Process' })
			aadd( aRpt,{ 'Desc', {|| Process->desc}, 'C', FLD_PROCDESC, 0, .t., .f., ;
					'Product Full Description' })
			aadd( aRpt,{ 'Defa Grade', ;
			 {|| iif( Process->def_grade>=1 , ;
						str(Process->def_grade,10), space( 10 ) )}, ;
			  'C', 10, 0, .t., .f., 'Default Grade ...' })

			aadd( aRpt,{ 'Class', {|| Process->proc_class}, 'N', 5, 0, .t., .f., ;
					'Process Class (e.g. Fresh, etc' })
			aadd( aRpt,{ 'Cl Desc', ;
				{|| NameOf(LU_PROCESS_CLASS, Process->proc_class)}, ;
				 'C', 20, 0, .t., .f. , ;
					'Class Description' })

			gRptInitHead()
			gRptGetSetHead( RPT_HEAD_TITLE, {'Process List'})

			PRINT_ON  RPT_OVERWRITE

			gRptPrintSize( aRpt )
			Process->(dbGotop())
			Process->(gRptPrinter( aRpt ))

			PRINT_OFF  RPT_COMPLETE_EJECT
		endif
		exit

	enddo
	kill window aWin
	close databases

return( nil )

function ContainerList()
	local aWin
	local aRpt

	if !openfile({'Product','Process','Contain'},DB_SHARED)
		close databases
		return( nil )
	endif

	myBsgScreen( 'Grower List' )

	create window at 7,10,13,65 title 'Container/Pallet List' to aWin
	display window aWin

	do while .t.
		in window aWin @ 2,2 winsay 'Prints the List of Containers & Pallets'
		thinWait('Next you may select the Printer to use...')

		if SelectPrn('CONTPALL.TXT')
			aRpt := {}

			aadd( aRpt,{ 'ID', {|| contain->container}, 'C', FLD_CONTAINER, 0, .t., .f., ;
					'Container ID' })
			aadd( aRpt,{ 'Desc', {|| contain->desc}, 'C', FLD_CONTAINER_DESC, 0, .t., .f., ;
					'Container Description' })
			aadd( aRpt,{ 'Sh.Desc', {|| contain->short}, 'C', FLD_CONTAINER_SHORT+1, 0, .t., .f., ;
					'Short Description' })
			aadd( aRpt,{ 'Tare', {|| contain->tare}, 'N', 10, 6, .t., .f., ;
					'Tare (for Info Only)' })
			aadd( aRpt,{ 'Value', {|| contain->value}, 'N', 10, 2, .t., .f., ;
					'Container Value' })
			aadd( aRpt,{ 'In Use', ;
				{|| iif( contain->inUse, 'USED ',' n/a ')}, ;
				 'C', 6, 0, .t., .f. , ;
					'In Use - Active' })

			gRptInitHead()
			gRptGetSetHead( RPT_HEAD_TITLE, {'Container/Pallet List'})

			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

			contain->(dbGotop())
			contain->(gRptPrinter( aRpt ))
			nuQprnOut( )
			nuQprnOut( 'Tares are for information only!' )
			nuQprnOut( )

			PRINT_OFF  RPT_COMPLETE_EJECT
		endif
		exit

	enddo
	kill window aWin
	close databases

return( nil )




