%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>

// error
void yyerror(const char *message);

// define AST node structure
typedef struct astNode{
		char name[100];
		char dataType[20];
		int ival;
		struct astNode *left, *right;       // left node pointer and right node pointer
}ASTNODE;

// status
typedef struct nameList{
	char name[100];
	int inFun;                                // 1 means in the function; 0 means outside the function
	struct astNode *astRoot;     // AST root
	struct nameList *next;         // the pointer that point to the next nameList
}NAMELIST;

// define the original function
ASTNODE* newNode(ASTNODE *left ,ASTNODE *right, char *dataType);
ASTNODE* doAST(ASTNODE *root);
ASTNODE* findDefAst(ASTNODE* root,int inFun);
void doDef(ASTNODE* astRoot);
NAMELIST *nameHead=NULL;
void doFunCall(ASTNODE *astRoot);
void doDefFun(ASTNODE *astRoot);
ASTNODE* colone(ASTNODE* root);
NAMELIST* coloneName(NAMELIST* root);
int inFunFlag;                                                                 // determine whether is inside the function
%}

%union{
	char name[100];
	int ival;
	struct astNode *ast;    // AST node pointer
}

// define datatype and token 
%token 	<ival>	number boolVal 
%token 	<name>	id
%token 	<ast>	printNum printBool mod and or not token define fun ifs

// define different expression type and return type
%type 	<ast>	EXP STMT STMTS PRINT-STMT NUM-OP PLUS MINUS MULTIPLY DIVIDE MODULUS 
				GREATER SMALLER EQUAL LOGICAL-OP AND-OP OR-OP NOT-OP EXPAND EXPOR EXPEQUAL
				DEF-STMT VARIABLE 
				FUN-EXP FUN-IDs FUN-BODY FUN-CALL PARAM FUN-NAME IF-EXP TEST-EXP  THEN-EXP ELSE-EXP EXPPLUS EXPMULTIPLY IDSTAR PARAMSTART 
%left '(' ')'            //  the definition of left and right brackets
%%

// define every function: given grammar
PROGRAM		:	STMTS				{}         
			;
STMTS		:	STMT STMTS			{}       
			|	STMT				{}      
			;
STMT 		:	EXP {$$=$1;}
			|	DEF-STMT {$$=$1;}
			|	PRINT-STMT	{$$=$1;}
PRINT-STMT	:	'(' printNum EXP ')' {$$=newNode($3,NULL,"printNum");doAST($$);}
			|	'(' printBool EXP')' {$$=newNode($3,NULL,"printBool");doAST($$);}
EXP 		:	boolVal 			{$$=newNode(NULL,NULL,"NUM");$$->ival=$1;}
			| 	number 				{$$=newNode(NULL,NULL,"NUM");$$->ival=$1;}
			| 	VARIABLE 			{$$=$1;}
			| 	NUM-OP 				{$$=$1;}
			| 	LOGICAL-OP			{$$=$1;}
			|	FUN-EXP 			{$$=$1;}
			| 	FUN-CALL 			{$$=$1;}
			|	IF-EXP 				{$$=$1;}
NUM-OP 		:	PLUS  				{$$=$1;}
			|	MINUS  				{$$=$1;}
			| 	MULTIPLY  			{$$=$1;}
			| 	DIVIDE  			{$$=$1;}
			| 	MODULUS  			{$$=$1;}
			|	GREATER 			{$$=$1;}
			| 	SMALLER  			{$$=$1;}
			| 	EQUAL 				{$$=$1;}
PLUS 		:	'(' '+' EXP EXPPLUS ')'		{$$=newNode($3,$4,"+");}
MINUS 		:	'(' '-' EXP EXP ')' 		{$$=newNode($3,$4,"-");}
MULTIPLY 	:	'(' '*' EXP EXPMULTIPLY ')'	{$$=newNode($3,$4,"*");} 	
DIVIDE		:	'(' '/' EXP EXP ')' 		{$$=newNode($3,$4,"/");}
MODULUS 	:	'(' mod EXP EXP ')' 		{$$=newNode($3,$4,"mod");}
GREATER 	:	'(' '>' EXP EXP ')' 		{$$=newNode($3,$4,">");}
SMALLER 	:	'(' '<' EXP EXP ')' 		{$$=newNode($3,$4,"<");}
EQUAL 		:	'(' '=' EXP EXPEQUAL ')' 	{$$=newNode($3,$4,"=");}
LOGICAL-OP 	:	AND-OP 						{$$=$1;}
			|	OR-OP  						{$$=$1;}
			|	NOT-OP						{$$=$1;}
AND-OP 		:	'('	and EXP EXPAND ')' 		{$$=newNode($3,$4,"&");}
OR-OP 		:	'(' or EXP EXPOR ')' 		{$$=newNode($3,$4,"|");}
NOT-OP 		:	'(' not EXP ')' 			{$$=newNode($3,NULL,"!");}
DEF-STMT 	:	'(' define VARIABLE EXP ')' {$$=newNode($3,$4,"define");doDef($$);}
VARIABLE	:	id							{$$=newNode(NULL, NULL, "id"); strcpy($$->name,$1);}
FUN-EXP 	:	'(' fun FUN-IDs FUN-BODY ')'{$$=newNode($3,$4,"fun");}
FUN-IDs		:	'(' IDSTAR ')' 				{$$=$2;}
FUN-BODY 	:	EXP							{$$=$1;}
FUN-CALL 	:	'(' FUN-EXP PARAMSTART ')'  {$$=newNode($2,$3,"funcall");}//call
			| 	'(' FUN-NAME PARAMSTART ')' {$2=newNode($2,$3,"funcall");$$=newNode($2,NULL,"funNamecall");}//call
PARAM 		:	EXP							{$$=$1;}
FUN-NAME 	:	id							{$$=newNode(NULL, NULL, "id"); strcpy($$->name,$1);}
IF-EXP		:	'(' ifs TEST-EXP THEN-EXP ELSE-EXP ')' 	{$4=newNode($4,$5,"ifElseDo");$$=newNode($3,$4,"if"); }
TEST-EXP 	:	EXP							{$$=$1;}
THEN-EXP	:	EXP							{$$=$1;}
ELSE-EXP 	:	EXP							{$$=$1;}
EXPPLUS		:	EXP EXPPLUS					{$$=newNode($1,$2,"+");}
			|	EXP 						{$$=$1;}
EXPMULTIPLY	:	EXP EXPMULTIPLY				{$$=newNode($1,$2,"*");}
			|	EXP 						{$$=$1;}
EXPAND		:	EXP EXPAND					{$$=newNode($1,$2,"&");}
			|	EXP 						{$$=$1;}
EXPOR		:	EXP EXPOR					{$$=newNode($1,$2,"|");}
			|	EXP 						{$$=$1;}
EXPEQUAL	:	EXP EXPEQUAL				{$$=newNode($1,$2,"=");}
			|	EXP 						{$$=$1;}
IDSTAR		:	id IDSTAR					{$$=newNode($2, NULL, "funid"); strcpy($$->name,$1);}
			|								{$$ = newNode(NULL, NULL, "empty");}
PARAMSTART	:	PARAM PARAMSTART			{$$=newNode($1,$2, "param");}
			|								{$$ = newNode(NULL, NULL, "empty");}
%%

// define STMT: store the data
ASTNODE* newNode(ASTNODE *left ,ASTNODE *right, char *dataType){
	ASTNODE *ast =(ASTNODE *)malloc(sizeof(ASTNODE));             // generate a tree
	strcpy(ast->dataType,dataType);                  // copy and store the data type
	ast->left=left;                                                  // store left node
	ast->right=right;                                             // store right node
	return ast;
}

// calculate
ASTNODE* doAST(ASTNODE *root){
	// check if it's NULL
	if(root==NULL||!strcmp(root->dataType,"empty")){	return ;}
	// 2. Print Num
	else if(!strcmp(root->dataType,"printNum")){
		doAST(root->left);
		printf("%d\n",root->left->ival);
	}
	// 2. Print Bool
	else if(!strcmp(root->dataType,"printBool")){
		doAST(root->left);
		// if  value equals 1, it's true, then print "#t"
		if(root->left->ival==1){
			printf("#t\n");
		}
		else{
			printf("#f\n");
		}
	}
	// 3. Expression: determine which operation
	else if(!strcmp(root->dataType,"NUM")){
		return ;
	}
	// 4. Numerical Operation
	// add
	else if(!strcmp(root->dataType,"+")){
		doAST(root->left);
		doAST(root->right);
		root->ival=root->left->ival+root->right->ival;
	}
	// sub
	else if(!strcmp(root->dataType,"-")){
		doAST(root->left);
		doAST(root->right);
		root->ival=root->left->ival-root->right->ival;
	}
	// mul
	else if(!strcmp(root->dataType,"*")){
		doAST(root->left);
		doAST(root->right);
		root->ival=root->left->ival*root->right->ival;
	}
	// div
	else if(!strcmp(root->dataType,"/")){
		doAST(root->left);
		doAST(root->right);
		root->ival=root->left->ival/root->right->ival;
	}
	// mod
	else if(!strcmp(root->dataType,"mod")){
		doAST(root->left);
		doAST(root->right);
		if(root->right->ival==0){                      // check if the denominator equals to zero
			root->ival=0;
			return ;
		}
		root->ival=root->left->ival%root->right->ival;
	}
	// greater
	else if(!strcmp(root->dataType,">")){
		doAST(root->left);
		doAST(root->right);
		if(root->left->ival>root->right->ival){              // determine if left node is greater than right node
			root->ival=1;
		}
		else{
			root->ival=0;
		}
	}
	// smaller
	else if(!strcmp(root->dataType,"<")){
		doAST(root->left);
		doAST(root->right);
		if(root->left->ival<root->right->ival){              // determine if left node is smaller than right node
			root->ival=1;
		}
		else{
			root->ival=0;
		}
	}
	// equal
	else if(!strcmp(root->dataType,"=")){
		doAST(root->left);
		doAST(root->right);
		if(root->left->ival==root->right->ival){              // determine if left node is equals to right node
			root->ival=1;
		}
		else{
			root->ival=0;
		}
	}
	// 5. Logical Expression
	// AND
	else if(!strcmp(root->dataType,"&")){
		doAST(root->left);
		doAST(root->right);
		root->ival=(root->left->ival)&&(root->right->ival);
	}
	// OR
	else if(!strcmp(root->dataType,"|")){
		doAST(root->left);
		doAST(root->right);
		root->ival=(root->left->ival)||(root->right->ival);
	}
	// NOT
	else if(!strcmp(root->dataType,"!")){
		doAST(root->left);
		root->ival=!(root->left->ival);
	}
	// if
	else if(!strcmp(root->dataType,"if")){
		doAST(root->left);					
		if(root->left->ival==1){              
			doAST(root->right->left);           // then keep traversing to the left child node of the right node 
			root->ival=root->right->left->ival;     
		}
		else{
			doAST(root->right->right);          // traverse to the right child node of the right node
			root->ival=root->right->right->ival;
		}
	}	
	// 6. Define
	else if(!strcmp(root->dataType,"id")){
		ASTNODE *temp=findDefAst(root,inFunFlag);
		if(temp==NULL){
			temp=findDefAst(root,!inFunFlag);                   // if the define format is incorrect, it means it did not find inFunFlag
		}
		if(inFunFlag){
			root->ival=temp->left->ival;
		}
		else{
			root->ival=temp->ival;
		}
	}
	// 7. Function
	else if(!strcmp(root->dataType,"funcall")){            // determine wheter the datatype is "funcall"
		inFunFlag=1;                                                     // consider is in the function
		doFunCall(root);
		doAST(root->left->right);                               // traverse AST
		root->ival=root->left->right->ival;              // assign the value to left subtree's right child
		inFunFlag=0;                                                // consider is not in the function since it's end
		
	}
	else if(!strcmp(root->dataType,"funNamecall")){            // determine whether the datatype is "funNamecall"
		// save old
		NAMELIST* temp=nameHead;
		nameHead=coloneName(nameHead);//new 
		root->left->left=findDefAst(root->left->left,0);
		doAST(root->left);
		root->ival=root->left->ival;
		nameHead=temp;                                                        // new assign back to the original nameHead
	}
	else if(!strcmp(root->dataType,"param")){                       // determine whether the datatype is "param"
		doAST(root->left);                                                         // traverse to left node
		root->ival=root->left->ival;
	}
}
// bind param
void doFunCall(ASTNODE *astRoot){
	ASTNODE* para=astRoot->right;                                                           // get right subtree's pointer
	ASTNODE* funId=astRoot->left->left;                                                   
	ASTNODE* temp;
	ASTNODE* temp2=(ASTNODE *)malloc(sizeof(ASTNODE));
	while(funId->left!=NULL){                                                                      // if left subtree's of funId is not NULL then traverse
		temp2->left=funId;
		temp2->right=para;
		doDefFun(temp2);                //store var to nameList
		para=para->right;
		funId=funId->left;
	}
	
}
void doDefFun(ASTNODE *astRoot){
	doAST(astRoot->right);
	NAMELIST *temp=(NAMELIST *)malloc(sizeof(NAMELIST));
	temp->next=NULL;
	temp->astRoot=astRoot->right;
	temp->inFun=1;
	strcpy(temp->name,astRoot->left->name);                 //copy def name
	if(nameHead==NULL){
		nameHead=temp;
	}
	else{
		
		NAMELIST *now=nameHead;
		while(now->next!=NULL){
			if((!strcmp(temp->name,now->next->name))&&now->next->inFun==1){
				temp->next=now->next->next;
				break;
			}
			now=now->next;
		}
		now->next=temp;
	}
}
void doDef(ASTNODE *astRoot){
	doAST(astRoot->right);
	NAMELIST *temp=(NAMELIST *)malloc(sizeof(NAMELIST));
	temp->next=NULL;
	temp->astRoot=astRoot->right;
	temp->inFun=0;
	strcpy(temp->name,astRoot->left->name);                  //copy def name
	if(nameHead==NULL){
		nameHead=temp;
	}
	else{
		NAMELIST *now=nameHead;
		while(now->next!=NULL){
			now=now->next;
		}
		now->next=temp;
	}
}
ASTNODE* findDefAst(ASTNODE* root,int inFun){
	NAMELIST *now=nameHead;
	while(now!=NULL){
		if(!strcmp(root->name,now->name)&&now->inFun==inFun){                  // check if root name==now node name  // check if inFun is the same value
			return colone(now->astRoot);             
		}
		else{
			now=now->next;                            // if not the same then traverse to next node 
		}
	}
	return NULL;
}
ASTNODE* colone(ASTNODE* root){
	if(root == NULL)
		return NULL;
	ASTNODE *ast =(ASTNODE *)malloc(sizeof(ASTNODE));      // generate a new one
	strcpy(ast->dataType,root->dataType);                                    // copy root datatype
	strcpy(ast->name,root->name);                                                // copy root name
	ast->ival=root->ival;                                                                   // copy root value
	ast->left=colone(root->left);                                                      //assign root left subtree node to left pointer
	ast->right=colone(root->right);                                                 // assign root right subtree node to right pointer
	return ast;
}
NAMELIST* coloneName(NAMELIST* root){
	if(root == NULL)
		return NULL;
	NAMELIST *temp =(NAMELIST *)malloc(sizeof(NAMELIST));          // generate a new one
	strcpy(temp->name,root->name);                                                       // copy root name
	temp->inFun=root->inFun;                                                                    // copy root inFun
	temp->astRoot=root->astRoot;                                                             // copy root pointer value to temp
	temp->next=coloneName(root->next);                                               // assign the next node of root node to "next" pointer
	return temp;
}
void yyerror(const char *message)
{
        fprintf (stdout, "%s\n",message);
}

int main(int argc, char *argv[]) {
        yyparse();
        return(0);
}

