function Get-FolderGrabCondition($folderName) {
    $ignoreItemName = ".nodoc"
    $IgnoreFolderDeafultList = ".\.git", ".\_site", ".\obj", ".\src"

    $notInListCondition = (-not $IgnoreFolderDeafultList.Contains($folderName))
    $doesntHaveNoDocFileCondition = (-not [System.IO.File]::Exists([System.IO.Path]::Combine($folderName, $ignoreItemName)))

    return $notInListCondition -and $doesntHaveNoDocFileCondition
}

function Get-SubDocFolders($Path) {
    $dirs = [System.IO.Directory]::GetDirectories($Path, "*", [System.IO.SearchOption]::AllDirectories)

    return $dirs | where { Get-FolderGrabCondition $_ }
}

function Get-RootDocFolder($Path){
    $dirs = [System.IO.Directory]::GetDirectories($Path, "*", [System.IO.SearchOption]::TopDirectoryOnly)

    return $dirs  | where { Get-FolderGrabCondition $_ }
}

function Get-YamlFrontMatter([string]$mdContent, [string]$mdpath) {
    $lines = $mdContent -Split [System.Environment]::NewLine
    if(($lines -and ($lines.Length -gt 0) -and ($lines[0] -eq "---"))) {
        $secondIndex = $lines[1..$lines.Length].IndexOf("---")
        Write-Host "Indexing '$mdpath'..."
        return [string]::Join([System.Environment]::NewLine, $lines[1..$secondIndex])
    } else {
        # Write-Host "Front-matter (Yaml meta-data) for '$mdpath' : NOT FOUND"
        return ""
    }
}

<#
function Get-ContentWithoutYamlFrontMatter([string]$mdContent) {
    $lines = $mdContent -Split [System.Environment]::NewLine
    if ($lines -and ($lines.Length -gt 0)) {
        if ($lines[0] -eq "---") {
            $secondIndex = $lines[1..$lines.Length].IndexOf("---")+1
            return [string]::Join([System.Environment]::NewLine, $lines[$secondIndex..$lines.Length])
        }
        else{
            return [string]::Join([System.Environment]::NewLine, $lines)
        }
    } else {
        return ""
    }
}
#>

function New-TocYaml($folder, $tocFolder){
    $mdFiles = [System.IO.Directory]::GetFiles($folder, "*.md", [System.IO.SearchOption]::TopDirectoryOnly)

    $topLevelTocItems = New-Object Collections.Generic.List[Object]

    $mdFiles | % {
        if([System.IO.Path]::GetFileName($_) -ne "index.md"){
            $tocItem = Get-MarkdownSingleTocItem $_ $tocfolder
            $topLevelTocItems.Add($tocItem)
        }
    }

    $subdocTopFolders = Get-RootDocFolder $folder
    $indexFiles = $subdocTopFolders | % { Join-Path $_ "index.md" } | where { [System.IO.File]::Exists($_) }

    $indexTocItems = New-Object Collections.Generic.List[Object]
    $indexFiles | % {
            $tocItem = Get-MarkdownSingleTocItem $_ $tocFolder
            $dirOfIndex = [System.IO.Path]::GetDirectoryName($_)

            if($tocItem.name -eq "Index"){
                $tocItem.name = Get-SanitizedName([System.IO.Path]::GetFileNameWithoutExtension($dirOfIndex))
            }

            $toc = New-TocYaml $dirOfIndex $tocFolder
            $items = $toc | Sort-Object -Property @{Expression={$_.order}; Descending=$false}, @{Expression={$_.name} ;Descending=$false}

            $items = @($items)

            if($null -ne $items -and $null -ne $tocItem -and $items.Length -gt 0){
                $tocItem.Add("items", @($items))
            }

            $indexTocItems.Add($tocItem)
    }

    $result = ($topLevelTocItems + $indexTocItems) | Sort-Object -Property order
    $result = @($result)
    return ([Collections.Generic.List[Object]]$result)
}

function Get-MarkdownSingleTocItem([string]$markdownPath, $tocFolder){
    $content = [System.IO.File]::ReadAllText($markdownPath)
    $frontMatter = Get-YamlFrontMatter $content $markdownPath
    # $contentWithoutFrontMatter = Get-ContentWithoutYamlFrontMatter $content
    # Write-Host $contentWithoutFrontMatter

    $yaml = $frontMatter | ConvertFrom-Yaml

    $noName = $null -eq $yaml.name -and $null -eq $yaml.title

    $relPath = [System.IO.Path]::GetRelativePath($tocFolder, $markdownPath)

    $name = $yaml.name # Try grabbing the name value
    if($null -eq $name){ # Try grabbing the title value
        $name = $yaml.title
    }
    if($null -eq $name){ # Generate a ToC name from the filename
        $fileNameNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($markdownPath) # Get filename without path
        $name = Get-SanitizedName($fileNameNoExtension)
    }

    $order = $yaml.order
    if($null -eq $order) { $order = 100 }
    $model = @{ "name" = $name; "order" = $order };
    if($yaml.href -ne $null) { $model.Add("href", $yaml.href) }

    # $isFileEmpty = [String]::IsNullOrWhiteSpace(($contentWithoutFrontMatter))
    $isFileEmpty = [String]::IsNullOrWhiteSpace((Get-content $markdownPath))

    if($yaml.nocontent -ne $true -and $model.href -eq $null -and ! $isFileEmpty) { $model.Add("href", $relPath) }
    return $model
}

function Get-SanitizedName($fileNameNoExtension) {
        $name = ($fileNameNoExtension.ToString() -creplace '(?<!^)([A-Z][a-z]|(?<=[a-z])[A-Z])', ' $&').Split($null) # Split on camel case
        $name = $name.replace('-',' ') # Change dashes to spaces
        $name = $name.replace('_',' ') # Change underscores to spaces
        $name = (Get-Culture).TextInfo.ToTitleCase($name) # Capitalize words
        return $name
}

function Build-TocHereRecursive {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]
        $Path=$PWD
    )
    foreach ($docFolder in Get-RootDocFolder $Path) {
        Write-Host "Starting to generate TOC for [$docFolder]"
        $raw = New-TocYaml $docFolder $docFolder
        $tocFile = ConvertTo-Yaml @($raw)
        $tocFile > (Join-Path $docFolder "toc.yml")
        Write-Host "Done generating TOC for [$docFolder]"
        Write-Host
    }
}

Export-ModuleMember -Function Build-TocHereRecursive
