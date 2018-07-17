SYNDHPMAP ; AFHIL/FJF terminology mapping
 ;;1.0;DHP;;Jan 17, 2017
 ;;Original routine authored by Andrew Thompson & Ferdinand Frankson of DXC Technology 2017-2018
 ;
MAP(MAP,CODE,DIR) ; Return a mapped code for a given code
 ; Input:
 ; MAP - mapping to be used
 ;       currently only map implemented are "sct2icd" (5/18/2018)
 ;                                          "sct2cpt" (5/15/2018)
 ;                                          "rxn2ndt" (5/15/2018)
 ; CODE - map source code
 ; DIR - direction of mapping
 ; D for direct (default)
 ; I for inverse
 ; 
 ; Output:
 ; 1^map target code
 ; or -1^exception
 ;
 N DOI,FN
 S FN="2002.030"
 S DIR=$G(DIR,"D")
 S DOI=$S(DIR="I":"inverse",1:"direct")
 I '$D(^SYN(FN,MAP)) Q "-1^map not recognised"
 I '$D(^SYN(FN,MAP,DOI,CODE)) Q "-1^code not mapped"
 Q "1^"_$O(^SYN(FN,MAP,DOI,CODE,""))