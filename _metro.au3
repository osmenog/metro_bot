#include "Crypt.au3"
#include "Array.au3"
#include "_http_wrapper.au3"
#include "JSON.au3"

global $sSession
global $sViewer
global $p_key
Global $p_sess=0

global $json_data
Global $cached_data
Global $cached = false

;~ Global $oCache
;~ Global $oMyError

Global $metro_var_gold = 0			;������
Global $metro_var_xp = 0			;����
Global $metro_var_level = 0			;�������
Global $metro_var_energy = 0		;���������� �������
Global $metro_var_ratio = 0			;��������� �����
Global $metro_var_ArenaTimer = 0	;��������� ��������� ����� �� �����

; #FUNCTION# ;===============================================================================
; Name...........: Metro_Init
; Description ...: �������������� ����������� � �������, � ��������� ������ "user.auth"
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
   
;~    $oCache = ObjCreate("Scripting.Dictionary") ; ������� ������ - ������������� ������
;~    $oMyError = ObjEvent("AutoIt.Error", "Metro_ErrHandler")    ; Initialize a COM error handler
   
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
;~    $oMyError = 0
;~    $oCache = 0
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

Func _metro_cacheData()
   _DebugOut ("[metro] Start caching of data...")
   local $t1 = TimerInit()
   if (not $cached) Then 
	  ;SaveCache ($json_data, "cache_auth.txt")
	  $cached_data = _JSONDecode ($json_data)
	  ;---
	  local $player = $cached_data[4][1]
	  $metro_var_gold = $player[13][1]
	  $metro_var_xp = $player[17][1]
	  $metro_var_level = $player[19][1]
	  $metro_var_ratio = $player[20][1]
	  $metro_var_energy = $player[28][1]
	  local $player_stat = $player[29][1]
	  $metro_var_ArenaTimer = $player_stat[14][1]
	  ;---
   EndIf
   $cached=true
   Local $t2 = TimerDiff($t1)
   _DebugOut ("[metro] Cached received data in " & $t2 & " ms.")
   Return 1
EndFunc

;������� ��� ������ � ������

; #FUNCTION# ;===============================================================================
; Name...........: Metro_OpenArena
; Description ...: ��������� ������� �������� �����, � ��������� ���������� � ���������
; Syntax.........: Metro_OpenArena ()
; Return values .: ����� - ���������� ������ ���������, ���������� ���������� � ���������:
;                          [0] - ID (foe)
;                          [1] - ���
;                          [2] - �������
;                  ������� - ������������ ������ ������ "" � @error:
;                          |1 - ������ �����������
;                          |2 - ������ �����������
;                          |3 - ������ ������ �� ������ ������
;                          - @extended ���������� ����� ������ ���������� �� �������
;============================================================================================
Func Metro_OpenArena()
   local $params[1] = ["sess="&$p_sess]
   local $recv_data = _run_method("fray.arena", $params)
   
   if @error then return SetError (1, 0, "") ;������ ����������� - 1
	  
   ; ��������� �������� �� ������������ ������
   local $arena_data = _JSONDecode($recv_data)
   if (@error<>0) and (NOT IsArray($arena_data)) then 
	  _DebugOut ("������ �������� ������: " & $_JSONErrorMessage)
	  _DebugReportVar("$arena_data", $arena_data, True) ;�� ������ ������, ���� JSONDecode ������ ������.
	  return SetError (3, 0, "") ;������ ������������ ������ - 3
   EndIf
   
   If ($arena_data[1][0] = "error") Then
	  _DebugOut ("������ � OpenArena. ��������� �������� ������")
	  _DebugReportVar ("$recv_data",$recv_data)
	  Return SetError (2, $arena_data[1][1], "")
   EndIf
     
   ;��������� ������������ ������
   local $foe = $arena_data[1][1]
   local $resp_array[3] = [ $foe[1][1], $foe[2][1], $foe[13][1] ]
   
   return $resp_array
EndFunc ;==>Metro_OpenArena
; #FUNCTION# ;===============================================================================
; Name...........: Metro_ArenaFight
; Description ...: ���������� ��� � ���������� �� ����� 
; Syntax.........: Metro_ArenaFight ($sOpponentID)
; Parameters ....: $sOpponentID - ID ��������� ���������� ���������
; Return values .: ����� - ���������� ������ ���������, ���������� ���������� � �����:
;                          [0] - ���� ������ (1-�������, 0-���������)
;                          [1] - ������������ ������
;                          [2] - ������������ ����
;                  ������� - ������������ ������ ������ "" � @error:
;                          |1 - ������ �����������
;                          |2 - ������ �����������
;                          |3 - ������ ������ �� ������ ������
;                          - @extended ���������� ����� ������ ���������� �� �������
;============================================================================================
Func Metro_ArenaFight($sOpponentID)
   local $params[4] = ["foe="&$sOpponentID, "pay=0", "ctx=21", "sess="&$p_sess]
   local $recv_data = _run_method ("fray.start", $params)
   
   if @error then return SetError (1, 0, "") ;������ �����������
   
  ; ��������� �������� �� ������������ ������
   local $arena_data = _JSONDecode($recv_data)
   if (@error<>0) and (NOT IsArray($arena_data)) then 
	  _DebugOut ("������ �������� ������: " & $_JSONErrorMessage)
	  _DebugReportVar("$recv_data", $recv_data, True) ;�� ������ ������, ���� JSONDecode ������ ������.
	  return SetError (3, 0, "") ;������ ������������ ������ - 3
   EndIf
   
   If ($arena_data[1][0] = "error") Then
	  _DebugOut ("������ � ArenaFight. ��������� �������� ������")
	  _DebugReportVar ("arena_data",$arena_data, True)
	  Return SetError (2, $arena_data[1][1], "")
   EndIf
     
   ;��������� ������������ ������
   local $fray = $arena_data[2][1]
   local $rew = $fray[6][1]
   local $resp_array[3] = [ 1, $rew[1][1], $rew[2][1] ]
   
   $metro_var_ArenaTimer = _TimeGetStamp() + 300
   
   return $resp_array
EndFunc ;==>Metro_ArenaFight
; #FUNCTION# ;===============================================================================
; Name...........: Metro_ArenaStop
; Description ...: ��������� ������� ��� � ���������� 
; Syntax.........: Metro_ArenaStop()
; Parameters ....: 
; Return values .: ����� - ���������� ������ ���������, ���������� ���������� � �����:
;                          [0] - ������������ ������
;                          [1] - ������������ ����
;                          [2] - ���������� �����
;                  ������� - ������������ ������ ������ "" � @error:
;                          |1 - ������ �����������
;                          |2 - ������ �����������
;                          |3 - ������ ������ �� ������ ������
;                          - @extended ���������� ����� ������ ���������� �� �������
;============================================================================================
Func Metro_ArenaStop()
   local $params[1] = ["sess="&$p_sess]
   local $recv_data = _run_method ("fray.stop", $params)
   
   if @error then return SetError (1, 0, "") ; 1-������ �����������
	  
    local $arena_data = _JSONDecode($recv_data)
   if (@error<>0) and (NOT IsArray($arena_data)) then 
	  _DebugOut ("������ �������� ������: " & $_JSONErrorMessage)
	  _DebugReportVar("$recv_data", $recv_data, True) ;�� ������ ������, ���� JSONDecode ������ ������.
	  return SetError (3, 0, "") ;������ ������������ ������ - 3
   EndIf
   
   If ($arena_data[1][0] = "error") Then
	  _DebugOut ("������ � ArenaStop. ��������� �������� ������")
	  _DebugReportVar ("arena_data",$arena_data, True)
	  Return SetError (2, $arena_data[1][1], "")
   EndIf
   
   ;������ ������������ ������:
   ;{"player":{"gold":339,"xp":12849,"ratio":150,"ctx":0,"stat":{"31":172}},"fray":{"win":0,"ctx":0,"run":0,"seq":[],"foe":[],"rew":[],"skip":0}}
   
   ;��������� ������������ ������
   local $player = $arena_data[1][1]
   ;If Not _ArrayDisplay ($player) then _DebugReportVar ("$player", $player, True)
   local $resp_array[3] = [ $player[1][1], $player[2][1], $player[3][1] ]
   
   $metro_var_gold = $resp_array[0]
   $metro_var_xp = $resp_array[1]
   $metro_var_ratio = $resp_array[2]
   
   return $resp_array
EndFunc ;==>Metro_ArenaStop
; #FUNCTION# ;===============================================================================
; Name...........: _run_method
; Description ...: �������������� � ���������� ������ �� ������. 
; Syntax.........: _run_method ($sMethod, $aParams)
; Parameters ....: $sMethod - ��� ����������� �������.
;                  $aParams - ������, ���������� � ���� �������������� ��������� ��� �������.
; Return values .: ����� - ������������ ����� �� ������ � ��������� ����
;                        - @extended �������� ���������� �������� ����
;                  ������� - ������������ ������ ������ "" � @error:
;                  |1 - ������ �����������
;                  |2 - ������ �������� ���������
;============================================================================================
Func _run_method ($sMethod, $aParams)
   local $params[1]
   ;���������� $sSession, $sViewer - ������ ���� ��������� ������� ��� �������������
   _ArrayAdd ($params, "session=" & $sSession)
   _ArrayAdd ($params, "method=" & $sMethod)
   _ArrayAdd ($params, "user=" & $sViewer)
   _ArrayAdd ($params, "hash=" & Int(Random (Default, 4294967295)))
   
   If (IsArray ($aParams)) AND (UBound($aParams) <> 0) then 
	  _ArrayConcatenate ($params, $aParams)
   Else
	  return SetError (2,0,"") ; ������ ������� ������
   EndIf
   
   _AddSign ($params) ;��������� �������
   ;_ArrayDisplay ($params); ��� �������
   local $recv_data = _http_SendAndReceive($params)
   ;local $recv_data = LoadFromCache ("cache_" & $sMethod & ".txt")
   
   if @error then return SetError (1, 0, "")
   SetExtended (StringLen ($recv_data))
   
   SaveCache ($recv_data, "cache_" & $sMethod & ".txt") ;��������� �������� ������ � ���
   
   return $recv_data
EndFunc	;==>_run_method

Func IsFightTimeout()
   if (not $cached) then Return 0
   
   local $currenttime = _TimeGetStamp()
   if $currenttime > $metro_var_ArenaTimer then 
	  Return False
   Else
      ;_DebugOut ("time diff = " & $metro_var_ArenaTimer - $currenttime)
	  SetExtended ($metro_var_ArenaTimer)
	  Return True
   EndIf
EndFunc

;~ ; This is my custom defined error handler
;~ Func Metro_ErrHandler()
;~    Local $err = $oMyError.number
;~    If $err = 0 Then $err = -1
;~    SetError($err)  ; to check for after this function returns
;~ EndFunc   ;==>MyErrFunc