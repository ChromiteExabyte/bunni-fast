package World
{
   import Art.LoadArt;
   import Collision.TestCollision;
   import Geom.Circle;
   import Geom.Vector2D;
   import Land.Land;
   import MapItems.Angel.AngelItem;
   import MapItems.Animals.GenericAnimal;
   import MapItems.Animals.MonsterItem;
   import MapItems.Avatar.AvatarItem;
   import MapItems.Building.*;
   import MapItems.Coriander.CorianderItem;
   import MapItems.FruitTrees.FruitTree;
   import MapItems.GenericItem;
   import MapItems.Ghosts.QuestItem;
   import MapItems.GirlBunny.GirlBunny;
   import MapItems.GirlBunny.GirlFriendBunny;
   import MapItems.GirlBunny.PiratePeach;
   import MapItems.HiScoreMan.HighScoreItem;
   import MapItems.Items;
   import MapItems.Mote.MoteItem;
   import MapItems.PiratePete.PiratePete;
   import MapItems.Priest.PriestItem;
   import MapItems.StoreItems.PlacementItem;
   import MapItems.StoreItems.StoreItem;
   import MapItems.StoreItems.StoreItemsList;
   import MapItems.Tower.TowerItem;
   import MapItems.Tutorial.TutorialItem;
   import Menu.HUD;
   import Menu.QuestHUD;
   import Metrics.Metrics;
   import Save.Save;
   import Rewards.Motes;
   import Sound.SoundManager;
   import Switches.Switch;
   import Tutorial.Tasks;
   import flash.display.BitmapData;
   import flash.display.BlendMode;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.display.StageQuality;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.filters.BlurFilter;
   import flash.external.ExternalInterface;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.ui.Mouse;
   import flash.utils.getTimer;
   import flash.utils.getQualifiedClassName;

   public class World extends MovieClip
   {

      public static var mHUD:HUD;

      public static var mAvatar:AvatarItem;

      public static var mPeach:PiratePeach;

      public static var mPete:PiratePete;

      public static var mGirl:GirlFriendBunny;

      public static var mTower:TowerItem;

      public static var mChurch:CastleItem;

      public static var mPointer:MovieClip;

      public static var mFocus:*;

      public static var mWorld:World;

      public static var WORLD_WIDTH:int = 5000;

      public static var WORLD_HEIGHT:int = 5000;

      public static const SCREEN_WIDTH:int = 800;

      public static const SCREEN_HEIGHT:int = 600;

      public static var WORLD_ROTATION:int = 0;

      public static var mCrazyMonsters:Boolean = false;

      public static var WORLD_LOC_X:int = 1050 - SCREEN_WIDTH / 2;

      public static var WORLD_LOC_Y:int = 600 - SCREEN_HEIGHT / 2;

      public static var mMenuOpen:Boolean = false;

      private static var mReturningItem:Boolean = false;

      private static var mPause:Boolean = false;

      public static var mMapDraw:Boolean = false;

      private var mDragingBunny:GenericAnimal = null;

      private var mDragingItem:PlacementItem = null;

      private var mStage:MovieClip;

      private var mClosestItem:GenericItem;

      private var mLastItem:GenericItem;

      private var mLastItemOver:GenericItem;

      private var mMouseDown:Boolean = false;

      private var mMouseStillDownCounter:int = 0;

      private var mLastX:int;

      private var mLastY:int;

      private var mMetrics:Metrics;

      private var mQuestHUD:QuestHUD;

      private var mIntroDone:Boolean = false;

      private var mLoadDone:Boolean = false;

      private var mBunniTitle:Bunni;

      private var mOverlay:Shape = new Shape();

      private var mOverlayBD:BitmapData = new BitmapData(World.SCREEN_WIDTH,World.SCREEN_HEIGHT,false);

      private var bf:BlurFilter = new BlurFilter(8,8);

      // bunni-fast: optional observation only; no change to frameRate or simulation timing.
      private var mBenchLastFrame:int = 0;
      private var mBenchDeltas:String = "";

      private var mBench:Boolean = false;
      private var mBenchFrames:int = 0;
      private var mBenchStart:int = 0;

      public function World()
      {
         super();
         WORLD_WIDTH = int(Bunni.mXML.worldsize);
         WORLD_HEIGHT = int(Bunni.mXML.worldsize);
         mWorld = this;
         mHUD = new HUD();
      }

      public static function PauseGame() : void
      {
         trace("pause");
         mPause = true;
         if(mPointer)
         {
            mPointer.visible = false;
            Mouse.show();
         }
      }

      public static function Continue() : void
      {
         trace("continue");
         mPause = false;
      }

      public function init(param1:MovieClip, param2:Bunni) : void
      {
         var stage:MovieClip = param1;
         var bunniTitle:Bunni = param2;
         this.mStage = stage;
         this.mBunniTitle = bunniTitle;
         mBench = bunniTitle.loaderInfo.parameters.bunniBench == "1";
         new LoadArt(function():void
         {
            Items.init();
            Bunni.SetLoadFeedback("Get Ready!");
            LoadDone();
         });
      }

      public function LoadDone() : void
      {
         this.mLoadDone = true;
         this.InitGame();
      }

      public function IntroDone() : void
      {
         this.mIntroDone = true;
         this.InitGame();
      }

      public function InitGame() : void
      {
         if(this.mIntroDone && this.mLoadDone)
         {
            trace("initgamecalled");
            // bunni-fast: retain the host's original quality. Explicit benchmark overrides only.
            var renderQuality:String = this.mBunniTitle.loaderInfo.parameters.bunniQuality;
            if(renderQuality == StageQuality.LOW || renderQuality == StageQuality.MEDIUM || renderQuality == StageQuality.HIGH || renderQuality == StageQuality.BEST)
            {
               this.mBunniTitle.stage.quality = renderQuality;
            }
            if(mBench && ExternalInterface.available)
            {
               ExternalInterface.addCallback("bunniBenchQuality",this.benchQuality);
               ExternalInterface.addCallback("bunniBenchRenderInfo",Land.renderInfo);
               ExternalInterface.addCallback("bunniBenchIdentity",Land.setIdentityFilterBypass);
               ExternalInterface.addCallback("bunniBenchPause",this.benchPause);
               ExternalInterface.addCallback("bunniBenchSaveInfo",Save.SaveInfo);
               ExternalInterface.addCallback("bunniBenchSave",this.benchSave);
               ExternalInterface.addCallback("bunniBenchState",this.benchState);
               ExternalInterface.addCallback("bunniBenchBackup",Save.ExportBackup);
               ExternalInterface.addCallback("bunniBenchMote",Motes.TriggerMote);
               ExternalInterface.addCallback("bunniBenchMovement",this.benchMovement);
               ExternalInterface.addCallback("bunniBenchImport",Save.ImportBackup);
            }
            mFocus = mAvatar;
            mHUD.x = 0;
            mHUD.y = 0;
            this.mStage.addChild(mHUD);
            this.mQuestHUD = new QuestHUD();
            this.mStage.addChild(this.mQuestHUD);
            this.mStage.addEventListener(MouseEvent.MOUSE_DOWN,this.mouseDown);
            this.mStage.addEventListener(MouseEvent.MOUSE_UP,this.mouseUp);
            this.mStage.addEventListener(MouseEvent.CLICK,this.mouseClick);
            this.mStage.addEventListener(MouseEvent.MOUSE_MOVE,this.updateMouse,false,0,true);
            addEventListener(Event.ENTER_FRAME,this.onEnterFrame);
            if(this.mBunniTitle.parent is Stage)
            {
               Stage(this.mBunniTitle.parent).stage.addEventListener(Event.MOUSE_LEAVE,this.leaveStage);
            }
            else if(this.mBunniTitle.parent.parent is Stage)
            {
               Stage(this.mBunniTitle.parent.parent).stage.addEventListener(Event.MOUSE_LEAVE,this.leaveStage);
            }
            this.mStage.addEventListener(MouseEvent.MOUSE_OVER,this.enterStage);
            mPointer = new Pointer();
            this.mStage.addChild(mPointer);
            mPointer.mouseChildren = false;
            mPointer.mouseEnabled = false;
            mPointer.visible = false;
            mAvatar = new AvatarItem(500,500);
            mFocus = mAvatar;
            World.WORLD_LOC_X = mFocus.x - World.SCREEN_WIDTH / 2;
            World.WORLD_LOC_Y = mFocus.y / 2 - World.SCREEN_HEIGHT / 2;
            this.mMetrics = Metrics.getInstance();
            Metrics.sendData("init");
            Save.DoLoad(this.RevealGame);
         }
      }

      private function RevealGame() : void
      {
         trace("REVEAL GAME",Sprite(this.mBunniTitle.mLoaderArt.parent),this.mBunniTitle.mLoaderArt);
         this.mBunniTitle.mLoaderArt.gotoAndPlay(2);
      }

      private function leaveStage(param1:Event) : void
      {
         this.mouseUp();
      }

      private function enterStage(param1:MouseEvent) : void
      {
         if(this.mMouseDown)
         {
            this.mouseDown();
         }
      }

      private function spawnMonster(param1:TimerEvent) : void
      {
         var _loc2_:Rectangle = null;
         var _loc3_:String = null;
         if(Switch.mFirstBridge)
         {
            if(Math.random() < 0.2)
            {
               if(Math.random() < 0.5)
               {
                  _loc3_ = "Monster";
               }
               else
               {
                  _loc3_ = "Deer";
               }
               StoreItemsList.MakeItemRandom(_loc3_,Land.mLandRectangles[2][0]);
            }
         }
         if(Switch.mPeteIsle)
         {
            if(Math.random() < 0.4)
            {
               if(Math.random() < 0.5)
               {
                  _loc3_ = "Monster";
               }
               else
               {
                  _loc3_ = "Deer";
               }
               StoreItemsList.MakeItemRandom(_loc3_,Land.mLandRectangles[3][0]);
            }
         }
         if(Switch.mWeddingIsle)
         {
            if(Math.random() < 0.6)
            {
               if(Math.random() < 0.5)
               {
                  _loc3_ = "Monster";
               }
               else
               {
                  _loc3_ = "Deer";
               }
               StoreItemsList.MakeItemRandom(_loc3_,Land.mLandRectangles[4][0]);
            }
         }
      }

      private function updateMouse(param1:MouseEvent) : void
      {
         mPointer.x = this.mStage.mouseX;
         mPointer.y = this.mStage.mouseY;
         param1.updateAfterEvent();
      }

      public function mouseDown(param1:MouseEvent = null) : void
      {
         var _loc2_:GenericItem = null;
         if(!mPause)
         {
            if(!(mFocus is GenericItem) || mFocus is CorianderItem)
            {
               return;
            }
            if(!mHUD.HitTest(Land.mStage.mouseX,Land.mStage.mouseY))
            {
               if(Bunni.mViewGame || mMapDraw)
               {
                  this.mMouseDown = true;
                  this.mMouseStillDownCounter = 0;
                  return;
               }
               if(!HighScoreItem.mMenuOpen && !MonsterItem.mMenuOpen && !PriestItem.mMenuOpen && !PiratePete.mMenuOpen && !this.mDragingBunny && !this.mDragingItem && !mMenuOpen && !TowerItem.mMenuOpen && !AngelItem.mMenuOpen && !QuestItem.mMenuOpen)
               {
                  _loc2_ = TestCollision.MousePointOnItem(this.mStage.mouseX,this.mStage.mouseY);
                  if(_loc2_ is PlacementItem)
                  {
                     Tasks.HintTextMouse("You picked up a <b>" + _loc2_.mName + "</b>");
                     this.mDragingItem = PlacementItem(_loc2_);
                     this.mDragingItem.StartDrag();
                     this.mLastItem = null;
                  }
                  else if(_loc2_ is GenericAnimal && GenericAnimal(_loc2_).mActive && GenericAnimal(_loc2_).mCanDrag)
                  {
                     if(_loc2_ is MonsterItem && !MonsterItem(_loc2_).mTame)
                     {
                        MonsterItem(_loc2_).TameMonster();
                     }
                     else
                     {
                        Tasks.HintTextMouse("You picked up a <b>" + _loc2_.mName + "</b>");
                        this.mDragingBunny = GenericAnimal(_loc2_);
                        this.mDragingBunny.StartDrag();
                        this.mLastItem = null;
                     }
                  }
                  else if(_loc2_ is TutorialItem)
                  {
                     TutorialItem(_loc2_).Click();
                  }
                  else if(_loc2_ is FruitTree)
                  {
                     Tasks.HintTextMouse("You shook a <b>" + _loc2_.mName + "</b>");
                     FruitTree(_loc2_).Click();
                  }
                  else if(_loc2_ is PriestItem)
                  {
                     PriestItem(_loc2_).Click();
                     mFocus = _loc2_;
                  }
                  else if(_loc2_ is HighScoreItem)
                  {
                     HighScoreItem(_loc2_).Click();
                     mFocus = _loc2_;
                  }
                  else if(_loc2_ is StoreItem)
                  {
                     if(StoreItem(_loc2_).mFree)
                     {
                        Tasks.HintTextMouse("You picked up a <b>" + _loc2_.mName + "</b>");
                        StoreItem(_loc2_).pickUp();
                     }
                     else
                     {
                        StoreItem(_loc2_).Click();
                        mFocus = _loc2_;
                     }
                  }
                  else if(_loc2_ is MoteItem)
                  {
                     MoteItem(_loc2_).Click();
                  }
                  else if(_loc2_ is TowerItem)
                  {
                     TowerItem(_loc2_).Click();
                  }
                  else if(_loc2_ is AngelItem)
                  {
                     AngelItem(_loc2_).Click();
                     mFocus = _loc2_;
                  }
                  else if(_loc2_ is QuestItem)
                  {
                     QuestItem(_loc2_).Click();
                  }
                  else if(_loc2_ is PiratePete)
                  {
                     PiratePete(_loc2_).Click();
                     mFocus = _loc2_;
                  }
                  else
                  {
                     this.mMouseDown = true;
                     this.mMouseStillDownCounter = 0;
                  }
               }
            }
         }
      }

      public function mouseUp(param1:MouseEvent = null) : void
      {
         var _loc2_:SoundManager = null;
         if(!mPause)
         {
            if(!(mFocus is GenericItem) || mFocus is CorianderItem)
            {
               return;
            }
            if(Bunni.mViewGame || mMapDraw)
            {
               mAvatar.Stop();
               this.mMouseDown = false;
               return;
            }
            mAvatar.Stop();
            this.mMouseDown = false;
            if(!HighScoreItem.mMenuOpen && !MonsterItem.mMenuOpen && !PriestItem.mMenuOpen && !PiratePete.mMenuOpen && !mMenuOpen && !TowerItem.mMenuOpen && !AngelItem.mMenuOpen && !QuestItem.mMenuOpen)
            {
               _loc2_ = SoundManager.getInstance();
               if(this.mDragingItem)
               {
                  if(mAvatar.mHighlight)
                  {
                     Tasks.HintTextMouse("You dropped a <b>" + this.mDragingItem.mName + "</b> item back into your inventory",4);
                     mAvatar.mHighlight = false;
                     this.mDragingItem.FollowAvatar();
                     _loc2_.playSound("ErrorPlace",2);
                     mFocus = mAvatar;
                  }
                  else if(Boolean(mPete) && mPete.mHighlight)
                  {
                     mPete.mHighlight = false;
                     mPete.SellItem(this.mDragingItem);
                  }
                  else
                  {
                     Tasks.HintTextMouse("You created a <b>" + this.mDragingItem.mName + "</b>!",4);
                     _loc2_.playSound("PutDown",0.8);
                     this.mDragingItem.CreateItem();
                     mFocus = mAvatar;
                  }
                  this.mDragingItem = null;
               }
               if(this.mDragingBunny)
               {
                  if(this.mClosestItem is BuildingItem)
                  {
                     Tasks.HintTextMouse("You set a <b>" + this.mDragingBunny.mName + "</b> to work on a <b>" + this.mClosestItem.mName + "</b>",4);
                     this.mDragingBunny.SetBuilding(BuildingItem(this.mClosestItem));
                     mFocus = mAvatar;
                  }
                  else if(this.mClosestItem == mPete)
                  {
                     mPete.SellAnimal(this.mDragingBunny);
                  }
                  else
                  {
                     Tasks.HintTextMouse("You dropped a <b>" + this.mDragingBunny.mName + "</b> item back into your inventory",4);
                     this.mDragingBunny.FollowAvatar(AvatarItem(this.mClosestItem));
                     mFocus = mAvatar;
                  }
                  if(this.mClosestItem)
                  {
                     this.mClosestItem.mHighlight = false;
                  }
                  this.mDragingBunny.StopDrag(new Vector2D(this.mStage.mouseX - this.mLastX,this.mStage.mouseY - this.mLastY));
                  this.mDragingBunny = null;
               }
            }
         }
      }

      private function mouseClick(param1:MouseEvent) : void
      {
      }

      private function onEnterFrame(param1:Event) : void
      {
         var _loc2_:int = 0;
         var _loc3_:GenericItem = null;
         var _loc4_:Vector2D = null;
         var _loc5_:Vector2D = null;
         // Keep benchmark timing windows separate from intentional game pauses.
         if(mBench && mPause)
         {
            if(mBenchLastFrame != 0) trace("bunni-fast-paused");
            mBenchStart = 0;
            mBenchFrames = 0;
            mBenchLastFrame = 0;
            mBenchDeltas = "";
         }
         if(!mPause)
         {
            if(mBench) trace("bunni-fast-phase begin");
            if(this.mMouseDown)
            {
               ++this.mMouseStillDownCounter;
               mAvatar.Move();
            }
            if(!(Bunni.mViewGame || mMapDraw))
            {
               _loc2_ = 0;
               while(_loc2_ < HUD.mSpeed)
               {
                  if(!HighScoreItem.mMenuOpen && !MonsterItem.mMenuOpen && !PriestItem.mMenuOpen && !PiratePete.mMenuOpen && !mMenuOpen && !TowerItem.mMenuOpen && !AngelItem.mMenuOpen && !QuestItem.mMenuOpen)
                  {
                     if(_loc2_ == 0)
                     {
                        mAvatar.update();
                        if(mBench) trace("bunni-fast-phase avatar");
                     }
                     _loc3_ = TestCollision.MousePointOnItem(this.mStage.mouseX,this.mStage.mouseY);
                     if(mBench) trace("bunni-fast-phase hit");
                     if(Boolean(_loc3_) && !(_loc3_ is BuildingItem))
                     {
                        mPointer.visible = true;
                        Mouse.hide();
                     }
                     else
                     {
                        mPointer.visible = false;
                        Mouse.show();
                     }
                     if(_loc3_ is GenericAnimal && !GenericAnimal(_loc3_).inAir())
                     {
                        Tasks.HintTextMouse("Click and hold to pick up <b>" + _loc3_.mName + "</b>");
                     }
                     else if(_loc3_ is MoteItem)
                     {
                        Tasks.HintTextMouse("Click to pick up Mote");
                     }
                     else if(_loc3_ is PlacementItem && PlacementItem(_loc3_).isFollowing())
                     {
                        Tasks.HintTextMouse("Click and hold to place <b>" + _loc3_.mName + "</b>");
                     }
                     else if(_loc3_ is StoreItem)
                     {
                        Tasks.HintTextMouse("Click to pick up <b>" + _loc3_.mName + "</b>");
                        StoreItem(_loc3_).Highlight();
                     }
                     else if(_loc3_ is TowerItem)
                     {
                        Tasks.HintTextMouse("Click to look at the <b>" + _loc3_.mName + "</b>");
                        TowerItem(_loc3_).mHighlight = true;
                     }
                     if(!_loc3_ || _loc3_ != this.mLastItemOver)
                     {
                        if(this.mLastItemOver is StoreItem)
                        {
                           StoreItem(this.mLastItemOver).Unhighlight();
                        }
                        else if(this.mLastItemOver is TowerItem)
                        {
                           TowerItem(this.mLastItemOver).mHighlight = false;
                        }
                     }
                     this.mLastItemOver = _loc3_;
                     if(this.mDragingItem)
                     {
                        this.mLastX = this.mStage.mouseX;
                        this.mLastY = this.mStage.mouseY;
                        _loc4_ = new Vector2D(mAvatar.x - this.mDragingItem.x,mAvatar.y - this.mDragingItem.y);
                        if(mPete)
                        {
                           _loc5_ = new Vector2D(mPete.x - this.mDragingItem.x,mPete.y - this.mDragingItem.y);
                        }
                        if(_loc4_.Length() < 100)
                        {
                           this.mDragingItem.ShowSmall();
                           if(mPete)
                           {
                              mPete.mHighlight = false;
                           }
                           mAvatar.mHighlight = true;
                           Tasks.HintTextMouse("Return <b>" + this.mDragingItem.mName + "</b> back to your inventory");
                        }
                        else if(Boolean(mPete) && _loc5_.Length() < 100)
                        {
                           Tasks.HintTextMouse("Sell <b>" + this.mDragingItem.mName + "</b> to Pirate Pete");
                           this.mDragingItem.ShowSmall();
                           mAvatar.mHighlight = false;
                           mPete.mHighlight = true;
                        }
                        else
                        {
                           this.mDragingItem.ShowLarge();
                           if(this.mDragingItem.CanPlace())
                           {
                              Tasks.HintTextMouse("You can place your <b>" + this.mDragingItem.mName + "</b> here");
                              mAvatar.mHighlight = false;
                              if(mPete)
                              {
                                 mPete.mHighlight = false;
                              }
                           }
                           else if(!mPete || Boolean(mPete) && Boolean(!mPete.mHighlight))
                           {
                              Tasks.HintTextMouse("Placement is blocked");
                              mAvatar.mHighlight = true;
                           }
                        }
                        this.mDragingItem.Move();
                        mAvatar.MoveCenter();
                     }
                     if(this.mDragingBunny)
                     {
                        this.mLastX = this.mStage.mouseX;
                        this.mLastY = this.mStage.mouseY;
                        this.mClosestItem = TestCollision.ClosestAvaliableItem(this.mStage.mouseX,this.mStage.mouseY);
                        if(mPete)
                        {
                           _loc5_ = new Vector2D(mPete.x - this.mDragingBunny.x,mPete.y - this.mDragingBunny.y);
                           if(_loc5_.Length() < 100)
                           {
                              this.mClosestItem = mPete;
                           }
                        }
                        this.mDragingBunny.Move();
                        mAvatar.MoveCenter();
                        if(this.mClosestItem.mName)
                        {
                           Tasks.HintTextMouse("Place your <b>" + this.mDragingBunny.mName + "</b> on <b>" + this.mClosestItem.mName + "</b>");
                        }
                        else
                        {
                           Tasks.HintTextMouse("Return <b>" + this.mDragingBunny.mName + "</b> to your inventory");
                        }
                        if(this.mClosestItem != this.mLastItem)
                        {
                           this.mClosestItem.mHighlight = true;
                           if(this.mLastItem)
                           {
                              this.mLastItem.mHighlight = false;
                           }
                        }
                        this.mLastItem = this.mClosestItem;
                     }
                  }
                  else
                  {
                     mPointer.visible = false;
                     Mouse.show();
                  }
                  this.ScrollScreen();
                  if(mBench) trace("bunni-fast-phase scroll");
                  Items.updateOnly();
                  if(mBench) trace("bunni-fast-phase update-items");
                  _loc2_++;
               }
            }
            else
            {
               mAvatar.update();
               this.ScrollScreen();
               Items.updateOnly();
            }
            if(mBench) trace("bunni-fast-phase updated");
            if(mMapDraw)
            {
               Land.mapDraw();
            }
            else
            {
               Land.draw();
            }
            if(mBench) trace("bunni-fast-phase land");
            if(this.mDragingBunny)
            {
               mFocus = this.mDragingBunny;
            }
            else if(this.mDragingItem)
            {
               if(mFocus != this.mDragingItem)
               {
                  mFocus = this.mDragingItem;
               }
               this.DrawOverlay();
               this.UpdateOverlay();
            }
            else
            {
               this.mOverlay.graphics.clear();
            }
            if(mMapDraw)
            {
               Items.mapDrawOnly();
            }
            else
            {
               Items.drawOnly();
            }
            if(mBench) trace("bunni-fast-phase items");
            if(!mMapDraw)
            {
               this.mQuestHUD.onUpdate();
               Land.queueObject(Land.mTextOut);
            }
            Land.flush();
            if(mBench) trace("bunni-fast-phase screen");
            if(!this.mDragingBunny && !this.mDragingItem && !mMenuOpen && !mMapDraw)
               Save.AutoSaveTick();
            if(mBench)
            {
               trace("bunni-fast-phase saved");
               trace("bunni-fast-frame");
               var frameTime:int = getTimer();
               if(mBenchLastFrame != 0) mBenchDeltas += (frameTime - mBenchLastFrame) + ",";
               mBenchLastFrame = frameTime;
               ++mBenchFrames;
               if(mBenchStart == 0)
               {
                  mBenchStart = getTimer();
                  mBenchFrames = 0;
               }
               else if(getTimer() - mBenchStart >= 1000)
               {
                  trace("bunni-fast-frames",mBenchFrames,getTimer() - mBenchStart,this.mBunniTitle.stage.quality);
                  trace("bunni-fast-frame-times",mBenchDeltas);
                  mBenchDeltas = "";
                  mBenchFrames = 0;
                  mBenchStart = getTimer();
               }
            }
         }
      }


      private function benchMovement(count:int = 300) : String
      {
         var seed:uint = 305419896;
         var randomInt:Function = function(limit:int):int { seed = uint(seed * 1664525 + 1013904223); return int(seed % limit); };
         var mismatches:Array = [];
         var pointMismatches:int = 0;
         var started:int = getTimer();
         count = Math.min(1000,Math.max(1,count));
         for(var i:int = 0; i < count; ++i)
         {
            var px:int = randomInt(5000) - 200;
            var py:int = randomInt(5200) - 200;
            if(i % 2 == 0 && Land.mLandArray.length)
            {
               var circle:Circle = Land.mLandArray[randomInt(Land.mLandArray.length)].circle;
               px = int(circle.x + (randomInt(3) - 1) * circle.r);
               py = int(circle.y + randomInt(3) - 1);
            }
            if(TestCollision.PointOnLand(px,py) != Land.pointOnLandFast(px,py)) ++pointMismatches;
            var dx:int = i % 5 == 0 ? px : px + randomInt(301) - 150;
            var dy:int = i % 5 == 0 ? py : py + randomInt(301) - 150;
            var speed:int = i % 7 == 0 ? 50 : 20;
            var original:Vector2D = TestCollision.NextStep(dx,dy,px,py,speed);
            var optimized:Vector2D = Land.nextAvatarStep(dx,dy,px,py,speed);
            if(original.x != optimized.x || original.y != optimized.y)
               mismatches.push({px:px,py:py,dx:dx,dy:dy,speed:speed,original:[original.x,original.y],optimized:[optimized.x,optimized.y]});
         }
         return JSON.stringify({cases:count,pointMismatches:pointMismatches,mismatches:mismatches,ms:getTimer()-started,landBlobs:Land.mLandArray.length});
      }

      private function benchState() : String
      {
         var items:Array = [];
         for each(var item:GenericItem in Items.GetSaveItems())
         {
            if(item == mAvatar || item.mPersist || item is MoteItem)
               items.push({name:item.mName,type:getQualifiedClassName(item),id:item.mID,x:item.x,y:item.y,
                  sx:item.drawx,sy:item.drawy,rect:item.itemRect ? [item.itemRect.x,item.itemRect.y,item.itemRect.width,item.itemRect.height] : null});
         }
         return JSON.stringify({paused:mPause,map:mMapDraw,dragging:Boolean(this.mDragingItem) || Boolean(this.mDragingBunny),canPlace:this.mDragingItem ? this.mDragingItem.CanPlace() : null,
            camera:[WORLD_LOC_X,WORLD_LOC_Y],wood:HUD.GetWood(),gold:HUD.GetGold(),gems:HUD.GetGems(),savedAt:Save.mSavedAt,error:Save.mLastError,items:items});
      }

      private function benchSave() : String
      {
         Save.SaveNow(null);
         return Save.SaveInfo();
      }

      // Optional benchmark control: compare render quality in the exact same world.
      private function benchPause(param1:Boolean) : void
      {
         mPause = param1;
         mBenchStart = 0;
         mBenchFrames = 0;
      }

      private function benchQuality(param1:String) : String
      {
         if(param1 == StageQuality.LOW || param1 == StageQuality.MEDIUM || param1 == StageQuality.HIGH || param1 == StageQuality.BEST)
         {
            this.mBunniTitle.stage.quality = param1;
         }
         return this.mBunniTitle.stage.quality;
      }

      private function DrawOverlay() : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:Circle = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:Rectangle = null;
         var _loc1_:Rectangle = new Rectangle(0,0,World.SCREEN_WIDTH,World.SCREEN_HEIGHT);
         this.mOverlay.graphics.clear();
         this.mOverlay.graphics.beginFill(8750469,1);
         this.mOverlay.graphics.drawRect(0,0,World.SCREEN_WIDTH,World.SCREEN_HEIGHT);
         this.mOverlay.graphics.endFill();
         _loc2_ = 0;
         while(_loc2_ < Land.mLandArray.length)
         {
            _loc4_ = Land.mLandArray[_loc2_].circle;
            _loc5_ = _loc4_.x - World.WORLD_LOC_X - _loc4_.r;
            _loc6_ = _loc4_.y / 2 - World.WORLD_LOC_Y - _loc4_.r / 2;
            _loc7_ = new Rectangle(_loc5_,_loc6_,_loc4_.r * 2,_loc4_.r);
            if(_loc1_.intersects(_loc7_))
            {
               this.mOverlay.graphics.beginFill(16777215,1);
               this.mOverlay.graphics.drawEllipse(_loc5_,_loc6_,_loc4_.r * 2,_loc4_.r);
               this.mOverlay.graphics.endFill();
            }
            _loc2_++;
         }
         this.mOverlay.graphics.lineStyle(1,8750469,1);
         _loc3_ = 0;
         while(_loc3_ < Items.mMapItems.length)
         {
            if(!(Items.mMapItems[_loc3_] is MoteItem || Items.mMapItems[_loc3_] is GenericAnimal || Items.mMapItems[_loc3_] is GirlBunny || Items.mMapItems[_loc3_] is AvatarItem || Items.mMapItems[_loc3_] is GirlFriendBunny))
            {
               _loc4_ = Items.mMapItems[_loc3_].mInnerCircle;
               _loc5_ = _loc4_.x - World.WORLD_LOC_X - _loc4_.r;
               _loc6_ = _loc4_.y / 2 - World.WORLD_LOC_Y - _loc4_.r / 2;
               _loc7_ = new Rectangle(_loc5_,_loc6_,_loc4_.r * 2,_loc4_.r);
               if(_loc1_.intersects(_loc7_))
               {
                  this.mOverlay.graphics.beginFill(8750469,1);
                  this.mOverlay.graphics.drawEllipse(_loc5_,_loc6_,_loc4_.r * 2,_loc4_.r);
                  this.mOverlay.graphics.endFill();
               }
            }
            _loc3_++;
         }
      }

      private function UpdateOverlay() : void
      {
         // bunni-fast: keep the same placement geometry, 8x8 blur and multiply blend,
         // rendered on stage. The old draw/applyFilter pair read a GPU bitmap back to
         // the CPU on every drag frame and could stall the browser during tree pickup.
         this.mOverlay.filters = [this.bf];
         this.mOverlay.blendMode = BlendMode.MULTIPLY;
         Land.queueObject(this.mOverlay);
      }

      public function ScrollScreen() : void
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         var _loc7_:Vector2D = null;
         var _loc8_:Number = NaN;
         var _loc3_:int = World.SCREEN_WIDTH;
         var _loc4_:int = World.SCREEN_HEIGHT;
         _loc2_ = _loc3_ / 2;
         _loc1_ = _loc4_ / 2;
         var _loc5_:Number = mFocus.x - World.SCREEN_WIDTH / 2 - World.WORLD_LOC_X;
         var _loc6_:Number = mFocus.y / 2 - World.SCREEN_HEIGHT / 2 - World.WORLD_LOC_Y;
         if(Boolean(this.mDragingItem) || Boolean(this.mDragingBunny))
         {
            _loc7_ = new Vector2D(_loc5_,_loc6_);
            _loc8_ = _loc7_.Length();
            if(_loc8_ > 200)
            {
               _loc8_ -= 200;
               _loc7_.Normalize();
               _loc7_.MultiplyByNumber(_loc8_);
               _loc5_ = _loc7_.x;
               _loc6_ = _loc7_.y;
            }
            else
            {
               _loc5_ = 0;
               _loc6_ = 0;
            }
         }
         if(_loc5_ != 0 || _loc6_ != 0)
         {
            if(!(mFocus is GenericItem))
            {
               World.WORLD_LOC_X += _loc5_ / 20;
               World.WORLD_LOC_Y += _loc6_ / 20;
            }
            else
            {
               World.WORLD_LOC_X += _loc5_ / 5;
               World.WORLD_LOC_Y += _loc6_ / 5;
            }
         }
         if(World.WORLD_LOC_X < 0)
         {
            Land.mScreenBitmapData.fillRect(new Rectangle(0,0,World.WORLD_WIDTH,World.SCREEN_HEIGHT),4283531204);
         }
         else if(World.WORLD_LOC_X > World.WORLD_WIDTH - World.SCREEN_WIDTH)
         {
            Land.mScreenBitmapData.fillRect(new Rectangle(0,0,World.WORLD_WIDTH,World.SCREEN_HEIGHT),4283531204);
         }
         else if(World.WORLD_LOC_Y < 0)
         {
            Land.mScreenBitmapData.fillRect(new Rectangle(0,0,World.WORLD_WIDTH,World.SCREEN_HEIGHT),4283531204);
         }
         else if(World.WORLD_LOC_Y > World.WORLD_HEIGHT / 2 - World.SCREEN_HEIGHT)
         {
            Land.mScreenBitmapData.fillRect(new Rectangle(0,0,World.WORLD_WIDTH,World.SCREEN_HEIGHT),4283531204);
         }
      }
   }
}
