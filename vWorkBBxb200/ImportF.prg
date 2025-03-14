// Import Growers & maybe other things.
//
//  July 5, 2013
//
//  (c) July 5, 2013 by Bill Hepler
//  Noted July 22, 2014 - need to set up the structure of this file 
//   etc.

#include 'bsgstd.ch'
#include "printer.ch"
#include "indexord.ch"
#include "valid.ch"
#include 'field.ch'

function ImportGrowers( )
	local lOk := .f.
	local cTmp
	local nPage :=1

   if xxPassWord( 'BH Mom maiden inits', 'OAK', .F. )
      if xxPassWord( 'Bills Dog?',"BROWNIE", .f. )
         lOk := .t.
      endif
   endif


	if openFile({'Grower'},DB_EXCLUSIVE) .and. lOk
		if !file('GRO_F_SC.DBF')
			WaitInfo({'Can NOT find GRO_F_SC.DBF in current Directory.  This', ;
			          'file must be created by Crafted Industrial Software Ltd.!'})
		else	
			use GRO_F_SC exclusive NEW		
			if yesno({'Do you wish to Import Grower File from Scale?'})
				GRO_F_SC->(dbGoTop())
				
				if selectPrn('GROW_IMP.TXT')
				
					PRINT_ON  RPT_OVERWRITE
					nuQprnOut('Grower Import...'+shMdy( date())+'   '+time()+ '  '+str(nPage,3) )
					nPage++
					nuQprnOut('')
					
					do while !GRO_F_SC->(eof())
						if empty( Gro_F_Sc->cheqname)
							nuQprnOut('Empty Grower / NOT ADDED! ...'+str(Gro_F_Sc->number,FLD_GROWER) )
						else
							if ValidTest( V_GROWER, Gro_F_Sc->number, VT_NO_MESSAGE )
								nuQprnOut('Grower already on File...'+str(Gro_F_Sc->number,FLD_GROWER) )
							else
								Grower->(AddRecord())
								
								Grower->number    := Gro_F_SC->number
								Grower->CheqName  := Gro_F_SC->CheqName
								Grower->Name      := Gro_F_SC->CheqName
								Grower->street    := Gro_F_SC->street
								Grower->city      := Gro_F_Sc->city

								cTmp              := upper( strTran(Gro_F_Sc->prov,'.','') )
								if len(alltrim(cTmp)) <> 2
									nuQprnOut('Grower '+str(Gro_F_Sc->number,FLD_GROWER)+' has odd province' )
								endif
								Grower->Prov      := cTmp
								
								Grower->pCode     := upper( Gro_F_sc->pCode )
								Grower->alt_name1 := Gro_F_sc->alt_name1
								Grower->phone     := Gro_F_sc->phone
								Grower->fax       := Gro_F_sc->fax
								
								Grower->Alt_phone1 := Gro_F_sc->alt_phone1
			
								nuQPrnOut(' Grower '+lstrim(Grower->number)+' added normally')
							endif
						endif
						if NearPageBottom( 10 )
							nuFormFeed( )
							nuQprnOut('Grower Import...'+shMdy( date())+'   '+time()+ '  '+str(nPage,3) )
							nuQprnOut('')													
							nPage++
						endif

						GRO_F_SC->(dbSKip())
					enddo
					nuQprnOut('')	
					nuQprnOut('End of report')
					PRINT_OFF RPT_COMPLETE_EJECT

				endif
			endif		
		endif
	endif
	
	close databases

return( nil )
