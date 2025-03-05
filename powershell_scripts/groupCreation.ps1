$SMail= "bharadwaj.juloori@dxc.com"
$NEmail = "bharadwaj.juloori@dxc.com"

#below line for setting protocall
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#!!the script works perfectly only when the ou is already present in AD
		#displaying the current domain

		$username1 = 'apikey'
		$password1 = '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'
		$securePassword = ConvertTo-SecureString $password1 -AsPlainText -Force
		$SmtpServer = 'smtp.sendgrid.net'
		$Port = 587
		$credential = New-Object System.Management.Automation.PSCredential($username1, $securePassword)

		$Domain=Get-ADDomain | select-object DistinguishedName
		Write-Host "you are in $Domain" -ForegroundColor green
	

		#importiong an csv file with required parameters
		$CurrentFolder = Split-Path -Parent $PSCommandPath
		$inputFilePath = "$CurrentFolder\group_creation.csv"
		$groups = Import-Csv -Path $inputfilePath


		#storing the required attributes
		foreach($group in $groups)
		{
			$group_values = @{

		      Name         = $group.name
		      Path          = $group.path
		      GroupScope    = $group.scope
		      GroupCategory = $group.category
		      Description   = $group.description
	
			}
		$g_name=$group_values.Name
		#Write-Host "$g_name"

		#checking for group creation, if already created throws an error
		try{
			 New-ADGroup @group_values
			 Write-Host "$g_name created..." -ForegroundColor green
			#copy output to file
			add-Content -Path $CurrentFolder\output.txt -Value "$g_name created"
		}

		catch [Microsoft.ActiveDirectory.Management.ADException]
		{
			Write-Host "$g_name" -ForegroundColor Yellow
    			Switch ($_.Exception.Message)
			{
			       "The specified group already exists" {Write-Host "group has already been created." -ForegroundColor red } 
        			default{Write-Host "Unhandled ADException: $_"}
				
				

			}
			#copy output to file
			add-Content -Path $CurrentFolder\output.txt -Value "$g_name group has already been created."
		}
	
		catch{
		Write-Error $_
		}

		}
	$MBody2 = "Attached User creation notification mail"
	$MSubject2 = "Notification mail"
	$Attachment="$CurrentFolder\output.txt"
	
	Send-MailMessage -To $NEmail -From $SMail -Subject $MSubject2 -Body $MBody2 -Attachments $Attachment -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
	Write-Host "Notification sent to :" -nonewline; Write-Host $NEmail -ForegroundColor Green
	Clear-Content -Path "$CurrentFolder\output.txt"					