local _, Internals = ...; 

-- **** imports ****
local kCore = kCore;
local kWidgets = kWidgets;

local Frame = kWidgets.Frame;
local BagIcon = Internals.BagIcon;

-- **** private ****
local Base;

local Int16 = function( value )
	local sign = value < 0 and 0x8000 or 0;
	local body = bit.band( sign > 0 and -value or value, 0x7fff );
	
	return bit.bor( body, sign );
end

local Int32 = function( value )
	local body = bit.band( value, 0x7fff );
	local sign = bit.band( value, 0x8000 );

	if ( sign > 0 ) then
		return -body;
	else
		return body;
	end
end

local Compress = function( self, container, slot )
	local shortContainer = Int16( container );
	local shortSlot = Int16( slot );

	return bit.bor( bit.lshift( shortContainer, 16 ), shortSlot );
end

local Decompress = function( self, value )
	local shortContainer = bit.rshift( value, 16 );
	local shortSlot = bit.band( value, 0xffff );

	return Int32( shortContainer ), Int32( shortSlot );
end

local ReanchorIcons = function( self )

end

local GetIcon = function( self, index )
	local icons = self.icons;
	local icon = icons[ index ];
	
	if ( not icon ) then
		local iconSize = self.iconSize;
	
		icon = BagIcon();
		icon:SetParent( self );
		icon:SetWidth( iconSize );
		icon:SetHeight( iconSize );
		if ( index == 1 ) then
			icon:SetPoint( "TOPLEFT", self, "TOPLEFT", 0, 0 );
		else
			local maxRowCount = floor( self.maxHeight / self.iconSize );			
			local currentRow = #icons % maxRowCount;
			
			if ( currentRow == 0 ) then
				icon:SetPoint( "LEFT", icons[ index - maxRowCount ], "RIGHT", 0, 0 );
			else
				icon:SetPoint( "TOP", icons[ index - 1 ], "BOTTOM", 0, 0 );
			end
		end
		
		tinsert( icons, icon );
	end
	
	return icon;
end

-- **** event handlers ****

-- **** public ****
local Add = function( self, container, slot )
	tinsert( self.slots, Compress( self, container, slot ) );
end

local CheckId = function( self, id )
	local filter = self.filter;
	if ( not filter ) then return false; end	
	
	for _, value in ipairs( filter ) do
		if ( value == id ) then
			return true;
		end
	end
	
	return false;
end

local CheckType = function( self, itemType, subType )
	local filter = self.filter;
	if ( not filter ) then return false; end	
	
	local fullType = tostring( itemType ) .. "->" .. tostring( subType );
	
	for _, value in ipairs( filter ) do
		if ( value == fullType or value == itemType ) then
			return true;
		end
	end
	
	return false;	
end

local CheckEmpty = function( self, bagType )
	local filter = self.filter;
	if ( not filter ) then return false; end	
	
	local emptyType = "empty->" .. bagType;
	
	for _, value in ipairs( filter ) do
		if ( value == emptyType ) then
			return true;
		end
	end
	
	return false;
end

local Reset = function( self )
	table.wipe( self.slots );
end

local Update = function( self )
	for _, icon in ipairs( self.icons ) do
		if ( icon:IsVisible() ) then
			icon:Update();
		end
	end
end

local Render = function( self )
	local icons = self.icons;
	local slots = self.slots;

	for index, v in ipairs( slots ) do
		local container, slot = Decompress( self, v );
	
		local icon = GetIcon( self, index );
		icon:Show();
		icon:Set( container, slot );
	end	

	for index = #slots + 1, #icons do
		icons[ index ]:Hide();
	end
	
	local iconSize = self.iconSize;	
	local slotCount = #slots;
	
	local maxRowCount = floor( self.maxHeight / iconSize );	
	local rowCount = slotCount < maxRowCount and slotCount or maxRowCount;
	local columnCount = ceil( slotCount / maxRowCount );
	
	local width = columnCount * iconSize;
	local height = rowCount * iconSize;
	
	self:SetWidth( width );
	self:SetHeight( height );
		
	return width, height;
end

-- positioning
local GetMaxHeight = function( self )
	return self.maxHeight;
end

local SetMaxHeight = function( self, value )
	self.maxHeight = value;
	
	ReanchorIcons( self );
end

local GetIconSize = function( self )
	return self.iconSize;
end

local SetIconSize = function( self, value )
	self.iconSize = value;
	
	ReanchorIcons( self );
end

-- **** ctor ****
local ctor = function( self, baseCtor, filter )
	baseCtor( self );

	self.filter = filter;
	self.slots = { };
	self.icons = { };
	
	self.iconSize = 32;
	self.maxHeight = 300;
end

-- **** main ****
Internals.BagCategoryFrame, Base = kCore.CreateClass( ctor, { 
		Add = Add,
		Reset = Reset,
		Update = Update,
		Render = Render,

		-- filtering
		CheckId = CheckId,
		CheckType = CheckType,
		CheckEmpty = CheckEmpty,
		
		-- positioning
		GetMaxHeight = GetMaxHeight,
		SetMaxHeight = SetMaxHeight,
		
		GetIconSize = GetIconSize,
		SetIconSize = SetIconSize,
	}, Frame );