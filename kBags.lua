local _, Internals = ...; 

-- **** defines ****
local CATEGORIES = {
		{ "Quest" },
		{ -- Heirloom items
			42943, -- Bloodied Arcanite Reaper
			42944, -- Balanced Heartseeker
			42946, -- Charmed Ancient Bone Bow
			42948, -- Devout Aurastone Hammer
			44091, -- Sharpened Scarlet Kris
			44092, -- Reforged Truesilver Champion
			44093, -- Upgraded Dwarven Hand Cannon
			44094, -- The Blessed Hammer of Grace
			44095, -- Grand Staff of Jordan
			44096, -- Battleworn Thrash Blade
			48716, -- Venerable Mass of McGowan
			48718, -- Repurposed Lava Dredger
			42949, -- Polished Spaulders of Valor
			42951, -- Mystical Pauldrons of Elements
			42952, -- Stained Shadowcraft Spaulders
			42984, -- Preened Ironfeather Shoulders
			42985, -- Tattered Dreadmist Mantle
			42991, -- Swift Hand of Justice
			42992, -- Discerning Eye of the Beast
			44097, -- Inherited Insignia of the Horde
			44098, -- Inherited Insignia of the Alliance
			44099, -- Strengthened Stockade Pauldrons
			44100, -- Pristine Lightforge Spaulders
			44102, -- Aged Pauldrons of The Five Thunders
			44103, -- Exceptional Stormshroud Shoulders
			44105, -- Lasting Feralheart Spaulders
			44107, -- Exquisite Sunderseer Mantle
			48683, -- Mystical Vest of Elements
			48685, -- Polished Breastplate of Valor
			48687, -- Preened Ironfeather Breastplate
			48689, -- Stained Shadowcraft Tunic
			48691, -- Tattered Dreadmist Robe
			50255, -- Dread Pirate Ring
		},
		{ "Reagent" },
		{ "Consumable" },
		{ "Meat" },
		{
			"Fishing Poles",
			33820, -- Weather-Beaten Fishing Hat
			46006, -- Glow Worm
			34861, -- Sharpened Fish Hook
		},
		{ "Trade Goods->Other" },
		{ 
			"Devices",
			48933, -- Wormhole generator
		},
		{ "Parts" },
		{ 
			"Metal & Stone",
			"empty->Mining Bag",
		},
		{ "Trade Goods->Cloth" },
		{ 
			"Herb",
			"empty->Herb Bag",
		},
		{ 
			"Gem",
			"empty->Gem Bag",
		},
		{
			"Elemental",
		},
		{ 
			"Enchanting", 
			"empty->Enchanting Bag",
			34055, -- Greater Cosmic Essence 
		},
		{
			"empty->Soul Bag",
			6265, -- Soul Shard
		},
	};

-- **** imports ****
local BagFrame = Internals.BagFrame;

-- **** main ****

-- bag
local bagFrame = BagFrame( 0, NUM_BAG_SLOTS );
bagFrame:SetMaxHeight( 300 );
for _, category in ipairs( CATEGORIES ) do
	bagFrame:AddCategory( category );
end
bagFrame:SetFrameStrata( "HIGH" );
bagFrame:Hide();

-- bank
local bankFrame = BagFrame( NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS, -1 );
bankFrame:SetPoint( "BOTTOMRIGHT", bagFrame, "BOTTOMLEFT", -19, 0 );
bankFrame:SetMaxHeight( 400 );
for _, category in ipairs( CATEGORIES ) do
	bankFrame:AddCategory( category );
end
bankFrame:SetFrameStrata( "HIGH" );
bankFrame:Hide();

-- "hide" blizzard bags
BankFrame:ClearAllPoints();
BankFrame:SetPoint( "TOPRIGHT", UIParent, "BOTTOMLEFT", 0, 0 );
BankFrame.size = 0;
for index = 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
	container = _G[ "ContainerFrame" .. tostring( index ) ];
	container:ClearAllPoints();
	container:SetPoint( "TOPRIGHT", UIParent, "BOTTOMLEFT", 0, 0 );
	container.size = 0;
end
UIPanelWindows[ "BankFrame" ] = nil;

-- create secure openers - this is just temporary workaround until I implement creating templated frames through kWidgets
bagToggleFrame = CreateFrame( "Frame", nil, UIParent, "SecureHandlerShowHideTemplate" );
bagToggleFrame:SetParent( ContainerFrame1 );
bagToggleFrame:SetFrameRef( "BankFrame", BankFrame );
bagToggleFrame:SetFrameRef( "kBag", bagFrame );
bagToggleFrame:SetFrameRef( "PetActionButton10", PetActionButton10 );
bagToggleFrame:SetFrameRef( "MultiBarLeftButton12", MultiBarLeftButton12 );
bagToggleFrame:Execute( [[
		kBag = self:GetFrameRef( "kBag" );
		BankFrame = self:GetFrameRef( "BankFrame" );
		PetActionButton10 = self:GetFrameRef( "PetActionButton10" );
		MultiBarLeftButton12 = self:GetFrameRef( "MultiBarLeftButton12" );
	]] );
bagToggleFrame:SetAttribute( "_onshow", [[
		if ( PetActionButton10:IsShown() ) then
			kBag:SetPoint( "BOTTOMRIGHT", PetActionButton10, "BOTTOMLEFT", -19, -6 );
		else
			kBag:SetPoint( "BOTTOMRIGHT", MultiBarLeftButton12, "BOTTOMLEFT", -19, -8 );
		end
		kBag:Show();
	]] );
bagToggleFrame:SetAttribute( "_onhide", [[
		BankFrame:Hide();
		kBag:Hide();
	]] );
	
local bankToggleFrame = CreateFrame( "Frame", nil, UIParent, "SecureHandlerShowHideTemplate" );
bankToggleFrame:SetParent( BankFrame );
bankToggleFrame:SetFrameRef( "ContainerFrame1", ContainerFrame1 );
bankToggleFrame:SetFrameRef( "kBank", bankFrame );
bankToggleFrame:Execute( [[
		ContainerFrame1 = self:GetFrameRef( "ContainerFrame1" );
		kBank = self:GetFrameRef( "kBank" );
	]] );
bankToggleFrame:SetAttribute( "_onshow", [[	
		ContainerFrame1:Show();		
		kBank:Show();
	]] );
bankToggleFrame:SetAttribute( "_onhide", [[
		ContainerFrame1:Hide();		
		kBank:Hide();
	]] );