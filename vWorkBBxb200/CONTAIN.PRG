* ÚÄ Program ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ?
* ? Application: Berry Payment System                                       ?
* ? Description: For Setting Up Container Types                             ?
* ?                                                                         ?
* ?          Oh dear, there are more than 9 types of containers             ?
* ?          We allow up to 20 now....                                      ?
* ?                                                                         ?
* ?   File Name: CONTAIN.PRG                                                ?
* ?      Author: Bill Hepler                                                ?
* ?Date created: 12-11-94              Date updated:  May-99                ?
* ?Time created: 10:55:00am            Time updated: þ10:55:00am            ?
* ?   Copyright: (c) 1994 by Bill Hepler & Crafted Industrial Software Ltd.         ?
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

#include "window.ch"
#include "indexord.ch"
#include "valid.ch"
#include "field.ch"
#include "bsgstd.ch"
#include "common.ch"
#include "inkey.ch"
#include "BerryPay.ch"
#include "errors.ch"
#include "contain.ch"

static aContainer[ MAX_TYPES_CONTAINERS, 6 ]

#define  A_CONTAINER_LONG_NAME    1
#define  A_CONTAINER_SHORT_NAME   2
#define  A_CONTAINER_TARE         3
#define  A_CONTAINER_VALUE        4
#define  A_CONTAINER_TYPE_IN_USE  5
#define  A_CONTAINER_TYPE_ON_FILE 6

function ContArray()
	local aCnt := {}
	local n

	for n := 1 to len(aContainer)
		aadd( aCnt, { ,,,, ,,, } )


		aCnt[n, A_CONT_ID ]   := aContainer[ n,A_CONTAINER_SHORT_NAME ]
		aCnt[n, A_CONT_NAME ] := aContainer[ n,A_CONTAINER_LONG_NAME  ]

		aCnt[n, A_CONT_WEIGHT ] := aContainer[n,A_CONTAINER_TARE]
		aCnt[n, A_CONT_VALUE  ] := aContainer[n,A_CONTAINER_VALUE]

		aCnt[n, A_CONT_IN     ] := 0
		aCnt[n, A_CONT_OUT    ] := 0
		aCnt[n, A_CONT_ISSUED ] := 0

		aCnt[n, A_CONT_LOOKED_AT ] := .f.
	next

return( aCnt )

function ContLName( n )
	local cReturn := space( FLD_CONTAINER_DESC)

	if n >= 1 .and. n <= len(aContainer)
		cReturn := aContainer[ n, A_CONTAINER_LONG_NAME ]
	endif

return( cReturn )

function ContInUse( n )
	local lReturn := .f.

	if n >= 1 .and. n <= len(aContainer)
		lReturn := aContainer[ n, A_CONTAINER_TYPE_IN_USE ]
	endif

return( lReturn )

function ContSName( n )
	local cReturn := space( FLD_CONTAINER_SHORT)

	if n >= 1 .and. n <= len(aContainer)
		cReturn := aContainer[ n, A_CONTAINER_SHORT_NAME ]
	endif

return( cReturn )

function ContNumb( cShort )
   local n
   local nReturn := 0

   for n := 1 to len( aContainer )
      if upper(alltrim( aContainer[n,A_CONTAINER_SHORT_NAME])) == ;
         upper(alltrim(cShort))
         nReturn := n
         exit
      endif
   next

return( nReturn )


function gsContainer( cFld, n, nSet )
	local nReturn := 0
	local nPos

	nPos := FieldPos( cFld+lstrim(n))
	if nPos <= 0
		appError( APP_ERR_WRONG_DBF_FILE3 ,  cFld+ 'Not pointed to correct DBF!' )
	else
		nReturn := FieldGet( nPos )
		if valType(nSet)=='N'
			FieldPut( nPos, nSet)
		endif
	endif
return( nReturn )

function gsInContainer( n, nSet )
	local nReturn := 0
	local nPos

	nPos := FieldPos('IN'+lstrim(n))
	if nPos <= 0
		appError( APP_ERR_WRONG_DBF_FILE1 , 'IN Not pointed to correct DBF!' )
	else
		nReturn := FieldGet( nPos )
		if valType(nSet)=='N'
			FieldPut( nPos, nSet)
		endif
	endif
return( nReturn )

function gsOutContainer( n, nSet )
	local nReturn := 0
	local nPos

	nPos := FieldPos('OUT'+lstrim(n))
	if nPos <= 0
		appError( APP_ERR_WRONG_DBF_FILE2 , 'OUT Not pointed to correct DBF!' )
	else
		nReturn := FieldGet( nPos )
		if valType(nSet)=='N'
			FieldPut( nPos, nSet)
		endif
	endif
return( nReturn )

function NetContRecvd( n )
	local nReturn := 0

   nReturn := gsInContainer( n ) - gsOutContainer( n )

return( nReturn )

function AnyContainers(  )
	local n
	local lReturn := .f.

	for n := 1 to MAX_TYPES_CONTAINERS

      if str( gsInContainer(n),  12,1) <> str(0,12,1) .or. ;
         str( gsOutContainer(n), 12,1) <> str(0,12,1)
			lReturn := .t.
			exit
		endif
	next

return( lReturn )

function ValueAllContain(  )    // in growers hand
	local nReturn := 0.00
	local n

	for n := 1 to len(aContainer)
		nReturn += ValueContain( n )
	next

return( nReturn )

static function ValueContain( nCode )
	local nReturn := 0.00
	local nValue  := 0.00

	if nCode >= 0 .and. nCode <= len(aContainer)
		nValue :=  aContainer[ nCode ,  A_CONTAINER_VALUE ]
		nReturn := -(nValue * NetContRecvd( nCode ))
		// negative because if 5 containers were shipped (i.e. -5 rec'd)
		//    -5 * $6/ea = -$30
		// the value in the growers hand is $30 !
	else
		appError( APP_ERR_CONTAINER_ID  , { str(nCode,12,2), ;
			'Container Code Error' })
	endif

return( nReturn  )


function Container(  )
	local nContainer, getList :={}, aW

	if !openfile({'CONTAIN'}, DB_SHARED )
		close databases
		return( nil )
	endif

	create window at 6,16,12,64 title 'Containers' to aW
	display window aW
	set cursor on

	in window aW @ 4,2 winsay 'Use this screen to set the Container types.'
	in window aW @ 5,2 winsay 'You are allowed up to '+ ;
		 lStrim(MAX_TYPES_CONTAINERS)+' types.'
	in window aW @ 6,2 winsay 'This must correlate with the scale system.'

	nContainer := 0
	do while .t.
		in window aW @ 2,2 winsay 'Container ID' winget nContainer ;
			 picture "@Z 99" ;
			lookup( LU_CONTAINER, 'Enter Container # - [F5] to Browse')
		read

		do case
		case lastkey()==K_ESC
			exit
		case ValidTest(V_CONTAINER,nContainer,VT_NO_MESSAGE)
			getScreen(.f.)
		case nContainer == 0
			waitInfo({'Container Number can not be blank'})
		otherwise
			// Aug 18-98
			if nContainer > 0 .or. nContainer <= MAX_TYPES_CONTAINERS
				if Contain->(addRecord())
					Contain->container := nContainer
					Contain->(dbCommit())
					getScreen( .t. )
				endif
			endif
		endcase
	enddo

   InitContainer()
	kill window aW
	close databases

return( nil )

static function getScreen( lRead )
	local nChoice
	local aWin

	if !Contain->(recLock())
		return( nil )
	endif

	create window at 5,14,13,67 ;
			title 'Edit Container Type' to aWin

	display window aWin
	set cursor on

	do while .t.
		GetStuffed( lRead, aWin )
		lRead := .f.

		nChoice := thinChoice( {'View','Edit','Delete','X - eXit'})

		do case
		case nChoice==0 .or. nChoice==4
			exit
		case nChoice==1
			thinWait()
			loop
		case nChoice==2
			lRead := .t.
		case nChoice==3
			if YesNo({'Are you Sure you want to Delete This?'})
				Contain->(DeleteRecord())
				exit
			endif
		endcase
	enddo
	kill window aWin
	Contain->(dbUnlock())
return( nil )

static function getStuffed( lRead, aWin )
	local getList := {}

	do while .t.
		in window aWin @ 2,2 winsay "ID         " winget Contain->container ;
			picture replicate('9',FLD_CONTAINER)
		getList := {}

		in window aWin @ 3,2 winsay "Description" winget Contain->Desc  ;
			get_message 'Enter a Description of this Container'

		in window aWin @ 4,2 winsay "Short Desc "  winget Contain->short ;
			get_message ;
			"This goes in various Report Headings"

		// we do not do any calc's with this, they are done at the scale...
		in window aWin @ 5,2 winsay "Weight     "  winget Contain->tare ;
			get_message ;
			"Tare Weight of Container (for Information only-Calcs done at scale!)"

		in window aWin @ 6,2 winsay 'Value      ' winget Contain->value ;
			 picture '9999.99' ;
			 get_message 'Value of container (used in some reports)'

		in window aWin @ 7,2 winsay "In Use     "  winget Contain->inuse ;
			picture 'Y' ;
			get_message ;
			"Are you Using/Tracking this Container Type?"

		if lRead
			read

			Contain->(dbCommit())
		else
			getList :={}
		endif
		exit
	enddo

return( nil )

function InitContainer()
	local n
	local lReturn := .f.
	local cDesc,cShort

	for n := 1 to MAX_TYPES_CONTAINERS
		aContainer[n, A_CONTAINER_LONG_NAME    ] := space(FLD_CONTAINER_DESC)
		aContainer[n, A_CONTAINER_SHORT_NAME   ] := space(FLD_CONTAINER_SHORT)
		aContainer[n, A_CONTAINER_TARE         ] := 0
		aContainer[n, A_CONTAINER_VALUE        ] := 0.00
		aContainer[n, A_CONTAINER_TYPE_IN_USE  ] := .f.
		aContainer[n, A_CONTAINER_TYPE_ON_FILE ] := .f.
	next

	if openfile({'Contain'},DB_SHARED)
		lReturn := .t.
		Contain->(dbGoTop())
		lReturn := .t.

      do while Contain->(lastRec()) < 10
         if !Contain->(AddRecord())
            exit
         else            
            Contain->container := Contain->(recno())

            // for South Alder - May 99
            cDesc := ''
            cShort := ''
            do case
            case n==1
               cDesc  := 'Partition Plastic Flat'
               cShort := 'PPFL'
            case n==2
               cDesc := 'NonPartition Plastic Flat'
               cShort := 'NPPFL'
            case n==3
               cDesc  := 'Blueberry Lugs'
               cShort := 'BBL'
            case n==4
               cDesc := 'Grey Heavy Lugs'
               cShort := 'GHL'
            case n==5
               cDesc  := 'Paper Flat w/ Basket'
               cShort := 'PFL-B'
            case n==6
               cDesc  := 'Foreign Flats'
               cShort := 'FFL'
            case n==7
               cDesc  := 'Plastic Flat Pallet'
               cShort := 'PLFP'
            case n==8
               cDesc  := 'Small Pallet'
               cShort := 'SP'
            case n==9
               cDesc := 'Generic 40x48 Pallet'
               cShort := '4048P'
            case n==10
               cDesc := 'Foreign pallet'
               cShort := 'FP'
            endcase
            Contain->desc  := cDesc
            Contain->short := cShort
            Contain->container := n

            if !empty(cDesc)
               Contain->inUse := .t.
            endif

            Contain->(dbCommit())
         endif
      enddo

      n := 0
      do while !Contain->(eof())
         do case
         case Contain->container > MAX_TYPES_CONTAINERS .or. ;
					Contain->container <= 0

				waitInfo({'Weird Container Types on File!'})
				if Contain->(recLock())
					Contain->(dbDelete())
				endif
         case Contain->container == n .and. n <> 0
               appError( APP_ERR_CONTAINER_DUPLICATE1, ;
                {'Duplicate container type '+lStrim(n), ;
                 'Please Fix Containers...'})

         case Contain->container > 0 .and. !Contain->(deleted()) .and. ;
					 Contain->container <= MAX_TYPES_CONTAINERS

            n := Contain->container

            if !empty(aContainer[n, A_CONTAINER_LONG_NAME    ]) .or. ;
               !empty(aContainer[n, A_CONTAINER_SHORT_NAME    ])
               appError( APP_ERR_CONTAINER_DUPLICATE2, ;
                {'Duplicate container type '+lStrim(n), ;
                 'Please Fix Containers...'})
            endif

				aContainer[n, A_CONTAINER_LONG_NAME    ] := Contain->desc
				aContainer[n, A_CONTAINER_SHORT_NAME   ] := Contain->short
				aContainer[n, A_CONTAINER_TARE         ] := Contain->tare
				aContainer[n, A_CONTAINER_VALUE        ] := Contain->value
				aContainer[n, A_CONTAINER_TYPE_IN_USE  ] := Contain->inuse
				aContainer[n, A_CONTAINER_TYPE_ON_FILE ] := .t.
         endcase

         n := Contain->container
			Contain->(dbSkip())
		enddo

		Contain->(dbCloseArea())
	endif

return( lReturn )


























