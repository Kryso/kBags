local _, Internals = ...; 

-- **** imports ****
local kCore = kCore;
local kWidgets = kWidgets;

local AuraIcon = kWidgets.AuraIcon;

local SecureActionButtonTemplate = kCore.CreateClass( function( self ) end, { }, function( self )
	local result = CreateFrame( "Button", nil, UIParent, "SecureActionButtonTemplate" );
	
	if ( not self.initialized ) then
		setmetatable( self.prototype, getmetatable( result ) );
		self.initialized = true;
	end
	
	return result;
end );

-- **** private ****
local Base;

local SplitStack = function( button, split )
	local self = button:GetParent();
	
	SplitContainerItem( self.container, self.slot, split );
end

-- **** event handlers ****

-- **** frame script handlers ****
local OnEnter = function( button, motion )
	local self = button:GetParent();

	local container = self.container;
	local slot = self.slot;
		
	self:SetBorderSize( 2 );
	
	if ( self:GetRight() >= ( GetScreenWidth() / 2 ) ) then
		GameTooltip:SetOwner( self, "ANCHOR_LEFT" );
	else
		GameTooltip:SetOwner( self, "ANCHOR_RIGHT" );
	end
	
	if ( container == -1 ) then
		GameTooltip:SetInventoryItem( "player", BankButtonIDToInvSlotID( slot ) );
	else
		local _, repairCost = GameTooltip:SetBagItem( container, slot );
		if ( InRepairMode() and ( repairCost and repairCost > 0 ) ) then
			GameTooltip:AddLine( REPAIR_COST, "", 1, 1, 1 );
			SetTooltipMoney( GameTooltip, repairCost );
		end
	end

	if ( IsModifiedClick( "DRESSUP" ) and self.hasItem ) then
		ShowInspectCursor();
	elseif ( MerchantFrame:IsShown() and MerchantFrame.selectedTab == 1 ) then
		ShowContainerSellCursor( container, slot );
	elseif ( self.readable ) then
		ShowInspectCursor();
	else
		ResetCursor();
	end
	
	local additionalInfo = "Slot: " .. tostring( container ) .. " / " .. tostring( slot ) .. " "
	local id = GetContainerItemID( container, slot );
	if ( id ) then
		local _, _, _, _, _, itemType, itemSubType, _, _, _, _ = GetItemInfo( id );
		additionalInfo = additionalInfo .. "Id: " .. tostring( id ) .. " Type: " .. tostring( itemType ) .. " / " .. tostring( itemSubType );
	end
	GameTooltip:AddLine( additionalInfo, "", 1, 1, 1 );
	
	GameTooltip:Show();
end

local OnLeave = function( button, motion )
	local self = button:GetParent();

	self:SetBorderSize( 1 );
	
	GameTooltip:Hide();
	ResetCursor();
end

local OnDragStart = function( button, clickedButton )
	local self = button:GetParent();

	PickupContainerItem( self.container, self.slot );
end

local OnReceiveDrag = function( button )
	local self = button:GetParent();

	PickupContainerItem( self.container, self.slot );
end

local OnMouseUp = function( button, clickedButton )
	local self = button:GetParent();
	local container = self.container;
	local slot = self.slot;

	if ( HandleModifiedItemClick( GetContainerItemLink( container, slot ) ) ) then
		return;
	end
	
	if ( IsModifiedClick( "SOCKETITEM" ) ) then
		SocketContainerItem( container, slot );
	end
	
	if ( IsModifiedClick( "SPLITSTACK" ) ) then
		local texture, itemCount, locked = GetContainerItemInfo( container, slot );
		if ( not locked ) then
			OpenStackSplitFrame( itemCount, button, "BOTTOMRIGHT", "TOPRIGHT" );
		end
		return;
	end
	
	if ( clickedButton == "LeftButton" ) then
		PickupContainerItem( container, slot );
	end
end

-- **** public ****
local Get = function( self )
	return self.container, self.slot;
end

local Set = function( self, container, slot )
	self.button:SetAttribute( "item", tostring( container ) .. " " .. tostring( slot ) );
	
	self.container = container;
	self.slot = slot;
end

local Update = function( self )
	local container = self.container;
	local slot = self.slot;
	
	local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo( container, slot );
	local start, duration, enable = GetContainerItemCooldown( container, slot );
	local name, _, rarity, _, _, itemType, itemSubType, _, _, _, _;
	if ( link ) then
		name, _, rarity, _, _, itemType, itemSubType, _, _, _, _ = GetItemInfo( link );
	end
	local color = rarity and ITEM_QUALITY_COLORS[ rarity ];
	
	self:SetTexture( texture );
	self:SetCount( count );
	self:SetCooldown( start, duration );	
	self.icon:SetDesaturated( locked );	
	if ( color ) then
		self:SetBorderColor( color.r, color.g, color.b, 1 );
	else
		self:SetBorderColor( 0.3, 0.3, 0.3, 1 );
	end
	self.readable = readable;
	self.hasItem = texture and true or false;	
end

-- **** ctor ****
local ctor = function( self, baseCtor )
	baseCtor( self );
	
	self.cooldown:SetReverse( false );
	
	local button = SecureActionButtonTemplate();
	button:SetParent( self );
	button:SetPoint( "TOPLEFT", self, "TOPLEFT", 0, 0 );
	button:SetPoint( "BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0 );
	button:SetAttribute( "type2", "item" );
	
	button.SplitStack = SplitStack;
	
	button:SetScript( "OnEnter", OnEnter );
	button:SetScript( "OnLeave", OnLeave );
	
	button:SetScript( "OnMouseUp", OnMouseUp );
	
	button:SetScript( "OnDragStart", OnDragStart );
	button:SetScript( "OnReceiveDrag", OnReceiveDrag );

	button:RegisterForClicks( "LeftButtonUp", "RightButtonUp" );
	button:RegisterForDrag( "LeftButton" );
	
	self.button = button;
end

-- **** main ****
Internals.BagIcon, Base = kCore.CreateClass( ctor, { 
		Get = Get,
		Set = Set,
		Update = Update,
	}, AuraIcon );