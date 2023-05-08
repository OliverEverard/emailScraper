function ProcessSitemap($sitemapUrl) {
    $regexPattern = "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"
    $logFile = "discovered-pages.txt"
    $emailFile = "email-addresses.csv"

    $response = Invoke-WebRequest $sitemapUrl -UseBasicParsing
    $sitemap = [xml]$response.Content

    $nsMgr = New-Object System.Xml.XmlNamespaceManager -ArgumentList $sitemap.NameTable
    $nsMgr.AddNamespace("ns", "http://www.sitemaps.org/schemas/sitemap/0.9")
    $pageUrls = $sitemap.SelectNodes("//ns:loc", $nsMgr) | Select-Object -ExpandProperty "#text"

    Write-Output "Found $($pageUrls.Count) URLs in the sitemap."

    $emailHash = @{}

    foreach($pageUrl in $pageUrls) {
        if($pageUrl.EndsWith(".xml")) {
            if([Uri]::IsWellFormedUriString($pageUrl, [UriKind]::Absolute)) {
                Write-Output "Processing absolute nested sitemap $pageUrl..."
                ProcessSitemap($pageUrl)
            }
            else {
                $nestedSitemapUrl = [System.Uri]::new([System.Uri]::new($sitemapUrl), $pageUrl).AbsoluteUri
                Write-Output "Processing relative nested sitemap $nestedSitemapUrl..."
                ProcessSitemap($nestedSitemapUrl)
            }
        }
        else {
            Write-Output "Processing page $pageUrl..."
            $pageResponse = Invoke-WebRequest $pageUrl -UseBasicParsing
            $emailMatches = [regex]::Matches($pageResponse.Content, $regexPattern)
    
            foreach($emailMatch in $emailMatches) {
                $email = $emailMatch.Value.Trim()
                if(-not $emailHash.ContainsKey($email)) {
                    Write-Output $email
                    $emailHash.Add($email, $true)
                }
            }

            Add-Content -Path $logFile -Value $pageUrl
        }
    }

    $emailArray = $emailHash.Keys | Select-Object @{Name='Email';Expression={$_}}
    $emailArray | Export-Csv $emailFile -NoTypeInformation -Append

    Write-Output "All unique email addresses found have been exported to $emailFile."
}

$sitemapUrl = Read-Host "Enter the sitemap URL to scrape"
ProcessSitemap($sitemapUrl)
