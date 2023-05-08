$sitemapUrl = Read-Host "Enter the sitemap URL to scrape"
$regexPattern = "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"
$logFile = "discovered-pages.txt"
$emailFile = "email-addresses.csv"

$response = Invoke-WebRequest $sitemapUrl -UseBasicParsing
$sitemap = [xml]$response.Content

$nsMgr = New-Object System.Xml.XmlNamespaceManager -ArgumentList $sitemap.NameTable
$nsMgr.AddNamespace("ns", "http://www.sitemaps.org/schemas/sitemap/0.9")
$pageUrls = $sitemap.SelectNodes("//ns:loc", $nsMgr) | Select-Object -ExpandProperty "#text"

Write-Output "Found $($pageUrls.Count) URLs in the sitemap."

$emails = @()

foreach($pageUrl in $pageUrls) {
    Write-Output "Processing $pageUrl..."
    $pageResponse = Invoke-WebRequest $pageUrl -UseBasicParsing
    $emailMatches = [regex]::Matches($pageResponse.Content, $regexPattern)
    
    foreach($emailMatch in $emailMatches) {
        Write-Output $emailMatch.Value
        $emails += $emailMatch
    }
    $emails | ConvertTo-Csv -NoTypeInformation | Out-File $emailFile


    Add-Content -Path $logFile -Value $pageUrl
}

Write-Output "All email addresses found have been exported to $emailFile."
