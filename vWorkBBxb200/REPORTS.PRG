//--------------------------------------------------------------------------
//   Application: Billing Information System
//   Description: Special Stuff for Configuring the Reports
//
//     File Name: REPORTS.PRG
//        Author: Bill Hepler
//  Date created: 11-22-98
//  Time created: 06:29:07pm
//     Copyright: (c) 1998,2009,2013 by Bill Hepler
// --------------------------------------------------------------------------

#include 'indexord.ch'
#include "field.ch"
#include "common.ch"


function GetToReport( cRpt, cDesc )
	local lReturn := .t.

	default cDesc to ''

   RptCfg->(OrdSetFocus( RPTCFG_RPT_ID_ORD ))

	do case
	case empty(cRpt)
		lReturn := .f.
   case alltrim(cRpt)==alltrim(upper(RptCfg->rpt_id)) .and. !RptCfg->(eof())
		lReturn := RptCfg->(RecLock())
   case !RptCfg->(dbSeek( padr(upper(alltrim(cRpt)), FLD_RPT_ID) ))
		if RptCfg->(AddRecord())
         RptCfg->rpt_id  := upper(alltrim(cRpt))
         RptCfg->desc    := cDesc
			RptCfg->(dbCommit())
		else
			lReturn := .f.
		endif
	otherwise
		lReturn := RptCfg->(RecLock())
	endcase

return( lReturn )

