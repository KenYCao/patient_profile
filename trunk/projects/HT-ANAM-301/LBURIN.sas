%include '_setup.sas';

*<lburin----------------------------------------------------------------------------------------;
*----------------------- 1.rawdata transpose------------------------------------->;
%getVNUM(indata=source.RD_FRMURIN, out=RD_FRMURIN);
%getVNUM(indata=source.RD_FRMURINUNS, out=RD_FRMURINUNS);
%macro lborresn(orres=,cs=,nd=,stresc=);
	length &stresc $200 orres $20 cs $10;
	call missing(orres, cs);
	if &orres^=. then orres=strip(put(&orres,best.));
		else if &orres=. and &nd='NOT DONE' then orres='NOT DONE';
			else if &orres=. and &nd^='NOT DONE' then orres=' ';
	if &cs='Y' or &cs='Yes' then cs='CS';else cs=' ';
	&stresc=strip(orres)||' '||strip(cs);
%mend lborresn;
%macro lborresc(orres=,cs=,nd=,stresc=);
	length &stresc $200 orres $20 cs $10;
	call missing(orres, cs);
	if &orres^='' then orres=strip(&orres);
		else if &orres='' and &nd='NOT DONE' then orres='NOT DONE';
			else if &orres='' and &nd^='NOT DONE' then orres=' ';
	if &cs='Y' or &cs='Yes' then cs='CS';else cs=' ';
	&stresc=strip(orres)||' '||strip(cs);
%mend lborresc;
%macro lburin(a1=,a2=,a3=,a4=,a5=,a6=);
	%do i=1 %to 2;
	%lborresn(orres=ITMURIN&&a&i..RESULT,stresc=&&a&i,cs=ITMURIN&&a&i..CS_C,nd=ITMURIN&&a&i.._C);
	%end;
	%do i=3 %to 6;
	%lborresc(orres=ITMURIN&&a&i..RESULT,stresc=&&a&i,cs=ITMURIN&&a&i..CS_C,nd=ITMURIN&&a&i.._C);
	%end;
%mend lburin;
data RD_FRMURINall;
	set RD_FRMURIN RD_FRMURINUNS;
	%informatDate(DOV);
	%formatDate(ITMURINCOLLDT_DTS);
	%lburin(a1=SG,a2=PH,a3=GLU,a4=BLD,a5=PRO,a6=BIL);
	if ITMURINCOLLTM_TMS^='' then LBDT=strip(ITMURINCOLLDT_DTS)||substr(strip(ITMURINCOLLTM_TMS),1,6);
		else LBDT=strip(ITMURINCOLLDT_DTS);
run;
proc sort data=RD_FRMURINall;
	by SUBJECTNUMBERSTR visitnum VISITMNEMONIC DOV A_DOV LBDT; 
run;
proc transpose data=RD_FRMURINall out=t_FRMURIN;
 	by SUBJECTNUMBERSTR visitnum VISITMNEMONIC DOV A_DOV LBDT; 
 	var SG PH GLU BLD PRO BIL; 
run;
data URIN;
	length vnum $100 VISITMNEMONIC $400;
	set t_FRMURIN;
	format VISITMNEMONIC $200.;
	TEST=strip(put(_NAME_,$URIN.));
	vnum='v_'||strip(put(VISITNUM*10,best.));
	if int(VISITNUM)^=VISITNUM then vnum=strip(vnum)||'_D';
	if index(VISITMNEMONIC,'UNS')>0 then VISITMNEMONIC='Unscheduled';
	VISITMNEMONIC=strip(VISITMNEMONIC)||'#'||strip(A_DOV);
	rename COL1=LBSTRESC A_DOV=B_DOV LBDT=C_LBDT VISITMNEMONIC=A_VISITMNEMONIC;
run;
*----------------------- 2.Last transpose----------------------------------->;
proc sort data=URIN out=s_URIN_t; by SUBJECTNUMBERSTR test; run;
proc transpose data=s_URIN_t out=t_URIN_t;
	by SUBJECTNUMBERSTR test; 
	id vnum;
	var  C_LBDT LBSTRESC A_VISITMNEMONIC;
run;
data t_URIN_t1;
	set t_URIN_t(rename=(_NAME_=__NAME));
	if __NAME^='LBSTRESC' then do;
		if __NAME='B_DOV' then test='Visit Date';
		else if __NAME='C_LBDT' then test='Date Collected';
	    else if __NAME='A_VISITMNEMONIC' then test='Label';
	end;
	if __NAME='LBSTRESC' then __n=input(test,UN.);else __n=0;
run;
proc sort data=t_URIN_t1 out=t_URIN_t2 nodupkey; by SUBJECTNUMBERSTR  __NAME test; run;
proc sort data=t_URIN_t2; by SUBJECTNUMBERSTR  __n __NAME; run;
%adjustVisitVarOrder(indata=t_URIN_t2,othvars=SUBJECTNUMBERSTR TEST);
data pdata.lburin(label='Urinalysis-Local');
	set t_URIN_t2;
run;

*----------------------------------------------------------------------------------------------------------->;
