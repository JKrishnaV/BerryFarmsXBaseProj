//----------------------------------------------------------------------------
//  Application: Berry Payment System
//   Description: Computes the Amount paid
//
//     File Name: MISCPAY.PRG
//        Author: Bill Hepler
//  Date created: 1999
//  Sep 2019 - comment added to code - no code change
//
// Copyright: (c) 1999, 2014 by Bill Hepler & Crafted Industrial Software Ltd.
//----------------------------------------------------------------------------

#include "errors.ch"
#include "miscpay.ch"
#include "indexord.ch"
#include "field.ch"
#include "bsgstd.ch"

///<summary>Optional UpToTHisDate</summary>
function PostPaidArray( dUpTo )
   // Finds all records in Account that relate to
   //   a given Daily Receipt.

	local aRay := {}
	local lAddIt
	local n

	// Audit1','Day+Acc ID','str(Audit->day_uniq,8)+str(Audit->acct_uniq,8)'
	// Audit2','Acc+Day ID','str(Audit->acct_uniq,8)+str(Audit->day_uniq,8)'

   Audit->(OrdSetFocus( AUDIT_DAY_ACCT_ORD ))
   Account->(OrdSetFocus( ACCOUNT_LINK_ORD ))
   Cheque->(OrdSetFocus(CHEQUE_CHEQUE_NO_ORD))

	Audit->(dbSeek( str(Daily->day_uniq,FLD_AD_LINK),HARDSEEK))
	do while Audit->day_uniq==Daily->day_uniq .and. !Audit->(eof())
		Account->(dbSeek( str(Audit->acct_uniq,FLD_AD_LINK),HARDSEEK))
		do while Audit->acct_uniq==Account->acct_uniq .and. !Account->(eof())

			lAddIt := .t.

			if valType(dUpTo)=='D'
				if Account->date > dUpTo
					lAddIt := .f.
				endif
			endif

			if lAddit
				aadd(aRay,  EMPTY_PAY_AUDIT_STRU )
				n := len(aRay)
				aRay[n,  PAS_ACC_TYPE       ] := Account->type
				aRay[n,  PAS_ACC_CLASS      ] := Account->class
				aRay[n,  PAS_ACC_DATE       ] := Account->date
				aRay[n,  PAS_ACC_UNIT_PRICE ] := Account->u_price
				aRay[n,  PAS_ACC_CHEQUE_NO  ] := Account->cheque
				aRay[n,  PAS_ACC_SERIES     ] := Account->series

				if Account->cheque > 0
					if Cheque->(dbSeek( Account->series + ;
							str(Account->cheque, FLD_CHEQUE), HARDSEEK ))

						aRay[n,  PAS_ACC_CHEQUE_DATE   ] := Cheque->date
						aRay[n,  PAS_ACC_CHEQUE_AMT    ] := Cheque->amount
						aRay[n,  PAS_ACC_CHEQUE_FOUND  ] := .t.

					endif
				endif
			endif

			if Account->number <> Daily->number
				appError( APP_ERR_GROWER_NO_WRONG, ;
					{'Grower number is different than expected', ;
					 'In Daily-POSTED='+str(Daily->number,10), ;
					 'In Account.DBF ='+str(Account->number,10) })
			endif
			Account->(dbSkip())
		enddo
		Audit->(dbSkip())
	enddo

return( aRay )

