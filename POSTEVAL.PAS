    unit posteval;
    {$N+,E-,O-}
     {main thing to test is -ve nums raised to power}
    {turn 18 to OB-'(', 19 to CB-')' code, so that its easy to modify}

   {complex no.s are not handled by this unit, it stops evaluations
   as soon as it gets a complex calcuation, morover numerical methods
   of computer or other are yet unknown to me so i don't know accuracy
   limits. Ineed to make my own data structure set, use protected mode
   my own numerical method set, complete software emulated math
   with accumulative error handling for errors that grow by more no.
   of calculations-expanding no. capacity to hold values so that
   error to significant level avoided and accuracy maintained}
   (**)  Interface  (**)

    {get copyright}

    const max{vars}=10;

          max_expr_syms=255;{based on size of string, will be less than 255}
          num_funcs=11; {no. of functions}
          max_func_len=6;{max function or operator length}
          No_ops=6;{no. of operators}
{this const not used} Max_syms=no_ops+num_funcs+1+max{vars}+2;
{1 is for real constant type, 2 for paranthesis}
          fnc1=no_ops+1;
          fncl=no_ops+num_funcs;
          OB=fncl+1;
          CB=OB+1;
          DIGITS=['0','1','2','3','4','5','6','7','8','9'];

          operators=['-','+','*','/','^','='];
          maxnum:real=99999999999.0;
          smallest:real=1e-12;
          max_exp:real=25.32843602;{ln(99999999999)}

    Type
                                 {do multiple parameter funcs later}
    Symbol_id = record
    sym_id:byte;
    VALUE:REAL;{VALUE at THIS POINT OF FUNC OR NUM}
    inf,{init inf-infinite & indeter-indeterminate, unreal to false in eval}
    zero,
    indeter,
    unreal:boolean; {work by rules of these forms & no calcs}
    {all booleans to be init to false in case they become true
    for an evaluation of var or const, or func then handle}
    end;{9=1+6+1+1 byte record}

    sym_stack = record
    index:array[1..max_expr_syms] of symbol_id;
          {Turning 1..max_expr_syms to 0..max exprs
           resolves problem of range check in postfix table
           creation,
           but how, the heck does it get that value...
           SOMETHING IS WRONG HERE}
    size:0..max_expr_syms;
    end;

    Exp_Table = Record
    exp_type:word;{0=infix, 1=postfix}

    Num_sym:word{0..max_expr_syms+1};{no. of operators, functions, numbers etc}
    sym_index:array[1..max_expr_syms] of symbol_id;

    End;

    Var_id = record
    name:string[max_func_len];{char}
    value:real;{value}
    end;

    Var_table = Record {var_table.vars[id_num].value}
    vars: array [1..max] of var_id;
    {func table is similar with funcs in specific hierarchy}
    {func hierarchy is const for this program}
    num_vars_used:1..max;{0 means variables not used.. which is invalid}
    end;

    op_id =record
    sym:array[1..no_ops] of char;
    num_ops:1..no_ops;
    end;

    var_func_id = record {hierarchy table}
    name:array[1..max_syms] of string[max_func_len];
    num_used:1..max_syms;
    end;



    Var opfunc,func_s:var_func_id;
        oper:op_id;

    Function str_val(s:string;var inf:boolean):real;

    Procedure Exp_chk( fun:string; Vref:var_table; var errcode,errpos:word);

    procedure infix_to_postfix(func:string; var postfix:exp_table;
                                            Vref:var_table;
                                            var errcode, errpos:word );

    procedure eval_postfix(pfix:exp_table; Vref:Var_table;var result:symbol_id);
  {if indeterminate or complex don't let .zero work or be true}
   (**) Implementation (**)


    (* string utils*)
    Procedure ins_chr_in_str(var s:string;place:word;ch:char;
                                                     var err:boolean);
    var l :word;
        d :string;
          {positions 1..254}
          {255th char can only be ( which will be removed by stk}
    begin
    err:=true;
    l:=length(s);
    if ((place>l) or (l>254) or (l<1)) then exit;
    err:=false;
    d:=s;
    move(s[place],d[place+1],l-place+1);
    inc(d[0]);
    end;
    (*
    Function Reverse_string(st:string):string;
    var l,tr:word;
    begin
    l:=length(st);
    reverse_string:=st;
    if l<>0 then
    for tr:=1 to l do
    reverse_string[tr]:=st[l-tr+1];
    end;
    *)

    Function str_val(s:string;var inf:boolean):real;
    var w,l:word;
        r,pow:real;
        decpoint:boolean;
    begin
    inf:=false;str_val:=0;r:=0;
    l:=length(s);
    if l=0 then exit;
    w:=1; decpoint:=false; pow:=1;
    if s[1]='-' then w:=w+1;
    while ((s[w] in digits) and (w<=l) and (r<=maxnum)) do
    begin
    if decpoint then
    begin
    pow:=pow/10;
    r:=r+(ord(s[w])-48)*pow;{r is always positive here}
    end
    else r:=r*10+(ord(s[w])-48);
    {} {added for tinycad}
    inf:= r>maxnum;
    if inf then exit; {can't handle}
    {}
    w:=w+1;
    if (not(decpoint) and (s[w]='.')) then
    begin
    decpoint:=true;
    w:=w+1;{INC FROM DEC POINT SO WHILE CAN'T CHECK FOR FIRST DECPOINT}
    end;
    end;{while}
    inf:= r>maxnum;
    if s[1]='-' then r:=-r;
    str_val:=r;{i forgot to do this maybe even below in infix_table}
               {OR MAYBE COSTANT VALUES NOT PUSHED }
               {OR SOME MISTAKE IN EVAL POSTFIX}
    end;

    Function finish_chr(s:string;ch:char):string;
    var l,tr:word;
        d:string;
    begin
    d[0]:=#0;
    l:=length(s);
    if l=0 then exit;
    for tr:=1 to l do
    if s[tr]<>ch then d:=d+s[tr];
    finish_chr:=d;
    end;

    Procedure Pop_chr(var s:string; var ch:char; var err:boolean);
    begin
    err:=s[0]=#0;
    if err then exit;
    ch:=s[length(s)];
    dec(s[0]);
    end;

    Procedure Exp_chk( fun:string; Vref:var_table; var errcode,errpos:word);
    var
       l, trav, count : word;
                   ch : char;

       found,
            dec_point : boolean;
              func, s : string;

    begin          {ERROR 10 ALWAYS OCCURS WHY?}

    errpos:=0; {position of error in string}
    errcode:=0; {what error?? set code value for error type}
    {both codes=0 means no error}
    func:=finish_chr(fun,' ');
    l:=length(func);

    if ( (l<1) or (l>(255-2)) )
    then  begin
    errcode:=1;{incorrect length}
    exit;
    end;

    func:='('+func+')'; l:=l+2;

    {paranthesis test..}
    count:=0;
    for trav:=1 to l do
    begin
    case func[trav] of
    '(':count:=count+1;
    ')':count:=count-1;
    end; {case}
    if ( (count=0) and (trav<l) ) then
    begin
    errcode:=2;{wrong paranthesis error}
    errpos:=trav;
    exit;
    end;
    end;{for trav}
    if count<>0 then
    begin
    errcode:=3;{no ending paranthesis error}
    errpos:=trav;
    exit;
    end;
    {paranthesis test end}

    {EXP CHECK}
   { trav:=0;
    while ( trav<(l-1) )do
    begin         USE REPEAT
    trav:=trav+1;}
    Trav:=1;
    repeat
    (* if operator occurs *)
    if ( (func[trav] in operators) and (func[trav+1]=')') ) then
    begin
    errcode:=4;{closing bracket after operator is invalid}
    errpos:=trav;
    exit;
    end;
    {if oper occurs}


    (* if a constant occurs*)
    IF (func[trav] in digits) then
    begin
    dec_point:=false;
    {detect a constant & bypass it, i.e place cursor to end of it}
    {check if constant will fit in 10 digits only when converting
    then if too big convert to infinity}

    repeat
    trav:=trav+1;


    if (not(dec_point) and (func[trav]='.')) then
    begin
    dec_point:=true;
    trav:=trav+1;
    end;

    until not(Func[Trav] in digits);

    if ((func[trav]='.') or (func[trav-1]='.'))then
    begin
    errcode:=5;{invalid position of decimal}
    errpos:=trav;
    exit;
    end;
    trav:=trav-1;{for setting to end digit so that next trav does next char}
    end;
    {constant check end} {last..}

    { if char not ='(' and not in operators and not in digits and not=')'
      then  search for function or variable name, if valid name then
      place trav at end of name (i.e close-braket for func)
      test for next char to be close-bracket or operator}
    if not ( (func[trav] in operators) or (func[trav] in digits) )then
    case func[trav] of
    '(': if (func[trav+1] in (operators+[')'])) then
         begin
         errcode:=6;{operator or close-bracket after open-bracket}
         errpos:=trav+1;
         exit;{leave proc if error}
         end; {trav not modified so loop increments automatically}


    ')': if not(func[trav+1] in (operators+[')'])) then
         begin
         errcode:=7;{operator or close-bracket must after closed-brak}
         errpos:=trav;
         exit;
         end;{leave}
    else
        begin
        (*detect funcs & vars or errors regarding them
        or inrecognisable string*)
        s:=func[trav];
        while not(func[trav+1] in (operators+digits+['(',')']) ) do
                                        begin {this way trav stops at right place}
                                        trav:=trav+1;
                                        s:=s+func[trav];
                                        end;

        {now compare string s to strings in list}
        {if func then next char is open bracket,
        if var then next char is operator or closed bracket,
        if nothing matches then unrecognized-identifier error}
         found:=false;
        {test for funcs first}
         with func_s do
         begin
         for count:=1 to num_used do
         if not(found) then found:=(s=name[count]);{else break}
         if (found and (func[trav+1]<>'(')) then
                   begin
                   errcode:=8;{open-bracket must follow function name}
                   errpos:=trav;
                   exit;{whole procedure}
                   end;{if found a func}
         end;{with funcs}

         {now test for variables}
         if not(found) then{if not a func then}
         with Vref do
         begin
         for count:=1 to num_vars_used do
         if not(found) then found:=(s=vars[count].name);{else break}
         if (found and not(func[trav+1] in (operators+[')'])) ) then
                   begin
                   errcode:=9;{close-bracket or operator must follow var name}
                   errpos:=trav;
                   exit;{whole procedure}
                   end;{if found a func}
         end;{with Vref}
         {if nothing found..}
        if not(found) then
        begin
        errcode:=10;{undefined-identifier}
        errpos:=trav;
        exit;
        end;
        {funcs & vars}
        end;{else case}
    end;{case}
    trav:=trav+1;
    until (trav>=l);{last bracket not to chk}
    {end;}{while trav<l-1}

    End;{proc exp_chk}


    Procedure infix_table(fun:string;var infix:exp_table;
                                               vref  :var_table;
                                           var errcode,errpos:word);
    var {CHECK THIS FOR CORRECT OPERATION}
        {MANUAL DEBUG NOW}
                    ch : char;
           pow10, valu : real;
               func, s : string;
   l, n, dig_num, loop : word;
 found, err, dec_point : boolean;

    begin
    func:=finish_chr(fun,' ');
    exp_chk(func,vref,errcode,errpos);
    if errcode<>0 then exit;
    func:='('+func+')';
    l:=length(func);
   {start , assign reference table values in infix table}

    with infix do
    begin
    exp_type:=0;
    num_sym:=1;{no. of symbols}
    n:=1;{no. of char in string}
    while n<=l do begin{ok n<=l}
    {search func[l] in all op_func & var tables to give val,
    dicide val for const 0 or last}
    if (func[n] in digits) then
    begin
    valu:=0;{real}
    dec_point:=false;
    dig_num:=0;
    pow10:=1;{real}
    while (func[n] in digits) do begin
    if (dig_num<12) then {max no. of integer digits=12}
    if dec_point then
       begin
       pow10:=pow10/10.0;
       valu:=valu+(ord(func[n])-48)*pow10;
       end
          else
          begin
          valu:=valu*10+(ord(func[n])-48);
          dig_num:=dig_num+1;{no. of digits}
          end;

      n:=n+1;{increment for next char test}

    if (not(dec_point) and (func[n]='.')) then
    begin
    dec_point:=true;
    n:=n+1;
    end;
     end;{while for const}
     with sym_index[num_sym] do
     begin
     sym_id:=0;
     value:=valu;
     inf:=dig_num>11;{ALSO SAME AS SIMPLE CHECK OF>maxnum}
     if inf then {if value>0 then} value:=1 {else value:=-1};
     {neg function used, hence all entered no.s are only of + sign}

     zero:=valu<=smallest;{ALL NO.S ARE POSITIVE}
     if zero then value:=0;
     indeter:=false;
     unreal:=false;
     {use all 12 digits, 12th digit is roungding digit in real}
     {pwr:=dig_num; not needed as sin real has > double capacity than used}
     {infinity:=dig_num>10;}
     end;
     n:=n-1;{to get back to last digit}
    end{if constant}
    else
    {check for operators}
    if (func[n] in operators) then
    with oper do
    begin
    for loop:=1 to no_ops do
        if func[n]=sym[loop] then
        with sym_index[num_sym] do
        begin
        sym_id:=loop;
     inf:=false;
     indeter:=false;
     unreal:=false;
        break;{inner most for , while , repeat loops}
        end;
    end{with oper}
    else
    case func[n] of {check for indeterminate form as can't be stored}
    '(':with sym_index[NUM_SYM] do
        begin
        sym_id:=OB;{value not needed}
     inf:=false;
     indeter:=false;
     unreal:=false;
        end;
    ')':with sym_index[NUM_SYM] do
        begin
        sym_id:=CB;{code}
     inf:=false;
     indeter:=false;
     unreal:=false;
        end;
    else {not in operators or digits}
    begin {search for functions, variables}
          {in func_s & var_tables}
    {func code= num oprs+ func index}
    found:=false;{if function found then don't search in variable}
    {extract name from string}
        s:=func[n];
        while not(func[n+1] in (operators+digits+['(',')']) ) do
                                        begin {this way trav stops at right place}
                                        n:=n+1;{inc to next char of str}
                                        s:=s+func[n];
                                        end;

         {with func_s do
         begin}

         for loop:=1 to FUNC_S.NUM_USED do
         if not(found) then
         begin
         found:=(s=FUNC_S.name[loop]);
         if found then
                  with sym_index[NUM_SYM] do
                  begin
                  sym_id:=no_ops{paranthesis}+loop;{}
     inf:=false;
     indeter:=false;
     unreal:=false;
                  end;
         end else{outer if} break;

         {now test for variables}
         if not(found) then{if not a func then}
         with Vref do
         begin
         for loop:=1 to num_vars_used do
         if not(found) then
         begin
         found:=(s=vars[loop].name);
         if found then
                  with sym_index[NUM_SYM] do
                  begin
                  sym_id:=CB{paranthesis}+loop;{}
     inf:=false;
     indeter:=false;
     unreal:=false;
                  end;
         end else break;
         {set value in table}
         END;{WITH VREF}
         {if not found above then definately here}
    end;{case else}
    end;{case}

    n:=n+1;{auto increment for string}
    num_sym:=num_sym+1;{auto increment for no. of symbols in table}
    end;{while n<=l}
    NUM_SYM:=NUM_SYM-1;
    end;{with infix}
    end;{procedure infix table }


    procedure push_sym(var stk:sym_stack; sym:symbol_id; var full:boolean);
    begin
    with stk do
    begin
    full:=size=max_expr_syms;{size of string, we'll never go above, so no err's}
                   {for current requirements}
    if full then exit;
    size:=size+1;
    move(sym,index[size],sizeof(sym));
    end;{with}
    end;

    procedure pop_sym(var stk:sym_stack; var sym:symbol_id; var nul:boolean);
    begin
    with stk do
    begin
    nul:=size=0;
    if nul then exit;
    move(index[size],sym,sizeof(sym));
    size:=size-1;
    end;{with}
    end;

    {
    procedure ins_sym_in_stk();
    begin for functions only..., but taken care of in case itself
    end;
    }

    procedure infix_to_postfix(func:string; var postfix:exp_table;
                                            Vref:var_table;
                                            var errcode, errpos:word );
    {NO ERROR IN PREV NOW-
    ERROR FOUNF WAS NUM_SYM HAD AN EXTRA INCREMENT VALUE AT END}
    var infxstk,oprstk,temp:sym_stack;
        infix:exp_table;
        symbl, sym:symbol_id;
        loop :word;
        full,nul,eror:boolean;
        brk_num,cnt:word;
    begin
    infix_table(func,infix,vref,errcode,errpos);
    if errcode<>0 then exit;
    OPRSTK.SIZE:=0;
    INFXSTK.SIZE:=0;
    TEMP.SIZE:=0;
    {start}
    with  infix do begin
    loop:=num_sym;

    while loop>=1 do
    begin
    push_sym(infxstk,sym_index[loop],full);
    loop:=loop-1;
    end;{while loop}
    end;{with infix} {infix in stack, pops first term first}

    with postfix do begin
    num_sym:=0;
    while infxstk.size<>0 do
    begin
    pop_sym(infxstk,symbl,nul);{LAST POPED SYMBOL SHOULD BE CLOSE BRAK}
    if not(nul) then begin
    case symbl.sym_id of
    0:begin
      {sym_id:=symbl.sym_id;
      value:=symbl.value;
      inf:=symbl.inf;} {move whenever to postfix var}
      num_sym:=num_sym+1;
      move(symbl,sym_index[num_sym],sizeof(symbl));
      end;{constant}
    {operator stack has operators, bracs,funcs}
    {infix stack has postfix forming, temp stack is for temporary work}

    1..6{no_ops}:
    begin {operator stack never empty for operator, but for bracket only}
    temp.size:=0; {operator id hierarchy wise}
    if( {THIS METHOD IS WRONG}
         (oprstk.index[oprstk.size].sym_id>=symbl.sym_id)
         and
      not(oprstk.index[oprstk.size].sym_id>no_ops){means bracket as no other thing}
      )
      then begin{just push the silly operator in operstk}
           while
           (
           not(oprstk.index[oprstk.size].sym_id>no_ops{OB}{open-brak})
           and
           (oprstk.index[oprstk.size].sym_id>=symbl.sym_id)
           )
            do begin
            {here we pop out till symbols in operator stack are large,equal to
            encountered than the new scanned operator which has to be placed in stack}
           {num_sym:=num_sym+1;}
           temp.size:=temp.size+1;
           pop_sym(oprstk,temp.INDEX[temp.size],eror);{eror should never come true}

           {push_sym(oprstk,symbl,eror);}{error never occurs}
           end;
           {pop temp to sym_index}
           nul:=false;
           while not(TEMP.SIZE=0) do
           begin
           num_sym:=num_sym+1;
           pop_sym(temp,sym_index[num_sym],nul);
           end;
           push_SYM(oprstk,symbl,nul);
           end
           else
        if {after this only bracket case can occur, hence just push}
        (
         (oprstk.index[oprstk.size].sym_id<symbl.sym_id)
         and
      not(oprstk.index[oprstk.size].sym_id>no_ops){means bracket as no other thing}
        ) then
        begin
        TEMP.SIZE:=0;
      while
        (
         (oprstk.index[oprstk.size].sym_id<symbl.sym_id)
         and
      not(oprstk.index[oprstk.size].sym_id>no_ops){means bracket as no other thing}
      ) DO BEGIN
      TEMP.SIZE:=TEMP.SIZE+1;
      pop_sym(oprstk,TEMP.INDEX[TEMP.SIZE],eror);{eror should never come true}
      END;{WHILE}
      PUSH_SYM(OPRSTK,SYMBL,EROR);
      EROR:=FALSE;
      WHILE NOT(TEMP.SIZE=0) DO
      BEGIN
      OPRSTK.SIZE:=OPRSTK.SIZE+1;
      POP_SYM(TEMP,OPRSTK.INDEX[OPRSTK.SIZE],EROR);
      END;{WHILE}
      END{IF}
      ELSE
      PUSH_SYM(OPRSTK,SYMBL,EROR);
      END;{CASE}

    Fnc1..Fncl: {ERROR HERE} {FUNCTIONS NOT INSERTED MAYBE}
    begin
    {size if infx is pointing no next char to be poped}
    {if a func} {RANGE CHECK ERROR OCCURED BELOW FOR THE FIRST TIME
    AT FUNC LN(2) BEFORE THIS FUNCS WERE NOT WORKING &
    I FIXED MOVE STATEMENT IN THISBLOCK}

    if (infxstk.index[infxstk.size].sym_id<>OB{open bracket}) then
    {THIS CAN ONLY HAPPEN IF SIZE> SPECIFIED AS ZERO NOT AT FUNC
    OR NO END BRAK IN INFIX TABLE}
    begin {send to postfix table}
      num_sym:=num_sym+1;
    move(symbl,sym_index[num_sym],sizeof(symbl));{same size}
    end
    else
    {ALL BRACKETS ARE SURPASSED WHEN ONLY FUNC BRACKS NEED TO BE}
        begin {if function with suceeding open-bracket}
        brk_num:=0; {word}
        cnt:=1;     {word}
        repeat {SOME CNT LOGIC ERROR}
        case (infxstk.index[infxstk.size-cnt+1].sym_id) of
        OB{open brack}:brk_num:=brk_num+1;
        CB{close brak}:brk_num:=brk_num-1;
        else
            begin {leave else case}
            end;
        end;{case}
        cnt:=cnt+1;
        until brk_num=0;
        CNT:=CNT-1;{THIS IMPORTANT STEP WAS MISTAKENLY REMARKED}
        {cnt has exact numeric pos where to insert function}
        move(infxstk.index[infxstk.size-cnt+1],temp.index[1],sizeof(symbl)*cnt);
        move(symbl,infxstk.index[infxstk.size-cnt+1],sizeof(symbl));
        move(temp.index[1],infxstk.index[infxstk.size-cnt+2],sizeof(symbl)*cnt);
        INFXSTK.SIZE:=INFXSTK.SIZE+1;
        end;{if func followed by open brack}

    end;{funcs}{if followed by open brac then search fo end bracket}
                  {and insert after there from here,}
                  {if not followed by opn brack then push to table}
    OB,CB:
    begin

    if (symbl.sym_id=OB) then
    begin
    push_sym(oprstk,symbl,eror);
    end
    else
        begin
        TEMP.SIZE:=0;
        {POP TO TEMP FIRST, THEN FROM TEMP TO EXPR}
        WHILE ((OPRSTK.INDEX[OPRSTK.SIZE].SYM_ID<>OB) )
        DO BEGIN
        TEMP.SIZE:=TEMP.SIZE+1;
        {pop all operators till open bracket with open bracket}
        pop_sym(oprstk,TEMP.INDEX[TEMP.SIZE],eror);{eror should never occur}
        END;{WHILE}
        WHILE NOT(TEMP.SIZE=0) DO
        BEGIN
        NUM_SYM:=NUM_SYM+1;
        POP_SYM(TEMP,SYM_INDEX[NUM_SYM],EROR);
        END;{WHILE TEMP}
        {RID OF EXTRA BRAC}POP_SYM(OPRSTK,TEMP.INDEX[1],EROR);
        {NOW CHECK FOR NEXT CHAR IN STACK TO BE A FUNC}
        IF INFXSTK.SIZE<>0 THEN
        {^THIS I HAD SOME WHAT PREDICTED FOR RANGE CHECK ERROR}
        IF (
           (INFXSTK.INDEX[INFXSTK.SIZE].SYM_ID>=FNC1)
           AND
           (INFXSTK.INDEX[INFXSTK.SIZE].SYM_ID<=FNCL)
           ){NEXT IS A FUNCTION}
           THEN BEGIN
           NUM_SYM:=NUM_SYM+1;
           POP_SYM(INFXSTK,SYM_INDEX[NUM_SYM],NUL);
           END;


        end;

    end;{brackets}
    else
        begin {variable table}
        {sym is just a temporary var for exchange in all places not
        needed outside its block}
        num_sym:=num_sym+1;
        move(symbl,sym_index[num_sym],sizeof(symbl));
        end;{case else}
    end;{case}
    end;{not nul}
    end;{while infxstk}
    end;{with postfix}


    end;{end proc}

    procedure eval_postfix(pfix:exp_table; Vref:Var_table;var result:symbol_id);
    var   {RETURNS ZERO ALL THE TIME, SMALL PROBLEM HERE ONLY}
    Val_stk:sym_stack;
    loop:word;{TURN RESULT ABOVE TO RES AND TRY IF NOTHING HAPPE4NS}
    opd1,opd2:symbol_id;{operands}
    nul,ful:boolean;

    begin
    {form = send sym_id only..., put form in sym id rather booleans
    0:zero
    1:infinite
    2:indeter
    3:unreal
    asssume result.sym_id to be zero always}
    {put all this code in plot rather than call it so many times??}
    val_stk.size:=0;{important initialise}
    with pfix do
    begin
         for loop:=1 to num_sym do
         with sym_index[loop] do
         begin
         result.inf:=false;
         result.zero:=false;{initialisation of 0 & inf necessary to false}
         result.unreal:=false;
         result.indeter:=false;

         case  sym_id of
         {make use of a common push statement to push in result in stk}
         {constant}
         0:{push_sym(val_stk, sym_index[loop], ful);}{ful can never be true}
           move(sym_index[loop],result,sizeof(result));
                    {values stack, all things are constants in this stack}
         {operators}
         1..6:
         begin
         pop_sym(val_stk,opd2,nul);{include the pop push code here for fast speed}
         pop_sym(val_stk,opd1,nul);{oprand 2 poped first from stack}
         { if indeterminats occur immediate exit is already done
         hence poped value from value stk can't be indeterminate
         and in this evaluator it can't be complex too
         result.indeter:=opd1.indeter or opd2.indeter;
         result.unreal:=opd1.unreal or opd2.unreal;
         }
         {if result is unreal or indeterminate exit proc??}
         {then there will be no need to check for indeterminates
         or unreals}
         {if not (result.unreal or result.indeter)then}
                 {later in complex nums handle unreals}
         case sym_id of
         1{-}:
         begin
         result.value:=opd1.value-opd2.value;
         case opd1.inf of
         true:
              case opd2.inf of
              true: if (
                       ((opd1.value>0) and (opd2.value<0))
                       or
                       ((opd1.value<0) and (opd2.value>0))
                       )
                       then
                       begin
                       result.inf:=true ;
                                 if result.value<0
                                 then
                                 result.value:=-1
                                 else
                                 result.value:=1;

                       end
                          else result.indeter:=true;

              false: begin
                     result.inf:=true;
                     result.value:=opd1.value;{+1 or -1}
                     end;
              end;

         false:
              case opd2.inf of
              true: begin
                    result.inf:=true;
                    result.value:=-(opd2.value);{-1 +1}
                    end;

              false:result.inf:=false;
              end;

         end;{case opd1.inf}
         end;{-}

         2{+}:
         begin
         result.value:=opd1.value+opd2.value;{inf+inf=inf}
         case opd1.inf of
         true:
              case opd2.inf of
              true: if (
                       ((opd1.value>0) and (opd2.value>0))
                       or
                       ((opd1.value<0) and (opd2.value<0))
                       )
                       then
                       begin
                       result.inf:=true ;
                                 if result.value<0{trusting inf values}
                                 then
                                 result.value:=-1
                                 else
                                 result.value:=1;

                       end
                          else result.indeter:=true;

              false: begin
                     result.inf:=true;
                     result.value:=opd1.value;{+1 or -1}
                     end;
              end;{nest case}

         false:
              case opd2.inf of
              true: begin
                    result.inf:=true;
                    result.value:=opd2.value;{+1 -1}
                    end;

              false:result.inf:=false;
              end;{nest case}

         end;{case opd1.inf}
         end;{+}

         3{*}:
         begin
         result.value:=opd1.value*opd2.value;
         result.indeter:=(
                           (opd1.inf and opd2.zero)
                           or
                           (opd1.zero and opd2.inf)
                         );
         result.inf:=(not(result.indeter) and (opd1.inf or opd2.inf));
         if result.inf then
         if (result.value<0) then result.value:=-1 else result.value:=+1;
         {zero*inf=indeterminate}
         end;{*}
         {since entered values <1/2 the digit capacity of real any two no.s can be multiplied}

               {all higher funcs are made by step smaller funcs,}
               {parametrically, i.e operators etc}
         4{/}:
         begin {unreal values can't be formed here}
         result.indeter:=(
                           (opd1.inf and opd2.inf)
                           or
                           (opd1.zero and opd2.zero)
                         );
         result.inf:=(not(result.indeter) and (opd1.inf or opd2.zero));
         if result.inf then
         if result.value<0 then result.value:=-1 else result.value:=1;
         if not(result.indeter or result.inf) then
         if opd2.inf then result.value:=0 else
         result.value:=opd1.value/opd2.value;
         end;{/}
         {result.value has sign of infinity}
         5{^}:  {raised to symbol}
         begin
         result.indeter:=(
                          (opd1.zero and opd2.zero)
                          or
                          ((abs(opd1.value)=1) and opd2.inf)
                          or
                          (opd1.inf and opd2.zero)
                          {or maybe -ve no log is unreal not indeter}
                          {((opd1.value<0) and opd2.zero)}
                         );
         RESULT.UNREAL:=((OPD1.VALUE<0) AND OPD2.ZERO);
         if not(result.indeter AND RESULT.UNREAL) then
         begin
         (*
         if (opd2.inf and opd1.zero){spl case}
         then begin {spl case not needed}
              result.inf:=opd2.value<0;
              result.zero:=opd2.value>0;
              if result.inf then result.value:=1;
              if result.zero then result.value:=0;
         *)
         if opd1.zero then
         begin
         result.value:=-1;
         result.inf:=true;
         end
         else
         if opd1.inf then
         begin
         result.value:=1;
         result.inf:=true;
         end
         else result.value:=ln(abs(opd1.value));{opd1.vale can be -ve}


         result.value:=opd2.value*result.value;{now check for inf sign}
        { if (opd2.inf and opd1.inf) then
         if
         result.value:=opd1.value*opd2.value;{infinity sign= multiple of signs}
       { chek this in first log then exp order}
       if (result.inf) then{check for exponent result}
       begin
         if result.value<0 then
         begin {if inf*opd2 <0 then exp:=0;}
         result.value:=0;
         RESULT.INF:=FALSE;
         result.zero:=true;{no need to put result=0 here, done below}
         end

         else  {if +result.inf then} {wrong here as res.inf}

         {get result value from exp +infinite=inf}
         begin
         result.value:=1;{exp + inf= +inf}
         {result.inf is already true}
         end;
                  {if opd2.zero then opd2.value=0 assumed}
         {opd2.zero & + inf don't exist}
       end  {result.inf=false}
         {}else

         if result.value>max_exp then
            begin
            result.value:=1;
            result.inf:=true;
            end else result.value:=exp(result.value);

      (*   if ((result.value>max_exp{ln(maxnum)}) or
         result.inf
         then
         begin
         result.value:=1;
         result.inf:=true;
         end else
         result.value:=exp(result.value);
         end;
       *)         {only positive inf ^ inf}
         if ( (opd1.value<0) )
         then begin
              {check in indeter if -ve num raised to inf}
{              result.indeter:=opd2.inf;}
              RESULT.VALUE:=-RESULT.VALUE;
              if ( (abs(opd2.value)<1) AND NOT(OPD2.ZERO)) then
              begin
         if NOT(      {1 PREV}
            (frac((1/opd2.value)/2)<>0){odd false if 0 i.e even}
                                          {no frac on div by zero if even}
            and
            (int(1/opd2.value)=(1/opd2.value))
            ) then result.unreal:=true;

              end{if abs(opd2)<1}
              else
              if (opd2.value=int(opd2.value)) then
              if (frac(opd2.value/2)=0) then
              {res=- if odd opd2 else + if even}
              result.value:=-result.value else else result.unreal:=true;
         end;{if opd1<0}
         end;{not indeter}

         end;{^}

         6{=}:
         if ( (opd1.value=opd2.value) and
              (opd1.inf=opd2.inf) and
              (opd1.zero=opd2.zero) ) then
         begin
         result.value:=opd1.value;
         result.zero:=opd1.zero;
         result.inf:=opd1.inf;
         {result.unreal to check in complex eval}
         end
         else
         result.indeter:=true;
         end;{operator nested case}

         {push_sym(val_stk,result,ful);}{push val, ok or indeter, or unreal}
         end;{main case condition}
         {   indeterminate is same as undefined or has no definition}

         Fnc1..Fncl: {functions} {use a single pop here}
         begin
         pop_sym(val_stk,opd1,nul);
         {always check that poped val shouldn't be indeter or unreal}
         {it could also be infinite or zero}
         case sym_id of
         Fnc1{sin}:
         if opd1.inf then result.indeter:=true
         else
         result.value:=sin(opd1.value);
         {fixed record var should act no different in terms of mem
         addressing by compiler else for speed variables to substitute
         records have to be used}
         8{cos}:
         if opd1.inf then result.indeter:=true
         else
         result.value:=cos(opd1.value);
         
         9{arctan}:
         if opd1.inf then
         result.value:=(pi/2)*opd1.value
         else result.value:=arctan(opd1.value);

        10{frac}:
        {if opd1.inf then result.value:=0 else}
        {frac will be zero even ifjust frac is used as inf frac part=0}
           result.value:=frac(opd1.value);

        11{int}:
        if opd1.inf then
        begin
        result.inf:=true;
        result.value:=opd1.value;
        end else
           result.value:=int(opd1.value);

        12{round}:
        if opd1.inf then
        begin
        result.inf:=true;
        result.value:=opd1.value;
        end else
           result.value:=int(opd1.value);

        13{sgn}:
        if opd1.zero then result.value:=0
        else
        result.value:=opd1.value/abs(opd1.value);
        {could've rather directly placed +1 or -1 for sgn}

        14{abs}:
        begin
        result.value:=abs(opd1.value);
        result.inf:=opd1.inf
        end;

        15{ln}:
        begin
        if opd1.value<0 then result.unreal:=true
        else
            if opd1.zero then
            begin
            result.inf:=true;
            result.value:=-1;
            end
        else
            if opd1.inf then
            begin
            result.inf:=true;
            result.value:=1;
            end
        else
            result.value:=ln(opd1.value);
        end;

        16{exp}:         {replace this by a constant}
        if ( (opd1.value>max_exp) or (opd1.inf and (opd1.value>0)) )then
        begin
        result.inf:=true;
        result.value:=1;
        end
        else
        if opd1.inf then
        begin
        result.zero:=true;
        result.value:=0;
        end
        else
        result.value:=exp(opd1.value);

        Fncl{neg}:
        BEGIN
        result.value:=-opd1.value;
        result.zero:=opd1.zero;
        result.inf:=opd1.inf;
        end;

        end;{CASE FUNC1..FUNCL}
        end;{case expr=func}
        {OB, CB -brackets never occur}
        else
            begin{variable table, value}
            {curr value- closed bracket value= variable array index value}
            {var can't have unreal or undet value here, send false}
            {it is assumed that vars have different names from
            used operators & funcs, also that postfix expression is correct}
            result.value:=vref.vars[sym_id-CB].value;
            end;
         end;{case}
{swap vectors doesn't let dos be reported of errors???}
         if (result.unreal or result.indeter) then exit{proc with this value}
         else
         begin
         if ((abs(result.value)>maxnum)) then
              begin
              result.inf:=true;
              if result.value<0 then
              result.value:=-1
              else result.value:=1;
              end;

         if ((abs(result.value)<=smallest) {and not(zero)}) then
             begin
             result.zero:=true;
             {RESULT.INF:=FALSE}
             result.value:=0;
             end;
         {if result.unreal, no processing}
         push_sym(val_stk,result,ful);{common push of result}
         end;{if result is indeterminate or unreal}
         end;{for loop, with sym_index}
    end;{with pfix}
    pop_sym(val_stk,result,nul);{if result is indet or unreal then exit, no pop}
    end;{proc eval}
                                     {var table needed with var values}
                                     {value for a variable read from provided}
                                     {var table}

           {log exists only for >0 values only,
            hence for polynomials let a inter raised to symbol exist
            i.e x^N gives X*X*X..n times, if n is not integer it is
            rounded to one}
           {provide frac, round, trunc etc funcs too}

 {later add boolean eval graphs, hex based graphs, log-log's, semi-logs etc
  i.e y,x-axis can be treated as functions themselves, ploting funcs on to
  them }

    BEGIN

    {set operator symbols}
    with oper do
    begin   {all operators are 1 char length}
            {hierarchy wise}
    num_ops:=no_ops;
    sym[1]:='-';
    sym[2]:='+';
    sym[3]:='*';
    sym[4]:='/';
    sym[5]:='^';
    sym[6]:='=';{equal to }
    {for more operators not one char use 2 param funcs instead}
    {or some other approach to check for these}
    end; {for binary use and, or ,xor , nand operators later}
    {compile expression in memory as far func & call it, this will be fastest}
    with func_s do
    begin {all single param funcs are here, all of same hierarchy}
    num_used:=num_funcs;
    Name[1]:='SIN';
    Name[2]:='COS';
    Name[3]:='ARCTAN';
    Name[4]:='FRAC';
    Name[5]:='INT';{TRUNC}
    Name[6]:='ROUND';
    Name[Fnc1]:='SGN';
    Name[8]:='ABS';
    Name[9]:='LN';
    Name[10]:='EXP';
    Name[11]:='NEG';{or use a # to represent neg func, inverts sign}
                    {defualt sign is always plus}
    end;
    {set values by hierarchy}
    with opfunc do{code num_used+1=var, num_used+2=const}
    begin
    num_used:=CB;{const & variables have highest values & treated seperately}

    {IN EVALUATION DON'T REFER TO THIS BUT DIRECTLY ASSUME THIS for
    code values}
    Name[1]:='-';
    Name[2]:='+';
    Name[3]:='*';
    Name[4]:='/';
    Name[5]:='^';{exponentiation}
    Name[6]:='=';{get sign, power, assign some other func}
    Name[Fnc1]:='SIN';
    Name[8]:='COS';
    Name[9]:='ARCTAN';
    Name[10]:='FRAC';
    Name[11]:='INT';
    Name[12]:='ROUND';
    Name[13]:='SGN';{num/abs(num) if num<>0, 0 otherwise}
    Name[14]:='ABS';
    Name[15]:='LN';
    Name[16]:='EXP';
    Name[Fncl]:='NEG';
    Name[OB]:='(';
    Name[CB]:=')';
    {nested loop 1-2nd last, 2-last to compare if same names are entered,
    names can't have space in b/w them}
    end;
    {use only 2 procs infix_to_postfix, eval_postfix}
    {& 1 function str_val to conv signed string real no. to real type}

    {treat brackets seperately, }
    {check always if no. of opening brakects= no. of closing brackets}
    END.