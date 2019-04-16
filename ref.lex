%{

/* Declarations section */
#include <stdio.h>

void showToken(char *);

void showTokenForInteger();

void errorUndefinedChar();

int decStrToDecInt(char *, int);

int octStrToDecInt(char *, int);

int hexStrToDecInt(char *, int);

void startComment();

void showTokenForComment();

void endComment();

void commentEOF();

void startSimpleStr();

void simpleStrHandler();

void endSimpleStr();

void startStr();

void strHandler();

void endStr();

void errorUnclosedStr();

void showTokenEOF();

int str_len;
char str_buf[1025];

%}

%x comment
%x simplestr
%x str

%option yylineno
%option noyywrap

digit   	      ([0-9])
letter  		  ([a-zA-Z])
alphanumeric      ({digit}|{letter})
newline           (\n|\r|\r\n)
sign              ([+-])
decnumber         ({sign}?{digit}+)
hexnumber         (0x[0-9a-fA-F]*)
octnumber         (0o[0-7]*)
integer           ({decnumber}|{hexnumber}|{octnumber})
frac              ({sign}?(({digit}*\.{digit}+)|({digit}+\.{digit}*)))
real              ({frac}{exponent}?|".inf"|".NaN")
exponent          (e{sign}{digit}+)
noapost           ([\t\x20-\x26\x28-\x7e])
noquotes          ([\t\x20-\x21\x23-\x7e]|"\\\"")
whitespace        ([\t ]|{newline})

%%

"---"             showToken("STARTSTRUCT");
"..."             showToken("ENDSTRUCT");
"["                         showToken("LLIST");
"]"                         showToken("RLIST");
"{"                         showToken("LDICT");
"}"                         showToken("RDICT");
":"                         showToken("KEY");
"?"                         showToken("COMPLEXKEY");
"-"                         showToken("ITEM");
","                         showToken("COMMA");
"!!"{letter}+               showToken("TYPE");

"#"                         startComment();
<comment>[^\n\r]*           showTokenForComment();
<comment>{newline}          endComment();
<comment><<EOF>>            commentEOF();

"true"                      showToken("TRUE");
"false"                     showToken("FALSE");
{integer}                   showTokenForInteger();
{real}                      showToken("REAL");

"\'"                        startSimpleStr();
<simplestr>{noapost}        simpleStrHandler();
<simplestr>"\'"             endSimpleStr();
<simplestr>[^{noapost}]     errorUndefinedChar();
<simplestr><<EOF>>          errorUnclosedStr();

"\""                        startStr();
<str>{noquotes}*{newline}?  strHandler();
<str>"\""                   endStr();
<str><<EOF>>                errorUnclosedStr();

{letter}+{alphanumeric}*    showToken("VAL");
"&"{letter}+                showToken("DECLARATION");
"*"{letter}+                showToken("DEREFERENCE");

{whitespace}                {};
<<EOF>>                     showTokenEOF();

<INITIAL,str,simplestr>.    errorUndefinedChar();

%%

void showToken(char * name){
    printf("%d %s %s\n", yylineno, name, yytext);
}

void showTokenForInteger(){
    int number;
    if (yyleng >= 2 && yytext[1] == 'o'){
        number = (yyleng > 2) ? octStrToDecInt(yytext+2, yyleng-2) : 0;
    } else if (yyleng >= 2 && yytext[1] == 'x'){
        number = (yyleng > 2) ? hexStrToDecInt(yytext+2, yyleng-2) : 0;
    } else {
        number = decStrToDecInt(yytext, yyleng);
    }
    printf("%d INTEGER %d\n", yylineno, number);
}

int decStrToDecInt(char * number_as_str, int length){
    int x = 1;
    int number = 0;
    while (--length >= 0 && number_as_str[length] != '+' && number_as_str[length] != '-'){
        number += (number_as_str[length] - '0') * x;
        x *= 10;
    }
    return (number_as_str[0] == '-') ? -number : number;
}

int octStrToDecInt(char * number_as_str, int length){
    int x = 1;
    int number = 0;
    while (--length >= 0){
        number += (number_as_str[length] - '0') * x;
        x *= 8;
    }
    return number;
}

int hexStrToDecInt(char * number_as_str, int length){
    int x = 1;
    int number = 0;
    while (--length >= 0){
        int current_digit = number_as_str[length];
        if (current_digit >= 'a' && current_digit <= 'f'){
            current_digit = current_digit - 'a' + 10;
        } else if (current_digit >= 'A' && current_digit <= 'F'){
            current_digit = current_digit - 'A' + 10;
        } else{
            current_digit -= '0';
        }
        number += current_digit * x;
        x *= 16;
    }
    return number;
}

void startComment(){
    BEGIN(comment);
}

void showTokenForComment(){
    printf("%d COMMENT #%s\n", yylineno, yytext);
}

void endComment(){
    BEGIN(INITIAL);
}

void commentEOF(){
    endComment();
    showTokenEOF();
}

void startSimpleStr(){
    str_len = 0;
    BEGIN(simplestr);
}

void simpleStrHandler(){
    str_buf[str_len++] = yytext[0];
}

void endSimpleStr(){
    str_buf[str_len] = '\0';
    printf("%d STRING %s\n", yylineno, str_buf);
    BEGIN(INITIAL);
}

void strHandler(){
    int i;
    for (i = 0; i < yyleng; ++i){
        if (yytext[i] == '\"'){
            str_buf[str_len] = '\0';
            printf("%d STRING %s\n", yylineno-1, str_buf);
            BEGIN(INITIAL);
        } else if (yytext[i] == '\n' || yytext[i] == '\r'){
            str_buf[str_len++] = '\x20';
            if (yytext[i] == '\r' && yyleng > i+1 && yytext[i+1] == '\n'){
                i++;
            }
        }
        else if (yytext[i] != '\\'){
            str_buf[str_len++] = yytext[i];
        } else {
            switch (yytext[++i]){
                case '\\':
                    str_buf[str_len++] = '\\';
                    break;
                case '\"':
                    str_buf[str_len++] = '\"';
                    break;
                case 'a':
                    str_buf[str_len++] = '\a';
                    break;
                case 'b':
                    str_buf[str_len++] = '\b';
                    break;
                case 'e':
                    str_buf[str_len++] = '\e';
                    break;
                case 'f':
                    str_buf[str_len++] = '\f';
                    break;
                case 'n':
                    str_buf[str_len++] = '\n';
                    break;
                case 'r':
                    str_buf[str_len++] = '\r';
                    break;
                case 't':
                    str_buf[str_len++] = '\t';
                    break;
                case 'v':
                    str_buf[str_len++] = '\v';
                    break;
                case '0':
                    str_buf[str_len++] = '\0';
                    break;
                case 'x':
                    if (yyleng <= i+2){
                      printf("Error undefined escape sequence x\n");
                      exit(0);
                    }
                    if (((yytext[i+1] >= '0' && yytext[i+1] <= '9') || (yytext[i+1] >= 'a' && yytext[i+1] <= 'f') || (yytext[i+1] >= 'A' && yytext[i+1] <= 'F')) &&
                        ((yytext[i+2] >= '0' && yytext[i+2] <= '9') || (yytext[i+2] >= 'a' && yytext[i+2] <= 'f') || (yytext[i+2] >= 'A' && yytext[i+2] <= 'F'))){
                            int n = hexStrToDecInt(yytext+i+1, 2);
                            str_buf[str_len++] = n;
                            i += 2;
                    } else {
                        printf("Error undefined escape sequence x\n");
                        exit(0);
                    }
                    break;
                default:
                    printf("Error undefined escape sequence %c\n", yytext[i]);
                    exit(0);
            }
        }
    }
}

void startStr(){
    str_len = 0;
    BEGIN(str);
}

void endStr(){
    str_buf[str_len] = '\0';
    printf("%d STRING %s\n", yylineno, str_buf);
    BEGIN(INITIAL);
}

void errorUndefinedChar(){
    printf("Error %c\n", yytext[0]);
    exit(0);
}

void errorUnclosedStr(){
    printf("Error unclosed string\n");
    exit(0);
}

void showTokenEOF(){
    printf("%d EOF \n", yylineno);
    exit(0);
}