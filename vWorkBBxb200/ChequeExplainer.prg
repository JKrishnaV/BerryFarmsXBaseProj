//////////////////////////////////////////////////////////////////////
///
/// <summary>
///      This is ON SCREEN documentation about cheques that I will include
///      in the manual.
/// </summary>
///
///
/// <remarks>
/// </remarks>
///
///
/// <copyright>
///    (c) 2021 - Bill Hepler and Crafted Industrial Software Ltd.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////


function ChequeExplainer()
	local aRay

   aRay := {  ;
    'The following is an overview of how cheques work in this system, and a detailed explanation of how and', ;
    'why to issue LOANS, REISSUE CHEQUES, VOID CHEQUES either LEAVING or REMOVING VOUCHER Records.',          ;
    '',                                                                                                       ;
    'OVERVIEW - in this system a Cheque relates to VOUCHER RECORDS. Each Voucher Record will record a debit', ;
    'or credit to a Growers account.  A cheque can relate to one or more Voucher records, but any given',     ;
    'voucher record will either be OUTSTANDING or will relate to exactly one cheque.',                        ;
    '',                                                                                                       ;
    'Voucher Records can be STAND ALONE records as might happen if you loan a grower some money (this kind',  ;
    'of transaction is sometimes called a PRE-SEASON Advance).  But most often Voucher Records will relate',  ;
    'to individual Receipt Records (scale tickets).  Receipt Records can relate to more than one Voucher'  ,  ;
    'Record because you can issue up to 3 advances, bonus payments, a marketing deduction and a final'     ,  ;
    'payment against each Receipt Record.','',                                                                ;
    'Issuing cheques for Crop Advances, Bonuses and Final Payments are discussed in your manual.',''        }

   aadd(aRay, ;
    'The complexity of this record keeping system imposes some limitations on what you can do in terms' )
   aadd(aRay, ;
    'of Voiding Cheques.')
	aadd(aRay, '')
   aadd(aRay,'The Printed Manual explains all this in even more detail if you need more information.' )
	aadd(aRay, '')

   aadd( aRay, ;
    '1-REISSUE CHEQUES is the easiest to understand.  In this case, a cheque was issued to a grower but')
   aadd( aRay, ;
    '  the cheque was lost or did not print properly. In that case, you simply want to reprint another check.')
   aadd( aRay, '  The system will assign a new number to the cheque.')
   aadd( aRay, '')

   aadd( aRay, ;
    '2-LOAN CHEQUES are fairly straight forward as well.  These will often come about when a grower needs')
   aadd( aRay, ;
    '  money at the beginning of the season to finance farm operations.  The management of your firm')
   aadd( aRay, ;
    '  must decide to do this. The system generates 2 Voucher Records.  One record directly relates')
   aadd( aRay, ;
    '  to the cheque and this record can not be changed.  The second Record relates to the amount')
   aadd( aRay, ;
    '  that the grower owes you for this amount, and you can edit that record in order to deal with' )
   aadd( aRay, ;
    '  when you intend to collect the receivable for the loan.  You can charge interest, but you must' )
   aadd( aRay, ;
    '  enter that manually.')

   aadd( aRay, '  * Usually when you make a loan the system will print a cheque for that EXACT amount. *')
	aadd(aRay, '')

   aadd( aRay, ;
    'VOID CHEQUES are more complex to understand.  These are intended to VOID (or UnDo) a cheque,' )
   aadd( aRay, ;
    'but there are two kinds of VOID CHEQUE options:')
   aadd( aRay, ;
    '3-The amounts that are owed to the grower are correct, but you wish to pay the grower later' )
   aadd( aRay, ;
    '  In this case you will want to leave the Voucher Records as they are, and simply void the' )
   aadd( aRay, ;
    '  cheque itself.')
   aadd( aRay, ;
    '4-The amounts to the grower are not correct or for some other reason you wish to recalculate' )
   aadd( aRay, ;
    '  what the grower owes and in this case the system will need to void the cheque AND it will' )
   aadd( aRay, ;
    '  also void the underlying Accounts Payable Voucher and reset Receipt Records so that you can' )
   aadd( aRay, ;
    '  pay out the grower at a different rate.  As mentioned above, there are some limitations on when')
   aadd( aRay, ;
    '  this kind of Void can be done.  In general, the ONLY time you can do this procedure is for'   )
   aadd( aRay, ;
    '  fairly new cheques.  You can NOT usually carry this out once another cheque has been issued'  )
   aadd( aRay, ;
    '  to that grower!  The most likely reasons you will want to do this are:' )
   aadd( aRay, ;
    '    A - You want to pay that grower a different rate for an advance.' )
   aadd( aRay, ;
    '    B - You want to pay out those reciepts at a later time.' )
   aadd( aRay, ;
    '    C - You want to include different receipts on this cheque.' )
	aadd( aRay, ;
    '  So this procedure will VOID the cheque and delete the associated VOUCHER RECORDS and audit trail' )
	aadd( aRay, ;
    '  entries.  It will also remove the payment amounts from Scale Receipts associated with the cheque.')
	aadd( aRay, ;
    '  Then you will be able to reprice receipts and ReDo a Cheque run for the Grower.')
   aadd( aRay, '')
   aadd( aRay,'Doing any of these Voids and Reissues will make an entry into the UnUsual events log.')
	aadd(aRay, '')

	WinArrayVu( aRay, 'Information about Issuing & Voiding Cheques' )

return( nil )
