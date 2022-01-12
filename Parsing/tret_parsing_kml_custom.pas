unit tret_parsing_kml_custom;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, Vcl.StdCtrls, ActiveX;

type
  tret_ParsingKMLCustom = class(TThread)

    sender_LogText : TMemo;

    zt_pkc_File: string;
    zt_pkc_isDebug: Boolean;

  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

  procedure StartTreatIni(sender_LogText: TMemo; zt_pkc_File: String; zt_pkc_isDebug: Boolean = False);

  function kmlConvCoorToLongLat(aData: String): String;
  function kmlConvSingleCoor(aData: String; isLat: Boolean = true): String;


implementation
uses XMLIntf, XMLDoc;

procedure StartTreatIni(sender_LogText: TMemo; zt_pkc_File: String; zt_pkc_isDebug: Boolean);
var prosesT_parseKmlCustom: tret_ParsingKMLCustom;
begin

  prosesT_parseKmlCustom := tret_ParsingKMLCustom.Create(true);

    prosesT_parseKmlCustom.FreeOnTerminate := True;

    prosesT_parseKmlCustom.sender_LogText := sender_LogText;
    prosesT_parseKmlCustom.zt_pkc_File := zt_pkc_File;
    prosesT_parseKmlCustom.zt_pkc_isDebug := zt_pkc_isDebug;

  prosesT_parseKmlCustom.Start;

end;


function kmlConvCoorToLongLat(aData: String): String;
var sLongLat : TStringList;
    I: Integer;
begin
  sLongLat := TStringList.Create;
    sLongLat.Text := StringReplace(TRIM(aData), ',0 ', #13#10, [rfReplaceAll]);

    sLongLat[sLongLat.Count - 1] := StringReplace(sLongLat[sLongLat.Count - 1], ',0', '', []);

    for I := sLongLat.Count - 1 downto 0 do
    begin
      sLongLat[I] := TRIM(sLongLat[I]);
      if copy(sLongLat[I],Length(sLongLat[I])-1,2) = ',0' then sLongLat[I] := copy(sLongLat[I],0,Length(sLongLat[I])-2);

      if (TRIM(sLongLat[I]) = '') OR (TRIM(sLongLat[I]) = '0') then sLongLat.Delete(I);
    end;

    Result := sLongLat.Text;

  sLongLat.Free;
end;

function kmlConvSingleCoor(aData: String; isLat: Boolean = true): String;
var sLongLat : TStringList;
    I: Integer;
begin
  sLongLat := TStringList.Create;
    sLongLat.Text := StringReplace(TRIM(aData), ',0 ', #13#10, [rfReplaceAll]);
    sLongLat[sLongLat.Count - 1] := StringReplace(sLongLat[sLongLat.Count - 1], ',0', '', []);

    sLongLat.Text := StringReplace(sLongLat.Text, ',', #13#10, [rfReplaceAll]);

    for I := sLongLat.Count - 1 downto 0 do
    begin
      sLongLat[I] := TRIM(sLongLat[I]);
      if (TRIM(sLongLat[I]) = '') OR (TRIM(sLongLat[I]) = '0') then sLongLat.Delete(I);
    end;

    for I := sLongLat.Count - 1 downto 0 do
    begin
        if (isLat) then
        begin
          if ((I mod 2) = 0) then sLongLat.Delete(I);
        end else
        begin
          if ((I mod 2) <> 0) then sLongLat.Delete(I);
        end;
    end;

    Result := sLongLat.Text;

  sLongLat.Free;
end;


{ tret_ListingFiles }

procedure tret_ParsingKMLCustom.Execute;
var I, J, K, vI : Integer;
    Doc: IXMLDocument;
    ANode, BNode, CNode, DNode, PNode: IXMLNode;
    aTitle: String;
begin

  CoInitialize(nil);
  try
    if (FileExists(zt_pkc_File)) AND (LowerCase(ExtractFileExt(zt_pkc_File))='.kml') then
    begin
      try
        Doc := TXMLDocument.Create(nil);
        Doc.LoadFromFile(zt_pkc_File);
        ANode := Doc.DocumentElement;

        //memo1.Lines.Add(ANode.ChildNodes.no.NodeName);

        for I := 0 to ANode.ChildNodes.First.ChildNodes.Count-1 do
        begin
          BNode := ANode.ChildNodes.First.ChildNodes[I];


          if LowerCase(BNode.LocalName) = 'folder' then
          begin

            for J := 0 to BNode.ChildNodes.Count-1 do
            begin
              CNode := BNode.ChildNodes[J];
              //memo1.Lines.Add(CNode.NodeName);

              if LowerCase(CNode.LocalName) = 'placemark' then
              begin

                for K := 0 to CNode.ChildNodes.Count-1 do
                begin
                  DNode := CNode.ChildNodes[K];

                  if LowerCase(DNode.LocalName) = 'name' then
                  begin
                    aTitle := DNode.Text;
                    sender_LogText.Lines.Add('NAMA : '+aTitle);
                  end;

//                  if LowerCase(DNode.LocalName) = 'ExtendedData' then
//                  begin
//                    aTitle := DNode.Text;
//                    form1.memo1.Lines.Add('NAMA : '+aTitle);
//                  end;


                  if LowerCase(DNode.LocalName) = 'multigeometry' then
                  begin
                    //memo1.Lines.Add('COOR AMBIL : '+DNode.ChildNodes['Polygon'].ChildNodes['outerBoundaryIs'].ChildNodes['LinearRing'].ChildNodes['coordinates'].Text);

                    if zt_pkc_isDebug then
                    begin
                      PNode := DNode.ChildNodes['Polygon'];
                      vI := 0;
                      while Assigned(PNode) do
                      begin
                        if PNode.NodeName = 'Polygon' then
                        begin
                          vI := vI + 1;
                          sender_LogText.Lines.Add('==== #'+IntToStr(vI)+' DATA LONG LAT ====');
                          sender_LogText.Lines.Add(kmlConvCoorToLongLat(PNode.ChildNodes['outerBoundaryIs'].ChildNodes['LinearRing'].ChildNodes['coordinates'].Text));

                          sender_LogText.Lines.Add('==== #'+IntToStr(vI)+' DATA LONG ====');
                          sender_LogText.Lines.Add(kmlConvSingleCoor(PNode.ChildNodes['outerBoundaryIs'].ChildNodes['LinearRing'].ChildNodes['coordinates'].Text, False));

                          sender_LogText.Lines.Add('==== #'+IntToStr(vI)+' DATA LAT ====');
                          sender_LogText.Lines.Add(kmlConvSingleCoor(PNode.ChildNodes['outerBoundaryIs'].ChildNodes['LinearRing'].ChildNodes['coordinates'].Text, True));

                        end;

                        PNode := PNode.NextSibling
                      end;

                    end;
                  end;

                end;
              end;
            end;


          end;
        end;


        aTitle := StringReplace(aTitle, '___', ' ',[rfReplaceAll, rfIgnoreCase]);
        aTitle := StringReplace(aTitle, '__', ' ',[rfReplaceAll, rfIgnoreCase]);
        aTitle := StringReplace(aTitle, '_', ' ',[rfReplaceAll, rfIgnoreCase]);
        aTitle := StringReplace(aTitle, '/', '_',[rfReplaceAll, rfIgnoreCase]);
        aTitle := StringReplace(aTitle, '\', '_',[rfReplaceAll, rfIgnoreCase]);
        aTitle := StringReplace(aTitle, '  ', ' ',[rfReplaceAll, rfIgnoreCase]);

        //format SQL
      finally
        //
      end;

    end;
  finally
    CoUninitialize;
  end;


end;

end.
