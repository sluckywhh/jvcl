{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: JvProviderTreeListDsgnFrame.pas, released on --.

The Initial Developer of the Original Code is Marcel Bestebroer
Portions created by Marcel Bestebroer are Copyright (C) 2002 - 2003 Marcel
Bestebroer
All Rights Reserved.

Contributor(s):

Last Modified: 2003-11-12

You may retrieve the latest version of this file at the Project JEDI's JVCL home page,
located at http://jvcl.sourceforge.net

Known Issues:
-----------------------------------------------------------------------------}

{$I JVCL.INC}

unit JvProviderTreeListDsgnFrame;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, ImgList, Menus, ActnList,
  {$IFNDEF COMPILER6_UP} DsgnIntf, {$ELSE} DesignIntf, DesignEditors, {$ENDIF}
  JvDataProvider, JvProviderTreeListFrame;

type
  {$IFDEF COMPILER6_UP}
  IFormDesigner = IDesigner;
  {$ENDIF}
  TDsgFmeBeforeNewItem = procedure(Sender: TObject; Kind: Integer; var Allow: Boolean) of object;
  TDsgFmeAfterNewItem = procedure(Sender: TObject; Item: IJvDataItem) of object;
  
  TfmeJvProviderTreeListDsgn = class(TfmeJvProviderTreeList)
    alDesign: TActionList;
    pmDsgn: TPopupMenu;
    ilDsgn: TImageList;
    aiAddItem: TAction;
    aiDelete: TAction;
    aiClear: TAction;
    aiMoveUp: TAction;
    aiMoveDown: TAction;
    aiRename: TAction;
    miAddItem: TMenuItem;
    miDeleteItem: TMenuItem;
    miSep1: TMenuItem;
    miClear: TMenuItem;
    miMoveUp: TMenuItem;
    miMoveDown: TMenuItem;
    miSep2: TMenuItem;
    miRename: TMenuItem;
    ilIdentList: TImageList;
    procedure aiAddItemExecute(Sender: TObject);
    procedure aiDeleteExecute(Sender: TObject);
    procedure aiClearExecute(Sender: TObject);
    procedure aiMoveUpExecute(Sender: TObject);
    procedure aiMoveDownExecute(Sender: TObject);
    procedure alDesignUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure lvProviderEditing(Sender: TObject; Item: TListItem;
      var AllowEdit: Boolean);
    procedure lvProviderEdited(Sender: TObject; Item: TListItem;
      var S: String);
    procedure aiRenameExecute(Sender: TObject);
  private
    { Private declarations }
    FBeforeNewItem: TDsgFmeBeforeNewItem;
    FAfterNewItem: TDsgFmeAfterNewItem;
  protected
    function DoBeforeNew(Kind: Integer): Boolean;
    procedure DoAfterNew(Item: IJvDataItem);
  public
    { Public declarations }
    Designer: IFormDesigner;
    procedure UpdateActionStates; virtual;

    property BeforeNewItem: TDsgFmeBeforeNewItem read FBeforeNewItem write FBeforeNewItem;
    property AfterNewItem: TDsgFmeAfterNewItem read FAfterNewItem write FAfterNewItem;
  end;

implementation

uses
  Commctrl,
  JvTypes, JvDsgnConsts, JvConsts;

{$R *.DFM}

function TfmeJvProviderTreeListDsgn.DoBeforeNew(Kind: Integer): Boolean;
begin
  Result := True;
  if @FBeforeNewItem <> nil then
    BeforeNewItem(Self, Kind, Result);
end;

procedure TfmeJvProviderTreeListDsgn.DoAfterNew(Item: IJvDataItem);
begin
  if @FAfterNewItem <> nil then
    AfterNewItem(Self, Item);
end;

procedure TfmeJvProviderTreeListDsgn.UpdateActionStates;
var
  Item: IJvDataItem;
  Items: IJvDataItems;
  Man: IJvDataItemsManagement;
  Dsgn: IJvDataItemsDesigner;
  ParentMan: IJvDataItemsManagement;
  I: Integer;
  ItemText: IJvDataItemText;

  function MakeMenuItem(const Idx: Integer; const AOwner: TComponent): TMenuItem;
  var
    S: string;
  begin
    Dsgn.GetKind(Idx, S);
    Result := TMenuItem.Create(AOwner);
    Result.Caption := S;
    Result.OnClick := aiAddItem.OnExecute;
    Result.Tag := Idx;
  end;

begin
  if lvProvider.SelCount <> 0 then
  begin
    Item := GetDataItem(lvProvider.Selected.Index);
    if (Item <> nil) and Supports(Item, IJvDataItems, Items) then
    begin
      if Supports(Items, IJvDataItemsManagement, Man) then
        Supports(Items, IJvDataItemsDesigner, Dsgn);
    end;
    if (Item <> nil) then
      Item.GetItems.QueryInterface(IJvDataItemsManagement, ParentMan);
  end
  else
  begin
    if Supports(Provider.ProviderIntf, IJvDataItems, Items) then
    begin
      if Supports(Items, IJvDataItemsManagement, Man) then
        Supports(Items, IJvDataItemsDesigner, Dsgn);
    end;
  end;

  // Update action states
  miAddItem.Clear;
  if (Dsgn = nil) or (Dsgn.GetCount = 0) then
    miAddItem.Action := aiAddItem
  else
  begin
    miAddItem.Action := nil;
    miAddItem.OnClick := nil;
    for I := 0 to Dsgn.GetCount - 1 do
      miAddItem.Add(MakeMenuItem(I, miAddItem));
    miAddItem.Visible := Man <> nil;
    miAddItem.Enabled := (Man <> nil) and (Items <> nil);
  end;
  aiAddItem.Enabled := (Man <> nil) and (Items <> nil);
  aiDelete.Enabled := (ParentMan <> nil) and (Item <> nil) and (Item <> FVirtualRoot) and
    Item.IsDeletable;
  aiClear.Enabled := (Man <> nil) and (Items <> nil) and (Items.Count > 0);
  aiRename.Enabled := (Item <> nil) and (Item <> FVirtualRoot) and Item.IsDeletable and
    Supports(Item, IJvDataItemText, ItemText) and ItemText.Editable;
end;

procedure TfmeJvProviderTreeListDsgn.aiAddItemExecute(Sender: TObject);
var
  Item: IJvDataItem;
  Items: IJvDataItems;
  Dsgn: IJvDataItemsDesigner;
  Mangr: IJvDataItemsManagement;
begin
  if lvProvider.Selected <> nil then
  begin
    Item := GetDataItem(lvProvider.Selected.Index);
    if Item <> nil then
      Item.QueryInterface(IJvDataItems, Items)
    else // should never occur
      raise EJVCLException.Create(SDataItemNotFound);
  end
  else
    Items := Provider.ProviderIntf as IJvDataItems;
  Item := nil;
  if Items <> nil then
  begin
    if Supports(Items, IJvDataItemsDesigner, Dsgn) then
    begin
      if not DoBeforeNew(TMenuItem(Sender).Tag) then
        Exit;
      Item := Dsgn.NewByKind(TMenuItem(Sender).Tag);
    end
    else if Supports(Items, IJvDataItemsManagement, Mangr) then
    begin
      if not DoBeforeNew(-1) then
        Exit;
      Item := Mangr.New;
    end
    else // should never occur
      raise EJVCLException.CreateFmt(SDataProviderAddErrorReason, [SDataProviderNoManOrDsgn]);
    DoAfterNew(Item);
    if Item <> nil then
    begin
      SelectItemID(Item.GetID);
      if Designer <> nil then
        Designer.Modified;
    end
    else
      raise EJVCLException.Create(SDataProviderAddFailed);
  end
  else // should never occur
    raise EJVCLException.CreateFmt(SDataProviderAddErrorReason, [SDataProviderNoSubItems]);
end;

procedure TfmeJvProviderTreeListDsgn.aiDeleteExecute(Sender: TObject);
var
  I: Integer;
  Item: IJvDataItem;
  Items: IJvDataItems;
  Mangr: IJvDataItemsManagement;
begin
  if lvProvider.Selected <> nil then
  begin
    Provider.Enter;
    try
      I := lvProvider.Selected.Index;
      Item := GetDataItem(I);
      if Item <> nil then
        Items := Item.GetItems
      else
        raise EJVCLException.Create(SDataItemNotFound);
      if Supports(Items, IJvDataItemsManagement, Mangr) then
      begin
        if I > 0 then
          SelectItemID(GetDataItem(I - 1).GetID)
        else
          SelectItemID('');
        Mangr.Remove(Item);
        if Designer <> nil then
          Designer.Modified;
        { Temporary fix: for some reason the item is removed from the ViewList at some point during
          the delete process, but is then added again! This does not happen at run time but I can
          not find the location where it does gets added again. }
        if GetViewList <> nil then
          GetViewList.RebuildView;
      end
      else
        raise EJVCLException.CreateFmt(SDataProviderDeleteErrorReason, [SDataProviderNoMan]);
    finally
      Provider.Leave;
    end;
  end;
  Items := nil;
  Mangr := nil;
  Item := nil;
end;

procedure TfmeJvProviderTreeListDsgn.aiClearExecute(Sender: TObject);
var
  Item: IJvDataItem;
  Items: IJvDataItems;
  Mangr: IJvDataItemsManagement;
begin
  if lvProvider.Selected <> nil then
  begin
    Item := GetDataItem(lvProvider.Selected.Index);
    if Item <> nil then
    begin
      if not Supports(Item, IJvDataItems, Items) then
        raise EJVCLException.CreateFmt(SDataProviderDeleteErrorReason, [SDataProviderNoSubItems]);
    end
    else
      raise EJVCLException.Create(SDataItemNotFound);
    if Supports(Items, IJvDataItemsManagement, Mangr) then
    begin
      Mangr.Clear;
      if Designer <> nil then
        Designer.Modified;
    end
    else
      raise EJVCLException.CreateFmt(SDataProviderDeleteErrorReason, [SDataProviderNoMan]);
  end;
end;

procedure TfmeJvProviderTreeListDsgn.aiMoveUpExecute(Sender: TObject);
begin
  inherited;
//
end;

procedure TfmeJvProviderTreeListDsgn.aiMoveDownExecute(Sender: TObject);
begin
  inherited;
//
end;

procedure TfmeJvProviderTreeListDsgn.alDesignUpdate(Action: TBasicAction;
  var Handled: Boolean);
begin
  inherited;
  if Action = aiAddItem then
    UpdateActionStates;
end;

procedure TfmeJvProviderTreeListDsgn.lvProviderEditing(Sender: TObject;
  Item: TListItem; var AllowEdit: Boolean);
begin
  inherited;
  AllowEdit := aiRename.Enabled and aiRename.Visible;
end;

procedure TfmeJvProviderTreeListDsgn.lvProviderEdited(Sender: TObject;
  Item: TListItem; var S: String);
var
  DataItem: IJvDataItem;
  ItemText: IJvDataItemText;
begin
  Provider.Enter;
  try
    DataItem := GetDataItem(Item.Index);
    if Supports(DataItem, IJvDataItemText, ItemText) then
      ItemText.Caption := S;
  finally
    Provider.Leave;
  end;
end;

procedure TfmeJvProviderTreeListDsgn.aiRenameExecute(Sender: TObject);
begin
  if lvProvider.Selected <> nil then
  begin
    lvProvider.SetFocus;
    ListView_EditLabel(lvProvider.Handle, lvProvider.Selected.Index);
  end;
end;

end.
