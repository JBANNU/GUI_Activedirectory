$SMail= "bharadwaj.juloori@dxc.com"
$NEmail = "bharadwaj.juloori@dxc.com"

#below line for setting protocall

		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

		$CurrentFolder = Split-Path -Parent $PSCommandPath
		$inputFilePath ="$CurrentFolder\inputfile.csv"
		$delimiter = "`t"

		$length=(Get-Content $inputFilePath).Length
		$length=$length-1
		#$confirm= Read-Host "Please confirm to proceed with creating $length users(Y/N) "

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
        				$Name = $inputData[0].Trim()
        				$SamAccountName = $inputData[0][0]+$Name.ToString().Split(" ")[$Name.ToString().Split(" ").Length-1].Trim()
					#$SamAccountName = $inputData[1].Trim()
        				$Domain = $inputData[1].Trim()
        				$Description = $inputData[2].Trim() 			
        				$OuPath = $inputData[3].Trim()
       					$Email = $inputData[4].Trim()
					$group = $inputData[5].Trim()
					$groups = $group.split(",")
	

       					$AdUserParams = @{}
        				$Upn = "$SamAccountName@$Domain"
	
					$Verify_mail= Get-ADUser -Filter {EmailAddress -eq $Email} -properties EmailAddress



					if((Get-ADUser -Filter * | where SamAccountName -like $SamAccountName | Measure-Object).count -eq 0)
					{
						if(!($Verify_mail))
						{
							if((Get-ADUser -Filter * | where Name -like $Name | Measure-Object).count -eq 0)
							{
				
								$password = Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
            							$password += Get-RandomCharacters -length 2 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
            							$password += Get-RandomCharacters -length 2 -characters '1234567890'
            							$password += Get-RandomCharacters -length 1 -characters '!"�$%&/()=?}][{@#*+'

            
            							$AdUserParams.Add("Name",$Name)
            							$AdUserParams.Add("DisplayName",$Name)
            							$AdUserParams.Add("SamAccountName",$SamAccountName)
            							$AdUserParams.Add("UserPrincipalName",$Upn)
            							$AdUserParams.Add("Path",$OuPath) #-Path "OU=Managers,DC=enterprise,DC=com"
            							$AdUserParams.Add("Enabled",$true)
            							$AdUserParams.Add("Description",$Description)
            							$AdUserParams.Add("AccountPassword",(ConvertTo-SecureString $Password -AsPlainText -Force))
            							$AdUserParams.Add("ChangePasswordAtLogon",$false)
            							$AdUserParams.Add("PasswordNeverExpires",$false)


				            			If($Name.ToString() -like "* *")
            							{
                							$FirstName = $Name.ToString().Split(" ")[0].Trim()
                							$LastName = $Name.ToString().Split(" ")[$Name.ToString().Split(" ").Length-1].Trim()
                							$AdUserParams.Add("GivenName",$FirstName)
                							$AdUserParams.Add("SurName",$LastName)
            							}

            							if(![String]::IsNullOrEmpty($Email))
            							{
                							$AdUserParams.Add("EmailAddress",$Email)
            							}

				            			If($SamAccountName.Length -le 20)
            							{
                							New-AdUser @AdUserParams
            
            					    			if((Get-ADUser -Filter * | where SamAccountName -like $SamAccountName | Measure-Object).count -eq 1)
                							{
                    								 # Send username
        									$Msubject = "credentials"
       										$MBody ="Dear Sir/Madam,`n`nYour access in Test domain has been created, please find your TEST domain login details below:`n`nUsername: $SamAccountName`nPassword: <Will be sent in separate email>`n`n`nThank you`n Bharadwaj Juloori."
			
										#add content to txt file
										add-Content -Path Z:\final\output.txt -Value "$Name	$Samaccountname	$Email"

	
										#send password
										$MSubject1 = "password for $Username"
       										$MBody1 ="$password"

						       			        #Send Notification
										$MSubject2 = "Account creation progress"
			
				
	
										#sending mails
					
             									Send-MailMessage -To $Email -From $SMail -Subject $Msubject -Body $MBody -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
	    									Send-MailMessage -To $Email -From $SMail -Subject $MSubject1 -Body $MBody1 -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
										#Send-MailMessage -To $NEmail -From $SMail -Subject $MSubject2 -Body $MBody2 -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
	    									Write-Host $SamAccountname -nonewline -ForegroundColor yellow; Write-Host " has been created and shared credentials with " -nonewline; Write-Host $Email -ForegroundColor Green
										#Write-Host "Account Progress sent to :" -nonewline; Write-Host $NEmail -ForegroundColor Green

	
										#-------- group addition ---------------------
	
      										foreach($groupdata in $groups)
 										{
											Add-ADGroupMember -identity $groupdata -Members $SamAccountName
		
										}
		
                							}
                							else
                							{
                    								Write-Host "$samaccountname`tCreation failed" -ForegroundColor Yellow
										add-Content -Path Z:\final\output.txt -Value "$samaccountname`tCreation failed"
                							}
            							}
            							else
            							{
                			
                							Write-Host "$samaccountname`tCreation failed - name must be 20 characters or less" -ForegroundColor Yellow
									add-Content -Path Z:\final\output.txt -Value "$samaccountname`tCreation failed - name must be 20 characters or less"
            							}
							}
							else
							{
								#--------------update USN then create--------------------------
					
				
								$Username = $Name
								$count=1
								while(get-ADUser -Filter "Name -eq '$Username'"){
									$Username = '{0}{1}' -f $Name, $count++
								}
				
		
								$Name = $Username
				

								$password = Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
            							$password += Get-RandomCharacters -length 2 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
            							$password += Get-RandomCharacters -length 2 -characters '1234567890'
            							$password += Get-RandomCharacters -length 1 -characters '!"�$%&/()=?}][{@#*+'

            
				            			$AdUserParams.Add("Name",$Name)
            							$AdUserParams.Add("DisplayName",$Name)
            							$AdUserParams.Add("SamAccountName",$SamAccountName)
            							$AdUserParams.Add("UserPrincipalName",$Upn)
			        	    			$AdUserParams.Add("Path",$OuPath) #-Path "OU=Managers,DC=enterprise,DC=com"
            							$AdUserParams.Add("Enabled",$true)
            							$AdUserParams.Add("Description",$Description)
            							$AdUserParams.Add("AccountPassword",(ConvertTo-SecureString $Password -AsPlainText -Force))
            							$AdUserParams.Add("ChangePasswordAtLogon",$false)
            							$AdUserParams.Add("PasswordNeverExpires",$false)


				            			If($Name.ToString() -like "* *")
            							{
                							$FirstName = $Name.ToString().Split(" ")[0].Trim()
                							$LastName = $Name.ToString().Split(" ")[$Name.ToString().Split(" ").Length-1].Trim()
                							$AdUserParams.Add("GivenName",$FirstName)
                							$AdUserParams.Add("SurName",$LastName)
            							}
		
            							if(![String]::IsNullOrEmpty($Email))
            							{
                							$AdUserParams.Add("EmailAddress",$Email)
            							}

				            			If($SamAccountName.Length -le 20)
            							{
                							New-AdUser @AdUserParams
            
            					    			if((Get-ADUser -Filter * | where SamAccountName -like $SamAccountName | Measure-Object).count -eq 1)
                							{
                    				
                    								 # Send username
        									$Msubject = "credentials"
       										$MBody ="Dear Sir/Madam,`n`nYour access in Test domain has been created, please find your TEST domain login details below:`n`nUsername: $SamAccountName`nPassword: <Will be sent in separate email>`n`n`nThank you`n Bharadwaj Juloori."
						
										#Add to txt file
										add-Content -Path Z:\final\output.txt -Value "$Name	$Samaccountname	$Email"


										#send password
										$MSubject1 = "password for $Username"
       										$MBody1 ="$password"

						       			        #Send Notification
										$MSubject2 = "Account creation progress"
			
				

										#sending mails
						
             									Send-MailMessage -To $Email -From $SMail -Subject $Msubject -Body $MBody -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
	    									Send-MailMessage -To $Email -From $SMail -Subject $MSubject1 -Body $MBody1 -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
										#Send-MailMessage -To $NEmail -From $SMail -Subject $MSubject2 -Body $MBody2 -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
	    									Write-Host $SamAccountname -nonewline -ForegroundColor yellow; Write-Host " has been created and shared credentials with " -nonewline; Write-Host $Email -ForegroundColor Green
										#Write-Host "Account Progress sent to :" -nonewline; Write-Host $NEmail -ForegroundColor Green

	
										#-------- group addition ---------------------

				      						foreach($groupdata in $groups)
 										{
											Add-ADGroupMember -identity $groupdata -Members $SamAccountName
				
										}
                							}
                							else
                							{
                    								Write-Host "$samaccountname`tCreation failed" -ForegroundColor Yellow
										add-Content -Path Z:\final\output.txt -Value "$samaccountname`tCreation failed"
                							}
            							}
            							else
            							{
                							Write-Host "$samaccountname`tCreation failed - name must be 20 characters or less" -ForegroundColor Yellow
									add-Content -Path Z:\final\output.txt -Value "$samaccountname`tCreation failed - name must be 20 characters or less"
            							}
			
							}
						}	
						else
						{
							 #-------- group addition ---------------------

				
							if((Get-ADUser -Filter * | where SamAccountName -like $SamAccountName | Measure-Object).count -eq 1){
							foreach($groupdata in $groups)
							{
								Add-ADGroupMember -identity $groupdata -Members $SamAccountName
							}
						}
						
						Write-Host "Account already existed with $Email" -ForegroundColor yellow
						add-Content -Path Z:\final\output.txt -Value "Account already existed with $Email"         
				
						#Send Notification
						$MSubject2 = "Notification mail"
					}

				}
		
	
				elseif((Get-ADUser -Filter * | where SamAccountName -like $SamAccountName | Measure-Object).count -gt 0)
				{
					if(!($Verify_mail))
					{
	
						if((Get-ADUser -Filter * | where Name -like $Name | Measure-Object).count -eq 0)
						{
							#------------------update SAA and create-----------------------
							$SAA = $Samaccountname
							$count=1
							while(get-ADUser -Filter "Samaccountname -eq '$SAA'"){
									$SAA = '{0}{1}' -f $Samaccountname, $count++
							}
						$Samaccountname = $SAA

						$Upn = "$SamAccountName@$Domain"
						$password = Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
            					$password += Get-RandomCharacters -length 2 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
            					$password += Get-RandomCharacters -length 2 -characters '1234567890'
            					$password += Get-RandomCharacters -length 1 -characters '!"�$%&/()=?}][{@#*+'

            
		            			$AdUserParams.Add("Name",$Name)
            					$AdUserParams.Add("DisplayName",$Name)
            					$AdUserParams.Add("SamAccountName",$SamAccountName)
            					$AdUserParams.Add("UserPrincipalName",$Upn)
            					$AdUserParams.Add("Path",$OuPath) #-Path "OU=Managers,DC=enterprise,DC=com"
            					$AdUserParams.Add("Enabled",$true)
            					$AdUserParams.Add("Description",$Description)
            					$AdUserParams.Add("AccountPassword",(ConvertTo-SecureString $Password -AsPlainText -Force))
            					$AdUserParams.Add("ChangePasswordAtLogon",$false)
            					$AdUserParams.Add("PasswordNeverExpires",$false)


		            			If($Name.ToString() -like "* *")
            					{
                					$FirstName = $Name.ToString().Split(" ")[0].Trim()
                					$LastName = $Name.ToString().Split(" ")[$Name.ToString().Split(" ").Length-1].Trim()
                					$AdUserParams.Add("GivenName",$FirstName)
                					$AdUserParams.Add("SurName",$LastName)
            					}

		            			if(![String]::IsNullOrEmpty($Email))
        		    			{
                					$AdUserParams.Add("EmailAddress",$Email)
            					}

		            			If($SamAccountName.Length -le 20)
            					{
                					New-AdUser @AdUserParams
            
                					if((Get-ADUser -Filter * | where SamAccountName -like $SamAccountName | Measure-Object).count -eq 1)
                					{
                    						 # Send username
        							$Msubject = "credentials"
       								$MBody ="Dear Sir/Madam,`n`nYour access in Test domain has been created, please find your TEST domain login details below:`n`nUsername: $SamAccountName`nPassword: <Will be sent in separate email>`n`n`nThank you `n Bharadwaj Juloori."
						
								#Add to txt file
								add-Content -Path Z:\final\output.txt -Value "$Name	$Samaccountname	$Email"


								#send password
								$MSubject1 = "password for $Username"
       								$MBody1 ="$password"
		
		       					        #Send Notification
								$MSubject2 = "Account creation progress"
			
				

								#sending mails
			
             							Send-MailMessage -To $Email -From $SMail -Subject $Msubject -Body $MBody -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
	    							Send-MailMessage -To $Email -From $SMail -Subject $MSubject1 -Body $MBody1 -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
								#Send-MailMessage -To $NEmail -From $SMail -Subject $MSubject2 -Body $MBody2 -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
	    							Write-Host $SamAccountname -nonewline -ForegroundColor yellow; Write-Host " has been created and shared credentials with " -nonewline; Write-Host $Email -ForegroundColor Green
								#Write-Host "Account Progress sent to :" -nonewline; Write-Host $NEmail -ForegroundColor Green

	
								#-------- group addition ---------------------
	
      								foreach($groupdata in $groups)
 								{
									Add-ADGroupMember -identity $groupdata -Members $SamAccountName
		
								}
						
                					}
                					else
                					{
                    				
                    						Write-Host "$samaccountname`tCreation failed" -ForegroundColor Yellow
								add-Content -Path Z:\final\output.txt -Value "$samaccountname`tCreation failed"
                			
                					}
            					}
            					else
            					{
                					Write-Host "$samaccountname`tCreation failed - name must be 20 characters or less" -ForegroundColor Yellow
							add-Content -Path Z:\final\output.txt -Value "$samaccountname`tCreation failed - name must be 20 characters or less"
            			
            					}

			

					}
					else
					{
				
						#-------------------------------------Update USN and SAA------------------------------------
						$Username = $Name
						$count=1
						while(get-ADUser -Filter "Name -eq '$Username'"){
							$Username = '{0}{1}' -f $Name, $count++
						}
				
		
						$Name = $Username
		
						$SAA = $Samaccountname
						$count=1
						while(get-ADUser -Filter "Samaccountname -eq '$SAA'"){
							$SAA = '{0}{1}' -f $Samaccountname, $count++
						}
						$Samaccountname = $SAA

						$Upn = "$SamAccountName@$Domain"
						$password = Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
            					$password += Get-RandomCharacters -length 2 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
            					$password += Get-RandomCharacters -length 2 -characters '1234567890'
            					$password += Get-RandomCharacters -length 1 -characters '!"�$%&/()=?}][{@#*+'

	            
        		    			$AdUserParams.Add("Name",$Name)
            					$AdUserParams.Add("DisplayName",$Name)
            					$AdUserParams.Add("SamAccountName",$SamAccountName)
            					$AdUserParams.Add("UserPrincipalName",$Upn)
            					$AdUserParams.Add("Path",$OuPath) #-Path "OU=Managers,DC=enterprise,DC=com"
            					$AdUserParams.Add("Enabled",$true)
            					$AdUserParams.Add("Description",$Description)
            					$AdUserParams.Add("AccountPassword",(ConvertTo-SecureString $Password -AsPlainText -Force))
            					$AdUserParams.Add("ChangePasswordAtLogon",$false)
            					$AdUserParams.Add("PasswordNeverExpires",$false)

	
        		    			If($Name.ToString() -like "* *")
            					{
                					$FirstName = $Name.ToString().Split(" ")[0].Trim()
                					$LastName = $Name.ToString().Split(" ")[$Name.ToString().Split(" ").Length-1].Trim()
                					$AdUserParams.Add("GivenName",$FirstName)
                					$AdUserParams.Add("SurName",$LastName)
            					}

		            			if(![String]::IsNullOrEmpty($Email))
        		    			{
                					$AdUserParams.Add("EmailAddress",$Email)
            					}

		            			If($SamAccountName.Length -le 20)
            					{
                                    Write-Host "AdUserParams: $($AdUserParams | Out-String)"
                					New-AdUser @AdUserParams
            
            			    			if((Get-ADUser -Filter * | where SamAccountName -like $SamAccountName | Measure-Object).count -eq 1)
                					{
                    						 # Send username
        							$Msubject = "credentials"
       								$MBody ="Dear Sir/Madam,`n`nYour access in Test domain has been created, please find your TEST domain login details below:`n`nUsername: $SamAccountName`nPassword: <Will be sent in separate email>`n`n`nThank you `n Bharadwaj Juloori."
						
								#Add to txt file
								add-Content -Path Z:\final\output.txt -Value "$Name	$Samaccountname	$Email"

	
								#send password
								$MSubject1 = "password for $Username"
       								$MBody1 ="$password"

				       			        #Send Notification
								$MSubject2 = "Account creation progress"
			
				

								#sending mails
			
             							Send-MailMessage -To $Email -From $SMail -Subject $Msubject -Body $MBody -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
	    							Send-MailMessage -To $Email -From $SMail -Subject $MSubject1 -Body $MBody1 -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
								#Send-MailMessage -To $NEmail -From $SMail -Subject $MSubject2 -Body $MBody2 -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
	    							Write-Host $SamAccountname -nonewline -ForegroundColor yellow; Write-Host " has been created and shared credentials with " -nonewline; Write-Host $Email -ForegroundColor Green
								#Write-Host "Account Progress sent to :" -nonewline; Write-Host $NEmail -ForegroundColor Green

		
								#-------- group addition ---------------------
		
      								foreach($groupdata in $groups)
 								{
									Add-ADGroupMember -identity $groupdata -Members $SamAccountName
		
								}
                					}
                					else
                					{
                    						Write-Host "$samaccountname`tCreation failed" -ForegroundColor Yellow
								add-Content -Path Z:\final\output.txt -Value "$samaccountname`tCreation failed"
                				
                					}
            					}
            					else
            					{
                					Write-Host "$samaccountname`tCreation failed - name must be 20 characters or less" -ForegroundColor Yellow
							add-Content -Path Z:\final\output.txt -Value "$samaccountname`tCreation failed - name must be 20 characters or less"
            			
            					}

				 
					}
				}
				else
				{
			
				 	#-------- group addition ---------------------

				
					if((Get-ADUser -Filter * | where SamAccountName -like $SamAccountName | Measure-Object).count -eq 1){
						foreach($groupdata in $groups)
						{
							Add-ADGroupMember -identity $groupdata -Members $SamAccountName
						}
					}
						
					Write-Host "Account already existed with $Email" -ForegroundColor yellow
					add-Content -Path Z:\final\output.txt -Value "Account already existed with $Email"         
				
					#Send Notification
					$MSubject2 = "Notification mail"
				}	
			}
		}
	}

	$MBody2 = "Attached User creation notification mail"
	$Attachment="Z:\final\output.txt"
	Send-MailMessage -To $NEmail -From $SMail -Subject $MSubject2 -Body $MBody2 -Attachments $Attachment -Credential $Credential -SmtpServer $SmtpServer -Port $Port -UseSsl
	Write-Host "Notification sent to :" -nonewline; Write-Host $NEmail -ForegroundColor Green
	Clear-Content -Path "Z:\final\output.txt"		
	