(***
 * DefaultDataEdit.pas;
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

unit DefaultDataEdit;

interface

uses
	SysUtils, Classes, DataEdit, Civil.Utils.Types.CPF, Civil.Utils.Types.CNPJ,
  Civil.Utils.Types.Telefone, RegularExpressions;

type

	TDataEdit<_DataType; _Data: IDataEdit<_DataType>, constructor> = class(TCustomDataEdit<_DataType,_Data>)
  public

  	property Value;
    property Empty;

  published

  	property UseDataFormat;

    property OnDataChange;
    property OnInvalidInputData;

  end; { TCNPJEdit }

  TDataCPF = class(TInterfacedObject, IDataEdit<TCPF>)
  strict private

  	class constructor CreateClass;

  	class var
      FDiag: TRegEx;

  public

  	// IDataEdit.Validate;
    function Validate(AData: AnsiString; AParcial: Boolean): Boolean;
    // IDataEdit.Format;
    function Format(AData: AnsiString): AnsiString;
  	// IDataEdit.Compare;
    function Compare(AData1, AData2: TCPF): Integer;
    // IDataEdit.ConvertToString;
    function ConvertToString(AData: TCPF): AnsiString;
    // IDataEdit.ConvertToData;
    function ConvertToData(AData: AnsiString): TCPF;
    // IDataEdit.NullValue;
    function NullValue: TCPF;

  end; { TDataCPF }

  TDataCNPJ = class(TInterfacedObject, IDataEdit<TCNPJ>)
  strict private

  	class constructor CreateClass;

  	class var
      FDiag: TRegEx;

  public

  	// IDataEdit.Validate;
    function Validate(AData: AnsiString; AParcial: Boolean): Boolean;
    // IDataEdit.Format;
    function Format(AData: AnsiString): AnsiString;
  	// IDataEdit.Compare;
    function Compare(AData1, AData2: TCNPJ): Integer;
    // IDataEdit.ConvertToString;
    function ConvertToString(AData: TCNPJ): AnsiString;
    // IDataEdit.ConvertToData;
    function ConvertToData(AData: AnsiString): TCNPJ;
    // IDataEdit.NullValue;
    function NullValue: TCNPJ;

  end; { TDataCNPJ }

  TDataTelefone = class(TInterfacedObject, IDataEdit<TTelefone>)
  strict private

  	class constructor CreateClass;

  	class var
      FDiag: TRegEx;

  public

  	// IDataEdit.Validate;
    function Validate(AData: AnsiString; AParcial: Boolean): Boolean;
    // IDataEdit.Format;
    function Format(AData: AnsiString): AnsiString;
  	// IDataEdit.Compare;
    function Compare(AData1, AData2: TTelefone): Integer;
    // IDataEdit.ConvertToString;
    function ConvertToString(AData: TTelefone): AnsiString;
    // IDataEdit.ConvertToData;
    function ConvertToData(AData: AnsiString): TTelefone;
    // IDataEdit.ConvertToData;
    function NullValue: TTelefone;

  end;

	TCPFEdit = class sealed(TDataEdit<TCPF, TDataCPF>);
  TCNPJEdit = class sealed(TDataEdit<TCNPJ, TDataCNPJ>);
  TTelefoneEdit = class sealed(TDataEdit<TTelefone, TDataTelefone>);

  procedure Register;

implementation

procedure Register;
begin
	Classes.RegisterComponents('Civil.SOFT', [TCPFEdit, TCNPJEdit, TTelefoneEdit]);
end;

(*
 * TDataCPF.
 * -----------------------------------------------------------------------------
 *)

class constructor TDataCPF.CreateClass;
begin
	FDiag := TRegEx.Create('^[0-9]{1,11}$', [roExplicitCapture, roCompiled]);
end;

function TDataCPF.Validate(AData: AnsiString; AParcial: Boolean): Boolean;
begin
	if AParcial then
		Result := FDiag.IsMatch(AData)
  else
  	Result := TCPF.ValidarCPF(AData);
end;

function TDataCPF.Format(AData: AnsiString): AnsiString;
var
	bff: TCPF;
begin
	Result := '';

	if not TCPF.ValidarCPF(AData) then Exit;

	bff := AData;
	Result := bff.Formatado;
end;

function TDataCPF.Compare(AData1: TCPF; AData2: TCPF): Integer;
begin
	Result := AnsiCompareStr(AData1, AData2);
end;

function TDataCPF.ConvertToString(AData: TCPF): AnsiString;
begin
	Result := AnsiString( AData );
end;

function TDataCPF.ConvertToData(AData: AnsiString): TCPF;
begin
  Result := AData;
end;

function TDataCPF.NullValue: TCPF;
begin
	Result := NULL_CPF;
end;

(*
 * TDataCNPJ.
 * -----------------------------------------------------------------------------
 *)

class constructor TDataCNPJ.CreateClass;
begin
	FDiag := TRegEx.Create('^[0-9]{1,14}$', [roExplicitCapture, roCompiled]);
end;

function TDataCNPJ.Validate(AData: AnsiString; AParcial: Boolean): Boolean;
begin
	if AParcial then
		Result := FDiag.IsMatch(AData)
  else
  	Result := TCNPJ.ValidarCNPJ(AData);
end;

function TDataCNPJ.Format(AData: AnsiString): AnsiString;
var
	bff: TCNPJ;
begin
	Result := '';

	if not TCNPJ.ValidarCNPJ(AData) then Exit;

	bff := AData;
	Result := bff.Formatado;
end;

function TDataCNPJ.Compare(AData1, AData2: TCNPJ): Integer;
begin
	Result := AnsiCompareStr(AData1, AData2);
end;

function TDataCNPJ.ConvertToString(AData: TCNPJ): AnsiString;
begin
	Result := AnsiString( AData );
end;

function TDataCNPJ.ConvertToData(AData: AnsiString): TCNPJ;
begin
	Result := AData;
end;

function TDataCNPJ.NullValue: TCNPJ;
begin
	Result := NULL_CNPJ;
end;

(*
 * TDataTelefone.
 * -----------------------------------------------------------------------------
 *)

class constructor TDataTelefone.CreateClass;
begin
  FDiag := TRegEx.Create('^[0-9]{1,11}$', [roExplicitCapture, roCompiled]);
end;

function TDataTelefone.Validate(AData: AnsiString; AParcial: Boolean): Boolean;
begin
	if AParcial then
		Result := FDiag.IsMatch(AData)
  else
  	Result := TTelefone.ValidarNumero(AData);
end;

function TDataTelefone.Format(AData: AnsiString): AnsiString;
var
	bff: TTelefone;
begin
	Result := '';

	if not TTelefone.ValidarNumero(AData) then Exit;

	bff := AData;
	Result := bff.Formatado;
end;

function TDataTelefone.Compare(AData1, AData2: TTelefone): Integer;
begin
	Result := AnsiCompareStr(AData1, AData2);
end;

function TDataTelefone.ConvertToString(AData: TTelefone): AnsiString;
begin
	Result := AnsiString( AData );
end;

function TDataTelefone.ConvertToData(AData: AnsiString): TTelefone;
begin
	Result := AData;
end;

function TDataTelefone.NullValue: TTelefone;
begin
	Result := NULL_TELEFONE;
end;

end.
