SYNFPRB ;ven/gpl - fhir loader utilities ;2018-08-17  3:27 PM
 ;;0.1;VISTA SYNTHETIC DATA LOADER;;Aug 17, 2018;Build 13
 ;
 ; Authored by George P. Lilly 2017-2018
 ;
 q
 ;
importConditions(rtn,ien,args)  ; entry point for loading Problems for a patient
 ; calls the intake Conditions web service directly
 ;
 n grtn
 n root s root=$$setroot^%wd("fhir-intake")
 d wsIntakeConditions(.args,,.grtn,ien)
 i $d(grtn) d  ; something was returned
 . k @root@(ien,"load","conditions")
 . m @root@(ien,"load","conditions")=grtn("conditions")
 . if $g(args("debug"))=1 m rtn=grtn
 s rtn("conditionsStatus","status")=$g(grtn("status","status"))
 s rtn("conditionsStatus","loaded")=$g(grtn("status","loaded"))
 s rtn("conditionsStatus","errors")=$g(grtn("status","errors"))
 ;b
 ;
 ;
 q
 ;
wsIntakeConditions(args,body,result,ien)        ; web service entry (post)
 ; for intake of one or more Conditions. input are fhir resources
 ; result is json and summarizes what was done
 ; args include patientId
 ; ien is specified for internal calls, where the json is already in a graph
 n jtmp,json,jrslt,eval
 ;i $g(ien)'="" if $$loadStatus("conditions","",ien)=1 d  q  ;
 ;. s result("conditionsStatus","status")="alreadyLoaded"
 i $g(ien)'="" d  ; internal call
 . d getIntakeFhir^SYNFHIR("json",,"Condition",ien,1)
 e  d  ; 
 . s args("load")=0
 . merge jtmp=BODY
 . do DECODE^VPRJSON("jtmp","json")
 i '$d(json) q  ;
 m ^gpl("gjson")=json
 ;
 ; determine the patient
 ;
 n dfn,eval
 if $g(ien)'="" d  ;
 . s dfn=$$ien2dfn^SYNFUTL(ien) ; look up dfn in the graph
 else  d  ;
 . s dfn=$g(args("dfn"))
 . i dfn="" d  ;
 . . n icn s icn=$g(args("icn"))
 . . i icn'="" s dfn=$$icn2dfn^SYNFUTL(icn)
 i $g(dfn)="" do  quit  ; need the patient
 . s result("conditions",1,"log",1)="Error, patient not found.. terminating"
 ;
 ;
 new zi s zi=0
 for  set zi=$order(json("entry",zi)) quit:+zi=0  do  ;
 . ;
 . ; define a place to log the processing of this entry
 . ;
 . new jlog set jlog=$name(eval("conditions",zi))
 . ;
 . ; insure that the resourceType is Observation
 . ;
 . new type set type=$get(json("entry",zi,"resource","resourceType"))
 . if type'="Condition" do  quit  ;
 . . set eval("conditions",zi,"vars","resourceType")=type
 . . do log(jlog,"Resource type not Condition, skipping entry")
 . set eval("conditions",zi,"vars","resourceType")=type
 . ;
 . ; see if this resource has already been loaded. if so, skip it
 . ;
 . if $g(ien)'="" if $$loadStatus("condition",zi,ien)=1 do  quit  ;
 . . d log(jlog,"Condition already loaded, skipping")
 . ;
 . ; determine Condition snomed code, coding system, and display text
 . ;
 . ;
 . ; determine the id of the resource
 . ;
 . ;new id set id=$get(json("entry",zi,"resource","id"))
 . ;set eval("conditions",zi,"vars","id")=id
 . ;d log(jlog,"ID is: "_id)
 . ;
 . new sctcode set sctcode=$get(json("entry",zi,"resource","code","coding",1,"code"))
 . do log(jlog,"code is: "_sctcode)
 . set eval("conditions",zi,"vars","code")=sctcode
 . n icdcode,notmapped
 . s notmapped=0
 . s icdcode=$$MAP^SYNDHPMP("sct2icd",sctcode)
 . i +icdcode=-1 s notmapped=1
 . do log(jlog,"icd mapping is: "_icdcode)
 . do:notmapped log(jlog,"snomed code "_sctcode_"is not mapped")
 . set eval("conditions",zi,"vars","mappedIcdCode")=icdcode
 . ;
 . ;
 . new codesystem set codesystem=$get(json("entry",zi,"resource","code","coding",1,"system"))
 . do log(jlog,"code system is: "_codesystem)
 . set eval("conditions",zi,"vars","codeSystem")=codesystem
 . ;
 . ; determine the onset date and time
 . ;
 . new onsetdate set onsetdate=$get(json("entry",zi,"resource","onsetDateTime"))
 . do log(jlog,"onsetDateTime is: "_onsetdate)
 . set eval("conditions",zi,"vars","onsetDateTime")=onsetdate
 . new fmOnsetDateTime s fmOnsetDateTime=$$fhirTfm^SYNFUTL(onsetdate)
 . d log(jlog,"fileman onsetDateTime is: "_fmOnsetDateTime)
 . set eval("conditions",zi,"vars","fmOnsetDateTime")=fmOnsetDateTime ;
 . new hl7OnsetDateTime s hl7OnsetDateTime=$$fhirThl7^SYNFUTL(onsetdate)
 . d log(jlog,"hl7 onsetDateTime is: "_hl7OnsetDateTime)
 . set eval("conditions",zi,"vars","hl7OnsetDateTime")=hl7OnsetDateTime ;
 . ;
 . ; determine the abatement date and time, if any
 . ;
 . new abatementdate set abatementdate=$get(json("entry",zi,"resource","abatementDateTime"))
 . if abatementdate'="" d  ;
 . . do log(jlog,"abatementDateTime is: "_abatementdate)
 . . set eval("conditions",zi,"vars","abatementDateTime")=abatementdate
 . . new fmAbatementDateTime s fmAbatementDateTime=$$fhirTfm^SYNFUTL(abatementdate)
 . . d log(jlog,"fileman abatementDateTime is: "_fmAbatementDateTime)
 . . set eval("conditions",zi,"vars","fmAbatementDateTime")=fmAbatementDateTime ;
 . . new hl7AbatementDateTime s hl7AbatementDateTime=$$fhirThl7^SYNFUTL(abatementdate)
 . . d log(jlog,"hl7 abatementDateTime is: "_hl7AbatementDateTime)
 . . set eval("conditions",zi,"vars","hl7AbatementDateTime")=hl7AbatementDateTime ;
 . else  d log(jlog,"no abatementDateTime")
 . ;
 . ; determine clinical status (active vs inactive)
 . ;
 . n clinicalstatus set clinicalstatus=$get(json("entry",zi,"resource","clinicalStatus"))
 . i $get(abatementdate)'="" set clinicalstatus="inactive" ; VistA doesn't allow active problems with a resolution date
 . ;
 . ; determine the encounter visit ien
 . n encounterId
 . s encounterId=$g(json("entry",zi,"resource","context","reference"))
 . i encounterId["urn:uuid:" s encounterId=$p(encounterId,"urn:uuid:",2)
 . s eval("conditions",zi,"vars","encounterId")=encounterId
 . d log(jlog,"reference encounter ID is : "_encounterId)
 . ;
 . ; determine visit ien
 . ;
 . n visitIen s visitIen=$$visitIen^SYNFENC(ien,encounterId)
 . s eval("conditions",zi,"vars","visitIen")=visitIen
 . d log(jlog,"visit ien is: "_visitIen)
 . ;
 . ; set up to call the data loader
 . ;
 . ;PRBUPDT(RETSTA,DHPPAT,DHPVST,DHPROV,DHPONS,DHPABT,DHPCLNST,DHPSCT)   ;Problem/Condition update
 . n RETSTA,DHPPAT,DHPVST,DHPROV,DHPONS,DHPABT,DHPCLNST,DHPSCT ;Problem/Condition update
 . s (DHPPAT,DHPVST,DHPROV,DHPONS,DHPABT,DHPCLNST,DHPSCT)=""      ;Condition update
 . ;
 . s DHPPAT=$$dfn2icn^SYNFUTL(dfn)
 . s eval("conditions",zi,"parms","DHPPAT")=DHPPAT
 . ;
 . s DHPVST=visitIen
 . s eval("conditions",zi,"parms","DHPVST")=visitIen
 . ;
 . s DHPSCT=sctcode
 . s eval("conditions",zi,"parms","DHPSCT")=DHPSCT
 . ;
 . s DHPCLNST=$S(clinicalstatus="Active":"A",1:"I")
 . s eval("conditions",zi,"parms","DHPCLNST")=DHPCLNST
 . ;
 . s DHPONS=hl7OnsetDateTime
 . s eval("conditions",zi,"parms","DHPONS")=DHPONS
 . ;
 . s DHPROV=$$MAP^SYNQLDM("OP","provider") ; map should return the NPI number
 . ;n DHPPROVIEN s DHPPROVIEN=$o(^VA(200,"B",IMMPROV,""))
 . ;if DHPPROVIEN="" S DHPPROVIEN=3
 . s eval("conditions",zi,"parms","DHPROV")=DHPROV
 . d log(jlog,"Provider NPI for outpatient is: "_DHPROV)
 . ;
 . ;s DHPLOC=$$MAP^SYNQLDM("OP","location")
 . ;n DHPLOCIEN s DHPLOCIEN=$o(^SC("B",DHPLOC,""))
 . ;if DHPLOCIEN="" S DHPLOCIEN=4
 . ;s eval("conditions",zi,"parms","DHPLOC")=DHPLOCIEN
 . ;d log(jlog,"Location for outpatient is: #"_DHPLOCIEN_" "_DHPLOC)
 . ;
 . s eval("conditions",zi,"status","loadstatus")="readyToLoad"
 . ;
 . if $g(args("load"))=1 d  ; only load if told to
 . . if $g(ien)'="" if $$loadStatus("conditions",zi,ien)=1 do  quit  ;
 . . . d log(jlog,"Condition already loaded, skipping")
 . . i notmapped d  ; snomed code does not map to icd code, can't use DATA2PCE
 . . . d log(jlog,"Calling PROBUPD^SYNDHP61 to add condition")
 . . . n DHPSDES,DHPRID,DHPDTM S (DHPSDES,DHPRID)=""
 . . . s DHPDTM=DHPONS
 . . . D PROBUPD^SYNDHP61(.RETSTA,DHPPAT,DHPSCT,DHPSDES,DHPROV,DHPDTM,DHPRID) ; update problem list with Snomed code
 . . i 'notmapped d  ; snomed code does map, use DATA2PCE to add problem to problem list
 . . . d log(jlog,"Calling PRBUPD^SYNDHP62 to add snomed condition")
 . . . D PRBUPDT^SYNDHP62(.RETSTA,DHPPAT,DHPVST,DHPROV,DHPONS,DHPABT,DHPCLNST,DHPSCT)    ;Problem/Condition update
 . . m eval("conditions",zi,"status")=RETSTA
 . . i $g(DEBUG)=1 ZWR RETSTA
 . . d log(jlog,"Return from data loader was: "_$g(RETSTA))
 . . if +$g(RETSTA)=1 do  ;
 . . . s eval("status","loaded")=$g(eval("status","loaded"))+1
 . . . s eval("conditions",zi,"status","loadstatus")="loaded"
 . . else  d  ;
 . . . s eval("status","errors")=$g(eval("status","errors"))+1
 . . . s eval("conditions",zi,"status","loadstatus")="notLoaded"
 . . . s eval("conditions",zi,"status","loadMessage")=$g(RETSTA)
 . . n root s root=$$setroot^%wd("fhir-intake")
 . . k @root@(ien,"load","conditions",zi)
 . . m @root@(ien,"load","conditions",zi)=eval("conditions",zi)
 ;
 if $get(args("debug"))=1 do  ;
 . m jrslt("source")=json
 . m jrslt("args")=args
 . m jrslt("eval")=eval
 m jrslt("conditionsStatus")=eval("conditionsStatus")
 set jrslt("result","status")="ok"
 set jrslt("result","loaded")=$g(eval("status","loaded"))
 i $g(ien)'="" d  ; called internally
 . m result=eval
 . m result("status")=jrslt("result")
 . m result("dfn")=dfn
 . m result("ien")=ien
 . ;b
 e  d  ;
 . d ENCODE^VPRJSON("jrslt","result")
 . set HTTPRSP("mime")="application/json" 
 q
 ;
log(ary,txt)    ; adds a text line to @ary@("log")
 s @ary@("log",$o(@ary@("log",""),-1)+1)=$g(txt)
 w:$G(DEBUG) !,"      ",$G(txt)
 q
 ;
loadStatus(typ,zx,zien) ; extrinsic return 1 if resource was loaded
 n root s root=$$setroot^%wd("fhir-intake")
 n rt s rt=0
 i $g(zx)="" i $d(@root@(zien,"load",typ)) s rt=1 q rt
 i $get(@root@(zien,"load",typ,zx,"status","loadstatus"))="loaded" s rt=1
 q rt
 ;
testall ; run the conditions import on all imported patients
 new root s root=$$setroot^%wd("fhir-intake")
 new indx s indx=$na(@root@("POS","DFN"))
 n dfn,ien,filter,reslt
 s dfn=0
 f  s dfn=$o(@indx@(dfn)) q:+dfn=0  d  ;
 . s ien=$o(@indx@(dfn,""))
 . q:ien=""
 . s filter("dfn")=dfn
 . k reslt
 . d wsIntakeConditions(.filter,,.reslt,ien)
 q
 ;
testone(reslt,doload)   ; run the conditions import on all imported patients
 new root s root=$$setroot^%wd("fhir-intake")
 new indx s indx=$na(@root@("POS","DFN"))
 n dfn,ien,filter
 n done s done=0
 s dfn=0
 f  s dfn=$o(@indx@(dfn)) q:+dfn=0  q:done   d  ;
 . s ien=$o(@indx@(dfn,""))
 . q:ien=""
 . q:$d(@root@(ien,"load","conditions"))
 . s filter("dfn")=dfn
 . s filter("debug")=1
 . i $g(doload)=1 s filter("load")=1
 . k reslt
 . d wsIntakeConditions(.filter,,.reslt,ien)
 . s done=1
 q
 ;
