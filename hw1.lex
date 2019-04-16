%{

/* Declarations section */
#include <stdio.h>
#include <stdarg.h>

#define INT_LENGTH 20
#define STR_LENGTH 1024
void showToken(char*, char*);
void showComment(void);
void error(const char* fmt, ...);
void showString();
void str_add_escaped(char*);
void str_add_asci_escaped(char*);
void str_add_char(char);

int comment_lines = 1;
char string_buffer[STR_LENGTH] = { 0 };
int string_cursor = 0;

%}

%option yylineno
%option noyywrap

digit   		([0-9])
letter  		([a-zA-Z])
alpha           ({letter}|{digit})
whitespace		([\t \x09\x0A\x0D])
textual         ({alpha}|{whitespace})
asci            ([\x20-\x7E]|{whitespace})
escape          (\\n|\\r|\\t|\\\\)
asci_escape     (\\{hexa}{1,6})
newline         ([(\n\r)\n\r])
comment         ([^(\*\/)\n])
name_prefix     ([\-]{letter}|{letter})
name_content    ({alpha}|[\_\-])
hash_prefix     ([\-]{letter}|{digit}|{letter})
important       ([iI][mM][pP][oO][rR][tT][aA][nN][tT])
hexa            ([0-9a-fA-F])

%x COMMENT
%x DOUBLE_STRING
%x SINGLE_STRING

%%

\/\*                                { BEGIN(COMMENT); }
<COMMENT>\*\/                       { BEGIN(INITIAL); showComment(); }
<COMMENT>{newline}                  { comment_lines++; }
<COMMENT>{asci}	                    {;}
<COMMENT><<EOF>>                    { error("Error unclosed commend"); }

\'                                  { BEGIN(SINGLE_STRING); }
<SINGLE_STRING>\'                   { BEGIN(INITIAL); showString();}
<SINGLE_STRING><<EOF>>              { error("unclosed string"); }
<SINGLE_STRING>{newline}            { error("unclosed string"); }
<SINGLE_STRING>{escape}             { str_add_escaped(yytext); }
<SINGLE_STRING>{asci_escape}        { str_add_asci_escaped(yytext); }
<SINGLE_STRING>\\{asci}             { error("undefined escape sequence %s", yytext + 1); }
<SINGLE_STRING>{asci}               { str_add_char(yytext[0]); }
<SINGLE_STRING>.                    { error("%s", yytext); }

{name_prefix}+{name_content}*       { showToken("NAME", yytext); }
#{hash_prefix}+{name_content}*      { showToken("HASHID", yytext); }
@import                             { showToken("IMPORT", yytext); }
!{whitespace}*{important}           { showToken("IMPORTANT", yytext); }

{whitespace}				        {;}
.		                            {printf("Error %s\n", yytext);}

%%

void showComment()
{
    printf("1 COMMENT %d\n", comment_lines);
    comment_lines = 1;
}

void showToken(char* name, char* content)
{
    printf("1 %s %s\n", name, content);
}

void error(const char* fmt, ...)
{
    va_list argptr;
    va_start(argptr, fmt);
    
    printf("Error ");
    vfprintf(stdout, fmt, argptr);
    printf("\n");

    va_end(argptr);
    exit(0);
}

void showString()
{
    showToken("STRING", (char*) string_buffer);
    string_cursor = 0;
}

void str_add_char(char c)
{
    string_buffer[string_cursor++] =  c;
}

void str_add_escaped(char* str)
{
    str_add_char(str[0]);
    str_add_char(str[1]);
}

void str_add_asci_escaped(char* str)
{
    char escaped_char;
    int hex_value;
    sscanf(str + 1, "%x", &hex_value);
    printf("debug %d\n", hex_value);
    if( hex_value < 0x20 || hex_value > 0x7e )
    {
        error("undefined escape sequence %s", str + 1);
    }
    escaped_char = (char) hex_value;
    str_add_char(escaped_char);
}