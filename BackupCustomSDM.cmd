@ECHO OFF
:: Salva pasta atual
PUSHD "%~dp0"

:: Define variaveis locais
CALL :updateDateTime
SETLOCAL ENABLEDELAYEDEXPANSION
SET autorbat=Daniel Becker Bighelini
SET nomebat=BACKUP CUSTOM TABLES CA SERVICE DESK MANAGER (USD)
SET versaobat=1.00 (30/09/2019)
SET batname=%~n0
SET batext=%~x0
SET batfile=%0
SET batpath=%~dp0
SET batpathfull="%batpath%%batname%%batext%"
SET cfgpathfull="%batpath%%batname%.cfg"
SET cfg="!batname!.cfg"
SET tmp="!batname!_!agoraf!.tmp"
SET log="!batname!.log"

:: Verifica se o arquivo de configuracao foi encontrado
IF NOT EXIST %cfgpathfull% GOTO error1

:readConfig
ECHO *** Carregando arquivo de configuracao %cfgpathfull%...
ECHO.
ECHO *** Opcoes selecionadas
FOR /F "tokens=1-2 delims==" %%a IN ('TYPE %cfgpathfull%') DO (
	IF NOT [%%b] == [] (
		SET bat%%a=%%b
		IF "%%b"=="1" ECHO %%a
	)
)

:confirm
ECHO.
CHOICE /C SN /M "Deseja continuar com a exportacao de dados"
IF ERRORLEVEL 2 GOTO cancel
ECHO.

SET battableszipname="!batpath!%batBACKUPFOLDERTABLES%_!agoraf!.zip"
SET batfileszipname="!batpath!%batBACKUPFOLDERFILES%_!agoraf!.zip"

IF "%batBACKUPFILES%"=="1" (
	:: Identifica a pasta de instalacao da SDM
	FOR /F "tokens=1,2 delims==" %%a IN ('nx_env NX_SITE') DO (
		SET nxsite=%%b
	)

	:: Substitui a barra pela contrabarra no local de instalacao
	SET findbar=/
	SET replacebar=\
	CALL SET nxsite=%%nxsite:!findbar!=!replacebar!%%

	ECHO Pasta de instacao SDM: !nxsite!
	
	SET batBACKUPFOLDERFILES="!batpath!!batBACKUPFOLDERFILES!_!agoraf!"
	IF NOT EXIST !batBACKUPFOLDERFILES!\NUL MD !batBACKUPFOLDERFILES!
	
	XCOPY !nxsite!\*.* !batBACKUPFOLDERFILES! /S /H
	
	:: Tentar usar o comando abaixo
	:: sdmp -a export
)

IF "%batBACKUPTABLES%"=="1" (
	SET batBACKUPFOLDERTABLES="!batpath!!batBACKUPFOLDERTABLES!_!agoraf!"
	IF NOT EXIST !batBACKUPFOLDERTABLES!\NUL MD !batBACKUPFOLDERTABLES!

	ECHO *** Criando backup de tabelas em !batBACKUPFOLDERTABLES!...
	ECHO.

	SET dumped=0
	SET skiped=0

	IF "%batWSP%"=="1"			CALL :dumpTable	"'Tabelas WSP'" "wspcol wsptbl wspdomset" FULL
	IF "%batCUSTOM%"=="1"		CALL :dumpTable "'Tabelas customizadas'" "!batCUSTOMTABLES!"
	IF "%batUISELECTION%"=="1"	CALL :dumpTable "'UI_Selection'" "usp_ui_selection usp_ui_selection_values"
	IF "%batOPTIONS%"=="1"		CALL :dumpTable "'Gerenciador de opcoes'" "Options"
	IF "%batKD%"=="1"			CALL :dumpTable "'Conhecimento'" "O_INDEXES KT_ACT_CONTENT CI_DOC_TEMPLATES KT_FLG_TYPE CI_WF_TEMPLATES CI_ACTIONS CI_STATUSES usp_search_source usp_lrel_search_source_tenants KT_BLC EBR_NOISE_WORDS EBR_SUBSTITS EBR_PREFIXES EBR_SYNONYMS_ADM EBR_SUFFIXES EBR_ACRONYMS QUERY_POLICY"
	IF "%batSECURITY%"=="1" 	CALL :dumpTable "'Gerenciamento de seguranca e funcoes'" "usp_web_form usp_tab usp_menu_tree_name usp_menu_tree usp_menu_bar usp_menu_tree_res usp_functional_access usp_functional_access_type usp_functional_access_role usp_functional_access_level usp_role usp_role_tab usp_role_web_form usp_role_go_form usp_acctyp_role Domain Domain_Constraint Access_Type_v2 usp_acctyp_role usp_help_content usp_help_item usp_help_lookup usp_help_set Credentials"
	IF "%batPOLICY%"=="1" 		CALL :dumpTable "'Politica de servico web SOAP'" "SA_Policy SA_Prob_Type"
	IF "%batMACRO%"=="1"		CALL :dumpTable "'Eventos e macros'" "Spell_Macro Events usp_lrel_false_action_act_f usp_lrel_true_action_act_t usp_lrel_aty_events"
	IF "%batNOTIFY%"=="1"		CALL :dumpTable "'Notificacoes'" "Act_Type_Assoc usp_notification_phrase Contact_Method Notify_Msg_Tpl Act_Type Notify_Object_Attr Notify_Rule"
	IF "%batEMAIL%"=="1"		CALL :dumpTable "'Email', 'Regras de caixa de correio'" "usp_mailbox usp_mailbox_rule"
	IF "%batCONTRACT%"=="1"		CALL :dumpTable "'Service Desk/Contratos de servico'" "Service_Contract SLA_Contract_Map"
	IF "%batSURVEY%"=="1"		CALL :dumpTable "'Service Desk/Pesquisas'" "Survey_Template Survey_Question_Template Survey_Answer_Template Managed_Survey"
	IF "%batSEQ%"=="1"			CALL :dumpTable "'Service Desk/Numeros de sequencia'" "Sequence_Control"
	IF "%batPRPRULE%"=="1"		CALL :dumpTable "'Service Desk/Regras de validacao de propriedade'" "Property_Validation_Rule Property_Value"
	IF "%batRESPONSE%"=="1"		CALL :dumpTable "'Service Desk/Respostas personalizadas'" "Response"
	IF "%batSERVICE%"=="1"		CALL :dumpTable "'Service Desk/Tipos de servico e Modelos de meta de servico'" "Service_Desc SLA_Template target_tgttpls_srvtypes target_time_tpl target_time"
	IF "%batDATA%"=="1"			CALL :dumpTable "'Service Desk/Dados de aplicativos/Codigos'" "attr_alias Rootcause ca_resource_cost_center usp_resolution_code usp_symptom_code Cr_Call_Timers usp_auto_close ca_resource_department ca_state_province Person_Contacting Timezone Severity Impact ca_location usp_location Reporting_Method usp_resolution_method usp_ical_event_template Type_Of_Contact ca_organization usp_organization ca_country Timespan ca_job_title Priority Product ca_site ca_contact_type usp_outage_type usp_special_handling Bop_Workshift Urgency"
	IF "%batDATANR%"=="1"		CALL :dumpTable "'Service Desk/Dados de aplicativos/Itens de configuracao'" "ca_resource_class ca_resource_family ca_model_def ca_resource_status ca_company_type"
	IF "%batDATAQUERY%"=="1"	CALL :dumpTable "'Service Desk/Dados de aplicativos/Consultas armazenadas'" "Cr_Stored_Queries"
	IF "%batDATAREF%"=="1"		CALL :dumpTable "'Service Desk/Dados de aplicativos/Referencias remotas'" "Remote_Ref"
	IF "%batFORMGROUP%"=="1"	CALL :dumpTable "'Service Desk/Grupos de formularios'" "Form_Group"
	IF "%batKPI%"=="1"			CALL :dumpTable "'Service Desk/KPIs'" "Kpi"
	IF "%batMOBILE%"=="1"		CALL :dumpTable "'Service Desk/Telefone celular'" "mobile_attrs"
	IF "%batCATEGORYTPL%"=="1"	CALL :dumpTable "'Service Desk/Objetos compartilhados de categorias'" "Property_Template Workflow_Task_Template Task_Type Task_Status usp_lrel_status_codes_tsktypes Behavior_Template usp_lrel_true_bhv_true usp_lrel_false_bhv_false usp_lrel_svc_grps_svc_wftpl usp_attr_control usp_dependent_control usp_caextwf_start_forms External_Entity_Map transition_type"
	IF "%batISSUE%"=="1"		CALL :dumpTable "'Service Desk/Ocorrencias'" "Issue_Category usp_lrel_svc_locs_svc_isscat usp_lrel_svc_schedules_isscat_svc Issue_Status iss_trans"
	IF "%batCHANGE%"=="1"		CALL :dumpTable "'Service Desk/Requisicoes de mudanca'" "Change_Category usp_lrel_svc_grps_svc_chgcat usp_lrel_svc_locs_svc_chgcat usp_lrel_svc_schedules_chgcat_svc usp_change_type Risk_Survey_Template Change_Status Closure_Code usp_window Risk_Survey_Template usp_conflict_status chg_trans"
	IF "%batCALLREQ%"=="1"		CALL :dumpTable "'Service Desk/Solicitacoes/Incidentes/Problemas'" "Prob_Category Req_Property_Template usp_lrel_svc_grps_svc_pcat usp_lrel_svc_locs_svc_pcat usp_lrel_svc_schedules_pcat_svc usp_pri_cal Cr_Status cr_trans in_trans pr_trans"

	ECHO.
	ECHO *** !dumped! tabelas foram copiadas.
	ECHO *** !skiped! tabelas foram ignoradas.
)

IF "%batBACKUPZIP%"=="1" (
	IF "%batBACKUPTABLES%"=="1" (
		ECHO.
		ECHO *** Compactando arquivos de tabelas em !battableszipname!...
		CALL :generateZip !batBACKUPFOLDERTABLES! !battableszipname!
	)

	IF "%batBACKUPFILES%"=="1" (
		ECHO.
		ECHO *** Compactando arquivos da estrutura Site em !batfileszipname!...
		CALL :generateZip !batBACKUPFOLDERFILES! !batfileszipname!
	)
)

ECHO *** Operacao concluida.
ECHO.
GOTO:EOF

:generateZip
SET batVbs="%batpath%%batname%_zipIt!agoraf!.vbs"
>%batVbs% ECHO Set objArgs = WScript.Arguments
>>%batVbs% ECHO InputFolder = objArgs(0)
>>%batVbs% ECHO ZipFile = objArgs(1)
>>%batVbs% ECHO CreateObject("Scripting.FileSystemObject").CreateTextFile(ZipFile, True).Write "PK" ^& Chr(5) ^& Chr(6) ^& String(18, vbNullChar)
>>%batVbs% ECHO Set objShell = CreateObject("Shell.Application")
>>%batVbs% ECHO Set source = objShell.NameSpace(InputFolder).Items
>>%batVbs% ECHO objShell.NameSpace(ZipFile).CopyHere source, 4 + 16 + 1024
>>%batVbs% ECHO wScript.Sleep 5000

CScript %batVbs% %1 %2 //Nologo
IF EXIST %batVbs% DEL %batVbs%
IF NOT EXIST %2 GOTO error2
IF EXIST "%batpath%%batname%_!agoraf!.tmp" RD /Q /S "%batpath%%batname%_!agoraf!.tmp"
IF EXIST %1 RD /Q /S %1
IF EXIST %2*.TMP DEL %2*.TMP
GOTO:EOF

:dumpTable
SET batTEMP=%1
SET batTITLE=%batTEMP:"=%
SET batTEMP=%2
SET batTABLES=%batTEMP:"=%
ECHO *** Exportando %batTITLE% %3...
FOR %%F IN (%batTABLES%) DO (
	CALL :extractUtil %%F %3
)
ECHO.
GOTO:EOF

:extractUtil
IF "%2"=="FULL" (
	pdm_extract %1 >%batBACKUPFOLDERTABLES%\%1.txt
) ELSE (
	pdm_extract -f "SELECT * FROM %1 WHERE id>400000" >%batBACKUPFOLDERTABLES%\%1.txt
)
FOR %%? IN (%batBACKUPFOLDERTABLES%\%1.txt) DO (
	IF "%%~z?"=="0" (
		DEL %%?
		SET /A skiped += 1
	) ELSE (
		SET /A dumped += 1
	)
)
GOTO:EOF

:updateDateTime
:: Consultando data atual
FOR %%A IN (%Date%) DO (
    FOR /F "tokens=1-3 delims=/-" %%B in ("%%~A") DO (
        SET dataf=%%D%%C%%B
		SET datas=%%B/%%C/%%D
    )
)
:: Consultando hora atual
FOR /F "tokens=1-3 delims=:.," %%A IN ("%Time%") DO (
	SET horaf=%%A%%B%%C
	SET horas=%%A:%%B:%%C
)
:: Concatenando data e hora
SET agoraf=%dataf%%horaf%
SET agoras=%datas% %horas%
GOTO:EOF

:error1
ECHO.
ECHO *** ERRO 01: Nao foi possivel localizar o arquivo de configuracao %cfgpathfull%.
ECHO.
GOTO:EOF

:error2
ECHO.
ECHO *** ERRO 02: Nao foi possivel criar o arquivo compactado %batzipname%.
ECHO.
GOTO:EOF

:cancel
ECHO.
ECHO *** Operacao cancelada.
ECHO.
GOTO:EOF

:end
:: Restaura a pasta de origem
POPD
:: Resetando variaveis
ENDLOCAL
