SYNFUTL	;ven/gpl - fhir loader utilities ; 10/19/17 4:33pm
	;;1.0;fhirloader;;oct 19, 2017;Build 2
	;
	; Authored by George P. Lilly 2017-2018
	;
	q
	;
initPLD(ien,element)	; initializes the PLD pointers in the fhir graph
	new root set root=$$setroot^%wd("fhir-intake")
	set @root@(ien,"load",element,"PLD","parms")=$name(@root@(ien,"load",element,"parms"))
	set @root@(ien,"load",element,"PLD","log")=$name(@root@(ien,"load",element,"log"))
	set @root@(ien,"load",element,"PLD","verify")=$name(@root@(ien,"load",element,"verify"))
	set @root@(ien,"load",element,"PLD","status")=$name(@root@(ien,"load",element,"status"))
	set @root@(ien,"load",element,"PLD","index")=root
	quit
	;
setPLD(ien,element)	; extrinsic which returns the global name containing the PLD for this element
	new root set root=$$setroot^%wd("fhir-intake")
	if '$data(@root@(ien,"load",element,"PLD")) do initPLD(ien,element)
	quit $name(@root@(ien,"load","Patient","PLD"))
	;
log(txt)	; logs a line to the log array defined by PLD("log")
	if '$data(PLD("log")) do  quit  ;
	. w !,"Error log array not defined ",txt
	do addto(PLD("log"),txt)
	quit
	;
addto(dest,string)	; add string to list dest
	; dest is passed by name
	new %ii
	set %ii=$order(@dest@("AAAAA"),-1)+1
	set @dest@(%ii)=string
	set @dest@(0)=%ii ; count
	quit
	;
addArray(dest,array)	; add array to list dest
	; dest and array are passed by name
	new %ii
	set %ii=$order(@dest@("AAAAA"),-1)+1
	new %ij set %ij=0
	for  set %ij=$order(@array@(%ij)) quit:'%ij  do  ;
	. set @dest@(%ii)=$get(@array@(%ij))
	. set @dest@(0)=%ii ; count
	. set %ii=%ii+1
	quit
	;
setIndex(sub,pred,obj)	; set the graph indexices
	n gn s gn=$$setroot^%wd("fhir-intake")
	q:sub=""
	q:pred=""
	q:obj=""
	s @gn@("SPO",sub,pred,obj)=""
	s @gn@("POS",pred,obj,sub)=""
	s @gn@("PSO",pred,sub,obj)=""
	s @gn@("OPS",obj,pred,sub)=""
	q
	;
clearIndexes	; do this carefully
	n gn s gn=$$setroot^%wd("fhir-intake")
	k @gn@("SPO")
	k @gn@("POS")
	k @gn@("PSO")
	k @gn@("OPS")
	q
	; 
fhirTfm(dtin)	; extrinsic which returns the fileman dateTime 
	; for the FHIR format input ie 2017-04-28T01:28:28-04:00
	n tdt
	s tdt=$tr(dtin,":")
	s tdt=$tr(tdt,"T")
	s tdt=$e(tdt,1,4)_$e(tdt,6,7)_$e(tdt,9,21)
	q $$HL7TFM^XLFDT(tdt)
	;
fhirThl7(dtin)	; extrinsic which returns the HL7 dateTime 
	; for the FHIR format input ie 2017-04-28T01:28:28-04:00
	; example hl7 returned: 20170428012828-0400
	n tdt
	s tdt=$tr(dtin,":")
	s tdt=$tr(tdt,"T")
	s tdt=$e(tdt,1,4)_$e(tdt,6,7)_$e(tdt,9,21)
	q tdt
	;
ien2dfn(ien)	; extrinsic returns the patient DFN given the graph ien
	n root s root=$$setroot^%wd("fhir-intake")
	q $o(@root@("PSO","DFN",ien,""))
	;
dfn2ien(dfn)	; extrinsic returns the graph ien given the DFN
	n root s root=$$setroot^%wd("fhir-intake")
	q $o(@root@("POS","DFN",dfn,""))
	;
ien2icn(ien)	; extrinsic returns the patient ICN given the graph ien
	n root s root=$$setroot^%wd("fhir-intake")
	q $o(@root@("PSO","ICN",ien,""))
	;
icn2ien(icn)	; extrinsic returns the graph ien given the DFN
	n root s root=$$setroot^%wd("fhir-intake")
	q $o(@root@("POS","ICN",icn,""))
	;
dfn2icn(dfn)	; extrinsic returns the ICN given the patient DFN
	n ien s ien=$$dfn2ien(dfn)
	q $$ien2icn(ien)
	;
icn2dfn(icn)	; extrinsic returns the DFN given the patient ICN
	n ien s ien=$$icn2ien(icn)
	q $$ien2dfn(ien)
	;
urlEnd(zurl)	; extrinsic which return the last part of a url 
	; (the part after the final /
	q $re($p($re(zurl),"/",1))
	;
testValueDex()	; 
	;new fhir
	do getIntakeFhir^SYNFHIR("testfhir",,"Patient",1)
	do valueDex("testfhir","value")
	;zwrite fhir
	quit
	;
valueDex(ary,indx)	; creates index indx of values of the array
	;
	new ind
	new fi s fi=$query(@ary@(""))
	;new fi s fi=""
	set ind(indx,@fi)=fi
	for  set fi=$query(@fi) quit:fi=""  do  ;
	. ;w !,@fi," ",fi
	. if @fi="" quit
	. set ind(indx,@fi)=fi
	. ;write !,fi," ",@fi
	;zwrite ind
	merge @ary=ind
	quit
	;
valueDex2(ary,indx)	; creates index indx of values of the array
	; this one simplifies indx
	new ind
	new fi s fi=$query(@ary@(""))
	set ind(indx,@fi)=fi
	for  set fi=$query(@fi) quit:fi=""  do  ;
	. ;w !,@fi," ",fi
	. if @fi="" quit
	. set ind($qs(fi,$ql(fi)),@fi)=fi
	. ;write !,fi," ",@fi
	;zwrite ind
	merge @indx=ind
	quit
	;
testAdb()	; test Array Defined By
	new fhir
	do getIntakeFhir^SYNFHIR("fhir",,"Patient",1)
	do adb("fhirrace","fhir","text","race")
	zwrite fhirrace
	;
	; expected results:
	;d testAdb^SYNFUTL
	;fhirrace("coding",1,"code")="2106-3"
	;fhirrace("coding",1,"display")="White"
	;fhirrace("coding",1,"system")="http://hl7.org/fhir/v3/Race"
	;fhirrace("text")="race"
	;
	quit
	;
adb(rtn,ary,pred,obj)	; returns the array defined by the predicate and object
	if '$d(@ary@("value")) do valueDex(ary,"value")
	new ref
	set ref=@ary@("value",obj) 
	if ref'[pred quit  ;
	do replace(.ref,","""_pred_"""","")
	;w !,ref b
	merge @rtn=@ref
	quit
	;
replace(ln,cur,repl)	; replace current with replacment in line ln
	new where set where=$find(ln,cur)
	quit:where=0 ; this might not work for cur at the end of ln, please test
	set ln=$extract(ln,1,where-$length(cur)-1)_repl_$extract(ln,where,$length(ln))
	quit
	;
	