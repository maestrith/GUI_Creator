#SingleInstance,Force
global window,conxml,v:=[],settings:=new XML("settings","lib\Settings.xml"),TreeView:=new XML("TreeView")
FileCheck(),Gui()
/*
	
	When adding a control from the TV make sure to check to see if it overlaps any other control
	if it does
		move it to a blank area then update its position.
	
	make a setting for GroupBoxes for dragging contents
	have it ask if you want things dragged into the tab (and maybe which tab)
	
	Test GUI needs to be a DynaRun and it needs to add GuiClose() and GuiEscape()
	
	re-explore the WheelDown/WheelUp to change edit modes
	give it a StatusBar to display the mode or window title
	escape de=selects all
	change{
		first item to:{
			for anything that is just Text
				Control Text:
			for anything that needs a list
				Control List:
			for Tab
				Control Tabs:
			and so on
		}
	}
	info window{
		have the add items display the hotkeys
	}
	FORCE{
		on new window force a name
		have it changable but make it clean
	}
	Tab Logic{
		when you make a tab control
		<control type="tab">
		<tab tab="1">
		if you add tabs
			add the <tab tab="A_Index"> per tab|dec|la|ra|tion
		
		also you know how to insert before so you don't need to re-build the tab list
		every time you make a new one, just insert it numerically where it belongs
		
		make the edit label into edit tabs and create a listview for adding/subtracting
		also make it so you can move controls from one tab to another easily
		maybe a treeview rather than a listview so you can show what controls are where
		on click of the control show the tab that it is on and "select" it
		
		if change tabs and and dec|la|ra is less than <tab>.length{
			WARN! and ask what to do with the orphaned tab items
			if delete
				delete the controls
			else
				Ask where to move the tabs
		}
	}
*/
MakeBackground(){
	ea:=settings.EA("//settings/grid"),Dot:=ea.Dot?ea.Dot:0,Grid:=ea.Grid!=""?ea.Grid:0xAAAAAA
	dot:=RGB(dot),Grid:=RGB(Grid)
	Image:=ComObjCreate("WIA.ImageFile"),vector:=ComObjCreate("WIA.Vector"),Dot+=0,Grid+=0,vector.Add(Dot)
	loop,99
		vector.Add(Grid)
	Image:=vector.Imagefile(10,10)
	FileDelete,tile.bmp
	Image.SaveFile("tile.bmp"),Display_Grid("removebrush")
	WinSet,Redraw,,% hwnd([3])
}
GetInfo(hotkey){
	MouseGetPos,x,y
	xx:=x,yy:=y
	ControlGetPos,cx,cy,cw,ch,,% hwnd([3])
	if(x>cx&&x<cx+cw&&y>cy+v.Caption&&y<cy+ch)
		x:=x-cx,y:=y-cy,Grid(x,y,1)
	else
		x:=0,y:=0
	value:=hotkey="TreeView"?"":Hotkey="DateTime"?"LongDate":Hotkey="Progress"?100:Hotkey
	if(hotkey="picture"){
		FileSelectFile,value,,,Select an image,*.bmp;*.jpg;*.gif;*.png
		if(ErrorLevel||value="")
			return
		if(!FileExist(value))
			return
	}
	undo.Add()
	control:=window.Add("gui/window/control",{type:hotkey,x:x,y:y,value:value},,1)
	pos:=WinPos(xx,yy),con:=window.SSN("//*[@x<" pos.x " and @x+@w>" pos.x " and @y<" pos.y " and @y+@h>" pos.y " and @type='Tab' or @type='Tab2']")
	if(con){
		tt:=xml.EA(con),nn:=GetClassNN(tt.hwnd)
		top:=window.SSN("//control[@hwnd='" tt.hwnd "']")
		ControlGet,tabnum,tab,,%nn%,% hwnd([3])
		Gui,3:Tab,%tabnum%,% SubStr(nn,16)
		if !tb:=SSN(top,"tab[@tab='" tabnum "']")
			tb:=window.Under(top,"tab",{tab:tabnum,hwnd:tt.hwnd})
		tb.SetAttribute("hwnd",tt.hwnd)
		tb.AppendChild(control)
		new:=AddControl(control)
	}else
		new:=AddControl(control)
	Debug(),Eval(),undo.redo:=[]
}
Convert_Hotkey(key){
	StringUpper,key,key
	for a,b in [{Shift:"+"},{Ctrl:"^"},{Alt:"!"}]
		for c,d in b
			key:=RegExReplace(key,"\" d,c "+")
	return key	
}
RGB(c){
	SetFormat,IntegerFast,H
	c:=(c&255)<<16|(c&65280)|(c>>16),c:=SubStr(c,1)
	SetFormat,IntegerFast,D
	return c
}
Display_Grid(x:=""){
	Static wBrush
	if (x="removebrush")
		wBrush:=""
	if(A_Gui!=3)
		return
	if(settings.SSN("//options/Display_Grid").text)
		tile:="tile.bmp"
	else
		return
	If(!wBrush)
		wBrush:=DllCall("CreatePatternBrush",UInt,DllCall("LoadImage",Int,0,Str,"tile.bmp",Int,0,Int,0,Int,0,UInt,0x2010,"UInt"),"UInt")
	Return wBrush
}
Grid(ByRef x,ByRef y,adjust:=0){
	if adjust
		x-=v.Border,y-=v.border+v.caption
	if settings.SSN("//options/Snap_To_Grid").text
		x:=Round(x,-1),y:=Round(y,-1)
}
AddControl(info){
	ea:=xml.EA(info)
	for a,b in {x:ea.x,y:ea.y,w:ea.w,h:ea.h}
		if(b~="\d")
			pos.=a b " "
	if(ea.type="ListView")
		pos.=" -Multi"
	value:=ea.value~="(ComboBox|DDL|DropDownList)"?ea.value "||":ea.value
	notify:=(ea.type~="Tab")?"gtabnotify":""
	/*
		ea.type:=ea.type="DropDownList"?"ComboBox":ea.type
	*/
	if(ea.font){
		Gui,3:Font,% CompileFont(info),% ea.font
		Gui,3:Add,% ea.type,%pos% hwndhwnd %notify% %Disable%,% value
		Gui,3:Font
	}else{
		Gui,3:Add,% ea.type,%pos% hwndhwnd %notify% %disable%,% value
	}
	if(ea.type="TreeView"){
		Gui,3:Default
		TV_Add("Treeview (Placeholder)")
	}if(InStr(ea.type,"tab"))
		Gui,3:Tab
	ControlGetPos,x,y,w,h,,ahk_id%hwnd%
	wh:=!(ea.type~="(ComboBox|DDL|DropDownList)")?[["w",w],["h",h]]:[["w",w]]
	for a,b in wh
		info.SetAttribute(b.1,b.2)
	info.SetAttribute("hwnd",hwnd+0)
	WinGet,cl,ControlListHWND,% hwnd([3])
	if(ea.type~="ComboBox|ListView|DropDownList|DDL"){
		for a,b in StrSplit(cl,"`n")
			if !window.SSN("//*[@hwnd='" b+0 "']")
				info.SetAttribute("married",b+0)
	}Debug()
	return info
}
Debug(info:=""){
	if(info=0)
		if(hwnd(55))
			return hwnd({rem:55})
	if(!settings.SSN("//options/Debug_Window").text)
		return
	if(!hwnd(55)){
		Gui,55:Destroy
		Gui,55:Default
		Gui,+hwndhwnd +Resize
		hwnd(55,hwnd)
		Gui,Margin,0,0
		Gui,Add,Edit,x0 y0 w900 h300 -Wrap
		Gui,Show,x0 y0 NA,Debug
		Gui,1:+AlwaysOnTop
		Gui,1:-AlwaysOnTop
	}info:=info?info:window
	Loop,2
		info.Transform()
	text:=info[]?info[]:window[]
	ControlSetText,Edit1,%text%,% hwnd([55])
	return
	55GuiEscape:
	55GuiClose:
	hwnd({rem:55})
	return
	55GuiSize:
	GuiControl,55:Move,Edit1,w%A_GuiWidth% h%A_GuiHeight%
	return
}
tv(){
	tv:
	if(A_GuiEvent!="Normal")
		return
	if((current:=TreeView.SSN("//*[@tv='" A_EventInfo "']")).ParentNode.nodename="Add"){
		GetInfo(current.nodename)
	}else if(tv:=TreeView.SSN("//*[@tv='" A_EventInfo "']")){
		ea:=xml.EA(tv),Control:=window.SSN("//*[@hwnd='" SSN(tv.ParentNode,"@hwnd").text "']"),ItemInfo:=xml.EA(Control),undo.add()
		if (ea.value~="(x|y|w|h)"){
			InputBox,newvalue,Enter a new value,% "Enter a new value for " conxml.SSN("//*[@value='" ea.value "']/@desc").text,,,,,,,,% ItemInfo[ea.value]
			if ErrorLevel
				return
			if RegExMatch(newvalue,"\D")
				return m("Must be an integer")
			Gui,2:Default
			if (tv.ParentNode.nodename="all"){
				sel:=window.SN("//control[@selected='1']")
				while,Control:=sel.Item[A_Index-1]{
					Control.SetAttribute(ea.value,newvalue),new:=xml.EA(Control)
					info:=TreeView.SSN("//*[@hwnd='" new.hwnd "']/*[@value='" ea.value "']"),info:=xml.EA(info)
					TV_Modify(info.tv,"",info.desc " = " newvalue)
					GuiControl,3:movedraw,% new.hwnd,% ea.value newvalue
				}
			}else{
				Control:=window.SSN("//*[@hwnd='" SSN(tv.ParentNode,"@hwnd").text "']")
				info:=TreeView.SSN("//*[@hwnd='" SSN(control,"@hwnd").text "']/*[@value='" ea.value "']"),info:=xml.EA(info)
				TV_Modify(info.tv,"",info.desc " = " newvalue)
				Control.SetAttribute(ea.value,newvalue),new:=xml.EA(Control)
				GuiControl,3:movedraw,% new.hwnd,% ea.value newvalue
			}
		}else if(ea.value~="\b(v|g)\b"){
			InputBox,newvalue,Enter a new value,% "Enter a new value for " conxml.SSN("//*[@value='" ea.value "']/@desc").text,,,,,,,,% ItemInfo[ea.value]
			if ErrorLevel
				return
			newvalue:=Clean(newvalue)
			if(ea.value="g"){
				sel:=window.SN("//control[@selected='1']")
				while,ss:=sel.Item[A_Index-1]{
					if label:=window.SSN("//label[@name='" SSN(ss,"@g").text "']"){
						if(newvalue="")
							label.ParentNode.RemoveChild(label)
						else
							label.SetAttribute("name",newvalue)
					}
					tv:=TreeView.SSN("//*[@hwnd='" SSN(ss,"@hwnd").text "']/info[@value='g']/@tv").text
					if(newvalue="")
						ss.RemoveAttribute("g"),TV_Modify(tv,"","G-Label")
					else
						ss.SetAttribute("g",newvalue)TV_Modify(tv,"","G-Label = " newvalue)
				}
			}if(ea.value="v"){
				tv:=TreeView.SSN("//*[@hwnd='" SSN(Control,"@hwnd").text "']/info[@value='v']/@tv").text
				if(newvalue="")
					Control.RemoveAttribute("v"),TV_Modify(tv,"","Variable")
				else
					Control.SetAttribute("v",newvalue)TV_Modify(tv,"","Variable = " newvalue)
				
			}
		}else if(ea.value="font"){
			ea:=xml.EA(control)
			if !ea.font
				ea:=window.EA("//control[@selected='1']")
			Dlg_Font(ea,1,hwnd(1))
			selected:=window.SN("//control[@selected='1']")
			while,Control:=selected.Item[A_Index-1]{
				for a,b in ea
					if(a~="i)(bold|italic|strikeout|color|font|size|underline)")
						Control.SetAttribute(a,b)
				con:=xml.EA(Control)
				style:=CompileFont(Control),name:=ea.font
				Gui,3:Font
				Gui,3:Font,%style%,%name%
				GuiControl,3:Font,% con.hwnd
				GuiControl,% "3:+c" ea.color,% con.hwnd
				WinSet,Redraw,,% hwnd([3])
				Gui,3:Font
			}
		}else if(ea.value="value"){
			InputBox,new,Input Required,% "Input a new value for " ea.desc,,,,,,,,% ItemInfo[ea.value]
			if ErrorLevel
				return
			ea:=xml.EA(control),control.SetAttribute("value",new)
			GuiControl,3:,% ea.hwnd,% _:=ea.value~="i)tab|tab2|ComboBox|DropDownList"?"|" new:new
			if((iteminfo.type="ComboBox"||iteminfo.type="DropDownList")&&!InStr(new,"||"))
				GuiControl,3:Choose,% ea.hwnd,1
		}else if(ea.value="option"){
			InputBox,new,Additional Options,% "Input a value for" ea.desc,,,,,,,,% ItemInfo[ea.value]
			if ErrorLevel
				return
			control.SetAttribute("option",new),ea:=xml.EA(control)
		}
		else if(tv.nodename="windowtitle"){
			node:=window.SSN("//window")
			InputBox,new,Enter New Name,Please enter the new name for the window title,,,,,,,,% SSN(node,"@windowtitle").text
			if(ErrorLevel)
				return
			node.SetAttribute("windowtitle",new)
		}
		else if(tv.nodename="windowname"){
			node:=window.SSN("//window")
			InputBox,new,Enter New Name,Please enter the new name for the window title,,,,,,,,% SSN(node,"@windowname").text
			if(ErrorLevel)
				return
			node.SetAttribute("windowname",Clean(new))
		}
		Highlight(),DisplaySelected()
		SetTimer,Redraw,-100
	}
	return
}
Highlight(a:=""){
	if(A_Gui>3&&a!="show")
		return
	hwnd({rem:99})
	Gui,99:+LastFound +owner1 +E0x20 -Caption +hwndsh
	hwnd(99,sh)
	WinSet,TransColor,0xF0F0F0 100
	Gui,99:Color,0xF0F0F0,0xFF
	Gui,99:Default
	WinGetPos,x,y,w,h,% hwnd([3])
	x+=v.Border,y+=v.border+v.Caption,h-=(v.Border*2)+(v.Caption),w-=(v.Border*2)
	Gui,99:Show,x%x% y%y% w%w% h%h% NoActivate
	ll:=window.SN("//control[@selected='1']/@hwnd")
	while,l:=ll.item(A_Index-1).text{
		ControlGetPos,cx,cy,w,h,,ahk_id%l%
		if (cx&&cy&&w&&h){
			pos:=WinPos(cx,cy)
			Gui,Add,Progress,% "c" color " x" pos.x " y" pos.y " w" w " h" h,100
		}
	}
	if a=0
		SetTimer,Redraw,-10
}
Redraw(win:=3){
	WinSet,Redraw,,% hwnd([win])
}
Exit(close:=0){
	GuiClose:
	WinGetPos,xx,yy,w,h,% hwnd([1])
	adj:=Adjust(xx,yy,w,h),att:={main:{x:xx,y:yy,w:adj.w,h:adj.h-v.menu}}
	for a,b in {settings:2,workarea:3}{
		ControlGetPos,x,y,w,h,,% hwnd([b])
		adjust:=Adjust(x,y,w,h)
		att[a]:={x:adjust.x,y:adjust.y-v.menu,w:adjust.w,h:adjust.h}
	}
	for a,b in att
		settings.Add("gui/" a,att[a])
	file:=window.SSN("//filename").text
	settings.Add("last",,file),settings.Save(1)
	temp:=new XML("project",file),rem:=window.SN("//*")
	while,rr:=rem.Item[A_Index-1]
		for a,b in StrSplit("offsetx,offsety,married,hwnd,ow,oh",",")
			rr.RemoveAttribute(b)
	if !(temp[]==window[]){
		MsgBox,35,File Changed,Would you like to save your GUI?
		if !FileExist(file)
			rem:=window.SSN("//filename"),rem.ParentNode.RemoveChild(rem)
		IfMsgBox,Yes
			Save()
		IfMsgBox,Cancel
			return
	}
	if(close)
		return New()
	ExitApp
	return
}
Hotkeys(state:=1){
	state:=state?"On":"Off"
	Hotkey,IfWinActive,% hwnd([1])
	hotkey:=settings.SN("//hotkeys/*[@hotkey!='']/@hotkey")
	while,key:=hotkey.item[A_Index-1].text
		Hotkey,%key%,Hotkey,%state%
	return
	Hotkey:
	hotkey:=settings.SSN("//*[@hotkey='" A_ThisHotkey "']").NodeName
	MouseGetPos,,,,Control,2
	if(control+0!=hwnd(3))
		if(window.SSN("//*[@hwnd='" control+0 "']/@type").text~="i)Tab|Tab2|ComboBox|GroupBox"=0){
			ControlSend,,{%A_ThisHotkey%},ahk_id%control%
			return
		}
	if(IsFunc(hotkey))
		%hotkey%()
	else if(hotkey~="(" Menu({menu:1}).Add ")")
		GetInfo(hotkey)
	return
}
Edit_Hotkeys(){
	static tv:=[]
	Gui,4:Destroy
	Gui,4:Default
	Gui,Add,TreeView,w300 r20
	Gui,Add,Button,gedithotkey Default,Edit Hotkey
	menu:=Menu({menu:1}),tv:=[],Hotkeys(0)
	for a,b in Menu.order{
		for c,d in StrSplit(Menu[b],"|"){
			if !tv[b]
				root:=tv[b]:=TV_Add(b)
			if !(settings.SSN("//hotkeys/" Clean(d)))
				settings.Add("hotkeys/" Clean(d),{menu:d})
			tv[TV_Add(GetMenuItem(d,1),root,"Vis")]:={parent:b,xml:settings.SSN("//hotkeys/" Clean(d))}
		}
	}
	TV_Modify(TV_GetChild(0),"Select Vis Focus")
	Gui,4:Show,,Hotkeys
	return
	4GuiEscape:
	Gui,4:Destroy
	Hotkeys()
	return
	edithotkey:
	Gui,4:Default
	value:=tv[TV_GetSelection()]
	oldmenu:=GetMenuItem(SSN(value.xml,"@menu").text)
	InputBox,new,New Hotkey,Enter a new hotkey,,,,,,,,% SSN(value.xml,"@hotkey").text
	if ErrorLevel
		return
	value.xml.SetAttribute("hotkey",new)
	newmenu:=GetMenuItem(SSN(value.xml,"@menu").text)
	Menu,% value.parent,Rename,%oldmenu%,%newmenu%
	TV_Modify(TV_GetSelection(),"",GetMenuItem(SSN(value.xml,"@menu").text,1))
	return
}
Adjust(ByRef x,ByRef y,w:="",h:=""){
	if(IsObject(x)=0&&y!=""&&x!=""&&w&&h)
		return {x:x-v.Border,y:y-(v.Border+v.Caption),w:w-(v.Border*2),h:h-(v.Border*2+v.Caption)}
	if(IsObject(x)=0&&y&&x)
		return {x:x-v.Border,y:y-(v.Border+v.Caption)}
}
New(){
	Gui,3:Destroy
	Gui,3:+Resize +hwndhwnd -0x20000 -0x10000 +parent1 -ToolWindow 
	hwnd(3,hwnd),ea:=settings.EA("//gui/workarea"),pos:=""
	Gui,3:Show,% GuiPos("//gui/workarea","x176 y5 w500 h500"),Work Area
	Gui,3:Margin,0,0
	window:=new XML("gui"),Display_Grid(),Select(0,0)
	WinSet,Redraw,,% hwnd([3])
}
Save(filename:=""){
	if(!FileExist("Projects"))
		FileCreateDir,Projects
	Loop,2
		window.Transform()
	if(!(filename)){
		if !filename:=window.SSN("//filename").text
			FileSelectFile,filename,S16,%A_ScriptDir%\Projects,Save Project As,*.xml
		if ErrorLevel
			return
		filename:=InStr(filename,".xml")?filename:filename ".xml"
	}
	window.Add("filename",,filename),filename:=SubStr(filename,-3)!=".xml"?filename ".xml":filename,window.file:=filename
	ControlGetPos,x,y,w,h,,% hwnd([3])
	att:={x:x,y:y,w:w,h:h},window.Add("workarea",att),window.Transform(),window.Save(1)
	SplitPath,filename,file
	TrayTip,GUI Creator,File '%file%' has been saved
	WinSetTitle,% hwnd([1]),,GUI Creator: %file%
	Debug()
}
Move(){
	MouseGetPos,x,y,win,Ctrl,2
	pos:=WinPos(x,y),moved:=0,ctrl+=0,xx:=x,yy:=y,lastx:=x,lasty:=y
	if !control:=window.SSN("//*[@hwnd='" ctrl "' or @married='" ctrl "']")
		control:=window.SSN("//window/*[@x<" pos.x " and @y<" pos.y " and @x+@w>" pos.x " and @y+@h>" pos.y "]")
	if(ctrl=hwnd(3)&&control.xml="")
		return pos:=WinPos(x,y),Select(pos.x,pos.y)
	if((control.nodename!="control")||(win!=hwnd(1)||ctrl=hwnd("tv")))
		return
	Gui,99:Destroy
	if(control+0=hwnd("tv"))
		return
	ea:=xml.EA(control)
	list:=ea.selected?window.SN("//control[@selected='1']/descendant-or-self::control"):window.SN("//control[@hwnd='" ea.hwnd "']/descendant-or-self::control")
	while,ll:=list.Item[A_Index-1]
		ea:=xml.EA(ll),ll.SetAttribute("offsetx",ea.x-pos.x),ll.SetAttribute("offsety",ea.y-pos.y)
	if(list.length){
		while,GetKeyState("LButton"){
			MouseGetPos,xx,yy
			if(Abs(x-xx)>3||Abs(y-yy)>3){
				while,ll:=list.item[A_Index-1],ea:=xml.EA(ll)
					if(ea.type="DropDownList")
						SendMessage,0x14F,0,0,,% "ahk_id" ea.hwnd
				undo.add()
				break
			}
		}
		if(Abs(x-xx)=0&&Abs(y-yy)=0)
			return CreateSelection(window.SN("//*[@hwnd='" SSN(control,"@hwnd").text "']"))
		if(GetKeyState("shift")){
			SetTimer,Resize,-1
			return
		}
		while,GetKeyState("LButton"){
			MouseGetPos,xx,yy
			if(Abs(lastx-xx)>0||Abs(lasty-yy)>0){
				pos:=WinPos(xx,yy)
				while,ll:=list.Item[A_Index-1],ea:=xml.EA(ll){
					nx:=pos.x+ea.offsetx,ny:=pos.y+ea.offsety,Grid(nx,ny)
					GuiControl,3:MoveDraw,% ea.hwnd,% "x" nx " y" ny
					ll.SetAttribute("x",nx),ll.SetAttribute("y",ny)
				}
			}
			lastx:=xx,lasty:=yy
		}
	}
	pos:=WinPos(xx,yy),con:=window.SSN("//*[@x<" pos.x " and @x+@w>" pos.x " and @y<" pos.y " and @y+@h>" pos.y " and @type='Tab' or @type='Tab2']")
	if con
		AddToTab(con,list)
	UpdateTV(list),Eval(),Highlight(),Debug(),DisplaySelected()
	return
}
Select(xx,yy){
	Random,Color,0xcccccc,0xeeeeee
	Gui,59:-Caption +AlwaysOnTop +E0x20 +hwndselect +Owner1
	WinGetPos,wx,wy,ww,wh,% hwnd([3])
	WinGetPos,mx,my,,,% hwnd([1])
	Gui,59:Color,%Color%
	Gui,59:Show,% "x" wx+v.border " y" wy+v.border+v.caption " w" ww-(v.border*2) " h" wh-(v.border*2)-v.Caption " noactivate hide"
	Gui,59:Show,NoActivate
	WinSet,Transparent,50,ahk_id%select%
	while,GetKeyState("LButton"){
		MouseGetPos,x,y
		x:=x-(wx-mx)-v.Border,y:=y-(wy-my)-v.Border-v.Caption
		WinSet,Region,%xx%-%yy% %x%-%yy% %x%-%y% %xx%-%y% %xx%-%yy%,ahk_id %select%
	}
	start:={x:xx,y:yy},end:={x:x,y:y},pos:=[],pos.x:=[],pos.y:=[]
	for a,b in [start,end]
		pos.x[b.x]:=1,pos.y[b.y]:=1
	Gui,59:Destroy
	List:=window.SN("//*[@x>" pos.x.MinIndex() " and @x<" pos.x.MaxIndex() " and @y>" pos.y.MinIndex() " and @y<" pos.y.MaxIndex() "]"),CreateSelection(list)
}
CreateSelection(selections,toggle:=0){
	if((GetKeyState("Control","P")=0&&GetKeyState("Shift","P")=0)&&toggle=0){
		sel:=window.SN("//window/descendant::control[@selected]")
		while,ss:=sel.Item[A_Index-1]
			ss.RemoveAttribute("selected")
	}
	while(ss:=selections.item[A_Index-1]){
		if(ss.NodeName!="control")
			Continue
		if ((GetKeyState("Control","P")||toggle)&&SSN(ss,"@selected").text)
			ss.RemoveAttribute("selected")
		else
			ss.SetAttribute("selected",1)
	}
	Highlight(),DisplaySelected(),Debug()
}
Inside(inside){
		pos:=xml.EA(inside)
		return window.SN("//*[@x>" pos.x " and @x<" pos.x+pos.w " and @y>" pos.y " and @y<" pos.y+pos.h "]")
}
DisplaySelected(){
	static lastselected,type:={windowname:"Window Name",windowtitle:"Window Title"}
	selected:=window.SN("//control[@selected='1']"),top:=TreeView.SSN("//selected")
	Gui,2:Default
	GuiControl,2:-Redraw,SysTreeView321
	sel:=TreeView.SN("//control")
	while,ss:=sel.Item[A_Index-1]
		if !window.SSN("//*[@hwnd='" SSN(ss,"@hwnd").text "']/@selected")
			TV_Delete(SSN(ss,"@tv").text),ss.ParentNode.RemoveChild(ss)
	if(selected.length>1){
		if all:=TreeView.SSN("//all")
			TV_Delete(SSN(all,"@tv").text),all.ParentNode.RemoveChild(all)
		all:=TreeView.Under(top,"all",{tv:TV_Add("All Controls",SSN(top,"@tv").text,"First")})
		constants:=conxml.SN("//constants/info")
		while,cc:=constants.Item[A_Index-1]
			if !SSN(all,"*[@value='" SSN(cc,"@value").text "']")
				TreeView.Under(all,"allset",{value:SSN(cc,"@value").text,tv:TV_Add(SSN(cc,"@desc").text,SSN(all,"@tv").text)})
		while,ss:=selected.Item[A_Index-1]{
			ea:=xml.EA(ss),info:=xml.EA(conxml.SSN("//" ea.type)),info.v:=1,info.value:=1
			for a in info
				if rem:=TreeView.SSN("//allset[@value='" a "']")
					TV_Delete(SSN(rem,"@tv").text),rem.ParentNode.RemoveChild(rem)
		}
		TV_Modify(SSN(all,"@tv").text,"Expand")
	}else if(selected.length<=1)
		if all:=TreeView.SSN("//all")
			TV_Delete(SSN(all,"@tv").text),all.ParentNode.RemoveChild(all)
	/*
		Work on:
		-Add all of the main info to the control itself
		--Add optional stuff below it like all of the extra settings for the controls
		-Fix the "All" edits in the tv
		--make it move all the selected stuff.
	*/
	while,ss:=selected.Item[A_Index-1],ea:=xml.EA(ss){
		if !tvi:=TreeView.SSN("//control[@hwnd='" SSN(ss,"@hwnd").text "']"){
			constants:=conxml.SN("//" ea.type "/constants|//constants/*"),rem:=xml.EA(conxml.SSN("//" ea.type))
			next:=TreeView.Under(top,"control",{hwnd:ea.hwnd,tv:TV_Add(ea.type,SSN(top,"@tv").text,"Vis")})
			while,cc:=constants.Item[A_Index-1],cea:=xml.EA(cc)
				if !rem[cea.value]
					value:=(vv:=SSN(ss,"@" cea.value).text)?cea.desc " = " vv:cea.desc,TreeView.Under(next,"info",{tv:TV_Add(value,SSN(next,"@tv").text),value:cea.value,desc:cea.desc})
			TV_Modify(SSN(next,"@tv").text,"Expand")
		}else{
			set:=SN(tvi,"descendant::*")
			while,sc:=set.item[A_Index-1],sa:=xml.EA(sc)
				TV_Modify(sa.tv,"",sa.desc _:=ea[sa.value]?" = " ea[sa.value]:"")
		}
	}
	ea:=xml.EA(window.SSN("//window"))
	for a,b in ea{
		text:=b?type[a] " = " b:type[a]
		node:=TreeView.SSN("//" a)
		TV_Modify(SSN(node,"@tv").text,"",text)
	}
	GuiControl,2:+Redraw,SysTreeView321
	TV_Modify(TreeView.SSN("//Add/@tv").text,selected.length?"-Expand":"Expand"),Highlight()
}
KillSelect(){
	Gui,99:Destroy
}
Select_All(){
	SelectAll:
	all:=window.SN("//window/descendant::control")
	while,aa:=all.Item[A_Index-1],ea:=xml.EA(aa){
		if InStr(A_ThisHotkey,"+")
			ea.selected?aa.RemoveAttribute("selected"):aa.SetAttribute("selected",1)
		else
			aa.SetAttribute("selected",1)
	}
	Highlight(),DisplaySelected()
	return
}
Save_As(){
	filename:=window.SSN("//filename").text
	SplitPath,filename,,dir
	FileSelectFile,filename,,%dir%,Save Window As,*.xml
	if !(ErrorLevel){
		window.SSN("//filename").text:=filename
		Save()
	}
}
LButton(){
	MouseGetPos,x,y,,ctrl,2
	node:=window.SSN("//*[@hwnd='" ctrl+0 "']")
	ea:=xml.EA(node)
	if(SSN(node,"@type").text~="Tab"){
		Sleep,200
		if(v.tabbutton)
			return v.tabbutton:=0 ;#[Fix This Please]
	}
	Sleep,40
	SetTimer,move,-1
}
Edit_GLabels(){
	if !window.SN("//*[@g!='']").length
		return m("This project does not have any labels associated with any of the controls","Please add label associations first")
	Gui,99:Destroy
	Gui,5:Destroy
	Gui,5:Default
	Gui,5:+hwndhwnd
	hwnd(5,hwnd)
	Gui,Add,ListView,w100 h400 AltSubmit gegl,Labels
	Gui,Add,Edit,x+10 w500 h400 geditgl
	labels:=window.SN("//@g")
	while,ll:=labels.item[A_Index-1]{
		if !window.SSN("//labels/label[@name='" ll.text "']")
			window.Add("labels/label",{name:ll.text},,1)
	}
	labels:=window.SN("//labels/label")
	while,ll:=labels.Item[A_Index-1]{
		if !window.SSN("//*[@g='" SSN(ll,"@name").text "']")
			ll.ParentNode.RemoveChild(ll)
		else
			LV_Add("",SSN(ll,"@name").text)
	}
	WinGetPos,x,y,w,h,% hwnd([1])
	Gui,5:Show,% Center(5),Label Editor
	LV_Modify(1,"Select Vis Focus")
	return
	editgl:
	if !LV_GetNext()
		return
	LV_GetText(label,LV_GetNext())
	if !info:=window.SSN("//labels/label[@name='" label "']")
		info:=window.Add("labels/label",{name:label},,1)
	ControlGetText,text,Edit1,% hwnd([5])
	info.text:=text
	return
	egl:
	if !LV_GetNext()
		return
	LV_GetText(label,LV_GetNext())
	text:=window.SSN("//label[@name='" label "']").text
	ControlSetText,Edit1,% RegExReplace(text,"\R","`r`n"),% hwnd([5])
	return
	5GuiClose:
	5GuiEscape:
	Gui,5:Destroy
	Highlight("show")
	return
}
Center(hwnd){
	Gui,%hwnd%:Show,Hide
	WinGetPos,x,y,w,h,% hwnd([1])
	WinGetPos,xx,yy,ww,hh,% hwnd([hwnd])
	centerx:=(Abs(w-ww)/2),centery:=Abs(h-hh)/2
	return "x" x+centerx " y" y+centery
}
Grid_Dot_Color(){
	color:=settings.Add("grid")
	dot:=Dlg_Color(SSN(color,"@dot").text,hwnd(1)),color.SetAttribute("dot",dot),MakeBackground(),settings.Add("options/Grid",,1)
}
Grid_Background(){
	color:=settings.Add("grid")
	dot:=Dlg_Color(SSN(color,"@grid").text,hwnd(1)),color.SetAttribute("grid",dot),MakeBackground(),settings.Add("options/Grid",,,1)
}
Resize(){
	static wia:=ComObjCreate("wia.imagefile")
	MouseGetPos,x,y,win,Ctrl,2
	pos:=WinPos(x,y),moved:=0,ctrl+=0,xx:=x,yy:=y,lastx:=x,lasty:=y
	if !control:=window.SSN("//*[@hwnd='" ctrl "' or @married='" ctrl "']")
		control:=window.SSN("//window/*[@x<" pos.x " and @y<" pos.y " and @x+@w>" pos.x " and @y+@h>" pos.y "]")
	ea:=xml.EA(control)
	list:=ea.selected?window.SN("//control[@selected='1']"):window.SN("//control[@hwnd='" ea.hwnd "']")
	while,ll:=list.Item[A_Index-1],ea:=xml.EA(ll){
		ControlGetPos,,,w,h,,% "ahk_id" ea.hwnd
		ll.SetAttribute("ow",w),ll.SetAttribute("oh",h)
		if(ea.width=""&&ea.height=""&&ea.type="Picture"){
			wia.loadfile(ea.value)
			for a,b in {width:wia.width,height:wia.height}
				ll.SetAttribute(a,b)
		}
	}
	while,GetKeyState("LButton"){
		MouseGetPos,x,y
		if(lastx=x&&lasty=y)
			Continue
		break
	}
	while,GetKeyState("LButton"){
		MouseGetPos,x,y
		if(lastx=x&&lasty=y)
			Continue
		while,ll:=list.Item[A_Index-1],ea:=xml.EA(ll){
			nw:=x-xx,nh:=y-yy,Grid(nw,nh),command:="Move"
			if(ea.type="Picture")
				nh:=Round(nw*ea.height/ea.width),command:="MoveDraw"
			GuiControl,3:%command%,% ea.hwnd,% "w" ea.ow+nw " h" ea.oh+nh
			ll.SetAttribute("w",ea.ow+nw),ll.SetAttribute("h",ea.oh+nh)
			lastx:=x,lasty:=y
		}
	}
	Highlight(),Eval(),DisplaySelected()
	SetTimer,Redraw,-10
}
Update_Program(){
	if(FileExist("gui.ahk"))
		return m("NO!")
	FileMove,%A_ScriptName%,deleteme.ahk,1
	UrlDownloadToFile,https://raw.githubusercontent.com/maestrith/GUI_Creator/master/GUI_Creator.ahk,%A_ScriptName%
	FileDelete,deleteme.ahk
	Reload
	ExitApp
}
Dlg_Font(ByRef Style,Effects=1,window=""){
	VarSetCapacity(LOGFONT,60),StrPut(style.font,&logfont+28,32,"CP0"),LogPixels:=DllCall("GetDeviceCaps","uint",DllCall("GetDC","uint",0),"uint",90),Effects:=0x041+(Effects?0x100:0)
	for a,b in font:={16:"bold",20:"italic",21:"underline",22:"strikeout"}
		if style[b]
			NumPut(b="bold"?700:1,logfont,a)
	style.size?NumPut(Floor(style.size*logpixels/72),logfont,0):NumPut(16,LOGFONT,0)
	VarSetCapacity(CHOOSEFONT,60,0),NumPut(60,CHOOSEFONT,0),NumPut(&LOGFONT,CHOOSEFONT,12),NumPut(Effects,CHOOSEFONT,20),NumPut(RGB(style.color),CHOOSEFONT,24),NumPut(window,CHOOSEFONT,4)
	if !r:=DllCall("comdlg32\ChooseFontA","uint",&CHOOSEFONT)
		return
	Color:=NumGet(CHOOSEFONT,24),bold:=NumGet(LOGFONT,16)>=700?1:0
	style:={size:NumGet(CHOOSEFONT,16)//10,font:StrGet(&logfont+28,"CP0"),color:RGB(color)}
	for a,b in font
		style[b]:=NumGet(LOGFONT,a,"UChar")?1:0
	style["bold"]:=bold
	return 1
}
CompileFont(XMLObject,text:=1){
	ea:=xml.EA(XMLObject),style:=[],name:=ea.name,styletext:="norm"
	for a,b in {bold:"",color:"c",italic:"",size:"s",strikeout:"",underline:""}
		if ea[a]
			styletext.=" " _:=b?b ea[a]:a
	style:=text?styletext:style
	if(style="norm")
		return
	return style
}
Delete(){
	all:=window.SN("//window/descendant::*[@selected='1']"),undo.Add()
	while,aa:=all.item[A_Index-1],ea:=xml.EA(aa)
		DllCall("DestroyWindow",ptr,ea.hwnd),aa.ParentNode.RemoveChild(aa)
	Select(0,0)
}
Eval(){
	tab:=window.SN("descendant::control[@type='Tab' or @type='Tab2']")
	list:=window.SN("//*[contains(@type,'Tab')]/descendant::control")
	while,ll:=list.item[A_Index-1]{
		parent:=SSN(ll,"ancestor::control[contains(@type,'Tab')]"),pa:=xml.EA(parent),ea:=xml.EA(ll)
		if !(ea.x>pa.x&&ea.x<pa.x+pa.w&&ea.y>pa.y&&ea.y<pa.y+pa.h){
			if new:=window.SSN("//control[contains(@type,'Tab')][@x<" ea.x " and @x+@y>" ea.x " and @y<" ea.y " and @y+@h>" ea.y "]"){
				tt:=xml.EA(new),nn:=GetClassNN(tt.hwnd),top:=window.SSN("//control[@hwnd='" tt.hwnd "']")
				ControlGet,tabnum,tab,,%nn%,% hwnd([3])
				Gui,3:Tab,%tabnum%,% SubStr(nn,16)
				if !tb:=SSN(new,"tab[@tab='" tabnum "']")
					tb:=window.Under(top,"tab",{tab:tabnum})
				tb.AppendChild(ll),new:=AddControl(ll)
				DllCall("DestroyWindow",ptr,ea.hwnd)
			}else{
				window.SSN("//window").AppendChild(ll)
				Gui,3:Tab
				DllCall("DestroyWindow",ptr,ea.hwnd),AddControl(ll)
			}
		}
	}
	gb:=window.SN("descendant::control[@type='GroupBox']"),inside:=[]
	while,gg:=gb.item[A_Index-1]{
		while,in:=Inside(gg).item[A_Index-1],ea:=xml.EA(in){
			if(gg.xml!=in.ParentNode.xml&&gg.ParentNode.xml=in.ParentNode.xml)
				gg.AppendChild(in)
			inside[ea.hwnd]:=1
		}
	}
	ngb:=window.SN("//descendant::control[@type!='GroupBox' and @type!='Tab' and @type!='Tab2']")
	while,move:=ngb.item[A_Index-1],ea:=xml.EA(move){
		if(inside[ea.hwnd]!=1&&SSN(move.ParentNode,"@type").text="GroupBox")
			move.ParentNode.ParentNode.AppendChild(move)
	}
	Debug()
}
GetClassNN(ctrl){
	WinGet,list,ControlList,% hwnd([3])
	for a,b in StrSplit(list,"`n"){
		ControlGet,hwnd,hwnd,,%b%,% hwnd([3])
		if(hwnd=ctrl)
			return b
	}
}
UpdateTV(list){
	while,ll:=list.Item[A_Index-1]{
		if tv:=TreeView.SSN("//*[@hwnd='" SSN(ll,"@hwnd").text "']"){
			x:=xml.EA(SSN(tv,"*[@value='x']")),y:=xml.EA(SSN(tv,"*[@value='y']"))
			Gui,2:Default
			for a,b in {x:[x.tv,x.desc],y:[y.tv,y.desc]}
				TV_Modify(b.1,"",b.2 " = " SSN(ll,"@" a).text)
		}
	}
}
AddToTab(tab,list){
	tt:=xml.EA(tab),nn:=GetClassNN(tt.hwnd)
	top:=window.SSN("//control[@hwnd='" tt.hwnd "']")
	ControlGet,tabnum,tab,,%nn%,% hwnd([3])
	Gui,3:Tab,%tabnum%,% SubStr(nn,16)
	while,ll:=list.item[A_Index-1],ea:=xml.EA(ll){
		if(InStr(ea.type,"tab"))
			Continue
		if(SSN(ll,"ancestor::control[@type='Tab' or @type='Tab2']"))
			Continue
		if !tb:=SSN(top,"tab[@tab='" tabnum "']")
			tb:=window.Under(top,"tab",{tab:tabnum})
		tb.AppendChild(ll)
		DllCall("DestroyWindow",ptr,ea.hwnd)
		AddControl(ll)
	}Debug()
}
UpdatePos(ctrl){
	ControlGetPos,x,y,w,h,,% "ahk_id" xml.EA(ctrl).hwnd
	pos:=WinPos(x,y)
	for a,b in {x:pos.x,y:pos.y,w:w,h:h}
		ctrl.SetAttribute(a,b)
	window.Transform(1)
}
Export(return:=0){
	glabel:=[],winname:=window.SSN("//window/@name").text,program:=winname?"Gui," winname ":Default`n":"",main:=window.SN("//window/control"),top:=window.SSN("//window"),obj:=[]
	while,mm:=main.item[A_Index-1],ea:=xml.EA(mm)
		obj[ea.y,ea.x,ea.hwnd]:=mm
	for a,b in obj
		for c,d in b
			for e,f in d
				top.AppendChild(f)
	obj:=[],gb:=window.SN("//*[@type='GroupBox']/*")
	while,gg:=gb.item[A_Index-1],ea:=xml.EA(gg)
		obj[ea.y,ea.x,ea.hwnd]:={parent:gg.ParentNode,item:gg}
	for a,b in obj
		for c,d in b
			for e,f in d
				f.parent.AppendChild(f.item)
	tab:=[],tabs:=window.SN("//window/control[@type='Tab' or @type='Tab2']")
	while,tt:=tabs.item[A_Index-1],ea:=xml.EA(tt)
		tab[ea.y,ea.x,ea.hwnd]:=tt
	for a,b in tab
		for c,d in b
			for e,f in d
				top.AppendChild(f)
	tabs:=window.SN("//*[@type='Tab' or @type='Tab2']/tab")
	while,tt:=tabs.item[A_Index-1]{
		items:=[],ctrls:=SN(tt,"control")
		while,cc:=ctrls.item[A_Index-1],ea:=xml.EA(cc)
			items[ea.y,ea.x,ea.hwnd]:=cc
		for a,b in items
			for c,d in b
				for e,f in d
					tt.AppendChild(f)
	}
	all:=window.SN("//window/descendant::*")
	while,aa:=all.item[A_Index-1],ea:=xml.EA(aa){
		if(aa.NodeName="tab"){
			line:="Gui,Tab," ea.tab "`n"
			program.=line
			Continue
		}
		font:=CompileFont(aa)
		if(ea.g)
			glabel[ea.g]:=1
		if(font!=lastfont&&font)
			Program.="Gui,Font," font "," ea.font "`n"
		if(font!=lastfont&&!font)
			program.="Gui,Font`n"
		Program.=CompileItem(aa) "`n",lastfont:=font
	}
	;/Compile GUI
	pos:=WinPos(),title:=window.SSN("//window/@windowtitle").text,title:=title?title:"Created with GUI Creator by maestrith"
	Program.="Gui,Show,w" pos.w " h" pos.h "," title "`r`nreturn"
	for a in glabel
		program.="`n" a ":`n" window.SSN("//labels/label[@name='" a "']").text "`nreturn"
	if(return)
		return program
	/*
		/yea, above thing
	*/
	m("Text copied to your clipboard:",Clipboard:=RegExReplace(program,"\R","`r`n"))
	return
	
	
	
	
	/*
		ControlGetPos,,,w,h,,% hwnd([3])
		
		program.="Gui,Show,w" w-(v.Border*2) " h" h-(v.Border*2+v.Caption) ",Created with GUI Creator by Maestrith :)`nreturn"
	*/
	StringReplace,program,program,`n,`r`n,All
	if(return)
		return program
	Clipboard:=program
	TrayTip,GUI Creator,GUI Copied to the Clipboard
	return
	control:
	ff:="Gui,Font," cf "," ea.font,_:=(cf="norm"&&lastfont="")?ff:="":(cf="norm"&&lastfont!="")?(ff:="Gui,Font",lastfont:="",program.=ff "`n"):(cf!="norm"&&ff!=lastfont)?(lastfont:=ff:="Gui,Font," cf "," ea.font,program.=ff "`n")
	add:=""
	for a,b in {v:ea.v,g:ea.g}
		if(b)
			add.=" " a b
	program.="Gui,Add," ea.type ",x" ea.x " y" ea.y " w" ea.w " h" ea.h add "," ea.value "`n"
	if ea.g
		glabel[ea.g]:=1
	return
}
Help(){
	MsgBox,262176,Help,Left Click and drag to create a selection`n-Shift+Left Click to add items to the selection`n-Ctrl+Left Click to toggle the items selected state`n`nShift+Click and drag to Resize selected controls`n`nCtrl+A to Select All and Ctrl+Shift+A to Toggle Select All`n`nTo delete selected controls press Delete
}
Test_GUI(){
	DynaRun(Export(1))
}
DynaRun(Script,debug=0){
	static exec
	exec.Terminate()
	Name:="GUI Creator Test",Pipe:=[],cr:= Chr(34) Chr(96)"n" Chr(34)
	script:="#SingleInstance,Force`n" script
	script.="`nreturn`nGuiEscape:`nGuiClose:`nExitApp`nreturn"
	Loop, 2
		Pipe[A_Index]:=DllCall("CreateNamedPipe","Str","\\.\pipe\" name,"UInt",2,"UInt",0,"UInt",255,"UInt",0,"UInt",0,"UPtr",0,"UPtr",0,"UPtr")
	Call:=Chr(34) A_AhkPath Chr(34) " /ErrorStdOut /CP65001 " Chr(34) "\\.\pipe\" Name Chr(34),Shell:=ComObjCreate("WScript.Shell"),Exec:=Shell.Exec(Call)
	for a,b in Pipe
		DllCall("ConnectNamedPipe","UPtr",b,"UPtr",0)
	FileOpen(Pipe[2],"h","UTF-8").Write(Script)
	for a,b in Pipe
		DllCall("CloseHandle","UPtr",b)
	return exec
}
Undo(){
	undo.undogo()
}
Redo(){
	undo.redogo()
}
Testing(){
	
}
WinPos(x:="",y:=""){
	ControlGetPos,xx,yy,ww,hh,,% hwnd([3])
	VarSetCapacity(rect,16),DllCall("GetClientRect",ptr,hwnd(3),ptr,&rect),x-=xx+v.Border,y-=yy+v.Border+v.Caption,w:=NumGet(rect,8),h:=NumGet(rect,12)
	return {x:x,y:y,w:w,h:h}
}
CompileItem(node){
	ea:=xml.EA(node),index:=0
	item:="Gui,Add," ea.type ","
	for a,b in StrSplit("x,y,w,h,g,v",",")
		if(ea[b]!="")
			item.=(index=0?"":" ") b ea[b],index++
	if(ea.option)
		item.=" " ea.option
	item.="," ea.value
	return item
}
Escape(){
	all:=window.SN("//*[@selected]")
	while,aa:=all.item[A_Index-1]
		aa.RemoveAttribute("selected")
	Highlight()
}
TabNotify(){
	v.tabbutton:=1
}
FileCheck(){
	if(!FileExist("lib"))
		FileCreateDir,lib
	conxml:=new XML("controls","lib\controls.xml")
	if(conxml.SSN("//version").text!="0.000.2")
		FileDelete,lib\controls.xml
	if(!FileExist("lib\controls.xml"))
		ctrl:=URLDownloadToVar("https://raw.githubusercontent.com/maestrith/GUI_Creator/master/lib/Controls.xml"),conxml:=new XML("control","lib\Controls.xml"),conxml.xml.LoadXML(ctrl),conxml.Save(1)
	if(!FileExist("tile.bmp"))
		MakeBackground()
}
URLDownloadToVar(url){
	http:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
	http.Open("GET",url),http.Send()
	return http.ResponseText
}
Class XML{
	keep:=[]
	__Get(x=""){
		return this.xml.xml
	}__New(param*){
		if(!FileExist(A_ScriptDir "\lib"))
			FileCreateDir,%A_ScriptDir%\lib
		root:=param.1,file:=param.2,file:=file?file:root ".xml",temp:=ComObjCreate("MSXML2.DOMDocument"),temp.setProperty("SelectionLanguage","XPath"),this.xml:=temp,this.file:=file,xml.keep[root]:=this ;temp.preserveWhiteSpace:=1
		if(FileExist(file)){
			FileRead,info,%file%
			if(info=""){
				this.xml:=this.CreateElement(temp,root)
				FileDelete,%file%
			}else
				temp.LoadXML(info),this.xml:=temp
		}else
			this.xml:=this.CreateElement(temp,root)
	}Add(path,att:="",text:="",dup:=0){
		p:="/",add:=(next:=this.SSN("//" path))?1:0,last:=SubStr(path,InStr(path,"/",0,0)+1)
		if(!next.xml){
			next:=this.SSN("//*")
			for a,b in StrSplit(path,"/")
				p.="/" b,next:=(x:=this.SSN(p))?x:next.AppendChild(this.xml.CreateElement(b))
		}if(dup&&add)
			next:=next.ParentNode.AppendChild(this.xml.CreateElement(last))
		for a,b in att
			next.SetAttribute(a,b)
		next.text:=text
		return next
	}CreateElement(doc,root){
		return doc.AppendChild(this.xml.CreateElement(root)).ParentNode
	}EA(path,att:=""){
		list:=[]
		if(att)
			return path.NodeName?SSN(path,"@" att).text:this.SSN(path "/@" att).text
		nodes:=path.NodeName?path.SelectNodes("@*"):nodes:=this.SN(path "/@*")
		while,n:=nodes.item(A_Index-1)
			list[n.NodeName]:=n.text
		return list
	}Find(info*){
		static last:=[]
		doc:=info.1.NodeName?info.1:this.xml
		if(info.1.NodeName)
			node:=info.2,find:=info.3,return:=info.4!=""?"SelectNodes":"SelectSingleNode",search:=info.4
		else
			node:=info.1,find:=info.2,return:=info.3!=""?"SelectNodes":"SelectSingleNode",search:=info.3
		if(InStr(info.2,"descendant"))
			last.1:=info.1,last.2:=info.2,last.3:=info.3,last.4:=info.4
		if(InStr(find,"'"))
			return doc[return](node "[.=concat('" RegExReplace(find,"'","'," Chr(34) "'" Chr(34) ",'") "')]/.." (search?"/" search:""))
		else
			return doc[return](node "[.='" find "']/.." (search?"/" search:""))
	}Get(Path,Default){
		text:=this.SSN(path).text
		return text?text:Default
	}Save(x*){
		if(x.1=1)
			this.Transform()
		if(this.xml.SelectSingleNode("*").xml="")
			return m("Errors happened while trying to save " this.file ". Reverting to old version of the XML")
		filename:=this.file?this.file:x.1.1,ff:=FileOpen(filename,0),text:=ff.Read(ff.length),ff.Close()
		if(!this[])
			return m("Error saving the " this.file " xml.  Please get in touch with maestrith if this happens often")
		if(text!=this[])
			file:=FileOpen(filename,"rw"),file.seek(0),file.write(this[]),file.length(file.position)
	}SSN(path){
		Try
			node:=this.xml.SelectSingleNode(path)
		Catch,e
			t(path,e.message)
		return node
	}SN(path){
		return this.xml.SelectNodes(path)
	}Transform(){
		static
		if(!IsObject(xsl))
			xsl:=ComObjCreate("MSXML2.DOMDocument"),xsl.loadXML("<xsl:stylesheet version=""1.0"" xmlns:xsl=""http://www.w3.org/1999/XSL/Transform""><xsl:output method=""xml"" indent=""yes"" encoding=""UTF-8""/><xsl:template match=""@*|node()""><xsl:copy>`n<xsl:apply-templates select=""@*|node()""/><xsl:for-each select=""@*""><xsl:text></xsl:text></xsl:for-each></xsl:copy>`n</xsl:template>`n</xsl:stylesheet>"),style:=null
		this.xml.TransformNodeToObject(xsl,this.xml)
	}Under(under,node,att:="",text:="",list:=""){
		new:=under.AppendChild(this.xml.CreateElement(node)),new.text:=text
		for a,b in att
			new.SetAttribute(a,b)
		for a,b in StrSplit(list,",")
			new.SetAttribute(b,att[b])
		return new
	}
}
SSN(node,path){
	return node.SelectSingleNode(path)
}
SN(node,path){
	return node.SelectNodes(path)
}
m(x*){
	for a,b in x
		list.=b "`n"
	MsgBox,0,GUI Creator,%list%
}
t(x*){
	for a,b in x
		list.=b "`n"
	ToolTip %list%
}
Gui(){
	static
	Gui,+Resize +hwndmain
	hwnd(1,main),OnMessage(0x136,"Display_Grid"),OnMessage(0x231,"KillSelect"),OnMessage(0x232,"highlight")
	DetectHiddenWindows,On
	Gui,1:Menu,% Menu()
	Gui,1:Add,StatusBar
	Gui,2:+parent1 +Resize +hwndhwnd -0x20000 -0x10000 0x400 -ToolWindow 
	Gui,2:Add,TreeView,x0 y0 w150 h500 gtv AltSubmit hwndtv
	Gui,2:Default
	add:=TreeView.Add("Add",{tv:TV_Add("Add Control")}),ea:=TreeView.EA(add),hwnd("tv",tv)
	for a,b in StrSplit(Menu({menu:1}).Add,"|")
		TreeView.Under(add,b,{tv:TV_Add(b,ea.tv,"Vis")})
	TreeView.Add("displaypos",{tv:TV_Add("Display Positions")})
	TreeView.Add("selected",{tv:TV_Add("Selected")})
	TreeView.Add("windowtitle",{tv:TV_Add("Window Title")})
	TreeView.Add("windowname",{tv:TV_Add("Window Name")})
	hwnd(2,hwnd),ea:=settings.EA("//gui/settings")
	if (ea.w)
		ControlMove,SysTreeView321,,,% ea.w,% ea.h,% hwnd([2])
	Gui,2:Show,% GuiPos("//gui/settings","x5 y5 w150 h500"),Settings
	Gui,3:+Resize +hwndhwnd -0x20000 -0x10000 +parent1 -ToolWindow 
	hwnd(3,hwnd),ea:=settings.EA("//gui/workarea"),pos:=""
	Gui,3:Show,% GuiPos("//gui/workarea","x176 y5 w500 h500"),Work Area
	Gui,3:Margin,0,0
	for a,b in {Border:33,Caption:4,Menu:15}{
		SysGet,value,%b%
		v[a]:=value
	}
	Gui,1:Show,% GuiPos("//gui/main","w700 h550"),GUI Creator
	Hotkey,IfWinActive,% hwnd([1])
	Hotkey,^a,SelectAll,On
	Hotkey,+^a,SelectAll,On
	Hotkey,^z,Undo,On
	Hotkey,^y,Redo,On
	Hotkey,~Escape,Escape,On
	Hotkey,~*LButton,LButton,On
	Hotkey,Delete,Delete,On
	WinSet,Redraw,,% hwnd([3])
	Hotkeys(),Options(1),New()
	if(last:=settings.SSN("//last/@file").text)
		Open(last),DisplaySelected()
	new Undo()
	return
	2GuiSize:
	ControlMove,SysTreeView321,,,A_GuiWidth,A_GuiHeight,% hwnd([2])
	return
	2GuiClose:
	3GuiClose:
	Exit(1)
	return
}
hwnd(win,hwnd=""){
	static winkeep:=[]
	if (win.rem){
		Gui,% win.rem ":Destroy"
		return winkeep.remove(win.rem)
	}
	if IsObject(win)
		return "ahk_id" winkeep[win.1]
	if !hwnd
		return winkeep[win]
	winkeep[win]:=hwnd
	return % "ahk_id" hwnd
}
Menu(info:=""){
	static menu:={order:["File","Edit","Options","Add","Help"],File:"&New|&Save|S&ave As|&Open|Ex&port|&Test GUI|E&xit|&Update Program",Add:"Button|Checkbox|ComboBox|DateTime|DropDownList|Edit|GroupBox|Hotkey|ListBox|ListView|MonthCal|Picture|Progress|Radio|Slider|Tab|Text|TreeView|UpDown",Options:"&Snap To Grid|Display &Grid|Grid &Dot Color|Grid &Background|Debug &Window",Edit:"Edit GLabels|Select All|Invert Selection|Edit &Hotkeys|Redraw",Help:"Help|Online Help"}
	if info.menu
		return menu
	for a,b in Menu.order{
		for c,d in StrSplit(Menu[b],"|"){
			HotkeyXML({check:d})
			Menu,%b%,Add,% GetMenuItem(d),menucmd
		}
	}
	for a,b in Menu.order
		Menu,Main,Add,&%b%,:%b%
	return "main"
	menucmd:
	MenuItem:=Clean(A_ThisMenuItem)
	if(A_ThisMenu="options"&&MenuItem~="(Snap_To_Grid|Display_Grid|Debug_Window)")
		return Options(MenuItem)
	if(A_ThisMenuItem="Debug Window")
		m("here")
	if(IsFunc(MenuItem))
		%MenuItem%()
	else if(A_ThisMenu="Add")
		GetInfo(MenuItem)
	else
		m("Feature not implemented yet. Coming Soon")
	return
}
HotkeyXML(item){
	if item.check
		if !settings.SSN("//hotkeys/*[@menu='" item.check "']")
			settings.Add("hotkeys/" Clean(item.check),{menu:item.check})
}
Clean(info,type:=0){
	if(InStr(info,"`t"))
		info:=RegExReplace(info,"(\t.*)")
	if(type=1)
		info:=RegExReplace(info,"_"," ")
	else if(type=2)
		info:=RegExReplace(info,"&")
	else if(type=0)
		info:=RegExReplace(RegExReplace(info," ","_"),"&")
	return info
}
GuiPos(path,default){
	ea:=settings.EA(path)
	for a,b in ea
		if (b!="")
			pos.=a b " "
	return pos:=pos?pos:default
}
Open(filename=""){
	last:=settings.SSN("//last/@file").text,tabcount:=0
	SplitPath,last,,dir
	if(!filename)
		FileSelectFile,filename,,%dir%,Select a Saved GUI,*.xml
	if(ErrorLevel||!FileExist(filename))
		return
	New(),window.xml.load(filename),list:=window.SN("//*[@type]")
	while,ll:=list.Item[A_Index-1]
		ll.RemoveAttribute("hwnd")
	while,ll:=window.SN("//window/descendant::*").Item[A_Index-1],ea:=xml.EA(ll){
		if(InStr(ea.type,"tab"))
			tabcount++
		if(ll.nodename="tab"){
			Gui,3:Tab,% ea.tab,% SubStr(GetClassNN(SSN(ll,"ancestor::control[@type='Tab' or @type='Tab2']/@hwnd").text),16)
			ll.SetAttribute("hwnd",SSN(ll.ParentNode,"@hwnd").text)
			Continue
		}
		if(!SSN(ll,"ancestor::control[@type='Tab' or @type='Tab2']"))
			Gui,3:Tab
		AddControl(ll)
	}
	ea:=window.EA("//workarea")
	ControlMove,,% ea.x,% ea.y,% ea.w,% ea.h,% hwnd([3])
	settings.Add("last",{file:filename}),Highlight(),Eval()
	Gui,3:Tab
}
GetMenuItem(menu,tv:=0){
	hotkey:=settings.SSN("//hotkeys/" Clean(menu) "/@hotkey").text
	space:=tv?" = ":"`t",menu:=tv?RegExReplace(menu,"&"):menu
	hotkey:=hotkey?menu space Convert_Hotkey(hotkey):menu
	return hotkey
}
Options(x:=""){
	if (x=1){
		for a,b in StrSplit(Menu({menu:1}).options,"|"){
			if settings.SSN("//options/" Clean(b)).text
				Menu,options,Check,%b%
			else
				Menu,options,UnCheck,%b%
		}
		func:=Clean(b)
		if(IsFunc(func))
			%func%()
		WinSet,Redraw,,% hwnd([3])
		return
	}
	settings.Add("options/" Clean(x),,(settings.SSN("//options/" Clean(x)).text?0:1)),Options(1)
	if(Clean(x)="debug_window")
		Debug(0)
}
Dlg_Color(Color,hwnd:=""){
	static
	VarSetCapacity(cccc,16*A_PtrSize,0),cc:=1,size:=VarSetCapacity(CHOOSECOLOR,9*A_PtrSize,0)
	Loop,16
		NumPut(settings.SSN("//colors/@color" A_Index).text,cccc,(A_Index-1)*4,"UInt")
	NumPut(size,CHOOSECOLOR,0,"UInt"),NumPut(hwnd,CHOOSECOLOR,A_PtrSize,"UPtr"),NumPut(Color,CHOOSECOLOR,3*A_PtrSize,"UInt"),NumPut(3,CHOOSECOLOR,5*A_PtrSize,"UInt"),NumPut(&cccc,CHOOSECOLOR,4*A_PtrSize,"UPtr")
	ret:=DllCall("comdlg32\ChooseColorW","UPtr",&CHOOSECOLOR,"UInt")
	colors:=[]
	Loop,16
		colors["color" A_Index]:=NumGet(cccc,(A_Index-1)*4,"UInt")
	settings.Add("colors",colors)
	if !ret
		exit
	return NumGet(CHOOSECOLOR,3*A_PtrSize)
}
class undo{
	undo:=[],redo:=[]
	__New(){
		undo.undo:=[],undo.redo:=[]
	}
	Add(){
		undo.undo.Insert(window.SSN("//*").clonenode(1))
	}
	Fix(in,out){
		last:=undo[in].Pop(),list1:=window.SN("//control"),list2:=SN(last,"//control"),undo[out].Insert(window.SSN("//*").CloneNode(1))
		while,ll:=list1.item[A_Index-1],ea:=xml.EA(ll)
			if !SSN(last,"//*[@hwnd='" ea.hwnd "']")
				DllCall("DestroyWindow",ptr,ea.hwnd),ll.ParentNode.RemoveChild(ll),action:=1
		while,ll:=list2.item[A_Index-1],ea:=xml.EA(ll)
			if !window.SSN("//*[@hwnd='" ea.hwnd "']")
				top:=ll.ParentNode.NodeName="window"?window.SSN("//window"):window.SSN("//*[@hwnd='" SSN(ll.ParentNode,"@hwnd").text "']"),top.AppendChild(ll),AddControl(ll),action:=1
		while,ll:=list2.item[A_Index-1],ea:=xml.EA(ll){
			ctrl:=window.SSN("//*[@hwnd='" ea.hwnd "']"),cea:=xml.EA(ctrl),move:=""
			for a,b in ea{
				if(ea[a]!=cea[a]&&a~="\b(x|y|w|h)")
					move.=a b " "
				ctrl.SetAttribute(a,b)
			}
			if move
				GuiControl,3:MoveDraw,% ea.hwnd,%move%
		}
		Highlight(),DisplaySelected()
		SetTimer,Redraw,-10
	}
	RedoGo(){
		undo.redo.1?undo.Fix("redo","undo"):m("Nothing more to redo")
	}
	UndoGo(){
		undo.undo.1?undo.Fix("undo","redo"):m("Nothing more to undo")
	}
}
f1::
file:=window.SSN("//filename").text
;SplitPath,file,,dir
Run,%file%
return