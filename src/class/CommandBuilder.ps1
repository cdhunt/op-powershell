class CommandArgument {
    [string] $Name
    [bool] $HasValue = $false
    [bool] $IsSensitive = $false
    [object[]] $Value
    hidden  [string] $Seperator = ''
    hidden [scriptblock] $ValueReduce = { $args -join ',' }
    hidden [bool] $HasQuote = $false

    CommandArgument([string]$name) {
        $this.Name = $name
    }

    CommandArgument([string]$name, [object[]]$value) {
        $this.Name = $name
        $this.Value = $value
        $this.Seperator = ' '
        $this.HasValue = $true
    }

    CommandArgument([string]$name, [object[]]$value, [string]$seperator) {
        $this.Name = $name
        $this.Value = $value
        $this.HasValue = $true
        $this.Seperator = $seperator
    }

    CommandArgument([string]$name, [object[]]$value, [string]$seperator, [scriptblock]$reduce) {
        $this.Name = $name
        $this.Value = $value
        $this.HasValue = $true
        $this.Seperator = $seperator
        $this.ValueReduce = $reduce
    }

    [CommandArgument] AddValue($v) {
        $this.Value += $v
        $this.HasValue = $true

        if ([string]::IsNullOrEmpty($this.Seperator)) {
            $this.Seperator = ' '
        }

        return $this
    }

    [CommandArgument] SetSeparator([string]$string) {
        $this.Seperator = $string

        return $this
    }

    [CommandArgument] SetQuotedValue() {
        $this.HasQuote = $true

        return $this
    }

    [CommandArgument] SetValueReduce([scriptblock]$script) {
        if ($script.ToString() -notlike '*$args *') {
            throw 'ScriptBlock must contain "$args" variable.'
        }

        $this.ValueReduce = $script

        return $this
    }

    [string] ToString() {
        return $this.ToString($false)
    }

    [string] ToString([bool]$sanitize) {
        $_argument = $this.Name
        $_value = [string]::Empty
        $_combined = [string]::Empty

        if ($this.HasValue) {
            $_value = if ($this.Value.Count -gt 1) { $this.ValueReduce.Invoke($this.Value) } else { $this.Value }

            if ($this.IsSensitive -and $sanitize) {
                $_value = '*****'
            }

            if ($this.HasQuote) {
                $_value = '"{0}"' -f $_value
            }
        }

        $_combined = $_argument, $_value -join $this.Seperator
        return $_combined
    }

    [System.Collections.Generic.List[CommandArgument]] AsMultipleArguments() {
        $_argArray = [System.Collections.Generic.List[CommandArgument]]::new()
        if ($this.HasValue) {
            foreach ($_value in $this.Value) {
                $_newArg = [CommandArgument]::new($this.Name, $_value)
                $_newArg.Seperator = $this.Seperator
                $_newArg.ValueReduce = $this.ValueReduce
                $_newArg.IsSensitive = $this.IsSensitive
                $_argArray.Add($_newArg)
            }
        }

        return $_argArray
    }
}

class CommandBuilder {
    [string] $Name
    hidden [System.Collections.Generic.List[CommandArgument]] $ArgumentList = [System.Collections.Generic.List[CommandArgument]]::new()

    CommandBuilder($name) {
        $this.Name = $name
    }

    [CommandBuilder] AddArgument([CommandArgument]$arg) {
        $this.ArgumentList.Add($arg)

        return $this
    }

    [CommandBuilder] AddArgument([string]$name) {
        $this.ArgumentList.Add([CommandArgument]::new($name))

        return $this
    }

    [CommandBuilder] AddArgument([string]$name, [object]$value) {
        $this.ArgumentList.Add([CommandArgument]::new($name, $value))

        return $this
    }

    [CommandBuilder] AddArgument([string]$name, [object]$value, [string]$seperator) {
        $this.ArgumentList.Add([CommandArgument]::new($name, $value, $seperator))

        return $this
    }

    [string] ToString() {
        return $this.ToString($false)
    }

    [string] ToString([bool]$sanitize) {
        $_command = $this.Name

        if ($this.ArgumentList.Count -ge 1) {
            $_argument = $this.ArgumentList | ForEach-Object {
                $_.ToString($sanitize)
            }
            return '{0} {1}' -f $_command, ($_argument -join ' ')
        }
        else {
            return '{0}' -f $_command
        }
    }

    [Diagnostics.ProcessStartInfo] GetProcessStartInfo() {
        $_processInfo = [Diagnostics.ProcessStartInfo]::new()
        $_processInfo.FileName = $this.Name
        $_processInfo.RedirectStandardError = $true
        $_processInfo.RedirectStandardOutput = $true
        $_processInfo.RedirectStandardInput = $true
        $_processInfo.UseShellExecute = $false

        $this.ArgumentList | ForEach-Object {
            if ($_.HasValue) {
                $_value = $_.ValueReduce.Invoke($_.Value)
                $_processInfo.ArgumentList.Add($_.Name)
                $_processInfo.ArgumentList.Add($_value)
            }
            else {
                $_processInfo.ArgumentList.Add($_.Name)
            }
        }

        return $_processInfo
    }

    [string] ParseStdErr([string]$message) {
        return $message
    }

    [string] Run() {
        Write-Verbose ('(Run) Command="{0}"' -f $this.ToString($true))

        $_process = [Diagnostics.Process]::new()
        $_process.StartInfo = $this.GetProcessStartInfo()
        $_cleanExit = $false
        $_message = [string]::Empty

        try {
            $_process.Start() | Out-Null
        }
        catch [ObjectDisposedException] {
            Write-Error 'No file name was specified.'
        }
        catch [InvalidOperationException] {
            Write-Error 'The process object has already been disposed.'
        }
        catch [PlatformNotSupportedException] {
            Write-Error 'This member is not supported on this platform.'
        }
        catch {
            Write-Error 'An error occurred when opening the associated file.'
        }

        try {
            $_process.WaitForExit(10000)
            $_cleanExit = $true
        }
        catch [SystemException] {
            Write-Error 'No process Id has been set, and a Handle from which the Id property can be determined does not exist or there is no process associated with this Process object.'
        }
        catch {
            Write-Error 'The wait setting could not be accessed.'
        }

        if ($_cleanExit) {

            $_message = $_process.StandardOutput.ReadToEnd()
            $_stdErr = $_process.StandardError.ReadToEnd()

            if (-not [string]::IsNullOrEmpty($_stdErr) ) {
                Write-Error $this.ParseStdErr($_stdErr)
            }
        }

        return $_message
    }
}

class OpCommand : CommandBuilder {

    OpCommand() : base('op') {}

    [string] ParseStdErr([string]$message) {
        $_groups = Select-String -InputObject $message -Pattern '\[ERROR\] (?<date>\d{4}\W\d{1,2}\W\d{1,2}) (?<time>\d{2}:\d{2}:\d{2}) (?<message>.*)'

        if ($null -eq $_groups) {
            return [string]::Empty
        }

        $_rawMessage = $_groups.Matches.Groups.Where( { $_.Name -eq 'message' }).Value

        $_firstChar = $_rawMessage.Substring(0, 1).ToUpper()
        $_rest = $_rawMessage.Substring(1)
        $_ending = if ($_rawMessage[-1] -ne '.') { '.' } else { [string]::Empty }
        $_message = '{0}{1}{2}' -f $_firstChar, $_rest, $_ending

        return $_message
    }
}

class OpCommandList : OpCommand {

    OpCommandList() : base() {
        $this.AddArgument('list')
    }
}

class OpCommandGet : OpCommand {

    OpCommandGet() : base() {
        $this.AddArgument('get')
    }
}

class OpCommandListItem : OpCommandList {

    OpCommandListItem() : base() {
        $this.AddArgument('items')
    }

    [OpCommandListItem] WithVault([string]$name) {
        $this.AddArgument('--vault', $name)
        return $this
    }

    [OpCommandListItem] WithCategory([string[]]$category) {
        $this.AddArgument('--categories', $category)
        return $this
    }

    [OpCommandListItem] WithCategory([string]$c1, [string]$c2) {
        $this.AddArgument('--categories', @($c1, $c2))
        return $this
    }

    [OpCommandListItem] WithCategory([string]$c1, [string]$c2, [string]$c3) {
        $this.AddArgument('--categories', @($c1, $c2, $c3))
        return $this
    }

    [OpCommandListItem] WithTag([string[]]$tag) {
        $this.AddArgument('--tags', $tag)
        return $this
    }

    [OpCommandListItem] WithTag([string]$t1, [string]$t2) {
        $this.AddArgument('--tags', @($t1, $t2))
        return $this
    }

    [OpCommandListItem] WithTag([string]$t1, [string]$t2, [string]$t3) {
        $this.AddArgument('--tags', @($t1, $t2, $t3))
        return $this
    }
}

class OpCommandGetItem : OpCommandGet {
    hidden [bool] $hasField = $false
    hidden [bool] $hasFormat = $false

    OpCommandGetItem([string]$item) : base() {
        $this.AddArgument('item', $item)
    }

    [OpCommandGetItem] WithVault([string]$name) {
        $this.AddArgument('--vault', $name)
        return $this
    }

    [OpCommandGetItem] WithField([string[]]$field) {
        $this.AddArgument('--fields', $field)
        $this.hasField = $true
        return $this
    }

    [OpCommandGetItem] WithField([string]$f1, [string]$f2) {
        $this.AddArgument('--fields', @($f1, $f2))
        $this.hasField = $true
        return $this
    }

    [OpCommandGetItem] WithField([string]$f1, [string]$f2, [string]$f3) {
        $this.AddArgument('--fields', @($f1, $f2, $f3))
        $this.hasField = $true
        return $this
    }

    hidden [OpCommandGetItem] WithFormat([string]$format) {
        if ($this.hasFormat) {
            Write-Error -Message 'Format has already been set'
            return $this
        }

        if (-not $this.hasField) {
            Write-Error -Message 'Format can only be used with Fields'
            return $this
        }

        $this.AddArgument('--format', $format)
        $this.hasFormat = $true

        return $this
    }

    [OpCommandGetItem] WithJsonFormat() {
        return $this.WithFormat('JSON')
    }

    [OpCommandGetItem] WithCsvFormat() {
        return $this.WithFormat('Csv')
    }

    [OpCommandGetItem] IncludeTrash() {
        $this.AddArgument('--include-trash')
        return $this
    }
}