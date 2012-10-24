#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7
#include-once
#include <Array.au3>
#include "_http_wrapper.au3"
#include "JSON.au3"

#region ���������� ���������� ��������
;��������� ������
global $sSession	;�������� sid, ������������ flash-����������.
global $sViewer		;��������� ID ������������.
global $p_key		;�������� auth_key,  ������������ flash-����������.
Global $p_sess=0	;����� ������, ������������ �� ������� ��� �����������.

;��������� ������
global $json_data		;����������� ������ �������� ������� ������, ���������� ��� �����������, � ��������������� �� JSON.
Global $cached = false 	;���� ����������: ��� �� ������ ��������� ��������� ������� ������ ��� ���
Global $CacheArray		;������, ���������� ��������� ����� ������� ������.
Global $cached_data		

;��������� �����������
Global const $AppVersion = "121022" ;������� ������ ����������
Global const $RequestURI = "/metro/vk/" & $AppVersion & "/vk_metro.php" ;����� ��� HTTP ��������

;���������
global const $JOB_NOTEARN = 0
global const $JOB_ACTIVE = 1
global const $JOB_FINISHED = 2
#endregion
#region �������� �������
; #FUNCTION# ;===============================================================================
; Name...........: Metro_Init
; Description ...: �������������� ����������� � �������, � ��������� ������ "user.auth"
; Syntax.........: Metro_Init ()
; Return values .: ����� - ���������� True
;                  ������� - ���������� False � ������������� @error:
;                  |1 - ������ ������������� http ������
;                  |2 - ������ ����������� metro_auth
;                  |3 - ������ ����������� ������
;============================================================================================
Func Metro_Init()
   DebugPrnt ("�������� �������������...")
   if NOT _http_init() Then 
	  DebugPrnt ("������ ��� ������������� HTTP ���������!!!")
	  return SetError (1, 0, False)
   ElseIf NOT Metro_Auth() Then
	  local $err = @extended
	  Switch $err
		 Case "1290"
			DebugPrnt ("������ #" & $err & ". ������ �������� �������, ����� �������� ������!!!")
		 Case "1202"
			DebugPrnt ("������ #" & $err & ". ��������� �������� �����������, ����� ������� sid � auth_key!!!")
		 Case Else
			DebugPrnt ("������ #" & $err & " ��� �����������!!!")
	  EndSwitch
	  return SetError (2, $err, False)
   ElseIf NOT _metro_cacheData() Then
	  DebugPrnt ("������ ��� ����������� ������!!!")
	  return SetError (3, 0, False)
   EndIf
     
   $p_sess = $cached_data[1][1]
   DebugPrnt ("������������� ���������! SessionId: " & $p_sess)
   Return True
EndFunc	;==>Metro_Init

Func Metro_destruct()
   _http_destruct()
EndFunc

; #FUNCTION# ;===============================================================================
; Name...........: Metro_Auth()
; Description ...: ��������� ������ "user.auth", ���������� ������ ���������� �� ����
; Syntax.........: Metro_Auth()
; Return values .: ����� - ���������� True � ��������� ������ ���������� �� ���� � ���������� ���������� $json_data
;						 @extended - ����� ��������  ������
;                  ������� - ���������� False � ������������� @error:
;                  |1 - ������ ����������� ��� � �������������� �������� ������
;                  |2 - ������ �����������
;                          - � @extended ������������ ����� ������ ���������� � �������
;============================================================================================
Func Metro_Auth()
   local $params[2] = ["pals=0", "lmenu=1"]
   $json_data = _run_method("user.auth", $params)
   if @error then return SetError (1, 0, False) ;������ �����������
   
   local $tmp = StringLeft($json_data, 20)	;����� 20 �������� �����
   $err = StringInStr ($tmp, "error")		;���� � ��������� ������ "error"
   if $err <> 0 then 						;���� ��������� �������
	  DebugPrnt ("������ ��������� ������: " & $json_data, 1)
	  local $startpos = $err+5+2
	  local $endpos = StringInStr($tmp, ",", 0, 1, $startpos)
	  Local $err_num = StringMid ($tmp, $startpos, $endpos-$startpos)
	  Return SetError (2, $err_num, False)
   EndIf
   SetExtended (StringLen ($json_data))
   DebugPrnt ("����������� ���������! ������� " & @extended & " ����")
   Return True
EndFunc ;==> Metro_Auth

Func _metro_cacheData()
   DebugPrnt ("�������� ������...", 1)
   local $t1 = TimerInit()
   if (not $cached) Then 
	  $cached_data = _JSONDecode ($json_data)
	  ;---
	  AssocArrayCreate ($CacheArray,10) ;������� ������������� ������ �������� 10 ���������
	  ;�������� ���������� � ������
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
   DebugPrnt ("����������� ��������� �� " & $t2 & " ��!", 1)
   Return 1
EndFunc

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
   local $recv_data = _http_SendAndReceive($params)
   
   if @error then return SetError (1, 0, "")
   SetExtended (StringLen ($recv_data))
   
   if $settings_savecache = 1 then SaveCache ($recv_data, "cache_" & $sMethod & ".txt") ;��������� �������� ������ � ���
	  
   return $recv_data
EndFunc	;==>_run_method
#endregion
#region ������� ��� ������ � ������
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
	  DebugPrnt ("������ �������� ������: " & $_JSONErrorMessage)
	  _DebugReportVar("$arena_data", $arena_data, True) ;�� ������ ������, ���� JSONDecode ������ ������.
	  return SetError (3, 0, "") ;������ ������������ ������ - 3
   EndIf
   
   If ($arena_data[1][0] = "error") Then
	  DebugPrnt ("������ � OpenArena. ��������� �������� ������")
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
	  DebugPrnt ("������ �������� ������: " & $_JSONErrorMessage)
	  _DebugReportVar("$recv_data", $recv_data, True) ;�� ������ ������, ���� JSONDecode ������ ������.
	  return SetError (3, 0, "") ;������ ������������ ������ - 3
   EndIf
   
   If ($arena_data[1][0] = "error") Then
	  DebugPrnt ("������ � ArenaFight. ��������� �������� ������")
	  _DebugReportVar ("arena_data",$arena_data, True)
	  Return SetError (2, $arena_data[1][1], "")
   EndIf
     
   ;��������� ������������ ������
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
	  DebugPrnt ("������ �������� ������: " & $_JSONErrorMessage)
	  _DebugReportVar("$recv_data", $recv_data, True) ;�� ������ ������, ���� JSONDecode ������ ������.
	  return SetError (3, 0, "") ;������ ������������ ������ - 3
   EndIf
   
   If ($arena_data[1][0] = "error") Then
	  DebugPrnt ("������ � ArenaStop. ��������� �������� ������")
	  _DebugReportVar ("arena_data",$arena_data, True)
	  Return SetError (2, $arena_data[1][1], "")
   EndIf
   
   ;��������� ������������ ������
   local $player = $arena_data[1][1]
   ;If Not _ArrayDisplay ($player) then ReportVar ("$player", $player, True)
   local $resp_array[3] = [ $player[1][1], $player[2][1], $player[3][1] ]
   
   AssocArrayAssign($CacheArray, "gold", $resp_array[0])
   AssocArrayAssign($CacheArray, "xp", $resp_array[1])
   AssocArrayAssign($CacheArray, "ratio", $resp_array[2])
   
   return $resp_array
EndFunc ;==>Metro_ArenaStop

; #FUNCTION# ;===============================================================================
; Name...........: IsFightTimeout
; Description ...: ����������, ������� �� ������� � ���������� ������� ArenaFight
; Syntax.........: IsFightTimeout ()
; Return values .: True - ������� �������, ������ ���������� ������� �����
;                       - @extended �������� ����� �������, ����� ������� ����������
;                  False - ������� �� �������, ������ ����� ��������� ������ ArenaStop
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
#endregion

#region ������
; #FUNCTION# ;===============================================================================
; Name...........: Metro_JobStatus
; Description ...: �������� ���������� � ������� ������
; Syntax.........: Metro_JobStatus()
; Return values .: ����� - ���������� ������:
;                  [0] - ��������� [0|1|2]
;                      |0-������ �� ����� (JOB_NOTEARN)
;                      |1-������ ����������� (JOB_ACTIVE)
;                      |2-������ ���������, �� �� �������� ������� (JOB_FINISHED)
;                  [1] - ����� ���������. ��������������� � 0, ���� ������ �� �����
;                  [2] - ����� ������. ��������������� � 0, ���� ������ �� �����
;                  [3] - �������. ��������������� � 0, ���� ������ �� �����
;                  ������� - ���������� 0, � ������������� @error:
;                  1 - ������ %%%%%%%%%%%%%%%%%%%
;============================================================================================
Func Metro_JobStatus()
   if (not $cached) then Return SetError (1, 0, 0)
   local $ts = Number(_TimeGetStamp())
   local $jf = Number(AssocArrayGet($CacheArray, "job_finished"))
   Select
	  case $jf=0 ;������ �� �����
		 local $resp_array[4] = [$JOB_NOTEARN,0,0,0] 
		 Return $resp_array
	  case $ts<$jf ;������ �����������
		 local $resp_array[4] = [$JOB_ACTIVE, _
								 $jf, _
								 Number(AssocArrayGet($CacheArray, "job_num")), _
								 Number(AssocArrayGet($CacheArray, "job_goldrew"))]
		 Return $resp_array
	  case $ts>$jf ;������ ���������
		 local $resp_array[4] = [$JOB_FINISHED, _
								 $jf, _
								 Number(AssocArrayGet($CacheArray, "job_num")), _
								 Number(AssocArrayGet($CacheArray, "job_goldrew"))]
		 Return $resp_array
	  case Else
		 Return SetError (1, 0, 0)
   EndSelect
EndFunc
; #FUNCTION# ;===============================================================================
; Name...........: Metro_JobTake
; Description ...: ������ ��������� ��������� ������
; Syntax.........: Metro_JobTake ([$iDefaultJob = 2])
; Parameters ....: $iDefaultJob - ����� ����������� ������.
; Return values .: ����� - ���������� True.
;                  ������� - ���������� False, � ������������� @error:
;                  |1 - ������ �����������
;                  |2 - %%%%%%%%%%%%%%%%%%%%%%%%%%%%
;                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;============================================================================================
Func Metro_JobTake($iDefaultJob = 2) ;����� ������
   local $params[2] = ["sess="&$p_sess, "job="&$iDefaultJob]
   local $recv_data = _run_method ("jobs.take", $params)
   if @error then return SetError (1, 0, False) ; 1-������ �����������
   
   local $job_data = _JSONDecode($recv_data)
   if (@error<>0) and (NOT IsArray($job_data)) then 
	  DebugPrnt ("������ �������� ������: " & $_JSONErrorMessage)
	  _DebugReportVar("$recv_data", $recv_data, True) ;�� ������ ������, ���� JSONDecode ������ ������.
	  return SetError (3, 0, False) ;������ ������������ ������ - 3
   EndIf
   
   If ($job_data[1][0] = "error") Then
	  DebugPrnt ("������ � ArenaStop. ��������� �������� ������")
	  _DebugReportVar ("arena_data",$job_data, True)
	  Return SetError (2, $job_data[1][1], False)
   EndIf
  
   $job_data = $job_data[1][1]
   AssocArrayAssign($CacheArray, "job_finished", $job_data[1][1])
   AssocArrayAssign($CacheArray, "job_num", $job_data[2][1])
   AssocArrayAssign($CacheArray, "job_goldrew", $job_data[3][1])
   
   Return true
EndFunc ; ==>Metro_JobTake
; #FUNCTION# ;===============================================================================
; Name...........: Metro_JobEarn
; Description ...: ��������� ������ � �������� �������
; Syntax.........: <%%%>
; Parameters ....: <%%%>
; Return values .: <%%%>
;============================================================================================
Func Metro_JobEarn()
   local $params[1] = ["sess="&$p_sess]
   local $recv_data = _run_method ("jobs.earn", $params)
   if @error then return SetError (1, 0, False) ; 1-������ �����������
   
   local $job_data = _JSONDecode($recv_data)
   if (@error<>0) and (NOT IsArray($job_data)) then 
	  DebugPrnt ("������ �������� ������: " & $_JSONErrorMessage)
	  _DebugReportVar("$recv_data", $recv_data, True) ;�� ������ ������, ���� JSONDecode ������ ������.
	  return SetError (3, 0, False) ;������ ������������ ������ - 3
   EndIf
   
   If ($job_data[1][0] = "error") Then
	  DebugPrnt ("������ � JobEarn. ��������� �������� ������")
	  _DebugReportVar ("$job_data",$job_data, True)
	  Return SetError (2, $job_data[1][1], False)
   EndIf
   
   AssocArrayAssign($CacheArray, "job_finished", 0)
   AssocArrayAssign($CacheArray, "job_num", 0)
   AssocArrayAssign($CacheArray, "job_goldrew", 0)
   return True
EndFunc ; ==>Metro_JobEarn
#endregion

