/*********************************************************************
 Program Nmae: _publicMacros.sas
  @Author: Ken Cao
  @Initial Date: 2015/01/25
 
 Public (shared) macro goes here.
__________________________________________________________________
 Modification History:
 xxx on yyyy/mm/dd: 


*********************************************************************/


/*
** transform numeric date value to character date (default format is yymmdd10.);
** Example 1: use default format
length cmdtc $10;
%ndt2cdt(ndt=cmdt, cdt=cmdtc);
** Example 2: use non-default format
length cmdtc $10;
%ndt2cdt(ndt=cmdt, cdt=cmdtc, fmt=date9.);
*/
%macro ndt2cdt(ndt=, cdt=, fmt=yymmdd10.);
    if &ndt > . then &cdt = put(&ndt, &fmt);
%mend ndt2cdt;


/*
** transform numeric time value to character time (default format is time5.);
*/
%macro ntime2ctime(ntime=, ctime=, fmt=time5.);
    if &ntime > . then &ctime = put(&ntime, &fmt);
%mend ntime2ctime;



/*
** concatenate year, month and day together.
Example:
    length cmstdtc $10;
    %concatDate(year=cmstyy, month=cmstmm, day=cmstdd, outdate=cmstdtc);
*/
%macro concatDate(year=, month=, day=, outdate=);
    /*
    if &year = 'UNK' then &outdate = '';
    else if &month = 'UNK' then &outdate = strip(year)||'-'||&month;
    else &outdate = strip(year)||'-'||month||'-'||&day;
    */
    length __year $4 __month $2 __day $2;
    __year = &year;
    if __year = 'UNK' then __year = ' ';
    __month = put(upcase(&month), $month.);
    __day = ifc(UPCASE(&day) = 'UNK', ' ', &day);

    if __year > ' ' then &outdate = __year;
    if __month > ' ' then &outdate = strip(&outdate)||'-'||__month;
    if __day > ' ' then &outdate = strip(&outdate)||'-'||__day;

    /*!-- More code to be added to check integrity of date --*/

    drop __year __month __day;
%mend concatDate;





%macro concatDate(year=, month=, day=, outdate=);

    length __year $4 __month $4 __day $4;

    __year = &year;
    if &month ^= 'UNK' then __month = put(upcase(&month), $month.);
    else __month = 'UNK';
    __day = &day;

    &outdate = ' ';

    ** Ken Cao on 2015/03/10: Display UNK for null value;
    if cmiss(__year, __month, __day) < 3 then do;
        if __year = ' ' then __year = 'UNK';
        if __month = ' ' then __month = 'UNK';
        if __day = ' ' then __day = 'UNK';
        &outdate = strip(__year)||'-'||strip(__month)||'-'||strip(__day);
    end;

    /*!-- More code to be added to check integrity of date --*/
    drop __year __month __day;
%mend concatDate;


* removes 1124-0 from subject ID ;
%macro subject;
    subject = substr(subject, 7);
%mend subject;

%macro char(var=,newvar=);
        &newvar=ifc(&var^=.,strip(put(&var,best.)),'');
%mend char;

%macro ageint(RFSTDTC=, BRTHDTC=, AGE=);
   __RFSTDTC = &RFSTDTC;
   __BRTHDTC = &BRTHDTC;
   if __RFSTDTC ^= '' and length(compress(__RFSTDTC)) = 10 and __BRTHDTC ^= '' and 
    length(compress(__BRTHDTC)) = 10 then
      &AGE._=int((input(substr(__RFSTDTC, 1, 10), yymmdd10.) - input(substr(__BRTHDTC, 1, 10), yymmdd10.) + 1)/365.25);
    %char(var=&AGE._,newvar=&AGE);
    drop __RFSTDTC __BRTHDTC &AGE._;
%mend ageint; 



%macro dy(datevar, dyvar);
    __isdate = 0;
    __isdate = prxmatch('/^\d{4}-\d{2}-\d{2}$/', strip(&datevar));

    length ___year ___mon ___day $4;
    call missing(___year, ___mon, ___day);

    if __isdate = 1 then do;
        ___year = prxchange('s/(\d{4})-(\d{2})-(\d{2})/$1/', -1, &datevar);
        ___mon = prxchange('s/(\d{4})-(\d{2})-(\d{2})/$2/', -1, &datevar);
        ___day = prxchange('s/(\d{4})-(\d{2})-(\d{2})/$3/', -1, &datevar);

        if ___day > '31' then do;
            put "ERR" "OR: Invalid date (day): " &datevar=;
            __isdate = 0;
           ___dy = .I;
        end;

        if ___mon > '13' then do;
           put "ERR" "OR: Invalid date (month): " &datevar=;
           __isdate = 0;
           ___dy = .I;
        end;


        if (___day = '30' and ___mon = '02') or
           (___day = '31' and ___mon in ('02', '04', '06', '09', '11')) then do;
           put "ERR" "OR: Invalid date(day): " &datevar=;
           __isdate = 0;
           ___dy = .I;
        end;

        if ___mon = '02' and ___day = '29' then do;
           ___nyear = input(___year, best.);
           if not ((mod(___nyear, 4) = 0 and mod(___nyear, 100) > 0) or mod(___nyear, 400) = 0) then do;
               put "ERR" "OR: Invalid date(day): " &datevar=;
               __isdate = 0;
               ___dy = .I;
            end;
        end;
    end;
    
    if rfstdtc = ' ' or __isdate = 0 then do;
        &dyvar = ___dy;
    end;
    else do;
       __rfstdt__ = input(rfstdtc, yymmdd10.);
         __date__ = input(&datevar, yymmdd10.);
         &dyvar = ifn(__date__>=__rfstdt__, __date__-__rfstdt__+1, __date__-__rfstdt__);
    end;
    drop __isdate __rfstdt__ __date__ rfstdtc  ___year ___mon ___day;
%mend dy;

/*
** derive --DY and concatenate it with date variable
Parameter:
    datevar: YYYY-MM-DD format date (char); !!! MAKE SURE VARIABLE LENGTH IS LONGER ENOUGH !!!
Example:
    data ae2;
        length subject $13 rfstdtc $10;
        if _n_ = 1 then do;
            declare hash h (dataset:'pdata.rfstdtc');
            rc = h.defineKey('subject');
            rc = h.defineData('rfstdtc');
            rc = h.defineDone();
            call missing(subject, rfstdtc);
        end;
        set ae;
        rc = h.find();
        %concatdy(aestdtc);
        %concatdy(aeendtc);
        drop rc;
    run;
*/
%macro concatdy(datevar);
%dy(&datevar, __dy__);
if __dy__ ^= .I  and __dy__ ^= . then &datevar = strip(&datevar)||' ('||strip(vvaluex('__dy__'))||')';
else if __dy__ = .I then &datevar = strip(&datevar)||' (?)';
drop __dy__;
%mend concatdy;




%macro visit();
    length visit2 $200;
    label visit2 = 'Visit';
    visit2 = strip(cycle)||' '||strip(visit)||' '||ifc(seq>., strip(vvaluex('seq')), ' ');
    visit2 = strip(visit2);
    drop visit cycle seq;
%mend visit;



%macro exvisitn(cycle, day);

__visitn = input(scan(&cycle, 2, ' '), best.) * 10E5 + &day;

%mend exvisitn;


%macro visitn(visit);
    length ___visit___ $255;
    ___visit___ = upcase(&visit);
    if prxmatch('/^CYCLE \d+ DAY \d+/', ___visit___) then do;
        __visitn = input(scan(___visit___, 2, ' '), best.) * 10E5 + input(scan(___visit___, 4, ' '), best.);
    end;
    else if prxmatch('/^CYCLE \d+ RESPONSE ASSESSMENT/', ___visit___) then do;
        __visitn = input(scan(___visit___, 2, ' '), best.) * 10E5 + 10E5 - 5;
    end;
    drop ___visit___;
%mend visitn;
