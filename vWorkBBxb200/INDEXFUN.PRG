// ---------------------------------------------------------------------------
//  Application: Berry Payment System
//  Description: Functions for Building Indexes
//
//    File Name: INDEXFUN.PRG
//       Author: Bill Hepler
//  Date created: 11-02-01
//  Time created: 08:12:17am
//     Dec 2019 - minor mod to make tidier
//
//  Copyright: (c) 2001, 2019 by Bill Hepler & Crafted Industrial Software Ltd.
// ---------------------------------------------------------------------------


#include 'forstuff.ch'
#include 'errors.ch'

static nForType

function SetForClause( nForParam  )

   nForType := nForParam

   if nForType <> FOR_TYPE_ADVANCE_1 .and. ;
      nForType <> FOR_TYPE_ADVANCE_2 .and. ;
      nForType <> FOR_TYPE_ADVANCE_3 .and. ;
      nForType <> FOR_TYPE_ALWAYS_TRUE

      appError( APP_ERR_UNKNOWN_INDEXING_TYPE , ;
        { 'Set For Clause is Goofy - proably' , ;
          'will crash soon - NOTE THIS ERROR MESSAGE !'} )

   endif

return( nil )


function SpecNX(  )
   local lReturn := .f.

   do case
   case nForType == FOR_TYPE_ADVANCE_1
      lReturn := (Daily->post_bat1==0)
   case nForType == FOR_TYPE_ADVANCE_2
      lReturn := (Daily->post_bat2==0)
   case nForType == FOR_TYPE_ADVANCE_3
      lReturn := (Daily->post_bat3==0)

   case nForType == FOR_TYPE_ALWAYS_TRUE
      lReturn := .T.
   endcase

return( lReturn )
