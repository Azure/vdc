Class CustomScriptExecution {

    [object] Execute([string] $command, [object] $arguments) {

        # Derive the script type from the command being
        # passed
        $scriptType = `
            $this.GetScriptType($command);

        # Branch the execution based on the type of the script being
        # passed for execution.
        switch ($scriptType.ToLower()) {
            "powershell" {
                return `
                    $this.RunPowerShellScript($command, $arguments, $scriptType);
            }
            "bash" {
                return `
                    $this.RunBashScript($command, $arguments, $scriptType);
            }
            default {
                Throw "Invalid script type. Script type not supported."
            }
        }

        return $null;
    }

    hidden [array] GetScriptType([string] $command) {
        
        # This variable will hold the type and sub-type for 
        # a script
        $commandType = @();
        
        $powershellScriptPattern = "^(.*?)\.ps1";
        $bashScriptPattern = "^(.*?)\.sh";

        # Check if the command passed contains ".ps1" extension
        # files or PowerShelll Cmdlets
        if($command -match $powershellScriptPattern) {
            $type = "powershell";
            $subType = "script";
        }
        # Check if the command passed contains set of PowerShell 
        # commands
        elseif($this.IsPowerShellCmdletPresentInCommand($command)) {
            $type = "powershell";
            $subType = "command";
        }
        # Check if the command passed contains ".sh" extension
        # files.
        elseif($command -match $bashScriptPattern `
            -or $this.IsBashCommandPresentInCommand($command)) {
            $type = "bash";
            $subType = "";
        }
        # If none of the above conditions are met, throw an exception
        # for unsupported script type
        else {
            Throw "Unknown script passed. Script type not supported."
        }

        # Add type and subtype of the script
        $commandType += $type;
        $commandType += $subType;

        # Returned the script type
        return $commandType;
    }

    hidden [bool] IsPowerShellCmdletPresentInCommand([string] $command) {

        # Get the first word from the command string to 
        # determine if it's a PowerShell Script, because 
        # PowerShell scripts always start with a known Cmdlet.
        # For Example: Get-Content, ConvertFrom-Json and so on.
        $cmdlet = ($command -split ' ')[0];

        # Use Get-Command to check if the retrieved word is a 
        # valid PowerShell Cmdlet.
        $cmdlet = `
            Get-Command `
                -Name $cmdlet `
                -ErrorAction SilentlyContinue;
                
        if($null -ne $cmdlet `
            -and $cmdlet.CommandType -eq "Cmdlet") {
            return $true;
        }
        else {
            return $false;
        }
    }

    hidden [bool] IsBashCommandPresentInCommand([string] $command) {
        # Get the first work from the command string to 
        # determine if it's a Bash Script, because 
        # Bash scripts always start with a known command.
        # For Example: sh, echo and so on.
        $cmdlet = ($command -split ' ')[0];

        # Does the command exists?
        $outputFromCommandCheck = `
            bash -c "command -v $cmdlet";

        # If the command is a valid bash command, then a 
        # return value is expected. If not, no return value
        # is expected.
        if($null -ne $outputFromCommandCheck) {
            return $true;
        }
        else {
            return $false;
        }
    }

    hidden [object] RunPowerShellScript([string] $command, [object] $arguments, [array] $scriptType) {

        if($scriptType[1].ToLower() -eq "script") {

            # Get arguments to execute the PowerShell script
            $argumentsList = `
                $this.AddArgumentsForExecution(
                    $command, 
                    $scriptType[0].ToLower(), 
                    $arguments);

            # Pass the script file path and argumentsList to
            # execute the script
            return `
                $this.RunJob($null, $command, $argumentsList);
        }
        else {

            # Pass the set of commands to execute the script
            return `
                $this.RunJob($command, $null, $null);
        }
        
    }

    hidden [object] RunBashScript([string] $command, [object] $arguments, [array] $scriptType) {

        # Get arguments to execute the bash script
        $argumentsList = `
            $this.AddArgumentsForExecution(
                $command, 
                $scriptType[0].ToLower(), 
                $arguments);

        # Append the arguments to the end of the bash script
        $command = `
            ("bash -c '{0} {1}'" -F $command, [string]$argumentsList);
        
        # Return the formatted command
        return `
            $this.RunJob($command, $null, $null);
    }

    hidden [array] AddArgumentsForExecution([string] $command, 
                                            [string] $type, 
                                            [object] $arguments
                                            ){

        # Get arguments for the script execution
        if($type -eq "powershell") {
            # If type is powershell, we need the command to order the arguments
            # in the right order
            return `
                $this.GetArgumentsForPowerShellScript($command, $arguments);
        }
        elseif($type -eq "bash") {
            # If type is bash, we pass the arguments in the same order passed.
            # So we do not need the command to be passed.
            return `
                $this.GetArgumentsForBashScript($arguments);
        }
        else {
            # Return null if the type is not PowerShell script
            # or bash script
            return $null;
        }
    }

    hidden [array] GetArgumentsForBashScript([object] $arguments) {

        # Variable to hold the list of arguments to be
        # passed to the bash script execution
        $orderedArguments = @();
        Write-Host "[Pre] Value of args of bash script is $(ConvertTo-Json $orderedArguments -Depth 50)";

        # Add the arguments to the array as-is as 
        # there is no way to verify the order in bash.
        # We are only converting the hashtable to an 
        # array
        $arguments.PSObject.Properties | Select-Object -Property Name | ForEach-Object {
            $argumentName = $_.Name;
            Write-Host "Debug name - $argumentName";
            Write-Host "Debug value - $($arguments.$argumentName)";
            $orderedArguments += $arguments.$argumentName;
        }
        # Return the arguments list
        return $orderedArguments;
    }

    hidden [array] GetArgumentsForPowerShellScript([string] $command, [object] $arguments) {

        # List of system parameters we can pass to a 
        # PowerShell script by default
        $systemParameters = `
            @(
                'Verbose',
                'Debug',
                'ErrorAction',
                'WarningAction',
                'InformationAction',
                'ErrorVariable',
                'WarningVariable',
                'InformationVariable',
                'OutVariable',
                'OutBuffer',
                'PipelineVariable'
            );

        # Variable to hold the ordered list of arguments to 
        # be passed to the script execution
        $orderedArguments = @();

        # Iterate through the list of Parameters accepted by
        # a script to rearrange the in argument in the right order.
        (Get-Command $command -ErrorAction SilentlyContinue).Parameters.Keys | ForEach-Object {
            $parameterName = $_;

            # Add the argument to a new array in the right order if
            # it is passed from the orchestation. Otherwise, add a 
            # null in its place
            if($null -ne $parameterName `
                -and $arguments.$parameterName -ne $null `
                -and $parameterName -notin $systemParameters) {

                if($($arguments.$parameterName) -is [array]) {
                    $orderedArguments += , $arguments.$parameterName;
                }
                else {
                    $orderedArguments += $arguments.$parameterName;
                }
            }
            elseif($null -ne $parameterName `
                -and $parameterName -notin $systemParameters) {
                $orderedArguments += $null;
            }
        }

        # Return the ordered arguments list
        return $orderedArguments;
    }

    hidden [object] RunJob([string] $command, [string] $filePath, [array] $argumentsList) {
        
        # Variable to store the output from running a script
        $result = $null;
        try {
            $job = $null;
            # Job is a set of commands to be executed. ScriptBlock
            # allows to run a set of commands. ScriptBlock does not
            # run .ps1 files. We use this method to run a set of 
            # PowerShell Cmdlets or bash commands.
            if(![string]::IsNullOrEmpty($command)) {
                # Case 1 - Cannot use the Invoke-Comaand because of erroraction not honored
                # Case 2 - Parameters cannot be dynamically passed to be able to call ConvertFrom-Json
                # (for example). We do not support Cmdlet as part of ScriptBlock along with ArgumentsList
                $job = Start-Job -ScriptBlock {
                    param($scriptCommand)
                    $script = [scriptblock]::Create($scriptCommand);
                    . $script;
                } -ArgumentList $command;
            }
            # Job is a script file to be executed. FilePath is used
            # to run a PowerShell script and pass arguments. PowerShell
            # scripts can only be invoked through  FilePath argument to
            # Start-Job. 
            elseif(![string]::IsNullOrEmpty($filePath)) {
                $job = `
                    Start-Job `
                        -FilePath $filePath `
                        -ArgumentList $argumentsList;
            }

            # Did the job start successfully?
            if ($null -ne $job) {

                # Wait for the job to complete
                While($job.JobStateInfo.State -notin @("Completed","Failed","Blocked")) {
                    $job = Get-Job -Name $job.Name;
                    Write-Debug "Waiting for Script to finish ... ";
                    Start-Sleep -s 1;
                }

                if($job.JobStateInfo.State -eq "Completed") {                
                    # Child job contains the output from running the commands
                    # or script file. It is always only one child job in our 
                    # case since we start only one job.
                    Write-Host "Script Completed";
                    $childJob = (Get-Job -Name $job.Name).ChildJobs;

                    Write-Host "$(ConvertTo-Json $childJob)";

                    $childJob | ForEach-Object {
                        # Set the result only if there is an output
                        if($_.Output.Count -ge 1) {
                            # TODO: To verify
                            #$result = $_.Output | Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID,PSShowComputerName;
                            $result = (ConvertTo-Json $_.Output | ConvertFrom-Json -AsHashtable).value

                        }
                        else {
                            $result = $null;
                        }
                    };
                }
                else {
                    
                    # Script failed to execute, throw an exception
                    $exception = Receive-Job -Name $job.Name;
                    Write-Host "$(ConvertTo-Json $exception)";
                    Throw "Script failed to execute: $exception";
                }
            }
            # Return the latest output
            return $result;
        }
        catch {
            Write-Host "$(ConvertTo-Json $_)";
            Write-Error "An error occurred when running the script."
            Write-Error $_;
            Throw $_;
        }
    }

}