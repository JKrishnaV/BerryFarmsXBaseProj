// Menus
// (c) Copyright 1994, 2012, 2014, 2019, 2020 by Bill Hepler
//     2014, 2019 for GST etc, minor fix ups etc.
//  May 2020  -  Revised a bit because we added some more reports
//  Nov 2021  -  Minor changes to Row & Column of Menus to be more consistant

#include 'BerryPay.ch'
#include 'berry_rpt.ch'
#include 'custpaid.ch'
#include 'signon.ch'
#include "sysvalue.ch"
#include 'version.ch'
#include 'xbp.ch'


function BerryMenus()
	local nChoice := 1, lCont := .t.
	local aScr

	aScr := save_scr()

	do while lCont
		close databases

		do case
		case !empty( sysValue( SYS_ARCHIVE_DATA_YEAR ))
			myBsgScreen( TheClientName( ) +' '+ sysValue( SYS_ARCHIVE_DATA_YEAR )   )
		otherwise
			myBsgScreen( TheClientName( )  )
		endcase

		if !HasCustPaid4SW( )
			exit
		endif

		nChoice := NiceMenu(nChoice,'Master Menu', 3, 5, { ;
		 { '1. Daily & Weekly Operations   ','Menu for daily & weekly tasks...'}, ;
		 { '2. Grower Information          ','View/Edit Grower Address and Transactions...'}, ;
		 { '3. Season End & Special Options','Menu for Season End Payments, Statements, Voiding Cheques ...'}, ;
		 { '4. Reports                     ','Menu for Reports....'}, ;
		 { '5. File Housekeeping           ','Menu for Prices, Products, etc...'}, ;
		 { '6. Housekeeping                ','Menu for Housekeeping utilities...'}, ;
		 { 'Q. Quit                        ','Exit this program and return to DOS'}})

		begin sequence
		do case
		 case nChoice == 1
			DailyMenu()
		 case nChoice == 2
			Grower()
		 case nChoice == 3
			SpecialMenu()
		 case nChoice == 4
			ReportMenu()
		 case nChoice == 5
			FileMenu()
		 case nChoice == 6
			HouseMenu()
		 otherwise
			if yesno({'Exit this system?'})
				lCont := .f.
			endif
		endcase

		end sequence
		rest_scr(aScr)
	enddo

return( nil )


static function DailyMenu()
	local nChoice:=1 , lCont := .t.
	local aScr

	aScr := save_scr()

	do while lCont
		close databases

		if !HasCustPaid4SW( )
			exit
		endif

		nChoice := NiceMenu(nChoice,'Daily/Weekly Operations', 5, 9, { ;
		 { '1. Load Receipts         ','Load Receipts from Disks'}, ;
		 { '2. Add/Edit Receipts     ','Manually Input/view/change load receipts'}, ;
		 { '3. Receipts by Number    ','View/Change Load Receipts by Receipt #'}, ;
		 { '4. Edit Receipt Prices   ','Edit Prices for Receipts'}, ;
		 { '5. 1st Advance Payment   ','Produce cheques for First (primary) Advance'}, ;
		 { '6. 2nd Advance Payment   ','Produce cheques for Seconard (secondary) Advance'}, ;
		 { '7. 3rd Advance Payment   ','Produce cheques for Third (tertiary) Advance'}, ;
		 { '8. Advance Statements    ', ;
		 'Produce statements for Advances & Final cheque run'}, ;
		 { '9. All Advance Statements', ;
		 'Produce any type of Weekly/Advance statements for Advances & Final cheque run'}                    })

		begin sequence

		do case
		 case nChoice==1
		 	ImportScaTicks()
		 case nChoice==2
			EditReceipt(  )
		 case nChoice==3
			ReceiptByNo(  )
		 case nChoice==4
			QedDailyPrice( )
		 case nChoice==5
			weeklyAdvancePay(1)
		 case nChoice==6
			weeklyAdvancePay(2)
		 case nChoice==7
			weeklyAdvancePay(3)
		 case nChoice==8
			StatementDo( GRO_STATEMENT_FOR_WEEKLY, SysValue( SYS_WEEK_STATEMENT_DEFAULT_FORMAT ) )
		 case nChoice==9
			AllWeekStatements()
		 otherwise
		 	lCont := .f.
		endcase

		end sequence

		close databases // July 2019 just in case
		sleep( 2 )     //  ditto

		rest_scr(aScr)
	enddo
return( nil )

static function ReportMenu()
	local nChoice:=1 , lCont := .t.
	local aScr

	aScr := save_scr()

	do while lCont
		close databases

		nChoice := NiceMenu( nChoice,'Reports Menu', 5, 9, { ;
		 { '1. Summary Reports...     ','Various Summaries of Transactions'      }, ;
		 { '2. File Listings...       ','Listings of Growers, Prices, and so on' }, ;
		 { '3. Transaction Details... ','Various Listings of Ticket Details'     }, ;
		 { '4. Financial Details...   ', ;
			'Cheque Registers, Grower Ledgers, Financial Reports'                 }, ;
		 { '5. Audit & Diagnostics... ', ;
			'Audit and Diagnostic Reports - intended to look at errors & anomolies' } })

		begin sequence

		do case
		case nChoice==1
			RptMSumm()
		case nChoice==2
			RptMfileList()
		case nChoice==3
			RptMtrans()
		case nChoice==4
			RptMfinance()
		case nChoice==5
			Audit_Diag_Menu()
		otherwise
		 	lCont := .f.
		endcase

		end sequence
		rest_scr(aScr)
	enddo
return( nil )

static function RptMSumm()
	local nChoice:=1 , lCont := .t.
	local aScr

	aScr := save_scr()

	do while lCont
		close databases

		nChoice := NiceMenu(nChoice,'Summary Reports Menu', 7, 13, { ;
		 { '1. Production Report   ','Show Production to Date'}, ;
		 { '2. Management Summary  ', ;
		  'Shows production for a given period & year to date'}, ;
		 { '3. 3 - Year Average    ','Summary of Production by Grower for past 3 years'}, ;
		 { '4. Process Class       ','Summary for each Process Class by Grower'}, ;
		 { '5. By Day Summaries    ','Several forms of Production for each day'}, ;
		 { '6. Container Summary   ', ;
		  'Summary of Container Receipts/Shipments-including Hash Total Info'}, ;
		 { '7. Receipt Continuity  ', ;
		  'Checks whether receipts are continous'}, ;
		 { '8. Posted Transactions ', ;
		  'Posted Transaction Reports - similar to Ledger for Grower'}, ;
		 { '9. Varieties Report    ', ;
		  'Shows Receipts of Varieties (if using this feature)'} })

		begin sequence

		do case
		case nChoice==1
			ProdYTD()
		case nChoice==2
			MangmtProSumRpt()
		case nChoice==3
			GrowerSum(  REP_3_YEAR    )
		case nChoice==4
			GrowerSum(  REP_PROCESS_CLASS     )
		case nChoice==5
			byDaySum()
		case nChoice==6
			ContainSum()
		case nChoice==7
			RecptSum()
		case nChoice==8
			PostSummary()
		case nChoice==9
			VarietyReport( )
		otherwise
		 	lCont := .f.
		endcase

		end sequence
		rest_scr(aScr)
	enddo
return( nil )

static function RptMfileList()
	local nChoice:=1 , lCont := .t., aScr

	aScr := save_scr()

	do while lCont
		close databases

		nChoice := NiceMenu(nChoice,'Listings Menu', 7,13, { ;
		 { '1. Grower List/Labels   ', ;
			'Print General List of Growers, or Mailing Labels'}, ;
		 { '2. Growers On Hold      ','Show Growers On Hold'}, ;
		 { '3. Growers by PayGroup  ','List Growers by Pay Group'}, ;
		 { '4. Price List           ','Listing of Prices'}, ;
		 { '5. Import Batches       ','Listing of Import Batches' }, ;
		 { '6. Products             ','List of Products' }, ;
		 { '7. Processes            ','List of Processes (e.g. FResh, Juice etc' }, ;
		 { '8. Containers/Pallets   ','List of Containers & Pallets' }, ;
		 { '9. Configurations       ','General System Settings - Program Configuration' } ;
							})

		begin sequence

		do case
		case nChoice==1
		 	growerList_1()
		case nChoice==2
			growerLists_2( .t. )
		case nChoice==3
			growerLists_2( .f. )
		case nChoice==4
			PricePrint( )
		case nChoice==5
			AllImpBatList()
		case nChoice==6
			ProductList()
		case nChoice==7
			ProcessList()
		case nChoice==8
			ContainerList()
		case nChoice==9
			PrintSysValue( SysGroups(), NIL )
		otherwise
		 	lCont := .f.
		endcase

		end sequence
		rest_scr(aScr)
	enddo
return( nil )

static function RptMtrans()
	local nChoice:=1 , lCont := .t., aScr

	aScr := save_scr()

	do while lCont
		close databases

		nChoice := NiceMenu(nChoice,'Transaction Detail Reports', 7, 13, { ;
		 { '1. Daily Audit Report            ', ;
		  'List Production sorted by date for all or a single grower'}, ;
		 { '2. Weekly Audit Report           ', ;
		  'List Production sorted by grower (similar to #3 above)'}, ;
		 { '3. Product Audit Listing         ', ;
		  'Unposted Transactions Listed by Product'} , ;
		 { '4. Container Audit List          ', ;
		  'Unposted, Posted or Both Types of Receipts Listed by Grower'} , ;
		 { '5. Single Container Audit        ', ;
		  'Listing of Receipts for a Single Container Type'} , ;
		 { '6. Grower Transactions #1        ', ;
		  'Lists receipts for a Grower in Format # 1' }, ;
		 { '7. Grower Transactions #2        ', ;
		  'Lists receipts for a Grower in Format # 2' }, ;
		 { '8. Dockage Audit Report          ', ;
		  'Lists receipts that may have Dockage on them' }, ;
		 { '9. Receipts from an Import Batch ', ;
		  'Lists the receipts in an Import Batch (imported from Scale)' } , ;
		 { 'A. Special Receipt Audit         ', ;
		  'List Production (reciepts) and select which to show' }, ;
		 { 'B. Receipts from a specific Field', ;
		  'List receipts from a specific field' } })

		begin sequence

		do case
		case nChoice==1
		 	dailyAudit( RP_DAILY_AUDIT )               // .t. )
		case nChoice==2
			dailyAudit( RP_WEEKLY_AUDIT )              // .f. )
		case nChoice==3
			ProdAudit( )
		case nChoice==4
			ContAudit( )
		case nChoice==5
			OneCont( )
		case nChoice==6
			GrowRecRpt( REP_GROWER_1 )
		case nChoice==7
			GrowRecRpt( REP_GROWER_2 )
		case nChoice==8
			DockAudit()
		case nChoice==9
			BatchAudit( )
		case nChoice==10
		 	dailyAudit( RP_ALTERNATE_1_AUDIT  )
		case nChoice==11                         // corrected
		 	FromFldRpt( RP_FROM_FIELD_AUDIT1 )

		otherwise
		 	lCont := .f.
		endcase

		end sequence
		rest_scr(aScr)
	enddo
return( nil )

static function RptMfinance()
	local nChoice:=1 , lCont := .t., aScr

	aScr := save_scr()

	do while lCont
		close databases

		nChoice := NiceMenu(nChoice,'Financial Reports Menu', 7, 13, { ;
		 { '1. Cheque Registers       ', ;
		  'Print Cheque Registers, Cheque Audit Trail'}, ;
		 { '2. Ledger for Growers     ', ;
		  'Print Grower Ledger, and Audit Trails'}, ;
		 { '3. Posted Transactions    ', ;
		  'Posted Transaction Reports - similar to Ledger for Grower'}, ;
		 { '4. Grower A/P Report #1   ', ;
		  'Accounts Payable - to show expected pay runs - Format #1'}, ;
		 { '5. Grower A/P Report #2   ', ;
		  'Accounts Payable - to show expected pay runs - Format #2'}, ;
		 { '6. Price Audit Report     ', ;
		  'Lists Prices on Receipts - intended to Audit for Errors' }, ;
		 { '7. Account Summary        ', ;
		  'Accounting Ledgers - summaries of grower financial transactions' }, ;
		 { '8. GST Tax Ledgers        ', ;
		  'Accounting Ledgers - oriented to Taxes - summary transactions' }, ;
		 { '9. Advance Statements     ', ;
		  'Advance Statements (also in Weekly Menu)' }, ;
       { 'A. Year End Statements    ', ;
		  'Year End Statements (also in Special/Season End Menu)' }, ;
       { 'B. Check Keyed Prices     ', ;
		  'Lists Keyed Prices on Receipts - intended to Audit for Errors' } })

		begin sequence

		do case
		case nChoice==1
		 	ChequeRegister()
		case nChoice==2
		 	AcctRegister()
		case nChoice==3
			PostSummary()     // Duplicated....
		case nChoice==4
			Grow_Ap( RP_GROW_AP01 )
		case nChoice==5
			Grow_Ap( RP_GROW_AP02 )
		case nChoice==6
			PriceAudit()
		case nChoice==7
			AcctLedger( )
		case nChoice==8
			Acc_rpt()
		case nChoice==9
		 	AllWeekStatements()
		case nChoice==10
		 	AllCropStatements()
      case nChoice==11
      	CheckKeyPrice()
		otherwise
		 	lCont := .f.
		endcase

		end sequence
		rest_scr(aScr)
	enddo
return( nil )

static function SpecialMenu()

	local nChoice:=1 , lCont := .t., aScr

	aScr := Save_Scr()

	do while lCont
		close databases

      // Note this menu was changed in 2021, especially to make the VOID more understandable!

		nChoice := NiceMenu(nChoice,'Special/Season End Menu', 5, 9, { ;
			 { '1. Final Crop Payments            ','Produce the Final cheque run for a crop'}             , ;
			 { '2. Make a Special Payment         ','Produce Post Season Special Payments and Deductions'} , ;
			 { '3. Final (Crop Year) Statement    ','Produce the Your Default version of a (Year End) Crop Payment Statement'}, ;
			 { '4. Any format of Final Statement  ','Produce any format of Final (Crop Year) Payment Statement'}              , ;
			 { '5. Reconcile Cheque Book          ','Reconcile your grower bank statement'}                 , ;
          { '6. Cheque Actions Menu...         ','Issue an Advance, Void, re-issue, zap out a cheque!'}  , ;
			 { '7. Corrective Advance 1           ','Special Correction for Advance 1 - call BILL first !'} , ;
			 { '8. Corrective Advance 2 wbf       ','Special Correction for Advance 2 - call BILL first !'} , ;
			 { '9. Corrects Advances 3            ','Special Correction for Mangled Advances - call BILL first !'}   ;
			   })

		begin sequence
		do case
		case nChoice==1
			finalPay()
		case nChoice==2
		 	spPay()
		case nChoice==3
			StatementDo( GRO_STATEMENT_FOR_CROPYEAR, sysValue( SYS_CROPYEAR_STATEMENT_DEFAULT_FORMAT ) )
		case nChoice==4
			AllCropStatements()
		case nChoice==5
			CheqReconcile()       // I'm not sure if anyone is using that.
      case nChoice==6
			DealWithCheqMenu()    // this is new
		case nChoice==7
			if YesNo({'Did you call Bill first?'})
				if xxPassWord( 'Egberts friend', 'FARKLE', .F. )
		      	Weekly_SpecFix( 1 )
				endif
			endif
      case nChoice==8
			if YesNo({'Did you call Bill first?'})
	      	if alltrim(soValue( SO_INIT ))=='BH'
					if xxPassWord( 'BH Mom maiden inits', 'OAK', .F. )
			      	WestBerry121( )
         	   endif
            endif
         endif

      case nChoice==9
			if YesNo({'Did you call Bill first for this?', ;
                   'This lets you REVERSE out Accounts Payables'})
	      	if alltrim(soValue( SO_INIT ))=='BH'
					if xxPassWord( 'BH Mom maiden inits', 'OAK', .F. )
			      	WestBerry122( )
         	   endif
            endif
         endif

		otherwise
		 	lCont := .f.
		endcase
		end sequence

		rest_scr(aScr)
	enddo
return( nil )

// New in 2021 - all these menu items were tested and modified in minor ways.
static function DealWithCheqMenu()

	local nChoice:=1 , lCont := .t., aScr

	aScr := Save_Scr()

	do while lCont
		close databases

		nChoice := NiceMenu(nChoice,'Deal with Cheques Menu', 7, 13, { ;
			 { '1. Reissue a Cheque               ','Void an old cheque and reissue the cheque for the same amount'}, ;
          { '2. Loan Cheques (manual advances) ','Make up an advance cheque (a loan!) for a certain amount to a Grower'}, ;
			 { '3. Void Cheques - Leave the A/P   ','Void a Cheque but do NOT change the related voucher and ticket records-see HELP on this!'}, ;
			 { '4. Void Cheque - Reverse A/P      ','Voids a cheque and removes the A/P calculations-can later pay out at new rate!'}, ;
			 { '5. Help for the Cheque Menu       ','Explains what each of these options do !'}  ;
			   })

		begin sequence
		do case
		case nChoice==1
			ReissueCheque()
		case nChoice==2
			LoanChq()
		case nChoice==3
			VoidChequeLeaveAP()
		case nChoice==4
			VoidChequeDeleteAP()
		case nChoice==5
			ChequeExplainer()
		otherwise
		 	lCont := .f.
		endcase
		end sequence

		rest_scr(aScr)
	enddo
return( nil )

static function HouseMenu()

	local nChoice:=1 , lCont := .t., aScr

	aScr := Save_Scr()

	do while lCont
		close databases

		nChoice := NiceMenu(nChoice,'General Housekeeping Menu', 5, 9, { ;
		 { '1. Reindex Files                  ','Reindex Data Files'},                    ;
		 { '2. System Settings (configuration)','Edit Miscellaneous System Information'}, ;
		 { '3. Printer Configure              ','Configuration of Printers'},             ;
		 { '4. Colours for Screen             ','Set Colours (only for system administrator'}, ;
		 { '5. Purge Old Data                 ','Delete old data for year beginning'},         ;
		 { '6. Daily File Unique Updater      ','Updates Unique ID in Daily File - for BH only!'},          ;
		 { '7. Reset Keyed Prices             ','Reset unposted keyed prices to Defaults'},    ;
		 { '8. View Posted Data               ', ;
			'View Daily Receipt Transactions (for systems administrator)'},      ;
		 { '9. Make Quick Backup              '                               , ;
			'Make a Quick Backup of Data - usually to Flash Drive'}       , ;
		 { 'A. Test Cheque Printing           ', 'Print a Sample Cheque...'}       , ;
		 { 'B. Set Screen Fonts               ', 'Choose a font for screen'}       , ;
		 { 'C. Unpost all payments            ', 'Unpost ALL Payments (BH only!)'} , ;
		 { 'D. Look at User Table             ', 'Audit Report on Users (BH only!)'} })

		 // { '9. Test HP Printer      ', ;
		 //   'Test HP Printer for Font Selection (for Cheques)...'}, ;


		begin sequence

		do case
		case nChoice==1
		 	What2Reindex()
		case nChoice==2
		 	EditSysValue(  SysGroups() )
		case nChoice==3
			PrinterUsers()
		case nChoice==4
		 	ColorSetUp()
		case nChoice==5
			PurgeData()
		case nChoice==6
			if xxPassword( 'this CRITICAL function','CRIT',.t.)
				// DailyFixerOld() - old ONE obsolete
				DailyFixerUniq()
			endif
		case nChoice==7
			ReSetTickPrice()
		case nChoice==8
			dbEdit2( .f., 'DAILY')

		// case nChoice==9           we now use WINDOWS fonts
		//    hpTestFontSets()

		case nChoice==9
			//        QuikBackUp( sysValue( SYS_OWN_DIRECTORY ),'', .f. )
			QuikBackUp( sysValue( SYS_OWN_DIRECTORY ),  ;
							sysValue( SYS_FOLDER_TO_BACKUP_INTO ), ;
							sysValue( SYS_FOLDER_BACKUP_BU1_2 ) , ;
				'Defaults for this are in your System Settings.', ;
							sysValue( SYS_TRY_ROBOCOPY_FOR_QBU ) )

		case nChoice==10
			TestChequeFormat( )
		case nChoice==11
			UIsetFonts( )
		case nChoice==12
			if alltrim(soValue( SO_INIT ))=='BH'                           .or. ;
			   alltrim(soValue( SO_INIT ))=='VBH'                          .or. ;
			   alltrim(soValue( SO_INIT ))== OLD_SCHOOL_ADMIN_USER         .or. ;
				alltrim(soValue( SO_INIT ))==CRAFTED_INDUSTRIAL_ADMIN_USER1 .or. ;
				alltrim(soValue( SO_INIT ))==CRAFTED_INDUSTRIAL_ADMIN_USER2

				if xxPassword( 'this CRITICAL DeBug function','CRIT',.t.)
					UnPostIt( )
				endif
			else
				WaitInfo({'You can not do this! Gotta be Bill'})
			endif

		case nChoice==13
			if alltrim(soValue( SO_INIT ))=='BH'                            .or. ;
			   alltrim(soValue( SO_INIT ))=='VBH'                           .or. ;
			   alltrim(soValue( SO_INIT ))== OLD_SCHOOL_ADMIN_USER          .or. ;
				alltrim(soValue( SO_INIT ))== CRAFTED_INDUSTRIAL_ADMIN_USER1 .or. ;
				alltrim(soValue( SO_INIT ))== CRAFTED_INDUSTRIAL_ADMIN_USER2

				if xxPassword( 'this CRITICAL DeBug function','CRIT',.t.)
					PassWordPrinter()
				endif
				BrowseUser()
			else
				WaitInfo({'You can not Print this Audit!  Gotta be Bill'})
				BrowseUser()
			endif

		otherwise
		 	lCont := .f.
		endcase

		end sequence
		rest_scr(aScr)
	enddo
return( nil )

static function FileMenu()

	local nChoice:=1 , lCont := .t., aScr

	aScr := Save_Scr()

	do while lCont
		close databases

		nChoice := NiceMenu(nChoice,'File Housekeeping Menu', 5, 9, { ;
		 { '1. Set Prices           ','Sets Prices by Date for Berries'}, ;
		 { '2. Types of Containers  ','Set the Types of containers'}, ;
		 { '3. Payment Groups       ','Make Payment Groups for Growers'}, ;
		 { '4. Products             ','Set the Products (Berries) you purchase'}, ;
		 { '5. Processes            ','Set the Produces Types Used'}, ;
		 { '6. Cheque Format        ','Cheque Format (for NIFTY CHEQUE Format'}, ;
		 { '7. Users of the System  ','Setup authorized users of the system'}, ;
		 { '8. Change your PassWord ','Change YOUR password'}, ;
		 { '9. Edit any Record      ','For Crafted Industrial Software Ltd ONLY'}, ;
		 { 'A. Depot Setup          ','Setup Depots - esp for Multi Depot Systems !!!'}, ;
		 { 'B. Import Growers       ','For Crafted Industrial Software ONLY  !!!'}, ;
		 { 'C. Varieties of Fruit   ','Sets Varieties of Fruit for Reporting'}, ;
		 { 'D. Edit Tax Rates       ','Set Tax Rates'} })

		begin sequence

		do case
		case nChoice==1
		 	Pricing()
		case nChoice==2
			Container()
		case nChoice==3
			PayGrp()
		case nChoice==4
			Product()
		case nChoice==5
			Process()
		case nChoice==6
			ChqFmtEdit( .t. )
		case nChoice==7
			BrowseUser( .t., {'A - Anything'} )
		case nChoice==8
			NewPassword()
		case nChoice==9
			if alltrim(soValue( SO_INIT ))=='BH'                            .or. ;
			   alltrim(soValue( SO_INIT ))=='VBH'                           .or. ;
			   alltrim(soValue( SO_INIT ))== OLD_SCHOOL_ADMIN_USER          .or. ;
				alltrim(soValue( SO_INIT ))== CRAFTED_INDUSTRIAL_ADMIN_USER1 .or. ;
				alltrim(soValue( SO_INIT ))== CRAFTED_INDUSTRIAL_ADMIN_USER2

				ViewAnyRecord()
			else
				WaitInfo({'No you can not do this!'})
			endif

		case nChoice==10
			DepotSetup()

		case nChoice==11
			ImportGrowers()

		case nChoice==12
			Varieties()

		case nChoice==13
			AddEditTaxes( )

		otherwise
		 	lCont := .f.
		endcase

		end sequence
		rest_scr(aScr)
	enddo
return( nil )


static function AllCropStatements()
	local nChoice
	local aScr
	local aRay
	local lCont := .t.

	aScr    := save_scr()
	nChoice := sysValue( SYS_CROPYEAR_STATEMENT_DEFAULT_FORMAT )

	do while lCont
		aRay := {}
		aRay := StatementMnuTxtArr( GRO_STATEMENT_FOR_CROPYEAR )
		close databases

		nChoice := NiceMenu(nChoice,'Crop Year (Year End) Statements', 7, 11, aRay )

		begin sequence

		if  nChoice >= 1 .and. nChoice <= len(aRay)
			StatementDo( GRO_STATEMENT_FOR_CROPYEAR, nChoice )
		else
			lCont := .f.
		endif

		end sequence

		rest_scr(aScr)
	enddo

return( nil )

static function AllWeekStatements()
	local nChoice:=1
	local aScr
	local aRay
	local lCont := .t.

	aScr := save_scr()
	nChoice := sysValue( SYS_WEEK_STATEMENT_DEFAULT_FORMAT )

	do while lCont
		aRay := {}
		aRay := StatementMnuTxtArr( GRO_STATEMENT_FOR_WEEKLY )
		close databases

		nChoice := NiceMenu(nChoice,'Weekly (Regular Advance) Statements', 8, 12, aRay  )

		begin sequence

		if  nChoice >= 1 .and. nChoice <= len(aRay)
			StatementDo( GRO_STATEMENT_FOR_WEEKLY, nChoice )
		else
			lCont := .f.
		endif

		end sequence

		rest_scr(aScr)
	enddo
	close databases

return( nil )


static function Audit_Diag_Menu()
	local nChoice:=1 , lCont := .t.
	local aScr

	aScr := save_scr()

	do while lCont
		close databases

		nChoice := NiceMenu( nChoice,'Audit/Diagnostic Menu', 7, 13, { ;
		 { '1. General Diagnostic          ', ;
			'Special Diagnostic Report'                                              }, ;
		 { '2. Date Diagnostics            ', ;
			'Special Diagnostic Report'                                              }, ;
		 { '3. Event Audit Log             ', ;
			'Events Log 2020 and forward-Cheque Runs Imports etc.'                   }, ;
		 { '4. List Voided Receipts        ', ;
			'Lists Voided Receipts (can include receipts voided at scale!)'          }, ;
		 { '5. View Receipt Audit Trail    ', ;
			'View & report on Receipt Audit Trail-shows SOME changes to receipts'    }, ;
		 { '6. Check for Payment Weirdness ', ;
			'Checks for Certain types of Payment Glitches-pretty slow-check w/ Bill' }, ;
		 { '7. Software Version Information', ;
			'Software Version Information Screen' } } )

		begin sequence

		do case
		case nChoice==1
			DiagnoseRpt()
		case nChoice==2
			DateErrorRpt()
		case nChoice==3
			TheEventsList()
		case nChoice==4
			VoidRpt()
		case nChoice==5
			vuRecptAudit()
      case nChoice==6
      	DiagLinkageRpt()
      case nChoice==7
      	ShowLogo( MyVersion() )
		otherwise
		 	lCont := .f.
		endcase

		end sequence
		rest_scr(aScr)
	enddo
return( nil )

