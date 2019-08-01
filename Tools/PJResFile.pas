{
 * This Source Code Form is subject to the terms of the Mozilla Public License,
 * v. 2.0. If a copy of the MPL was not distributed with this file, You can
 * obtain one at http://mozilla.org/MPL/2.0/
 *
 * Copyright (C) 2004-2014, Peter Johnson (www.delphidabbler.com).
 *
 * $Rev: 1669 $
 * $Date: 2014-01-15 21:22:00 +0000 (Wed, 15 Jan 2014) $
 *
 * Defines classes that encapsulate 32 bit binary resource files and the
 * individual resources within them. Also provides supporting routines and
 * constants.
}


unit PJResFile;


{
  NOTES
  =====

  This unit defines classes that encapsulate the Windows 32 bit resource file
  format.

  BINARY RESOURCE FILE FORMAT
  ---------------------------

  A 32 bit resource file is comprised as follows:
    +--------------+
    | File header  |
    +--------------+
    | Resource 1   |
    +--------------+
    | Padding      |
    +--------------+
    | Resource 2   |
    +--------------+
    | Padding      |
    +--------------+
    ...          ...
    +--------------+
    | Resource N   |
    +--------------+
    | Padding      |
    +--------------+

  The File header is a "pseudo-resource" that identifies the file as a 32 bit
  resource file (rather than a 16 bit file). This is a 32 byte structure, the
  first 8 bytes of which are $00, $00, $00, $00, $20, $00, $00, $00.

  Each resource is made up of a variable length header record followed by the
  resource data.

  A resource file header is made up of the following fields:

    DataSize: DWORD;            // size of resource data (excluding end padding)
    HeaderSize: DWORD;          // size of resource data header
    Type: Unicode or Ordinal;   // type of resource
    Name: Unicode or Ordinal;   // name of resource
    [Padding: Word];            // padding to DWORD boundary, if needed
    DataVersion: DWORD;         // version of the data resource
    MemoryFlags: Word;          // describes the state of the resource
    LanguageId: Word;           // language for the resource
    Version: DWORD;             // user defined resource version
    Characteristics: DWORD;     // user defined info about resource

  The resource name and type can either be a #0#0 terminated Unicode string or
  can be an ordinal word value (preceded by a $FFFF word). If Type or Name is a
  Unicode string then an additional padding word may be needed after the Name
  "field" to ensure the following field start on a DWORD boundary. (The name
  field doesn't have to be DWORD aligned so there is no padding between the Type
  and Name "fields").

  Each resource starts on a DWORD boundary, so there may be padding bytes
  following the resource data if it is not a multiple of 4 bytes in length.

  IMPLEMENTATION NOTES
  --------------------

  Although the word "file" is used in these notes, this term also covers binary
  resource data stored in a stream.

  Two classes are used to encapsulate a resource file:

    + TPJResourceFile
      Encapsulates the whole file and has methods to load and save resource
      files, to add and delete resources and to find out information about the
      resources contained in the file.

    + TPJResourceEntry
      Encapsulates a single resource with a resource file. It exposes properties
      that give access to all the fields of the resource header and provides a
      stream onto the resource's data. Methods to check whether the resource
      matches certain criteria are also provided.

  While TPJResourceFile is a concrete class, TPJResourceEntry is abstract - it
  is used as an interface to actual concrete resource entry instances maintained
  internally by TPJResourceFile. This approach is used because instances of
  TPJResourceEntry must not be directly instantiated: all resources are "owned"
  by a resource file object. New instances of resource entry objects are created
  internally by TPJResourceFile in response to methods and constructors.

  Since the resource type and name identifiers are variable length we can't use
  a standard Pascal record to represent a resource header. Instead we use two
  fixed length packed records:
    TResEntryHdrPefix:  the DataSize and HeaderSize fields.
    TResEntryHdrSuffix: the DataVersion through to Characteristics fields.
  We handle the resource type and name "fields" (and any padding) separately.

  When interrogating or accessing Windows resources using the Windows API
  resource types and names are specified either as #0 terminated strings
  or as ordinal values as returned from the MakeIntResource "macro". This
  convention is also used by the TPJResourceFile and TPJResourceEntry classes -
  the methods that take resource identifiers as parameters all expect them to be
  in this form. Note that 32 bit resource files use the Unicode or Ordinal
  format described in the Binary Resource File Format section above. The classes
  convert from the resource file format to and from the API format on saving and
  loading resource files.
}


{$UNDEF UseAnsiStrIComp}
{$UNDEF UseRTLNameSpaces}
{$UNDEF SupportsTBytes}
{$IFDEF CONDITIONALEXPRESSIONS}
  {$IF CompilerVersion >= 24.0} // Delphi XE3 and later
    {$LEGACYIFEND ON}  // NOTE: this must come before all $IFEND directives
  {$IFEND}
  {$IF CompilerVersion >= 23.0} // Delphi XE2 and later
    {$DEFINE UseRTLNameSpaces}
  {$IFEND}
  {$IF CompilerVersion >= 18.5} // Delphi 2007 and later
    {$DEFINE SupportsTBytes}
  {$IFEND}
  {$IF CompilerVersion >= 15.0} // Delphi 7 and later
    {$WARN UNSAFE_TYPE OFF}
    {$WARN UNSAFE_CAST OFF}
    {$WARN UNSAFE_CODE OFF}
  {$IFEND}
  {$IF CompilerVersion >= 14.0} // Delphi 6 and later
    {$DEFINE UseAnsiStrIComp}
  {$IFEND}
{$ENDIF}


interface


uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  SysUtils,
  Classes;

const
  // Memory flags constants - used in MemoryFlags field of resource header
  // These flags can be ORd together as a bit-mask
  RES_MF_MOVEABLE     = $0010;                // can move resource in memory
  RES_MF_PURE         = $0020;                // resource data is DWORD aligned
  RES_MF_PRELOAD      = $0040;                // must load after app loads
  RES_MF_DISCARDABLE  = $1000;                // can be unloaded if memory low
  // These flags can be ANDed with bit-mask to remove complementary flag
  RES_MF_FIXED        = not RES_MF_MOVEABLE;  // can't move resource in memory
  RES_MF_IMPURE       = not RES_MF_PURE;      // data not aligned: needs padding
  RES_MF_LOADONCALL   = not RES_MF_PRELOAD;   // load only when app accesses
  // NOTE: RES_MF_MOVEABLE, RES_MF_IMPURE and RES_MF_PRELOAD ignored by Win NT

  // System resource types not defined in Delphi Windows unit for some supported
  // Delphis
  RT_HTML             = MAKEINTRESOURCE(23);  // HTML resources
  RT_MANIFEST         = MAKEINTRESOURCE(24);  // XP manifest resource


type

  {$IFNDEF SupportsTBytes}
  // Byte array used as type of TPJResourceEntry.DataBytes property.
  TBytes = array of Byte;
  {$ENDIF}

  TPJResourceEntry = class;

  ///  <summary>Enumerator for the resource entries contained in a
  ///  TPJResourceFile object.</summary>
  ///  <remarks>
  ///  <para>For Delphi 2005 and later, this enumerator, along with
  ///  TPJResourceFile's GetEnumerator method, enables use of the for..in loops
  ///  to enumerate resource entries.</para>
  ///  <para>For Delphi 7 and earlier the enumerator can still be used, but must
  ///  be created by calling the TPJResourceFile.GetEnumerator method. A while
  ///  loop is used to perform the enumeration, calling the enumerator's
  ///  MoveNext and GetCurrent methods. The enumerator object must be freed when
  ///  the enumeration is completed.</para>
  ///  </remarks>
  TPJResourceFileEnumerator = class(TObject)
  private
    ///  <summary>Index of current item in enumeration.</summary>
    fIndex: Integer;
    ///  <summary>List of resource entries being enumerated.</summary>
    fEntries: TList;
  public
    ///  <summary>Constructs a new instance of the enumerator for the given
    ///  list of resource entries.</summary>
    ///  <remarks>This constructor is not designed to be called directly by
    ///  users. It is for internal use by TPJResourceFile instances. To create
    ///  an enumerator users should instead call TPJResourceFile.GetEnumerator.
    ///  </remarks>
    constructor Create(const Entries: TList);
    ///  <summary>Moves to the next entry in the enumeration if possible.
    ///  Returns True if there is a "next" entry or False if the enumeration has
    ///  completed and no more entries are available.</summary>
    ///  <remarks>The first call to this method in a new enumeration makes the
    ///  first item in the enumeration available.</remarks>
    function MoveNext: Boolean;
    ///  <summary>Returns a reference to the current entry in the enumeration.
    ///  </summary>
    ///  <exception>An exception will be raised if MoveNext has not been called
    ///  at least once before calling GetCurrent.</exception>
    ///  <remarks>This method must not be called after the enumeration has
    ///  completed. Check the value returned by MoveNext before calling this
    ///  method.</remarks>
    function GetCurrent: TPJResourceEntry;
    ///  <summary>Returns a reference to the current entry in the enumeration.
    ///  </summary>
    ///  <exception>An exception will be raised if MoveNext has not been called
    ///  at least once before calling Current.</exception>
    ///  <remarks>This property is an alias of the GetCurrent method.</remarks>
    property Current: TPJResourceEntry read GetCurrent;
  end;

  ///  <summary>Class that encapsulates a 32 bit binary resource file and
  ///  exposes the entries within it.</summary>
  ///  <remarks>This class allows reading, creation and editing of resource
  ///  files.</remarks>
  TPJResourceFile = class(TObject)
  private
    ///  <summary>Maintains list of all resource entries.</summary>
    fEntries: TList;
    ///  <summary>Read accessor for Entries[] property.</summary>
    function GetEntry(Idx: Integer): TPJResourceEntry;
    ///  <summary>Read accessor for EntryCount property.</summary>
    function GetEntryCount: Integer;
  public
    ///  <summary>Constructs a new, empty, resource file object instance.
    ///  </summary>
    constructor Create;
    ///  <summary>Destroys the current object instance.</summary>
    ///  <remarks>All resources in the Entries[] list are freed.</remarks>
    destructor Destroy; override;
    ///  <summary>Creates and returns a new enumerator for the resource entries.
    ///  </summary>
    ///  <remarks>Designed for internal use to enabled for..in enumerations on
    ///  TPJResourceFile. If used directly the caller is responsible for freeing
    ///  the enumerator object.</remarks>
    function GetEnumerator: TPJResourceFileEnumerator;
    ///  <summary>Clears all resources from the Entries[] list.</summary>
    ///  <remarks>All resource entry objects are freed.</remarks>
    procedure Clear;
    ///  <summary>Deletes the given resource entry from the Entries[] list and
    ///  returns True if the entry was found and deleted or False if the entry
    ///  was not found.</summary>
    function DeleteEntry(const Entry: TPJResourceEntry): Boolean;
    ///  <summary>Returns the index of the given resource entry in the Entries[]
    ///  list or -1 if the entry is not in the list.</summary>
    function IndexOfEntry(const Entry: TPJResourceEntry): Integer;
    ///  <summary>Loads resources from the given resource file.</summary>
    ///  <exception>EPJResourceFile raised if the file is not a valid 32 bit
    ///  resource file.</exception>
    ///  <exception>EFCreateError raised if the file is does not exist or can't
    ///  be opened.</exception>
    procedure LoadFromFile(const FileName: TFileName);
    ///  <summary>Loads resources from the current position in the given stream.
    ///  </summary>
    ///  <exception>EPJResourceFile raised if the stream does not contain a
    ///  valid 32 bit resource.</exception>
    procedure LoadFromStream(const Stm: TStream);
    ///  <summary>Saves the resources in the Entries[] to the given file in 32
    ///  bit resource file format.</summary>
    procedure SaveToFile(const FileName: TFileName);
    ///  <summary>Saves the resources in the Entries[] to the given stream in 32
    ///  bit resource file format.</summary>
    procedure SaveToStream(const Stm: TStream);
    ///  <summary>Checks if the given stream contains data in valid 32 bit
    ///  resource file format starting from the current stream position.
    ///  </summary>
    class function IsValidResourceStream(const Stm: TStream): Boolean;
    ///  <summary>Adds new empty resource entry to the Entries[] list.</summary>
    ///  <param name="ResType">PChar [in] Type of new resource (in ordinal or
    ///  string format).</param>
    ///  <param name="ResName">PChar [in] Name of new resource (in ordinal or
    ///  string format).</param>
    ///  <param name="LangID">Word [in] Language ID of new resource. 0 (the
    ///  default) indicates the resource is language neutral.</param>
    ///  <returns>TPJResourceEntry. Reference to the new resource entry.
    ///  </returns>
    ///  <exception>EPJResourceFile raised if an entry already exists with same
    ///  type, name and language ID.</exception>
    function AddEntry(const ResType, ResName: PChar;
      const LangID: Word = 0): TPJResourceEntry; overload;
    ///  <summary>Adds a copy of a given resource entry with the same type and
    ///  given name and language ID to the Entries[] list.</summary>
    ///  <param name="Entry">TPJResourceEntry [in] Resource entry to be copied.
    ///  </param>
    ///  <param name="ResName">PChar [in] Name of new resource (in ordinal or
    ///  string format).</param>
    ///  <param name="LangID">Word [in] Language ID of new resource. 0 (the
    ///  default) indicates the resource is language neutral.</param>
    ///  <returns>TPJResourceEntry. Reference to the new resource entry.
    ///  </returns>
    ///  <exception>EPJResourceFile raised if an entry already exists with same
    ///  type, name and language ID.</exception>
    function AddEntry(const Entry: TPJResourceEntry; const ResName: PChar;
      const LangID: Word = 0): TPJResourceEntry; overload;
    ///  <summary>Finds and returns the first resource in the Entries[] list
    ///  that matches a given set of properties.</summary>
    ///  <param name="ResType">PChar [in] Required resource type (in ordinal or
    ///  string format.</param>
    ///  <param name="ResName">PChar [in] Required resource name (in ordinal or
    ///  string format. If ResName is nil them a resource with any name matches.
    ///  </param>
    ///  <param name="LangID">Word [in] Required resource Language ID. If LangId
    ///  is $FFFF then a resource with any Language ID matches.</param>
    ///  <returns>TPJResourceEntry. Reference to found resource entry or nil if
    ///  there is no matching resource.</returns>
    function FindEntry(const ResType, ResName: PChar;
      const LangID: Word = $FFFF): TPJResourceEntry;
    ///  <summary>Finds and returns the index of the first resource in the
    ///  Entries[] list that matches a given set of properties.</summary>
    ///  <param name="ResType">PChar [in] Required resource type (in ordinal or
    ///  string format.</param>
    ///  <param name="ResName">PChar [in] Required resource name (in ordinal or
    ///  string format. If ResName is nil them a resource with any name matches.
    ///  </param>
    ///  <param name="LangID">Word [in] Required resource Language ID. If LangId
    ///  is $FFFF then a resource with any Language ID matches.</param>
    ///  <returns>Integer. Index of found resource entry or -1 if there is no
    ///  matching resource.</returns>
    function FindEntryIndex(const ResType, ResName: PChar;
      const LangID: Word = $FFFF): Integer;
    ///  <summary>Checks if a resource entry exists in the Entries[] list that
    ///  matches a given set of properties.</summary>
    ///  <param name="ResType">PChar [in] Required resource type (in ordinal or
    ///  string format.</param>
    ///  <param name="ResName">PChar [in] Required resource name (in ordinal or
    ///  string format. If ResName is nil them a resource with any name matches.
    ///  </param>
    ///  <param name="LangID">Word [in] Required resource Language ID. If LangId
    ///  is $FFFF then a resource with any Language ID matches.</param>
    ///  <returns>Boolean. True if a matching resource entry was found or False
    ///  if not.</returns>
    function EntryExists(const ResType, ResName: PChar;
      const LangID: Word = $FFFF): Boolean;
    ///  <summary>The number of resources in the Entries[] list.</summary>
    property EntryCount: Integer read GetEntryCount;
    ///  <summary>A list of contained resources.</summary>
    property Entries[Idx: Integer]: TPJResourceEntry read GetEntry;
  end;


  ///  <summary>Pure abstract class that encapsulates an entry in a resource
  ///  file.</summary>
  ///  <remarks>This class should not be directly instantiated but should be
  ///  used to reference resource entry objects created internally by
  ///  TPJResourceFile.</remarks>
  TPJResourceEntry = class(TObject)
  protected
    // abstract property access methods
    function GetCharacteristics: DWORD; virtual; abstract;
    procedure SetCharacteristics(const Value: DWORD); virtual; abstract;
    function GetData: TStream; virtual; abstract;
    function GetDataSize: DWORD; virtual; abstract;
    function GetDataVersion: DWORD; virtual; abstract;
    procedure SetDataVersion(const Value: DWORD); virtual; abstract;
    function GetHeaderSize: DWORD; virtual; abstract;
    function GetLanguageID: Word; virtual; abstract;
    function GetMemoryFlags: Word; virtual; abstract;
    procedure SetMemoryFlags(const Value: Word); virtual; abstract;
    function GetResName: PChar; virtual; abstract;
    function GetResType: PChar; virtual; abstract;
    function GetVersion: DWORD; virtual; abstract;
    procedure SetVersion(const Value: DWORD); virtual; abstract;
    function GetDataBytes: TBytes; virtual; abstract;
    procedure SetDataBytes(const Value: TBytes); virtual; abstract;
  public
    ///  <summary>Checks if this resource matches a given set of properties.
    ///  </summary>
    ///  <param name="ResType">PChar [in] Required resource type (in ordinal or
    ///  string format).</param>
    ///  <param name="ResName">PChar [in] Required resource name (in ordinal or
    ///  string format). If ResName is nil them a resource with any name
    ///  matches.</param>
    ///  <param name="LangID">Word [in] Required resource Language ID. If LangId
    ///  is $FFFF then a resource with any Language ID matches.</param>
    ///  <returns>Boolean. True if a match was found or False if not.</returns>
    function IsMatching(const ResType, ResName: PChar;
      const LangID: Word = $FFFF): Boolean; overload; virtual; abstract;
    ///  <summary>Checks if this resource matches another resource.</summary>
    ///  <param name="Entry">TPJResourceEntry [in] Resource to match.</param>
    ///  <returns>Boolean. True if this resource and Entry have the same type,
    ///  name and language ID.</returns>
    function IsMatching(const Entry: TPJResourceEntry): Boolean; overload;
      virtual; abstract;
    ///  <summary>Loads the contents of a file into the resource's raw data.
    ///  </summary>
    ///  <param name="SrcFileName">TFileName [in] Name of the file to be loaded.
    ///  </param>
    ///  <param name="Append">Boolean [in] Indicates whether file contents
    ///  should be appended to the existing data (True) or whether it should
    ///  overwrite it (False).</param>
    ///  <remarks>The data stream pointer is reset to 0 on completion.</remarks>
    procedure LoadDataFromFile(const SrcFileName: TFileName;
      const Append: Boolean); virtual; abstract;
    ///  <summary>Deletes all the resource's raw data.</summary>
    ///  <remarks>After calling this method the value of DataSize is zero.
    ///  </remarks>
    procedure ClearData; virtual; abstract;
    ///  <summary>Size of resource data, excluding padding.</summary>
    property DataSize: DWORD read GetDataSize;
    ///  <summary>Size of resource header record including internal padding.
    ///  </summary>
    property HeaderSize: DWORD read GetHeaderSize;
    ///  <summary>Predefined data resource version information.</summary>
    property DataVersion: DWORD read GetDataVersion write SetDataVersion;
    ///  <summary>Attribute bit-mask specifying state of resource.</summary>
    property MemoryFlags: Word read GetMemoryFlags write SetMemoryFlags;
    ///  <summary>The resource's language identifier.</summary>
    ///  <remarks>A value of 0 indicates the resource is language neutral.
    ///  </remarks>
    property LanguageID: Word read GetLanguageID;
    ///  <summary>User specified version number for resource data.</summary>
    property Version: DWORD read GetVersion write SetVersion;
    ///  <summary>Additional user defined resource information.</summary>
    property Characteristics: DWORD read GetCharacteristics
      write SetCharacteristics;
    ///  <summary>Name of resource.</summary>
    ///  <remarks>Can have a string or ordinal value.</remarks>
    property ResName: PChar read GetResName;
    ///  <summary>Type of resource.</summary>
    ///  <remarks>Can have a string or ordinal value.</remarks>
    property ResType: PChar read GetResType;
    ///  <summary>Stream containing raw resource data excluding padding.
    ///  </summary>
    property Data: TStream read GetData;
    ///  <summary>Raw resource data as a byte array.</summary>
    ///  <remarks>When the property is read a copy of the raw data is returned.
    ///  When the property is written the entry's raw data is replaced by a copy
    ///  of the byte array assigned to the property and the Data stream position
    ///  is set to the start of the stream.</remarks>
    property DataBytes: TBytes read GetDataBytes write SetDataBytes;
  end;

  ///  <summary>Class of exception raised by objects in this unit.</summary>
  EPJResourceFile = class(Exception);

///  <summary>Checks if the given resource ID is numeric.</summary>
function IsIntResource(const ResID: PChar): Boolean;

///  <summary>Checks whether two given resource IDs and equal.</summary>
function IsEqualResID(const R1, R2: PChar): Boolean;

///  <summary>Converts the given resource ID into its string representation.
///  </summary>
///  <remarks>If resource ID is an ordinal the ordinal number preceded by '#' is
///  returned, otherwise the string itself is returned.</remarks>
function ResIDToStr(const ResID: PChar): string;


implementation


type
  ///  <summary>Record that stores the fixed length fields that precede the
  ///  variable length type and name records in a resource header.</summary>
  TResEntryHdrPrefix = packed record
    ///  <summary>Size of resource data (excluding end padding).</summary>
    DataSize: DWORD;
    ///  <summary>Size of resource data header.</summary>
    HeaderSize: DWORD;
  end;

  ///  <summary>Record that stores the fixed length fields that follow the
  ///  variable length type and name records in a resource header.</summary>
  TResEntryHdrSuffix = packed record
    ///  <summary>Version of the data resource.</summary>
    DataVersion: DWORD;
    ///  <summary>Describes the state of the resource.</summary>
    MemoryFlags: Word;
    ///  <summary>ID of the resource's language.</summary>
    LanguageID: Word;
    ///  <summary>User defined resource version.</summary>
    Version: DWORD;
    ///  <summary>User defined infornation about resource.</summary>
    Characteristics: DWORD;
  end;

  ///  <summary>Implementation of the abstract TPJResourceEntry class that
  ///  encapsulates an entry in a resource file.</summary>
  TInternalResEntry = class(TPJResourceEntry)
  private
    ///  <summary>Stores or points to resource name.</summary>
    fResName: PChar;
    ///  <summary>Stores or points to resource type.</summary>
    fResType: PChar;
    ///  <summary>Fixed length fields that follow variable size fields of a the
    ///  resource header.</summary>
    fHdrSuffix: TResEntryHdrSuffix;
    ///  <summary>Stream that stores entry's raw resource data.</summary>
    fDataStream: TStream;
    ///  <summary>Reference to TPJResourceFile instance that contains and owns
    ///  this resource entry.</summary>
    fOwner: TPJResourceFile;
    ///  <summary>Initialises a resource entry object as belonging to the given
    ///  TPJResourceFile instance.</summary>
    ///  <remarks>This is a helper method called from constructors.</remarks>
    procedure Init(const Owner: TPJResourceFile);
    ///  <summary>Finalises the given resource identifier, releasing any memory
    ///  it has allocated and sets the identifier to nil.</summary>
    procedure FinaliseResID(var ResID: PChar);
    ///  <summary>Copies one resource identifier to another, taking care of any
    ///  necessary memory allocation.</summary>
    ///  <param name="Dest">PChar [in/out] Identifier that receives the copied
    ///  resource identifier. If Src is ordinal Dest is set to the value of Src.
    ///  If Src is a string then the string is copied and Dest is set to point
    ///  to the copy.</param>
    ///  <param name="Src">PChar [in] Identifier to be copied.</param>
    ///  <remarks>Dest is finalised before being modified.</remarks>
    procedure CopyResID(var Dest: PChar; const Src: PChar);
  protected
    ///  <summary>Gets value of Characteristics field from resource header.
    ///  </summary>
    function GetCharacteristics: DWORD; override;
    ///  <summary>Sets value of Characteristics field in resource header.
    ///  </summary>
    procedure SetCharacteristics(const Value: DWORD); override;
    ///  <summary>Gets reference to resource's raw data stream.</summary>
    function GetData: TStream; override;
    ///  <summary>Gets the size of the resource data, excluding any padding.
    ///  </summary>
    function GetDataSize: DWORD; override;
    ///  <summary>Gets value of Version field from resource header.</summary>
    function GetDataVersion: DWORD; override;
    ///  <summary>Sets value of Version field in resource header.</summary>
    procedure SetDataVersion(const Value: DWORD); override;
    ///  <summary>Returns size of variable length resource header.</summary>
    function GetHeaderSize: DWORD; override;
    ///  <summary>Gets value of LanguageID field from resource header.</summary>
    function GetLanguageID: Word; override;
    ///  <summary>Gets value of MemoryFlags field from resource header.
    ///  </summary>
    function GetMemoryFlags: Word; override;
    ///  <summary>Sets value of MemoryFlags field in resource header.</summary>
    procedure SetMemoryFlags(const Value: Word); override;
    ///  <summary>Gets name of resource as either a string pointer or an ordinal
    ///  value.</summary>
    function GetResName: PChar; override;
    ///  <summary>Gets type of resource as either a string pointer or an ordinal
    ///  value.</summary>
    function GetResType: PChar; override;
    ///  <summary>Gets value of Version field from resource header.</summary>
    function GetVersion: DWORD; override;
    ///  <summary>Sets value if Version field in resource header.</summary>
    procedure SetVersion(const Value: DWORD); override;
    ///  <summary>Returns a byte array containing a copy of the resource's raw
    ///  data.</summary>
    function GetDataBytes: TBytes; override;
    ///  <summary>Replaces the resource's raw data with a copy of the given byte
    ///  array.</summary>
    procedure SetDataBytes(const Value: TBytes); override;
  public
    ///  <summary>Constructs a new resource entry instance with the given
    ///  properties within a given resource file object.</summary>
    ///  <param name="Owner">TPJResourceFile [in] Resource "file" to which this
    ///  resource entry belongs.</param>
    ///  <param name="ResType">PChar [in] Type of new resource.</param>
    ///  <param name="ResName">PChar [in] Name of new resource.</param>
    ///  <param name="LangID">Word [in] Language ID of new resource.</param>
    ///  <remarks>This constructor is called by the owning TPJResourceFile
    ///  instance when it needs to create a new entry. Users should not call
    ///  this constructor directly.</remarks>
    constructor Create(const Owner: TPJResourceFile;
      const ResType, ResName: PChar; LangID: Word); overload;
    ///  <summary>Creates a new resource entry instance from the data stored in
    ///  a stream.</summary>
    ///  <param name="Owner">TPJResourceFile [in] Resource "file" to which this
    ///  resource entry belongs.</param>
    ///  <param name="Stm">TStream [in] Stream containing a binary
    ///  representation of the resource. The data in the stream must be in the
    ///  correct 32 bit resource format.</param>
    ///  <remarks>This constructor is called by the owning TPJResourceFile
    ///  instance when it needs to create a new entry from data in a stream.
    ///  Users should not call this constructor directly.</remarks>
    constructor Create(const Owner: TPJResourceFile;
      const Stm: TStream); overload;
    ///  <summary>Destroys the current resource instance.</summary>
    destructor Destroy; override;
    ///  <summary>Write the resource entry to the given stream in 32 bit
    ///  resource format.</summary>
    procedure WriteToStream(Stm: TStream);
    ///  <summary>Checks if this resource matches a given set of properties.
    ///  </summary>
    ///  <param name="ResType">PChar [in] Required resource type (in ordinal or
    ///  string format).</param>
    ///  <param name="ResName">PChar [in] Required resource name (in ordinal or
    ///  string format). If ResName is nil them a resource with any name
    ///  matches.</param>
    ///  <param name="LangID">Word [in] Required resource Language ID. If LangId
    ///  is $FFFF then a resource with any Language ID matches.</param>
    ///  <returns>Boolean. True if a match was found or False if not.</returns>
    function IsMatching(const ResType, ResName: PChar;
      const LangID: Word = $FFFF): Boolean; overload; override;
    ///  <summary>Checks if this resource matches another resource.</summary>
    ///  <param name="Entry">TPJResourceEntry [in] Resource to match.</param>
    ///  <returns>Boolean. True if this resource and Entry have the same type,
    ///  name and language ID.</returns>
    function IsMatching(const Entry: TPJResourceEntry): Boolean; overload;
      override;
    ///  <summary>Loads the contents of a file into the resource's raw data.
    ///  </summary>
    ///  <param name="SrcFileName">TFileName [in] Name of the file to be loaded.
    ///  </param>
    ///  <param name="Append">Boolean [in] Indicates whether file contents
    ///  should be appended to the existing data (True) or whether it should
    ///  overwrite it (False).</param>
    ///  <remarks>The data stream pointer is reset to 0 on completion.</remarks>
    procedure LoadDataFromFile(const SrcFileName: TFileName;
      const Append: Boolean); override;
    ///  <summary>Deletes all the resource's raw data.</summary>
    ///  <remarks>After calling this method the value of DataSize is zero.
    ///  </remarks>
    procedure ClearData; override;
  end;

resourcestring
  // Error messages
  sErrBadResFile      = 'Invalid 32 bit resource file';
  sErrDupResEntry     = 'Duplicate entry: can''t add to resource file';
  sErrEndOfStream     = 'Unexpected end of stream when reading resource entry';
  sErrCorruptHeader   = 'Encountered corrupt header size field when reading '
                      + 'resource header';
  sErrHeaderCalc      = 'Error calculating header size while writing resource '
                      + 'entry';
  sErrResWrite        = 'Error writing resource data to stream';

// Helper routines

function IsIntResource(const ResID: PChar): Boolean;
begin
  Result :=
    {$IFDEF FPC}
      LongRec(DWORD(ResID)).Hi = 0;
    {$ELSE}
      HiWord(DWORD(ResID)) = 0;
    {$ENDIF}
end;

function ResIDToStr(const ResID: PChar): string;
begin
  if IsIntResource(ResID) then
    Result := '#' +
      {$IFDEF FPC}
        IntToStr(LongRec(DWORD(ResID)).Lo)
      {$ELSE}
        IntToStr(LoWord(DWORD(ResID)))
      {$ENDIF}
  else
    Result := ResID;
end;

function IsEqualResID(const R1, R2: PChar): Boolean;
begin
  if IsIntResource(R1) then
    // R1 is ordinal: R2 must also be ordinal with same value in lo word
    Result := IsIntResource(R2) and
      {$IFDEF FPC}
        (LongRec(DWORD(R1)).Lo = LongRec(DWORD(R2)).Lo)
      {$ELSE}
        (LoWord(DWORD(R1)) = LoWord(DWORD(R2)))
      {$ENDIF}
  else
    // R1 is string pointer: R2 must be same string (ignoring case)
    Result := not IsIntResource(R2) and (StrIComp(R1, R2) = 0);
end;

{ TInternalResEntry }

procedure TInternalResEntry.ClearData;
begin
  fDataStream.Size := 0;
end;

procedure TInternalResEntry.CopyResID(var Dest: PChar; const Src: PChar);
begin
  // Clear up the old destination identifier
  FinaliseResID(Dest);  // Dest is set to nil here
  if IsIntResource(Src) then
    // Ordinal value: store in Dest
    Dest := Src
  else
    // String value: make Dest point to copy of string
    Dest := StrNew(Src);
end;

constructor TInternalResEntry.Create(const Owner: TPJResourceFile;
  const Stm: TStream);

  // Reads a value from the stream and count of total bytes read. Raises
  // exception if all required bytes can't be read.
  procedure Read(out Value; const Size: Integer; var BytesRead: Integer);
  begin
    // Read stream and check all expected bytes read
    if Stm.Read(Value, Size) <> Size then
      raise EPJResourceFile.Create(sErrEndOfStream);
    // Update count of total bytes read
    Inc(BytesRead, Size);
  end;

  // Reads zero of more bytes from the stream until the number of bytes read is
  // a multiple of the size of a DWORD.
  procedure SkipToBoundary(var BytesRead: Integer);
  var
    SkipBytes: Integer; // number of bytes to skip
    Dummy: DWORD;       // temp store for bytes read
  begin
    if BytesRead mod SizeOf(DWORD) <> 0 then
    begin
      SkipBytes := SizeOf(DWORD) - BytesRead mod SizeOf(DWORD);
      Read(Dummy, SkipBytes, BytesRead);
    end;
  end;

  // Reads a resource identifier from the stream and updates the total bytes
  // read.
  procedure ReadResID(out ResID: PChar; var BytesRead: Integer);
  var
    Ch: WideChar;     // store wide chars read from stream
    Str: WideString;  // string resource id
    {$IFDEF FPC}
    AnsiStr: AnsiString;
    {$ENDIF}
  begin
    Assert(SizeOf(Word) = SizeOf(WideChar));
    // Read first WideChar: determines type of resource id
    Read(Ch, SizeOf(Ch), BytesRead);
    if Ord(Ch) = $FFFF then
    begin
      // First char is $FFFF so this is ordinal resource id
      // next character contains resource id: stored in out parameter
      Read(Ch, SizeOf(Ch), BytesRead);
      CopyResID(ResID, MakeIntResource(Ord(Ch)));
    end
    else
    begin
      // First char not $FFFF so this is string resource id
      // we read each character into string until zero char encountered
      Str := Ch;
      Read(Ch, SizeOf(Ch), BytesRead);
      while Ord(Ch) <> 0 do
      begin
        Str := Str + Ch;
        Read(Ch, SizeOf(Ch), BytesRead);
      end;
      {$IFNDEF FPC}
      // we now copy resource string, converted to string, to resource id
      // *** there would be a shorter way than this when string = UnicodeString,
      //     but this is needed for string = AnsiString and works for both.
      CopyResID(ResID, PChar(WideCharToString(PWideChar(Str))));
      {$ELSE}
      WideCharToStrVar(PWideChar(Str), AnsiStr);
      CopyResID(ResID, PChar(AnsiStr));
      {$ENDIF}
    end;
  end;

var
  BytesRead: Integer;             // total # of bytes read from stream
  HdrPrefix: TResEntryHdrPrefix;  // fixed size resource header prefix
begin
  // Initialise new object
  Init(Owner);
  // Read header
  // start counting bytes
  BytesRead := 0;
  // read fixed header prefix
  Read(HdrPrefix, SizeOf(HdrPrefix), BytesRead);
  // read variable type and name resource ids then skip to DWORD boundary
  ReadResID(fResType, BytesRead);
  ReadResID(fResName, BytesRead);
  SkipToBoundary(BytesRead);
  // read fixed header suffix
  Read(fHdrSuffix, SizeOf(fHdrSuffix), BytesRead);
  // check header length was as expected
  if Int64(BytesRead) <> Int64(HdrPrefix.HeaderSize) then
    raise EPJResourceFile.Create(sErrCorruptHeader);
  // Read any resource data into data stream
  if HdrPrefix.DataSize > 0 then
  begin
    // check stream is large enough for expected data
    if Stm.Size < Stm.Position + Int64(HdrPrefix.DataSize) then
      raise EPJResourceFile.Create(sErrEndOfStream);
    // copy data from input stream into resource data stream & reset it
    fDataStream.CopyFrom(Stm, HdrPrefix.DataSize);
    fDataStream.Position := 0;
    Inc(BytesRead, HdrPrefix.DataSize);
    // skip any padding bytes following resource data
    SkipToBoundary(BytesRead);
  end;
end;

constructor TInternalResEntry.Create(const Owner: TPJResourceFile;
  const ResType, ResName: PChar; LangID: Word);
begin
  // Initialise new object
  Init(Owner);
  // Store type and name resource ids
  CopyResID(fResType, ResType);
  CopyResID(fResName, ResName);
  // Record language id
  fHdrSuffix.LanguageID := LangID;
end;

destructor TInternalResEntry.Destroy;
begin
  // Free resource identifier storage
  FinaliseResID(fResType);
  FinaliseResID(fResName);
  // Free resource data stream
  fDataStream.Free;
  // Delete from owner list
  if Assigned(fOwner) then
    fOwner.DeleteEntry(Self);
  inherited;
end;

procedure TInternalResEntry.FinaliseResID(var ResID: PChar);
begin
  // Check resource id not already finalised
  if Assigned(ResID) then
  begin
    if not IsIntResource(ResID) then
      // This is string resource: free the string's memory
      StrDispose(ResID);
    // Zero the identifier
    ResID := nil;
  end;
end;

function TInternalResEntry.GetCharacteristics: DWORD;
begin
  Result := fHdrSuffix.Characteristics;
end;

function TInternalResEntry.GetData: TStream;
begin
  Result := fDataStream;
end;

function TInternalResEntry.GetDataBytes: TBytes;
var
  SavedStreamPos: Int64;
begin
  SavedStreamPos := fDataStream.Position;
  fDataStream.Position := 0;
  SetLength(Result, fDataStream.Size);
  if fDataStream.Size > 0 then
    fDataStream.ReadBuffer(Pointer(Result)^, Length(Result));
  fDataStream.Position := SavedStreamPos;
end;

function TInternalResEntry.GetDataSize: DWORD;
begin
  Result := fDataStream.Size;
end;

function TInternalResEntry.GetDataVersion: DWORD;
begin
  Result := fHdrSuffix.DataVersion;
end;

function TInternalResEntry.GetHeaderSize: DWORD;

  // Calculates size of given resource identifier in bytes.
  function ResIDSize(const ResID: PChar): Integer;
  begin
    if IsIntResource(ResID) then
      // Ordinal resource id: want size of a DWORD
      Result := SizeOf(DWORD)
    else
      // String resource id: want length of string in WideChars + terminating
      // zero WideChar
      Result := (StrLen(ResID) + 1) * SizeOf(WideChar);
  end;

begin
  Assert(SizeOf(WideChar) = SizeOf(Word));
  // Add up size of fixed and variable parts of header
  Result := SizeOf(TResEntryHdrPrefix) + SizeOf(TResEntryHdrSuffix) +
    ResIDSize(fResType) + ResIDSize(fResName);
  // Round up to multiple of DWORD if required
  Assert(Result mod SizeOf(Word) = 0);
  if Result mod SizeOf(DWORD) <> 0 then
    Inc(Result, SizeOf(Word));
end;

function TInternalResEntry.GetLanguageID: Word;
begin
  Result := fHdrSuffix.LanguageID;
end;

function TInternalResEntry.GetMemoryFlags: Word;
begin
  Result := fHdrSuffix.MemoryFlags;
end;

function TInternalResEntry.GetResName: PChar;
begin
  Result := fResName;
end;

function TInternalResEntry.GetResType: PChar;
begin
  Result := fResType;
end;

function TInternalResEntry.GetVersion: DWORD;
begin
  Result := fHdrSuffix.Version;
end;

procedure TInternalResEntry.Init(const Owner: TPJResourceFile);
begin
  Assert(Assigned(Owner));
  inherited Create;
  // Record owner
  fOwner := Owner;
  // Create stream to hold resource data
  fDataStream := TMemoryStream.Create;
  // Clear all field in resource header suffix
  FillChar(fHdrSuffix, SizeOf(fHdrSuffix), 0);
end;

function TInternalResEntry.IsMatching(const ResType, ResName: PChar;
  const LangID: Word = $FFFF): Boolean;
begin
  // Check if types are same
  Result := IsEqualResID(ResType, Self.ResType);
  if Assigned(ResName) then
    // ResName is assigned so check names are same
    Result := Result and IsEqualResID(ResName, Self.ResName);
  if LangID <> $FFFF then
    // Language ID is provided so check languages are same
    Result := Result and (LangID = Self.LanguageID);
end;

function TInternalResEntry.IsMatching(const Entry: TPJResourceEntry): Boolean;
begin
  // Check that entry's resource type & name and language matches ours
  Result := IsMatching(Entry.ResType, Entry.ResName, Entry.LanguageID);
end;

procedure TInternalResEntry.LoadDataFromFile(const SrcFileName: TFileName;
  const Append: Boolean);
var
  SrcStm: TFileStream;  // stream onto source file
begin
  // Copy source file into resource data
  SrcStm := TFileStream.Create(SrcFileName, fmOpenRead or fmShareDenyWrite);
  try
    if not Append then
      fDataStream.Size := 0;
    fDataStream.Seek(0, soFromEnd);
    fDataStream.CopyFrom(SrcStm, 0);
    fDataStream.Position := 0;
  finally
    SrcStm.Free;
  end;
end;

procedure TInternalResEntry.SetCharacteristics(const Value: DWORD);
begin
  fHdrSuffix.Characteristics := Value;
end;

procedure TInternalResEntry.SetDataBytes(const Value: TBytes);
begin
  fDataStream.Size := 0;
  if Length(Value) > 0 then
    fDataStream.WriteBuffer(Pointer(Value)^, Length(Value));
  fDataStream.Position := 0;
end;

procedure TInternalResEntry.SetDataVersion(const Value: DWORD);
begin
  fHdrSuffix.DataVersion := Value;
end;

procedure TInternalResEntry.SetMemoryFlags(const Value: Word);
begin
  fHdrSuffix.MemoryFlags := Value;
end;

procedure TInternalResEntry.SetVersion(const Value: DWORD);
begin
  fHdrSuffix.Version := Value;
end;

procedure TInternalResEntry.WriteToStream(Stm: TStream);

  // Writes given value with given size to the stream and updates count of bytes
  // bytes written to date. Raises exception if all required bytes can't be
  // written.
  procedure Write(const Value; const Size: Integer; var BytesWritten: Integer);
  begin
    // Write stream and check all expected bytes read
    if Stm.Write(Value, Size) <> Size then
      raise EPJResourceFile.Create('Error writing resource entry to stream');
    // Update count of bytes written
    Inc(BytesWritten, Size);
  end;

  // Writes a resource identifier to the stream and updates total number of
  // bytes written.
  procedure WriteResID(ResID: PChar; var BytesWritten: Integer);
  var
    OrdValue: DWORD;        // resource id ordinal value
    StrValue: WideString;   // resource id string value
  begin
    if IsIntResource(ResID) then
    begin
      // This is ordinal: create and write out required DWORD
      OrdValue := $0000FFFF or
        {$IFDEF FPC}
          (LongRec(DWORD(ResID)).Lo shl 16);
        {$ELSE}
          (DWORD(LoWord(ResID)) shl 16);
        {$ENDIF}
      Write(OrdValue, SizeOf(OrdValue), BytesWritten);
    end
    else
    begin
      // This is string: create and write out required wide string
      StrValue := WideString(string(ResID));
      Write(
        StrValue[1], (Length(StrValue) + 1) * SizeOf(WideChar), BytesWritten
      );
    end;
  end;

  // Write zero or more bytes to the stream until the number of bytes written is
  // a multiple of the size of a DWORD.
  procedure WriteToBoundary(var BytesWritten: Integer);
  const
    cPadding: DWORD = 0;  // stores zero bytes for writing out as padding
  var
    PadBytes: Integer;    // number of padding bytes needed
  begin
    if BytesWritten mod SizeOf(DWORD) <> 0 then
    begin
      PadBytes := SizeOf(DWORD) - BytesWritten mod SizeOf(DWORD);
      Assert((PadBytes + BytesWritten) mod SizeOf(DWORD) = 0);
      Write(cPadding, PadBytes, BytesWritten);
    end;
  end;

var
  BytesWritten: Integer;          // count of bytes written to stream
  HdrPrefix: TResEntryHdrPrefix;  // fixed size resource header prefix
begin
  // Initialise number of bytes written
  BytesWritten := 0;
  // Write header
  // write data size and header size
  HdrPrefix.DataSize := GetDataSize;
  HdrPrefix.HeaderSize := GetHeaderSize;
  Write(HdrPrefix, SizeOf(HdrPrefix), BytesWritten);
  // write type and name resource ids, padded to DWORD boundary
  WriteResID(fResType, BytesWritten);
  WriteResID(fResName, BytesWritten);
  WriteToBoundary(BytesWritten);
  // write fixed header suffix (updated via properties)
  Write(fHdrSuffix, SizeOf(fHdrSuffix), BytesWritten);
  // check correct size header written
  if Int64(BytesWritten) <> Int64(HdrPrefix.HeaderSize) then
    raise EPJResourceFile.Create(sErrHeaderCalc);
  // Write any resource data
  if HdrPrefix.DataSize > 0 then
  begin
    // copy whole of resource data stream to output stream
    fDataStream.Position := 0;
    try
      Stm.CopyFrom(fDataStream, HdrPrefix.DataSize);
      Inc(BytesWritten, HdrPrefix.DataSize);
    except
      // convert any write error to EPJResourceFile error
      raise EPJResourceFile.Create(sErrResWrite);
    end;
    // rewind resource data stream
    fDataStream.Position := 0;
    // write out any required padding bytes to make length multiple of DWORD
    WriteToBoundary(BytesWritten);
  end;
end;

{ TPJResourceFile }

function TPJResourceFile.AddEntry(const ResType, ResName: PChar;
  const LangID: Word = 0): TPJResourceEntry;
begin
  // Check matching entry not already in file
  if Assigned(FindEntry(ResType, ResName, LangID)) then
    raise EPJResourceFile.Create(sErrDupResEntry);
  // Create new resource entry and add to list
  Result := TInternalResEntry.Create(Self, ResType, ResName, LangID);
  fEntries.Add(Result);
end;

function TPJResourceFile.AddEntry(const Entry: TPJResourceEntry;
  const ResName: PChar; const LangID: Word): TPJResourceEntry;
var
  OldPos: Longint;  // position in entry to be copied data stream
begin
  // Create new empty entry
  Result := AddEntry(Entry.ResType, ResName, LangID);
  // Copy read/write ordinal properties
  Result.DataVersion := Entry.DataVersion;
  Result.MemoryFlags := Entry.MemoryFlags;
  Result.Version := Entry.Version;
  Result.Characteristics := Entry.Characteristics;
  // Copy given entry's data to new entry, preserving position in stream
  OldPos := Entry.Data.Position;
  Entry.Data.Position := 0;
  Result.Data.CopyFrom(Entry.Data, Entry.Data.Size);
  Entry.Data.Position := OldPos;
  // Reset new entry's stream position
  Result.Data.Position := 0;
end;

procedure TPJResourceFile.Clear;
var
  Idx: Integer; // loops through all entries
begin
  // Free all resource entry instances
  for Idx := Pred(EntryCount) downto 0 do
    Entries[Idx].Free;  // this unlinks entry from list
end;

constructor TPJResourceFile.Create;
begin
  inherited;
  // Create list to store resource entries
  fEntries := TList.Create;
end;

function TPJResourceFile.DeleteEntry(const Entry: TPJResourceEntry): Boolean;
var
  Idx: Integer; // index of entry in list
begin
  // Find index of entry in list, if exists
  Idx := IndexOfEntry(Entry);
  Result := Idx > -1;
  if Result then
    // Delete found entry from list
    fEntries.Delete(Idx);
end;

destructor TPJResourceFile.Destroy;
begin
  Clear;
  fEntries.Free;
  inherited;
end;

function TPJResourceFile.EntryExists(const ResType, ResName: PChar;
  const LangID: Word = $FFFF): Boolean;
begin
  Result := Assigned(FindEntry(ResType, ResName, LangID));
end;

function TPJResourceFile.FindEntry(const ResType,
  ResName: PChar; const LangID: Word = $FFFF): TPJResourceEntry;
var
  Idx: Integer; // loops through all resource entries in file
begin
  // Loop through entries checking if they match type, name and language id
  Result := nil;
  for Idx := 0 to Pred(EntryCount) do
    if Entries[Idx].IsMatching(ResType, ResName, LangID) then
    begin
      Result := Entries[Idx];
      Break;
    end;
end;

function TPJResourceFile.FindEntryIndex(const ResType, ResName: PChar;
  const LangID: Word = $FFFF): Integer;
var
  Entry: TPJResourceEntry;  // matching resource entry instance
begin
  // Try to find resource entry matching type, name and language
  Entry := FindEntry(ResType, ResName, LangID);
  if Assigned(Entry) then
    // Found entry: get index in list
    Result := IndexOfEntry(Entry)
  else
    // No matching entry
    Result := -1;
end;

function TPJResourceFile.GetEntry(Idx: Integer): TPJResourceEntry;
begin
  Result := TInternalResEntry(fEntries[Idx]);
end;

function TPJResourceFile.GetEntryCount: Integer;
begin
  Result := fEntries.Count;
end;

function TPJResourceFile.GetEnumerator: TPJResourceFileEnumerator;
begin
  Result := TPJResourceFileEnumerator.Create(fEntries);
end;

function TPJResourceFile.IndexOfEntry(const Entry: TPJResourceEntry): Integer;
begin
  Result := fEntries.IndexOf(Entry);
end;

class function TPJResourceFile.IsValidResourceStream(
  const Stm: TStream): Boolean;
const
  // Expected bytes in the header record that introduces a 32 bit resource file
  DummyHeader: array[0..7] of Byte = ($00, $00, $00, $00, $20, $00, $00, $00);
var
  HeaderBuf: array[0..31] of Byte;  // stores introductory header
begin
  if Stm.Read(HeaderBuf, SizeOf(HeaderBuf)) = SizeOf(HeaderBuf) then
    // Check if header is equivalent to dummy header that starts resource files
    Result := CompareMem(@HeaderBuf, @DummyHeader, SizeOf(DummyHeader))
  else
    // Couldn't read header
    Result := False;
end;

procedure TPJResourceFile.LoadFromFile(const FileName: TFileName);
var
  Stm: TFileStream; // stream onto file
begin
  Stm := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(Stm);
  finally
    Stm.Free;
  end;
end;

procedure TPJResourceFile.LoadFromStream(const Stm: TStream);
begin
  // Clear any previous resource entries
  Clear;
  // Test for header of 32 bit resource file: exception if invalid
  if not IsValidResourceStream(Stm) then
    raise EPJResourceFile.Create(sErrBadResFile);
  // This is valid 32 bit resource file. We've passed header: read the resources
  while Stm.Position < Stm.Size do
    fEntries.Add(TInternalResEntry.Create(Self, Stm));  // increments stream pos
end;

procedure TPJResourceFile.SaveToFile(const FileName: TFileName);
var
  Stm: TFileStream; // stream onto file
begin
  Stm := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stm);
  finally
    Stm.Free;
  end;
end;

procedure TPJResourceFile.SaveToStream(const Stm: TStream);
var
  Idx: Integer; // loops through all entries in resource
begin
  // Write header record to stream
  with TInternalResEntry.Create(Self, MakeIntResource(0), MakeIntResource(0), $0000) do
    try
      WriteToStream(Stm);
    finally
      Free;
    end;
  // Write actual resource entries
  for Idx := 0 to Pred(EntryCount) do
    (Entries[Idx] as TInternalResEntry).WriteToStream(Stm);
end;

{ TPJResourceFileEnumerator }

constructor TPJResourceFileEnumerator.Create(const Entries: TList);
begin
  inherited Create;
  fEntries := Entries;
  fIndex := -1;
end;

function TPJResourceFileEnumerator.GetCurrent: TPJResourceEntry;
begin
  Result := TPJResourceEntry(fEntries[fIndex]);
end;

function TPJResourceFileEnumerator.MoveNext: Boolean;
begin
  Result := fIndex < Pred(fEntries.Count);
  if Result then
    Inc(fIndex);
end;

end.

