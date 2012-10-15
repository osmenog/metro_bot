#include <Debug.au3>
global $init_debug_session = False

Func _URIEncode($sData)
    ; Prog@ndy
    Local $aData = StringSplit(BinaryToString(StringToBinary($sData,4),1),"")
    Local $nChar
    $sData=""
    For $i = 1 To $aData[0]
        ; ConsoleWrite($aData[$i] & @CRLF)
        $nChar = Asc($aData[$i])
        Switch $nChar
            Case 44, 45, 46
                $sData &= "%" & Hex($nChar,2)
            Case 32
                $sData &= "+"
            Case Else
                
				$sData &= $aData[$i]
        EndSwitch
    Next
    Return $sData
EndFunc

Func _URIDecode($sData)
    ; Prog@ndy
    Local $aData = StringSplit(StringReplace($sData,"+"," ",0,1),"%")
    $sData = ""
    For $i = 2 To $aData[0]
        $aData[1] &= Chr(Dec(StringLeft($aData[$i],2))) & StringTrimLeft($aData[$i],2)
    Next
    Return BinaryToString(StringToBinary($aData[1],1),4)
EndFunc
 
Func Debug ($str,$caption='')
   ;Если функция вызывается впервые, то инициализируем отладочную сессию
   if $init_debug_session = False then 
	  _DebugSetup("Metro bot debug log", True, 4, "debug.log")
	  $init_debug_session = true
   EndIf
   
   If StringLen($str)=0 then Return
   Local $msg
   If $caption<>'' then 
	  $msg="[" & $caption & "] " & $str
   Else
	  $msg= $str
   EndIf
   _DebugOut ($msg)
EndFunc

Func LoadSettings()
   local $sf = @ScriptDir & "\settings.ini"
   If NOT FileExists ($sf) then 
	  _DebugOut ("Отсутствует файл settings.ini!")
	  Exit
   EndIf
   
   $sSession = IniRead($sf, "vk", "session","")
   $sViewer = IniRead($sf, "vk", "viewer_id","")
   $p_key = IniRead($sf, "vk", "auth_key","")
   
   _DebugOut ("Настройки успешно загружены!")
EndFunc

Func SaveCache(ByRef $text, $filename = "cache.txt")
   local $file = FileOpen($filename, 10) ; which is similar to 2 + 8 (erase + create dir)
   FileWrite ($file, $text)
   FileClose($file)
EndFunc

Func LoadFromCache ($filename)
   local $text = ""
   local $file = FileOpen($filename, 0) ; read mode
   While 1
	  Local $chars = FileRead($file,1)
	  $text &= $chars
	  If @error = -1 Then ExitLoop
   WEnd
   FileClose($file)
   return $text
EndFunc

Func _TimeGetStamp()
        Local $av_Time
        $av_Time = DllCall('CrtDll.dll', 'long:cdecl', 'time', 'ptr', 0)
        If @error Then
                SetError(99)
                Return False
        EndIf
        Return $av_Time[0]
	 EndFunc
	 
Func SaveStatistics ($iGold,$iXP)
   local $sf = @ScriptDir & "\settings.ini"
   
   If NOT FileExists ($sf) then 
	  _DebugOut ("Отсутствует файл settings.ini!")
	  Exit
   EndIf
   
   local $cur_gold = IniRead($sf, "stats", "gold", 0)
   local $cur_exp = IniRead($sf, "stats", "xp", 0)
   IniWrite ($sf, "stats", "gold", $cur_gold + $iGold)
   IniWrite ($sf, "stats", "xp", $cur_exp + $iXP)
EndFunc