// PROGRAM...: ImpoList.prg
// June 2005 - Bill Hepler
//   lists Import Batches
//   Minor change June 2015
// 
// May 2020, revised to deal with new way of doing
//           Added actual name of Import File in March 202

#include "BerryPay.ch"
#include "bsgstd.ch"
#include "field.ch"
#include "indexord.ch"
#include "inkey.ch"
#include "price.ch"
#include "printer.ch"
#include "rpt.ch"
#include "sysvalue.ch"
#include "valid.ch"
#include "window.ch"

function AllImpBatList()
	local getList :={}, aWin
	local aRpt
	local cDepot := space( FLD_DEPOT )
	local lOrderByDate := .f., lLegend := .t.
	local aTitle
	local aRay
	local n
	local lFormFeed

	if !openfile({'ImpBat','Daily','Depot'},DB_SHARED)
		close databases
		return( nil )
	endif

	myBsgScreen( 'Import Batch List' )

	create window at 6,10,16,68 title 'Summary of All Import Batches' to aWin
	display window aWin

	in window aWin @ 6,2 winsay 'To list receipts for a single batch,'
	in window aWin @ 7,3 winsay 'See:   Transaction Detail Reports'
	in window aWin @ 8,3 winsay '          A. Receipts form an Import Batch'

	do while .t.
		in window aWin @ 3,2 winsay 'Order by date' winget lOrderByDate picture 'Y' ;
		  get_message 'Y=is order in which the imports were done, N=By Branch & Batch#'

		in window aWin @ 4,2 winsay 'Show Legend  ' winget lLegend picture 'Y' ;
		  get_message 'Shows an explanation of Column Data at the end of the report'

		read

		if lastkey()==K_ESC
			exit
		endif

		msgLine("Quick check for DUPLICATE & MISSING batches")
		ImpBat->(OrdSetFocus( IMPBAT_DEPOT_BATCH_ORD ))
		ImpBat->( dbGoTop())
		if ImpBat->(eof())
			WaitInfo({'No batches on file'})
			loop
		else
			// Check for Gaps & Duplicates - Jass gets up to all kinds of funny stuff.
			msgLine('Checking for duplicates etc!')
			//     depot          1st Batch     last batch  Duplicates  Gaps <weird stuff should NEVER happen>

			n := 0
			aRay := {}
			do while !ImpBat->(eof())
				if n == 0
					aadd( aRay, { ImpBat->depot, ImpBat->imp_bat, ImpBat->imp_bat,         0 ,       0 , 0  })
					n := len( aRay )
				else
					if aRay[ n, 1 ] == ImpBat->depot
						do case
						case aRay[ n, 3] == ImpBat->imp_bat
							aRay[ n, 4] ++                       // duplicate batch No
						case ImpBat->imp_bat > aRay[ n, 3]+1
							aRay[ n, 5] ++                       // gap
						endcase
						aRay[ n, 3 ] := ImpBat->imp_bat
					else
						aadd( aRay, { ImpBat->depot, ImpBat->imp_bat, ImpBat->imp_bat,         0 ,       0 , 0  })
						n := len( aRay )
					endif
				endif
				ImpBat->(dbSkip())
			enddo
		endif


		if SelectPrn('IMPBAT.TXT')
			aRpt := {}

			aadd( aRpt, { '' , { || ''  }, 'C', 001 , 000, ;
			  .f., .f., 'Dummy' })

			aadd( aRpt, {{'Scale','Batch#'} , { || ImpBat->IMP_BAT  }, 'N', 008 , 000, ;
			  .t., .f., 'Batch Number assigned by SCALE PROGRAM' })

			aadd( aRpt, {'Imported' , { || shMdy(ImpBat->QADD_DATE) }, 'C', 012 , 000, ;
			  .t., .f., 'Date imported by cisBerryPay' })

			aadd( aRpt, {'#Recpts'  , { || ImpBat->no_Trans }, 'N', 008 , 000, ;
			  .t., .f., 'Total number of Tickets INCLUDING VOIDS' })

			aadd( aRpt, {'#Voids' , { || ImpBat->VOIDS    }, 'N', 008 , 000, ;
			  .t., .f., 'Number of Voided tickets in Batch' })

			aadd( aRpt, { {'Lowest','Recpt #'}, { || ImpBat->LOW_RECPT}, 'N', 008 , 000, ;
			  .t., .f., 'Lowest Receipt# posted in this batch' })

			aadd( aRpt, { {'Highest','Recpt #'}, { || ImpBat->HI_RECPT}, 'N', 008 , 000, ;
			  .t., .f., 'Highest Receipt# posted in this batch' })

			aadd( aRpt, {'Earliest' , { ||shMdy( ImpBat->LOW_DATE ) }, 'C', 012 , 000, ;
			  .t., .f., 'Earliest date of Receipt in Batch' })

			aadd( aRpt, {'Latest', { || shMdy(ImpBat->HIGH_DATE) }, 'D', 012 , 000, ;
			  .t., .f., 'Most recent date of Receipt in Batch' })

			aadd( aRpt, {'Added By ' , { || ImpBat->QADD_OP  }, 'C', 010 , 000, ;
			  .t., .f., 'Posted by' })

			aadd( aRpt, {'CPU ID#' , { || ImpBat->UNIQ_IMBAT  }, 'N', FLD_DOCUMENT , 000, ;
			  .t., .f., 'Transaction Number for this batch, Assigned by Computer!' })

			aadd( aRpt, {'File Name' , { || ImpBat->imp_file  }, 'C', FLD_IMP_FILE_NAME , 000, ;
			  .t., .f., 'Actual File Name imported',  2 , .t., 10 })

			gRptInitHead()

			gRptGetSetHead( RPT_HEAD_SUBTOTAL , .t.)

			aTitle := {'Summary of Import Batches '}
			if !empty( cDepot )
				ImpBat->( dbSetFilter( { || ImpBat->depot == cDepot } , 'ImpBat->depot == cDepot' ))
				aTitle[ 1 ] += ' for Depot='+cDepot
			else
				aTitle[ 1 ] += ' for all Depots'
				ImpBat->( dbClearFilter())
			endif

			if lOrderByDate
				ImpBat->( OrdSetFocus( IMPBAT_UNIQUE_ID_ORD   ) )
				aadd( aTitle, 'Ordered by Date of Import' )

				gRptGetSetHead( RPT_HEAD_SUBTOTAL,  .f. )

				aRpt[1 ] := { 'D' , { || ImpBat->depot  }, 'C', FLD_DEPOT , 000, ;
			                 .t., .f., 'Depot' }

			else
				ImpBat->( OrdSetFocus( IMPBAT_DEPOT_BATCH_ORD ) )
				aadd( aTitle, 'Ordered by Depot and Batch# assigned by Scale' )

				gRptGetSetHead( RPT_HEAD_SUBTOTAL_ON, {|| ImpBat->depot } )
				gRptGetSetHead( RPT_HEAD_SUBTOTAL_TITLE, ;
					{ || nuQprnOut( 'Depot: '+ Impbat->depot ) } )

			endif
			gRptGetSetHead( RPT_HEAD_TITLE, aTitle )

			PRINT_ON  RPT_OVERWRITE
			gRptPrintSize( aRpt )

			ImpBat->(dbGoTop())
			ImpBat->(gRptPrinter( aRpt ))

			if NearPageBottom( 7 )
				nuQprnOut('')
				nuQprnOut('Continued...')
				nuFormFeed()
			endif

			for n := 1 to len( aRay )
				lFormFeed := NearPageBottom( 7 )
				if n == 1 .or. lFormFeed

					if lFormFeed
						nuFormFeed()
					endif

					nuQPrnOut('Summary of Batch Continuity as of ' + ;
									 shMDY( date() ) + ' '+time() )
					nuQPrnOut('')

					nuQPrnOut('')
					//          123456789_12345
					nuQQPrnOut('   ')
					nuQQPrnOut('Depot')
					nuQQPrnOut('      1st Batch')
					nuQQPrnOut('     Last Batch')
					nuQQPrnOut('     Duplicates')
					nuQQPrnOut('      Gaps')
					nuQprnOut()
				endif

				nuQPrnOut('   ')
				nuQQprnOut( padr(aRay[ n, 1 ],  5) )
				nuQQprnOut( str( aRay[ n, 2 ], 15 ) )
				nuQQprnOut( str( aRay[ n, 3 ], 15 ) )

				nuQQprnOut( str( aRay[ n, 4 ], 15 ) )
				nuQQprnOut( str( aRay[ n, 5 ], 10 ) )
			next
			nuQprnOut('End of Summary')
			nuQprnOut()
			nuQprnOut()


			if lLegend
				prnRptLegend( aRpt, aTitle, .t. ) // only show columns selected
			endif

			PRINT_OFF  RPT_COMPLETE_EJECT
		endif
	enddo
	kill window aWin
	close databases

return( nil )





