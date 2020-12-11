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
}
