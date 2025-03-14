//---------------------------------------------------------------------------
//    File Name: DataStru.prg
//  Description: Has stuff for the Structure of various RECEIPTS files
//  Aug 2008     Added Original Net field....
//  Aug 2019     Use Define for Container Field
//  Mar 2020     Widened some fields and added  FROM_FIELD for WestBerry
//  Jul 2020     Added Extra Fields for Hash Totals of Containers.
//
//       Author: Bill Hepler
//
// Date created: 05-06-99
// Date updated: July 2012, 2019, 2020
//    Copyright: 1999, 2012, 2019, 2020 by Bill Hepler
// -----------------------------------------------------------------------------

#include 'Field.CH'
#include "BerryPay.ch"

function ReceiptStru( nReceiptStru )
	local aReturn := {}
	local n

	aadd( aReturn, { 'DEPOT'      ,  'C' ,   FLD_DEPOT  ,   000 } )                 // The Scale Site where goods/containers were shipped from etc..
	aadd( aReturn, { 'PRODUCT'    ,  'C' ,   FLD_PRODUCT ,  000 } )                 // Product - blank for Containers only
	aadd( aReturn, { 'RECPT'      ,  'N' ,   FLD_RECPT   ,  000 } )                 // Scale Ticket Number ( DEPOT + Scale Ticket No SB unique !)
	aadd( aReturn, { 'NUMBER'     ,  'N' ,   FLD_GROWER  ,  000 } )                 // Grower ID
	aadd( aReturn, { 'GROSS'      ,  'N' ,    006  ,        000 } )
	aadd( aReturn, { 'TARE'       ,  'N' ,    006  ,        000 } )
	aadd( aReturn, { 'NET'        ,  'N' ,    006  ,        000 } )
	aadd( aReturn, { 'GRADE'      ,  'N' ,   FLD_GRADE ,    000 } )                  // Grade Product+Process+Grade is the RECEIVING SKU...
	aadd( aReturn, { 'PROCESS'    ,  'C' ,   FLD_PROCESS,   000 } )                  // Type of Product (for Fresh, for Processing, for Juice etc)

	aadd( aReturn, { 'IN1'        ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )          // Containers Received (usually the product is weighed in these)
	aadd( aReturn, { 'IN2'        ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN3'        ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN4'        ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN5'        ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN6'        ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN7'        ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN8'        ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN9'        ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN10'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN11'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN12'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN13'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN14'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN15'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN16'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN17'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN18'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN19'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'IN20'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )

	aadd( aReturn, { 'OUT1'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )         // Containers issued to Grower
	aadd( aReturn, { 'OUT2'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT3'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT4'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT5'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT6'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT7'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT8'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT9'       ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT10'      ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT11'      ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT12'      ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT13'      ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT14'      ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT15'      ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT16'      ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT17'      ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT18'      ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT19'      ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )
	aadd( aReturn, { 'OUT20'      ,  'N' ,   FLD_CONTAINER_QTY  ,   000 } )

	aadd( aReturn, { 'TIME'       ,  'C' ,    005  ,   000 } )                      // the Time ticket was created

   // August 7, 2008
   aadd( aReturn, { 'ORI_NET'    ,  'N' ,    006  ,   000 } )                     // Original Net Weight at Scale

   // July 2013
   aadd( aReturn, { 'CERTIFIED'    ,  'C' ,   FLD_CERTIFIED,   000 } )             // Effectively User Defined info

	// May & June 2015
	aadd( aReturn, {'LONG_PROD','C',FLD_LONG_NU_PRODUCT ,0 })   // May 2015  - weirdly this is What was imported - noted in March 2020
	aadd( aReturn, {'LONG_PROC','C',FLD_LONG_NU_PROCESS ,0 })   // May 2015  -    ditto
	aadd( aReturn, {'VARIETY',  'C',FLD_VARIETY ,0 })           // May 2015

	aadd( aReturn, { 'DATE'  ,    'D' ,    008  ,   000 }   )                   // Ticket Date - moved up to here

	do case
	case nReceiptStru == RECEIPT_STRU_FOR_DAILY
		// This field is NOT used for anything // June 2000 - got rid of
		// aadd( aReturn, { 'AUDIT',     'N',     FLD_DOCUMENT  ,    000 }   )

		aadd( aReturn, { 'DAY_UNIQ',  'N',     FLD_DOCUMENT  ,    000 }   )         // Unique ID assigned by this system

		// Sep 99 - for "scratch work"
		aadd( aReturn, { 'INFO_TEMP',  'C', 1 ,    000 }   )

      // Oct 99 for Suzy - DEPOT + TICKET + RECPTLTR should REALLY be unique
      aadd( aReturn, { 'RECPTLTR',  'C', 1 ,    000 }   )                         // Just in case an Adjusting transaction needs to be created


      // Oct 99 for BH
      aadd( aReturn, { 'EDITED',  'D', 8 ,    000 }   )                           // last edited in OFFICE !

		// June 2000 - for "final & advance"
      //    Prior to June 2007 we had ADV_PR1 was called ADV_PRICE !
      //                       we had ADV_PRID1 was called ADV_PR_ID
      //                       we had POST_BAT1 was called POST_BAT
      //    we changed it, HAVE conversion routine in ConvPrior()


      aadd( aReturn, { 'ADV_PR1',    'N', 5 , 002 }   )   // Advance Price 1
      aadd( aReturn, { 'FIN_PRICE',  'N', 5 , 002 }   )   // Final Price
		aadd( aReturn, { 'PREM_PRICE', 'N', 5,  002 }   )   // Time Premium Price
		// Unit Price of course...that is price per pound

		// June 2000 - what Record was Used in Price.DBF
      aadd( aReturn, { 'ADV_PRID1',  'N', FLD_DOCUMENT , 000 }   )  //Adv 1 ID
      aadd( aReturn, { 'FIN_PR_ID',  'N', FLD_DOCUMENT , 000 }   )

      aadd( aReturn, { 'POST_BAT1',  'N', FLD_DOCUMENT , 000 } )  //Adv 1 Batch
      aadd( aReturn, { 'IMP_BAT',    'N', FLD_DOCUMENT , 000 } )  // Import Batch as REPORTED BY THE SCALE !
                                                                  // Noted April 2020 - DEPOT + IMP_BAT should uniquely define a batch....
                                                                  // but we can not be sure about this...it is external data.
                                                                  // so ->UNIQ_IMBAT is guaranteed unique.

      aadd( aReturn, { 'FIN_BAT',    'N', FLD_DOCUMENT , 000 } )  //Final Payment Posting Batch

      //Nov 2001
      aadd( aReturn, { 'ADV_PR2',    'N', 5 , 002 }   )   // Advance Price 2
      aadd( aReturn, { 'ADV_PRID2',  'N', FLD_DOCUMENT , 000 }   )
      aadd( aReturn, { 'POST_BAT2',  'N', FLD_DOCUMENT , 000 } )  //Adv Batch

      aadd( aReturn, { 'ADV_PR3',    'N', 5 , 002 }   )   // Advance Price 2
      aadd( aReturn, { 'ADV_PRID3',  'N', FLD_DOCUMENT , 000 }   )
      aadd( aReturn, { 'POST_BAT3',  'N', FLD_DOCUMENT , 000 } )  //Adv Batch

      // June 2005
      aadd( aReturn, { 'ADD_DATE',   'D', 8 , 000 } )                                  // See QADD_DATE
      aadd( aReturn, { 'ADD_BY',     'C', 8 , 000 } )

      aadd( aReturn, { 'EDIT_DATE',  'D', 8 , 000 } )
      aadd( aReturn, { 'EDIT_BY'  ,  'C', 8 , 000 } )
      aadd( aReturn, { 'EDIT_REAS',  'C', 20 , 000 } )

      aadd( aReturn, { 'DOCK_PCT',   'N', 3,000 })

      aadd( aReturn, { 'ISVOID',     'L', 1,0 })

      // June 2007
      aadd( aReturn, {'THEPRICE',    'N', 5,2 })   // June 2007     - gets keyed in
      aadd( aReturn, {'PRICESRC',    'N', 1,0 })     // June 2007

		// July 2014
		aadd( aReturn, {'PR_NOTE1', 'C', FLD_TICKET_NOTE,0 })   // July 2014
		aadd( aReturn, {'NP_NOTE1', 'C', FLD_TICKET_NOTE,0 })   // July 2014


	case nReceiptStru == RECEIPT_STRU_FOR_SUMMARY
		for n := 1 to len(aReturn)
			if aReturn[n,2]=='N'
				do case
				case substr(aReturn[n,1],1,2)=='IN'
					aReturn[n,3] := 9 // 8
				case substr(aReturn[n,1],1,3)=='OUT'
					aReturn[n,3] := 9 // 8
				case aReturn[n,1]=='NET'
					aReturn[n,3] := 11 // 10
            case aReturn[n,1]=='ORI_NET'
					aReturn[n,3] := 11 // 10
            endcase
			endif
		next

      aadd( aReturn, { 'HASH_IN',  'N', 10 ,0 } )
		aadd( aReturn, { 'HASH_OUT', 'N', 10 ,0 } )
      aadd( aReturn, { 'HASH_BAL', 'N', 10, 0 } )   // Out - In - Based on Scale Report sent July 2, 2020

	endcase
	// -------------------------------- Here at end add stuff for ->from_Field data...

	aadd( aReturn, {'FROM_FIELD', 'C', FLD_FROM_FIELD,0 })  // Mar 2020 - FROM_FIELD is used to reference this in CODE !
	aadd( aReturn, {'IMPORTED',   'L', 1, 0 })              // Mar 2020 - we need to know if this was an IMPORTED ticket.
	aadd( aReturn, {'UNIQ_IMBAT', 'N', FLD_DOCUMENT ,0 })   // Apr 2020 - this is the UNIQUE Identifier, assigned in Office. called IMPORT SESSION
                                                           //            see notes on IMP_BAT
	aadd( aReturn, {'LAST_ADVPB', 'N', FLD_DOCUMENT, 0 })   // Apr 2020 - Last ADVance Posting Batch
	// note that this SHOULD contain the largest of POST_BAT1 & POSTBAT2 & POSTBAT3

	aadd( aReturn, {'CONT_ERRS',  'C', FLD_CONTAINER_ERRS, 0 }) // May 2020 - Add Container Errors -
	                                                            //   these occur if the Scale Program is sending container info
																				   //   but the BerryPay program (this PRG) is NOT configured to
																				   //   accept them!  We store the first few.
																				   // Example Data
																				   //     FB         <- one error
																				   //     FB,SD,SF   <- multi-errors
																				   // Cuts OFF if too many errors.




return( aReturn )


