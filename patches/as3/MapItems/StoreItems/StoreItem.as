package MapItems.StoreItems
{
   import Art.LoadArt;
   import FSM.StateMachine;
   import Geom.Circle;
   import Land.Land;
   import MapItems.Animals.DeerItem;
   import MapItems.Animals.GenericAnimal;
   import MapItems.Animals.MonsterItem;
   import MapItems.Coriander.CorianderItem;
   import MapItems.GenericItem;
   import MapItems.Items;
   import MapItems.StoreItems.States.BubblePop;
   import MapItems.StoreItems.States.GrowBubble;
   import Menu.HUD;
   import Menu.PurchaseMenu;
   import Menu.QuestHUD;
   import Menu.TradeMenu;
   import Rewards.Cards;
   import Rewards.Motes;
   import Sound.Attenuation;
   import Sound.SoundManager;
   import Tutorial.Tasks;
   import World.World;
   import flash.display.MovieClip;
   import flash.events.TimerEvent;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.utils.*;
   import gs.TweenMax;
   import gs.plugins.*;

   public class StoreItem extends GenericItem
   {

      public static var mVerdantBay:Object;

      public static var mWeddingIsle:Object;

      public static var mDress:Object;

      public static var mPearls:Object;

      public static var mTiara:Object;

      public static var mSilverStore:Object;

      public static var mSteelStore:Object;

      public static var mGoldStore:Object;

      public static var mChurch:Object;

      public var mDescription:String;

      public var mCostWood:int;

      public var mCostRock:int;

      public var mCostGem:int;

      public var mFrame:int;

      public var mItemClass:Class;

      public var mItemSize:int;

      public var mInner:int;

      public var mOuter:int;

      public var mFree:Boolean;

      public var mMaxItems:int = 1;

      protected var mPurchaseMenu:*;

      public var mPickedUp:Boolean = false;

      private var mAvaliable:Boolean = false;

      private var firstOver:Boolean = true;

      private var rockmax:TweenMax;

      private var woodmax:TweenMax;

      public function StoreItem(param1:int, param2:int, param3:Object, param4:Boolean)
      {
         var _loc5_:int = 0;
         var _loc6_:Timer = null;
         super();
         mName = param3.name;
         this.mDescription = param3.description;
         if(mName == "Verdant Bay")
         {
            if(!mVerdantBay)
            {
               this.mCostWood = HUD.mWoodMaxMin * 3 + HUD.mWood / 4;
               this.mCostRock = HUD.mGoldMaxMin * 3 + HUD.mRock / 4;
               this.mCostWood = Math.min(99999,this.mCostWood);
               this.mCostRock = Math.min(99999,this.mCostRock);
               mVerdantBay = new Object();
               mVerdantBay.wood = this.mCostWood;
               mVerdantBay.rock = this.mCostRock;
            }
            else
            {
               this.mCostWood = mVerdantBay.wood;
               this.mCostRock = mVerdantBay.rock;
            }
         }
         else if(mName == "Wedding Isle")
         {
            if(!mWeddingIsle)
            {
               this.mCostWood = HUD.mWoodMaxMin * 5 + HUD.mWood / 4;
               this.mCostRock = HUD.mGoldMaxMin * 5 + HUD.mRock / 4;
               this.mCostWood = Math.min(99999,this.mCostWood);
               this.mCostRock = Math.min(99999,this.mCostRock);
               mWeddingIsle = new Object();
               mWeddingIsle.wood = this.mCostWood;
               mWeddingIsle.rock = this.mCostRock;
            }
            else
            {
               this.mCostWood = mWeddingIsle.wood;
               this.mCostRock = mWeddingIsle.rock;
            }
         }
         else if(mName == "Wedding Dress")
         {
            if(!mDress)
            {
               this.mCostWood = HUD.mWoodMaxMin * 1 + HUD.mRock / 2;
               this.mCostRock = HUD.mGoldMaxMin * 1 + HUD.mWood / 2;
               this.mCostWood = Math.min(99999,this.mCostWood);
               this.mCostRock = Math.min(99999,this.mCostRock);
               mDress = new Object();
               mDress.wood = this.mCostWood;
               mDress.rock = this.mCostRock;
            }
            else
            {
               this.mCostWood = mDress.wood;
               this.mCostRock = mDress.rock;
            }
         }
         else if(mName == "String of Pearls")
         {
            if(!mPearls)
            {
               this.mCostWood = HUD.mWoodMaxMin * 4 + HUD.mRock / 2;
               this.mCostRock = HUD.mGoldMaxMin * 4 + HUD.mWood / 2;
               this.mCostWood = Math.min(99999,this.mCostWood);
               this.mCostRock = Math.min(99999,this.mCostRock);
               mPearls = new Object();
               mPearls.wood = this.mCostWood;
               mPearls.rock = this.mCostRock;
            }
            else
            {
               this.mCostWood = mPearls.wood;
               this.mCostRock = mPearls.rock;
            }
         }
         else if(mName == "Tiara")
         {
            if(!mTiara)
            {
               this.mCostWood = HUD.mWoodMaxMin * 8 + HUD.mRock / 2;
               this.mCostRock = HUD.mGoldMaxMin * 8 + HUD.mWood / 2;
               this.mCostWood = Math.min(99999,this.mCostWood);
               this.mCostRock = Math.min(99999,this.mCostRock);
               mTiara = new Object();
               mTiara.wood = this.mCostWood;
               mTiara.rock = this.mCostRock;
            }
            else
            {
               this.mCostWood = mTiara.wood;
               this.mCostRock = mTiara.rock;
            }
         }
         else
         {
            this.mCostWood = param3.costwood;
            this.mCostRock = param3.costrock;
         }
         this.mCostGem = param3.costgem;
         if(this is BridgeAngelItem)
         {
            init(param1,param2,LoadArt.mGhostArt.getFrame(1),new Circle(param1,param2,100),new Circle(param1,param2,21));
         }
         else
         {
            this.mFrame = param3.frame;
            this.mItemClass = param3.itemclass;
            this.mItemSize = param3.size;
            this.mInner = param3.inner;
            this.mOuter = param3.outer;
            this.mFree = param4;
            _loc5_ = this.mFrame;
            if(this.mFree)
            {
               _loc5_ += StoreItemsList.mNoStoreItemFrames * 2;
            }
            if(this.mFree)
            {
               init(param1,param2,LoadArt.mStoreItems.getFrame(_loc5_),new Circle(param1,param2,21),new Circle(param1,param2,21));
            }
            else
            {
               init(param1,param2,LoadArt.mStoreItems.getFrame(_loc5_),new Circle(param1,param2,100),new Circle(param1,param2,21));
            }
            if(this.mFree)
            {
               _loc6_ = new Timer(30000,1);
               _loc6_.addEventListener(TimerEvent.TIMER_COMPLETE,this.hintToPickUp);
               _loc6_.start();
               Attenuation.PlayPointSound("BubbleAppear",new Point(this.x,this.y),0.5,1500);
            }
         }
      }

      public static function SetUp(param1:XMLList) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         _loc5_ = 0;
         while(_loc5_ < param1.length())
         {
            _loc2_ = int(param1[_loc5_].id);
            _loc3_ = int(param1[_loc5_].wood);
            _loc4_ = int(param1[_loc5_].rock);
            if(_loc2_ == 1)
            {
               mVerdantBay = new Object();
               mVerdantBay.wood = _loc3_;
               mVerdantBay.rock = _loc4_;
            }
            else if(_loc2_ == 2)
            {
               mWeddingIsle = new Object();
               mWeddingIsle.wood = _loc3_;
               mWeddingIsle.rock = _loc4_;
            }
            else if(_loc2_ == 3)
            {
               mDress = new Object();
               mDress.wood = _loc3_;
               mDress.rock = _loc4_;
            }
            else if(_loc2_ == 4)
            {
               mPearls = new Object();
               mPearls.wood = _loc3_;
               mPearls.rock = _loc4_;
            }
            else if(_loc2_ == 5)
            {
               mTiara = new Object();
               mTiara.wood = _loc3_;
               mTiara.rock = _loc4_;
            }
            else if(_loc2_ == 6)
            {
               mSilverStore = new Object();
               mSilverStore.wood = _loc3_;
               mSilverStore.rock = _loc4_;
            }
            else if(_loc2_ == 7)
            {
               mSteelStore = new Object();
               mSteelStore.wood = _loc3_;
               mSteelStore.rock = _loc4_;
            }
            else if(_loc2_ == 8)
            {
               mGoldStore = new Object();
               mGoldStore.wood = _loc3_;
               mGoldStore.rock = _loc4_;
            }
            else if(_loc2_ == 9)
            {
               mChurch = new Object();
               mChurch.wood = _loc3_;
               mChurch.rock = _loc4_;
            }
            _loc5_++;
         }
      }

      private function hintToPickUp(param1:TimerEvent) : void
      {
         if(!this.mPickedUp)
         {
            Tasks.HintTextEvent(4,"You\'ve discovered a free " + mName + "!  Click to pick it up.");
         }
      }

      override public function initStateMachine() : void
      {
         if(this.mFree)
         {
            mStateMachine = new StateMachine(this);
            mStateMachine.SetCurrentState(new GrowBubble());
         }
      }

      override public function draw() : void
      {
         var _loc2_:Matrix = null;
         var _loc3_:ColorTransform = null;
         if(!mArt)
         {
            trace("___WE HAVE NULL ART___");
            trace(this);
            trace(this.mID);
            throw new Error("___WE HAVE NULL ART___," + this + "," + this.mID);
         }
         if(mStateMachine)
         {
            mStateMachine.Update();
         }
         drawx = x - World.WORLD_LOC_X;
         drawy = y / 2 - World.WORLD_LOC_Y;
         var _loc1_:Rectangle = new Rectangle(0,0,World.SCREEN_WIDTH,World.SCREEN_HEIGHT);
         if(mScale == 1)
         {
            if(!mArt)
            {
               return;
            }
            itemRect = new Rectangle(drawx + mArt.hotspotX,drawy + mArt.hotspotY,mArt.mRect.width,mArt.mRect.height);
         }
         else
         {
            if(!mArt)
            {
               return;
            }
            itemRect = new Rectangle(drawx + mArt.hotspotX * mScale,drawy + mArt.hotspotY * mScale,mArt.mRect.width * mScale,mArt.mRect.height * mScale);
         }
         if(!this.itemRect)
         {
            trace("this",this);
            trace("in mapitem",Items.Exists(this));
            trace("this",this.mName);
            trace("mArt",mArt);
            trace("x",x);
            trace("y",y);
         }
         if(_loc1_.intersects(itemRect))
         {
            _loc2_ = new Matrix();
            _loc2_.translate(mArt.hotspotX,mArt.hotspotY);
            _loc2_.scale(mScale,mScale);
            _loc2_.translate(drawx,drawy);
            _loc3_ = new ColorTransform();
            if(this.Avaliable())
            {
               if(this.mFree)
               {
                  mAlpha = 1;
               }
               else if(this.SoldOut())
               {
                  mAlpha = 0;
               }
               else if(HUD.PurchaseFeedback(this.mCostWood,this.mCostRock,this.mCostGem) != 0)
               {
                  mAlpha = 0.5;
               }
               else
               {
                  mAlpha = 1;
               }
            }
            else
            {
               mAlpha = 0;
            }
            _loc3_.alphaMultiplier = mAlpha;
            Land.queue(mArt.bitmapData,_loc2_,_loc3_,null,true);
         }
      }

      public function Avaliable() : Boolean
      {
         if(mName == "Silver Store")
         {
            if(!this.mAvaliable)
            {
               trace("bronze store mote",Motes.TestMote("bronze_store"));
               if(Motes.TestMote("bronze_store"))
               {
                  this.mAvaliable = true;
                  if(!mSilverStore)
                  {
                     this.mCostWood = HUD.mWoodMaxMin * 2 + HUD.mRock;
                     this.mCostRock = HUD.mGoldMaxMin * 2 + HUD.mRock + 10;
                     this.mCostWood = Math.min(99999,this.mCostWood);
                     this.mCostRock = Math.min(99999,this.mCostRock);
                     mSilverStore = new Object();
                     mSilverStore.wood = this.mCostWood;
                     mSilverStore.rock = this.mCostRock;
                  }
                  else
                  {
                     this.mCostWood = mSilverStore.wood;
                     this.mCostRock = mSilverStore.rock;
                  }
                  return true;
               }
               return false;
            }
         }
         else if(mName == "Steel Store")
         {
            if(!this.mAvaliable)
            {
               if(Motes.TestMote("girl_quest_2"))
               {
                  this.mAvaliable = true;
                  if(!mSteelStore)
                  {
                     this.mCostWood = HUD.mWoodMaxMin * 6 + HUD.mRock / 2;
                     this.mCostRock = HUD.mGoldMaxMin * 6 + HUD.mWood / 2;
                     this.mCostWood = Math.min(99999,this.mCostWood);
                     this.mCostRock = Math.min(99999,this.mCostRock);
                     mSteelStore = new Object();
                     mSteelStore.wood = this.mCostWood;
                     mSteelStore.rock = this.mCostRock;
                  }
                  else
                  {
                     this.mCostWood = mSteelStore.wood;
                     this.mCostRock = mSteelStore.rock;
                  }
                  return true;
               }
               return false;
            }
         }
         else if(mName == "Gold Store")
         {
            if(!this.mAvaliable)
            {
               if(Motes.TestMote("girl_quest_6"))
               {
                  this.mAvaliable = true;
                  if(!mGoldStore)
                  {
                     this.mCostWood = HUD.mWoodMaxMin * 7 + HUD.mRock / 2;
                     this.mCostRock = HUD.mGoldMaxMin * 7 + HUD.mWood / 2;
                     this.mCostWood = Math.min(99999,this.mCostWood);
                     this.mCostRock = Math.min(99999,this.mCostRock);
                     mGoldStore = new Object();
                     mGoldStore.wood = this.mCostWood;
                     mGoldStore.rock = this.mCostRock;
                  }
                  else
                  {
                     this.mCostWood = mGoldStore.wood;
                     this.mCostRock = mGoldStore.rock;
                  }
                  return true;
               }
               return false;
            }
         }
         else if(mName == "Church")
         {
            if(!this.mAvaliable)
            {
               if(Motes.TestMote("girl_crown"))
               {
                  this.mAvaliable = true;
                  if(!mChurch)
                  {
                     this.mCostWood = HUD.mWoodMaxMin * 10 + HUD.mRock / 2;
                     this.mCostRock = HUD.mGoldMaxMin * 10 + HUD.mWood / 2;
                     this.mCostWood = Math.min(99999,this.mCostWood);
                     this.mCostRock = Math.min(99999,this.mCostRock);
                     mChurch = new Object();
                     mChurch.wood = this.mCostWood;
                     mChurch.rock = this.mCostRock;
                  }
                  else
                  {
                     this.mCostWood = mChurch.wood;
                     this.mCostRock = mChurch.rock;
                  }
                  return true;
               }
               return false;
            }
         }
         return true;
      }

      public function SoldOut() : Boolean
      {
         var _loc1_:int = 0;
         if(this.mMaxItems != 0)
         {
            if(mName == "Wedding Dress")
            {
               if(Motes.TestMote("girl_quest_2"))
               {
                  return true;
               }
               return false;
            }
            if(mName == "String of Pearls")
            {
               if(Motes.TestMote("girl_quest_6"))
               {
                  return true;
               }
               return false;
            }
            if(mName == "Tiara")
            {
               if(Motes.TestMote("girl_crown"))
               {
                  return true;
               }
               return false;
            }
            _loc1_ = Items.GetCountByName(this.mName);
            if(_loc1_ > this.mMaxItems)
            {
               return true;
            }
         }
         return false;
      }

      public function Highlight() : void
      {
         var _loc2_:SoundManager = null;
         var _loc1_:int = this.mFrame + StoreItemsList.mNoStoreItemFrames;
         if(this.mFree)
         {
            if(this.firstOver)
            {
               _loc2_ = SoundManager.getInstance();
               _loc2_.playSound("BubbleOver",1.3);
               this.firstOver = false;
            }
            _loc1_ += StoreItemsList.mNoStoreItemFrames * 2;
         }
         else if(this.firstOver)
         {
            _loc2_ = SoundManager.getInstance();
            _loc2_.playSound("StoreOver",2);
            this.firstOver = false;
         }
         this.mArt = LoadArt.mStoreItems.getFrame(_loc1_);
      }

      public function Click() : void
      {
         var _loc1_:SoundManager = null;
         if(!World.mMenuOpen && !this.mPurchaseMenu)
         {
            _loc1_ = SoundManager.getInstance();
            _loc1_.playSound("ClickStore",2);
            World.mMenuOpen = true;
            if(mName == "Buy Gold" || mName == "Buy Gems" || mName == "Buy Wood")
            {
               this.mPurchaseMenu = new TradeMenu();
               this.mPurchaseMenu.init(mName,this.mDescription,this.mCostWood,this.mCostRock,this.mCostGem,this,this.mFree);
               Land.mStage.addChild(this.mPurchaseMenu);
            }
            else
            {
               this.mPurchaseMenu = new PurchaseMenu();
               this.mPurchaseMenu.init(mName,this.mDescription,this.mCostWood,this.mCostRock,this.mCostGem,this,this.mFree);
               Land.mStage.addChild(this.mPurchaseMenu);
            }
         }
      }

      public function Pop() : void
      {
         if(!this.mPickedUp)
         {
            this.mPickedUp = true;
            mStateMachine = new StateMachine(this);
            mStateMachine.SetCurrentState(new BubblePop(this.mFrame));
         }
      }

      public function pickUp() : void
      {
         var _loc1_:GenericItem = null;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:Object = null;
         var _loc5_:PlacementItem = null;
         if(!this.mPickedUp)
         {
            this.mPickedUp = true;
            if(this == QuestHUD.mFocusItem)
            {
               QuestHUD.mFocusItem = null;
            }
            Motes.PurchaseMote(mName);
            if(getQualifiedSuperclassName(this.mItemClass) == "MapItems.Animals::GenericAnimal")
            {
               World.mMenuOpen = false;
               _loc2_ = this.x;
               _loc3_ = this.y;
               _loc1_ = new this.mItemClass(_loc2_,_loc3_);
               _loc4_ = StoreItemsList.GetObjFromName(mName);
               _loc1_.mName = _loc4_.name;
               _loc1_.mItemID = int(_loc4_.id);
               _loc1_.mPersist = int(_loc4_.persistent) == 1;
               if(!(_loc1_ is MonsterItem || _loc1_ is DeerItem))
               {
                  GenericAnimal(_loc1_).FollowAvatar(World.mAvatar);
               }
               if(this.mFree)
               {
                  mStateMachine = new StateMachine(this);
                  mStateMachine.SetCurrentState(new BubblePop(this.mFrame));
               }
            }
            else
            {
               _loc5_ = new PlacementItem(World.mAvatar.x,World.mAvatar.y,this.mFrame,this.mInner,this.mOuter,this.mItemSize,this.mItemClass,mName,this.mCostWood,this.mCostGem,this.mCostRock);
               _loc5_.mMissionID = this.mMissionID;
               World.mMenuOpen = false;
               if(this.mFree)
               {
                  mStateMachine = new StateMachine(this);
                  mStateMachine.SetCurrentState(new BubblePop(this.mFrame));
               }
            }
            if(!Cards.FoundItem(mName,this))
            {
               Tasks.PickUp(mName);
            }
         }
      }

      private function decorate() : void
      {
         CorianderItem.Decorate();
         TweenMax.to(Land.mBackgroundBitmap,3,{
            "colorTransform":{
               "tint":0,
               "tintAmount":0
            },
            "onComplete":this.focusAvatar
         });
      }

      private function focusAvatar() : void
      {
         World.mFocus = World.mAvatar;
      }

      private function awardChurch() : void
      {
         if(!Cards.FoundItem("Church",this))
         {
            Tasks.PickUp("Church");
         }
         Motes.PurchaseMote("Church");
         World.mFocus = World.mAvatar;
      }

      private function drawChurch() : void
      {
         StoreItemsList.MakeItem("Church",0,0);
         TweenMax.to(Land.mBackgroundBitmap,3,{
            "colorTransform":{
               "tint":0,
               "tintAmount":0
            },
            "onComplete":this.awardChurch
         });
      }

      public function purchase(param1:int, param2:int, param3:int) : void
      {
         var _loc4_:GenericItem = null;
         var _loc5_:Object = null;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:Class = null;
         var _loc9_:Object = null;
         var _loc10_:PlacementItem = null;
         if(World.mMenuOpen)
         {
            World.mFocus = World.mAvatar;
            if(getQualifiedClassName(this.mItemClass) == "MapItems.Decorations::Dress" || getQualifiedClassName(this.mItemClass) == "MapItems.Decorations::Pearls" || getQualifiedClassName(this.mItemClass) == "MapItems.Decorations::Tiara")
            {
               HUD.SubtractResource(param1,param2,param3);
               this.PingCost(param1,param2,param3);
               World.mMenuOpen = false;
               this.mPurchaseMenu.destroy();
               Land.mStage.removeChild(this.mPurchaseMenu);
               this.mPurchaseMenu = null;
               World.mFocus = Items.GetItemArrayByName("Coriander")[0];
               TweenMax.to(Land.mBackgroundBitmap,1,{
                  "colorTransform":{
                     "tint":16777215,
                     "tintAmount":1
                  },
                  "onComplete":this.decorate
               });
            }
            else
            {
               if(getQualifiedClassName(this.mItemClass) == "MapItems.Building::CastleItem")
               {
                  HUD.SubtractResource(param1,param2,param3);
                  this.PingCost(param1,param2,param3);
                  World.mMenuOpen = false;
                  this.mPurchaseMenu.destroy();
                  Land.mStage.removeChild(this.mPurchaseMenu);
                  this.mPurchaseMenu = null;
                  _loc5_ = new Object();
                  _loc5_.x = 3937;
                  _loc5_.y = 1027;
                  World.mFocus = _loc5_;
                  TweenMax.to(Land.mBackgroundBitmap,1,{
                     "colorTransform":{
                        "tint":16777215,
                        "tintAmount":1
                     },
                     "onComplete":this.drawChurch
                  });
                  return;
               }
               if(getQualifiedSuperclassName(this.mItemClass) == "MapItems.Animals::GenericAnimal")
               {
                  HUD.SubtractResource(param1,param2,param3);
                  this.PingCost(param1,param2,param3);
                  World.mMenuOpen = false;
                  this.mPurchaseMenu.destroy();
                  Land.mStage.removeChild(this.mPurchaseMenu);
                  this.mPurchaseMenu = null;
                  _loc6_ = this.x;
                  _loc7_ = this.y;
                  _loc8_ = this.mItemClass;
                  _loc4_ = new _loc8_(_loc6_,_loc7_);
                  _loc9_ = StoreItemsList.GetObjFromName(mName);
                  _loc4_.mName = _loc9_.name;
                  _loc4_.mItemID = int(_loc9_.id);
                  _loc4_.mPersist = int(_loc9_.persistent) == 1;
                  if(!(_loc4_ is MonsterItem || _loc4_ is DeerItem))
                  {
                     GenericAnimal(_loc4_).FollowAvatar(World.mAvatar);
                  }
                  if(this.mFree)
                  {
                     Items.RemoveItem(this);
                  }
               }
               else
               {
                  _loc10_ = new PlacementItem(World.mAvatar.x,World.mAvatar.y,this.mFrame,this.mInner,this.mOuter,this.mItemSize,this.mItemClass,mName,this.mCostWood,this.mCostGem,this.mCostRock);
                  HUD.SubtractResource(param1,param2,param3);
                  this.PingCost(param1,param2,param3);
                  World.mMenuOpen = false;
                  this.mPurchaseMenu.destroy();
                  Land.mStage.removeChild(this.mPurchaseMenu);
                  this.mPurchaseMenu = null;
                  if(this.mFree)
                  {
                     Items.RemoveItem(this);
                  }
               }
            }
            if(!Cards.FoundItem(mName,this))
            {
               Tasks.PickUp(mName);
            }
            Motes.PurchaseMote(mName);
         }
      }

      private function PingCost(param1:int, param2:int, param3:int) : void
      {
         if(param2 != 0)
         {
            this.PingRock(param2);
         }
         if(param1 != 0)
         {
            this.PingWood(param1);
         }
      }

      private function PingRock(param1:int) : void
      {
         var _loc2_:MovieClip = new MineText();
         _loc2_.mValue.text = String(param1);
         _loc2_.x = 223.45;
         _loc2_.y = 1.8;
         Land.mTextOut.addChild(_loc2_);
         var _loc3_:int = this.drawx - 35;
         var _loc4_:int = this.drawy;
         this.rockmax = new TweenMax(_loc2_,2,{
            "x":_loc3_,
            "y":_loc4_,
            "alpha":0.5,
            "onUpdate":this.updateRockTween,
            "onComplete":this.removeRock,
            "onCompleteParams":[_loc2_,param1]
         });
      }

      private function updateRockTween() : void
      {
         this.rockmax.setDestination("x",this.drawx - 35);
         this.rockmax.setDestination("y",this.drawy);
      }

      private function removeRock(param1:MovieClip, param2:int) : void
      {
         Land.mTextOut.removeChild(param1);
         param1 = null;
      }

      public function PingWood(param1:int) : void
      {
         var _loc2_:MovieClip = new MillText();
         _loc2_.mValue.text = String(param1);
         _loc2_.x = 168;
         _loc2_.y = 1.8;
         Land.mTextOut.addChild(_loc2_);
         var _loc3_:int = this.drawx - 35;
         var _loc4_:int = this.drawy;
         this.woodmax = new TweenMax(_loc2_,2,{
            "x":_loc3_,
            "y":_loc4_,
            "alpha":0.5,
            "onUpdate":this.updateWoodTween,
            "onComplete":this.removeWood,
            "onCompleteParams":[_loc2_,param1]
         });
      }

      private function updateWoodTween() : void
      {
         this.woodmax.setDestination("x",this.drawx - 35);
         this.woodmax.setDestination("y",this.drawy);
      }

      private function removeWood(param1:MovieClip, param2:int) : void
      {
         Land.mTextOut.removeChild(param1);
         param1 = null;
      }

      public function cancel() : void
      {
         if(World.mMenuOpen)
         {
            World.mFocus = World.mAvatar;
            World.mMenuOpen = false;
            this.mPurchaseMenu.destroy();
            Land.mStage.removeChild(this.mPurchaseMenu);
            this.mPurchaseMenu = null;
         }
      }

      override public function Update() : void
      {
         if(mStateMachine)
         {
            mStateMachine.Update();
         }
         if(this.mPurchaseMenu)
         {
            this.mPurchaseMenu.x = this.x - World.WORLD_LOC_X;
            this.mPurchaseMenu.y = this.y / 2 - World.WORLD_LOC_Y - 70;
         }
      }

      public function Unhighlight() : void
      {
         this.firstOver = true;
         var _loc1_:int = this.mFrame;
         if(this.mFree)
         {
            _loc1_ += StoreItemsList.mNoStoreItemFrames * 2;
         }
         this.mArt = LoadArt.mStoreItems.getFrame(_loc1_);
      }
   }
}
