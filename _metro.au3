#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7
#include-once
#include <Crypt.au3>
#include <Array.au3>
#include "AssocArrays.au3"
#include "_http_wrapper.au3"
#include "JSON.au3"

global $sSession
global $sViewer
global $p_key
Global $p_sess=0

global $json_data
Global $cached_data
Global $cached = false

Global $CacheArray

;~ Global $metro_var_gold = 0					;Деньги
;~ Global $metro_var_xp = 0					;Опыт
;~ Global $metro_var_level = 0					;Уровень
;~ Global $metro_var_energy = 0				;Оставшаяся энергия
;~ Global $metro_var_ratio = 0					;Количетво Побед
;~ Global $metro_var_ArenaTimer = 0			;Таймштамп последней битвы на арене
;~ Global $metro_var_NotFinishedFight = False	;Завершени ли предыдущая битва или нет
;~ Global $metro_var_servertime = 0			;Текущее время на сервере

;~ Global $metro_var_job_finished = 0			;Время окончания выполнения работы
;~ Global $metro_var_job_num = 0				;Номер работы
;~ Global $metro_var_job_goldrew = 0			;Денежное вознаграждение за выполнение работы

; #FUNCTION# ;===============================================================================
; Name...........: Metro_Init
; Description ...: Инициализирует подключение к серверу, и выполняет запрос "user.auth"
; Syntax.........: Metro_Init ()
; Return values .: Успех - Возвращает True
;                  Неудача - Возвращает False и устанавливает @error:
;                  |1 - Ошибка инициализации http модуля
;                  |2 - Ошибка авторизации metro_auth
;                  |3 - Ошибка кеширования данных
;============================================================================================
Func Metro_Init()
   DebugPrnt ("Начинаем инициализацию...")
   if NOT _http_init() Then 
	  DebugPrnt ("Ошибка при инициализации HTTP протокола!!!")
	  return SetError (1, 0, False)
   ElseIf NOT Metro_Auth() Then
	  DebugPrnt ("Ошибка при авторизации!!!")
	  return SetError (2, 0, False)
   ElseIf NOT _metro_cacheData() Then
	  DebugPrnt ("Ошибка при кешировании данных!!!")
	  return SetError (3, 0, False)
   EndIf
     
   $p_sess = $cached_data[1][1]
   DebugPrnt ("Инициализация завершена! SessionId: " & $p_sess)
   Return True
EndFunc	;==>Metro_Init

Func Metro_destruct()
   _http_destruct()
EndFunc

Func _AddSign (ByRef $p)
   _ArraySort ($p)
   _Crypt_Startup()
   local $sig= StringLower (StringTrimLeft(_Crypt_HashData(_ArrayToString ($p,"") & $p_key, $CALG_MD5),2))
   _Crypt_Shutdown()
   _ArrayPush ($p, "auth=" & $sig)
EndFunc

; #FUNCTION# ;===============================================================================
; Name...........: Metro_Auth()
; Description ...: Выполняет запрос "user.auth", возвращает полную информацию об игре
; Syntax.........: Metro_Auth()
; Return values .: Успех - Возвращает True и сохраняет полную информацию об игре в глобальную переменную $json_data
;						 @extended - длина принятых  данных
;                  Неудача - Возвращает False и устанавливает @error:
;                  |1 - Ошибка подключения или в некорректность принятых данных
;                  |2 - Ошибка авторизации
;                          - В @extended записывается номер ошибки полученной с сервера
;============================================================================================
Func Metro_Auth()
   local $params[2] = ["pals=0", "lmenu=1"]
   $json_data = _run_method("user.auth", $params)
   if @error then return SetError (1, 0, False) ;Ошибка подключения
   
   local $tmp = StringLeft($json_data, 20)	;Берем 20 символов слева
   $err = StringInStr ($tmp, "error")		;Ищем в подстроке строку "error"
   if $err <> 0 then 						;Если подстрока найдена
	  DebugPrnt ("Сервер возвратил ошибку: " & $json_data, 1)
	  local $startpos = $err+5+2
	  local $endpos = StringInStr($tmp, ",", 0, 1, $startpos)
	  Local $err_num = StringMid ($tmp, $startpos, $endpos-$startpos)
	  Return SetError (2, $err_num, False)
   EndIf
   SetExtended (StringLen ($json_data))
   DebugPrnt ("Авторизация завершена! Принято " & @extended & " байт")
   Return True
EndFunc ;==> Metro_Auth

Func _metro_cacheData()
   DebugPrnt ("Кешируем данные...", 1)
   local $t1 = TimerInit()
   if (not $cached) Then 
	  $cached_data = _JSONDecode ($json_data)
	  ;---
	  AssocArrayCreate ($CacheArray,10) ;Создаем ассоциативный массив размером 10 элементов
	  ;Получаем информацию о игроке
	  local $player = $cached_data[4][1]
	  AssocArrayAssign($CacheArray, "gold", $player[13][1])
	  AssocArrayAssign($CacheArray, "xp", $player[17][1])
	  AssocArrayAssign($CacheArray, "level", $player[19][1])
	  AssocArrayAssign($CacheArray, "ratio", $player[20][1])
	  AssocArrayAssign($CacheArray, "energy", $player[28][1])
	  
	  local $player_stat = $player[29][1]
	  AssocArrayAssign($CacheArray, "arenatimer", $player_stat[14][1])
	  	  
	  local $fray = $cached_data[7][1]
	  local $foe = $fray[2][1]
	  
	  AssocArrayAssign($CacheArray, "isfight", False)
	  if IsArray($foe) and (UBound($foe) <> 0) then AssocArrayAssign($CacheArray, "isfight", True)
	  AssocArrayAssign($CacheArray, "servertime", $cached_data[13][1])
	  
	  local $jobs = $cached_data[10][1]
	  AssocArrayAssign($CacheArray, "job_finished", $jobs[1][1])
	  AssocArrayAssign($CacheArray, "job_num", $jobs[2][1])
	  AssocArrayAssign($CacheArray, "job_goldrew", $jobs[3][1])
	  
	  ;AssocArrayDisplay ($CacheArray)
	  ;---
   EndIf
   $cached=true
   Local $t2 = TimerDiff($t1)
   DebugPrnt ("Кеширование завершено за " & $t2 & " мс!", 1)
   Return 1
EndFunc

#region "Функции для работы с ареной"
; #FUNCTION# ;===============================================================================
; Name...........: Metro_OpenArena
; Description ...: Выполняет функцию открытия арены, и получения информации о сопернике
; Syntax.........: Metro_OpenArena ()
; Return values .: Успех - Возвращает массив элементов, содержащий информацию о сопернике:
;                          [0] - ID (foe)
;                          [1] - Имя
;                          [2] - Фракция
;                  Неудача - Возвращается пустая строка "" и @error:
;                          |1 - Ошибка подключения
;                          |2 - Ошибка авторизации
;                          |3 - Запрос вернул не верные данные
;                          - @extended возвращает номер ошибки полученную от сервера
;============================================================================================
Func Metro_OpenArena()
   local $params[1] = ["sess="&$p_sess]
   local $recv_data = _run_method("fray.arena", $params)
   
   if @error then return SetError (1, 0, "") ;Ошибка подключения - 1
	  
   ; Выполняем проверку на корректность данных
   local $arena_data = _JSONDecode($recv_data)
   if (@error<>0) and (NOT IsArray($arena_data)) then 
	  DebugPrnt ("Ошибка принятых данных: " & $_JSONErrorMessage)
	  _DebugReportVar("$arena_data", $arena_data, True) ;На всякий случай, если JSONDecode вернет ошибку.
	  return SetError (3, 0, "") ;Ошибка корректности данных - 3
   EndIf
   
   If ($arena_data[1][0] = "error") Then
	  DebugPrnt ("Ошибка в OpenArena. Вернулись неверные данные")
	  _DebugReportVar ("$recv_data",$recv_data)
	  Return SetError (2, $arena_data[1][1], "")
   EndIf
     
   ;Формируем возвращаемый массив
   local $foe = $arena_data[1][1]
   local $resp_array[3] = [ $foe[1][1], $foe[2][1], $foe[13][1] ]
   
   return $resp_array
EndFunc ;==>Metro_OpenArena

; #FUNCTION# ;===============================================================================
; Name...........: Metro_ArenaFight
; Description ...: Инициирует бой с оппонентом на арене 
; Syntax.........: Metro_ArenaFight ($sOpponentID)
; Parameters ....: $sOpponentID - ID Вконтакте выбранного соперника
; Return values .: Успех - Возвращает массив элементов, содержащий информацию о битве:
;                          [0] - Флаг победы (1-выйгрыш, 0-поражение)
;                          [1] - Заработанные деньги
;                          [2] - Заработанный опыт
;                  Неудача - Возвращается пустая строка "" и @error:
;                          |1 - Ошибка подключения
;                          |2 - Ошибка авторизации
;                          |3 - Запрос вернул не верные данные
;                          - @extended возвращает номер ошибки полученную от сервера
;============================================================================================
Func Metro_ArenaFight($sOpponentID)
   local $params[4] = ["foe="&$sOpponentID, "pay=0", "ctx=21", "sess="&$p_sess]
   local $recv_data = _run_method ("fray.start", $params)
   
   if @error then return SetError (1, 0, "") ;Ошибка подключения
   
  ; Выполняем проверку на корректность данных
   local $arena_data = _JSONDecode($recv_data)
   if (@error<>0) and (NOT IsArray($arena_data)) then 
	  DebugPrnt ("Ошибка принятых данных: " & $_JSONErrorMessage)
	  _DebugReportVar("$recv_data", $recv_data, True) ;На всякий случай, если JSONDecode вернет ошибку.
	  return SetError (3, 0, "") ;Ошибка корректности данных - 3
   EndIf
   
   If ($arena_data[1][0] = "error") Then
	  DebugPrnt ("Ошибка в ArenaFight. Вернулись неверные данные")
	  _DebugReportVar ("arena_data",$arena_data, True)
	  Return SetError (2, $arena_data[1][1], "")
   EndIf
     
   ;Формируем возвращаемый массив
   local $player = $arena_data[1][1]
   local $stat = $player[3][1]
   AssocArrayAssign ($CacheArray, "arenatimer", $stat[1][1])
   local $fray = $arena_data[2][1]
   local $rew = $fray[6][1]
   local $resp_array[3] = [ $fray[1][1], $rew[1][1], $rew[2][1] ]
   
   if $fray[1][1] = 1 then 
	  SaveStatistics ($resp_array[1], $resp_array[2], 1, 0)
   else
	  SaveStatistics (0, 0, 0, 1)
   EndIf
   
   return $resp_array
EndFunc ;==>Metro_ArenaFight

; #FUNCTION# ;===============================================================================
; Name...........: Metro_ArenaStop
; Description ...: Завершает начатый бой с соперником 
; Syntax.........: Metro_ArenaStop()
; Parameters ....: 
; Return values .: Успех - Возвращает массив элементов, содержащий информацию о битве:
;                          [0] - Заработанные деньги
;                          [1] - Заработанный опыт
;                          [2] - Количество побед
;                  Неудача - Возвращается пустая строка "" и @error:
;                          |1 - Ошибка подключения
;                          |2 - Ошибка авторизации
;                          |3 - Запрос вернул не верные данные
;                          - @extended возвращает номер ошибки полученную от сервера
;============================================================================================
Func Metro_ArenaStop()
   local $params[1] = ["sess="&$p_sess]
   local $recv_data = _run_method ("fray.stop", $params)
   
   if @error then return SetError (1, 0, "") ; 1-Ошибка подключения
	  
    local $arena_data = _JSONDecode($recv_data)
   if (@error<>0) and (NOT IsArray($arena_data)) then 
	  DebugPrnt ("Ошибка принятых данных: " & $_JSONErrorMessage)
	  _DebugReportVar("$recv_data", $recv_data, True) ;На всякий случай, если JSONDecode вернет ошибку.
	  return SetError (3, 0, "") ;Ошибка корректности данных - 3
   EndIf
   
   If ($arena_data[1][0] = "error") Then
	  DebugPrnt ("Ошибка в ArenaStop. Вернулись неверные данные")
	  _DebugReportVar ("arena_data",$arena_data, True)
	  Return SetError (2, $arena_data[1][1], "")
   EndIf
   
   ;Формируем возвращаемый массив
   local $player = $arena_data[1][1]
   ;If Not _ArrayDisplay ($player) then ReportVar ("$player", $player, True)
   local $resp_array[3] = [ $player[1][1], $player[2][1], $player[3][1] ]
   
   AssocArrayAssign($CacheArray, "gold", $resp_array[0])
   AssocArrayAssign($CacheArray, "xp", $resp_array[1])
   AssocArrayAssign($CacheArray, "ratio", $resp_array[2])
   
   return $resp_array
EndFunc ;==>Metro_ArenaStop
#endregion

; #FUNCTION# ;===============================================================================
; Name...........: _run_method
; Description ...: Подготавливает и отправляет запрос за сервер. 
; Syntax.........: _run_method ($sMethod, $aParams)
; Parameters ....: $sMethod - Тип выполняемой команды.
;                  $aParams - Массив, содержищий в себе дополнительные параметры для запроса.
; Return values .: Успех - Возвращается ответ на запрос в текстовом виде
;                        - @extended содержит количество принятых байт
;                  Неудача - Возвращается пустая строка "" и @error:
;                  |1 - Ошибка подключения
;                  |2 - Ошибка входного параметра
;============================================================================================
Func _run_method ($sMethod, $aParams)
   local $params[1]
   _ArrayAdd ($params, "session=" & $sSession)
   _ArrayAdd ($params, "method=" & $sMethod)
   _ArrayAdd ($params, "user=" & $sViewer)
   _ArrayAdd ($params, "hash=" & Int(Random (Default, 4294967295)))
   
   If (IsArray ($aParams)) AND (UBound($aParams) <> 0) then 
	  _ArrayConcatenate ($params, $aParams)
   Else
	  return SetError (2,0,"") ; Ошибка входных данных
   EndIf
   
   _AddSign ($params) ;Добавляем подпись
   local $recv_data = _http_SendAndReceive($params)
   
   if @error then return SetError (1, 0, "")
   SetExtended (StringLen ($recv_data))
   
   if $settings_savecache = 1 then SaveCache ($recv_data, "cache_" & $sMethod & ".txt") ;Сохраняем принятые данные в кэш
	  
   return $recv_data
EndFunc	;==>_run_method

; #FUNCTION# ;===============================================================================
; Name...........: IsFightTimeout
; Description ...: Определяет, активен ли таймаут с последнего запроса ArenaFight
; Syntax.........: IsFightTimeout ()
; Return values .: True - Таймаут активен, тоесть необходимо сделать паузу
;                       - @extended содержит штамп времени, когда таймаут закончится
;                  False - Таймаут не активет, тоесть можно выполнять запрос ArenaStop
;============================================================================================
Func IsFightTimeout()
   if (not $cached) then Return 0
   
   local $currenttime = _TimeGetStamp()
   local $arenatime = AssocArrayGet($CacheArray, "arenatimer") 
   
   if $currenttime > $arenatime then 
	  Return False
   Else
	  SetExtended ($arenatime)
	  Return True
   EndIf
EndFunc ;==>IsFightTimeout

#region "Работа"
Func IsJobFinished()
   if (not $cached) then Return 0
   
   local $ts = _TimeGetStamp()
   local $jf = AssocArrayGet($CacheArray, "job_finished") 
   
   if $jf < $ts then ;Если время окончания работы меньше текущего
	  Return True
   Else
	  SetExtended ($jf-$ts) ; Возвращаем разницу по времени 
	  Return False
   EndIf
EndFunc

; #FUNCTION# ;===============================================================================
; Name...........: Metro_JobTake
; Description ...: Начать выполнять указанную работу
; Syntax.........: Metro_JobTake ([$iDefaultJob = 2])
; Parameters ....: $iDefaultJob - Номер выполняемой работы.
; Return values .: Успех - Возвращает True.
;                  Неудача - Возвращает False, и устанавливает @error:
;                  |1 - Ошибка подключения
;                  |2 - %%%%%%%%%%%%%%%%%%%%%%%%%%%%
;                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;============================================================================================
Func Metro_JobTake($iDefaultJob = 2) ;Взять работу
   local $params[2] = ["sess="&$p_sess, "job="&$iDefaultJob]
   local $recv_data = _run_method ("jobs.take", $params)
   if @error then return SetError (1, 0, False) ; 1-Ошибка подключения
   
   local $job_data = _JSONDecode($recv_data)
   if (@error<>0) and (NOT IsArray($job_data)) then 
	  DebugPrnt ("Ошибка принятых данных: " & $_JSONErrorMessage)
	  _DebugReportVar("$recv_data", $recv_data, True) ;На всякий случай, если JSONDecode вернет ошибку.
	  return SetError (3, 0, False) ;Ошибка корректности данных - 3
   EndIf
   
   If ($job_data[1][0] = "error") Then
	  DebugPrnt ("Ошибка в ArenaStop. Вернулись неверные данные")
	  _DebugReportVar ("arena_data",$job_data, True)
	  Return SetError (2, $job_data[1][1], False)
   EndIf
  
   $job_data = $job_data[1][1]
   AssocArrayAssign($CacheArray, "job_finished", $job_data[1][1])
   AssocArrayAssign($CacheArray, "job_num", $job_data[2][1])
   AssocArrayAssign($CacheArray, "job_goldrew", $job_data[3][1])
   
   Return true
EndFunc

Func Metro_JobEarn() ;Завершить работу и получить награду
   local $params[1] = ["sess="&$p_sess]
   local $recv_data = _run_method ("jobs.earn", $params)
   if @error then return SetError (1, 0, False) ; 1-Ошибка подключения
   
   local $job_data = _JSONDecode($recv_data)
   if (@error<>0) and (NOT IsArray($job_data)) then 
	  DebugPrnt ("Ошибка принятых данных: " & $_JSONErrorMessage)
	  _DebugReportVar("$recv_data", $recv_data, True) ;На всякий случай, если JSONDecode вернет ошибку.
	  return SetError (3, 0, False) ;Ошибка корректности данных - 3
   EndIf
   
   If ($job_data[1][0] = "error") Then
	  DebugPrnt ("Ошибка в JobEarn. Вернулись неверные данные")
	  _DebugReportVar ("$job_data",$job_data, True)
	  Return SetError (2, $job_data[1][1], False)
   EndIf
   
   AssocArrayAssign($CacheArray, "job_finished", 0)
   AssocArrayAssign($CacheArray, "job_num", 0)
   AssocArrayAssign($CacheArray, "job_goldrew", 0)
   return True
EndFunc

Func AssocArrayDisplay (ByRef $avArray)
   $asKeys = AssocArrayKeys($avArray)

   $sName = ""
   For $iCount = 0 To UBound($asKeys) - 1
	  $sName &= "[" & $asKeys[$iCount] & "] = " & AssocArrayGet($avArray, $asKeys[$iCount]) & @CRLF
   Next
   DebugPrnt ($sName)
EndFunc
#endregion