$IPArch = $(Resolve-DnsName yuch.mshome.net | Select-Object -ExpandProperty "IPAddress")
function Open-Arch() {
    ssh $IPArch
}

$IPUbuntu = $(Resolve-DnsName yuck.mshome.net | Select-Object -ExpandProperty "IPAddress")
function Open-Ubuntu() {
    ssh $IPUbuntu
}

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression