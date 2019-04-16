%{

/* Declarations section */
#include <stdio.h>
void showToken(char *);
void showComment(void);

int comment_lines = 1;

%}

%option yylineno
%option noyywrap

digit   		([0-9])
letter  		([a-zA-Z])
alpha           ({letter}|{digit})
whitespace		([\t \x09\x0A\x0D])
textual         ({alpha}|{whitespace})
asci            ([\x20-\x7E]|{whitespace})
newline         ([(\n\r)\n\r])
comment         ([^(\*\/)\n])
name_prefix     ([\-]|{letter})
name_content    ({alpha}|[\_\-])

%x COMMENT

%%

\/\*                                { BEGIN(COMMENT); }
<COMMENT>\*\/                       { BEGIN(INITIAL); showComment(); }
<COMMENT>{newline}                  { comment_lines++; }
<COMMENT>{asci}	                    {;}
<COMMENT><<EOF>>                    {;}

{name_prefix}+{name_content}*       { showToken("NAME"); }
{whitespace}				        {;}
.		                            {printf("Lex doesn't know what that is!\n");}

%%

void showComment()
{
    printf("%d\n", comment_lines);
    comment_lines = 1;
}
void showToken(char * name)
{
        printf("%d %s %s\n", yyleng, name, yytext);
}

