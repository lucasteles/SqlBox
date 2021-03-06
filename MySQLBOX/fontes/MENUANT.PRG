***********************************************
* MENURAIZ - PRINCIPAL PROGRAM - SQL ToolBox  *
***********************************************

_SCREEN.WINDOWSTATE = 2		&& tela cheia
_SCREEN.MaxButton = .t.
_SCREEN.Visible = .T.
_SCREEN.Caption = 'SQL ToolBox'

* GENERAL SET'S
SET TALK OFF
SET ESCAPE OFF
SET EXCL OFF
SET DATE BRIT
SET HOURS TO 24
SET SAFETY OFF
SET READBORDER ON
SET REPROCESS TO 3 SECONDS
SET DECIMAL TO 8
SET EXACT OFF
SET NEAR OFF
SET DELE ON
SET CLOCK STATUS
SET CURSOR ON
SET CONFIRM ON
SET COLOR TO
SET CENTURY ON
SET DATE BRITISH
SET POINT TO ','
SET SEPA TO '.'
CLOSE ALL
CLEA ALL
CLEA WIND
CLEA MEMO
CLEA
ACTI SCREEN
IF 'TESTESVF' $ CURDIR()
	ON ERROR
	ON SHUTDOWN
ELSE
	ON ERROR DO ROTERRO WITH ERROR(),MESSAGE(),PROGRAM(),LINENO()
	ON SHUTDOWN QUIT
ENDIF

LOCAL lcLOGFILE, lcOKLOG AS String
lcOKLOG = ''

=OPENDBF('CONFIG')
IF NOT USED('CONFIG')
	RETURN
ENDIF
=OPENDBF('HISTOR')
=OPENDBF('FAVORI')

* GENERAL VARIABLES (CONNECTION)
PUBLIC pnALCAORIGEM, pnALCADESTINO AS Integer
STORE 0 TO pnALCAORIGEM, pnALCADESTINO

PUBLIC pcCONNECTION1, pcCONNECTION2 AS STRING
STORE '' TO pcCONNECTION1, pcCONNECTION2

PUBLIC gcNOVO, gcSEARCH AS String
gcNOVO = ''
gcSEARCH = ''

DO FORM PRINCIPAL
CLOSE ALL
RETURN

* SIMPLE "YES OR NO" FUNCTION
PROC SIMOUNAO
*************
PARAMETERS WQUESTION,WTITSN,WDEFASN
	MRESPSN = MESSAGEBOX( WQUESTION,WTITSN,IIF(WDEFASN=1,36,292) )
	CLEA TYPEAHEAD
	IF MRESPSN = 6
		RETU(.T.)
	ENDIF
RETU(.F.)

* SIMPLE ALERT FUNCTION
PROC MENS
*********
PARAM MMENS
 	=MESSAGEBOX(MMENS,"WARNING",48)
RETURN

* ERROR ROUTINE
PROC ROTERRO
************
PARAMETERS MYERRO,MYMESS,MYPROG,MYLINH
	DO CASE
	CASE MYERRO = 1705
		=MESSAGEBOX('ACCESS DENIED! FILE CAN NOT BE OPENNED','ERROR',32)
	OTHERWISE
		=MESSAGEBOX('ERROR CODE: '+;
		ALLTRIM(STR(MYERRO)) + '=' + MYMESS + ' LINE ' + ALLTRIM(STR(MYLINH)) + ':' + MYPROG, 'ERROR',32)
	ENDCASE
	CANCEL
RETURN

* FINISH THE PROGRAM
PROC SAIDA
**********
	IF !MESSAGEBOX('This program will be finished','EXIT',33) = 2
		IF pnALCAORIGEM>0
			=SQLDISCONNECT(pnALCAORIGEM)
			pnALCAORIGEM = 0
		ENDIF
		CLOSE ALL
		CLEAR WIND
		CANCEL
	ENDIF
RETURN

* WINDOW MESSAGE - USER MUST WAIT
PROC ESPERANDO
**************
PARAMETER tcMESS
	DEFI WIND ESPERANDO TITLE 'WAIT' NOCLOSE FLOAT NOMINIMIZE NOZOOM;
		SYSTEM AT 0,0 SIZE 7,LEN(tcMESS)+4;
		FONT "FIXEDSYS",9
	MOVE WIND ESPERANDO CENTER
	ACTI WIND ESPERANDO
	@ 2,1 SAY tcMESS
	=INKEY(.3)
RETURN

FUNC OPENDBF
************
* OPEN DBF LOG FILES
LPARAMETERS tcFILE,tcMODE
	LOCAL lcFILENAME, lcALIAS AS STRING
	IF TYPE('tcMODE')<>'C'
		tcMODE = 'SHARED'
	ENDIF
	IF tcFILE='CONFIG'
		lcFILENAME = 'CONFIG.DBF'
	ENDIF
	IF tcFILE='HISTOR'
		lcFILENAME = 'C:\TEMP\HISTOR.DBF'
	ENDIF
	IF tcFILE='FAVORI'
		lcFILENAME = 'C:\TEMP\FAVORI.DBF'
	ENDIF
	IF USED(tcFILE)
		USE IN (tcFILE)
	ENDIF
	IF NOT FILE(lcFILENAME)
		=CRIARLOG(tcFILE, lcFILENAME)
	ENDIF
	LOCAL lnOK AS Integer
	lnOK = 1
	TRY 
		IF tcMODE='EXCL'
			USE (lcFILENAME) IN 0 ALIAS (tcFILE) EXCL
		ELSE
			USE (lcFILENAME) IN 0 ALIAS (tcFILE)
		ENDIF
	CATCH
		DO MENS WITH 'FAILED TO OPEN: '+tcFILE
		lnOK = -1
	ENDTRY

	IF USED(tcFILE)
		IF tcFILE $ 'HISTOR,FAVORI'
			SELE (tcFILE)
			GO BOTT
		ENDIF
		IF tcFILE = 'CONFIG'
			SELE CONFIG
			SET ORDER TO 1
			GO TOP
		ENDIF
	ENDIF
RETURN(lnOK)

PROC CRIARLOG
*************
* CREATE LOG FILE
LPARAMETERS tcALIAS, tcARQLOG
	IF tcALIAS='CONFIG'
		RETURN(0)
	ENDIF
	LOCAL lnOK AS Integer
	lnOK = 0
	TRY 
		IF NOT DIRECTORY('C:\TEMP\')
			MD C:\TEMP
		ENDIF
		IF DIRECTORY('C:\TEMP\')
			IF tcALIAS='HISTOR'
				CREATE TABLE (tcARQLOG) (;
					DATAHORA DATETIME,;
					RESUMO C(40),;
					DURACAO NUERIC(8,3),;
					SUCESSO NUMERIC(1),;
					COMANDO M(10);
				)
			ENDIF
			IF tcALIAS='FAVORI'
				CREATE TABLE (tcARQLOG) (;
					TITULO C(40),;
					DATAHORA DATETIME,;
					RESUMO C(40),;
					DURACAO NUERIC(8,3),;
					SUCESSO NUMERIC(1),;
					COMANDO M(10);
				)
			ENDIF
		ENDIF
		lnOK = 1
	CATCH
		lnOK = -1
	ENDTRY
	IF USED(tcALIAS)
		USE IN (tcALIAS)
	ENDIF
RETURN(lnOK)

PROC ATUSQL
***********************************************************************
* ATUSQL - ATUALIZA BASE SQL DE ACORDO COM A A��O DESEJADA	- *
***********************************************************************
PARAMETERS tnALCA, tcACTION, tcTABELA, tcOUTROS, tcCAMPOSUPDATE
	* PARAMETRO1 - ALCA DE CONEX�O
	* PARAMETRO2 - ACAO (A/M/D)
	* PARAMETRO3 - TABELA
	* PARAMETRO4 - STRING CONTENDO PALAVRAS-CHAVE
	* PARAMETRO5 - CAMPOS EXCE��ES (SE VAI GRAVAR OU N�O, DEPENDE DAS PALAVRAS-CHAVE)
	* PALAVRAS-CHAVE:
	* NOAUTOINC = INDICA QUE O PK_ID N�O � AUTONUMERA��O (PRECISA GRAVA-LO)
	* NOPK      = INDICA QUE O N�O H� PK_ID (VALIDO PARA INSERTS ONLY)
	* UPDATE=NO = INDICA QUE OS CAMPOS RELACIONADOS DEVEM SER IGNORADOS
	* UPDATE=YES= INDICA QUE OS S� CAMPOS RELACIONADOS DEVEM SER GRAVADOS
	IF TYPE('tnALCA') <> 'N'
		tnALCA = 0
	ENDIF
	IF EMPTY(tnALCA)
		RETURN(0)
	ENDIF
	IF TYPE('tcACTION') <> 'C'
		DO MENS WITH 'NENHUMA A��O FOI INFORMADA (ATUSQL)'
		RETURN(0)
	ENDIF
	IF EMPTY(ALIAS())
		DO MENS WITH 'NENHUMA TABELA SELECIONADA (ATUSQL)'
		RETURN(0)
	ENDIF
	IF NOT tcACTION $ 'AMD'
		DO MENS WITH 'A��O INFORMADA N�O FOI RECONHECIDA: ('+tcACTION+') ATUSQL'
		RETURN(0)
	ENDIF
	IF TYPE('tcTABELA') <> 'C'
		tcTABELA = ALIAS()
	ENDIF
	IF TYPE('tcOUTROS') <> 'C'
		tcOUTROS = ''
	ENDIF
	IF TYPE('tcCAMPOSUPDATE') <> 'C'
		tcCAMPOSUPDATE = ''
	ENDIF
	tcCAMPOSUPDATE = VIRGULAR(tcCAMPOSUPDATE)

	lnUPDATE = 0
	IF 'UPDATE=NO' $ tcOUTROS
		lnUPDATE = 1
	ENDIF
	IF 'UPDATE=YES' $ tcOUTROS
		lnUPDATE = 2
	ENDIF

	PRIVATE ARRAY laERRO[1]
	PRIVATE lnSQLOK, lnRESP, lnIDENTITY, lnCONTEUXID, lnRESPIDENTITY AS Integer
	PRIVATE lcATUSQL, lcERRO, lcALIASUI, lcCMDIDENTITY, lcMOTIVO, lcSQLCONDI AS String

	lnSQLOK		= -1				&& CONTROLE DE OPERA��O BEM SUCEDIDA
	lcATUSQL	= ''
	lcALIASFOX  = ALIAS()

	pnNOPK = 0
	IF 'NOPK' $ tcOUTROS
		* PODE-SE ESCOLHER IGNORAR OK PK_ID
		pnNOPK = 1
	ENDIF
	pnAUTOINC = 0
	IF NOT 'NOAUTOINC' $ tcOUTROS
		* POR DEFAULT OS PK NUMERICOS S�O AUTONUMERA��O
		pnAUTOINC = 1
	ENDIF

	* PEGA PROX.NUMERO (RECNO)
	IF pnAUTOINC=1 AND tcACTION='A'	AND pnNOPK<>1
		IF 'ORACLE' $ UPPER(CONFIG.CONEXAO) OR 'POSTGRES' $ UPPER(CONFIG.CONEXAO)
			lcPROXIMO = 'SELECT '+tcTABELA+'_S.NEXTVAL AS PROXIMO FROM DUAL'
			=SQLEXEC(tnALCA,lcPROXIMO,'TMPLASTPK')
			luPK_ID		= TMPLASTPK.PROXIMO
			USE IN TMPLASTPK
			pnAUTOINC = 0
			SELE &lcALIASFOX
			REPLACE PK_ID WITH luPK_ID
		ENDIF
	ENDIF

	* MONTA SINTAXE COMPLETA
	DO MONTASQLC

*	LOCAL lcNOVASTRING AS String
*	lcNOVASTRING	= ''
*	* TRATAMENTOS ESPECIAIS DE SINTAXE
*	DO CASE
*		CASE 'FOXPRO' $ UPPER(CONFIG.CONEXAO)
*			lcNOVASTRING = TRATASQLFOX(lcATUSQL)
*		CASE 'POSTGRE' $ UPPER(CONFIG.CONEXAO)
*			lcNOVASTRING = TRATASQLPGSQL(lcATUSQL)
*		CASE 'ORACLE' $ UPPER(CONFIG.CONEXAO)
*			lcNOVASTRING = TRATASQLORACLE(lcATUSQL)
*		OTHERWISE
*			lcNOVASTRING = TRATASQLMSSQL(lcATUSQL)
*	ENDCASE
*	lcATUSQL	= lcNOVASTRING

	* EXECUTA COMANDO NA BASE SQL
	lnSQLOK		= SQLEXEC(tnALCA,lcATUSQL)
	IF lnSQLOK<0
		=AERROR(laERRO)
		lnERRO = ALLTRIM(STR(laERRO(1)))
		lcERRO = laERRO(3)
		=MESSAGEBOX('ERRO P/ ATUALIZAR A BASE DE DADOS: '+lnERRO+CHR(13)+lcERRO,'AVISO: SQL-ERRO',48)
*		lnRESP=MESSAGEBOX('ESCOLHA O TRATAMENTO','TRATANDO ERRO SQL',2)
*		IF lnRESP=3
*			_CLIPTEXT = lcATUSQL
*			DEBUG
*			SUSP
*		ENDIF
*		IF lnRESP=4
*			_CLIPTEXT = lcATUSQL
*		ENDIF
*		RETURN(0)
	ENDIF
	IF 'ORACLE' $ UPPER(CONFIG.CONEXAO)
		=SQLEXEC(tnALCA,'COMMIT')
	ENDIF

*!*		IF tcACTION='A' AND pnAUTOINC=1
*!*			* SE FOI UM INSERT, PEGAR O CAMPO C/ AUTOINCREMENTO (IDENTITY)
*!*			lcALIASUI	= ALIAS()
*!*			lnIDENTITY	= 0
*!*			DO PEGAULTINC
*!*			SELECT &lcALIASUI
*!*			IF lnIDENTITY>0
*!*				* ATUALIZA CAMPO AUTO-NUMERA��O NA BASE LOCAL
*!*				REPLACE PK_ID WITH lnIDENTITY
*!*			ELSE
*!*				lnSQLOK = -2
*!*				* EXCLUIR REGISTRO (NAO FOI INCLUIDO NO SQL)
*!*				DELETE
*!*				SKIP-1
*!*				IF BOF() AND NOT EOF()
*!*					SKIP
*!*				ENDIF
*!*			ENDIF
*!*		ENDIF
	LOCAL lnRETORNO AS Integer
	IF TYPE('PK_ID') $ 'CDT'
		lnRETORNO = PK_ID
	ELSE
		lnRETORNO = 1
	ENDIF
RETURN(lnRETORNO)

PROC PEGAULTINC
***************
	DO CASE
		CASE 'MYSQL' $ UPPER(CONFIG.CONEXAO)
			lcCMDIDENTITY	= "SELECT MAX(PK_ID) AS ULTIMAINC FROM "+tcTABELA
			lnRESPIDENTITY	= SQLEXEC(tnALCA,lcCMDIDENTITY,'TMPLASTPK')
		CASE 'POSTGRES' $ UPPER(CONFIG.CONEXAO)
			lcCMDIDENTITY	= "SELECT CURRVAL('"+tcTABELA+"_S'::text) AS ULTIMAINC" &&tcSEQUENCIA
			lnRESPIDENTITY	= SQLEXEC(tnALCA,lcCMDIDENTITY,'TMPLASTPK')
		CASE 'ORACLE' $ UPPER(CONFIG.CONEXAO)
			lcCMDIDENTITY	= 'SELECT '+tcSEQUENCIA+'.CURRVAL AS ULTIMAINC FROM DUAL'
			lnRESPIDENTITY	= SQLEXEC(tnALCA,lcCMDIDENTITY,'TMPLASTPK')
		CASE 'FOXPRO' $ UPPER(CONFIG.CONEXAO)
			* FALTA: M�TODO PARA PEGAR �LTIMO REGISTRO NO FOX
		OTHERWISE
			*SQL SERVER
			lcCMDIDENTITY	= 'SELECT @@IDENTITY AS ULTIMAINC'
			lnRESPIDENTITY	= SQLEXEC(tnALCA,lcCMDIDENTITY,'TMPLASTPK')
	ENDCASE

	lcMOTIVO = ''

	IF lnRESPIDENTITY<0
		lcMOTIVO = 'EXEC-SQL'
	ENDIF
	IF TYPE('ULTIMAINC')<>'N'
		lcMOTIVO = 'SEM PK_ID'
	ELSE
		IF ULTIMAINC<=0
			lcMOTIVO = 'PK_ID SEM CONTEUDO'
		ENDIF
	ENDIF	

	IF NOT EMPTY(lcMOTIVO)
		DO MENS WITH 'ERRO NA INCLUS�O (P/RETORNAR PK_ID): '+lcMOTIVO+' ATUSQL'
	ELSE
		*RETORNA ULTIMA INSER��O
		lnIDENTITY = ULTIMAINC
	ENDIF
	USE IN TMPLASTPK
RETURN

PROCEDURE MONTASQLC
*******************
* MONTA COMANDO DE ACORDO COM A ACAO EXECUTADA NA BASE LOCAL
* OBS: A ACAO � EFETUADA NO DBF (CURSOR LOCAL) E DEPOIS PRECISA QUE SEJA ATUALIZADA
* ---- A BASE SQL. ASSIM ESTE COMANDO � MONTADO PARA SER EXECUTADO E EFETUAR ESTA TAREFA

	IF tcACTION='A'
		lcSQLCONDI = ''
	ELSE
		*CONDICAO
		luPK_ID	= PK_ID
		lcSQLCONDI = " WHERE PK_ID="+XX(luPK_ID)
	ENDIF

	* MONTA NOME DA TABELA NO SQL
	IF tcTABELA = 'TMP'
		RETURN
	ENDIF

	* MONTA SINTAXE DE CADA COMANDO, DEPENDENDO DA A��O
	PRIVATE pcCPOAUX AS String
	pcCPOAUX = ''
	DO CASE
		CASE tcACTION = 'D'
			* DELETAR REGISTRO (DELETE)
			lcATUSQL = 'DELETE FROM '+tcTABELA+lcSQLCONDI

		CASE tcACTION = 'A'
			* INCLUIR REGISTRO (INSERT)
			WQF = AFIELDS(WTABF)
			STORE '' TO lcINSERE1, lcINSERE2
			FOR WXC = 1 TO WQF
				pcCPOAUX = ALLTRIM(WTABF[WXC,1])
				IF pcCPOAUX = 'PK_ID' AND pnAUTOINC=1
					* CAMPO IDENTITY 
					LOOP
				ENDIF
				IF pcCPOAUX = 'PK_ID' AND pnNOPK=1
					* N�O GRAVAR PK
					LOOP
				ENDIF
				IF pcCPOAUX = 'DH_ALTERACAO'
					LOOP
				ENDIF
				IF lnUPDATE=1
					IF VIRGULAR(pcCPOAUX) $ VIRGULAR(tcCAMPOSUPDATE)
						* CAMPO A SER IGNORADO
						LOOP
					ENDIF
				ENDIF
				IF lnUPDATE=2
					IF NOT VIRGULAR(pcCPOAUX) $ VIRGULAR(tcCAMPOSUPDATE)
						* CAMPO QUE N�O FAZ PARTE DA RELA��O
						LOOP
					ENDIF
				ENDIF
				IF EMPTY(lcINSERE1)
					lcSEPARA = ''
				ELSE
					lcSEPARA = ', '
				ENDIF

				lcCONTEUDO = "''"
				DO VCONTEUDO
*				IF pcCPOAUX = 'DH_INCLUSAO'
*					lcCONTEUDO = D2SQL(DATE(),'HOJE')
*				ENDIF

				lcINSERE1 = lcINSERE1 + lcSEPARA + pcCPOAUX
				lcINSERE2 = lcINSERE2 + lcSEPARA + lcCONTEUDO
			ENDFOR
			lcATUSQL = 'INSERT INTO '+tcTABELA+' ('+lcINSERE1+') VALUES ('+lcINSERE2+')'

		CASE tcACTION = 'M'
			* ALTERAR REGISTRO (UPDATE)
			WQF = AFIELDS(WTABF)
			WCAMPOSUP = ''
			STORE '' TO lcINSERE1, lcINSERE2
			FOR WXC = 1 TO WQF
				pcCPOAUX = ALLTRIM(WTABF[WXC,1])
				IF pcCPOAUX = 'PK_ID'
					* CAMPO IDENTITY
					LOOP
				ENDIF
				IF pcCPOAUX = 'DH_INCLUSAO'
					LOOP
				ENDIF
				IF lnUPDATE=1
					IF VIRGULAR(pcCPOAUX) $ VIRGULAR(tcCAMPOSUPDATE)
						* CAMPO A SER IGNORADO
						LOOP
					ENDIF
				ENDIF
				IF lnUPDATE=2
					IF NOT VIRGULAR(pcCPOAUX) $ VIRGULAR(tcCAMPOSUPDATE)
						* CAMPO QUE N�O FAZ PARTE DA RELA��O
						LOOP
					ENDIF
				ENDIF
				IF '_KK' $ pcCPOAUX
					* CAMPO DE CONTROLE (NUNCA � FEITO UPDATE POR ESTA ROTINA
					LOOP
				ENDIF
				IF EMPTY(WCAMPOSUP)
					lcSEPARA = ''
				ELSE
					lcSEPARA = ', '
				ENDIF

				lcCONTEUDO = "''"
				DO VCONTEUDO
*				IF pcCPOAUX = 'DH_ALTERACAO'
*					lcCONTEUDO = D2SQL(DATE(),'HOJE')
*				ENDIF

				WCAMPOSUP = WCAMPOSUP + lcSEPARA + pcCPOAUX + "="+lcCONTEUDO
			ENDFOR
			lcATUSQL = 'UPDATE '+tcTABELA+' SET '+ WCAMPOSUP + lcSQLCONDI
	ENDCASE
RETURN

PROC VCONTEUDO
**************
	*formatacao dos campos de acordo com seu tipo
	IF TYPE(pcCPOAUX)$'DT'
		WDATAUX = &pcCPOAUX
		lcCONTEUDO = D2SQL(WDATAUX)
	ENDIF
	IF TYPE(pcCPOAUX)$'CM'
		lcCONTEUDO = "'"+ALLTRIM(STRTRAN(&pcCPOAUX ,"'",""))+"'"
		IF lcCONTEUDO = "''"
			lcCONTEUDO	= "' '"
		ENDIF
	ENDIF
	IF TYPE(pcCPOAUX)='L'
		lcCONTEUDO = IIF(&pcCPOAUX,'1','0')
	ENDIF
	IF TYPE(pcCPOAUX)$'NY'
		lcCONTEUDO = ALLTRIM(TRANS(&pcCPOAUX ,"999999999999999.99999999"))
		IF SET('POINT')<>'.'
			lcCONTEUDO = STRTRAN(lcCONTEUDO,'.','')
			lcCONTEUDO = STRTRAN(lcCONTEUDO,',','.')
		ENDIF
	ENDIF
	IF ISNULL(lcCONTEUDO)
		lcCONTEUDO = 'NULL'
	ENDIF
RETURN

FUNC VIRGULAR
*************
PARAMETERS tcVIRGULAR
	IF TYPE('tcVIRGULAR')='N'
		tcVIRGULAR = ALLTRIM(STR(tcVIRGULAR))
	ENDIF
	LOCAL lcVIRGULAR as String
	lcVIRGULAR = ','+tcVIRGULAR+','
RETURN(lcvirgular)

FUNC XX
*******
*RETORNA STRING PRONTA PARA CONCATENAR C/ COMANDO-SQL
PARAMETERS tnENTRA, tcPICTURE
	LOCAL lcSAI AS String
	lcSAI = 'NULL'
	IF NOT ISNULL(tnENTRA)
		IF TYPE('tnENTRA')='N'
			lcSAI = ALLTRIM(STR(tnENTRA,30))
			IF TYPE('tcPICTURE')='C'
				lcSAI = TRANSFORM(tnENTRA,tcPICTURE)
				lcSAI = STRTRAN(lcSAI,',','.')
			ENDIF
		ENDIF
		IF TYPE('tnENTRA')='C'
			tnENTRA = STRTRAN(tnENTRA,"'","")
			IF EMPTY(tnENTRA)
				lcSAI = "' '"
			ELSE
				lcSAI = "'"+ALLTRIM(tnENTRA)+"'"
			ENDIF
		ENDIF
		IF TYPE('tnENTRA')='D' OR TYPE('tnENTRA')='T'
			lcSAI = D2SQL(tnENTRA)
		ENDIF
	ENDIF
RETURN(lcSAI)

FUNC D2SQL
**********
LPARAMETERS tdENTRA, tcMODO
* PARAMETRO1= DATA A SER TRANSFORMADA (OU STRING)
* PARAMETRO2= MODO (DATA/STRING)
* ONDE: DATA=MONTA A STRING COM A DATA JA CONVERTIDA, EX: CONVERT(DATETIME,20/11/2004,103)
*       STRING=MONTA UMA STRING A SER TRATADA PELO SERVIDOR SQL, EX: CONVERT(DATETIME,CAMPO,103)
*              (ENVIAR O NOME DO CAMPO PARA A CONDI��O)
	IF TYPE('tcMODO') <> 'C'
		tcMODO = 'DATA'
	ENDIF
	IF tcMODO = 'STRING'
		IF TYPE('tdENTRA') <> 'C'
			RETURN('')
		ENDIF
	ELSE
		IF NOT TYPE('tdENTRA') $ 'DT'
			tdENTRA = {}
		ENDIF
	ENDIF
	LOCAL luSAI
	luSAI = 'null'
	IF !EMPTY(tdENTRA)
		DO CASE
			CASE 'MYSQL' $ UPPER(CONFIG.CONEXAO)
				*data entre aspas no formato aaaammdd
				DO CASE
					CASE tcMODO = 'HOJE'
						luSAI	= 'NOW()'
					CASE tcMODO = 'STRING'
						luSAI = "DATE_FORMAT('"+DTOS(tdENTRA)+"','%D/%M/%Y')"
					OTHERWISE
						IF TYPE('tdENTRA')='D'
							*data entre aspas no formato aaaammdd
							luSAI = "'"+DTOS(tdENTRA)+"'"
						ELSE
							*datahora entre aspas no formato aaaammdd
							luSAI = "'"+TTOC(tdENTRA,3)+"'"
							luSAI = STRT(luSAI,'T',' ')
						ENDIF
				ENDCASE
			CASE 'POSTGRE' $ UPPER(CONFIG.CONEXAO)
				*data entre aspas no formato aaaammdd
				DO CASE
					CASE tcMODO = 'HOJE'
						luSAI	= "current_date"
					CASE tcMODO = 'STRING'
						luSAI	= "TO_CHAR("+tdENTRA+",'MM/DD/YYYY')"
					OTHERWISE
						LOCAL lcHHMMSS AS STRING
						lcHHMMSS = TTOC(tdENTRA,2)
						IF TYPE('tdENTRA')='D'
							*data entre aspas no formato aaaammdd
							luSAI = "TO_DATE('"+DTOS(tdENTRA)+"','YYYYMMDD')"
						ELSE
							*datahora entre aspas no formato aaaammdd
							lcHHMMSS = SUBSTR(lcHHMMSS,1,2)+SUBSTR(lcHHMMSS,4,2)+SUBSTR(lcHHMMSS,7,2)
							luSAI = "TO_TIMESTAMP('"+DTOS(tdENTRA)+lcHHMMSS+"','YYYYMMDDHH24MISS')"
						ENDIF

				ENDCASE
			CASE 'ORACLE' $ UPPER(CONFIG.CONEXAO)
				DO CASE
					CASE tcMODO = 'HOJE'
						luSAI	= 'SYSDATE'
					CASE tcMODO = 'STRING'
						luSAI = "TO_CHAR("+tdENTRA+",'DD/MM/YYYY')"
					OTHERWISE
						LOCAL lcHHMMSS AS STRING
						lcHHMMSS = TTOC(tdENTRA,2)
						IF TYPE('tdENTRA')='D'
							*data entre aspas no formato aaaammdd
							luSAI = "TO_DATE('"+DTOS(tdENTRA)+"','YYYYMMDD')"
						ELSE
							*datahora entre aspas no formato aaaammdd
							lcHHMMSS = SUBSTR(lcHHMMSS,1,2)+SUBSTR(lcHHMMSS,4,2)+SUBSTR(lcHHMMSS,7,2)
							luSAI = "TO_DATE('"+DTOS(tdENTRA)+lcHHMMSS+"','YYYYMMDDHH24MISS')"
						ENDIF
				ENDCASE
			CASE 'FOXPRO' $ UPPER(CONFIG.CONEXAO)
				DO CASE
					CASE tcMODO = 'HOJE'
						luSAI	= "DATETIME()"
					CASE tcMODO = 'STRING'
						luSAI	= "DTOC(DATE())"
					OTHERWISE
						luSAI	= "'"+DTOS(tdENTRA)+"'"
				ENDCASE
			OTHERWISE
				*SQL SERVER
				*onde: convert(formato,conteudo,nro)
				*ex: convert(datetime,'25/08/2003',103)
				DO CASE
					CASE tcMODO = 'HOJE'
						luSAI	= 'GETDATE()'
					CASE tcMODO = 'STRING'
						luSAI	= "convert(varchar,"+tdENTRA+",103)"
					OTHERWISE
						* MARTELANDO A DATA APENAS ACIMA DE 1900 E MENOR QUE 2079
						LOCAL lnANO, lnMES, lnDIA, lnHORA, lnMINUTO, lnSEGUNDO AS Integer
						LOCAL ldDATA AS Date
						lnANO	= YEAR(tdENTRA)
						lnMES	= MONTH(tdENTRA)
						lnDIA	= DAY(tdENTRA)
						IF lnANO < 1900
							lnANO	= YEAR(DATE())
						ENDIF
						IF lnANO > 2079
							lnANO	= YEAR(DATE())
						ENDIF
						IF TYPE('tdENTRA') = 'T'
							lnHORA		= HOUR(tdENTRA)
							lnMINUTO	= MINUTE(tdENTRA)
							lnSEGUNDO	= SEC(tdENTRA)
						ELSE
							STORE 0 TO lnHORA, lnMINUTO, lnSEGUNDO
						ENDIF
						ldDATA	= STRZERO(lnANO,4) + ;
									STRZERO(lnMES,2) + ;
									STRZERO(lnDIA,2) + ' ' + ;
									STRZERO(lnHORA,2) + ':' +;
									STRZERO(lnMINUTO,2) + ':' +;
									STRZERO(lnSEGUNDO,2)
						luSAI	= "convert(datetime,'"+ ldDATA +"',103)"
				ENDCASE
		ENDCASE
	ENDIF
RETURN(luSAI)

FUNC TRATASQLFOX
****************
LPARAMETERS tcCPOIN AS String
	LOCAL lcCPOOUT AS String
	IF TYPE('tcCPOIN') <> 'C'
		tcCPOIN = ''
	ENDIF
	IF EMPTY(tcCPOIN)
		RETURN('')
	ENDIF
	lcCPOOUT = tcCPOIN
	IF ' CASE WHEN ' $ lcCPOOUT
		lcCPOOUT = STRTRAN( lcCPOOUT, ' CASE WHEN '	, ' IIF( '	)
		lcCPOOUT = STRTRAN( lcCPOOUT, ' THEN '			, ' , '		)
		lcCPOOUT = STRTRAN( lcCPOOUT, ' ELSE '			, ' , '		)
		lcCPOOUT = STRTRAN( lcCPOOUT, ' END '			, ' ) '		)
	ENDIF
	lcCPOOUT = STRTRAN( lcCPOOUT, 'SUBSTRING(', 'SUBSTR(')
RETURN(lcCPOOUT)

FUNC TRATASQLPGSQL
******************
LPARAMETERS tcCPOIN AS String
RETURN(lcCPOOUT)

FUNC TRATASQLORACLE
*******************
LPARAMETERS tcCPOIN AS String
	LOCAL lcCPOOUT AS String
	IF TYPE('tcCPOIN') <> 'C'
		tcCPOIN = ''
	ENDIF
	IF EMPTY(tcCPOIN)
		RETURN('')
	ENDIF
	lcCPOOUT = tcCPOIN
	lcCPOOUT = STRTRAN( lcCPOOUT, 'SUBSTRING(', 'SUBSTR(')
RETURN(lcCPOOUT)

FUNC TRATASQLMSSQL
******************
LPARAMETERS tcCPOIN AS String
	LOCAL lcCPOOUT AS String
	IF TYPE('tcCPOIN') <> 'C'
		tcCPOIN = ''
	ENDIF
	IF EMPTY(tcCPOIN)
		RETURN('')
	ENDIF
	lcCPOOUT = tcCPOIN
	lcCPOOUT = STRTRAN( lcCPOOUT, '||' , '+' )
	lcCPOOUT = STRTRAN( lcCPOOUT, 'SUBSTR(', 'SUBSTRING(')
	lcCPOOUT = STRTRAN( lcCPOOUT, 'LENGTH(', 'LEN(')
RETURN(lcCPOOUT)

FUNC STRZERO
************
LPARAMETERS tnVALOR,tnTAM
	LOCAL lcOUT AS STRING
	lcOUT = STR(tnVALOR,tnTAM)
	lcOUT = STRTRAN(lcOUT," ","0")
RETU(lcOUT)
