#include "Crypt.au3"
#include "Array.au3"
#include "_http_wrapper.au3"
#include "JSON.au3"

global $sSession	;="0523eb904d3ddcb7d0af0479a4e3da9dba776d2e0e8950e503d49184bc575d"
global $sViewer	;="11096378"
global $p_key		;="245f518dc8b3c5d8c8725f1bc3195410"
Global $p_sess=0

global $json_data
Global $cached_data
Global $cached = false


; #FUNCTION# ;===============================================================================
; Name...........: Metro_Init
; Description ...: Инициализирует подключение к серверу, и выполняет запрос "user.auth"
; Syntax.........: Metro_Init ($hRequest, $sHeaders [, $iModifiers = Default ])
; Parameters ....: $hRequest - Handle returned by _WinHttpOpenRequest function.
;                  $sHeader - [optional] Header(s) to append to the request.
;                  $iModifier - [optional] Contains the flags used to modify the semantics of this function. Default is $WINHTTP_ADDREQ_FLAG_ADD_IF_NEW.
; Return values .: Success - Returns 1
;                  Failure - Returns 0 and sets @error:
;                  |1 - DllCall failed
;============================================================================================
Func Metro_Init()
   _DebugOut ("[metro] initialization ...")
      
   if NOT _http_init() Then 
	  _DebugOut ("[metro] http_init error")
	  SetError (1)
   ElseIf NOT _metro_auth() Then
	  _DebugOut ("[metro] metro_auth error")
	  SetError (2)
   ElseIf NOT _metro_cacheData() Then
	  _DebugOut ("metro_cacheData error")
	  SetError (3)
   EndIf
   
   ;_ArrayDisplay ($cached_data)
   
   if Not @error Then
	  $p_sess = $cached_data[1][1]
	  _DebugOut ("[metro] initialization complete. SessionId: " & $p_sess)
	  Return 1
   Else
	  _DebugOut ("[metro] error on metro initialization. Exit programm.")
	  Return @error
   EndIf
   
EndFunc	;==>_WinHttpAddRequestHeaders

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

Func _metro_auth()
   local $params[2] = ["pals=0", "lmenu=1"]
      
   $json_data = _run_method("user.auth", $params)
   
   if @error then return SetError (1, 0, 0)
	  
   _DebugOut ("[metro] Auth successful! Received " & StringLen ($json_data) & " bytes")
   Return 1   
EndFunc

Func metro_getGold()
   if (not $cached) then Return 0
   local $pd = $cached_data[4][1]
   Return $pd[13][1]
EndFunc

Func metro_GetEnergy()
   if (not $cached) then Return 0
   local $pd = $cached_data[4][1]
   Return $pd[28][1]
EndFunc
   
Func _metro_cacheData()
   Debug ("Start caching of data...","metro")
   local $t1 = TimerInit()
   if (not $cached) Then 
	  SaveCache ($json_data)
	  $cached_data = _JSONDecode ($json_data)
   EndIf
   $cached=true
   Local $t2 = TimerDiff($t1)
   Debug ("Cached received data in " & $t2 & " ms.","metro")
   Return 1
EndFunc

Func metro_OpenArena()
   local $params[1] = ["sess="&$p_sess]
   
   local $recv_data = _run_method("fray.arena", $params)
   
   if @error then return SetError (1, 0, "")
   SetExtended (StringLen ($recv_data))
   return $recv_data
EndFunc

Func metro_StartArena($opponent_id)
   local $params[4] = ["foe="&$opponent_id, "pay=0", "ctx=21", "sess="&$p_sess]
   local $recv_data = _run_method ("fray.start", $params)
   
   if @error then return SetError (1, 0, "")
   SetExtended (StringLen ($recv_data))
   return $recv_data
EndFunc

Func metro_StopArena()
   local $params[1] = ["sess="&$p_sess]
   local $recv_data = _run_method ("fray.stop", $params)
   
   if @error then return SetError (1, 0, "")
   SetExtended (StringLen ($recv_data))
   return $recv_data
EndFunc

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
   ;Переменные $sSession, $sViewer - должны быть глобально заданны при инициализации
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
   ;_ArrayDisplay ($params); Для отладки
   local $recv_data = _http_SendAndReceive($params)
   
   if @error then return SetError (1, 0, "")
   SetExtended (StringLen ($recv_data))
   return $recv_data
EndFunc	;==>_run_method