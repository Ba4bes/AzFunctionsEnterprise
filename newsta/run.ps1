using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $Adjectives, $Nouns)

$Location = 'west europe'

$ResourceGroupName = $Request.Query.ResourceGroupName
if ([string]::isnullorempty($ResourceGroupName)) {
    $ResourceGroupName = $Request.Body.ResourceGroupName
}
if ([string]::isnullorempty($ResourceGroupName)) {
    $Body = "Please Provide a ResourceGroupName"
    $StatusCode = [HttpStatusCode]::BadRequest
}
else {

    # Write to the Azure Functions log stream.
    Write-Host "PowerShell HTTP trigger function processed a request."

    $AdjectivesArray = $Adjectives -Split '\r?\n'.Trim()
    $Nounsarray = $Nouns -Split '\r?\n'.Trim()
    Write-host " thing"
    do {
        # Select an Adjective and a noun
        $Adjective = Get-Random -InputObject $AdjectivesArray
        $AllowedLength = 24 - $Adjective.Length
        $WordsAllowed = $NounsArray | Where-Object { $_.length -le $AllowedLength }
        $Word = Get-Random -InputObject $WordsAllowed
        $Result = $Adjective + $Word
        Write-Host "result: $Result"
        #Check availability
        $Availability = Get-AzStorageAccountNameAvailability -Name $Result
    } while ($Availability.NameAvailable -eq $false)

    " $Result was available!"

    Write-Host "Creating ResourceGroup in case it doesn't exist"
    # New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force

    Write-Host "Creating Storage Account"

    Try {

        #  $SAResult = New-AzStorageAccount -Name $Result -ResourceGroupName $ResourceGroupName -Location $Location -SkuName Standard_LRS  -ErrorAction Stop
        Write-Host "StorageAccount created"
        $StatusCode = [HttpStatusCode]::OK
        $Body = "Your new Storage Account has been created: $Result"
    }
    Catch {
        $StatusCode = [HttpStatusCode]::BadRequest
        $Body = "ERROR, could not create storage account: $_"
    }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $StatusCode
        Body       = $Body
    })