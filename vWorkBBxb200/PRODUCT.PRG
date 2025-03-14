// ---------------------------------------------------------------------------
// Application: Berry Payment System                                      
// Description: For Setting Up Products (i.e. berries)                    
//   July 2014 - Add Date etc and GST
//   June 2015 - Add Variety
//                                                                         
//    File Name: PRODUCT.PRG                                               
//       Author: Bill Hepler                                               
// Date created: 12-11-94        
// Time created: 10:55:00am      
// Copyright: (c) 1994, 2014, 2015 by Bill Hepler & Crafted Industrial Software Ltd.
// ---------------------------------------------------------------------------------

#include "window.ch"
#include "indexord.ch"
#include "valid.ch"
#include "field.ch"
#include "bsgstd.ch"
#include "common.ch"
#include "inkey.ch"
#include "BerryPay.ch"
#include "sysvalue.ch"

function Product(  )
	local cProduct, getList :={}, aW

	if !openfile({'PRODUCT','VARIETY','DAILY'}, DB_SHARED )
		close databases
		return( nil )
	endif

	create window at 6,16,11,64 title 'Products' to aW
	display window aW
	set cursor on

	in window aW @ 4,2 winsay 'Use this screen to set the Products that'
	in window aW @ 5,2 winsay 'you buy from growers.'
	in window aW @ 6,2 winsay 'This must correlate with the scale system.'

	cProduct := space(FLD_PRODUCT)
	do while .t.
		in window aW @ 2,2 winsay 'Product ID ' winget cProduct ;
			 picture "@!" ;
			lookup( LU_PRODUCT, 'Enter Product ID - [F5] to Browse')
		read

		do case
		case lastkey()==K_ESC
			exit
		case ValidTest(V_PRODUCT,cProduct,VT_NO_MESSAGE)
			getScreen(.f.)
		case empty(cProduct)
			waitInfo({'Product ID can not be blank'})
		otherwise
			// Aug 18-98
			if yesno({'Add Product Type '+cProduct+' ?'})
				if Product->(addRecord())
					Product->product  := cProduct
					Product->(dbCommit())
					Product->chg_gst  := .t.  // For Marketing Deduction!
					
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
	local lDelete

	if !Product->(recLock())
		return( nil )
	endif

   create window at 4,9,20,72 ;
			title 'Edit Product' to aWin

	display window aWin
	set cursor on

	do while .t.
		GetStuffed( lRead, aWin )
		lRead := .f.

		nChoice := thinChoice( {'View','Edit','Delete','Help-Var','X - eXit'})

		do case
		case nChoice==0 .or. nChoice==5
			exit
		case nChoice==1
			thinWait()
			loop
		case nChoice==2
			lRead := .t.
		case nChoice==3			
			if YesNo({'Are you Sure you want to Delete This?', ;
			          '','We are going to check if you are allowed to!'})
				lDelete := .t.
				if !empty(Daily->product)
					msgLine('We are checking to see if there are any receipts with this...')
					Daily->(ordSetFocus( 0 ))
					Daily->(dbGoTop())
					do while !Daily->(eof())
						if Daily->product == Product->product
							WaitHand({'Hey NO deleting here, we have some Receipts on file', ;
							          'with this product!' })
							lDelete := .f.
							exit
						endif
						Daily->(dbSkip())
					enddo
				endif
				if lDelete
					Product->(DeleteRecord())
					WaitInfo({'Product Deleted!'})
				else
					WaitInfo({'We did not delete...'})
				endif
				exit
			endif
		case nChoice==4
			ReceiptVarietyHelp( sysValue(SYS_DEFAULT_VARIETY) )
		endcase
	enddo
	kill window aWin
	Product->(dbUnlock())
return( nil )

static function getStuffed( lRead, aWin )
	local getList := {}

	do while .t.
		in window aWin @ 2,2 winsay 'Product ID ' winget Product->product ;
			 picture "@!"			 
		getList := {}

      in window aWin @ 14, 27 winsay NameOf( LU_VARIETY, ;
                  Product->variety )

      in window aWin @ 12, 27 winsay NameOf( LU_PRODUCT_CATEGORY, ;
                Product->category )

		in window aWin @ 3,2 winsay "Description" winget Product->Desc  ;
		  get_message 'Enter a Description of this Product'
		in window aWin @ 4,2 winsay "Short Desc." winget Product->ShortDesc  ;
		  get_message ;
		  'The Abbreviated Description of this Product used on Cheques & Reports'
		in window aWin @ 5,2 winsay "Deduction  " winget Product->deduct  ;
        picture '99.999999' ;
        valid Product->deduct <= 0.000000 ;
        get_message ;
         'Regular (weekly) per pound deduction for marketing - Make NEGATIVE!'

		in window aWin @ 6,2 winsay 'Deduction (if any) is taken from first advance if possible.'
      in window aWin @ 7,2 winsay '(Computer guy note, see MrkDeduction()).  You should not'
		in window aWin @ 8,2 winsay 'include the GST amount in the Marketing Deduction!'
			
      in window aWin @ 10,2 winsay 'Charge GST on Marketing Deduction' winget Product->chg_gst ;
       picture 'Y' get_message 'Charge GST on Marketing Deduction?  Do NOT include GST in Marketing Deduction!'

      in window aWin @ 12,2 winsay 'Report Category' winget Product->category ;
       picture '@Z 9' ;
       valid ValidTest( V_PRODUCT_CATEGORY, Product->category, VT_BROWSE )  ;
       lookup( LU_PRODUCT_CATEGORY, ;
        '[F5] to Browse - Classify Product for Reporting Purposes-See System Values')

      in window aWin @ 14,2 winsay 'Default Variety' winget Product->variety ;
       picture '@!' ;
       valid iif(empty( Product->variety),.t., ValidTest( V_VARIETY, Product->variety, VT_BROWSE ))  ;
       lookup( LU_VARIETY, ;
        '[F5]=Browse - Set a Default Variety for this Product (for reporting)')
		  
		if lRead
			read

         in window aWin @ 12, 27 winsay NameOf( LU_PRODUCT_CATEGORY, ;
                   Product->category )
         in window aWin @ 14, 27 winsay NameOf( LU_VARIETY, ;
                   Product->variety )

			if Product->deduct > 0
				if Product->deduct >= .99
					Product->deduct := 0.00
				endif
				Product->deduct := -1*Product->deduct
				WaitHand({'Deduction set to NEGATIVE!'})
			endif

			Product->(dbCommit())
		else
			getList :={}
		endif
		exit
	enddo

return( nil )


























