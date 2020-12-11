Describe 'CommandBuilder' {
    BeforeAll {
        $class = Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'src', 'class', 'CommandBuilder.ps1'
        . $class
    }
    Context "CommandArgument" {
        Context "Defaults" {
            BeforeAll {
                $sut = [CommandArgument]::New('test')
            }
            It 'Should have a name property' {
                $sut.Name | Should -Be 'test'
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
                $result | Should -Be 'test'
            }
        }
        Context "Defaults with single Value" {
            BeforeAll {
                $sut = [CommandArgument]::New('test', 'value')
            }

            It 'Should have a name property' {
                $sut.Name | Should -Be 'test'
            }
            It 'Should have a value' {
                $sut.HasValue | Should -BeTrue
                $sut.Value | Should -Be 'value'
            }
            It 'Should have a space seperator' {
                $sut.Seperator | Should -Be ' '
            }
            It 'ToString return should be Name Value' {
                $result = $sut.ToString()
                $result | Should -Be 'test value'
            }
        }
        Context "Defaults with multi Value" {
            BeforeAll {
                $sut = [CommandArgument]::New('test', @('value1', 'value2'))
            }

            It 'Should have a name property' {
                $sut.Name | Should -Be 'test'
            }
            It 'Should have a value array' {
                $sut.HasValue | Should -BeTrue
                $sut.Value.Count | Should -Be 2
            }
            It 'Should have a space seperator' {
                $sut.Seperator | Should -Be ' '
            }
            It 'ToString return should be Name Value' {
                $result = $sut.ToString()
                $result | Should -Be 'test value1,value2'
            }
        }
        Context "Seperator" {
            BeforeAll {
                $sut = [CommandArgument]::New('test', 'value')
                $sut = $sut.SetSeparator(':')
            }

            It 'Should have a space seperator' {
                $sut.Seperator | Should -Be ':'
            }
            It 'ToString return should be Name Value' {
                $result = $sut.ToString()
                $result | Should -Be 'test:value'
            }
        }
        Context "Reduce with one value" {
            BeforeAll {
                $sut = [CommandArgument]::New('test', 'value')
                $sut = $sut.SetValueReduce( { $args -join ' ' })
            }

            It 'Should have a space seperator' {
                $sut.ValueReduce.ToString().Trim() | Should -Be '$args -join '' '''
            }
            It 'ToString return should be Name Value' {
                $result = $sut.ToString()
                $result | Should -Be 'test value'
            }
            It 'AsMultipleArguments should also be Name Value' {
                $result = $sut.AsMultipleArguments()

                $result.Count | Should -Be 1
                $result[0].ToString() | Should -Be 'test value'
            }
        }
        Context "Reduce with multiple values" {
            BeforeAll {
                $sut = [CommandArgument]::New('test', @('value1', 'value2'))
                $sut = $sut.SetValueReduce( { $args -join ' ' } )
            }

            It 'ToString return should be Name Value Value' {
                $result = $sut.ToString()

                $sut.Value.Count | Should -Be 2
                $sut.HasValue | Should -BeTrue
                $result | Should -Be 'test value1 value2'
            }
            It 'Should throw if Reduce doesn''t reference $args' {
                { $sut.SetValueReduce( { $_ -join ' ' } ) } | Should -Throw 'ScriptBlock must contain "$args" variable.'
            }
            It 'AsMultipleArguments should return a List of Argument' {
                $result = $sut.AsMultipleArguments()

                $result.Count | Should -Be 2
                $result[0].ToString() | Should -Be 'test value1'
                $result[1].ToString() | Should -Be 'test value2'
            }
        }
        Context 'Add Value' {
            BeforeAll {
                $sut = [CommandArgument]::New('test')

            }
            It 'Should not have a value' {
                $sut.HasValue | Should -BeFalse
                $sut.Seperator | Should -BeNullOrEmpty
                $sut.Value | Should -BeNullOrEmpty
            }
            It 'AddValue should add to Value array' {
                $new = $sut.AddValue('value')

                $new.Value.Count | Should -Be 1
                $new.HasValue | Should -BeTrue
                $result = $new.ToString()
                $result | Should -Be 'test value'
            }
        }
    }
    Context "ThingToRun" {
        Context "No arguments" {
            BeforeAll {
                $sut = [CommandBuilder]::New('test')
            }
            It 'Should have a Name' {
                $sut.Name | Should -Be 'test'
            }
            It 'Should have no arguments' {
                $sut.ArgumentList.count | Should -Be 0
            }
        }
        Context "With one argument" {
            BeforeAll {
                $sut = [CommandBuilder]::New('test')
                $arg = [CommandArgument]::New('-arg', 'value')
                $sut = $sut.AddArgument($arg)
            }
            It 'Should have a Name' {
                $sut.Name | Should -Be 'test'

            }
            It 'Should an argument' {
                $sut.ArgumentList.count | Should -Be 1
                $sut.ToString() | Should -Be 'test -arg value'
            }
        }
        Context "With multiple argument" {
            BeforeAll {
                $sut = [CommandBuilder]::New('test')
                $arg1 = [CommandArgument]::New('-arg', 'value')
                $arg2 = [CommandArgument]::New('-flag')
                $sut = $sut.AddArgument($arg1).AddArgument($arg2)

            }
            It 'Should have a Name' {
                $sut.Name | Should -Be 'test'

            }
            It 'Should an argument' {
                $sut.ArgumentList.count | Should -Be 2
                $sut.ToString() | Should -Be 'test -arg value -flag'
            }
        }
        Context "With one sensitive value" {
            BeforeAll {
                $sut = [CommandBuilder]::New('test')
                $arg = [CommandArgument]::New('-arg', 'value')
                $arg.IsSensitive = $true
                $sut = $sut.AddArgument($arg)
            }
            It 'Should have a Name' {
                $sut.Name | Should -Be 'test'

            }
            It 'Should mask an argument' {
                $sut.ArgumentList.count | Should -Be 1
                $sut.ToString($true) | Should -Be 'test -arg *****'
            }
            It 'Should not mask by default' {
                $sut.ArgumentList.count | Should -Be 1
                $sut.ToString() | Should -Be 'test -arg value'
            }
        }
        Context "With multiple values, one sensitive" {
            BeforeAll {
                $sut = [CommandBuilder]::New('test')
                $arg1 = [CommandArgument]::New('-arg', 'value')
                $arg1.IsSensitive = $true
                $arg2 = [CommandArgument]::New('-arg2', 'value2')
                $sut = $sut.AddArgument($arg).AddArgument($arg2)
            }
            It 'Should only the sensetive argument' {
                $sut.ArgumentList.count | Should -Be 2
                $sut.ToString($true) | Should -Be 'test -arg ***** -arg2 value2'
            }
        }
        Context 'Helper methods' {
            It '.AddArgument($name)' {
                $sut = [CommandBuilder]::New('test').AddArgument('-flag')
                $sut.ArgumentList.count | Should -Be 1
                $sut.ToString() | Should -Be 'test -flag'
            }
            It '.AddArgument($name, $value)' {
                $sut = [CommandBuilder]::New('test').AddArgument('-flag', 'value')
                $sut.ArgumentList.count | Should -Be 1
                $sut.ToString() | Should -Be 'test -flag value'
            }
            It '.AddArgument($name, $value, $seperator)' {
                $sut = [CommandBuilder]::New('test').AddArgument('-flag', 'value', ':')
                $sut.ArgumentList.count | Should -Be 1
                $sut.ToString() | Should -Be 'test -flag:value'
            }
        }
        Context 'Get ProcessStartInfo' {
            BeforeAll {
                $sut = [CommandBuilder]::New('test').AddArgument('-flag')
            }
            It 'Should return a ProcessStartInfo object' {
                $result = $sut.GetProcessStartInfo()

                $result.FileName | Should -Be 'test'
                $result.ArgumentList | Should -Be '-flag'
            }

        }
    }
}

