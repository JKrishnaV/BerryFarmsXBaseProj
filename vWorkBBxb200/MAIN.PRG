// Crafted Industrial Software Ltd.
// Bill Hepler
// Took over from Duncan Jeffries....who was not the original author
// Feb 2016 - Bill Hepler checked over, mod some dates
//     See CUSTPAID.CH
// April 2020 - small changes
// Aug   2022 - small improvement to Multi-Year Issues


#include 'BerryPay.ch'
#include 'bsgstd.ch'
#include 'custpaid.ch'
#include 'myver.ch'
#include 'setcurs.ch'
#include 'sysvalue.ch'
#include 'version.ch'
#include 'xbp.ch'

static nWarnings := 0
static cTables   := ''

function main()
	local aW
	local n,nKey

	// Added in July 2015  No Parameters used here.
	InitErrorSys( MYVER_THIS_VERSION, shMdy( date()) + ' ' + time(), '' )

	if !MyInit()
		close databases
		return( nil )
	endif

	aW := TestDbfMsg('')
	msgLine('Checking Indexes...')

	ChkInd( 'Account',       aW )
	ChkInd( 'Audit',         aW )
	ChkInd( 'BankRec',       aW )
	ChkInd( 'Cheque',        aW )
	ChkInd( 'Cheque',        aW )
	ChkInd( 'ChqFmt',        aW )
	ChkInd( 'Contain',       aW )
	ChkInd( 'Daily',         aW )
	ChkInd( 'Daily_Audit',   aW )    // April 2020
	ChkInd( 'Events',        aW )
	ChkInd( 'FinBat',        aW )
	ChkInd( 'Grower',        aW )
	ChkInd( 'ImpBat',        aW )
	ChkInd( 'PayGrp',        aW )
	ChkInd( 'PostBat',       aW )
	ChkInd( 'Price',         aW )
	ChkInd( 'Process',       aW )
	ChkInd( 'Product',       aW )
	ChkInd( 'RptCfg',        aW )
	ChkInd( 'VoidChq',       aW )
	ChkInd( 'VoidTck',       aW )
	winkill( aW )

	if !InitContainer()
		return(nil)
	endif

	msgLine('Getting ready to run Payment Program..')

	nKey := inkey()
	n := 1
	do while nKey <> 0 .and. n < 10
		nKey := inkey(1)
		if nextKey()==0
			exit
		endif
		n++
	enddo

	ShowLogo( MyVersion() )
	msgLine('Starting up....')

	inkey(1)

	if SignOn()
		if year(date()) < 2019 .or. year(date()) > 2065
			WaitInfo({'The system is reporting the date as being', ;
				 shMDY(date()), ;
				 'This can not be correct....'})
		else
			if empty( sysValue( SYS_ARCHIVE_DATA_YEAR ))
				CheckActiveCropYear()              // new in 2020 to allow for problem with Crop Year Settings.
			else
				WaitHand({'Archive for YEAR '+ sysValue( SYS_ARCHIVE_DATA_YEAR ), ;
					'You should not normally change data!'})
			endif

			if 'SANDBOX' $ upper(curDirectory())
				WaitInfo({'This is a SAND BOX - a test version of the', ;
							 'program....'})
			endif

			// gRptSetWhen2LandScape( 110 )

			if !HasCustPaid4SW( )
				close databases
				quit
			endif

			msgLine('Full initialization done...')

			SetCursor( SC_NORMAL )

			BerryMenus()     // the main ACTION
		endif
	endif

   close databases
	SetADS_DacSession( .F. ) // NOT REALLY needed

return( nil )

static function chkInd( cFile, aW )
	if !CheckDBF( cFile, .f., aW )
		Reindex1File( cFile )
	endif
return( nil )

///<summary>To make sure customer has paid or S/W stops working</summary>
function HasCustPaid4SW( )
	local lWarn   := .f.
	local lReturn := .t.
	local cNote   := ''
	local lMild   := .t.  // Mild Warning
	local lBackDoorFound := .f.
	local dExpiryDate, dDate

	dDate       := date()
	dExpiryDate := ctod( CUSTOMER_MUST_PAY_BY_DATE )

	if ('WESTBERRY'  $  upper(sysValue( SYS_ACTUAL_CLIENT_NAME )) .or. ;
		 'WEST BERRY' $  upper(sysValue( SYS_ACTUAL_CLIENT_NAME )) )

		dExpiryDate := ctod( WESTBERRY_FAILSAFE_MUST_PAY )
	endif

	if dDate < dExpiryDate - 62    // Its all good  -
		return( lReturn )
	endif

	if dow( date() ) % 2 == 0
		lMild := .f.
	endif

	if file( BACKDOOR_FILE_NAME_FOR_30_DAYS )
		lBackDoorFound := .t.
		dExpiryDate += 30
		cNote := '*** BACK DOOR WORK AROUND is temporary ***'
	endif


	do case
	case dDate > dExpiryDate
		lReturn := .f.

	case dDate == dExpiryDate
		cNote := '*** This is the LAST DAY to resolve this ***'
		lWarn := .t.
		lMild := .f.

	case dDate > ctod( CUSTOMER_MUST_PAY_BY_DATE )
		if lBackDoorFound
			lWarn   := .t.
		else
			lReturn := .f.
		endif

	case dDate > dExpiryDate - 7
		lMild := .f.
		lWarn := .t.
		if lBackDoorFound
			cNote := '*** Work Around Activated but EXPIRY is Soon ***'
		else
			cNote := '*** !!! - EXPIRY is Very Soon - !!! ***'
		endif

	case dDate > dExpiryDate - 31
		lWarn := .t.
		if lBackDoorFound
			cNote := '*** EXPIRY is Soon ***'
		endif

	case dDate > ctod( CUSTOMER_MUST_PAY_BY_DATE ) -61
		lWarn := .t.
		if lBackDoorFound
			cNote := '*** Work Around Activated ***'
		else
			cNote := '*** The software will EXPIRE in less than 2 months ***'
		endif

	otherwise
		lReturn := .t.
	endcase

	do case
	case !lReturn
		msgBox( '*** This Software Has Expired !  ***'             + CR_LF + ;
				  'You must call Crafted Industrial Software Ltd to' + CR_LF + ;
				  'ReActivate the Software !' )

	case lWarn .and. ( nWarnings < 3  .or. nWarnings % 10 == 0 )
		nWarnings++

		msgBox( 'Important Warning !' + CR_LF +  ;
				  'This software will expire soon - please ensure'   + CR_LF + ;
				  'that you contact Crafted soon to ensure that your'+ CR_LF + ;
				  'system will continue to work for you !'           + CR_LF + ;
				  cNote   +                                          + CR_LF + CR_LF  + ;
				  '  The Expiry Date is: '+ shMdy( dExpiryDate )     + CR_LF + ;
				  'Reach Crafted at: 604-256-7485 or by Email: bill@craftedisltd.com' )

		if !lMild
			msgBox( 'Please do NOT delay !'      + CR_LF +  ;
				  'This is an Important Warning.' + CR_LF +  ;
				  'This software will expire soon - please ensure'   + CR_LF + ;
				  'that you contact Crafted soon to ensure that your'+ CR_LF + ;
				  'system will continue to work for you !'           + CR_LF + ;
				  '  The Expiry Date is: '+ shMdy( dExpiryDate )     + CR_LF + ;
				  cNote   +                                          + CR_LF + CR_LF  + ;
				  'Reach Crafted at: 604-256-7485 or by Email: bill@craftedisltd.com' )
		endif

	endcase

return( lReturn )


static function CheckActiveCropYear()
	local nYearLow   := 9999
	local nYearHigh  := -1
	local n

   cTables   := ''

  	msgLine('Quick Check of Crop Year')
	close databases
	dbUseArea( .t., NIL,  'Daily',   NIL, .t. )    // no indexes
	if !NetErr()
		Daily->(ordSetFocus( 0 )) // could have auto open of indexes on!
		Daily->(dbGoTop())
		for n:=1 to 4
			if Daily->(eof())
				exit
			else
				SetHighLow( year(Daily->date), @nYearLow, @nYearHigh )
			endif
			Daily->(dbSkip())
		next

		Daily->(dbGoBottom())
		for n:=1 to 4
	      if Daily->(bof())
				exit
			else
	         SetHighLow( Year(Daily->date), @nYearLow, @nYearHigh )
			endif
			Daily->(dbSkip(-1))
		next
		daily->(dbCloseArea())
	endif


	dbUseArea( .t., NIL,  'Account',  NIL, .t. )   // no indexes
	if !NetErr()
		Account->(ordSetFocus( 0 ))
		Account->(dbGoTop())
		for n := 1 to 4
		  if Account->(eof())
			  exit
		  else
			  SetHighLow( Account->year, @nYearLow, @nYearHigh )
			  Account->(dbSkip())
		  endif
		next

		Account->(dbGoBottom())
		for n := 1 to 4
		  if Account->(eof())
			  exit
		  else
			  SetHighLow( Account->year, @nYearLow, @nYearHigh )
			  Account->(dbSkip( -1))
		  endif
		next

		Account->(dbCloseArea())
	endif

	dbUseArea( .t., NIL,  'Cheque',  NIL, .t. )   // no indexes
	if !NetErr()
		for n := 1 to 4
			Cheque->(ordSetFocus( 0 ))
			Cheque->(dbGoTop())

		  if Cheque->(eof())
			  exit
		  else
			  SetHighLow( Cheque->year, @nYearLow, @nYearHigh )
			  Cheque->(dbSkip())
		  endif
		next

		Cheque->(dbGoBottom())
		for n := 1 to 4
		  if Cheque->(eof())
			  exit
		  else
			  SetHighLow( Cheque->year, @nYearLow, @nYearHigh )
			  Cheque->(dbSkip( -1))
		  endif
		next

		Cheque->(dbCloseArea())
	endif
	close database

   inkey()
   inkey()
	if nYearLow < 9998 .or. nYearHigh > 0
   	if sysValue( SYS_CURRENT_HOWMANY_YEARS ) == 1                               // we only do strong tests in this case

         if !(sysValue( SYS_CURRENT_YEAR ) == nYearLow) .or. !(sysValue( SYS_CURRENT_YEAR ) == nYearHigh)
            WaitHand({'We have an unusual situation - we expect to see only ONE CROP YEAR', ;
                      'in a Data Set.  This may require attention from Crafted Industrial Software', ;
                      'please contact us to ensure that this is NOT a problem.',                     ;
                      'Looked at transaction dates in Daily Receipts and the Crop Year in' ,         ;
                      'the A/P Account Transactions & Cheques.','',                                  ;
                      ' Crop Year='+ var2char( sysValue( SYS_CURRENT_YEAR)),                         ;
                      ' Lowest crop Year in Data - nYearLow=' + var2char( nYearLow),                 ;
                      ' Highest crop Year in Data- nYearHigh='+ var2char( nYearHigh),                ;
                      'Check Tables: '+cTables })
         endif

		endif

	endif

   do case
   case year( date() ) < sysValue( SYS_CURRENT_YEAR )
		WaitHand({'This is very ODD.  This system has a CROP YEAR that is', ;
		          'LATER than the current date - Your Computer Clock may be wrong', ;
					 'or there may be a problem with your data!', ;
					 'Contact your IT department or Crafted Industrial Software Ltd.'})

   case year( date() ) > year( sysValue( SYS_CURRENT_SEASON_END   )) + 1 .or. ;
        year( date() ) > sysValue( SYS_CURRENT_YEAR )  + 1

		WaitHand({'This is very ODD.  You seem to be looking at an ACTIVE data set', ;
		          'that is a Year out of date', ;
                'Usually data this old would be set as an ARCHIVE!', '', ;
			       'Season Start = ' + var2char( sysValue( SYS_CURRENT_SEASON_START )), ;
					 'Crop Year    = ' + var2char( sysValue( SYS_CURRENT_YEAR ) ), ;
					 'Season End   = ' + var2char( sysValue( SYS_CURRENT_SEASON_END   ))    })

	endcase

	if !( year( sysValue( SYS_CURRENT_SEASON_START )) == sysValue( SYS_CURRENT_YEAR ))     .or. ;
	   !( year( sysValue( SYS_CURRENT_SEASON_END   )) == sysValue( SYS_CURRENT_YEAR ))

		WaitHand({'The YEAR End and Season Start & End for this data set seem a bit wonky', ;
			       'Season Start = ' + var2char( sysValue( SYS_CURRENT_SEASON_START )), ;
					 'Crop Year    = ' + var2char( sysValue( SYS_CURRENT_YEAR ) ), ;
					 'Season End   = ' + var2char( sysValue( SYS_CURRENT_SEASON_END   ))    })

	endif


return( nil )

///<summary>nYearLow & high SB passed by Reference </summary>
static function SetHighLow( nYear, nYearLow, nYearHigh )
	local nOldYearLow  := -1
   local nOldYearHigh := -1

	if !eof()
		if nYear < 2001
			WaitInfo({'Low YEAR/date in this record '+dbf()+' #'+var2char( recno()), ;
                   'Value = '+var2char( nYear ), ;
                   'DBF = ' + var2char( dbf()) , ;
						 'Please get Crafted Industrial to Deal with this issue' })
		else
			nOldYearLow  := nYearLow
			nOldYearHigh := nYearHigh

			nYearLow  := min( nYear, nYearLow   )
			nYearHigh := max( nYear, nYearHigh  )

         if nOldYearLow > 2002      .and. nOldYearHigh < 2055 .and. ;
            (nYearLow <> nYear       .or. nYearHigh <> nYear ) .and. ;
            (nOldYearLow <> nYearLow .or. nOldYearHigh <> nYearHigh)

            if !( upper(dbf()) $ cTables )
            	if len(cTables) > 1
               	cTables += ','
               endif
               cTables += upper( dbf())+' RecNo:'+var2char( recNo())
            endif

         endif

		endif
	endif

return( nil )


