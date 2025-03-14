// ----------------------------------------------------------------------------
//  Application: Berry Payment System
//  Description: Version of Program - Specific to each Application
//     File Name: MyVER.PRG
//        Author: Bill Hepler
//  Date created: 05-06-96
//  Time created: 02:47:11pm
//    Updated:    Sep 25, 2012 - aesthetic
//     Copyright: (c) 1996, 2012, 2018, 2019 by Bill Hepler
// ------------------------------------------------------------------------------

#include 'version.ch'
#include 'myver.ch'

function MyVersion()
	local aVer[ V_VERSION_ARRAY_SIZE ]

   aVer[ V_VERSION       ]       := MYVER_THIS_VERSION
   aVer[ V_CLIENT        ]       := MYVER_CLIENT
   aVer[ V_PROGRAM_NAME  ]       := MYVER_NAME
   aVer[ V_SHORT_NAME    ]       := MYVER_SHORT_NAME
   aVer[ V_REVISION_DATE ]       := MYVER_REV_DATE

	aVer[ V_PRG_REV_COMPILE_DATE_TIME ] := __DATE__ +'-' + strTran( __TIME__, ":","")
	
	aVer[ V_SHOW_SCALE_REV_DATE ] := 'N'    // do not show Scale Rev Date.

return( aVer )

