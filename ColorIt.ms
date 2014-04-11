/*
Color it
all rights reserved to sven fraeys
*/

struct colorPainter_system(
	-- main system to apply colors
	fn GetMaterial _node _color=(
		-- return material of the color
		
		-- check if material already exists
		if(classof _node.material == multimaterial)then(
			for mat in _node.material.materiallist do(
				if(mat.diffusecolor == _color)then(
					-- return the existing material
					return mat
				)
			)
		)
		
		-- create a material with given color
		mat = standardmaterial()
		mat.name = _node.name + "_Color"+(_color as string)
		mat.diffuseColor = _color
		return mat
	),
	fn ColorIt _node _colorValue=(
		-- apply a color to the given node and
		print("_node")
		print(_node)
		-- if the baseObject is an editable poly
		if(classof _node == PolyMeshObject)then(
			selectedFaces = _node.edit_poly.getSelection #Face
			--print("selectedFaces")
			--print(selectedFaces)
			
			if ( (selectedFaces as array).count == 0 ) then(
				return false
			)
			
			
			modPanel.setCurrentObject _node.baseObject
			subobjectlevel = 4
			--selectedFaces = _node.baseObject.SetSelection #Face #{}
			selectedFaces = polyop.setFaceSelection _node.baseObject selectedFaces
			_node.material = GetMaterial _node _colorValue
			subobjectlevel = 0
			modPanel.setCurrentObject _node.edit_poly
			subobjectlevel = 4
			return true
			
			--return true
		)
		
		-- if baseObject is undefined apply a general material
		if(_node.baseObject == undefined)then(
			_node.material = GetMaterial _node _colorValue
			return true
		)
		
		-- if the baseObject is an editable poly
		if(classof _node.baseObject != Editable_Poly)then(
			_node.material = GetMaterial _node _colorValue
			return true
		)
		
		
		
		-- if no faces are selected do not do anything
		if( ( (_node.baseObject.GetSelection #Face) as array).count == 0 and subobjectlevel != 0)then(
			return false
		)
		
		-- apply material
		mat = GetMaterial _node _colorValue
		_node.material = mat
	),
	
	
	fn Edit _node=(
		-- go to face mode --
		max modify mode
		modPanel.setCurrentObject _node.baseObject
		subobjectlevel = 4
	),
	fn GetColor _material _id=(
		/* return the color of a given material and id for multimaterials 
		*/
 		-- show _material --
		difColor = color 115 115 115
		if(classof _material == Multimaterial)then(
-- 			print "deesss"
-- 			for mat in  _material do(
				c = 0
				found = false
				for matId in _material.materialIDList do(
-- 					print matId
					c += 1
					if(matId == _id)then(
-- 						print "found"
						--found
						found = true
						exit
					)
				)
				if(found == true)then(
-- 					print "c"
					difColor = _material.materialList[c].diffuseColor
				)
-- 			)
		)else if(classof _material == standardmaterial)then(
			difColor = _material.diffuseColor
		)
		difColor
	),
	fn AsDataObj _strVal=(
		/* return as data object to transfer
		*/
		dataObj = filterstring _strVal ";"
		matId = execute(dataObj[1])
		
		colorVal = execute(dataObj[2])
		
		
		faceInt = (dataObj[3])
		
		faceArr = #()
		if(faceInt != undefined)then(
			faceArrStr = filterstring faceInt ","			
			for faceString in faceArrStr do(
				faceVal = execute(faceString)
				append faceArr faceVal
			)	
		)
		
		dataObjVal = #(matId, colorVal, faceArr)
		return dataObjVal
	),
	fn ApplyColorDataObject _node _dataObjArr=(
		/*apply the given data object
		*/
		print "ApplyColorDataObject"
		matObj = multimaterial()
		matObj.name = _node.name as string
		matObj.materialList = #()
		print "---"
		matObj.numsubs = _dataObjArr.count
		c = 1
		print ("Coloring " + _node.name)
		for dataObj in _dataObjArr do(
			print "Apply Colors -"
			print dataObj[1]
			print dataObj[2]
			print (dataObj[3].count)
			stdMat = standardmaterial()
			stdMat.name = _node.name + (dataObj[1] as string)
			stdMat.DiffuseColor = dataObj[2]
			matId = dataObj[1]
			
			
			if(_dataObjArr.count == 1)then(
				_node.material = stdMat
				return true
			)
			matObj.materialIDList[c] = matId 
			matObj.materialList[c] = stdMat 
			for faceId in dataObj[3] do(
				
				(polyop.setFaceMatID _node.baseObject faceId matId)
			)
			c+=1
		)
		_node.material = matObj
	),
	fn AsDataString _dataObj=(
		/*return the whole setup as string
		*/
		matId = _dataObj[1]
		
		colorVal = _dataObj[2]
		faceArr = _dataObj[3]
		faceArrStr = ""
		print matId
		print colorVal
		for faceInt in faceArr do(
			faceArrStr += (faceInt as string) + ","
		)
		strVal = (matId as string) + ";" + (colorVal as string) + ";" +faceArrStr
		strVal
	),
	fn Import _node _iniFile=(
		/*apply iniFile data on the node
		*/
		if(doesfileexist _iniFile == false)then(
			return false
		)
		print "Import"
		print _node.name
		fs = openfile _iniFile
		valueString = undefined
		print "Reading ini file"
		while (eof fs == false)do(
			lineStr = readline fs
			strPieces = filterstring lineStr "="
-- 			if(_node.name == strPieces[1])then(
			nameInIni = strPieces[1]
			nameInIni = filterstring nameInIni "0123456789"
			nameInIni = nameInIni[1]
			nameStr = filterstring _node.name "0123456789"
			nameStr = nameStr[1]
			if(nameStr == nameInIni)then(
				valueString = strPieces[2]
			)
		)
		close fs
		
		if(valueString == undefined)then(
			return false
		)
-- 		dataValStr = getinisetting _iniFile "Color" _node.name
		dataValStr = valueString
		
		
		
		dataObjStringArr = filterstring dataValStr "&"
		
		
		DataObjArr = #()
		for dataString in dataObjStringArr do(
			dataObj = AsDataObj dataString
			print (dataObj[1])
			append DataObjArr dataObj
		)
		print "---"
		print DataObjArr.count
		ApplyColorDataObject _node DataObjArr
		
	),
	fn GetBaseColor _node=(
		/*return the main color on the object
		*/
		if(classof _node.material == standardmaterial)then(
			return _node.material.diffuse
		)
		return _node.wirecolor
	),
	fn Export _node _iniFile=(
		/*export node to ini
		*/
		print "export"
		print _node.name
		
		polyObj = _node.baseObject
		
		matIdList = #()
		
		if(_node.baseObject == undefined)then(
			continue
		)
		if(classof _node.baseObject != Editable_Poly)then(
			dataContainer = #((0) ,(GetBaseColor (_node)), #() )
			append matIdList dataContainer
		)
		
		if(classof _node.baseObject == Editable_Poly)then(
			numfaces = polyop.getNumFaces polyObj
			
			for i = 1 to numfaces do(
				matId =  (polyop.getFaceMatID polyObj i)
				c = GetColor _node.material matId
				dataContainer = #((matId) ,c, #() )
				new = true
				for matIdB in matIdList do(
					if (matIdB[1] == matId or matIdB[2] == c)then(
						dataContainer = matIdB
						new = false
					)
				)
				appendifunique (dataContainer[3]) i
				if(new)then(
					append matIdList dataContainer
				)
			)
		)
		
		totalStringValue = ""
		for dataObj in matIdList do(
			strVal = AsDataString dataObj
			totalStringValue += strVal + "&"
-- 			dataObj = AsDataObj strVal
-- 			print dataObj
		)
		setinisetting _iniFile "Color"_node.name totalStringValue
	)
)

-- painter.Color $ (color 0 255 0)

-- delete interface if already exists
try(destroydialog colorPainter_rollout)catch()
global colorPainter_rollout_pos

rollout colorPainter_rollout ""(
	
)

rcmenu colorPain_MainMenu(
	--main menu in colorIt
	--
	subMenu  "File"(
		menuItem mi_Save "Save Colors Of Selected Objects..."
		menuItem mi_Load "Load Colors In Selected Objects..."
	)
	on mi_Save picked do(
		colorPainter_rollout.HandleSave()
	)
	on mi_Load picked do(
		colorPainter_rollout.HandleLoad()
	)
	subMenu  "Edit"(
		menuItem mi_ChangeBackground "Browse Background..."
		menuItem mi_ResetBackground "Reset Background"
	)
	on mi_ResetBackground picked do(
		colorPainter_rollout.ResetImage()
	)
	on mi_ChangeBackground picked do(
		fileName = getOpenFileName caption:"Open Background Image"
		colorPainter_rollout.ChangeImage fileName
	)
	subMenu  "Help"(
		menuItem mi_Contact "Email Me ! For Feedback And Requests"
		menuItem mi_VisitPortfolio "Click Here For More Awesome Tools Like This !"
	)
	
	on mi_Contact picked do(
		(dotnetobject("Diagnostics.process")).start ("mailto:sven.fraeys@gmail.com")
	)
	on mi_VisitPortfolio picked do(
		(dotnetobject("Diagnostics.process")).start ("http://svenfraeys.com/tools")
	)
)

rcmenu colorPaint_RightClickMenu(
	--context menu when right clicking on image
	menuitem mi_Browse "Browse Background..."
	menuitem mi_ResetBackground "Reset Background"
	on mi_Browse picked do(
		fileName = getOpenFileName caption:"Open Background Image"
		colorPainter_rollout.ChangeImage fileName
	)
	on mi_ResetBackground picked do(
		colorPainter_rollout.ResetImage()
	)
)

rollout colorPainter_rollout "Color It !" width:388 height:440(
	--main interface
	--button btn_Edit "Edit" 
	colorpicker color_Color "" height:30  across:4
	button btn_Color "Fill" width:50 height:30 offset:[-50,0]
	button btn_Save "Save" width:37 height:30  align:#right offset:[50,0]
	button btn_Load "Load" width:37 height:30 align:#right
	local m_Image
	local m_OriginalImagePath
	
	dotnetcontrol PictureBox_Color "PictureBox" width:367 height:367
	local painter
	
	
	
	
	
	on PictureBox_Color DragDrop _args do(
-- 		messagebox "d"
-- 		_a.Data.GetData(DataFormats.FileDrop)
	)
	
	fn ChangeImage _filePath=(
		if(_filePath == undefined)then(
			return false
		)
		
		global m_CurrentImagePath = _filePath

		DotNetImageClass = dotnetclass "System.Drawing.Image"
		m_Image = DotNetImageClass.FromFile (_filePath)
		PictureBox_Color.image = m_Image
		PictureBox_Color.width = m_Image.width
		PictureBox_Color.height = m_Image.height
		colorPainter_rollout.width = m_Image.width + 30
		colorPainter_rollout.height = m_Image.height + 44
-- 		btn_Save.pos = [btn_Save.pos[1],m_Image.height + 50]
-- 		btn_Load.pos = [btn_Load.pos[1],m_Image.height + 50]
	)
	fn ResetImage=(
		ChangeImage m_OriginalImagePath
	)
	
	local m_IsDown = false
	
	
	
	fn CalculatePositionOfColor _color=(
		straal = 50
		rVector = [0,1]
		gVector = [1,0]
		bVector = [-1,0]
		rVector = rVector * ((_color.r / 255) * straal)
		gVector = gVector * ((_color.g / 255) * straal )
		bVector = bVector * ((_color.b / 255) * straal )
		rVector + gVector + bVector
	)
	
	fn HandlePickColorOnColorWheel _args =(
		if(m_IsDown)then(
			if(_args.X  < 0 or _args.Y < 0 or _args.X  > m_Image.width or _args.Y > m_Image.height)then(
				return false
			)
			try(
			pixelObj = m_Image.GetPixel _args.X _args.Y
			r = pixelObj.R
			g = pixelObj.G
			b = pixelObj.B
			MaxColor = color r g b
			color_Color.color = MaxColor
			if(subobjectlevel == 0)then(
				for obj in selection do(
					painter.ColorIt obj (MaxColor)	
				)	
			)else(
				painter.ColorIt $ (MaxColor)	
			)
			
			
			)catch()
		)
	)
	on PictureBox_Color MouseMove _args do(
		HandlePickColorOnColorWheel _args
	)
	
	on PictureBox_Color MouseDown _args do(
		if(_args.Button == _args.Button.Left)then(
			m_IsDown = true
			HandlePickColorOnColorWheel _args	
		)else(
			popupmenu colorPaint_RightClickMenu
		)
		
	)
	on PictureBox_Color MouseUp _args do(
		m_IsDown = false
	)
	
	on btn_Edit pressed do(
		
		painter.Edit $
	)
	on btn_Color pressed do(
		if(subobjectlevel == 0)then(
			for obj in selection do(
				painter.ColorIt obj (color_Color.color)
			)	
		)else(
			painter.ColorIt $ (color_Color.color)
		)
-- 		painter.ColorIt $ (color_Color.color)
	)
	on color_Color changed _arg do(
		if(subobjectlevel == 0)then(
			for obj in selection do(
				painter.ColorIt obj (color_Color.color)
			)	
		)else(
			painter.ColorIt $ (color_Color.color)
		)
		
	)
	fn HandleSave=(
		pathStr = getSaveFileName caption:"Save Colors" types:"Data(*.ini)|*.ini"
		if(pathStr == undefined)then(
			return false
		)
		for nodeObj in selection do(
			res = painter.Export nodeObj pathStr	
		)
		
	)
	fn HandleLoad=(
		pathStr = getOpenFileName  caption:"Load Colors" types:"Data(*.ini)|*.ini"
		if(pathStr == undefined)then(
			return false
		)
		res = querybox "Are you sure you want to load colors? \nCurrent colors of the selection will be lost"
		if(res)then(
			for nodeObj in selection do(
				res = painter.Import nodeObj pathStr	
			)
		)
	)
	on btn_Save pressed do(
		HandleSave()
	)
	on btn_Load pressed do(
		HandleLoad()
	)
	on colorPainter_rollout open do(
		painter = colorPainter_system()
		DotNetImageClass = dotnetclass "System.Drawing.Image"
		m_OriginalImagePath = (getfilenamepath (getThisScriptFilename()) + @"ColorWheel.png")
		m_Image = DotNetImageClass.FromFile m_OriginalImagePath
		PictureBox_Color.image = m_Image
		
		if(m_CurrentImagePath != undefined)then(
			ChangeImage m_CurrentImagePath
		)else(
			ChangeImage m_OriginalImagePath
		)
		
		PictureBox_Color.AllowDrop = true
		if(colorPainter_rollout_pos != undefined)then(
			setdialogpos colorPainter_rollout colorPainter_rollout_pos
		)
	)
	on colorPainter_rollout close do(
		colorPainter_rollout_pos = getdialogpos colorPainter_rollout 
	)
)

-- make the interface
createdialog colorPainter_rollout menu:colorPain_MainMenu

-- colorPainter_rollout.color_Color.changed (color 0 255 0)
-- myCol = 

-- painter = colorPainter_system()
-- painter.Import $ "c:\\test3.ini"