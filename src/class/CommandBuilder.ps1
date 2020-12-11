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
        $_argument = $this.ArgumentList | ForEach-Object {
            $_.ToString($sanitize)
        }

        return '{0} {1}' -f $_command, ($_argument -join ' ')
    }

    [Diagnostics.ProcessStartInfo] GetProcessStartInfo() {
        $_processInfo = [Diagnostics.ProcessStartInfo]::new()
        $_processInfo.FileName = $this.Name
        $_processInfo.RedirectStandardError = $true
        $_processInfo.RedirectStandardOutput = $true
        $_processInfo.UseShellExecute = $false

        $this.ArgumentList | ForEach-Object {
            $_processInfo.ArgumentList.Add($_.ToString())
        }

        return $_processInfo
    }
}