package MapItems.StoreItems
{
   import Art.LoadArt;
   import Collision.TestCollision;
   import Drawing.BitmapFrame;
   import FSM.StateMachine;
   import Geom.Circle;
   import Geom.Vector2D;
   import Land.Land;
   import MapItems.GenericItem;
   import MapItems.Ghosts.QuestItem;
   import MapItems.Items;
   import MapItems.StoreItems.States.*;
   import Rewards.Motes;
   import Sound.SoundManager;
   import Tutorial.Tasks;
   import World.World;
   import flash.events.TimerEvent;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Point;

   public class PlacementItem extends GenericItem
   {

      private static var mInteractionCircle:BitmapFrame;

      public var mDestination:Point = new Point(0,0);

      private var mFrame:int;

      private var mInner:int;

      private var mOuter:int;

      private var mItemClass:Class;

      private var mCanPlace:Boolean;

      public var mLarge:Boolean = false;

      public var mCostWood:int;

      public var mCostGem:int;

      public var mCostRock:int;

      private var destX:Number;

      private var destY:Number;

      private var mHasPlaced:Boolean = false;

      public function PlacementItem(param1:int, param2:int, param3:int, param4:int, param5:int, param6:int, param7:Class, param8:String, param9:int, param10:int, param11:int)
      {
         super();
         mName = param8;
         this.mCostWood = param9;
         this.mCostGem = param10;
         this.mCostRock = param11;
         this.mFrame = param3;
         this.mInner = param4;
         this.mOuter = param5;
         this.mItemClass = param7;
         init(param1,param2,LoadArt.mStoreItems.getFrame(this.mFrame),new Circle(param1,param2,this.mInner),new Circle(param1,param2,this.mOuter),param6);
         var _loc12_:Object = StoreItemsList.GetObjFromName(mName);
         this.mName = _loc12_.name;
         this.mItemID = int(_loc12_.id);
         this.mPersist = int(_loc12_.persistent) == 1;
         World.mAvatar.AddShopItemToChain(this);
         if(!mInteractionCircle)
         {
            mInteractionCircle = new BitmapFrame();
            mInteractionCircle.CreateFrameFromMovieClip(new InteractionCircle());
         }
      }

      private function hintPlace(param1:TimerEvent) : void
      {
         if(this.mHasPlaced)
         {
         }
      }

      public function CreateItem() : void
      {
         this.mHasPlaced = true;
         Motes.PlacementMote(mName);
         Tasks.Place(mName);
         var _loc1_:GenericItem = new this.mItemClass(mArt,x,y,mSize,new Circle(x,y,this.mInner),new Circle(x,y,this.mOuter));
         var _loc2_:Object = StoreItemsList.GetObjFromName(mName);
         _loc1_.mName = _loc2_.name;
         _loc1_.mItemID = int(_loc2_.id);
         _loc1_.mPersist = int(_loc2_.persistent) == 1;
         _loc1_.mMissionID = this.mMissionID;
         if(_loc1_ is QuestItem)
         {
            QuestItem(_loc1_).SetByID();
         }
         Items.RemoveItem(this);
      }

      public function DestroyItem() : void
      {
         Items.RemoveItem(this);
      }

      public function CanPlace() : Boolean
      {
         if(TestCollision.CircleOnMap2(new Circle(x,y,this.mInner)))
         {
            mAlpha = 1;
            this.mCanPlace = true;
         }
         else
         {
            mAlpha = 0.2;
            this.mCanPlace = false;
         }
         return this.mCanPlace;
      }

      public function isFollowing() : Boolean
      {
         if(Boolean(mStateMachine) && mStateMachine.isInState(new ItemFollowAvatar()))
         {
            return true;
         }
         return false;
      }

      public function FollowAvatar() : void
      {
         this.ShowSmall();
         mAlpha = 1;
         World.mAvatar.AddShopItemToChain(this);
         mStateMachine = new StateMachine(this);
         mStateMachine.SetCurrentState(new ItemFollowAvatar());
      }

      public function ShowLarge() : void
      {
         this.mLarge = true;
         mArt = LoadArt.mStoreItems.getFrame(this.mFrame + StoreItemsList.mNoStoreItemFrames * 4);
      }

      public function ShowSmall() : void
      {
         this.mLarge = false;
         mArt = LoadArt.mStoreItems.getFrame(this.mFrame);
      }

      override public function initStateMachine() : void
      {
         mStateMachine = new StateMachine(this);
         mStateMachine.SetCurrentState(new ItemFollowAvatar());
      }

      public function StartDrag() : void
      {
         var _loc1_:int = 0;
         var _loc2_:SoundManager = SoundManager.getInstance();
         _loc2_.playSound("PickUp",2);
         World.mAvatar.RemoveItemFromChain(this);
         mStateMachine = null;
      }

      public function SetDestination(param1:int, param2:int) : void
      {
         this.mDestination = new Point(param1,param2);
      }

      public function Move() : void
      {
         this.destX = Land.mStage.mouseX + World.WORLD_LOC_X;
         this.destY = (Land.mStage.mouseY + World.WORLD_LOC_Y) * 2;
         var _loc1_:Vector2D = TestCollision.NextStep(this.destX,this.destY,x,y,50,this.mInnerCircle);
         if(_loc1_.Length() != 0)
         {
            this.x += _loc1_.x;
            this.y += _loc1_.y;
         }
      }

      public function draw_under() : void
      {
         var _loc1_:Matrix = null;
         var _loc2_:Number = NaN;
         var _loc3_:ColorTransform = null;
         if(this.mOuter != 0)
         {
            drawx = x - World.WORLD_LOC_X;
            drawy = y / 2 - World.WORLD_LOC_Y;
            if(this.mCanPlace)
            {
               _loc1_ = new Matrix();
               _loc1_.translate(mInteractionCircle.hotspotX,mInteractionCircle.hotspotY);
               _loc2_ = this.mOuter / 100;
               _loc1_.scale(_loc2_,_loc2_);
               _loc1_.translate(drawx,drawy);
               Land.queue(mInteractionCircle.bitmapData,_loc1_,_loc3_,null,true);
            }
            else
            {
               _loc1_ = new Matrix();
               _loc1_.translate(mInteractionCircle.hotspotX,mInteractionCircle.hotspotY);
               _loc2_ = this.mOuter / 100;
               _loc1_.scale(_loc2_,_loc2_);
               _loc1_.translate(drawx,drawy);
               _loc3_ = new ColorTransform();
               _loc3_.alphaMultiplier = 0.2;
               Land.queue(mInteractionCircle.bitmapData,_loc1_,_loc3_,null,true);
            }
         }
      }
   }
}
