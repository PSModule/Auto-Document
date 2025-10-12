#REQUIRES -Modules powershell-yaml, MarkdownPS

[CmdletBinding()]
param(
    [Parameter()]
    [string] $Path
)

function Get-ActionFile {
    <#
    .SYNOPSIS
        Get the path to the action.yml or action.yaml file in the current directory.
    #>

    [CmdletBinding()]
    param()

    if (Test-Path -Path '.\action.yml') {
        $actionFile = Get-Item -Path '.\action.yml'
    } elseif (Test-Path -Path '.\action.yaml') {
        $actionFile = Get-Item -Path '.\action.yaml'
    } else {
        Write-Verbose 'No action file found in the current directory.'
    }

    $actionFile
}

if ($Path) {
    if (-not (Test-Path -Path $Path)) {
        Write-Error "The path [$Path] does not exist."
    }
} else {
    $Path = Get-ActionPath
}

$action = ConvertFrom-Yaml -Yaml (Get-Content -Path $Path -Raw)
# $action = ConvertFrom-Yaml -Yaml (Get-Content -Path 'C:\Repos\GitHub\PSModule\Action\Auto-Release\action.yml' -Raw)

if ($action.name) {
    $title = New-MDHeader -Text $action.name -Level 1
}

if ($action.description) {
    $description = New-MDParagraph -Lines $action.description
}

if ($action.inputs) {
    $inputs = $action.inputs.GetEnumerator() | ForEach-Object {
        $name = $_.Key
        $description = $_.Value.description
        $required = $_.Value.required
        $default = $_.Value.default
        $deprecationMessage = $_.Value.deprecationMessage
        [PSCustomObject]@{
            Name               = $name
            Description        = $description.Replace("`n", ' ').Replace("`r", ' ').Replace('  ', ' ').Trim()
            Required           = $required ? 'Yes' : 'No'
            Default            = $default ? 'Yes' : 'No'
            DeprecationMessage = $deprecationMessage
        }
    }

    $inputsContent = New-MDHeader -Text 'Inputs' -Level 2
    $inputsContent += $inputs | New-MDTable -Shrink
}

if ($action.outputs) {
    $outputs = $action.outputs.GetEnumerator() | ForEach-Object {
        $name = $_.Key
        $description = $_.Value.description
        [PSCustomObject]@{
            Name        = $name
            Description = $description.Replace("`n", ' ').Replace("`r", ' ').Replace('  ', ' ').Trim()
        }
    }

    $outputsContent = New-MDHeader -Text 'Outputs' -Level 2
    $outputsContent += $outputs | New-MDTable -Shrink
}

$readmeContent = @"
$title
$description
$inputsContent
$outputsContent
$examplesContent
"@

$readmeContent | Out-File -FilePath 'C:\Repos\GitHub\PSModule\Action\Auto-Release\README.md' -Force
