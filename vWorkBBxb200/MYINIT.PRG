//---------------------------------------------------------------------------
//   Application: Berry Pay
//   Description: Initialize for this program
//     File Name: MYINIT.PRG
//        Author: Bill Hepler
//
//      June 6-2010 - pulled from Waste Management
//      Sep 26, 2012 - minor mods
//      July 3, 2013 - Library
//      July 9, 2018 - Library version etc.
//      Aug 13, 2018 - Libray version etc.
//
//  Date created: 05-22-96
//  Time created: 06:40:12pm
//  Copyright: (c) 1996, 2013, 2016, 2017, 2018 by Bill Hepler
//---------------------------------------------------------------------------

#include  'inkey.ch'
#include  'sysvalue.ch'
#include  'bsgstd.ch'
#include  'indexord.ch'
#include  "BerryPay.ch"
#include  'myarc.ch'
#include  'w32page.ch'
#include  "PRINTER.CH"
#include  "version.ch"

Function MyInit(  )
	local lReturn := .f.
   local nCol := 110
   local cPath
   local oCrt

   @ maxrow(),0 say 'Starting up....'
   oCrt := SetAppWindow()
   oCrt:icon := ICON_SMALL_FOR_APP_WIN

   // ShowErrDlg( .t. )   // Show Dialog boxes for errors to User

   if swVersionAsNum( VER_TELL_LIBRARY_VER ) < MINIMUM_LIB_VERSION
      AlertMe( ;
      'The version of CISltd200.DLL must be at least '+var2char( MINIMUM_LIB_VERSION ) + ;
      ';Your version is '+ var2char(swVersionAsNum( VER_TELL_LIBRARY_VER )) + ';We will QUIT now!' )
      close databases
      return( lReturn )
   endif

   if !file('bsgColor.dbf')
      if !file('bsgColor.dbf')
         cPath := CurDirectory()
			
         MsgBox('We can NOT find the file BSGCOLOR.DBF in directory:' + CR_LF + ;
             '  '+cPath + CR_LF + ;
             'This can mean that:' + CR_LF + ;
             '-The ICON used to start this program points to the wrong'+CR_LF+ ;
             ' data directory'+CR_LF+ ;
             '-- or --' + CR_LF + ;
             '-If you are on a NetWork-it can mean that the Network Drive'+CR_LF+ ;
             ' you are accessing is not available.' + CR_LF + CR_LF + ;
             'WE WILL QUIT NOW!')

         if upper( CurDirectory()) $ upper( ThisExeDirectory())
            msgBox('Perhaps you are trying to run the EXE directly from'+CR_LF+ ;
             'Windows Explorer - this usually will not work, you should'+CR_LF+ ;
             'be running the program from an ICON.' )
         endif

         lReturn := .f.
      endif
   endif

   InitDictionary( InitMyData() )
   set century ON

	if init_CIS_std()
      setKey( K_ALT_C, {|| nil } )
      setkey(K_ALT_I,{|| ShowLogo( MyVersion() ) })

      // InitDictionary( InitMyData() )
		if InitSysValue( InitMySysValue() )
	      if str( sysValue( SYS_DEFAULT_RPT_LINE_HEIGHT ), 3,1)=='0.0'
            gRptSetDefaLineHt( W32_LINE_HEIGHT_MULTIPLIER  , 1 )
         else
            gRptSetDefaLineHt( W32_LINE_HEIGHT_LPI , sysValue( SYS_DEFAULT_RPT_LINE_HEIGHT ) )
         endif

         nCol := sysValue( SYS_GENERALLY_SWITCH_TO_LANDSCAPE )
         if nCol > 81 .and. nCol < 200
            gRptSetWhen2LandScape( nCol )
         else
            gRptSetWhen2LandScape( 0 )
         endif

         if InitPrinter( PRINTER_INIT_FROM_TABLE )
            set epoch to 2000

            ConvertData()

            SetStnCrtIniDir( sysValue( SYS_OWN_DIRECTORY  ) )
            if !SetCrtFont()
               WaitInfo({'Did you know that you may configure', ;
                  'the Fonts for the Display?', ;
                  'This is under Screen Configuration', ;
                  'in the Configuration Menu'})
            endif

            Alt_R_instruction('see Configure Menu / Screen Options / Fonts')
            setKey( K_ALT_R, {|| Alt_ReDrawScrn() } )
            lReturn := .t.
            InitTaxes()
         endif
    	endif
   endif
return( lReturn )

