  #Import SharePoint Online module
  Import-Module Microsoft.Online.SharePoint.Powershell
         
  Function Restore-PreviousVersion()
  {
    param
      (
          [Parameter(Mandatory=$true)] [string] $SiteURL,
          [Parameter(Mandatory=$true)] [string] $ListName
      )
     Try 
     {
          $Cred= Get-Credential
          $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
         
          #Setup the context
          $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
          $Ctx.Credentials = $Credentials
                 
          $List = $Ctx.Web.Lists.GetByTitle($ListName)
          $Ctx.Load($List)
          $ctx.ExecuteQuery()
    
              #Define Query to get List Items in batch
          $Query = New-Object Microsoft.SharePoint.Client.CamlQuery
          $Query.ViewXml = @"
          <View Scope='RecursiveAll'>
             <Query>
                 <OrderBy><FieldRef Name='ID' Ascending='TRUE'/></OrderBy>
             </Query>
             <RowLimit Paged="TRUE">2000</RowLimit>
         </View>
 "@
             #Get List Items in Batch
     Do
     {
         $ListItems = $List.GetItems($Query)
         $Ctx.Load($ListItems)
         $Ctx.ExecuteQuery()
         $ListItems.count
         $Query.ListItemCollectionPosition = $ListItems.ListItemCollectionPosition
                  #Iterate through each item and restore the previous version
         Foreach($Item in $ListItems)
         { 
             #Get the file versions
             $File = $Ctx.Web.GetFileByServerRelativeUrl($Item["FileRef"])
             $Ctx.Load($File)
             $Ctx.Load($File.Versions)
             $Ctx.ExecuteQuery()
         
             If($File.Versions.Count -gt 0)
             {
                 #Get the previous version's label
                 $VersionLabel=$File.Versions[($File.Versions.Count-1)].VersionLabel
         
                 #Restore the previous version
                 $File.Versions.RestoreByLabel($VersionLabel)
                 $Ctx.ExecuteQuery()
                 Write-Host -f Green "Previous version $VersionLabel Restored on :" $Item["FileRef"]
             }
             Else
             {
                 Write-host "No Versions Available for "$Item["FileRef"] -f Yellow
             }
         }
     }
     While($Query.ListItemCollectionPosition -ne $null)
     }
      Catch {
          write-host -f Red "Error Getting List Items:" $_.Exception.Message
      }
  } 
         
  #Set parameter values
  $SiteURL="<Site_URL>"
  $ListName="Documents"
         
  #Call the function to restore previous document version
  Restore-PreviousVersion -SiteURL $SiteURL -ListName $ListName
