package Tutorial
{
   import Bridge.Bridges;
   import Geom.DataTimer;
   import Land.Land;
   import MapItems.Animals.GenericAnimal;
   import MapItems.Avatar.AvatarItem;
   import MapItems.Building.MillItem;
   import MapItems.Building.MineItem;
   import MapItems.Items;
   import MapItems.GenericItem;
   import MapItems.StoreItems.StoreItem;
   import MapItems.StoreItems.StoreItemsList;
   import MapItems.Terrain.ForestItems.PineItem;
   import MapItems.Tower.TowerItem;
   import Menu.QuestHUD;
   import Rewards.Motes;
   import Save.Save;
   import Survey.SurveyDialog;
   import ViralLogin.ViralLogin;
   import World.World;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   import gs.TweenLite;

   public class Tasks
   {

      private static var mTutorialClip:MovieClip;

      private static var mLastHint:String;

      private static var mHintText:MovieClip;

      public static var mLogin:Sprite;

      private static var mReg:Boolean;

      public static var mSurveyTime:int;

      private static var mClickDone:Function;

      private static var kMoved:Boolean = false;

      private static var kPickUpHouse:Boolean = false;

      private static var kPlaceHouse:Boolean = false;

      private static var kBuyBunni:Boolean = false;

      private static var kPickUpPine:Boolean = false;

      private static var kPlacePine:Boolean = false;

      private static var kPickUpMill:Boolean = false;

      private static var kPlaceMill:Boolean = false;

      private static var kWorkMill:Boolean = false;

      private static var kBunniHungry:Boolean = false;

      private static var kPickUpFlowers:Boolean = false;

      private static var kPlaceFlowers:Boolean = false;

      private static var kPickUpTower:Boolean = false;

      private static var kPlaceTower:Boolean = false;

      private static var kFirstMote:Boolean = false;

      private static var kSecondIsland:Boolean = false;

      private static var kClickTower:Boolean = false;

      private static var kPickUpStore:Boolean = false;

      private static var kPlaceStore:Boolean = false;

      private static var kPickUpMine:Boolean = false;

      private static var kPlaceMine:Boolean = false;

      private static var kWorkMine:Boolean = false;

      private static var kTutorialDone:Boolean = false;

      private static var mLastHintTime:int = getTimer();

      private static var mGameStarted:Boolean = false;

      private static var mMoveCounter:int = 0;

      private static var mMessageSupression:Array = new Array();

      private static var mRestoredState:XML;

      public static function SaveState() : XML
      {
         var state:XML = <tutorial/>;
         state.@kMoved = kMoved;
         state.@kPickUpHouse = kPickUpHouse;
         state.@kPlaceHouse = kPlaceHouse;
         state.@kBuyBunni = kBuyBunni;
         state.@kPickUpPine = kPickUpPine;
         state.@kPlacePine = kPlacePine;
         state.@kPickUpMill = kPickUpMill;
         state.@kPlaceMill = kPlaceMill;
         state.@kWorkMill = kWorkMill;
         state.@kBunniHungry = kBunniHungry;
         state.@kPickUpFlowers = kPickUpFlowers;
         state.@kPlaceFlowers = kPlaceFlowers;
         state.@kPickUpTower = kPickUpTower;
         state.@kPlaceTower = kPlaceTower;
         state.@kFirstMote = kFirstMote;
         state.@kSecondIsland = kSecondIsland;
         state.@kClickTower = kClickTower;
         state.@kPickUpStore = kPickUpStore;
         state.@kPlaceStore = kPlaceStore;
         state.@kPickUpMine = kPickUpMine;
         state.@kPlaceMine = kPlaceMine;
         state.@kWorkMine = kWorkMine;
         state.@kTutorialDone = kTutorialDone;
         state.@mMoveCounter = mMoveCounter;
         state.hint = mTutorialClip ? mTutorialClip.mTaskText.htmlText : "";
         return state;
      }

      public static function RestoreState(state:XML) : void
      {
         if(state == null) return;
         kMoved = String(state.@kMoved) == "true";
         kPickUpHouse = String(state.@kPickUpHouse) == "true";
         kPlaceHouse = String(state.@kPlaceHouse) == "true";
         kBuyBunni = String(state.@kBuyBunni) == "true";
         kPickUpPine = String(state.@kPickUpPine) == "true";
         kPlacePine = String(state.@kPlacePine) == "true";
         kPickUpMill = String(state.@kPickUpMill) == "true";
         kPlaceMill = String(state.@kPlaceMill) == "true";
         kWorkMill = String(state.@kWorkMill) == "true";
         kBunniHungry = String(state.@kBunniHungry) == "true";
         kPickUpFlowers = String(state.@kPickUpFlowers) == "true";
         kPlaceFlowers = String(state.@kPlaceFlowers) == "true";
         kPickUpTower = String(state.@kPickUpTower) == "true";
         kPlaceTower = String(state.@kPlaceTower) == "true";
         kFirstMote = String(state.@kFirstMote) == "true";
         kSecondIsland = String(state.@kSecondIsland) == "true";
         kClickTower = String(state.@kClickTower) == "true";
         kPickUpStore = String(state.@kPickUpStore) == "true";
         kPlaceStore = String(state.@kPlaceStore) == "true";
         kPickUpMine = String(state.@kPickUpMine) == "true";
         kPlaceMine = String(state.@kPlaceMine) == "true";
         kWorkMine = String(state.@kWorkMine) == "true";
         kTutorialDone = String(state.@kTutorialDone) == "true";
         mMoveCounter = int(state.@mMoveCounter);
         mRestoredState = state;
      }

      public function Tasks()
      {
         super();
      }

      public static function Init() : void
      {
         mTutorialClip = new TutorialClip();
         mTutorialClip.y = World.SCREEN_HEIGHT;
         mTutorialClip.mouseChildren = false;
         mTutorialClip.mouseEnabled = false;
         Bunni.mRealStage.addChild(mTutorialClip);
         TaskLogin();
         mHintText = new HintText();
         mHintText.y = World.SCREEN_HEIGHT;
         mHintText.mouseChildren = false;
         mHintText.mouseEnabled = false;
         Bunni.mRealStage.addChild(mHintText);
      }

      public static function TaskLogin() : void
      {
         if(Bunni.mViewGame)
         {
            TaskTutorialDone();
            Bunni.staticWorld.IntroDone();
         }
         else
         {
            mTutorialClip.alpha = 1;
            mTutorialClip.mTaskText.htmlText = "I\'m Susanna the Ghost.<br> Have you been to Bunni island before?";
            mLogin = new ViralLogin(null,false);
            mLogin.x = World.SCREEN_WIDTH / 2 - mLogin.width / 2;
            mLogin.y = World.SCREEN_HEIGHT / 2 - mLogin.height / 2;
            Bunni.mRealStage.addChild(mLogin);
            Bunni.mRealStage.setChildIndex(mTutorialClip,Bunni.mRealStage.numChildren - 1);
         }
      }

      public static function TaskHide() : void
      {
         TweenLite.to(mTutorialClip.mTaskText,3,{"alpha":0});
         TweenLite.to(mTutorialClip.mBubble,3,{"alpha":0});
         TweenLite.to(mTutorialClip.mGhost,3,{"alpha":0});
      }

      public static function NewUser() : void
      {
         TutShow();
         mTutorialClip.alpha = 1;
         mTutorialClip.mTaskText.htmlText = "Your game is now loading...";
      }

      public static function onCloseSignIn() : void
      {
         Bunni.mRealStage.removeChild(mLogin);
         mLogin = null;
         Bunni.staticWorld.IntroDone();
      }

      public static function SuccsesfulReturn() : void
      {
         mReg = false;
      }

      public static function SuccsesfulRegiseter() : void
      {
         mReg = true;
      }

      public static function GameStarted() : void
      {
         var _loc1_:Timer = null;
         var _loc2_:Array = null;
         var _loc3_:Timer = null;
         mGameStarted = true;
         TutShow();
         if(mRestoredState != null)
         {
            mTutorialClip.mTaskText.htmlText = String(mRestoredState.hint);
            World.mHUD.EnableSaveButton();
            Save.EnableAutoSave();
            mRestoredState = null;
            // Restore guidance without re-running task methods that spawn items.
            var focusName:String = "";
            if(!kTutorialDone && kMoved)
            {
               if(!kPickUpPine) focusName = "Medium Pine Forest";
               else if(kPlacePine && !kPickUpMill) focusName = "Sawmill";
               else if(kPlaceMill && !kPickUpHouse) focusName = "Bunni House";
               else if(kBunniHungry && !kPickUpFlowers) focusName = "Medium Posie Garden";
               for each(var candidate:GenericItem in Items.GetItemArrayByName(focusName))
                  if(candidate is StoreItem) { QuestHUD.mFocusItem = candidate; break; }
            }
            Motes.TriggerMote("welcome_back");
            return;
         }
         if(mReg)
         {
            Tasks.HintTextEvent(50,"Hi!  Welcome to my desolate island.  Unless you start building a home, you will soon be dead, just like me.");
            _loc1_ = new Timer(15000,1);
            _loc1_.addEventListener(TimerEvent.TIMER_COMPLETE,hintToMove);
            _loc1_.start();
            _loc2_ = [5,10,15,20,25,30,35,40,45];
            mSurveyTime = _loc2_[Math.floor(Math.random() * _loc2_.length)];
            trace("mSurveyTime",mSurveyTime);
            _loc3_ = new Timer(mSurveyTime * 60000,1);
            _loc3_.addEventListener(TimerEvent.TIMER_COMPLETE,takeSurvey);
            _loc3_.start();
         }
         else
         {
            Tasks.HintTextEvent(51,"Welcome back " + Bunni.uName + "... I have restored your island.");
            TaskTutorialDone();
            Save.EnableAutoSave();
            Motes.TriggerMote("welcome_back");
         }
      }

      private static function takeSurvey(param1:TimerEvent) : void
      {
         World.PauseGame();
         var _loc2_:SurveyDialog = new SurveyDialog();
         _loc2_.x = 640 / 2 - _loc2_.width / 2;
         _loc2_.y = 480 / 2 - _loc2_.height / 2;
         Bunni.mRealStage.addChild(_loc2_);
      }

      private static function hintToMove(param1:TimerEvent) : void
      {
         if(!AvatarItem.mHasMoved)
         {
            Tasks.HintTextEvent(10,"Click and hold to move");
         }
      }

      private static function TaskPickUpPine() : void
      {
         var _loc1_:StoreItem = StoreItem(StoreItemsList.MakeStoreRandom("Medium Pine Forest",Land.mLandRectangles[0][0]));
         QuestHUD.mFocusItem = _loc1_;
         var _loc2_:DataTimer = new DataTimer(5000,1);
         _loc2_.data.item = _loc1_;
         _loc2_.addEventListener(TimerEvent.TIMER_COMPLETE,hintToPickUpPine);
         _loc2_.start();
      }

      private static function hintToPickUpPine(param1:TimerEvent) : void
      {
         var _loc2_:DataTimer = param1.currentTarget as DataTimer;
         if(!StoreItem(_loc2_.data.item).mPickedUp)
         {
            Tasks.HintTextEvent(11,"If you click on the tree bubble, you\'ll pick them up.");
         }
      }

      private static function TaskPlacePine() : void
      {
         var _loc1_:DataTimer = new DataTimer(5000,1);
         _loc1_.addEventListener(TimerEvent.TIMER_COMPLETE,hintToPlacePine);
         _loc1_.start();
      }

      private static function hintToPlacePine(param1:TimerEvent) : void
      {
         if(!Items.ExistsClass(PineItem))
         {
            Tasks.HintTextEvent(12,"Planting time! Click and drag the tree to plant it.");
         }
      }

      private static function TaskPickUpMill() : void
      {
         var _loc1_:StoreItem = StoreItem(StoreItemsList.MakeStoreRandom("Sawmill",Land.mLandRectangles[0][0]));
         QuestHUD.mFocusItem = _loc1_;
         Tasks.HintTextEvent(52,"Still alive? Something horrible happened on these islands.  You\'ll see lots of ghosts like me if you make it very far.");
         var _loc2_:DataTimer = new DataTimer(10000,1);
         _loc2_.data.item = _loc1_;
         _loc2_.addEventListener(TimerEvent.TIMER_COMPLETE,hintToPickUpMill);
         _loc2_.start();
      }

      private static function hintToPickUpMill(param1:TimerEvent) : void
      {
         var _loc2_:DataTimer = param1.currentTarget as DataTimer;
         if(!StoreItem(_loc2_.data.item).mPickedUp)
         {
            Tasks.HintTextEvent(13,"Trees aren\'t good unless you harvest them and for that you\'ll need a sawmill");
         }
      }

      private static function TaskPlaceMill() : void
      {
         var _loc1_:DataTimer = new DataTimer(5000,1);
         _loc1_.addEventListener(TimerEvent.TIMER_COMPLETE,hintToPlaceMill);
         _loc1_.start();
      }

      private static function hintToPlaceMill(param1:TimerEvent) : void
      {
         if(!Items.ExistsClass(MineItem))
         {
            Tasks.HintTextEvent(14,"Pick up the sawmill and plant it near the trees.  Remember: Click and Drag!");
         }
      }

      private static function TaskPickUpHouse() : void
      {
         var _loc1_:StoreItem = StoreItem(StoreItemsList.MakeStoreRandom("Bunni House",Land.mLandRectangles[0][0]));
         QuestHUD.mFocusItem = _loc1_;
         var _loc2_:DataTimer = new DataTimer(10000,1);
         _loc2_.data.item = _loc1_;
         _loc2_.addEventListener(TimerEvent.TIMER_COMPLETE,hintToPickUpHouse);
         _loc2_.start();
      }

      private static function hintToPickUpHouse(param1:TimerEvent) : void
      {
         var _loc2_:DataTimer = param1.currentTarget as DataTimer;
         if(!StoreItem(_loc2_.data.item).mPickedUp)
         {
            Tasks.HintTextEvent(15,"Look a house!  I wonder if you can place that somewhere.");
         }
      }

      private static function TaskPlaceHouse() : void
      {
      }

      private static function TaskBuyBunni() : void
      {
         var _loc1_:Timer = new Timer(10000,1);
         _loc1_.addEventListener(TimerEvent.TIMER_COMPLETE,hintToBuyBunni);
         _loc1_.start();
      }

      private static function hintToBuyBunni(param1:TimerEvent) : void
      {
         var _loc2_:int = Items.CountMapItems("bunni");
         trace("bunniCount",_loc2_);
         if(_loc2_ == 0)
         {
            Tasks.HintTextEvent(16,"Click on the Bunni to hire workers for your sawmill.");
         }
      }

      private static function TaskBunniOnMill() : void
      {
         var _loc1_:Timer = new Timer(15000,1);
         _loc1_.addEventListener(TimerEvent.TIMER_COMPLETE,hintToPutBunniOnMill);
         _loc1_.start();
      }

      private static function hintToPutBunniOnMill(param1:TimerEvent) : void
      {
         var _loc3_:int = 0;
         var _loc5_:GenericAnimal = null;
         var _loc2_:Array = Items.GetItemArrayByName("Bunni");
         var _loc4_:Boolean = false;
         _loc3_ = 0;
         while(_loc3_ < _loc2_.length)
         {
            if(_loc2_[_loc3_] is GenericAnimal)
            {
               _loc5_ = _loc2_[_loc3_];
               if(_loc5_)
               {
                  if(_loc5_.mWorkPlace is MillItem)
                  {
                     _loc4_ = true;
                  }
               }
            }
            _loc3_++;
         }
         if(!_loc4_)
         {
            Tasks.HintTextEvent(17,"Click and drag the worker onto the mill.  A yellow circle will appear under the mill.");
         }
      }

      private static function TaskBunniStarve() : void
      {
         Tasks.HintTextEvent(53,"Before the end of everything, Grandpa Angel saved a few survivors in magical bubbles.  You may come across a few here and there.");
      }

      private static function TaskPickUpFlower() : void
      {
         QuestHUD.mFocusItem = StoreItemsList.MakeStoreRandom("Medium Posie Garden",Land.mLandRectangles[0][0]);
         Tasks.HintTextEvent(54,"Oh, look a hungry bunni. That is how most of us died.  There just wasn\'t any food left.  *sigh*");
      }

      private static function TaskPlaceFlowers() : void
      {
      }

      private static function TaskClickMote() : void
      {
         Motes.TriggerMote("first_mote");
         StoreItemsList.MakeItemRandom("Tower Of Love",Land.mLandRectangles[1][0]);
         Tasks.HintTextEvent(55,"What?  Is that a bit of love? All your building has begun to awaken the island spirits.  Uh oh.");
         var _loc1_:Timer = new Timer(10000,1);
         _loc1_.addEventListener(TimerEvent.TIMER_COMPLETE,hintToClickMote);
         _loc1_.start();
      }

      private static function hintToClickMote(param1:TimerEvent) : void
      {
         if(!Motes.TestMote("first_mote"))
         {
            Tasks.HintTextEvent(19,"Ohh...the heart shaped object following you is a Mote.  Click the Mote to collect it.");
         }
      }

      private static function TaskFindTower() : void
      {
         Bridges.DrawBridge("first_bridge");
         StoreItemsList.MakeStoreRandom("Ginger Cove",Land.mLandRectangles[1][0],false);
         QuestHUD.mFocusItem = StoreItemsList.MakeStoreRandom("Coriander",Land.mLandRectangles[1][0]);
         Tasks.HintTextEvent(20,"How exciting! A new island is open. Let\'s go exploring.  Click and hold to move your bunni to the next island.");
      }

      private static function TaskSecondIsland() : void
      {
         Tasks.HintTextEvent(56,"*Gulp* I\'ve heard of this place.  It is the secret heart of the Bunni Islands.");
         var _loc1_:Timer = new Timer(10000,1);
         _loc1_.addEventListener(TimerEvent.TIMER_COMPLETE,hintToOpenTower);
         _loc1_.start();
      }

      private static function hintToOpenTower(param1:TimerEvent) : void
      {
         var _loc2_:TowerItem = null;
         if(!TowerItem.mHasOpened)
         {
            Tasks.HintTextEvent(21,"Try to find a strange tower.  Can you open it?");
         }
      }

      private static function TaskPickUpStore() : void
      {
         Tasks.HintTextEvent(57,"If you get stuck, visit the tower!  Bring love back to the island! You can now save your game if you wish.");
         TaskTutorialDone();
      }

      private static function TaskTutorialDone() : void
      {
         World.mHUD.EnableSaveButton();
         kTutorialDone = true;
      }

      private static function TutHide() : void
      {
         TweenLite.to(mTutorialClip,1,{"alpha":0});
      }

      private static function TutShow() : void
      {
         TweenLite.to(mTutorialClip,1,{"alpha":1});
      }

      private static function removeClip() : void
      {
         Bunni.mRealStage.removeChild(mTutorialClip);
         mTutorialClip = null;
      }

      public static function MoveAvatar() : void
      {
         if(!kTutorialDone)
         {
            if(!kMoved)
            {
               ++mMoveCounter;
               if(mMoveCounter > 1)
               {
                  kMoved = true;
                  TaskPickUpPine();
               }
            }
            if(!kSecondIsland && World.mAvatar.y > 1500)
            {
               kSecondIsland = true;
               TaskSecondIsland();
            }
         }
         else if(!kMoved)
         {
            kMoved = true;
            TaskTutorialDone();
         }
      }

      public static function BunniStarve() : void
      {
         if(!kTutorialDone)
         {
            if(!kBunniHungry)
            {
               kBunniHungry = true;
               TaskPickUpFlower();
            }
         }
      }

      public static function ClickMote() : void
      {
         if(!kTutorialDone)
         {
            if(!kFirstMote)
            {
               kFirstMote = true;
               TaskFindTower();
            }
         }
      }

      public static function ClickTower() : void
      {
         if(!kTutorialDone)
         {
            if(!kClickTower)
            {
               kClickTower = true;
               TaskPickUpStore();
            }
         }
      }

      public static function BunniWork(param1:String) : void
      {
         if(!kTutorialDone)
         {
            if(!kWorkMill)
            {
               if(param1 == "Sawmill")
               {
                  kWorkMill = true;
                  TaskBunniStarve();
               }
            }
         }
      }

      public static function PickUp(param1:String) : void
      {
         if(!kTutorialDone)
         {
            if(!kPickUpPine)
            {
               if(param1 == "Pine Tree")
               {
                  kPickUpPine = true;
                  TaskPlacePine();
               }
            }
            else if(!kPickUpMill)
            {
               if(param1 == "Sawmill")
               {
                  kPickUpMill = true;
                  TaskPlaceMill();
               }
            }
            else if(!kPickUpHouse)
            {
               if(param1 == "Bunni House")
               {
                  kPickUpHouse = true;
                  TaskPlaceHouse();
               }
            }
            else if(!kBuyBunni)
            {
               if(param1 == "Bunni")
               {
                  kBuyBunni = true;
                  TaskBunniOnMill();
               }
            }
            else if(!kPickUpFlowers)
            {
               if(param1 == "Posies")
               {
                  kPickUpFlowers = true;
                  TaskPlaceFlowers();
               }
            }
            QuestHUD.mFocusItem = null;
         }
      }

      public static function Place(param1:String) : void
      {
         if(!kTutorialDone)
         {
            if(!kPlacePine)
            {
               if(param1 == "Medium Pine Forest")
               {
                  kPlacePine = true;
                  TaskPickUpMill();
               }
            }
            else if(!kPlaceMill)
            {
               if(param1 == "Sawmill")
               {
                  kPlaceMill = true;
                  TaskPickUpHouse();
               }
            }
            else if(!kPlaceHouse)
            {
               if(param1 == "Bunni House")
               {
                  kPlaceHouse = true;
                  TaskBuyBunni();
               }
            }
            else if(!kPlaceFlowers)
            {
               if(param1 == "Medium Posie Garden")
               {
                  kPlaceFlowers = true;
                  TaskClickMote();
               }
            }
         }
      }

      public static function HintTextMouse(param1:String, param2:int = 0) : void
      {
         mHintText.mHintMouse.alpha = 1;
         mHintText.mHintMouse.htmlText = param1;
         TweenLite.to(mHintText.mHintMouse,4,{
            "delay":param2,
            "alpha":0
         });
      }

      public static function HintTextEvent(param1:int, param2:String, param3:int = 0, param4:int = 0) : void
      {
         var _loc5_:DataTimer = null;
         var _loc6_:DataTimer = null;
         if(mMessageSupression.indexOf(param1) == -1)
         {
            mMessageSupression.push(param1);
            TweenLite.to(mTutorialClip.mGhost,1,{"alpha":1});
            TweenLite.to(mTutorialClip.mTaskText,1,{"alpha":1});
            TweenLite.to(mTutorialClip.mBubble,1,{"alpha":1});
            mTutorialClip.mTaskText.htmlText = param2;
            _loc5_ = new DataTimer(20000,1);
            _loc5_.data.id = param1;
            _loc5_.addEventListener(TimerEvent.TIMER_COMPLETE,popID);
            _loc5_.start();
            _loc6_ = new DataTimer(10000,1);
            _loc6_.data.text = param2;
            _loc6_.addEventListener(TimerEvent.TIMER_COMPLETE,fadeText);
            _loc6_.start();
         }
      }

      private static function popID(param1:TimerEvent) : *
      {
         var _loc2_:DataTimer = param1.currentTarget as DataTimer;
         mMessageSupression.splice(mMessageSupression.indexOf(_loc2_.data.id),1);
      }

      private static function fadeText(param1:TimerEvent) : *
      {
         var _loc2_:DataTimer = param1.currentTarget as DataTimer;
         if(mTutorialClip.mTaskText.text == _loc2_.data.text)
         {
            TweenLite.to(mTutorialClip.mTaskText,3,{"alpha":0});
            TweenLite.to(mTutorialClip.mBubble,3,{"alpha":0});
            TweenLite.to(mTutorialClip.mGhost,3,{"alpha":0});
         }
      }

      public static function SetText(param1:String, param2:Function = null) : void
      {
         mClickDone = param2;
         mTutorialClip.mClickContinue.visible = false;
         TweenLite.to(mTutorialClip.mTaskText,0.5,{
            "alpha":0,
            "onComplete":swatchText,
            "onCompleteParams":[param1]
         });
      }

      private static function swatchText(param1:String) : void
      {
         mTutorialClip.mTaskText.htmlText = param1;
         TweenLite.to(mTutorialClip.mTaskText,0.5,{
            "alpha":1,
            "onComplete":displayedText
         });
      }

      private static function displayedText() : void
      {
         if(Boolean(mClickDone))
         {
            mTutorialClip.mClickContinue.visible = true;
         }
      }

      private static function contText(param1:MouseEvent) : void
      {
         if(Boolean(mClickDone))
         {
            mClickDone();
         }
      }

      public static function ClickThruText(param1:Array, param2:int, param3:Function) : void
      {
         var textArray:Array = param1;
         var i:int = param2;
         var callback:Function = param3;
         if(mGameStarted && i == 0)
         {
            World.PauseGame();
         }
         SetText(textArray[i],function():void
         {
            if(i + 1 < textArray.length)
            {
               ClickThruText(textArray,i + 1,callback);
            }
            else
            {
               mTutorialClip.mClickContinue.visible = false;
               if(mGameStarted)
               {
                  World.Continue();
                  Bunni.staticWorld.mouseUp();
               }
               if(Boolean(callback))
               {
                  callback();
               }
            }
         });
      }
   }
}
