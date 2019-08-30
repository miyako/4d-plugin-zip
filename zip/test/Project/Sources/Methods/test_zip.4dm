//%attributes = {}
$src:=Get 4D folder:C485(Current resources folder:K5:16)+Current method name:C684+Folder separator:K24:12
CREATE FOLDER:C475($src;*)

METHOD GET CODE:C1190(Current method path:C1201;$code)
TEXT TO DOCUMENT:C1237($src+Current method name:C684+".txt";$code;"utf-8")

$pass:=""

$dst:=System folder:C487(Desktop:K41:16)+Current method name:C684+".zip"
$success:=Zip ($src;$dst;$pass;0;ZIP_With_attributes)

$dst:=System folder:C487(Desktop:K41:16)+Current method name:C684+".7z"
$success:=Zip ($src;$dst;$pass;0;ZIP_7Z)