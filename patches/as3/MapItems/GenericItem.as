package MapItems
{
   import Art.LoadArt;
   import Drawing.BitmapFrame;
   import FSM.StateMachine;
   import Geom.Circle;
   import Land.Land;
   import MapItems.Animals.MonsterItem;
   import MapItems.Avatar.AvatarItem;
   import MapItems.Building.CastleItem;
   import MapItems.Building.StoreBuildingItem;
   import MapItems.Coriander.CorianderItem;
   import MapItems.Peach.PeachItem;
   import MapItems.PiratePete.PiratePete;
   import MapItems.Tower.TowerItem;
   import World.World;
   import flash.display.*;
   import flash.geom.*;

   public class GenericItem
   {

      private static var mNextValidID:int = 0;

      public var mHighlight:Boolean = false;

      public var mInnerCircle:Circle;

      public var mOuterCircle:Circle;

      public var mSize:int;

      public var mArt:BitmapFrame;

      private var mX:int;

      private var mY:int;

      public var drawx:int;

      public var drawy:int;

      public var mScale:Number = 1;

      public var mExplination:int = 0;

      public var mParent:Boolean;

      public var mStateMachine:StateMachine = null;

      public var mReserved:Boolean = false;

      public var mCanHarvest:Boolean = false;

      public var mCollision:* = true;

      public var mAlpha:Number = 1;

      public var mName:String;

      public var mItemID:int;

      public var mMissionID:int;

      public var mPersist:Boolean = false;

      public var mVisible:Boolean = true;

      public var itemRect:Rectangle;

      public var mID:int;

      public function GenericItem()
      {
         super();
         this.mID = mNextValidID;
         ++mNextValidID;
      }

      public function destroy() : void
      {
         this.mStateMachine = null;
         this.mArt = null;
         this.mInnerCircle = null;
         this.mOuterCircle = null;
      }

      public function get x() : int
      {
         return this.mX;
      }

      public function get y() : int
      {
         return this.mY;
      }

      public function set x(param1:int) : void
      {
         this.mX = param1;
         if(this.mInnerCircle)
         {
            this.mInnerCircle.x = param1;
         }
      }

      public function set y(param1:int) : void
      {
         this.mY = param1;
         if(this.mInnerCircle)
         {
            this.mInnerCircle.y = param1;
         }
      }

      public function init(param1:int, param2:int, param3:BitmapFrame = null, param4:Circle = null, param5:Circle = null, param6:int = 0, param7:Boolean = true) : void
      {
         this.x = param1;
         this.y = param2;
         this.mArt = param3;
         if(param4)
         {
            this.mInnerCircle = new Circle(this.x,this.y,param4.r);
         }
         if(param5)
         {
            this.mOuterCircle = new Circle(param5.x,param5.y,param5.r);
         }
         this.mSize = param6;
         this.mParent = param7;
         Items.AddItem(this);
         this.initStateMachine();
      }

      public function initStateMachine() : void
      {
      }

      public function Update() : void
      {
         if(this.mStateMachine)
         {
            this.mStateMachine.Update();
         }
      }

      public function mapDraw() : void
      {
         var _loc3_:ColorTransform = null;
         if(!this.mArt)
         {
            throw new Error("___WE HAVE NULL ART___," + this + "," + this.mID);
         }
         var _loc1_:Number = Land.mScreenBitmapData.width / Land.mEntireMap.width;
         this.drawx = (this.x + Land.WORLD_INSET / 2) * _loc1_;
         this.drawy = (this.y / 2 + Land.WORLD_INSET / 2) * _loc1_;
         var _loc2_:Matrix = new Matrix();
         _loc2_.translate(this.mArt.hotspotX,this.mArt.hotspotY);
         _loc2_.scale(this.mScale * _loc1_,this.mScale * _loc1_);
         _loc2_.translate(this.drawx,this.drawy + 64);
         if(this.mAlpha != 1)
         {
            _loc3_ = new ColorTransform();
            _loc3_.alphaMultiplier = this.mAlpha;
         }
         Land.queue(this.mArt.bitmapData,_loc2_,_loc3_,null,true);
      }

      public function mapDrawLabels() : void
      {
         var _loc1_:TowerItem = null;
         var _loc2_:MovieClip = null;
         var _loc3_:Number = NaN;
         var _loc4_:Matrix = null;
         if(!this.mArt)
         {
            throw new Error("___WE HAVE NULL ART___," + this + "," + this.mID);
         }
         if(this is TowerItem || this is CastleItem || this is StoreBuildingItem || this is PeachItem || this is AvatarItem || this is CorianderItem || this is PiratePete)
         {
            if(this is AvatarItem)
            {
               this.mName = "You";
            }
            if(this.mName)
            {
               _loc3_ = Land.mScreenBitmapData.width / Land.mEntireMap.width;
               if(this is AvatarItem)
               {
                  _loc2_ = new AvatarText();
               }
               else if(this is TowerItem || this is CastleItem || this is StoreBuildingItem)
               {
                  _loc2_ = new BuildingText();
               }
               else
               {
                  _loc2_ = new CharacterText();
               }
               _loc2_.mLabel.text = this.mName;
               _loc4_ = new Matrix();
               this.drawx = (this.x + Land.WORLD_INSET / 2) * _loc3_;
               this.drawy = (this.y / 2 + Land.WORLD_INSET / 2) * _loc3_;
               _loc4_.translate(this.drawx,this.drawy + 64);
               Land.queueObject(_loc2_,_loc4_);
               _loc2_ = null;
            }
         }
      }

      public function draw() : void
      {
         var _loc2_:Matrix = null;
         var _loc3_:BitmapFrame = null;
         var _loc4_:Number = NaN;
         var _loc5_:ColorTransform = null;
         if(!this.mArt)
         {
            trace("___WE HAVE NULL ART___");
            trace(this);
            trace(this.mID);
            throw new Error("___WE HAVE NULL ART___," + this + "," + this.mID);
         }
         this.drawx = this.x - World.WORLD_LOC_X;
         this.drawy = this.y / 2 - World.WORLD_LOC_Y;
         var _loc1_:Rectangle = new Rectangle(0,0,World.SCREEN_WIDTH,World.SCREEN_HEIGHT);
         if(this.mScale == 1)
         {
            this.itemRect = new Rectangle(this.drawx + this.mArt.hotspotX,this.drawy + this.mArt.hotspotY,this.mArt.mRect.width,this.mArt.mRect.height);
         }
         else
         {
            this.itemRect = new Rectangle(this.drawx + this.mArt.hotspotX * this.mScale,this.drawy + this.mArt.hotspotY * this.mScale,this.mArt.mRect.width * this.mScale,this.mArt.mRect.height * this.mScale);
         }
         if(!this.itemRect)
         {
            trace("this",this);
            trace("in mapitem",Items.Exists(this));
            trace("this",this.mName);
            trace("mArt",this.mArt);
            trace("x",this.x);
            trace("y",this.y);
         }
         if(_loc1_.intersects(this.itemRect))
         {
            if(this.mHighlight && !(this is TowerItem))
            {
               _loc2_ = new Matrix();
               _loc2_.translate(LoadArt.mHighlight.hotspotX,LoadArt.mHighlight.hotspotY);
               _loc4_ = (this.mInnerCircle.r + 50) / 100;
               _loc2_.scale(_loc4_,_loc4_);
               _loc2_.translate(this.drawx,this.drawy);
               Land.queue(LoadArt.mHighlight.bitmapData,_loc2_,null,null,true);
            }
            if(this.mScale == 1 && this.mAlpha == 1)
            {
               if(this is MonsterItem)
               {
                  if(MonsterItem(this).mTame)
                  {
                     _loc3_ = LoadArt.mMoteArt.getFrame(58);
                     Land.blit(_loc3_.bitmapData,_loc3_.mRect,this.drawx + _loc3_.hotspotX,this.drawy + _loc3_.hotspotY - 40);
                  }
               }
               Land.blit(this.mArt.bitmapData,this.mArt.mRect,this.drawx + this.mArt.hotspotX,this.drawy + this.mArt.hotspotY);
               if(this.mExplination != 0)
               {
                  _loc3_ = LoadArt.mExplination.getFrame(this.mExplination);
                  Land.blit(_loc3_.bitmapData,_loc3_.mRect,this.drawx + _loc3_.hotspotX,this.drawy + _loc3_.hotspotY - 70);
               }
               if(this.mHighlight && this is TowerItem)
               {
                  _loc2_ = new Matrix();
                  _loc2_.translate(LoadArt.mHighlight.hotspotX,LoadArt.mHighlight.hotspotY);
                  _loc4_ = (this.mInnerCircle.r + 50) / 100;
                  _loc2_.translate(this.drawx + 33,this.drawy + 44);
                  Land.queue(LoadArt.mTowerHilight.bitmapData,_loc2_,null,null,true);
               }
            }
            else
            {
               _loc2_ = new Matrix();
               _loc2_.translate(this.mArt.hotspotX,this.mArt.hotspotY);
               _loc2_.scale(this.mScale,this.mScale);
               _loc2_.translate(this.drawx,this.drawy);
               if(this.mAlpha != 1)
               {
                  _loc5_ = new ColorTransform();
                  _loc5_.alphaMultiplier = this.mAlpha;
               }
               Land.queue(this.mArt.bitmapData,_loc2_,_loc5_,null,true);
               if(this.mExplination)
               {
                  _loc2_.translate(0,-70);
                  _loc3_ = LoadArt.mExplination.getFrame(this.mExplination);
                  Land.queue(_loc3_.bitmapData,_loc2_,null,null,true);
               }
            }
         }
      }

      public function get id() : int
      {
         return this.mID;
      }
   }
}
