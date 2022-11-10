** Parameter für die ausgabe von Reports über cr4dotnet mit Crystal Reports
   PRIVATE cReport,aparameter, cRDatei, cRLAusgabe, cRTitel, nRKopien, bDruckerwahl, bPDFAnzeige, cDrucker, bPDFRepTmp, nRKopienAbSeite, nRAbSeite
   PARAMETERS cReport, aparameter, cRDatei, cRLAusgabe, cRTitel, nRKopien, bDruckerwahl, bPDFAnzeige, cDrucker, bPDFRepTmp, nRKopienAbSeite, nRAbSeite

// cReport = Reportname
// aParameter = Array [n,2] mit Parametern {"PARAMETERNAME","PARAMETERWERT"}
// cRDatei = PDF-Ausgabedatei
// cRLAusgabe = AUsgabe 
// 						 "A" = Report nur anzeigen (default)
//							 "M" = Anzeigen Modal
//							 "P" = Export als PDF 
//							 "E" = Excel
//							 "W" = Word
//							 "H" = HTML
//							 "R" = RTF
// 						 "D" = Drucken
//  						 "DA" = Drucken und Anzeigen
//  						 "DP" = Drucken und Export als PDF
//  						 "DE" = Drucken und Export als Excel
//							 "DW" = Drucken und Export als Word
//							 "DH" = Drucken und HTML
//							 "DR" = Drucken und RTF
//  						 "AP" = Anzeigen und Export als PDF
//  						 "AE" = Anzeigen und Export als Excel
//							 "AW" = Anzeigen und Export als Word
//							 "AH" = Anzeigen und HTML
//							 "AR" = Anzeigen und RTF
//								
// cRTitel = ReportTitel
// nRKopien = Anzahl Ausdrucke
// bDruckerwahl = Auswahl des Druckers vor dem Druck anzeigen (default = false)
// bPDFAnzeige = Anzeige der PDF nach Export
// cDrucker = Vorgabedrucker 
// bPDFRepTmp = wenn true, dann Reports in temporärem Verzeichnis speichern, das täglich aufgeräumt wird


	IF EMPTY(cReport)
   	cReport = ""
		return
   ENDIF
	IF EMPTY(cRLAusgabe)
		cRLAusgabe = "A"
	ENDIF
	IF EMPTY(aParameter)
		aParameter = NEW ARRAY(1,2)
		aParameter.fill("")
	ENDIF
	IF EMPTY(cRDatei)
		cRDatei = SUBSTR(cReport,1,RAT(".",cReport)-1) + ".pdf"
   ENDIF
	IF EMPTY(cRTitel)
   	cRTitel = "Report"
   ENDIF

	IF EMPTY(nRKopien)
   	nRKopien = 1
   ENDIF

	IF EMPTY(bDruckerWahl)
   	bDruckerWahl = false
   ENDIF
	
	IF EMPTY(cDrucker)
   	cDrucker = ""
   ENDIF

	IF EMPTY(bPDFAnzeige)
   	bPDFAnzeige = false
   ENDIF
	
	IF EMPTY(bPDFRepTmp)
   	bPDFRepTmp = false
   ENDIF
	
	IF EMPTY(nRKopienAbSeite)
   	nRKopienAbSeite = 0
   ENDIF

	IF EMPTY(nRAbSeite)
   	nRAbSeite = 0
   ENDIF

	set procedure to :adoapps:Cr4DotNet.cc addi
   cr4=new Cr4DotNet()
   cr4.SetReport(cReport)
   cr4.SetTitle(cRTitel)
	
	IF NOT EMPTY(_app.login)
		cUs = SUBSTR(_app.login,1,AT("/",_app.login)-1)
		cPW = SUBSTR(_app.login,AT("/",_app.login)+1)
		cr4.Setlogin(cUs,cPw)
	ENDIF
   cr4.SetKeinePDFPreufung(true)
   cr4.ShowGRP(false)

   cDatei = cRDatei
   cr4.SetExportDatei(cDatei)
	IF NOT EMPTY(cDrucker)
		IF _app.bEWS = true
			// Keine Druckerauswahl im Entwicklungssystem
		ELSE
			cr4.SetPRINTER(cDrucker)
		ENDIF
	ENDIF
	
	// Parameter setzen
	FOR repI = 1 TO  aParameter.size/2
		IF NOT EMPTY(aParameter[repI,1])
			cr4.setparameter(aParameter[repI,1],aParameter[repI,2])
		ENDIF
	ENDFOR

   RepAusgabe(UPPER(cRLAusgabe),cDatei,nRKopien,bDruckerWahl,bPDFAnzeige,bPDFRepTmp, nRKopienAbSeite, nRAbSeite)

return

Function RepAusgabe(repATyp,cRepDatei,nRepKopien,bRepDruckerWahl,bPDFAnzeigeNachEx,bPDFTemporaer, nRepKopienAbSeite, nRepAbSeite)
      // Bei temporärer PDF nicht drucken und auf jedenm Fall anzeigen
		IF bPDFTemporaer = true
			// Temporäre PDF anzeigen
			cRepdatei = PDF_Tmp()
			repATyp = "P"
			bPDFAnzeigeNachEx = true
		ENDIF

		// Im Entwicklungssystem keine automatischen Ausdrucke!
		IF SUBSTR(repATyp,1,1) == "D" AND _app.bEWS = true
// 	Zu Testzwecken ggfs. einschalten		
//		IF SUBSTR(repATyp,1,1) == "D" AND _app.bEWS = false
			//	Kein Ausdruck, sondern PDF-Export
			repATyp = SUBSTR(repATyp,2,1)
			IF AT("A",UPPER(repATyp))  = 1 OR AT("M",UPPER(repATyp))  = 1
				// Wird sowieso angezeigt - nichts ändern
			ELSE
				IF AT("P",UPPER(repATyp)) = 1
					// PDF-Export also auch nix ändern
				ELSE
					// Ansonsten als temporäres PDF-Exportieren 
					repATyp = "P"
					cRepdatei = PDF_Tmp()
				ENDIF
				bPDFAnzeigeNachEx = true
			ENDIF
		ENDIF
		IF SUBSTR(repATyp,1,1) == "D"
			// Ausdrucken
			IF bRepDruckerWahl = true
				cr4.getprinter()
			ENDIF
			IF NOT EMPTY(nRKopienAbSeite)
				// Anfangsseiten
				FOR nPrintI = 1 TO nRepKopien
					 cr4.print2(1,false,1,nRAbSeite-1)
				ENDFOR
				// weitere Seiten
				FOR nPrintI = 1 TO nRKopienAbSeite
					 cr4.print2(1,false,nRAbSeite,0)
				ENDFOR
			ELSE
				IF nRepKopien > 0
					FOR nPrintI = 1 TO nRepKopien
						 cr4.print()
					ENDFOR
				ENDIF
			ENDIF
			repATyp = SUBSTR(repATyp,2,1)
		ENDIF
		IF EMPTY(repATyp) OR repATyp == "O"	
			return
		ENDIF
		bRepAnzeige = false
		IF AT("A",UPPER(repATyp))  = 1 OR AT("M",UPPER(repATyp))  = 1
			// Anzeigen
			bRepAnzeige = true
			IF AT("M",UPPER(repATyp))  = 1
				cr4.show(null,true)
			ELSE
				cr4.show()
			ENDIF
			repATyp = SUBSTR(repATyp,2,1)
		ENDIF
		IF AT("O",UPPER(repATyp))  = 1
			// Keine Ausgabe
			repATyp = SUBSTR(repATyp,2,1)
		ENDIF		
		aExportType = NEW ASSOCARRAY()
		aExportType["P"] = "pdf"
		aExportType["E"] = "xls"
		aExportType["W"] = "doc"
		aExportType["H"] = "html"
		aExportType["R"] = "rtf"
		IF EMPTY(repATyp) OR repATyp == ""	OR AT("N",UPPER(repATyp))  = 1	
			return
		ENDIF
		IF bPDFTemporaer = false
			cRepdatei = SUBSTR(cRepdatei,1,RAT(".",cRepdatei)-1) + "." + aExportType[repATyp]
		ENDIF

		DO CASE
      	CASE repATyp == "P"
				  cr4.ExportToDisk("PDF",cRepDatei)
      	CASE repATyp == "E"
				  cr4.ExportToDisk("Excel",cRepDatei)
      	CASE repATyp == "W"
				  cr4.ExportToDisk("Word",cRepDatei)
      	CASE repATyp == "H"
				  cr4.ExportToDisk("HTML",cRepDatei)
      	CASE repATyp == "R"
				  cr4.ExportToDisk("RTF",cRepDatei)
      ENDCASE
	   IF bPDFAnzeigeNachEx = true
 		   adolib("runexe",cRepDatei)
	   ENDIF
		IF	bRepAnzeige = false
			// Keine Anzeige - dann aufräumen
         cr4.schliessen()
		ENDIF
		
return


