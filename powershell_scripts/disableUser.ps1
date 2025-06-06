$SMail= "bharadwaj.juloori@dxc.com"
$NEmail = "bharadwaj.juloori@dxc.com"

#below line for setting protocall
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		$CurrentFolder = Split-Path -Parent $PSCommandPath

		$username1 = 'apikey'
		$password1 = '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'
		$securePassword = ConvertTo-SecureString $password1 -AsPlainText -Force
		$SmtpServer = 'smtp.sendgrid.net'
		$Port = 587
		$credential = New-Object System.Management.Automation.PSCredential($username1, $securePassword)




		$Users=Get-Content $CurrentFolder\disable_list.txt

		ForEach($user in $users)
		{
			if((Get-ADUser -Filter * | where SamAccountName -like $user | Measure-Object).count -eq 1){

			Disable-ADAccount -Identity $user
			$date = Get-Date -UFormat "%m/%d/%Y"
			$user | Set-ADUser -Description $date
			#Get-ADUser -identity $user | set-ADObject -Replace primarygroupID="Terminated_user"
			Get-ADUser -Identity $user -Properties Memberof | ForEach-Object {$_.Memberof | Remove-ADGroupMember -Members $User -Confirm:$false}
			get-ADuser -Identity $user |move-ADObject -TargetPath "OU=Disabled, DC=UAMTest, DC=com"

			Write-Host "Disabled the user account " -nonewline; Write-Host $user -ForegroundColor Green

			#copy output to file
			add-Content -Path $CurrentFolder\output.txt -Value "$user"	
			}
			else
			{
			Write-Host $user -nonewline; Write-Host " - Account not existed in AD"
			#copy output to file
			add-Content -Path $CurrentFolder\output.txt -Value "$user not existed in AD"
			}
	
		}
		#Send Notification
		$MSubject2 = "Notification mail"
		$MBody2 = "Disabled users"
		$Attachment="$CurrentFolder\output.txt"
		Send-MailMessage -To $NEmail -From $SMail -Subject $MSubject2 -Body $MBody2 -Attachments $Attachment -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
		Write-Host "Notification sent to :" -nonewline; Write-Host $NEmail -ForegroundColor Green
		Clear-Content -Path "$CurrentFolder\output.txt"
