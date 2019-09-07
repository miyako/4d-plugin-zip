//%attributes = {}
  //$src:=Get 4D folder(Current resources folder)+Current method name+Folder separator
  //CREATE FOLDER($src;*)

  //METHOD GET CODE(Current method path;$code)
  //TEXT TO DOCUMENT($src+Current method name+".txt";$code;"utf-8")

$pass:="password"

$src:=System folder:C487(Applications or program files:K41:17)+"4D"+Folder separator:K24:12+"4D v17 R6"+Folder separator:K24:12+"4D.app"
$dst:=System folder:C487(Desktop:K41:16)+Current method name:C684+".zip"

$start:=Milliseconds:C459
$success:=Zip ($src;$dst;$pass;ZIP_Compression_level_2;ZIP_With_attributes)
$duration:=Milliseconds:C459-$start


$dst:=System folder:C487(Desktop:K41:16)+Current method name:C684+".7z"
$success:=Zip ($src;$dst;$pass;0;ZIP_7Z)