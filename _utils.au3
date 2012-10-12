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
   ;���� ������� ���������� �������, �� �������������� ���������� ������
   if $init_debug_session = False then 
	  _DebugSetup("Metro bot debug log", True);, 2) ;����� ���������� � �������
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
	  _DebugOut ("����������� ���� settings.ini!")
	  Exit
   EndIf
   
   $sSession = IniRead($sf, "vk", "session","")
   $sViewer = IniRead($sf, "vk", "viewer_id","")
   $p_key = IniRead($sf, "vk", "auth_key","")
   
   _DebugOut ("��������� ������� ���������!")
EndFunc

Func SaveCache(ByRef $text)
   local $file = FileOpen("cache.tmp.txt", 10) ; which is similar to 2 + 8 (erase + create dir)
   FileWrite ($file, $text)
   FileClose($file)
EndFunc