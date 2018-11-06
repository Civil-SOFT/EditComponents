(***
 * DataEdit.pas;
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2018 Eng.º Anderson Marques Ribeiro
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *)

unit DataEdit;

interface

uses
	SysUtils, Classes, Controls, Vcl.StdCtrls, RegularExpressions, Messages,
  Windows, Graphics;

type

  IDataEdit<_DataType> = interface(IUnknown)
  	['{E3DC429D-80A9-43D6-B364-B7D3E97317B9}']

    function Validate(AData: AnsiString; AParcial: Boolean): Boolean;
    function Format(AData: AnsiString): AnsiString;
    function Compare(AData1, AData2: _DataType): Integer;
    function ConvertToString(AData: _DataType): AnsiString;
    function ConvertToData(AData: AnsiString): _DataType;
    function NullValue: _DataType;

  end; { IDataEdit }

  TOnDataChange = procedure(Sender: TObject; const Data) of object;
  TOnInvalidInputData = procedure(Sender: TObject; AData: AnsiString) of object;

	TCustomDataEdit<_DataType; _Data: IDataEdit<_DataType>, constructor> = class(TCustomEdit)
  strict private

  	procedure CMEnter(var Msg: TCMEnter); message CM_ENTER;
    procedure CMExit(var Msg: TCMExit); message CM_EXIT;
    procedure WMChar(var Msg: TWMChar); message WM_CHAR;
    procedure WMKeyDown(var Msg: TWMKeyDown); message WM_KEYDOWN;
    procedure WMLButtonUp(var Msg: TWMLButtonUp); message WM_LBUTTONUP;

  public

  	constructor Create(AOwner: TComponent); override;

  protected

		procedure KeyDown(var Key: Word; Shift: TShiftState); override;

  strict private

  	class constructor CreateClass;

    var
    	FCursorPos: Integer;

		procedure GetSel(out _SelStart: Integer; out _SelStop: Integer);
		procedure SetSel(const _SelStart: Integer; _SelStop: Integer);
		procedure SetCursorPos;
		procedure SelectPrevChar;
		procedure SelectNextChar;
    procedure SelectFirstChar;
    procedure GotoEnd;

  	var
      FUseDataFormat: Boolean;
      FValue: _DataType;
      FValidateExit: Boolean;

    class var
      FData: _Data;

    procedure SetUseDataFormat(AValue: Boolean);
    procedure SetValue(AValue: _DataType);
    function GetEmpty: Boolean;

  protected

  	property UseDataFormat: Boolean read FUseDataFormat write SetUseDataFormat;
    property Value: _DataType read FValue write SetValue;
    property Empty: Boolean read GetEmpty;

  private

  	function ValidContent: Boolean;

    procedure FormatText;
    function ChangeValue: Boolean;

    (*
     * Events.
     * -------------------------------------------------------------------------
     *)

  strict private

  	var
    	FOnDataChange: TOnDataChange;
    	FOnInvalidInputData: TOnInvalidInputData;

  protected

  	property OnDataChange: TOnDataChange read FOnDataChange write FOnDataChange;
    property OnInvalidInputData: TOnInvalidInputData read FOnInvalidInputData write FOnInvalidInputData;

  	procedure DoInvalidInputData(AData: AnsiString); dynamic;
    procedure DoDataChange(AData: _DataType); dynamic;

  end; { TCustomDataEdit }

implementation

uses
	Forms, ClipBrd, Dialogs;

(*
 * TCustomDataEdit.
 * -----------------------------------------------------------------------------
 *)

procedure TCustomDataEdit<_DataType, _Data>.CMEnter(var Msg: TCMEnter);
begin
	inherited;

  if FValidateExit then
	  inherited Text := FData.ConvertToString(FValue);
end;

procedure TCustomDataEdit<_DataType, _Data>.CMExit(var Msg: TCMExit);
var
	str: AnsiString;
begin
	str := inherited Text;
  FValidateExit := True;

	if (Length(str) > 0) then
  begin
  	if not FData.Validate(str, False) then
    begin
    	FValidateExit := False;
      SetFocus;
      DoInvalidInputData(str);
    end
    else
    begin
			ChangeValue;
      FormatText;
    end;
  end;

	inherited;
end;

procedure TCustomDataEdit<_DataType, _Data>.WMChar(var Msg: TWMChar);
var
	str, strTexto: AnsiString;
  ss: TShiftState;
label
	Continuar;
begin
  str := inherited Text;

  case Msg.CharCode of
    VK_BACK:
    begin
      if SelLength = 1 then
        SelLength := 0;

      goto Continuar;
    end;
    VK_RETURN:
    begin
      SelStart := 0;
      SelLength := Length(inherited Text);
      ChangeValue;
    end;
    VK_ESCAPE:
    begin
    	if not FData.Validate(inherited Text, False) then
	    	inherited Text := '';
    end;
    VK_TAB:
    	if not FData.Validate(str, True) then
      	Msg.CharCode := 0;
    3:
    	Clipboard.AsText := SelText;
    else
    begin
      if SelLength > 0 then
      	str := StringReplace(str, SelText, '', []);

      strTexto := Chr(Msg.CharCode);

    	if Msg.CharCode = 22 then
      	strTexto := Clipboard.AsText;

      Insert(strTexto, str, SelStart);

      if not FData.Validate(str, True) then
        Msg.CharCode := 0;
    end;
  end;

Continuar:

  inherited;

  if (SelStart < Length(inherited Text)) and
  		FData.Validate(Chr(Msg.CharCode), True) and
  		//not (Msg.CharCode in [VK_LEFT, VK_RIGHT, VK_HOME, VK_END]) and
  	 (GetKeyState(VK_CONTROL) >= 0) then
  	SelLength := 1;
end;

procedure TCustomDataEdit<_DataType, _Data>.WMKeyDown(var Msg: TWMKeyDown);
begin
	inherited;

  case Msg.CharCode of
    VK_DELETE:
      SelLength := 1;
  end;
end;

procedure TCustomDataEdit<_DataType, _Data>.WMLButtonUp(var Msg: TWMLButtonUp);
begin
	inherited;

  if SelLength = 0 then
	  SelLength := 1;
end;

constructor TCustomDataEdit<_DataType, _Data>.Create(AOwner: TComponent);
begin
	inherited;

  FUseDataFormat := True;
  FValidateExit := True;
end;

procedure TCustomDataEdit<_DataType, _Data>.KeyDown(var Key: Word; Shift: TShiftState);
var
	intStart, intEnd: Integer;
label
	Terminar;
begin
  if Key in [VK_LEFT, VK_RIGHT, VK_HOME, VK_END, VK_UP, VK_DOWN] then
  begin
    if ssShift in Shift then
    begin
      GetSel(intStart, intEnd);

      case Key of
        VK_LEFT, VK_UP:
        begin
          if intStart = 0 then
            goto Terminar;

          if intStart < FCursorPos then
            SetSel(intStart - 1, intEnd)
          else if (intEnd - FCursorPos) = 1 then
            SetSel(intStart - 1, intEnd)
          else if FCursorPos <= intEnd then
            SetSel(intStart, intEnd - 1);
        end;
        VK_RIGHT, VK_DOWN:
        begin
          if intStart < FCursorPos then
            SetSel(intStart + 1, intEnd)
          else if FCursorPos < intEnd then
            SetSel(intStart, intEnd + 1);
        end;
        VK_HOME:
          SetSel(0, FCursorPos + 1);
        VK_END:
          SetSel(FCursorPos, Length(inherited Text));
      end;
    end
    else
    begin
      FCursorPos := SelStart;
      case Key of
        VK_LEFT, VK_UP:
          SelectPrevChar;
        VK_RIGHT, VK_DOWN:
          SelectNextChar;
        VK_HOME:
          SelectFirstChar;
        VK_END:
          GotoEnd;
      end;
    end;

Terminar:

    Key := 0;
  end;

  inherited;
end;

class constructor TCustomDataEdit<_DataType, _Data>.CreateClass;
begin
  FData := _Data.Create;
end;

procedure TCustomDataEdit<_DataType, _Data>.GetSel(out _SelStart: Integer; out _SelStop: Integer);
begin
  _SelStart := GetSelStart();
  _SelStop := _SelStart + GetSelLength();
end;

procedure TCustomDataEdit<_DataType, _Data>.SetSel(const _SelStart: Integer; _SelStop: Integer);
begin
  SetSelLength(0);
  SetSelStart(_SelStart);
  SetSelLength(_SelStop - _SelStart);
end;

procedure TCustomDataEdit<_DataType, _Data>.SetCursorPos;
var
	intComp: Integer;
begin
	intComp := Length(inherited Text);
  if not (csDesigning in ComponentState) then
  begin
    if FCursorPos < 0 then
    	FCursorPos := 0
    else if FCursorPos > intComp then
    	FCursorPos := intComp;
      SetSel(FCursorPos, FCursorPos + 1);
  end;
end;

procedure TCustomDataEdit<_DataType, _Data>.SelectPrevChar;
var
  P: LongInt;
  AStart: Integer;
  AStop: Integer;
begin
  GetSel(AStart, AStop);
  if (FCursorPos = 0) and (AStop - AStart <= 1) then Exit;
  P := FCursorPos;
  Dec(FCursorPos);
  SetCursorPos;
end;

procedure TCustomDataEdit<_DataType, _Data>.SelectNextChar;
var
	intComp: Integer;
begin
	intComp := Length(inherited Text);
  if intComp < 11 then
  begin
	  if FCursorPos = intComp then Exit;
  end
  else
  	if FCursorPos = intComp - 1 then Exit;
  Inc(FCursorPos);
  SetCursorPos;
end;

procedure TCustomDataEdit<_DataType, _Data>.SelectFirstChar;
begin
  FCursorPos := 0;
  SetCursorPos;
end;

procedure TCustomDataEdit<_DataType, _Data>.GotoEnd;
var
	intComp: Integer;
begin
	intComp := Length(inherited Text);
 	FCursorPos := intComp;

  if intComp = 11 then
	  Dec(FCursorPos);

  SetCursorPos;
end;

procedure TCustomDataEdit<_DataType, _Data>.SetUseDataFormat(AValue: Boolean);
begin
	if FUseDataFormat = AValue then Exit;

  FUseDataFormat := AValue;
  FormatText;
end;

procedure TCustomDataEdit<_DataType, _Data>.SetValue(AValue: _DataType);
begin
	if FData.Compare(AValue, FValue) = 0 then Exit;
end;

function TCustomDataEdit<_DataType, _Data>.GetEmpty: Boolean;
begin
	Result := not FData.Validate(inherited Text, False);
end;

function TCustomDataEdit<_DataType, _Data>.ValidContent: Boolean;
begin
	Result := FData.Validate(inherited Text, False);
end;

procedure TCustomDataEdit<_DataType, _Data>.FormatText;
begin
  if FUseDataFormat then
    inherited Text := FData.Format(inherited Text);
end;

function TCustomDataEdit<_DataType, _Data>.ChangeValue: Boolean;
var
	str: String;
begin
	Result := False;
  str := inherited Text;

  if Modified and FData.Validate(str, False) then
  begin
    FValue := FData.ConvertToData(str);
    Modified := False;
    DoDataChange(FValue);
    Result := True;
  end;
end;

procedure TCustomDataEdit<_DataType, _Data>.DoDataChange(AData: _DataType);
begin
	if Assigned(FOnDataChange) then
  	FOnDataChange(Self, AData);
end;

procedure TCustomDataEdit<_DataType, _Data>.DoInvalidInputData(AData: AnsiString);
begin
	if Assigned(FOnInvalidInputData) then
  	FOnInvalidInputData(Self, AData);
end;

end.
