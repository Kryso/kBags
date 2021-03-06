local _, Internals = ...; 

-- **** imports ****
local kCore = kCore;
local kWidgets = kWidgets;

local Frame = kWidgets.Frame;
local Border = kWidgets.Border;
local BagCategoryFrame = Internals.BagCategoryFrame;

-- **** private ****
local Base;

local GetContainerItemType = function( self, container, slot )
	local itemType, subType, isEmpty;
	local id = GetContainerItemID( container, slot );
	
	if ( not id ) then
		if ( container <= 0 ) then return; end
		
		id = GetInventoryItemID( "player", ContainerIDToInventoryID( container ) );
		
		if ( not id ) then return; end	
		
		-- itemType here is in fact subType, but we want it to be returned as second argument
		_, _, _, _, _, _, itemType, _, _, _, _ = GetItemInfo( id );
		
		isEmpty = true;
	else
		_, _, _, _, _, itemType, subType, _, _, _, _ = GetItemInfo( id ); 
	end
	
	return id, itemType, subType, isEmpty;
end

-- **** event handlers ****
local OnBagUpdate = function( self, container )
	if ( ( container >= self.minContainer and container <= self.maxContainer ) or self.additionalContainer == container ) then
		self:Update();
	end
end

local OnBagUpdateCooldown = function( self )
	self:Update();
end

local OnItemLockChanged = function( self )
	self:Update();
end

-- **** frame scripts ****
local OnShow = function( self )
	if ( not InCombatLockdown() ) then
		self:Render();
	end
	self:Update();
end

local OnHide = function( self )
	if ( not InCombatLockdown() ) then
		self:Render();
	end
	self:Update();
end

-- **** public ****
local AddCategory = function( self, filter )
	local categories = self.categories;
	
	local category = BagCategoryFrame( filter );
	category:SetParent( self );
	
	local maxHeight = self.maxHeight;
	local iconSize = self.iconSize;
	
	if ( maxHeight ) then
		category:SetMaxHeight( maxHeight );
	end
	if ( iconSize ) then
		category:SetIconSize( iconSize );
	end
	
	category:SetPoint( "TOPLEFT", categories[ #categories ], "BOTTOMLEFT", 0, 0 );
	
	tinsert( categories, category );	
end

local ScanContainer = function( self, container )
	local defaultCategory = self.defaultCategory;
	local categories = self.categories;

	for slot = 1, GetContainerNumSlots( container ) do
		local category = defaultCategory;
		
		local id, itemType, subType, isEmpty = GetContainerItemType( self, container, slot );
		if ( isEmpty ) then
			for _, value in ipairs( categories ) do
				if ( value:CheckEmpty( itemType ) ) then
					category = value;
					break;
				end
			end
		else
			for _, value in ipairs( categories ) do
				if ( value:CheckId( id ) ) then
					category = value;
					break;
				end
			end
			
			if ( category == defaultCategory ) then
				for _, value in ipairs( categories ) do
					if ( value:CheckType( itemType, subType ) ) then
						category = value;
						break;
					end
				end
			end
		end
		
		category:Add( container, slot );
	end
end

local Render = function( self )
	local defaultCategory = self.defaultCategory;
	local categories = self.categories;
	
	for _, category in ipairs( categories ) do
		category:Reset();
	end
	
	local additionalContainer = self.additionalContainer;
	for container = self.minContainer, self.maxContainer do
		ScanContainer( self, container );
	end	
	if ( additionalContainer ) then
		ScanContainer( self, additionalContainer );
	end

	local width = 0;
	local height = 0;
	
	local prevCategory;
	for _, category in ipairs( categories ) do
		local categoryWidth, categoryHeight = category:Render();
		
		if ( categoryWidth > 0 and categoryHeight > 0 ) then
			if ( not prevCategory ) then
				category:SetPoint( "TOPLEFT", self, "TOPLEFT", 3, -3 );
			else
				category:SetPoint( "TOPLEFT", prevCategory, "TOPRIGHT", 0, 0 );
			end
			prevCategory = category;
			category:Show();
			
			width = width + categoryWidth;
			if ( height < categoryHeight ) then
				height = categoryHeight;
			end
		else
			category:Hide();
		end
	end
	
	self:SetWidth( width + 6 );
	self:SetHeight( height + 6 );
end

local Update = function( self )
	for _, category in ipairs( self.categories ) do
		category:Update();
	end
end

-- positioning
local GetMaxHeight = function( self )
	return self.maxHeight;
end

local SetMaxHeight = function( self, value )
	self.defaultCategory:SetMaxHeight( value );
	for _, category in ipairs( self.categories ) do
		category:SetMaxHeight( value );
	end
	
	self.maxHeight = value;
end

local GetIconSize = function( self )
	return self.iconSize;
end

local SetIconSize = function( self, value )
	self.defaultCategory:SetIconSize( value );
	for _, category in ipairs( self.categories ) do
		category:SetIconSize( value );
	end	
	
	self.iconSize = value;
end

-- **** ctor ****
local ctor = function( self, baseCtor, minContainer, maxContainer, additionalContainer )
	baseCtor( self );

	self.minContainer = minContainer;
	self.maxContainer = maxContainer;
	self.additionalContainer = additionalContainer;
	
	self.categories = { };
	
	local border = Border( self );
	border:SetPoint( "TOPLEFT", self, "TOPLEFT", 0, 0 );
	border:SetPoint( "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0 );
	self.border = border;
	
	local defaultCategory = BagCategoryFrame();
	defaultCategory:SetParent( self );
	defaultCategory:SetPoint( "TOPLEFT", self, "TOPLEFT", 3, -3 );
	tinsert( self.categories, defaultCategory );
	self.defaultCategory = defaultCategory;
	
	self:RegisterEvent( "BAG_UPDATE", OnBagUpdate );
	self:RegisterEvent( "BAG_UPDATE_COOLDOWN", OnBagUpdateCooldown );
	self:RegisterEvent( "ITEM_LOCK_CHANGED", OnItemLockChanged );
	
	self:SetScript( "OnShow", OnShow );
	self:SetScript( "OnHide", OnHide );
	
	self:Update();
end

-- **** main ****
Internals.BagFrame, Base = kCore.CreateClass( ctor, { 
		AddCategory = AddCategory,
		Update = Update,
		Render = Render,

		GetMaxHeight = GetMaxHeight,
		SetMaxHeight = SetMaxHeight,

		GetIconSize = GetIconSize,
		SetIconSize = SetIconSize,
	}, Frame );