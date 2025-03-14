// Revised Feb 2020  & Jan 2021
//   Bill Hepler

#include "CIS_BMP.CH"
#include 'myarc.ch'
#include 'myver.ch'

VERSION
   "CompanyName"      = "Crafted Industrial Software Ltd."
   "FileDescription"  = "Crafted IS BerryPay Office XBase 2"
   "FileVersion"      = MYVER_THIS_VERSION
   "InternalName"     = "BerryPay"
   "LegalCopyright"   = "(c) 1991-2024 Bill Hepler & Crafted Industrial Software Ltd."
   "OriginalFileName" = "WinBerryPay.exe"
   "ProductName"      = "Crafted IS Berry Pay"
   "ProductVersion"   = MYVER_THIS_VERSION
   "Comments"         = "Crafted IS Software for Fruit Processors; (604)256-7485"
   "Author"           = "Bill Hepler"

// the First ICON is used as the Icon for the Program....
ICON
  ICON_MAIN_FOR_DESKTOP  = "MoneyInEnvelope.ICO"
  ICON_SMALL_FOR_APP_WIN = "DOLL_SM.ICO"  // 2nd one is For Window
  ICON_ALT_FOR_TESTING   = "MEDICAL_BAG.ICO"
  ICON_HISTORY_ARCHIVE   = "HISTORY.ICO"
  ICON_INDEX_ARCHIVE     = "INDEX.ICO"
  ICON_MONEY2            = "MONEY2.ICO"
  ICON_WALLET_CLOSED     = "WALLET_CLOSED.ICO"
  ICON_BLUEBERRY_2       = "BLUEBERRY_2.ICO"

// Must use actual BMP files - Windows weird ness..
BITMAP
  CIS_BMP_HI_RES_LOGO           = "C:\clp\Berry2\vWorkBBxb200\CIS-Logos102-mid1.BMP"
  CIS_BMP_MINI_LOGO             = "C:\clp\libXB200\lWork\CIS_BMP_MINI_LOGO.BMP"


