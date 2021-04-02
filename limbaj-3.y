%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
extern FILE* yyin;
extern char* yytext;
extern int yylineno;

char *functie_curenta = NULL;
char *structura_curenta = NULL;
int corect = 1;

struct variabileInBloc_t {
    int numar;
    struct variabileInBloc_t *exterior;
};
struct variabileInBloc_t *variabileInBloc = NULL;

FILE *fisier_tabela;


struct expresie;

struct lista_expresii {
    struct expresie *expr;
    struct lista_expresii *urmator;
};

struct expresie_apel {
    char *fun;
    struct lista_expresii *arg;
};

struct expresie_var {
    char *nume;
    int nr_indexare;
    int indexare[1024];
};

struct expresie_str {
    enum {
        EXPRESIE_STR_VAL,
        EXPRESIE_STR_CONCAT,
        EXPRESIE_STR_APEL,
        EXPRESIE_STR_VAR
    } tip_str;
    char *val;
    struct expresie_str *str1, *str2;
    struct expresie_apel *apel;
    struct expresie_var *var;
};

struct expresie_bool {
    enum {
        EXPRESIE_BOOL_COMP_NUM,
        EXPRESIE_BOOL_COMP_STR,
        EXPRESIE_BOOL_SI,
        EXPRESIE_BOOL_SAU,
        EXPRESIE_BOOL_NEG,
        EXPRESIE_BOOL_VAL,
        EXPRESIE_BOOL_APEL,
        EXPRESIE_BOOL_VAR
    } tip_bool;
    bool val;
    struct expresie_num *expr_comp_num1, *expr_comp_num2;
    struct expresie_str *expr_comp_str1, *expr_comp_str2;
    struct expresie_bool *expr_bool1, *expr_bool2;
    struct expresie_apel *apel;
    struct expresie_var *var;
};

struct expresie_num {
    enum {
        EXPRESIE_NUM_VAL,
        EXPRESIE_NUM_PLUS,
        EXPRESIE_NUM_MINUS,
        EXPRESIE_NUM_INMULTIRE,
        EXPRESIE_NUM_IMPARTIRE,
        EXPRESIE_NUM_APEL,
        EXPRESIE_NUM_VAR
    } tip_expr;
    float val;
    struct expresie_num *expr1, *expr2;
    struct expresie_apel *apel;
    struct expresie_var *var;
};

struct expresie {
    enum {
        EXPRESIE_NUM,
        EXPRESIE_BOOL,
        EXPRESIE_STR,
        EXPRESIE_NEW,
        EXPRESIE_APEL,
        EXPRESIE_VAR
    } tip_expr;
    struct expresie_num *num;
    struct expresie_bool *boolean;
    struct expresie_str *str;
    char *new;
    struct expresie_apel *apel;
    struct expresie_var *var;
};

struct tip_t {
    char *nume;
    int dimensiune;
    int numar[1024];
};

struct lista_param_t {
    struct tip_t *tip;
    char *nume;
    struct lista_param_t *urmator;
};

struct simbol {
    enum {
        SIMBOL_VARIABILA,
        SIMBOL_FUNCTIE,
        SIMBOL_STRUCTURA
    } tip_simbol;
    char *nume;
    char *functie;
    char *structura;
    struct tip_t *tip;
    struct lista_param_t *param;
    struct expresie *init;
};

int nrSimboluri = 0;
struct simbol SymbolTable[1024];

void insertVarTable(char *nume, struct tip_t *tip);
void insertFuncTable(char *nume, struct tip_t *ret, struct lista_param_t *param);
void insertStructTable(char *nume);
void printTable();
void varDefinita(char *nume);
void funDefinita(char *nume);
void structDefinita(char *nume);
struct tip_t *tipVar(char *nume);
struct tip_t *tipRetFun(char *nume);
void tipExpr(struct expresie *expr, struct tip_t *tip);
void tipuriEgale(struct tip_t *stanga, struct tip_t *dreapta);
void apelCorect(struct expresie_apel *apel);

%}

%union
{
    int nr;
    float nrfloat;
    char *stringVal;
    struct expresie* expresie;
    struct expresie_num* expresie_num;
    struct expresie_bool* expresie_bool;
    struct expresie_str* expresie_str;
    struct expresie_apel* expresie_apel;
    struct expresie_var* expresie_var;
    struct lista_expresii *argumente;
    struct tip_t* tip;
    struct lista_param_t *lista_tipuri;
};

%token<stringVal>IDENTIFICATOR
%token<nr>NUMAR
%token<nrfloat> NUMARFLOAT
%token<stringVal>TIP_PRIMITIV
%token<stringVal> VALOARE_STRING
%type<tip>tip
%type<lista_tipuri> lista_param lista_param_nevida
%type<expresie> expresie
%type<expresie_var> variabila
%type<expresie_num> expresie_num subexpresie_num
%type<expresie_bool> expresie_bool subexpresie_bool
%type<expresie_str> expresie_str subexpresie_str
%type<expresie_apel> apel
%type<argumente> lista_argumente lista_argumente_nevida
%token BEGIN_PROG END_PROG MAI_MARE MAI_MIC MAI_MIC_SAU_EGAL MAI_MARE_SAU_EGAL EGALITATE STRUCT FUNC VOID SI SAU NEG TRUE FALSE IF FOR WHILE ELSE IN CONST NEW CONCAT EVAL RETURN STR_MAI_MIC STR_MAI_MARE STR_EGALITATE STR_MAI_MIC_SAU_EGAL STR_MAI_MARE_SAU_EGAL
%start program
%left SAU
%left SI
%left NEG
%left NUM_MAI_MIC NUM_MAI_MARE NUM_EGALITATE NUM_MAI_MIC_SAU_EGAL NUM_MAI_MARE_SAU_EGAL
%left STR_MAI_MIC STR_MAI_MARE STR_EGALITATE STR_MAI_MIC_SAU_EGAL STR_MAI_MARE_SAU_EGAL
%left '+' '-'
%left '*' '/'
%%
  program : lista_decl { printf("Sintaxă corectă\n");
                         if (corect) {
                           printf("Corect semantic\n");
                           printTable();
                         }
                         else
                           printf("Incorect semantic\n");
                       }
          ;


  lista_decl : decl
             | decl lista_decl
             ;

  decl : decl_variabila
       | decl_structura { structura_curenta = NULL; }
       | decl_functie { functie_curenta = NULL; }
       ;

  decl_variabila : tip IDENTIFICATOR ';'       {
                                                structDefinita($1->nume);
                                                insertVarTable($2, $1);
                                                if (variabileInBloc != NULL)
                                                  ++variabileInBloc->numar;
                                                }
                 | tip IDENTIFICATOR '=' expresie ';'   {
                                                         structDefinita($1->nume);
                                                         struct tip_t tip_expr;
                                                         tipExpr($4, &tip_expr);
                                                         tipuriEgale(&tip_expr, $1);
                                                         
                                                         insertVarTable($2, $1);
                                                         if (variabileInBloc != NULL)
                                                           ++variabileInBloc->numar;
                                                     }

                 | CONST tip IDENTIFICATOR '=' expresie ';'     {
                                                     structDefinita($2->nume);
                                                     struct tip_t tip_expr;
                                                     tipExpr($5, &tip_expr);
                                                     tipuriEgale(&tip_expr, $2);
                                                     
                                                     insertVarTable($3, $2);
                                                     if (variabileInBloc != NULL)
                                                       ++variabileInBloc->numar;
                                                     }
                 ;

  atribuire : IDENTIFICATOR '=' expresie ';' {
                                                     varDefinita($1);
                                                     struct tip_t tip_expr;
                                                     tipExpr($3, &tip_expr);
                                                     struct tip_t *tip_var = tipVar($1);
                                                     tipuriEgale(&tip_expr, tip_var);
                                                     
                                             }
            ;

  lista_instr : /* epsilon */
              | lista_instr_nevida
              ;

  lista_instr_nevida : instr
                     | instr lista_instr_nevida
                     ;

  instr : decl_variabila
        | atribuire
        | WHILE subexpresie_bool bloc
        | IF subexpresie_bool bloc
        | IF subexpresie_bool bloc ELSE bloc
        | FOR IDENTIFICATOR IN IDENTIFICATOR bloc
        | apel
        | EVAL '(' subexpresie_num ')' ';'      {if (corect) {
                                                     if((int)$3->val == $3->val)
                                                     {
                                                     printf("Rezultatul expresiei din eval este %d\n", (int)$3->val);
                                                     }
                                                     else {printf("Valorile nu sunt de tip int\n");}}}
        | RETURN expresie ';'
        ;

  bloc : '{' {
               struct variabileInBloc_t *temp = malloc(sizeof(struct variabileInBloc_t));
               temp->numar = 0;
               temp->exterior = variabileInBloc;
               variabileInBloc = temp;
             }
           lista_instr '}' {
               nrSimboluri -= variabileInBloc->numar;
               struct variabileInBloc_t *temp = variabileInBloc;
               variabileInBloc = variabileInBloc->exterior;
               free(temp);
             }
       ;

  decl_functie : FUNC tip IDENTIFICATOR '(' lista_param ')'
                {
                    insertFuncTable($3, $2, $5);
                    functie_curenta = $3;
                }
                bloc
               | FUNC VOID IDENTIFICATOR '(' lista_param ')'
                {
                    insertFuncTable($3, NULL, $5);
                    functie_curenta = $3;
                }
                bloc
               ;

  lista_param : /* epsilon */ { $$ = NULL; }
              | lista_param_nevida { $$ = $1; }
              ;

  lista_param_nevida : tip IDENTIFICATOR ',' lista_param_nevida {
                          for (struct lista_param_t *i = $4; i != NULL; i = i->urmator) {
                              if (strcmp(i->nume, $2) == 0) {
                                 corect = 0;
                                 printf("Parametri cu același nume %s\n", $2);
                              }
                          }
                          $$ = malloc(sizeof(struct lista_param_t));
                          $$->tip = $1;
                          $$->nume = $2;
                          $$->urmator = $4;
                       }
                     | tip IDENTIFICATOR { $$ = malloc(sizeof(struct lista_param_t)); $$->tip = $1; $$->nume = $2; $$->urmator = NULL;}
                     ;

  lista_membri : membru lista_membri
               | membru
               ;

  membru : decl_variabila
         | decl_functie
         ;

  apel : IDENTIFICATOR '(' lista_argumente ')' { funDefinita($1); $$ = malloc(sizeof(struct expresie_apel)); $$->fun = $1; $$->arg = $3; apelCorect($$); }
       ;

  lista_argumente : /* epsilon */ { $$ = NULL; }
                  | lista_argumente_nevida { $$ = $1; }
                  ;

  lista_argumente_nevida : expresie ',' lista_argumente_nevida { $$ = malloc(sizeof(struct lista_expresii)); $$->expr = $1; $$->urmator = $3; }
                         | expresie { $$ = malloc(sizeof(struct lista_expresii)); $$->expr = $1; $$->urmator = NULL; }
                         ;

  expresie : expresie_num { $$ = malloc(sizeof(struct expresie)); $$->tip_expr = EXPRESIE_NUM; $$->num = $1; }
           | expresie_bool { $$ = malloc(sizeof(struct expresie)); $$->tip_expr = EXPRESIE_BOOL; $$->boolean = $1; }
           | expresie_str { $$ = malloc(sizeof(struct expresie)); $$->tip_expr = EXPRESIE_STR; $$->str = $1; }
           | NEW IDENTIFICATOR { structDefinita($2); $$ = malloc(sizeof(struct expresie)); $$->tip_expr = EXPRESIE_NEW; $$->new = $2; }
           | apel { $$ = malloc(sizeof(struct expresie)); $$->tip_expr = EXPRESIE_APEL; $$->apel = $1; }
           | variabila { $$ = malloc(sizeof(struct expresie)); $$->tip_expr = EXPRESIE_VAR; $$->var = $1; }
           ;

  variabila : IDENTIFICATOR { varDefinita($1); $$ = malloc(sizeof(struct expresie_var)); $$->nume = $1; $$->nr_indexare = 0; }
            | variabila '[' NUMAR ']' { $$ = $1; $$->indexare[$$->nr_indexare] = $3; }
            ;

  expresie_num : NUMAR { $$ = malloc(sizeof(struct expresie_num)); $$->tip_expr = EXPRESIE_NUM_VAL; $$->val = $1; }
               | NUMARFLOAT { $$ = malloc(sizeof(struct expresie_num)); $$->tip_expr = EXPRESIE_NUM_VAL; $$->val = $1; }
               | subexpresie_num '+' subexpresie_num { $$ = malloc(sizeof(struct expresie_num)); $$->tip_expr = EXPRESIE_NUM_PLUS; $$->expr1 = $1; $$->expr2 = $3; $$->val = $1->val + $3->val;}
               | subexpresie_num '-' subexpresie_num { $$ = malloc(sizeof(struct expresie_num)); $$->tip_expr = EXPRESIE_NUM_MINUS; $$->expr1 = $1; $$->expr2 = $3; $$->val = $1->val - $3->val; }
               | subexpresie_num '*' subexpresie_num { $$ = malloc(sizeof(struct expresie_num)); $$->tip_expr = EXPRESIE_NUM_INMULTIRE; $$->expr1 = $1; $$->expr2 = $3; $$->val = $1->val * $3->val; }
               | subexpresie_num '/' subexpresie_num { $$ = malloc(sizeof(struct expresie_num)); $$->tip_expr = EXPRESIE_NUM_IMPARTIRE; $$->expr1 = $1; $$->expr2 = $3; $$->val = $1->val / $3->val; }
               ;

  subexpresie_num : NUMAR { $$ = malloc(sizeof(struct expresie_num)); $$->tip_expr = EXPRESIE_NUM_VAL; $$->val = $1; }
                  | NUMARFLOAT { $$ = malloc(sizeof(struct expresie_num)); $$->tip_expr = EXPRESIE_NUM_VAL; $$->val = $1; }
                  | subexpresie_num '+' subexpresie_num { $$ = malloc(sizeof(struct expresie_num)); $$->tip_expr = EXPRESIE_NUM_PLUS; $$->expr1 = $1; $$->expr2 = $3; $$->val = $1->val + $3->val;}
                  | subexpresie_num '-' subexpresie_num { $$ = malloc(sizeof(struct expresie_num)); $$->tip_expr = EXPRESIE_NUM_MINUS; $$->expr1 = $1; $$->expr2 = $3; $$->val = $1->val - $3->val;}
                  | subexpresie_num '*' subexpresie_num { $$ = malloc(sizeof(struct expresie_num)); $$->tip_expr = EXPRESIE_NUM_INMULTIRE; $$->expr1 = $1; $$->expr2 = $3; $$->val = $1->val * $3->val;}
                  | subexpresie_num '/' subexpresie_num { $$ = malloc(sizeof(struct expresie_num)); $$->tip_expr = EXPRESIE_NUM_IMPARTIRE; $$->expr1 = $1; $$->expr2 = $3; $$->val = $1->val / $3->val;}
                  | '(' expresie_num ')' { $$ = $2; }
                  | variabila {
                      $$ = malloc(sizeof(struct expresie_num));
                      $$->tip_expr = EXPRESIE_NUM_VAR;
                      $$->var = $1;
                      struct tip_t *tip_var = tipVar($$->var->nume);
                      struct tip_t tip_int = {.nume = "int", .dimensiune = 0};
                      tipuriEgale(tip_var, &tip_int);
                     }
                  | apel {
                      $$ = malloc(sizeof(struct expresie_num));
                      $$->tip_expr = EXPRESIE_NUM_APEL;
                      $$->apel = $1;
                      struct tip_t *tip_apel = tipRetFun($$->apel->fun);
                      struct tip_t tip_int = {.nume = "int", .dimensiune = 0};
                      tipuriEgale(tip_apel, &tip_int);
                     }
                  ;


  expresie_bool : subexpresie_num comparare_num subexpresie_num {
                        $$ = malloc(sizeof(struct expresie_bool));
                        $$->tip_bool = EXPRESIE_BOOL_COMP_NUM;
                        $$->expr_comp_num1 = $1;
                        $$->expr_comp_num2 = $3;
                    }
                | comparare_str '(' subexpresie_str ',' subexpresie_str ')' {
                        $$ = malloc(sizeof(struct expresie_bool));
                        $$->tip_bool = EXPRESIE_BOOL_COMP_STR;
                        $$->expr_comp_str1 = $3;
                        $$->expr_comp_str2 = $5;
                    }
                | subexpresie_bool SI subexpresie_bool {
                        $$ = malloc(sizeof(struct expresie_bool));
                        $$->tip_bool = EXPRESIE_BOOL_SI;
                        $$->expr_bool1 = $1;
                        $$->expr_bool2 = $3;
                     }
                | subexpresie_bool SAU subexpresie_bool {
                        $$ = malloc(sizeof(struct expresie_bool));
                        $$->tip_bool = EXPRESIE_BOOL_SAU;
                        $$->expr_bool1 = $1;
                        $$->expr_bool2 = $3;
                     }
                | NEG subexpresie_bool {
                        $$ = malloc(sizeof(struct expresie_bool));
                        $$->tip_bool = EXPRESIE_BOOL_NEG;
                        $$->expr_bool1 = $2;
                     }
                | TRUE { $$ = malloc(sizeof(struct expresie_bool)); $$->tip_bool = EXPRESIE_BOOL_VAL; $$->val = true; }
                | FALSE { $$ = malloc(sizeof(struct expresie_bool));  $$->tip_bool = EXPRESIE_BOOL_VAL; $$->val = false; }
                ;

  subexpresie_bool : subexpresie_num comparare_num subexpresie_num {
                        $$ = malloc(sizeof(struct expresie_bool));
                        $$->tip_bool = EXPRESIE_BOOL_COMP_NUM;
                        $$->expr_comp_num1 = $1;
                        $$->expr_comp_num2 = $3;
                    }
                  | comparare_str '(' subexpresie_str ',' subexpresie_str ')' {
                        $$ = malloc(sizeof(struct expresie_bool));
                        $$->tip_bool = EXPRESIE_BOOL_COMP_STR;
                        $$->expr_comp_str1 = $3;
                        $$->expr_comp_str2 = $5;
                    }

                  | subexpresie_bool SI subexpresie_bool {
                        $$ = malloc(sizeof(struct expresie_bool));
                        $$->tip_bool = EXPRESIE_BOOL_SI;
                        $$->expr_bool1 = $1;
                        $$->expr_bool2 = $3;
                     }
                  | subexpresie_bool SAU subexpresie_bool {
                        $$ = malloc(sizeof(struct expresie_bool));
                        $$->tip_bool = EXPRESIE_BOOL_SAU;
                        $$->expr_bool1 = $1;
                        $$->expr_bool2 = $3;
                     }
                  | NEG subexpresie_bool {
                        $$ = malloc(sizeof(struct expresie_bool));
                        $$->tip_bool = EXPRESIE_BOOL_NEG;
                        $$->expr_bool1 = $2;
                     }
                  | TRUE { $$ = malloc(sizeof(struct expresie_bool));  $$->tip_bool = EXPRESIE_BOOL_VAL; $$->val = true; }
                  | FALSE { $$ = malloc(sizeof(struct expresie_bool));  $$->tip_bool = EXPRESIE_BOOL_VAL; $$->val = false; }
                | '(' subexpresie_bool ')' { $$ = $2; }
                | apel {
                         $$ = malloc(sizeof(struct expresie_bool));
                         $$->tip_bool = EXPRESIE_BOOL_APEL;
                         $$->apel = $1;
                         struct tip_t *tip_apel = tipRetFun($$->apel->fun);
                         struct tip_t tip_bool = {.nume = "bool", .dimensiune = 0};
                         tipuriEgale(tip_apel, &tip_bool);
                       }
                | variabila {
                      $$ = malloc(sizeof(struct expresie_bool));
                      $$->tip_bool = EXPRESIE_BOOL_VAR;
                      $$->var = $1;
                      struct tip_t *tip_var = tipVar($$->var->nume);
                      struct tip_t tip_bool = {.nume = "bool", .dimensiune = 0};
                      tipuriEgale(tip_var, &tip_bool);
                    }
                ;

  comparare_num : NUM_MAI_MARE
                | NUM_MAI_MIC
                | NUM_EGALITATE
                | NUM_MAI_MIC_SAU_EGAL
                | NUM_MAI_MARE_SAU_EGAL
                ;

  comparare_str : STR_MAI_MARE
                | STR_MAI_MIC
                | STR_EGALITATE
                | STR_MAI_MIC_SAU_EGAL
                | STR_MAI_MARE_SAU_EGAL
                ;

  expresie_str : VALOARE_STRING { $$ = malloc(sizeof(struct expresie_str)); $$->tip_str = EXPRESIE_STR_VAL; $$->val = $1; }
               | CONCAT '(' subexpresie_str ',' subexpresie_str ')' { $$ = malloc(sizeof(struct expresie_str)); $$->tip_str = EXPRESIE_STR_CONCAT; $$->str1 = $3; $$->str2 = $5; }
               ;

  subexpresie_str : VALOARE_STRING { $$ = malloc(sizeof(struct expresie_str)); $$->tip_str = EXPRESIE_STR_VAL; $$->val = $1; }
                  | CONCAT '(' subexpresie_str ',' subexpresie_str ')' { $$ = malloc(sizeof(struct expresie_str)); $$->tip_str = EXPRESIE_STR_CONCAT; $$->str1 = $3; $$->str2 = $5;}
                  | '(' subexpresie_str ')' { $$ = $2; }
                  | apel {
                      $$ = malloc(sizeof(struct expresie_str));
                      $$->tip_str = EXPRESIE_STR_APEL;
                      $$->apel = $1;
                      struct tip_t *tip_apel = tipRetFun($$->apel->fun);
                      struct tip_t tip_str = {.nume = "string", .dimensiune = 0};
                      tipuriEgale(tip_apel, &tip_str);
                   }
                  | variabila {
                      $$ = malloc(sizeof(struct expresie_str));
                      $$->tip_str = EXPRESIE_STR_VAR;
                      $$->var = $1;
                      struct tip_t *tip_var = tipVar($$->var->nume);
                      struct tip_t tip_str = {.nume = "string", .dimensiune = 0};
                      tipuriEgale(tip_var, &tip_str);
                    }
                  ;

  decl_structura : STRUCT IDENTIFICATOR {
                    insertStructTable($2);
                    structura_curenta = $2;
                }
                   '{' lista_membri '}'
                 ;

  tip : TIP_PRIMITIV { $$ = malloc(sizeof(struct tip_t)); $$->nume = $1; $$->dimensiune = 0; }
      | IDENTIFICATOR { $$ = malloc(sizeof(struct tip_t)); $$->nume = $1; $$->dimensiune = 0; }
      | tip '[' NUMAR ']' { $$ = $1;  $$->numar[$$->dimensiune] = $3; $$->dimensiune += 1; }
      ;


%%


void yyerror(char * s){
    printf("eroare: %s la linia:%d\n",s,yylineno);
}


void checkTable(char* nume)
{
    int i;
    for( i=0; i<nrSimboluri; i++)
    {
        if (((structura_curenta == NULL && SymbolTable[i].structura == NULL) ||
             (structura_curenta != NULL && SymbolTable[i].structura != NULL &&
              strcmp(structura_curenta, SymbolTable[i].structura) == 0)) &&
            ((functie_curenta == NULL && SymbolTable[i].functie == NULL) ||
             (functie_curenta != NULL && SymbolTable[i].functie != NULL &&
              strcmp(functie_curenta, SymbolTable[i].functie) == 0)) &&
            (strcmp(SymbolTable[i].nume, nume) == 0))
        {
            printf("%s ", nume);
            if (functie_curenta != NULL)
                printf("din functia %s ", functie_curenta);
            if (structura_curenta != NULL)
                printf("din structura %s ", structura_curenta);
            printf("deja există\n");
            corect = 0;
            break;
        }
    }
}

void insertVarTable(char *nume, struct tip_t *tip)
{
    checkTable(nume);
    SymbolTable[nrSimboluri].tip_simbol = SIMBOL_VARIABILA;
    SymbolTable[nrSimboluri].nume = nume;
    SymbolTable[nrSimboluri].functie = functie_curenta;
    SymbolTable[nrSimboluri].structura = structura_curenta;
    SymbolTable[nrSimboluri].tip = tip;

    nrSimboluri++;

}

void insertFuncTable(char *nume, struct tip_t *ret, struct lista_param_t *param)
{
    checkTable(nume);
    SymbolTable[nrSimboluri].tip_simbol = SIMBOL_FUNCTIE;
    SymbolTable[nrSimboluri].nume = nume;
    SymbolTable[nrSimboluri].structura = structura_curenta;
    SymbolTable[nrSimboluri].tip = ret;
    SymbolTable[nrSimboluri].param = param;
    nrSimboluri++;
}

void insertStructTable(char *nume)
{
    checkTable(nume);
    SymbolTable[nrSimboluri].tip_simbol = SIMBOL_STRUCTURA;
    SymbolTable[nrSimboluri].nume = nume;
    nrSimboluri++;
}

void printTip(FILE *f, struct tip_t *tip) {
    if (tip != NULL) {
        fprintf(f, "%s", tip->nume);
        for (int j = 0; j < tip->dimensiune; ++j)
            fprintf(f, "[%d]", tip->numar[j]);
    } else {
        fprintf(f, "void");
    }
}

void printTable() {
  fisier_tabela = fopen("symbol_table.txt", "w");
  for (int i = 0; i < nrSimboluri; ++i) {
      if (SymbolTable[i].tip_simbol == SIMBOL_VARIABILA) {
        fprintf(fisier_tabela, "%s\t", SymbolTable[i].nume);
        printTip(fisier_tabela, SymbolTable[i].tip);
        fprintf(fisier_tabela, "\t");
        if (SymbolTable[i].structura == NULL &&
            SymbolTable[i].functie == NULL)
            fprintf(fisier_tabela, "globala\t");
        if (SymbolTable[i].structura != NULL &&
            SymbolTable[i].functie == NULL)
            fprintf(fisier_tabela, "membru\t");
        if (SymbolTable[i].functie != NULL)
            fprintf(fisier_tabela, "locala\t");
        if (SymbolTable[i].structura != NULL)
          fprintf(fisier_tabela, "în struct %s\t", SymbolTable[i].structura);
        if (SymbolTable[i].functie != NULL)
          fprintf(fisier_tabela, "în func %s\t", SymbolTable[i].functie);
        fprintf(fisier_tabela, "\n");

      } else if (SymbolTable[i].tip_simbol == SIMBOL_FUNCTIE) {
          fprintf(fisier_tabela, "%s\t", SymbolTable[i].nume);
          if (SymbolTable[i].tip != NULL)
              fprintf(fisier_tabela, "%s", SymbolTable[i].tip->nume);
          else
              fprintf(fisier_tabela, "void");
          fprintf(fisier_tabela, "(");
          for (struct lista_param_t *j = SymbolTable[i].param; j != NULL; j = j->urmator) {
              printTip(fisier_tabela, j->tip);
              if (j->urmator != NULL)
                  fprintf(fisier_tabela, ", ");
          }
          fprintf(fisier_tabela, ")\t");
          if (SymbolTable[i].structura != NULL)
              fprintf(fisier_tabela, "metodă\tîn struct %s\t", SymbolTable[i].structura);
          else
              fprintf(fisier_tabela, "func\t");
          fprintf(fisier_tabela, "\n");
      } else {
          fprintf(fisier_tabela, "%s\tstruct\n", SymbolTable[i].nume);
      }
  }
  fclose(fisier_tabela);
}

void varDefinita(char *nume) {
    for (int i = 0; i < nrSimboluri; ++i) {
        if (SymbolTable[i].tip_simbol == SIMBOL_VARIABILA && strcmp(SymbolTable[i].nume, nume) == 0) {
            if (SymbolTable[i].functie == NULL && SymbolTable[i].structura == NULL)
                return;
            if (SymbolTable[i].functie == NULL && SymbolTable[i].structura != NULL &&
                structura_curenta != NULL &&
                strcmp(SymbolTable[i].structura, structura_curenta) == 0)
                return;
            if (SymbolTable[i].functie != NULL && SymbolTable[i].structura == NULL &&
                structura_curenta == NULL && functie_curenta != NULL &&
                structura_curenta == NULL && strcmp(SymbolTable[i].functie, functie_curenta) == 0)
                return;
            if (SymbolTable[i].functie != NULL && SymbolTable[i].structura != NULL &&
                functie_curenta != NULL && structura_curenta != NULL &&
                strcmp(SymbolTable[i].functie, functie_curenta) == 0 &&
                strcmp(SymbolTable[i].structura, structura_curenta) == 0)
                return;
        } else if (functie_curenta != NULL &&
                   SymbolTable[i].tip_simbol == SIMBOL_FUNCTIE &&
                   strcmp(SymbolTable[i].nume, functie_curenta) == 0) {
            for (struct lista_param_t *j = SymbolTable[i].param; j != NULL; j = j->urmator) {
                if (strcmp(j->nume, nume) == 0)
                    return;
            }
        }
    }
    corect = 0;
    printf("Variabila %s nu a fost definită\n", nume);
}

void funDefinita(char *nume) {
    for (int i = 0; i < nrSimboluri; ++i) {
        if (SymbolTable[i].tip_simbol == SIMBOL_FUNCTIE && strcmp(SymbolTable[i].nume, nume) == 0) {
            if (SymbolTable[i].structura != NULL && structura_curenta != NULL &&
                strcmp(SymbolTable[i].structura, structura_curenta) == 0)
                return;
            if (SymbolTable[i].structura == NULL)
                return;
        }
    }
    corect = 0;
    printf("Funcția %s nu a fost definită\n", nume);
}

void structDefinita(char *nume) {
    if (strcmp(nume, "int") == 0 ||
        strcmp(nume, "float") == 0 ||
        strcmp(nume, "char") == 0 ||
        strcmp(nume, "string") == 0 ||
        strcmp(nume, "bool") == 0)
        return;
    for (int i = 0; i < nrSimboluri; ++i) {
        if (SymbolTable[i].tip_simbol == SIMBOL_STRUCTURA && strcmp(SymbolTable[i].nume, nume) == 0) {
            return;
        }
    }
    corect = 0;
    printf("Structura %s nu a fost definită\n", nume);
}

struct tip_t *tipVar(char *nume) {
    struct tip_t *rezultat = NULL;
    for (int i = 0; i < nrSimboluri; ++i) {
        if (SymbolTable[i].tip_simbol == SIMBOL_VARIABILA && strcmp(SymbolTable[i].nume, nume) == 0) {
            if (SymbolTable[i].functie == NULL && SymbolTable[i].structura == NULL)
                rezultat = SymbolTable[i].tip;
            if (SymbolTable[i].functie == NULL && SymbolTable[i].structura != NULL &&
                structura_curenta != NULL &&
                strcmp(SymbolTable[i].structura, structura_curenta) == 0)
                rezultat = SymbolTable[i].tip;
            if (SymbolTable[i].functie != NULL && SymbolTable[i].structura == NULL &&
                structura_curenta == NULL && functie_curenta != NULL &&
                structura_curenta == NULL && strcmp(SymbolTable[i].functie, functie_curenta) == 0)
                rezultat = SymbolTable[i].tip;
            if (SymbolTable[i].functie != NULL && SymbolTable[i].structura != NULL &&
                functie_curenta != NULL && structura_curenta != NULL &&
                strcmp(SymbolTable[i].functie, functie_curenta) == 0 &&
                strcmp(SymbolTable[i].structura, structura_curenta) == 0)
                rezultat = SymbolTable[i].tip;
        } else if (functie_curenta != NULL &&
                   SymbolTable[i].tip_simbol == SIMBOL_FUNCTIE &&
                   strcmp(SymbolTable[i].nume, functie_curenta) == 0) {
            for (struct lista_param_t *j = SymbolTable[i].param; j != NULL; j = j->urmator) {
                if (strcmp(j->nume, nume) == 0)
                    rezultat = j->tip;
            }
        }
    }
    return rezultat;
}

struct tip_t *tipRetFun(char *nume) {
    struct tip_t *rezultat = NULL;
    for (int i = 0; i < nrSimboluri; ++i) {
        if (SymbolTable[i].tip_simbol == SIMBOL_FUNCTIE && strcmp(SymbolTable[i].nume, nume) == 0) {
            if (SymbolTable[i].structura != NULL && structura_curenta != NULL &&
                strcmp(SymbolTable[i].structura, structura_curenta) == 0)
                return SymbolTable[i].tip;
            if (SymbolTable[i].structura == NULL)
                rezultat = SymbolTable[i].tip;
        }
    }
    return rezultat;
}

void tipExpr(struct expresie *expr, struct tip_t *tip) {
    if (expr->tip_expr == EXPRESIE_NUM) {
        tip->nume = "int";
        tip->dimensiune = 0;
    } else if (expr->tip_expr == EXPRESIE_BOOL) {
        tip->nume = "bool";
        tip->dimensiune = 0;
    } else if (expr->tip_expr == EXPRESIE_STR) {
        tip->nume = "string";
        tip->dimensiune = 0;
    } else if (expr->tip_expr == EXPRESIE_NEW) {
        tip->nume = expr->new;
        tip->dimensiune = 0;
    } else if (expr->tip_expr == EXPRESIE_APEL) {
        tip = tipRetFun(expr->apel->fun);
    } else if (expr->tip_expr == EXPRESIE_VAR) {
        tip = tipVar(expr->var->nume);
    }
}

void tipuriEgale(struct tip_t *stanga, struct tip_t *dreapta) {
    int egale = 1;
    if (stanga != NULL && dreapta != NULL) {
        if ((strcmp(stanga->nume, dreapta->nume) == 0 ||
             (strcmp(stanga->nume, "int") == 0 && strcmp(dreapta->nume, "float") == 0) ||
             (strcmp(dreapta->nume, "int") == 0 && strcmp(stanga->nume, "float") == 0)) &&
            stanga->dimensiune == dreapta->dimensiune) {
            for (int i = 0; i < stanga->dimensiune; ++i)
                if (stanga->numar[i] == dreapta->numar[i]) {
                    egale = 0;
                    break;
                }
                else
                    egale = 0;
        } else {
            egale = 0;
        }
    } else {
        egale = 0;
    }
    if (egale == 0) {
        corect = 0;
        printTip(stdout, stanga);
        printf(" nu este compatibil cu ");
        printTip(stdout, dreapta);
        printf("\n");
    }
}

void apelCorect(struct expresie_apel *apel) {
    struct lista_param_t *param = NULL;

    for (int i = 0; i < nrSimboluri; ++i) {
        if (SymbolTable[i].tip_simbol == SIMBOL_FUNCTIE && strcmp(SymbolTable[i].nume, apel->fun) == 0) {
            if (SymbolTable[i].structura != NULL && structura_curenta != NULL &&
                strcmp(SymbolTable[i].structura, structura_curenta) == 0) {
                param = SymbolTable[i].param;
                break;
            }
            if (SymbolTable[i].structura == NULL) {
                param = SymbolTable[i].param;
                break;
            }
        }
    }

    struct lista_expresii *arg = apel->arg;

    while (param != NULL && arg != NULL) {
        struct tip_t tip_expr;
        tipExpr(arg->expr, &tip_expr);
        tipuriEgale(&tip_expr, param->tip);
        param = param->urmator;
        arg = arg->urmator;
    }
    if (param != NULL || arg != NULL) {
        corect = 0;
        printf("În apelul funcției %s numărul de argumente este greșit\n", apel->fun);
    }
}

int main(int argc, char** argv){
    yyin=fopen(argv[1],"r");
    yyparse();
}
