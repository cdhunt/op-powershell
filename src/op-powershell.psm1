$classFolder = Join-Path -Path $PSScriptRoot -ChildPath class
$publicFolder = Join-Path -Path $PSScriptRoot -ChildPath public
$CommandBuilderFile = Join-Path -Path $classFolder -ChildPath CommandBuilder.ps1
$OpCommandFile = Join-Path -Path $classFolder -ChildPath OpCommand.ps1

. $CommandBuilderFile
. $OpCommandFile

Get-ChildItem -Path $publicFolder | ForEach-Object {
    . $_.FullName
}