#
#       DirectSetup.nsh
#       
#       For installing DirectX using the System Plug-in.
#
#
 
# NSIS Macro Includes
!define DirectX_Version '!insertmacro DirectX_Version'
!define DirectX_Install '!insertmacro DirectX_Install'
 
# NSIS Includes
!include LogicLib.nsh
 
# Macro Variables
Var DX_SETUP_TYPE
Var DX_SETUP_OUTPATH
 
# DirectSetup Return Values
!define DSETUPERR_SUCCESS_RESTART 1
!define DSETUPERR_SUCCESS 0
!define DSETUPERR_BADWINDOWSVERSION -1
!define DSETUPERR_SOURCEFILENOTFOUND -2
!define DSETUPERR_BADSOURCESIZE -3
!define DSETUPERR_BADSOURCETIME -4
!define DSETUPERR_NOCOPY -5
!define DSETUPERR_OUTOFDISKSPACE -6
!define DSETUPERR_CANTFINDINF -7
!define DSETUPERR_CANTFINDDIR -8
!define DSETUPERR_INTERNAL -9
!define DSETUPERR_NTWITHNO3D -10
!define DSETUPERR_UNKNOWNOS -11
!define DSETUPERR_USERHITCANCEL -12
!define DSETUPERR_NOTPREINSTALLEDONNT -13
!define DSETUPERR_NOTADMIN -15
!define DSETUPERR_UNSUPPORTEDPROCESSOR -16
!define DSETUPERR_CABDOWNLOADFAIL -19
!define DSETUPERR_DXCOMPONENTFILEINUSE -20
!define DSETUPERR_UNTRUSTEDCABINETFILE -21
 
# DirectSetup Flags
!define DSETUP_DDRAWDRV         0x00000008
!define DSETUP_DSOUNDDRV            0x00000010
!define DSETUP_DXCORE               0x00010000
!define DSETUP_DIRECTX              0x00010018
!define DSETUP_MANAGEDDX            0x00004000
!define DSETUP_TESTINSTALL          0x00020000
 
# DirectXSetupCallbackFunction Reason Codes
!define DSETUP_CB_MSG_NOMESSAGE                     0
!define DSETUP_CB_MSG_INTERNAL_ERROR                10
!define DSETUP_CB_MSG_BEGIN_INSTALL                 13
!define DSETUP_CB_MSG_BEGIN_INSTALL_RUNTIME         14
!define DSETUP_CB_MSG_PROGRESS                      18
!define DSETUP_CB_MSG_WARNING_DISABLED_COMPONENT    19
 
/*
    DirectX_Version
 
        Retrieves the version number of the DirectX core runtime components that are currently installed.
 
        INPUT:
            DirectX_SRC = Location of the extracted DirectX runtime components.
 
        OUTPUT:
            $2 = Returns the version number as an int which was converted from a hex value.
            $3 = Returns the revision number as an int which was converted from a hex value.
 
*/
!macro DirectX_Version DirectX_SRC
 
    StrCpy $DX_SETUP_OUTPATH $OUTDIR
 
    SetOutPath "${DirectX_SRC}"
    System::Alloc 4
    Pop $0
    System::Alloc 4
    Pop $1
    System::Call "dsetup::DirectXSetupGetVersion(i, i) i (r0, r1) .r2"
 
    System::Call "*$0(&i4 .r2)"
    System::Call "*$1(&i4 .r3)"
 
    SetOutPath $DX_SETUP_OUTPATH
 
!macroend
 
/*
    DirectX_Install
 
        Retrieves the version number of the DirectX core runtime components that are currently installed.
 
        INPUT:
            DirectX_SRC = Location of the extracted DirectX runtime components.
 
        OUTPUT:
            $9 = The return vaule recieved by the DirectX Setup program.
 
        Todo:
            Incorperate DirectXSetupCallbackFunction() to allow progress status when
                DirectSetup is running.
 
*/
!macro DirectX_Install DirectX_SRC
 
    StrCpy $DX_SETUP_TYPE ${DSETUP_DIRECTX}
 
    # Uncomment this line when testing. It test a DirectX install, but won't actually do the install.
        ;StrCpy $DX_SETUP_TYPE ${DSETUP_TESTINSTALL}
 
    # Save the current $OUTDIR.
    StrCpy $DX_SETUP_OUTPATH $OUTDIR
    SetOutPath "${DirectX_SRC}"
 
    # The Actual DirectX Setup call
    DetailPrint "Updating DirectX. Please wait."
    System::Call 'DSetup::DirectXSetupA(i, t, i) i \
    ($HWNDPARENT, "${DirectX_SRC}", $DX_SETUP_TYPE) .r9'
 
    # Reset $OUTDIR
        SetOutPath $DX_SETUP_OUTPATH
 
    # When DirectX Installs in some way:
 
        ${If} $9 == ${DSETUPERR_SUCCESS}
            DetailPrint "DirectX Setup Success! No restart needed!"
            Goto DX_INSTALL_SUCCESS
        ${ElseIf} $9 == ${DSETUPERR_SUCCESS_RESTART}
            SetRebootFlag true
            DetailPrint "DirectX Setup Success! A restart will be required."
            Goto DX_INSTALL_SUCCESS
 
    # When DirectX Fails in some way:
 
        # User's system is incapable
        ${ElseIf} $9 == ${DSETUPERR_BADWINDOWSVERSION}
            DetailPrint "DirectX Setup Failed: Microsoft DirectX does not support the version of Microsoft Windows on the computer."
            Goto DX_INSTALL_FAIL
        ${ElseIf} $9 == ${DSETUPERR_OUTOFDISKSPACE}
            DetailPrint "DirectX Setup Failed: The setup program ran out of disk space during installation."
            Goto DX_INSTALL_FAIL
        ${ElseIf} $9 == ${DSETUPERR_UNKNOWNOS}
            DetailPrint "DirectX Setup Failed: The operating system is unknown."
            Goto DX_INSTALL_FAIL
        ${ElseIf} $9 == ${DSETUPERR_NOTADMIN}
            DetailPrint "DirectX Setup Failed: The current user does not have administrative privileges."
            Goto DX_INSTALL_FAIL
        ${ElseIf} $9 == ${DSETUPERR_UNSUPPORTEDPROCESSOR}
            DetailPrint "DirectX Setup Failed: The processor type is unsupported. DirectX supports only Intel Pentium, AMD K6, and compatible processors with equivalent or higher performance."
            Goto DX_INSTALL_FAIL
 
        # DirectX Files broken
        ${ElseIf} $9 == ${DSETUPERR_SOURCEFILENOTFOUND}
            DetailPrint "DirectX Setup Failed: One of the required source files could not be found."
            Goto DX_INSTALL_FAIL
        ${ElseIf} $9 == ${DSETUPERR_NOCOPY}
            DetailPrint "DirectX Setup Failed: A file's version could not be verified or was incorrect."
            Goto DX_INSTALL_FAIL
        ${ElseIf} $9 == ${DSETUPERR_CANTFINDINF}
            DetailPrint "DirectX Setup Failed: A required information (.inf) file could not be found."
            Goto DX_INSTALL_FAIL
        ${ElseIf} $9 == ${DSETUPERR_CANTFINDDIR}
            DetailPrint "DirectX Setup Failed: The setup program could not find the working directory."
            Goto DX_INSTALL_FAIL
        ${ElseIf} $9 == ${DSETUPERR_CABDOWNLOADFAIL}
            DetailPrint "DirectX Setup Failed: The cabinet (.cab) file failed to load."
            Goto DX_INSTALL_FAIL
        ${ElseIf} $9 == ${DSETUPERR_DXCOMPONENTFILEINUSE}
            DetailPrint "DirectX Setup Failed: The cabinet (.cab) file was in use."
            Goto DX_INSTALL_FAIL
        ${ElseIf} $9 == ${DSETUPERR_UNTRUSTEDCABINETFILE}
            DetailPrint "DirectX Setup Failed: The cabinet (.cab) file is not signed."
            Goto DX_INSTALL_FAIL
 
        # Unknown or other errors
        ${Else} # Also doubles for ${DSETUPERR_INTERNAL}
            DetailPrint "DirectX Setup Failed: An internal error occurred."
            Goto DX_INSTALL_FAIL
        ${EndIf}
 
    DX_INSTALL_FAIL:
        # Instructions when failed.
 
    DX_INSTALL_SUCCESS:
        # Instructions when passed.
 
!macroend