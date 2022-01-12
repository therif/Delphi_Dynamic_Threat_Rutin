unit tret_Listing_Files;

interface

uses
  System.Classes, System.SysUtils, Vcl.StdCtrls, Vcl.ComCtrls;

type
  tret_ListingFiles = class(TThread)

    sender_ToDisplay : TObject;

    zt_lf_Path: string;
    zt_lf_Ext: string;
    zt_lf_IncDir: Boolean;
    zt_lf_Paused : Boolean;

    strToSendOut: String;

  private
    { Private declarations }
    procedure sendOutTextToDisplay;
  protected
    procedure Execute; override;
  end;

  procedure StartTreatIni(sender_ToDisplay: TObject; zt_lf_Path: String; zt_lf_Ext: String; zt_lf_IncDir: Boolean = False);


var
  prosesT_listingfiles: tret_ListingFiles;
  vr_ztlf_jml_file: Integer;
  vr_ztlf_listingfile_paused: Boolean;

implementation

procedure StartTreatIni(sender_ToDisplay: TObject; zt_lf_Path: String; zt_lf_Ext: String; zt_lf_IncDir: Boolean = False);
begin

  if not Assigned(prosesT_listingfiles) then
  begin
    prosesT_listingfiles := tret_ListingFiles.Create(true);
  end;

  prosesT_listingfiles.FreeOnTerminate := True;

  prosesT_listingfiles.sender_ToDisplay := sender_ToDisplay;
  prosesT_listingfiles.zt_lf_Path := zt_lf_Path;
  prosesT_listingfiles.zt_lf_Ext := zt_lf_Ext;
  prosesT_listingfiles.zt_lf_IncDir := zt_lf_IncDir;

  prosesT_listingfiles.Start;
end;

procedure GetAllFiles(aPath, aExt: string; blIncDir: Boolean = False);
var search: TSearchRec;
    aDirectory, mask: string;
begin

  if Assigned(prosesT_listingfiles) then
  begin
    if aExt = '*' then mask := '*.kml'
       else mask := '*.'+aExt;

    aDirectory := ExtractFilePath(aPath);

    // find all files
    //if FindFirst(directory+mask, $23, search) = 0 then
    if FindFirst(aDirectory+mask, $23, search) = 0 then
    begin
      repeat
        prosesT_listingfiles.strToSendOut := aDirectory + search.Name;
        prosesT_listingfiles.sendOutTextToDisplay;
        Inc(vr_ztlf_jml_file);
      until FindNext(search) <> 0;
    end;

    // Subdirectories/ Unterverzeichnisse
    if FindFirst(aDirectory + '*.*', faDirectory, search) = 0 then
    begin
      //if blIncDir then Form1.ListBox1.Items.Add(directory);

      repeat
        if ((search.Attr and faDirectory) = faDirectory) and (search.Name[1] <> '.') then
        begin
          if blIncDir then
          begin
            prosesT_listingfiles.strToSendOut := aDirectory + search.Name;
            prosesT_listingfiles.sendOutTextToDisplay;

            GetAllFiles(aDirectory + search.Name + '\' + ExtractFileName(mask), aExt, True);
          end else
          begin
            GetAllFiles(aDirectory + search.Name + '\' + ExtractFileName(mask), aExt);
          end;

        end;
      until FindNext(search) <> 0;
      FindClose(search);
    end;
  end;
end;

{ tret_ListingFiles }

procedure tret_ListingFiles.Execute;
begin
  { Place thread code here }

  GetAllFiles(zt_lf_Path,zt_lf_Ext,zt_lf_IncDir);
end;

procedure tret_ListingFiles.sendOutTextToDisplay;
begin
  if prosesT_listingfiles.sender_ToDisplay is TListBox then
  begin
    TListBox(prosesT_listingfiles.sender_ToDisplay).Items.Add(strToSendOut);
  end else
  if prosesT_listingfiles.sender_ToDisplay is TMemo then
  begin
    TMemo(prosesT_listingfiles.sender_ToDisplay).Lines.Add(strToSendOut);
  end else
  if prosesT_listingfiles.sender_ToDisplay is TRichEdit then
  begin
    TRichEdit(prosesT_listingfiles.sender_ToDisplay).Lines.Add(strToSendOut);
  end;
end;

end.
