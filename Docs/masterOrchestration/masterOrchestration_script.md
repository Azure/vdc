## Master Orchestration Script
The master orchestration script is located under the "Config" directory in the VDC toolkit repository.  
[Master Orchestration Script](../../Config/masterOrchestration.ps1)

This will be the script the deployment admin executes to run the full VDC orchestration

The deployment admin should only change one line in the script. In the picture below its line 3.
- This is the location of the input file. 

![](/images/inputFile_line_change.png)  
*Picture 1*

Once you have your input file complete and the environments you wish to deploy folders copied and configured. You can call the master script for the deployment.

In PowerShell 7 command prompt - navigate to the directory where the vdc toolkit is located. In the root directory 
- First you must login to Azure with an account that can access all the subscriptions you wish to deploy too
- Next you must call the masterOrchestration.ps1 file
	- **./config/masterOrchestration.ps1**
- Make sure the information is correct for the number of shared services and msvdi environments you wish to deploy
    - These numbers should align with the number of arrays under each object in the inputFile.json
	
![](/images/master_script_ex.png)  
*Picture 2*

- Next you will be prompted to enter the password information for each deployment 
	- VM Admin password
	- Domain Admin UserName
	- Domain Admin Password
- If you want random passwords for these variables please enter "random" for the prompt

Once you fill out all the secret information the first deployment will kick off. 
Deployment will go in the order below:
1. Hub1 - this is the master hub which everything is peered too
2. Hub2-X - These are optional spoke shared service environments
3. MSVDI1-X - These are spoke MSVDI environments. These are also optional
