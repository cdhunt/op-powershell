Describe 'OpCommand' {
    BeforeAll {
        $class = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'src', 'class', 'CommandBuilder.ps1'
        . $class
    }
    Context 'Constructor' {
        BeforeAll {
            $sut = [OpCommand]::New()
        }
        It 'Should be a valid CommandBuilder child object' {
            $sut.Name | Should -Be 'op'
        }
        It 'Should not have a value' {
            $sut.HasValue | Should -BeFalse
            $sut.Value | Should -BeNullOrEmpty
        }
        It 'Should have no seperator' {
            $sut.Seperator | Should -BeNullOrEmpty
        }
        It 'ToString return should be Name' {
            $result = $sut.ToString()
            $result | Should -Be 'op'
        }
        It 'Has message data' {
            $sut.LocalizedMessage | Should -Not -BeNullOrEmpty
            $sut.LocalizedMessage.Count | Should -Be 2
        }
    }
    Context 'List' {
        BeforeAll {
            $sut = [OpCommandList]::New()
        }
        It 'Should be a valid CommandBuilder child object' {
            $sut.Name | Should -Be 'op'
        }
        It 'Should not have a value' {
            $sut.HasValue | Should -BeFalse
            $sut.Value | Should -BeNullOrEmpty
        }
        It 'Should have no seperator' {
            $sut.Seperator | Should -BeNullOrEmpty
        }
        It 'ToString return should be Name' {
            $result = $sut.ToString()
            $result | Should -Be 'op list'
        }
    }
    Context 'List Items' {
        BeforeAll {
            $sut = [OpCommandListItem]::New()
        }
        It 'Should be a valid CommandBuilder child object' {
            $sut.Name | Should -Be 'op'
        }
        It 'ToString return should be Name' {
            $result = $sut.ToString()
            $result | Should -Be 'op list items'
        }
    }
    Context 'List Items with Arguments' {
        BeforeEach {
            $sut = [OpCommandListItem]::New()
        }

        It 'With Vault' {
            $result = $sut.WithVault('test_vault').ToString()
            $result | Should -Be 'op list items --vault test_vault'
        }
        It 'With one Category' {
            $result = $sut.WithCategory('Login').ToString()
            $result | Should -Be 'op list items --categories Login'
        }
        It 'With more than one Category' {
            $result = $sut.WithCategory(@('Login', 'Password')).ToString()
            $result | Should -Be 'op list items --categories Login,Password'
        }
        It 'With more than one Category using first overload' {
            $result = $sut.WithCategory('Login', 'Password').ToString()
            $result | Should -Be 'op list items --categories Login,Password'
        }
        It 'With more than one Category using second overload' {
            $result = $sut.WithCategory('Login', 'Password', 'Server').ToString()
            $result | Should -Be 'op list items --categories Login,Password,Server'
        }
        It 'With one Tag' {
            $result = $sut.WithTag('tag1').ToString()
            $result | Should -Be 'op list items --tags tag1'
        }
        It 'With more than one Tag' {
            $result = $sut.WithTag(@('tag1', 'tag2')).ToString()
            $result | Should -Be 'op list items --tags tag1,tag2'
        }
        It 'With more than one Tag using first overload' {
            $result = $sut.WithTag('tag1', 'tag2').ToString()
            $result | Should -Be 'op list items --tags tag1,tag2'
        }
        It 'With more than one Tag using second overload' {
            $result = $sut.WithTag('tag1', 'tag2', 'tag3').ToString()
            $result | Should -Be 'op list items --tags tag1,tag2,tag3'
        }
        It 'With Category and Tag' {
            $result = $sut.WithCategory('Login', 'Password').WithTag('tag1', 'tag2').ToString()
            $result | Should -Be 'op list items --categories Login,Password --tags tag1,tag2'
        }
        It 'With Category, Tag and Vault' {
            $result = $sut.WithCategory('Login', 'Password').WithTag('tag1', 'tag2').WithVault('test_vault').ToString()
            $result | Should -Be 'op list items --categories Login,Password --tags tag1,tag2 --vault test_vault'
        }
    }
    Context 'List Item as ProcessStartInfo' {
        BeforeEach {
            $sut = [OpCommandListItem]::New().WithCategory('Login', 'Password').WithTag('tag1', 'tag2').WithVault('test_vault').GetProcessStartInfo()
        }
        It 'Is as [Diagnostics.ProcessStartInfo]' {
            $sut | Should -BeOfType Diagnostics.ProcessStartInfo
        }
        It 'Should have valid properties' {
            $sut.FileName = 'op'
            $sut.RedirectStandardError = $true
            $sut.RedirectStandardOutput = $true
        }
        It 'Should have all arguments' {
            $sut.ArgumentList.Count | Should -Be 8
            $sut.ArgumentList[0] | Should -Be 'list'
            $sut.ArgumentList[1] | Should -Be 'items'
            $sut.ArgumentList[2] | Should -Be '--categories'
            $sut.ArgumentList[3] | Should -Be 'Login,Password'
            $sut.ArgumentList[4] | Should -Be '--tags'
            $sut.ArgumentList[5] | Should -Be 'tag1,tag2'
            $sut.ArgumentList[6] | Should -Be '--vault'
            $sut.ArgumentList[7] | Should -Be 'test_vault'
        }
    }
    Context 'Get Item with Arguments' {
        BeforeEach {
            $sut = [OpCommandGetItem]::New('test_secret')
        }
        It 'Constructor' {
            $result = $sut.ToString()
            $result | Should -Be 'op get item test_secret'
        }
        It 'With Vault' {
            $result = $sut.WithVault('test_vault').ToString()
            $result | Should -Be 'op get item test_secret --vault test_vault'
        }
        It 'With one Field' {
            $result = $sut.WithField('website').ToString()
            $result | Should -Be 'op get item test_secret --fields website'
        }
        It 'With more than one Field' {
            $result = $sut.WithField(@('website', 'username')).ToString()
            $result | Should -Be 'op get item test_secret --fields website,username'
        }
        It 'With more than one Field using first overload' {
            $result = $sut.WithField('website', 'username').ToString()
            $result | Should -Be 'op get item test_secret --fields website,username'
        }
        It 'With more than one Field using second overload' {
            $result = $sut.WithField('website', 'username', 'Server').ToString()
            $result | Should -Be 'op get item test_secret --fields website,username,Server'
        }

        It 'With Field and Format Json' {
            $result = $sut.WithField('website', 'username').WithJsonFormat().ToString()
            $result | Should -Be 'op get item test_secret --fields website,username --format JSON'
        }
        It 'With Field and Format CSV' {
            $result = $sut.WithField('website', 'username').WithCsvFormat().ToString()
            $result | Should -Be 'op get item test_secret --fields website,username --format CSV'
        }
        It 'Format without Field errors' {
            $ErrorActionPreference = 'Stop'
            { $sut.WithCsvFormat().ToString() } | Should -Throw 'Format can only be used with Fields'

        }
        It 'Can''t add Format without Field' {
            $ErrorActionPreference = 'SilentlyContinue'
            $result = $sut.WithCsvFormat().ToString()
            $result | Should -Be 'op get item test_secret'
        }
        It 'Change Format errors' {
            $ErrorActionPreference = 'Stop'
            { $sut.WithField('website', 'username').WithJsonFormat().WithCsvFormat() } | Should -Throw 'Format has already been set'
        }
        It 'Can''t change Format' {
            $ErrorActionPreference = 'SilentlyContinue'
            $result = $sut.WithField('website', 'username').WithJsonFormat().WithCsvFormat().ToString()
            $result | Should -Be 'op get item test_secret --fields website,username --format JSON'
        }
    }
    Context 'Get Item as ProcessStartInfo' {
        BeforeEach {
            $sut = [OpCommandGetItem]::New('test_secret').WithField('website', 'username').WithJsonFormat().GetProcessStartInfo()
        }
        It 'Is as [Diagnostics.ProcessStartInfo]' {
            $sut | Should -BeOfType Diagnostics.ProcessStartInfo
        }
        It 'Should have valid properties' {
            $sut.FileName = 'op'
            $sut.RedirectStandardError = $true
            $sut.RedirectStandardOutput = $true
        }
        It 'Should have all arguments' {
            $sut.ArgumentList.Count | Should -Be 7
            $sut.ArgumentList[0] | Should -Be 'get'
            $sut.ArgumentList[1] | Should -Be 'item'
            $sut.ArgumentList[2] | Should -Be 'test_secret'
            $sut.ArgumentList[3] | Should -Be '--fields'
            $sut.ArgumentList[4] | Should -Be 'website,username'
            $sut.ArgumentList[5] | Should -Be '--format'
            $sut.ArgumentList[6] | Should -Be 'JSON'
        }
    }
    Context 'ParseError' {
        BeforeEach {
            $commandHelpMessage = @'
To list objects and events, use one of the `list` subcommands.

Usage:
    op list [command]

Available Commands:
    documents   Get a list of documents
    events      Get a list of events from the Activity Log
    groups      Get a list of groups
    items       Get a list of items
    templates   Get a list of templates
    users       Get the list of users
    vaults      Get a list of vaults

Flags:
    -h, --help   get help with list

Global Flags:
        --account shorthand   use the account with this shorthand
        --cache               store and use cached information
        --config directory    use this configuration directory
        --session token       authenticate with this session token

Use "op list [command] --help" for more information about a command.
'@
            $signinError = '[ERROR] 2020/12/11 13:48:31 session expired, sign in to create a new session'
            $signinError2 = '[ERROR] 2020/12/11 15:01:17 You are not currently signed in. Please run `op signin --help` for instructions'
            $ErrorActionPreference = 'Stop'
        }
        It 'Base passes the message through to Error' {
            $sut = [CommandBuilder]::new('command')
            $sut.ParseStdErr($signinError)  | Should -Be '[ERROR] 2020/12/11 13:48:31 session expired, sign in to create a new session'
        }
        It 'Parses Command Help should have no Error message' {
            $sut = [OpCommand]::new()
            $sut.ParseStdErr($commandHelpMessage) | Should -BeNullOrEmpty
        }
        It 'Parses Signin Error should an Error message' {
            $sut = [OpCommand]::new()
            $sut.ParseStdErr($signinError)  | Should -Be 'errorSignin'
        }
        It 'Parses Signin Error 2 should an Error message' {
            $sut = [OpCommand]::new()
            $sut.ParseStdErr($signinError2)  | Should -Be 'errorSignin'
        }
        It 'Child class should parse Error message' {
            $sut = [OpCommandListItem]::new()
            $sut.ParseStdErr($signinError)  | Should -Be 'errorSignin'
        }
    }
}
