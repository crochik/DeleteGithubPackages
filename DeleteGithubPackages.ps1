param (
    [Parameter(Mandatory = $true)] $Config,
    [switch] $SkipConfirmation
)

if (![System.IO.File]::Exists($Config)) { 
    Write-Host "Config file not found:"$Config
    exit 1
}

$config = Get-Content -Raw -Path $Config | ConvertFrom-Json
$token = $config.token
$owner = $config.owner
$project = $config.project
$packagename = $config.package
$olderthan = [string]$config.olderthan -as [DateTime]

$today = Get-Date
if ($olderthan -gt $today) {
    Write-Host "Older than date should be in the past:"$olderthan
    exit 2
}

$headers = @{
    Accept        = "application/vnd.github.package-deletes-preview+json";
    Authorization = "bearer $token" 
}

function GetPackages {
    $body = '{"query":"query {repository(owner:\"' + $owner + '\", name:\"' + $project + '\") {registryPackages(last:20) {edges{node{id, name, versions(last:20){nodes {id,platform,updatedAt,version}}}}}}}"}'
    $response = Invoke-WebRequest -Uri https://api.github.com/graphql -Method POST -Headers $headers -Body $body
    $json = $response | ConvertFrom-Json
    return $json;    
}

function DeletePackageVersion {
    param($id)
    Write-Host "Delete Package Version Id:"$id
    $body = '{"query":"mutation { deletePackageVersion(input:{packageVersionId:\"' + $id + '\"}) { success }}"}'
    Write-Host $body
    $response = Invoke-WebRequest -Uri https://api.github.com/graphql -Method POST -Headers $headers -Body $body
    $json = $response | ConvertFrom-Json
    if ( $json.data.deletePackageVersion.success -ne $true) {
        Write-Error $response
    }
    
    return $json.data.deletePackageVersion.success;
}

if ($SkipConfirmation -ne $true) {
    Write-Host "Delete Packages from $owner/$project/$packagename older than $olderthan ?"
    $confirm = Read-Host -Prompt "> Type Yes to continue" 
    if ($confirm -ne 'Yes') {
        Write-Host 'Aborting...'
        exit 3
    }
}
else {
    Write-Host "Deleting Packages from $owner/$project older than $olderthan in 5 seconds..."
    Start-Sleep -Seconds 5
}

$modified = $true
while ($modified) {
    $modified = $false
    $json = GetPackages

    Write-Host "============================================================="
    foreach ($edge in $json.data.repository.registryPackages.edges) {
        $package = $edge.node
        Write-Host "Package:"$package.name

        if ( $package.name -ne $packagename ) {
            continue
        }

        $list = $package.versions.nodes | Sort-Object -Property updatedAt
        ForEach ($version in $list) {
            if ( $version.updatedAt -gt $olderthan) {
                Write-Host ">> no more old packages"
                break;
            }
            if ($version.version -eq 'docker-base-layer') {
                Write-Host " - (SKIP)"$version.version
                continue;
            }

            Write-Host " - "$version.version
            $deleted = DeletePackageVersion $version.id
            if (!$deleted) {
                Write-Host ">> Error"
                break;
            }
            $modified = $true
        }
    }
} 

Write-Host "============================================================="
exit $LASTEXITCODE