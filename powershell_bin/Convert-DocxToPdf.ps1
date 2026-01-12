param(
    [ValidateScript({
                        if(-Not ($_ | Test-Path) ){
                            throw "File does not exist"
                        }
                        if(-Not ($_ | Test-Path -PathType Leaf) ){
                            throw "The Path argument must be a file. Folder paths are not allowed."
                        }
                        if($_ -notmatch "(\.doc.*)"){
                            throw "The file specified in the path argument must be of type docx"
                        }
                        return $true
                    })]
    [System.IO.FileInfo]
    $DocumentPath,
    [ValidateScript({
                        if(-Not ($_ | Test-Path) ){
                            throw "Folder does not exist"
                        }
                        if(($_ | Test-Path -PathType Leaf) ){
                            throw "The Path argument must be a folder. File paths are not allowed."
                        }
                        return $true
                    })]
    [System.IO.FileInfo]
    $OutputDir
)

function Resolve-Error ($ErrorRecord=$Error[0])
{
   $ErrorRecord | Format-List * -Force
   $ErrorRecord.InvocationInfo |Format-List *
   $Exception = $ErrorRecord.Exception
   for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
   {   "$i" * 80
       $Exception |Format-List * -Force
   }
}

$pdf_path = $OutputDir.FullName
$word_app = New-Object -ComObject Word.Application


try {
    $document = $word_app.Documents.Open($DocumentPath.FullName)
    $pdf_filename = "$($([System.IO.FileInfo]$DocumentPath).BaseName).pdf"
    $pdf_path = $pdf_path + "\" + $pdf_filename
    # write-host $pdf_path
    $document.SaveAs([ref] $pdf_path, [ref] 17)
    $document.Close()
}
catch {
    # write-host $_.Exception.Message
    Resolve-Error
}
finally {
    $word_app.Quit()
}



