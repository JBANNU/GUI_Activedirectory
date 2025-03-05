$SMail= "bharadwaj.juloori@dxc.com"

#below line for setting protocall
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$username1 = 'apikey'
		$password1 = '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'
		$securePassword = ConvertTo-SecureString $password1 -AsPlainText -Force
		$SmtpServer = 'smtp.sendgrid.net'
		$Port = 587
		$credential = New-Object System.Management.Automation.PSCredential($username1, $securePassword)

		$CurrentFolder = Split-Path -Parent $PSCommandPath
		$inputFilePath = "$CurrentFolder\add_user_to_existing_group.CSV"
		$delimiter = "`t"



		Get-Content $inputFilePath  | % {

		$inputLine = $_

		if(!$inputLine.ToString().StartsWith("#")) {

		        $inputData = $inputLine.ToString().Split($delimiter)
        		$SamAccountName = $inputData[0].Trim()
			$group = $inputData[1].Trim()
			$groups = $group.split(",")
	
			#-------- Bulk group addition to Bulk user---------------------

			if((Get-ADUser -Filter * | where SamAccountName -like $SamAccountName | Measure-Object).count -eq 1){
		      	foreach($groupdata in $groups)
 			{
				
				if((get-ADGroup -Filter * | where SamaccountName -like $groupdata |Measure-Object).count -eq 1){
				Add-ADGroupMember -identity $groupdata -Members $samaccountname
				write-Host "$samaccountname Added to $groupdata"
				add-Content -Path $CurrentFolder\output.txt -Value "$samaccountname Added to $groupdata"
				}
				else{
				write-Host "$groupdata not existed in AD"
				add-Content -Path $CurrentFolder\output.txt -Value "$groupdata not existed in AD"
			
		
				}
		
			}
			}
			else{
				write-Host "$samaccountname not existed in AD"
				add-Content -Path $CurrentFolder\output.txt -Value "$samaccountname not existed in AD"
			}
		
		}

	}
		#Send Notification
		$MSubject2 = "Notification mail"
		$MBody2 = "Attached users list for password reset "
		$Attachment="$CurrentFolder\output.txt"
        $NEmail="bharadwaj.juloori@dxc.com"
		Send-MailMessage -To $NEmail -From $SMail -Subject $MSubject2 -Body $MBody2 -Attachments $Attachment -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
		Write-Host "Notification sent to :" -nonewline; Write-Host $NEmail -ForegroundColor Green
		Clear-Content -Path "$CurrentFolder\output.txt"
