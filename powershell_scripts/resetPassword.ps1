$SMail= "bharadwaj.juloori@dxc.com"
$NEmail = "bharadwaj.juloori@dxc.com"

#below line for setting protocall
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

		$CurrentFolder = Split-Path -Parent $PSCommandPath
		$inputFilePath = "$CurrentFolder\password_reset.csv"
		$delimiter = "`t"

	

		function Get-RandomCharacters($length, $characters) {
		    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
		    $private:ofs=""
		    return [String]$characters[$random]
		}
 	
		function Scramble-String([string]$inputString){     
		    $characterArray = $inputString.ToCharArray()   
		    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
		    $outputString = -join $scrambledStringArray
		    return $outputString 
		}

		$username1 = 'apikey'
		$password1 = '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'
		$securePassword = ConvertTo-SecureString $password1 -AsPlainText -Force
		$SmtpServer = 'smtp.sendgrid.net'
		$Port = 587
		$credential = New-Object System.Management.Automation.PSCredential($username1, $securePassword)

		Get-Content $inputFilePath  | % {

		    $inputLine = $_
	
		    if(!$inputLine.ToString().StartsWith("#")) {

		        $inputData = $inputLine.ToString().Split($delimiter)
		        $SamAccountName = $inputData[0].Trim()
        		$Email = Get-ADUser -Identity $SamAccountName -properties mail | Select -expandproperty mail

			$password = Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
			$password += Get-RandomCharacters -length 2 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
            		$password += Get-RandomCharacters -length 2 -characters '1234567890'
           	 	$password += Get-RandomCharacters -length 1 -characters '!"§$%&/()=?}][{@#*+'
           
           
          		$pass = ConvertTo-SecureString $password -AsPlainText -Force
	   		Set-ADAccountPassword $SamAccountName -NewPassword $pass -Reset
            		Write-Host "Reset the password for " -nonewline; Write-Host $SamAccountName -ForegroundColor Yellow -nonewline;Write-Host " and sent to Mail ID "  -nonewline;Write-Host $Email -ForegroundColor Green
          
			#copy output to file
			add-Content -Path $CurrentFolder\output.txt -Value "$SamAccountname $Email"	

			#send password
			$MSubject1 = "password"
        		$MBody1 ="$password"

			
	
             
			Send-MailMessage -To $Email -From $SMail -Subject $MSubject1 -Body $MBody1 -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
	    
       
		}
		}
		#Send Notification
		$MSubject2 = "Notification mail"
		$MBody2 = "Attached users list for password reset "
		$Attachment="$CurrentFolder\output.txt"
		Send-MailMessage -To $NEmail -From $SMail -Subject $MSubject2 -Body $MBody2 -Attachments $Attachment -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
		Write-Host "Notification sent to :" -nonewline; Write-Host $NEmail -ForegroundColor Green
		Clear-Content -Path "$CurrentFolder\output.txt"
