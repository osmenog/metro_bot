Opt("TrayAutoPause", 0) ;0=no pause, 1=Pause
Opt("TrayIconDebug", 0) ;0=no info, 1=debug line info
Opt("TrayIconHide", 1) ;0=show, 1=hide tray icon

#include "_utils.au3"
#include "_metro.au3"
#include "AssocArrays.au3"

Global $runned = True		;���� ���������� ����
Global Const $ver = "0.4"	;������ �������

local $mr = Main()
Exit ($mr)

Func Main()
   LoadSettings()
   DebugPrnt ("Started v" & $ver & " ...")
   
   If Not Metro_init() then 
	  DebugPrnt ("��������� ������ ���������...")
	  Return 1
   EndIf
   
   #region ����� ���������� � ������� ������
   DebugPrnt ("���������� � �������")
   DebugPrnt ("������: " & AssocArrayGet($CacheArray, "gold") & _
			   "; ����: " & AssocArrayGet($CacheArray, "xp") & _
			   "; �������: " & AssocArrayGet($CacheArray, "energy") & ".", 1)
			   
   local $js = Metro_JobStatus()
   ;_ArrayDisplay ($js)
   Switch $js[0]
   case $JOB_NOTEARN
	  DebugPrnt ("������ �� �����", 1)
   case $JOB_ACTIVE
	  DebugPrnt ("����������� ������ �" & $js[2] & ". ��������� � " & $js[1] & "." & "�������: " & $js[3] & ".", 1)
   case $JOB_FINISHED
	  DebugPrnt ("������ �" & $js[2] & " ��������. �������: " & $js[3] & ".", 1)
   case else 
	  DebugPrnt ("������� Metro_JobStatus ������� ������� ����� :(", 1)
   EndSwitch
   
   local $st = AssocArrayGet($CacheArray, "servertime")
   local $ts = _TimeGetStamp()
   DebugPrnt ("����� �������: " & $st & ". ����� �������: " & $ts & ". ��������: " & ($ts-$st), 1)
   #endregion   
   
   ;AssocArrayDisplay ($CacheArray)
   	  
   While $runned
	  
	  ;��������� ����� �� ������, ���������� �� ���, � �������� ��������������
	  local $js = Metro_JobStatus()   
	  Switch $js[0]
		 case $JOB_NOTEARN
			Metro_JobTake(2)	;����� ������
			If @error=0 then 
			   DebugPrnt ("������� ������ �" & $js[2] & ". ��������� � " & $js[1] & ". �������: " & $js[3] & ".")
			Else
			   DebugPrnt("������ ��� ������ ������")
			EndIf
		 case $JOB_FINISHED
			Metro_JobEarn()		;�������� ��������������
			DebugPrnt ("�������� �������������� �� ������: " & $js[3] & ".")
	  EndSwitch
	  	  
	  ;��������� ���� �� ��������� ���������� ����� �� �����
	  IF AssocArrayGet($CacheArray, "isfight") then 
		 _DebugOut ("���������� �� ����������� ����� �� �����!!!")
		 $fight = Metro_ArenaStop()
		 if @error<>0 then 
			DebugPrnt ("������!!! �� ���� ��������� �����.")
		 Else
			DebugPrnt ("�������� ����� ����� ���������!")
			AssocArrayAssign($CacheArray, "isfight", False)
		 EndIf
	  EndIf
	  
	  ;��������� ����� �� ������� �� �����
	  IF NOT IsFightTimeout() Then
		 PlayArena()
	  Else
		 local $ts = _TimeGetStamp()
		 $pausetime = @extended - $ts + 15
		 DebugPrnt ("Wait for timeout: " & $pausetime & " seconds...")
	  EndIf
	  
	  ;����������� ����� ����� ���������
	  Sleep (10000)
   WEnd

   Metro_destruct()
EndFunc

Func PlayArena()
   DebugPrnt ("Searching opponent...")
   local $c=1 ;������� ������� ������ ���������
   while $c < 50
	  local $opponent = Metro_OpenArena()	 ;������� �� �����, �������� ���� � ���������.
	  ;��� ����� �������� �� @error (1203)
	  DebugPrnt ("Oppenent #" & $c & ": " & $opponent[0] & ", " & $opponent[1] & ", " & $opponent[2])
	  If ($opponent[2]=1) or ($opponent[2]=0) Then ExitLoop
	  Sleep (1000)
	  $c += 1
   WEnd
   DebugPrnt ("Founded #" & $c & ": " & $opponent[0] & ", " & $opponent[1] & ", " & $opponent[2])
   
   local $fight = Metro_ArenaFight ($opponent[0])
   if @error<>0 then 
	  DebugPrnt ("error on Metro_ArenaFight: " & @error & " ex: " & @extended)
	  if @extended="1202" then 
		 DebugPrnt ("need timeout 5 min")
		 AssocArrayAssign($CacheArray, "arenatimer", _TimeGetStamp() + 300)
		 Return 0
	  EndIf
	  $runned = false
	  Return 0
   EndIf
   
   if $fight[0]=1 Then
	  DebugPrnt ("Fight with " & $opponent[1] & ": Win! +" & $fight[1] & " gold +" & $fight[2] & " exp." )
   Else
	  DebugPrnt ("Fight with " & $opponent[1] & ": Loose...")
   EndIf
   
   $fight = Metro_ArenaStop()
   if @error<>0 then 
	  DebugPrnt ("error on Metro_ArenaStop: " & @error & " ex: " & @extended)
	  Return 0
   EndIf
   
   if $fight[0]=1 Then DebugPrnt ("Current stats: " & $fight[0] & " gold, " & $fight[1] & " exp, " & $fight[2] & " win rating.")
EndFunc