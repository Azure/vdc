$rootPath = Resolve-Path ".\";
$resultsFile = Join-Path $rootPath "Test-Pester.XML";
Invoke-Pester -OutputFile $resultsFile;