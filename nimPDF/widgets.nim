import objects, fontmanager, gstate, page, tables, image, strutils

const
  FIELD_TYPE_BUTTON = "Btn"
  FIELD_TYPE_TEXT = "Tx"
  FIELD_TYPE_CHOICE = "Ch"

type
  AnnotFlags = enum
    afInvisible = 1
    afHidden = 2
    afPrint = 3
    afNoZoom = 4
    afNoRotate = 5
    afNoView = 6
    afReadOnly = 7
    afLocked = 8
    afToggleNoView = 9
    afLockedContents = 10

  WidgetKind = enum
    wkTextField
    wkCheckBox
    wkRadioButton
    wkComboBox
    wkListBox
    wkPushButton

  BorderStyle* = enum
    bsSolid
    bsDashed
    bsBeveled
    bsInset
    bsUnderline

  Visibility* = enum
    Visible
    Hidden
    VisibleNotPrintable
    HiddenButPrintable

  ButtonFlags* = enum
    bfNoToggleToOff = 15
    bfRadio = 16
    bfPushButton = 17
    bfRadiosInUnison = 26

  TextFieldFlags* = enum
    tfMultiline = 13
    tfPassWord = 14
    tfFileSelect = 21
    tfDoNotSpellCheck = 23
    tfDoNoScroll = 24
    tfComb = 25
    tfRichText = 26

  TextFieldAlignment* = enum
    tfaLeft
    tfaCenter
    tfaRight

  ComboBoxFlags = enum
    cfCombo = 18
    cfEdit = 19
    cfSort = 20
    cfMultiSelect = 22
    cfDoNotSpellCheck = 23
    cfCommitOnSelChange = 27

  FormActionTrigger* = enum
    MouseUp
    MouseDown
    MouseEnter
    MouseExit
    GetFocus
    LostFocus

  FormSubmitFormat* = enum
    EmailFormData
    PDF_Format
    HTML_Format
    XFDF_Format

  NamedAction* = enum
    naFirstPage
    naNextPage
    naPrevPage
    naLastPage
    naPrintDialog

  SepStyle* = enum
    ssCommaDot   # 1,234.56
    ssDotOnly    # 1234.56
    ssDotComma   # 1.234,56
    ssCommaOnly  # 1234,56

  NegStyle* = enum
    nsDash       # '-'
    nsRedText
    nsParenBlack
    nsParenRed

  PushButtonFlags* = enum
    pbfCaptionOnly
    pbfIconOnly
    pbfCaptionBelowIcon
    pbfCaptionAboveIcon
    pbfCaptionRightToTheIcon
    pbfCaptionLeftToTheIcon
    pbfCaptionOverlaidIcon

  ColorType = enum
    ColorRGB
    ColorCMYK

  FormActionKind = enum
    fakOpenWebLink
    fakResetForm
    fakSubmitForm
    fakEmailEntirePDF
    fakRunJS
    fakNamedAction
    fakGotoLocalPage
    fakGotoAnotherPDF
    fakLaunchApp

  FormAction = ref object
    trigger: FormActionTrigger
    case kind: FormActionKind
    of fakOpenWebLink:
      url: string
    of fakResetForm:
      discard
    of fakSubmitForm:
      format: FormSubmitFormat
      uri: string
    of fakEmailEntirePDF:
      to, cc, bcc, title, body: string
    of fakRunJS:
      script: string
    of fakNamedAction:
      namedAction: NamedAction
    of fakGotoLocalPage:
      localDest: Destination
    of fakGotoAnotherPDF:
      remoteDest: Destination
      path: string
    of fakLaunchApp:
      app, params, operation, defaultDir: string

  Border = ref object of MapRoot
    style: BorderStyle
    width: int
    dashPattern: seq[int]
    colorRGB: RGBColor
    colorCMYK: CMYKColor
    colorType: ColorType

  SpecialFormat* = enum
    sfZipCode
    sfZipCode4
    sfPhoneNumber
    sfSSN
    sfMask

  FormatKind = enum
    FormatNone
    FormatNumber
    FormatCurrency
    FormatPercent
    FormatDate
    FormatTime
    FormatSpecial
    FormatCustom

  FormatObject = ref object
    case kind: FormatKind
    of FormatNone: discard
    of FormatNumber, FormatPercent:
      decimalNumber: int
      sepStyle: SepStyle
      negStyle: NegStyle
    of FormatCurrency:
      strCurrency: string
      currencyPrepend: bool
    of FormatDate, FormatTime:
      strFmt: string
    of FormatSpecial:
      style: SpecialFormat
      mask: string
    of FormatCustom:
      JSfmt, keyStroke: string

  HighLightMode* = enum
    hmNone
    hmInvert
    hmOutline
    hmPush
    hmToggle

  FieldFlags = enum
    ffReadOnly = 1
    ffRequired = 2
    ffNoExport = 3

  Widget = ref object of MapRoot
    kind: WidgetKind
    state: DocState
    id: string
    border: Border
    rect: Rectangle
    toolTip: string
    visibility: Visibility
    rotation: int
    fontFamily: string
    fontStyle: FontStyles
    fontSize: float64
    fontEncoding: EncodingType
    fontColorRGB: RGBColor
    fontColorCMYK: CMYKColor
    fontColorType: ColorType
    fillColorRGB: RGBColor
    fillColorCMYK: CMYKColor
    fillColorType: ColorType
    actions: seq[FormAction]
    validateScript: string
    calculateScript: string
    format: FormatObject
    highLightMode: HighLightMode
    fieldFlags: int

  TextField* = ref object of Widget
    align: TextFieldAlignment
    maxChars: int
    defaultValue: string
    flags: set[TextFieldFlags]

  CheckBox* = ref object of Widget
    shape: string
    checkedByDefault: bool

  RadioButton* = ref object of Widget
    shape: string
    checkedByDefault: bool
    allowUnchecked: bool

  ComboBox* = ref object of Widget
    keyVal: Table[string, string]
    editable: bool

  ListBox* = ref object of Widget
    keyVal: Table[string, string]
    multipleSelect: bool

  IconScaleMode* = enum
    ismAlwaysScale
    ismScaleIfBigger
    ismScaleIfSmaller
    ismNeverScale

  IconScalingType* = enum
    istAnamorphic
    istProportional

  PushButton* = ref object of Widget
    flags: set[PushButtonFlags]
    caption: string
    rollOverCaption: string
    alternateCaption: string
    icon: Image
    rollOverIcon: Image
    alternateIcon: Image
    iconScaleMode: IconScaleMode
    iconScalingType: IconScalingType
    iconFitToBorder: bool
    iconLeftOver: array[2, float64]

method createObject(self: MapRoot): PdfObject {.base.} = discard

proc newBorder(): Border =
  new(result)
  result.style = bsSolid
  result.width = 1
  result.dashPattern = nil
  result.colorRGB = initRGB(0,0,0)
  result.colorType = ColorRGB

proc setWidth(self: Border, w: int) =
  self.width = w

proc setStyle(self: Border, s: BorderStyle) =
  self.style = s
  if s == bsDashed:
    self.dashPattern = @[1, 0]

proc setDash(self: Border, dash: openArray[int]) =
  self.style = bsDashed
  self.dashPattern = @dash

proc setColor(self: Border, col: RGBColor) =
  self.colorType = ColorRGB
  self.colorRGB = col

proc setColor(self: Border, col: CMYKColor) =
  self.colorType = ColorCMYK
  self.colorCMYK = col

method createObject(self: Border): PdfObject =
  var dict = newDictObj()
  dict.addNumber("W", self.width)
  case self.style
  of bsSolid: dict.addName("S", "S")
  of bsDashed:
    dict.addName("S", "D")
    var arr = newArray(self.dashPattern)
    dict.addElement("D", arr)
  of bsBeveled: dict.addName("S", "B")
  of bsInset: dict.addName("S", "I")
  of bsUnderline: dict.addName("S", "U")
  result = dict

proc newArray(c: RGBColor): ArrayObj =
  result = newArray(c.r, c.g, c.b)

proc newArray(c: CMYKColor): ArrayObj =
  result = newArray(c.c, c.m, c.y, c.k)

proc newColorArray(colorType: ColorType, rgb: RGBColor, cmyk: CMYKColor): ArrayObj =
  if colorType == ColorRGB: result = newArray(rgb)
  else: result = newArray(cmyk)

proc setBit[T: enum](x: var int, bit: T) =
  x = x or (1 shr ord(bit))

proc removeBit[T: enum](x: var int, bit: T) =
  x = x and (not (1 shr ord(bit)))

proc createPDFObject(self: Widget): DictObj =
  const
    hmSTR: array[HighLightMode, char] = ['N', 'I', 'O', 'P', 'T']

  var dict = newDictObj()
  dict.addName("Type", "Annot")
  dict.addName("Subtype", "Widget")
  dict.addName("H", $hmSTR[self.highLightMode])
  dict.addString("T", self.id)
  dict.addString("TU", self.toolTip)

  var annotFlags = 0

  case self.visibility:
  of Visible: annotFlags.setBit(afPrint)
  of Hidden: annotFlags.setBit(afHidden)
  of VisibleNotPrintable: discard
  of HiddenButPrintable:
    annotFlags.setBit(afPrint)
    annotFlags.setBit(afHidden)

  dict.addNumber("F", annotFlags)

  var mk = newDictObj()
  let bg = newColorArray(self.fillColorType, self.fillColorRGB, self.fillColorCMYK)
  mk.addElement("BG", bg)
  mk.addNumber("R", self.rotation)
  dict.addElement("MK", mk)

  if self.border != nil:
    let border = self.border
    let bs = border.createObject()
    let bc = newColorArray(border.colorType, border.colorRGB, border.colorCMYK)
    dict.addElement("BS", bs)
    mk.addElement("BC", bc)

  var rc = newArray(self.rect)
  dict.addElement("Rect", rc)

  var font = self.state.makeFont(self.fontFamily, self.fontStyle, self.fontEncoding)
  let fontID = $font.ID

  if self.fontColorType == ColorRGB:
    let c = self.fontColorRGB
    dict.addString("DA", "/F$1 $2 Tf $3 $4 $5 rg" % [fontID, f2s(self.fontSize), f2s(c.r), f2s(c.g), f2s(c.b)])
  else:
    let c = self.fontColorCMYK
    dict.addString("DA", "/F$1 $2 Tf $3 $4 $5 $6 k" % [fontID, f2s(self.fontSize), f2s(c.c), f2s(c.m), f2s(c.y), f2s(c.k)])

  if self.actions.isNil: self.actions = @[]



  #var dr = newDictObj()
  #var ft = newDictObj()
  #ft.addElement("")
  #dr.addElement("Font", ft)
  #dict.addElement("DR", dr)

  #DR
  #AP
  #P
  #Parent

  result = dict

proc init(self: Widget, doc: DocState, id: string) =
  self.state = doc                      #
  self.id = id                          # ok
  self.border = nil                     # ok
  self.toolTip = ""                     # ok
  self.visibility = Visible             # ok
  self.rotation = 0                     # ok
  self.fontFamily = "Helvetica"         # ok
  self.fontStyle = {FS_REGULAR}         # ok
  self.fontSize = 10.0                  # ok
  self.fontEncoding = ENC_STANDARD      # ok
  self.fontColorType = ColorRGB         # ok
  self.fontColorRGB = initRGB(0, 0, 0)  # ok
  self.fillColorType = ColorRGB         # ok
  self.fillColorRGB = initRGB(0, 0, 0)  # ok
  self.actions = nil                    #
  self.validateScript = nil             #
  self.calculateScript = nil            #
  self.format = nil                     #
  self.highLightMode = hmNone           # ok
  self.fieldFlags = 0                   #

proc setToolTip*(self: Widget, toolTip: string) =
  self.toolTip = toolTip

proc setVisibility*(self: Widget, val: Visibility) =
  self.visibility = val

# multiple of 90 degree
proc setRotation*(self: Widget, angle: int) =
  self.rotation = angle

proc setReadOnly*(self: Widget, val: bool) =
  if val: self.fieldFlags.setBit(ffReadOnly)
  else: self.fieldFlags.removeBit(ffReadOnly)

proc setRequired*(self: Widget, val: bool) =
  if val: self.fieldFlags.setBit(ffRequired)
  else: self.fieldFlags.removeBit(ffRequired)

proc setNoExport*(self: Widget, val: bool) =
  if val: self.fieldFlags.setBit(ffNoExport)
  else: self.fieldFlags.removeBit(ffNoExport)

proc setFont*(self: Widget, family: string) =
  self.fontFamily = family

proc setFontStyle*(self: Widget, style: FontStyles) =
  self.fontStyle = style

proc setFontSize*(self: Widget, size: float64) =
  self.fontSize = self.state.fromUser(size)

proc setFontEncoding*(self: Widget, enc: EncodingType) =
  self.fontEncoding = enc

proc setFontColor*(self: Widget, r,g,b: float64) =
  self.fontColorType = ColorRGB
  self.fontColorRGB = initRGB(r,g,b)

proc setFontColor*(self: Widget, c,m,y,k: float64) =
  self.fontColorType = ColorCMYK
  self.fontColorCMYK = initCMYK(c,m,y,k)

proc setFontColor*(self: Widget, col: RGBColor) =
  self.fontColorType = ColorRGB
  self.fontColorRGB = col

proc setFontColor*(self: Widget, col: CMYKColor) =
  self.fontColorType = ColorCMYK
  self.fontColorCMYK = col

proc setFillColor*(self: Widget, r,g,b: float64) =
  self.fillColorType = ColorRGB
  self.fillColorRGB = initRGB(r,g,b)

proc setFillColor*(self: Widget, c,m,y,k: float64) =
  self.fillColorType = ColorCMYK
  self.fillColorCMYK = initCMYK(c,m,y,k)

proc setFillColor*(self: Widget, col: RGBColor) =
  self.fillColorType = ColorRGB
  self.fillColorRGB = col

proc setFillColor*(self: Widget, col: CMYKColor) =
  self.fillColorType = ColorCMYK
  self.fillColorCMYK = col

proc setBorderColor*(self: Widget, r,g,b: float64) =
  if self.border.isNil: self.border = newBorder()
  self.border.setColor(initRGB(r,g,b))

proc setBorderColor*(self: Widget, c,m,y,k: float64) =
  if self.border.isNil: self.border = newBorder()
  self.border.setColor(initCMYK(c,m,y,k))

proc setBorderColor*(self: Widget, col: RGBColor) =
  if self.border.isNil: self.border = newBorder()
  self.border.setColor(col)

proc setBorderColor*(self: Widget, col: CMYKColor) =
  if self.border.isNil: self.border = newBorder()
  self.border.setColor(col)

proc setBorderWidth*(self: Widget, w: int) =
  if self.border.isNil: self.border = newBorder()
  self.border.setWidth(w)

proc setBorderStyle*(self: Widget, style: BorderStyle) =
  if self.border.isNil: self.border = newBorder()
  self.border.setStyle(style)

proc setBorderDash*(self: Widget, dash: openArray[int]) =
  if self.border.isNil: self.border = newBorder()
  self.border.setDash(dash)

proc addActionOpenWebLink*(self: Widget, trigger: FormActionTrigger, url: string) =
  if self.actions.isNil: self.actions = @[]
  var action = new(FormAction)
  action.trigger = trigger
  action.kind = fakOpenWebLink
  action.url = url
  self.actions.add action

proc addActionResetForm*(self: Widget, trigger: FormActionTrigger) =
  if self.actions.isNil: self.actions = @[]
  var action = new(FormAction)
  action.trigger = trigger
  action.kind = fakResetForm
  self.actions.add action

proc addActionSubmitForm*(self: Widget, trigger: FormActionTrigger, format: FormSubmitFormat, uri: string) =
  if self.actions.isNil: self.actions = @[]
  var action = new(FormAction)
  action.trigger = trigger
  action.kind = fakSubmitForm
  action.uri = uri
  self.actions.add action

proc addActionEmailEntirePDF*(self: Widget, trigger: FormActionTrigger; to, cc, bcc, title, body: string) =
  if self.actions.isNil: self.actions = @[]
  var action = new(FormAction)
  action.trigger = trigger
  action.kind = fakEmailEntirePDF
  action.to = to
  action.cc = cc
  action.bcc = bcc
  action.title = title
  action.body = body
  self.actions.add action

proc addActionRunJS*(self: Widget, trigger: FormActionTrigger, script: string) =
  if self.actions.isNil: self.actions = @[]
  var action = new(FormAction)
  action.trigger = trigger
  action.kind = fakRunJS
  action.script = script
  self.actions.add action

proc addActionNamed*(self: Widget, trigger: FormActionTrigger, name: NamedAction) =
  if self.actions.isNil: self.actions = @[]
  var action = new(FormAction)
  action.trigger = trigger
  action.kind = fakNamedAction
  action.namedAction = name
  self.actions.add action

proc addActionGotoLocalPage*(self: Widget, trigger: FormActionTrigger, dest: Destination) =
  if self.actions.isNil: self.actions = @[]
  var action = new(FormAction)
  action.trigger = trigger
  action.kind = fakGotoLocalPage
  action.localDest = dest
  self.actions.add action

proc addActionGotoAnotherPDF*(self: Widget, trigger: FormActionTrigger, path: string, dest: Destination) =
  if self.actions.isNil: self.actions = @[]
  var action = new(FormAction)
  action.trigger = trigger
  action.kind = fakGotoAnotherPDF
  action.remoteDest = dest
  action.path = path
  self.actions.add action

proc addActionLaunchApp*(self: Widget, trigger: FormActionTrigger; app, params, operation, defaultDir: string) =
  if self.actions.isNil: self.actions = @[]
  var action = new(FormAction)
  action.trigger = trigger
  action.kind = fakLaunchApp
  action.app = app
  action.params = params
  action.operation = operation
  action.defaultDir = defaultDir
  self.actions.add action

proc formatNumber*(self: Widget, decimalNumber: int, sepStyle: SepStyle, negStyle: NegStyle) =
  var fmt = new(FormatObject)
  fmt.kind = FormatNumber
  fmt.decimalNumber = decimalNumber
  fmt.sepStyle = sepStyle
  fmt.negStyle = negStyle
  self.format = fmt

proc formatCurrency*(self: Widget, strCurrency: string, currencyPrepend: bool) =
  var fmt = new(FormatObject)
  fmt.kind = FormatCurrency
  fmt.strCurrency = strCurrency
  fmt.currencyPrepend = currencyPrepend
  self.format = fmt

proc formatPercent*(self: Widget, decimalNumber: int, sepStyle: SepStyle) =
  var fmt = new(FormatObject)
  fmt.kind = FormatPercent
  fmt.decimalNumber = decimalNumber
  fmt.sepStyle = sepStyle
  self.format = fmt

#[
m/d
m/d/yy
m/d/yyyy
mm/dd/yy
mm/dd/yyyy
mm/yy
mm/yyyy
d-mmm
d-mmm-yy
d-mmm-yyyy
dd-mmm-yy
dd-mmm-yyy
yy-mm-dd
yyyy-mm-dd
mmm-yy
mmm-yyyy
mmmm-yy
mmmm-yyyy
mmm d, yyyy
mmmm d, yyyy
m/d/yy h:MM tt
m/d/yyyy h:MM tt
m/d/yy HH:MM
m/d/yyyy HH MM
]#

proc formatDate*(self: Widget, strFmt: string) =
  var fmt = new(FormatObject)
  fmt.kind = FormatDate
  fmt.strFmt = strFmt
  self.format = fmt

#[
HH:MM
h:MM tt
HH:MM:ss
h:MM:ss tt
]#

proc formatTime*(self: Widget, strFmt: string) =
  var fmt = new(FormatObject)
  fmt.kind = FormatTime
  fmt.strFmt = strFmt
  self.format = fmt

proc formatSpecial*(self: Widget, style: SpecialFormat, mask: string = nil) =
  var fmt = new(FormatObject)
  fmt.kind = FormatSpecial
  fmt.style = style
  fmt.mask = mask
  self.format = fmt

proc formatCustom*(self: Widget, JSfmt, keyStroke: string) =
  var fmt = new(FormatObject)
  fmt.kind = FormatCustom
  fmt.JSfmt = JSfmt
  fmt.keyStroke = keyStroke
  self.format = fmt

#[
// 0 <= N <= 100
AFRange_Validate(true, 0, true, 100);


// Keep the Text2 field grayed out and read only
// until an amount greater than 100 is entered in the ActiveValue field
var f = this.getField("Text2");
f.readonly = (event.value < 100);
f.textColor = (event.value < 100) ? color.gray : color.black;

//N<=100
if(event.value >100)
{
   app.alert('N<=100');
   event.value = 100;
}
]#

proc setValidateScript*(self: Widget, script: string) =
  self.validateScript = script

#[
//Please add and update the field names
AFSimple_Calculate("AVG", new Array (  "Text1",  "Text2" ));

//Please add and update the field names
AFSimple_Calculate("SUM", new Array (  "Text1",  "Text2" ));

//Please add and update the field names
AFSimple_Calculate("PRD", new Array (  "Text1",  "Text2" ));

//Please add and update the field names
AFSimple_Calculate("MIN", new Array (  "Text1",  "Text2" ));

//Please add and update the field names
AFSimple_Calculate("MAX", new Array (  "Text1",  "Text2" ));

//Please add and update the field names
var a = this.getField( "Text1" ).value;
var b = this.getField( "Text2" ).value;
this.getField( "Text3" ).value = 10 * a - b /10;
]#

proc setCalculateScript*(self: Widget, script: string) =
  self.calculateScript = script

proc setHighLightMode*(self: Widget, mode: HighLightMode) =
  self.highLightMode = mode

#----------------------TEXT FIELD
proc newTextField*(doc: DocState, x,y,w,h: float64, id: string): TextField =
  new(result)
  result.init(doc, id)
  result.rect = initRect(x,y,w,h)
  result.kind = wkTextField
  result.align = tfaLeft
  result.maxChars = 0
  result.defaultValue = ""
  result.flags = {}
  doc.addWidget(result)

proc setAlignment*(self: TextField, align: TextFieldAlignment) =
  self.align = align

proc setMaxChars*(self: TextField, maxChars: int) =
  self.maxChars = maxChars

proc setDefaultValue*(self: TextField, val: string) =
  self.defaultValue = val

proc setFlag*(self: TextField, flag: TextFieldFlags) =
  self.flags.incl flag

proc setFlags*(self: TextField, flags: set[TextFieldFlags]) =
  self.flags.incl flags

proc removeFlag*(self: TextField, flag: TextFieldFlags) =
  self.flags.excl flag

proc removeFlags*(self: TextField, flags: set[TextFieldFlags]) =
  self.flags.excl flags

method createObject(self: TextField): PdfObject =
  var dict = self.createPDFObject()
  dict.addName("FT", FIELD_TYPE_TEXT)
  result = dict

#----------------------CHECK BOX
proc newCheckBox*(doc: DocState, x,y,w,h: float64, id: string): CheckBox =
  new(result)
  result.init(doc, id)
  result.rect = initRect(x,y,w,h)
  result.kind = wkCheckBox
  result.shape = "\x35"
  result.checkedByDefault = false
  doc.addWidget(result)

proc setShape*(self: CheckBox, val: string) =
  self.shape = val

proc setCheckedByDefault*(self: CheckBox, val: bool) =
  self.checkedByDefault = val

method createObject(self: CheckBox): PdfObject =
  var dict = self.createPDFObject()
  dict.addName("FT", FIELD_TYPE_BUTTON)
  result = dict

#----------------------RADIO BUTTON
proc newRadioButton*(doc: DocState, x,y,w,h: float64, id: string): RadioButton =
  new(result)
  result.init(doc, id)
  result.rect = initRect(x,y,w,h)
  result.kind = wkRadioButton
  result.shape = "\6C"
  result.checkedByDefault = false
  result.allowUnchecked = false
  doc.addWidget(result)

proc setShape*(self: RadioButton, val: string) =
  self.shape = val

proc setCheckedByDefault*(self: RadioButton, val: bool) =
  self.checkedByDefault = val

proc setAllowUnchecked*(self: RadioButton, val: bool) =
  self.allowUnchecked = val

method createObject(self: RadioButton): PdfObject =
  var dict = self.createPDFObject()
  dict.addName("FT", FIELD_TYPE_BUTTON)
  result = dict

#---------------------COMBO BOX
proc newComboBox*(doc: DocState, x,y,w,h: float64, id: string): ComboBox =
  new(result)
  result.init(doc, id)
  result.rect = initRect(x,y,w,h)
  result.kind = wkComboBox
  result.editable = false
  result.keyVal = initTable[string, string]()
  doc.addWidget(result)

proc addKeyVal*(self: ComboBox, key, val: string) =
  self.keyVal[key] = val

proc setEditable*(self: ComboBox, val: bool) =
  self.editable = val

method createObject(self: ComboBox): PdfObject =
  var dict = self.createPDFObject()
  dict.addName("FT", FIELD_TYPE_CHOICE)
  result = dict

#---------------------LIST BOX
proc newListBox*(doc: DocState, x,y,w,h: float64, id: string): ListBox =
  new(result)
  result.init(doc, id)
  result.rect = initRect(x,y,w,h)
  result.kind = wkListBox
  result.multipleSelect = false
  result.keyVal = initTable[string, string]()
  doc.addWidget(result)

proc addKeyVal*(self: ListBox, key, val: string) =
  self.keyVal[key] = val

proc setMultipleSelect*(self: ListBox, val: bool) =
  self.multipleSelect = val

method createObject(self: ListBox): PdfObject =
  var dict = self.createPDFObject()
  dict.addName("FT", FIELD_TYPE_CHOICE)
  result = dict

#---------------------PUSH BUTTON
proc newPushButton*(doc: DocState, x,y,w,h: float64, id: string): PushButton =
  new(result)
  result.init(doc, id)
  result.rect = initRect(x,y,w,h)
  result.kind = wkPushButton
  result.caption = ""
  result.rollOverCaption = nil
  result.alternateCaption = nil
  result.flags = {}
  result.icon = nil
  result.rollOverIcon = nil
  result.alternateIcon = nil
  result.iconScaleMode = ismAlwaysScale
  result.iconScalingType = istProportional
  result.iconFitToBorder = false
  result.iconLeftOver = [0.5, 0.5]

  doc.addWidget(result)

proc setCaption*(self: PushButton, val: string) =
  self.caption = val

proc setRollOverCaption*(self: PushButton, val: string) =
  self.rollOverCaption = val

proc setAlternateCaption*(self: PushButton, val: string) =
  self.alternateCaption = val

proc setIcon*(self: PushButton, img: Image) =
  self.icon = img

proc setRollOverIcon*(self: PushButton, img: Image) =
  self.rollOverIcon = img

proc setAlternateIcon*(self: PushButton, img: Image) =
  self.alternateIcon = img

proc setIconScaleMode*(self: PushButton, mode: IconScaleMode) =
  self.iconScaleMode = mode

proc setIconScalingType*(self: PushButton, mode = IconScalingType) =
  self.iconScalingType = mode

proc setIconFitBorder*(self: PushButton, mode: bool) =
  self.iconFitToBorder = mode

proc setIconLeftOver*(self: PushButton, left, bottom: float64) =
  self.iconLeftOver = [left, bottom]

proc setFlag*(self: PushButton, flag: PushButtonFlags) =
  self.flags.incl flag

proc setFlags*(self: PushButton, flags: set[PushButtonFlags]) =
  self.flags.incl flags

proc removeFlag*(self: PushButton, flag: PushButtonFlags) =
  self.flags.excl flag

proc removeFlags*(self: PushButton, flags: set[PushButtonFlags]) =
  self.flags.excl flags

method createObject(self: PushButton): PdfObject =
  var dict = self.createPDFObject()
  dict.addName("FT", FIELD_TYPE_BUTTON)
  result = dict
