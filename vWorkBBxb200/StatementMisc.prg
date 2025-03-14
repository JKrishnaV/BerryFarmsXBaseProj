//////////////////////////////////////////////////////////////////////
///   StatementMisc.prg
///
/// <summary>
///    Miscellaneous Functions for Statements
///    There are 2 types of Statements:
///      1. Weekly / Regular / Advance Pay Statements, that cover Advance & Final payments
///         which would go with Cheques.
///     2.  Final / Crop Year Statements, that are intended to be sent out at Year End
///         and perhaps at other times which show overall payment information.
///         These might accaompany a final cheque.
/// </summary>
///
///
/// <remarks>
/// </remarks>
///
///
/// <copyright>
///  (c) 2019 Crafted Industrial Software Ltd and Bill Hepler, all Rights Reserved.
/// </copyright>
///
//////////////////////////////////////////////////////////////////////
///

#include "BerryPay.ch"
#include "SYSVALUE.CH"

static aWeeklyInfo    :=  {} //  GROWER_STATEMENT_WEEKLY_ARRAY
static aCropYearInfo  :=  {} //  GROWER_STATEMENT_CROPYEAR_ARRAY

///<summary>Returns 2D array for Menus see GRO_STATEMENT_FOR_ ... </summary>
function StatementMnuTxtArr( cGroStatFor )
	local aReturn := {}
   local n, nLen := 0

   initMe()

   do case
   case cGroStatFor == GRO_STATEMENT_FOR_WEEKLY
		for n := 1 to len( aWeeklyInfo )
			aadd( aReturn, { aWeeklyInfo[   n, GRO_STATEMENT_COL_DESC ], GROW_STATEMENT_WEEKLY_GENERAL_DESC } )
         if n == sysValue( SYS_WEEK_STATEMENT_DEFAULT_FORMAT )
         	aReturn[ n, 1 ] += ' ** Default **'
         endif
         aReturn[ n, 2] += ( ' '+aReturn[n,1])
			nLen := max( nLen, len( aReturn[ n,1]) )
      next

   case cGroStatFor == GRO_STATEMENT_FOR_CROPYEAR
		for n := 1 to len( aCropYearInfo )
			aadd( aReturn, { aCropYearInfo[ n, GRO_STATEMENT_COL_DESC ], GROW_STATEMENT_CROPYEAR_GENERAL_DESC } )
         if n == sysValue( SYS_CROPYEAR_STATEMENT_DEFAULT_FORMAT )
         	aReturn[ n, 1 ] += ' ** Default **'
         endif
         aReturn[ n, 2] += ( ' '+aReturn[n,1])
			nLen := max( nLen, len( aReturn[ n,1]) )
      next

   otherwise
   	WaitHand({'You should NEVER see this! MenuTextArray() Problem', ;
                'call Crafted IS Ltd at 604-256-7485'})
   endcase

	for n := 1 to len( aReturn )
     	aReturn[ n, 1] := str( n,1)+'. '+padr( aReturn[ n,1 ], nLen)
   next

return( aReturn )

function StatementDo( cGroStatFor, nStatementFmtID )
   initMe()

   do case
   case cGroStatFor == GRO_STATEMENT_FOR_WEEKLY
   	if nStatementFmtID >= WEEK_STATEMENT_FORMAT_1_OLD .and. ;
			nStatementFmtID <= len( aWeeklyInfo )

         eval( aWeeklyInfo[ nStatementFmtID, GRO_STATEMENT_COL_EXE_BLOCK ] )

		else
			WaitHand({'We are attempting to Print Weekly Statement #'+var2char( nStatementFmtID ), ;
                   'but this has not been set yet -- please check your System Settings!'})
      endif
   case cGroStatFor == GRO_STATEMENT_FOR_CROPYEAR
   	if nStatementFmtID >= CROPYEAR_STATEMENT_FORMAT_1_OLD .and. ;
			nStatementFmtID <= len( aCropYearInfo )

         eval( aCropYearInfo[ nStatementFmtID, GRO_STATEMENT_COL_EXE_BLOCK ] )

		else
			WaitHand({'We are attempting to Print Crop Year Statement #'+var2char( nStatementFmtID ), ;
                   'but this has not been set yet -- please check your System Settings!'})
      endif

   otherwise
   	WaitHand({'You should NEVER see this! MenuTextArray() Problem', ;
                'call Crafted IS Ltd at 604-256-7485'})
   endcase

return( nil )

function StatementDesc( cGroStatFor, nStatementFmtID )
	local cReturn := 'Bad Error !'

   initMe()

   do case
   case cGroStatFor == GRO_STATEMENT_FOR_WEEKLY
   	if nStatementFmtID >= WEEK_STATEMENT_FORMAT_1_OLD .and. ;
			nStatementFmtID <= len( aWeeklyInfo )

         cReturn := aWeeklyInfo[ nStatementFmtID, GRO_STATEMENT_COL_DESC ]
         if nStatementFmtID == sysValue( SYS_WEEK_STATEMENT_DEFAULT_FORMAT )
         	cReturn += ' ** Default **'
         endif

		else
			WaitHand({'We are attempting to Describe a Weekly Statement #'+var2char( nStatementFmtID ), ;
                   'but this has not been set yet -- please check your System Settings!'})
      endif
   case cGroStatFor == GRO_STATEMENT_FOR_CROPYEAR
   	if nStatementFmtID >= CROPYEAR_STATEMENT_FORMAT_1_OLD .and. ;
			nStatementFmtID <= len( aCropYearInfo )

         cReturn := aCropYearInfo[ nStatementFmtID, GRO_STATEMENT_COL_DESC ]
         if nStatementFmtID == sysValue( SYS_CROPYEAR_STATEMENT_DEFAULT_FORMAT )
         	cReturn += ' ** Default **'
			endif

		else
			WaitHand({'We are attempting to Describe a Crop Year Statement #'+var2char( nStatementFmtID ), ;
                   'but this has not been set yet -- please check your System Settings!'})
      endif

   otherwise
   	WaitHand({'You should NEVER see this! StatementDesc() Problem', ;
                'call Crafted IS Ltd at 604-256-7485'})
   endcase

return( cReturn )


static function InitMe()

	if len( aWeeklyInfo ) == 0
		aWeeklyInfo    :=  GROWER_STATEMENT_WEEKLY_ARRAY
		aCropYearInfo  :=  GROWER_STATEMENT_CROPYEAR_ARRAY
   endif

return( nil )





