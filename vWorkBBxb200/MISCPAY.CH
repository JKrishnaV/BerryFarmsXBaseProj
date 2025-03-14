//---------------------------------------------------------------------------
//    File Name: MISCPAY.CH                                                 
//  Description: For Audit Trail of Payments                                
//                                                                          
//       Author: Bill Hepler                                                
// Date created: 09-19-99              Updated: June 3, 2014
// Copyright: 1999, 2014 by Bill Hepler & Crafted Industrial Software Ltd.
//-----------------------------------------------------------------------

#define  EMPTY_PAY_AUDIT_STRU   { '','', ctod(''), '', 0, ctod(''), 0.00,0.00, .f. }

// { Account->type, Account->class, Account->date, Account->series,
//      Account->cheque, Cheque->date, Cheque->amount, Account->u_price}

#define   PAS_ACC_TYPE         1
#define   PAS_ACC_CLASS        2
#define   PAS_ACC_DATE         3
#define   PAS_ACC_SERIES       4
#define   PAS_ACC_CHEQUE_NO    5
#define   PAS_ACC_CHEQUE_DATE  6
#define   PAS_ACC_CHEQUE_AMT   7
#define   PAS_ACC_UNIT_PRICE   8
#define   PAS_ACC_CHEQUE_FOUND 9




