$ErrorActionPreference = "Stop"

import-module servermanager
echo "Installing .NET Framework"
add-windowsfeature as-net-framework