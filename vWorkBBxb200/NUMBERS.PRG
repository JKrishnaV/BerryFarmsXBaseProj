* ÚÄ Program ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
* ³  Application: Berry Payment System                                       ³
* ³  Description: Prints Numbers on a Cheque....                             ³
* ³                                                                          ³
* ³                                                                          ³
* ³                                                                          ³
* ³                                                                          ³
* ³    File Name: NUMBERS.PRG                                                ³
* ³       Author: Bill Hepler                                                ³
* ³ Date created: 06/13/05              Date updated: þ06/13/05              ³
* ³ Time created: 10:52:45am            Time updated: þ10:52:45am            ³
* ³    Copyright: (c) 1905 by Bill Hepler & Crafted Industrial Software Ltd.³
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

//** (c) 1991,1993 Bill Hepler
//** 1993 licensed to Crafted Industrial Software Ltd.
//** 1991,1993 licensed to Minnova Inc.
#include 'bsgstd.ch'

function NumInWords( nValue, nWidth )
   local aRay := {}
   local cWord
   local cNum
   local nDollars, nCents
   local n, nLines

   cNum := str( nValue, 12, 2)
   nDollars := val( substr( cNum, 1, 9) )
   nCents   := val( substr( cNum, 11,2) )

//   cWord := '*** '+alltrim( BigInWords( nDollars) ) +' and ' + ;
//      lStrim(nCents)+'/100 ***'

   cWord := alltrim( BigInWords( nDollars) ) +' and ' + ;
         lStrim(nCents)+'/100 Dollars'

   nLines := mlCount( cWord, nWidth, 0, .t. )

   for n := 1 to nLines
      aadd( aRay,  memoLine( cWord, nWidth, n ) )
   next

return( aRay )



static function BigInWords( xnumber )
   // Calls: s1_9 s10_99
	//** function ***
	//** strings out a number !
	//** this is usually used for writing cheques
   // 10/9/89 Bill Hepler
   // strategy:
   //  for numbers>1 and <999,999,999
   //  look for HUNDREDs of millions
   //   "       1-99       " "
   //  look for HUNDREDS of thousands
   //   "       1-99     "   "
   //  similarly for 1-999
   //
   // THIS DOES not RETURN THE DECIMAL PORTION !!!!
   //
   // calls 2 other functions s1_9   (for numbers from 1-9)
   //                         s10_99 (for numbers from 1-99)
   //                         s10_99  calls s1_9 also

   local xstring, m_900mill, m_90mill, m_900k, m_90k, m_900, m_90
   local cReturn

   cReturn := ' '

   xstring := str( xnumber, 12, 2 )
   m_900mill := substr( xstring, 1, 1 )
   m_90mill := substr( xstring, 2, 2 )
   m_900k := substr( xstring, 4, 1 )
   m_90k := substr( xstring, 5, 2 )
   m_900 := substr( xstring, 7, 1 )
   m_90 := substr( xstring, 8, 2 )

   if xnumber > 999999000 .or. xnumber < 1
      // error
      cReturn := 'ZERO Dollars'
      return( cReturn )
   endif

   if m_900mill <> ' '
      cReturn := s1_9( m_900mill ) + 'HUNDRED '
   endif

   if m_900mill <> ' ' .or. m_90mill <> '  '
      cReturn +=  s10_99( m_90mill ) + 'MILLION '
   endif

   if m_900k <> ' ' .and. m_900k <> '0'
      cReturn +=  s1_9( m_900k ) + 'HUNDRED '
   endif

   if( m_900k <> ' ' .or. m_90k <> '  ' ).and.( m_900k + m_90k <> '000' )
      cReturn += s10_99( m_90k ) + 'THOUSAND '
   endif

   if m_900 <> ' ' .and. m_900 <> '0'
      cReturn += s1_9( m_900 ) + 'HUNDRED '
   endif

   if m_900 <> ' ' .and. m_90 <> '  ' .and. m_90 <> '00'
      cReturn += 'AND ' + s10_99( m_90 )
   else
      cReturn += s10_99( m_90 )
   endif

   // this also works just fine -- but the other puts the AND in.
   // IF m_900<>' ' .OR. m_90<>'  '
   //   x_written=x_written + s10_99(m_90)
   // ENDIF


return( cReturn )

// deals with numbers 0-9
static function s1_9( xx )                              // Amended by SUMMER93
   // Calls:
   // Called By: writ_num s10_99
   local s1_9x

   s1_9x := ''
   do case
   case xx = '1'
      s1_9x := 'ONE '
   case xx = '2'
      s1_9x := 'TWO '
   case xx = '3'
      s1_9x := 'THREE '
   case xx = '4'
      s1_9x := 'FOUR '
   case xx = '5'
      s1_9x := 'FIVE '
   case xx = '6'
      s1_9x := 'SIX '
   case xx = '7'
      s1_9x := 'SEVEN '
   case xx = '8'
      s1_9x := 'EIGHT '
   case xx = '9'
      s1_9x := 'NINE '
   endcase
return( s1_9x )


// deals with numbers 0-99
static function s10_99( xxyy )                          // Amended by SUMMER93
   // Calls: s1_9
   // Called By: writ_num
   local s10_99x

   s10_99x := ''

   if len( xxyy ) <> 2
      wait 'Bad parameter passed to s10_99-'
   endif

   do case
   case( xxyy <= ' 9' .and. xxyy >= ' 1' ).or.( xxyy <= '09' .and. xxyy;
         >= '01' )
      s10_99x := s1_9( substr( xxyy, 2, 1 ) )
   case xxyy = '10'
      s10_99x := 'TEN '
   case xxyy = '11'
      s10_99x := 'ELEVEN '
   case xxyy = '12'
      s10_99x := 'TWELVE '
   case xxyy = '13'
      s10_99x := 'THIRTEEN '
   case xxyy = '14'
      s10_99x := 'FOURTEEN '
   case xxyy = '15'
      s10_99x := 'FIFTEEN '
   case xxyy = '16'
      s10_99x := 'SIXTEEN '
   case xxyy = '17'
      s10_99x := 'SEVENTEEN '
   case xxyy = '18'
      s10_99x := 'EIGHTEEN '
   case xxyy = '19'
      s10_99x := 'NINETEEN '
   case xxyy >= '20' .and. xxyy <= '29'
      s10_99x := 'TWENTY ' + s1_9( substr( xxyy, 2, 1 ) )
   case xxyy >= '30' .and. xxyy <= '39'
      s10_99x := 'THIRTY ' + s1_9( substr( xxyy, 2, 1 ) )
   case xxyy >= '40' .and. xxyy <= '49'
      s10_99x := 'FORTY ' + s1_9( substr( xxyy, 2, 1 ) )
   case xxyy >= '50' .and. xxyy <= '59'
      s10_99x := 'FIFTY ' + s1_9( substr( xxyy, 2, 1 ) )
   case xxyy >= '60' .and. xxyy <= '69'
      s10_99x := 'SIXTY ' + s1_9( substr( xxyy, 2, 1 ) )
   case xxyy >= '70' .and. xxyy <= '79'
      s10_99x := 'SEVENTY ' + s1_9( substr( xxyy, 2, 1 ) )
   case xxyy >= '80' .and. xxyy <= '89'
      s10_99x := 'EIGHTY ' + s1_9( substr( xxyy, 2, 1 ) )
   case xxyy >= '90' .and. xxyy <= '99'
      s10_99x := 'NINETY ' + s1_9( substr( xxyy, 2, 1 ) )
   endcase
return( s10_99x )

// end !

