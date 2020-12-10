class Argument {
    [string] $Name
    [bool] $HasValue = $false
    [object[]] $Value
    hidden  [string] $Seperator = ''
    hidden [scriptblock] $ValueReduce = { $args -join ',' }
    hidden [bool] $HasQuote = $false

    Argument([string]$name) {
        $this.Name = $name
    }

    Argument([string]$name, [object[]]$value) {
        $this.Name = $name
        $this.Value = $value
        $this.Seperator = ' '
        $this.HasValue = $true
    }

    Argument([string]$name, [object[]]$value, [string]$seperator) {
        $this.Name = $name
        $this.Value = $value
        $this.HasValue = $true
        $this.Seperator = $seperator
    }

    Argument([string]$name, [object[]]$value, [string]$seperator, [scriptblock]$reduce) {
        $this.Name = $name
        $this.Value = $value
        $this.HasValue = $true
        $this.Seperator = $seperator
        $this.ValueReduce = $reduce
    }

    [Argument] AddValue($v) {
        $this.Value += $v
        $this.HasValue = $true

        if ([string]::IsNullOrEmpty($this.Seperator)) {
            $this.Seperator = ' '
        }

        return $this
    }

    [Argument] SetSeparator([string]$string) {
        $this.Seperator = $string

        return $this
    }

    [Argument] SetQuotedValue() {
        $this.HasQuote = $true

        return $this
    }

    [Argument] SetValueReduce([scriptblock]$script) {
        if ($script.ToString() -notlike '*$args *') {
            throw 'ScriptBlock must contain "$args" variable.'
        }

        $this.ValueReduce = $script

        return $this
    }

    [string] ToString() {
        $_argument = $this.Name
        $_value = [string]::Empty
        $_combined = [string]::Empty

        if ($this.HasValue) {
            $_value = if ($this.Value.Count -gt 1) { $this.ValueReduce.Invoke($this.Value) } else { $this.Value }
        }

        if ($this.HasQuote) {
            $_value = '"{0}"' -f $_value
        }

        $_combined = $_argument, $_value -join $this.Seperator
        return $_combined
    }
}

class ThingToRun {
    [string] $Name
    hidden [System.Collections.Generic.List[Argument]] $ArgumentList = [System.Collections.Generic.List[Argument]]::new()

    ThingToRun($name) {
        $this.Name = $name
    }

    [ThingToRun] AddArgument([Argument]$arg) {
        $this.ArgumentList.Add($arg)

        return $this
    }

    [ThingToRun] AddArgument([string]$name) {
        $this.ArgumentList.Add([Argument]::new($name))

        return $this
    }

    [ThingToRun] AddArgument([string]$name, [object]$value) {
        $this.ArgumentList.Add([Argument]::new($name, $value))

        return $this
    }

    [ThingToRun] AddArgument([string]$name, [object]$value, [string]$seperator) {
        $this.ArgumentList.Add([Argument]::new($name, $value, $seperator))

        return $this
    }


    [string] ToString() {
        $_command = $this.Name
        $_argument = $this.ArgumentList | ForEach-Object { $_.ToString() }

        return '{0} {1}' -f $_command, ($_argument -join ' ')
    }
}