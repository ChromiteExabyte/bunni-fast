package MapItems.Avatar
{
   import Art.LoadArt;
   import Collision.TestCollision;
   import Geom.Circle;
   import Geom.Vector2D;
   import Land.Land;
   import MapItems.Animals.GenericAnimal;
   import MapItems.GenericItem;
   import MapItems.Mote.MoteItem;
   import MapItems.StoreItems.PlacementItem;
   import Menu.HUD;
   import Sound.Attenuation;
   import Static.Size;
   import Tutorial.Tasks;
   import World.World;
   import flash.geom.Point;

   public class AvatarItem extends GenericItem
   {

      public static var mHasMoved:Boolean = false;

      private var destX:Number;

      private var destY:Number;

      private const START_FRAME:int = 2;

      private const END_FRAME:int = 23;

      private var mFrameCounter:int = 2;

      private var mPath:Array = new Array();

      private var mBunnyChain:Array = new Array();

      private var mCurrentLength:Number = 0;

      public function AvatarItem(param1:int, param2:int)
      {
         super();
         this.init(param1,param2,LoadArt.mAvatarArtFrameSet.getFrame(1),new Circle(param1,param2,20),null,Size.NONE);
         this.destX = param1;
         this.destY = param2;
      }

      public function Move() : void
      {
         var _loc1_:Number = NaN;
         mHasMoved = true;
         Tasks.MoveAvatar();
         if(World.mMapDraw)
         {
            _loc1_ = Land.mScreenBitmapData.width / Land.mEntireMap.width;
            this.destX = Land.mStage.mouseX / _loc1_ + Land.WORLD_INSET / 2 * _loc1_;
            this.destY = (Land.mStage.mouseY - 64) * 2 / _loc1_ + Land.WORLD_INSET / 2 * _loc1_;
         }
         else
         {
            this.destX = Land.mStage.mouseX + World.WORLD_LOC_X;
            this.destY = (Land.mStage.mouseY + World.WORLD_LOC_Y) * 2;
         }
      }

      public function MoveCenter() : void
      {
         this.destX = 320 + World.WORLD_LOC_X;
         this.destY = (240 + World.WORLD_LOC_Y) * 2;
      }

      public function Stop() : void
      {
         this.destX = x;
         this.destY = y;
      }

      public function AddShopItemToChain(param1:PlacementItem) : void
      {
         this.mBunnyChain.unshift(param1);
         param1.SetDestination(x,y);
      }

      public function AddMoteItemToChain(param1:MoteItem) : void
      {
         this.mBunnyChain.unshift(param1);
         param1.SetDestination(x,y);
      }

      public function AddBunnyToChain(param1:GenericAnimal) : void
      {
         this.mBunnyChain.unshift(param1);
         param1.SetDestination(x,y);
      }

      public function RemoveBunnyFromChain(param1:GenericAnimal) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = int(this.mBunnyChain.length);
         _loc2_ = 0;
         while(_loc2_ < _loc3_)
         {
            if(this.mBunnyChain[_loc2_] == param1)
            {
               this.mBunnyChain.splice(_loc2_,1);
            }
            _loc2_++;
         }
      }

      public function RemoveItemFromChain(param1:GenericItem) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = int(this.mBunnyChain.length);
         _loc2_ = 0;
         while(_loc2_ < _loc3_)
         {
            if(this.mBunnyChain[_loc2_] == param1)
            {
               this.mBunnyChain.splice(_loc2_,1);
            }
            _loc2_++;
         }
      }

      private function CalculateBunnyDestinations() : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc10_:Vector2D = null;
         var _loc11_:Number = NaN;
         var _loc1_:int = 100;
         var _loc4_:int = int(this.mPath.length);
         var _loc5_:int = int(this.mBunnyChain.length);
         var _loc6_:int = 0;
         var _loc7_:Number = 0;
         var _loc8_:Number = this.x;
         var _loc9_:Number = this.y;
         _loc2_ = 0;
         while(_loc2_ < _loc5_)
         {
            while(_loc6_ < _loc4_ - 2)
            {
               _loc10_ = new Vector2D(_loc8_ - this.mPath[_loc6_].x,_loc9_ - this.mPath[_loc6_].y);
               _loc7_ += _loc10_.Length();
               if(_loc6_ == 0)
               {
               }
               if(_loc7_ >= _loc1_)
               {
                  _loc11_ = _loc7_ - _loc1_;
                  _loc10_.Truncate(_loc11_);
                  _loc8_ = _loc10_.x + _loc8_;
                  _loc9_ = _loc10_.y + _loc9_;
                  if(this.mBunnyChain[_loc2_] is GenericAnimal)
                  {
                     GenericAnimal(this.mBunnyChain[_loc2_]).SetDestination(_loc8_,_loc9_);
                  }
                  else if(this.mBunnyChain[_loc2_] is MoteItem)
                  {
                     MoteItem(this.mBunnyChain[_loc2_]).SetDestination(_loc8_,_loc9_);
                  }
                  else if(this.mBunnyChain[_loc2_] is PlacementItem)
                  {
                     PlacementItem(this.mBunnyChain[_loc2_]).SetDestination(_loc8_,_loc9_);
                  }
                  _loc7_ = 0;
                  break;
               }
               _loc8_ = Number(this.mPath[_loc6_].x);
               _loc9_ = Number(this.mPath[_loc6_].y);
               _loc6_++;
            }
            if(_loc6_ == _loc4_ - 2)
            {
            }
            _loc2_++;
         }
      }

      public function update() : void
      {
         var _loc1_:Vector2D = null;
         var _loc2_:String = null;
         var _loc3_:Number = NaN;
         var _loc4_:int = 0;
         this.mArt = LoadArt.mAvatarArtFrameSet.getFrame(this.mFrameCounter);
         ++this.mFrameCounter;
         if(this.mFrameCounter > this.END_FRAME)
         {
            HUD.AddScore(1);
            _loc2_ = "Hop" + int(Math.random() * 4);
            Attenuation.PlayPointSound(_loc2_,new Point(this.x,this.y),2,1000);
            this.mFrameCounter = this.START_FRAME;
         }
         if(World.mMapDraw)
         {
            _loc1_ = Land.nextAvatarStep(this.destX,this.destY,x,y,50);
         }
         else
         {
            _loc1_ = Land.nextAvatarStep(this.destX,this.destY,x,y,20);
         }
         if(_loc1_.Length() != 0)
         {
            this.x += _loc1_.x;
            this.y += _loc1_.y;
            this.mCurrentLength += _loc1_.Length();
            if(this.mCurrentLength > 20)
            {
               this.mPath.unshift({
                  "x":this.x,
                  "y":this.y,
                  "length":_loc1_.length
               });
               _loc3_ = 0;
               _loc4_ = 0;
               while(_loc4_ < this.mPath.length)
               {
                  _loc3_ += this.mPath[_loc4_].length;
                  if(_loc3_ > 800)
                  {
                     this.mPath.splice(_loc4_,this.mPath.length - _loc4_);
                  }
                  _loc4_++;
               }
               this.mCurrentLength = 0;
            }
         }
         if(_loc1_.Length() < 1 && this.mFrameCounter < 3)
         {
            this.mFrameCounter = 1;
         }
         this.CalculateBunnyDestinations();
      }
   }
}
