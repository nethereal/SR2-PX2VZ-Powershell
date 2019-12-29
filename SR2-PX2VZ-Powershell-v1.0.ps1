
$FlightProgramOutputFolder = "$($env:LOCALAPPDATA)Low\Jundroo\SimpleRockets 2\UserData\FlightPrograms\"

$XMLFolder = "$($env:LOCALAPPDATA)Low\Jundroo\SimpleRockets 2\UserData\SolarSystems\ESS 2.0 - Stepping Stone\"
$XMLFile = "SolarSystem.XML"
$XMLData = [xml](Get-Content "$XMLFolder$XMLFile") 

$Planets = $XMLData.ChildNodes[1].Planet

$PlanetNameProp = @(
    'angularVelocity',
    'Description',
    'hasTerrainPhysics',
    'hasWater',
    'MusicKeywords',
    'name',
    'parent',
    'planetType',
    'radius',
    'radiusScaledSpaceHeightAdjustment',
    'seaLevel',
    'skyShaderEnabled',
    'surfaceGravity',
    'uniformHeight'
)

$PlanetNameOrb = @(
    'argumentOfPeriapsis',
    'eccentricity',
    'inclination',
    'prograde',
    'rightAscensionOfAscendingNode',
    'semiMajorAxis',
    'time',
    'trueAnomaly'
)

$PlanetNameAtm = @(
    'crushAltitude',
    'desc',
    'hasPhysicsAtmosphere',
    'meanDaySurfaceTemperature',
    'meanGamma',
    'meanMassPerMolecule',
    'meanNightSurfaceTemperature',
    'surfaceAirDensity'
)

$BaseXML = @"
<?xml version="1.0" encoding="utf-8"?>
<Program name="###PROGRAMNAME###">
  <Variables>
###VARINSERT###
  </Variables>
  <Instructions>
    <Event event="FlightStart" id="0" style="flight-start" pos="-10,-20" />
    ###SETINSERT###
  </Instructions>
  <Expressions />
</Program>
"@

$VarDeclareTempate = @"
    <Variable name="VARNAME" number="0" />
"@

$VarSetTemplate = @"
    <SetVariable id="VARINC" style="set-variable">
      <Variable local="false" variableName="VARNAME" />
      <Constant VARTYPE="VARVALUE" />
    </SetVariable>
"@

$Script:VarInc = 1

Function MyIsNumber ([string]$val) {
    $groupresults = $val.ToCharArray() | % { [Byte]$_ } | Group-Object
    If (($groupresults | ? { $_.Name -eq "46" }).Count -gt 1) { return $false }
    $UniqueAsciiVals = ($val.ToCharArray() | % { [Byte]$_ }) | Select -Unique
    $UniqueAsciiVals = $UniqueAsciiVals | ? { $_ -ne "46" } 
    If (($UniqueAsciiVals | ? { $_ -ge 48 -and $_ -le 57 }).Count -ne $UniqueAsciiVals.Count) { return $false }
    return $true
}

Function ConstructVarXML {
    Param(
        $Name,
        $Value
    )
    If (MyIsNumber -val $Value) { $VarType = "number" } 
    ElseIf ($Value.ToUpper() -eq "TRUE" -or $Value.ToUpper() -eq "FALSE") { $VarType = 'style="true" bool' }
    Else { $VarType = "text" }
    $tmpDeclareTemplate = $null
    $tmpDeclareTemplate = $VarDeclareTempate 
    $tmpDeclareTemplate = $tmpDeclareTemplate -replace "VARNAME",$Name
    $tmpSetTemplate = $null
    $tmpSetTemplate = $VarSetTemplate 
    $tmpSetTemplate = $tmpSetTemplate -replace "VARNAME",$Name
    $tmpSetTemplate = $tmpSetTemplate -replace "VARINC",$Script:VarInc
    $tmpSetTemplate = $tmpSetTemplate -replace "VARTYPE",$VarType
    $tmpSetTemplate = $tmpSetTemplate -replace "VARVALUE",$Value
    $result = @("","")
    $result[0] = $tmpDeclareTemplate
    $result[1] = $tmpSetTemplate
    $Script:VarInc++
    return $result
}

ForEach ($Planet in $Planets) {
    $ProgramName = $null
    $ProgramName = "PX2VZ-$($Planet.Name)"
    $ProgramFileName = $null
    $ProgramFileName = "$($ProgramName).xml"
    $tmpXMLTemplate = $null
    $tmpXMLTemplate = $BaseXML
    $tmpXMLTemplate = $tmpXMLTemplate -replace "###PROGRAMNAME###",$ProgramName
    ForEach ($Prop in $PlanetNameProp) {
        $VarValue = $null
        $VarValue = $Planet."$Prop"
        $VarName = $null
        $VarName = "$($Planet.Name)Prop$($Prop.Substring(0,1).ToUpper() + $Prop.Substring(1))"
        If ($VarValue -and $VarName) { 
            $tempres = $null
            $tempres = ConstructVarXML -Name $VarName -Value $VarValue 
            $tmpXMLTemplate = $tmpXMLTemplate -replace "###VARINSERT###","$($tempres[0])`n###VARINSERT###"
            $tmpXMLTemplate = $tmpXMLTemplate -replace "###SETINSERT###","$($tempres[1])`n###SETINSERT###"
        }
    }
    ForEach ($OrbProp in $PlanetNameOrb) {
        $VarValue = $null
        $VarValue = $Planet.Orbit."$OrbProp"
        $VarName = $null
        $VarName = "$($Planet.Name)PropOrb$($OrbProp.Substring(0,1).ToUpper() + $OrbProp.Substring(1))"
        If ($VarValue -and $VarName) { 
            $tempres = $null
            $tempres = ConstructVarXML -Name $VarName -Value $VarValue 
            $tmpXMLTemplate = $tmpXMLTemplate -replace "###VARINSERT###","$($tempres[0])`n###VARINSERT###"
            $tmpXMLTemplate = $tmpXMLTemplate -replace "###SETINSERT###","$($tempres[1])`n###SETINSERT###"
        }
    }
    ForEach ($AtmProp in $PlanetNameAtm) {
        $VarValue = $null
        $VarValue = $Planet.Atmosphere."$AtmProp"
        $VarName = $null
        $VarName = "$($Planet.Name)PropAtm$($AtmProp.Substring(0,1).ToUpper() + $AtmProp.Substring(1))"
        If ($VarValue -and $VarName) { 
            $tempres = $null
            $tempres = ConstructVarXML -Name $VarName -Value $VarValue 
            $tmpXMLTemplate = $tmpXMLTemplate -replace "###VARINSERT###","$($tempres[0])`n###VARINSERT###"
            $tmpXMLTemplate = $tmpXMLTemplate -replace "###SETINSERT###","$($tempres[1])`n###SETINSERT###"
        }
    }
    $tmpXMLTemplate = $tmpXMLTemplate -replace "`n###VARINSERT###",""
    $tmpXMLTemplate = $tmpXMLTemplate -replace "`n###SETINSERT###",""
    Set-Content -Path "$FlightProgramOutputFolder$ProgramName$(".xml")" -Value $tmpXMLTemplate
}

