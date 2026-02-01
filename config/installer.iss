[Setup]
AppName=APP_NAME
AppVersion=1.0
DefaultDirName={autopf}\APP_NAME
DefaultGroupName=APP_NAME
OutputDir=Output
OutputBaseFilename=APP_NAME-setup
Compression=lzma
SolidCompression=yes
DisableWelcomePage=yes

[Files]
Source: "zip\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\APP_NAME"; Filename: "{app}\APP_NAME.exe"; IconFilename: "{app}\resources\icon.ico"
Name: "{userdesktop}\APP_NAME"; Filename: "{app}\APP_NAME.exe"; IconFilename: "{app}\resources\icon.ico"

[Run]
Filename: "{app}\APP_NAME.exe"; Description: "Launch APP_NAME"; Flags: nowait postinstall skipifsilent
