{$IFDEF MSWINDOWS}
{$IFNDEF DEBUG}
{$IFNDEF FPC}

{$IF CompilerVersion > 18}
  {$WEAKLINKRTTI ON}
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$IFEND}

const

  IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE = $8000;

  {$SetPEOptFlags IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE}

  IMAGE_FILE_RELOCS_STRIPPED               = $0001;  { Relocation info stripped from file. }
  IMAGE_FILE_EXECUTABLE_IMAGE              = $0002;  { The file is executable (there are no unresolved external references). }
  IMAGE_FILE_LINE_NUMS_STRIPPED            = $0004;  { Line nunbers stripped from file. }
  IMAGE_FILE_LOCAL_SYMS_STRIPPED           = $0008;  { Local symbols stripped from file. }
  IMAGE_FILE_DEBUG_STRIPPED                = $0200;  { Debugging info stripped from file in .DBG file }
  IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP       = $0400;  { If Image is on removable media, copy and run from the swap file. }
  IMAGE_FILE_NET_RUN_FROM_SWAP             = $0800;  { If Image is on Net, copy and run from the swap file. }

  {$SetPEFlags IMAGE_FILE_RELOCS_STRIPPED or IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP or IMAGE_FILE_NET_RUN_FROM_SWAP}
  {$SetPEFlags IMAGE_FILE_DEBUG_STRIPPED or IMAGE_FILE_LINE_NUMS_STRIPPED or IMAGE_FILE_LOCAL_SYMS_STRIPPED}
  {$SetPEFlags IMAGE_FILE_EXECUTABLE_IMAGE}

{$ENDIF FPC}
{$ENDIF DEBUG}
{$ENDIF MSWINDOWS}
