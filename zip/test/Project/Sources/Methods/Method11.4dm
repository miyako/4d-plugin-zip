//%attributes = {}
C_TEXT:C284($src;$ZipFile)
C_LONGINT:C283($Ok)
ARRAY TEXT:C222($MonTab;2)
$MonTab{1}:=System folder:C487(Desktop:K41:16)+"木暮理太郎 白馬岳.pdf"
$MonTab{2}:=""

$ZipFile:=System folder:C487(Desktop:K41:16)+"木暮理太郎 白馬岳.zip"


$src:=JSON Stringify array:C1228($MonTab)

$Ok:=Zip ($src;$ZipFile;"";0)